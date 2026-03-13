# Architecture Research

**Domain:** World of Warcraft Midnight (12.0) addon — dungeon trash pack warning system
**Researched:** 2026-03-13
**Confidence:** MEDIUM — core WoW addon patterns are HIGH confidence; Midnight API restriction details for specific dungeon-context behavior are LOW confidence due to limited public documentation

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────┐
│                       TerriblePackWarnings                    │
├──────────────────────────────────────────────────────────────┤
│  ENTRY POINT                                                  │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  Core.lua — addon init, namespace, TOC manifest      │    │
│  └──────────────┬───────────────────────────────────────┘    │
│                 │ registers & wires                           │
├─────────────────┼────────────────────────────────────────────┤
│  DATA LAYER     │                                             │
│  ┌──────────────▼──────────────┐                             │
│  │  Data/PackDatabase.lua       │  Static mob/ability tables  │
│  │  Data/DungeonIndex.lua       │  Pack groupings by area     │
│  └──────────────┬──────────────┘                             │
│                 │ read-only                                   │
├─────────────────┼────────────────────────────────────────────┤
│  WARNING ENGINE │                                             │
│  ┌──────────────▼──────────────┐                             │
│  │  Engine/WarningScheduler.lua │  Manages C_Timer handles   │
│  │  Engine/BossWarnings.lua     │  Wraps C_EncounterEvents   │
│  └──────────────┬──────────────┘                             │
│                 │ triggers / cancels                         │
├─────────────────┼────────────────────────────────────────────┤
│  EVENT HANDLER  │                                             │
│  ┌──────────────▼──────────────┐                             │
│  │  Events/CombatEvents.lua     │  PLAYER_REGEN_DISABLED/    │
│  │                              │  PLAYER_REGEN_ENABLED       │
│  └──────────────┬──────────────┘                             │
│                 │                                             │
├─────────────────┼────────────────────────────────────────────┤
│  UI LAYER       │                                             │
│  ┌──────────────▼──────────────┐                             │
│  │  UI/PackSelectFrame.lua      │  List menu, pack buttons    │
│  │  UI/PackSelectFrame.xml      │  Frame XML definition       │
│  └─────────────────────────────┘                             │
└──────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Core.lua | Addon namespace, TOC entry point, wires components together | Global table `TPW = {}`, ADDON_LOADED handler |
| Data/PackDatabase.lua | Static Lua tables: mob abilities, cast times, cooldowns | Plain Lua tables, no runtime modification |
| Data/DungeonIndex.lua | Pack groupings by dungeon area, display names, ordering | Plain Lua tables referencing PackDatabase keys |
| Engine/WarningScheduler.lua | Schedules and cancels C_Timer handles per active pack | C_Timer.NewTimer / C_Timer.NewTicker, timer handle table |
| Engine/BossWarnings.lua | Issues warning display via C_EncounterEvents API | C_EncounterEvents.SetEventColor, SetEventSound |
| Events/CombatEvents.lua | Detects combat start/end, auto-starts/cancels timers | Frame:RegisterEvent("PLAYER_REGEN_DISABLED/ENABLED") |
| UI/PackSelectFrame.lua | Renders pack list, handles user selection, opens/closes | CreateFrame, ScrollFrame, Button widgets |
| UI/PackSelectFrame.xml | Defines frame hierarchy, anchors, sizes | XML <Frame>, <ScrollFrame>, <Button> elements |

## Recommended Project Structure

```
TerriblePackWarnings/
├── TerriblePackWarnings.toc      # Manifest: Interface 120001, file load order
├── Core.lua                      # Namespace, ADDON_LOADED wiring
├── Data/
│   ├── PackDatabase.lua          # All mob abilities: { spellName, castTime, cooldown }
│   └── DungeonIndex.lua          # Dungeon areas -> pack lists -> PackDatabase refs
├── Engine/
│   ├── WarningScheduler.lua      # C_Timer management, active timer state
│   └── BossWarnings.lua          # C_EncounterEvents integration wrapper
├── Events/
│   └── CombatEvents.lua          # PLAYER_REGEN_DISABLED/ENABLED handler
└── UI/
    ├── PackSelectFrame.lua        # Frame logic, click handlers, state
    └── PackSelectFrame.xml        # Frame XML layout definition
```

### Structure Rationale

- **Data/ separate from Engine/:** Pack data is static and will grow with each dungeon. Isolating it means adding a new dungeon only requires adding files in Data/ — no engine changes.
- **Engine/ separate from Events/:** The scheduler does not need to know about combat events. Events/ calls into Engine/ but not vice versa. This makes the scheduler testable in isolation (manually call start/stop from UI without combat).
- **UI/ separate from Engine/:** The UI triggers the scheduler but does not own timer state. If the warning engine needs to change (different API), the UI doesn't change.
- **XML for frame definition, Lua for logic:** WoW convention. XML defines structure and anchors; Lua handles all dynamic behavior. Pure-Lua frame creation is also valid but XML keeps layout declarative.
- **Load order in TOC:** Core.lua first (namespace), then Data/, then Engine/, then Events/, then UI/. Each layer depends only on layers above it in this list.

## Architectural Patterns

### Pattern 1: Addon Namespace Table

**What:** All addon state lives in a single global table (`TPW = TPW or {}`). Submodules attach to this table rather than using separate globals.
**When to use:** Always — this is the WoW addon convention. Prevents global namespace pollution and makes inter-module communication explicit.
**Trade-offs:** Simple and conventional. No downside for a single addon.

**Example:**
```lua
-- Core.lua (loaded first)
TPW = TPW or {}
TPW.version = "1.0.0"

-- Engine/WarningScheduler.lua (loaded later)
TPW.Scheduler = {}

function TPW.Scheduler:Start(packKey)
  -- ...
end
```

### Pattern 2: Event Frame Dispatcher

**What:** A single hidden Frame registers for all needed events. OnEvent dispatches to handler functions by event name.
**When to use:** Any time you need WoW game events. The standard pattern since WoW 1.x.
**Trade-offs:** Clean dispatch table. One frame handles all events cleanly.

**Example:**
```lua
-- Events/CombatEvents.lua
local frame = CreateFrame("Frame")
local handlers = {}

handlers["PLAYER_REGEN_DISABLED"] = function()
  -- Player entered combat: auto-start timers if pack is selected
  if TPW.State.selectedPack then
    TPW.Scheduler:Start(TPW.State.selectedPack)
  end
end

handlers["PLAYER_REGEN_ENABLED"] = function()
  -- Player left combat: cancel all active timers
  TPW.Scheduler:CancelAll()
end

frame:SetScript("OnEvent", function(self, event, ...)
  if handlers[event] then handlers[event](...) end
end)

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
```

### Pattern 3: Timer Handle Table for Cancellation

**What:** C_Timer.NewTimer returns a handle object. Store all active handles in a table so they can be cancelled as a group when combat ends or the player changes pack selection.
**When to use:** Any time you schedule multiple timers that may need to be cancelled early (pack swap, wipe, combat end).
**Trade-offs:** Requires discipline to clear the table on cancel. Simple and reliable.

**Example:**
```lua
-- Engine/WarningScheduler.lua
TPW.Scheduler = { activeTimers = {} }

function TPW.Scheduler:Start(packKey)
  local abilities = TPW.PackDatabase[packKey].abilities
  for _, ability in ipairs(abilities) do
    local handle = C_Timer.NewTimer(ability.firstCastTime, function()
      TPW.BossWarnings:Show(ability)
    end)
    table.insert(self.activeTimers, handle)
  end
end

function TPW.Scheduler:CancelAll()
  for _, handle in ipairs(self.activeTimers) do
    if not handle:IsCancelled() then
      handle:Cancel()
    end
  end
  self.activeTimers = {}
end
```

## Data Flow

### Primary Flow: Pack Selection to Active Warnings

```
[Player opens UI]
    ↓
PackSelectFrame renders DungeonIndex areas + packs
    ↓
[Player clicks a pack]
    ↓
PackSelectFrame → TPW.State.selectedPack = packKey
    ↓
PackSelectFrame → TPW.Scheduler:CancelAll()  (clear previous pack)
    ↓ (optional: auto-start if already in combat)
    ↓
[Player pulls — PLAYER_REGEN_DISABLED fires]
    ↓
CombatEvents handler → TPW.Scheduler:Start(selectedPack)
    ↓
WarningScheduler reads PackDatabase[selectedPack].abilities
    ↓
For each ability: C_Timer.NewTimer(firstCastTime, callback)
    ↓
Timer fires → BossWarnings:Show(ability)
    ↓
C_EncounterEvents.SetEventColor / C_EncounterEvents.SetEventSound
    ↓
[Blizzard Boss Warnings UI displays the alert]
```

### Combat End Flow

```
[Combat ends — PLAYER_REGEN_ENABLED fires]
    ↓
CombatEvents handler → TPW.Scheduler:CancelAll()
    ↓
All pending C_Timer handles cancelled, activeTimers = {}
```

### State

```
TPW.State = {
  selectedPack = nil,     -- string key into PackDatabase, or nil
  inCombat     = false,   -- mirrors PLAYER_REGEN_DISABLED/ENABLED
}
```

State is minimal and lives in Core.lua. No SavedVariables needed for v1 (pack selection is ephemeral per session, not persisted).

### Key Data Flows

1. **Pack selection to timer arm:** UI writes to TPW.State, Scheduler reads PackDatabase, schedules C_Timers.
2. **Combat start to timer fire:** PLAYER_REGEN_DISABLED event → Scheduler:Start() → timers running.
3. **Combat end / pack swap to timer cancel:** PLAYER_REGEN_ENABLED event or new pack selection → Scheduler:CancelAll().
4. **Timer expiry to player display:** C_Timer callback → BossWarnings wrapper → C_EncounterEvents API → Blizzard native Boss Warnings UI.

## Scaling Considerations

This addon has no server-side component and no network traffic. "Scaling" here means data volume and feature scope.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 1 dungeon (v1) | Single PackDatabase.lua file, no partitioning needed |
| 8 dungeons (season pool) | Split Data/ into one file per dungeon, DungeonIndex.lua aggregates all |
| Full expansion pool (20+ dungeons) | LoadOnDemand: split into one sub-addon per dungeon, main addon loads only current dungeon's data |

### Scaling Priorities

1. **First bottleneck:** Data file size. All pack data in one file becomes unwieldy past ~3 dungeons. Fix: one file per dungeon in Data/.
2. **Second bottleneck:** Timer complexity if multi-pack pulls are supported. Fix: Scheduler handles a list of active packs, not just one. Defer to future milestone.

## Anti-Patterns

### Anti-Pattern 1: Polling in OnUpdate

**What people do:** Register an OnUpdate script on a frame to check combat state or timer state every frame.
**Why it's wrong:** OnUpdate fires every rendered frame (~60-144 times/second). Checking state this way wastes CPU and can cause frame drops. C_Timer and RegisterEvent exist specifically to avoid this.
**Do this instead:** Use C_Timer for delays. Use RegisterEvent("PLAYER_REGEN_DISABLED") for combat detection. Never poll what you can subscribe to.

### Anti-Pattern 2: One Global Per Module

**What people do:** `TPWScheduler = {}`, `TPWDatabase = {}`, `TPWFrame = {}` as separate globals.
**Why it's wrong:** WoW's global namespace is shared across all addons. Multiple top-level globals increase collision risk and pollute the environment.
**Do this instead:** One top-level table (`TPW = {}`), all modules attach as subtables (`TPW.Scheduler`, `TPW.PackDatabase`).

### Anti-Pattern 3: Hardcoding Data in Engine or UI Files

**What people do:** Put mob ability timers inline in the scheduler or directly in the UI click handler.
**Why it's wrong:** Adding a new dungeon requires touching engine/UI code. Data and logic become coupled and the addon becomes unmaintainable.
**Do this instead:** All ability data lives exclusively in Data/. Engine and UI reference it by key. New dungeon = new data file only.

### Anti-Pattern 4: Using C_Timer.NewTicker for One-Shot Warnings

**What people do:** Use C_Timer.NewTicker (repeating) for a warning that only needs to fire once.
**Why it's wrong:** A ticker that isn't cancelled keeps firing indefinitely, spamming warnings after the timer expires.
**Do this instead:** Use C_Timer.NewTimer for one-shot warnings. Use C_Timer.NewTicker only if you need recurring reminders (e.g., "this ability is on a 20-second cooldown, repeat"). Store every handle for cancellation.

### Anti-Pattern 5: Assuming C_EncounterEvents Is Sufficient Without Fallback

**What people do:** Rely solely on C_EncounterEvents for warning display without testing if the API surfaces correctly in dungeon instances.
**Why it's wrong:** Midnight API documentation for C_EncounterEvents in dungeon (non-raid) contexts is incomplete as of 2026-03-13. The API was designed primarily for raid encounters. It may behave differently or require encounter IDs that dungeon trash packs lack.
**Do this instead:** Build the warning display as an abstraction layer (BossWarnings.lua). If C_EncounterEvents doesn't work for dungeon trash, the fallback is a simple custom UIParent text frame. Only this one module needs to change.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Blizzard Boss Warnings UI | C_EncounterEvents.SetEventColor, C_EncounterEvents.SetEventSound | LOW confidence this works for dungeon trash — needs empirical validation on first boot in a dungeon instance |
| Blizzard native combat events | Frame:RegisterEvent("PLAYER_REGEN_DISABLED/ENABLED") | HIGH confidence — confirmed available in Midnight 12.0.1 |
| C_Timer | C_Timer.NewTimer, C_Timer.NewTicker | HIGH confidence — confirmed available in Midnight 12.0.1, present since patch 6.0.2 |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| UI → Engine | Direct Lua function call: TPW.Scheduler:Start(packKey) | UI does not own timer state |
| Engine → Data | Direct table read: TPW.PackDatabase[packKey] | Data is read-only; engine never writes to it |
| Events → Engine | Direct Lua function call: TPW.Scheduler:CancelAll() | Events module has no UI dependency |
| Engine → BossWarnings | Direct Lua function call: TPW.BossWarnings:Show(ability) | BossWarnings is a thin wrapper — easy to swap |

## Build Order Implications

Components must be built in dependency order. Lower layers have no upstream dependencies and can be developed and tested first.

1. **Data layer first** — PackDatabase.lua and DungeonIndex.lua are pure Lua tables with no dependencies. Build and populate this first. Validate data shape before anything else exists.
2. **Warning engine second** — WarningScheduler.lua depends on PackDatabase shape. BossWarnings.lua needs empirical API validation (boot the game and test C_EncounterEvents in a dungeon). Build the scheduler with a stub display function initially.
3. **Event handler third** — CombatEvents.lua is a thin wiring layer that calls into the already-built Scheduler. Build after Scheduler is proven.
4. **UI last** — PackSelectFrame depends on DungeonIndex (to render pack lists) and Scheduler (to arm timers on selection). Build after data and engine are stable.

This order means Phase 1 (data) and Phase 2 (engine) can be validated via `/run` console commands without any UI built. Phase 3 (events) and Phase 4 (UI) layer on top of a working core.

## Sources

- [Patch 12.0.0/API changes — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)
- [Patch 12.0.0/Planned API changes — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes)
- [PLAYER_REGEN_DISABLED — Warcraft Wiki](https://warcraft.wiki.gg/wiki/PLAYER_REGEN_DISABLED) — confirmed available in Midnight 12.0.1
- [API C_Timer.After — Warcraft Wiki](https://warcraft.wiki.gg/wiki/API_C_Timer.After) — confirmed available in Midnight 12.0.1
- [Lua API Changes for Midnight Launch — Wowhead](https://www.wowhead.com/news/addon-changes-for-midnight-launch-ending-soon-with-release-candidate-coming-380133) — C_EncounterEvents namespace confirmed added
- [TOC format — Warcraft Wiki](https://warcraft.wiki.gg/wiki/TOC_format) — Interface version 120001 for Midnight
- [Handling events — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Handling_events) — event frame pattern
- [WoW Midnight 12.0.1 Addon Changes — ssegold.com](https://www.ssegold.com/wow-midnight-12-0-1-addon-changes) — boss mod API additions
- [Combat Addons in Midnight — kaylriene.com Part 1](https://kaylriene.com/2025/10/03/wow-midnights-addon-combat-and-design-changes-part-1-api-anarchy-and-the-dark-black-box/) — restriction context
- [Combat Philosophy — Blizzard official](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight)

---
*Architecture research for: WoW Midnight dungeon pack warning addon (TerriblePackWarnings)*
*Researched: 2026-03-13*
