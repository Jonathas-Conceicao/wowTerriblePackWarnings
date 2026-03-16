---
phase: 09-import-pipeline
plan: 02
subsystem: ui, core
tags: [lua, wow-addon, import, slash-commands, toc, packframe]

requires:
  - phase: 09-import-pipeline-01
    provides: "Import/Pipeline.lua and Data/DungeonEnemies.lua modules"
provides:
  - "Import pipeline wired into addon lifecycle (restore on login, slash commands)"
  - "TOC load order for DungeonEnemies.lua and Pipeline.lua"
  - "Imported Route display name in PackFrame UI"
affects: [10-final-polish]

tech-stack:
  added: []
  patterns: ["Defensive nil-check before calling optional module APIs"]

key-files:
  created: []
  modified: [Core.lua, TerriblePackWarnings.toc, UI/PackFrame.lua]

key-decisions:
  - "Defensive guard on RestoreFromSaved call (ns.Import may not exist if Pipeline.lua fails to load)"
  - "Auto-expand newly added dungeon keys in Refresh rather than at file load time"

patterns-established:
  - "Nil-guard pattern for optional module calls in ADDON_LOADED"

requirements-completed: [IMPORT-04, DATA-12]

duration: 3min
completed: 2026-03-16
---

# Phase 9 Plan 2: Import Pipeline Wiring Summary

**Wired import/clear slash commands, ADDON_LOADED restore, TOC load order, and imported route display name into addon**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-16T04:08:57Z
- **Completed:** 2026-03-16T04:11:57Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Core.lua calls RestoreFromSaved on ADDON_LOADED to restore imported routes from SavedVariables
- /tpw import and /tpw clear slash commands wired into the command handler
- TOC updated with DungeonEnemies.lua and Pipeline.lua in correct dependency order
- PackFrame shows "Imported Route" header and auto-expands imported packs on refresh

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire import pipeline into Core.lua and update TOC load order** - `79dd5f1` (feat)
2. **Task 2: Add imported route display name to PackFrame UI** - `66882b5` (feat)

## Files Created/Modified
- `Core.lua` - Added RestoreFromSaved call, import/clear slash commands, updated help text
- `TerriblePackWarnings.toc` - Added DungeonEnemies.lua and Pipeline.lua load entries
- `UI/PackFrame.lua` - Added "imported" display name, auto-expand logic in Refresh

## Decisions Made
- Used defensive nil-guard (`if ns.Import and ns.Import.RestoreFromSaved`) before restore call to handle cases where Pipeline.lua may not have loaded
- Auto-expand new dungeon keys in Refresh() rather than only at file load time, ensuring imported routes added at runtime are visible immediately

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Import pipeline is fully wired: decode, transform, populate, persist, and restore all connected
- Ready for Phase 10 final polish or end-to-end testing

---
*Phase: 09-import-pipeline*
*Completed: 2026-03-16*

## Self-Check: PASSED
