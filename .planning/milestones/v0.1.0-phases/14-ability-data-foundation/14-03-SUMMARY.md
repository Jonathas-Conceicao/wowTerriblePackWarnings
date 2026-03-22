---
phase: 14-ability-data-foundation
plan: "03"
subsystem: data
tags: [lua, wow-addon, ability-data, mdt, pipeline, restore-from-saved]

# Dependency graph
requires:
  - phase: 14-ability-data-foundation
    provides: AbilityDB pattern established and 8 dungeon stubs created in 14-01/14-02
provides:
  - Fixed RestoreFromSaved that rebuilds packs from preset + current skillConfig on login
  - Full AbilityDB for Magisters Terrace (22 npcIDs, 86 spells)
  - Full AbilityDB for Seat of the Triumvirate (19 npcIDs, 73 spells)
  - Murder Row completely removed from all addon files
affects: [phase-15-per-dungeon-route-storage, phase-16-cast-detection]

# Tech tracking
tech-stack:
  added: []
  patterns: [preset-saved-for-restore, legacy-fallback-on-restore]

key-files:
  created: []
  modified:
    - Import/Pipeline.lua
    - Data/MagistersTerrace.lua
    - Data/SeatoftheTriumvirate.lua
    - TerriblePackWarnings.toc
    - scripts/install.bat
  deleted:
    - Data/MurderRow.lua

key-decisions:
  - "Save preset in ns.db.importedRoute so RestoreFromSaved can rebuild from current skillConfig — not just stale serialized packs"
  - "Legacy fallback in RestoreFromSaved preserves compatibility with saves that lack preset field"
  - "Murder Row (dungeonIdx 160) removed from DUNGEON_IDX_MAP and all file references — not a Midnight S1 dungeon"

patterns-established:
  - "Restore pattern: RunFromPreset(saved.preset) rebuilds packs fresh with current skillConfig on every login"

requirements-completed: [DATA-13, DATA-14, DATA-15]

# Metrics
duration: 15min
completed: 2026-03-20
---

# Phase 14 Plan 03: Pipeline Fix and MT/SotT Data Summary

**Fixed RestoreFromSaved to rebuild packs from saved preset + current skillConfig; populated Magisters Terrace (22 npcIDs) and Seat of the Triumvirate (19 npcIDs) with MDT spell data; Murder Row removed from all addon files**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-20T07:29:00Z
- **Completed:** 2026-03-20T07:44:33Z
- **Tasks:** 3
- **Files modified:** 5 (+ 1 deleted)

## Accomplishments
- RestoreFromSaved now calls RunFromPreset(saved.preset) so ability enable/disable changes in skillConfig survive /reload — closes UAT gap 2
- Magisters Terrace has 22 npcID entries with 86 total spells from MDT source
- Seat of the Triumvirate has 19 npcID entries with 73 total spells from MDT source
- Murder Row (dungeonIdx 160) removed from DUNGEON_IDX_MAP, TOC, install.bat, and data file deleted — closes UAT gap 3
- Legacy fallback preserved in RestoreFromSaved for saves that pre-date the preset field

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix RestoreFromSaved and remove Murder Row from Pipeline.lua** - `bf1c79f` (fix)
2. **Task 2: Populate Magisters Terrace and Seat of the Triumvirate data files** - `ead4c70` (feat)
3. **Task 3: Remove Murder Row from TOC and install.bat, delete Data/MurderRow.lua** - `289e8fc` (chore)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `Import/Pipeline.lua` - Murder Row removed from DUNGEON_IDX_MAP; preset field added to importedRoute save; RestoreFromSaved rebuilt to call RunFromPreset; legacy fallback added
- `Data/MagistersTerrace.lua` - Populated with 22 npcID entries and 86 spells from MDT
- `Data/SeatoftheTriumvirate.lua` - Populated with 19 npcID entries and 73 spells from MDT
- `TerriblePackWarnings.toc` - Removed Data\MurderRow.lua entry
- `scripts/install.bat` - Removed MurderRow.lua copy command
- `Data/MurderRow.lua` - Deleted

## Decisions Made
- Save `preset` field in `ns.db.importedRoute` so `RestoreFromSaved` can call `RunFromPreset` to rebuild with current skillConfig. This means enabling/disabling skills in the config UI will be reflected after /reload without needing to re-import.
- Legacy fallback in `RestoreFromSaved` (copy `saved.packs` directly) preserved for any existing saves without the new `preset` field.
- Print statement in the rebuild path of `RestoreFromSaved` is intentionally after `RunFromPreset` to avoid double-printing (RunFromPreset already prints "Imported: ..."). The second print provides a "Restored:" prefix to distinguish login restore from a live import.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added preset field to ns.db.importedRoute save**
- **Found during:** Task 1 (Fix RestoreFromSaved)
- **Issue:** The plan's new RestoreFromSaved called `Import.RunFromPreset(saved.preset)` but `RunFromPreset` never saved `preset` to `ns.db.importedRoute` — only `dungeonName`, `dungeonIdx`, and `packs` were saved. Without the preset, the rebuild path would always fall through to the legacy fallback.
- **Fix:** Added `preset = preset` to the `ns.db.importedRoute` table in `RunFromPreset`
- **Files modified:** Import/Pipeline.lua
- **Verification:** RestoreFromSaved can now access `saved.preset` for the rebuild path
- **Committed in:** bf1c79f (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Fix was essential for the RestoreFromSaved rebuild to actually work. Without saving preset, the feature would silently fall through to the stale-pack legacy path on every login.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 9 Midnight S1 dungeon AbilityDB files are now populated (8 from Phase 14, WindrunnerSpire from earlier phases)
- RestoreFromSaved correctly rebuilds packs from current skillConfig on login
- Murder Row completely removed — no dead code or unreachable dungeon entries remain
- Ready for Phase 15: Per-Dungeon Route Storage structural refactor

---
*Phase: 14-ability-data-foundation*
*Completed: 2026-03-20*
