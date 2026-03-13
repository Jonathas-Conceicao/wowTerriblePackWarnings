# Stack Research

**Domain:** World of Warcraft Midnight (12.0) addon — dungeon pack warning timers
**Researched:** 2026-03-13
**Confidence:** MEDIUM (Midnight launched 2026-03-02; live API details are thin in public docs; confidence on TOC/Lua/timers is HIGH; confidence on Boss Warnings / M+ event specifics is LOW-MEDIUM)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Lua 5.1 (WoW dialect) | WoW embedded | All addon logic | The only scripting language the WoW client exposes. No choice here. |
| XML (FRAMES_XML) | Standard | Frame and template declarations | Still the right tool for static frame structure and template inheritance; avoids boilerplate `CreateFrame` calls for persistent UI elements. Can be skipped for simple addons — but useful for the pack list frame. |
| TOC manifest | Interface 120001 | Addon metadata and load order | 12.0.0+ strictly requires a matching interface version; addons without `120001` or higher will not load and cannot be overridden by the player. |

### Timing and Scheduling

| Technology | Purpose | Why |
|------------|---------|-----|
| `C_Timer.After(seconds, fn)` | Fire a one-shot callback after N seconds | Confirmed available and AllowedWhenUntainted in 12.0.1. Standard, heap-based, no OnUpdate overhead. Use for scheduling ability warning messages N seconds after a pack pull is confirmed. |
| `C_Timer.NewTicker(seconds, fn, iterations)` | Repeating timer (optional) | Returns a cancelable handle with `:Cancel()`, `:IsCancelled()`. Useful if you need periodic progress-bar updates, but not strictly required if you drive timers off one-shots. |

### UI Widgets

| Technology | Purpose | Why |
|------------|---------|-----|
| `CreateFrame("Frame")` | Root container / event bus | The canonical Midnight-era approach. No Ace3 dependency, no taint risk from library frames. |
| `CreateFrame("Button", ...)` | Clickable pack rows | Standard interactive element for the pack list. |
| `CreateFrame("ScrollFrame", ...)` | Scrollable pack list container | Built-in scroll container; pairs with a child content frame sized to fit all rows. `FauxScrollFrameTemplate` is the older alternative but ScrollFrame direct is cleaner. |
| `CreateFrame("StatusBar", ...)` | Ability cooldown progress bars | Appropriate for countdown visualization. 12.0 added smooth interpolation via `SetValue(value, interpolationType)` and timer status bars with automatic updates — use this over hand-rolled OnUpdate bars. |
| `CreateFrame("Frame")` via XML `<Frame>` | Static layout declaration | XML for the outer panel; Lua for dynamic row creation. |

### Boss Warnings Integration (MEDIUM confidence — API naming partially confirmed)

| Technology | Purpose | What We Know |
|------------|---------|-------------|
| `C_EncounterEvents.SetEventColor(eventID, r, g, b)` | Colorize a custom encounter event entry | Confirmed added in 12.0.1 per Wowhead release notes. Allows addons to associate a color with an encounter event. |
| `C_EncounterEvents.SetEventSound(eventID, soundKitID)` | Attach a sound to a custom encounter event | Confirmed added in 12.0.1. Plays a sound when the event's text warning fires. |
| `C_EncounterTimeline` namespace | Read/write the Boss Timeline HUD | Referenced in 12.0.0 API changes as newly added (76 new events, `C_EncounterTimeline` and `C_EncounterWarnings` namespaces). Specific function signatures are not publicly documented in detail. **Requires in-game `/api` verification before implementation.** |
| Blizzard's Boss Timeline HUD | Native timeline display (vertical or horizontal) with spell icons | Blizzard's built-in equivalent of DBM/BigWigs for boss encounters. Addons confirmed to be able to add custom events ("break timers" cited as example). Whether this extends to non-boss M+ trash content is unconfirmed. |

### Saved State

| Technology | Purpose | Pattern |
|------------|---------|---------|
| `SavedVariables` in TOC | Persist per-account settings | Declare `## SavedVariables: TerriblePackWarningsDB` in TOC. Initialize from defaults on `ADDON_LOADED`. |
| `SavedVariablesPerCharacter` | Per-character state if needed | Not required for v1 — last selected pack can be account-wide. |

---

## TOC File Format (12.0)

```lua
## Interface: 120001
## Title: TerriblePackWarnings
## Notes: Dungeon trash pack ability timers for Mythic+
## Author: [author]
## Version: 1.0.0
## SavedVariables: TerriblePackWarningsDB

# Load order: data first, then logic, then UI
Data\Packs.lua
Core\Timers.lua
Core\Warnings.lua
UI\PackList.lua
UI\PackList.xml
```

Key rules:
- `## Interface: 120001` is mandatory. Without it the addon will not load. There is no player override.
- TOC filename must exactly match the folder name or the addon is not detected.
- `Category` and `Group` fields are optional but recommended (added in 11.1.0) for addon compartment organization.
- `LoadOnDemand: 1` is available if pack data needs lazy loading (not needed for v1).
- Multi-client support: `## Interface: 120001, 50503` is valid comma-delimited syntax if you ever want Classic compatibility — ignore for now.

---

## Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| WoW in-game `/api` command | Browse live API documentation | The definitive source for Midnight. Filters by namespace — use `/api C_EncounterEvents` to inspect the actual functions before implementing. |
| Blizzard test encounter in MOTHERLODE!! | Test addon without repeated dungeon farming | Blizzard added a dummy encounter in patch 12.0 with units spamming spells. Use forced-state CVars (`secretCooldownsForced`, `secretSpellcastsForced`) to simulate restricted conditions. |
| CVar `secretAurasForced` et al. | Simulate M+ secret-value state | Multiple forced-state variables let you test restricted-API paths in a normal zone without actually being in M+. |
| Warcraft Wiki (warcraft.wiki.gg) | Community API reference | More current than wowpedia.fandom.com. Check patch-version tags on pages. |
| WoWUIDev Discord | Developer Q&A channel where Blizzard posts update notes | Primary source for pre-documentation API knowledge. Join for anything not yet on the wiki. |

---

## Addon Namespace Pattern (Standard Lua Structure)

```lua
-- Every Lua file in the addon gets implicit (...) = addonName, addonTable
local AddonName, TPW = ...

-- Event bus frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == AddonName then
            TPW:Initialize()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        TPW:OnEnteringWorld()
    end
end)
```

This pattern is: zero external dependencies, zero taint risk, idiomatic for Midnight-era plain addons.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Plain Lua + XML, no libraries | Ace3 / LibStub ecosystem | Only if building a multi-addon suite where library sharing reduces size. For a focused single-purpose v1 addon, Ace3 adds ~200KB of library overhead and complicates the dependency graph. PROJECT.md explicitly rules this out. |
| `C_Timer.After` for scheduling | `OnUpdate` script per-frame loop | OnUpdate has no sleep state — it fires every frame. Use only when you need sub-second interpolation. C_Timer is more efficient for >0.1s intervals. |
| `CreateFrame("StatusBar")` for progress display | Custom texture + SetWidth animation | StatusBar is purpose-built for progress visualization and gets Midnight's new interpolation support for free. |
| `C_EncounterEvents` namespace for Boss Timeline | Custom frame overlay (DIY warning UI) | Build a custom frame only if `C_EncounterEvents` does not support non-boss M+ trash content after in-game verification. This is the primary risk area to validate. |
| ScrollFrame + dynamic Button rows | AceGUI ScrollList | AceGUI works but requires LibStub. A handrolled ScrollFrame is ~50 lines of Lua and has zero dependencies. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `CombatLogGetCurrentEventInfo()` / `COMBAT_LOG_EVENT_UNFILTERED` | Blocked by Secret Values system during M+ runs. Was the backbone of DBM/WeakAuras pre-Midnight. Combat log events are "completely removed" from the addon API during instanced content. | Predefined cooldown data + `C_Timer.After` keyed off user-initiated pack selection |
| Nameplate scanning (`C_NamePlate`, `UnitGUID` on nameplates) | Enemy unit identity (names, GUIDs, IDs) becomes secret while in instances. Cannot reliably identify specific mobs from nameplates. | Predefined pack database — user selects which pack they are pulling |
| `UnitCastingInfo` / `UnitChannelInfo` on enemy units | Spellcast data for enemies is secret in instanced content. Pre-Midnight approach used by cast-bar addons. | Approximate predefined cast timers |
| `GetSpellCooldown` on enemy spells | Cooldowns return secret values during M+ runs. | Predefined cooldown estimates in pack data |
| WeakAuras-style dynamic aura processing | WeakAuras lost most combat functionality in Midnight and the team decided against rewriting it. The pattern of complex conditional aura logic no longer works in instances. | Static predefined timer triggers |
| Ace3 / LibStub dependency chain | Adds ~200KB, requires embedded library handling, complicates TOC load order, unnecessary for this scope | Plain `local AddonName, ns = ...` namespace pattern |
| `wowpedia.fandom.com` as authoritative API source | Out of date on Midnight-specific changes. Pages sometimes lack version tags. | `warcraft.wiki.gg` — actively maintained for Midnight patch notes |

---

## Critical Unknowns — Validate Before Implementing Boss Warnings

The Boss Warnings / Encounter Timeline integration is the highest-risk element of this stack. The following must be verified in-game via `/api` before Phase 2 implementation:

1. **Does `C_EncounterTimeline` or `C_EncounterWarnings` accept custom (addon-defined) events, or only events from Blizzard encounter scripts?**
   - Blizzard's blog says addons can "add their own custom events to the timeline, such as break timers" — but this may be restricted to specific encounter contexts.
   - If custom events are locked to boss encounters only, trash pack timers cannot use the Boss Timeline HUD.

2. **Does the Encounter Timeline HUD appear outside boss encounters (i.e., during M+ trash pulls)?**
   - The HUD guide describes it as a "boss fight" tool. It may not render at all during trash combat.
   - If so, a custom StatusBar frame overlay becomes the fallback.

3. **What is the exact function signature for adding a custom event?**
   - `C_EncounterEvents.SetEventColor` and `SetEventSound` are confirmed, but these appear to customize existing events. An `AddEvent` or `RegisterEvent` equivalent needs verification.

4. **Are UI events like `PLAYER_REGEN_DISABLED` (entering combat) still fired to addons during M+ runs?**
   - If yes, the addon can auto-start timers when the player pulls. If no (black-boxed), the user must manually confirm the pull via a button press.

**Fallback plan:** If `C_EncounterTimeline` custom events are unavailable for trash content, implement a draggable `StatusBar`-based warning frame as a drop-in replacement. This should be designed as a swappable rendering layer from the start.

---

## Version Compatibility

| Component | Minimum Interface | Notes |
|-----------|------------------|-------|
| TOC `## Interface` | 120001 | Hard requirement — no player override in Midnight |
| `C_Timer.After` | 120001 | Available; AllowedWhenUntainted confirmed 12.0.1 |
| `C_EncounterEvents.SetEventColor` | 120001 (12.0.1) | Added in 12.0.1 post-launch patch per Wowhead |
| `C_EncounterEvents.SetEventSound` | 120001 (12.0.1) | Same |
| `StatusBar` smooth interpolation | 120001 | New interpolation param added in 12.0 |
| `SavedVariables` | All modern | Stable, unchanged |
| `CreateFrame`, `ScrollFrame`, `Button` | All modern | Stable Widget API, confirmed current through 12.0.1 |

---

## Sources

- [Patch 12.0.0/API changes — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes) — 437 new APIs, Secret Values system, C_EncounterTimeline/C_EncounterWarnings namespaces confirmed added. HIGH confidence.
- [Patch 12.0.0/Planned API changes — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes) — Secret Values mechanics, M+ cooldown/aura restrictions, C_Timer AllowedWhenUntainted, UI APIs. HIGH confidence.
- [TOC format — Warcraft Wiki](https://warcraft.wiki.gg/wiki/TOC_format) — Interface 120001 requirement, all TOC fields including Category/Group. HIGH confidence.
- [Create a WoW AddOn in 15 Minutes — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Create_a_WoW_AddOn_in_15_Minutes) — Canonical addon structure, ADDON_LOADED pattern, SavedVariables. HIGH confidence.
- [C_Timer.After — Warcraft Wiki](https://warcraft.wiki.gg/wiki/API_C_Timer.After) — AllowedWhenUntainted status, usage pattern. HIGH confidence.
- [Widget API — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Widget_API) — Frame types, ScrollFrame, StatusBar, current through 12.0.1. HIGH confidence.
- [Wowhead: Lua API Changes for Midnight Launch](https://www.wowhead.com/news/addon-changes-for-midnight-launch-ending-soon-with-release-candidate-coming-380133) — C_EncounterEvents.SetEventColor/SetEventSound confirmed added. MEDIUM confidence (Wowhead reporting, not official docs).
- [Blizzard: How Midnight's Changes Will Impact Combat Addons](https://news.blizzard.com/en-us/article/24244638/how-midnights-upcoming-game-changes-will-impact-combat-addons) — Custom events on Boss Timeline, addon skinning capability. MEDIUM confidence (pre-launch article, subject to iteration).
- [Blizzard: Combat Philosophy and Addon Disarmament in Midnight](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight) — Secret Values philosophy, what addons can still do. MEDIUM confidence.
- [Wowhead: Blizzard Boss Timeline HUD Guide](https://www.wowhead.com/guide/ui/blizzard-boss-timeline-hud-features-customization) — Timeline/text warning components, no boss-specific restriction noted but no trash-pack confirmation either. LOW confidence for trash applicability.
- WoWUIDev Discord — Primary developer communication channel. Not directly cited but referenced across multiple articles as the authoritative real-time source.

---

*Stack research for: WoW Midnight dungeon pack warning addon (TerriblePackWarnings)*
*Researched: 2026-03-13*
