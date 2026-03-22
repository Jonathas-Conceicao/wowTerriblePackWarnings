local addonName, ns = ...

ns.NameplateScanner = {}
local Scanner = ns.NameplateScanner

-- Current pack reference (has .abilities)
local activePack = nil

-- C_Timer.NewTicker handle for the 0.25s poll loop
local tickerHandle = nil

-- classBase -> number (count of in-combat hostile mobs from last tick)
local prevCounts = {}

-- classBase -> { barId1, barId2, ... } (active timed icon barIds per class)
local classBarIds = {}

-- spellID -> boolean (untimed static icon already shown for this ability)
local staticShown = {}

-- spellID -> ability table reference (untimed skills only, used to check if class has trackable casts)
local spellIndex = {}

-- classBase -> bool (true = this class has at least one untimed ability; built at Start())
local classHasUntimed = {}

-- classBase -> bool (true = at least one mob of this class is casting a tracked spell)
local castingByClass = {}

-- Global incrementing ID for unique per-mob barIds
local timerCounter = 0

-- Nameplate cache: unitToken -> { hostile = bool, classBase = string }
-- Populated on NAME_PLATE_UNIT_ADDED, cleared on NAME_PLATE_UNIT_REMOVED.
-- UnitCanAttack and UnitClass are stable for a given mob in dungeon content,
-- so we cache them to avoid redundant API calls in the 0.25s hot loop.
local plateCache = {}

-- Reusable tick-scope tables (wiped at start of each Tick to avoid per-tick allocation)
local newCounts  = {}
local newCasting = {}

-- Debug logging: reads shared toggle from SavedVariables (ns.db.debug)
-- Toggle with /tpw debug. Persists through /reload.
local function dbg(msg)
    if ns.db and ns.db.debug then print("|cff888888TPW-dbg|r " .. msg) end
end

-- ============================================================
-- Nameplate cache management (called from Core.lua events)
-- ============================================================

function Scanner:OnNameplateAdded(unitToken)
    local hostile = UnitCanAttack("player", unitToken)
    local _, classBase = UnitClass(unitToken)
    plateCache[unitToken] = {
        hostile   = hostile,
        classBase = classBase,
    }
end

function Scanner:OnNameplateRemoved(unitToken)
    plateCache[unitToken] = nil
end

-- ============================================================
-- Internal: mob lifecycle handlers
-- ============================================================

--- Called when new mobs of a class enter combat.
-- Spawns per-mob timed icons and per-ability static icons.
function Scanner:OnMobsAdded(classBase, delta)
    classBarIds[classBase] = classBarIds[classBase] or {}

    for _, ability in ipairs(activePack.abilities) do
        if ability.mobClass == classBase then
            if ability.cooldown then
                -- Timed: one icon per mob instance
                for i = 1, delta do
                    timerCounter = timerCounter + 1
                    local barId = "mob_" .. classBase .. "_" .. timerCounter
                    table.insert(classBarIds[classBase], barId)
                    ns.Scheduler:StartAbility(ability, barId)
                    dbg("OnMobsAdded: " .. tostring(ability.spellID) .. " barId=" .. barId)
                end
            else
                -- Untimed: one static icon per ability, regardless of mob count
                if not staticShown[ability.spellID] then
                    staticShown[ability.spellID] = true
                    ns.IconDisplay.ShowStaticIcon("static_" .. ability.spellID, ability.spellID, ability.label, ability.ttsMessage, ability.soundKitID, ability.soundEnabled)
                    dbg("OnMobsAdded: static icon for " .. tostring(ability.spellID))
                end
            end
        end
    end
end

-- ============================================================
-- Internal: cast lifecycle handlers
-- ============================================================

--- Called on state transition: no-cast -> casting for a given mob class.
-- Highlights all untimed static icons whose mobClass matches classBase.
-- Alert (sound/TTS) fires here on the transition — not repeated while cast is ongoing.
function Scanner:OnCastStart(classBase)
    for _, ability in ipairs(activePack.abilities) do
        if not ability.cooldown and ability.mobClass == classBase then
            local key = "static_" .. ability.spellID
            ns.IconDisplay.SetCastHighlight(key, ability)
        end
    end
    dbg("OnCastStart: " .. classBase)
end

--- Called on state transition: casting -> no-cast for a given mob class.
-- Clears orange cast glow on all untimed static icons for this class.
function Scanner:OnCastEnd(classBase)
    for _, ability in ipairs(activePack.abilities) do
        if not ability.cooldown and ability.mobClass == classBase then
            local key = "static_" .. ability.spellID
            ns.IconDisplay.ClearCastHighlight(key)
        end
    end
    dbg("OnCastEnd: " .. classBase)
end

-- ============================================================
-- Internal: tick (0.25s poll)
-- ============================================================

--- Single scan tick: count hostile in-combat mobs by class, reconcile changes.
-- PERF: Runs every 0.25s via C_Timer.NewTicker while a pack is active.
-- Per tick: iterates C_NamePlate.GetNamePlates() (typically 5-20 frames).
-- UnitCanAttack and UnitClass are cached at NAME_PLATE_UNIT_ADDED (stable per mob).
-- Only UnitAffectingCombat is called per tick (dynamic combat state).
-- Cost: ~20 API calls/tick at 20 nameplates (1 call each). Reconcile loop
-- is O(unique_classes), typically 2-5 iterations. Reviewed 2026-03-16.
function Scanner:Tick()
    if not activePack then return end

    wipe(newCounts)  -- classBase -> count of in-combat hostile mobs this tick

    local plates = C_NamePlate.GetNamePlates()
    for _, plate in ipairs(plates) do
        local npUnit = plate.namePlateUnitToken or plate.unitToken
        if npUnit then
            local cached = plateCache[npUnit]
            if cached and cached.hostile and cached.classBase then
                -- UnitAffectingCombat does not throw in Midnight — call directly
                local inCombat = UnitAffectingCombat(npUnit)
                if inCombat then
                    newCounts[cached.classBase] = (newCounts[cached.classBase] or 0) + 1
                    -- Debug: log every class detected (first scan only)
                    if not prevCounts[cached.classBase] then
                        dbg("Scan found class: " .. cached.classBase .. " unit=" .. tostring(npUnit))
                    end
                end
            end
        end
    end

    -- Reconcile: only add new timers when visible mob count exceeds tracked timer count
    -- This prevents camera turns from spawning duplicate icons
    for classBase, count in pairs(newCounts) do
        local tracked = classBarIds[classBase] and #classBarIds[classBase] or 0
        if count > tracked then
            Scanner:OnMobsAdded(classBase, count - tracked)
        end
    end

    -- Copy newCounts into prevCounts (reuse table, avoid reassignment)
    wipe(prevCounts)
    for k, v in pairs(newCounts) do
        prevCounts[k] = v
    end

    -- Cast detection pass: poll UnitCastingInfo/UnitChannelInfo for tracked spells
    -- Reuses the `plates` variable captured at the top of Tick() (no duplicate GetNamePlates call)
    wipe(newCasting)  -- classBase -> bool

    for _, plate in ipairs(plates) do
        local npUnit = plate.namePlateUnitToken or plate.unitToken
        if npUnit then
            local cached = plateCache[npUnit]
            if cached and cached.hostile and cached.classBase then
                -- Check if this mob is casting or channeling anything.
                -- Midnight wraps spellIDs as Secret Values (can't use as table keys),
                -- so we only check if a cast is happening (name ~= nil), not which spell.
                -- Our model: any mob of tracked class casting → glow all untimed skills for that class.
                -- Only check mobs whose class has untimed abilities (O(1) lookup via classHasUntimed).
                if classHasUntimed[cached.classBase] then
                    local isCasting = false
                    local okCast, castName = pcall(UnitCastingInfo, npUnit)
                    if okCast and castName then
                        isCasting = true
                    end
                    if not isCasting then
                        local okChan, chanName = pcall(UnitChannelInfo, npUnit)
                        if okChan and chanName then
                            isCasting = true
                        end
                    end
                    if isCasting then
                        newCasting[cached.classBase] = true
                    end
                end
            end
        end
    end

    -- Reconcile cast state transitions
    for classBase in pairs(newCasting) do
        if not castingByClass[classBase] then
            castingByClass[classBase] = true
            Scanner:OnCastStart(classBase)
        end
    end
    for classBase in pairs(castingByClass) do
        if not newCasting[classBase] then
            castingByClass[classBase] = nil
            Scanner:OnCastEnd(classBase)
        end
    end
end

-- ============================================================
-- Public API
-- ============================================================

--- Start scanning nameplates for the given pack.
-- Creates a 0.25s repeating ticker and does an immediate first tick.
function Scanner:Start(pack)
    -- Guard: prevent duplicate tickers (Pitfall 3)
    if tickerHandle then return end

    activePack = pack
    wipe(prevCounts)
    wipe(classBarIds)
    wipe(staticShown)
    wipe(spellIndex)
    wipe(classHasUntimed)
    wipe(castingByClass)
    timerCounter = 0

    -- Build O(1) lookup tables for untimed skills
    -- Timed skills alert via the timer system (SetUrgent), not cast detection
    for _, ability in ipairs(pack.abilities) do
        if not ability.cooldown then
            spellIndex[ability.spellID] = ability
            classHasUntimed[ability.mobClass] = true
        end
    end

    dbg("NameplateScanner:Start — polling every 0.25s for " .. #pack.abilities .. " abilities")

    -- PERF: 0.25s poll interval chosen as balance between detection latency
    -- and CPU cost. See Scanner:Tick() for per-tick cost breakdown.
    tickerHandle = C_Timer.NewTicker(0.25, function()
        Scanner:Tick()
    end)

    -- Immediate first tick so detection doesn't wait 0.25s
    Scanner:Tick()
end

--- Stop scanning and clean up all state.
function Scanner:Stop()
    if tickerHandle then
        if not tickerHandle:IsCancelled() then
            tickerHandle:Cancel()
        end
        tickerHandle = nil
    end

    activePack = nil
    wipe(prevCounts)
    wipe(classBarIds)
    wipe(staticShown)
    wipe(spellIndex)
    wipe(classHasUntimed)
    wipe(castingByClass)
    -- Note: plateCache is NOT wiped here — it's managed by nameplate events
    -- and stays valid across combat sessions

    dbg("NameplateScanner:Stop — scanner halted")
end
