---
status: diagnosed
trigger: "Zone change fires reset ('TPW Reset to pack 1') but state stays 'ready' with dungeon still selected instead of going back to 'idle'."
created: 2026-03-14T00:00:00Z
updated: 2026-03-14T00:00:00Z
---

## Current Focus

hypothesis: CombatWatcher:Reset() intentionally preserves dungeon selection and sets state to "ready" instead of "idle"
test: Read Reset() implementation
expecting: Reset clears selectedDungeon and sets state to "idle"
next_action: Report root cause

## Symptoms

expected: Zone change should clear dungeon selection entirely and return state to "idle"
actual: Zone change fires Reset() which prints "TPW Reset to pack 1" and keeps state as "ready" with dungeon still selected
errors: None (functional bug, not crash)
reproduction: Select a dungeon via /tpw select, then change zones
started: By design — Reset() was written this way

## Eliminated

(none needed — root cause found on first read)

## Evidence

- timestamp: 2026-03-14
  checked: Core.lua line 36 — PLAYER_ENTERING_WORLD handler
  found: Calls ns.CombatWatcher:Reset() on every zone change
  implication: Reset is the zone-change handler, so the bug is in Reset()

- timestamp: 2026-03-14
  checked: CombatWatcher.lua lines 77-87 — Reset() implementation
  found: When selectedDungeon is set and valid, Reset() sets currentPackIndex=1 and state="ready". It does NOT clear selectedDungeon to nil.
  implication: This is the direct root cause. Reset preserves dungeon selection by design, but the UAT expectation is that zone change should clear it.

- timestamp: 2026-03-14
  checked: CombatWatcher.lua lines 10-17 — state definitions
  found: "idle" = no dungeon selected, "ready" = dungeon selected waiting for pull
  implication: To reach "idle", selectedDungeon must be set to nil and currentPackIndex to nil

## Resolution

root_cause: CombatWatcher:Reset() (CombatWatcher.lua lines 77-87) preserves the dungeon selection when a valid dungeon is selected. It resets pack index to 1 and state to "ready", but never clears selectedDungeon to nil. The "idle" state (no dungeon selected) is only reached in the else branch — when no dungeon was selected in the first place.
fix: (not applied — diagnosis only)
verification: (not applied — diagnosis only)
files_changed: []
