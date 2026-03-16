---
phase: 07-complete-dungeon-route
plan: 02
subsystem: ui
tags: [lua, wow-addon, tooltip, fontstring, gametooltip, icon-display]

requires:
  - phase: 05-icon-display-and-tts
    provides: "IconDisplay with CreateIconSlot, ShowIcon, ShowStaticIcon, CancelIcon, CancelAll"
provides:
  - "Label FontString rendering on icon slots"
  - "Spell tooltip on icon mouseover via GameTooltip:SetSpellByID"
  - "Tooltip guard on icon cancel preventing orphaned tooltips"
  - "Label propagation from ability data through all call sites"
affects: [pack-data, dungeon-routes]

tech-stack:
  added: []
  patterns:
    - "FontString OVERLAY label at bottom edge of icon frames"
    - "EnableMouse + OnEnter/OnLeave for GameTooltip on custom frames"
    - "GameTooltip:GetOwner guard before hiding slots"

key-files:
  created: []
  modified:
    - Display/IconDisplay.lua
    - Engine/Scheduler.lua
    - Engine/NameplateScanner.lua

key-decisions:
  - "ANCHOR_BOTTOMLEFT for tooltip anchor since icons are near top of screen (ANCHOR_Y=900)"
  - "Reschedule closure omits label intentionally — existing FontString survives cooldown reset"

patterns-established:
  - "Label param as optional trailing argument in display API functions"
  - "Tooltip guard pattern: check GetOwner before Hide in all cancel paths"

requirements-completed: [ROUTE-02, ROUTE-03]

duration: 3min
completed: 2026-03-16
---

# Phase 7 Plan 2: Icon Labels and Tooltips Summary

**Optional label FontString on icon slots with GameTooltip spell tooltip on mouseover and tooltip guards on cancel**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-16T00:22:58Z
- **Completed:** 2026-03-16T00:26:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Icon slots render optional label FontString at bottom edge when ability.label is set
- Hovering any icon shows full WoW spell tooltip via GameTooltip:SetSpellByID
- Tooltip hides on mouse leave and on icon cancellation (both single and bulk cancel)
- Label field propagates from ability data through Scheduler and NameplateScanner to IconDisplay

## Task Commits

Each task was committed atomically:

1. **Task 1: Add label, tooltip, and tooltip guard to IconDisplay.lua** - `2037f0a` (feat)
2. **Task 2: Propagate label through Scheduler and NameplateScanner call sites** - `639db3d` (feat)

## Files Created/Modified
- `Display/IconDisplay.lua` - Label FontString, tooltip on hover, tooltip guard on cancel
- `Engine/Scheduler.lua` - ability.label propagation in ShowIcon and ShowStaticIcon calls
- `Engine/NameplateScanner.lua` - ability.label propagation in ShowStaticIcon call

## Decisions Made
- Used ANCHOR_BOTTOMLEFT for tooltip placement since icons sit near top of screen (ANCHOR_Y=900)
- Intentionally omitted label from reschedule closure — existing FontString on the slot survives cooldown resets, no need to recreate

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Label and tooltip infrastructure ready for dungeon route pack data with ability.label fields
- All display API signatures stable for downstream consumers

---
*Phase: 07-complete-dungeon-route*
*Completed: 2026-03-16*
