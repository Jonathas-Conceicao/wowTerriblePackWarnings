---
phase: 09
slug: import-pipeline
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-16
---

# Phase 09 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | WoW addon — no automated test framework |
| **Quick run command** | `grep -n "ImportRoute\|PackDatabase\|dungeonEnemies\|DUNGEON_IDX" Import/Pipeline.lua` |
| **Full suite command** | `./scripts/install.bat` |
| **Estimated runtime** | ~5 seconds |

## Per-Task Verification Map

| Task ID | Plan | Wave | Test Type | Automated Command | Status |
|---------|------|------|-----------|-------------------|--------|
| 09-01-01 | 01 | 1 | grep | `grep -c "id =" Data/DungeonEnemies.lua` | ⬜ pending |
| 09-01-02 | 01 | 1 | grep | `grep -n "ImportRoute\|PackDatabase\|AbilityDB" Import/Pipeline.lua` | ⬜ pending |
| 09-02-01 | 02 | 2 | grep | `grep -n "importedRoute\|RestoreFromSaved\|import" Core.lua Import/Pipeline.lua` | ⬜ pending |

## Manual-Only Verifications

| Behavior | Why Manual | Test Instructions |
|----------|------------|-------------------|
| /tpw import decodes and populates packs | WoW client | Paste MDT string, verify packs appear |
| Imported route survives /reload | SavedVariables | Import, /reload, verify packs still there |
| Combat works with imported packs | Runtime | Select pack, enter combat, verify icons |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify
- [x] Sampling continuity satisfied
- [x] `nyquist_compliant: true`

**Approval:** approved 2026-03-16
