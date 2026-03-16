# TerriblePackWarnings

## What This Is

A World of Warcraft addon for Midnight (12+ API) that brings ability warnings to dungeon trash packs in Mythic+ content. Players import an MDT/Keystone.guru route, and the addon displays spell icon squares with cooldown sweeps, TTS callouts, and per-mob timer instances detected via nameplate scanning -- giving competitive M+ players the same threat awareness on trash that they get on bosses.

## Core Value

When a player imports a route and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities via custom spell icon display with per-mob detection.

## Current State

**Shipped:** v0.0.3 (2026-03-16)
**Code:** 1,812 lines of Lua across 10 files + 3 bundled libraries
**Tech stack:** Plain Lua, WoW FrameXML, C_VoiceChat TTS, nameplate scanning, LibDeflate + AceSerializer

**What works:**
- MDT/Keystone.guru route import via UI paste popup
- npcID-keyed ability database with dynamic pack building from imported routes
- MDT-style pack UI: numbered pulls with round NPC portrait icons, boss highlighting
- Custom spell icon display: horizontal squares with cooldown sweep, TTS, red glow
- Nameplate-based mob detection: 0.25s poll, UnitClass matching, per-mob timers
- Route persistence via SavedVariables, auto-scroll to active pull
- DungeonEnemies data for all 9 Midnight M+ dungeons

## Requirements

### Validated

- Predefined pack/mob database for one Midnight dungeon -- v0.0.1
- Pack selection UI -- v0.0.1
- Ability timer system (cooldown-based, auto-repeating) -- v0.0.1
- Addon structure (Lua, TOC, SavedVariables) -- v0.0.1
- Custom spell icon display (cooldown sweep, red glow) -- v0.0.2
- Nameplate-based mob detection (UnitClass) -- v0.0.2
- Multi-instance timed tracking -- v0.0.2
- Text-to-speech pre-warnings -- v0.0.2
- Untimed skill support -- v0.0.2
- Icon labels and spell tooltip -- v0.0.2
- MDT route import via paste string -- v0.0.3
- npcID-keyed ability database -- v0.0.3
- Dynamic pack building from imported routes -- v0.0.3
- MDT-style pull UI with NPC portraits -- v0.0.3
- Import/Clear route management -- v0.0.3

### Active

- [ ] README, TOC project IDs, icon texture
- [ ] CI/release script alignment with TerribleBuffTracker
- [ ] Debug logging and commands removed
- [ ] Code cleanup: unused vars, single-use functions, hot path audit

## Current Milestone: v0.0.4 Cleanup and Small Improvements

**Goal:** Polish the addon for broader testing — README, project IDs, CI alignment, debug removal, code cleanup.

### Out of Scope

- Combat log event parsing -- blocked by Midnight API restrictions
- Auto-detection of current pack without route addon -- no reliable API
- Community-contributed warning profiles -- future milestone
- Route editing within TPW -- editing stays in MDT/Keystone.guru

## Context

- **Platform:** World of Warcraft Midnight expansion (12+ API)
- **API constraints:** Midnight restricts combat log reading. Nameplate scanning works for mob detection.
- **Display system:** Custom spell icon squares with CooldownFrameTemplate sweep. TTS via C_VoiceChat.SpeakText.
- **Import system:** LibDeflate + AceSerializer decode MDT export strings. DungeonEnemies data for 9 dungeons provides npcID → displayId mapping.
- **Architecture:** Self-contained display + nameplate detection. Only external dependency is bundled decode libraries (LibStub pattern).

## Constraints

- **API:** Midnight 12+ addon API only
- **Framework:** Plain Lua + XML + bundled libs (LibDeflate, AceSerializer via LibStub)
- **Data:** Ability cooldown timers are approximate/predefined

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Manual pack selection over auto-detection | Midnight API blocks combat log scanning | Good |
| Custom icon display over DBM/ET adapters | DBM not universal, ET boss-only | Good |
| Nameplate UnitClass for runtime detection | NPC IDs not available on nameplates | Good |
| npcID for data linkage, UnitClass for runtime | MDT uses npcIDs, nameplates expose class | Good |
| Bundle LibDeflate + AceSerializer via LibStub | Required for MDT string decode, follows industry pattern | Good |
| Paste-only import (no slash command) | WoW chat buffer too small for MDT strings | Good -- discovered during UAT |
| Save processed pack data (not raw MDT string) | Instant load, no re-decode on startup | Good |
| Accept any dungeon import (no skill tracking if no AbilityDB) | Future-proofs for adding new dungeon abilities | Good |
| Round NPC portraits with circular mask | Matches MDT visual style | Good |
| Boss pull highlighting (dark red) | Quick visual identification of boss encounters | Good |

---
*Last updated: 2026-03-16 after v0.0.4 milestone start*
