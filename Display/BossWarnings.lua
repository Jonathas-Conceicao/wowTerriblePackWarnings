local addonName, ns = ...

ns.BossWarnings = {}
local BW = ns.BossWarnings

-- Debug logging (toggle for testing)
local DEBUG = true
local function dbg(msg)
    if DEBUG then print("|cff888888TPW-dbg|r " .. msg) end
end

-- Active adapter name, set on first detection
local activeAdapter = nil

-- Track DBM bar IDs we created (to cancel individually rather than CancelAllBars)
local activeBarIDs = {}

-- ============================================================
-- Forward declarations (ET fallback needs RN functions)
-- ============================================================
local RN_Show, RN_ShowTimer, RN_CancelTimer, RN_CancelAllTimers

-- ============================================================
-- Adapter Detection (lazy, runs once on first call)
-- ============================================================

local function DetectAdapter()
    if activeAdapter then return end

    if DBT then
        activeAdapter = "DBM"
    elseif C_EncounterTimeline
        and C_EncounterTimeline.IsFeatureEnabled
        and C_EncounterTimeline.IsFeatureEnabled()
    then
        activeAdapter = "EncounterTimeline"
    else
        activeAdapter = "RaidNotice"
    end

    print("|cff00ccffTPW|r display: " .. activeAdapter)
end

-- ============================================================
-- Encounter Timeline adapter
-- ============================================================

-- Maps our caller-provided id -> eventID returned by C_EncounterTimeline
local etEventIDs = {}

local function ET_ShowTimer(id, text, duration, spellID)
    local eventInfo = {
        text = text,
        duration = duration,
        spellID = spellID,
    }
    local ok, eventID = pcall(C_EncounterTimeline.AddScriptEvent, eventInfo)
    if ok and eventID then
        etEventIDs[id] = eventID
    else
        -- Timeline not rendering (outside boss encounter) — fall back to RaidNotice
        dbg("ET_ShowTimer fallback to RaidNotice")
        RN_ShowTimer(id, text, duration, spellID)
    end
end

local function ET_CancelTimer(id)
    local eventID = etEventIDs[id]
    if eventID then
        pcall(C_EncounterTimeline.CancelScriptEvent, eventID)
        etEventIDs[id] = nil
    end
end

local function ET_CancelAllTimers()
    pcall(C_EncounterTimeline.CancelAllScriptEvents)
    wipe(etEventIDs)
end

local function ET_Show(text, duration)
    -- Use AddScriptEvent to show a short-lived timeline entry for the alert
    local eventInfo = {
        text = text,
        duration = duration or 5,
    }
    local ok, eventID = pcall(C_EncounterTimeline.AddScriptEvent, eventInfo)
    if ok and eventID then
        etEventIDs["alert_" .. GetTime()] = eventID
    else
        -- Timeline not rendering (outside boss encounter) — fall back to RaidNotice
        dbg("ET_Show fallback to RaidNotice")
        RN_Show(text, duration)
    end
end

-- ============================================================
-- DBM adapter
-- ============================================================

local function DBM_ShowTimer(id, text, duration, spellID)
    local barID = "TPW_" .. id
    DBT:CreateBar(duration, barID, spellID)
    activeBarIDs[id] = barID
end

local function DBM_CancelTimer(id)
    local barID = activeBarIDs[id]
    if barID then
        DBT:CancelBar(barID)
        activeBarIDs[id] = nil
    end
end

local function DBM_CancelAllTimers()
    for id, barID in pairs(activeBarIDs) do
        DBT:CancelBar(barID)
    end
    wipe(activeBarIDs)
end

local function DBM_Show(text, duration)
    -- Text alerts complement the existing timer bar — use RaidNotice flash
    RN_Show(text, duration)
end

-- ============================================================
-- RaidNotice fallback adapter
-- ============================================================

RN_Show = function(text, duration)
    RaidNotice_AddMessage(RaidBossEmoteFrame, text, ChatTypeInfo["RAID_WARNING"], duration or 5)
end

RN_ShowTimer = function(id, text, duration, spellID)
    -- No bar support; approximate as text flash with duration appended
    RN_Show(text .. " (" .. duration .. "s)", duration)
end

RN_CancelTimer = function(id)
    -- No-op: text flash cannot be cancelled
end

RN_CancelAllTimers = function()
    -- No-op: text flash cannot be cancelled
end

-- ============================================================
-- Public API
-- ============================================================

function BW.Show(text, duration)
    DetectAdapter()
    dbg("Show [" .. activeAdapter .. "]: " .. text)
    if activeAdapter == "EncounterTimeline" then
        ET_Show(text, duration)
    elseif activeAdapter == "DBM" then
        DBM_Show(text, duration)
    else
        RN_Show(text, duration)
    end
end

function BW.ShowTimer(id, text, duration, spellID)
    DetectAdapter()
    dbg("ShowTimer [" .. activeAdapter .. "]: " .. text .. " (" .. duration .. "s)")
    if activeAdapter == "EncounterTimeline" then
        ET_ShowTimer(id, text, duration, spellID)
    elseif activeAdapter == "DBM" then
        DBM_ShowTimer(id, text, duration, spellID)
    else
        RN_ShowTimer(id, text, duration, spellID)
    end
end

function BW.CancelTimer(id)
    DetectAdapter()
    if activeAdapter == "EncounterTimeline" then
        ET_CancelTimer(id)
    elseif activeAdapter == "DBM" then
        DBM_CancelTimer(id)
    else
        RN_CancelTimer(id)
    end
end

function BW.CancelAllTimers()
    DetectAdapter()
    if activeAdapter == "EncounterTimeline" then
        ET_CancelAllTimers()
    elseif activeAdapter == "DBM" then
        DBM_CancelAllTimers()
    else
        RN_CancelAllTimers()
    end
end

function BW.GetAdapter()
    return activeAdapter
end
