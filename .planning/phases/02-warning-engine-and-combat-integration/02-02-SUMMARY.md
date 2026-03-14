---
phase: 02-warning-engine-and-combat-integration
plan: "02"
subsystem: engine
tags: [lua, wow-addon, timers, combat-events, state-machine, C_Timer]

# Dependency graph
requires:
  - phase: 02-01
    provides: "ns.BossWarnings display API (Show, ShowTimer, CancelTimer, CancelAllTimers) and ordered PackDatabase array"
provides:
  - "ns.Scheduler:Start / Stop — timer chain engine with cancellation"
  - "ns.CombatWatcher — idle/ready/active/end state machine wired to combat lifecycle events"
  - "/tpw select/start/stop/status slash command for console testing"
  - "Core.lua permanently registered for PLAYER_ENTERING_WORLD zone-change resets"
affects:
  - 03-ui-and-pack-selection

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-element table pattern for closure-visible mutable state (combatActive)"
    - "Recursive C_Timer.NewTimer chain for repeating ability warnings"
    - "State machine with explicit guard returns (if state ~= 'ready' then return)"
    - "All timer handles stored in indexed table for atomic bulk cancellation"

key-files:
  created:
    - Engine/Scheduler.lua
    - Engine/CombatWatcher.lua
  modified:
    - Core.lua

key-decisions:
  - "combatActive uses single-element table {false} instead of boolean variable — Lua closures capture variable references; boolean reassignment creates a new value invisible to existing closures"
  - "scheduleAbility recursion on cast callback creates repeating cycle; each call uses cooldown as new first_cast"
  - "CombatWatcher state guard (if state ~= 'ready' then return) in OnCombatStart prevents double-starts and end-state triggers"
  - "PLAYER_ENTERING_WORLD intentionally not unregistered — must fire on every zone change to reset sequence"
  - "Slash command /tpw used for console testing instead of global TPW table (honors locked no-global decision)"

patterns-established:
  - "Timer chain pattern: scheduleAbility(ability) schedules pre-warning + cast alert + bar, cast callback recurses with cooldown as first_cast"
  - "Atomic Stop: combatActive[1] = false, then cancel all handles via IsCancelled guard, wipe table, cancel display timers"
  - "State machine guard pattern: all public event handlers check state before acting"

requirements-completed: [WARN-01, WARN-03, CMBT-01, CMBT-02, CMBT-03]

# Metrics
duration: 2min
completed: 2026-03-14
---

# Phase 2 Plan 02: Warning Engine and Combat Integration Summary

**C_Timer recursive chain scheduler with idle/ready/active/end combat watcher auto-advancing through dungeon packs on PLAYER_REGEN events**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-14T08:10:21Z
- **Completed:** 2026-03-14T08:11:55Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Scheduler fires 5-second pre-warnings and cast alerts at correct offsets, repeating on cooldown via recursive C_Timer chain
- All timer handles tracked in `activeTimers` table and cancelled atomically via `Stop()` — prevents ghost warnings
- CombatWatcher state machine auto-starts timers on `PLAYER_REGEN_DISABLED`, stops and advances pack index on `PLAYER_REGEN_ENABLED`
- Zone changes via `PLAYER_ENTERING_WORLD` reset sequence to pack 1 (frame stays permanently registered)
- `/tpw select/start/stop/status` provides full console testing without a global variable

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Scheduler module with timer chain management** - `12b8feb` (feat)
2. **Task 2: Create CombatWatcher state machine and update Core.lua event wiring** - `5e5b29d` (feat)

## Files Created/Modified
- `Engine/Scheduler.lua` - Timer scheduling engine: Start reads pack data, schedules all ability chains; Stop cancels all handles atomically
- `Engine/CombatWatcher.lua` - Combat lifecycle state machine: idle/ready/active/end with SelectDungeon, ManualStart, OnCombatStart, OnCombatEnd, Reset, GetState
- `Core.lua` - Registers PLAYER_REGEN_DISABLED/ENABLED; wires events to CombatWatcher; PLAYER_ENTERING_WORLD stays permanently registered; /tpw slash command wired to full API

## Decisions Made
- `combatActive` is a single-element table `{false}` rather than a boolean. Lua closures capture references to upvalue slots; when you assign `combatActive = false`, closures already holding the reference still see the old `true` value. The table itself never changes identity, so `combatActive[1] = false` is visible to all closures.
- `scheduleAbility` recurses inside the cast callback rather than using `C_Timer.NewTicker`. This ensures each ability's repeat interval is independent and the same `combatActive` guard applies on every iteration.
- `OnCombatStart` guards with `if state ~= "ready" then return` to handle: (a) player is in a non-dungeon zone where PLAYER_REGEN_DISABLED fires during world PvP, (b) end state after all packs exhausted.

## Deviations from Plan

None - plan executed exactly as written. The plan's note about "no global TPW table" vs "use TPW.Scheduler approach" was already resolved within the plan itself — slash command approach was used as directed.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Engine is complete and ready for Phase 3 UI: `ns.CombatWatcher:GetState()` exposes state/dungeon/packIndex for UI display
- `ns.CombatWatcher:SelectDungeon(key)` is the integration point for a pack selection UI
- Pre-existing blocker note: `PLAYER_REGEN_DISABLED` behavior in M+ keystone runs is not empirically verified — should be validated in-game before declaring full correctness

---
*Phase: 02-warning-engine-and-combat-integration*
*Completed: 2026-03-14*
