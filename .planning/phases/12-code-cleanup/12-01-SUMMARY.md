---
phase: 12-code-cleanup
plan: 01
subsystem: engine
tags: [lua, debug-logging, savedvariables, hot-path-audit, dead-code]

requires:
  - phase: 11-docs-ci
    provides: "README and project documentation"
provides:
  - "Toggleable debug logging via /tpw debug (persists through /reload)"
  - "Hot path documentation on NameplateScanner 0.25s tick"
  - "Clean codebase with no dead code or unused variables"
affects: []

tech-stack:
  added: []
  patterns:
    - "Shared debug flag via ns.db.debug (SavedVariables)"
    - "PERF comment blocks on hot-path functions"

key-files:
  created: []
  modified:
    - Engine/NameplateScanner.lua
    - Display/IconDisplay.lua
    - Core.lua
    - UI/PackFrame.lua

key-decisions:
  - "Kept debug logging as toggleable flag instead of removing (user override)"
  - "Debug defaults to OFF, toggled via /tpw debug, persists via SavedVariables"
  - "Only one hot path identified: NameplateScanner 0.25s tick (~60 API calls/tick)"

patterns-established:
  - "Debug logging pattern: dbg() checks ns.db.debug, never local DEBUG flags"

requirements-completed: [CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04]

duration: 2min
completed: 2026-03-16
---

# Phase 12 Plan 01: Code Cleanup Summary

**Toggleable debug logging via SavedVariables, dead code removal, and PERF-annotated hot paths across all 10 Lua files**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-16T07:19:18Z
- **Completed:** 2026-03-16T07:22:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Refactored per-file `local DEBUG = true` flags into shared `ns.db.debug` SavedVariables toggle
- Added `/tpw debug` slash command to toggle debug logging on/off (persists through /reload)
- Removed `/tpw show` and `/tpw hide` debug slash commands from Core.lua
- Audited all 10 Lua files for dead code; removed unused iteration variables in PackFrame.lua
- Documented NameplateScanner:Tick as the only hot path with PERF comments (0.25s, ~60 API calls/tick)

## Task Commits

Each task was committed atomically:

1. **Task 1: Debug artifact refactor + debug slash command removal** - `24e0f7f` (feat)
2. **Task 2: Dead code removal and hot path audit** - `767feaa` (chore)

## Files Created/Modified
- `Engine/NameplateScanner.lua` - Replaced DEBUG flag with ns.db.debug, added PERF comments on Tick
- `Display/IconDisplay.lua` - Replaced DEBUG flag with ns.db.debug
- `Core.lua` - Removed show/hide commands, added /tpw debug toggle, updated help text
- `UI/PackFrame.lua` - Replaced unused dungeonIdx iteration variables with _

## Decisions Made
- **User override applied:** Instead of removing DEBUG/dbg() as the plan specified, refactored to a toggleable SavedVariables flag per user's explicit instruction. This preserves debug capability for runtime diagnostics while defaulting to silent in production.
- **Scheduler.lua had no debug code:** Plan referenced DEBUG/dbg on lines 18-19 of Scheduler.lua but the current file had no debug artifacts. No changes needed there.
- **Minimal dead code found:** All 10 files were well-maintained. Only found unused `dungeonIdx` loop variables in PackFrame.lua (2 instances).

## Deviations from Plan

### User-Directed Override (CLEAN-01)

**1. Debug logging refactored to toggleable flag instead of removed**
- **Reason:** User explicitly overrode CLEAN-01 requirements
- **Change:** Per-file `local DEBUG = true` replaced with `ns.db.debug` check; dbg() functions retained
- **Added:** `/tpw debug` slash command for runtime toggle
- **Impact:** Debug logging persists as a feature (default OFF) rather than being stripped

### Auto-fixed Issues

None.

---

**Total deviations:** 1 user-directed override
**Impact on plan:** CLEAN-01 requirement semantics changed from "remove" to "make toggleable" per user instruction. All other requirements (CLEAN-02, CLEAN-03, CLEAN-04) executed as specified.

## Hot Path Audit Findings

| Hot Path | File | Frequency | API Calls/Tick | Status |
|----------|------|-----------|----------------|--------|
| Scanner:Tick | NameplateScanner.lua | Every 0.25s | ~60 (at 20 nameplates) | Acceptable |

No other hot paths found: no OnUpdate handlers, no high-frequency event registrations (COMBAT_LOG_EVENT_UNFILTERED, UNIT_AURA, etc.). Scheduler uses one-shot C_Timer.NewTimer callbacks. Core.lua event handlers fire at combat boundaries only.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 12 code cleanup complete
- Codebase is clean, documented, and ready for v0.0.4 release

---
*Phase: 12-code-cleanup*
*Completed: 2026-03-16*
