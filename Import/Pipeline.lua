local addonName, ns = ...

ns.Import = {}
local Import = ns.Import

-- dungeonIdx -> { key, name } for all Midnight season dungeons
local DUNGEON_IDX_MAP = {
    [11]  = { key = "seat_of_the_triumvirate", name = "Seat of the Triumvirate" },
    [45]  = { key = "algethar_academy",        name = "Algethar Academy" },
    [150] = { key = "pit_of_saron",            name = "Pit of Saron" },
    [151] = { key = "skyreach",                name = "Skyreach" },
    [152] = { key = "windrunner_spire",        name = "Windrunner Spire" },
    [153] = { key = "magisters_terrace",       name = "Magisters Terrace" },
    [154] = { key = "maisara_caverns",         name = "Maisara Caverns" },
    [155] = { key = "nexus_point_xenas",       name = "Nexus Point Xenas" },
}
-- Expose on ns so ConfigFrame and other files can read dungeon names
ns.DUNGEON_IDX_MAP = DUNGEON_IDX_MAP

--- Merge per-skill user overrides from the active profile's skillConfig with AbilityDB defaults.
-- Returns a merged ability table, or nil if the skill is disabled or has defaultEnabled=false with no override.
-- IMPORTANT: checks cfg.enabled == false (strict equality) — nil means "use default = enabled".
-- Timing fields (first_cast, cooldown) come from profile config only when cfg.timed is true.
-- mobCategory is read from ns.AbilityDB[npcID].mobCategory; defaults to "unknown" (wildcard).
-- @param npcID    number   NPC ID of the mob
-- @param ability  table    ability entry from ns.AbilityDB[npcID].abilities
-- @return table|nil  merged ability table, or nil if disabled
local function MergeSkillConfig(npcID, ability)
    local entry = ns.AbilityDB[npcID]
    local mobCategory = (entry and entry.mobCategory) or "unknown"
    local profileCfg = ns.db.profiles
        and ns.db.profiles[ns.db.activeProfile]
        and ns.db.profiles[ns.db.activeProfile].skillConfig
    local cfg = profileCfg
        and profileCfg[npcID]
        and profileCfg[npcID][ability.spellID]
    if not cfg then
        -- No user override exists. Check if ability defaults to disabled.
        if ability.defaultEnabled == false then return nil end
        -- No override and not defaultEnabled=false: return with no timers (all untimed by default)
        return {
            spellID      = ability.spellID,
            mobCategory  = mobCategory,
            first_cast   = nil,
            cooldown     = nil,
            label        = nil,
            ttsMessage   = (C_Spell.GetSpellInfo(ability.spellID) or {}).name,
            soundEnabled = false,
        }
    end
    if cfg.enabled == false then return nil end  -- user explicitly disabled
    local defaultTTS = (C_Spell.GetSpellInfo(ability.spellID) or {}).name
    return {
        spellID      = ability.spellID,
        mobCategory  = mobCategory,
        first_cast   = cfg.timed and cfg.first_cast or nil,
        cooldown     = cfg.timed and cfg.cooldown or nil,
        label        = cfg.label ~= nil and cfg.label or nil,
        ttsMessage   = cfg.ttsMessage ~= nil and cfg.ttsMessage or defaultTTS,
        soundKitID   = cfg.soundKitID,
        soundEnabled = cfg.soundEnabled or false,
    }
end

--- Build a single pack from one MDT pull entry.
-- @param pullIdx     number   1-based pull index (used for displayName)
-- @param pullData    table    preset.value.pulls[pullIdx] (enemyIdx -> {cloneIdxs})
-- @param dungeonIdx  number   MDT dungeon index, for ns.DungeonEnemies lookup
-- @return table  pack object matching PackDatabase format
local function BuildPack(pullIdx, pullData, dungeonIdx)
    local pack = {
        displayName = "Pull " .. pullIdx,
        npcIDs      = {},
        abilities   = {},
    }

    local enemies = ns.DungeonEnemies[dungeonIdx]
    if not enemies then return pack end

    -- First pass: count clone instances per npcID (before deduplication)
    local mobCounts = {}
    for enemyIdx, clones in pairs(pullData) do
        if tonumber(enemyIdx) and enemies[enemyIdx] then
            local npcID = enemies[enemyIdx].id
            local cloneCount = 0
            for _ in pairs(clones) do cloneCount = cloneCount + 1 end
            mobCounts[npcID] = (mobCounts[npcID] or 0) + cloneCount
        end
    end
    pack.mobCounts = mobCounts

    -- Second pass: deduplicate npcIDs and build ability list with skillConfig merging
    local seenNpc = {}
    local seenAbility = {}

    for enemyIdx, clones in pairs(pullData) do
        if tonumber(enemyIdx) and enemies[enemyIdx] then
            local npcID = enemies[enemyIdx].id

            if not seenNpc[npcID] then
                seenNpc[npcID] = true
                table.insert(pack.npcIDs, npcID)

                local entry = ns.AbilityDB and ns.AbilityDB[npcID]
                if entry then
                    for _, ability in ipairs(entry.abilities) do
                        local merged = MergeSkillConfig(npcID, ability)
                        if merged then
                            local key = merged.spellID .. "_" .. merged.mobCategory
                            if not seenAbility[key] then
                                seenAbility[key] = true
                                table.insert(pack.abilities, merged)
                            end
                        end
                    end
                end
            end
        end
    end

    return pack
end

--- Run a full import from a decoded MDT preset table.
-- Populates ns.PackDatabase[dungeonKey] and saves to ns.db.importedRoutes[dungeonKey].
-- @param preset table  decoded MDT preset (from ns.MDTDecode)
-- @return boolean  true on success, false on validation failure
function Import.RunFromPreset(preset)
    local dungeonIdx = preset.value and preset.value.currentDungeonIdx
    local pulls      = preset.value and preset.value.pulls

    if not dungeonIdx or not pulls then
        print("|cff00ccffTPW|r Import error: preset missing required fields")
        return false
    end

    local dungeonInfo = DUNGEON_IDX_MAP[dungeonIdx]
    local dungeonName = dungeonInfo and dungeonInfo.name or ("Dungeon #" .. dungeonIdx)
    local dungeonKey  = dungeonInfo and dungeonInfo.key or ("dungeon_" .. dungeonIdx)

    if not dungeonInfo then
        print(string.format("|cff00ccffTPW|r Warning: unknown dungeon idx %d - packs will have no tracked abilities", dungeonIdx))
    end

    local packs = {}
    local packsWithAbilities = 0

    for pullIdx = 1, #pulls do
        local pullData = pulls[pullIdx]
        if pullData then
            local pack = BuildPack(pullIdx, pullData, dungeonIdx)
            table.insert(packs, pack)
            if #pack.abilities > 0 then
                packsWithAbilities = packsWithAbilities + 1
            end
        end
    end

    -- Populate PackDatabase under the dungeon's own key
    ns.PackDatabase[dungeonKey] = packs

    -- Persist processed data (not raw MDT string) under per-dungeon key
    -- preset is saved so RestoreAllFromSaved can rebuild packs from current skillConfig on login
    ns.db.importedRoutes = ns.db.importedRoutes or {}
    ns.db.importedRoutes[dungeonKey] = {
        dungeonName = dungeonName,
        dungeonIdx  = dungeonIdx,
        preset      = preset,
        packs       = packs,
    }

    print(string.format("|cff00ccffTPW|r Imported: %s - %d pulls (%d with tracked abilities)",
        dungeonName, #packs, packsWithAbilities))

    -- Auto-select the imported route and persist selection
    ns.CombatWatcher:SelectDungeon(dungeonKey)
    ns.db.selectedDungeon = dungeonKey

    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
    return true
end

--- Entry point for /tpw import <string> slash command.
-- @param importString string  raw MDT export string
-- @return boolean  true on success, false on failure
function Import.RunFromString(importString)
    local ok, result = ns.MDTDecode(importString)
    if not ok then
        print("|cff00ccffTPW|r Import decode failed: " .. tostring(result))
        return false
    end
    return Import.RunFromPreset(result)
end

--- Restore all previously imported routes from SavedVariables on login.
-- Called from Core.lua ADDON_LOADED handler after ns.db is initialized.
-- Iterates ns.db.importedRoutes and rebuilds packs from each saved preset + current skillConfig.
function Import.RestoreAllFromSaved()
    if not ns.db.importedRoutes then return end
    local count = 0
    for dungeonKey, saved in pairs(ns.db.importedRoutes) do
        if saved.preset and saved.dungeonIdx then
            -- Rebuild packs from saved preset + current skillConfig
            local pulls = saved.preset.value and saved.preset.value.pulls
            if pulls then
                local packs = {}
                for pullIdx = 1, #pulls do
                    local pullData = pulls[pullIdx]
                    if pullData then
                        local pack = BuildPack(pullIdx, pullData, saved.dungeonIdx)
                        table.insert(packs, pack)
                    end
                end
                ns.PackDatabase[dungeonKey] = packs
                count = count + 1
            end
        end
    end
    if count > 0 then
        local selectKey = ns.db.selectedDungeon
        if selectKey and ns.PackDatabase[selectKey] and #ns.PackDatabase[selectKey] > 0 then
            ns.CombatWatcher:SelectDungeon(selectKey)
        end
    end
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

--- Clear imported route for a specific dungeon from PackDatabase and SavedVariables.
-- @param dungeonKey string  the dungeon key to clear (e.g. "windrunner_spire")
function Import.Clear(dungeonKey)
    if not dungeonKey then
        print("|cff00ccffTPW|r Error: no dungeon selected to clear")
        return
    end
    ns.PackDatabase[dungeonKey] = nil
    if ns.db.importedRoutes then
        ns.db.importedRoutes[dungeonKey] = nil
    end

    -- Stop active tracking if this dungeon was active
    local curState, curDungeon = ns.CombatWatcher:GetState()
    if curDungeon == dungeonKey then
        if ns.NameplateScanner and ns.NameplateScanner.Stop then
            ns.NameplateScanner:Stop()
        end
        if ns.Scheduler and ns.Scheduler.Stop then
            ns.Scheduler:Stop()
        end
    end

    local dungeonInfo = nil
    for _, info in pairs(DUNGEON_IDX_MAP) do
        if info.key == dungeonKey then dungeonInfo = info break end
    end
    local name = dungeonInfo and dungeonInfo.name or dungeonKey
    print("|cff00ccffTPW|r Route cleared for " .. name .. ".")
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end
