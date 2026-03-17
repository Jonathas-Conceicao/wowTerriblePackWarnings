# TerriblePackWarnings

## What This Is

A World of Warcraft addon for Midnight (12+ API) that brings ability warnings to dungeon trash packs in Mythic+ content. Players import an MDT/Keystone.guru route, and the addon displays spell icon squares with cooldown sweeps, TTS callouts, and per-mob timer instances detected via nameplate scanning -- giving competitive M+ players the same threat awareness on trash that they get on bosses.

## Core Value

When a player imports a route and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities via custom spell icon display with per-mob detection.

## Current State

**Shipped:** v0.0.4 (2026-03-16)
**Code:** 1,839 lines of Lua across 10 files + 3 bundled libraries
**Tech stack:** Plain Lua, WoW FrameXML, C_VoiceChat TTS, nameplate scanning, LibDeflate + AceSerializer

**What works:**
- MDT/Keystone.guru route import via UI paste popup
- npcID-keyed ability database with dynamic pack building from imported routes
- MDT-style pack UI: numbered pulls with round NPC portrait icons, boss highlighting
- Custom spell icon display: horizontal squares with cooldown sweep, TTS, red glow
- Nameplate-based mob detection: 0.25s poll, UnitClass matching, per-mob timers
- Route persistence via SavedVariables, auto-scroll to active pull
- DungeonEnemies data for all 9 Midnight M+ dungeons

## Current Milestone: v0.1.0 Configuration and Skill Data

**Goal:** Add per-skill configuration UI, populate ability data from MDT for all dungeons, rework highlighting for untimed vs timed skills, and support per-dungeon route management.

**Target features:**
- Configuration window: dungeon→mob→skill tree with per-skill settings
- MDT ability data extraction for all 9 Midnight S1 dungeons
- Per-skill toggles, custom labels, TTS text, and WoW sound alert dropdown (CDM-style)
- Untimed skill highlighting on same-class cast detection via nameplate polling
- Per-dungeon route import and storage (each dungeon holds its own route)
- Dungeon selector in TPW window with auto-switch on zone-in
- Pull rows show mob counts per type

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

- Configuration window with dungeon→mob→skill hierarchy
- MDT ability data population for all 9 dungeons (untimed, default WARRIOR class)
- Per-skill settings: toggle tracking, custom label, TTS text, sound alert dropdown
- Untimed skill highlighting via nameplate cast detection (UnitCastingInfo polling)
- Timed skill pre-warning highlight at 5 seconds with alert
- Per-dungeon route storage (independent routes per dungeon)
- Dungeon selector in TPW window with zone-in auto-switch
- Pull rows showing mob count per type

### Out of Scope

- Combat log event parsing -- blocked by Midnight API restrictions
- Auto-detection of current pack without route addon -- no reliable API
- Community-contributed warning profiles -- future milestone
- Route editing within TPW -- editing stays in MDT/Keystone.guru

## Context

- **Platform:** World of Warcraft Midnight expansion (12+ API)
- **API constraints:** Midnight restricts combat log reading. Nameplate scanning works for mob detection. UnitCastingInfo/UnitChannelInfo available for cast detection via nameplate polling.
- **Display system:** Custom spell icon squares with CooldownFrameTemplate sweep. TTS via C_VoiceChat.SpeakText.
- **Import system:** LibDeflate + AceSerializer decode MDT export strings. DungeonEnemies data for 9 dungeons provides npcID → displayId mapping.
- **Architecture:** Self-contained display + nameplate detection. Only external dependency is bundled decode libraries (LibStub pattern).
- **MDT source:** Local at C:\Users\jonat\Repositories\MythicDungeonTools — ability data per enemy available, no cast timing.
- **CDM reference:** Cooldown Manager sound alert pattern in wow-ui-source at C:\Users\jonat\Repositories\wow-ui-source — dropdown for WoW built-in sound files.

## Constraints

- **API:** Midnight 12+ addon API only
- **Framework:** Plain Lua + XML + bundled libs (LibDeflate, AceSerializer via LibStub)
- **Data:** Ability cooldown timers are approximate/predefined
- **Cast detection:** Must use UnitCastingInfo via nameplate polling (no CLEU)

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
| Default mobClass to WARRIOR for MDT-imported abilities | MDT lacks class data, WARRIOR is safe default, refine later | — Pending |
| UnitCastingInfo polling for untimed skill highlights | CLEU disabled in Midnight, nameplate polling already runs | — Pending |
| Per-dungeon route storage | Each dungeon can have independent imported route | — Pending |

---
*Last updated: 2026-03-17 after v0.1.0 milestone start*
