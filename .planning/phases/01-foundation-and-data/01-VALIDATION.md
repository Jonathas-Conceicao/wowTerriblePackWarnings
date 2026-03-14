---
phase: 1
slug: foundation-and-data
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-13
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual in-game validation (WoW addon Lua — no offline test runner) |
| **Config file** | none — WoW addons are tested in the game client |
| **Quick run command** | `/reload` in WoW client |
| **Full suite command** | `/reload` + console verification commands |
| **Estimated runtime** | ~30 seconds (manual) |

---

## Sampling Rate

- **After every task commit:** Run `scripts/install.bat` + `/reload` in WoW
- **After every plan wave:** Full console verification suite
- **Before `/gsd:verify-work`:** All manual verifications green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | FOUND-01 | manual | `/reload` — check addon list, no Lua errors | N/A | ⬜ pending |
| TBD | TBD | TBD | DATA-01 | manual | `/run print(TPW.PackDatabase)` — non-nil | N/A | ⬜ pending |
| TBD | TBD | TBD | DATA-02 | manual | `/run` — check first_cast + cooldown fields | N/A | ⬜ pending |
| TBD | TBD | TBD | FOUND-02 | manual | Run `scripts/install.bat`, push git tag | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — WoW addon testing is inherently manual/in-game.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Addon loads in WoW | FOUND-01 | WoW addon Lua only runs in-game | Enable addon, `/reload`, check addon list |
| PackDatabase queryable | DATA-01 | Lua namespace only accessible in-game | `/run print(TPW.PackDatabase)` |
| Ability data has timing fields | DATA-02 | Data validation requires in-game console | `/run` to inspect first_cast/cooldown |
| No taint errors | FOUND-01 | Taint detection is WoW-runtime only | `/reload`, check for error popups |
| install.bat works | FOUND-02 | Requires local WoW installation | Run script, verify files copied |
| GitHub Actions release | FOUND-02 | Requires git push + GitHub | Push tag, check Actions tab |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
