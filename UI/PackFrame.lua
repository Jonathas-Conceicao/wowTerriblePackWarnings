local addonName, ns = ...

-- Public API
ns.PackUI = {}
local PackUI = ns.PackUI

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------
local ROW_HEIGHT = 28
local PORTRAIT_SIZE = 22
local MAX_PORTRAITS = 8

------------------------------------------------------------------------
-- Lookup Tables (built once at file scope)
------------------------------------------------------------------------
local npcIdToDisplayId = {}
for dungeonIdx, enemies in pairs(ns.DungeonEnemies) do
    for _, enemy in pairs(enemies) do
        if enemy.id and enemy.displayId then
            npcIdToDisplayId[enemy.id] = enemy.displayId
        end
    end
end

local npcIdToClass = {}
for npcID, entry in pairs(ns.AbilityDB or {}) do
    if entry.mobClass then
        npcIdToClass[npcID] = entry.mobClass
    end
end

local CLASS_ICON = {
    WARRIOR     = "Interface\\Icons\\ClassIcon_Warrior",
    PALADIN     = "Interface\\Icons\\ClassIcon_Paladin",
    HUNTER      = "Interface\\Icons\\ClassIcon_Hunter",
    ROGUE       = "Interface\\Icons\\ClassIcon_Rogue",
    PRIEST      = "Interface\\Icons\\ClassIcon_Priest",
    DEATHKNIGHT = "Interface\\Icons\\ClassIcon_DeathKnight",
    SHAMAN      = "Interface\\Icons\\ClassIcon_Shaman",
    MAGE        = "Interface\\Icons\\ClassIcon_Mage",
    WARLOCK     = "Interface\\Icons\\ClassIcon_Warlock",
    MONK        = "Interface\\Icons\\ClassIcon_Monk",
    DRUID       = "Interface\\Icons\\ClassIcon_Druid",
    DEMONHUNTER = "Interface\\Icons\\ClassIcon_DemonHunter",
    EVOKER      = "Interface\\Icons\\ClassIcon_Evoker",
}

--- Set the best available portrait for an NPC.
-- Fallback chain: creatureDisplayID -> class icon from AbilityDB -> question mark
local function GetPortraitTexture(tex, npcID)
    local displayId = npcIdToDisplayId[npcID]
    if displayId and displayId > 0 then
        SetPortraitTextureFromCreatureDisplayID(tex, displayId)
        return
    end
    -- Fallback: class icon from AbilityDB mobClass
    local mobClass = npcIdToClass[npcID]
    if mobClass and CLASS_ICON[mobClass] then
        tex:SetTexture(CLASS_ICON[mobClass])
        return
    end
    -- Last resort: question mark
    tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
end

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
-- Header (dungeon name + pull count)
------------------------------------------------------------------------
local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -28)
header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -28)
header:SetJustifyH("LEFT")

local function UpdateHeader()
    if ns.db and ns.db.importedRoute then
        local route = ns.db.importedRoute
        local pullCount = route.packs and #route.packs or 0
        header:SetText(route.dungeonName .. " -- " .. pullCount .. " pulls")
        header:SetTextColor(1, 0.82, 0)
    else
        header:SetText("No route imported")
        header:SetTextColor(0.6, 0.6, 0.6)
    end
end

------------------------------------------------------------------------
-- Scroll Frame (anchored below header, above footer button area)
------------------------------------------------------------------------
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -46)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 35)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(250)
scrollFrame:SetScrollChild(scrollChild)

------------------------------------------------------------------------
-- Pull Row Creation
------------------------------------------------------------------------
local rows = {}

local function CreatePullRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    -- Background for state coloring
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    -- Hover highlight
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.1)

    -- Pull number label
    row.pullNum = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.pullNum:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.pullNum:SetWidth(20)
    row.pullNum:SetJustifyH("CENTER")

    -- Portrait textures (circular masked)
    row.portraits = {}
    for i = 1, MAX_PORTRAITS do
        local tex = row:CreateTexture(nil, "ARTWORK")
        tex:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
        if i == 1 then
            tex:SetPoint("LEFT", row.pullNum, "RIGHT", 4, 0)
        else
            tex:SetPoint("LEFT", row.portraits[i - 1], "RIGHT", 2, 0)
        end
        tex:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        tex:Hide()
        row.portraits[i] = tex
    end

    return row
end

------------------------------------------------------------------------
-- List Population
------------------------------------------------------------------------
local function PopulateList()
    -- Hide all existing rows
    for _, row in ipairs(rows) do
        row:Hide()
    end

    local packs = ns.PackDatabase["imported"]
    if not packs then
        scrollChild:SetHeight(1)
        return
    end

    local curState, activeDungeon, activePackIndex = ns.CombatWatcher:GetState()
    local yOffset = 0

    for i, pack in ipairs(packs) do
        local row = rows[i]
        if not row then
            row = CreatePullRow(scrollChild)
            rows[i] = row
        end

        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)

        -- Pull number
        row.pullNum:SetText(tostring(i))

        -- Populate portraits from pack.npcIDs
        local npcIDs = pack.npcIDs or {}
        for p = 1, MAX_PORTRAITS do
            local tex = row.portraits[p]
            if p <= #npcIDs then
                GetPortraitTexture(tex, npcIDs[p])
                tex:Show()
            else
                tex:Hide()
            end
        end

        -- State coloring
        local sameDungeon = (activeDungeon == "imported")
        if sameDungeon and i == activePackIndex and curState == "active" then
            row.bg:SetColorTexture(1, 0.5, 0, 0.25)       -- orange: active/fighting
        elseif sameDungeon and i == activePackIndex then
            row.bg:SetColorTexture(0, 1, 0, 0.15)          -- green: selected
        elseif sameDungeon and activePackIndex and i < activePackIndex then
            row.bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)    -- grey: completed
        else
            row.bg:SetColorTexture(0, 0, 0, 0)             -- transparent
        end

        -- Click to select pack
        local packIndex = i
        row:SetScript("OnClick", function()
            ns.CombatWatcher:SelectPack("imported", packIndex)
            ns.PackUI:Refresh()
        end)

        row:Show()
        yOffset = yOffset + ROW_HEIGHT
    end

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
    UpdateHeader()
    PopulateList()
end

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------
UpdateHeader()
PopulateList()
RestorePosition()
