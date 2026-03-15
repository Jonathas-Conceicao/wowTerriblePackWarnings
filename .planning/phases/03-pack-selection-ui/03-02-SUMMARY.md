---
phase: 03-pack-selection-ui
plan: 02
subsystem: ui
tags: [wow-addon, scrollbox, selection, combat-state, visual-feedback]

# Dependency graph
requires:
  - phase: 03-pack-selection-ui
    provides: "Pack selection window frame with ScrollBox tree list (Plan 01)"
  - phase: 02-warning-engine-and-combat-integration
    provides: "CombatWatcher state machine with GetState API"
provides:
  - "Interactive pack selection via CombatWatcher:SelectPack(dungeonKey, packIndex)"
  - "Combat state row rendering with 4 visual states (default/selected/active/completed)"
  - "Live UI refresh on auto-advance and zone reset via ns.PackUI:Refresh() callbacks"
  - "Wipe recovery via click-to-reselect completed packs"
affects: [03-03]

# Tech tracking
tech-stack:
  added: []
  patterns: [state-driven row styling in ElementInitializer, PopulateList-based Refresh for small lists]

key-files:
  created: []
  modified: [Engine/CombatWatcher.lua, UI/PackFrame.lua]

key-decisions:
  - "Refresh rebuilds DataProvider via PopulateList (simple, sufficient for small pack lists)"
  - "Removed ScrollBox/ScrollView/GetDataProvider public exposures -- Refresh is the only needed API"

patterns-established:
  - "UpdateRowAppearance pattern: read CombatWatcher:GetState() during ElementInitializer for state-based styling"
  - "UI refresh via DataProvider rebuild -- ScrollBox re-initializes all visible elements"

requirements-completed: [UI-02, UI-03]

# Metrics
duration: 1min
completed: 2026-03-15
---

# Phase 3 Plan 02: Pack Selection and Combat State UI Summary

**Interactive pack row selection with 4-state visual feedback (default/selected/active/completed) driven by CombatWatcher state changes**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-15T04:48:15Z
- **Completed:** 2026-03-15T04:49:42Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- CombatWatcher:SelectPack API for arbitrary pack selection by dungeon key and index
- UI refresh callbacks on all state transitions (select, combat end, reset)
- Pack rows render 4 distinct states: default (white), selected/ready (green+checkmark), active/fighting (orange+combat icon), completed (grey+checkmark)
- Wipe recovery enabled by clicking any pack including completed ones

## Task Commits

Each task was committed atomically:

1. **Task 1: Add SelectPack API and UI refresh callbacks to CombatWatcher** - `12d5077` (feat)
2. **Task 2: Wire selection click handlers and combat state row rendering** - `1a9bbe0` (feat)

## Files Created/Modified
- `Engine/CombatWatcher.lua` - Added SelectPack(dungeonKey, packIndex) function and ns.PackUI:Refresh() callbacks to SelectDungeon, SelectPack, OnCombatEnd, Reset
- `UI/PackFrame.lua` - Added UpdateRowAppearance for state-based styling, wired OnClick to SelectPack, implemented PackUI:Refresh via PopulateList rebuild

## Decisions Made
- Refresh rebuilds the entire DataProvider via PopulateList() rather than updating individual rows -- simple and sufficient for a small pack list (one dungeon, few packs)
- Removed the Plan 01 placeholder exposures (ScrollBox, ScrollView, GetDataProvider) since PackUI:Refresh() is the only cross-module API needed
- Dungeon headers show gold only when they contain the active dungeon, white otherwise (Plan 01 had all headers gold)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Pack selection and combat state rendering complete
- Ready for Plan 03 (if exists) or phase completion
- All CombatWatcher state transitions now trigger UI refresh automatically

## Self-Check: PASSED

- FOUND: Engine/CombatWatcher.lua (modified)
- FOUND: UI/PackFrame.lua (modified)
- FOUND: 12d5077 (Task 1 commit)
- FOUND: 1a9bbe0 (Task 2 commit)

---
*Phase: 03-pack-selection-ui*
*Completed: 2026-03-15*
