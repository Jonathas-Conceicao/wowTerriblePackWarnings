---
status: complete
phase: v0.0.2-combined
source: [04-01-SUMMARY.md, 05-01-SUMMARY.md, 05-02-SUMMARY.md, 06-01-SUMMARY.md, 06-02-SUMMARY.md]
started: 2026-03-15T22:30:00Z
updated: 2026-03-15T22:30:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. Addon Loads Without Errors
expected: After /reload, the addon loads without Lua errors. No BossWarnings references cause errors. Chat shows load message.
result: pass

### 2. Timed Icon Display
expected: After selecting Windrunner Spire and entering combat with PALADIN mobs (or /tpw sim 60), a spell icon square appears for Spellguard's Protection with a cooldown sweep animation and integer countdown.
result: pass

### 3. Untimed Icon Display
expected: When WARRIOR mobs are in combat, a static Spirit Bolt icon appears with no sweep or countdown. Only one icon shows regardless of how many warriors are present.
result: pass

### 4. Multiple Mob Instances
expected: If 2 PALADIN mobs are in combat, 2 separate Spellguard's Protection icon squares appear, each with independent countdowns. Icons grow horizontally.
result: pass

### 5. Red Glow at 5 Seconds
expected: When a timed ability has 5 seconds remaining, the icon square gains a red border glow.
result: pass

### 6. TTS Warning at 5 Seconds
expected: When a timed ability has 5 seconds remaining, text-to-speech speaks the short callout ("Shield"). Only fires for timed abilities, not untimed.
result: pass

### 7. Timer Repeat Cycle
expected: After the first cast fires at ~50s, the cooldown sweep resets and begins counting down again for the next cast cycle. The same icon slot is reused (no new icon created).
result: pass

### 8. Mid-Combat Mob Detection
expected: If additional PALADIN or WARRIOR mobs enter combat mid-fight, new icons spawn for them. The 0.25s scanner detects them without noticeable delay.
result: pass

### 9. Combat End Clears All Icons
expected: When combat ends (PLAYER_REGEN_ENABLED), all spell icon squares disappear. No ghost icons remain. Pack advances to next.
result: pass

### 10. Camera Turn Does Not Duplicate Icons
expected: During combat, turning the camera so nameplates disappear and reappear does NOT create duplicate icon squares. Icon count stays stable.
result: pass

### 11. Sim Command Works
expected: Running /tpw sim 30 simulates a 30-second combat. Scanner starts, icons appear based on nearby nameplates, and after 30s combat ends and icons clear.
result: skipped
reason: Sim command dropped — not needed for v0.0.2

### 12. Pack Selection UI Still Works
expected: /tpw opens the pack selection window. Clicking a pack selects it. Combat state indicators update. Window still functions as before.
result: pass

### 13. Zone Change Resets State
expected: Zoning out clears all state and icons. Auto-detection re-selects the dungeon if entering a known instance.
result: pass

## Summary

total: 13
passed: 12
issues: 0
pending: 0
skipped: 1

## Gaps

[none yet]
