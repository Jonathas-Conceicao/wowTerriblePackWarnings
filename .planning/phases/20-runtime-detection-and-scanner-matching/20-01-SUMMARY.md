---
phase: 20-runtime-detection-and-scanner-matching
plan: 01
subsystem: engine
tags: [lua, wow-addon, nameplate-scanner, mob-detection, category-matching]

# Dependency graph
requires:
  - phase: 19-data-layer
    provides: mobCategory field on ns.AbilityDB entries (boss/miniboss/caster/warrior/rogue/trivial/unknown)
provides:
  - DeriveCategory local function in NameplateScanner with locked priority chain
  - plateCache extended with category field (derived at NAME_PLATE_UNIT_ADDED)
  - OnClassificationChanged handler that refreshes cached category
  - UNIT_CLASSIFICATION_CHANGED event registered in Core.lua
  - Category-keyed scanner tables (categoryBarIds, categoryHasUntimed, castingByCategory)
  - Wildcard matching predicate in OnMobsAdded, OnCastStart, OnCastEnd
  - Pipeline MergeSkillConfig propagating mobCategory from AbilityDB onto merged ability objects
affects:
  - 21-cleanup-and-release

# Tech tracking
tech-stack:
  added: []
  patterns:
    - DeriveCategory priority chain (boss -> lieutenant pcall -> non-elite trivial -> elite class subtype -> unknown)
    - Wildcard matching: ability.mobCategory == "unknown" fires for all mobs
    - Event-time category derivation (never in hot Tick loop)
    - pcall-wrapped UnitIsLieutenant for safe unverified API usage

key-files:
  created: []
  modified:
    - Engine/NameplateScanner.lua
    - Import/Pipeline.lua
    - Core.lua

key-decisions:
  - "DeriveCategory priority chain is locked: boss -> lieutenant (pcall) -> non-elite trivial -> PALADIN caster -> ROGUE rogue -> WARRIOR warrior -> unknown fallback"
  - "ability.mobCategory == unknown is a wildcard: fires for ALL mob categories (false positives over false negatives)"
  - "classBase retained in plateCache for DeriveCategory steps 4-6 and debugging; to be removed in cleanup phase"
  - "MergeSkillConfig reads mobCategory from ns.AbilityDB[npcID] at pack-build time, not from SavedVariables"

patterns-established:
  - "DeriveCategory: local function called only at NAME_PLATE_UNIT_ADDED and UNIT_CLASSIFICATION_CHANGED, never in Tick()"
  - "Wildcard predicate: ability.mobCategory == 'unknown' or ability.mobCategory == category"
  - "Table rename pattern: classXxx -> categoryXxx for all category-keyed scanner tables"

requirements-completed: [DETC-01, DETC-02, DETC-03, DETC-04, DETC-05, SCAN-01, SCAN-02, SCAN-03]

# Metrics
duration: 3min
completed: 2026-03-23
---

# Phase 20 Plan 01: Runtime Detection and Scanner Matching Summary

**Category-based nameplate scanner with DeriveCategory priority chain, wildcard mob matching, and Pipeline mobCategory propagation replacing all class-based matching**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-23T22:02:21Z
- **Completed:** 2026-03-23T22:05:03Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Rewrote `Engine/NameplateScanner.lua` from class-based to category-based matching; all `classBarIds`/`classHasUntimed`/`castingByClass` tables renamed and rekeyed to semantic category strings
- Added `DeriveCategory(unitToken)` local function implementing the locked priority chain with pcall-wrapped `UnitIsLieutenant`; called only at event time, never in `Tick()`
- Updated `Import/Pipeline.lua` `MergeSkillConfig` to read `mobCategory` from `ns.AbilityDB[npcID]` and propagate onto merged ability objects; dedup key updated accordingly
- Registered `UNIT_CLASSIFICATION_CHANGED` in `Core.lua` and routed to new `Scanner:OnClassificationChanged` handler

## Task Commits

1. **Task 1: Update Pipeline MergeSkillConfig and BuildPack for mobCategory** - `c40ee9f` (feat)
2. **Task 2: Add DeriveCategory, extend plateCache, register UNIT_CLASSIFICATION_CHANGED** - `06001b9` (feat)

## Files Created/Modified

- `Engine/NameplateScanner.lua` - Full rework: DeriveCategory added, plateCache gains category field, all class-keyed tables renamed to category-keyed, wildcard predicate in OnMobsAdded/OnCastStart/OnCastEnd, Tick reads cached.category
- `Import/Pipeline.lua` - MergeSkillConfig signature simplified to 2-arg, reads mobCategory from AbilityDB, dedup key uses mobCategory
- `Core.lua` - UNIT_CLASSIFICATION_CHANGED event registration and routing to OnClassificationChanged

## Decisions Made

- `classBase` retained in `plateCache` alongside `category` — DeriveCategory uses `UnitClass` at steps 4-6 of priority chain; may be useful for debugging. Removal deferred to cleanup phase.
- wildcard (`"unknown"`) abilities fire for all mob categories — false positive strategy to ensure non-Skyreach dungeons continue working with full `"unknown"` category entries.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Scanner is now functional with category-based matching; Skyreach packs (with typed mobCategory) and all other dungeons (defaulting to "unknown") will work correctly
- Phase 21 cleanup: consider removing `classBase` from `plateCache` if no longer needed after this phase; review any debug log formatting
- UnitIsLieutenant behavior remains unvalidated in-game — test during first Skyreach pull to confirm miniboss detection works or falls through safely via pcall

---
*Phase: 20-runtime-detection-and-scanner-matching*
*Completed: 2026-03-23*
