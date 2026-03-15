---
phase: 04-data-schema-and-pack-update
plan: 01
subsystem: database
tags: [lua, wow-addon, data-schema, ability-data]

# Dependency graph
requires:
  - phase: 02-warning-engine-and-combat-integration
    provides: "Scheduler and CombatWatcher engine consuming pack data"
provides:
  - "Flat pack.abilities schema with mobClass and timed/untimed support"
  - "Nil-cooldown guard in Scheduler for untimed abilities"
affects: [05-custom-display, 06-nameplate-detection]

# Tech tracking
tech-stack:
  added: []
  patterns: ["flat ability list per pack instead of nested mobs->abilities", "mobClass UnitClass token for nameplate filtering", "timed vs untimed ability distinction via nil cooldown"]

key-files:
  created: []
  modified: ["Data/WindrunnerSpire.lua", "Engine/Scheduler.lua"]

key-decisions:
  - "Flattened mobs->abilities nesting to direct pack.abilities list"
  - "mobClass uses uppercase UnitClass tokens (PALADIN, WARRIOR)"
  - "Untimed abilities have nil cooldown and are skipped by Scheduler"

patterns-established:
  - "Flat ability schema: each ability has name, spellID, mobClass, optional first_cast/cooldown"
  - "Nil-cooldown guard pattern: if ability.cooldown then scheduleAbility(ability) end"

requirements-completed: [DATA-06, DATA-07, DATA-08, DATA-09]

# Metrics
duration: 1min
completed: 2026-03-15
---

# Phase 4 Plan 1: Data Schema and Pack Update Summary

**Flat ability schema with mobClass fields and timed/untimed support, patched Scheduler iteration with nil-cooldown guard**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-15T19:58:32Z
- **Completed:** 2026-03-15T19:59:33Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Restructured WindrunnerSpire.lua from nested mobs->abilities to flat pack.abilities list
- Added mobClass field (PALADIN, WARRIOR) on each ability for Phase 6 nameplate detection
- Added Spirit Bolt as untimed ability (nil cooldown) alongside timed Spellguard's Protection
- Patched Scheduler:Start to iterate pack.abilities with nil-cooldown guard preventing errors on untimed abilities

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite WindrunnerSpire.lua to flat ability schema** - `4428a7b` (feat)
2. **Task 2: Patch Scheduler and CombatWatcher for new schema iteration** - `14a92fa` (feat)

## Files Created/Modified
- `Data/WindrunnerSpire.lua` - Flat ability schema with two abilities, mobClass fields, timed/untimed support
- `Engine/Scheduler.lua` - Updated iteration from nested mobs loop to flat abilities loop with nil-cooldown guard

## Decisions Made
None - followed plan as specified

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Flat ability schema is ready for Phase 5 (custom display) to render timed and untimed abilities differently
- mobClass field is ready for Phase 6 (nameplate detection) to filter abilities by detected mob class
- No blockers

## Self-Check: PASSED

All files exist and all commits verified.

---
*Phase: 04-data-schema-and-pack-update*
*Completed: 2026-03-15*
