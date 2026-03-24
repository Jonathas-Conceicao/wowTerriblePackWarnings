---
phase: 19-data-layer
plan: 02
subsystem: database
tags: [lua, wow-addon, ability-db, mob-detection]

requires:
  - phase: 19-data-layer plan 01
    provides: "Skyreach.lua mobCategory schema pattern"

provides:
  - "All 7 non-Skyreach dungeon data files use mobCategory = 'unknown' instead of mobClass = 'WARRIOR'"
  - "Header comments in all 7 files document the mobCategory vocabulary"

affects:
  - "Phase 20 runtime detection — reads ns.AbilityDB[npcID].mobCategory"

tech-stack:
  added: []
  patterns:
    - "mobCategory field on every AbilityDB entry; 'unknown' acts as wildcard at runtime"
    - "Header comment convention: document field vocabulary and disambiguate from WoW class tokens"

key-files:
  created: []
  modified:
    - Data/WindrunnerSpire.lua
    - Data/AlgetharAcademy.lua
    - Data/MagistersTerrace.lua
    - Data/MaisaraCaverns.lua
    - Data/NexusPointXenas.lua
    - Data/PitOfSaron.lua
    - Data/SeatoftheTriumvirate.lua

key-decisions:
  - "Plan's expected entry counts (table in PLAN.md) were slightly off for some files; actual counts from the files are authoritative and were not modified"

patterns-established:
  - "mobCategory = 'unknown' as wildcard default for non-Skyreach dungeons"
  - "Header comment documents mobCategory vocabulary and explicitly distinguishes it from WoW runtime class tokens"

requirements-completed:
  - DATA-01
  - DATA-03
  - DATA-04

duration: 10min
completed: 2026-03-23
---

# Phase 19 Plan 02: Replace mobClass with mobCategory in 7 non-Skyreach Data Files Summary

**AbilityDB schema migration complete for 7 dungeons: mobClass removed, mobCategory = "unknown" set on all entries, headers updated with vocabulary documentation**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-23T20:15:00Z
- **Completed:** 2026-03-23T20:25:00Z
- **Tasks:** 1
- **Files modified:** 7

## Accomplishments
- Replaced `mobClass = "WARRIOR"` with `mobCategory = "unknown"` on every AbilityDB entry in all 7 non-Skyreach dungeon files
- Updated all 7 file headers to document the mobCategory vocabulary ("boss"|"miniboss"|"caster"|"warrior"|"rogue"|"trivial"|"unknown") and explicitly note that these semantic roles are not the same as WoW runtime class tokens
- Zero `mobClass` references remain in any of the 7 files

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace mobClass with mobCategory = "unknown" in all 7 non-Skyreach data files** - `093b0b8` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `Data/WindrunnerSpire.lua` - Header updated, 29 entries migrated to mobCategory = "unknown"
- `Data/AlgetharAcademy.lua` - Header updated, 16 entries migrated to mobCategory = "unknown"
- `Data/MagistersTerrace.lua` - Header updated, 22 entries migrated to mobCategory = "unknown"
- `Data/MaisaraCaverns.lua` - Header updated, 31 entries migrated to mobCategory = "unknown"
- `Data/NexusPointXenas.lua` - Header updated, 30 entries migrated to mobCategory = "unknown"
- `Data/PitOfSaron.lua` - Header updated, 22 entries migrated to mobCategory = "unknown"
- `Data/SeatoftheTriumvirate.lua` - Header updated, 19 entries migrated to mobCategory = "unknown"

## Decisions Made
- The plan's entry count table listed different numbers than the actual files contained (e.g., MagistersTerrace listed 21 entries but had 22; MaisaraCaverns listed 30 but had 31). These are pre-existing counts in the files — no entries were added or removed. The acceptance criterion of zero `mobClass` references and all `mobCategory` values being "unknown" is fully satisfied.

## Deviations from Plan

None - plan executed exactly as written. The entry count discrepancies noted above are pre-existing in the source files and do not represent a deviation in this plan's execution.

## Issues Encountered
- `grep -rn "mobClass" Data/` still returns results from `Data/Skyreach.lua` — this is expected because Skyreach is handled by Plan 01, which has not yet been executed. This plan's acceptance criteria covers only the 7 non-Skyreach files, all of which pass.

## Next Phase Readiness
- All 7 non-Skyreach dungeon files now have `mobCategory` field on every entry, satisfying the AbilityDB schema requirement for Phase 20 runtime detection
- Once Plan 01 (Skyreach) completes, all 8 dungeon files will have a consistent `mobCategory` field
- Phase 20 can read `ns.AbilityDB[npcID].mobCategory` — "unknown" will act as wildcard (all mobs match)

---
*Phase: 19-data-layer*
*Completed: 2026-03-23*
