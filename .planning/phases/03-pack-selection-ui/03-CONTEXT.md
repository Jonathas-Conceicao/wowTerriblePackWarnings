# Phase 3: Pack Selection UI - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

In-game window where players browse packs grouped by dungeon, select one, see which pack is active, and enter combat to trigger timers -- all without console commands. No custom timer/bar UI (addon is a data provider). Plain Lua + XML, no libraries.

</domain>

<decisions>
## Implementation Decisions

### Window & Layout
- Medium dialog size (~300x400px), standard WoW panel look
- Accordion-style sections: dungeon names as collapsible headers, packs listed underneath
- Each pack row shows **name only** (no mob count or mob names)
- Window is **movable**, position **saved in SavedVariables** across sessions
- Standard title bar with addon name and close button

### Selection & Highlighting
- Selected pack gets a **border + icon** (glowing border and/or checkmark)
- Pack rows show **combat state**: active pack has a "fighting" indicator, completed packs show a checkmark
- Clicking any pack re-selects it (including completed packs -- for wipe recovery)
- Selection **persists** when window is closed/reopened, clears on zone change (existing Reset behavior)

### Pull Trigger Flow
- **No pull button** -- selecting a pack sets it as active, timers auto-start on combat (PLAYER_REGEN_DISABLED)
- Window **stays open during combat** so player can see active pack and re-select if needed
- Clicking a pack under a different dungeon requires **clicking the dungeon header first** (expand accordion), then clicking the pack
- Pack list **live-updates** when auto-advance moves to next pack on combat end

### Window Access
- `/tpw` with no arguments **toggles** the window (open if closed, close if open)
- Existing subcommands (`select`, `start`, `stop`, `status`) **kept alongside UI** for power users and debugging
- **Escape closes** the window (register with UISpecialFrames)

### Claude's Discretion
- Exact frame dimensions and backdrop style
- Accordion expand/collapse animation (or instant toggle)
- Combat state icon choices (skull, swords, checkmark, etc.)
- ScrollFrame implementation details
- How to refresh the pack list when auto-advance fires (callback, event, polling)

</decisions>

<specifics>
## Specific Ideas

- Accordion pattern similar to DBM options panel for dungeon grouping
- Window should feel like a standard WoW panel (talent window, quest log) -- not a custom/flashy addon UI
- Live-updating highlight on auto-advance means the UI reflects dungeon progress in real-time without player interaction

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CombatWatcher:SelectDungeon(key)`: Sets dungeon + pack index, transitions to "ready" state
- `CombatWatcher:ManualStart(packIndex)`: Starts timers for specific pack index
- `CombatWatcher:GetState()`: Returns state, selectedDungeon, currentPackIndex
- `ns.PackDatabase`: Ordered array per dungeon key with displayName, mobs, abilities
- `ns.db` (SavedVariables): Available for persisting window position
- Slash command `/tpw` already registered in Core.lua

### Established Patterns
- `local addonName, ns = ...` namespace for all files
- Event frame with RegisterEvent/UnregisterEvent in Core.lua
- Data files populate ns.PackDatabase at load time
- Colored print messages with `|cff00ccff` prefix

### Integration Points
- Core.lua slash command handler needs update: bare `/tpw` should toggle window instead of showing help
- CombatWatcher state machine drives UI updates (state changes = UI refresh)
- PLAYER_ENTERING_WORLD already fires Reset() which clears selection -- UI must reflect this
- TOC file needs new Lua/XML files for UI module

</code_context>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 03-pack-selection-ui*
*Context gathered: 2026-03-15*
