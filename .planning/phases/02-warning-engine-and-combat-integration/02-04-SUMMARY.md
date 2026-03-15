---
phase: 02-warning-engine-and-combat-integration
plan: 04
subsystem: display
tags: [encounter-timeline, dbm, boss-warnings, debug-logging, lua]

# Dependency graph
requires:
  - phase: 02-warning-engine-and-combat-integration
    provides: BossWarnings adapter framework with lazy detection and Show/ShowTimer API
provides:
  - Adapter-specific Show() for ET (AddScriptEvent) and DBM (CreateBar)
  - Debug chat logging across Scheduler and BossWarnings for testing
affects: [03-ui-and-pack-data]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Debug toggle pattern: local DEBUG flag + dbg() helper per module"
    - "DBM barID-as-text: pass display text as barID parameter to DBT:CreateBar"

key-files:
  created: []
  modified:
    - Display/BossWarnings.lua
    - Engine/Scheduler.lua

key-decisions:
  - "DBM_Show uses barID as display text (no separate text API needed)"
  - "ET_Show creates short-lived timeline events via AddScriptEvent for alerts"
  - "RaidNotice_AddMessage count is 1 (only in RN_Show; RN_ShowTimer delegates to RN_Show)"

patterns-established:
  - "Debug logging: |cff888888TPW-dbg|r prefix for all debug output"

requirements-completed: [WARN-01, WARN-02]

# Metrics
duration: 2min
completed: 2026-03-15
---

# Phase 2 Plan 4: Adapter-Specific Show() Summary

**ET_Show uses C_EncounterTimeline.AddScriptEvent and DBM_Show uses DBT:CreateBar, replacing RaidNotice stubs; debug chat logging traces full schedule-to-display flow**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-15T01:38:18Z
- **Completed:** 2026-03-15T01:40:15Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- ET_Show now creates timeline entries via C_EncounterTimeline.AddScriptEvent instead of RaidNotice text
- DBM_Show now creates DBM timer bars via DBT:CreateBar instead of RaidNotice text
- Debug logging in Scheduler (5 calls) and BossWarnings (2 calls) traces the full warning flow
- RaidNotice_AddMessage reduced to 1 occurrence (only in RN_Show fallback)

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement real ET_Show and DBM_Show adapter functions** - `91cda03` (feat)
2. **Task 2: Add debug chat logging to Scheduler and BossWarnings** - `4b87767` (feat)

## Files Created/Modified
- `Display/BossWarnings.lua` - ET_Show and DBM_Show use native APIs; debug logging added
- `Engine/Scheduler.lua` - Debug logging for schedule, fire, start, stop events

## Decisions Made
- DBM_Show passes "TPW: " + alert text as barID, since DBT:CreateBar uses barID as display text when no localization table is present
- ET_Show stores alert eventIDs keyed by "alert_" + GetTime() to avoid collisions with timer bar IDs
- RaidNotice count is 1 not 2 as plan estimated, because RN_ShowTimer delegates to RN_Show rather than calling RaidNotice_AddMessage directly

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 2 complete: all 4 plans executed
- Warning engine fully functional with adapter-specific display for ET, DBM, and RaidNotice fallback
- Debug logging enabled for in-game testing
- Ready for Phase 3 (UI and Pack Data)

---
*Phase: 02-warning-engine-and-combat-integration*
*Completed: 2026-03-15*

## Self-Check: PASSED
