local addonName, ns = ...

ns.CombatWatcher = {}
local CombatWatcher = ns.CombatWatcher

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
end

function CombatWatcher:ManualStart(packIndex)
    if not selectedDungeon then
        print("|cff00ccffTPW|r Error: no dungeon selected. Use /tpw select <dungeon>")
        return
    end

    if packIndex then
        currentPackIndex = packIndex
    end

    ns.Scheduler:Start(selectedDungeon, currentPackIndex)
    state = "active"
end

function CombatWatcher:OnCombatStart()
    -- Guard: only trigger from ready state to prevent double-starts and end-state triggers
    if state ~= "ready" then return end

    ns.Scheduler:Start(selectedDungeon, currentPackIndex)
    state = "active"
end

function CombatWatcher:OnCombatEnd()
    if state ~= "active" then return end

    ns.Scheduler:Stop()

    -- Auto-advance to next pack
    currentPackIndex = currentPackIndex + 1

    local dungeon = ns.PackDatabase[selectedDungeon]
    if currentPackIndex > #dungeon then
        state = "end"
        print("|cff00ccffTPW|r All packs completed.")
    else
        state = "ready"
        print("|cff00ccffTPW|r Next: " .. dungeon[currentPackIndex].displayName)
    end
end

function CombatWatcher:Reset()
    ns.Scheduler:Stop()

    if selectedDungeon and ns.PackDatabase[selectedDungeon] then
        currentPackIndex = 1
        state            = "ready"
        print("|cff00ccffTPW|r Reset to pack 1")
    else
        state = "idle"
    end
end

function CombatWatcher:GetState()
    return state, selectedDungeon, currentPackIndex
end
