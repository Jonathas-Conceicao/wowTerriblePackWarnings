local addonName, ns = ...

ns.Scheduler = {}
local Scheduler = ns.Scheduler

-- All active C_Timer handles for bulk cancellation
local activeTimers = {}

-- Per-barId timer tracking for surgical cancellation (used by StopAbility)
local barTimers = {}

-- Single-element table so closures capture the table reference (not a boolean value).
-- Lua closures capture variable references; boolean reassignment creates a new value,
-- but table mutation is visible to all existing closures via the same reference.
local combatActive = { false }

-- Incrementing ID for display icon slots
local timerCounter = 0

-- ============================================================
-- Local scheduler core
-- ============================================================

local scheduleAbility  -- forward declaration for recursion

scheduleAbility = function(ability, existingBarId)
    local barId = existingBarId or ("bar_" .. timerCounter)
    if not existingBarId then
        timerCounter = timerCounter + 1
    end

    -- Show the icon immediately with cooldown sweep
    ns.IconDisplay.ShowIcon(barId, ability.spellID, ability.ttsMessage, ability.first_cast, ability.label)

    -- Pre-warning: 5 seconds before the cast — set urgent glow + TTS
    local preWarnOffset = ability.first_cast - 5
    if preWarnOffset < 0 then preWarnOffset = 0 end

    -- Ensure per-barId tracking table exists
    barTimers[barId] = barTimers[barId] or { handles = {} }

    if preWarnOffset > 0 then
        local preHandle = C_Timer.NewTimer(preWarnOffset, function()
            if not combatActive[1] then return end
            ns.IconDisplay.SetUrgent(barId)
        end)
        table.insert(activeTimers, preHandle)
        table.insert(barTimers[barId].handles, preHandle)
    end

    -- Cast alert timer — reschedule for next cycle
    local castHandle = C_Timer.NewTimer(ability.first_cast, function()
        if not combatActive[1] then return end

        -- Reschedule for next repeat using cooldown as the new first_cast
        -- Reuse the same barId so ShowIcon resets the existing icon slot
        scheduleAbility({
            name       = ability.name,
            spellID    = ability.spellID,
            ttsMessage = ability.ttsMessage,
            first_cast = ability.cooldown,
            cooldown   = ability.cooldown,
        }, barId)
    end)
    table.insert(activeTimers, castHandle)
    table.insert(barTimers[barId].handles, castHandle)
end

-- ============================================================
-- Public API
-- ============================================================

function Scheduler:Start(dungeonKey, packIndex)
    local dungeon = ns.PackDatabase[dungeonKey]
    if not dungeon then
        print("|cff00ccffTPW|r Error: unknown dungeon key '" .. tostring(dungeonKey) .. "'")
        return
    end

    local pack = dungeon[packIndex]
    if not pack then
        print("|cff00ccffTPW|r Error: pack index " .. tostring(packIndex) .. " not found in '" .. dungeonKey .. "'")
        return
    end

    combatActive[1] = true

    for _, ability in ipairs(pack.abilities) do
        if ability.cooldown then
            scheduleAbility(ability)
        else
            -- Untimed: show static icon (one per ability, regardless of mob count)
            ns.IconDisplay.ShowStaticIcon("static_" .. ability.spellID, ability.spellID, ability.label)
        end
    end

    print("|cff00ccffTPW|r Started: " .. pack.displayName)
end

--- Start a single ability with an explicit barId (used by NameplateScanner per-mob).
function Scheduler:StartAbility(ability, barId)
    combatActive[1] = true
    scheduleAbility(ability, barId)
end

--- Cancel all timers for a single barId and remove its icon (used by NameplateScanner on mob death).
function Scheduler:StopAbility(barId)
    local entry = barTimers[barId]
    if entry then
        for _, handle in ipairs(entry.handles) do
            if not handle:IsCancelled() then
                handle:Cancel()
            end
        end
        barTimers[barId] = nil
    end
    ns.IconDisplay.CancelIcon(barId)
end

function Scheduler:Stop()
    combatActive[1] = false

    for _, handle in ipairs(activeTimers) do
        if not handle:IsCancelled() then
            handle:Cancel()
        end
    end
    wipe(activeTimers)
    wipe(barTimers)

    local ok, err = pcall(ns.IconDisplay.CancelAll)
    if not ok then
        print("|cff00ccffTPW|r Warning: CancelAll error: " .. tostring(err))
    end

    timerCounter = 0
end
