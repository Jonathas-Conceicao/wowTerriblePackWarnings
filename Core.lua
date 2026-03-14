local addonName, ns = ...

-- Initialize PackDatabase at module scope so data files can populate it
-- during load time (before ADDON_LOADED fires)
ns.PackDatabase = ns.PackDatabase or {}

-- Event frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

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

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Future: display initialization
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

-- Slash command
SLASH_TERRIBLEPACKWARNINGS1 = "/tpw"
SlashCmdList["TERRIBLEPACKWARNINGS"] = function(msg)
    -- Stub for Phase 3
end
