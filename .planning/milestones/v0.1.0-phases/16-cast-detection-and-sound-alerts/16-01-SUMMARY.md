---
phase: 16-cast-detection-and-sound-alerts
plan: 01
subsystem: display
tags: [lua, wow-addon, icon-display, sound, tts, cast-glow, scheduler, nameplate-scanner]

# Dependency graph
requires:
  - phase: 15-per-dungeon-route-storage
    provides: soundKitID and ttsMessage stored in pack.abilities via MergeSkillConfig
  - phase: 13-config-ui-and-pack-polish
    provides: ConfigFrame wired soundKitID into skillConfig; mutual exclusivity enforced in UI
provides:
  - Orange cast glow textures (castGlowTextures) on icon slots, separate from red urgent glow
  - SetCastHighlight and ClearCastHighlight public methods on ns.IconDisplay
  - PlaySound(soundKitID, "Master") in SetUrgent and SetCastHighlight
  - soundKitID and ttsMessage stored on all icon slots via ShowIcon and ShowStaticIcon
  - soundKitID carried through Scheduler reschedule cycle (including label fix)
affects:
  - 16-02-PLAN (cast detection engine — calls SetCastHighlight/ClearCastHighlight)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Separate castGlowTextures (orange) alongside glowTextures (red) — independent glow systems per slot
    - Sound/TTS mutually exclusive: soundKitID takes priority, TrySpeak fires when soundKitID is nil
    - PlaySound("Master") bypasses SFX-mute while respecting Master volume slider

key-files:
  created: []
  modified:
    - Display/IconDisplay.lua
    - Engine/Scheduler.lua
    - Engine/NameplateScanner.lua

key-decisions:
  - "Orange glow uses separate castGlowTextures field (not recolored glowTextures) to avoid state conflict when red and orange glows coexist"
  - "PlaySound uses Master channel per locked CONTEXT.md decision (not SFX channel used by Blizzard internally)"
  - "Sound and TTS are mutually exclusive per slot: soundKitID present -> PlaySound, soundKitID nil -> TrySpeak (backward compatible)"
  - "soundKitID added to Scheduler reschedule table alongside the pre-existing label fix (label was previously missing from reschedule)"

patterns-established:
  - "HideCastGlow called in both CancelIcon and CancelAll for proper cleanup"
  - "ShowStaticIcon now stores ttsMessage and soundKitID on slot for SetCastHighlight use"

requirements-completed: [HILITE-02, ALERT-01, ALERT-02, ALERT-03]

# Metrics
duration: 3min
completed: 2026-03-20
---

# Phase 16 Plan 01: Cast Detection and Sound Alerts — Display Primitives Summary

**Orange cast glow (separate from red urgent glow), SetCastHighlight/ClearCastHighlight on IconDisplay, and PlaySound wired through Scheduler + NameplateScanner ShowIcon/ShowStaticIcon calls**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-20T10:12:41Z
- **Completed:** 2026-03-20T10:15:06Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `CreateCastGlowTextures` with orange color (1, 0.5, 0, 1) as a parallel system to the existing red `glowTextures` — both can coexist visually on the same slot without conflict
- Implemented `SetCastHighlight(instanceKey, ability)` and `ClearCastHighlight(instanceKey)` as public methods on `ns.IconDisplay`, ready for Plan 02's cast detection engine
- Updated `SetUrgent` to play `PlaySound(soundKitID, "Master")` when configured, falling back to `TrySpeak` when not — sound and TTS are now mutually exclusive
- Extended `ShowIcon` and `ShowStaticIcon` signatures to accept and store `soundKitID` (and `ttsMessage` for static) on slot
- Wired `soundKitID` through the full Scheduler path: initial `ShowIcon`, reschedule table (also fixed missing `label`), and `ShowStaticIcon` in `Scheduler:Start`
- Wired `soundKitID` and `ttsMessage` through `NameplateScanner.OnMobsAdded` `ShowStaticIcon` call

## Task Commits

Each task was committed atomically:

1. **Task 1: Add orange cast glow, SetCastHighlight/ClearCastHighlight, PlaySound to IconDisplay** - `043e697` (feat)
2. **Task 2: Wire soundKitID through Scheduler and NameplateScanner ShowIcon/ShowStaticIcon calls** - `8760b23` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `Display/IconDisplay.lua` - Added orange cast glow system, SetCastHighlight, ClearCastHighlight, PlaySound in SetUrgent, soundKitID stored on slots
- `Engine/Scheduler.lua` - soundKitID passed to ShowIcon, reschedule table, and ShowStaticIcon; label added to reschedule table
- `Engine/NameplateScanner.lua` - ttsMessage and soundKitID passed to ShowStaticIcon in OnMobsAdded

## Decisions Made

- Orange glow uses a separate `castGlowTextures` field rather than recoloring `glowTextures`, so both red urgent glow and orange cast glow can be active simultaneously on a timed skill's icon without color conflict (Pitfall 4 from research).
- `PlaySound` uses `"Master"` channel per the locked CONTEXT.md decision; Blizzard uses `"SFX"` internally but `"Master"` bypasses the SFX-mute slider.
- `label` was previously missing from the Scheduler reschedule table — added alongside `soundKitID` as a Rule 1 auto-fix (the label would disappear on icon reset after first cycle).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added missing `label` to Scheduler reschedule table**
- **Found during:** Task 2 (reading the existing reschedule table)
- **Issue:** The plan explicitly noted "also add `label = ability.label` which was previously missing from the reschedule table" — the label field was absent, causing the label text to disappear after the first cooldown cycle when ShowIcon resets the icon slot
- **Fix:** Added `label = ability.label` to the reschedule table alongside `soundKitID`
- **Files modified:** Engine/Scheduler.lua
- **Verification:** grep "ability.label" Engine/Scheduler.lua shows label in reschedule table at line 63
- **Committed in:** 8760b23 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug, explicitly called out in plan action)
**Impact on plan:** Fix was planned/expected — the plan action text documented it explicitly. No scope creep.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `ns.IconDisplay.SetCastHighlight` and `ns.IconDisplay.ClearCastHighlight` are ready for Plan 02's cast detection engine to call
- `soundKitID` flows end-to-end: pack.abilities -> Scheduler -> ShowIcon -> slot -> SetUrgent -> PlaySound
- Static icon slots now store `ttsMessage` and `soundKitID` for use by `SetCastHighlight`
- No blockers for Plan 02

## Self-Check: PASSED

- Display/IconDisplay.lua: FOUND
- Engine/Scheduler.lua: FOUND
- Engine/NameplateScanner.lua: FOUND
- 16-01-SUMMARY.md: FOUND
- Commit 043e697: FOUND
- Commit 8760b23: FOUND

---
*Phase: 16-cast-detection-and-sound-alerts*
*Completed: 2026-03-20*
