---
phase: 06
slug: nameplate-detection-and-mob-lifecycle
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-15
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | WoW addon — no automated test framework |
| **Config file** | none |
| **Quick run command** | `grep -n "GetNamePlates\|UnitClass\|UnitAffectingCombat\|NewTicker" Engine/NameplateScanner.lua` |
| **Full suite command** | `./scripts/install.bat && echo "Reload WoW"` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run grep verify commands
- **After every plan wave:** Install and verify in-game
- **Before `/gsd:verify-work`:** Full install and in-game UAT
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | DETC-01, DETC-02, DETC-03, DETC-04 | grep | `grep -n "GetNamePlates\|UnitClass\|NewTicker\|StartAbility" Engine/NameplateScanner.lua` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | DISP-07 | grep | `grep -n "prevCounts\|CancelIcon\|count.*decrease" Engine/NameplateScanner.lua` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `Engine/NameplateScanner.lua` — created by Wave 1 tasks

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Scan detects in-combat mobs | DETC-01 | Nameplate interaction in WoW | Pull mobs, verify icons spawn per mob class |
| Multiple mobs = multiple timers | DETC-03 | Combat with multiple mobs | Pull pack with 2 paladins, verify 2 shield icons |
| Mid-combat aggro detection | DETC-04 | Dynamic combat | Aggro additional mob mid-fight, verify new icon |
| Icons clear when mobs die | DISP-07 | Combat mob death | Kill one mob, verify icon removed |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (grep-based)
- [x] Sampling continuity satisfied
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-03-15
