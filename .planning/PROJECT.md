# TerriblePackWarnings

## What This Is

A World of Warcraft addon for Midnight (12+ API) that brings ability warnings to dungeon trash packs in Mythic+ content. Players import an MDT/Keystone.guru route, configure which skills to track with custom timers and alerts, and the addon displays spell icons with countdown sweeps, cast detection highlights, and sound/TTS callouts -- giving M+ players threat awareness on trash that they normally only get on bosses. Mobs are categorized by role (boss, miniboss, caster, warrior, rogue, trivial) with runtime detection and category-based alert filtering.

## Core Value

When a player imports a route and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities via custom spell icon display with per-mob detection and configurable alerts.

## Current State

**Shipped:** v0.1.1 (2026-03-24)
**Code:** 6,414 lines of Lua across 19 files + 3 bundled libraries
**Tech stack:** Plain Lua, WoW FrameXML, C_VoiceChat TTS, nameplate scanning, LibDeflate + AceSerializer

**What works:**
- Per-skill configuration window with dungeon→mob→skill tree, search, and profile management
- Ability data for all 8 Midnight S1 dungeons (190+ mobs from MDT)
- Per-mob category system: boss, miniboss, caster, warrior, rogue, trivial, unknown
- Runtime category detection via UnitClassification, UnitIsLieutenant, UnitClassBase (DeriveCategory priority chain)
- Category-based scanner matching with unknown-as-wildcard (false positives over false negatives)
- Color-coded category tags in config UI with category-aware search
- Per-dungeon route storage with zone-in auto-switch
- Cast detection via UnitCastingInfo nameplate polling (Secret Values workaround)
- Timed ability warnings with cooldown sweep and 5s pre-warning
- Sound/TTS alerts with CDM-style sound dropdown (67 sounds)
- Profile system: create/delete/switch, import/export as shareable strings
- Combat modes: Auto/Manual/Disable
- Skill preview with cooldown sweep from config window
- MobCategories.md reference doc with all 8 dungeons fully categorized

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
- Configuration window with dungeon→mob→skill hierarchy -- v0.1.0
- MDT ability data for all 8 S1 dungeons -- v0.1.0
- Per-skill settings (toggle, label, timed, sound/TTS) -- v0.1.0
- Cast detection highlights via UnitCastingInfo -- v0.1.0
- Per-dungeon route storage with zone-in auto-switch -- v0.1.0
- Slash command rework (/tpw config, /tpw route) -- v0.1.0
- Config search filtering -- v0.1.0
- Profile system with import/export -- v0.1.0
- Per-skill timed toggle with timer fields -- v0.1.0
- Per-skill sound alert checkbox -- v0.1.0
- Per-mob mobCategory field in AbilityDB (7 categories) -- v0.1.1
- Runtime category detection (DeriveCategory priority chain) -- v0.1.1
- Category-based scanner matching with unknown-as-wildcard -- v0.1.1
- Color-coded category tags in config UI -- v0.1.1
- Category-aware config search with partial match and hyphen normalization -- v0.1.1
- All 8 S1 dungeons fully categorized from in-game verification -- v0.1.1
- isBoss field removed, boss detection unified through mobCategory -- v0.1.1

### Active

(None -- next milestone will define new requirements)

### Out of Scope

- Combat log event parsing -- blocked by Midnight API restrictions (CLEU disabled)
- Auto-detection of current pack without route addon -- no reliable API
- Route editing within TPW -- editing stays in MDT/Keystone.guru
- Spell-specific cast detection -- spellIDs are Secret Values in Midnight
- User-editable categories -- categories are factual properties of NPCs
- UnitEffectiveLevel for detection -- unusable on nameplates (takes cstring name, UnitName is Secret Value)
- Per-category sound/alert override -- defer until base category system is validated useful

## Context

- **Platform:** World of Warcraft Midnight expansion (12+ API)
- **API constraints:** Midnight restricts combat log reading, spell IDs from casts, and health values (all Secret Values). Nameplate scanning and cast name detection work.
- **Display system:** Custom spell icon squares with CooldownFrameTemplate sweep. TTS via C_VoiceChat.SpeakText. Sound via PlaySound on Master channel.
- **Import system:** LibDeflate + AceSerializer decode MDT export strings and encode profile strings.
- **Architecture:** Self-contained display + nameplate detection. Profile system for per-skill configuration. Per-dungeon route storage. Category-based scanner matching with DeriveCategory runtime detection.
- **Category system:** Mobs categorized by role (boss/miniboss/caster/warrior/rogue/trivial/unknown). Runtime detection via UnitIsBossMob → UnitIsLieutenant → UnitClassification → UnitClassBase priority chain. Unknown = wildcard at runtime.

## Constraints

- **API:** Midnight 12+ addon API only
- **Framework:** Plain Lua + XML + bundled libs (LibDeflate, AceSerializer via LibStub)
- **Data:** Ability cooldown timers configured by users (no reliable source)
- **Cast detection:** Category-based only (Secret Values prevent spell-specific detection)
- **Category detection:** UnitEffectiveLevel unusable on nameplates; UnitIsLieutenant unverified in Blizzard UI but pcall-wrapped

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Manual pack selection over auto-detection | Midnight API blocks combat log scanning | Good |
| Custom icon display over DBM/ET adapters | DBM not universal, ET boss-only | Good |
| Nameplate UnitClass for runtime detection | NPC IDs not available on nameplates | Good |
| npcID for data linkage, UnitClass for runtime | MDT uses npcIDs, nameplates expose class | Good |
| Bundle LibDeflate + AceSerializer via LibStub | Required for MDT string decode + profile export | Good |
| Paste-only import (no slash command) | WoW chat buffer too small for MDT strings | Good |
| Save processed pack data (not raw MDT string) | Instant load, no re-decode on startup | Good |
| defaultEnabled = false for MDT-imported abilities | Users opt-in per skill, no noise from unknown abilities | Good |
| Class-based cast detection (not spell-specific) | Midnight Secret Values prevent spellID table keys | Good |
| Per-dungeon route storage | Each dungeon independently imported/managed | Good |
| Profile system for skill config | Shareable configurations, multiple setups per player | Good |
| Auto-disable on non-S1 zone-out | Prevents stale tracking outside dungeons | Good |
| Rebuild packs on config close | Natural workflow boundary, avoids per-keystroke rebuilds | Good |
| mobCategory replaces mobClass in AbilityDB | Category is the semantic concept; WoW class is runtime-only | Good |
| Category-based scanner matching (not class-based) | Two mobs of same WoW class can be different categories | Good |
| DeriveCategory priority chain: boss→lieutenant→classification→class→unknown | Lieutenants are often PALADINs; must check before class | Good |
| Unknown = wildcard (false positives over false negatives) | Unknown ability fires for any mob; unknown mob triggers only unknown abilities | Good |
| Pipeline copies mobCategory onto abilities at runtime | Scanner reads ability.mobCategory directly; not saved to SavedVariables | Good |
| isBoss removed from DungeonEnemies | Unified through AbilityDB mobCategory = "boss"; no duplication | Good |

---
*Last updated: 2026-03-24 after v0.1.1 milestone*
