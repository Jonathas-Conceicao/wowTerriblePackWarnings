---
phase: 07
slug: complete-dungeon-route
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-15
---

# Phase 07 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | WoW addon — no automated test framework |
| **Quick run command** | `grep -c "packs\[#packs" Data/WindrunnerSpire.lua` |
| **Full suite command** | `./scripts/install.bat` |
| **Estimated runtime** | ~5 seconds |

## Per-Task Verification Map

| Task ID | Plan | Wave | Test Type | Automated Command | Status |
|---------|------|------|-----------|-------------------|--------|
| 07-01-01 | 01 | 1 | grep | `grep -c "packs\[#packs" Data/WindrunnerSpire.lua` | ⬜ pending |
| 07-01-02 | 01 | 1 | grep | `grep -n "label\|SetSpellByID\|GameTooltip" Display/IconDisplay.lua` | ⬜ pending |

## Manual-Only Verifications

| Behavior | Why Manual | Test Instructions |
|----------|------------|-------------------|
| 17 packs in accordion UI | Visual | /tpw, verify all 17 packs listed |
| Icon label text visible | Visual | Enter combat, verify "DR"/"Bolt" labels on icons |
| Tooltip on mouseover | Interaction | Hover icon, verify spell tooltip appears |
| Full dungeon route progression | Combat | Run through packs, verify auto-advance through 17 |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify
- [x] Sampling continuity satisfied
- [x] `nyquist_compliant: true`

**Approval:** approved 2026-03-15
