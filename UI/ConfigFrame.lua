local addonName, ns = ...

-- Public API
ns.ConfigUI = {}

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
-- Fallback chain: creatureDisplayID -> class icon -> question mark
local function GetPortraitTexture(tex, npcID)
    local displayId = npcIdToDisplayId[npcID]
    if displayId and displayId > 0 then
        SetPortraitTextureFromCreatureDisplayID(tex, displayId)
        return
    end
    local mobClass = npcIdToClass[npcID]
    if mobClass and CLASS_ICON[mobClass] then
        tex:SetTexture(CLASS_ICON[mobClass])
        return
    end
    tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
end

------------------------------------------------------------------------
-- Module-level state
------------------------------------------------------------------------
local configFrame = nil
local leftScrollFrame, leftScrollChild
local rightScrollFrame, rightScrollChild
local rightPanelHeader
local rightPanelRows = {}
local nodes = {}          -- dungeon tree nodes
local selectedNpcID = nil
local selectedDungeonIdx = nil
local PORTRAIT_SIZE = 22

-- Collapse indicators (UTF-8 byte sequences)
local ICON_COLLAPSED = "\226\150\186 "  -- Unicode ►
local ICON_EXPANDED  = "\226\150\188 "  -- Unicode ▼

------------------------------------------------------------------------
-- Sound popup (singleton, built on first use)
------------------------------------------------------------------------
local soundPopup = nil

local function BuildSoundPopup()
    soundPopup = CreateFrame("Frame", "TPWSoundPopup", UIParent, "BasicFrameTemplateWithInset")
    soundPopup:SetSize(200, 300)
    soundPopup:Hide()
    soundPopup:SetFrameStrata("DIALOG")
    soundPopup.TitleText:SetText("Select Sound")
    tinsert(UISpecialFrames, "TPWSoundPopup")

    local spScroll = CreateFrame("ScrollFrame", nil, soundPopup, "UIPanelScrollFrameTemplate")
    spScroll:SetPoint("TOPLEFT", soundPopup, "TOPLEFT", 12, -28)
    spScroll:SetPoint("BOTTOMRIGHT", soundPopup, "BOTTOMRIGHT", -34, 8)
    local spChild = CreateFrame("Frame", nil, spScroll)
    spChild:SetWidth(150)
    spScroll:SetScrollChild(spChild)

    soundPopup.scrollChild = spChild
    soundPopup.buttons = {}
end

local function ShowSoundPopup(anchorBtn, npcID, spellID, soundBtn, ttsEditBox)
    if not soundPopup then BuildSoundPopup() end

    local spChild = soundPopup.scrollChild

    -- Hide all existing buttons
    for _, btn in ipairs(soundPopup.buttons) do
        btn:Hide()
    end

    -- For each sound entry, reuse or create a button
    local yOffset = 0
    for i, entry in ipairs(ns.AlertSounds) do
        local btn = soundPopup.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, spChild)
            btn:SetHeight(20)
            btn:SetNormalFontObject(GameFontNormal)
            btn:SetHighlightFontObject(GameFontHighlight)
            local hlTex = btn:CreateTexture(nil, "HIGHLIGHT")
            hlTex:SetAllPoints()
            hlTex:SetColorTexture(1, 1, 1, 0.1)
            soundPopup.buttons[i] = btn
        end

        -- Capture locals for the closure
        local soundKitID = entry.soundKitID
        local soundName  = entry.name

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", spChild, "TOPLEFT", 4, -yOffset)
        btn:SetPoint("TOPRIGHT", spChild, "TOPRIGHT", -4, -yOffset)
        btn:SetText(soundName)
        btn:Show()

        btn:SetScript("OnClick", function()
            -- Write config
            ns.db.skillConfig[npcID] = ns.db.skillConfig[npcID] or {}
            ns.db.skillConfig[npcID][spellID] = ns.db.skillConfig[npcID][spellID] or {}
            ns.db.skillConfig[npcID][spellID].soundKitID = soundKitID

            -- Preview + TTS EditBox coupling
            if soundKitID then
                PlaySound(soundKitID)
                ttsEditBox:Disable()
                ttsEditBox:SetAlpha(0.4)
            else
                -- TTS selected
                ttsEditBox:Enable()
                ttsEditBox:SetAlpha(1.0)
            end

            soundBtn:SetText(soundName)
            soundPopup:Hide()
        end)

        yOffset = yOffset + 20
    end

    spChild:SetHeight(math.max(yOffset, 1))

    soundPopup:ClearAllPoints()
    soundPopup:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, 0)
    soundPopup:Show()
end

------------------------------------------------------------------------
-- BuildDungeonIndex: sorted list of dungeons with their mobs
------------------------------------------------------------------------
local function BuildDungeonIndex()
    local result = {}

    for dungeonIdx, info in pairs(ns.DUNGEON_IDX_MAP) do
        local enemies = ns.DungeonEnemies[dungeonIdx]
        if enemies then
            local seen = {}
            local mobs = {}
            for _, enemy in pairs(enemies) do
                if enemy.id and ns.AbilityDB[enemy.id] and not seen[enemy.id] then
                    seen[enemy.id] = true
                    table.insert(mobs, { npcID = enemy.id, name = enemy.name or ("NPC " .. enemy.id) })
                end
            end

            if #mobs > 0 then
                -- Sort mobs alphabetically by name
                table.sort(mobs, function(a, b) return a.name < b.name end)
                table.insert(result, {
                    dungeonIdx  = dungeonIdx,
                    dungeonName = info.name,
                    mobs        = mobs,
                })
            end
        end
    end

    -- Sort dungeons alphabetically by name
    table.sort(result, function(a, b) return a.dungeonName < b.dungeonName end)

    return result
end

------------------------------------------------------------------------
-- RebuildLayout: reposition all tree nodes top-to-bottom
------------------------------------------------------------------------
local function RebuildLayout()
    local yOffset = 0
    for _, node in ipairs(nodes) do
        node.header:ClearAllPoints()
        node.header:SetPoint("TOPLEFT",  leftScrollChild, "TOPLEFT",  0, -yOffset)
        node.header:SetPoint("TOPRIGHT", leftScrollChild, "TOPRIGHT", 0, -yOffset)
        yOffset = yOffset + node.header:GetHeight()

        if node.expanded and node.content then
            node.content:ClearAllPoints()
            node.content:SetPoint("TOPLEFT",  leftScrollChild, "TOPLEFT",  0, -yOffset)
            node.content:SetPoint("TOPRIGHT", leftScrollChild, "TOPRIGHT", 0, -yOffset)
            node.content:SetHeight(node.contentHeight)
            node.content:Show()
            yOffset = yOffset + node.contentHeight
        elseif node.content then
            node.content:Hide()
        end
    end

    leftScrollChild:SetHeight(math.max(yOffset, 1))
    leftScrollFrame:UpdateScrollChildRect()
end

------------------------------------------------------------------------
-- PopulateRightPanel: show abilities for selected mob
-- (stub in Task 1 — full implementation in Task 2)
------------------------------------------------------------------------
local function PopulateRightPanel(npcID)
    -- Hide all existing rightPanelRows
    for _, row in ipairs(rightPanelRows) do
        row:Hide()
    end

    local entry = ns.AbilityDB[npcID]
    if not entry then
        rightPanelHeader:SetText("No ability data for NPC " .. tostring(npcID))
        return
    end

    -- Find mob name from DungeonEnemies
    local mobName = "NPC " .. npcID
    for _, enemies in pairs(ns.DungeonEnemies) do
        for _, enemy in pairs(enemies) do
            if enemy.id == npcID and enemy.name then
                mobName = enemy.name
                break
            end
        end
    end

    local mobClass = entry.mobClass or "UNKNOWN"
    rightPanelHeader:SetText(mobName .. " \226\128\148 " .. mobClass)

    -- Full skill rows are built in Task 2; for now show default text
    rightScrollChild:SetHeight(1)
    rightScrollFrame:UpdateScrollChildRect()
end

------------------------------------------------------------------------
-- BuildLeftPanel: create left scroll area with dungeon-mob tree
------------------------------------------------------------------------
local function BuildLeftPanel(parent)
    leftScrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    leftScrollFrame:SetPoint("TOPLEFT",     parent, "TOPLEFT",     12, -32)
    leftScrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT",  220 - 34, 8)

    leftScrollChild = CreateFrame("Frame", nil, leftScrollFrame)
    leftScrollChild:SetWidth(200)
    leftScrollFrame:SetScrollChild(leftScrollChild)

    local dungeonList = BuildDungeonIndex()

    if #dungeonList == 0 then
        local emptyLabel = leftScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyLabel:SetPoint("CENTER", leftScrollChild, "CENTER", 0, 0)
        emptyLabel:SetText("No ability data loaded.")
        leftScrollChild:SetHeight(40)
        return
    end

    nodes = {}

    for _, dungeonEntry in ipairs(dungeonList) do
        local dungeonIdx   = dungeonEntry.dungeonIdx
        local dungeonName  = dungeonEntry.dungeonName
        local mobList      = dungeonEntry.mobs

        -- Dungeon header button
        local header = CreateFrame("Button", nil, leftScrollChild)
        header:SetHeight(24)
        header:SetNormalFontObject(GameFontNormal)
        header:SetHighlightFontObject(GameFontHighlight)

        local hlTex = header:CreateTexture(nil, "HIGHLIGHT")
        hlTex:SetAllPoints()
        hlTex:SetColorTexture(1, 1, 1, 0.1)

        -- Content frame for mob rows
        local content = CreateFrame("Frame", nil, leftScrollChild)
        content:Hide()

        local contentHeight = #mobList * 26

        -- Build mob rows inside content
        for i, mob in ipairs(mobList) do
            local mobRow = CreateFrame("Button", nil, content)
            mobRow:SetHeight(26)
            mobRow:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -(i - 1) * 26)
            mobRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(i - 1) * 26)

            -- Portrait
            local portrait = mobRow:CreateTexture(nil, "ARTWORK")
            portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
            portrait:SetPoint("LEFT", mobRow, "LEFT", 4, 0)
            portrait:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
            GetPortraitTexture(portrait, mob.npcID)

            -- Mob name
            local nameStr = mobRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameStr:SetPoint("LEFT", portrait, "RIGHT", 4, 0)
            nameStr:SetPoint("RIGHT", mobRow, "RIGHT", -4, 0)
            nameStr:SetJustifyH("LEFT")
            nameStr:SetText(mob.name)

            -- Hover highlight
            local rowHL = mobRow:CreateTexture(nil, "HIGHLIGHT")
            rowHL:SetAllPoints()
            rowHL:SetColorTexture(1, 1, 1, 0.1)

            -- Click handler
            local npcID_local     = mob.npcID
            local dungeonIdx_local = dungeonIdx
            mobRow:SetScript("OnClick", function()
                selectedNpcID      = npcID_local
                selectedDungeonIdx = dungeonIdx_local
                PopulateRightPanel(npcID_local)
            end)
        end

        content:SetHeight(contentHeight)

        -- Node table entry
        local node = {
            header        = header,
            content       = content,
            contentHeight = contentHeight,
            expanded      = false,
        }
        table.insert(nodes, node)

        -- Header text and click
        header:SetText(ICON_COLLAPSED .. dungeonName)
        header:SetScript("OnClick", function()
            node.expanded = not node.expanded
            if node.expanded then
                header:SetText(ICON_EXPANDED .. dungeonName)
            else
                header:SetText(ICON_COLLAPSED .. dungeonName)
            end
            RebuildLayout()
        end)
    end

    RebuildLayout()
end

------------------------------------------------------------------------
-- BuildConfigFrame: lazy-constructed on first Toggle()
------------------------------------------------------------------------
local function BuildConfigFrame()
    configFrame = CreateFrame("Frame", "TPWConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(580, 480)
    configFrame:SetPoint("CENTER")
    configFrame:Hide()

    configFrame.TitleText:SetText("TerriblePackWarnings \226\128\148 Config")

    -- Escape to close
    tinsert(UISpecialFrames, "TPWConfigFrame")

    -- Movable
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Vertical divider line at ~225px from left
    local divider = configFrame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    divider:SetWidth(1)
    divider:SetPoint("TOP",    configFrame, "TOPLEFT",    225, -30)
    divider:SetPoint("BOTTOM", configFrame, "BOTTOMLEFT", 225,  8)

    -- Build left panel (dungeon-mob tree)
    BuildLeftPanel(configFrame)

    -- Right scroll frame
    rightScrollFrame = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
    rightScrollFrame:SetPoint("TOPLEFT",     configFrame, "TOPLEFT",     228,  -32)
    rightScrollFrame:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -34,   35)

    rightScrollChild = CreateFrame("Frame", nil, rightScrollFrame)
    rightScrollChild:SetWidth(300)
    rightScrollFrame:SetScrollChild(rightScrollChild)

    -- Right panel header
    rightPanelHeader = rightScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightPanelHeader:SetPoint("TOPLEFT",  rightScrollChild, "TOPLEFT",  4, -4)
    rightPanelHeader:SetPoint("TOPRIGHT", rightScrollChild, "TOPRIGHT", -4, -4)
    rightPanelHeader:SetJustifyH("LEFT")
    rightPanelHeader:SetText("Select a mob to view abilities.")

    rightScrollChild:SetHeight(40)

    -- Reset All button (bottom-right of config frame)
    local resetAllBtn = CreateFrame("Button", nil, configFrame, "GameMenuButtonTemplate")
    resetAllBtn:SetSize(80, 22)
    resetAllBtn:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -12, 8)
    resetAllBtn:SetText("Reset All")
    resetAllBtn:SetScript("OnClick", function()
        if not selectedDungeonIdx then return end
        local enemies = ns.DungeonEnemies[selectedDungeonIdx]
        if not enemies then return end
        for _, enemy in pairs(enemies) do
            if enemy.id and ns.AbilityDB[enemy.id] then
                ns.db.skillConfig[enemy.id] = nil
            end
        end
        if selectedNpcID then
            PopulateRightPanel(selectedNpcID)
        end
    end)

    configFrame.resetAllBtn = resetAllBtn
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------
function ns.ConfigUI.Toggle()
    if not configFrame then BuildConfigFrame() end
    if configFrame:IsShown() then configFrame:Hide() else configFrame:Show() end
end
