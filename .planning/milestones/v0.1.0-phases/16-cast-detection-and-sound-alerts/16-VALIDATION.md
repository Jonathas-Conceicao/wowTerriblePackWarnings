---
phase: 16
slug: cast-detection-and-sound-alerts
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-20
---

# Phase 16 — Validation Strategy

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
| 16-01-01 | 01 | 1 | ALERT-01 | manual | Orange glow textures created, PlaySound added to SetUrgent | ⬜ pending |
| 16-01-02 | 01 | 1 | ALERT-02, ALERT-03 | manual | soundKitID wired through ShowIcon/ShowStaticIcon, mutual exclusivity | ⬜ pending |
| 16-02-01 | 02 | 2 | HILITE-01 | manual | UnitCastingInfo polling detects casts, orange glow fires on state transition | ⬜ pending |
| 16-02-02 | 02 | 2 | HILITE-02 | manual | Timed skill pre-warning at 5s with sound/TTS, in-game checkpoint | ⬜ pending |

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements (install.bat + /reload cycle)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Orange glow on cast detection | HILITE-01 | WoW UI rendering + nameplate API | Pull mobs, verify orange glow appears when same-class mob casts |
| Timed pre-warning with alert | HILITE-02 | Runtime timer + audio playback | Import route, pull timed mob, verify red glow + sound/TTS at 5s |
| Sound dropdown plays alert | ALERT-01 | Audio playback in-game | Set sound in config, trigger ability, verify sound plays |
| TTS text plays correctly | ALERT-02 | TTS engine in-game | Set TTS text, trigger ability, verify spoken text |
| Sound/TTS mutually exclusive | ALERT-03 | Config UI + runtime behavior | Set sound → verify TTS disabled; set TTS → verify sound disabled |

---

## Validation Sign-Off

- [x] All tasks have manual verification procedures
- [x] Sampling continuity: every task verifiable via install + /reload
- [x] Wave 0 covered (existing install.bat infrastructure)
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
