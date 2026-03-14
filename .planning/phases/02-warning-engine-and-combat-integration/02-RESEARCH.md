# Phase 2: Warning Engine and Combat Integration - Research

**Researched:** 2026-03-14
**Domain:** WoW Addon Lua — C_Timer scheduling, warning display APIs, combat event wiring, Midnight API restrictions
**Confidence:** MEDIUM (core timer/event APIs HIGH; Midnight display restrictions LOW due to evolving/unclear policy)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Addon is a **data provider only** — it does NOT implement timers, bars, or alert UI
- Push ability data into **Blizzard's Encounter Timer system** (native bars/timeline) as primary display
- **DBM API integration** as fallback if Blizzard's API doesn't support addon-injected trash timers
- Use built-in sounds from whichever display system is active
- No custom frames or rendering in v1
- 5-second pre-warning before each ability cast
- Auto-restart timers on cooldown (repeating cycle until combat ends)
- Warning text shows **ability name only** (no mob name prefix)
- All ability timers for a pack start simultaneously on pull; each uses its own `first_cast` offset to naturally stagger
- **Auto-trigger** via `PLAYER_REGEN_DISABLED` when a pack is selected
- **Manual trigger** API also available (for console testing and Phase 3 UI)
- On combat end (`PLAYER_REGEN_ENABLED`): **auto-advance** to the next pack in the sequence
- Next combat start fires timers for the newly-advanced pack automatically
- On zone change (`PLAYER_ENTERING_WORLD`): **full reset** — sequence position returns to pack 1, all timers cancelled
- When all packs in the sequence are exhausted: enter **"end" state**, no more auto-triggers
- Change `PackDatabase` from key-value map to **ordered array** per dungeon (auto-advance increments an index)
- Pack key becomes a field inside each array entry
- Database order defines the sequence — no explicit sort field needed
- External callers (Phase 3 UI, console) can set the current pack to any index (manual re-selection)

### Claude's Discretion
- API shape for the engine (Scheduler object vs flat namespace functions)
- Internal timer implementation (C_Timer.After, ticker, OnUpdate)
- How to detect Blizzard Encounter Timer API availability vs falling back to DBM
- Exact DBM API integration approach

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| WARN-01 | Timer scheduler starts ability cooldown timers when a pack pull is triggered | C_Timer.NewTimer for one-shot delays; C_Timer.NewTicker for repeating; handles stored for cancel |
| WARN-02 | Warnings display through Blizzard's Boss Warnings API (with fallback frame if API doesn't support trash) | RaidNotice_AddMessage(RaidBossEmoteFrame, ...) is the primary display path; Midnight restrictions require in-game validation |
| WARN-03 | All active timers cancel on combat end or zone change | C_Timer handle :Cancel() method; collect all handles in a table, wipe on cleanup |
| CMBT-01 | Manual pull trigger button starts timers for the selected pack | Engine exposes a public Start(packIndex) function callable from console or Phase 3 UI |
| CMBT-02 | PLAYER_REGEN_DISABLED/ENABLED detection for automatic combat start/end | Standard event registration; PLAYER_REGEN_DISABLED fires when player loses regen (enters combat); no parameters |
| CMBT-03 | State resets on PLAYER_ENTERING_WORLD (zone change) | Existing Core.lua stub needs to call Engine:Reset() instead of doing nothing |
</phase_requirements>

---

## Summary

Phase 2 builds a pure Lua timer scheduler that fires pre-computed ability warnings using only hardcoded cooldown data — no combat log reading required. The scheduler starts on `PLAYER_REGEN_DISABLED`, fires a warning N seconds before each ability cast using `C_Timer.NewTimer` chains, and cancels all handles on `PLAYER_REGEN_ENABLED` or `PLAYER_ENTERING_WORLD`.

The most significant risk is the warning display layer. WoW Midnight (Interface 120000/120001) introduced sweeping addon restrictions targeting "secret values" from combat data. The key distinction is that **Midnight restrictions target addons reading real-time combat state** (combat log events, spell cooldowns on targets, debuff states). This addon never reads combat state — it fires timers based purely on elapsed pull time. The `C_Timer` scheduling API and `PLAYER_REGEN_DISABLED` event are not classified as "secret values" and should remain functional. However, calling `RaidNotice_AddMessage(RaidBossEmoteFrame, ...)` to inject custom text during M+ runs requires in-game validation — Blizzard's Boss Timeline HUD is boss-encounter-centric and may not accept addon-injected messages for trash combat.

**Primary recommendation:** Implement the Scheduler and Combat modules first (these are low-risk). Build the display layer (`BossWarnings.lua`) as a swappable, interface-keyed module with `RaidNotice_AddMessage` as the primary attempt and a simple `UIParent`-anchored TextFrame as the guaranteed fallback. Validate display behavior in-game before finalizing which path to use.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| C_Timer.NewTimer | Native (Patch 6+, native Patch 10+) | One-shot cancellable timer | Returns handle with :Cancel(); used by virtually all WoW timer addons |
| C_Timer.NewTicker | Native (Patch 6+, native Patch 10+) | Repeating cancellable timer | Cleaner than C_Timer.After chains for repeating callbacks |
| RaidNotice_AddMessage | FrameXML global (Patch 1+) | Display text in Boss Warnings position | Standard API for boss emote / raid warning display |
| RaidBossEmoteFrame | FrameXML global | Frame target for RaidNotice_AddMessage | Boss-style center-screen display position |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| C_Timer.After | Native | Fire-and-forget one-shot timer | Use ONLY when cancellation is not needed (not suitable here) |
| CreateFrame("Frame") | Native | Custom fallback warning frame | If RaidNotice_AddMessage is blocked during M+ trash |
| ChatTypeInfo["RAID_WARNING"] | FrameXML global | Color table for RaidNotice_AddMessage | Provides standard yellow warning color |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| C_Timer.NewTimer chain | C_Timer.NewTicker with iterations | NewTicker is cleaner; NewTimer chain allows varying intervals per ability |
| C_Timer | OnUpdate script | OnUpdate fires every frame — overkill for second-scale timers; C_Timer is more efficient |
| RaidNotice_AddMessage | UIParent TextFrame | UIParent fallback always works; BossEmoteFrame is the "native feel" target |

**Installation:** No external dependencies. All APIs are Blizzard native.

---

## Architecture Patterns

### Recommended Project Structure

After Phase 2, the addon file tree should be:

```
TerriblePackWarnings/
├── Core.lua                  # Event frame; registers PLAYER_REGEN_DISABLED/ENABLED; calls Engine
├── Engine/
│   ├── Scheduler.lua         # Timer scheduling — Start(), Stop(), active handle management
│   └── CombatWatcher.lua     # PLAYER_REGEN_DISABLED/ENABLED wiring; auto-advance logic
├── Display/
│   └── BossWarnings.lua      # Display abstraction: tries RaidNotice_AddMessage, falls back to custom frame
├── Data/
│   └── WindrunnerSpire.lua   # Pack data (restructured to ordered array)
└── TerriblePackWarnings.toc  # Loads Core, Engine/Scheduler, Engine/CombatWatcher, Display/BossWarnings, Data/...
```

Subdirectories require backslash separators in the TOC file (Windows convention for WoW TOC):
```
Engine\Scheduler.lua
Engine\CombatWatcher.lua
Display\BossWarnings.lua
```

### Pattern 1: Timer Handle Collection + Bulk Cancel

**What:** Store all active `C_Timer.NewTimer` handles in a table; cancel all on cleanup.
**When to use:** Any time multiple concurrent timers must be cancelled atomically.

```lua
-- Source: warcraft.wiki.gg/wiki/API_C_Timer.NewTimer (verified)
local activeTimers = {}

local function cancelAllTimers()
    for _, handle in ipairs(activeTimers) do
        if handle and not handle:IsCancelled() then
            handle:Cancel()
        end
    end
    wipe(activeTimers)
end

-- Schedule a one-shot timer, store handle
local handle = C_Timer.NewTimer(delay, function()
    -- fire warning
end)
table.insert(activeTimers, handle)
```

### Pattern 2: Repeating Ability Timer via Recursive NewTimer

**What:** Chain `C_Timer.NewTimer` calls to repeat at the ability's cooldown interval.
**When to use:** Each ability has its own `first_cast` + `cooldown` rhythm; NewTicker with fixed intervals doesn't accommodate variable first-cast offsets.

```lua
-- Each ability entry: { name, first_cast, cooldown }
local function scheduleAbility(ability, combatActive)
    -- Pre-warning fires (cooldown - 5) seconds into wait, actual cast fires at cooldown
    local preWarnOffset = ability.first_cast - 5  -- 5-second pre-warning
    if preWarnOffset < 0 then preWarnOffset = 0 end

    local preHandle = C_Timer.NewTimer(preWarnOffset, function()
        if not combatActive[1] then return end
        ns.BossWarnings.Show(ability.name .. " in 5 sec")
    end)
    table.insert(activeTimers, preHandle)

    local castHandle = C_Timer.NewTimer(ability.first_cast, function()
        if not combatActive[1] then return end
        ns.BossWarnings.Show(ability.name)
        -- Reschedule for next repeat
        scheduleAbility({ name = ability.name, first_cast = ability.cooldown, cooldown = ability.cooldown }, combatActive)
    end)
    table.insert(activeTimers, castHandle)
end
```

Note: `combatActive` is a single-element table used as a mutable reference so the closure can observe cancellation without re-capturing a scalar boolean.

### Pattern 3: Data Provider Display Interface

**What:** The display module exposes a single `Show(text)` function. The implementation tries the native API first and falls back gracefully.
**When to use:** Whenever the display target is uncertain (Midnight API flux, trash vs boss context).

```lua
-- Display/BossWarnings.lua
local addonName, ns = ...
ns.BossWarnings = ns.BossWarnings or {}

local useNativeAPI = true  -- determined at runtime via in-game test

function ns.BossWarnings.Show(text)
    if useNativeAPI and RaidBossEmoteFrame then
        RaidNotice_AddMessage(RaidBossEmoteFrame, text, ChatTypeInfo["RAID_WARNING"])
    else
        -- Fallback: custom TextFrame anchored to UIParent center
        ns.BossWarnings._showFallback(text)
    end
end
```

### Pattern 4: PackDatabase Restructured as Ordered Array

**What:** Change the flat string-keyed map to an ordered array per dungeon, enabling auto-advance by index increment.

```lua
-- Data/WindrunnerSpire.lua — NEW structure
local addonName, ns = ...

ns.PackDatabase["windrunner_spire"] = ns.PackDatabase["windrunner_spire"] or {}
local packs = ns.PackDatabase["windrunner_spire"]

packs[#packs + 1] = {
    key = "windrunner_spire_pack_1",
    displayName = "Windrunner Spire — Pack 1",
    mobs = {
        {
            name = "Spellguard Magus",
            npcID = 232113,
            abilities = {
                { name = "Spellguard's Protection", spellID = 1253686, first_cast = 50, cooldown = 50 },
            },
        },
    },
}
```

Auto-advance:
```lua
-- After PLAYER_REGEN_ENABLED: increment index, cap at #packs + 1 (end state)
ns.Engine.currentPackIndex = ns.Engine.currentPackIndex + 1
if ns.Engine.currentPackIndex > #packs then
    ns.Engine.state = "end"
end
```

### Anti-Patterns to Avoid

- **Using C_Timer.After for cancellable timers:** `C_Timer.After` has no return value and cannot be cancelled. A ghost warning WILL fire after combat ends if you use it.
- **Storing combatActive as a captured local boolean:** Closures capture the variable reference, not the value — but booleans are values in Lua. Use a single-element table `{true}` so closures see updates.
- **Re-registering events each combat:** `RegisterEvent` is idempotent but adding it inside `PLAYER_REGEN_DISABLED` without guard will cause doubled handling. Register once at load time, guard with state.
- **Keeping `PLAYER_ENTERING_WORLD` unregistered after first fire:** The existing Core.lua calls `UnregisterEvent` on first fire. Phase 2 needs repeated `PLAYER_ENTERING_WORLD` for zone-change resets — the handler must NOT unregister itself.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cancellable timer | Custom linked-list scheduler | `C_Timer.NewTimer` + handle table | Native heap-based implementation; :Cancel() is O(1) |
| Repeating timer | OnUpdate counter | `C_Timer.NewTicker` or chained NewTimer | OnUpdate fires every frame; C_Timer only does work at creation/destruction |
| Display routing | Custom frame visibility hacks | `RaidNotice_AddMessage` + fallback TextFrame | Standard API; queue-managed two-slot display with fade |

**Key insight:** WoW's C_Timer system is a standard heap — creating and cancelling timers is cheap. The complexity is entirely in state management (tracking handles, clearing them correctly), not in timer mechanics.

---

## Common Pitfalls

### Pitfall 1: Ghost Warnings After Combat End

**What goes wrong:** A `C_Timer.After` (or an uncancelled `NewTimer`) fires its callback after `PLAYER_REGEN_ENABLED`. Warning appears on a dead combat.
**Why it happens:** `C_Timer.After` has no cancellation API. `NewTimer` handles stored in local variables get GC'd and `:Cancel()` is never called.
**How to avoid:** Store ALL timer handles in `activeTimers` table. Call `cancelAllTimers()` in BOTH `PLAYER_REGEN_ENABLED` and `PLAYER_ENTERING_WORLD` handlers.
**Warning signs:** Warning text appearing after combat ends, or a warning appearing at the start of the next pull for the previous pack's ability.

### Pitfall 2: PLAYER_ENTERING_WORLD Firing Once and Unregistering

**What goes wrong:** The current Core.lua unregisters `PLAYER_ENTERING_WORLD` after the first fire. Zone changes after the first login never trigger the reset.
**Why it happens:** Phase 1 added `UnregisterEvent("PLAYER_ENTERING_WORLD")` to avoid repeated display init calls.
**How to avoid:** Move display init logic out of the `PLAYER_ENTERING_WORLD` handler. Let the event remain registered permanently. The engine's `Reset()` is safe to call repeatedly.
**Warning signs:** Timers from a previous zone continuing to fire after zoning in.

### Pitfall 3: Auto-Trigger Firing When No Pack Is Selected

**What goes wrong:** `PLAYER_REGEN_DISABLED` fires any time the player enters combat — even before any pack is selected.
**Why it happens:** Event fires unconditionally; the handler has no guard.
**How to avoid:** Check `ns.Engine.currentPackIndex ~= nil` (or a selected-pack flag) before starting timers in the `PLAYER_REGEN_DISABLED` handler.
**Warning signs:** Lua error trying to index a nil pack, or timers starting when the player pulls a random mob in the world.

### Pitfall 4: M+ Keystone Run PLAYER_REGEN_DISABLED Behavior

**What goes wrong:** `PLAYER_REGEN_DISABLED` may fire earlier than expected during a M+ run (e.g., on entering the instance if there's an existing aggro state) or may not fire if the key timer triggers from a non-combat state.
**Why it happens:** M+ keystone dungeons have their own combat initialization flow that may differ from non-timed dungeons.
**How to avoid:** Validate in-game during a live M+ run. The manual trigger (CMBT-01) provides a fallback if auto-trigger proves unreliable.
**Warning signs:** Timers starting immediately on zone-in before any pull, or auto-trigger not firing at all.

### Pitfall 5: Midnight API Blocking RaidNotice_AddMessage During M+ Trash

**What goes wrong:** `RaidNotice_AddMessage(RaidBossEmoteFrame, ...)` silently fails or throws a Lua error during an active M+ run due to Midnight's "secret values" protection.
**Why it happens:** Midnight restricts addons from driving certain UI calls during protected encounter scenarios. The exact scope (boss-only vs all instanced combat) is unconfirmed for trash pulls as of research date.
**How to avoid:** Design `BossWarnings.lua` as a swappable interface from day one. Validate in-game in a M+ trash pull before committing to the native API path. Have the fallback TextFrame ready and tested.
**Warning signs:** No warnings appearing during a dungeon run; Lua error mentioning "restricted" or "protected" in the BossWarnings call stack.

### Pitfall 6: TOC File Not Including New Engine Files

**What goes wrong:** `Scheduler.lua` and `CombatWatcher.lua` are never loaded; `ns.Engine` is nil at runtime.
**Why it happens:** WoW only loads files listed in the TOC, in order.
**How to avoid:** Add all new files to `TerriblePackWarnings.toc` before the data files. Core.lua must load before engine files if engine files depend on `ns` being initialized.
**Warning signs:** "attempt to index global 'ns' (a nil value)" or missing function errors at login.

---

## Code Examples

Verified patterns from official sources:

### C_Timer.NewTimer (one-shot, cancellable)
```lua
-- Source: warcraft.wiki.gg/wiki/API_C_Timer.NewTimer
local handle = C_Timer.NewTimer(seconds, function(timerHandle)
    -- callback; timerHandle == handle (distinct object, shared state)
    doSomething()
end)
-- Cancel at any time:
handle:Cancel()
-- Check status:
if handle:IsCancelled() then ... end
```

### C_Timer.NewTicker (repeating, cancellable)
```lua
-- Source: warcraft.wiki.gg/wiki/API_C_Timer.NewTicker
local ticker = C_Timer.NewTicker(interval, function(tickerHandle)
    doRepeating()
end)
-- Stop:
ticker:Cancel()
-- Optional: fixed number of repetitions
local ticker = C_Timer.NewTicker(interval, callback, 5)  -- fires 5 times then stops
```

### RaidNotice_AddMessage (display in Boss Warnings position)
```lua
-- Source: github.com/Ennie/wow-ui-source FrameXML/RaidWarning.lua (verified)
-- Signature: RaidNotice_AddMessage(noticeFrame, textString, colorInfo [, displayTime])
RaidNotice_AddMessage(
    RaidBossEmoteFrame,
    "Spellguard's Protection",
    ChatTypeInfo["RAID_WARNING"]  -- yellow color table {r,g,b}
)
-- Or with custom display time:
RaidNotice_AddMessage(RaidBossEmoteFrame, "Spellguard's Protection", ChatTypeInfo["RAID_WARNING"], 5)
```

### Event Registration (PLAYER_REGEN_DISABLED pattern)
```lua
-- Register at load time — NOT inside another event handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Player entered combat
        if ns.Engine.currentPackIndex then
            ns.Engine:Start()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Player left combat
        ns.Engine:Stop()
        ns.Engine:AdvancePack()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Zone changed — full reset, keep listening
        ns.Engine:Reset()
    end
end)
```

### Fallback TextFrame (guaranteed display)
```lua
-- Custom frame for when RaidBossEmoteFrame is unavailable/blocked
local fallbackFrame = CreateFrame("Frame", nil, UIParent)
fallbackFrame:SetSize(400, 60)
fallbackFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

local fallbackText = fallbackFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
fallbackText:SetAllPoints()
fallbackText:SetTextColor(1, 0.82, 0)  -- gold

local function showFallback(text)
    fallbackText:SetText(text)
    fallbackFrame:Show()
    C_Timer.After(5, function() fallbackFrame:Hide() end)
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| C_Timer callbacks in Lua-side heap | Native C implementation | Patch 10.0.0 (2022) | Faster; non-function callbacks now rejected |
| C_Timer.After for all timers | C_Timer.NewTimer for cancellable; C_Timer.After only for fire-and-forget | Always; explicit distinction needed | NewTimer is the correct choice here |
| Boss mods parsing combat log | Boss mods skinning Blizzard encounter data | WoW Midnight (2026) | Direct combat log parsing blocked in instances |
| Open addon API for all combat data | Secret Values — restricted during M+/boss encounters | WoW Midnight (2026) | Predefined-cooldown timers unaffected; display layer uncertain |

**Deprecated/outdated:**
- `AceTimer-3.0`: Wrapper library for Ace3 addons. This addon uses plain Lua (no libraries per project decision), so do not use.
- `OnUpdate`-based timers: Fires every frame. Replaced by `C_Timer` for any interval > 0.05s.
- `C_Timer.After` for this use case: No cancellation — unusable for ability timer chains that must stop on combat end.

---

## Open Questions

1. **Does RaidNotice_AddMessage work during M+ trash combat in Midnight (Interface 120001)?**
   - What we know: Midnight restricts addons from accessing "secret values" (real-time combat state). RaidNotice_AddMessage is a display call, not a data read. The Boss Timeline HUD is boss-encounter-centric. Display APIs were not listed in removed API changes.
   - What's unclear: Whether calling RaidNotice_AddMessage from addon Lua during a Mythic+ trash pull is restricted, silently ignored, or fully functional.
   - Recommendation: Validate in-game in a live M+ run as the first task of Phase 2. If blocked, fall back to custom TextFrame immediately. Design `BossWarnings.lua` as a swappable interface (see Architecture Patterns, Pattern 3).

2. **Does PLAYER_REGEN_DISABLED fire reliably at the start of a trash pull in M+ (not at keystone start, not on boss zone)?**
   - What we know: The event fires when player loses mana regen due to combat. It takes no parameters. It is not classified as a "secret value."
   - What's unclear: Edge cases in M+ where the combat state may be pre-set, or where Midnight's protection layer intercepts the event delivery.
   - Recommendation: Verify with the manual trigger (`/run TPW.Scheduler:Start("windrunner_spire", 1)`) as the primary test. Log event fires to chat with `print()` during early testing.

3. **Should PackDatabase use a flat key + ordered index, or per-dungeon arrays?**
   - What we know: CONTEXT.md locks the decision as ordered array per dungeon. The data file populates `ns.PackDatabase["windrunner_spire"]` as an ordered array.
   - What's unclear: The engine needs to know which dungeon the player is in to select the right array. Phase 2 scope only has one dungeon; the engine can assume windrunner_spire for now.
   - Recommendation: Use `ns.PackDatabase["windrunner_spire"]` directly for Phase 2. Phase 3 can add dungeon-detection logic.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual in-game console testing (no automated test runner for WoW Lua) |
| Config file | None — WoW addon environment has no unit test framework |
| Quick run command | `/run TPW.Scheduler:Start("windrunner_spire", 1)` in WoW chat |
| Full suite command | Manual checklist executed in a live M+ or dungeon run |

WoW Lua addons cannot use conventional unit test runners. All validation is in-game.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WARN-01 | Timers start on pull trigger | Manual smoke | `/run TPW.Scheduler:Start("windrunner_spire", 1)` then wait for warning | ❌ Wave 0: no test infra |
| WARN-02 | Warnings display in Boss Warnings UI | Manual visual | Enter dungeon, trigger pull, observe RaidBossEmoteFrame center screen | ❌ Wave 0: needs live dungeon |
| WARN-03 | Timers cancel on combat end / zone change | Manual smoke | Pull trash, let combat end, verify no ghost warnings fire | ❌ Wave 0: needs live dungeon |
| CMBT-01 | Manual trigger starts timers | Manual smoke | `/run TPW.Scheduler:Start("windrunner_spire", 1)` in console | ❌ Wave 0: no test infra |
| CMBT-02 | PLAYER_REGEN_DISABLED auto-triggers | Manual integration | Select a pack, enter combat with trash, observe timers starting | ❌ Wave 0: needs live dungeon |
| CMBT-03 | Zone change resets state | Manual integration | Run dungeon, zone out, zone back in, verify sequence restarted at pack 1 | ❌ Wave 0: needs live dungeon |

### Sampling Rate
- **Per task commit:** Reload UI, `/run print(ns.Engine and "Engine OK" or "Engine MISSING")` — confirms module loaded
- **Per wave merge:** Full manual checklist in Windrunner Spire (or test instance)
- **Phase gate:** All 4 success criteria observable before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `Engine/Scheduler.lua` — does not exist yet; covers WARN-01, WARN-03, CMBT-01
- [ ] `Engine/CombatWatcher.lua` — does not exist yet; covers CMBT-02, CMBT-03
- [ ] `Display/BossWarnings.lua` — does not exist yet; covers WARN-02
- [ ] Data structure migration: `Data/WindrunnerSpire.lua` must change from map to ordered array before engine can consume it

---

## Midnight API Risk Summary

This section consolidates the Midnight API risk because it touches every part of Phase 2.

**What Midnight restricts (confirmed):**
- Combat log events (CLEU) — addons no longer receive them in instances
- "Secret values": real-time spell cooldowns on targets, debuff states, precise enemy cast timing
- Sending addon comms or chat during an active M+ run or boss encounter

**What Midnight does NOT appear to restrict (based on research, not confirmed in-game):**
- `C_Timer.NewTimer` / `C_Timer.NewTicker` — timer scheduling is not a data read
- `PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED` — these describe the player's own regen state, not combat log data
- `PLAYER_ENTERING_WORLD` — standard load event
- `RaidNotice_AddMessage` — this is a display call, not listed in removed APIs (LOW confidence; needs in-game validation)
- Custom TextFrame display via `CreateFrame` — purely client-side UI

**Key distinction for TerriblePackWarnings:** This addon reads zero combat data. It starts a clock on pull and fires events at predetermined offsets. It falls entirely outside the class of addons that Midnight targets (rotation helpers, parse-driven boss timers, combat automation). The design is inherently Midnight-compatible at the scheduler/event level. The display layer is the only genuine uncertainty.

---

## Sources

### Primary (HIGH confidence)
- [warcraft.wiki.gg — API_C_Timer.After](https://warcraft.wiki.gg/wiki/API_C_Timer.After) — signature, cancellation, performance notes
- [warcraft.wiki.gg — API_C_Timer.NewTimer](https://warcraft.wiki.gg/wiki/API_C_Timer.NewTimer) — signature, :Cancel(), differences from NewTicker
- [warcraft.wiki.gg — API_C_Timer.NewTicker](https://warcraft.wiki.gg/wiki/API_C_Timer.NewTicker) — signature, iterations, :Cancel(), :IsCancelled()
- [warcraft.wiki.gg — PLAYER_REGEN_DISABLED](https://warcraft.wiki.gg/wiki/PLAYER_REGEN_DISABLED) — event fires when player enters combat; no parameters
- [github.com/Ennie/wow-ui-source FrameXML/RaidWarning.lua](https://github.com/Ennie/wow-ui-source/blob/master/FrameXML/RaidWarning.lua) — RaidNotice_AddMessage parameters, compatible frames
- [warcraft.wiki.gg — Patch_12.0.0/API_changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes) — confirmed C_Timer and PLAYER_REGEN_DISABLED not in removed APIs

### Secondary (MEDIUM confidence)
- [warcraft.wiki.gg — Patch_12.0.0/Planned_API_changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes) — Secret Values mechanism; communication restrictions only during boss encounter or M+ run
- [kaylriene.com — Midnight addon changes part 1](https://kaylriene.com/2025/10/03/wow-midnights-addon-combat-and-design-changes-part-1-api-anarchy-and-the-dark-black-box/) — Black box scope; DBM/WeakAuras discontinued; restrictions confirmed
- [icy-veins.com — Combat Addon Restrictions Eased](https://www.icy-veins.com/wow/news/combat-addon-restrictions-eased-in-midnight/) — restrictions narrowed to active boss encounters and M+ runs; loot council / break timers restored
- [news.blizzard.com — How Midnight's Changes Impact Combat Addons](https://news.blizzard.com/en-us/article/24244638/how-midnights-upcoming-game-changes-will-impact-combat-addons) — "addons can present combat information differently" but "not automate combat decisions"
- [wowhead.com — Boss Mod Addons in Midnight](https://www.wowhead.com/news/boss-mod-addons-in-midnight-teaching-old-mods-new-tricks-380024) — BigWigs/DBM survive by skinning Blizzard encounter data; timers via reminder system

### Tertiary (LOW confidence — needs in-game validation)
- [wowinterface.com — RaidBossEmoteFrame thread](https://www.wowinterface.com/forums/showthread.php?t=45522) — frame is accessible and scalable; no restriction evidence found
- [dtgre.com — WoW Midnight Combat Changes 2026](https://www.dtgre.com/2026/03/wow-midnight-2026-combat-changes-addon-restrictions.html) — only automation/decision-making is restricted; display APIs not explicitly named as blocked
- [mmo-champion.com — RaidNotice_AddMessage macro example](https://www.mmo-champion.com/threads/675534-Macro-for-printing-a-message-on-the-screen) — `/run RaidNotice_AddMessage(RaidBossEmoteFrame, "message", ChatTypeInfo["RAID_WARNING"])` shown working

---

## Additional Research: DBM Integration & WoW UI Source

**Sources:** Local repos — `C:\Users\jonat\Repositories\DeadlyBossMods`, `C:\Users\jonat\Repositories\wow-ui-source`

### C_EncounterTimeline.AddScriptEvent() — PRIMARY DISPLAY PATH

**Discovery:** Blizzard's Encounter Timeline has a native API for addons to inject custom timer events:

```lua
-- From wow-ui-source/Blizzard_APIDocumentationGenerated/EncounterTimelineDocumentation.lua
C_EncounterTimeline.AddScriptEvent(eventInfo)    -- Add custom timeline event (returns eventID)
C_EncounterTimeline.CancelScriptEvent(eventID)   -- Cancel custom event
C_EncounterTimeline.FinishScriptEvent(eventID)    -- Mark event as finished
C_EncounterTimeline.PauseScriptEvent(eventID)     -- Pause event
C_EncounterTimeline.ResumeScriptEvent(eventID)    -- Resume event
C_EncounterTimeline.CancelAllScriptEvents()       -- Clear all custom events
```

**Supporting APIs:**
- `C_EncounterTimeline.IsFeatureEnabled()` / `IsFeatureAvailable()` — detect if timeline is active
- `C_EncounterTimeline.HasVisibleEvents()` — check if events are showing
- `C_EncounterTimeline.GetEventHighlightTime()` — returns pre-warning highlight time (default 5s)
- `C_EncounterTimeline.GetViewType()` — Timer or Track view (user's choice)

**This changes the display strategy:** Instead of `RaidNotice_AddMessage` (text flash), the addon should inject events into Blizzard's Encounter Timeline. The player sees them as native timer bars or track events depending on their UI preference. This is exactly what the user requested ("add it to Blizzard as an upcoming CD").

**Risk:** `AddScriptEvent` may only work during active boss encounters (like the rest of the Encounter Timeline). Needs in-game validation for trash combat. If it only works during encounters, fall back to DBM.

### C_EncounterWarnings — SECONDARY/COMPLEMENTARY PATH

```lua
-- ENCOUNTER_WARNING event payload:
-- text, casterGUID, casterName, targetGUID, targetName, iconFileID, tooltipSpellID,
-- isDeadly, color, duration, severity, shouldPlaySound, shouldShowChatMessage, shouldShowWarning

-- Severity levels: Critical (High), Medium, Normal (Low)
-- API: C_EncounterWarnings.GetColorForSeverity(severity)
--      C_EncounterWarnings.GetSoundKitForSeverity(severity)
--      C_EncounterWarnings.PlaySound(severity)
--      C_EncounterWarnings.IsFeatureEnabled()
```

**Use:** Can complement timeline events with text warnings for imminent casts. However, ENCOUNTER_WARNING is likely fired by Blizzard server-side for encounter mechanics — addon may not be able to trigger it.

### DBM Integration API — FALLBACK DISPLAY PATH

**From local DeadlyBossMods source (`DBM-Core/` and `DBM-StatusBarTimers/`):**

#### Option A: DBT:CreateBar() — Direct Timer Bar Injection
```lua
-- DBM-StatusBarTimers/DBT.lua
DBT:CreateBar(timer, id, icon, huge, small, color, isDummy, colorType, inlineIcon, keep, fade, countdown, countdownMax, isCooldown)
DBT:CancelBar(id)
DBT:CancelAllBars()
DBT:GetBar(id)
```
This is the lowest-level API — injects a bar directly into DBM's timer bar display.

#### Option B: DBM:NewMod() + mod:NewTimer() — Full Mod Registration
```lua
-- Register as a DBM mod
local mod = DBM:NewMod("TPW_WindrunnerSpire", 0, nil, 0)

-- Create reusable timer objects
local timerSpellguard = mod:NewTimer(50, "Spellguard's Protection", 1253686, true, nil, 4)

-- Start timer
timerSpellguard:Start(50)  -- 50 second countdown

-- Stop timer
timerSpellguard:Stop()
```
This gives full DBM integration including user options, WeakAuras support, and voice pack compatibility.

#### Option C: DBM Callback System — Event Hooks
```lua
DBM:RegisterCallback("DBM_Pull", function() end)    -- Combat started
DBM:RegisterCallback("DBM_Wipe", function() end)    -- Group wiped
DBM:RegisterCallback("DBM_Kill", function() end)    -- Boss killed
DBM:RegisterCallback("DBM_TimerBegin", function(event, id, msg, timer, icon, ...) end)
```

**Recommendation:** Use **Option A (DBT:CreateBar)** as the DBM fallback. It's the simplest — just push a bar with a duration and ID. No mod registration needed. Check `if DBT then` to detect DBM presence.

### RaidNotice_AddMessage — TERTIARY/LEGACY PATH

From `wow-ui-source/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/RaidWarning.lua`:

```lua
function RaidNotice_AddMessage(noticeFrame, textString, colorInfo, displayTime)
-- noticeFrame: RaidBossEmoteFrame or RaidWarningFrame
-- colorInfo: {r, g, b} table (e.g., ChatTypeInfo["RAID_WARNING"])
-- displayTime: optional, defaults to 10 seconds
-- Uses two-slot queue with scale-up/fade-out animation
```

Not restricted to boss encounters. Events: `RAID_BOSS_EMOTE`, `RAID_BOSS_WHISPER`, `CLEAR_BOSS_EMOTES`.

### Updated Display Priority

Based on research:
1. **C_EncounterTimeline.AddScriptEvent()** — Native Blizzard timeline bars. Ideal match for user request. Validate in-game.
2. **DBT:CreateBar()** — DBM timer bars. Works if player has DBM installed. Simple API.
3. **RaidNotice_AddMessage()** — Text flash fallback. Always available, less informative.

### Detection Logic
```lua
local function getDisplayAdapter()
    if C_EncounterTimeline and C_EncounterTimeline.IsFeatureEnabled() then
        return "encounter_timeline"
    elseif DBT then
        return "dbm"
    else
        return "raid_notice"
    end
end
```

---

## Metadata

**Confidence breakdown:**
- Standard Stack (C_Timer APIs): HIGH — verified from warcraft.wiki.gg official docs
- C_EncounterTimeline.AddScriptEvent: MEDIUM — confirmed API exists in wow-ui-source; trash combat applicability unverified in-game
- DBM Integration (DBT:CreateBar): HIGH — verified from local DeadlyBossMods source code
- Standard Stack (RaidNotice_AddMessage): MEDIUM — verified from Blizzard UI source; Midnight compatibility unconfirmed
- Architecture: HIGH — standard WoW addon patterns, verified against existing codebase
- Combat Events (PLAYER_REGEN_DISABLED): HIGH — well-documented, not listed in Midnight removals
- Midnight restrictions: MEDIUM overall; display layer specifically LOW (conflicting signals, needs in-game test)
- Pitfalls: HIGH — derived from official API documentation and documented Midnight changes

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (Midnight API policies are still settling; re-verify display layer after in-game test)
