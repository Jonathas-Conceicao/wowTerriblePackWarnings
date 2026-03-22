---
phase: 16-cast-detection-and-sound-alerts
plan: "02"
subsystem: engine
tags: [cast-detection, nameplate-scanner, UnitCastingInfo, secret-values]
dependency_graph:
  requires: [16-01]
  provides: [cast detection via UnitCastingInfo, class-based cast glow]
  affects: [Engine/NameplateScanner.lua, Display/IconDisplay.lua]
tech_stack:
  added: []
  patterns: [class-based cast detection (not spell-based), pcall UnitCastingInfo, Secret Values workaround]
key_files:
  created: []
  modified:
    - Engine/NameplateScanner.lua
    - Display/IconDisplay.lua
decisions:
  - "UnitCastingInfo spellID is a Secret Value in Midnight — cannot use as table key"
  - "Cast detection uses name presence (non-nil) instead of spellID matching"
  - "Detection is class-based: any mob of tracked class casting → glow all untimed skills for that class"
  - "UnitHealth/UnitHealthMax also Secret Values — cannot use for HP-based timing"
  - "Glow reverted to simple 2px edge textures (ActionButton_ShowOverlayGlow not available in Midnight)"
  - "Variable shadowing bug fixed: local 'g' table shadowed 'g' (green) parameter in CreateGlowTextures"
metrics:
  duration: "~30 minutes (including debugging)"
  completed_date: "2026-03-20"
  tasks_completed: 2
  files_modified: 2
---

# Phase 16 Plan 02: Cast Detection Engine Summary

**One-liner:** UnitCastingInfo-based cast detection with Secret Values workaround — class-based orange glow on untimed skills when any mob of matching class is casting.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add spellIndex, castingByClass, and cast detection to NameplateScanner | d58e35f | Engine/NameplateScanner.lua |
| 2 | In-game verification checkpoint | — (approved with post-checkpoint fixes) | — |

## Post-Checkpoint Fixes

| Fix | Commit | Issue |
|-----|--------|-------|
| Secret Values workaround | 0880078 | UnitCastingInfo spellID is "table index is secret" — switched to name-based detection |
| Variable shadowing | 6ffaebf | local `g` table shadowed `g` (green) parameter in CreateGlowTextures |
| Glow revert | a8f8d21 | ActionButton_ShowOverlayGlow not available in Midnight — reverted to 2px edge textures |
| HP debug removal | 5ba3ae4 | UnitHealth/UnitHealthMax are Secret Values — removed test logging |

## What Was Built

### Cast Detection Engine (NameplateScanner.lua)

- `spellIndex` table built at `Start()` — maps spellID → ability for untimed skills (used for class lookup, not spellID matching)
- `castingByClass` table tracks per-class cast state across ticks
- Cast detection pass in `Tick()`: polls `UnitCastingInfo`/`UnitChannelInfo` with `pcall` for each nameplate
- Checks if casting name is non-nil (Secret Values prevent spellID usage), then matches class against untimed abilities
- State transition detection: `nil → true` fires `OnCastStart` (orange glow + alert), `true → nil` fires `OnCastEnd` (clear glow)

### Secret Values Discovery

Midnight wraps these API values as Secret Values on nameplate units:
- `UnitCastingInfo` spellID (position 9) — "table index is secret"
- `UnitChannelInfo` spellID (position 8) — same
- `UnitHealth` / `UnitHealthMax` — cannot do math

**What works:** `UnitCastingInfo` name (position 1) returns a usable string.

### Glow System (IconDisplay.lua)

- `CreateGlowTextures` parameterized for both red (timed) and orange (cast detection) glows
- Fixed variable shadowing: renamed local table from `g` to `textures`, parameter from `g` to `green`
- Reverted from ActionButton overlay glow (unavailable) to simple 2px edge textures

## Deviations from Plan

- **Major:** spellID-based cast matching replaced with class-based name presence detection due to Secret Values
- **Minor:** ActionButton_ShowOverlayGlow unavailable, fell back to edge textures
- **Minor:** HP-based timing investigated and abandoned (also Secret Values)

## Self-Check: PASSED

All files exist. Commits verified in git log. Cast detection working in-game with orange glow.
