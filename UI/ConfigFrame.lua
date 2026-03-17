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

--- Create a "pushed in" background for an EditBox
local function AddEditBoxBackground(editBox)
    local bg = editBox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.4)

    -- Subtle inset border (top and left darker, bottom and right lighter)
    local borderTop = editBox:CreateTexture(nil, "BORDER")
    borderTop:SetColorTexture(0, 0, 0, 0.6)
    borderTop:SetHeight(1)
    borderTop:SetPoint("TOPLEFT", editBox, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", editBox, "TOPRIGHT", 0, 0)

    local borderLeft = editBox:CreateTexture(nil, "BORDER")
    borderLeft:SetColorTexture(0, 0, 0, 0.6)
    borderLeft:SetWidth(1)
    borderLeft:SetPoint("TOPLEFT", editBox, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", editBox, "BOTTOMLEFT", 0, 0)

    local borderBottom = editBox:CreateTexture(nil, "BORDER")
    borderBottom:SetColorTexture(0.3, 0.3, 0.3, 0.4)
    borderBottom:SetHeight(1)
    borderBottom:SetPoint("BOTTOMLEFT", editBox, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", 0, 0)

    local borderRight = editBox:CreateTexture(nil, "BORDER")
    borderRight:SetColorTexture(0.3, 0.3, 0.3, 0.4)
    borderRight:SetWidth(1)
    borderRight:SetPoint("TOPRIGHT", editBox, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", 0, 0)
end

------------------------------------------------------------------------
-- Module-level state
------------------------------------------------------------------------
local configFrame = nil
local leftScrollFrame, leftScrollChild
local rightScrollFrame, rightScrollChild
local rightPanelHeader
local rightPanelRows = {}
local nodes = {}
local selectedNpcID = nil
local selectedDungeonIdx = nil
local PORTRAIT_SIZE = 22
local SPELL_ICON_SIZE = 44

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

local function ShowSoundPopup(anchorBtn, npcID, spellID, soundBtn, ttsEditBox, ttsPlayBtn)
    if not soundPopup then BuildSoundPopup() end

    local spChild = soundPopup.scrollChild

    for _, btn in ipairs(soundPopup.buttons) do
        btn:Hide()
    end

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

        local soundKitID = entry.soundKitID
        local soundName  = entry.name

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", spChild, "TOPLEFT", 4, -yOffset)
        btn:SetPoint("TOPRIGHT", spChild, "TOPRIGHT", -4, -yOffset)
        btn:SetText(soundName)
        btn:Show()

        btn:SetScript("OnClick", function()
            ns.db.skillConfig[npcID] = ns.db.skillConfig[npcID] or {}
            ns.db.skillConfig[npcID][spellID] = ns.db.skillConfig[npcID][spellID] or {}
            ns.db.skillConfig[npcID][spellID].soundKitID = soundKitID

            if soundKitID then
                PlaySound(soundKitID)
                ttsEditBox:Disable()
                ttsEditBox:SetAlpha(0.4)
                ttsPlayBtn:Disable()
                ttsPlayBtn:SetAlpha(0.4)
            else
                ttsEditBox:Enable()
                ttsEditBox:SetAlpha(1.0)
                ttsPlayBtn:Enable()
                ttsPlayBtn:SetAlpha(1.0)
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

--- TrySpeak: fire TTS callout (same as IconDisplay)
local function TrySpeak(message)
    if not message or message == "" then return end
    local voiceID = C_TTSSettings and C_TTSSettings.GetVoiceOptionID
        and C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)
    if not voiceID then
        local voices = C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices()
        if voices and voices[1] then voiceID = voices[1].voiceID end
    end
    if voiceID then
        C_VoiceChat.SpeakText(voiceID, message, 0, 100, false)
    end
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
                table.sort(mobs, function(a, b) return a.name < b.name end)
                table.insert(result, {
                    dungeonIdx  = dungeonIdx,
                    dungeonName = info.name,
                    mobs        = mobs,
                })
            end
        end
    end

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
-- PopulateRightPanel: show per-skill settings for the selected mob
------------------------------------------------------------------------
local function PopulateRightPanel(npcID)
    for _, row in ipairs(rightPanelRows) do
        row:Hide()
    end

    local entry = ns.AbilityDB[npcID]
    if not entry then
        rightPanelHeader:SetText("No ability data for NPC " .. tostring(npcID))
        rightScrollChild:SetHeight(40)
        rightScrollFrame:UpdateScrollChildRect()
        return
    end

    -- Find mob name
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
    rightPanelHeader:SetText(mobName .. " - " .. mobClass)

    local yOffset = 32

    for abilityIdx, ability in ipairs(entry.abilities) do
        local skillRow = rightPanelRows[abilityIdx]
        if not skillRow then
            skillRow = CreateFrame("Frame", nil, rightScrollChild)
            rightPanelRows[abilityIdx] = skillRow
        end

        skillRow:ClearAllPoints()
        skillRow:SetPoint("TOPLEFT",  rightScrollChild, "TOPLEFT",  4, -yOffset)
        skillRow:SetPoint("TOPRIGHT", rightScrollChild, "TOPRIGHT", -4, -yOffset)

        -- Spell tooltip on hover
        skillRow.spellID = ability.spellID
        skillRow:EnableMouse(true)
        skillRow:SetScript("OnEnter", function(self)
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:Show()
        end)
        skillRow:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local cfg = ns.db.skillConfig
            and ns.db.skillConfig[npcID]
            and ns.db.skillConfig[npcID][ability.spellID]

        local npcID_cb  = npcID
        local spellID_cb = ability.spellID

        -- ---- Row 1: CheckButton + large spell icon + ability name ----
        local rowInnerY = 0

        -- CheckButton with visible textures
        if not skillRow.checkBtn then
            skillRow.checkBtn = CreateFrame("CheckButton", nil, skillRow, "UICheckButtonTemplate")
            skillRow.checkBtn:SetSize(24, 24)
        end
        local checkBtn = skillRow.checkBtn
        checkBtn:ClearAllPoints()
        checkBtn:SetPoint("TOPLEFT", skillRow, "TOPLEFT", 0, -rowInnerY)
        if cfg and cfg.enabled == false then
            checkBtn:SetChecked(false)
        else
            checkBtn:SetChecked(true)
        end
        checkBtn:SetScript("OnClick", function(self)
            ns.db.skillConfig[npcID_cb] = ns.db.skillConfig[npcID_cb] or {}
            ns.db.skillConfig[npcID_cb][spellID_cb] = ns.db.skillConfig[npcID_cb][spellID_cb] or {}
            if self:GetChecked() then
                ns.db.skillConfig[npcID_cb][spellID_cb].enabled = nil
            else
                ns.db.skillConfig[npcID_cb][spellID_cb].enabled = false
            end
        end)

        -- Spell icon (doubled size)
        if not skillRow.spellIcon then
            skillRow.spellIcon = skillRow:CreateTexture(nil, "ARTWORK")
        end
        local spellIcon = skillRow.spellIcon
        spellIcon:SetSize(SPELL_ICON_SIZE, SPELL_ICON_SIZE)
        spellIcon:ClearAllPoints()
        spellIcon:SetPoint("LEFT", checkBtn, "RIGHT", 4, 0)
        local iconTex = C_Spell.GetSpellTexture(ability.spellID)
        if iconTex then
            spellIcon:SetTexture(iconTex)
        else
            spellIcon:SetColorTexture(0.2, 0.2, 0.2, 1)
        end

        -- Ability name (beside icon, vertically centered)
        if not skillRow.abilityName then
            skillRow.abilityName = skillRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        end
        local abilityName = skillRow.abilityName
        abilityName:ClearAllPoints()
        abilityName:SetPoint("LEFT", spellIcon, "RIGHT", 8, 0)
        abilityName:SetPoint("RIGHT", skillRow, "RIGHT", 0, 0)
        abilityName:SetJustifyH("LEFT")
        abilityName:SetText(ability.name or "")

        rowInnerY = rowInnerY + SPELL_ICON_SIZE + 4

        -- ---- Row 2: timing info (optional) ----
        if not skillRow.timingLabel then
            skillRow.timingLabel = skillRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        end
        local timingLabel = skillRow.timingLabel
        timingLabel:ClearAllPoints()
        if ability.first_cast and ability.cooldown then
            timingLabel:SetPoint("TOPLEFT", skillRow, "TOPLEFT", 28, -rowInnerY)
            timingLabel:SetPoint("TOPRIGHT", skillRow, "TOPRIGHT", 0, -rowInnerY)
            timingLabel:SetJustifyH("LEFT")
            timingLabel:SetText("First cast: " .. ability.first_cast .. "s, Cooldown: " .. ability.cooldown .. "s")
            timingLabel:Show()
            rowInnerY = rowInnerY + 16
        else
            timingLabel:Hide()
        end

        -- ---- Row 3: Label ----
        if not skillRow.labelPrefix then
            skillRow.labelPrefix = skillRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            skillRow.labelPrefix:SetText("Label:")
        end
        local labelPrefix = skillRow.labelPrefix
        labelPrefix:ClearAllPoints()
        labelPrefix:SetPoint("TOPLEFT", skillRow, "TOPLEFT", 4, -rowInnerY)

        if not skillRow.labelEditBox then
            local eb = CreateFrame("EditBox", nil, skillRow)
            eb:SetSize(140, 20)
            eb:SetFontObject(ChatFontNormal)
            eb:SetAutoFocus(false)
            eb:SetMaxLetters(64)
            eb:SetTextInsets(4, 4, 2, 2)
            AddEditBoxBackground(eb)
            eb:SetScript("OnEnterPressed", function(self)
                ns.db.skillConfig[npcID_cb] = ns.db.skillConfig[npcID_cb] or {}
                ns.db.skillConfig[npcID_cb][spellID_cb] = ns.db.skillConfig[npcID_cb][spellID_cb] or {}
                ns.db.skillConfig[npcID_cb][spellID_cb].label = self:GetText()
                self:ClearFocus()
            end)
            eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            skillRow.labelEditBox = eb
        end
        local labelEditBox = skillRow.labelEditBox
        labelEditBox:ClearAllPoints()
        labelEditBox:SetPoint("LEFT", labelPrefix, "RIGHT", 4, 0)
        local currentLabel = (cfg and cfg.label ~= nil) and cfg.label or (ability.label or "")
        labelEditBox:SetText(currentLabel)
        labelEditBox:Show()

        rowInnerY = rowInnerY + 24

        -- ---- Row 4: Sound ----
        if not skillRow.soundPrefix then
            skillRow.soundPrefix = skillRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            skillRow.soundPrefix:SetText("Sound:")
        end
        local soundPrefix = skillRow.soundPrefix
        soundPrefix:ClearAllPoints()
        soundPrefix:SetPoint("TOPLEFT", skillRow, "TOPLEFT", 4, -rowInnerY)

        local currentSoundName = "TTS"
        local currentSoundKitID = cfg and cfg.soundKitID
        if currentSoundKitID then
            for _, snd in ipairs(ns.AlertSounds) do
                if snd.soundKitID == currentSoundKitID then
                    currentSoundName = snd.name
                    break
                end
            end
        end

        if not skillRow.soundBtn then
            skillRow.soundBtn = CreateFrame("Button", nil, skillRow, "GameMenuButtonTemplate")
            skillRow.soundBtn:SetSize(140, 20)
        end
        local soundBtn = skillRow.soundBtn
        soundBtn:ClearAllPoints()
        soundBtn:SetPoint("LEFT", soundPrefix, "RIGHT", 4, 0)
        soundBtn:SetText(currentSoundName)

        rowInnerY = rowInnerY + 24

        -- ---- Row 5: TTS text + Play button ----
        if not skillRow.ttsPrefix then
            skillRow.ttsPrefix = skillRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            skillRow.ttsPrefix:SetText("TTS:")
        end
        local ttsPrefix = skillRow.ttsPrefix
        ttsPrefix:ClearAllPoints()
        ttsPrefix:SetPoint("TOPLEFT", skillRow, "TOPLEFT", 4, -rowInnerY)

        if not skillRow.ttsEditBox then
            local eb = CreateFrame("EditBox", nil, skillRow)
            eb:SetHeight(20)
            eb:SetFontObject(ChatFontNormal)
            eb:SetAutoFocus(false)
            eb:SetMaxLetters(256)
            eb:SetTextInsets(4, 4, 2, 2)
            AddEditBoxBackground(eb)
            eb:SetScript("OnEnterPressed", function(self)
                ns.db.skillConfig[npcID_cb] = ns.db.skillConfig[npcID_cb] or {}
                ns.db.skillConfig[npcID_cb][spellID_cb] = ns.db.skillConfig[npcID_cb][spellID_cb] or {}
                ns.db.skillConfig[npcID_cb][spellID_cb].ttsMessage = self:GetText()
                self:ClearFocus()
            end)
            eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            skillRow.ttsEditBox = eb
        end
        local ttsEditBox = skillRow.ttsEditBox
        ttsEditBox:ClearAllPoints()
        ttsEditBox:SetPoint("LEFT",  ttsPrefix, "RIGHT",  4,  0)
        ttsEditBox:SetPoint("RIGHT", skillRow,  "RIGHT", -50,  0)
        local currentTTS = (cfg and cfg.ttsMessage ~= nil) and cfg.ttsMessage
            or (ability.ttsMessage or ability.name or "")
        ttsEditBox:SetText(currentTTS)

        -- Play button for TTS preview
        if not skillRow.ttsPlayBtn then
            skillRow.ttsPlayBtn = CreateFrame("Button", nil, skillRow, "GameMenuButtonTemplate")
            skillRow.ttsPlayBtn:SetSize(42, 20)
            skillRow.ttsPlayBtn:SetText("Play")
        end
        local ttsPlayBtn = skillRow.ttsPlayBtn
        ttsPlayBtn:ClearAllPoints()
        ttsPlayBtn:SetPoint("LEFT", ttsEditBox, "RIGHT", 4, 0)
        ttsPlayBtn:SetScript("OnClick", function()
            local text = ttsEditBox:GetText()
            TrySpeak(text)
        end)

        -- Couple TTS editbox + play button state with sound selection
        if currentSoundKitID then
            ttsEditBox:Disable()
            ttsEditBox:SetAlpha(0.4)
            ttsPlayBtn:Disable()
            ttsPlayBtn:SetAlpha(0.4)
        else
            ttsEditBox:Enable()
            ttsEditBox:SetAlpha(1.0)
            ttsPlayBtn:Enable()
            ttsPlayBtn:SetAlpha(1.0)
        end
        ttsEditBox:Show()
        ttsPlayBtn:Show()

        -- Wire sound button now that ttsEditBox and ttsPlayBtn are available
        local npcID_snd  = npcID
        local spellID_snd = ability.spellID
        soundBtn:SetScript("OnClick", function(self)
            ShowSoundPopup(self, npcID_snd, spellID_snd, self, ttsEditBox, ttsPlayBtn)
        end)

        rowInnerY = rowInnerY + 24

        -- ---- Row 6: Reset button ----
        if not skillRow.resetBtn then
            skillRow.resetBtn = CreateFrame("Button", nil, skillRow, "GameMenuButtonTemplate")
            skillRow.resetBtn:SetSize(60, 20)
            skillRow.resetBtn:SetText("Reset")
        end
        local resetBtn = skillRow.resetBtn
        resetBtn:ClearAllPoints()
        resetBtn:SetPoint("TOPLEFT", skillRow, "TOPLEFT", 4, -rowInnerY)

        local npcID_rst   = npcID
        local spellID_rst  = ability.spellID
        resetBtn:SetScript("OnClick", function()
            if ns.db.skillConfig and ns.db.skillConfig[npcID_rst] then
                ns.db.skillConfig[npcID_rst][spellID_rst] = nil
            end
            PopulateRightPanel(npcID_rst)
        end)

        rowInnerY = rowInnerY + 24

        -- Separator gap between abilities
        skillRow:SetHeight(rowInnerY + 4)
        skillRow:Show()

        yOffset = yOffset + rowInnerY + 8
    end

    rightScrollChild:SetHeight(math.max(yOffset, 40))
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

        local MOB_ROW_HEIGHT = 26
        local contentHeight = #mobList * MOB_ROW_HEIGHT

        -- Build mob rows inside content
        for i, mob in ipairs(mobList) do
            local mobRow = CreateFrame("Button", nil, content)
            mobRow:SetHeight(MOB_ROW_HEIGHT)
            mobRow:SetPoint("TOPLEFT",  content, "TOPLEFT",  16, -(i - 1) * MOB_ROW_HEIGHT)
            mobRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(i - 1) * MOB_ROW_HEIGHT)

            -- Alternating row background
            if i % 2 == 0 then
                local rowBg = mobRow:CreateTexture(nil, "BACKGROUND")
                rowBg:SetAllPoints()
                rowBg:SetColorTexture(1, 1, 1, 0.05)
            end

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

        local node = {
            header        = header,
            content       = content,
            contentHeight = contentHeight,
            expanded      = false,
        }
        table.insert(nodes, node)

        -- Use ASCII characters for collapse indicators (Unicode doesn't render in WoW)
        header:SetText("[+] " .. dungeonName)
        header:SetScript("OnClick", function()
            node.expanded = not node.expanded
            if node.expanded then
                header:SetText("[-] " .. dungeonName)
            else
                header:SetText("[+] " .. dungeonName)
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

    configFrame.TitleText:SetText("TerriblePackWarnings - Config")

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

    -- Vertical divider
    local divider = configFrame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    divider:SetWidth(1)
    divider:SetPoint("TOP",    configFrame, "TOPLEFT",    225, -30)
    divider:SetPoint("BOTTOM", configFrame, "BOTTOMLEFT", 225,  8)

    -- Build left panel
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

    -- Reset All button
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
