---
status: complete
phase: 17-command-rework-and-config-search
source: [17-01-SUMMARY.md, 17-02-SUMMARY.md]
started: 2026-03-21T00:00:00Z
updated: 2026-03-21T03:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. /tpw opens config window
expected: Type /tpw in chat. The config window opens (not the route window).
result: pass

### 2. /tpw route opens route window
expected: Type /tpw route in chat. The route window opens.
result: pass

### 3. Case-insensitive subcommands
expected: Type /tpw ROUTE, /tpw Route, /tpw DEBUG — all work regardless of casing.
result: pass

### 4. /tpw help shows grouped output
expected: Type /tpw help. Chat shows commands grouped by category (Windows, Route, Debug) with descriptions.
result: pass

### 5. Config button removed from route window
expected: Open route window (/tpw route). Footer has only Clear (left) and Import (right) — no Config button.
result: pass

### 6. Combat mode buttons centered in route window
expected: Route window shows Disable/Manual/Auto buttons centered and evenly spaced.
result: pass

### 7. Config top bar layout
expected: Config window has top bar with [Route] [Reset All] on left, [Search box] on right. Horizontal divider below.
result: pass

### 8. Route button in config opens route window
expected: Click Route button in config top bar. Route window opens.
result: pass

### 9. Reset All with confirmation
expected: Click Reset All in config. StaticPopup asks confirmation with Yes/No. Click Yes — all skill configs clear.
result: pass

### 10. Search filters dungeon/mob tree
expected: Type a mob name in search box. Left panel shows only matching mobs, auto-expands their dungeon.
result: pass

### 11. Search filters by skill name
expected: Type a skill name in search box. Mobs with matching abilities appear. Selecting a mob shows only matched skills.
result: pass

### 12. Search no matches shows message
expected: Type nonsense in search. Left panel shows "No matches found." message.
result: pass

### 13. Close config resets search
expected: Type a search term, close config window. Reopen — search box empty, full tree restored.
result: pass

### 14. Right panel mob portrait and divider
expected: Select a mob in config. Right panel shows square mob portrait before mob name, horizontal divider line between header and skills.
result: pass

### 15. Left panel background and borders
expected: Config window left panel has a subtle dark background tint with proper borders.
result: pass

### 16. Disable mode clears displays immediately
expected: During combat with icons showing, click Disable. All spell icons and glows clear instantly.
result: pass

## Summary

total: 16
passed: 16
issues: 0
pending: 0
skipped: 0

## Gaps

[none]
