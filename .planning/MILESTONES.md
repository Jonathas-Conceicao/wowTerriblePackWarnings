# Milestones

## v0.1.0 Configuration and Skill Data (Shipped: 2026-03-22)

**Phases completed:** 6 phases, 16 plans
**Code:** 6,294 lines of Lua across 19 files + 3 bundled libraries
**Timeline:** 6 days (2026-03-17 → 2026-03-22)

**Key accomplishments:**
- Config window with dungeon→mob→skill tree, per-skill settings (enable, label, timed, sound/TTS), search, profile management
- Ability data for all 8 Midnight S1 dungeons extracted from MDT (190+ mobs)
- Per-dungeon route storage with zone-in auto-switch and schema migration
- Cast detection via UnitCastingInfo (Secret Values workaround: class-based name presence check)
- Sound/TTS alerts with per-skill configuration, CDM-style sound dropdown (67 sounds)
- Profile system: create/delete/switch, import/export via LibDeflate+AceSerializer
- Slash command rework: /tpw opens config, /tpw route opens route, case-insensitive
- Combat modes: Auto/Manual/Disable with immediate disable clearing all tracking
- Skill preview with cooldown sweep from config window

**Requirements:** 31/31 v0.1.0 requirements completed
**Audit:** tech_debt (5 items, no blockers)

---

## v0.0.4 Cleanup and Polish (Shipped: 2026-03-16)

**Phases completed:** 2 phases, 2 plans
**Code:** 1,839 lines of Lua across 10 files

**Key accomplishments:**
- README with WIP notice, gallery, AI disclosure, GPL-2.0 license
- TOC metadata: CurseForge 1487612, Wago ZKbxadN1, blp addon icon
- Debug logging toggleable via /tpw debug (SavedVariables, defaults OFF)
- All status messages guarded behind debug flag — silent by default
- Nameplate cache: UnitCanAttack/UnitClass cached at events, hot path reduced from ~60 to ~20 API calls/tick
- Zone re-entry resets imported route to pull 1
- Mid-combat pack select starts scanner immediately
- CHANGELOG.md for release notes
- Dead code removal and PERF audit comments

**Requirements:** 8/8 v0.0.4 requirements completed (DOC-01/02, CI-01/02, CLEAN-01/02/03/04)

---

## v0.0.3 MDT Import (Shipped: 2026-03-16)

**Phases completed:** 3 phases, 5 plans
**Code:** 1,812 lines of Lua across 10 files (+ 3 bundled libraries)
**Timeline:** 2026-03-16

**Key accomplishments:**
- npcID-keyed ability database replacing hardcoded pack data — abilities linked to mobs, not packs
- MDT export string decoding via bundled LibDeflate + AceSerializer (following MDT's own pattern)
- Import pipeline: decoded MDT preset → pull extraction → npcID → AbilityDB matching → dynamic PackDatabase population
- Route persistence via SavedVariables (processed pack data, instant load)
- MDT-style pack UI: numbered pull rows with round NPC portrait icons (circular mask, 22px)
- Import popup editbox for pasting MDT/Keystone.guru strings, Clear with confirmation dialog
- Alternating row stripes, boss pull dark red highlighting, auto-scroll to active pull
- DungeonEnemies data for all 9 Midnight M+ dungeons (206 mobs, 38 bosses flagged)
- Portrait fallback chain: displayId → class icon from AbilityDB → question mark

**Requirements:** 11/11 v0.0.3 requirements completed (DATA-10/11/12, IMPORT-01/02/03/04, UI-09/10/11/12)

---

## v0.0.2 Display Rework (Shipped: 2026-03-16)

**Phases completed:** 4 phases, 7 plans
**Code:** 1,239 lines of Lua across 7 files
**Timeline:** 2026-03-15 to 2026-03-16

**Key accomplishments:**
- Custom WeakAura-style spell icon display replacing DBM/ET/RaidNotice adapters
- Horizontal icon row with cooldown sweep animation, integer countdown, and red glow at 5 seconds
- Text-to-speech warnings via C_VoiceChat.SpeakText with custom short callouts per ability
- Nameplate-based mob detection: 0.25s poll, UnitClass matching, per-mob independent timer instances
- Full Windrunner Spire route: 17 packs with 4 tracked abilities (Spellguard's Protection, Spirit Bolt, Fire Spit, Interrupting Screech)
- Icon labels ("DR", "Bolt", "DMG", "Kick") and spell tooltip on mouseover
- Data schema: flat pack.abilities with mobClass, timed/untimed, label, ttsMessage fields

**Requirements:** 16/16 v0.0.2 requirements completed (DISP-01 through DISP-08, DATA-06 through DATA-09, DETC-01 through DETC-04)

---

## v0.0.1 MVP Proof of Concept (Shipped: 2026-03-15)

**Phases completed:** 3 phases, 8 plans
**Code:** 768 lines of Lua across 6 files
**Timeline:** 3 days (2026-03-13 to 2026-03-15)

**Key accomplishments:**
- Loadable WoW Midnight addon with TOC, namespace, SavedVariables, and dev tooling (install/release scripts, GitHub Actions)
- Windrunner Spire pack database with ability timers (first_cast + cooldown repeat)
- 3-tier display adapter: DBM bars > Encounter Timeline > RaidNotice fallback with pcall-protected API calls
- Timer scheduler with auto-repeating ability warnings and 5-second pre-warn alerts
- Combat state machine: auto-start on PLAYER_REGEN_DISABLED, auto-advance packs on combat end, zone-change full reset
- Pack selection UI: accordion window with dungeon headers, click-to-select, combat state indicators (active/completed), live refresh on auto-advance
- Zone auto-detection via GetInstanceInfo for automatic dungeon selection

**Requirements:** 14/14 v1 requirements completed (FOUND-01/02, DATA-01/02, WARN-01/02/03, CMBT-01/02/03, UI-01/02/03/04)

---

