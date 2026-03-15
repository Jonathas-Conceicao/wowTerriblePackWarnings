---
phase: 06-nameplate-detection-and-mob-lifecycle
plan: 01
subsystem: engine
tags: [nameplate, c_timer, mob-detection, scheduler, wow-api]

# Dependency graph
requires:
  - phase: 05-custom-spell-icon-display
    provides: "IconDisplay ShowIcon/ShowStaticIcon/CancelIcon/CancelAll API"
  - phase: 04-data-schema-and-pack-database
    provides: "pack.abilities with mobClass, first_cast, cooldown fields"
provides:
  - "Scheduler:StartAbility(ability, barId) for per-mob timer control"
  - "Scheduler:StopAbility(barId) for surgical per-barId timer cancellation"
  - "NameplateScanner module with 0.25s poll-based mob detection and lifecycle management"
affects: [06-02, combat-watcher-integration]

# Tech tracking
tech-stack:
  added: []
  patterns: [per-barId timer tracking, count-based mob lifecycle reconciliation, pcall-wrapped unit queries]

key-files:
  created: [Engine/NameplateScanner.lua]
  modified: [Engine/Scheduler.lua]

key-decisions:
  - "Per-barId timer tracking in barTimers table for surgical cancellation instead of letting orphaned timers fire"
  - "Immediate first tick on Scanner:Start for instant mob detection without 0.25s delay"

patterns-established:
  - "barTimers[barId] = { handles = {} } pattern for per-instance timer tracking"
  - "Count-based reconciliation: prevCounts vs newCounts per class to detect mob additions/removals"
  - "Defensive plate.namePlateUnitToken or plate.unitToken field access"

requirements-completed: [DETC-01, DETC-02, DETC-03, DETC-04, DISP-07]

# Metrics
duration: 2min
completed: 2026-03-15
---

# Phase 6 Plan 1: Nameplate Scanner and Scheduler Per-Mob API Summary

**Scheduler refactored with StartAbility/StopAbility per-barId API, NameplateScanner polls nameplates every 0.25s for count-based mob lifecycle management**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-15T21:17:11Z
- **Completed:** 2026-03-15T21:18:48Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Scheduler now supports per-mob timer control via StartAbility/StopAbility with per-barId timer handle tracking in barTimers table
- NameplateScanner polls C_NamePlate.GetNamePlates() every 0.25s, filtering hostile in-combat mobs by UnitClass
- Count-based reconciliation detects mob additions (spawn per-mob timed icons) and removals (cancel icons surgically)
- Untimed abilities show single static icon on first mob detection; cleared when all mobs of that class die

## Task Commits

Each task was committed atomically:

1. **Task 1: Refactor Scheduler with StartAbility/StopAbility and per-barId timer tracking** - `ac3e361` (feat)
2. **Task 2: Create NameplateScanner module with poll-based mob detection and lifecycle** - `887d4df` (feat)

## Files Created/Modified
- `Engine/Scheduler.lua` - Added barTimers table, StartAbility/StopAbility public API, per-barId timer handle tracking, wipe(barTimers) in Stop()
- `Engine/NameplateScanner.lua` - New module: 0.25s poll loop, per-class count tracking, mob lifecycle with OnMobsAdded/OnMobsRemoved, pcall-wrapped unit queries

## Decisions Made
- Per-barId timer tracking (barTimers table) chosen over letting orphaned timers fire -- cleaner cancellation for mid-combat mob deaths
- Immediate first tick on Scanner:Start() so detection does not wait 0.25s after combat start

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- NameplateScanner and Scheduler per-mob API are ready for Plan 02 which wires CombatWatcher to call Scanner:Start/Stop instead of Scheduler:Start/Stop
- TOC entry for Engine/NameplateScanner.lua needs to be added (before CombatWatcher.lua for load order)

## Self-Check: PASSED

- [x] Engine/Scheduler.lua exists with StartAbility/StopAbility/barTimers
- [x] Engine/NameplateScanner.lua exists with full scanner implementation
- [x] Commit ac3e361 found (Task 1)
- [x] Commit 887d4df found (Task 2)

---
*Phase: 06-nameplate-detection-and-mob-lifecycle*
*Completed: 2026-03-15*
