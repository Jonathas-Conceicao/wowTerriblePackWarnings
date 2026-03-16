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

-- Global incrementing ID for unique per-mob barIds
local timerCounter = 0

-- Nameplate cache: unitToken -> { hostile = bool, classBase = string }
-- Populated on NAME_PLATE_UNIT_ADDED, cleared on NAME_PLATE_UNIT_REMOVED.
-- UnitCanAttack and UnitClass are stable for a given mob in dungeon content,
-- so we cache them to avoid redundant API calls in the 0.25s hot loop.
local plateCache = {}

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
                    dbg("OnMobsAdded: " .. ability.name .. " barId=" .. barId)
                end
            else
                -- Untimed: one static icon per ability, regardless of mob count
                if not staticShown[ability.spellID] then
                    staticShown[ability.spellID] = true
                    ns.IconDisplay.ShowStaticIcon("static_" .. ability.spellID, ability.spellID, ability.label)
                    dbg("OnMobsAdded: static icon for " .. ability.name)
                end
            end
        end
    end
end

--- Called when mobs of a class die (count decreased between ticks).
-- Removes per-mob timed icons and clears static icons when class count reaches 0.
function Scanner:OnMobsRemoved(classBase, delta)
    local ids = classBarIds[classBase]
    if not ids then return end

    for i = 1, delta do
        local barId = table.remove(ids) -- remove from end
        if barId then
            ns.Scheduler:StopAbility(barId)
            dbg("OnMobsRemoved: stopped barId=" .. barId)
        end
    end

    -- If all mobs of this class are gone, also clear static icons for this class
    if #ids == 0 then
        for _, ability in ipairs(activePack.abilities) do
            if ability.mobClass == classBase and not ability.cooldown then
                local staticId = "static_" .. ability.spellID
                ns.IconDisplay.CancelIcon(staticId)
                staticShown[ability.spellID] = nil
                dbg("OnMobsRemoved: cleared static icon for " .. ability.name)
            end
        end
        classBarIds[classBase] = nil
    end
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

    local newCounts = {} -- classBase -> count of in-combat hostile mobs this tick

    local plates = C_NamePlate.GetNamePlates()
    for _, plate in ipairs(plates) do
        local npUnit = plate.namePlateUnitToken or plate.unitToken
        if npUnit then
            local cached = plateCache[npUnit]
            if cached and cached.hostile and cached.classBase then
                local inCombatOk, inCombat = pcall(UnitAffectingCombat, npUnit)
                if inCombatOk and inCombat then
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

    prevCounts = newCounts
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
    timerCounter = 0

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
    -- Note: plateCache is NOT wiped here — it's managed by nameplate events
    -- and stays valid across combat sessions

    dbg("NameplateScanner:Stop — scanner halted")
end
