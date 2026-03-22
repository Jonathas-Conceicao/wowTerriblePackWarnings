local addonName, ns = ...

ns.CombatWatcher = {}
local CombatWatcher = ns.CombatWatcher

-- ============================================================
-- Zone-to-dungeon auto-detection
-- ============================================================

-- Maps instance name (from GetInstanceInfo()) to PackDatabase key.
-- NOTE: Names with punctuation (apostrophes, colons) are best-guess estimates.
-- Verify exact strings in-game via debug logging (/tpw debug then zone in).
local ZONE_DUNGEON_MAP = {
    ["Windrunner Spire"]        = "windrunner_spire",
    ["Algethar Academy"]        = "algethar_academy",
    ["Pit of Saron"]            = "pit_of_saron",
    ["Skyreach"]                = "skyreach",
    ["Magisters' Terrace"]      = "magisters_terrace",
    ["Maisara Caverns"]         = "maisara_caverns",
    ["Nexus Point: Xenas"]      = "nexus_point_xenas",
    ["Seat of the Triumvirate"] = "seat_of_the_triumvirate",
}

-- ============================================================
-- State
-- ============================================================

local selectedDungeon  = nil  -- dungeon key string, e.g. "windrunner_spire"
local currentPackIndex = nil  -- 1-based index into the dungeon's pack array
local state            = "idle"
-- States:
--   idle   : No dungeon selected. Combat events do nothing.
--   ready  : Dungeon selected, waiting for combat pull.
--   active : Timers are running. Combat-end stops timers and advances.
--   end    : All packs exhausted. Combat events do nothing.

-- ============================================================
-- Public API
-- ============================================================

function CombatWatcher:SelectDungeon(dungeonKey)
    local dungeon = ns.PackDatabase[dungeonKey]
    if not dungeon or #dungeon == 0 then
        print("|cff00ccffTPW|r Error: unknown dungeon key '" .. tostring(dungeonKey) .. "'")
        return
    end

    selectedDungeon  = dungeonKey
    currentPackIndex = 1
    state            = "ready"

    if ns.db and ns.db.debug then
        print("|cff00ccffTPW|r Selected: " .. dungeonKey .. " (" .. #dungeon .. " packs)")
    end
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

function CombatWatcher:SelectPack(dungeonKey, packIndex)
    local dungeon = ns.PackDatabase[dungeonKey]
    if not dungeon or #dungeon == 0 then
        print("|cff00ccffTPW|r Error: unknown dungeon key '" .. tostring(dungeonKey) .. "'")
        return
    end
    if not packIndex or packIndex < 1 or packIndex > #dungeon then
        print("|cff00ccffTPW|r Error: invalid pack index " .. tostring(packIndex))
        return
    end

    -- Stop any active scanner/timers for the previous pack
    ns.NameplateScanner:Stop()
    ns.Scheduler:Stop()

    selectedDungeon  = dungeonKey
    currentPackIndex = packIndex

    -- If already in combat, start scanning for the new pack immediately
    if UnitAffectingCombat("player") then
        local pack = dungeon[packIndex]
        if pack then
            ns.NameplateScanner:Start(pack)
        end
        state = "active"
    else
        state = "ready"
    end

    if ns.db and ns.db.debug then
        print("|cff00ccffTPW|r Selected: " .. dungeon[packIndex].displayName .. " (" .. state .. ")")
    end
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

function CombatWatcher:ManualStart(packIndex)
    if not selectedDungeon then
        print("|cff00ccffTPW|r Error: no dungeon selected. Use /tpw select <dungeon>")
        return
    end

    if packIndex then
        currentPackIndex = packIndex
    end

    local dungeon = ns.PackDatabase[selectedDungeon]
    local pack = dungeon and dungeon[currentPackIndex]
    if not pack then return end

    ns.NameplateScanner:Start(pack)
    state = "active"
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

function CombatWatcher:OnCombatStart()
    local mode = ns.db and ns.db.combatMode or "auto"
    if mode == "disable" then return end
    -- Guard: only trigger from ready state to prevent double-starts and end-state triggers
    if state ~= "ready" then return end

    local dungeon = ns.PackDatabase[selectedDungeon]
    local pack = dungeon and dungeon[currentPackIndex]
    if not pack then return end

    ns.NameplateScanner:Start(pack)
    state = "active"
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

function CombatWatcher:OnCombatEnd()
    local mode = ns.db and ns.db.combatMode or "auto"
    if mode == "disable" then return end
    if state ~= "active" then return end

    -- Manual mode: stop scanning but do NOT advance to next pack
    if mode == "manual" then
        ns.NameplateScanner:Stop()
        ns.Scheduler:Stop()
        state = "ready"
        if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
        return
    end

    -- Auto mode: advance to next pack (existing behavior)
    -- Transition state BEFORE Stop() to prevent re-triggering on error
    local dungeon = ns.PackDatabase[selectedDungeon]
    local nextIndex = currentPackIndex + 1

    if nextIndex > #dungeon then
        state = "end"
        currentPackIndex = nextIndex
    else
        state = "ready"
        currentPackIndex = nextIndex
    end

    -- Scanner must stop before Scheduler to clean up per-mob state first
    ns.NameplateScanner:Stop()
    ns.Scheduler:Stop()

    if state == "end" then
        if ns.db and ns.db.debug then print("|cff00ccffTPW|r All packs completed.") end
    else
        if ns.db and ns.db.debug then print("|cff00ccffTPW|r Next: " .. dungeon[currentPackIndex].displayName) end
    end
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

function CombatWatcher:Reset()
    ns.NameplateScanner:Stop()
    ns.Scheduler:Stop()

    local instanceName = select(1, GetInstanceInfo())
    local dungeonKey   = ZONE_DUNGEON_MAP[instanceName]

    if ns.db and ns.db.debug then
        print("|cff00ccffTPW|r Zone: " .. tostring(instanceName) .. " -> " .. tostring(dungeonKey))
    end

    if dungeonKey then
        -- Known S1 dungeon zone — auto-switch to it
        ns.db.selectedDungeon = dungeonKey
        if ns.PackDatabase[dungeonKey] and #ns.PackDatabase[dungeonKey] > 0 then
            selectedDungeon  = dungeonKey
            currentPackIndex = 1
            state            = "ready"
        else
            selectedDungeon  = nil
            currentPackIndex = nil
            state            = "idle"
            print("|cff00ccffTPW|r No route for " .. instanceName .. ". Import one with /tpw")
        end
    else
        -- Not an S1 dungeon zone — auto-disable tracking
        ns.db.combatMode = "disable"
        if ns.IconDisplay and ns.IconDisplay.CancelNonPreviews then
            ns.IconDisplay.CancelNonPreviews()
        end
        selectedDungeon  = nil
        currentPackIndex = nil
        state            = "idle"
    end

    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

function CombatWatcher:GetState()
    return state, selectedDungeon, currentPackIndex
end
