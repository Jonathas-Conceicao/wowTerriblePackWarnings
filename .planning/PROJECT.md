# TerriblePackWarnings

## What This Is

A World of Warcraft addon for Midnight (12+ API) that brings DBM-style ability warnings to dungeon trash packs in Mythic+ content. Players select the pack they're about to pull from a UI window or slash command, and the addon surfaces timed ability warnings through DBM timer bars (with Encounter Timeline and RaidNotice fallbacks) -- giving competitive M+ players the same threat awareness on trash that they get on bosses.

## Core Value

When a player selects a pack and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities via DBM bars or Blizzard's native warning UI.

## Current State

**Shipped:** v0.0.1 (2026-03-15)
**Code:** 768 lines of Lua across 6 files
**Tech stack:** Plain Lua, WoW FrameXML templates, DBM/DBT API integration

**What works:**
- Windrunner Spire pack data with ability timers
- 3-tier display: DBM bars > Encounter Timeline > RaidNotice fallback
- Auto-combat trigger (PLAYER_REGEN_DISABLED) and auto-advance through packs
- Zone auto-detection (auto-selects dungeon on zone entry)
- Pack selection UI with accordion list, combat state indicators, live refresh
- Position persistence, Escape-to-close, standard WoW panel behavior

## Requirements

### Validated

- Predefined pack/mob database for one Midnight dungeon -- v0.0.1
- Pack selection UI (accordion list grouped by dungeon) -- v0.0.1
- Ability timer system (cooldown-based, auto-repeating) -- v0.0.1
- Display integration (DBM bars, ET fallback, RaidNotice fallback) -- v0.0.1
- Addon structure (Lua, TOC, SavedVariables) -- v0.0.1

### Active

- [ ] Custom spell icon display (horizontal squares, cooldown sweep, red glow)
- [ ] Nameplate-based mob detection (filter by UnitClass)
- [ ] Multi-instance timed tracking (one timer per mob of matching class)
- [ ] Text-to-speech pre-warnings
- [ ] Untimed skill support (icon-only, no countdown)
- [ ] Updated Windrunner Spire data with mob class filters

## Current Milestone: v0.0.2 Display Rework

**Goal:** Replace DBM/ET/RaidNotice adapters with a custom WeakAura-style spell icon display that uses nameplate scanning to detect mobs and create independent timer instances per mob.

### Out of Scope

- Route addon integration (MDT, Keystone.guru) -- future milestone
- Combat log event parsing -- blocked by Midnight API restrictions
- Nameplate scanning -- blocked by Midnight API restrictions
- Auto-detection of current pack without route addon -- no reliable API
- Community-contributed warning profiles -- future milestone

## Context

- **Platform:** World of Warcraft Midnight expansion (12+ API)
- **API constraints:** Midnight severely restricts combat log reading, nameplate scanning, and other real-time detection APIs. The addon relies on predefined data and user interaction.
- **Display system:** DBM is the primary display adapter (works everywhere including outside boss encounters). Encounter Timeline only renders during boss fights. RaidNotice is the universal fallback for text alerts.
- **Architecture:** Addon is a data provider -- pushes ability data into external timer/warning systems (DBM, ET, RaidNotice). Does not render custom timer bars or frames.
- **Related project:** MethodDungeonTools (local at C:\Users\jonat\Repositories\MethodDungeonTools) -- potential future integration target.

## Constraints

- **API:** Midnight 12+ addon API only -- no access to restricted combat/nameplate APIs
- **Framework:** Plain Lua + XML, no external libraries (Ace3, LibStub, etc.)
- **Data:** Ability cooldown timers are approximate/predefined, not derived from real-time combat events

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Manual pack selection over auto-detection | Midnight API blocks combat log and nameplate scanning | Good -- works reliably with zone auto-detect as bonus |
| Predefined cooldown timers over cast bar triggers | Cast bar detection unavailable in Midnight API | Good -- timers are predictable and consistent |
| Plain Lua + XML, no libraries | Keep it simple for v1, avoid dependency complexity | Good -- 768 LOC, no dependency issues |
| DBM-first display over Encounter Timeline | ET only renders during boss encounters, DBM works everywhere | Good -- discovered during UAT, pivoted successfully |
| One dungeon for v1 | Prove the concept before scaling data | Good -- validated core loop works |
| Data provider architecture | Push into existing timer systems, don't render own UI | Good -- leverages DBM bars players already know |
| pcall-protect external API calls | ET API errors were aborting state transitions | Good -- prevents cascading failures |
| State-before-action pattern | Update state machine before calling potentially-failing operations | Good -- prevents re-trigger bugs |
| Zone auto-detection via GetInstanceInfo | Maps instance names to dungeon keys for automatic selection | Good -- reduces manual steps |

---
*Last updated: 2026-03-15 after v0.0.2 milestone start*
