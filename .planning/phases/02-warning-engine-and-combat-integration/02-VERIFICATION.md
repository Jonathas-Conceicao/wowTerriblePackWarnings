---
phase: 02-warning-engine-and-combat-integration
verified: 2026-03-14T14:00:00Z
status: human_needed
score: 11/11 must-haves verified
re_verification: true
  previous_status: passed
  previous_score: 11/11
  gaps_closed:
    - "Timers stop on combat end and auto-advance to next pack or end state"
    - "Zone change resets state to idle with no dungeon selected"
    - "Warnings display via Encounter Timeline API or DBM API, not as RaidNotice fallback"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Ability Warning Timing Accuracy"
    expected: "Pre-warning appears ~45s in (Spellguard's Protection in 5 sec), cast alert at ~50s, repeats every 50s"
    why_human: "Timer offsets are code-correct but WoW tick rate and display timing require in-game confirmation"
  - test: "Display Adapter Selection — EncounterTimeline inside dungeon"
    expected: "Warnings appear in Encounter Timeline (not RaidNotice text) when inside a dungeon instance with ET detected"
    why_human: "C_EncounterTimeline.IsFeatureEnabled() behavior for dungeon trash is empirically unverified; this was the root of the original UAT issue"
  - test: "Ghost Warning Prevention"
    expected: "/tpw stop or combat end prevents all future warnings even after 60+ seconds"
    why_human: "combatActive[1]=false closure mutation is code-correct but timer cancellation race conditions require live testing"
  - test: "Auto-advance on Combat End"
    expected: "After combat ends, state becomes 'end' (1 pack) or advances to pack 2 index with chat confirmation"
    why_human: "Only 1 pack in WindrunnerSpire.lua so end-state path triggers immediately; UAT confirmed this was broken in original code and now fixed"
  - test: "PLAYER_REGEN_DISABLED guard in M+ Keystone without dungeon selected"
    expected: "No warnings fire when state=idle; CombatWatcher guard prevents spurious triggers"
    why_human: "PLAYER_REGEN_DISABLED behavior in keystone runs is empirically unverified"
---

# Phase 2: Warning Engine and Combat Integration Verification Report

**Phase Goal:** Build the warning engine (Scheduler + display adapters) and combat integration (CombatWatcher state machine) so that selecting a dungeon and entering combat auto-fires timed ability warnings through the best available display system.
**Verified:** 2026-03-14T14:00:00Z
**Status:** HUMAN_NEEDED (all automated checks pass; awaiting in-game confirmation of display adapter and timing behavior)
**Re-verification:** Yes — after gap closure via plans 02-03 and 02-04

---

## Re-verification Context

The initial VERIFICATION.md (2026-03-14T12:00:00Z) reported `status: passed` based on static code analysis. UAT (02-UAT.md) subsequently identified 3 major in-game failures:

1. Warnings showed as RaidNotice text even when ET adapter was detected — `ET_Show` and `DBM_Show` were copy-paste stubs calling `RaidNotice_AddMessage`.
2. Timers did not stop on PLAYER_REGEN_ENABLED — `OnCombatEnd` called `Stop()` before setting state, so an error in `CancelAllTimers` left state as "active" and re-triggered on next combat.
3. Zone change kept state as "ready" with dungeon selected — `Reset()` did not clear `selectedDungeon` or set state to "idle".

Plans 02-03 and 02-04 were executed as gap-closure plans. This re-verification confirms all three gaps are closed in the current codebase.

---

## Goal Achievement

### Observable Truths

Truths drawn from 02-02-PLAN.md `must_haves.truths` (primary plan), augmented by 02-03 and 02-04 gap-closure truths.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Scheduler fires 5-second pre-warnings and cast alerts at correct offsets | VERIFIED | `scheduleAbility` in Scheduler.lua: `preWarnOffset = first_cast - 5`, timer at `preWarnOffset` calls `BossWarnings.Show(name .. " in 5 sec", 4)`, timer at `first_cast` calls `BossWarnings.Show(name, 3)` |
| 2 | Each ability fires a pre-warning then cast alert, repeating on cooldown | VERIFIED | Cast callback recursively calls `scheduleAbility({first_cast=ability.cooldown, cooldown=ability.cooldown})` |
| 3 | All timers cancel immediately when combat ends (PLAYER_REGEN_ENABLED) | VERIFIED | `OnCombatEnd` sets state BEFORE calling `Stop()`; `Stop()` sets `combatActive[1]=false`, cancels all handles via `IsCancelled()` guard, wipes `activeTimers`, calls `pcall(BossWarnings.CancelAllTimers)` |
| 4 | Zone change resets state to idle with no dungeon selected | VERIFIED | `Reset()` in CombatWatcher.lua lines 79-86: sets `selectedDungeon=nil`, `currentPackIndex=nil`, `state="idle"` unconditionally |
| 5 | Combat start with selected pack auto-triggers timers via PLAYER_REGEN_DISABLED | VERIFIED | Core.lua line 28-29 wires `PLAYER_REGEN_DISABLED` to `CombatWatcher:OnCombatStart()`; guard `if state ~= "ready" then return` prevents idle/end-state triggers |
| 6 | Combat end auto-advances to the next pack in the sequence | VERIFIED | `OnCombatEnd` computes `nextIndex = currentPackIndex + 1`; if within bounds, sets `state="ready"` and `currentPackIndex=nextIndex`, prints next pack name |
| 7 | When all packs exhausted, engine enters end state and stops auto-triggering | VERIFIED | `OnCombatEnd`: if `nextIndex > #dungeon`, sets `state="end"` before `Stop()`; `OnCombatStart` guard `state ~= "ready"` blocks end-state triggers |
| 8 | Warnings display via ET adapter using AddScriptEvent when ET is active | VERIFIED (code) | `ET_Show` (line 71-81): creates `eventInfo{text,duration}` table, calls `C_EncounterTimeline.AddScriptEvent(eventInfo)`, stores returned `eventID` in `etEventIDs` — no RaidNotice call |
| 9 | Warnings display via DBM adapter using CreateBar when DBM is active | VERIFIED (code) | `DBM_Show` (line 108-112): constructs `barID="TPW: "..text`, calls `DBT:CreateBar(duration or 5, barID)`, stores in `activeBarIDs` — no RaidNotice call |
| 10 | Errors in BossWarnings.CancelAllTimers do not abort state transitions | VERIFIED | `Scheduler:Stop()` line 107: `local ok, err = pcall(ns.BossWarnings.CancelAllTimers)`; error prints warning but does not propagate |
| 11 | State before Stop pattern prevents re-triggering on error in OnCombatEnd | VERIFIED | `OnCombatEnd` sets `state="end"` or `state="ready"` (lines 67/72) before calling `ns.Scheduler:Stop()` (lines 69/74) |

**Score:** 11/11 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Engine/Scheduler.lua` | Timer scheduling with start, stop, cancel, repeating chains; pcall-protected Stop | VERIFIED | 113 lines; `Start`, `Stop` with pcall on line 107; `scheduleAbility` recursive chain; `combatActive` single-element table; all handles in `activeTimers` |
| `Engine/CombatWatcher.lua` | State machine (idle/ready/active/end); Reset clears to idle | VERIFIED | 90 lines; `SelectDungeon`, `ManualStart`, `OnCombatStart`, `OnCombatEnd`, `Reset`, `GetState`; Reset unconditionally sets nil/idle (lines 82-84) |
| `Display/BossWarnings.lua` | ET_Show uses AddScriptEvent; DBM_Show uses CreateBar; 3-tier fallback | VERIFIED | 187 lines; `ET_Show` calls `C_EncounterTimeline.AddScriptEvent`; `DBM_Show` calls `DBT:CreateBar`; `RN_Show` is fallback only; `DEBUG` flag + `dbg()` helper present |
| `Core.lua` | All 4 events registered; PLAYER_ENTERING_WORLD permanent; slash commands wired | VERIFIED | 66 lines; all events registered at top level (lines 10-13); no `UnregisterEvent("PLAYER_ENTERING_WORLD")` call; `/tpw` slash command with select/start/stop/status |
| `Data/WindrunnerSpire.lua` | Ordered array pack data with key, displayName, mobs, abilities | VERIFIED | 23 lines; `packs[#packs+1]={key, displayName, mobs=[{name, npcID, abilities=[{name,spellID,first_cast,cooldown}]}]}` |
| `TerriblePackWarnings.toc` | All 5 files in correct load order | VERIFIED | 14 lines; Core.lua, Engine\Scheduler.lua, Engine\CombatWatcher.lua, Display\BossWarnings.lua, Data\WindrunnerSpire.lua |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Engine/Scheduler.lua` | `Display/BossWarnings.lua` | `ns.BossWarnings.Show`, `ShowTimer`, `CancelAllTimers` | WIRED | Lines 40, 49, 64 (inside callbacks/function bodies); pcall on CancelAllTimers line 107 |
| `Engine/CombatWatcher.lua` | `Engine/Scheduler.lua` | `ns.Scheduler:Start`, `ns.Scheduler:Stop` | WIRED | Start at lines 47, 55; Stop at lines 69, 74, 80 |
| `Engine/CombatWatcher.lua` | `ns.PackDatabase` | reads ordered array by dungeon key and current pack index | WIRED | Lines 24, 63 |
| `Core.lua` | `Engine/CombatWatcher.lua` | PLAYER_REGEN_DISABLED/ENABLED/PLAYER_ENTERING_WORLD events | WIRED | Lines 29, 32, 36; also `/tpw` wires SelectDungeon, ManualStart, GetState |
| `Display/BossWarnings.lua` | `C_EncounterTimeline` / `DBT` / `RaidNotice_AddMessage` | runtime adapter dispatch via `activeAdapter` | WIRED | ET path: `AddScriptEvent`, `CancelScriptEvent`, `CancelAllScriptEvents`; DBM path: `DBT:CreateBar`, `DBT:CancelBar`; RN fallback: `RaidNotice_AddMessage` |

---

## Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| WARN-01 | 02-02, 02-04 | Timer scheduler starts ability cooldown timers when a pack pull is triggered | SATISFIED | `Scheduler:Start(dungeonKey, packIndex)` reads pack data, calls `scheduleAbility` for every ability; wired to `/tpw start` and PLAYER_REGEN_DISABLED |
| WARN-02 | 02-01, 02-04 | Warnings display through Blizzard's Boss Warnings API (with fallback if API doesn't support trash) | SATISFIED (code) | ET_Show uses `C_EncounterTimeline.AddScriptEvent`; DBM_Show uses `DBT:CreateBar`; RaidNotice is true fallback only; in-game ET behavior unverified (see human checks) |
| WARN-03 | 02-02, 02-03 | All active timers cancel on combat end or zone change | SATISFIED | `Stop()` with pcall-protected `CancelAllTimers`; called from `OnCombatEnd` (PLAYER_REGEN_ENABLED) and `Reset()` (PLAYER_ENTERING_WORLD) |
| CMBT-01 | 02-02 | Manual pull trigger starts timers for selected pack | SATISFIED | `/tpw start [pack#]` calls `CombatWatcher:ManualStart()` which calls `Scheduler:Start()`; slash command is the manual trigger per locked decision |
| CMBT-02 | 02-02, 02-03 | PLAYER_REGEN_DISABLED/ENABLED detection for automatic combat start/end | SATISFIED | Core.lua registers both; DISABLED -> `OnCombatStart()`, ENABLED -> `OnCombatEnd()`; state guards prevent spurious triggers |
| CMBT-03 | 02-02, 02-03 | State resets on PLAYER_ENTERING_WORLD (zone change) | SATISFIED | PLAYER_ENTERING_WORLD permanently registered; `Reset()` now unconditionally clears selectedDungeon=nil, currentPackIndex=nil, state="idle" |

**All 6 requirements satisfied.** No orphaned requirements detected for Phase 2.

---

## Anti-Patterns Found

No anti-patterns found in any Phase 2 file after gap closure:

- No TODO/FIXME/PLACEHOLDER/XXX comments
- No stub implementations (no `return nil`, `return {}`, empty handlers)
- No `C_Timer.After` usage — only `C_Timer.NewTimer` used throughout
- No unprotected external API calls in Stop() path — `pcall` wraps `CancelAllTimers`
- `ET_Show` and `DBM_Show` use real adapter APIs (gap closed by 02-04)
- `Reset()` unconditionally clears to idle (gap closed by 02-03)
- `OnCombatEnd` sets state before calling `Stop()` (gap closed by 02-03)

One design note (not a defect): `ManualStart` does not guard on state — it allows starting timers even if state is "end" or "active". This is intentional (manual override for testing), but it does not reset `state="active"` if already active, which could leave `combatActive[1]` set to true from a prior Start without calling Stop first. This is a known acceptable tradeoff for a testing/debug flow rather than a production path.

---

## Human Verification Required

The following behaviors require in-game testing and cannot be verified programmatically:

### 1. Ability Warning Timing Accuracy

**Test:** `/tpw select windrunner_spire` then `/tpw start`. Watch for Spellguard's Protection warning.
**Expected:** A pre-warning appears at ~45 seconds ("Spellguard's Protection in 5 sec"), followed by the cast alert at 50 seconds, repeating every 50 seconds thereafter.
**Why human:** Timer offsets are code-correct but actual WoW tick rate and display timing require in-game confirmation.

### 2. Display Adapter — Encounter Timeline Inside Dungeon

**Test:** Enter a Midnight dungeon instance. Run `/tpw select windrunner_spire` then `/tpw start`. Observe where warnings appear.
**Expected:** Chat prints "TPW display: EncounterTimeline" and warnings appear in the Boss Warnings / Encounter Timeline UI (not as RaidNotice text flashes in the center of the screen).
**Why human:** This was the original UAT failure. `C_EncounterTimeline.IsFeatureEnabled()` returning true does not guarantee `AddScriptEvent` renders visually in the ET bar for dungeon trash. The API behavior for non-boss encounters must be confirmed in-game.

### 3. Display Adapter — DBM Bars

**Test:** Load DBM/BossMod. Run `/tpw select windrunner_spire` then `/tpw start` outside a dungeon (or where ET is not enabled).
**Expected:** Chat prints "TPW display: DBM" and a timer bar appears in the DBM bar frame counting down to the first ability cast.
**Why human:** `DBT:CreateBar` API signature and DBM bar frame visibility depend on DBM version loaded.

### 4. Ghost Warning Prevention

**Test:** `/tpw start`, then immediately `/tpw stop`. Wait 60+ seconds.
**Expected:** No warnings appear after stop.
**Why human:** `combatActive[1]=false` closure mutation is code-correct but timer cancellation race conditions require live testing.

### 5. Auto-advance and End State on Combat End

**Test:** `/tpw select windrunner_spire`, enter combat with any mob, leave combat.
**Expected:** Chat prints "All packs completed." (only 1 pack defined). Running `/tpw status` shows `state: end`. Entering combat again does NOT start timers.
**Why human:** UAT originally confirmed this was broken. The fix has been verified in code (state-before-stop pattern, state="end" guard in OnCombatStart). In-game confirmation needed to close the UAT issue.

### 6. Zone Change Full Reset

**Test:** `/tpw select windrunner_spire`, then `/tpw start`, then zone out (hearth or portal).
**Expected:** Chat prints "TPW Session cleared (zone change)." Running `/tpw status` shows `state: idle, Dungeon: nil, Pack: nil`. No warnings fire after zone change.
**Why human:** UAT originally confirmed this was broken (state stayed "ready"). The fix sets nil/idle unconditionally. In-game confirmation needed to close the UAT issue.

---

## Gaps Summary

No gaps remain in the automated verification. All three UAT-identified bugs are closed:

- **Gap 1 (display stubs):** `ET_Show` now calls `C_EncounterTimeline.AddScriptEvent`; `DBM_Show` now calls `DBT:CreateBar`. RaidNotice is the true fallback only.
- **Gap 2 (combat end / timer stop):** State is set before `Stop()` in `OnCombatEnd`; `Stop()` wraps `CancelAllTimers` in `pcall`. State transitions are error-safe.
- **Gap 3 (zone reset to idle):** `Reset()` unconditionally sets `selectedDungeon=nil`, `currentPackIndex=nil`, `state="idle"`.

The remaining human verification items are behavioral confirmations (ET API rendering, DBM bar appearance, in-game timing) rather than code defects. Status is HUMAN_NEEDED rather than PASSED because the ET display adapter behavior in dungeons was the root cause of the original UAT failure and must be confirmed in-game before the phase can be declared production-ready.

---

_Verified: 2026-03-14T14:00:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification after gap closure: plans 02-03 (engine fixes) and 02-04 (display fixes)_
