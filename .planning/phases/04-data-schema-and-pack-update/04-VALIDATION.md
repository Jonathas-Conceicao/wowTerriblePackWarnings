---
phase: 04
slug: data-schema-and-pack-update
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-15
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | WoW addon — no automated test framework |
| **Config file** | none |
| **Quick run command** | `grep -n "mobClass\|cooldown\|spellID" Data/WindrunnerSpire.lua` |
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
| 04-01-01 | 01 | 1 | DATA-06, DATA-07, DATA-08, DATA-09 | grep | `grep -n "mobClass\|cooldown.*nil\|PALADIN\|WARRIOR" Data/WindrunnerSpire.lua` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Addon loads with new schema | DATA-06 | WoW client required | /reload, check no Lua errors |
| Scheduler handles new schema | DATA-08 | Runtime iteration change | /tpw select, /tpw start |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (grep-based)
- [x] Sampling continuity satisfied
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-03-15
