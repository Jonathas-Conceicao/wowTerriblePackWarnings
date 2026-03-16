# Requirements: TerriblePackWarnings

**Defined:** 2026-03-16
**Core Value:** When a player imports a route and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities via custom spell icon display.

## v0.0.3 Requirements

Requirements for MDT import and dynamic route support.

### Data Rework

- [x] **DATA-10**: Ability database keyed by npcID — each npcID maps to its spells with cooldown, label, tts, mobClass
- [x] **DATA-11**: Multiple npcIDs can share the same ability (e.g. 232122 and 232121 both have Interrupting Screech)
- [x] **DATA-12**: Packs are dynamically built from imported route data, not hardcoded in data files

### MDT Import

- [x] **IMPORT-01**: Decode MDT export strings using LibDeflate + AceSerializer (bundled following MDT's own pattern)
- [x] **IMPORT-02**: Extract pull list with npcIDs from decoded preset data
- [x] **IMPORT-03**: Match pull npcIDs against ability database to build pack abilities with correct mobClasses
- [x] **IMPORT-04**: Populate PackDatabase from imported route (replaces hardcoded data files)

### UI Overhaul

- [x] **UI-09**: Pack list shows indexed pulls with round NPC portrait icons per mob in each pack
- [x] **UI-10**: Import button opens text editbox for pasting MDT/KSG export string
- [x] **UI-11**: Clear button removes all imported route data, leaving pack list empty
- [x] **UI-12**: Display imported dungeon name and pull count in the UI header

## Ability-to-NPC Mapping (Reference Data)

| Ability | SpellID | NPC IDs | MobClass | Timer |
|---------|---------|---------|----------|-------|
| Spellguard's Protection | 1253686 | 232113 | PALADIN | 50s/50s |
| Spirit Bolt | 1216135 | 232070 | WARRIOR | untimed |
| Fire Spit | 1216848 | 236891, 232056 | WARRIOR | untimed |
| Interrupting Screech | 471643 | 232122, 232121 | PALADIN | 20s/25s |

## Out of Scope

| Feature | Reason |
|---------|--------|
| Dropdown for multiple dungeons | v0.0.3 shows only the imported route until cleared |
| Keystone.guru native API | KSG shares via MDT-compatible strings — same decoder works |
| Auto-import from MDT addon | Paste-only for v0.0.3, direct MDT integration later |
| Route editing within TPW | Import only — editing stays in MDT/KSG |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-10 | Phase 8 | Complete |
| DATA-11 | Phase 8 | Complete |
| DATA-12 | Phase 9 | Complete |
| IMPORT-01 | Phase 8 | Complete |
| IMPORT-02 | Phase 9 | Complete |
| IMPORT-03 | Phase 9 | Complete |
| IMPORT-04 | Phase 9 | Complete |
| UI-09 | Phase 10 | Complete |
| UI-10 | Phase 10 | Complete |
| UI-11 | Phase 10 | Complete |
| UI-12 | Phase 10 | Complete |

**Coverage:**
- v0.0.3 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-03-16*
