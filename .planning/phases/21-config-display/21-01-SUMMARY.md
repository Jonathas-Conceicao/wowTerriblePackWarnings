---
phase: 21-config-display
plan: 01
subsystem: ui
tags: [lua, wow-addon, fontstring, color-escape, search-filter, category]

# Dependency graph
requires:
  - phase: 19-data-layer
    provides: entry.mobCategory field on all AbilityDB entries
provides:
  - Color-coded category tag rendering in ConfigFrame mob header
  - Category-aware search with hyphen normalization in ApplySearchFilter
affects:
  - UI/ConfigFrame.lua consumers (display correctness for all mob headers)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - WoW color escape "|cffRRGGBB...|r" for inline colored text in FontString
    - Lua pattern gsub("%-","") for hyphen normalization in search input

key-files:
  created: []
  modified:
    - UI/ConfigFrame.lua

key-decisions:
  - "CATEGORY_COLORS defined as file-scoped local before PopulateRightPanel (not ns.*)"
  - "Dead npcIdToClass table and CLASS_ICON table removed — both relied on entry.mobClass which no longer exists since Phase 19"
  - "Portrait fallback simplified: displayId -> question mark (class icon fallback removed since no class data)"
  - "gsub hyphen escape uses '%-' not '-' — gsub has no plain-text flag, hyphen must be escaped in Lua pattern"
  - "categoryMatch uses renamed local catEntry to avoid shadowing entry local in else block"

patterns-established:
  - "Pattern: category match at same branch level as mob name match — both set currentMatchedMobs without currentMatchedSpells"
  - "Pattern: normalize user search input only (strip hyphens from filter, not from stored category values)"

requirements-completed: [UI-01, UI-02, UI-03]

# Metrics
duration: 2min
completed: 2026-03-23
---

# Phase 21 Plan 01: Config Display Summary

**Color-coded mob category tags in ConfigFrame header and category-aware search with hyphen normalization replacing broken entry.mobClass references**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-23T22:25:33Z
- **Completed:** 2026-03-23T22:27:45Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Fixed broken header display: mob headers now show "MobName [Category]" with gold/cyan/brown/etc. color tags instead of "MobName - UNKNOWN" for every mob
- Removed all dead code relying on entry.mobClass (npcIdToClass table, CLASS_ICON table, portrait class fallback) — all produced no-ops since Phase 19
- Extended ApplySearchFilter with category matching: "boss", "caster", "warrior", "mini-boss" (hyphen normalized) all filter correctly with partial match support

## Task Commits

Each task was committed atomically:

1. **Task 1: Add color-coded category tag to mob header** - `2aeb22c` (feat)
2. **Task 2: Add category matching to search filter** - `b6e245e` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `UI/ConfigFrame.lua` - CATEGORY_COLORS table, header fix, search filter extension, dead code removal

## Decisions Made
- Removed `npcIdToClass` and `CLASS_ICON` tables as Rule 1 auto-fix: both relied on `entry.mobClass` which no longer exists. Portrait fallback now goes directly to question mark icon.
- Used `catEntry` as the local variable name for the category check (instead of `entry`) to avoid shadowing the `entry` local already used in the else block.
- `CATEGORY_COLORS` placed as a file-scoped local immediately before `PopulateRightPanel` (the only consumer) rather than inside the function — avoids re-creating the table on each call.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed dead npcIdToClass and CLASS_ICON tables**
- **Found during:** Task 1 (header fix — scanning for all entry.mobClass references)
- **Issue:** Lines 18-23 built `npcIdToClass` from `entry.mobClass`, which no longer exists since Phase 19. The table was always empty. Lines 41-44 in `GetPortraitTexture` used it to select a class icon, but always fell through to the question mark fallback. Plan acceptance criteria required zero `entry.mobClass` references.
- **Fix:** Removed the `npcIdToClass` build loop, `CLASS_ICON` table, and the `GetPortraitTexture` branch that used both. Portrait function retains displayId path and question mark fallback.
- **Files modified:** UI/ConfigFrame.lua
- **Verification:** `grep "entry.mobClass" UI/ConfigFrame.lua` returns 0 results; `grep "CLASS_ICON\|npcIdToClass" UI/ConfigFrame.lua` returns 0 results
- **Committed in:** 2aeb22c (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug/dead code from Phase 19 field removal)
**Impact on plan:** Necessary cleanup — the dead code produced no visible behavior but could mislead future maintainers. No scope creep.

## Issues Encountered
None — both changes were exactly as specified in the plan. The only extra work was the dead code removal triggered by the zero-`entry.mobClass` acceptance criterion.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Phase 21 Plan 01 complete — category tags display correctly in config window
- No remaining plans in this phase
- Milestone v0.1.1 work complete; ready for cleanup phase or release
- Blocker from STATE.md (UnitIsLieutenant unverified) is a runtime concern — validate in-game during testing

---
*Phase: 21-config-display*
*Completed: 2026-03-23*
