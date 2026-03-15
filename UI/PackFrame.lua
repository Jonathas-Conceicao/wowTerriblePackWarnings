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
-- Row Appearance (state-based styling)
------------------------------------------------------------------------
local function UpdateRowAppearance(button, data)
    local curState, activeDungeon, activePackIndex = ns.CombatWatcher:GetState()
    local sameDungeon = (data.dungeonKey == activeDungeon)

    if sameDungeon and data.packIndex == activePackIndex and curState == "active" then
        -- Active / fighting
        button:SetText("   |TInterface\\LFGFrame\\BattlenetWorking0:16|t " .. data.displayName)
        button:GetFontString():SetTextColor(1, 0.5, 0)
    elseif sameDungeon and data.packIndex == activePackIndex and (curState == "ready" or curState == "end") then
        -- Selected / ready (or end-state on final pack)
        button:SetText("   |TInterface\\Buttons\\UI-CheckBox-Check:16|t " .. data.displayName)
        button:GetFontString():SetTextColor(0, 1, 0)
    elseif sameDungeon and activePackIndex and data.packIndex < activePackIndex then
        -- Completed (earlier pack in same dungeon)
        button:SetText("   |TInterface\\Buttons\\UI-CheckBox-Check:16|t " .. data.displayName)
        button:GetFontString():SetTextColor(0.5, 0.5, 0.5)
    else
        -- Default
        button:SetText("   " .. data.displayName)
        button:GetFontString():SetTextColor(1, 1, 1)
    end
end

------------------------------------------------------------------------
-- Element Initializer
------------------------------------------------------------------------
local function ElementInitializer(button, node)
    local data = node:GetData()
    if data.isDungeon then
        -- Dungeon header row: highlight active dungeon in gold, others white
        local _, activeDungeon = ns.CombatWatcher:GetState()
        button:SetText(data.displayName)
        if data.key == activeDungeon then
            button:GetFontString():SetTextColor(1, 0.82, 0) -- gold
        else
            button:GetFontString():SetTextColor(1, 1, 1) -- white
        end
        button:SetScript("OnClick", function()
            node:ToggleCollapsed()
            ScrollBox:Update()
        end)
    else
        -- Pack leaf row: click selects pack
        UpdateRowAppearance(button, data)
        button:SetScript("OnClick", function()
            ns.CombatWatcher:SelectPack(data.dungeonKey, data.packIndex)
        end)
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

function PackUI:Refresh()
    PopulateList()
end

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------
-- Data files load before UI in TOC, and Core.lua ADDON_LOADED sets ns.db
-- before PackFrame.lua file body executes, so both PackDatabase and db
-- are available at this point.
PopulateList()
RestorePosition()
