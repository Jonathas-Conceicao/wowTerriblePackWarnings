local addonName, ns = ...

ns.BossWarnings = {}
local BW = ns.BossWarnings

-- Active adapter name, set on first detection
local activeAdapter = nil

-- Track DBM bar IDs we created (to cancel individually rather than CancelAllBars)
local activeBarIDs = {}

-- ============================================================
-- Adapter Detection (lazy, runs once on first call)
-- ============================================================

local function DetectAdapter()
    if activeAdapter then return end

    if C_EncounterTimeline
        and C_EncounterTimeline.IsFeatureEnabled
        and C_EncounterTimeline.IsFeatureEnabled()
    then
        activeAdapter = "EncounterTimeline"
    elseif DBT then
        activeAdapter = "DBM"
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
    local eventID = C_EncounterTimeline.AddScriptEvent(eventInfo)
    if eventID then
        etEventIDs[id] = eventID
    end
end

local function ET_CancelTimer(id)
    local eventID = etEventIDs[id]
    if eventID then
        C_EncounterTimeline.CancelScriptEvent(eventID)
        etEventIDs[id] = nil
    end
end

local function ET_CancelAllTimers()
    C_EncounterTimeline.CancelAllScriptEvents()
    wipe(etEventIDs)
end

local function ET_Show(text, duration)
    -- Use AddScriptEvent to show a short-lived timeline entry for the alert
    local eventInfo = {
        text = text,
        duration = duration or 5,
    }
    local eventID = C_EncounterTimeline.AddScriptEvent(eventInfo)
    if eventID then
        etEventIDs["alert_" .. GetTime()] = eventID
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
    local barID = "TPW: " .. text
    DBT:CreateBar(duration or 5, barID)
    activeBarIDs["alert_" .. GetTime()] = barID
end

-- ============================================================
-- RaidNotice fallback adapter
-- ============================================================

local function RN_Show(text, duration)
    RaidNotice_AddMessage(RaidBossEmoteFrame, text, ChatTypeInfo["RAID_WARNING"], duration or 5)
end

local function RN_ShowTimer(id, text, duration, spellID)
    -- No bar support; approximate as text flash with duration appended
    RN_Show(text .. " (" .. duration .. "s)", duration)
end

local function RN_CancelTimer(id)
    -- No-op: text flash cannot be cancelled
end

local function RN_CancelAllTimers()
    -- No-op: text flash cannot be cancelled
end

-- ============================================================
-- Public API
-- ============================================================

function BW.Show(text, duration)
    DetectAdapter()
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
