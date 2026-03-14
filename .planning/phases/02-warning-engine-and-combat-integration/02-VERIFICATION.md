---
phase: 02-warning-engine-and-combat-integration
verified: 2026-03-14T12:00:00Z
status: passed
score: 11/11 must-haves verified
re_verification: false
---

# Phase 2: Warning Engine and Combat Integration Verification Report

**Phase Goal:** Selecting a pack and pulling causes timed ability warnings to appear in the Boss Warnings UI (or fallback frame) and all timers clean up correctly on combat end or zone change
**Verified:** 2026-03-14T12:00:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

Truths are drawn from both plan frontmatter `must_haves` blocks (02-01 and 02-02) and the four ROADMAP.md success criteria for Phase 2.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | PackDatabase stores packs as an ordered array per dungeon with key, displayName, mobs fields | VERIFIED | `WindrunnerSpire.lua` uses `ns.PackDatabase["windrunner_spire"]` as ordered array; each entry has `key`, `displayName`, `mobs` |
| 2 | ns.BossWarnings.Show(text, duration) displays a warning using the best available display system | VERIFIED | `Display/BossWarnings.lua` implements `BW.Show` dispatching to ET / DBM / RaidNotice via `activeAdapter` |
| 3 | Display adapter auto-detects C_EncounterTimeline > DBT > RaidNotice at runtime | VERIFIED | `DetectAdapter()` in `BossWarnings.lua` lines 16-31: checks `C_EncounterTimeline.IsFeatureEnabled()`, then `DBT`, then falls back to RaidNotice |
| 4 | TOC file lists all new Engine and Display files in correct load order | VERIFIED | TOC lines 10-14: `Core.lua`, `Engine\Scheduler.lua`, `Engine\CombatWatcher.lua`, `Display\BossWarnings.lua`, `Data\WindrunnerSpire.lua` |
| 5 | Scheduler fires 5-second pre-warnings and cast alerts at correct offsets | VERIFIED | `Scheduler.lua` `scheduleAbility`: `preWarnOffset = first_cast - 5`, `C_Timer.NewTimer(preWarnOffset, ...)` then `C_Timer.NewTimer(ability.first_cast, ...)` |
| 6 | Each ability fires a pre-warning then cast alert, repeating on cooldown | VERIFIED | Cast callback in `scheduleAbility` recursively calls `scheduleAbility({..., first_cast = ability.cooldown, cooldown = ability.cooldown})` |
| 7 | All timers cancel immediately when combat ends (PLAYER_REGEN_ENABLED) | VERIFIED | `Core.lua` line 31 wires `PLAYER_REGEN_ENABLED` to `CombatWatcher:OnCombatEnd()`, which calls `Scheduler:Stop()`; `Stop()` sets `combatActive[1] = false`, cancels all handles via `IsCancelled()` guard, wipes table, calls `BossWarnings.CancelAllTimers()` |
| 8 | Zone change (PLAYER_ENTERING_WORLD) resets sequence to pack 1 and cancels all timers | VERIFIED | `Core.lua` line 35 wires `PLAYER_ENTERING_WORLD` to `CombatWatcher:Reset()`; `Reset()` calls `Scheduler:Stop()` then resets `currentPackIndex = 1` and `state = "ready"`; event is NOT unregistered |
| 9 | Combat start with a selected pack auto-triggers timers via PLAYER_REGEN_DISABLED | VERIFIED | `Core.lua` line 29 wires `PLAYER_REGEN_DISABLED` to `CombatWatcher:OnCombatStart()`; state guard `if state ~= "ready" then return` prevents spurious triggers |
| 10 | Combat end auto-advances to the next pack in the sequence | VERIFIED | `CombatWatcher:OnCombatEnd()` increments `currentPackIndex` after stop; transitions to `"end"` state when all packs exhausted |
| 11 | When all packs exhausted, engine enters end state and stops auto-triggering | VERIFIED | `OnCombatEnd()` sets `state = "end"` when `currentPackIndex > #dungeon`; `OnCombatStart()` guard `if state ~= "ready"` prevents end-state triggers |

**Score:** 11/11 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Data/WindrunnerSpire.lua` | Ordered array pack data for auto-advance indexing | VERIFIED | 24 lines; uses `packs[#packs + 1] = {...}` with `key`, `displayName`, `mobs` fields |
| `Display/BossWarnings.lua` | Display abstraction with 3-tier fallback | VERIFIED | 170 lines; exports `Show`, `ShowTimer`, `CancelTimer`, `CancelAllTimers`, `GetAdapter`; all three adapters implemented substantively |
| `Engine/Scheduler.lua` | Timer scheduling with Start, Stop, cancel, repeating ability chains | VERIFIED | 98 lines; `Scheduler:Start` and `Scheduler:Stop`; `scheduleAbility` recursive chain; `combatActive` single-element table pattern |
| `Engine/CombatWatcher.lua` | Combat event wiring, auto-advance, zone reset | VERIFIED | 92 lines; `SelectDungeon`, `ManualStart`, `OnCombatStart`, `OnCombatEnd`, `Reset`, `GetState`; full idle/ready/active/end state machine |
| `Core.lua` | Updated event frame with PLAYER_REGEN_DISABLED/ENABLED and permanent PLAYER_ENTERING_WORLD | VERIFIED | 67 lines; all four events registered; no `UnregisterEvent("PLAYER_ENTERING_WORLD")` call; `/tpw` slash command fully wired |
| `TerriblePackWarnings.toc` | Updated load order with Engine and Display files | VERIFIED | All five files listed in correct dependency order |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Engine/Scheduler.lua` | `Display/BossWarnings.lua` | `ns.BossWarnings.Show`, `ShowTimer`, `CancelAllTimers` | WIRED | Lines 31, 39, 54, 95 in Scheduler.lua; all inside function bodies, not module scope |
| `Engine/CombatWatcher.lua` | `Engine/Scheduler.lua` | `ns.Scheduler:Start`, `ns.Scheduler:Stop` | WIRED | Lines 47, 55 (Start) and 62, 78 (Stop) in CombatWatcher.lua |
| `Engine/CombatWatcher.lua` | `ns.PackDatabase` | reads ordered array by dungeon key and current pack index | WIRED | Lines 24, 67, 80 in CombatWatcher.lua |
| `Core.lua` | `Engine/CombatWatcher.lua` | `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`, `PLAYER_ENTERING_WORLD` | WIRED | Core.lua lines 29, 32, 36; also `/tpw` slash command wires `SelectDungeon`, `ManualStart`, `GetState` |
| `Display/BossWarnings.lua` | `C_EncounterTimeline` or `DBT` or `RaidNotice_AddMessage` | runtime adapter detection | WIRED | All three adapter call sites present; `C_EncounterTimeline.AddScriptEvent/CancelScriptEvent/CancelAllScriptEvents`, `DBT:CreateBar/CancelBar`, `RaidNotice_AddMessage` |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| WARN-01 | 02-02 | Timer scheduler starts ability cooldown timers when a pack pull is triggered | SATISFIED | `Scheduler:Start(dungeonKey, packIndex)` reads pack data and schedules all ability chains via `scheduleAbility`; wired to `/tpw start` and `PLAYER_REGEN_DISABLED` |
| WARN-02 | 02-01 | Warnings display through Blizzard's Boss Warnings API (with fallback frame if API doesn't support trash) | SATISFIED | `Display/BossWarnings.lua` implements 3-tier: Encounter Timeline (Blizzard Boss Warnings), DBM timer bars, RaidNotice text flash |
| WARN-03 | 02-02 | All active timers cancel on combat end or zone change | SATISFIED | `Scheduler:Stop()` atomically cancels all `C_Timer.NewTimer` handles + display timers; called from both `OnCombatEnd()` (PLAYER_REGEN_ENABLED) and `Reset()` (PLAYER_ENTERING_WORLD) |
| CMBT-01 | 02-02 | Manual pull trigger button starts timers for the selected pack | SATISFIED | `/tpw start [pack#]` calls `CombatWatcher:ManualStart()` which calls `Scheduler:Start()`; no button required — slash command is the manual trigger per locked decision |
| CMBT-02 | 02-02 | PLAYER_REGEN_DISABLED/ENABLED detection for automatic combat start/end | SATISFIED | `Core.lua` registers both events; `PLAYER_REGEN_DISABLED` -> `OnCombatStart()`, `PLAYER_REGEN_ENABLED` -> `OnCombatEnd()` |
| CMBT-03 | 02-02 | State resets on PLAYER_ENTERING_WORLD (zone change) | SATISFIED | `PLAYER_ENTERING_WORLD` permanently registered in Core.lua (no unregister); calls `CombatWatcher:Reset()` which stops timers and resets to pack 1 |

**All 6 requirements satisfied.** No orphaned requirements detected for Phase 2.

---

## Anti-Patterns Found

No anti-patterns found in any Phase 2 file:

- No TODO/FIXME/PLACEHOLDER/XXX comments
- No stub implementations (`return nil`, `return {}`, empty handlers)
- No `C_Timer.After` usage (non-cancellable) — only `C_Timer.NewTimer` used
- No `DBT:CancelAllBars()` call — DBM adapter tracks own bar IDs and cancels individually
- All `C_Timer.NewTimer` handles stored in `activeTimers` before any early-return path

One notable design note (not a defect): The TOC lists `Engine\Scheduler.lua` and `Engine\CombatWatcher.lua` before `Display\BossWarnings.lua`. All calls to `ns.BossWarnings` in the engine files occur inside function bodies (closures and methods), never at module scope. By the time any engine function is invoked at runtime, all modules including `Display\BossWarnings.lua` are fully loaded. This is correct Lua addon load-time behavior.

---

## Human Verification Required

The following behaviors require in-game testing and cannot be verified programmatically:

### 1. Ability Warning Timing Accuracy

**Test:** `/tpw select windrunner_spire` then `/tpw start`. Watch for Spellguard's Protection warning.
**Expected:** A pre-warning appears at ~45 seconds ("Spellguard's Protection in 5 sec"), followed by the cast alert at 50 seconds, repeating every 50 seconds thereafter.
**Why human:** Timer offsets are code-correct but actual WoW tick rate and display timing require in-game confirmation.

### 2. Display Adapter Selection

**Test:** Run with and without DBM loaded; run inside a dungeon instance.
**Expected:** Chat prints "TPW display: EncounterTimeline" inside a dungeon (if Blizzard supports it for trash), "TPW display: DBM" with DBM loaded outside, "TPW display: RaidNotice" otherwise.
**Why human:** `C_EncounterTimeline.IsFeatureEnabled()` return value for dungeon trash is unconfirmed — the research noted this as an outstanding concern.

### 3. Ghost Warning Prevention

**Test:** `/tpw start`, then immediately `/tpw stop` (or leave combat). Wait 60 seconds.
**Expected:** No warnings appear after stop.
**Why human:** Closure mutation via `combatActive[1] = false` is code-correct but timer cancellation race conditions require live testing.

### 4. Auto-advance on Combat End

**Test:** `/tpw select windrunner_spire`, enter combat, leave combat.
**Expected:** Chat prints "Next: Windrunner Spire -- Pack 2" (or "All packs completed." if only one pack exists in the database).
**Why human:** Currently only one pack is defined in WindrunnerSpire.lua, so the "all packs exhausted" path will trigger immediately — confirming end-state behavior requires at minimum two packs, or manual testing with `/tpw start 2` after confirming pack 2 doesn't exist triggers the error path gracefully.

### 5. PLAYER_REGEN_DISABLED Behavior in M+ Keystone

**Test:** Run a Mythic+ key. Pull a pack without selecting a dungeon (state = idle).
**Expected:** No warnings fire; state machine guard prevents spurious triggers.
**Why human:** The summary noted PLAYER_REGEN_DISABLED behavior in keystone runs as empirically unverified. Real keystone pulls may differ from open-world combat events.

---

## Gaps Summary

No gaps. All 11 observable truths verified, all 6 artifacts substantive and wired, all 6 Phase 2 requirements satisfied, zero anti-patterns. The phase goal is achieved in code.

The only outstanding items are human verification tests for in-game timing accuracy, display adapter detection behavior inside dungeons, and M+ keystone event behavior — none of which indicate defects in the implementation.

---

_Verified: 2026-03-14T12:00:00Z_
_Verifier: Claude (gsd-verifier)_
