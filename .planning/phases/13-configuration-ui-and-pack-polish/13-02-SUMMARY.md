---
phase: 13-configuration-ui-and-pack-polish
plan: "02"
subsystem: ui
tags: [packframe, portraits, count-overlay, config-button, wow-addon]

requires:
  - phase: 13-01
    provides: pack.mobCounts populated by BuildPack before seenNpc dedup

provides:
  - Mob count FontString overlays ("xN") on PackFrame pull row portraits
  - Config footer button in PackFrame calling ns.ConfigUI.Toggle()

affects:
  - UI/ConfigFrame.lua (Plan 03 — configBtn calls ns.ConfigUI.Toggle, which Plan 03 implements)

tech-stack:
  added: []
  patterns:
    - Lazy FontString creation on texture objects (tex.countLabel created once, reused on refresh)
    - Sparse count overlay (only shown when count > 1, hidden otherwise)
    - Nil-guarded ns.ConfigUI.Toggle() call pattern for cross-file API

key-files:
  created: []
  modified:
    - UI/PackFrame.lua

key-decisions:
  - "countLabel FontString created lazily on tex object in PopulateList (not in CreatePullRow) so row reuse across refreshes works correctly"
  - "count > 1 guard: show 'xN' only for multiple clones, hide entirely for single-instance mobs"
  - "configBtn placed left of clearBtn via SetPoint(RIGHT, clearBtn, LEFT) matching existing button chain pattern"

patterns-established:
  - "Pattern: Lazy overlay on texture — if not tex.overlay then ... end guard inside PopulateList"

requirements-completed: [ROUTE-04]

duration: 1min
completed: 2026-03-17
---

# Phase 13 Plan 02: PackFrame Count Overlays and Config Button Summary

**"xN" mob count overlays on pull row portraits (FRIZQT__.TTF 10px OUTLINE, BOTTOMRIGHT anchor) and Config footer button wired to ns.ConfigUI.Toggle()**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-17T07:02:29Z
- **Completed:** 2026-03-17T07:03:40Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Pull rows now show "xN" count labels on portrait icons when a pack contains multiple clones of the same NPC (e.g., "x3" for three Nerubian Spellguards)
- Portraits with only one mob of that type show no overlay (countLabel hidden)
- Config button added to footer (left of Clear button): [Config] [Clear] [Import]
- Config button calls `ns.ConfigUI.Toggle()` via nil-guarded check, ready for Plan 03

## Task Commits

1. **Task 1: Add mob count overlays and Config footer button** - `1027af1` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `UI/PackFrame.lua` - Added countLabel FontString on portrait textures in PopulateList, added configBtn in footer section

## Decisions Made

- countLabel created lazily inside `PopulateList` on `tex` (portrait texture object), not in `CreatePullRow`. This works because `tex` persists across `PopulateList` calls (rows are recycled), so `if not tex.countLabel then` correctly creates it once and reuses it on subsequent refreshes.
- `count > 1` is the visibility threshold — single-instance mobs show no overlay per spec.
- configBtn anchored via `SetPoint("RIGHT", clearBtn, "LEFT", -8, 0)` matching the existing importBtn/clearBtn chain pattern exactly.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ROUTE-04 complete: pack.mobCounts (from Plan 01) is now consumed and displayed
- Config button is in place; Plan 03 (ConfigFrame.lua) will implement ns.ConfigUI and ns.ConfigUI.Toggle()
- No blockers for Plan 03

## Self-Check: PASSED

| Item | Status |
|------|--------|
| UI/PackFrame.lua modified | FOUND |
| 13-02-SUMMARY.md created | FOUND |
| Commit 1027af1 (Task 1) | FOUND |

---
*Phase: 13-configuration-ui-and-pack-polish*
*Completed: 2026-03-17*
