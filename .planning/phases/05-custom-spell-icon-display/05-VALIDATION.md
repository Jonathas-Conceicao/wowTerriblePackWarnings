---
phase: 05
slug: custom-spell-icon-display
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-15
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | WoW addon — no automated test framework |
| **Config file** | none |
| **Quick run command** | `grep -n "CreateFrame\|SetCooldown\|SpeakText\|SetTexture" Display/SpellIcons.lua` |
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
| 05-01-01 | 01 | 1 | DISP-01, DISP-02, DISP-03, DISP-08 | grep | `grep -n "CreateFrame\|SetCooldown\|SetTexture\|C_Spell" Display/SpellIcons.lua` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 1 | DISP-04, DISP-05 | grep | `grep -n "PixelGlow\|SpeakText\|ttsMessage" Display/SpellIcons.lua` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 2 | DISP-06 | grep | `grep -rn "BossWarnings" Engine/ Display/ Core.lua TerriblePackWarnings.toc` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Display/SpellIcons.lua` — created by Wave 1 tasks

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Horizontal icon row at top-left | DISP-01 | Visual rendering in WoW | /tpw start, verify icons at top-left |
| Cooldown sweep animation | DISP-02 | Animation rendering | Start timer, verify clock sweep and countdown |
| Static icon for untimed | DISP-03 | Visual rendering | Verify Spirit Bolt shows as static icon |
| Red glow at 5 seconds | DISP-04 | Visual effect | Wait for 5s remaining, verify red glow |
| TTS announces at 5 seconds | DISP-05 | Audio output | Wait for 5s remaining, verify voice |
| No DBM/ET/RaidNotice code | DISP-06 | Code removal | grep for BossWarnings references |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (grep-based)
- [x] Sampling continuity satisfied
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-03-15
