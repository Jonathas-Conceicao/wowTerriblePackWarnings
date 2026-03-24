---
phase: 21
slug: config-display
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-23
updated: 2026-03-24
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | grep/bash verification (no test framework — WoW addon, Lua only) |
| **Config file** | none |
| **Quick run command** | `grep -n "mobCategory" UI/ConfigFrame.lua` |
| **Full suite command** | `grep -n "mobCategory\|CATEGORY_COLORS\|gsub.*%-" UI/ConfigFrame.lua` |
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
| 21-01-01 | 01 | 1 | UI-01 | grep | `grep "CATEGORY_COLORS\|colorHex\|categoryTag" UI/ConfigFrame.lua` (returns 4+ hits) | N/A | ✅ green |
| 21-01-02 | 01 | 1 | UI-02 | grep | `grep "entry\.mobClass\|CLASS_ICON\|npcIdToClass" UI/ConfigFrame.lua` (empty, exit 1) | N/A | ✅ green |
| 21-01-03 | 01 | 1 | UI-03 | grep | `grep "categoryMatch\|gsub.*%-\|mobCategory.*find" UI/ConfigFrame.lua` (returns 4 hits) | N/A | ✅ green |

*Status: ✅ all green*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| Category tag renders with correct color in-game | UI-01 | Requires WoW client rendering | Open config, select mob, verify colored [Category] tag | Pending |
| Search "boss" returns boss mobs | UI-03 | Requires in-game search box interaction | Type "boss" in search, verify filtered results | Pending |
| Search "mini-boss" matches miniboss | UI-03 | Hyphen normalization | Type "mini-boss", verify miniboss mobs appear | Pending |

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
