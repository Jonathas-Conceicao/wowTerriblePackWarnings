---
phase: 10
slug: route-ui-overhaul
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-16
---

# Phase 10 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | WoW addon — no automated test framework |
| **Quick run command** | `grep -n "SetPortraitTextureFromCreatureDisplayID\|StaticPopup\|EditBox\|imported" UI/PackFrame.lua` |
| **Full suite command** | `./scripts/install.bat` |
| **Estimated runtime** | ~5 seconds |

## Per-Task Verification Map

| Task ID | Plan | Wave | Test Type | Automated Command | Status |
|---------|------|------|-----------|-------------------|--------|
| 10-01-01 | 01 | 1 | grep | `grep -n "SetPortraitTextureFromCreatureDisplayID\|SetMask\|npcIDs" UI/PackFrame.lua` | ⬜ pending |
| 10-01-02 | 01 | 1 | grep | `grep -n "StaticPopup\|EditBox\|Import\|Clear" UI/PackFrame.lua` | ⬜ pending |

## Manual-Only Verifications

| Behavior | Why Manual | Test Instructions |
|----------|------------|-------------------|
| Pull rows with round NPC portraits | Visual | Import route, verify numbered pulls with mob icons |
| Import popup editbox | Interaction | Click Import, verify popup with paste area |
| Clear confirmation dialog | Interaction | Click Clear, verify confirmation prompt |
| Header shows dungeon name + count | Visual | Import route, verify header text |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify
- [x] Sampling continuity satisfied
- [x] `nyquist_compliant: true`

**Approval:** approved 2026-03-16
