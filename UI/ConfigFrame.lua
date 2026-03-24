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


--- Set the best available portrait for an NPC.
local function GetPortraitTexture(tex, npcID)
    local displayId = npcIdToDisplayId[npcID]
    if displayId and displayId > 0 then
        SetPortraitTextureFromCreatureDisplayID(tex, displayId)
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
local rightPanelRows = {}
local nodes = {}
local selectedNpcID = nil
local PopulateRightPanel  -- forward declaration (used by StaticPopup before definition)
local selectedDungeonIdx = nil
local PORTRAIT_SIZE = 22
local SPELL_ICON_SIZE = 44
local MOB_ROW_HEIGHT = 26

-- Search and top bar state
local HEADER_PORTRAIT_SIZE = 36
local currentSearchText = ""
local currentMatchedMobs = {}     -- npcID -> true for mobs that match current filter
local currentMatchedSpells = {}   -- npcID -> { spellID -> true } for spell-level filtering
local searchTimer = nil
local noResultsLabel = nil
local searchEditBox = nil

-- Right panel header widgets (module-level for PopulateRightPanel access)
local headerFrame, headerPortrait, headerNameStr, hDivider

------------------------------------------------------------------------
-- StaticPopup: Reset All confirmation
------------------------------------------------------------------------
StaticPopupDialogs["TPW_CONFIRM_RESET_ALL"] = {
    text = "Reset all skill settings in the current profile?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        local sc = ns.Profile.GetSkillConfig()
        wipe(sc)
        if ns.Import and ns.Import.RestoreAllFromSaved then
            ns.Import.RestoreAllFromSaved()
        end
        if selectedNpcID then
            PopulateRightPanel(selectedNpcID)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

------------------------------------------------------------------------
-- StaticPopup: Delete Profile confirmation
------------------------------------------------------------------------
StaticPopupDialogs["TPW_DELETE_PROFILE"] = {
    text = "Delete profile?",
    button1 = "Delete",
    button2 = "Cancel",
    OnShow = function(self)
        self.Text:SetFormattedText("Delete profile \"%s\"?", ns.db.activeProfile or "")
    end,
    OnAccept = function()
        ns.Profile.DeleteProfile(ns.db.activeProfile)
        if configFrame and configFrame.profileBtn then
            configFrame.profileBtn:SetText((ns.db.activeProfile or "Default") .. " v")
        end
        if configFrame and configFrame.UpdateDelButton then
            configFrame.UpdateDelButton()
        end
        if selectedNpcID then PopulateRightPanel(selectedNpcID) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

------------------------------------------------------------------------
-- Profile dropdown popup (singleton, built on first use)
------------------------------------------------------------------------
local profileDropdown = nil

local function BuildProfileDropdown()
    profileDropdown = CreateFrame("Frame", "TPWProfileDropdown", UIParent, "BasicFrameTemplateWithInset")
    profileDropdown:SetSize(160, 220)
    profileDropdown:Hide()
    profileDropdown:SetFrameStrata("DIALOG")
    profileDropdown.TitleText:SetText("Profiles")
    tinsert(UISpecialFrames, "TPWProfileDropdown")

    profileDropdown.scrollFrame = CreateFrame("ScrollFrame", nil, profileDropdown, "UIPanelScrollFrameTemplate")
    profileDropdown.scrollFrame:SetPoint("TOPLEFT",     profileDropdown, "TOPLEFT",     8, -28)
    profileDropdown.scrollFrame:SetPoint("BOTTOMRIGHT", profileDropdown, "BOTTOMRIGHT", -28,  8)

    profileDropdown.scrollChild = CreateFrame("Frame", nil, profileDropdown.scrollFrame)
    profileDropdown.scrollChild:SetWidth(120)
    profileDropdown.scrollFrame:SetScrollChild(profileDropdown.scrollChild)

    profileDropdown.buttons = {}
end

local function ShowProfileDropdown(anchorBtn, onSelect)
    if not profileDropdown then BuildProfileDropdown() end

    local names = ns.Profile.GetProfileNames()
    local scrollChild = profileDropdown.scrollChild
    local activeName = ns.db.activeProfile or "Default"

    -- Hide existing buttons
    for _, btn in ipairs(profileDropdown.buttons) do
        btn:Hide()
    end

    local yOffset = 0
    for i, name in ipairs(names) do
        local btn = profileDropdown.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, scrollChild)
            btn:SetHeight(22)
            btn:SetNormalFontObject(GameFontNormal)
            btn:SetHighlightFontObject(GameFontHighlight)
            local hlTex = btn:CreateTexture(nil, "HIGHLIGHT")
            hlTex:SetAllPoints()
            hlTex:SetColorTexture(1, 1, 1, 0.1)
            profileDropdown.buttons[i] = btn
        end

        local profileName = name
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  4, -yOffset)
        btn:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, -yOffset)
        btn:SetText(profileName)
        -- Highlight active profile
        if profileName == activeName then
            btn:SetNormalFontObject(GameFontHighlight)
        else
            btn:SetNormalFontObject(GameFontNormal)
        end
        btn:SetScript("OnClick", function()
            onSelect(profileName)
            profileDropdown:Hide()
        end)
        btn:Show()

        yOffset = yOffset + 24
    end

    scrollChild:SetHeight(math.max(yOffset, 1))
    profileDropdown:ClearAllPoints()
    profileDropdown:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, 0)
    profileDropdown:Show()
end

------------------------------------------------------------------------
-- Profile Import popup (singleton, built on first use)
------------------------------------------------------------------------
local profileImportPopup = nil

local function BuildProfileImportPopup()
    profileImportPopup = CreateFrame("Frame", "TPWProfileImport", UIParent, "BasicFrameTemplateWithInset")
    profileImportPopup:SetSize(400, 250)
    profileImportPopup:SetPoint("CENTER")
    profileImportPopup:Hide()
    profileImportPopup:SetFrameStrata("DIALOG")
    profileImportPopup.TitleText:SetText("Import Profile")
    tinsert(UISpecialFrames, "TPWProfileImport")

    local scrollFrame = CreateFrame("ScrollFrame", nil, profileImportPopup, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     profileImportPopup, "TOPLEFT",     12, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", profileImportPopup, "BOTTOMRIGHT", -32,  44)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(350)
    editBox:SetAutoFocus(true)
    editBox:SetTextInsets(4, 4, 4, 4)
    scrollFrame:SetScrollChild(editBox)
    profileImportPopup.editBox = editBox

    local importBtn = CreateFrame("Button", nil, profileImportPopup, "GameMenuButtonTemplate")
    importBtn:SetSize(80, 22)
    importBtn:SetPoint("BOTTOMRIGHT", profileImportPopup, "BOTTOMRIGHT", -40, 12)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        if text and text ~= "" then
            local name, err = ns.Profile.ImportProfile(text)
            if name then
                print("|cff00ccffTPW|r Imported profile: " .. name)
                profileImportPopup:Hide()
                if configFrame and configFrame.profileBtn then
                    configFrame.profileBtn:SetText((ns.db.activeProfile or "Default") .. " v")
                end
                if configFrame and configFrame.UpdateDelButton then
                    configFrame.UpdateDelButton()
                end
                if selectedNpcID then PopulateRightPanel(selectedNpcID) end
            else
                print("|cff00ccffTPW|r Import failed: " .. tostring(err))
            end
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, profileImportPopup, "GameMenuButtonTemplate")
    cancelBtn:SetSize(80, 22)
    cancelBtn:SetPoint("RIGHT", importBtn, "LEFT", -8, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() profileImportPopup:Hide() end)
end

------------------------------------------------------------------------
-- Profile Export popup (singleton, built on first use)
------------------------------------------------------------------------
local profileExportPopup = nil

local function BuildProfileExportPopup()
    profileExportPopup = CreateFrame("Frame", "TPWProfileExport", UIParent, "BasicFrameTemplateWithInset")
    profileExportPopup:SetSize(400, 250)
    profileExportPopup:SetPoint("CENTER")
    profileExportPopup:Hide()
    profileExportPopup:SetFrameStrata("DIALOG")
    profileExportPopup.TitleText:SetText("Export Profile")
    tinsert(UISpecialFrames, "TPWProfileExport")

    local scrollFrame = CreateFrame("ScrollFrame", nil, profileExportPopup, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     profileExportPopup, "TOPLEFT",     12, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", profileExportPopup, "BOTTOMRIGHT", -32,  44)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(350)
    editBox:SetAutoFocus(true)
    editBox:SetTextInsets(4, 4, 4, 4)
    scrollFrame:SetScrollChild(editBox)
    profileExportPopup.editBox = editBox

    local closeBtn = CreateFrame("Button", nil, profileExportPopup, "GameMenuButtonTemplate")
    closeBtn:SetSize(80, 22)
    closeBtn:SetPoint("BOTTOM", profileExportPopup, "BOTTOM", 0, 12)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() profileExportPopup:Hide() end)
end

local function ShowProfileExport()
    if not profileExportPopup then BuildProfileExportPopup() end
    local encoded = ns.Profile.EncodeProfile(ns.db.activeProfile)
    profileExportPopup.editBox:SetText(encoded)
    profileExportPopup:Show()
    profileExportPopup.editBox:SetFocus()
    profileExportPopup.editBox:HighlightText()
end

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
            ns.Profile.SetSkillField(npcID, spellID, "soundKitID", soundKitID)

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
-- Spell resolution helpers
------------------------------------------------------------------------

--- Resolve spell name safely. Returns ability.name if present, else queries C_Spell.GetSpellInfo.
-- @param ability table  ability entry with .spellID and optional .name
-- @return string  spell name or "Spell <id>"
local function GetSpellNameSafe(ability)
    if ability.name then return ability.name end
    local info = C_Spell.GetSpellInfo(ability.spellID)
    if info and info.name then return info.name end
    return "Spell " .. ability.spellID
end

--- Resolve spell icon safely. Tries C_Spell.GetSpellTexture first, then C_Spell.GetSpellInfo iconID.
-- @param spellID number
-- @return number|nil  texture ID or nil (caller handles grey fallback)
local function GetSpellIconSafe(spellID)
    local tex = C_Spell.GetSpellTexture(spellID)
    if tex then return tex end
    local info = C_Spell.GetSpellInfo(spellID)
    if info and info.iconID then return info.iconID end
    return nil
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

            table.sort(mobs, function(a, b) return a.name < b.name end)
            table.insert(result, {
                dungeonIdx  = dungeonIdx,
                dungeonName = info.name,
                mobs        = mobs,
            })
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
        -- Skip non-visible nodes
        if node.visible == false then
            node.header:Hide()
            if node.content then node.content:Hide() end
        else
            node.header:Show()
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
    end

    leftScrollChild:SetHeight(math.max(yOffset, 1))
    leftScrollFrame:UpdateScrollChildRect()
end

local CATEGORY_COLORS = {
    boss      = "FFD700",
    miniboss  = "FF8C00",
    caster    = "00BFFF",
    warrior   = "CD853F",
    rogue     = "FFE566",
    trivial   = "808080",
    unknown   = "A0A0A0",
}

------------------------------------------------------------------------
-- PopulateRightPanel: show per-skill settings for the selected mob
------------------------------------------------------------------------
PopulateRightPanel = function(npcID, matchedSpellIDs)
    for _, row in ipairs(rightPanelRows) do
        row:Hide()
    end

    local entry = ns.AbilityDB[npcID]
    if not entry then
        if headerNameStr then
            headerNameStr:SetText("No ability data for NPC " .. tostring(npcID))
        end
        if headerPortrait then headerPortrait:Hide() end
        if hDivider then hDivider:Hide() end
        rightScrollChild:SetHeight(40)
        rightScrollFrame:UpdateScrollChildRect()
        return
    end

    -- Update header portrait and name
    if headerPortrait and headerNameStr then
        GetPortraitTexture(headerPortrait, npcID)
        headerPortrait:Show()
        local mobName = "NPC " .. npcID
        for _, enemies in pairs(ns.DungeonEnemies) do
            for _, enemy in pairs(enemies) do
                if enemy.id == npcID and enemy.name then
                    mobName = enemy.name
                    break
                end
            end
        end
        local cat = entry.mobCategory or "unknown"
        local colorHex = CATEGORY_COLORS[cat] or "A0A0A0"
        local displayCat = cat:sub(1,1):upper() .. cat:sub(2)
        local categoryTag = "|cff" .. colorHex .. "[" .. displayCat .. "]|r"
        headerNameStr:SetText(mobName .. " " .. categoryTag)
        if hDivider then hDivider:Show() end
    end

    local yOffset = HEADER_PORTRAIT_SIZE + 30

    local abilityIdx = 0
    for _, ability in ipairs(entry.abilities) do
        -- Search filter: skip spells not in matched set
        if not matchedSpellIDs or matchedSpellIDs[ability.spellID] then

        abilityIdx = abilityIdx + 1
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

        local sc = ns.Profile.GetSkillConfig()
        local cfg = sc[npcID] and sc[npcID][ability.spellID]

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
        elseif not cfg and ability.defaultEnabled == false then
            checkBtn:SetChecked(false)
        else
            checkBtn:SetChecked(true)
        end
        checkBtn:SetScript("OnClick", function(self)
            if self:GetChecked() then
                ns.Profile.SetSkillField(npcID_cb, spellID_cb, "enabled", nil)
            else
                ns.Profile.SetSkillField(npcID_cb, spellID_cb, "enabled", false)
                -- Clear preview for this skill when unchecking
                ns.IconDisplay.CancelIcon("preview_" .. spellID_cb)
            end
            -- Rebuild right panel to collapse/expand config options
            PopulateRightPanel(npcID)
        end)

        -- Spell icon (doubled size)
        if not skillRow.spellIcon then
            skillRow.spellIcon = skillRow:CreateTexture(nil, "ARTWORK")
        end
        local spellIcon = skillRow.spellIcon
        spellIcon:SetSize(SPELL_ICON_SIZE, SPELL_ICON_SIZE)
        spellIcon:ClearAllPoints()
        spellIcon:SetPoint("LEFT", checkBtn, "RIGHT", 4, 0)
        local iconTex = GetSpellIconSafe(ability.spellID)
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
        abilityName:SetText(GetSpellNameSafe(ability))

        rowInnerY = rowInnerY + SPELL_ICON_SIZE + 4

        -- Determine if skill is enabled (checked) — config options only visible when checked
        local isEnabled = true
        if cfg and cfg.enabled == false then
            isEnabled = false
        elseif not cfg and ability.defaultEnabled == false then
            isEnabled = false
        end

        -- Save compact height for collapse
        local compactY = rowInnerY

        -- ---- Label (first option under checked skill) ----
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
            eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            skillRow.labelEditBox = eb
        end
        local labelEditBox = skillRow.labelEditBox
        -- Re-bind save handler every render (npcID_cb/spellID_cb change on reuse)
        local function saveLabelValue(self)
            ns.Profile.SetSkillField(npcID_cb, spellID_cb, "label", self:GetText())
            self:ClearFocus()
        end
        labelEditBox:SetScript("OnEnterPressed", saveLabelValue)
        labelEditBox:SetScript("OnEditFocusLost", saveLabelValue)
        labelEditBox:ClearAllPoints()
        labelEditBox:SetPoint("LEFT", labelPrefix, "RIGHT", 4, 0)
        local currentLabel = (cfg and cfg.label ~= nil) and cfg.label or (ability.label or "")
        labelEditBox:SetText(currentLabel)
        labelEditBox:Show()

        rowInnerY = rowInnerY + 24

        -- ---- Timed toggle + first_cast/cooldown inputs ----
        local isTimed = cfg and cfg.timed or false

        if not skillRow.timedCheckBtn then
            skillRow.timedCheckBtn = CreateFrame("CheckButton", nil, skillRow, "UICheckButtonTemplate")
            skillRow.timedCheckBtn:SetSize(22, 22)
            skillRow.timedCheckBtn.text = skillRow.timedCheckBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            skillRow.timedCheckBtn.text:SetPoint("LEFT", skillRow.timedCheckBtn, "RIGHT", 2, 0)
            skillRow.timedCheckBtn.text:SetText("Timed")
        end
        local timedCheckBtn = skillRow.timedCheckBtn
        timedCheckBtn:ClearAllPoints()
        timedCheckBtn:SetPoint("TOPLEFT", skillRow, "TOPLEFT", 0, -rowInnerY)
        timedCheckBtn:SetChecked(isTimed)

        -- First Cast label + editbox
        if not skillRow.fcLabel then
            skillRow.fcLabel = skillRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            skillRow.fcLabel:SetText("First:")
        end
        local fcLabel = skillRow.fcLabel
        fcLabel:ClearAllPoints()
        fcLabel:SetPoint("LEFT", timedCheckBtn.text, "RIGHT", 12, 0)

        if not skillRow.fcEditBox then
            local eb = CreateFrame("EditBox", nil, skillRow)
            eb:SetSize(50, 20)
            eb:SetFontObject(ChatFontNormal)
            eb:SetAutoFocus(false)
            eb:SetMaxLetters(5)
            eb:SetTextInsets(4, 4, 2, 2)
            AddEditBoxBackground(eb)
            eb:SetScript("OnTextChanged", function(self, userInput)
                if not userInput then return end
                local text = self:GetText()
                local clean = text:gsub("[^0-9]", "")
                if clean ~= text then
                    self:SetText(clean)
                    self:SetCursorPosition(#clean)
                end
            end)
            eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            skillRow.fcEditBox = eb
        end
        local fcEditBox = skillRow.fcEditBox
        fcEditBox:ClearAllPoints()
        fcEditBox:SetPoint("LEFT", fcLabel, "RIGHT", 4, 0)
        fcEditBox:SetText(cfg and cfg.first_cast and tostring(cfg.first_cast) or "")
        -- Re-bind save handler every render
        local function saveFcValue(self)
            local val = tonumber(self:GetText())
            if val and val > 0 then
                if val > 1200 then val = 1200 end
                ns.Profile.SetSkillField(npcID_cb, spellID_cb, "first_cast", val)
                self:SetText(tostring(val))
            else
                ns.Profile.SetSkillField(npcID_cb, spellID_cb, "first_cast", nil)
                self:SetText("")
            end
            self:ClearFocus()
        end
        fcEditBox:SetScript("OnEditFocusLost", saveFcValue)
        fcEditBox:SetScript("OnEnterPressed", saveFcValue)

        -- Cooldown label + editbox
        if not skillRow.cdLabel then
            skillRow.cdLabel = skillRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            skillRow.cdLabel:SetText("CD:")
        end
        local cdLabel = skillRow.cdLabel
        cdLabel:ClearAllPoints()
        cdLabel:SetPoint("LEFT", fcEditBox, "RIGHT", 8, 0)

        if not skillRow.cdEditBox then
            local eb = CreateFrame("EditBox", nil, skillRow)
            eb:SetSize(50, 20)
            eb:SetFontObject(ChatFontNormal)
            eb:SetAutoFocus(false)
            eb:SetMaxLetters(5)
            eb:SetTextInsets(4, 4, 2, 2)
            AddEditBoxBackground(eb)
            eb:SetScript("OnTextChanged", function(self, userInput)
                if not userInput then return end
                local text = self:GetText()
                local clean = text:gsub("[^0-9]", "")
                if clean ~= text then
                    self:SetText(clean)
                    self:SetCursorPosition(#clean)
                end
            end)
            eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            skillRow.cdEditBox = eb
        end
        local cdEditBox = skillRow.cdEditBox
        cdEditBox:ClearAllPoints()
        cdEditBox:SetPoint("LEFT", cdLabel, "RIGHT", 4, 0)
        cdEditBox:SetText(cfg and cfg.cooldown and tostring(cfg.cooldown) or "")
        -- Re-bind save handler every render
        local function saveCdValue(self)
            local val = tonumber(self:GetText())
            if val and val > 0 then
                if val > 1200 then val = 1200 end
                ns.Profile.SetSkillField(npcID_cb, spellID_cb, "cooldown", val)
                self:SetText(tostring(val))
            else
                ns.Profile.SetSkillField(npcID_cb, spellID_cb, "cooldown", nil)
                self:SetText("")
            end
            self:ClearFocus()
        end
        cdEditBox:SetScript("OnEditFocusLost", saveCdValue)
        cdEditBox:SetScript("OnEnterPressed", saveCdValue)

        -- Gray out timer fields when untimed
        if isTimed then
            fcEditBox:Enable()
            fcEditBox:SetAlpha(1.0)
            cdEditBox:Enable()
            cdEditBox:SetAlpha(1.0)
        else
            fcEditBox:Disable()
            fcEditBox:SetAlpha(0.4)
            cdEditBox:Disable()
            cdEditBox:SetAlpha(0.4)
        end

        -- Wire timed checkbox to toggle field states
        timedCheckBtn:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            ns.Profile.SetSkillField(npcID_cb, spellID_cb, "timed", checked and true or nil)
            if checked then
                fcEditBox:Enable()
                fcEditBox:SetAlpha(1.0)
                cdEditBox:Enable()
                cdEditBox:SetAlpha(1.0)
            else
                fcEditBox:Disable()
                fcEditBox:SetAlpha(0.4)
                cdEditBox:Disable()
                cdEditBox:SetAlpha(0.4)
            end
        end)

        rowInnerY = rowInnerY + 26

        -- ---- Sound alert checkbox (own row, below timer fields) ----
        if not skillRow.soundCheckBtn then
            skillRow.soundCheckBtn = CreateFrame("CheckButton", nil, skillRow, "UICheckButtonTemplate")
            skillRow.soundCheckBtn:SetSize(22, 22)
            skillRow.soundCheckBtn.text = skillRow.soundCheckBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            skillRow.soundCheckBtn.text:SetPoint("LEFT", skillRow.soundCheckBtn, "RIGHT", 2, 0)
            skillRow.soundCheckBtn.text:SetText("Sound Alert")
        end
        local soundCheckBtn = skillRow.soundCheckBtn
        soundCheckBtn:ClearAllPoints()
        soundCheckBtn:SetPoint("TOPLEFT", skillRow, "TOPLEFT", 4, -rowInnerY)
        soundCheckBtn:SetChecked(cfg and cfg.soundEnabled or false)
        local isSoundEnabled = cfg and cfg.soundEnabled or false
        soundCheckBtn:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            ns.Profile.SetSkillField(npcID_cb, spellID_cb, "soundEnabled", checked and true or nil)
            -- Rebuild packs so runtime has updated soundEnabled
            if ns.Import and ns.Import.RestoreAllFromSaved then
                ns.Import.RestoreAllFromSaved()
            end
            -- Rebuild to update sound/TTS widget states
            PopulateRightPanel(npcID)
        end)

        rowInnerY = rowInnerY + 24

        -- ---- Sound dropdown ----
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
            eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            skillRow.ttsEditBox = eb
        end
        local ttsEditBox = skillRow.ttsEditBox
        -- Re-bind save handler every render (npcID_cb/spellID_cb change on reuse)
        local function saveTtsValue(self)
            ns.Profile.SetSkillField(npcID_cb, spellID_cb, "ttsMessage", self:GetText())
            self:ClearFocus()
        end
        ttsEditBox:SetScript("OnEnterPressed", saveTtsValue)
        ttsEditBox:SetScript("OnEditFocusLost", saveTtsValue)
        ttsEditBox:ClearAllPoints()
        ttsEditBox:SetPoint("LEFT",  ttsPrefix, "RIGHT",  4,  0)
        ttsEditBox:SetPoint("RIGHT", skillRow,  "RIGHT", -50,  0)
        local currentTTS = (cfg and cfg.ttsMessage ~= nil) and cfg.ttsMessage
            or (ability.ttsMessage or GetSpellNameSafe(ability))
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

        -- Disable sound/TTS controls when sound alert is unchecked
        if not isSoundEnabled then
            soundBtn:Disable()
            soundBtn:SetAlpha(0.4)
            ttsEditBox:Disable()
            ttsEditBox:SetAlpha(0.4)
            ttsPlayBtn:Disable()
            ttsPlayBtn:SetAlpha(0.4)
        else
            soundBtn:Enable()
            soundBtn:SetAlpha(1.0)
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
            local sc = ns.Profile.GetSkillConfig()
            if sc[npcID_rst] then
                sc[npcID_rst][spellID_rst] = nil
            end
            ns.IconDisplay.CancelIcon("preview_" .. spellID_rst)
            PopulateRightPanel(npcID_rst)
        end)

        -- Show preview button
        if not skillRow.showBtn then
            skillRow.showBtn = CreateFrame("Button", nil, skillRow, "GameMenuButtonTemplate")
            skillRow.showBtn:SetSize(50, 20)
            skillRow.showBtn:SetText("Show")
        end
        local showBtn = skillRow.showBtn
        showBtn:ClearAllPoints()
        showBtn:SetPoint("LEFT", resetBtn, "RIGHT", 4, 0)
        local spellID_show = ability.spellID
        local npcID_show = npcID
        showBtn:SetScript("OnClick", function()
            -- Read current config live (not stale closure values)
            local sc = ns.Profile.GetSkillConfig()
            local liveCfg = sc[npcID_show] and sc[npcID_show][spellID_show]
            -- Read label from editbox directly (may not be saved yet)
            local liveLabel = skillRow.labelEditBox and skillRow.labelEditBox:GetText() or (ability.label or "")
            local liveTimed = liveCfg and liveCfg.timed or false
            local liveFC = liveCfg and liveCfg.first_cast
            local liveCD = liveCfg and liveCfg.cooldown
            -- Cancel existing preview first so it can be refreshed
            ns.IconDisplay.CancelIcon("preview_" .. spellID_show)
            ns.Scheduler:StopAbility("preview_" .. spellID_show)
            if liveTimed and liveFC and liveFC > 0 then
                -- Use Scheduler for proper first_cast → cooldown repeat cycle
                ns.Scheduler:StartAbility({
                    spellID      = spellID_show,
                    first_cast   = liveFC,
                    cooldown     = liveCD or liveFC,
                    label        = liveLabel,
                    ttsMessage   = nil,
                    soundKitID   = nil,
                    soundEnabled = false,
                }, "preview_" .. spellID_show)
            else
                ns.IconDisplay.ShowStaticIcon("preview_" .. spellID_show, spellID_show, liveLabel, nil, nil, false)
            end
        end)

        -- Hide preview button
        if not skillRow.hideBtn then
            skillRow.hideBtn = CreateFrame("Button", nil, skillRow, "GameMenuButtonTemplate")
            skillRow.hideBtn:SetSize(50, 20)
            skillRow.hideBtn:SetText("Hide")
        end
        local hideBtn = skillRow.hideBtn
        hideBtn:ClearAllPoints()
        hideBtn:SetPoint("LEFT", showBtn, "RIGHT", 4, 0)
        hideBtn:SetScript("OnClick", function()
            ns.Scheduler:StopAbility("preview_" .. spellID_show)
            ns.IconDisplay.CancelIcon("preview_" .. spellID_show)
        end)

        rowInnerY = rowInnerY + 24

        -- Show/hide config widgets based on enabled state
        local function setConfigVisible(visible)
            local method = visible and "Show" or "Hide"
            if skillRow.labelPrefix then skillRow.labelPrefix[method](skillRow.labelPrefix) end
            if skillRow.labelEditBox then skillRow.labelEditBox[method](skillRow.labelEditBox) end
            if skillRow.timedCheckBtn then skillRow.timedCheckBtn[method](skillRow.timedCheckBtn) end
            if skillRow.fcLabel then skillRow.fcLabel[method](skillRow.fcLabel) end
            if skillRow.fcEditBox then skillRow.fcEditBox[method](skillRow.fcEditBox) end
            if skillRow.cdLabel then skillRow.cdLabel[method](skillRow.cdLabel) end
            if skillRow.cdEditBox then skillRow.cdEditBox[method](skillRow.cdEditBox) end
            if skillRow.soundCheckBtn then skillRow.soundCheckBtn[method](skillRow.soundCheckBtn) end
            if skillRow.soundPrefix then skillRow.soundPrefix[method](skillRow.soundPrefix) end
            if skillRow.soundBtn then skillRow.soundBtn[method](skillRow.soundBtn) end
            if skillRow.ttsPrefix then skillRow.ttsPrefix[method](skillRow.ttsPrefix) end
            if skillRow.ttsEditBox then skillRow.ttsEditBox[method](skillRow.ttsEditBox) end
            if skillRow.ttsPlayBtn then skillRow.ttsPlayBtn[method](skillRow.ttsPlayBtn) end
            if skillRow.timingLabel then skillRow.timingLabel[method](skillRow.timingLabel) end
            if skillRow.resetBtn then skillRow.resetBtn[method](skillRow.resetBtn) end
            if skillRow.showBtn then skillRow.showBtn[method](skillRow.showBtn) end
            if skillRow.hideBtn then skillRow.hideBtn[method](skillRow.hideBtn) end
        end

        if isEnabled then
            setConfigVisible(true)
            skillRow:SetHeight(rowInnerY + 4)
            yOffset = yOffset + rowInnerY + 16
        else
            setConfigVisible(false)
            skillRow:SetHeight(compactY + 4)
            yOffset = yOffset + compactY + 8
        end
        skillRow:Show()

        end -- search filter if
    end

    rightScrollChild:SetHeight(math.max(yOffset, 40))
    rightScrollFrame:UpdateScrollChildRect()
end

------------------------------------------------------------------------
-- ApplySearchFilter: filter tree nodes and right panel by text
------------------------------------------------------------------------
local function ApplySearchFilter(text)
    -- Clear filter: restore all nodes
    if not text or text == "" then
        currentSearchText = ""
        currentMatchedMobs = {}
        currentMatchedSpells = {}
        for _, node in ipairs(nodes) do
            node.visible = true
            if node.mobRows then
                -- Restore original positions and show all mob rows
                for idx, mr in ipairs(node.mobRows) do
                    mr.frame:ClearAllPoints()
                    mr.frame:SetPoint("TOPLEFT",  node.content, "TOPLEFT",  16, -(idx - 1) * MOB_ROW_HEIGHT)
                    mr.frame:SetPoint("TOPRIGHT", node.content, "TOPRIGHT", 0, -(idx - 1) * MOB_ROW_HEIGHT)
                    mr.frame:Show()
                end
                node.contentHeight = #node.mobRows * MOB_ROW_HEIGHT
            end
        end
        if noResultsLabel then noResultsLabel:Hide() end
        RebuildLayout()
        if selectedNpcID then
            PopulateRightPanel(selectedNpcID)
        end
        return
    end

    local filter = text:lower():gsub("%-", "")  -- strip hyphens: "mini-boss" -> "miniboss"
    currentSearchText = filter
    currentMatchedMobs = {}
    currentMatchedSpells = {}

    -- Scan all dungeons/mobs for matches
    local dungeonList = BuildDungeonIndex()
    for _, dungeonEntry in ipairs(dungeonList) do
        for _, mob in ipairs(dungeonEntry.mobs) do
            local npcID = mob.npcID
            local mobNameMatch = (mob.name or ""):lower():find(filter, 1, true)

            -- Category match: check mob's category against search filter
            local categoryMatch = false
            local catEntry = ns.AbilityDB[npcID]
            if catEntry and catEntry.mobCategory then
                categoryMatch = catEntry.mobCategory:find(filter, 1, true) ~= nil
            end

            if mobNameMatch or categoryMatch then
                -- Mob name or category match: show all abilities
                currentMatchedMobs[npcID] = true
                -- Do NOT populate currentMatchedSpells for this mob (show all)
            else
                -- Check if any ability name matches
                local entry = ns.AbilityDB[npcID]
                if entry then
                    local matchedSpells = {}
                    local anyMatch = false
                    for _, ability in ipairs(entry.abilities) do
                        local spellName = GetSpellNameSafe(ability):lower()
                        if spellName:find(filter, 1, true) then
                            matchedSpells[ability.spellID] = true
                            anyMatch = true
                        end
                    end
                    if anyMatch then
                        currentMatchedMobs[npcID] = true
                        currentMatchedSpells[npcID] = matchedSpells
                    end
                end
            end
        end
    end

    -- Update node visibility and mob row visibility
    for _, node in ipairs(nodes) do
        -- Check if any mob in this node matches
        local nodeHasMatch = false
        if node.mobRows then
            for _, mr in ipairs(node.mobRows) do
                if currentMatchedMobs[mr.npcID] then
                    nodeHasMatch = true
                    mr.frame:Show()
                else
                    mr.frame:Hide()
                end
            end
        end

        node.visible = nodeHasMatch

        if nodeHasMatch then
            -- Auto-expand matching nodes
            node.expanded = true
            node.header:SetText("[-] " .. node.dungeonName)
            -- Recompute contentHeight based on visible mob count
            if node.mobRows then
                local visibleCount = 0
                for _, mr in ipairs(node.mobRows) do
                    if currentMatchedMobs[mr.npcID] then
                        visibleCount = visibleCount + 1
                    end
                end
                node.contentHeight = visibleCount * MOB_ROW_HEIGHT
                -- Reposition visible mob rows
                local rowY = 0
                for _, mr in ipairs(node.mobRows) do
                    if currentMatchedMobs[mr.npcID] then
                        mr.frame:ClearAllPoints()
                        mr.frame:SetPoint("TOPLEFT",  node.content, "TOPLEFT",  16, -rowY)
                        mr.frame:SetPoint("TOPRIGHT", node.content, "TOPRIGHT", 0, -rowY)
                        rowY = rowY + MOB_ROW_HEIGHT
                    end
                end
            end
        else
            node.expanded = false
            node.header:SetText("[+] " .. node.dungeonName)
        end
    end

    -- Show "no results" if nothing matched
    local anyVisible = false
    for _, node in ipairs(nodes) do
        if node.visible then anyVisible = true break end
    end
    if noResultsLabel then
        if anyVisible then noResultsLabel:Hide() else noResultsLabel:Show() end
    end

    RebuildLayout()

    -- Update right panel
    if selectedNpcID and currentMatchedMobs[selectedNpcID] then
        PopulateRightPanel(selectedNpcID, currentMatchedSpells[selectedNpcID])
    else
        selectedNpcID = nil
        -- Clear skill rows
        for _, row in ipairs(rightPanelRows) do
            row:Hide()
        end
        if headerNameStr then
            headerNameStr:SetText("Select a mob to view abilities.")
        end
        if headerPortrait then headerPortrait:Hide() end
        if hDivider then hDivider:Hide() end
        rightScrollChild:SetHeight(40)
        rightScrollFrame:UpdateScrollChildRect()
    end
end

------------------------------------------------------------------------
-- BuildLeftPanel: create left scroll area with dungeon-mob tree
------------------------------------------------------------------------
local function BuildLeftPanel(parent)
    leftScrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    leftScrollFrame:SetPoint("TOPLEFT",     parent, "TOPLEFT",     12, -60)
    leftScrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT",  220 - 34, 12)

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

        local contentHeight = #mobList * MOB_ROW_HEIGHT

        -- Build mob rows inside content, tracking them for search filtering
        local mobRowList = {}
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
                PopulateRightPanel(npcID_local, currentMatchedSpells[npcID_local])
            end)

            table.insert(mobRowList, { frame = mobRow, npcID = mob.npcID })
        end

        content:SetHeight(contentHeight)

        local node = {
            header        = header,
            content       = content,
            contentHeight = contentHeight,
            expanded      = false,
            dungeonIdx    = dungeonIdx,
            dungeonName   = dungeonName,
            visible       = true,
            mobRows       = mobRowList,
        }
        table.insert(nodes, node)

        -- Alternating dungeon header backgrounds
        local dungeonNodeIdx = #nodes
        if dungeonNodeIdx % 2 == 0 then
            local headerBg = header:CreateTexture(nil, "BACKGROUND")
            headerBg:SetAllPoints()
            headerBg:SetColorTexture(1, 1, 1, 0.05)
        end

        -- Use ASCII characters for collapse indicators (Unicode doesn't render in WoW)
        header:SetText("[+] " .. dungeonName)
        -- Left-align after SetText creates the FontString
        local fs = header:GetFontString()
        if fs then
            fs:ClearAllPoints()
            fs:SetPoint("LEFT", header, "LEFT", 4, 0)
            fs:SetJustifyH("LEFT")
        end
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
    configFrame:SetSize(720, 480)
    configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 175)
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

    -- Top bar: Route button
    local routeBtn = CreateFrame("Button", nil, configFrame, "GameMenuButtonTemplate")
    routeBtn:SetSize(70, 22)
    routeBtn:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, -30)
    routeBtn:SetText("Route")
    routeBtn:SetScript("OnClick", function()
        if ns.PackUI and ns.PackUI.Toggle then ns.PackUI.Toggle() end
    end)

    -- Top bar: Reset All button (global, resets current profile)
    local resetAllBtn = CreateFrame("Button", nil, configFrame, "GameMenuButtonTemplate")
    resetAllBtn:SetSize(70, 22)
    resetAllBtn:SetPoint("LEFT", routeBtn, "RIGHT", 8, 0)
    resetAllBtn:SetText("Reset All")
    resetAllBtn:SetScript("OnClick", function()
        StaticPopup_Show("TPW_CONFIRM_RESET_ALL")
    end)

    -- Top bar: Profile dropdown button
    local profileBtn = CreateFrame("Button", nil, configFrame, "GameMenuButtonTemplate")
    profileBtn:SetSize(100, 22)
    profileBtn:SetPoint("LEFT", resetAllBtn, "RIGHT", 8, 0)
    profileBtn:SetText((ns.db.activeProfile or "Default") .. " v")
    profileBtn:SetScript("OnClick", function(self)
        ShowProfileDropdown(self, function(name)
            ns.Profile.SwitchProfile(name)
            self:SetText((ns.db.activeProfile or "Default") .. " v")
            if configFrame.UpdateDelButton then configFrame.UpdateDelButton() end
            if selectedNpcID then PopulateRightPanel(selectedNpcID) end
        end)
    end)
    configFrame.profileBtn = profileBtn

    -- Top bar: New Profile button
    local newBtn = CreateFrame("Button", nil, configFrame, "GameMenuButtonTemplate")
    newBtn:SetSize(45, 22)
    newBtn:SetPoint("LEFT", profileBtn, "RIGHT", 4, 0)
    newBtn:SetText("New")
    newBtn:SetScript("OnClick", function()
        if profileDropdown then profileDropdown:Hide() end
        local name = ns.Profile.CreateProfile()
        if name then
            configFrame.profileBtn:SetText((ns.db.activeProfile or "Default") .. " v")
            if configFrame.UpdateDelButton then configFrame.UpdateDelButton() end
            if selectedNpcID then PopulateRightPanel(selectedNpcID) end
        else
            print("|cff00ccffTPW|r Maximum profiles reached (15)")
        end
    end)

    -- Top bar: Delete Profile button
    local delBtn = CreateFrame("Button", nil, configFrame, "GameMenuButtonTemplate")
    delBtn:SetSize(45, 22)
    delBtn:SetPoint("LEFT", newBtn, "RIGHT", 4, 0)
    delBtn:SetText("Del")
    delBtn:SetScript("OnClick", function()
        if (ns.db.activeProfile or "Default") == "Default" then return end
        if profileDropdown then profileDropdown:Hide() end
        StaticPopup_Show("TPW_DELETE_PROFILE")
    end)
    configFrame.delBtn = delBtn

    -- Helper to refresh Del button enabled state after profile changes
    local function UpdateDelButton()
        if (ns.db.activeProfile or "Default") == "Default" then
            delBtn:Disable()
            delBtn:SetAlpha(0.4)
        else
            delBtn:Enable()
            delBtn:SetAlpha(1.0)
        end
    end
    configFrame.UpdateDelButton = UpdateDelButton

    -- Set initial Del button state
    UpdateDelButton()

    -- Top bar: Import Profile button
    local impBtn = CreateFrame("Button", nil, configFrame, "GameMenuButtonTemplate")
    impBtn:SetSize(45, 22)
    impBtn:SetPoint("LEFT", delBtn, "RIGHT", 4, 0)
    impBtn:SetText("Imp")
    impBtn:SetScript("OnClick", function()
        if not profileImportPopup then BuildProfileImportPopup() end
        profileImportPopup.editBox:SetText("")
        profileImportPopup:Show()
    end)

    -- Top bar: Export Profile button
    local expBtn = CreateFrame("Button", nil, configFrame, "GameMenuButtonTemplate")
    expBtn:SetSize(45, 22)
    expBtn:SetPoint("LEFT", impBtn, "RIGHT", 4, 0)
    expBtn:SetText("Exp")
    expBtn:SetScript("OnClick", function()
        ShowProfileExport()
    end)

    -- Top bar: Search EditBox
    searchEditBox = CreateFrame("EditBox", nil, configFrame)
    searchEditBox:SetSize(160, 22)
    searchEditBox:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -12, -30)
    searchEditBox:SetAutoFocus(false)
    searchEditBox:SetFontObject(ChatFontNormal)
    searchEditBox:SetTextInsets(6, 6, 0, 0)
    AddEditBoxBackground(searchEditBox)

    -- Placeholder text
    local placeholder = searchEditBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetPoint("LEFT", searchEditBox, "LEFT", 6, 0)
    placeholder:SetText("Search mobs or skills...")
    searchEditBox.placeholder = placeholder

    searchEditBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if self.placeholder then
            self.placeholder:SetShown(text == "")
        end
        if searchTimer then searchTimer:Cancel(); searchTimer = nil end
        searchTimer = C_Timer.NewTimer(0.3, function()
            searchTimer = nil
            ApplySearchFilter(text)
        end)
    end)

    searchEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Horizontal divider below top bar (separates buttons/search from panels)
    local topBarDivider = configFrame:CreateTexture(nil, "ARTWORK")
    topBarDivider:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    topBarDivider:SetHeight(1)
    topBarDivider:SetPoint("TOPLEFT",  configFrame, "TOPLEFT",  8, -56)
    topBarDivider:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -8, -56)

    -- Vertical divider between left and right panels
    local divider = configFrame:CreateTexture(nil, "OVERLAY")
    divider:SetColorTexture(0.4, 0.4, 0.4, 1)
    divider:SetWidth(2)
    divider:SetPoint("TOP",    configFrame, "TOPLEFT",    225, -56)
    divider:SetPoint("BOTTOM", configFrame, "BOTTOMLEFT", 225,  12)

    -- Left panel background (subtle dark tint)
    local leftBg = configFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    leftBg:SetColorTexture(0, 0, 0, 0.2)
    leftBg:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 8, -57)
    leftBg:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMLEFT", 224, 12)

    -- Left panel bottom border
    local leftBottomBorder = configFrame:CreateTexture(nil, "ARTWORK")
    leftBottomBorder:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    leftBottomBorder:SetHeight(1)
    leftBottomBorder:SetPoint("BOTTOMLEFT",  configFrame, "BOTTOMLEFT",  8, 12)
    leftBottomBorder:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMLEFT", 224, 12)

    -- Build left panel (anchors set inside at -60)
    BuildLeftPanel(configFrame)

    -- "No results" label for search (hidden by default)
    noResultsLabel = leftScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noResultsLabel:SetPoint("TOP", leftScrollChild, "TOP", 0, -20)
    noResultsLabel:SetText("No matches found.")
    noResultsLabel:SetTextColor(0.6, 0.6, 0.6)
    noResultsLabel:Hide()

    -- Right scroll frame (shifted down for top bar)
    rightScrollFrame = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
    rightScrollFrame:SetPoint("TOPLEFT",     configFrame, "TOPLEFT",     228,  -60)
    rightScrollFrame:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -34,   12)

    rightScrollChild = CreateFrame("Frame", nil, rightScrollFrame)
    rightScrollChild:SetWidth(300)
    rightScrollFrame:SetScrollChild(rightScrollChild)

    -- Right panel header container (portrait + name)
    headerFrame = CreateFrame("Frame", nil, rightScrollChild)
    headerFrame:SetPoint("TOPLEFT",  rightScrollChild, "TOPLEFT",  4, -4)
    headerFrame:SetPoint("TOPRIGHT", rightScrollChild, "TOPRIGHT", -4, -4)
    headerFrame:SetHeight(HEADER_PORTRAIT_SIZE + 8)

    headerPortrait = headerFrame:CreateTexture(nil, "ARTWORK")
    headerPortrait:SetSize(HEADER_PORTRAIT_SIZE, HEADER_PORTRAIT_SIZE)
    headerPortrait:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
    headerPortrait:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    headerPortrait:Hide()  -- hidden until a mob is selected

    headerNameStr = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerNameStr:SetPoint("LEFT", headerPortrait, "RIGHT", 6, 0)
    headerNameStr:SetPoint("RIGHT", headerFrame, "RIGHT", 0, 0)
    headerNameStr:SetJustifyH("LEFT")
    headerNameStr:SetText("Select a mob to view abilities.")

    -- Horizontal divider below header
    hDivider = rightScrollChild:CreateTexture(nil, "ARTWORK")
    hDivider:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    hDivider:SetHeight(1)
    hDivider:SetPoint("TOPLEFT",  rightScrollChild, "TOPLEFT",  0, -(HEADER_PORTRAIT_SIZE + 14))
    hDivider:SetPoint("TOPRIGHT", rightScrollChild, "TOPRIGHT", 0, -(HEADER_PORTRAIT_SIZE + 14))
    hDivider:Hide()  -- hidden until a mob is selected

    rightScrollChild:SetHeight(40)

    -- OnHide: reset search state and restore all nodes
    configFrame:SetScript("OnHide", function()
        currentSearchText = ""
        currentMatchedMobs = {}
        currentMatchedSpells = {}
        if searchTimer then searchTimer:Cancel(); searchTimer = nil end
        if searchEditBox then searchEditBox:SetText("") end
        -- Restore all nodes to visible
        for _, node in ipairs(nodes) do
            node.visible = true
            if node.mobRows then
                for _, mr in ipairs(node.mobRows) do
                    mr.frame:Show()
                end
            end
        end
        -- Clear all skill previews
        if ns.IconDisplay and ns.IconDisplay.CancelPreviews then
            ns.IconDisplay.CancelPreviews()
        end
        -- Rebuild all packs from current profile so config changes take effect in combat
        if ns.Import and ns.Import.RestoreAllFromSaved then
            ns.Import.RestoreAllFromSaved()
        end
    end)
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------
function ns.ConfigUI.Toggle()
    if not configFrame then BuildConfigFrame() end
    if configFrame:IsShown() then configFrame:Hide() else configFrame:Show() end
end

--- Re-render the right panel if a mob is currently selected (called after skill config changes).
function ns.ConfigUI.Refresh()
    if selectedNpcID and configFrame and configFrame:IsShown() then
        PopulateRightPanel(selectedNpcID)
    end
end

--- Open config window directly to a specific mob
-- @param npcID       number  NPC ID to select
-- @param dungeonIdx  number  dungeon index to expand
function ns.ConfigUI.OpenToMob(npcID, dungeonIdx)
    if not configFrame then BuildConfigFrame() end

    -- Clear search filter before expanding
    currentSearchText = ""
    currentMatchedMobs = {}
    currentMatchedSpells = {}
    if searchTimer then searchTimer:Cancel(); searchTimer = nil end
    if searchEditBox then searchEditBox:SetText("") end
    for _, node in ipairs(nodes) do
        node.visible = true
        if node.mobRows then
            for _, mr in ipairs(node.mobRows) do
                mr.frame:Show()
            end
        end
    end

    -- Expand the correct dungeon node and collapse others
    for _, node in ipairs(nodes) do
        if node.dungeonIdx == dungeonIdx and not node.expanded then
            node.expanded = true
            node.header:SetText("[-] " .. node.dungeonName)
        elseif node.dungeonIdx ~= dungeonIdx and node.expanded then
            node.expanded = false
            node.header:SetText("[+] " .. node.dungeonName)
        end
    end
    RebuildLayout()

    -- Select the mob
    selectedNpcID = npcID
    selectedDungeonIdx = dungeonIdx
    PopulateRightPanel(npcID)

    configFrame:Show()
end
