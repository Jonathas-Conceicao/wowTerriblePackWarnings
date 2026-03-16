# TerriblePackWarnings

## What This Is

A World of Warcraft addon for Midnight (12+ API) that brings ability warnings to dungeon trash packs in Mythic+ content. Players select a pack from a UI window, and the addon displays spell icon squares with cooldown sweeps, TTS callouts, and per-mob timer instances detected via nameplate scanning -- giving competitive M+ players the same threat awareness on trash that they get on bosses.

## Core Value

When a player selects a pack and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities via custom spell icon display with per-mob detection.

## Current State

**Shipped:** v0.0.2 (2026-03-16)
**Code:** 1,239 lines of Lua across 7 files
**Tech stack:** Plain Lua, WoW FrameXML templates, C_VoiceChat TTS, nameplate scanning

**What works:**
- Full Windrunner Spire route: 17 packs with 4 tracked abilities
- Custom spell icon display: horizontal squares with cooldown sweep, integer countdown, red glow at 5s
- Nameplate-based mob detection: 0.25s poll, UnitClass matching, per-mob independent timers
- Text-to-speech warnings with custom short callouts per ability
- Icon labels and spell tooltip on mouseover
- Pack selection UI with accordion list, combat state indicators, live refresh
- Zone auto-detection, auto-advance through packs, combat lifecycle management

## Requirements

### Validated

- Predefined pack/mob database for one Midnight dungeon -- v0.0.1
- Pack selection UI (accordion list grouped by dungeon) -- v0.0.1
- Ability timer system (cooldown-based, auto-repeating) -- v0.0.1
- Addon structure (Lua, TOC, SavedVariables) -- v0.0.1
- Custom spell icon display (horizontal squares, cooldown sweep, red glow) -- v0.0.2
- Nameplate-based mob detection (filter by UnitClass) -- v0.0.2
- Multi-instance timed tracking (one timer per mob of matching class) -- v0.0.2
- Text-to-speech pre-warnings -- v0.0.2
- Untimed skill support (icon-only, no countdown) -- v0.0.2
- Full dungeon route with 17 packs -- v0.0.2
- Icon labels and spell tooltip -- v0.0.2

### Active

(None -- next milestone will define new requirements)

### Out of Scope

- Route addon integration (MDT, Keystone.guru) -- future milestone
- Combat log event parsing -- blocked by Midnight API restrictions
- Auto-detection of current pack without route addon -- no reliable API
- Community-contributed warning profiles -- future milestone
- Multiple dungeon support -- v0.0.2 covers Windrunner Spire only

## Context

- **Platform:** World of Warcraft Midnight expansion (12+ API)
- **API constraints:** Midnight restricts combat log reading and some real-time detection APIs. Nameplate scanning via C_NamePlate.GetNamePlates + UnitClass + UnitAffectingCombat works for mob detection.
- **Display system:** Custom spell icon squares (replaced DBM/ET/RaidNotice in v0.0.2). Cooldown sweep via CooldownFrameTemplate. TTS via C_VoiceChat.SpeakText.
- **Architecture:** Addon renders its own icon display and uses nameplate scanning for mob detection. No external addon dependencies.
- **Related project:** MethodDungeonTools (local at C:\Users\jonat\Repositories\MethodDungeonTools) -- potential future integration target.

## Constraints

- **API:** Midnight 12+ addon API only
- **Framework:** Plain Lua + XML, no external libraries (Ace3, LibStub, etc.)
- **Data:** Ability cooldown timers are approximate/predefined, not derived from real-time combat events

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Manual pack selection over auto-detection | Midnight API blocks combat log scanning | Good -- zone auto-detect as bonus |
| Predefined cooldown timers over cast bar triggers | Cast bar detection unavailable | Good -- predictable and consistent |
| Plain Lua + XML, no libraries | Keep it simple, avoid dependency complexity | Good -- 1,239 LOC, no dependencies |
| Custom icon display over DBM/ET adapters | DBM not universal, ET only works in boss fights | Good -- fully self-contained display |
| Nameplate UnitClass for mob detection | NPC IDs blocked, class-based detection works | Good -- reliably detects mob types |
| 0.25s poll for nameplate scanning | Event-based unreliable for combat state changes | Good -- responsive without performance issues |
| Cleanup on combat end only (no mid-combat removal) | Camera turns cause false nameplate removals | Good -- avoids ghost timer issues |
| Count-based mob tracking vs event-based | Compare visible count against tracked timers | Good -- prevents camera-turn duplicates |
| TTS via C_VoiceChat.SpeakText | Native API, no bundled sound files needed | Good -- works in Midnight |
| Simple red border glow (4 edge textures) | Avoid LibCustomGlow dependency | Good -- lightweight, no library needed |

---
*Last updated: 2026-03-16 after v0.0.2 milestone*
