---
phase: 05-custom-spell-icon-display
plan: 01
subsystem: ui
tags: [wow-api, cooldown-sweep, tts, spell-icons, lua]

# Dependency graph
requires:
  - phase: 04-data-schema-and-pack-update
    provides: Flattened abilities list with mobClass, timed/untimed schema
provides:
  - IconDisplay module with ShowIcon, ShowStaticIcon, SetUrgent, CancelIcon, CancelAll API
  - WindrunnerSpire pack data with ttsMessage fields
affects: [05-02-scheduler-integration, 05-03-legacy-removal]

# Tech tracking
tech-stack:
  added: []
  patterns: [CooldownFrameTemplate sweep animation, C_VoiceChat.SpeakText TTS, red border glow via texture edges]

key-files:
  created: [Display/IconDisplay.lua]
  modified: [Data/WindrunnerSpire.lua]

key-decisions:
  - "Simple red border glow via 4 edge textures instead of LibCustomGlow"
  - "BackdropTemplate with 1px dark edgeFile for non-glow icon border"
  - "C_TTSSettings.GetVoiceOptionID with C_VoiceChat.GetTtsVoices fallback for voice ID resolution"

patterns-established:
  - "IconDisplay API pattern: instanceKey-based slot management with horizontal re-layout"
  - "TTS pattern: short callout strings via ttsMessage field, post-12.0.0 SpeakText signature"

requirements-completed: [DISP-01, DISP-02, DISP-03, DISP-04, DISP-05, DISP-08]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 5 Plan 1: Custom Spell Icon Display Summary

**IconDisplay module with cooldown sweep animations, red border urgency glow, and C_VoiceChat TTS callouts on a horizontal icon row**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-15T20:32:47Z
- **Completed:** 2026-03-15T20:36:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created complete IconDisplay module with 5 public API functions for spell icon management
- Implemented cooldown sweep animation using CooldownFrameTemplate for timed abilities
- Built TTS callout system using C_VoiceChat.SpeakText with voice ID fallback chain
- Added ttsMessage = "Shield" to Spellguard's Protection in WindrunnerSpire pack data

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Display/IconDisplay.lua with full icon display API** - `08b4bb7` (feat)
2. **Task 2: Add ttsMessage field to WindrunnerSpire pack data** - `b90979b` (feat)

## Files Created/Modified
- `Display/IconDisplay.lua` - Complete spell icon display module (246 lines) with ShowIcon, ShowStaticIcon, SetUrgent, CancelIcon, CancelAll
- `Data/WindrunnerSpire.lua` - Added ttsMessage = "Shield" to Spellguard's Protection ability

## Decisions Made
- Used BackdropTemplate with 1px WHITE8X8 edgeFile for subtle dark border on non-glowing icons
- Red glow implemented as 4 edge textures (2px each) at OVERLAY layer for visibility
- TTS voice resolution: C_TTSSettings.GetVoiceOptionID first, C_VoiceChat.GetTtsVoices fallback
- SetColorTexture fallback when C_Spell.GetSpellTexture returns nil

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- IconDisplay API ready for Scheduler integration (Plan 02)
- Pack data has ttsMessage fields ready for TTS callouts
- Legacy BossWarnings.lua still present, to be removed in Plan 03

## Self-Check: PASSED

- FOUND: Display/IconDisplay.lua
- FOUND: Data/WindrunnerSpire.lua
- FOUND: commit 08b4bb7
- FOUND: commit b90979b

---
*Phase: 05-custom-spell-icon-display*
*Completed: 2026-03-15*
