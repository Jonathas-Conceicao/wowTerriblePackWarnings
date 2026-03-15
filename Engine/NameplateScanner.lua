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

-- Debug logging (matches established project pattern)
local DEBUG = true
local function dbg(msg)
    if DEBUG then print("|cff888888TPW-dbg|r " .. msg) end
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
                    ns.IconDisplay.ShowStaticIcon("static_" .. ability.spellID, ability.spellID)
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
function Scanner:Tick()
    if not activePack then return end

    local newCounts = {} -- classBase -> count of in-combat hostile mobs this tick

    local plates = C_NamePlate.GetNamePlates()
    for _, plate in ipairs(plates) do
        local npUnit = plate.namePlateUnitToken or plate.unitToken
        if npUnit and UnitCanAttack("player", npUnit) then
            local inCombatOk, inCombat = pcall(UnitAffectingCombat, npUnit)
            if inCombatOk and inCombat then
                local classOk, _, classBase = pcall(UnitClass, npUnit)
                if classOk and classBase then
                    newCounts[classBase] = (newCounts[classBase] or 0) + 1
                end
            end
        end
    end

    -- Reconcile increases first (new mobs entered combat)
    for classBase, count in pairs(newCounts) do
        local prev = prevCounts[classBase] or 0
        if count > prev then
            Scanner:OnMobsAdded(classBase, count - prev)
        end
    end

    -- Reconcile decreases (mobs died)
    for classBase, prev in pairs(prevCounts) do
        local count = newCounts[classBase] or 0
        if count < prev then
            Scanner:OnMobsRemoved(classBase, prev - count)
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

    dbg("NameplateScanner:Stop — scanner halted")
end
