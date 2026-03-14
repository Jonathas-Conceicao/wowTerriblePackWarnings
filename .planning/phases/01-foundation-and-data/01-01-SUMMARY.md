---
phase: 01-foundation-and-data
plan: 01
subsystem: addon-core
tags: [wow-addon, toc, lua, namespace, pack-database]

# Dependency graph
requires: []
provides:
  - "Loadable WoW addon skeleton (TOC + Core.lua)"
  - "ns.PackDatabase namespace for pack data files"
  - "Windrunner Spire pack 1 data entry with ability timers"
  - "SavedVariables initialization (TerriblePackWarningsDB)"
  - "/tpw slash command stub"
affects: [02-timer-engine, 03-ui-polish]

# Tech tracking
tech-stack:
  added: []
  patterns: [wow-addon-namespace, event-frame-pattern, module-scope-database-init]

key-files:
  created:
    - TerriblePackWarnings.toc
    - Core.lua
    - Data/WindrunnerSpire.lua
  modified: []

key-decisions:
  - "PackDatabase initialized at module scope (not inside ADDON_LOADED) so data files can populate it during load"
  - "No global TPW table -- all data accessed through ns namespace per locked decision"

patterns-established:
  - "Namespace pattern: local addonName, ns = ... in every Lua file"
  - "Data file pattern: populate ns.PackDatabase[pack_key] with mobs/abilities schema"
  - "Event frame pattern: CreateFrame + RegisterEvent + UnregisterEvent after handling"

requirements-completed: [FOUND-01, DATA-01, DATA-02]

# Metrics
duration: 1min
completed: 2026-03-14
---

# Phase 1 Plan 1: Addon Skeleton + Pack Data Summary

**WoW addon skeleton with TOC, Core.lua namespace/event handling, and Windrunner Spire pack database entry with timed ability data**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-14T01:59:20Z
- **Completed:** 2026-03-14T02:00:21Z
- **Tasks:** 2
- **Files created:** 3

## Accomplishments
- Loadable WoW addon with dual interface version (120000/120001) TOC manifest
- Core.lua with namespace pattern, ADDON_LOADED/PLAYER_ENTERING_WORLD handlers, SavedVariables init, and /tpw slash command stub
- Windrunner Spire pack 1 data with Spellguard Magus (NPC 232113) and Spellguard's Protection ability (Spell 1253686) including first_cast and cooldown fields

## Task Commits

Each task was committed atomically:

1. **Task 1: Create TOC manifest and Core.lua addon skeleton** - `6c61b96` (feat)
2. **Task 2: Create Windrunner Spire pack data file** - `c28b5dd` (feat)

## Files Created/Modified
- `TerriblePackWarnings.toc` - Addon manifest with dual interface version, SavedVariables, file load order
- `Core.lua` - Addon namespace init, event frame, ADDON_LOADED handler, SavedVariables init, slash command stub
- `Data/WindrunnerSpire.lua` - Pack database entry for Windrunner Spire pack 1 with Spellguard Magus ability data

## Decisions Made
- PackDatabase initialized at module scope (before event handlers) so data files can write into it during load-time execution
- No global TPW table created -- namespace-only access per locked project decision

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Addon skeleton is complete and loadable in WoW
- PackDatabase schema established for additional dungeon data files
- /tpw slash command stub ready for Phase 3 UI work
- Timer engine (Phase 2) can read pack data from ns.PackDatabase

## Self-Check: PASSED

- FOUND: TerriblePackWarnings.toc
- FOUND: Core.lua
- FOUND: Data/WindrunnerSpire.lua
- FOUND: commit 6c61b96 (Task 1)
- FOUND: commit c28b5dd (Task 2)

---
*Phase: 01-foundation-and-data*
*Completed: 2026-03-14*
