# Phase 14: Ability Data Foundation - Context

**Gathered:** 2026-03-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Populate AbilityDB files for all 9 Midnight S1 dungeons with spellIDs extracted from MDT source. All mobs default to WARRIOR class. Spell names and icons resolved dynamically via C_Spell.GetSpellInfo at runtime. All dungeons visible and navigable in the config UI from Phase 13.

</domain>

<decisions>
## Implementation Decisions

### Spell Selection Criteria
- Import ALL spells from MDT per mob — no filtering or curation
- Users disable unwanted spells via config UI checkbox (Phase 13)
- All newly imported spells default to DISABLED (not tracked until user enables)
- Boss mob spells imported but default to disabled — available for users who want them

### Data Authoring Approach
- Claude reads MDT dungeon files directly and generates Data/*.lua files during execution — no extraction script
- Spell names NOT hardcoded — resolved dynamically via C_Spell.GetSpellInfo(spellID) at runtime
- All new mobs default to mobClass = "WARRIOR" (MDT lacks class data)
- All new spells have no timing data (no first_cast, no cooldown) — untimed by default
- Labels default to nil for new spells (C_Spell name used as display fallback)
- TTS messages default to nil for new spells (spell name used as TTS fallback)

### WindrunnerSpire Reconciliation
- Keep existing hand-authored entries UNCHANGED (PALADIN class, timing, labels, TTS)
- Add any MDT spells not already present in WindrunnerSpire.lua as new untimed WARRIOR entries
- Do NOT overwrite existing npcIDs that already have data

### Default Enabled State
- Existing WindrunnerSpire abilities with hand-authored data: remain enabled by default (current behavior)
- All newly generated abilities (from MDT extraction): disabled by default
- Implementation: MergeSkillConfig already handles this — new spells need `enabled = false` stored in a defaults table or the AbilityDB entry itself

### Claude's Discretion
- Exact ordering of entries within Data files
- Whether to add comments per mob identifying spell names (helpful for future curation)
- How to handle the "disabled by default" flag — could be a field on the ability entry or a separate defaults mechanism

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing AbilityDB Pattern
- `Data/WindrunnerSpire.lua` — Established schema: ns.AbilityDB[npcID] = { mobClass, abilities = [{name, spellID, first_cast, cooldown, label, ttsMessage}] }
- `Import/Pipeline.lua` — MergeSkillConfig helper, DUNGEON_IDX_MAP, BuildPack ability merging

### MDT Source Data (spellID extraction)
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\WindrunnerSpire.lua` — MDT enemy data with spells = { [spellID] = {} }
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\AlgetharAcademy.lua`
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\MagistersTerrace.lua`
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\MaisaraCaverns.lua`
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\MurderRow.lua`
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\NexusPointXenas.lua`
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\PitOfSaron.lua`
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\SeatoftheTriumvirate.lua`
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\Skyreach.lua`

### DungeonEnemies Reference
- `Data/DungeonEnemies.lua` — npcID, name, displayId, isBoss for all 9 dungeons. Used to cross-reference MDT enemy entries.

### Config UI Integration
- `UI/ConfigFrame.lua` — BuildDungeonIndex reads ns.AbilityDB to populate dungeon→mob tree. New data files surface automatically.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Data/WindrunnerSpire.lua` — template for all new dungeon data files (same schema)
- `Data/DungeonEnemies.lua` — provides isBoss flag for boss detection
- `Import/Pipeline.lua` DUNGEON_IDX_MAP — maps dungeonIdx to key/name for all 9 dungeons

### Established Patterns
- AbilityDB schema: `ns.AbilityDB[npcID] = { mobClass = "WARRIOR", abilities = { {spellID = N}, ... } }`
- MDT spells structure: `enemy.spells = { [spellID] = {} }` — keys are spellIDs, values always empty
- ConfigFrame BuildDungeonIndex: iterates ns.AbilityDB and ns.DungeonEnemies to build tree — new Data files auto-appear

### Integration Points
- `TerriblePackWarnings.toc` — new Data files must be added to load order (before UI files)
- `Core.lua` — no changes needed (AbilityDB initialized at ns scope, populated by Data files at load time)

</code_context>

<specifics>
## Specific Ideas

- MDT spells table format: `["spells"] = { [spellID] = {} }` — confirmed same structure across all 9 dungeons
- WindrunnerSpire MDT has spellIDs 1216135, 1216298, 1253700, 1216250, 1216253, 1253683, 1253686, 1216462 — some already in our AbilityDB, some new
- All 8 new dungeon files follow identical pattern to WindrunnerSpire.lua

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 14-ability-data-foundation*
*Context gathered: 2026-03-17*
