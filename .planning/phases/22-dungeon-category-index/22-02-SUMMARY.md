---
phase: 22-dungeon-category-index
plan: "02"
subsystem: data-ui
tags: [dungeon-enemies, pack-frame, boss-detection, category-cleanup]
dependency_graph:
  requires: [22-01]
  provides: [clean-dungeon-enemies, abilitydb-boss-detection]
  affects: [UI/PackFrame.lua, Data/DungeonEnemies.lua]
tech_stack:
  added: []
  patterns: [abilitydb-single-source-of-truth, nil-guard-defense-in-depth]
key_files:
  modified:
    - Data/DungeonEnemies.lua
    - UI/PackFrame.lua
decisions:
  - "Boss detection consolidated into AbilityDB as single source of truth; isBoss field removed from DungeonEnemies entirely"
  - "Nil-guard added to PackFrame boss check: ns.AbilityDB[npcID] and ... ensures safe access for mobs without AbilityDB entries"
metrics:
  duration: "5 minutes"
  completed: "2026-03-24"
  tasks_completed: 2
  files_modified: 2
---

# Phase 22 Plan 02: isBoss Removal and AbilityDB Boss Detection Summary

**One-liner:** Removed isBoss from all DungeonEnemies entries and replaced npcIdIsBoss lookup table in PackFrame with AbilityDB mobCategory check.

## What Was Built

- Removed `isBoss = true` field from all 38 entries across 7 dungeon sections in `Data/DungeonEnemies.lua`
- Updated file header comment to remove stale mention of `isBoss`
- Added Mindless Laborer (npcID 252557, displayId 137487) as entry [24] in the Pit of Saron section (dungeonIdx 150)
- Removed 9-line `npcIdIsBoss` construction block from `UI/PackFrame.lua`
- Replaced `if npcIdIsBoss[npcID] then` with `if ns.AbilityDB[npcID] and ns.AbilityDB[npcID].mobCategory == "boss" then`

## Decisions Made

- **Boss detection in AbilityDB only:** The `isBoss` field in DungeonEnemies was a parallel data structure that could drift from AbilityDB. Consolidating to `mobCategory == "boss"` in AbilityDB makes AbilityDB the single authoritative source for mob classification.
- **Nil-guard retained:** Not every npcID is guaranteed to have an AbilityDB entry (e.g., pets, summons), so the nil-guard `ns.AbilityDB[npcID] and` is required for defense in depth.

## Verification Results

- `grep -rn "isBoss" Data/ UI/` returns nothing
- `grep -rn "npcIdIsBoss" UI/` returns nothing
- `grep "mobCategory.*boss" UI/PackFrame.lua` returns the new boss check at line 501
- `grep "252557" Data/DungeonEnemies.lua` returns `[24] = { id = 252557, name = "Mindless Laborer", displayId = 137487 },`
- `grep "252557" Data/PitOfSaron.lua` confirms AbilityDB entry exists with `mobCategory = "trivial"`

## Commits

| Task | Commit  | Description                                                      |
| ---- | ------- | ---------------------------------------------------------------- |
| 1    | d19b023 | feat(22-02): remove isBoss from DungeonEnemies, add Mindless Laborer |
| 2    | 715f9af | feat(22-02): replace npcIdIsBoss with AbilityDB mobCategory check in PackFrame |

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Data/DungeonEnemies.lua: FOUND
- UI/PackFrame.lua: FOUND
- Commit d19b023: FOUND
- Commit 715f9af: FOUND
