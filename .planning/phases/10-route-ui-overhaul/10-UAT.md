---
status: complete
phase: v0.0.3-combined
source: [08-01-SUMMARY.md, 08-02-SUMMARY.md, 09-01-SUMMARY.md, 09-02-SUMMARY.md, 10-01-SUMMARY.md]
started: 2026-03-16T03:00:00Z
updated: 2026-03-16T03:00:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. Addon Loads Without Errors
expected: After /reload, addon loads without Lua errors. No missing library errors.
result: pass

### 2. /tpw Opens UI with Empty State
expected: /tpw opens the pack selection window. Header shows "No route imported" (or similar empty state). No pulls listed. Import and Clear buttons visible at the bottom.
result: pass

### 3. Import via Slash Command
expected: Running /tpw import <MDT string> decodes the string and populates the pack list. Chat shows import summary (dungeon name, pull count, abilities found).
result: skipped
reason: WoW chat buffer too small for MDT strings. Slash command removed. Import is UI-only via Import button.

### 4. UI Shows Imported Pulls
expected: After import, the pack selection window shows numbered pull rows with small round NPC portrait icons per mob. Header shows dungeon name and pull count.
result: pass

### 5. Import via UI Button
expected: Clicking the Import button opens a popup with a multi-line editbox. Pasting an MDT string and clicking Import populates the pull list.
result: pass

### 6. Click Pull to Select
expected: Clicking a pull row selects it (green highlight). State shows as "ready" for combat.
result: pass

### 7. Combat Works with Imported Packs
expected: With an imported pull selected, entering combat triggers nameplate scanning and spell icon display (same as v0.0.2 behavior). Timed abilities show cooldown sweep, untimed show static icons.
result: pass

### 8. Route Persists Across Reload
expected: After importing a route, /reload preserves the imported data. Pack list shows the same pulls without needing to re-import.
result: pass

### 9. Clear with Confirmation
expected: Clicking the Clear button shows a confirmation dialog. Confirming clears all imported data. Pack list returns to empty state.
result: pass

### 10. /tpw clear via Slash Command
expected: Running /tpw clear removes imported route data. Pack list empties. Chat confirms clearing.
result: pass

### 11. /tpw decode Works
expected: Running /tpw decode <MDT string> prints the decoded table structure to chat (debug utility).
result: skipped
reason: WoW chat buffer too small for MDT strings. Slash command removed.

## Summary

total: 11
passed: 9
issues: 0
pending: 0
skipped: 2

## Gaps

[none yet]
