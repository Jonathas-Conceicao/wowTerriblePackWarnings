local addonName, ns = ...

-- Public API
ns.PackUI = {}
local PackUI = ns.PackUI

-- Human-readable dungeon display names
local DUNGEON_NAMES = {
    windrunner_spire = "Windrunner Spire",
    imported = "Imported Route",
}

-- Accordion state: which dungeons are expanded
local expandedDungeons = {}

-- Row pool
local rows = {}
local ROW_HEIGHT = 22
local HEADER_INDENT = 8
local PACK_INDENT = 24

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
-- Scroll Frame (simple scroll child approach)
------------------------------------------------------------------------
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 10)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(250)
scrollFrame:SetScrollChild(scrollChild)

------------------------------------------------------------------------
-- Row Creation
------------------------------------------------------------------------
local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    -- Hover highlight
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.1)

    -- Text label
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")

    return row
end

------------------------------------------------------------------------
-- Row Appearance (state-based styling)
------------------------------------------------------------------------
local function UpdateRowAppearance(row, data)
    local curState, activeDungeon, activePackIndex = ns.CombatWatcher:GetState()
    local sameDungeon = (data.dungeonKey == activeDungeon)

    local prefix = "   "
    local r, g, b = 1, 1, 1

    if sameDungeon and data.packIndex == activePackIndex and curState == "active" then
        -- Active / fighting
        prefix = "   |TInterface\\LFGFrame\\BattlenetWorking0:14|t "
        r, g, b = 1, 0.5, 0
    elseif sameDungeon and data.packIndex == activePackIndex and (curState == "ready" or curState == "end") then
        -- Selected / ready
        prefix = "   |TInterface\\Buttons\\UI-CheckBox-Check:14|t "
        r, g, b = 0, 1, 0
    elseif sameDungeon and activePackIndex and data.packIndex < activePackIndex then
        -- Completed
        prefix = "   |TInterface\\Buttons\\UI-CheckBox-Check:14|t "
        r, g, b = 0.5, 0.5, 0.5
    end

    row.text:SetText(prefix .. data.displayName)
    row.text:SetTextColor(r, g, b)
end

------------------------------------------------------------------------
-- List Population
------------------------------------------------------------------------
local function PopulateList()
    -- Hide all existing rows
    for _, row in ipairs(rows) do
        row:Hide()
    end

    local yOffset = 0
    local rowIndex = 0

    for dungeonKey, packs in pairs(ns.PackDatabase) do
        -- Dungeon header row
        rowIndex = rowIndex + 1
        local headerRow = rows[rowIndex]
        if not headerRow then
            headerRow = CreateRow(scrollChild, rowIndex)
            rows[rowIndex] = headerRow
        end

        headerRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", HEADER_INDENT, -yOffset)
        headerRow:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -HEADER_INDENT, -yOffset)

        local displayName = DUNGEON_NAMES[dungeonKey] or dungeonKey
        local isExpanded = expandedDungeons[dungeonKey]
        local arrow = isExpanded and "|TInterface\\Buttons\\UI-MinusButton-UP:14|t " or "|TInterface\\Buttons\\UI-PlusButton-UP:14|t "

        -- Color active dungeon gold
        local _, activeDungeon = ns.CombatWatcher:GetState()
        if dungeonKey == activeDungeon then
            headerRow.text:SetText(arrow .. displayName)
            headerRow.text:SetTextColor(1, 0.82, 0)
        else
            headerRow.text:SetText(arrow .. displayName)
            headerRow.text:SetTextColor(1, 1, 1)
        end

        headerRow:SetScript("OnClick", function()
            expandedDungeons[dungeonKey] = not expandedDungeons[dungeonKey]
            PopulateList()
        end)
        headerRow:Show()
        yOffset = yOffset + ROW_HEIGHT

        -- Pack rows (if expanded)
        if isExpanded then
            for i, pack in ipairs(packs) do
                rowIndex = rowIndex + 1
                local packRow = rows[rowIndex]
                if not packRow then
                    packRow = CreateRow(scrollChild, rowIndex)
                    rows[rowIndex] = packRow
                end

                packRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", PACK_INDENT, -yOffset)
                packRow:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -HEADER_INDENT, -yOffset)

                local data = {
                    dungeonKey  = dungeonKey,
                    packIndex   = i,
                    displayName = pack.displayName,
                }
                UpdateRowAppearance(packRow, data)

                packRow:SetScript("OnClick", function()
                    ns.CombatWatcher:SelectPack(dungeonKey, i)
                end)
                packRow:Show()
                yOffset = yOffset + ROW_HEIGHT
            end
        end
    end

    -- Set scroll child height
    scrollChild:SetHeight(math.max(yOffset, 1))
end

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
    -- Auto-expand newly added dungeon keys (e.g. imported route on restore)
    for dungeonKey in pairs(ns.PackDatabase) do
        if expandedDungeons[dungeonKey] == nil then
            expandedDungeons[dungeonKey] = true
        end
    end
    PopulateList()
end

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------
-- Expand all dungeons by default
for dungeonKey in pairs(ns.PackDatabase) do
    expandedDungeons[dungeonKey] = true
end

PopulateList()
RestorePosition()
