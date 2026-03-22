# Architecture Research

**Domain:** WoW Midnight (12.0) addon — v0.1.0 integration architecture for configuration UI, ability data, cast detection, and per-dungeon routes
**Researched:** 2026-03-17
**Confidence:** HIGH — derived from direct source analysis of all 10 existing Lua files. No external research needed; all integration questions answered from the code itself.

---

## Current Architecture (as of v0.0.4)

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                          UI Layer                                 │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  UI/PackFrame.lua — pack selection window, import popup   │    │
│  └──────────────────────────┬─────────────────────────────┘    │
│                              │ reads PackDatabase, calls CW      │
├──────────────────────────────┼───────────────────────────────────┤
│                         Engine Layer                              │
│  ┌────────────────┐  ┌───────┴──────┐  ┌──────────────────────┐  │
│  │ CombatWatcher  │  │  Scheduler   │  │  NameplateScanner    │  │
│  │ state machine  │  │ timer/icon   │  │  0.25s poll loop     │  │
│  └───────┬────────┘  └──────┬───────┘  └──────────┬───────────┘  │
│          └──────────────────┴────────────────────┘              │
│                              │ drives                             │
├──────────────────────────────┼───────────────────────────────────┤
│                       Display Layer                               │
│  ┌───────────────────────────┴───────────────────────────────┐   │
│  │    Display/IconDisplay.lua — spell icon squares, sweep     │   │
│  └───────────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│                     Import / Data Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ Import/      │  │ Data/        │  │ Data/                   │ │
│  │ Decode.lua   │  │ DungeonEnemies│  │ WindrunnerSpire.lua     │ │
│  │ Pipeline.lua │  │ .lua (9 dung)│  │ (AbilityDB, npcID keyed)│ │
│  └──────────────┘  └──────────────┘  └─────────────────────────┘ │
├──────────────────────────────────────────────────────────────────┤
│                     Persistence Layer                             │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  TerriblePackWarningsDB  (SavedVariables, account-wide)   │   │
│  │  .debug  .windowPos  .importedRoute{dungeonName,packs}    │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### Load Order (TOC)

```
Libs\load_libs.xml
Core.lua                   ← namespace, ns.PackDatabase, ns.AbilityDB initialized
Engine\Scheduler.lua
Engine\NameplateScanner.lua
Engine\CombatWatcher.lua
Display\IconDisplay.lua
Import\Decode.lua
Data\DungeonEnemies.lua    ← writes ns.DungeonEnemies at file scope
Data\WindrunnerSpire.lua   ← writes ns.AbilityDB[npcID] at file scope
Import\Pipeline.lua        ← reads ns.AbilityDB and ns.DungeonEnemies
UI\PackFrame.lua           ← reads ns.AbilityDB at file scope for portrait lookup
```

Data files populate shared tables at file-load time before any ADDON_LOADED event fires. Pipeline.lua must load after all Data files. UI files must load after Pipeline.

---

## Target Architecture (v0.1.0)

### What Changes

```
┌──────────────────────────────────────────────────────────────────┐
│                          UI Layer                                 │
│  ┌─────────────────────┐   ┌──────────────────────────────────┐  │
│  │   UI/PackFrame.lua  │   │     UI/ConfigFrame.lua  (NEW)    │  │
│  │  +dungeon selector  │   │  dungeon→mob→skill tree          │  │
│  │  +mob count per row │   │  per-skill toggle/label/TTS/sound│  │
│  └──────────┬──────────┘   └──────────────┬───────────────────┘  │
│             │ reads PackDatabase            │ reads/writes         │
│             │                              │ ns.db.skillConfig    │
├─────────────┴──────────────────────────────┴─────────────────────┤
│                         Engine Layer                              │
│  ┌────────────────┐  ┌───────────────┐  ┌──────────────────────┐  │
│  │ CombatWatcher  │  │  Scheduler    │  │   NameplateScanner   │  │
│  │ +expanded zone │  │  unchanged    │  │  +UnitCastingInfo    │  │
│  │  map (9 dung.) │  │               │  │   polling for untimed│  │
│  │ +per-dungeon   │  │               │  │  +castHighlightActive│  │
│  │  key selection │  │               │  │   tracking           │  │
│  └───────┬────────┘  └───────┬───────┘  └──────────┬───────────┘  │
│          └──────────────────┴────────────────────┘               │
├──────────────────────────────────────────────────────────────────┤
│                       Display Layer                               │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │    Display/IconDisplay.lua                                 │   │
│  │    +SetCastHighlight / ClearCastHighlight (untimed)        │   │
│  │    +PlaySoundFile support in SetUrgent and SetCastHighlight │   │
│  └───────────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│                     Import / Data Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ Import/      │  │ Data/        │  │ Data/*.lua (8 new files) │ │
│  │ Pipeline.lua │  │ DungeonEnemies│  │ one per remaining dungeon│ │
│  │ +per-dungeon │  │ unchanged    │  │ same schema as           │ │
│  │  key write   │  │               │  │ WindrunnerSpire.lua     │ │
│  │ +skillConfig │  │               │  │                         │ │
│  │  merge       │  │               │  │                         │ │
│  └──────────────┘  └──────────────┘  └─────────────────────────┘ │
├──────────────────────────────────────────────────────────────────┤
│                     Persistence Layer                             │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  TerriblePackWarningsDB  (SavedVariables, account-wide)   │   │
│  │  .debug   .windowPos   .configPos                         │   │
│  │  .importedRoutes { [dungeonKey] = {dungeonName, dungeonIdx,│   │
│  │                                    packs} }               │   │
│  │  .skillConfig { [npcID] = { [spellID] = {                 │   │
│  │      enabled, label, ttsMessage, soundFile } } }          │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Integration Questions Answered

### Q1: Where does MDT-extracted ability data live — new Data/ files per dungeon or single consolidated file?

**Answer: One file per dungeon, following the existing WindrunnerSpire.lua pattern.**

`Data/WindrunnerSpire.lua` establishes the schema: write into `ns.AbilityDB[npcID]` at file scope. Each new dungeon gets its own file (e.g., `Data/AlgetharAcademy.lua`). Never consolidate into one large file.

Rationale:
- A syntax error in one dungeon's file does not prevent others from loading.
- Adding or updating a dungeon is a single-file change with no merge conflicts.
- PackFrame.lua reads `ns.AbilityDB` at file scope to build `npcIdToClass` — this table is correct as long as all Data files load before PackFrame.lua in the TOC.
- Pipeline.lua reads `ns.AbilityDB[npcID]` per-enemy when building packs — all data files must load before Pipeline.lua.

New files use the same schema. For abilities that are untimed (cast-detected), omit `first_cast` and `cooldown`. Default `mobClass` to `"WARRIOR"` for MDT-imported abilities since MDT does not store class data.

```lua
-- Data/AlgetharAcademy.lua
local addonName, ns = ...
ns.AbilityDB = ns.AbilityDB or {}

ns.AbilityDB[196577] = {  -- Spellbound Battleaxe
    mobClass = "WARRIOR",
    abilities = {
        {
            name    = "Arcane Slash",
            spellID = 388685,
            label   = "Slash",
            -- no first_cast/cooldown = untimed, cast-detected
        },
    },
}
```

TOC additions: all 8 new Data files load after `Data/DungeonEnemies.lua` and before `Import/Pipeline.lua`.

---

### Q2: How should per-skill config be stored in SavedVariables?

**Answer: Sparse override map at `ns.db.skillConfig[npcID][spellID]`. Store only user-modified fields, never a full copy of ability data.**

The merge helper is called inside `Pipeline.BuildPack()` when assembling pack abilities. This means every imported route automatically reflects current skill config at import time.

```lua
-- Stored in TerriblePackWarningsDB:
ns.db.skillConfig = {
    [232113] = {           -- npcID: Spellguard Magus
        [1253686] = {      -- spellID: Spellguard's Protection
            enabled    = false,
            label      = "BLOCK",
            ttsMessage = "Block it now",
            soundFile  = "Sound\\Spells\\...\\SpellAlert.ogg",
        },
    },
}
```

Merge helper used in Pipeline.lua:
```lua
local function MergeSkillConfig(npcID, ability)
    local cfg = ns.db.skillConfig
        and ns.db.skillConfig[npcID]
        and ns.db.skillConfig[npcID][ability.spellID]
    if not cfg then return ability end
    if cfg.enabled == false then return nil end  -- disabled: skip
    return {
        name       = ability.name,
        spellID    = ability.spellID,
        mobClass   = ability.mobClass,
        first_cast = ability.first_cast,
        cooldown   = ability.cooldown,
        label      = cfg.label      or ability.label,
        ttsMessage = cfg.ttsMessage or ability.ttsMessage,
        soundFile  = cfg.soundFile,
    }
end
```

ConfigFrame writes directly to `ns.db.skillConfig[npcID][spellID]`. Changes take effect on the next import or route rebuild — no hot-swap of in-memory pack data needed for this milestone.

---

### Q3: Where does cast detection (UnitCastingInfo polling) fit?

**Answer: Extend the existing NameplateScanner Tick() loop. No new ticker.**

The 0.25s ticker already iterates all nameplates. Extend the body of `Scanner:Tick()` to call `UnitCastingInfo(npUnit)` for hostile mobs whose class matches an untimed ability. Track which static icon keys are currently highlighted so the clear signal fires when the cast ends.

Key facts:
- `UnitCastingInfo` return value at index 9 is the spellID (number, locale-independent). Do not compare by spell name string.
- The 0.25s interval is sufficient: casts are 1.5-3s minimum, so detection lag is imperceptible.
- Adding this inside the existing Tick() loop adds at most 1 API call per hostile nameplate per tick, only when untimed abilities are active. At 5-10 nameplates this is negligible.

State needed in NameplateScanner:
```lua
-- spellID -> true if the cast highlight is currently active
local castHighlightActive = {}
```

Extension to Tick():
```lua
-- After the existing in-combat count block, inside the nameplate loop:
if cached.hostile and cached.classBase and activePack then
    for _, ability in ipairs(activePack.abilities) do
        if not ability.cooldown
           and ability.mobClass == cached.classBase
           and staticShown[ability.spellID]
        then
            -- UnitCastingInfo: return[9] is spellID (number)
            local _, _, _, _, _, _, _, _, castSpellID = UnitCastingInfo(npUnit)
            local castKey = "static_" .. ability.spellID
            if castSpellID == ability.spellID then
                if not castHighlightActive[ability.spellID] then
                    castHighlightActive[ability.spellID] = true
                    ns.IconDisplay.SetCastHighlight(castKey)
                end
            else
                if castHighlightActive[ability.spellID] then
                    castHighlightActive[ability.spellID] = nil
                    ns.IconDisplay.ClearCastHighlight(castKey)
                end
            end
        end
    end
end
```

`castHighlightActive` must be wiped in `Scanner:Stop()`.

---

### Q4: How does per-dungeon route storage change the PackDatabase["imported"] single-key pattern?

**Answer: Replace the single "imported" key with per-dungeon keys (e.g., "windrunner_spire"). Replace `ns.db.importedRoute` (single object) with `ns.db.importedRoutes` (map of dungeonKey → routeData).**

Changes required in Pipeline.lua:
```lua
-- Before
ns.PackDatabase["imported"] = packs
ns.db.importedRoute = { dungeonName=..., dungeonIdx=..., packs=... }

-- After
local dungeonKey = dungeonInfo.key  -- e.g. "windrunner_spire"
ns.PackDatabase[dungeonKey] = packs
ns.db.importedRoutes = ns.db.importedRoutes or {}
ns.db.importedRoutes[dungeonKey] = { dungeonName=..., dungeonIdx=..., packs=... }
```

`Import.RestoreFromSaved()` iterates `ns.db.importedRoutes` (the map) instead of reading the single `ns.db.importedRoute` object.

`Import.Clear()` takes an optional `dungeonKey` argument. Without it, clear all routes; with it, clear only that dungeon.

`CombatWatcher:Reset()` checks `ns.db.importedRoutes` for the current zone's dungeon key and selects it automatically instead of always selecting "imported".

`PackFrame.lua` must be updated in two places:
1. `PopulateList()` reads from `ns.PackDatabase[activeDungeon]` where `activeDungeon` is the dungeon key (e.g. "windrunner_spire"), not "imported".
2. The dungeon selector widget populates from `ns.db.importedRoutes` (showing all dungeons with imported routes).

**Migration note:** `ns.db.importedRoute` (old key) and `ns.db.importedRoutes` (new key) are different names. On first login after update, the old key is ignored and no route is restored. This is acceptable — users re-import once. No migration code needed.

---

### Q5: Where does the config window code go?

**Answer: New file `UI/ConfigFrame.lua`, loaded last in the TOC, frame created lazily on first open.**

ConfigFrame is a separate top-level frame (`TPWConfigFrame`). It opens via a "Config" button added to the footer of PackFrame, or via `/tpw config` slash command.

The frame is built lazily (inside a `ConfigFrame.Open()` function with `if not configFrame then ... end` guard) to keep load-time cost zero. The config window is rarely opened; no reason to create dozens of widgets at login.

ConfigFrame reads `ns.AbilityDB` to enumerate all known dungeons, mobs, and abilities. It reads `ns.db.skillConfig` for current user values. On any widget change, it writes immediately to `ns.db.skillConfig[npcID][spellID]`.

When the user closes ConfigFrame, call `PackUI:Refresh()` to rebuild the displayed route if one is active. A full re-import is not needed unless the user explicitly clicks a "Rebuild" button — existing in-memory packs reflect the skillConfig at the time of import. For live changes to take effect on the currently-running pack, a `Scheduler:Stop()` + `NameplateScanner:Stop()` + re-select cycle may be needed, but that can be a v0.1.0 limitation.

TOC addition at end:
```
UI\PackFrame.lua
UI\ConfigFrame.lua
```

Core.lua slash command extension:
```lua
elseif cmd == "config" then
    if ns.ConfigUI and ns.ConfigUI.Toggle then ns.ConfigUI.Toggle() end
```

---

### Q6: How does the highlighting rework change IconDisplay and Scheduler?

**Answer: Two distinct highlight paths — timed uses the existing SetUrgent (pre-warning timer), untimed uses new SetCastHighlight (cast detected). Both can trigger sound. The existing ShowStaticIcon path is unchanged structurally.**

**Timed ability pre-warning (unchanged path, add sound):**
- Scheduler fires at `first_cast - 5` seconds
- Calls `ns.IconDisplay.SetUrgent(barId)` — existing red glow + TTS
- Add: if the ability's slot has a `soundFile`, call `PlaySoundFile(soundFile, "Master")`

**Untimed ability cast highlight (new path):**
- NameplateScanner detects `UnitCastingInfo` match
- Calls `ns.IconDisplay.SetCastHighlight("static_" .. spellID)` — visually distinct from SetUrgent (e.g. orange glow or pulsing border, not red)
- Plays sound if `slot.soundFile` is set
- When cast ends, NameplateScanner calls `ns.IconDisplay.ClearCastHighlight(key)` — reverts to normal static state

New functions to add to IconDisplay.lua:
```lua
--- SetCastHighlight: highlight an untimed icon when a cast is in progress.
-- Visually distinct from SetUrgent (orange glow, not red).
function ns.IconDisplay.SetCastHighlight(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end
    ShowOrangeGlow(slot)  -- new helper, same pattern as ShowGlow but orange
    if slot.soundFile then
        PlaySoundFile(slot.soundFile, "Master")
    end
end

--- ClearCastHighlight: remove cast highlight when the cast ends.
function ns.IconDisplay.ClearCastHighlight(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end
    HideGlow(slot)
end
```

The existing `ShowStaticIcon` stores a reference in `slot` that NameplateScanner uses by the `instanceKey`. The slot must also store `soundFile`:
```lua
-- In ShowStaticIcon (and ShowIcon):
slot.soundFile = ability and ability.soundFile or nil
```

Because `ShowStaticIcon` currently does not receive an ability table (only `instanceKey`, `spellID`, `label`), the caller (NameplateScanner.OnMobsAdded) must pass `soundFile`:
```lua
-- NameplateScanner.OnMobsAdded:
ns.IconDisplay.ShowStaticIcon("static_" .. ability.spellID, ability.spellID, ability.label, ability.soundFile)
```

This is a one-line change to the ShowStaticIcon signature.

---

## Recommended File Structure (post-milestone)

```
TerriblePackWarnings/
├── Core.lua                        # +register ZONE_CHANGED_NEW_AREA; +/tpw config
├── TerriblePackWarnings.toc        # +8 data files, +ConfigFrame.lua
├── Engine/
│   ├── Scheduler.lua               # unchanged
│   ├── NameplateScanner.lua        # +UnitCastingInfo cast detection in Tick()
│   └── CombatWatcher.lua           # +expanded ZONE_DUNGEON_MAP; +auto-select from routes
├── Display/
│   └── IconDisplay.lua             # +SetCastHighlight/ClearCastHighlight; +sound playback
├── Import/
│   ├── Decode.lua                  # unchanged
│   └── Pipeline.lua                # +per-dungeon key; +skillConfig merge; +routes map restore
├── Data/
│   ├── DungeonEnemies.lua          # unchanged
│   ├── WindrunnerSpire.lua         # unchanged
│   ├── SeatOfTheTriumvirate.lua    # new
│   ├── AlgetharAcademy.lua         # new
│   ├── PitOfSaron.lua              # new
│   ├── Skyreach.lua                # new
│   ├── MagistersTerrace.lua        # new
│   ├── MaisaraCaverns.lua          # new
│   ├── NexusPointXenas.lua         # new
│   └── MurderRow.lua               # new (stub — no ability data yet)
└── UI/
    ├── PackFrame.lua               # +dungeon selector; +mob count per type
    └── ConfigFrame.lua             # new
```

### Updated TOC Load Order

```
Libs\load_libs.xml
Core.lua
Engine\Scheduler.lua
Engine\NameplateScanner.lua
Engine\CombatWatcher.lua
Display\IconDisplay.lua
Import\Decode.lua
Data\DungeonEnemies.lua
Data\WindrunnerSpire.lua
Data\SeatOfTheTriumvirate.lua
Data\AlgetharAcademy.lua
Data\PitOfSaron.lua
Data\Skyreach.lua
Data\MagistersTerrace.lua
Data\MaisaraCaverns.lua
Data\NexusPointXenas.lua
Data\MurderRow.lua
Import\Pipeline.lua
UI\PackFrame.lua
UI\ConfigFrame.lua
```

---

## Data Flows

### Import Flow (per-dungeon, v0.1.0)

```
User pastes MDT string in popup
    → Import.RunFromString(str)
    → ns.MDTDecode(str)                         -- Decode.lua: unchanged
    → Import.RunFromPreset(preset)              -- Pipeline.lua
    → dungeonKey = dungeonInfo.key              -- e.g. "windrunner_spire"
    → for each pull: BuildPack(pullIdx, pullData, dungeonIdx)
        → ns.AbilityDB[npcID]                   -- already loaded by Data/*.lua
        → MergeSkillConfig(npcID, ability)      -- applies ns.db.skillConfig overrides
    → ns.PackDatabase[dungeonKey] = packs
    → ns.db.importedRoutes[dungeonKey] = {...}
    → CombatWatcher:SelectDungeon(dungeonKey)
    → PackUI:Refresh()
```

### Login Restore Flow (multi-dungeon)

```
ADDON_LOADED fires → Import.RestoreFromSaved()
    → for dungeonKey, saved in pairs(ns.db.importedRoutes or {}) do
        → ns.PackDatabase[dungeonKey] = saved.packs
    → CombatWatcher:Reset() -- selects zone dungeon or first available route
    → PackUI:Refresh()
```

### Zone Auto-Switch Flow

```
PLAYER_ENTERING_WORLD fires → CombatWatcher:Reset()
    → GetInstanceInfo() → instanceName
    → ZONE_DUNGEON_MAP[instanceName] → dungeonKey (e.g. "windrunner_spire")
    → if ns.PackDatabase[dungeonKey] then
        → CombatWatcher:SelectDungeon(dungeonKey)
    → PackUI:Refresh()
```

### Config→Display Pipeline

```
ConfigFrame: user edits skill setting
    → ns.db.skillConfig[npcID][spellID].label = "NEW"
    ↓
(Next import or route rebuild)
Pipeline.BuildPack() calls MergeSkillConfig()
    → merged ability has updated label
    → ns.PackDatabase[dungeonKey] updated
    ↓
Scheduler.StartAbility(ability, barId)
    → IconDisplay.ShowIcon(barId, spellID, ttsMessage, duration, label)
    → slot.soundFile = ability.soundFile
    ↓
At pre-warning time: IconDisplay.SetUrgent(barId)
    → ShowGlow(slot) + TrySpeak(ttsMessage) + PlaySoundFile(soundFile)
```

### Cast Detection Flow (untimed abilities)

```
NameplateScanner:Tick() every 0.25s
    → for each hostile nameplate:
        → for each untimed ability matching mob class and staticShown:
            → UnitCastingInfo(npUnit) → [..., spellID at index 9]
            → if spellID matches ability.spellID:
                → castHighlightActive[ability.spellID] = true
                → IconDisplay.SetCastHighlight("static_" .. spellID)
            → else if was highlighted:
                → castHighlightActive[ability.spellID] = nil
                → IconDisplay.ClearCastHighlight("static_" .. spellID)
```

---

## Component Build Order

Build in this order to avoid blocked work:

1. **Data/*.lua for 8 remaining dungeons** — pure data, no code dependencies. Can be done entirely from MDT source at `C:\Users\jonat\Repositories\MythicDungeonTools`. Unblocks all dungeon ability coverage.

2. **IconDisplay.lua highlight rework** — add `SetCastHighlight`, `ClearCastHighlight`, sound playback, `soundFile` parameter to `ShowStaticIcon`. No upstream dependencies on other changes. Unblocks step 3.

3. **NameplateScanner.lua cast detection** — extend `Tick()` with UnitCastingInfo polling, `castHighlightActive` tracking. Depends on `SetCastHighlight` / `ClearCastHighlight` existing in IconDisplay (step 2). Also pass `soundFile` to `ShowStaticIcon` in `OnMobsAdded`.

4. **Pipeline.lua per-dungeon key + skillConfig merge** — change "imported" to `dungeonKey`, `importedRoute` to `importedRoutes` map, add `MergeSkillConfig` helper. Depends on knowing the skillConfig schema (defined here, no code dependency). Unblocks step 5 and step 7.

5. **CombatWatcher.lua zone map expansion + auto-switch** — expand `ZONE_DUNGEON_MAP` to all 9 dungeons, update `Reset()` to auto-select from `importedRoutes`. Depends on Pipeline writing per-dungeon keys (step 4).

6. **Core.lua updates** — add `ZONE_CHANGED_NEW_AREA` event registration if needed (may be covered by existing `PLAYER_ENTERING_WORLD`), add `/tpw config` slash command. Depends on ConfigFrame existing (step 7).

7. **ConfigFrame.lua** — new file. Reads `ns.AbilityDB` (step 1 ensures all dungeons populated) and `ns.db.skillConfig`. Writes skillConfig on change. Depends on AbilityDB data (step 1) and skillConfig schema (step 4).

8. **PackFrame.lua dungeon selector + mob count** — UI polish. Depends on per-dungeon PackDatabase keys (step 4) being in place and `importedRoutes` map being the source of truth.

---

## Internal Module Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Data/*.lua → Pipeline | `ns.AbilityDB[npcID]` populated at load time | Read-only after load; Pipeline is the only reader at runtime |
| Pipeline → PackDatabase | `ns.PackDatabase[dungeonKey] = packs` | Single writer; CombatWatcher, PackFrame read only |
| Pipeline → SavedVariables | `ns.db.importedRoutes[dungeonKey]` | Pipeline owns importedRoutes; ConfigFrame owns skillConfig |
| ConfigFrame → SavedVariables | `ns.db.skillConfig[npcID][spellID]` | ConfigFrame is the only writer; Pipeline reads at build time |
| NameplateScanner → IconDisplay | `SetCastHighlight` / `ClearCastHighlight` by instanceKey | Scanner owns cast state; IconDisplay owns visual state |
| Scheduler → IconDisplay | `SetUrgent` by barId | Scheduler owns timer state; IconDisplay owns visual state |
| PackFrame → CombatWatcher | `SelectDungeon(key)`, `SelectPack(key, idx)` | PackFrame never writes to PackDatabase directly |
| CombatWatcher → NameplateScanner + Scheduler | `Start(pack)`, `Stop()` | CombatWatcher orchestrates; Scanner and Scheduler are driven |

---

## Anti-Patterns

### Anti-Pattern 1: Storing full ability copies in skillConfig

**What people do:** Save the complete merged ability object — including name, spellID, mobClass, timers — in `ns.db.skillConfig`.

**Why it's wrong:** SavedVariables bloats. Any change to AbilityDB defaults does not propagate because stale copies shadow the new defaults. Debugging shows outdated data from old sessions.

**Do this instead:** Store only user-modified fields (label override, TTS override, sound selection, enabled flag). Defaults stay in AbilityDB and are merged at build time.

### Anti-Pattern 2: Keeping "imported" as the single PackDatabase key

**What people do:** Leave `ns.PackDatabase["imported"]` as the only key, treating the dungeon selector as a UI-only concept that reads from "imported".

**Why it's wrong:** Two dungeon routes cannot coexist. Auto-switch on zone-in has nowhere to write an incoming dungeon without overwriting the existing route. The "imported" key is semantically wrong once per-dungeon storage is the goal.

**Do this instead:** Use `dungeonInfo.key` (e.g. `"windrunner_spire"`) as the PackDatabase key from the start. The "imported" key is retired in this milestone.

### Anti-Pattern 3: Separate ticker for cast detection

**What people do:** Add a second `C_Timer.NewTicker` in NameplateScanner for UnitCastingInfo polling at a shorter interval (e.g. 0.1s).

**Why it's wrong:** Doubles nameplate API iteration. The existing 0.25s ticker is sufficient for cast detection — cast times are 1.5s minimum, so 0.25s lag is imperceptible.

**Do this instead:** Add UnitCastingInfo calls inside the body of the existing `Tick()`, gated on `activePack` having untimed abilities.

### Anti-Pattern 4: Matching casts by spell name string

**What people do:** Compare `UnitCastingInfo()` return value (the spell name string) against `ability.name` stored in AbilityDB.

**Why it's wrong:** `ability.name` is a developer-chosen English label. `UnitCastingInfo()` returns the localized spell name from the game client. Non-English clients break the match.

**Do this instead:** Use `UnitCastingInfo()` return value index 9, which is the numeric spellID — locale-independent. AbilityDB already stores `spellID`. Compare numerically.

### Anti-Pattern 5: Eager ConfigFrame construction at file load

**What people do:** Build all ConfigFrame widgets at file-scope in ConfigFrame.lua, mirroring the PackFrame pattern.

**Why it's wrong:** Config UI is opened rarely. Creating dozens of nested frames at ADDON_LOADED wastes memory and login time.

**Do this instead:** Build the config frame lazily on first `ConfigFrame.Open()` call using `if not configFrame then ... build ... end` at the top of the open function.

---

## Sources

- Direct source code analysis — all 10 Lua files in TerriblePackWarnings v0.0.4, read 2026-03-17
- `TerriblePackWarnings.toc` — load order, read 2026-03-17
- `.planning/PROJECT.md` — milestone requirements, read 2026-03-17
- WoW API: `UnitCastingInfo` return value at index 9 is numeric spellID — confirmed stable, available since classic era, unchanged in Midnight

---
*Architecture research for: TerriblePackWarnings v0.1.0 — configuration UI, ability data, cast detection, per-dungeon routes*
*Researched: 2026-03-17*
