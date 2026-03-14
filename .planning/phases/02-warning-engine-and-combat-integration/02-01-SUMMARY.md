---
phase: 02-warning-engine-and-combat-integration
plan: 01
subsystem: data
tags: [lua, wow-addon, pack-database, display-abstraction, encounter-timeline, dbm, raid-notice]

# Dependency graph
requires:
  - phase: 01-foundation-and-data
    provides: Core.lua with ns namespace and ns.PackDatabase initialized at module scope

provides:
  - Ordered array pack data format for WindrunnerSpire (enabling index-based auto-advance)
  - Display abstraction module with 3-tier fallback: Encounter Timeline > DBM > RaidNotice
  - Updated TOC with all Phase 2 file entries in correct load order

affects:
  - 02-02 (Scheduler and CombatWatcher will consume ns.BossWarnings and ns.PackDatabase ordered arrays)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Lazy adapter detection: detect display system on first call, cache result, print to chat
    - Per-dungeon ordered array in PackDatabase keyed by dungeon slug
    - DBM bar ID namespacing: prefix all TPW-managed bars with "TPW_" to avoid collisions
    - Track own resource IDs locally rather than calling CancelAll on shared systems

key-files:
  created:
    - Display/BossWarnings.lua
  modified:
    - Data/WindrunnerSpire.lua
    - TerriblePackWarnings.toc

key-decisions:
  - "PackDatabase per-dungeon ordered array (not flat map) allows index-based auto-advance by Scheduler"
  - "Lazy adapter detection defers C_EncounterTimeline check until first call, avoiding load-time unavailability"
  - "DBM adapter tracks own bar IDs in activeBarIDs table instead of calling DBT:CancelAllBars() (which would cancel all DBM bars)"

patterns-established:
  - "Adapter pattern: local adapter functions, public BW.* dispatch based on cached activeAdapter string"
  - "Array insertion via packs[#packs + 1] = {} preserves sequence order for all dungeon data files"

requirements-completed: [WARN-02]

# Metrics
duration: 5min
completed: 2026-03-14
---

# Phase 2 Plan 01: PackDatabase Restructure and Display Abstraction Summary

**Per-dungeon ordered array pack format plus 3-tier display abstraction (Encounter Timeline > DBM > RaidNotice fallback) with lazy adapter detection**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-14T00:00:00Z
- **Completed:** 2026-03-14
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- WindrunnerSpire.lua restructured from flat key-value map to per-dungeon ordered array, enabling index-based pack auto-advance
- Display/BossWarnings.lua created with Show, ShowTimer, CancelTimer, CancelAllTimers, GetAdapter; adapter detected lazily at first call
- TerriblePackWarnings.toc updated with all Phase 2 file paths (Engine\Scheduler.lua, Engine\CombatWatcher.lua, Display\BossWarnings.lua) in correct load order

## Task Commits

Each task was committed atomically:

1. **Task 1: Restructure PackDatabase to ordered array and update TOC** - `ed4e90b` (feat)
2. **Task 2: Create display abstraction module with 3-tier fallback** - `b905004` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `Data/WindrunnerSpire.lua` - Converted from flat map to per-dungeon ordered array with key field per entry
- `Display/BossWarnings.lua` - 3-tier display abstraction with lazy adapter detection and public BW.* API
- `TerriblePackWarnings.toc` - Added Engine\Scheduler.lua, Engine\CombatWatcher.lua, Display\BossWarnings.lua entries

## Decisions Made

- Lazy adapter detection: C_EncounterTimeline may not be available at addon load time (only confirmed available inside dungeons); detecting on first call avoids false negatives
- DBM path tracks own bar IDs in `activeBarIDs` table and cancels individually — calling DBT:CancelAllBars() would destroy all DBM bars including those from other addons
- RaidNotice fallback for ShowTimer approximates a bar with text appended duration "(Ns)" since RaidNotice has no bar primitive

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PackDatabase ordered array format ready for Scheduler consumption (plan 02-02)
- ns.BossWarnings API ready for Scheduler and CombatWatcher to call for output
- TOC already lists Engine\Scheduler.lua and Engine\CombatWatcher.lua, so those files can be added in plan 02-02 without another TOC edit
- Outstanding concern: C_EncounterTimeline applicability to dungeon trash content unconfirmed — BossWarnings adapter is swappable by design to allow replacing adapter without changing callers

---
*Phase: 02-warning-engine-and-combat-integration*
*Completed: 2026-03-14*
