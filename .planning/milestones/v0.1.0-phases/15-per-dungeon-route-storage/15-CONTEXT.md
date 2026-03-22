# Phase 15: Per-Dungeon Route Storage - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Structural refactor: retire `PackDatabase["imported"]` single-key pattern. Each S1 dungeon stores its own imported route independently in SavedVariables. Add dungeon selector dropdown to Route window, zone-in auto-switch, and combat mode selector (Auto/Manual/Disable).

</domain>

<decisions>
## Implementation Decisions

### Dungeon Selector UX
- Dropdown at top of Route window showing current dungeon name
- Click to see all 8 S1 dungeons (just names, no route status indicators)
- When no route imported for selected dungeon: show "No route imported for [Dungeon]. Click Import to add one." with Import button visible
- Dropdown does not indicate which dungeons have routes — simple name list

### Zone-In Auto-Switch Behavior
- On zone-in: auto-switch to that dungeon's route AND reset to pull 1
- ZONE_DUNGEON_MAP populated with hardcoded instance names for all 8 S1 dungeons
- If no route imported for the dungeon: switch anyway, show import prompt, print chat notification "TPW: No route for [Dungeon]. Import one with /tpw"
- Uses GetInstanceInfo() for zone detection (existing pattern)

### Import/Clear Per Dungeon
- Import auto-detects dungeon from MDT string (dungeonIdx in preset) — route stored under correct dungeon automatically
- After import: Route window auto-switches to show the imported dungeon
- Importing a route for a dungeon that already has one: replace silently, no confirmation
- Clear: clears route for currently selected dungeon only, other dungeons keep their routes
- Existing confirmation dialog "Clear imported route?" still applies but now says "Clear route for [Dungeon]?"

### Combat Mode Selector
- Three mutually exclusive buttons in Route window: Auto, Manual, Disable
- **Auto**: current behavior — auto-advance packs on combat start/end, trigger icons and warnings
- **Manual**: icons/warnings trigger for selected pack, but NO auto-advance on combat start/end. Player manually clicks pulls to navigate.
- **Disable**: addon does nothing — no scanning, no icons, no warnings
- Mode persists in SavedVariables
- Claude's discretion on visual treatment (toggle group, radio-style, highlight active)

### SavedVariables Schema Migration
- `ns.db.importedRoute` (single object) → `ns.db.importedRoutes` (keyed by dungeonKey, e.g. `ns.db.importedRoutes["windrunner_spire"]`)
- Add `ns.db.schemaVersion` for migration detection
- On ADDON_LOADED: if `ns.db.importedRoute` exists (old format), migrate to `importedRoutes[dungeonKey]` then delete old field
- `ns.db.combatMode` stores "auto" / "manual" / "disable" (default: "auto")
- `ns.db.selectedDungeon` stores last-selected dungeon key for Route window state persistence

### Claude's Discretion
- Exact visual treatment of combat mode buttons
- SavedVariables schema version number
- How to handle the `"imported"` key retirement across all files (atomic grep-verified refactor per STATE.md pitfall)
- RestoreFromSaved → RestoreAllFromSaved iteration pattern
- Whether dropdown uses a popup frame (like sound popup) or a simpler approach

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Atomic Refactor Target Files
- `Import/Pipeline.lua` — RunFromPreset, RunFromString, RestoreFromSaved, Clear — all use `PackDatabase["imported"]` and `ns.db.importedRoute`
- `Engine/CombatWatcher.lua` — SelectDungeon, SelectPack, OnCombatStart, OnCombatEnd, Reset — all reference `"imported"` key and ZONE_DUNGEON_MAP
- `UI/PackFrame.lua` — PopulateList, UpdateHeader — read `PackDatabase["imported"]`, `ns.db.importedRoute`, `activeDungeon == "imported"`
- `Core.lua` — ADDON_LOADED handler (RestoreFromSaved call), slash commands

### Existing Patterns
- `UI/ConfigFrame.lua` — sound popup pattern (Button + popup frame for dropdown)
- `UI/PackFrame.lua` — footer button layout pattern (Config/Clear/Import chain)
- `Data/Sounds.lua` — data table pattern for dropdown options

### STATE.md Pitfalls
- `PackDatabase["imported"]` retirement must be atomic across Pipeline.lua, CombatWatcher.lua, PackFrame.lua
- Add `schemaVersion` before writing v0.1.0 fields; migrate `importedRoute` → `importedRoutes` on ADDON_LOADED

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Sound popup pattern (ConfigFrame.lua) — reusable for dungeon dropdown popup
- Footer button chain (PackFrame.lua) — pattern for combat mode buttons
- DUNGEON_IDX_MAP (Pipeline.lua) — maps dungeonIdx → key/name, already exposed on ns

### Established Patterns
- `ns.db` SavedVariables initialization in Core.lua ADDON_LOADED
- `ns.PackDatabase[key]` for runtime pack storage
- `CombatWatcher:SelectDungeon(key)` / `SelectPack(key, idx)` API
- StaticPopup for confirmations (TPW_CONFIRM_CLEAR)

### Integration Points
- Core.lua ADDON_LOADED: migration logic + RestoreAllFromSaved
- CombatWatcher:Reset() — zone-change handler, needs to read ZONE_DUNGEON_MAP for all 8 dungeons
- PackFrame PopulateList/UpdateHeader — must read per-dungeon PackDatabase[dungeonKey]
- Import popup OnClick — RunFromString still works, RunFromPreset auto-detects dungeon

### Key Refactor Points (grep "imported")
- `ns.PackDatabase["imported"]` → `ns.PackDatabase[dungeonKey]`
- `ns.db.importedRoute` → `ns.db.importedRoutes[dungeonKey]`
- `activeDungeon == "imported"` → `activeDungeon == selectedDungeonKey`
- `CombatWatcher:SelectDungeon("imported")` → `CombatWatcher:SelectDungeon(dungeonKey)`

</code_context>

<specifics>
## Specific Ideas

- Combat mode buttons: think of them like WoW stance bar buttons or spec toggle buttons — visually distinct active state
- Import flow: paste MDT string → auto-detect dungeon → store under that key → switch view to it. Seamless.
- The dropdown should feel like a simple tab system, not a complex UI. Click → list → click dungeon → done.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 15-per-dungeon-route-storage*
*Context gathered: 2026-03-20*
