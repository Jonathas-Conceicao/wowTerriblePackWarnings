---
phase: 2
slug: warning-engine-and-combat-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual in-game console testing (WoW Lua has no automated test runner) |
| **Config file** | None — WoW addon environment |
| **Quick run command** | `/run local ns = select(2, ...); print(ns.Engine and "OK" or "MISSING")` via `/reload` + console |
| **Full suite command** | Manual checklist in WoW dungeon instance |
| **Estimated runtime** | ~60 seconds per quick check; ~10 minutes for full dungeon validation |

---

## Sampling Rate

- **After every task commit:** `/reload` in WoW, verify no Lua errors, check module loads
- **After every plan wave:** Run `/run TPW_Test()` smoke test (prints engine state)
- **Before `/gsd:verify-work`:** Full manual checklist in Windrunner Spire
- **Max feedback latency:** ~30 seconds (reload + console command)

---

## Per-Task Verification Map

| Req ID | Requirement | Test Type | Automated Command | File Exists | Status |
|--------|-------------|-----------|-------------------|-------------|--------|
| WARN-01 | Timer scheduler starts on pull trigger | Manual smoke | `/run ns.Engine:Start()` | ❌ W0 | ⬜ pending |
| WARN-02 | Warnings display in Encounter Timeline/DBM/RaidNotice | Manual visual | Pull trash, observe display | ❌ W0 | ⬜ pending |
| WARN-03 | Timers cancel on combat end/zone change | Manual smoke | End combat, verify no ghost warnings | ❌ W0 | ⬜ pending |
| CMBT-01 | Manual trigger starts timers | Manual smoke | `/run ns.Engine:Start()` in console | ❌ W0 | ⬜ pending |
| CMBT-02 | PLAYER_REGEN_DISABLED auto-triggers | Manual integration | Select pack, enter combat | ❌ W0 | ⬜ pending |
| CMBT-03 | Zone change resets state | Manual integration | Zone out/in, verify reset | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Engine/Scheduler.lua` — timer scheduling module (WARN-01, WARN-03, CMBT-01)
- [ ] `Engine/CombatWatcher.lua` — combat event wiring (CMBT-02, CMBT-03)
- [ ] `Display/BossWarnings.lua` — display adapter layer (WARN-02)
- [ ] `Data/WindrunnerSpire.lua` restructured from map to ordered array

*All validation is manual in-game — no automated test framework exists for WoW Lua addons.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Timer bars appear in Encounter Timeline | WARN-02 | Requires live WoW client with UI | Select pack, pull trash, observe timeline bars |
| DBM fallback displays bars | WARN-02 | Requires DBM installed in WoW | Disable Encounter Timeline, pull trash, observe DBM bars |
| No ghost warnings after combat end | WARN-03 | Timing-sensitive, visual verification | Pull trash, let combat end, wait 60s for stale warnings |
| Auto-advance to next pack | CMBT-02 | Requires sequential combat encounters | Pull pack 1, end combat, pull again, verify pack 2 timers |
| Zone change full reset | CMBT-03 | Requires zoning in/out of instance | Mid-sequence, zone out, zone back in, verify at pack 1 |

---

## Validation Sign-Off

- [ ] All tasks have manual verify instructions
- [ ] Wave 0 covers all module creation
- [ ] Quick smoke test available via `/reload` + console
- [ ] Full validation checklist covers all 4 success criteria
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
