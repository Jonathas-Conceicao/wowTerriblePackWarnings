---
status: complete
phase: 02-warning-engine-and-combat-integration
source: [02-01-SUMMARY.md, 02-02-SUMMARY.md, 02-03-SUMMARY.md, 02-04-SUMMARY.md]
started: 2026-03-14T10:00:00Z
updated: 2026-03-15T02:00:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. Addon Loads Without Errors
expected: After /reload, the addon loads without Lua errors. Chat shows the colored load message: "TerriblePackWarnings loaded. Type /tpw to configure."
result: pass

### 2. Pack Data Queryable as Ordered Array
expected: Running `/run print(select(2, ...).PackDatabase["windrunner_spire"][1].displayName)` prints "Windrunner Spire — Pack 1". The data is an ordered array, not a string-keyed map.
result: skipped
reason: ns is local to addon files (no global TPW table by design) — not accessible from /run console. Data verified indirectly via /tpw select.

### 3. Select Dungeon via Slash Command
expected: Running `/tpw select windrunner_spire` prints a confirmation message showing the dungeon is selected and current pack index is 1. Running `/tpw status` shows state as "ready" with the selected dungeon.
result: pass

### 4. Manual Timer Start — Display Adapter (retest)
expected: Running `/tpw start` (after selecting a dungeon) starts ability timers. Warnings display via Encounter Timeline bars or DBM bars, NOT as RaidNotice text. Debug logging shows adapter dispatch in chat.
result: pass
previous: issue — "warnings show as RaidNotice text"
fix: "DBM adapter priority, ET pcall+fallback, forward declarations, DBM_Show uses RaidNotice for text alerts"

### 5. Timer Stop via Slash Command
expected: Running `/tpw stop` cancels all active timers immediately. No further warnings appear after stopping. Running `/tpw status` shows state change (no longer active).
result: pass

### 6. Timer Repeat Cycle
expected: After the first cast alert at ~50s, the timer automatically restarts. A second pre-warning appears at ~95s (50+50-5) and second cast alert at ~100s. The cycle continues until manually stopped or combat ends.
result: pass

### 7. Display Adapter Detection
expected: On first timer start, a chat message prints which display adapter was detected (Encounter Timeline, DBM, or RaidNotice). The warnings appear in the detected system's UI.
result: pass

### 8. Combat Auto-Trigger
expected: With a dungeon selected (/tpw select windrunner_spire), entering combat with a mob (pulling trash) automatically starts timers via PLAYER_REGEN_DISABLED. No manual /tpw start needed.
result: pass

### 9. Combat End Auto-Advance (retest)
expected: After combat ends (mob dies, PLAYER_REGEN_ENABLED), all timers stop cleanly — no ghost warnings fire. With 1 pack, state advances to "end" and does NOT re-trigger on next combat. Running `/tpw status` shows the session ended.
result: pass
previous: issue — "timers don't stop, keeps re-triggering every combat"
fix: "02-03: OnCombatEnd transitions state before Stop(), Stop() wraps CancelAllTimers in pcall"

### 10. Zone Change Full Reset (retest)
expected: After selecting a dungeon and entering combat, zoning out resets state to "idle". `/tpw status` shows no dungeon selected, no pack index. Chat message says session cleared (not "reset to pack 1").
result: pass
previous: issue — "state stays 'ready' with dungeon still selected"
fix: "02-03: Reset() unconditionally clears selectedDungeon=nil, currentPackIndex=nil, state='idle'"

## Summary

total: 10
passed: 9
issues: 0
pending: 0
skipped: 1

## Gaps

- truth: "Warnings display in Encounter Timeline bars or DBM bars, not as RaidNotice text"
  status: failed
  reason: "User reported: warnings show as RaidNotice text in middle of screen, not in Encounter Timeline or DBM bars despite EncounterTimeline detected at load. /tpw start input stays in chat. Need more chat logging for debug."
  severity: major
  test: 4
  root_cause: "ET_Show and DBM_Show in Display/BossWarnings.lua are copy-paste stubs that all call RaidNotice_AddMessage instead of adapter-specific APIs. Only ShowTimer functions have real implementations."
  artifacts:
    - path: "Display/BossWarnings.lua"
      issue: "ET_Show (lines 65-67) calls RaidNotice_AddMessage instead of C_EncounterTimeline API"
    - path: "Display/BossWarnings.lua"
      issue: "DBM_Show (lines 94-96) calls RaidNotice_AddMessage instead of DBM API"
  missing:
    - "Implement ET_Show using C_EncounterTimeline.AddScriptEvent with short duration"
    - "Implement DBM_Show using DBT:CreateBar or DBM announcement API"
    - "Add chat debug logging to Scheduler and BossWarnings for testing"
  debug_session: ".planning/debug/warnings-display-raidnotice-fallback.md"
- truth: "Timers stop on combat end and auto-advance to next pack or end state"
  status: failed
  reason: "User reported: timers don't stop on PLAYER_REGEN_ENABLED. With 1 pack, should reach end state after first combat. Instead keeps re-triggering every combat. Multiple combats stack duplicate timer sets resulting in overlapping warnings firing together."
  severity: blocker
  test: 9
  root_cause: "Two interacting bugs: (1) Scheduler:Stop() has no pcall protection around BossWarnings.CancelAllTimers() — if ET adapter's CancelAllScriptEvents errors, the entire OnCombatEnd state transition is aborted, leaving state as 'active'. (2) Reset() unconditionally sets state='ready' and packIndex=1 on PLAYER_ENTERING_WORLD, re-enabling combat triggers even after session should have ended."
  artifacts:
    - path: "Engine/Scheduler.lua"
      issue: "Stop() line 95 calls BossWarnings.CancelAllTimers() without pcall — error aborts state transition"
    - path: "Engine/CombatWatcher.lua"
      issue: "OnCombatEnd() lines 59-75 has no error protection around Stop() — state stays 'active' on error"
    - path: "Engine/CombatWatcher.lua"
      issue: "Reset() lines 77-87 unconditionally sets state='ready' regardless of prior state"
  missing:
    - "Wrap BossWarnings.CancelAllTimers() in pcall in Scheduler:Stop()"
    - "Move state transition before Stop() in OnCombatEnd() or use pcall"
    - "Add end-state guard to Reset() — don't reset to ready if session is complete"
    - "Consider session ID instead of boolean combatActive flag to prevent stale callbacks"
  debug_session: ""
- truth: "Zone change resets state to idle with no dungeon selected"
  status: failed
  reason: "User reported: zone change fires reset message but state stays 'ready' with dungeon still selected. Should go back to 'idle' and clear dungeon."
  severity: major
  test: 10
  root_cause: "CombatWatcher:Reset() in Engine/CombatWatcher.lua lines 77-87 preserves dungeon selection on zone change. When a valid dungeon is selected, it resets currentPackIndex to 1 and sets state to 'ready' but never clears selectedDungeon to nil."
  artifacts:
    - path: "Engine/CombatWatcher.lua"
      issue: "Reset() lines 77-87 keeps selectedDungeon and sets state='ready' instead of clearing to 'idle'"
  missing:
    - "Set selectedDungeon = nil, currentPackIndex = nil, state = 'idle' unconditionally in Reset()"
    - "Update print message to reflect session cleared, not just pack reset"
  debug_session: ".planning/debug/zone-change-reset-keeps-ready.md"
