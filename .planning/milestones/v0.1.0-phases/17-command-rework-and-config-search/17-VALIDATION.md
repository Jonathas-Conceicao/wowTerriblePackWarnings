---
phase: 17
slug: command-rework-and-config-search
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-21
---

# Phase 17 — Validation Strategy

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
| 17-01-01 | 01 | 1 | CMD-01, CMD-02 | manual | /tpw opens config, /tpw route opens route, case-insensitive, grouped help | ⬜ pending |
| 17-01-02 | 01 | 1 | UIPOL-02 | manual | Config button removed, Clear/Import spread across footer | ⬜ pending |
| 17-02-01 | 02 | 1 | CMD-03, SEARCH-01, SEARCH-02, UIPOL-01 | manual | Route button, search box, Reset All repositioned, search filtering works | ⬜ pending |
| 17-02-02 | 02 | 1 | CMD-03 | manual | Right panel header has mob portrait + divider | ⬜ pending |

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements (install.bat + /reload cycle)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| /tpw opens config | CMD-01 | WoW slash command routing | Type /tpw, verify config window opens |
| /tpw route opens route | CMD-01 | WoW slash command routing | Type /tpw route, verify route window opens |
| Case-insensitive commands | CMD-01 | Slash command parsing | Type /tpw ROUTE, /tpw Route, verify both work |
| Grouped help output | CMD-02 | Chat output formatting | Type /tpw help, verify grouped categories |
| Route button in config | CMD-03 | UI button presence | Open config, verify Route button in top bar |
| Config button removed from route | CMD-03 | UI button absence | Open route, verify no Config button |
| Search filters tree | SEARCH-01 | Interactive search | Type in search box, verify tree filters |
| Search filters skills | SEARCH-02 | Interactive search | Select mob during search, verify filtered skills |
| Search reset on close | SEARCH-02 | Window close behavior | Close config, reopen, verify full tree |
| Reset All repositioned | UIPOL-01 | UI layout | Verify Reset All in top bar with confirmation |
| Footer buttons spread | UIPOL-02 | UI layout | Verify Clear left, Import right in route footer |

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
