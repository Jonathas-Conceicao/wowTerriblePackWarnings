---
phase: 13
slug: configuration-ui-and-pack-polish
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-17
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual in-game testing (WoW addon — no automated test framework) |
| **Config file** | N/A |
| **Quick run command** | `./scripts/install.bat && /reload in WoW` |
| **Full suite command** | `./scripts/install.bat && full in-game test cycle` |
| **Estimated runtime** | ~60 seconds (install + reload + visual check) |

---

## Sampling Rate

- **After every task commit:** Install addon and /reload in WoW client
- **After every plan wave:** Full in-game walkthrough of all success criteria
- **Before `/gsd:verify-work`:** All success criteria manually verified in-game
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Verification | Status |
|---------|------|------|-------------|-----------|--------------|--------|
| 13-01-01 | 01 | 1 | CFG-01 | manual | Config window opens, left panel shows dungeon headers | ⬜ pending |
| 13-01-02 | 01 | 1 | CFG-01 | manual | Dungeon headers expand/collapse to show mob rows with portraits | ⬜ pending |
| 13-01-03 | 01 | 1 | CFG-02 | manual | Clicking mob shows ability settings on right panel | ⬜ pending |
| 13-02-01 | 02 | 1 | CFG-03 | manual | Disabling ability checkbox removes icon from display | ⬜ pending |
| 13-02-02 | 02 | 1 | CFG-04 | manual | Custom label appears on spell icon display | ⬜ pending |
| 13-02-03 | 02 | 1 | CFG-05 | manual | Hovering skill row shows WoW spell tooltip | ⬜ pending |
| 13-03-01 | 03 | 1 | ROUTE-04 | manual | Pull rows show "Nx MobName" counts | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements (install.bat + /reload cycle)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Config window layout | CFG-01 | WoW UI rendering, visual layout | Open config, verify left/right panel structure |
| Skill settings panel | CFG-02 | Interactive UI elements | Select mob, verify checkbox/label/sound controls |
| Skill toggle effect | CFG-03 | Runtime display behavior | Disable skill, activate pack, verify icon absent |
| Custom label display | CFG-04 | Runtime icon label text | Set label in config, verify on spell icon display |
| Spell tooltip | CFG-05 | GameTooltip rendering | Hover skill row, verify WoW tooltip appears |
| Mob count display | ROUTE-04 | Visual pull row content | Import route, verify "Nx" counts on portraits |

*All phase behaviors require manual in-game verification — WoW addons have no automated UI test framework.*

---

## Validation Sign-Off

- [x] All tasks have manual verification procedures
- [x] Sampling continuity: every task verifiable via install + /reload
- [x] Wave 0 covered (existing install.bat infrastructure)
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
