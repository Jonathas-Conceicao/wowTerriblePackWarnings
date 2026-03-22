---
phase: 14-ability-data-foundation
plan: "04"
subsystem: ui
tags: [lua, wow-addon, config-ui, spell-resolution]

# Dependency graph
requires:
  - phase: 13-config-ui-pack-polish
    provides: ConfigFrame.lua with PopulateRightPanel and BuildDungeonIndex
provides:
  - GetSpellNameSafe helper for dynamic spell name resolution via C_Spell.GetSpellInfo
  - GetSpellIconSafe helper with fallback chain (GetSpellTexture -> GetSpellInfo.iconID)
  - All 9 S1 dungeons visible in config tree regardless of AbilityDB state
affects: [15-per-dungeon-route-storage, 16-cast-detection-sound-alerts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GetSpellNameSafe: prefer hand-authored name, fallback to C_Spell.GetSpellInfo, final fallback Spell <id>"
    - "GetSpellIconSafe: GetSpellTexture first, GetSpellInfo.iconID second, nil on miss (caller handles grey)"
    - "BuildDungeonIndex includes all dungeons unconditionally; empty mobs list is valid"

key-files:
  created: []
  modified:
    - UI/ConfigFrame.lua

key-decisions:
  - "GetSpellNameSafe returns ability.name if present rather than always querying the API — hand-authored names take precedence"
  - "GetSpellIconSafe returns nil (not a grey texture) so callers can apply their own fallback visual"
  - "BuildDungeonIndex now inserts all dungeons unconditionally — empty dungeons show a collapsed node with no mob rows"

patterns-established:
  - "Spell resolution helpers placed in dedicated section before BuildDungeonIndex for discoverability"
  - "TTS default text falls back to GetSpellNameSafe so abilities without hand-authored names still get meaningful TTS"

requirements-completed: [DATA-13, DATA-14, DATA-15]

# Metrics
duration: 5min
completed: 2026-03-20
---

# Phase 14 Plan 04: Spell Resolution Helpers and Empty Dungeon Visibility Summary

**Dynamic spell name/icon resolution via C_Spell.GetSpellInfo helpers in ConfigFrame.lua, with all 9 S1 dungeons always visible in the config tree**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-20T07:40:58Z
- **Completed:** 2026-03-20T07:46:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added `GetSpellNameSafe` helper: returns hand-authored name if set, queries `C_Spell.GetSpellInfo` as fallback, final fallback `"Spell <id>"`
- Added `GetSpellIconSafe` helper: tries `C_Spell.GetSpellTexture` then `C_Spell.GetSpellInfo.iconID`, returns nil so caller applies grey fallback
- All three call sites in `PopulateRightPanel` updated: spell icon, ability name display, and TTS default text
- Removed `#mobs > 0` guard in `BuildDungeonIndex` so all 9 dungeons appear in config tree regardless of AbilityDB population

## Task Commits

Each task was committed atomically:

1. **Task 1: Add spell resolution helpers and remove empty dungeon guard** - `6808e8e` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `UI/ConfigFrame.lua` - Added GetSpellNameSafe/GetSpellIconSafe helpers, updated PopulateRightPanel (3 call sites), removed #mobs > 0 guard

## Decisions Made

- `GetSpellNameSafe` checks `ability.name` first — hand-authored names are always preferred over API lookup
- `GetSpellIconSafe` returns nil rather than a fallback texture — the existing grey colorTexture fallback in PopulateRightPanel handles the nil case correctly
- Removed the empty-dungeon guard entirely rather than conditionally hiding nodes — empty expansions are valid UX; hiding dungeons confuses players who expect to see all content

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ConfigFrame.lua now resolves spell names and icons dynamically for all abilities, including those in the 8 newly-populated dungeons from plans 14-01 and 14-02
- All 9 S1 dungeons are visible in the config tree; expanding a dungeon with AbilityDB entries shows mob rows, expanding one without shows an empty area
- Ready for Phase 15 (per-dungeon route storage) — no ConfigFrame changes expected there

---
*Phase: 14-ability-data-foundation*
*Completed: 2026-03-20*
