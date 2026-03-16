# Phase 9: Import Pipeline - Context

**Gathered:** 2026-03-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the pipeline that takes a decoded MDT table, extracts pulls with npcIDs, matches against AbilityDB, and populates PackDatabase with dynamic packs ready for combat. Includes persistence via SavedVariables and a `/tpw import` command.

</domain>

<decisions>
## Implementation Decisions

### Pull-to-Pack Mapping
- MDT pulls reference mobs by `enemyIdx` into `dungeonEnemies[dungeonIdx]` table
- Each enemy entry has an `id` field = **npcID** — this is how we match to AbilityDB
- **Bundle MDT's full dungeonEnemies data** for all available dungeons (not just Windrunner Spire) — provides npcIDs, names, displayIds for future use
- Create a **dungeonIdx → dungeon key mapping table** (extensible for future dungeons)
- For each pull: iterate enemyIdx entries → look up npcID from dungeonEnemies → check `ns.AbilityDB[npcID]` → collect abilities with mobClass
- **All pulls appear as packs** — even those with no tracked abilities (empty packs for route progression)
- **Accept any dungeon** — unknown dungeons build packs with mob data but no skill tracking. All MDT NPC data is copied for future reference.

### Import Persistence
- **Save processed pack data** to SavedVariables (`ns.db.importedRoute`)
- Processed data includes: dungeon name, pull list with npcIDs, abilities, pack displayNames
- On ADDON_LOADED: if `ns.db.importedRoute` exists, repopulate PackDatabase from it
- Clear button removes `ns.db.importedRoute` and empties PackDatabase
- No re-decoding needed — instant load from saved data

### Import Flow
1. User runs `/tpw import <MDT string>` (or pastes into UI editbox in Phase 10)
2. Call `ns.MDTDecode(string)` → get preset table
3. Extract `preset.value.currentDungeonIdx` and `preset.value.pulls`
4. Look up dungeonEnemies for that dungeonIdx
5. For each pull: map enemyIdx → npcID → AbilityDB lookup → build pack abilities
6. Populate `ns.PackDatabase` with the built packs
7. Save processed data to `ns.db.importedRoute`
8. Refresh UI

### Claude's Discretion
- Import module file location (Import/Pipeline.lua or similar)
- Pack displayName format for imported pulls (e.g. "Pull 1", "Pull 2")
- How to store the dungeonEnemies data (single file? per-dungeon?)
- Whether to expose import via slash command only or also via ns.Import API

</decisions>

<specifics>
## Specific Ideas

- The dungeonEnemies data from MDT is reference data — copy it wholesale from MDT repo for all available dungeons
- MDT's dungeon data files are in per-expansion directories (e.g. MythicDungeonTools/TheWarWithin/WindrunnerSpire.lua)
- The import should print a summary: "Imported: Windrunner Spire - 17 pulls (4 with tracked abilities)"

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Import/Decode.lua`: `ns.MDTDecode(string)` returns decoded MDT preset table
- `ns.AbilityDB`: npcID → { mobClass, abilities } mapping from Data/WindrunnerSpire.lua
- `ns.PackDatabase`: existing pack format consumed by Scheduler and NameplateScanner
- `ns.db` (SavedVariables): available for persistence

### MDT Data Location
- Dungeon enemy data: `C:\Users\jonat\Repositories\MythicDungeonTools\TheWarWithin\` (per-dungeon .lua files)
- Each file populates `MDT.dungeonEnemies[dungeonIdx]` with enemy entries containing `id` (npcID)

### Integration Points
- CombatWatcher reads PackDatabase for pack selection and auto-advance
- NameplateScanner reads pack.abilities for mob detection
- Scheduler reads ability data (cooldown, ttsMessage, label, spellID)
- PackFrame UI reads PackDatabase for display
- Zone auto-detection in CombatWatcher:Reset may need updating (no more hardcoded dungeon key)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 09-import-pipeline*
*Context gathered: 2026-03-16*
