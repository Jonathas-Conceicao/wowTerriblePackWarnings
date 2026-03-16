# Phase 9: Import Pipeline - Research

**Researched:** 2026-03-16
**Domain:** WoW Addon Lua — MDT preset parsing, PackDatabase population, SavedVariables persistence
**Confidence:** HIGH

## Summary

Phase 9 builds the bridge between decoded MDT preset tables and the `ns.PackDatabase` format consumed by the existing engine. All upstream plumbing (`ns.MDTDecode`, `ns.AbilityDB`) is complete. The work is purely data transformation: traverse `preset.value.pulls`, resolve each `enemyIdx` through a bundled `ns.DungeonEnemies` table, look up `npcID` in `ns.AbilityDB`, and write packs to `ns.PackDatabase["imported"]`.

The MDT pull structure is well-understood from source. The `ns.PackDatabase` pack format is well-understood from the engine consumers. The SavedVariables pattern is already in place in `Core.lua`. The only design decision remaining (Claude's discretion) is the file layout for the bundled dungeon enemy data.

**Primary recommendation:** Implement a single `Import/Pipeline.lua` that owns the full import flow. Bundle all Midnight dungeon enemy data into a single `Data/DungeonEnemies.lua` keyed by `dungeonIdx`. Use a constant `DUNGEON_IDX_MAP` table in Pipeline.lua to resolve dungeon names.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- MDT pulls reference mobs by `enemyIdx` into `dungeonEnemies[dungeonIdx]` table
- Each enemy entry has an `id` field = npcID — this is how we match to AbilityDB
- Bundle MDT's full dungeonEnemies data for all available dungeons (not just Windrunner Spire)
- Create a dungeonIdx → dungeon key mapping table (extensible for future dungeons)
- For each pull: iterate enemyIdx entries → look up npcID from dungeonEnemies → check `ns.AbilityDB[npcID]` → collect abilities with mobClass
- All pulls appear as packs — even those with no tracked abilities (empty packs for route progression)
- Accept any dungeon — unknown dungeons build packs with mob data but no skill tracking
- Save processed pack data to SavedVariables (`ns.db.importedRoute`)
- Processed data includes: dungeon name, pull list with npcIDs, abilities, pack displayNames
- On ADDON_LOADED: if `ns.db.importedRoute` exists, repopulate PackDatabase from it
- Clear button removes `ns.db.importedRoute` and empties PackDatabase
- No re-decoding needed — instant load from saved data
- Import flow: `/tpw import <string>` → `ns.MDTDecode` → extract `preset.value.currentDungeonIdx` and `preset.value.pulls` → map through dungeonEnemies → build packs → populate PackDatabase → save to db → refresh UI
- Print import summary: "Imported: Windrunner Spire - 17 pulls (4 with tracked abilities)"

### Claude's Discretion

- Import module file location (Import/Pipeline.lua or similar)
- Pack displayName format for imported pulls (e.g. "Pull 1", "Pull 2")
- How to store the dungeonEnemies data (single file? per-dungeon?)
- Whether to expose import via slash command only or also via ns.Import API

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| IMPORT-02 | Extract pull list with npcIDs from decoded preset data | MDT preset structure fully verified: `preset.value.pulls[pullIdx][enemyIdx] = {cloneIdx, ...}` → `ns.DungeonEnemies[dungeonIdx][enemyIdx].id` = npcID |
| IMPORT-03 | Match pull npcIDs against ability database to build pack abilities with correct mobClasses | `ns.AbilityDB[npcID]` returns `{mobClass, abilities}` — exact match; abilities array copied as-is into pack |
| IMPORT-04 | Populate PackDatabase from imported route (replaces hardcoded data files) | `ns.PackDatabase["imported"]` = array of packs; CombatWatcher uses any string key; must wire auto-select after populate |
| DATA-12 | Packs are dynamically built from imported route data, not hardcoded in data files | Pipeline replaces hardcoded pack definitions; `Data/WindrunnerSpire.lua` retains only AbilityDB entries |
</phase_requirements>

---

## Standard Stack

### Core
| Component | Version/Source | Purpose | Why Standard |
|-----------|---------------|---------|--------------|
| `ns.MDTDecode` | Import/Decode.lua (Phase 8) | Decode MDT export string → preset table | Already built, tested via `/tpw decode` |
| `ns.AbilityDB` | Data/WindrunnerSpire.lua (Phase 8) | npcID → `{mobClass, abilities}` | Already built, keyed exactly for this use |
| `ns.PackDatabase` | Core.lua | Dungeon key → array of pack tables | Existing engine contract; unchanged format |
| `ns.db` | TerriblePackWarningsDB SavedVariables | `ns.db.importedRoute` persistence | Initialized in Core.lua ADDON_LOADED; ready to use |

### Supporting
| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `ns.DungeonEnemies` (new) | dungeonIdx → array of enemy entries | Looked up during import for npcID resolution |
| `DUNGEON_IDX_MAP` (new, local) | dungeonIdx → string key + display name | Resolves dungeon identity from preset |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Single `Data/DungeonEnemies.lua` | Per-dungeon files in `Data/Dungeons/` | Per-dungeon is cleaner for many dungeons but adds load_*.xml complexity; single file is simpler for v0.0.3's scope of 9 Midnight dungeons |
| `ns.PackDatabase["imported"]` (single key) | `ns.PackDatabase[dungeonKey]` (dynamic key) | Single key is simpler — there is only ever one imported route at a time in v0.0.3; avoids need to clear stale dungeon keys |

**Installation:** No new libraries needed.

---

## MDT Preset Structure (Verified from MDT Source)

### Decoded Preset Layout

```lua
-- preset (the table returned by ns.MDTDecode)
preset = {
    text = "My Route Name",          -- preset name string
    uid  = "...",                    -- unique ID
    value = {
        currentDungeonIdx = 152,     -- integer, indexes into MDT.dungeonEnemies
        currentPull       = 3,       -- currently active pull in MDT (not used by us)
        pulls = {
            [1] = {                  -- pull 1
                -- keys are enemyIdx (integer), values are arrays of cloneIdx integers
                [3]  = { 1, 2 },     -- enemy at dungeonEnemies[idx][3], clones 1 and 2
                [7]  = { 1 },
                ["color"] = "ff2020ff",  -- optional pull color string (skip this key)
            },
            [2] = {
                [3]  = { 3 },
                [11] = { 1, 2, 3 },
            },
            -- ...
        },
    },
}
```

**Source:** `MythicDungeonTools/Modules/DungeonEnemies.lua` lines 771-798 (AddOrRemoveBlipToCurrentPull shows write pattern); `MythicDungeonTools/MythicDungeonTools.lua` line 3442 (read pattern `for enemyIdx, clones in pairs(preset.value.pulls[idx])`); `MythicDungeonTools/Modules/Transmission.lua` line 401 (`preset.value.currentDungeonIdx` access).

**Critical:** The pulls table has non-integer keys like `"color"`. The iteration must skip non-numeric keys with `if tonumber(enemyIdx) then`.

### MDT dungeonEnemies Entry Structure

```lua
-- MDT.dungeonEnemies[dungeonIdx][enemyIdx]
{
    ["name"]        = "Restless Steward",
    ["id"]          = 232070,        -- THIS IS THE npcID
    ["count"]       = 7,
    ["health"]      = 1242693,
    ["scale"]       = 1.2,
    ["displayId"]   = 136509,
    ["creatureType"] = "Undead",
    ["level"]       = 90,
    ["spells"]      = { [1216135] = {}, ... },
    ["clones"]      = {
        [1] = { ["x"] = ..., ["y"] = ..., ["g"] = 2, ["sublevel"] = 1 },
        -- ...
    },
}
```

**Source:** `MythicDungeonTools/Midnight/WindrunnerSpire.lua` lines 40-96 (direct inspection).

The `id` field is the npcID used for `ns.AbilityDB` lookup.

### dungeonIdx → Dungeon Identity (Midnight Season)

| dungeonIdx | englishName |
|-----------|-------------|
| 11 | Seat of the Triumvirate |
| 45 | Algethar Academy |
| 150 | Pit of Saron |
| 151 | Skyreach |
| 152 | Windrunner Spire |
| 153 | Magisters Terrace |
| 154 | Maisara Caverns |
| 155 | Nexus Point Xenas |
| 160 | Murder Row |

**Source:** Verified by reading all `Midnight/*.lua` files — each sets `local dungeonIndex = N` and `englishName = "..."` in `MDT.mapInfo`.

---

## Architecture Patterns

### Recommended Project Structure

```
TerriblePackWarnings/
├── Core.lua                    -- ADDON_LOADED: call ns.Import.RestoreFromSaved()
├── Data/
│   ├── WindrunnerSpire.lua     -- ns.AbilityDB entries (unchanged)
│   └── DungeonEnemies.lua      -- NEW: ns.DungeonEnemies[dungeonIdx] tables
├── Import/
│   ├── Decode.lua              -- ns.MDTDecode (unchanged)
│   └── Pipeline.lua            -- NEW: ns.Import.Run(), ns.Import.RestoreFromSaved(), ns.Import.Clear()
└── TerriblePackWarnings.toc    -- add new files after existing entries
```

### Pattern 1: Import Pipeline Function

```lua
-- Import/Pipeline.lua

local addonName, ns = ...

ns.Import = {}
local Import = ns.Import

-- dungeonIdx → { key, displayName } for all currently-supported MDT dungeons
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
-- @param pullData    table    preset.value.pulls[pullIdx] (enemyIdx → {cloneIdxs})
-- @param dungeonIdx  number   MDT dungeon index, for ns.DungeonEnemies lookup
-- @return table  pack object matching PackDatabase format
local function BuildPack(pullIdx, pullData, dungeonIdx)
    local pack = {
        displayName = "Pull " .. pullIdx,
        npcIDs      = {},   -- flat list for reference/UI use
        abilities   = {},   -- array, same structure as hardcoded pack.abilities
    }

    local enemies = ns.DungeonEnemies[dungeonIdx]
    if not enemies then return pack end

    -- Track which npcIDs/abilities we've already added (dedup per pack)
    local seenNpc = {}
    local seenAbility = {}

    for enemyIdx, clones in pairs(pullData) do
        if tonumber(enemyIdx) and enemies[enemyIdx] then
            local npcID = enemies[enemyIdx].id

            if not seenNpc[npcID] then
                seenNpc[npcID] = true
                table.insert(pack.npcIDs, npcID)

                local entry = ns.AbilityDB[npcID]
                if entry then
                    for _, ability in ipairs(entry.abilities) do
                        local key = ability.spellID .. "_" .. entry.mobClass
                        if not seenAbility[key] then
                            seenAbility[key] = true
                            -- Shallow copy so pack owns its data
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
function Import.RunFromPreset(preset)
    local dungeonIdx = preset.value and preset.value.currentDungeonIdx
    local pulls      = preset.value and preset.value.pulls

    if not dungeonIdx or not pulls then
        print("|cff00ccffTPW|r Import error: preset missing required fields")
        return false
    end

    local dungeonInfo = DUNGEON_IDX_MAP[dungeonIdx]
    local dungeonName = dungeonInfo and dungeonInfo.name or ("Dungeon #" .. dungeonIdx)

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

    -- Persist processed data
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
    -- Reset CombatWatcher state
    ns.NameplateScanner:Stop()
    ns.Scheduler:Stop()
    print("|cff00ccffTPW|r Import cleared.")
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end
```

### Pattern 2: DungeonEnemies Data File

```lua
-- Data/DungeonEnemies.lua

local addonName, ns = ...

ns.DungeonEnemies = ns.DungeonEnemies or {}

-- dungeonIdx 152 = Windrunner Spire (Midnight season)
-- Sourced from MythicDungeonTools/Midnight/WindrunnerSpire.lua
-- Only fields used by Pipeline.lua are kept: id (npcID), name, displayId, clones count
-- Full clone coordinate data is omitted — we only need npcID resolution

ns.DungeonEnemies[152] = {
    [1]  = { id = 232070, name = "Restless Steward",   displayId = 136509 },
    [2]  = { id = 232071, name = "Dutiful Groundskeeper", displayId = 136510 },
    -- ... (all entries from MDT file)
}

-- Additional dungeons follow same pattern
-- ns.DungeonEnemies[151] = { ... }   -- Skyreach
-- etc.
```

**Note:** The clone coordinate data can be omitted from the bundled copy. We only need `id` (npcID), `name`, and optionally `displayId`. This keeps the file size manageable.

### Pattern 3: Pack Format (Verified from Engine Consumers)

```lua
-- Pack structure consumed by NameplateScanner, Scheduler, CombatWatcher, PackFrame

pack = {
    displayName = "Pull 1",       -- string shown in PackFrame UI
    npcIDs      = { 232070, ... }, -- new field for Phase 10 portrait icons
    abilities = {
        {
            name       = "Interrupting Screech",
            spellID    = 471643,
            mobClass   = "PALADIN",    -- used by NameplateScanner.Tick() UnitClass match
            first_cast = 20,           -- optional (nil = untimed/static icon)
            cooldown   = 25,           -- optional (nil = untimed/static icon)
            label      = "Kick",       -- shown on icon
            ttsMessage = "Stop Casting", -- optional TTS string
        },
    },
}
```

**Contract verified from:**
- `NameplateScanner.lua` line 39: `for _, ability in ipairs(activePack.abilities)` — iterates abilities
- `NameplateScanner.lua` line 41: `if ability.mobClass == classBase` — class match
- `NameplateScanner.lua` line 43: `if ability.cooldown then` — timed vs untimed
- `Scheduler.lua` line 39: `ns.IconDisplay.ShowIcon(barId, ability.spellID, ability.ttsMessage, ability.first_cast, ability.label)` — all fields used
- `CombatWatcher.lua` line 63: `dungeon[packIndex].displayName` — display name used

### Pattern 4: Core.lua Changes Required

```lua
-- In the ADDON_LOADED handler, after ns.db = TerriblePackWarningsDB:
if ns.Import and ns.Import.RestoreFromSaved then
    ns.Import.RestoreFromSaved()
end

-- In the slash command handler, add:
elseif cmd == "import" then
    if arg == "" then
        print("|cff00ccffTPW|r Usage: /tpw import <MDT export string>")
    else
        ns.Import.RunFromString(arg)
    end
elseif cmd == "clear" then
    ns.Import.Clear()
```

### Pattern 5: TOC Load Order

```
-- TerriblePackWarnings.toc additions (order matters):
Data\DungeonEnemies.lua     -- before Pipeline.lua (ns.DungeonEnemies must exist)
Import\Pipeline.lua         -- after Decode.lua and DungeonEnemies.lua
```

`ns.AbilityDB` is populated by `Data/WindrunnerSpire.lua` which loads before `Import/Pipeline.lua` — no change needed there.

### Anti-Patterns to Avoid

- **Iterating pulls without `tonumber(enemyIdx)` guard:** The pulls table contains `["color"]` string keys mixed with integer enemy indices. Calling `enemies[enemyIdx]` with a string key crashes or returns nil silently. Always guard: `if tonumber(enemyIdx) then`.
- **Re-decoding on login:** CONTEXT.md locks "no re-decoding on ADDON_LOADED". Save processed pack data, not the raw MDT string.
- **Saving the full clone coordinate data:** Clones in MDT entries have x/y/sublevel. This is not needed and adds SavedVariables bloat. Strip to `{id, name, displayId}` in the bundled data file.
- **Expecting sequential pull indices:** MDT pulls array is 1-based and sequential for standard routes, but use `for pullIdx = 1, #pulls` not `pairs` to preserve order.
- **Not deduplicating npcIDs within a pull:** A pull can contain multiple clones of the same enemy (e.g. `[3] = {1, 2}`). Without the `seenNpc` guard, abilities would be added multiple times, creating duplicate timer icons.
- **CombatWatcher zone auto-detect after import:** The existing `CombatWatcher:Reset()` uses `ZONE_DUNGEON_MAP` which has no "imported" key. After import we call `SelectDungeon("imported")` explicitly. On zone change, `Reset()` will clear state — this is correct behavior (import is cleared when zone changes, user re-imports for next run). Do NOT add "imported" to `ZONE_DUNGEON_MAP`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| MDT string decoding | Custom decode chain | `ns.MDTDecode` (Phase 8) | Already built and tested |
| Ability lookup | Secondary ability map | `ns.AbilityDB[npcID]` directly | Phase 8 built this exactly for import use |
| Pack persistence | Custom serialization | `ns.db.importedRoute = packs` (SavedVariables) | WoW handles Lua table serialization automatically |
| Pull ordering | Sort/reorder logic | Iterate `pulls[1..#pulls]` in order | MDT stores pulls as ordered array |

---

## Common Pitfalls

### Pitfall 1: String Keys in Pulls Table
**What goes wrong:** `preset.value.pulls[pullIdx]` is iterated with `pairs()`. The `["color"]` key is a string that equals `"color"`, not a number. `enemies["color"]` is nil, so `enemies["color"].id` crashes.
**Why it happens:** MDT stores the pull color as a string key in the same table as the enemy entries.
**How to avoid:** Guard every enemyIdx with `if tonumber(enemyIdx) then` before accessing `enemies[enemyIdx]`.
**Warning signs:** Nil indexing error mentioning "id" field on a pulls-related path.

### Pitfall 2: Missing DungeonEnemies Entry
**What goes wrong:** `ns.DungeonEnemies[dungeonIdx]` is nil for a dungeon that exists in MDT but hasn't been added to our bundled data yet. Import produces empty packs for all pulls.
**Why it happens:** We only bundle Midnight dungeons initially. A user might import a MistsOfPandaria route.
**How to avoid:** CONTEXT.md locks "unknown dungeons build packs with mob data but no skill tracking." If `enemies` is nil, still create the pack with `displayName` set, just no npcIDs or abilities. Add a warning print: "Unknown dungeon idx %d — packs will have no tracked abilities."
**Warning signs:** All packs import with 0 abilities for a valid MDT string.

### Pitfall 3: SavedVariables Timing
**What goes wrong:** `ns.db` is nil when `Import.RestoreFromSaved()` runs if called too early.
**Why it happens:** `ns.db = TerriblePackWarningsDB` is set in ADDON_LOADED. Any call before ADDON_LOADED fires will see `ns.db = nil`.
**How to avoid:** Call `Import.RestoreFromSaved()` from inside the ADDON_LOADED handler in Core.lua, after `ns.db = TerriblePackWarningsDB`.
**Warning signs:** Lua error "attempt to index a nil value (global 'ns')" or "attempt to index field 'db' (a nil value)".

### Pitfall 4: PackFrame Hardcoded DUNGEON_NAMES
**What goes wrong:** PackFrame.lua has `DUNGEON_NAMES = { windrunner_spire = "Windrunner Spire" }`. The new "imported" key will fall back to the raw key as display name.
**Why it happens:** PackFrame hardcodes known dungeon keys for display.
**How to avoid:** Add `imported = "Imported Route"` to `DUNGEON_NAMES` in PackFrame.lua, OR add a `dungeonDisplayName` field to `ns.db.importedRoute` and read it from there in PackFrame. The per-pack display names will still say "Pull 1", "Pull 2" etc. which is fine. This is a minor issue.
**Warning signs:** PackFrame header shows "imported" instead of a readable name.

### Pitfall 5: CombatWatcher SelectDungeon Validation
**What goes wrong:** `CombatWatcher:SelectDungeon("imported")` is called before `ns.PackDatabase["imported"]` is populated, causing "unknown dungeon key" error.
**Why it happens:** If `RestoreFromSaved` assigns packs first and then calls SelectDungeon, this is fine. But if order is reversed it fails.
**How to avoid:** Always assign `ns.PackDatabase["imported"] = packs` before calling `ns.CombatWatcher:SelectDungeon("imported")`.

---

## Code Examples

### Verified Pull Iteration Pattern (from MDT source)

```lua
-- Source: MythicDungeonTools/MythicDungeonTools.lua line 3442
for enemyIdx, clones in pairs(preset.value.pulls[idx]) do
    if tonumber(enemyIdx) then
        local npcId = MDT.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["id"]
        -- ...
    end
end
```

Our equivalent:

```lua
for enemyIdx, clones in pairs(pullData) do
    if tonumber(enemyIdx) and enemies[enemyIdx] then
        local npcID = enemies[enemyIdx].id
        local entry = ns.AbilityDB[npcID]
        -- ...
    end
end
```

### Verified PackDatabase Read Pattern (from CombatWatcher)

```lua
-- Source: Engine/CombatWatcher.lua line 33
local dungeon = ns.PackDatabase[dungeonKey]
if not dungeon or #dungeon == 0 then ... return end
```

After import, `ns.PackDatabase["imported"]` must be a non-empty array for SelectDungeon to accept it.

### Verified SavedVariables Pattern (from Core.lua)

```lua
-- Source: Core.lua lines 21-25
if not TerriblePackWarningsDB then
    TerriblePackWarningsDB = {}
end
ns.db = TerriblePackWarningsDB
```

Adding `ns.db.importedRoute` persists automatically — no additional setup needed.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Hardcoded pack arrays in data files | Dynamic packs from MDT import | Data files now only define `ns.AbilityDB` entries; packs are transient (rebuilt from SavedVariables) |
| `ns.PackDatabase["windrunner_spire"]` static key | `ns.PackDatabase["imported"]` single dynamic key | CombatWatcher is key-agnostic; no engine changes needed |

**Deprecated/outdated:**
- `Data/WindrunnerSpire.lua` pack definitions: Any hardcoded `ns.PackDatabase["windrunner_spire"]` entries from earlier phases should be removed so the UI doesn't show a stale hardcoded dungeon alongside the imported one. The file retains only `ns.AbilityDB` entries.

---

## Open Questions

1. **Does `Data/WindrunnerSpire.lua` currently contain hardcoded PackDatabase entries?**
   - What we know: The file currently only contains `ns.AbilityDB` entries (confirmed by reading the file). There are no `ns.PackDatabase` entries in it.
   - What's unclear: Nothing — this is confirmed clean. No removal needed.
   - Recommendation: No action needed on WindrunnerSpire.lua for this phase.

2. **How many enemies are in Windrunner Spire's MDT data file?**
   - What we know: The file starts at `dungeonEnemies[dungeonIndex] = { [1] = ..., [2] = ... }` and has many entries.
   - What's unclear: Exact count (file not fully read, but not required for planning).
   - Recommendation: The planner should create a task to copy all `{id, name, displayId}` entries for dungeonIdx 152. A subtask verifying the pull count from a real MDT export would be valuable.

3. **Should `ns.DungeonEnemies` include all 9 Midnight dungeons or just Windrunner Spire?**
   - What we know: CONTEXT.md locks "bundle MDT's full dungeonEnemies data for all available dungeons."
   - What's unclear: Nothing — all 9 Midnight dungeons are locked in scope.
   - Recommendation: Include all 9 Midnight dungeons in `Data/DungeonEnemies.lua`. The MistsOfPandaria set (indices 130-138) is not part of the Midnight season pool and should be excluded for v0.0.3.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — WoW addon Lua, no automated test runner available |
| Config file | none |
| Quick run command | `/tpw decode <MDT string>` then `/tpw status` in-game |
| Full suite command | Manual: import a known MDT string, verify pull count and ability count in chat output |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| IMPORT-02 | Extract pull list with npcIDs from decoded preset | manual-only | `/tpw import <string>` → check summary line pull count | N/A |
| IMPORT-03 | Match npcIDs to AbilityDB, correct mobClass | manual-only | Import Windrunner Spire route → verify "(N with tracked abilities)" > 0 | N/A |
| IMPORT-04 | PackDatabase populated; packs survive reload | manual-only | `/reload` after import → verify restored message in chat | N/A |
| DATA-12 | No hardcoded pack data drives combat | manual-only | Remove `Data/WindrunnerSpire.lua` pack entries → combat still works after import | N/A |

**Justification for manual-only:** WoW addon Lua runs inside the game client. There is no off-client test runner for this codebase. All tests are in-game chat command sequences.

### Sampling Rate
- **Per task:** Load addon in-game, run `/tpw import <string>`, verify chat output
- **Per wave merge:** Full flow: import → pull → combat start → timer fires → reload → restore
- **Phase gate:** All four requirements verified manually before `/gsd:verify-work`

### Wave 0 Gaps
None — no test framework to set up. Validation is in-game only.

---

## Sources

### Primary (HIGH confidence)
- `MythicDungeonTools/Modules/DungeonEnemies.lua` lines 771-816 — pull structure write pattern, confirming `pulls[pullIdx][enemyIdx] = {cloneIdxs}` format
- `MythicDungeonTools/MythicDungeonTools.lua` line 3442 — pull structure read pattern with `tonumber(enemyIdx)` guard
- `MythicDungeonTools/Modules/Transmission.lua` line 401 — `preset.value.currentDungeonIdx` field path confirmed
- `MythicDungeonTools/Midnight/WindrunnerSpire.lua` lines 4-96 — dungeonIndex 152, dungeonEnemies structure with `id`, `name`, `displayId`, `clones` fields
- All `MythicDungeonTools/Midnight/*.lua` files — dungeonIndex values and englishName for all 9 Midnight dungeons
- `TerriblePackWarnings/Engine/NameplateScanner.lua` — pack.abilities contract (mobClass, spellID, cooldown, label)
- `TerriblePackWarnings/Engine/Scheduler.lua` — ability field usage (spellID, ttsMessage, first_cast, label)
- `TerriblePackWarnings/Engine/CombatWatcher.lua` — PackDatabase["key"] → array-of-packs contract, displayName usage
- `TerriblePackWarnings/Core.lua` — SavedVariables initialization pattern, slash command structure
- `TerriblePackWarnings/Data/WindrunnerSpire.lua` — confirms no PackDatabase entries exist (AbilityDB only)

### Secondary (MEDIUM confidence)
- None — all findings sourced directly from code.

### Tertiary (LOW confidence)
- None.

---

## Metadata

**Confidence breakdown:**
- MDT preset structure: HIGH — read directly from MDT source code
- Pack format contract: HIGH — read directly from all engine consumers
- SavedVariables pattern: HIGH — read directly from Core.lua
- Dungeon index mapping: HIGH — read all Midnight .lua files
- DungeonEnemies entry format: HIGH — read WindrunnerSpire.lua directly

**Research date:** 2026-03-16
**Valid until:** 2026-04-16 (stable — MDT dungeon data format is very stable; engine code is project-internal)
