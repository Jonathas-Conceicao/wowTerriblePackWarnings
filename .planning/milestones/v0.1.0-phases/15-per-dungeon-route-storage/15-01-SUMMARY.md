---
phase: 15-per-dungeon-route-storage
plan: 01
subsystem: data-storage
tags: [lua, savedbariables, schema-migration, combat-state, wow-addon]

# Dependency graph
requires:
  - phase: 14-ability-data-foundation
    provides: AbilityDB population and RestoreFromSaved preset-based restore pattern
provides:
  - Per-dungeon PackDatabase[dungeonKey] storage in Pipeline.lua
  - RestoreAllFromSaved rebuilds all saved routes on login
  - Clear(dungeonKey) clears only the specified dungeon's route
  - Schema migration v0->v1 migrates importedRoute -> importedRoutes[dungeonKey]
  - Full 8-dungeon ZONE_DUNGEON_MAP in CombatWatcher for zone-in auto-switch
  - combatMode guards (auto/manual/disable) in OnCombatStart and OnCombatEnd
affects: [16-cast-detection-sound-alerts, PackFrame dungeon selector plan]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - SavedVariables schema migration with schemaVersion guard in ADDON_LOADED
    - Per-dungeon keyed storage in both PackDatabase (runtime) and ns.db.importedRoutes (persisted)
    - ZONE_DUNGEON_MAP for GetInstanceInfo()-based zone-in auto-switch
    - Combat mode guards via ns.db.combatMode checked at top of OnCombatStart/OnCombatEnd

key-files:
  created: []
  modified:
    - Import/Pipeline.lua
    - Core.lua
    - Engine/CombatWatcher.lua

key-decisions:
  - "Per-dungeon route storage uses dungeonKey (string) as both PackDatabase key and ns.db.importedRoutes key"
  - "RestoreAllFromSaved uses BuildPack directly (not RunFromPreset) to avoid double-printing on restore"
  - "Clear(dungeonKey) only stops active tracking if the cleared dungeon was the active one"
  - "Schema migration reads ns.DUNGEON_IDX_MAP (safe because all TOC files load before ADDON_LOADED fires)"
  - "ZONE_DUNGEON_MAP instance names are best-guess estimates requiring in-game verification for punctuation"
  - "Non-S1 zones fall back to ns.db.selectedDungeon to avoid losing selection on non-dungeon loading screens"

patterns-established:
  - "Pattern: Schema migration with schemaVersion guard — check, migrate, delete old field, set version, then initialize new defaults"
  - "Pattern: Combat mode guard — check ns.db.combatMode at top of OnCombatStart/OnCombatEnd before any state checks"

requirements-completed: [ROUTE-01, ROUTE-03]

# Metrics
duration: 4min
completed: 2026-03-20
---

# Phase 15 Plan 01: Per-Dungeon Route Storage Summary

**Retired PackDatabase["imported"] single-key pattern; replaced with per-dungeon keyed storage, schema migration v0->v1, full 8-dungeon ZONE_DUNGEON_MAP, and auto/manual/disable combat mode guards**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-20T08:30:57Z
- **Completed:** 2026-03-20T08:34:43Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Pipeline.lua stores routes under `PackDatabase[dungeonKey]` and `ns.db.importedRoutes[dungeonKey]`; `RestoreAllFromSaved` rebuilds all saved routes on login; `Clear(dungeonKey)` removes only the specified dungeon
- Core.lua migrates `ns.db.importedRoute` (old) to `ns.db.importedRoutes[dungeonKey]` on first load, guarded by `schemaVersion`, and initializes `combatMode`/`selectedDungeon`
- CombatWatcher expanded ZONE_DUNGEON_MAP to all 8 S1 dungeons, rewrote `Reset()` for zone-in auto-switch, and added combat mode guards preventing scanning/advancing when mode is "disable" or "manual"

## Task Commits

Each task was committed atomically:

1. **Task 1: Refactor Pipeline.lua to per-dungeon storage and add schema migration to Core.lua** - `c516cc0` (feat)
2. **Task 2: Rewrite CombatWatcher for per-dungeon state, full ZONE_DUNGEON_MAP, and combat mode guards** - `20fba15` (feat)

**Plan metadata:** (pending final commit)

## Files Created/Modified
- `Import/Pipeline.lua` - RunFromPreset now writes to PackDatabase[dungeonKey]; RestoreAllFromSaved replaces RestoreFromSaved; Clear(dungeonKey) per-dungeon clear
- `Core.lua` - Schema migration block, RestoreAllFromSaved call, /tpw clear uses selectedDungeon
- `Engine/CombatWatcher.lua` - 8-dungeon ZONE_DUNGEON_MAP, zone-in auto-switch Reset(), combatMode guards in OnCombatStart/OnCombatEnd

## Decisions Made
- `RestoreAllFromSaved` calls `BuildPack` directly instead of `RunFromPreset` to avoid double-printing the "Imported:" message on every login restore
- `/tpw clear` resolves the target dungeon key as `ns.db.selectedDungeon or activeDungeon` — uses the UI-persisted selection as primary, combat state as fallback
- `Reset()` on non-S1 zones falls back to `ns.db.selectedDungeon` rather than clearing selection — prevents losing dungeon selection on city/loading-screen zone changes
- ZONE_DUNGEON_MAP uses best-guess instance names with punctuation (apostrophes, colons) that require in-game verification

## Deviations from Plan

### Out-of-Scope Items Found

**PackFrame.lua still has "imported" references (deferred)**
- **Found during:** Task 1 pre-work (reading PackFrame.lua)
- **Issue:** PackFrame.lua has 4 remaining `"imported"` refs (lines 277, 354, 372, 385) that will make the UI read from the wrong PackDatabase key after this refactor
- **Action:** Deferred — this plan's scope covers only Pipeline.lua, Core.lua, CombatWatcher.lua. PackFrame.lua is addressed in the next plan (15-02 or similar).
- **Impact:** The Route window will not display packs after import until PackFrame.lua is updated. Engine and storage work correctly.

---

**Total deviations:** 0 auto-fixed
**Impact on plan:** Plan executed exactly as written for the three specified files. PackFrame.lua is a known follow-up.

## Issues Encountered
- `grep` acceptance criterion for `ns.db.importedRoute` specified "exactly 1 match" but migration block has 4 references (check, read into local, write importedRoutes, set to nil). All references are inside the migration block and correct — criterion intent (no uses outside migration) is satisfied.

## Next Phase Readiness
- Per-dungeon storage structural foundation is complete
- PackFrame.lua needs updating (still reads `PackDatabase["imported"]` and compares `activeDungeon == "imported"`)
- CombatWatcher ZONE_DUNGEON_MAP instance names need in-game verification for punctuation accuracy
- Phase 16 (cast detection/sound alerts) can proceed in parallel with PackFrame update

---
*Phase: 15-per-dungeon-route-storage*
*Completed: 2026-03-20*
