---
phase: 08-ability-database-and-decode-library
plan: 01
subsystem: database
tags: [lua, wow-addon, ability-data, libdeflate, ace-serializer, libstub]

requires:
  - phase: 03-pack-selection-and-combat-state-ui
    provides: PackDatabase namespace and UI framework
provides:
  - npcID-keyed AbilityDB data structure in ns.AbilityDB
  - LibStub, AceSerializer-3.0, LibDeflate bundled in Libs/
  - TOC loading order with libs before addon code
  - pkgmeta externals for CurseForge release packaging
affects: [09-mdt-import-pipeline, 10-route-to-pack-conversion]

tech-stack:
  added: [LibStub, AceSerializer-3.0, LibDeflate]
  patterns: [npcID-keyed ability lookup, XML lib loader]

key-files:
  created:
    - Libs/load_libs.xml
    - Libs/LibStub/LibStub.lua
    - Libs/AceSerializer-3.0/AceSerializer-3.0.lua
    - Libs/LibDeflate/LibDeflate.lua
  modified:
    - Core.lua
    - Data/WindrunnerSpire.lua
    - TerriblePackWarnings.toc
    - .pkgmeta
    - scripts/install.bat

key-decisions:
  - "Sourced LibStub and AceSerializer from MethodDungeonTools repo (older MDT fork) since MythicDungeonTools only bundles LibDeflate locally"
  - "Duplicated shared abilities by value for npcIDs 232122/232121 rather than using references"

patterns-established:
  - "AbilityDB pattern: ns.AbilityDB[npcID] = { mobClass, abilities[] } for per-mob ability lookup"
  - "Libs/ folder with load_libs.xml for third-party library management"

requirements-completed: [DATA-10, DATA-11]

duration: 2min
completed: 2026-03-16
---

# Phase 8 Plan 01: Ability Database and Decode Library Summary

**npcID-keyed AbilityDB with 6 Windrunner Spire mob entries, plus LibStub/AceSerializer/LibDeflate bundled for MDT decode pipeline**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-16T03:16:33Z
- **Completed:** 2026-03-16T03:18:36Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Rewrote WindrunnerSpire.lua from hardcoded pack data to npcID-keyed AbilityDB with 6 mob entries
- Bundled LibStub, AceSerializer-3.0, and LibDeflate in Libs/ with proper XML load order
- Updated TOC, pkgmeta, and install script for library loading and distribution

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite AbilityDB data and initialize namespace** - `62835e4` (feat)
2. **Task 2: Bundle libraries and update build files** - `a7b6d42` (feat)

## Files Created/Modified
- `Data/WindrunnerSpire.lua` - Replaced pack data with npcID-keyed AbilityDB (6 entries)
- `Core.lua` - Added ns.AbilityDB initialization alongside ns.PackDatabase
- `Libs/load_libs.xml` - XML loader: LibStub -> AceSerializer -> LibDeflate
- `Libs/LibStub/LibStub.lua` - Library version registry (from MethodDungeonTools)
- `Libs/AceSerializer-3.0/AceSerializer-3.0.lua` - Lua table serialization
- `Libs/LibDeflate/LibDeflate.lua` - DEFLATE compression/decompression
- `TerriblePackWarnings.toc` - Added Libs\load_libs.xml before Core.lua, added Import\Decode.lua
- `.pkgmeta` - Added externals section for CurseForge packaging
- `scripts/install.bat` - Added Libs/ and Import/ folder copy blocks

## Decisions Made
- Sourced LibStub and AceSerializer from MethodDungeonTools repo since MythicDungeonTools only bundles LibDeflate locally (externals are fetched at packaging time)
- Duplicated shared abilities by value for npcIDs 232122/232121 (Interrupting Screech) for simplicity and independence

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- LibStub and AceSerializer-3.0 not found in MythicDungeonTools/libs (only LibDeflate bundled there). Found them in the older MethodDungeonTools repo instead. Same libraries, same versions.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- AbilityDB populated and ready for Phase 9 import pipeline to query
- Decode libraries (LibDeflate, AceSerializer) ready for MDT string decompression
- Import\Decode.lua entry added to TOC (file to be created in Plan 08-02)

---
*Phase: 08-ability-database-and-decode-library*
*Completed: 2026-03-16*
