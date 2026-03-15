---
phase: 05-custom-spell-icon-display
plan: 02
subsystem: engine
tags: [lua, scheduler, icon-display, wow-api]

# Dependency graph
requires:
  - phase: 05-custom-spell-icon-display
    provides: IconDisplay module with ShowIcon, ShowStaticIcon, SetUrgent, CancelAll API
provides:
  - Scheduler fully wired to IconDisplay API for all display operations
  - Legacy BossWarnings.lua removed from repository and build files
affects: [05-03-verification]

# Tech tracking
tech-stack:
  added: []
  patterns: [barId reuse for repeating ability icon slot reset]

key-files:
  created: []
  modified: [Engine/Scheduler.lua, TerriblePackWarnings.toc, scripts/install.bat]

key-decisions:
  - "Reuse same barId on repeating ability reschedule so ShowIcon resets cooldown sweep on existing slot"
  - "ShowIcon called immediately on schedule (not just at pre-warn) so icon is visible for full duration"
  - "ttsMessage propagated through recursive rescheduling for continued TTS on repeat cycles"

patterns-established:
  - "Scheduler-IconDisplay integration: ShowIcon at schedule time, SetUrgent at pre-warn, CancelAll at stop"

requirements-completed: [DISP-06]

# Metrics
duration: 2min
completed: 2026-03-15
---

# Phase 5 Plan 2: Scheduler Integration and Legacy Cleanup Summary

**Scheduler rewritten to use IconDisplay API with barId slot reuse, BossWarnings.lua deleted, TOC and install script updated**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-15T20:36:40Z
- **Completed:** 2026-03-15T20:37:58Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Rewrote Scheduler.lua to replace all 4 BossWarnings calls with IconDisplay equivalents
- Added untimed ability support via ShowStaticIcon for abilities without cooldowns
- Deleted 206-line legacy BossWarnings.lua display adapter from repository
- Updated TOC and install.bat to reference IconDisplay.lua

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite Scheduler.lua to use IconDisplay API** - `e4dd9b8` (feat)
2. **Task 2: Delete BossWarnings.lua and update TOC and install script** - `9737de9` (chore)

## Files Created/Modified
- `Engine/Scheduler.lua` - Replaced all BossWarnings calls with IconDisplay API, added barId reuse and static icon support
- `Display/BossWarnings.lua` - Deleted (206 lines of legacy adapter code)
- `TerriblePackWarnings.toc` - Changed Display\BossWarnings.lua to Display\IconDisplay.lua
- `scripts/install.bat` - Changed copy target from BossWarnings.lua to IconDisplay.lua

## Decisions Made
- ShowIcon called immediately when ability is scheduled (icon visible for full countdown duration, not just at pre-warn)
- Same barId passed to recursive reschedule so ShowIcon resets the existing slot cooldown sweep
- ttsMessage included in rescheduled ability table to maintain TTS on repeat cycles

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Scheduler fully integrated with IconDisplay API
- All legacy display code removed
- Ready for Plan 03 (verification/testing)

## Self-Check: PASSED

- FOUND: Engine/Scheduler.lua
- FOUND: TerriblePackWarnings.toc
- FOUND: scripts/install.bat
- MISSING (expected): Display/BossWarnings.lua (deleted)
- FOUND: commit e4dd9b8
- FOUND: commit 9737de9

---
*Phase: 05-custom-spell-icon-display*
*Completed: 2026-03-15*
