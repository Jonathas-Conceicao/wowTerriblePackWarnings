---
phase: 18-profiles-and-skill-config-rework
plan: 01
subsystem: data
tags: [profiles, savedsvariables, schema-migration, encode-decode, libdeflate, aceserializer]

# Dependency graph
requires:
  - phase: 17-command-rework-and-config-search
    provides: Config UI and search foundation that profile system integrates with
provides:
  - Profile data layer: ns.db.profiles keyed storage with Default + named profiles
  - Schema v2 migration from flat skillConfig to profiles table
  - Import/Profile.lua module with CRUD, encode/decode, and import functions
  - Cleaned WindrunnerSpire.lua with spellID + defaultEnabled only
  - Profile-aware MergeSkillConfig reading from active profile
affects:
  - 18-02 through 18-03: All subsequent plans in phase 18 build on this data layer

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Profile encode chain: AceSerializer:Serialize -> LibDeflate:CompressDeflate -> LibDeflate:EncodeForPrint with ! prefix
    - Profile CRUD via ns.Profile table exposed on namespace
    - MergeSkillConfig reads ns.db.profiles[ns.db.activeProfile].skillConfig (never direct skillConfig)
    - Schema migration pattern: version check -> migrate -> bump version number

key-files:
  created:
    - Import/Profile.lua
  modified:
    - Data/WindrunnerSpire.lua
    - Core.lua
    - Import/Pipeline.lua
    - TerriblePackWarnings.toc

key-decisions:
  - "Profile skillConfig stores only user overrides; all abilities default to unchecked (defaultEnabled=false) until user enables them"
  - "first_cast/cooldown in merged ability come from profile cfg.timed flag only — data files no longer carry timing data"
  - "soundEnabled field added to merged ability output (defaults false); ttsMessage falls back to C_Spell.GetSpellInfo spell name"
  - "MAX_PROFILES = 15 enforced in CreateProfile; Default profile cannot be deleted"
  - "Schema v1->v2 migration preserves existing skillConfig by moving it to profiles.Default.skillConfig"

patterns-established:
  - "Profile encode/decode: ! prefix + LibDeflate:EncodeForPrint chain (mirrors MDT decode chain)"
  - "SwitchProfile always calls RestoreAllFromSaved to rebuild PackDatabase from new profile"
  - "GetSkillConfig falls back to Default profile if activeProfile is missing"

requirements-completed: [PROF-01, PROF-03, PROF-06]

# Metrics
duration: 3min
completed: 2026-03-21
---

# Phase 18 Plan 01: Data Layer — Profiles and Schema v2 Summary

**Profile data layer with v1->v2 schema migration, cleaned WindrunnerSpire data, and Import/Profile.lua CRUD + encode/decode module**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-21T21:35:02Z
- **Completed:** 2026-03-21T21:38:00Z
- **Tasks:** 2
- **Files modified:** 4 (+ 1 created)

## Accomplishments

- Stripped all hand-authored timing/name/label/TTS fields from WindrunnerSpire.lua — every ability entry now has only `spellID` + `defaultEnabled = false`
- Created Import/Profile.lua with 10 functions: GetSkillConfig, SetSkillField, SwitchProfile, CreateProfile (max 15), DeleteProfile, GetProfileNames, EncodeProfile, DecodeProfile, ImportProfile, plus MAX_PROFILES constant
- Added schema v1->v2 migration in Core.lua that migrates flat `skillConfig` into `profiles["Default"].skillConfig` and retires the old field
- Pivoted MergeSkillConfig in Pipeline.lua to read from active profile's skillConfig; timing fields come from `cfg.timed` flag, `soundEnabled` field added to merged output

## Task Commits

Each task was committed atomically:

1. **Task 1: Clean WindrunnerSpire data and create Profile.lua module** - `81bec1d` (feat)
2. **Task 2: Schema v2 migration and MergeSkillConfig profile pivot** - `f217502` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `Import/Profile.lua` — New module: profile CRUD + encode/decode via LibDeflate+AceSerializer chain
- `Data/WindrunnerSpire.lua` — Stripped to spellID + defaultEnabled only; updated header comment
- `Core.lua` — Added v1->v2 schema migration; retired ns.db.skillConfig initialization; added profiles/activeProfile init guards
- `Import/Pipeline.lua` — MergeSkillConfig now reads from active profile; timing from cfg.timed; soundEnabled added
- `TerriblePackWarnings.toc` — Added Import\Profile.lua after Import\Pipeline.lua

## Decisions Made

- Profile skillConfig stores only user overrides — all abilities unchecked by default because data files now have `defaultEnabled = false` everywhere
- `first_cast`/`cooldown` come from profile `cfg.timed` flag only; data files no longer carry timing data, so the scheduler receives nil timers unless user configures them
- `soundEnabled` field added to merged ability output (defaults `false`); `ttsMessage` falls back to `C_Spell.GetSpellInfo` spell name rather than a data-file string
- `MAX_PROFILES = 15` enforced at CreateProfile time; Default profile cannot be deleted (DeleteProfile returns false for "Default")
- Schema v1->v2 migration preserves any existing skillConfig by moving it to `profiles["Default"].skillConfig`

## Deviations from Plan

None — plan executed exactly as written.

Note: Core.lua still contains 3 references to `ns.db.skillConfig` inside the v1->v2 migration block (reading old data to migrate it, then setting to nil). This is correct and necessary migration code — the field is retired as active storage.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Profile data layer is complete and ready for Phase 18 Plan 02 (Config UI profile switcher)
- All subsequent plans can call `ns.Profile.*` functions to read/write skill config
- `ns.Import.RestoreAllFromSaved()` correctly rebuilds PackDatabase from active profile on login
- No blockers.

---
*Phase: 18-profiles-and-skill-config-rework*
*Completed: 2026-03-21*
