---
phase: 17-command-rework-and-config-search
plan: 01
subsystem: ui
tags: [slash-commands, ui-polish, packframe, config-window]

# Dependency graph
requires:
  - phase: 16-cast-detection-and-sound-alerts
    provides: ConfigUI and PackUI public Toggle APIs established
provides:
  - Reworked slash command handler with case-insensitive subcommands and /tpw route subcommand
  - Route window footer with configBtn removed and Clear/Import spread across footer width
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "cmd:lower() normalization immediately after msg:match() for case-insensitive slash commands"
    - "Bare /tpw defaults to config window; /tpw route is the secondary path to route window"

key-files:
  created: []
  modified:
    - Core.lua
    - UI/PackFrame.lua

key-decisions:
  - "Bare /tpw defaults to config window (was route window) — config is the primary UX entry point"
  - "cmd = cmd and cmd:lower() or '' nil-guard pattern for slash command normalization"
  - "configBtn removed from PackFrame footer — /tpw config and bare /tpw both open config window now"

patterns-established:
  - "Slash command normalization: apply cmd:lower() immediately after msg:match() before any comparisons"

requirements-completed:
  - CMD-01
  - CMD-02
  - UIPOL-02

# Metrics
duration: 10min
completed: 2026-03-20
---

# Phase 17 Plan 01: Command Rework and Footer Cleanup Summary

**Slash commands reworked so bare /tpw opens config window, /tpw route added for route window, all subcommands case-insensitive, and route window footer stripped of configBtn with Clear/Import spread to opposite edges.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-20T00:00:00Z
- **Completed:** 2026-03-20T00:10:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Bare `/tpw` now opens the config window (was route window) — config is the new primary entry point
- New `/tpw route` subcommand opens the route/pack selection window
- All slash subcommands are now case-insensitive via `cmd:lower()` normalization
- `/tpw help` replaced with grouped output under Windows, Route, and Debug category headers
- `configBtn` removed from PackFrame footer; `clearBtn` moved to `BOTTOMLEFT`, `importBtn` stays at `BOTTOMRIGHT`

## Task Commits

1. **Task 1: Rework slash commands in Core.lua** - `8beb817` (feat)
2. **Task 2: Remove configBtn and spread footer buttons in PackFrame.lua** - `61a9aa0` (feat)

## Files Created/Modified

- `Core.lua` - Reworked SlashCmdList handler: cmd:lower() normalization, /tpw route branch, bare /tpw -> ConfigUI.Toggle, grouped help output
- `UI/PackFrame.lua` - Removed configBtn block, changed clearBtn anchor from RIGHT-of-importBtn to BOTTOMLEFT of frame

## Decisions Made

- Bare `/tpw` opens config window rather than route window — config is the primary UX entry point per the phase objective
- `cmd = cmd and cmd:lower() or ""` nil-guard pattern handles the case where msg is empty (no subcommand) without a separate match
- `configBtn` removal makes the footer cleaner; users access config via bare `/tpw` or `/tpw config`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Slash command rework is complete; all existing subcommands (select, start, stop, status, debug, clear) are unaffected
- Route window footer is clean with two symmetrically-placed buttons
- Ready for Phase 17 Plan 02 (config search or next planned work)

---
*Phase: 17-command-rework-and-config-search*
*Completed: 2026-03-20*
