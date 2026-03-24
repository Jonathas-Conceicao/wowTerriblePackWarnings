---
phase: 20
slug: runtime-detection-and-scanner-matching
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | grep/bash verification (no test framework — WoW addon, Lua only) |
| **Config file** | none |
| **Quick run command** | `grep -rn "mobClass" Engine/ Import/` |
| **Full suite command** | `grep -rn "ability.mobClass" Engine/ Import/ && grep -rn "classBarIds\|classHasUntimed\|castingByClass" Engine/` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run quick command (must return empty for old patterns)
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 20-xx-01 | TBD | TBD | DETC-01 | grep | `grep "UnitClassification" Engine/NameplateScanner.lua` | N/A | pending |
| 20-xx-02 | TBD | TBD | DETC-02 | grep | `grep "UNIT_CLASSIFICATION_CHANGED" Core.lua` | N/A | pending |
| 20-xx-03 | TBD | TBD | DETC-03 | grep | `grep "pcall.*UnitIsLieutenant" Engine/NameplateScanner.lua` | N/A | pending |
| 20-xx-04 | TBD | TBD | DETC-04 | grep | `grep "DeriveCategory" Engine/NameplateScanner.lua` | N/A | pending |
| 20-xx-05 | TBD | TBD | DETC-05 | grep | `grep "plateCache.*category" Engine/NameplateScanner.lua` | N/A | pending |
| 20-xx-06 | TBD | TBD | SCAN-01 | grep | `grep "mobCategory" Import/Pipeline.lua` | N/A | pending |
| 20-xx-07 | TBD | TBD | SCAN-02 | grep | `grep "unknown" Engine/NameplateScanner.lua` | N/A | pending |
| 20-xx-08 | TBD | TBD | SCAN-03 | grep | `grep "ability.mobCategory" Engine/NameplateScanner.lua` | N/A | pending |

*Status: pending*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework needed — validation is grep-based (presence of new patterns, absence of old patterns).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Skyreach category filtering works in-game | SCAN-03 | Requires live dungeon run | Import Skyreach route, pull mobs, verify only matching-category abilities display |
| Non-Skyreach wildcard works in-game | SCAN-02 | Requires live dungeon run | Import non-Skyreach route, pull mobs, verify all abilities still display |
| UnitIsLieutenant returns meaningful values | DETC-03 | Requires live dungeon content | Check debug log for lieutenant detection on known miniboss mobs |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 1s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
