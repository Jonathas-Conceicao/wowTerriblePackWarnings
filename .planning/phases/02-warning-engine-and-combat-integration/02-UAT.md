---
status: complete
phase: 02-warning-engine-and-combat-integration
source: [02-01-SUMMARY.md, 02-02-SUMMARY.md]
started: 2026-03-14T10:00:00Z
updated: 2026-03-14T10:00:00Z
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

### 4. Manual Timer Start via Slash Command
expected: Running `/tpw start` (after selecting a dungeon) starts ability timers. Within ~45 seconds, a pre-warning appears ("Spellguard's Protection in 5 sec" or similar text/bar). At ~50 seconds, the cast alert fires. Display appears in either the Encounter Timeline, DBM bars, or as a RaidNotice text flash depending on which system is available.
result: issue
reported: "/tpw start stays in chat after pressing enter. Timers do fire but warnings show as RaidNotice text in middle of screen, not in Encounter Timeline or DBM bars despite EncounterTimeline being detected at load. User also wants more chat logging for debug during testing. DBM /break command works as reference for DBM bar integration."
severity: major

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

### 9. Combat End Auto-Advance
expected: After combat ends (mob dies, PLAYER_REGEN_ENABLED), all timers stop cleanly — no ghost warnings fire. A chat message indicates the pack index advanced to the next pack. Running `/tpw status` shows the incremented pack index.
result: issue
reported: "Timers don't stop on combat end (PLAYER_REGEN_ENABLED). With only 1 pack, after first combat ends it should auto-advance to end state and not re-trigger on next combat. Instead it keeps re-triggering every combat indefinitely."
severity: major

### 10. Zone Change Full Reset
expected: After selecting a dungeon and advancing through one or more combats, zoning out (hearth, portal, or leaving instance) resets the state. Running `/tpw status` after zone change shows state reset to "idle" with no dungeon selected and pack index cleared.
result: issue
reported: "Zone change fires reset ('TPW Reset to pack 1') but state stays 'ready' with dungeon still selected instead of going back to 'idle'. Reset should clear dungeon selection entirely."
severity: major

## Summary

total: 10
passed: 6
issues: 3
pending: 0
skipped: 1
skipped: 0

## Gaps

- truth: "Warnings display in Encounter Timeline bars or DBM bars, not as RaidNotice text"
  status: failed
  reason: "User reported: warnings show as RaidNotice text in middle of screen, not in Encounter Timeline or DBM bars despite EncounterTimeline detected at load. /tpw start input stays in chat. Need more chat logging for debug."
  severity: major
  test: 4
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
- truth: "Timers stop on combat end and auto-advance to next pack or end state"
  status: failed
  reason: "User reported: timers don't stop on PLAYER_REGEN_ENABLED. With 1 pack, should reach end state after first combat. Instead keeps re-triggering every combat. Multiple combats stack duplicate timer sets resulting in overlapping warnings firing together."
  severity: blocker
  test: 9
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
- truth: "Zone change resets state to idle with no dungeon selected"
  status: failed
  reason: "User reported: zone change fires reset message but state stays 'ready' with dungeon still selected. Should go back to 'idle' and clear dungeon."
  severity: major
  test: 10
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
