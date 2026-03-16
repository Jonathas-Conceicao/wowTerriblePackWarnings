---
status: complete
phase: 07-complete-dungeon-route
source: [07-01-SUMMARY.md, 07-02-SUMMARY.md]
started: 2026-03-16T01:00:00Z
updated: 2026-03-16T01:00:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. Addon Loads with 17 Packs
expected: After /reload, addon loads without errors. /tpw shows the pack selection window with all 17 Windrunner Spire packs listed in the accordion.
result: pass

### 2. Pack 1 — Shield + Bolt Icons
expected: Entering combat on pack 1 with PALADIN and WARRIOR mobs shows Spellguard's Protection icon (with "DR" label) and Spirit Bolt icon (with "Bolt" label).
result: pass

### 3. Icon Labels Visible
expected: Labels ("DR", "Bolt") appear as small text at the bottom edge of each icon square. They don't obscure the spell icon.
result: pass

### 4. Tooltip on Mouseover
expected: Mousing over any icon square shows the WoW spell tooltip (spell name, description, etc.). Tooltip disappears when mouse leaves the icon.
result: pass

### 5. Pack 3 — Fire Spit
expected: Pack 3 combat with WARRIOR mobs shows Fire Spit icon (static, untimed) with "DMG" label.
result: pass

### 6. Pack 13 — Interrupting Screech
expected: Pack 13 combat with PALADIN mobs shows Interrupting Screech icon with cooldown sweep (20s start, 25s repeat), "Kick" label, and TTS "Stop Casting" at 5 seconds remaining.
result: pass

### 7. Empty Packs Auto-Advance
expected: Packs without abilities (4, 5, 7, 9-12, 14-17) still appear in the UI, auto-advance on combat end, and show no icons during combat.
result: pass

### 8. Full Route Progression
expected: Running through multiple packs in sequence, the pack selection UI shows progression (completed packs greyed, current highlighted). Auto-advance works through the full 17-pack route.
result: pass

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
