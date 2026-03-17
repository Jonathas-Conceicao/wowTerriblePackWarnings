---
phase: 14-ability-data-foundation
plan: "02"
subsystem: data
tags: [ability-db, dungeon-data, mdt-extraction]
dependency_graph:
  requires: []
  provides: [ns.AbilityDB entries for 8 dungeons]
  affects: [UI/ConfigFrame.lua, Import/Pipeline.lua]
tech_stack:
  added: []
  patterns: [npcID-keyed AbilityDB, mobClass WARRIOR default, defaultEnabled false]
key_files:
  created:
    - Data/AlgetharAcademy.lua
    - Data/MagistersTerrace.lua
    - Data/MaisaraCaverns.lua
    - Data/MurderRow.lua
    - Data/NexusPointXenas.lua
    - Data/PitOfSaron.lua
    - Data/SeatoftheTriumvirate.lua
    - Data/Skyreach.lua
  modified:
    - TerriblePackWarnings.toc
    - scripts/install.bat
decisions:
  - "MDT spells tables contain exactly one spellID per mob — no multi-spell mobs found across all 5 dungeons"
  - "Outcast Servant (76132) included in Skyreach despite plan note suggesting exclusion — MDT data shows it HAS a spellID (152953)"
  - "[DNT] Conduit Stalker (250299) included in NexusPointXenas — plan does not specify exclusion of DNT mobs"
metrics:
  duration: "~10 minutes"
  completed: "2026-03-17"
  tasks_completed: 2
  files_created: 8
  files_modified: 2
---

# Phase 14 Plan 02: Ability Data Foundation - Dungeon Data Files Summary

Extracted MDT spellIDs for 8 remaining Midnight S1 dungeons into AbilityDB data files — 5 with full mob data from MDT, 3 stub files for dungeons with no MDT spell data yet.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create 8 dungeon AbilityDB data files from MDT source | 631a426 | Data/AlgetharAcademy.lua, Data/MagistersTerrace.lua, Data/MaisaraCaverns.lua, Data/MurderRow.lua, Data/NexusPointXenas.lua, Data/PitOfSaron.lua, Data/SeatoftheTriumvirate.lua, Data/Skyreach.lua |
| 2 | Update TOC and install.bat with new Data files | e115ae4 | TerriblePackWarnings.toc, scripts/install.bat |

## What Was Built

**5 full data files** extracted from MDT source:
- `Data/AlgetharAcademy.lua` — 16 mobs (dungeonIndex 45)
- `Data/PitOfSaron.lua` — 22 mobs (dungeonIndex 150)
- `Data/Skyreach.lua` — 22 mobs (dungeonIndex 151)
- `Data/MaisaraCaverns.lua` — 31 mobs (dungeonIndex 154)
- `Data/NexusPointXenas.lua` — 34 mobs (dungeonIndex 155)

**3 stub files** for dungeons with no MDT spell data yet:
- `Data/MagistersTerrace.lua` — 25 enemies in MDT but no spell tables
- `Data/SeatoftheTriumvirate.lua` — 22 enemies in MDT but no spell tables
- `Data/MurderRow.lua` — no enemies in MDT at all

**Schema** (all new entries):
- `mobClass = "WARRIOR"` (default for all MDT-sourced mobs)
- `defaultEnabled = false` (user must opt-in per spell)
- No `name`, `label`, `ttsMessage`, `first_cast`, or `cooldown` fields (resolved dynamically or N/A)

**TOC** updated with 8 new Data lines between `WindrunnerSpire.lua` and `Sounds.lua`, all before `Pipeline.lua`.

**install.bat** updated with 8 new copy commands in the Data section.

## Mob Counts by Dungeon

| Dungeon | npcIDs | Status |
|---------|--------|--------|
| Algethar Academy | 16 | Full data |
| Pit of Saron | 22 | Full data |
| Skyreach | 22 | Full data |
| Maisara Caverns | 31 | Full data |
| Nexus Point Xenas | 34 | Full data |
| Magisters Terrace | 0 | Stub |
| Seat of the Triumvirate | 0 | Stub |
| Murder Row | 0 | Stub |

## Deviations from Plan

### Auto-observed Differences

**1. Outcast Servant (75976) has spells in MDT**

- **Found during:** Task 1 extraction
- **Issue:** Plan said to skip Outcast Servant (75976) if it has no spells. MDT extraction showed it has spellID 152953.
- **Fix:** Included it. Plan note was incorrect — it does have a spell entry.
- **Files modified:** Data/Skyreach.lua

**2. All mobs have exactly one spell each**

- **Found during:** Task 1 extraction
- **Issue:** Plan format shows multi-spell ability arrays, but MDT spells tables for these dungeons contain exactly one spellID per mob.
- **Fix:** Single-entry ability arrays written correctly.

None — plan executed as designed for all structural requirements. All acceptance criteria met.

## Self-Check: PASSED

All 8 data files exist on disk. Both task commits (631a426, e115ae4) confirmed in git log.
