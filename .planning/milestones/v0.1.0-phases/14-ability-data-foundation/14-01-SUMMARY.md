---
phase: 14
plan: "01"
subsystem: ability-data
tags: [ability-db, config, pipeline, windrunner-spire, data-reconciliation]
dependency_graph:
  requires: []
  provides: [defaultEnabled mechanic, WindrunnerSpire MDT reconciliation]
  affects: [Import/Pipeline.lua, UI/ConfigFrame.lua, Data/WindrunnerSpire.lua]
tech_stack:
  added: []
  patterns: [defaultEnabled=false for MDT-sourced abilities, strict nil vs false for enabled state]
key_files:
  created: []
  modified:
    - Import/Pipeline.lua
    - UI/ConfigFrame.lua
    - Data/WindrunnerSpire.lua
decisions:
  - "New MDT-sourced abilities default to disabled (defaultEnabled=false) — user must explicitly enable via Config checkbox"
  - "Existing hand-authored abilities have no defaultEnabled field so they remain enabled by default"
  - "New npcIDs from MDT use mobClass=WARRIOR as the default (per v0.1.0 decision)"
  - "npcIDs 232071 and 250883 omitted (no spells in MDT data)"
metrics:
  duration: "~2 minutes"
  completed_date: "2026-03-17"
  tasks_completed: 2
  files_modified: 3
---

# Phase 14 Plan 01: Ability Data Foundation — defaultEnabled and WindrunnerSpire Reconciliation Summary

**One-liner:** defaultEnabled=false mechanic for MDT-sourced abilities with full WindrunnerSpire MDT reconciliation adding 108 disabled-by-default spell entries across 31 npcIDs.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add defaultEnabled support to MergeSkillConfig and ConfigFrame | aa9e80d | Import/Pipeline.lua, UI/ConfigFrame.lua |
| 2 | Reconcile WindrunnerSpire.lua with MDT spellIDs | f53d2d0 | Data/WindrunnerSpire.lua |

## What Was Built

### Task 1: defaultEnabled Mechanic

**Import/Pipeline.lua — MergeSkillConfig:** Added a check for `ability.defaultEnabled == false` in the `if not cfg then` branch. When no user override exists and the ability defaults to disabled, it is omitted from packs (returns nil). Once a user explicitly enables via the Config checkbox (`enabled = nil`), the cfg entry exists and the ability is included.

**UI/ConfigFrame.lua — CheckButton initial state:** Added `elseif not cfg and ability.defaultEnabled == false then checkBtn:SetChecked(false)` so abilities defaulting to disabled show as unchecked in the UI before the user has touched them. The OnClick handler already correctly writes `enabled = nil` when checked (creating the cfg entry) so no change was needed there.

### Task 2: WindrunnerSpire MDT Reconciliation

- 6 existing npcIDs preserved with all original fields (mobClass, name, spellID, first_cast, cooldown, label, ttsMessage)
- 5 existing npcIDs extended with missing MDT spellIDs as `defaultEnabled = false` entries
- 24 new npcIDs added from MDT (including all 5 bosses) with `mobClass = "WARRIOR"` and all abilities `defaultEnabled = false`
- 2 npcIDs skipped (232071, 250883) — no spells in MDT
- Final counts: 31 npcIDs, 108 `defaultEnabled = false` entries, 3 PALADIN entries preserved

## Verification Results

1. `grep -c "defaultEnabled = false" Data/WindrunnerSpire.lua` → 108 (>50 required)
2. `grep -c "mobClass" Data/WindrunnerSpire.lua` → 31 (>20 required)
3. Pipeline.lua contains `if ability.defaultEnabled == false then return nil end`
4. ConfigFrame.lua contains `elseif not cfg and ability.defaultEnabled == false then`
5. Original "Spellguard's Protection" entry intact
6. 3 PALADIN entries preserved (232113, 232122, 232121)

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

All files exist. Both task commits verified in git log.
