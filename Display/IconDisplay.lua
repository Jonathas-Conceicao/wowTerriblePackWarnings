local addonName, ns = ...

ns.IconDisplay = ns.IconDisplay or {}

-- Debug logging: reads shared toggle from SavedVariables (ns.db.debug)
-- Toggle with /tpw debug. Persists through /reload.
local function dbg(msg)
    if ns.db and ns.db.debug then print("|cff888888TPW-dbg|r " .. msg) end
end

----------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------
local ICON_SIZE    = 80   -- square pixel size
local ICON_PADDING = 4    -- gap between icons
local ANCHOR_X     = 200   -- left offset from screen edge
local ANCHOR_Y     = 900   -- vertical offset from screen edge
local GLOW_WIDTH   = 2    -- red border thickness

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------
local activeSlots = {}    -- ordered array of visible icon slot frames
local slotsByKey  = {}    -- instanceKey -> slot frame

----------------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------------

--- LayoutSlots: reposition all active slots in a horizontal row
local function LayoutSlots()
    for i, slot in ipairs(activeSlots) do
        slot:ClearAllPoints()
        slot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
            ANCHOR_X + (i - 1) * (ICON_SIZE + ICON_PADDING),
            ANCHOR_Y)
    end
end

--- CreateIconSlot: build a single icon frame
-- @param spellID  number  the spell whose icon to display
-- @param duration number|nil  if provided, creates a cooldown sweep
-- @return frame   the slot frame
local function CreateIconSlot(spellID, duration, label)
    local slot = CreateFrame("Frame", nil, UIParent)
    slot:SetSize(ICON_SIZE, ICON_SIZE)
    slot:SetFrameStrata("HIGH")
    slot:SetFrameLevel(100)

    -- Spell icon texture
    local tex = slot:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    local iconOk, icon = pcall(function() return C_Spell.GetSpellTexture(spellID) end)
    if not iconOk then
        dbg("GetSpellTexture FAILED for " .. tostring(spellID) .. ": " .. tostring(icon))
        icon = nil
    end
    dbg("Icon texture for spellID " .. tostring(spellID) .. " = " .. tostring(icon))
    if icon then
        tex:SetTexture(icon)
    else
        tex:SetColorTexture(0.2, 0.2, 0.2, 1)
    end
    slot.icon = tex

    -- Cooldown sweep (timed abilities only)
    if duration and duration > 0 then
        local cd = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
        cd:SetAllPoints()
        cd:SetDrawEdge(true)
        cd:SetHideCountdownNumbers(false)
        cd:SetCooldown(GetTime(), duration)
        slot.cd = cd
    end

    -- Label text (optional short text on icon bottom edge)
    if label and label ~= "" then
        local lbl = slot:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        lbl:SetPoint("TOP", slot, "BOTTOM", 0, -2)
        lbl:SetText(label)
        lbl:SetTextColor(1, 1, 1, 1)
        slot.label = lbl
    end

    -- Tooltip on mouseover
    slot.spellID = spellID
    slot:EnableMouse(true)
    slot:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetSpellByID(self.spellID)
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return slot
end

--- TrySpeak: fire TTS callout if message is provided
-- Uses post-12.0.0 C_VoiceChat.SpeakText signature (voiceID, text, rate, volume, overlap)
local function TrySpeak(message)
    if not message then return end

    local voiceID = C_TTSSettings and C_TTSSettings.GetVoiceOptionID
        and C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)

    if not voiceID then
        local voices = C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices()
        if voices and voices[1] then
            voiceID = voices[1].voiceID
        end
    end

    if voiceID then
        dbg("TTS speak: " .. message)
        C_VoiceChat.SpeakText(voiceID, message, 0, 100, false)
    end
end

--- CreateGlowTextures: build 4 edge textures on slot
-- @param slot   frame   the icon slot
-- @param r,g,b  number  glow color (0-1)
-- @param field  string  field name on slot to store the textures table
local function CreateGlowTextures(slot, r, green, b, field)
    if slot[field] then return end
    local textures = {}
    textures.top = slot:CreateTexture(nil, "OVERLAY")
    textures.top:SetColorTexture(r, green, b, 1)
    textures.top:SetPoint("TOPLEFT", slot, "TOPLEFT", 0, 0)
    textures.top:SetPoint("TOPRIGHT", slot, "TOPRIGHT", 0, 0)
    textures.top:SetHeight(GLOW_WIDTH)
    textures.bottom = slot:CreateTexture(nil, "OVERLAY")
    textures.bottom:SetColorTexture(r, green, b, 1)
    textures.bottom:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 0, 0)
    textures.bottom:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 0, 0)
    textures.bottom:SetHeight(GLOW_WIDTH)
    textures.left = slot:CreateTexture(nil, "OVERLAY")
    textures.left:SetColorTexture(r, green, b, 1)
    textures.left:SetPoint("TOPLEFT", slot, "TOPLEFT", 0, 0)
    textures.left:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 0, 0)
    textures.left:SetWidth(GLOW_WIDTH)
    textures.right = slot:CreateTexture(nil, "OVERLAY")
    textures.right:SetColorTexture(r, green, b, 1)
    textures.right:SetPoint("TOPRIGHT", slot, "TOPRIGHT", 0, 0)
    textures.right:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 0, 0)
    textures.right:SetWidth(GLOW_WIDTH)
    slot[field] = textures
end

local function ShowGlow(slot)
    CreateGlowTextures(slot, 1, 0, 0, "glowTextures")
    for _, tex in pairs(slot.glowTextures) do tex:Show() end
end

local function HideGlow(slot)
    if not slot.glowTextures then return end
    for _, tex in pairs(slot.glowTextures) do tex:Hide() end
end

local function ShowCastGlow(slot)
    CreateGlowTextures(slot, 1, 0.5, 0, "castGlowTextures")
    for _, tex in pairs(slot.castGlowTextures) do tex:Show() end
end

local function HideCastGlow(slot)
    if not slot.castGlowTextures then return end
    for _, tex in pairs(slot.castGlowTextures) do tex:Hide() end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

--- ShowIcon: display a timed spell icon with cooldown sweep
-- @param instanceKey string  unique key for this icon instance
-- @param spellID     number  spell ID for icon texture
-- @param ttsMessage  string|nil  short TTS callout text
-- @param duration    number  cooldown duration in seconds
-- @param label       string|nil  short label text below icon
-- @param soundKitID  number|nil  WoW soundKitID to play at SetUrgent (nil = use TTS)
-- @param soundEnabled boolean|nil  if false/nil, no sound or TTS fires at SetUrgent
function ns.IconDisplay.ShowIcon(instanceKey, spellID, ttsMessage, duration, label, soundKitID, soundEnabled)
    -- If already showing this key, reset its cooldown
    local existing = slotsByKey[instanceKey]
    if existing then
        if existing.cd then
            existing.cd:SetCooldown(GetTime(), duration)
        end
        HideGlow(existing)
        return
    end

    dbg("ShowIcon creating: " .. instanceKey .. " spellID=" .. tostring(spellID)
        .. " dur=" .. tostring(duration))

    local slot = CreateIconSlot(spellID, duration, label)
    slot.ttsMessage = ttsMessage
    slot.soundKitID = soundKitID
    slot.soundEnabled = soundEnabled or false
    slot.instanceKey = instanceKey

    activeSlots[#activeSlots + 1] = slot
    slotsByKey[instanceKey] = slot

    LayoutSlots()
    slot:Show()

    dbg("ShowIcon done: visible=" .. tostring(slot:IsShown())
        .. " alpha=" .. tostring(slot:GetAlpha())
        .. " w=" .. tostring(slot:GetWidth())
        .. " slots=" .. tostring(#activeSlots))
end

--- ShowStaticIcon: display an untimed spell icon (no sweep, no countdown)
-- Only one icon per instanceKey (untimed = one icon regardless of mob count)
-- @param instanceKey string  unique key for this icon
-- @param spellID     number  spell ID for icon texture
-- @param label       string|nil  short label text below icon
-- @param ttsMessage  string|nil  short TTS callout text (used by SetCastHighlight)
-- @param soundKitID  number|nil  WoW soundKitID to play at SetCastHighlight (nil = use TTS)
-- @param soundEnabled boolean|nil  if false/nil, no sound or TTS fires at SetCastHighlight
function ns.IconDisplay.ShowStaticIcon(instanceKey, spellID, label, ttsMessage, soundKitID, soundEnabled)
    if slotsByKey[instanceKey] then return end

    local slot = CreateIconSlot(spellID, nil, label)
    slot.ttsMessage = ttsMessage
    slot.soundKitID = soundKitID
    slot.soundEnabled = soundEnabled or false
    slot.instanceKey = instanceKey

    activeSlots[#activeSlots + 1] = slot
    slotsByKey[instanceKey] = slot

    LayoutSlots()
    slot:Show()

    dbg("ShowStaticIcon: " .. instanceKey .. " spellID=" .. tostring(spellID))
end

--- SetUrgent: add red border glow and fire sound or TTS for a timed icon
-- Sound and TTS are mutually exclusive: soundKitID takes priority over ttsMessage.
-- @param instanceKey string  the icon to mark urgent
function ns.IconDisplay.SetUrgent(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end

    ShowGlow(slot)  -- red glow (existing)
    if slot.soundEnabled then
        if slot.soundKitID then
            PlaySound(slot.soundKitID, "Master")
        else
            TrySpeak(slot.ttsMessage)
        end
    end

    dbg("SetUrgent: " .. instanceKey)
end

--- SetCastHighlight: show orange cast glow and fire configured alert on untimed icon
-- Called by NameplateScanner when a mob of this icon's class begins casting a tracked spell.
-- Alert fires only on the not-glowing -> glowing transition (caller's responsibility).
-- @param instanceKey string  the icon to highlight
-- @param ability     table   ability table with optional soundKitID and ttsMessage
function ns.IconDisplay.SetCastHighlight(instanceKey, ability)
    local slot = slotsByKey[instanceKey]
    if not slot then return end
    ShowCastGlow(slot)
    -- Use slot.soundEnabled (set at ShowStaticIcon time) for live state
    local soundOn = slot.soundEnabled
    if soundOn then
        if slot.soundKitID then
            PlaySound(slot.soundKitID, "Master")
        elseif slot.ttsMessage then
            TrySpeak(slot.ttsMessage)
        end
    end
    dbg("SetCastHighlight: " .. instanceKey)
end

--- ClearCastHighlight: hide orange cast glow without affecting red urgent glow
-- Called by NameplateScanner when the casting mob's cast ends.
-- @param instanceKey string  the icon to clear
function ns.IconDisplay.ClearCastHighlight(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end
    HideCastGlow(slot)
    dbg("ClearCastHighlight: " .. instanceKey)
end

--- CancelIcon: remove a specific icon and re-layout remaining icons
-- @param instanceKey string  the icon to cancel
function ns.IconDisplay.CancelIcon(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end

    -- Hide tooltip if it was anchored to this slot
    if GameTooltip:GetOwner() == slot then
        GameTooltip:Hide()
    end

    HideGlow(slot)
    HideCastGlow(slot)
    slot:Hide()
    slotsByKey[instanceKey] = nil

    for i = #activeSlots, 1, -1 do
        if activeSlots[i] == slot then
            table.remove(activeSlots, i)
            break
        end
    end

    LayoutSlots()

    dbg("CancelIcon: " .. instanceKey)
end

--- CancelPreviews: cancel all preview icons (keys starting with "preview_")
function ns.IconDisplay.CancelPreviews()
    local toRemove = {}
    for key, _ in pairs(slotsByKey) do
        if key:find("^preview_") then
            table.insert(toRemove, key)
        end
    end
    for _, key in ipairs(toRemove) do
        if ns.Scheduler and ns.Scheduler.StopAbility then
            ns.Scheduler:StopAbility(key)
        end
        ns.IconDisplay.CancelIcon(key)
    end
end

--- CancelNonPreviews: cancel all icons except previews (keys starting with "preview_")
function ns.IconDisplay.CancelNonPreviews()
    local toRemove = {}
    for key, _ in pairs(slotsByKey) do
        if not key:find("^preview_") then
            table.insert(toRemove, key)
        end
    end
    for _, key in ipairs(toRemove) do
        ns.IconDisplay.CancelIcon(key)
    end
end

--- CancelAll: hide and clear all active icon slots
function ns.IconDisplay.CancelAll()
    for _, slot in ipairs(activeSlots) do
        if GameTooltip:GetOwner() == slot then
            GameTooltip:Hide()
        end
        HideGlow(slot)
        HideCastGlow(slot)
        slot:Hide()
    end
    activeSlots = {}
    slotsByKey  = {}

    dbg("CancelAll")
end
