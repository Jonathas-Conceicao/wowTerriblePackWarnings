---
status: complete
phase: 03-pack-selection-ui
source: [03-01-SUMMARY.md, 03-02-SUMMARY.md]
started: 2026-03-15T05:00:00Z
updated: 2026-03-15T05:00:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. Addon Loads Without Errors
expected: After /reload, the addon loads without Lua errors. Chat shows "TerriblePackWarnings loaded. Type /tpw to configure."
result: pass

### 2. Window Opens via /tpw
expected: Typing `/tpw` (bare, no arguments) opens a medium-sized dialog window with a title bar showing the addon name and a close button. The window contains a scrollable list area.
result: pass

### 3. Window Toggles and Closes
expected: Typing `/tpw` again closes the window. Pressing Escape also closes the window. The window behaves like a standard WoW panel.
result: pass

### 4. Accordion Dungeon Headers
expected: The window shows dungeon names as collapsible section headers. Clicking a dungeon header expands/collapses the pack list underneath it.
result: pass

### 5. Pack Rows Display
expected: Under an expanded dungeon header, pack rows show the pack display name (name only, no mob count). The list is scrollable if it exceeds the window height.
result: pass

### 6. Click to Select Pack
expected: Clicking a pack row selects it. The selected pack shows a visual highlight (border, checkmark icon, or color change). A chat message confirms the selection.
result: pass

### 7. Combat State Indicators
expected: With a dungeon selected, entering combat shows the active pack with a distinct "fighting" indicator (different color/icon from just selected). After combat ends, completed packs show a completed indicator (grey/checkmark).
result: pass

### 8. Live Update on Auto-Advance
expected: With the window open during combat, when combat ends and auto-advance moves to the next pack, the highlight/indicator updates in real-time without needing to close and reopen the window.
result: pass

### 9. Wipe Recovery Re-Select
expected: After a pack is marked as completed, clicking it again re-selects it (for wipe recovery). The state resets to ready for that pack.
result: pass

### 10. Window Position Persistence
expected: Dragging the window to a new position, then doing /reload and /tpw — the window reopens at the saved position, not the default center.
result: pass

### 11. Zone Change Resets UI
expected: After selecting a dungeon and packs, zoning out resets the state. The window (if open) reflects the reset — no pack selected, state cleared.
result: pass

### 12. Existing Subcommands Still Work
expected: `/tpw select windrunner_spire`, `/tpw status`, `/tpw start`, `/tpw stop` all still work alongside the new UI window.
result: pass

## Summary

total: 12
passed: 12
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
