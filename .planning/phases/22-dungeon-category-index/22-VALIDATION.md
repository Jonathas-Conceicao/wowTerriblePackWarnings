---
phase: 22
slug: dungeon-category-index
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-24
updated: 2026-03-24
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | grep/bash verification (no test framework — WoW addon, Lua only) |
| **Config file** | none |
| **Quick run command** | `grep -rn "mobCategory.*unknown" Data/ --include="*.lua" \| grep -v Skyreach` |
| **Full suite command** | `grep -rn "isBoss" Data/ UI/ && grep -rn "npcIdIsBoss" UI/` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run quick command
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | CAT-01 | grep | `grep -c "mobCategory" Data/WindrunnerSpire.lua` (32) | N/A | ✅ green |
| 22-01-02 | 01 | 1 | CAT-02 | grep | Remaining unknowns match MobCategories.md | N/A | ✅ green |
| 22-01-03 | 01 | 1 | CAT-03 | grep | 10 planned + 6 auto-fix stubs confirmed | N/A | ✅ green |
| 22-02-01 | 02 | 2 | CAT-04 | grep | `grep -rn "isBoss" Data/ UI/` (empty, exit 1) | N/A | ✅ green |
| 22-02-02 | 02 | 2 | CAT-05 | grep | `grep -n "npcIdIsBoss" UI/PackFrame.lua` (empty) + `mobCategory.*boss` at line 501 | N/A | ✅ green |
| 22-02-03 | 02 | 2 | CAT-06 | grep | `grep "252557" Data/DungeonEnemies.lua Data/PitOfSaron.lua` (2 hits) | N/A | ✅ green |

*Status: ✅ all green*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| Boss pull rows still highlight dark red | CAT-05 | Requires in-game PackFrame rendering | Import route, verify boss pulls show red rows | Pending |
| Mindless Laborer portrait renders | CAT-06 | Requires in-game UI | Import Pit of Saron route, check mob portrait | Pending |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 1s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-03-24

---

## Validation Audit 2026-03-24

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
