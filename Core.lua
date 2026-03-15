local addonName, ns = ...

-- Initialize PackDatabase at module scope so data files can populate it
-- during load time (before ADDON_LOADED fires)
ns.PackDatabase = ns.PackDatabase or {}

-- Event frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= addonName then return end

        -- Initialize SavedVariables
        if not TerriblePackWarningsDB then
            TerriblePackWarningsDB = {}
        end
        ns.db = TerriblePackWarningsDB

        print("|cff00ccffTerriblePackWarnings|r loaded. Type |cff00ff00/tpw|r to configure.")
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.CombatWatcher:OnCombatStart()

    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.CombatWatcher:OnCombatEnd()

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- NOTE: intentionally NOT unregistered — must fire on every zone change to reset state
        ns.CombatWatcher:Reset()
    end
end)

-- Slash command
-- /tpw select <dungeon>  — select a dungeon and reset to pack 1
-- /tpw start [pack#]     — manually start timers (optional pack index)
-- /tpw stop              — cancel all active timers
-- /tpw status            — print current state
SLASH_TERRIBLEPACKWARNINGS1 = "/tpw"
SlashCmdList["TERRIBLEPACKWARNINGS"] = function(msg)
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    if cmd == "select" then
        if arg == "" then
            print("|cff00ccffTPW|r Usage: /tpw select <dungeon_key>")
        else
            ns.CombatWatcher:SelectDungeon(arg)
        end
    elseif cmd == "start" then
        ns.CombatWatcher:ManualStart(tonumber(arg) or nil)
    elseif cmd == "stop" then
        ns.Scheduler:Stop()
    elseif cmd == "status" then
        local s, d, i = ns.CombatWatcher:GetState()
        print("|cff00ccffTPW|r State: " .. s
              .. ", Dungeon: " .. tostring(d)
              .. ", Pack: " .. tostring(i))
    elseif cmd == "help" then
        print("|cff00ccffTPW|r Commands: select <dungeon>, start [pack#], stop, status, help")
    else
        -- Bare /tpw or unrecognized command — toggle pack selection window
        if ns.PackUI and ns.PackUI.Toggle then ns.PackUI.Toggle() end
    end
end
