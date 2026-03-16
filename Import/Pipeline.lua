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
    [160] = { key = "murder_row",              name = "Murder Row" },
}

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
                        local key = ability.spellID .. "_" .. entry.mobClass
                        if not seenAbility[key] then
                            seenAbility[key] = true
                            table.insert(pack.abilities, {
                                name       = ability.name,
                                spellID    = ability.spellID,
                                mobClass   = entry.mobClass,
                                first_cast = ability.first_cast,
                                cooldown   = ability.cooldown,
                                label      = ability.label,
                                ttsMessage = ability.ttsMessage,
                            })
                        end
                    end
                end
            end
        end
    end

    return pack
end

--- Run a full import from a decoded MDT preset table.
-- Populates ns.PackDatabase["imported"] and saves to ns.db.importedRoute.
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

    -- Populate PackDatabase
    ns.PackDatabase["imported"] = packs

    -- Persist processed data (not raw MDT string)
    ns.db.importedRoute = {
        dungeonName = dungeonName,
        dungeonIdx  = dungeonIdx,
        packs       = packs,
    }

    print(string.format("|cff00ccffTPW|r Imported: %s - %d pulls (%d with tracked abilities)",
        dungeonName, #packs, packsWithAbilities))

    -- Auto-select the imported route
    ns.CombatWatcher:SelectDungeon("imported")

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

--- Restore previously imported route from SavedVariables on login.
-- Called from Core.lua ADDON_LOADED handler after ns.db is initialized.
function Import.RestoreFromSaved()
    if not ns.db.importedRoute then return end
    local saved = ns.db.importedRoute

    ns.PackDatabase["imported"] = saved.packs

    print(string.format("|cff00ccffTPW|r Restored: %s - %d pulls", saved.dungeonName, #saved.packs))

    ns.CombatWatcher:SelectDungeon("imported")
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

--- Clear imported route from PackDatabase and SavedVariables.
function Import.Clear()
    ns.PackDatabase["imported"] = nil
    ns.db.importedRoute = nil

    -- Stop active tracking
    if ns.NameplateScanner and ns.NameplateScanner.Stop then
        ns.NameplateScanner:Stop()
    end
    if ns.Scheduler and ns.Scheduler.Stop then
        ns.Scheduler:Stop()
    end

    print("|cff00ccffTPW|r Import cleared.")
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end
