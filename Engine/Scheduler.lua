local addonName, ns = ...

ns.Scheduler = {}
local Scheduler = ns.Scheduler

-- All active C_Timer handles for bulk cancellation
local activeTimers = {}

-- Single-element table so closures capture the table reference (not a boolean value).
-- Lua closures capture variable references; boolean reassignment creates a new value,
-- but table mutation is visible to all existing closures via the same reference.
local combatActive = { false }

-- Debug logging (toggle for testing)
local DEBUG = true
local function dbg(msg)
    if DEBUG then print("|cff888888TPW-dbg|r " .. msg) end
end

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
    ns.IconDisplay.ShowIcon(barId, ability.spellID, ability.ttsMessage, ability.first_cast)

    -- Pre-warning: 5 seconds before the cast — set urgent glow + TTS
    local preWarnOffset = ability.first_cast - 5
    if preWarnOffset < 0 then preWarnOffset = 0 end

    dbg("Schedule: " .. ability.name .. " pre-warn at " .. preWarnOffset .. "s, cast at " .. ability.first_cast .. "s")

    if preWarnOffset > 0 then
        local preHandle = C_Timer.NewTimer(preWarnOffset, function()
            if not combatActive[1] then return end
            dbg("Fire pre-warn: " .. ability.name)
            ns.IconDisplay.SetUrgent(barId)
        end)
        table.insert(activeTimers, preHandle)
    end

    -- Cast alert timer — reschedule for next cycle
    local castHandle = C_Timer.NewTimer(ability.first_cast, function()
        if not combatActive[1] then return end
        dbg("Fire cast: " .. ability.name .. ", next in " .. ability.cooldown .. "s")

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
    dbg("Start: " .. pack.displayName .. " (" .. #pack.abilities .. " abilities)")

    for _, ability in ipairs(pack.abilities) do
        if ability.cooldown then
            scheduleAbility(ability)
        else
            -- Untimed: show static icon (one per ability, regardless of mob count)
            ns.IconDisplay.ShowStaticIcon("static_" .. ability.spellID, ability.spellID)
            dbg("Static icon: " .. ability.name)
        end
    end

    print("|cff00ccffTPW|r Started: " .. pack.displayName)
end

function Scheduler:Stop()
    dbg("Stop: cancelled " .. #activeTimers .. " timers")
    combatActive[1] = false

    for _, handle in ipairs(activeTimers) do
        if not handle:IsCancelled() then
            handle:Cancel()
        end
    end
    wipe(activeTimers)

    local ok, err = pcall(ns.IconDisplay.CancelAll)
    if not ok then
        print("|cff00ccffTPW|r Warning: CancelAll error: " .. tostring(err))
    end

    timerCounter = 0
end
