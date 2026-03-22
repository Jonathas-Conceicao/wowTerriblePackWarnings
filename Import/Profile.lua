local addonName, ns = ...

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

ns.Profile = {}
local Profile = ns.Profile

local MAX_PROFILES = 15

--- Return the active profile's skillConfig table.
-- Falls back to "Default" if the active profile is missing.
-- Initializes profile.skillConfig = {} if absent.
-- @return table  skillConfig table for the active profile
function Profile.GetSkillConfig()
    local profileName = ns.db.activeProfile or "Default"
    local profiles = ns.db.profiles
    if not profiles then return {} end

    local profile = profiles[profileName]
    if not profile then
        -- Fall back to Default
        profileName = "Default"
        profile = profiles["Default"]
        if not profile then
            profiles["Default"] = { skillConfig = {} }
            profile = profiles["Default"]
        end
    end
    if not profile.skillConfig then
        profile.skillConfig = {}
    end
    return profile.skillConfig
end

--- Write a single field to the active profile's skillConfig.
-- Creates intermediate tables as needed.
-- @param npcID   number  NPC ID
-- @param spellID number  spell ID
-- @param field   string  field name to set
-- @param value   any     value to set
function Profile.SetSkillField(npcID, spellID, field, value)
    local skillConfig = Profile.GetSkillConfig()
    if not skillConfig[npcID] then
        skillConfig[npcID] = {}
    end
    if not skillConfig[npcID][spellID] then
        skillConfig[npcID][spellID] = {}
    end
    skillConfig[npcID][spellID][field] = value
end

--- Switch to a different profile and refresh all downstream state.
-- @param profileName string  name of the profile to activate
function Profile.SwitchProfile(profileName)
    ns.db.activeProfile = profileName
    if ns.Import and ns.Import.RestoreAllFromSaved then
        ns.Import.RestoreAllFromSaved()
    end
    if ns.ConfigUI and ns.ConfigUI.Refresh then
        ns.ConfigUI.Refresh()
    end
end

--- Create a new profile with the next sequential name ("Profile 1", "Profile 2", ...).
-- Enforces a maximum of MAX_PROFILES profiles (not counting Default).
-- Auto-switches to the newly created profile.
-- @return string|nil  new profile name, or nil if at the limit
function Profile.CreateProfile()
    local profiles = ns.db.profiles
    if not profiles then return nil end

    -- Count non-Default profiles and find max numeric suffix
    local count = 0
    local maxNum = 0
    for name, _ in pairs(profiles) do
        if name ~= "Default" then
            count = count + 1
            local num = tonumber(name:match("^Profile (%d+)$"))
            if num and num > maxNum then
                maxNum = num
            end
        end
    end

    if count >= MAX_PROFILES then
        return nil
    end

    local newName = "Profile " .. (maxNum + 1)
    profiles[newName] = { skillConfig = {} }
    Profile.SwitchProfile(newName)
    return newName
end

--- Delete a named profile.
-- Returns false if the name is "Default".
-- Switches to "Default" after deletion.
-- @param name string  profile name to delete
-- @return boolean  true on success, false if name is "Default"
function Profile.DeleteProfile(name)
    if name == "Default" then return false end
    local profiles = ns.db.profiles
    if profiles then
        profiles[name] = nil
    end
    Profile.SwitchProfile("Default")
    return true
end

--- Return a sorted array of profile names, with "Default" always first.
-- @return table  sorted array of profile name strings
function Profile.GetProfileNames()
    local profiles = ns.db.profiles
    if not profiles then return { "Default" } end

    local names = {}
    for name, _ in pairs(profiles) do
        if name ~= "Default" then
            table.insert(names, name)
        end
    end
    table.sort(names)
    table.insert(names, 1, "Default")
    return names
end

--- Encode a profile's skillConfig to a shareable string.
-- Chain: AceSerializer:Serialize -> LibDeflate:CompressDeflate -> LibDeflate:EncodeForPrint, prepends "!".
-- @param profileName string  name of the profile to encode
-- @return string|nil  encoded string, or nil on failure
function Profile.EncodeProfile(profileName)
    local profiles = ns.db.profiles
    if not profiles then return nil end
    local profile = profiles[profileName]
    if not profile then return nil end

    local skillConfig = profile.skillConfig or {}
    local serialized = AceSerializer:Serialize(skillConfig)
    local compressed = LibDeflate:CompressDeflate(serialized)
    if not compressed then return nil end
    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then return nil end
    return "!" .. encoded
end

--- Decode a profile string back into a skillConfig table.
-- Reverse of EncodeProfile: strip "!", DecodeForPrint, DecompressDeflate, Deserialize.
-- @param str string  encoded profile string
-- @return table|nil, string|nil  skillConfig table on success, or nil + error message
function Profile.DecodeProfile(str)
    if not str or str == "" then
        return nil, "No input string provided"
    end

    local encoded, hasPrefix = str:gsub("^%!", "")
    if hasPrefix ~= 1 then
        return nil, "Invalid profile string (missing ! prefix)"
    end

    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then
        return nil, "DecodeForPrint failed -- string may be corrupted"
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return nil, "DecompressDeflate failed"
    end

    local success, data = AceSerializer:Deserialize(decompressed)
    if not success then
        return nil, "AceSerializer:Deserialize failed: " .. tostring(data)
    end

    return data, nil
end

--- Import a profile from an encoded string.
-- Decodes the string, creates a new sequential profile, sets its skillConfig,
-- and switches to the new profile.
-- @param str string  encoded profile string (from EncodeProfile)
-- @return string|nil, string|nil  new profile name on success, or nil + error message
function Profile.ImportProfile(str)
    local skillConfig, err = Profile.DecodeProfile(str)
    if not skillConfig then
        return nil, err
    end

    local newName = Profile.CreateProfile()
    if not newName then
        return nil, "Profile limit reached (max " .. MAX_PROFILES .. ")"
    end

    local profiles = ns.db.profiles
    if profiles and profiles[newName] then
        profiles[newName].skillConfig = skillConfig
    end

    Profile.SwitchProfile(newName)
    return newName, nil
end
