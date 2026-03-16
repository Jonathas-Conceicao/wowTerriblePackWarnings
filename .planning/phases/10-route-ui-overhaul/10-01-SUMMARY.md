---
phase: 10-route-ui-overhaul
plan: 01
subsystem: ui
tags: [wow-addon, lua, packframe, portraits, mdt-import, static-popup]

requires:
  - phase: 09-import-pipeline
    provides: "Import.RunFromString, Import.Clear, PackDatabase[imported], DungeonEnemies, AbilityDB"
provides:
  - "Pull row UI with round NPC portrait icons and state coloring"
  - "Import popup with multi-line editbox for MDT strings"
  - "Clear confirmation dialog via StaticPopup"
  - "Header showing dungeon name + pull count"
affects: []

tech-stack:
  added: []
  patterns: ["Portrait fallback chain: displayId -> class icon -> question mark", "Row pool reuse pattern for scroll lists"]

key-files:
  created: []
  modified: [UI/PackFrame.lua]

key-decisions:
  - "Portrait fallback uses AbilityDB mobClass to select WoW class icons when displayId is missing"
  - "Import popup is a separate Frame (not StaticPopup) to avoid 255 char limit on MDT strings"

patterns-established:
  - "GetPortraitTexture helper: displayId -> class icon -> question mark fallback chain"
  - "Circular portrait mask via TempPortraitAlphaMask on texture objects"
  - "Footer button pattern: Clear/Import anchored BOTTOMRIGHT of main frame"

requirements-completed: [UI-09, UI-10, UI-11, UI-12]

duration: 2min
completed: 2026-03-16
---

# Phase 10 Plan 01: Route UI Overhaul Summary

**MDT-style pull list with round NPC portraits, import editbox popup, and clear confirmation dialog replacing accordion dungeon list**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-16T04:39:27Z
- **Completed:** 2026-03-16T04:41:21Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Replaced accordion dungeon list with indexed pull rows showing numbered pulls and circular NPC portrait icons
- Portrait fallback chain: creatureDisplayID -> class icon from AbilityDB mobClass -> question mark
- Import popup with multi-line editbox supporting MDT strings of any length
- Clear confirmation dialog via StaticPopup before removing imported data
- State coloring: orange for active pull, green for selected, grey for completed

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite PackFrame with pull rows, NPC portraits, and header** - `8240bd7` (feat)
2. **Task 2: Add import popup, clear confirmation, and footer buttons** - `0452844` (feat)

## Files Created/Modified
- `UI/PackFrame.lua` - Complete rewrite: pull row list with portraits, import popup, clear dialog, header, footer buttons

## Decisions Made
- Portrait fallback uses AbilityDB mobClass to select WoW class icons when displayId is missing (not just question mark)
- Import popup is a separate Frame (not StaticPopup) to avoid the 255 character limit on MDT export strings
- Row pool pattern reuses rows across Refresh calls, only creating new ones when needed

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 10 has only this one plan; route UI overhaul is complete
- All v0.0.3 phases (8, 9, 10) are now complete
- Addon ready for in-game testing of full MDT import workflow

---
*Phase: 10-route-ui-overhaul*
*Completed: 2026-03-16*
