---
phase: 18-profiles-and-skill-config-rework
plan: 02
subsystem: ui
tags: [config-ui, profiles, timer-fields, sound-checkbox, profile-switcher]

# Dependency graph
requires:
  - phase: 18-01
    provides: Import/Profile.lua data layer — ns.Profile.* API

provides:
  - Per-skill timed toggle checkbox with first_cast and cooldown numeric inputs in ConfigFrame right panel
  - Sound alert checkbox per skill row independent of tracking checkbox
  - Profile top bar controls: dropdown, New, Delete buttons in ConfigFrame top bar
  - Window widened to 720px to accommodate new controls
  - All ConfigFrame skillConfig reads/writes now go through ns.Profile

affects:
  - 18-03: Profile export/import UI (if planned) — top bar now has profile controls to build on

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Profile dropdown follows BuildSoundPopup singleton pattern (lazy build, rebuild on show)
    - Timer EditBoxes use numeric-only OnTextChanged gsub filter and clamp on focus lost
    - Del button state managed via UpdateDelButton() stored on configFrame for access from StaticPopup OnAccept
    - configFrame.profileBtn and configFrame.delBtn stored as frame fields for cross-scope access

key-files:
  modified:
    - UI/ConfigFrame.lua

key-decisions:
  - "Timed toggle saves cfg.timed = true or nil (not false) to avoid polluting skillConfig with untimed noise"
  - "soundCheckBtn is independent of the tracking checkbox — sound alert can fire even when tracking is off"
  - "Del button disabled for Default profile via UpdateDelButton() called after every profile change"
  - "Profile dropdown uses v (ASCII) not the Unicode triangle — WoW font rendering constraint"
  - "Static timing label display (Row 2) replaced by timed toggle + first_cast/cooldown inputs"

# Metrics
duration: 4min
completed: 2026-03-21
---

# Phase 18 Plan 02: Config UI — Timer Fields, Sound Checkbox, Profile Controls

**Per-skill timer toggle + first_cast/cooldown inputs, sound alert checkbox, profile dropdown/New/Del top bar controls, and window widened to 720px**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-21T21:40:53Z
- **Completed:** 2026-03-21T21:44:55Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Migrated all 20 `ns.db.skillConfig` references in ConfigFrame.lua to `ns.Profile.GetSkillConfig()` / `ns.Profile.SetSkillField()` — zero direct skillConfig writes remain
- Updated Reset All StaticPopup to wipe active profile's skillConfig via `wipe(sc)` and call `RestoreAllFromSaved()`
- Replaced static timing label display with interactive timed toggle checkbox + first_cast and cooldown numeric EditBoxes (with OnTextChanged numeric filter and 1200s max clamp)
- Timer EditBoxes gray out at 0.4 alpha when Timed is unchecked; re-enable when checked
- Added soundCheckBtn per skill row — independent of the tracking checkbox per CONTEXT.md decision
- Added profile dropdown popup (TPWProfileDropdown) following BuildSoundPopup singleton pattern
- Added Profile button, New button, and Del button to top bar
- Del button is disabled (alpha 0.4) when Default profile is active; re-enables on profile switch
- Widened config window from 580px to 720px; Route/ResetAll buttons shrunk from 80px to 70px; search box from 200px to 160px

## Task Commits

1. **Task 1: Pivot all skillConfig references and add timer fields + sound checkbox** - `f926be7` (feat)
2. **Task 2: Profile top bar controls — dropdown, New, Delete buttons and window widening** - `ba0e629` (feat)

## Files Created/Modified

- `UI/ConfigFrame.lua` — Major update: all skillConfig I/O via ns.Profile; new timed toggle + first_cast/cooldown inputs; soundCheckBtn; profile dropdown popup; New/Del buttons; 720px width

## Decisions Made

- `timed` field saved as `true` or `nil` (never `false`) to keep skillConfig clean — nil means untimed
- `soundEnabled` saved as `true` or `nil` (never `false`) — independent of tracking checkbox
- `UpdateDelButton()` stored on `configFrame` table so TPW_DELETE_PROFILE StaticPopup OnAccept can call it without a direct upvalue
- Profile dropdown button uses " v" ASCII suffix instead of Unicode ▼ triangle to avoid WoW rendering issues
- Static "First cast: Xs, Cooldown: Ys" timing label replaced entirely by interactive inputs

## Deviations from Plan

### Auto-fixed Issues

None.

### Minor Adjustments

**1. UpdateDelButton inlined then extracted** — The plan showed UpdateDelButton as a standalone local function. I initially inlined the enable/disable logic then extracted it as `configFrame.UpdateDelButton` to satisfy the acceptance criteria and make it accessible from the StaticPopup OnAccept callback. This is cleaner than the plan's upvalue approach since the popup is defined at file scope before configFrame exists.

**2. Profile dropdown "▼" character** — The plan used `\226\150\188` (▼ Unicode). I used " v" (ASCII) instead because WoW's embedded font may not render arbitrary Unicode code points consistently.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Config UI now shows all PROF-02, PROF-04, PROF-05, PROF-07 controls
- Ready for in-game testing: `/tpw` opens config; profile dropdown, New, Del buttons functional; Timed toggle grays out timer fields when unchecked
- No blockers for Plan 03 (if applicable)

---
*Phase: 18-profiles-and-skill-config-rework*
*Completed: 2026-03-21*
