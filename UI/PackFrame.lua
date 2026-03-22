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
for _, enemies in pairs(ns.DungeonEnemies) do
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

-- Boss lookup: npcID -> true if isBoss flag in DungeonEnemies
local npcIdIsBoss = {}
for _, enemies in pairs(ns.DungeonEnemies) do
    for _, enemy in pairs(enemies) do
        if enemy.id and enemy.isBoss then
            npcIdIsBoss[enemy.id] = true
        end
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
-- Per-dungeon selection helpers
------------------------------------------------------------------------
local function GetSelectedDungeonKey()
    return ns.db and ns.db.selectedDungeon or nil
end

local function GetSelectedDungeonName()
    local key = GetSelectedDungeonKey()
    if not key then return nil end
    for _, info in pairs(ns.DUNGEON_IDX_MAP or {}) do
        if info.key == key then return info.name end
    end
    return key
end

------------------------------------------------------------------------
-- Clear Confirmation Dialog (StaticPopup)
------------------------------------------------------------------------
StaticPopupDialogs["TPW_CONFIRM_CLEAR"] = {
    text = "Clear imported route? This cannot be undone.",
    button1 = "Clear",
    button2 = "Cancel",
    OnAccept = function()
        local key = GetSelectedDungeonKey()
        if key then
            ns.Import.Clear(key)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

------------------------------------------------------------------------
-- Import Popup Frame (separate frame, NOT StaticPopup -- no 255 char limit)
------------------------------------------------------------------------
local importPopup = CreateFrame("Frame", "TPWImportPopup", UIParent, "BasicFrameTemplateWithInset")
importPopup:SetSize(320, 200)
importPopup:SetPoint("CENTER")
importPopup:Hide()
importPopup:SetFrameStrata("DIALOG")

importPopup.TitleText:SetText("Import MDT Route")

-- Escape to close
tinsert(UISpecialFrames, "TPWImportPopup")

-- Scroll frame inside popup for multi-line editbox
local popupScroll = CreateFrame("ScrollFrame", nil, importPopup, "UIPanelScrollFrameTemplate")
popupScroll:SetPoint("TOPLEFT", importPopup, "TOPLEFT", 12, -32)
popupScroll:SetPoint("BOTTOMRIGHT", importPopup, "BOTTOMRIGHT", -34, 40)

local editBox = CreateFrame("EditBox", nil, popupScroll)
editBox:SetMultiLine(true)
editBox:SetMaxLetters(0)
editBox:SetAutoFocus(false)
editBox:SetFontObject(ChatFontNormal)
editBox:SetWidth(popupScroll:GetWidth() or 260)
editBox:SetScript("OnEscapePressed", function() importPopup:Hide() end)
popupScroll:SetScrollChild(editBox)

importPopup:SetScript("OnShow", function()
    editBox:SetText("")
    editBox:SetFocus()
end)

-- Import button on popup
local popupImportBtn = CreateFrame("Button", nil, importPopup, "GameMenuButtonTemplate")
popupImportBtn:SetSize(80, 22)
popupImportBtn:SetPoint("BOTTOMRIGHT", importPopup, "BOTTOMRIGHT", -12, 8)
popupImportBtn:SetText("Import")
popupImportBtn:SetScript("OnClick", function()
    local str = editBox:GetText()
    if str and str ~= "" then
        ns.Import.RunFromString(str)
    end
    importPopup:Hide()
end)

-- Cancel button on popup
local popupCancelBtn = CreateFrame("Button", nil, importPopup, "GameMenuButtonTemplate")
popupCancelBtn:SetSize(80, 22)
popupCancelBtn:SetPoint("RIGHT", popupImportBtn, "LEFT", -8, 0)
popupCancelBtn:SetText("Cancel")
popupCancelBtn:SetScript("OnClick", function() importPopup:Hide() end)

------------------------------------------------------------------------
-- Dungeon Dropdown (singleton, built on first use)
------------------------------------------------------------------------
local dungeonDropdown = nil

local function BuildDungeonDropdown()
    dungeonDropdown = CreateFrame("Frame", "TPWDungeonDropdown", UIParent, "BasicFrameTemplateWithInset")
    dungeonDropdown:SetFrameStrata("DIALOG")
    dungeonDropdown:Hide()
    dungeonDropdown.TitleText:SetText("Select Dungeon")
    tinsert(UISpecialFrames, "TPWDungeonDropdown")

    -- Build sorted dungeon list from DUNGEON_IDX_MAP
    local dungeons = {}
    for _, info in pairs(ns.DUNGEON_IDX_MAP or {}) do
        table.insert(dungeons, { key = info.key, name = info.name })
    end
    table.sort(dungeons, function(a, b) return a.name < b.name end)

    local btnHeight = 22
    local padding = 32  -- top title bar
    local bottomPad = 8
    dungeonDropdown:SetSize(220, #dungeons * btnHeight + padding + bottomPad)

    for i, dungeon in ipairs(dungeons) do
        local btn = CreateFrame("Button", nil, dungeonDropdown, "GameMenuButtonTemplate")
        btn:SetSize(196, btnHeight)
        btn:SetPoint("TOPLEFT", dungeonDropdown, "TOPLEFT", 12, -(padding + (i - 1) * btnHeight))
        btn:SetText(dungeon.name)
        btn:SetScript("OnClick", function()
            ns.db.selectedDungeon = dungeon.key
            -- If this dungeon has packs loaded, select it in CombatWatcher
            if ns.PackDatabase[dungeon.key] and #ns.PackDatabase[dungeon.key] > 0 then
                ns.CombatWatcher:SelectDungeon(dungeon.key)
            end
            dungeonDropdown:Hide()
            if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
        end)
    end
end

local function ShowDungeonDropdown(anchorBtn)
    if not dungeonDropdown then BuildDungeonDropdown() end
    dungeonDropdown:ClearAllPoints()
    dungeonDropdown:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, 0)
    dungeonDropdown:Show()
end

------------------------------------------------------------------------
-- Main Frame
------------------------------------------------------------------------
local frame = CreateFrame("Frame", "TPWPackFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(300, 430)
frame:SetPoint("CENTER")
frame:Hide()

frame.TitleText:SetText("TerriblePackWarnings - Route")

-- Escape to close (re-register on every show to survive UISpecialFrames wipes)
tinsert(UISpecialFrames, "TPWPackFrame")
frame:SetScript("OnShow", function()
    -- Ensure we're in UISpecialFrames
    local found = false
    for _, name in ipairs(UISpecialFrames) do
        if name == "TPWPackFrame" then found = true break end
    end
    if not found then tinsert(UISpecialFrames, "TPWPackFrame") end
end)

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
-- Dungeon Selector Button (top of frame)
------------------------------------------------------------------------
local dungeonBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
dungeonBtn:SetSize(276, 22)
dungeonBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -26)
dungeonBtn:SetScript("OnClick", function(self) ShowDungeonDropdown(self) end)

------------------------------------------------------------------------
-- Header (pull count subtitle, anchored below dungeon button)
------------------------------------------------------------------------
local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header:SetPoint("TOPLEFT", dungeonBtn, "BOTTOMLEFT", 2, -4)
header:SetPoint("TOPRIGHT", dungeonBtn, "BOTTOMRIGHT", -2, -4)
header:SetJustifyH("LEFT")

local function UpdateHeader()
    local key = GetSelectedDungeonKey()
    local name = GetSelectedDungeonName()

    -- Update dungeon button text
    if name then
        dungeonBtn:SetText(name)
    else
        dungeonBtn:SetText("Select Dungeon...")
    end

    -- Update header subtitle (pull count)
    if key and ns.db.importedRoutes and ns.db.importedRoutes[key] then
        local route = ns.db.importedRoutes[key]
        local pullCount = route.packs and #route.packs or 0
        header:SetText(pullCount .. " pulls")
        header:SetTextColor(1, 0.82, 0)
    elseif key then
        header:SetText("No route imported. Click Import to add one.")
        header:SetTextColor(0.6, 0.6, 0.6)
    else
        header:SetText("Select a dungeon above")
        header:SetTextColor(0.6, 0.6, 0.6)
    end
end

------------------------------------------------------------------------
-- Scroll Frame (anchored below header, above footer button area)
------------------------------------------------------------------------
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -66)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 60)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(250)
scrollFrame:SetScrollChild(scrollChild)

------------------------------------------------------------------------
-- Footer Buttons (Import / Clear / Config)
------------------------------------------------------------------------
local importBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
importBtn:SetSize(80, 22)
importBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 8)
importBtn:SetText("Import")
importBtn:SetScript("OnClick", function() importPopup:Show() end)

local clearBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
clearBtn:SetSize(80, 22)
clearBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 8)
clearBtn:SetText("Clear")
clearBtn:SetScript("OnClick", function()
    local key = GetSelectedDungeonKey()
    if not key then return end
    local name = GetSelectedDungeonName() or key
    StaticPopupDialogs["TPW_CONFIRM_CLEAR"].text = "Clear route for " .. name .. "? This cannot be undone."
    StaticPopup_Show("TPW_CONFIRM_CLEAR")
end)

------------------------------------------------------------------------
-- Combat Mode Buttons (Auto / Manual / Disable)
------------------------------------------------------------------------
local modeButtons = {}

local function UpdateModeButtons()
    local current = ns.db and ns.db.combatMode or "auto"
    for _, btn in ipairs(modeButtons) do
        if btn.mode == current then
            btn:SetAlpha(1.0)
            if not btn.activeBg then
                btn.activeBg = btn:CreateTexture(nil, "BACKGROUND")
                btn.activeBg:SetAllPoints()
                btn.activeBg:SetColorTexture(0, 0.6, 0.8, 0.3)
            end
            btn.activeBg:Show()
        else
            btn:SetAlpha(0.5)
            if btn.activeBg then btn.activeBg:Hide() end
        end
    end
end

local function SetCombatMode(mode)
    if ns.db then ns.db.combatMode = mode end
    -- Disable: immediately stop all tracking and clear displays
    if mode == "disable" then
        if ns.NameplateScanner and ns.NameplateScanner.Stop then
            ns.NameplateScanner:Stop()
        end
        if ns.Scheduler and ns.Scheduler.Stop then
            ns.Scheduler:Stop()
        end
        if ns.IconDisplay and ns.IconDisplay.CancelNonPreviews then
            ns.IconDisplay.CancelNonPreviews()
        end
    end
    UpdateModeButtons()
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

-- Center the 3 mode buttons: total width = 3*80 + 2*4 = 248, frame = 300, padding = (300-248)/2 = 26
local modeDisable = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
modeDisable:SetSize(80, 22)
modeDisable:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 26, 33)
modeDisable:SetText("Disable")
modeDisable.mode = "disable"
modeDisable:SetScript("OnClick", function() SetCombatMode("disable") end)
table.insert(modeButtons, modeDisable)

local modeManual = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
modeManual:SetSize(80, 22)
modeManual:SetPoint("LEFT", modeDisable, "RIGHT", 4, 0)
modeManual:SetText("Manual")
modeManual.mode = "manual"
modeManual:SetScript("OnClick", function() SetCombatMode("manual") end)
table.insert(modeButtons, modeManual)

local modeAuto = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
modeAuto:SetSize(80, 22)
modeAuto:SetPoint("LEFT", modeManual, "RIGHT", 4, 0)
modeAuto:SetText("Auto")
modeAuto.mode = "auto"
modeAuto:SetScript("OnClick", function() SetCombatMode("auto") end)
table.insert(modeButtons, modeAuto)

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

    local selectedKey = GetSelectedDungeonKey()
    local packs = selectedKey and ns.PackDatabase[selectedKey] or nil
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
                -- Count overlay
                if not tex.countLabel then
                    tex.countLabel = row:CreateFontString(nil, "OVERLAY")
                    tex.countLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                    tex.countLabel:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 0, 0)
                    tex.countLabel:SetTextColor(1, 1, 1, 1)
                end
                local count = pack.mobCounts and pack.mobCounts[npcIDs[p]] or 1
                if count > 1 then
                    tex.countLabel:SetText("x" .. count)
                    tex.countLabel:Show()
                else
                    tex.countLabel:Hide()
                end

                -- Clickable overlay to open config for this mob (out of combat only)
                if not tex.clickOverlay then
                    tex.clickOverlay = CreateFrame("Button", nil, row)
                    tex.clickOverlay:SetAllPoints(tex)
                    tex.clickOverlay:SetFrameLevel(row:GetFrameLevel() + 2)
                    tex.clickOverlay:RegisterForClicks("LeftButtonUp")
                end
                local npcID_portrait = npcIDs[p]
                local routeData = selectedKey and ns.db.importedRoutes and ns.db.importedRoutes[selectedKey]
                local dungeonIdx_portrait = routeData and routeData.dungeonIdx
                tex.clickOverlay:SetScript("OnClick", function()
                    if InCombatLockdown() then return end
                    if ns.ConfigUI and ns.ConfigUI.OpenToMob and dungeonIdx_portrait then
                        ns.ConfigUI.OpenToMob(npcID_portrait, dungeonIdx_portrait)
                    end
                end)
                tex.clickOverlay:Show()
            else
                tex:Hide()
                if tex.countLabel then tex.countLabel:Hide() end
                if tex.clickOverlay then tex.clickOverlay:Hide() end
            end
        end

        -- Check if pack contains a boss
        local hasBoss = false
        for _, npcID in ipairs(npcIDs) do
            if npcIdIsBoss[npcID] then
                hasBoss = true
                break
            end
        end

        -- State coloring (combat state > boss > alternating)
        local sameDungeon = (activeDungeon == selectedKey)
        if sameDungeon and i == activePackIndex and curState == "active" then
            row.bg:SetColorTexture(1, 0.5, 0, 0.25)       -- orange: active/fighting
        elseif sameDungeon and i == activePackIndex then
            row.bg:SetColorTexture(0, 1, 0, 0.15)          -- green: selected
        elseif sameDungeon and activePackIndex and i < activePackIndex then
            row.bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)    -- grey: completed
        elseif hasBoss then
            row.bg:SetColorTexture(0.6, 0.2, 0.2, 0.3)    -- dark red: boss pull
        elseif i % 2 == 0 then
            row.bg:SetColorTexture(1, 1, 1, 0.05)          -- subtle alternating stripe
        else
            row.bg:SetColorTexture(0, 0, 0, 0)             -- transparent
        end

        -- Click to select pack
        local packIndex = i
        row:SetScript("OnClick", function()
            ns.CombatWatcher:SelectPack(selectedKey, packIndex)
            ns.PackUI:Refresh()
        end)

        row:Show()
        yOffset = yOffset + ROW_HEIGHT
    end

    scrollChild:SetHeight(math.max(yOffset, 1))

    -- Auto-scroll to center the active/selected pack (delay 1 frame for layout)
    C_Timer.After(0, function()
        local scrollTarget = nil
        if activeDungeon == selectedKey and activePackIndex then
            scrollTarget = activePackIndex
        end
        if scrollTarget and scrollTarget > 0 then
            local frameHeight = scrollFrame:GetHeight() or 0
            local maxScroll = scrollFrame:GetVerticalScrollRange() or 0
            local targetOffset = (scrollTarget - 1) * ROW_HEIGHT - (frameHeight / 2) + (ROW_HEIGHT / 2)
            targetOffset = math.max(0, math.min(targetOffset, maxScroll))
            scrollFrame:SetVerticalScroll(targetOffset)
        end
    end)
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

function PackUI:Refresh()
    UpdateHeader()
    PopulateList()
    UpdateModeButtons()
end

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------
UpdateHeader()
PopulateList()
RestorePosition()
UpdateModeButtons()
