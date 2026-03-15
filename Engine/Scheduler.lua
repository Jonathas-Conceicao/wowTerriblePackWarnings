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

-- Incrementing ID for display timer bars
local timerCounter = 0

-- ============================================================
-- Local scheduler core
-- ============================================================

local scheduleAbility  -- forward declaration for recursion

scheduleAbility = function(ability)
    -- Pre-warning: 5 seconds before the cast
    local preWarnOffset = ability.first_cast - 5
    if preWarnOffset < 0 then preWarnOffset = 0 end

    dbg("Schedule: " .. ability.name .. " pre-warn at " .. preWarnOffset .. "s, cast at " .. ability.first_cast .. "s")

    if preWarnOffset > 0 then
        local preHandle = C_Timer.NewTimer(preWarnOffset, function()
            if not combatActive[1] then return end
            dbg("Fire pre-warn: " .. ability.name)
            ns.BossWarnings.Show(ability.name .. " in 5 sec", 4)
        end)
        table.insert(activeTimers, preHandle)
    end

    -- Cast alert timer
    local castHandle = C_Timer.NewTimer(ability.first_cast, function()
        if not combatActive[1] then return end
        dbg("Fire cast: " .. ability.name .. ", next in " .. ability.cooldown .. "s")
        ns.BossWarnings.Show(ability.name, 3)

        -- Reschedule for next repeat using cooldown as the new first_cast
        scheduleAbility({
            name     = ability.name,
            spellID  = ability.spellID,
            first_cast = ability.cooldown,
            cooldown   = ability.cooldown,
        })
    end)
    table.insert(activeTimers, castHandle)

    -- Countdown timer bar (ShowTimer begins the bar immediately with full duration)
    timerCounter = timerCounter + 1
    local barId = "bar_" .. timerCounter
    ns.BossWarnings.ShowTimer(barId, ability.name, ability.first_cast, ability.spellID)
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
    dbg("Start: " .. pack.displayName .. " (" .. #pack.mobs .. " mobs)")

    for _, mob in ipairs(pack.mobs) do
        for _, ability in ipairs(mob.abilities) do
            scheduleAbility(ability)
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

    local ok, err = pcall(ns.BossWarnings.CancelAllTimers)
    if not ok then
        print("|cff00ccffTPW|r Warning: CancelAllTimers error: " .. tostring(err))
    end

    timerCounter = 0
end
