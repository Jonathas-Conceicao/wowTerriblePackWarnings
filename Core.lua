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

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= addonName then return end

        -- Initialize SavedVariables
        if not TerriblePackWarningsDB then
            TerriblePackWarningsDB = {}
        end
        ns.db = TerriblePackWarningsDB

        -- Restore imported route from SavedVariables
        if ns.Import and ns.Import.RestoreFromSaved then
            ns.Import.RestoreFromSaved()
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
        ns.NameplateScanner:Stop()
        ns.Scheduler:Stop()
        ns.IconDisplay.CancelAll()
        ns.CombatWatcher:OnCombatEnd()
    elseif cmd == "status" then
        local s, d, i = ns.CombatWatcher:GetState()
        print("|cff00ccffTPW|r State: " .. s
              .. ", Dungeon: " .. tostring(d)
              .. ", Pack: " .. tostring(i))
    elseif cmd == "show" then
        -- Debug: show a spell icon by spellID
        local spellID = tonumber(arg)
        if not spellID then
            print("|cff00ccffTPW|r Usage: /tpw show <spellID>")
        else
            -- Find ability in current pack data to get label/tts
            local label, tts
            for _, packs in pairs(ns.PackDatabase) do
                for _, pack in ipairs(packs) do
                    for _, ability in ipairs(pack.abilities) do
                        if ability.spellID == spellID then
                            label = ability.label
                            tts = ability.ttsMessage
                            break
                        end
                    end
                end
            end
            ns.IconDisplay.ShowIcon("debug_" .. spellID, spellID, tts, 30, label)
            print("|cff00ccffTPW|r Showing spell " .. spellID .. " for 30s")
        end
    elseif cmd == "decode" then
        if arg == "" then
            print("|cff00ccffTPW|r Usage: /tpw decode <MDT export string>")
        else
            local ok, result = ns.MDTDecode(arg)
            if ok then
                print("|cff00ccffTPW|r Decode OK. Type: " .. type(result))
                if type(result) == "table" then
                    -- Print basic info about decoded data
                    local count = 0
                    for _ in pairs(result) do count = count + 1 end
                    print("|cff00ccffTPW|r  Top-level keys: " .. count)
                end
            else
                print("|cff00ccffTPW|r Decode failed: " .. tostring(result))
            end
        end
    elseif cmd == "hide" then
        -- Debug: hide a spell icon by spellID
        local spellID = tonumber(arg)
        if not spellID then
            ns.IconDisplay.CancelAll()
            print("|cff00ccffTPW|r All icons cleared")
        else
            ns.IconDisplay.CancelIcon("debug_" .. spellID)
            print("|cff00ccffTPW|r Hidden spell " .. spellID)
        end
    elseif cmd == "import" then
        if arg == "" then
            print("|cff00ccffTPW|r Usage: /tpw import <MDT export string>")
        else
            ns.Import.RunFromString(arg)
        end
    elseif cmd == "clear" then
        ns.Import.Clear()
    elseif cmd == "help" then
        print("|cff00ccffTPW|r Commands: select <dungeon>, start [pack#], stop, status, import <string>, clear, decode <string>, help")
    else
        -- Bare /tpw or unrecognized command — toggle pack selection window
        if ns.PackUI and ns.PackUI.Toggle then ns.PackUI.Toggle() end
    end
end
