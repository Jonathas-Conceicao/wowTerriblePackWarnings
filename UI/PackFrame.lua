local addonName, ns = ...

-- Public API
ns.PackUI = {}
local PackUI = ns.PackUI

-- Human-readable dungeon display names
local DUNGEON_NAMES = {
    windrunner_spire = "Windrunner Spire",
}

------------------------------------------------------------------------
-- Main Frame
------------------------------------------------------------------------
local frame = CreateFrame("Frame", "TPWPackFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(300, 400)
frame:SetPoint("CENTER")
frame:Hide()

frame.TitleText:SetText("TerriblePackWarnings")

-- Escape to close
tinsert(UISpecialFrames, "TPWPackFrame")

-- Movable with position persistence
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if ns.db then
        ns.db.windowPos = { x = self:GetLeft(), y = self:GetTop() }
    end
end)

------------------------------------------------------------------------
-- Position Restore
------------------------------------------------------------------------
local function RestorePosition()
    local pos = ns.db and ns.db.windowPos
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    end
end

-- Expose for external calls
PackUI.RestorePosition = RestorePosition

------------------------------------------------------------------------
-- ScrollBox Tree List (Accordion)
------------------------------------------------------------------------
local ScrollBox = CreateFrame("Frame", nil, frame.Inset, "WowScrollBoxList")
ScrollBox:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -4)
ScrollBox:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -20, 4)

local ScrollBar = CreateFrame("EventFrame", nil, frame.Inset, "MinimalScrollBar")
ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT", 2, 0)
ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT", 2, 0)

local ScrollView = CreateScrollBoxListTreeListView()
ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)

------------------------------------------------------------------------
-- Element Initializer
------------------------------------------------------------------------
local function ElementInitializer(button, node)
    local data = node:GetData()
    if data.isDungeon then
        -- Dungeon header row
        button:SetText(data.displayName)
        button:GetFontString():SetTextColor(1, 0.82, 0) -- gold header text
        button:SetScript("OnClick", function()
            node:ToggleCollapsed()
            ScrollBox:Update()
        end)
    else
        -- Pack leaf row (no-op click placeholder for Plan 02)
        button:SetText("   " .. data.displayName)
        button:GetFontString():SetTextColor(1, 1, 1) -- white
        button:SetScript("OnClick", function() end)
    end
end

ScrollView:SetElementInitializer("UIPanelButtonTemplate", ElementInitializer)

------------------------------------------------------------------------
-- Data Population
------------------------------------------------------------------------
local DataProvider

local function PopulateList()
    DataProvider = CreateTreeDataProvider()
    for dungeonKey, packs in pairs(ns.PackDatabase) do
        local dungeonNode = DataProvider:Insert({
            isDungeon   = true,
            displayName = DUNGEON_NAMES[dungeonKey] or dungeonKey,
            key         = dungeonKey,
        })
        for i, pack in ipairs(packs) do
            dungeonNode:Insert({
                isDungeon   = false,
                displayName = pack.displayName,
                dungeonKey  = dungeonKey,
                packIndex   = i,
            })
        end
    end
    ScrollView:SetDataProvider(DataProvider)
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------
function PackUI.Toggle()
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function PackUI.Show()
    frame:Show()
end

function PackUI.Hide()
    frame:Hide()
end

-- Expose internals for Plan 02 (Refresh, selection highlight)
PackUI.ScrollBox = ScrollBox
PackUI.ScrollView = ScrollView
PackUI.GetDataProvider = function() return DataProvider end

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------
-- Data files load before UI in TOC, and Core.lua ADDON_LOADED sets ns.db
-- before PackFrame.lua file body executes, so both PackDatabase and db
-- are available at this point.
PopulateList()
RestorePosition()
