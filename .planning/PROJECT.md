# TerriblePackWarnings

## What This Is

A World of Warcraft addon for Midnight (12+ API) that brings DBM-style ability warnings to dungeon trash packs in Mythic+ content. Players select the pack they're about to pull from a predefined list, and the addon surfaces timed ability warnings through Blizzard's native Boss Warnings system — giving competitive M+ players the same threat awareness on trash that they get on bosses.

## Core Value

When a player selects a pack and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities in Blizzard's native Boss Warning UI.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Predefined pack/mob database for one Midnight dungeon
- [ ] Pack selection UI (list/menu of packs grouped by dungeon area)
- [ ] Ability timer system (cooldown-based timers triggered on pack selection/pull)
- [ ] Boss Warnings integration (surface ability timers through Blizzard's native Boss Warning API)
- [ ] Addon structure following standard WoW Midnight addon conventions (Lua + XML, TOC file)

### Out of Scope

- Route addon integration (MDT, Keystone.guru) — future milestone, requires validation of API constraints first
- Combat log event parsing — blocked by Midnight API restrictions
- Nameplate scanning — blocked by Midnight API restrictions
- Auto-detection of current pack — future milestone, depends on available detection APIs
- Multi-dungeon support — v1 is proof of concept with one dungeon
- CurseForge/Wago publishing polish — v1 is proof of concept
- Community-contributed warning profiles — future milestone

## Context

- **Platform:** World of Warcraft Midnight expansion (12+ API)
- **API constraints:** Midnight severely restricts combat log reading, nameplate scanning, and other real-time detection APIs. The addon must rely on predefined data and user interaction rather than runtime detection.
- **Boss Warnings system:** Blizzard's new native warning UI in Midnight. The addon hooks into this to display ability timers, avoiding custom frame overhead and giving players a consistent UX.
- **Inspiration:** DBM/BigWigs timer bars for boss encounters, but applied to trash packs. Competitive M+ players already use these for bosses — this fills the gap for trash.
- **Future vision:** Integration with route addons (MethodDungeonTools, Keystone.guru) to auto-track packs along an imported route, with combat start/end events advancing through the route. This requires significant API validation first.
- **Related project:** MethodDungeonTools (local at C:\Users\jonat\Repositories\MethodDungeonTools) — potential future integration target.

## Constraints

- **API:** Midnight 12+ addon API only — no access to restricted combat/nameplate APIs
- **Framework:** Plain Lua + XML, no external libraries (Ace3, LibStub, etc.)
- **Data:** Ability cooldown timers are approximate/predefined, not derived from real-time combat events
- **Scope:** Single dungeon for v1 proof of concept

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Manual pack selection over auto-detection | Midnight API blocks combat log and nameplate scanning | — Pending |
| Predefined cooldown timers over cast bar triggers | Cast bar detection unavailable in Midnight API | — Pending |
| Plain Lua + XML, no libraries | Keep it simple for v1, avoid dependency complexity | — Pending |
| Boss Warnings API over custom frames | Native UX, less addon UI to maintain, Blizzard-supported | — Pending |
| One dungeon for v1 | Prove the concept before scaling data to full dungeon pool | — Pending |

---
*Last updated: 2026-03-13 after initialization*
