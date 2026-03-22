---
phase: 18-profiles-and-skill-config-rework
plan: 03
subsystem: engine-and-ui
tags: [soundEnabled, icon-display, scheduler, nameplate-scanner, config-ui, profile-import-export]

# Dependency graph
requires:
  - phase: 18-01
    provides: Import/Profile.lua with EncodeProfile/ImportProfile, MergeSkillConfig with soundEnabled field
  - phase: 18-02
    provides: ConfigFrame top bar with profile controls to extend

provides:
  - soundEnabled gating on SetUrgent (timed skills) and SetCastHighlight (untimed skills) in IconDisplay
  - soundEnabled parameter flowing from MergeSkillConfig through Scheduler to IconDisplay
  - Profile import popup (TPWProfileImport) with EditBox, Import/Cancel buttons
  - Profile export popup (TPWProfileExport) with pre-selected encoded string
  - Imp and Exp buttons in ConfigFrame top bar

affects:
  - Audio behavior: sound/TTS only fires when user has enabled it per-skill in profile
  - Users can now share profiles as encoded strings via Exp/Imp buttons

# Tech tracking
tech-stack:
  added: []
  patterns:
    - soundEnabled gate pattern: check flag before any PlaySound/TrySpeak call
    - Profile popup pattern: same singleton pattern as BuildSoundPopup (lazy build, show/hide)
    - Export auto-select: SetFocus + HighlightText after SetText for instant copy-paste

key-files:
  created: []
  modified:
    - Display/IconDisplay.lua
    - Engine/Scheduler.lua
    - Engine/NameplateScanner.lua
    - UI/ConfigFrame.lua

key-decisions:
  - "soundEnabled stored as `soundEnabled or false` on slot — nil from old data treated as false (sound off)"
  - "SetCastHighlight gates on ability.soundEnabled from pack data, not slot field — ability table carries the flag at call time"
  - "Export popup uses HighlightText() for instant copy selection; import popup clears EditBox text on each open"
  - "impBtn/expBtn sized at 45px each (matching New/Del) — anchored right of delBtn in chain"

# Metrics
duration: 3min
completed: 2026-03-21
---

# Phase 18 Plan 03: soundEnabled Engine Wiring and Profile Import/Export UI Summary

**soundEnabled gated in SetUrgent and SetCastHighlight; soundEnabled flows from MergeSkillConfig through Scheduler to IconDisplay; profile import/export popup frames with Imp/Exp buttons in top bar**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-21T21:47:35Z
- **Completed:** 2026-03-21T21:50:08Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `soundEnabled` as 7th parameter to `ShowIcon` and 6th parameter to `ShowStaticIcon`; stored as `slot.soundEnabled = soundEnabled or false` on the slot
- Replaced unconditional `PlaySound`/`TrySpeak` in `SetUrgent` with `if slot.soundEnabled then` block — timed skills only alert when user enabled sound
- Replaced unconditional audio in `SetCastHighlight` with `if ability.soundEnabled then` block — untimed skills only alert when user enabled sound
- Updated `Scheduler:Start` ShowIcon call and ShowStaticIcon call to pass `ability.soundEnabled`
- Added `soundEnabled = ability.soundEnabled` to the reschedule table in `scheduleAbility` so repeating cycles carry the flag
- Updated `NameplateScanner:OnMobsAdded` ShowStaticIcon call to pass `ability.soundEnabled`
- Created `BuildProfileImportPopup()` producing `TPWProfileImport` frame (400x250, DIALOG strata, UISpecialFrames registered) with ScrollFrame/EditBox, Import and Cancel buttons
- Import button calls `ns.Profile.ImportProfile(text)`, prints result, refreshes profileBtn text and calls UpdateDelButton
- Created `BuildProfileExportPopup()` producing `TPWProfileExport` frame with same structure; `ShowProfileExport()` fills EditBox with `EncodeProfile` output and calls `HighlightText()` for immediate copy
- Added `impBtn` (Imp, 45px) and `expBtn` (Exp, 45px) to ConfigFrame top bar, anchored right of delBtn

## Task Commits

1. **Task 1: Wire soundEnabled through IconDisplay, Scheduler, NameplateScanner** - `a920274` (feat)
2. **Task 2: Profile import/export popup frames in ConfigFrame** - `392472c` (feat)

## Files Created/Modified

- `Display/IconDisplay.lua` — soundEnabled parameter on ShowIcon/ShowStaticIcon, slot.soundEnabled storage, SetUrgent and SetCastHighlight audio gates
- `Engine/Scheduler.lua` — soundEnabled passed to ShowIcon and ShowStaticIcon; carried in reschedule table
- `Engine/NameplateScanner.lua` — soundEnabled passed in OnMobsAdded ShowStaticIcon call
- `UI/ConfigFrame.lua` — BuildProfileImportPopup, BuildProfileExportPopup, ShowProfileExport, impBtn, expBtn

## Decisions Made

- `soundEnabled or false` on slot storage — nil from pre-profile data treated as false (no sound), matching "soundEnabled defaults to false" from Plan 01
- `SetCastHighlight` gates on `ability.soundEnabled` from the ability table passed at call time (not the slot field) — untimed icons don't store soundEnabled on slot in the old path, but the ability table from OnCastStart carries it
- Export popup calls `HighlightText()` immediately after `SetText` so user can Ctrl+A / Ctrl+C without extra steps
- Import popup clears the EditBox text (`editBox:SetText("")`) on each open so stale strings don't confuse the user

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- All PROF-06 (import/export) and PROF-07 (sound gating) requirements are now complete
- Phase 18 is fully implemented
- No blockers.

---
*Phase: 18-profiles-and-skill-config-rework*
*Completed: 2026-03-21*
