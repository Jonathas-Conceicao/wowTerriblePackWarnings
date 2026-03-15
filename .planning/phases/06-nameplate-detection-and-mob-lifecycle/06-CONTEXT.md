# Phase 6: Nameplate Detection and Mob Lifecycle - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire nameplate scanning to detect mob classes during combat, spawn per-mob timer instances via IconDisplay, and clean up icons when mobs die. This phase connects the data schema (Phase 4) and display system (Phase 5) to live combat via nameplate detection.

</domain>

<decisions>
## Implementation Decisions

### Mob Detection
- **Periodic scan** of `C_NamePlate.GetNamePlates()` every **0.5 seconds** during combat
- For each nameplate: check `UnitAffectingCombat(unit)` — only start timers for mobs actually in combat (ignore idle patrol mobs)
- Match mob's `UnitClass(unit)` against ability `mobClass` field from pack data
- When a matching mob enters combat → spawn independent timer icon via `IconDisplay.ShowIcon`
- Multiple mobs of same class = multiple independent timer squares
- Untimed abilities: show one static icon on first matching mob detection, regardless of count

### Mob Death Detection
- Use **NAME_PLATE_UNIT_REMOVED** event to detect mob deaths
- Nameplate disappearance = assume mob is dead (combat log events are blocked/secret values in Midnight API)
- If a nameplate disappears because mob runs out of range, still treat as "dead" — accept this trade-off
- **Count-based clearing**: track how many nameplates of each class currently exist. When count reaches 0, clear all icons for that class's skills.

### Scan Lifecycle
- Scanning starts when CombatWatcher enters "active" state (combat start)
- Scanning stops when CombatWatcher leaves "active" state (combat end / zone change)
- On combat end: clear all tracked mobs and icons (existing CombatWatcher:Reset flow handles this)

### Claude's Discretion
- Where the scanner module lives (new file vs extending CombatWatcher)
- How to track individual mob → timer mappings (table structure)
- Whether to use C_Timer.NewTicker for the 0.5s poll or OnUpdate
- How to coordinate with existing CombatWatcher state machine

</decisions>

<specifics>
## Specific Ideas

- The NameplateSummary.lua reference script (C:\Users\jonat\Repositories\WeakerScripts\Samples\NameplateSummary.lua) shows the pattern: iterate plates, check UnitCanAttack, check UnitAffectingCombat, read UnitClass
- The 0.5s poll rate should be fast enough to catch new mobs joining combat without noticeable delay

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Engine/CombatWatcher.lua`: State machine with OnCombatStart/OnCombatEnd — scanner hooks here
- `Display/IconDisplay.lua`: ShowIcon(id, spellID, duration), ShowStaticIcon(id, spellID), CancelIcon(id), CancelAll()
- `Engine/Scheduler.lua`: Currently iterates pack.abilities and calls IconDisplay — scanner replaces this with per-mob spawning

### Established Patterns
- `UnitAffectingCombat(unit)` from NameplateSummary.lua — checks if a nameplate unit is in combat
- `UnitClass(unit)` returns `(localizedName, classBase)` — classBase is ALLCAPS token matching data schema
- `C_NamePlate.GetNamePlates()` returns array of nameplate objects with `.unitToken`

### Integration Points
- CombatWatcher:OnCombatStart → start scanning
- CombatWatcher:OnCombatEnd → stop scanning, clear all
- NAME_PLATE_UNIT_REMOVED event → decrement class count, clear icons if count reaches 0
- Scheduler.lua → needs rework to not auto-start all timers; scanner controls when individual timers spawn

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-nameplate-detection-and-mob-lifecycle*
*Context gathered: 2026-03-15*
