local addonName, ns = ...

ns.CombatWatcher = {}
local CombatWatcher = ns.CombatWatcher

-- ============================================================
-- Zone-to-dungeon auto-detection
-- ============================================================

-- Maps instance name (from GetInstanceInfo()) to PackDatabase key
local ZONE_DUNGEON_MAP = {
    ["Windrunner Spire"] = "windrunner_spire",
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

    print("|cff00ccffTPW|r Selected: " .. dungeonKey .. " (" .. #dungeon .. " packs)")
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

    selectedDungeon  = dungeonKey
    currentPackIndex = packIndex
    state            = "ready"

    print("|cff00ccffTPW|r Selected: " .. dungeon[packIndex].displayName)
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
    if state ~= "active" then return end

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
        print("|cff00ccffTPW|r All packs completed.")
    else
        print("|cff00ccffTPW|r Next: " .. dungeon[currentPackIndex].displayName)
    end
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

function CombatWatcher:Reset()
    ns.NameplateScanner:Stop()
    ns.Scheduler:Stop()

    selectedDungeon  = nil
    currentPackIndex = nil
    state            = "idle"

    -- Auto-detect dungeon from current zone
    local instanceName = GetInstanceInfo()
    local dungeonKey = ZONE_DUNGEON_MAP[instanceName]
    if dungeonKey and ns.PackDatabase[dungeonKey] then
        selectedDungeon  = dungeonKey
        currentPackIndex = 1
        state            = "ready"
        print("|cff00ccffTPW|r Auto-detected: " .. instanceName .. " (" .. #ns.PackDatabase[dungeonKey] .. " packs)")
    else
        print("|cff00ccffTPW|r Session cleared (zone change).")
    end

    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

function CombatWatcher:GetState()
    return state, selectedDungeon, currentPackIndex
end
