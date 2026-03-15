---
phase: 06-nameplate-detection-and-mob-lifecycle
plan: 02
subsystem: engine
tags: [lua, wow-addon, nameplate, combat, lifecycle]

# Dependency graph
requires:
  - phase: 06-01
    provides: "NameplateScanner module and Scheduler StartAbility/StopAbility API"
provides:
  - "Fully integrated detection pipeline from combat events through nameplate scanning to per-mob icon display"
  - "CombatWatcher driven entirely through NameplateScanner instead of direct Scheduler:Start"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scanner-driven combat flow: CombatWatcher -> NameplateScanner -> Scheduler per-mob API"

key-files:
  created: []
  modified:
    - Engine/CombatWatcher.lua
    - TerriblePackWarnings.toc

key-decisions:
  - "Scanner Stop called before Scheduler Stop on combat end for correct cleanup order"
  - "ManualStart uses scanner path so /tpw start tests the same detection pipeline"

patterns-established:
  - "Combat lifecycle flows through NameplateScanner, never directly to Scheduler:Start"

requirements-completed: [DETC-01, DETC-02, DETC-04]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 6 Plan 2: Wire Scanner into CombatWatcher Summary

**CombatWatcher now drives all timer creation through NameplateScanner instead of direct Scheduler:Start calls, completing the nameplate detection pipeline**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-15T21:15:00Z
- **Completed:** 2026-03-15T21:18:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- CombatWatcher OnCombatStart and ManualStart now invoke NameplateScanner:Start(pack) instead of Scheduler:Start
- CombatWatcher OnCombatEnd and Reset call NameplateScanner:Stop() before Scheduler:Stop() for correct cleanup order
- TOC updated with NameplateScanner.lua between Scheduler.lua and CombatWatcher.lua for correct load order
- In-game verification confirmed per-mob icon spawning, mid-combat detection, and death cleanup

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire CombatWatcher to NameplateScanner and update TOC** - `9122cff` (feat)
2. **Task 2: Verify nameplate detection and mob lifecycle in-game** - checkpoint:human-verify (approved)

## Files Created/Modified
- `Engine/CombatWatcher.lua` - Replaced direct Scheduler:Start calls with NameplateScanner:Start/Stop calls
- `TerriblePackWarnings.toc` - Added NameplateScanner.lua to load order between Scheduler and CombatWatcher

## Decisions Made
- Scanner Stop called before Scheduler Stop on combat end to ensure nameplate state is cleaned up before timers are cancelled
- ManualStart (/tpw start) uses the scanner path so testing exercises the same detection pipeline as real combat

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All v0.0.2 phases complete -- nameplate detection and mob lifecycle fully integrated
- Addon ready for extended in-game testing and iteration

---
*Phase: 06-nameplate-detection-and-mob-lifecycle*
*Completed: 2026-03-15*
