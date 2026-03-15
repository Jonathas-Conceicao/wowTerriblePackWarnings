local addonName, ns = ...

ns.IconDisplay = ns.IconDisplay or {}

--- Debug logging (toggle for testing)
local DEBUG = true
local function dbg(msg)
    if DEBUG then print("|cff888888TPW-dbg|r " .. msg) end
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
local function CreateIconSlot(spellID, duration)
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

--- CreateGlowTextures: build 4 red edge textures on slot
local function CreateGlowTextures(slot)
    if slot.glowTextures then return end

    local g = {}
    -- Top edge
    g.top = slot:CreateTexture(nil, "OVERLAY")
    g.top:SetColorTexture(1, 0, 0, 1)
    g.top:SetPoint("TOPLEFT", slot, "TOPLEFT", 0, 0)
    g.top:SetPoint("TOPRIGHT", slot, "TOPRIGHT", 0, 0)
    g.top:SetHeight(GLOW_WIDTH)

    -- Bottom edge
    g.bottom = slot:CreateTexture(nil, "OVERLAY")
    g.bottom:SetColorTexture(1, 0, 0, 1)
    g.bottom:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 0, 0)
    g.bottom:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 0, 0)
    g.bottom:SetHeight(GLOW_WIDTH)

    -- Left edge
    g.left = slot:CreateTexture(nil, "OVERLAY")
    g.left:SetColorTexture(1, 0, 0, 1)
    g.left:SetPoint("TOPLEFT", slot, "TOPLEFT", 0, 0)
    g.left:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 0, 0)
    g.left:SetWidth(GLOW_WIDTH)

    -- Right edge
    g.right = slot:CreateTexture(nil, "OVERLAY")
    g.right:SetColorTexture(1, 0, 0, 1)
    g.right:SetPoint("TOPRIGHT", slot, "TOPRIGHT", 0, 0)
    g.right:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 0, 0)
    g.right:SetWidth(GLOW_WIDTH)

    slot.glowTextures = g
end

local function ShowGlow(slot)
    CreateGlowTextures(slot)
    for _, tex in pairs(slot.glowTextures) do
        tex:Show()
    end
end

local function HideGlow(slot)
    if not slot.glowTextures then return end
    for _, tex in pairs(slot.glowTextures) do
        tex:Hide()
    end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

--- ShowIcon: display a timed spell icon with cooldown sweep
-- @param instanceKey string  unique key for this icon instance
-- @param spellID     number  spell ID for icon texture
-- @param ttsMessage  string|nil  short TTS callout text
-- @param duration    number  cooldown duration in seconds
function ns.IconDisplay.ShowIcon(instanceKey, spellID, ttsMessage, duration)
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

    local slot = CreateIconSlot(spellID, duration)
    slot.ttsMessage = ttsMessage
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
function ns.IconDisplay.ShowStaticIcon(instanceKey, spellID)
    if slotsByKey[instanceKey] then return end

    local slot = CreateIconSlot(spellID, nil)
    slot.instanceKey = instanceKey

    activeSlots[#activeSlots + 1] = slot
    slotsByKey[instanceKey] = slot

    LayoutSlots()
    slot:Show()

    dbg("ShowStaticIcon: " .. instanceKey .. " spellID=" .. tostring(spellID))
end

--- SetUrgent: add red border glow and fire TTS for a timed icon
-- @param instanceKey string  the icon to mark urgent
function ns.IconDisplay.SetUrgent(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end

    ShowGlow(slot)
    TrySpeak(slot.ttsMessage)

    dbg("SetUrgent: " .. instanceKey)
end

--- CancelIcon: remove a specific icon and re-layout remaining icons
-- @param instanceKey string  the icon to cancel
function ns.IconDisplay.CancelIcon(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end

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

--- CancelAll: hide and clear all active icon slots
function ns.IconDisplay.CancelAll()
    for _, slot in ipairs(activeSlots) do
        slot:Hide()
    end
    activeSlots = {}
    slotsByKey  = {}

    dbg("CancelAll")
end
