local addonName, ns = ...

-- Initialize PackDatabase at module scope so data files can populate it
-- during load time (before ADDON_LOADED fires)
ns.PackDatabase = ns.PackDatabase or {}
ns.AbilityDB = ns.AbilityDB or {}

-- Event frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= addonName then return end

        -- Initialize SavedVariables
        if not TerriblePackWarningsDB then
            TerriblePackWarningsDB = {}
        end
        ns.db = TerriblePackWarningsDB

        -- Schema migration: v0 -> v1 (per-dungeon route storage)
        if not ns.db.schemaVersion then
            if ns.db.importedRoute then
                local old = ns.db.importedRoute
                local dungeonInfo = old.dungeonIdx and ns.DUNGEON_IDX_MAP and ns.DUNGEON_IDX_MAP[old.dungeonIdx]
                if dungeonInfo then
                    ns.db.importedRoutes = ns.db.importedRoutes or {}
                    ns.db.importedRoutes[dungeonInfo.key] = old
                end
                ns.db.importedRoute = nil
            end
            ns.db.schemaVersion = 1
        end

        -- Schema migration: v1 -> v2 (profiles)
        if ns.db.schemaVersion == 1 then
            ns.db.profiles = { ["Default"] = {} }
            if ns.db.skillConfig and next(ns.db.skillConfig) then
                ns.db.profiles["Default"].skillConfig = ns.db.skillConfig
            else
                ns.db.profiles["Default"].skillConfig = {}
            end
            ns.db.skillConfig = nil
            ns.db.activeProfile = "Default"
            ns.db.schemaVersion = 2
        end

        -- Initialize fields for new installs (schemaVersion == 2 from fresh start)
        ns.db.profiles = ns.db.profiles or { ["Default"] = { skillConfig = {} } }
        ns.db.activeProfile = ns.db.activeProfile or "Default"
        if not ns.db.profiles["Default"] then
            ns.db.profiles["Default"] = { skillConfig = {} }
        end

        -- Initialize other SavedVariables fields
        ns.db.importedRoutes  = ns.db.importedRoutes or {}
        ns.db.combatMode      = ns.db.combatMode or "auto"

        -- Restore all imported routes from SavedVariables
        if ns.Import and ns.Import.RestoreAllFromSaved then
            ns.Import.RestoreAllFromSaved()
        end

        print("|cff00ccffTerriblePackWarnings|r loaded. Type |cff00ff00/tpw|r to configure.")
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.CombatWatcher:OnCombatStart()

    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.CombatWatcher:OnCombatEnd()

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- NOTE: intentionally NOT unregistered — must fire on every zone change to reset state
        ns.CombatWatcher:Reset()

    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unitToken = ...
        ns.NameplateScanner:OnNameplateAdded(unitToken)

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unitToken = ...
        ns.NameplateScanner:OnNameplateRemoved(unitToken)
    end
end)

-- Slash command
-- /tpw                   -- open config window (default)
-- /tpw config            -- open config window
-- /tpw route             -- open route window
-- /tpw select <dungeon>  -- select a dungeon and reset to pack 1
-- /tpw start [pack#]     -- manually start timers (optional pack index)
-- /tpw stop              -- cancel all active timers
-- /tpw status            -- print current state
-- /tpw debug             -- toggle debug logging (persists through /reload)
-- /tpw clear             -- clear imported route
-- /tpw help              -- print grouped command list
SLASH_TERRIBLEPACKWARNINGS1 = "/tpw"
SlashCmdList["TERRIBLEPACKWARNINGS"] = function(msg)
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""
    if cmd == "select" then
        if arg == "" then
            print("|cff00ccffTPW|r Usage: /tpw select <dungeon_key>")
        else
            ns.CombatWatcher:SelectDungeon(arg)
        end
    elseif cmd == "start" then
        ns.CombatWatcher:ManualStart(tonumber(arg) or nil)
    elseif cmd == "stop" then
        ns.NameplateScanner:Stop()
        ns.Scheduler:Stop()
        ns.IconDisplay.CancelAll()
        ns.CombatWatcher:OnCombatEnd()
    elseif cmd == "status" then
        local s, d, i = ns.CombatWatcher:GetState()
        print("|cff00ccffTPW|r State: " .. s
              .. ", Dungeon: " .. tostring(d)
              .. ", Pack: " .. tostring(i))
    elseif cmd == "debug" then
        -- Toggle debug logging (persists through /reload via SavedVariables)
        ns.db.debug = not ns.db.debug
        if ns.db.debug then
            print("|cff00ccffTPW|r Debug logging |cff00ff00ON|r")
        else
            print("|cff00ccffTPW|r Debug logging |cffff0000OFF|r")
        end
    elseif cmd == "clear" then
        local _, activeDungeon = ns.CombatWatcher:GetState()
        local clearKey = ns.db.selectedDungeon or activeDungeon
        ns.Import.Clear(clearKey)
    elseif cmd == "config" then
        if ns.ConfigUI and ns.ConfigUI.Toggle then ns.ConfigUI.Toggle() end
    elseif cmd == "route" then
        if ns.PackUI and ns.PackUI.Toggle then ns.PackUI.Toggle() end
    elseif cmd == "help" then
        local c = "|cff00ccffTPW|r"
        print(c .. " |cffffff00Windows:|r")
        print(c .. "  /tpw          - Open config window")
        print(c .. "  /tpw config   - Open config window")
        print(c .. "  /tpw route    - Open route window")
        print(c .. " |cffffff00Route:|r")
        print(c .. "  /tpw select <key> - Select dungeon")
        print(c .. "  /tpw start [#]    - Start timers (optional pack#)")
        print(c .. "  /tpw stop         - Cancel all timers")
        print(c .. "  /tpw clear        - Clear imported route")
        print(c .. " |cffffff00Debug:|r")
        print(c .. "  /tpw status   - Print current state")
        print(c .. "  /tpw debug    - Toggle debug logging")
    else
        -- Bare /tpw or unrecognized command — toggle config window
        if ns.ConfigUI and ns.ConfigUI.Toggle then ns.ConfigUI.Toggle() end
    end
end
