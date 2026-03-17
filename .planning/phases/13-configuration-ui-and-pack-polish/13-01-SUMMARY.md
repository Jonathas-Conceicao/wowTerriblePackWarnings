---
phase: 13-configuration-ui-and-pack-polish
plan: "01"
subsystem: data-layer
tags: [sounds, pipeline, skillconfig, dungeon-map, slash-command, toc]
dependency_graph:
  requires: []
  provides:
    - ns.AlertSounds (Data/Sounds.lua)
    - ns.DUNGEON_IDX_MAP (Import/Pipeline.lua)
    - MergeSkillConfig (Import/Pipeline.lua)
    - pack.mobCounts (Import/Pipeline.lua BuildPack)
    - ns.db.skillConfig initialization (Core.lua)
    - /tpw config slash command (Core.lua)
  affects:
    - Import/Pipeline.lua BuildPack (abilities now filtered/merged via skillConfig)
    - TerriblePackWarnings.toc (load order updated for Data/Sounds.lua, UI/ConfigFrame.lua)
tech_stack:
  added:
    - Data/Sounds.lua (new file — sound catalog with 12 entries)
  patterns:
    - Sparse skillConfig override schema (nil = default = enabled, false = disabled)
    - MergeSkillConfig: per-ability merge helper, returns nil to silently drop disabled abilities
    - mobCounts first-pass before seenNpc dedup in BuildPack
key_files:
  created:
    - Data/Sounds.lua
  modified:
    - Import/Pipeline.lua
    - Core.lua
    - TerriblePackWarnings.toc
decisions:
  - "cfg.enabled == false strict equality check (not 'not cfg.enabled') — nil means use default = enabled"
  - "MergeSkillConfig returns nil for disabled abilities; seenAbility guard applied only on non-nil return"
  - "mobCounts tracked in separate first pass before seenNpc dedup loop"
  - "DUNGEON_IDX_MAP exposed on ns with single line after existing local declaration"
metrics:
  duration: "2 minutes"
  completed_date: "2026-03-17"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 3
---

# Phase 13 Plan 01: Data Layer and Plumbing Summary

**One-liner:** Data layer and plumbing for Config UI — sound catalog (12 CDM entries), sparse skillConfig schema with MergeSkillConfig merge helper, mob clone count tracking in BuildPack, DUNGEON_IDX_MAP exposed on ns, /tpw config wired, and TOC updated for Sounds.lua and ConfigFrame.lua.

## What Was Built

### Task 1: Data/Sounds.lua + Pipeline.lua

**Data/Sounds.lua** (new file): Sound catalog for the per-skill alert dropdown. 12 entries total — TTS (soundKitID = nil) as the first/default entry, followed by 11 WoW built-in CDM alert sound kit IDs. Provides `ns.AlertSounds` for ConfigFrame.

**Import/Pipeline.lua** — Three changes:

1. `ns.DUNGEON_IDX_MAP = DUNGEON_IDX_MAP` added after the local declaration — exposes dungeon name/key mapping to ConfigFrame.

2. `local function MergeSkillConfig(npcID, ability, mobClass)` added before BuildPack. Reads `ns.db.skillConfig[npcID][spellID]` and either returns nil (disabled, `cfg.enabled == false` strict check), the original ability (no override, copied to avoid mutating AbilityDB), or a merged table with user overrides applied (label, ttsMessage, soundKitID).

3. BuildPack updated: a first pass counts clone instances per npcID into `pack.mobCounts` before the `seenNpc` dedup loop. The ability insertion now calls `MergeSkillConfig` and only inserts the non-nil merged result.

### Task 2: Core.lua + TerriblePackWarnings.toc

**Core.lua** — Two changes:
- `ns.db.skillConfig = ns.db.skillConfig or {}` in ADDON_LOADED handler after `ns.db = TerriblePackWarningsDB`
- New `elseif cmd == "config" then` branch calling `ns.ConfigUI.Toggle()` (guarded with nil check), before `cmd == "help"`
- Help text updated to include "config"

**TerriblePackWarnings.toc**: `Data\Sounds.lua` inserted after `Data\WindrunnerSpire.lua`; `UI\ConfigFrame.lua` added as the last entry.

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| `cfg.enabled == false` strict equality | nil means "never set = use default = enabled"; only stored when user explicitly disables |
| MergeSkillConfig returns nil to drop disabled | Caller guard is `if merged then` — no special casing needed at insertion site |
| mobCounts as separate first pass | Avoids interleaving count logic with dedup logic; count must include all clones before seenNpc discards duplicates |
| Expose DUNGEON_IDX_MAP with single `ns.DUNGEON_IDX_MAP = DUNGEON_IDX_MAP` line | Minimal change; keeps the local declaration intact so internal Pipeline.lua code is unchanged |
| ConfigFrame.lua last in TOC | ConfigFrame must load after PackFrame (which it may reference for layout) and after Sounds.lua |

## Deviations from Plan

None — plan executed exactly as written.

## Integration Points Created

These contracts are now ready for Plans 02 and 03 to consume:

| Contract | Consumer | How |
|----------|----------|-----|
| `ns.AlertSounds` | ConfigFrame (Plan 03) | Sound dropdown option list |
| `ns.DUNGEON_IDX_MAP` | ConfigFrame (Plan 03) | Dungeon tree headers (names and keys) |
| `ns.db.skillConfig` | ConfigFrame (Plan 03) reads/writes; Pipeline.lua BuildPack reads | Per-skill user overrides |
| `pack.mobCounts` | PackFrame (Plan 02) | Portrait count overlay ("x3" label) |
| `MergeSkillConfig` | Called internally in BuildPack | Skills filtered/merged on next import |
| `/tpw config` | User | Opens ConfigFrame via ns.ConfigUI.Toggle() |

## Self-Check: PASSED

| Item | Status |
|------|--------|
| Data/Sounds.lua created | FOUND |
| Import/Pipeline.lua modified | FOUND |
| Core.lua modified | FOUND |
| TerriblePackWarnings.toc modified | FOUND |
| 13-01-SUMMARY.md created | FOUND |
| Commit e276da1 (Task 1) | FOUND |
| Commit ba0383e (Task 2) | FOUND |
