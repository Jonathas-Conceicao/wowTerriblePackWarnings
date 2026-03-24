---
phase: 19
slug: data-layer
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-23
updated: 2026-03-23
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | grep/bash verification (no test framework — WoW addon, Lua only) |
| **Config file** | none |
| **Quick run command** | `grep -rn "mobClass" Data/` |
| **Full suite command** | `grep -rn "mobClass" Data/ && grep -rn "mobCategory" Data/ --include="*.lua" \| head -5` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run `grep -rn "mobClass" Data/` (must return empty)
- **After every plan wave:** Run full grep suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | DATA-01 | grep | `grep -c "mobCategory" Data/Skyreach.lua` (returns 23) | N/A | ✅ green |
| 19-01-02 | 01 | 1 | DATA-02 | grep | `grep "mobCategory" Data/Skyreach.lua \| grep -v "unknown"` (returns 19 non-unknown) | N/A | ✅ green |
| 19-01-03 | 01 | 1 | DATA-03 | grep | `grep -rn "mobClass" Data/ --include="*.lua"` (empty, exit 1) | N/A | ✅ green |
| 19-01-04 | 01 | 1 | DATA-04 | grep | `grep -rn "mobClass" Data/ --include="*.lua"` (empty, exit 1) | N/A | ✅ green |

*Status: ✅ all green*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework needed — validation is entirely grep-based (presence/absence of field names in Lua data files).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| Skyreach categories match reference table | DATA-02 | 22 specific values need human spot-check | Compare grep output against CONTEXT.md category table | ✅ verified |
| Outcast Servant stub entry exists | DATA-02 | New entry, not just field edit | `grep "75976" Data/Skyreach.lua` must show mobCategory = "warrior" | ✅ verified |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 1s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-03-23

---

## Validation Audit 2026-03-23

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
