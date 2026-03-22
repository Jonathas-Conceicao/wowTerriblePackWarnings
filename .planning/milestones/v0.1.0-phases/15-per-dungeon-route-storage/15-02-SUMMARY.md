---
phase: 15-per-dungeon-route-storage
plan: 02
subsystem: ui
tags: [lua, wow-addon, ui, dungeon-dropdown, combat-mode, packframe]

# Dependency graph
requires:
  - phase: 15-per-dungeon-route-storage
    plan: 01
    provides: Per-dungeon PackDatabase[dungeonKey] storage, ns.DUNGEON_IDX_MAP, CombatWatcher:SelectDungeon/SelectPack/GetState, Import.Clear(dungeonKey)
provides:
  - TPWDungeonDropdown popup with all 8 S1 dungeons sorted alphabetically
  - dungeonBtn selector button at top of PackFrame showing current dungeon name
  - UpdateHeader reads ns.db.importedRoutes[key] with empty-state message per dungeon
  - PopulateList reads PackDatabase[selectedKey] via GetSelectedDungeonKey()
  - Three combat mode buttons (Auto/Manual/Disable) with visual active state
  - Clear dialog shows selected dungeon name; OnAccept calls Import.Clear(key)
  - Zero "imported" string key references remaining in PackFrame.lua
affects: [16-cast-detection-sound-alerts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Dungeon dropdown as singleton BasicFrameTemplateWithInset popup (same pattern as sound popup in ConfigFrame)
    - Per-dungeon data reading via GetSelectedDungeonKey() helper centralizing ns.db.selectedDungeon access
    - Combat mode buttons using alpha + ColorTexture background to indicate active state

key-files:
  created: []
  modified:
    - UI/PackFrame.lua

key-decisions:
  - "dungeonBtn is a persistent GameMenuButtonTemplate button at top of frame; it opens the TPWDungeonDropdown singleton popup on click"
  - "GetSelectedDungeonKey() centralizes ns.db.selectedDungeon access so all per-dungeon reads go through one function"
  - "modeButtons table + UpdateModeButtons() called in both Refresh() and Initialize to keep visual state synced on open"
  - "SetCombatMode() calls PackUI:Refresh() after updating ns.db.combatMode so pack list re-evaluates combat state coloring immediately"
  - "Scroll frame TOPLEFT anchor moved from -46 to -66 to accommodate dungeonBtn (22px) + header gap (4px) below title bar"

patterns-established:
  - "Pattern: Singleton dropdown popup built on first use (BuildDungeonDropdown / ShowDungeonDropdown) matching ConfigFrame sound popup pattern"
  - "Pattern: Combat mode toggle buttons — array of buttons with btn.mode field, UpdateModeButtons() sets alpha+bg based on ns.db.combatMode"

requirements-completed: [ROUTE-02]

# Metrics
duration: 3min
completed: 2026-03-20
---

# Phase 15 Plan 02: PackFrame Dungeon Dropdown and Combat Mode Buttons Summary

**PackFrame.lua fully migrated to per-dungeon data: TPWDungeonDropdown popup selector, per-dungeon PopulateList/UpdateHeader, three combat mode toggle buttons, zero "imported" key references**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-20T08:37:26Z
- **Completed:** 2026-03-20T08:39:57Z
- **Tasks:** 2 (implemented together in one file write)
- **Files modified:** 1

## Accomplishments

- Added TPWDungeonDropdown singleton popup (BasicFrameTemplateWithInset, DIALOG strata) listing all 8 S1 dungeons alphabetically; clicking a dungeon sets ns.db.selectedDungeon and calls CombatWatcher:SelectDungeon if packs exist
- Replaced UpdateHeader to show per-dungeon pull count from ns.db.importedRoutes[key]; shows "No route imported. Click Import to add one." when key has no route; shows "Select a dungeon above" when no dungeon selected
- Replaced PopulateList to read PackDatabase[selectedKey] and compare activeDungeon == selectedKey; SelectPack and auto-scroll now use selectedKey
- Added three combat mode buttons (Auto/Manual/Disable) in second footer row; UpdateModeButtons() uses alpha (1.0 active / 0.5 inactive) plus tinted background texture for active button
- Clear dialog now shows "Clear route for [Dungeon Name]?" and OnAccept calls Import.Clear(key)
- Frame height increased from 400 to 430; scroll frame bottom anchor moved from 35 to 60 for second button row

## Task Commits

Both tasks are implemented in a single atomic commit (both tasks modify only PackFrame.lua):

1. **Tasks 1 + 2: Dungeon dropdown, per-dungeon PopulateList, combat mode buttons** - `13aee92` (feat)

**Plan metadata:** (pending final commit)

## Files Created/Modified

- `UI/PackFrame.lua` - Complete rewrite of PackFrame: dungeon dropdown, per-dungeon UpdateHeader/PopulateList, combat mode buttons, zero "imported" references

## Decisions Made

- Tasks 1 and 2 both modify only PackFrame.lua; they were implemented together in a single Write to avoid partial-state intermediate file; committed as one atomic feat commit
- GetSelectedDungeonKey() defined early in the file (before any usage) so UpdateHeader, PopulateList, Clear OnClick, and StaticPopup OnAccept all call through the same function
- dungeonBtn uses GameMenuButtonTemplate (same as import/clear/config buttons) for visual consistency
- Scroll frame top anchor: moved -46 to -66 (22px dungeonBtn height + 4px gap = 26px added below the title bar's existing -40px baseline, net shift 20px down)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PackFrame.lua is fully migrated to per-dungeon storage
- The "imported" key pattern is fully retired across all four files (Pipeline.lua, Core.lua, CombatWatcher.lua, PackFrame.lua)
- Phase 16 (cast detection and sound alerts) can now proceed — the structural refactor across the entire phase 15 scope is complete
- ZONE_DUNGEON_MAP instance names still need in-game verification for punctuation accuracy (deferred from phase 15-01)

---
*Phase: 15-per-dungeon-route-storage*
*Completed: 2026-03-20*

## Self-Check: PASSED

- FOUND: UI/PackFrame.lua
- FOUND: commit 13aee92
