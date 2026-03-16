---
phase: 08
slug: ability-database-and-decode-library
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-16
---

# Phase 08 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | WoW addon — no automated test framework |
| **Quick run command** | `grep -n "AbilityDB\|MDTDecode\|LibDeflate\|AceSerializer" Data/WindrunnerSpire.lua Core.lua` |
| **Full suite command** | `./scripts/install.bat` |
| **Estimated runtime** | ~5 seconds |

## Per-Task Verification Map

| Task ID | Plan | Wave | Test Type | Automated Command | Status |
|---------|------|------|-----------|-------------------|--------|
| 08-01-01 | 01 | 1 | grep | `grep -c "AbilityDB" Data/WindrunnerSpire.lua` | ⬜ pending |
| 08-01-02 | 01 | 1 | grep | `grep -n "LibDeflate\|AceSerializer\|LibStub" TerriblePackWarnings.toc` | ⬜ pending |
| 08-02-01 | 02 | 2 | grep | `grep -n "MDTDecode\|DecodeForPrint\|Deserialize" Import/Decode.lua` | ⬜ pending |

## Manual-Only Verifications

| Behavior | Why Manual | Test Instructions |
|----------|------------|-------------------|
| Addon loads with libs | WoW client required | /reload, verify no Lua errors |
| /tpw decode <string> works | MDT string decoding | Paste MDT export string, verify decoded output |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify
- [x] Sampling continuity satisfied
- [x] `nyquist_compliant: true`

**Approval:** approved 2026-03-16
