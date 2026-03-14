# Phase 2: Warning Engine and Combat Integration - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Timer scheduling, warning display integration, and combat event wiring that delivers working in-game ability warnings for selected packs. The addon is a **data provider** — it pushes ability data into external timer/warning systems (Blizzard Encounter Timers or DBM API) and does not render UI itself. Includes auto-advance through a pack sequence and combat start/end lifecycle management.

</domain>

<decisions>
## Implementation Decisions

### Warning Display
- Addon is a **data provider only** — it does NOT implement timers, bars, or alert UI
- Display priority (try in order):
  1. **C_EncounterTimeline.AddScriptEvent()** — Blizzard's native encounter timeline (bars/timeline based on user config)
  2. **DBT:CreateBar()** — DBM timer bars (if player has DBM installed)
  3. **RaidNotice_AddMessage()** — Text flash fallback (always available)
- Use built-in sounds from whichever display system is active
- No custom frames or rendering in v1

### Timer Behavior
- 5-second pre-warning before each ability cast
- Auto-restart timers on cooldown (repeating cycle until combat ends)
- Warning text shows **ability name only** (no mob name prefix)
- All ability timers for a pack start simultaneously on pull; each uses its own `first_cast` offset to naturally stagger

### Combat Lifecycle
- **Auto-trigger** via `PLAYER_REGEN_DISABLED` when a pack is selected
- **Manual trigger** API also available (for console testing and Phase 3 UI)
- On combat end (`PLAYER_REGEN_ENABLED`): **auto-advance** to the next pack in the sequence
- Next combat start fires timers for the newly-advanced pack automatically
- On zone change (`PLAYER_ENTERING_WORLD`): **full reset** — sequence position returns to pack 1, all timers cancelled
- When all packs in the sequence are exhausted: enter **"end" state**, no more auto-triggers

### Pack Selection / Data Structure
- Change `PackDatabase` from key-value map to **ordered array** per dungeon (auto-advance increments an index)
- Pack key becomes a field inside each array entry
- Database order defines the sequence — no explicit sort field needed
- External callers (Phase 3 UI, console) can set the current pack to any index (manual re-selection)

### Claude's Discretion
- API shape for the engine (Scheduler object vs flat namespace functions)
- Internal timer implementation (C_Timer.After, ticker, OnUpdate)
- How to detect Blizzard Encounter Timer API availability vs falling back to DBM
- Exact DBM API integration approach

</decisions>

<specifics>
## Specific Ideas

- The addon should feel like a "data feed" to existing timer systems, not a standalone timer addon
- Auto-advance through packs mirrors the flow of a dungeon run — pull pack 1, auto-advance to pack 2, etc.
- Players re-select previous packs via the Phase 3 list UI (scrolling back), not through engine controls
- "End" state when all packs exhausted should be a clear signal (not silent)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Core.lua`: Event frame with ADDON_LOADED + PLAYER_ENTERING_WORLD handlers already registered
- `Data/WindrunnerSpire.lua`: Pack data file — needs restructuring from map to ordered array
- `ns.PackDatabase`: Shared namespace table, currently a map keyed by pack string
- `ns.db` (SavedVariables): Available for persisting state if needed

### Established Patterns
- `local addonName, ns = ...` namespace pattern for all files
- Event frame with RegisterEvent/UnregisterEvent pattern
- Data files populate `ns.PackDatabase` at load time (before ADDON_LOADED)

### Integration Points
- `PLAYER_ENTERING_WORLD` handler in Core.lua — currently a stub, will need zone-change reset logic
- Slash command `/tpw` stub — Phase 3 will use this
- New events needed: `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`
- TOC file needs new Lua files added for engine modules

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-warning-engine-and-combat-integration*
*Context gathered: 2026-03-14*
