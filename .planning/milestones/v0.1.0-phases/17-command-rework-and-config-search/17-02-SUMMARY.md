---
phase: 17-command-rework-and-config-search
plan: 02
subsystem: ui
tags: [lua, wow-addon, config-frame, search, filter]

# Dependency graph
requires:
  - phase: 17-01
    provides: slash command rework that opens ConfigUI

provides:
  - Top bar with Route button, Reset All (global), and search EditBox in ConfigFrame
  - Real-time search filtering of dungeon/mob tree by mob name and skill name
  - Filtered right panel showing only matched skills when search is active
  - Right panel header with square portrait, "Mob Name - CLASS" text, and horizontal divider
  - StaticPopupDialogs["TPW_CONFIRM_RESET_ALL"] for global skill config reset

affects:
  - ConfigFrame.lua future modifications

# Tech tracking
tech-stack:
  added: []
  patterns:
    - C_Timer.NewTimer debounce pattern for search input (0.3s delay)
    - node.visible + node.mobRows for per-node and per-row show/hide during filtering
    - matchedSpellIDs optional param propagated from ApplySearchFilter to PopulateRightPanel

key-files:
  created: []
  modified:
    - UI/ConfigFrame.lua

key-decisions:
  - "Route button in top bar calls ns.PackUI.Toggle() — opens route window from config window"
  - "Reset All in top bar (not bottom-right) resets ALL dungeons globally via StaticPopup confirmation"
  - "Search debounce is 0.3s via C_Timer.NewTimer; timer cancelled and restarted on each keystroke"
  - "node.visible=false causes RebuildLayout to hide both header and content frame via goto continueNode"
  - "When search active and mob name matches, show all abilities; when only spell name matches, populate currentMatchedSpells for that mob"
  - "OnHide resets search state and restores all nodes to visible (no visible state leak between sessions)"
  - "HEADER_PORTRAIT_SIZE=36; skill row yOffset starts at HEADER_PORTRAIT_SIZE+20 to clear portrait+divider"
  - "headerPortrait uses TempPortraitAlphaMask for square clip, hidden until mob selected"
  - "hDivider SetColorTexture(0.4,0.4,0.4,0.8) matches vertical divider for visual consistency"
  - "rightPanelHeader alias kept pointing to headerNameStr for backward compatibility"

patterns-established:
  - "ApplySearchFilter: clear state first, then scan BuildDungeonIndex, then update nodes, then call RebuildLayout"
  - "mob row repositioning inside ApplySearchFilter when filter active (not in RebuildLayout)"

requirements-completed: [CMD-03, SEARCH-01, SEARCH-02, UIPOL-01]

# Metrics
duration: 4min
completed: 2026-03-20
---

# Phase 17 Plan 02: Config Search, Top Bar, and Right Panel Header Summary

**Config window gains Route/Reset-All/Search top bar, real-time mob+skill name filtering with debounce, and a portrait+name+divider right panel header replacing the bare FontString**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-20T18:45:53Z
- **Completed:** 2026-03-20T18:49:18Z
- **Tasks:** 2 (implemented together in single write)
- **Files modified:** 1

## Accomplishments
- Route button in top bar opens the pack selection window via `ns.PackUI.Toggle()`
- Reset All button in top bar shows `TPW_CONFIRM_RESET_ALL` StaticPopup that wipes all `ns.db.skillConfig` entries globally
- Search EditBox with 0.3s debounce filters the dungeon/mob tree in real time by mob name and spell name
- ApplySearchFilter populates `currentMatchedMobs` and `currentMatchedSpells`, auto-expands matching nodes, hides non-matching mob rows, and updates `node.contentHeight` for proper scroll layout
- `PopulateRightPanel` accepts optional `matchedSpellIDs` param; when active, skips non-matching ability rows via `goto continueAbility`
- `configFrame:SetScript("OnHide")` clears search state and restores all nodes to visible
- `OpenToMob` clears search before expanding, ensuring clean state when navigating from PackFrame
- Right panel header replaced with portrait (36px square, TempPortraitAlphaMask) + "Mob Name - CLASS" FontString + horizontal divider; portrait and divider hidden until mob selected
- Skill row yOffset starts at `HEADER_PORTRAIT_SIZE + 20` to account for header area

## Task Commits

1. **Task 1+2: Top bar layout, search filtering, right panel header** - `ce9d4c7` (feat)

**Plan metadata:** (to follow in final commit)

## Files Created/Modified
- `UI/ConfigFrame.lua` - Added top bar, search, ApplySearchFilter, right panel header with portrait and divider

## Decisions Made
- Route button calls `ns.PackUI.Toggle()` — consistent with existing PackUI public API
- Reset All moves from bottom-right to top bar and becomes global (not per-dungeon) with StaticPopup confirmation
- Search filter clears and restores properly in two places: `OnHide` and `OpenToMob`
- `node.visible == false` check uses `goto continueNode` in RebuildLayout — idiomatic Lua for early continue
- When mob name matches: all abilities shown (no `currentMatchedSpells` entry for that mob)
- When only spell name matches: `currentMatchedSpells[npcID]` holds the matching spellID set
- `rightPanelHeader` alias kept pointing to `headerNameStr` for any future compat code

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All 17-02 requirements satisfied: CMD-03 (Route button), SEARCH-01 (search box with debounce), SEARCH-02 (filtered right panel + search reset on close), UIPOL-01 (Reset All in top bar with confirmation)
- Phase 17 complete; config window UX polish is done

## Self-Check: PASSED

- `UI/ConfigFrame.lua` exists: FOUND
- Commit `ce9d4c7` exists: FOUND

---
*Phase: 17-command-rework-and-config-search*
*Completed: 2026-03-20*
