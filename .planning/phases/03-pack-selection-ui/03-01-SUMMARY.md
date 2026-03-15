---
phase: 03-pack-selection-ui
plan: 01
subsystem: ui
tags: [wow-addon, scrollbox, tree-list, accordion, frame, savedvariables]

# Dependency graph
requires:
  - phase: 01-foundation-and-data
    provides: "PackDatabase structure and Core.lua slash command handler"
  - phase: 02-warning-engine-and-combat-integration
    provides: "CombatWatcher state API for future UI refresh"
provides:
  - "Pack selection window frame (TPWPackFrame) with accordion dungeon/pack list"
  - "ns.PackUI.Toggle/Show/Hide API"
  - "Position persistence via SavedVariables"
  - "Escape-to-close via UISpecialFrames"
affects: [03-02, 03-03]

# Tech tracking
tech-stack:
  added: [BasicFrameTemplateWithInset, WowScrollBoxList, CreateScrollBoxListTreeListView, MinimalScrollBar]
  patterns: [ScrollBox tree list for hierarchical data, position save/restore with BOTTOMLEFT anchor]

key-files:
  created: [UI/PackFrame.lua]
  modified: [Core.lua, TerriblePackWarnings.toc]

key-decisions:
  - "DUNGEON_NAMES lookup table in PackFrame.lua instead of modifying PackDatabase schema"
  - "RestorePosition called at file load time (not event handler) since ns.db is set before PackFrame loads"
  - "Bare /tpw toggles window; help moved to explicit /tpw help subcommand"

patterns-established:
  - "UI modules expose API on ns namespace (ns.PackUI) with Toggle/Show/Hide pattern"
  - "ScrollBox tree list with dungeon header nodes and pack leaf children"

requirements-completed: [UI-01, UI-04]

# Metrics
duration: 1min
completed: 2026-03-15
---

# Phase 3 Plan 01: Pack Selection Window Summary

**ScrollBox tree list window with accordion dungeon headers, pack rows from PackDatabase, and /tpw slash toggle**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-15T04:44:11Z
- **Completed:** 2026-03-15T04:45:31Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Pack selection window with BasicFrameTemplateWithInset, ScrollBox tree list showing dungeon headers and pack rows
- Movable frame with position persistence across /reload via SavedVariables
- Bare /tpw toggles the window open/closed; Escape closes it via UISpecialFrames
- TOC load order updated to include UI\PackFrame.lua after all data files

## Task Commits

Each task was committed atomically:

1. **Task 1: Create PackFrame.lua window with accordion ScrollBox tree list** - `fb54236` (feat)
2. **Task 2: Wire slash command toggle and update TOC load order** - `b88e6b3` (feat)

## Files Created/Modified
- `UI/PackFrame.lua` - Pack selection window with ScrollBox tree list, movable frame, position persistence, ns.PackUI API
- `Core.lua` - Updated slash handler: bare /tpw toggles window, help moved to /tpw help
- `TerriblePackWarnings.toc` - Added UI\PackFrame.lua to load order after Data files

## Decisions Made
- Used a local DUNGEON_NAMES lookup table in PackFrame.lua rather than modifying PackDatabase schema (addresses Research open question #2)
- RestorePosition is called at file load time rather than via an ADDON_LOADED event handler, since Core.lua's ADDON_LOADED has already set ns.db before PackFrame.lua executes in TOC order
- Bare /tpw toggles window; moved help text to explicit /tpw help subcommand so unrecognized commands also toggle the window

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- PackFrame.lua exposes ScrollBox, ScrollView, and DataProvider for Plan 02 to wire click-to-select and combat state highlighting
- Pack row OnClick is a no-op placeholder ready for Plan 02 selection logic
- ns.PackUI.Refresh placeholder not yet implemented (Plan 02 responsibility)

## Self-Check: PASSED

- FOUND: UI/PackFrame.lua
- FOUND: .planning/phases/03-pack-selection-ui/03-01-SUMMARY.md
- FOUND: fb54236 (Task 1 commit)
- FOUND: b88e6b3 (Task 2 commit)

---
*Phase: 03-pack-selection-ui*
*Completed: 2026-03-15*
