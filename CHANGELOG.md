# Changelog

## v0.0.4 — Cleanup and Polish

- README with project description, WIP notice, gallery, and GPL-2.0 license
- TOC metadata: CurseForge ID, Wago ID, addon icon
- Debug logging now toggleable via `/tpw debug` (off by default, persists through /reload)
- Removed debug-only slash commands (/tpw show, /tpw hide)
- Nameplate cache optimization: UnitCanAttack and UnitClass cached at nameplate events, reducing hot-path API calls from ~60 to ~20 per tick
- Dead code removal and hot path audit with PERF comments

## v0.0.3 — MDT Import

- Import MDT/Keystone.guru routes via paste popup in the pack UI
- npcID-keyed ability database — abilities linked to mobs, not hardcoded packs
- Import pipeline: decode MDT string → extract pulls → match AbilityDB → build packs
- Route persistence across /reload via SavedVariables
- MDT-style pack UI: numbered pulls with round NPC portrait icons
- Boss pull highlighting (dark red), alternating row stripes, auto-scroll to active pull
- DungeonEnemies data for all 9 Midnight S1 dungeons (206 mobs, 38 bosses)
- Clear button with confirmation dialog
- Bundled LibDeflate + AceSerializer for MDT string decoding

## v0.0.2 — Display Rework

- Custom spell icon display replacing DBM/Encounter Timeline/RaidNotice adapters
- Horizontal icon row with cooldown sweep animation and integer countdown
- Red glow border at 5 seconds remaining
- Text-to-speech warnings with short callouts per ability
- Nameplate-based mob detection: 0.25s poll, UnitClass matching, per-mob timers
- Timed and untimed ability support (icon-only for interrupt-dependent casts)
- Icon labels and spell tooltip on mouseover
- Full Windrunner Spire route: 17 packs, 4 tracked abilities

## v0.0.1 — MVP

- Loadable WoW Midnight addon with correct TOC and SavedVariables
- Windrunner Spire pack database with ability timers
- Timer scheduler with auto-repeating warnings and 5-second pre-warn
- Combat state machine: auto-start, auto-advance, zone-change reset
- Pack selection UI with accordion list and combat state indicators
- Zone auto-detection via GetInstanceInfo
- Dev tooling: install script, release script, GitHub Actions CI
