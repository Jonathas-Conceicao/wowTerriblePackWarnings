# Phase 6: Nameplate Detection and Mob Lifecycle - Research

**Researched:** 2026-03-15
**Domain:** World of Warcraft addon API — nameplate polling, unit query functions, timer management
**Confidence:** HIGH

## Summary

This phase wires live nameplate data to the existing display and scheduling infrastructure. The core loop is simple: a 0.25s repeating ticker scans all visible nameplates, filters to hostile in-combat mobs, matches their class against pack ability entries, and drives per-mob icon spawn/cleanup entirely through changes in per-class counts between ticks.

All required WoW API functions (`C_NamePlate.GetNamePlates`, `UnitClass`, `UnitAffectingCombat`, `UnitCanAttack`) accept nameplate unit tokens and are fully verified by the existing NameplateSummary.lua reference implementation, which wraps volatile calls in `pcall` for safety. `C_Timer.NewTicker` is the correct repeating timer API — it returns a handle with `:Cancel()` and `:IsCancelled()` methods identical to the `C_Timer.NewTimer` handles already used by Scheduler.lua.

The most architecturally significant decision is where to introduce the new scanner. Given that CombatWatcher already owns the start/stop lifecycle and Scheduler.lua's current design (auto-start all timers on combat start) must be reworked, the cleanest split is a dedicated `Engine/NameplateScanner.lua` module. Scheduler.lua keeps the per-ability timer scheduling logic but loses the `Start` call that auto-launches everything; instead, NameplateScanner drives when individual ability timers are created by calling into Scheduler on first mob detection.

**Primary recommendation:** New `Engine/NameplateScanner.lua` with a `C_Timer.NewTicker(0.25, ...)` that owns mob-class count tracking and calls into a refactored Scheduler API (`Scheduler:StartAbility`, `Scheduler:StopAbility`) rather than `Scheduler:Start` which fires everything at once.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Periodic scan of `C_NamePlate.GetNamePlates()` every **0.25 seconds** during combat
- For each nameplate: check `UnitAffectingCombat(unit)` — only start timers for mobs actually in combat (ignore idle patrol mobs)
- Match mob's `UnitClass(unit)` against ability `mobClass` field from pack data
- When a matching mob enters combat → spawn independent timer icon via `IconDisplay.ShowIcon`
- Multiple mobs of same class = multiple independent timer squares
- Untimed abilities: show one static icon on first matching mob detection, regardless of count
- **No events** for death detection — purely gameloop-driven via the same 0.25s scan
- Each scan counts how many in-combat nameplates exist per class; count decrease → remove that many timer icons; count reaches 0 → clear all icons for that class's skills
- No NAME_PLATE_UNIT_REMOVED or combat log events — everything is poll-based
- Scanning starts when CombatWatcher enters "active" state (combat start)
- Scanning stops when CombatWatcher leaves "active" state (combat end / zone change)
- On combat end: clear all tracked mobs and icons (existing CombatWatcher:Reset flow handles this)

### Claude's Discretion
- Where the scanner module lives (new file vs extending CombatWatcher)
- How to track individual mob → timer mappings (table structure)
- Whether to use C_Timer.NewTicker for the 0.25s poll or OnUpdate
- How to coordinate with existing CombatWatcher state machine

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DETC-01 | Scan nameplates on combat start to detect which mob classes are in combat | C_NamePlate.GetNamePlates() + UnitClass() pattern confirmed in NameplateSummary.lua; scanner starts from CombatWatcher:OnCombatStart hook |
| DETC-02 | When a mob matching a skill's mobClass enters combat, start an independent timer instance | Count-increase logic per class triggers Scheduler:StartAbility for each new mob; barId generated per instance |
| DETC-03 | Multiple mobs of the same class create multiple independent timed squares | Per-class array of barIds tracked in scanner; each mob gets its own barId and IconDisplay slot |
| DETC-04 | Continue scanning nameplates during combat to detect newly-aggro'd mobs | C_Timer.NewTicker runs continuously until scanner:Stop(); count increases mid-combat spawn new instances |
| DISP-07 | When all mobs of a tracked skill's class die, clear all instances of that skill from display | Count-decrease logic removes one barId per dead mob; count=0 calls CancelIcon for all class instances |
</phase_requirements>

---

## Standard Stack

### Core APIs (all verified by NameplateSummary.lua reference)

| API | Returns | Purpose | Safety |
|-----|---------|---------|--------|
| `C_NamePlate.GetNamePlates()` | `NamePlateFrame[]` | All currently visible nameplates | Safe; returns empty table when none |
| `plate.namePlateUnitToken` | `string` e.g. `"nameplate1"` | Unit token for further queries | Field confirmed by Blizzard source |
| `UnitCanAttack("player", unit)` | `boolean` | Filter out friendly NPCs and players | Wrap in pcall per reference pattern |
| `UnitAffectingCombat(unit)` | `boolean` | True if mob is aggroed/in combat | Wrap in pcall per reference pattern |
| `UnitClass(unit)` | `localizedName, classBase, classId` | `classBase` is ALLCAPS token matching `mobClass` field | Wrap in pcall per reference pattern |
| `C_Timer.NewTicker(seconds, fn)` | `FunctionContainer` | Repeating timer; handle has `:Cancel()`, `:IsCancelled()` | Same interface as NewTimer already used |

### Supporting

| Component | Purpose |
|-----------|---------|
| `ns.IconDisplay.ShowIcon(key, spellID, ttsMsg, duration)` | Spawn timed icon for one mob instance |
| `ns.IconDisplay.ShowStaticIcon(key, spellID)` | Spawn untimed icon (one per ability, class-keyed) |
| `ns.IconDisplay.CancelIcon(key)` | Remove one icon slot |
| `ns.IconDisplay.CancelAll()` | Clear everything on combat end |
| `ns.Scheduler` (refactored) | Per-ability timer scheduling; called per-mob, not per-pack |

**No new library dependencies.** All needed functionality is in the WoW API and existing addon modules.

---

## Architecture Patterns

### Recommended Project Structure (additions only)

```
Engine/
├── CombatWatcher.lua   -- existing; add scanner start/stop calls
├── Scheduler.lua       -- existing; refactor Start → StartAbility / StopAbility
└── NameplateScanner.lua  -- NEW: 0.25s poll, count tracking, mob lifecycle
```

TOC entry: add `Engine\NameplateScanner.lua` after `Engine\Scheduler.lua` and before `Engine\CombatWatcher.lua` (scanner must be defined before CombatWatcher references it).

Actually, load order constraint: CombatWatcher calls into Scanner, so Scanner must be defined first. Insert before CombatWatcher in TOC.

### Pattern 1: Nameplate Iteration with pcall Safety

The reference script establishes the canonical pattern for iterating plates and querying volatile unit state:

```lua
-- Source: WeakerScripts/Samples/NameplateSummary.lua (verified working pattern)
local plates = C_NamePlate.GetNamePlates()
for _, plate in ipairs(plates) do
    local npUnit = plate.namePlateUnitToken  -- official field name
    if npUnit and UnitCanAttack("player", npUnit) then
        local inCombatOk, inCombat = pcall(UnitAffectingCombat, npUnit)
        if inCombatOk and inCombat then
            local classOk, localName, classBase = pcall(UnitClass, npUnit)
            if classOk and classBase then
                -- process mob
            end
        end
    end
end
```

**Critical note:** The reference script uses `plate.unitToken` — this appears to be the same field as `plate.namePlateUnitToken`. The Blizzard source code and wiki both confirm `namePlateUnitToken` as the authoritative field name. Use `plate.namePlateUnitToken` with a defensive fallback: `plate.namePlateUnitToken or plate.unitToken`.

### Pattern 2: Per-Class Count Table (mob lifecycle tracking)

```lua
-- Scanner internal state
local prevCounts = {}  -- classBase -> number (count from last tick)
local classBarIds = {} -- classBase -> { barId1, barId2, ... } (active timed icons)
local staticShown = {} -- classBase -> boolean (untimed icon already shown)

-- On each tick:
local newCounts = {}
for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
    -- ... filter and classify ...
    newCounts[classBase] = (newCounts[classBase] or 0) + 1
end

-- Reconcile increases (new mobs)
for classBase, count in pairs(newCounts) do
    local prev = prevCounts[classBase] or 0
    if count > prev then
        -- spawn (count - prev) new timer instances
    end
end

-- Reconcile decreases (dead mobs)
for classBase, prev in pairs(prevCounts) do
    local count = newCounts[classBase] or 0
    if count < prev then
        -- remove (prev - count) icons from classBarIds[classBase]
    end
end

prevCounts = newCounts
```

### Pattern 3: C_Timer.NewTicker for Poll Loop

```lua
-- Source: warcraft.wiki.gg/wiki/API_C_Timer.NewTimer (confirmed)
-- NewTicker is the repeating variant of NewTimer
local tickerHandle = nil

function NameplateScanner:Start(pack)
    activePack = pack
    tickerHandle = C_Timer.NewTicker(0.25, function()
        NameplateScanner:Tick()
    end)
end

function NameplateScanner:Stop()
    if tickerHandle and not tickerHandle:IsCancelled() then
        tickerHandle:Cancel()
    end
    tickerHandle = nil
    wipe(prevCounts)
    wipe(classBarIds)
    wipe(staticShown)
end
```

### Pattern 4: Scheduler Refactoring (StartAbility / StopAbility)

Current `Scheduler:Start(dungeonKey, packIndex)` auto-starts all timers immediately. Phase 6 replaces this with per-mob control:

```lua
-- New API in Scheduler.lua
function Scheduler:StartAbility(ability, barId)
    -- scheduleAbility(ability, barId) — same logic, explicit barId
end

function Scheduler:StopAbility(barId)
    -- cancel all C_Timer handles associated with barId
    -- call IconDisplay.CancelIcon(barId)
end
```

The existing `scheduleAbility` internal function already accepts `existingBarId` — `StartAbility` is essentially a public wrapper around it.

CombatWatcher's `ManualStart` path can remain for `/tpw start` command but should invoke the scanner instead of Scheduler directly.

### Key ID Convention

```lua
-- Timed ability instance: one per mob
local barId = "mob_" .. classBase .. "_" .. instanceNumber
-- e.g. "mob_PALADIN_1", "mob_PALADIN_2"

-- Untimed (static) ability: one per ability class
local staticId = "static_" .. ability.spellID
-- e.g. "static_1253686" (unchanged from current Scheduler pattern)
```

### Anti-Patterns to Avoid

- **Starting a new ticker without cancelling the old one:** Always cancel `tickerHandle` before creating a new one; `CombatWatcher:OnCombatStart` can fire if state is wrong and create duplicate polls.
- **Calling UnitClass/UnitAffectingCombat without pcall:** These can error if a nameplate disappears between `GetNamePlates()` and the query. The reference script wraps all three in `pcall`.
- **Using `plate.unitToken` as the only field access:** Blizzard source confirms `namePlateUnitToken` is canonical; use both as fallback.
- **Removing abilities from classBarIds while iterating it:** Build a list of IDs to remove, then remove after the loop.
- **Keeping Scheduler:Start as the entry point:** It fires all timers blindly. CombatWatcher:OnCombatStart must now call `NameplateScanner:Start(pack)` instead of `Scheduler:Start(...)`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Repeating 0.25s tick | OnUpdate frame script with manual elapsed tracking | `C_Timer.NewTicker(0.25, fn)` | NewTicker handles elapsed bookkeeping, cancellation, and re-entry safety |
| Icon slot management | Custom frame pool or table | `ns.IconDisplay.ShowIcon` / `CancelIcon` | Already built, handles layout, glow, TTS |
| Per-ability scheduling | Custom timer recursion | `scheduleAbility` (existing in Scheduler) | Already handles pre-warn timers, repeating cooldown, barId reuse |
| Class-to-mobClass matching | String normalization | `UnitClass()` second return value (`classBase`) | Returns the exact ALLCAPS token already stored in `ability.mobClass` — direct equality check |

---

## Common Pitfalls

### Pitfall 1: unitToken vs namePlateUnitToken Field Name
**What goes wrong:** Accessing `plate.unitToken` returns nil, causing all subsequent unit queries to silently no-op.
**Why it happens:** The reference NameplateSummary.lua uses `plate.unitToken` as a variable name that may have been set differently in that script's context, but Blizzard's official nameplate frames expose `namePlateUnitToken`.
**How to avoid:** `local npUnit = plate.namePlateUnitToken or plate.unitToken` — defensive fallback covers both.
**Warning signs:** Scanner runs but never spawns any icons; debug print of `npUnit` is nil.

### Pitfall 2: Stale Counts After Combat End
**What goes wrong:** `prevCounts` retains values from last combat; on next combat start, the first tick sees counts as "decreases from last time" and tries to cancel non-existent icons.
**Why it happens:** `NameplateScanner:Stop()` must wipe `prevCounts`, `classBarIds`, and `staticShown` — forgetting any of them causes state bleed.
**How to avoid:** `wipe(prevCounts); wipe(classBarIds); wipe(staticShown)` in `Stop()`, verified by checking all three tables are empty after `Stop`.
**Warning signs:** Icons unexpectedly disappear immediately at combat start of the second pack.

### Pitfall 3: Multiple Tickers Running Simultaneously
**What goes wrong:** If `NameplateScanner:Start()` is called twice (e.g. `ManualStart` + auto `OnCombatStart`), two tickers run in parallel and double-spawn icons.
**Why it happens:** CombatWatcher's `ManualStart` path currently calls `Scheduler:Start` directly and sets state to "active", which means subsequent `OnCombatStart` is blocked by the `state ~= "ready"` guard — but if scanner is called from both paths without the same guard, it can slip through.
**How to avoid:** Guard `NameplateScanner:Start()` with a `if tickerHandle then return end` early exit.
**Warning signs:** Two icons spawn for one mob of a class; count tracking goes off by multiples of 2.

### Pitfall 4: Idle Patrol Mobs Triggering Timer Spawns
**What goes wrong:** A mob in the same room but not yet aggroed (idle patrol) matches the class filter and spawns a timer before combat begins properly.
**Why it happens:** `UnitCanAttack("player", npUnit)` returns true for hostile mobs even when they're not in combat. The `UnitAffectingCombat` check must come second and is the actual gate.
**How to avoid:** Always check both: `UnitCanAttack` (hostile?) AND `UnitAffectingCombat` (actually aggroed?). The reference script models this correctly.
**Warning signs:** Timers start before the player pulls, or for mobs in adjacent rooms.

### Pitfall 5: Scheduler:Stop Called on Combat End Clears IconDisplay Before Scanner Cleanup
**What goes wrong:** CombatWatcher:OnCombatEnd calls `Scheduler:Stop()` which calls `IconDisplay.CancelAll()`. If scanner's `Stop()` is called after this, it tries to `CancelIcon` keys that no longer exist in IconDisplay — which is harmless but leaves `classBarIds` dirty.
**Why it happens:** Order of operations: scanner should stop first (cancel ticker, wipe state), then Scheduler stops (cancel C_Timer handles, call CancelAll).
**How to avoid:** In `CombatWatcher:OnCombatEnd`, call `NameplateScanner:Stop()` before `Scheduler:Stop()`.

---

## Code Examples

### Full Scanner Tick Function
```lua
-- Source: derived from NameplateSummary.lua pattern + phase decisions
function NameplateScanner:Tick()
    if not activePack then return end

    local newCounts = {}  -- classBase -> count of in-combat hostile mobs this tick

    local plates = C_NamePlate.GetNamePlates()
    for _, plate in ipairs(plates) do
        local npUnit = plate.namePlateUnitToken or plate.unitToken
        if npUnit and UnitCanAttack("player", npUnit) then
            local inCombatOk, inCombat = pcall(UnitAffectingCombat, npUnit)
            if inCombatOk and inCombat then
                local classOk, _, classBase = pcall(UnitClass, npUnit)
                if classOk and classBase then
                    newCounts[classBase] = (newCounts[classBase] or 0) + 1
                end
            end
        end
    end

    -- Detect increases: new mob entered combat
    for classBase, count in pairs(newCounts) do
        local prev = prevCounts[classBase] or 0
        if count > prev then
            local delta = count - prev
            NameplateScanner:OnMobsAdded(classBase, delta)
        end
    end

    -- Detect decreases: mobs died
    for classBase, prev in pairs(prevCounts) do
        local count = newCounts[classBase] or 0
        if count < prev then
            local delta = prev - count
            NameplateScanner:OnMobsRemoved(classBase, delta)
        end
    end

    prevCounts = newCounts
end
```

### OnMobsAdded — Spawn Icons
```lua
function NameplateScanner:OnMobsAdded(classBase, delta)
    classBarIds[classBase] = classBarIds[classBase] or {}
    for _, ability in ipairs(activePack.abilities) do
        if ability.mobClass == classBase then
            if ability.cooldown then
                -- Timed: one icon per mob instance
                for i = 1, delta do
                    timerCounter = timerCounter + 1
                    local barId = "mob_" .. classBase .. "_" .. timerCounter
                    table.insert(classBarIds[classBase], barId)
                    ns.Scheduler:StartAbility(ability, barId)
                end
            else
                -- Untimed: one static icon per ability, regardless of mob count
                if not staticShown[ability.spellID] then
                    staticShown[ability.spellID] = true
                    ns.IconDisplay.ShowStaticIcon("static_" .. ability.spellID, ability.spellID)
                end
            end
        end
    end
end
```

### OnMobsRemoved — Clean Up Icons
```lua
function NameplateScanner:OnMobsRemoved(classBase, delta)
    local ids = classBarIds[classBase]
    if not ids then return end

    for i = 1, delta do
        local barId = table.remove(ids)  -- remove from end
        if barId then
            ns.Scheduler:StopAbility(barId)
        end
    end

    -- If all mobs of this class gone, also clear static icons for this class
    if #ids == 0 then
        for _, ability in ipairs(activePack.abilities) do
            if ability.mobClass == classBase and not ability.cooldown then
                local staticId = "static_" .. ability.spellID
                ns.IconDisplay.CancelIcon(staticId)
                staticShown[ability.spellID] = nil
            end
        end
        classBarIds[classBase] = nil
    end
end
```

### Scheduler:StartAbility and StopAbility (refactored)
```lua
-- Source: extends existing scheduleAbility internal function in Scheduler.lua
function Scheduler:StartAbility(ability, barId)
    -- scheduleAbility already accepts existingBarId to reuse a slot
    scheduleAbility(ability, barId)
end

function Scheduler:StopAbility(barId)
    -- Cancel all timers registered under this barId
    -- Since activeTimers is a flat list (no per-barId index), simplest approach:
    -- Mark barId as cancelled in a set, check in timer callbacks
    -- OR: maintain a per-barId timer list (more surgical)
    ns.IconDisplay.CancelIcon(barId)
    -- Timer callbacks already guard with combatActive[1] check;
    -- after CancelIcon the barId is gone from display regardless
end
```

**Note on Scheduler:StopAbility and timer orphaning:** The current Scheduler design stores all timers in a flat `activeTimers` list — there is no per-barId index. When a single mob dies mid-combat, we need to cancel only that mob's pre-warn and cast timers without cancelling all other mobs' timers. This requires either:
- (a) Per-barId timer tracking: `barTimers[barId] = { preHandle, castHandle }` — the cleanest approach.
- (b) Let orphaned timers fire but check if the barId's icon still exists in IconDisplay before acting — simpler but wastes timer callbacks.

Recommendation: option (a), tracked per-barId in Scheduler. The `scheduleAbility` function stores handles in `activeTimers` today; add a parallel `barTimers[barId] = {}` table and push handles there too.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Scheduler:Start fires all timers at combat start | Scanner controls per-mob timer spawning | Phase 6 | Timers now tied to actual mob presence, not just pack selection |
| No nameplate scanning | C_NamePlate.GetNamePlates 0.25s poll | Phase 6 | Mob death detection without event listeners |
| Static icon shown at pack start (Scheduler) | Static icon shown on first mob detection (Scanner) | Phase 6 | Static icons only appear if the matching mob class is actually present |

---

## Open Questions

1. **`plate.unitToken` vs `plate.namePlateUnitToken` in practice**
   - What we know: Blizzard source and wiki confirm `namePlateUnitToken`; NameplateSummary.lua uses `plate.unitToken` as a local but the actual field read may work both ways or there's a metatable alias.
   - What's unclear: Whether older API versions exposed `unitToken` as a direct field alias.
   - Recommendation: Use `plate.namePlateUnitToken or plate.unitToken` defensive read. If either works in-game, behavior is correct; if `namePlateUnitToken` is nil and `unitToken` also nil, the `if npUnit` guard skips silently.

2. **ManualStart path compatibility**
   - What we know: `CombatWatcher:ManualStart` currently calls `Scheduler:Start` directly, bypassing the scanner.
   - What's unclear: Whether `/tpw start` should invoke the scanner (live detection) or the old Scheduler:Start (immediate all-timers).
   - Recommendation: Phase 6 should update `ManualStart` to call `NameplateScanner:Start(pack)` for consistency, since nameplate-driven spawning is now the canonical path.

3. **Per-barId timer cancellation complexity**
   - What we know: Current Scheduler uses a flat activeTimers list; per-mob stop requires either per-barId tracking or accepting orphaned timers.
   - What's unclear: How often mid-combat mob deaths occur before a full pack wipe (which triggers CombatEnd + CancelAll anyway).
   - Recommendation: Implement per-barId tracking (`barTimers` table in Scheduler) for correctness. For Mythic+ this is important since pulls can partially die before the player dies/resets.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None detected — no test config or test directory in repo |
| Config file | None — Wave 0 must create |
| Quick run command | Manual in-game testing (WoW addon; no Lua unit test framework in project) |
| Full suite command | Manual in-game testing |

**Note:** This is a WoW addon. Standard Lua unit test frameworks (busted, etc.) are not integrated. Validation is in-game. No Wave 0 test infrastructure gaps to create — the testing approach is manual observation in the WoW client.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Validation Method |
|--------|----------|-----------|-------------------|
| DETC-01 | Scan nameplates on combat start | manual | Pull a pack; icons spawn within 0.25s |
| DETC-02 | Mob matching mobClass triggers timer instance | manual | PALADIN mob in pack → Spellguard's Protection icon appears |
| DETC-03 | Multiple same-class mobs = multiple timed squares | manual | Two PALADIN mobs → two icon squares |
| DETC-04 | Continue scanning for newly-aggro'd mobs | manual | Add-pull a second PALADIN mid-combat → third icon appears |
| DISP-07 | All mobs of class die → icons clear | manual | Kill all PALADINs → their icons disappear; WARRIOR static icon remains |

### Wave 0 Gaps

None — no test infrastructure to create. In-game manual verification is the project's established validation approach.

---

## Sources

### Primary (HIGH confidence)
- `WeakerScripts/Samples/NameplateSummary.lua` — direct working code showing `C_NamePlate.GetNamePlates()` iteration, `UnitCanAttack`, `UnitAffectingCombat`, `UnitClass` with pcall guards on nameplate unit tokens
- [warcraft.wiki.gg — C_NamePlate.GetNamePlates](https://warcraft.wiki.gg/wiki/API_C_NamePlate.GetNamePlates) — official return structure, `namePlateUnitToken` field confirmed
- [warcraft.wiki.gg — C_Timer.NewTimer (includes NewTicker)](https://warcraft.wiki.gg/wiki/API_C_Timer.NewTimer) — `NewTicker(seconds, fn)` returns handle with `:Cancel()`, `:IsCancelled()`
- [Blizzard Interface Code — Blizzard_NamePlates.lua](https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlates.lua) — `namePlateUnitToken` as canonical field name in Blizzard source

### Secondary (MEDIUM confidence)
- [warcraft.wiki.gg — UnitToken](https://warcraft.wiki.gg/wiki/UnitToken) — nameplate tokens (nameplate1..40) confirmed as valid UnitToken format accepted by unit query functions
- [warcraft.wiki.gg — UnitAffectingCombat](https://warcraft.wiki.gg/wiki/API_UnitAffectingCombat) — accepts UnitToken parameter; returns true if aggroed
- [warcraft.wiki.gg — UnitClass](https://warcraft.wiki.gg/wiki/API_UnitClass) — returns `(localizedName, classFilename, classId)` where classFilename is ALLCAPS token

### Tertiary (LOW confidence — in-game verification recommended)
- `plate.unitToken` field alias: NameplateSummary.lua uses this but official name is `namePlateUnitToken`. Both may be accessible; use defensive fallback.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs verified by working reference code and official wiki
- Architecture: HIGH — new module pattern is straightforward extension of existing CombatWatcher/Scheduler design
- Pitfalls: HIGH — unitToken field name discrepancy, stale count tables, ticker duplication all identified from code inspection
- Scheduler refactoring: MEDIUM — per-barId timer cancellation design requires judgment; two valid options documented

**Research date:** 2026-03-15
**Valid until:** 2026-09-15 (stable WoW addon API — changes only at major expansions)
