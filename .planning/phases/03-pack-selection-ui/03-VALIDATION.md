---
phase: 03
slug: pack-selection-ui
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-15
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | WoW addon — no automated test framework available |
| **Config file** | none |
| **Quick run command** | `grep -n "function\|CreateFrame\|SetScript" UI/PackFrame.lua` |
| **Full suite command** | `./scripts/install.bat && echo "Reload WoW with /reload"` |
| **Estimated runtime** | ~5 seconds (install) + manual in-game verification |

---

## Sampling Rate

- **After every task commit:** Run grep verify commands to confirm code structure
- **After every plan wave:** Install and verify in-game
- **Before `/gsd:verify-work`:** Full install and in-game UAT
- **Max feedback latency:** 5 seconds (grep checks)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | UI-01, UI-04 | grep | `grep -n "CreateFrame\|ScrollBox\|UISpecialFrames" UI/PackFrame.lua` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | UI-01 | grep | `grep -n "TreeDataProvider\|ToggleCollapsed\|accordion" UI/PackFrame.lua` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 1 | UI-02, UI-03 | grep | `grep -n "SelectPack\|SetSelected\|highlight\|border" UI/PackFrame.lua` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 1 | UI-03 | grep | `grep -n "combatState\|checkmark\|fighting\|RefreshList" UI/PackFrame.lua` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `UI/PackFrame.lua` — main UI module file (created by Wave 1 tasks)

*No test framework to install — WoW addon uses grep-based structural verification and in-game manual testing.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Scrollable pack list with accordion grouping | UI-01 | WoW UI rendering requires in-game client | /tpw to open, verify dungeon headers collapse/expand, packs scroll |
| Click-to-select highlights pack | UI-02 | Mouse interaction in WoW client | Click a pack row, verify border+icon appears |
| Active pack visual indicator persists | UI-03 | Combat state rendering in-game only | Select pack, enter combat, verify fighting indicator on active row |
| /tpw toggles window | UI-04 | Slash command execution in WoW client | Type /tpw, verify window opens; type again, verify closes |
| Escape closes window | UI-04 | UISpecialFrames requires WoW client | With window open, press Escape, verify closes |
| Movable + saved position | UI-03 | SavedVariables + frame dragging | Drag window, /reload, /tpw — verify same position |
| Live-update on auto-advance | UI-03 | Combat end event in-game only | With window open during combat, verify highlight moves on combat end |

*All phase behaviors require in-game manual verification — WoW addon has no headless test environment.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (grep-based structural checks)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (files created in Wave 1)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-03-15
