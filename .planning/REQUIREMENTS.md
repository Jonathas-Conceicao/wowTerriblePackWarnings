# Requirements: TerriblePackWarnings

**Defined:** 2026-03-15
**Core Value:** When a player selects a pack and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities via custom spell icon display.

## v0.0.2 Requirements

Requirements for custom display rework. Replaces DBM/ET/RaidNotice adapters with WeakAura-style spell icon squares.

### Display

- [x] **DISP-01**: Horizontal row of square spell icons at top-left of screen, growing rightward
- [x] **DISP-02**: Each timed square shows the spell icon (from spellID) with cooldown sweep animation and integer countdown
- [x] **DISP-03**: Untimed skills display as static icons (no sweep, no countdown), one icon regardless of mob count
- [x] **DISP-04**: Red glow border on timed squares when 5 seconds remain before cast
- [x] **DISP-05**: Text-to-speech announces ability name 5 seconds before timed cast fires
- [ ] **DISP-06**: Remove DBM/EncounterTimeline/RaidNotice display adapters (custom display replaces all)
- [ ] **DISP-07**: When all mobs of a tracked skill's class die, clear all instances of that skill from display
- [x] **DISP-08**: Timed skills show one icon per mob instance; untimed skills show one icon total

### Data

- [x] **DATA-06**: Each ability entry supports optional timer (nil cooldown = untimed/icon-only)
- [x] **DATA-07**: Each ability entry includes mobClass filter (UnitClass value, e.g. "PALADIN") for nameplate detection
- [x] **DATA-08**: Mob name field dropped from data schema (filter by class, not name)
- [x] **DATA-09**: Update Windrunner Spire Pack 1: Spellguard's Protection (1253686, PALADIN, 50s) and Spirit Bolt (1216135, WARRIOR, untimed)

### Detection

- [ ] **DETC-01**: Scan nameplates on combat start to detect which mob classes are in combat
- [ ] **DETC-02**: When a mob matching a skill's mobClass enters combat, start an independent timer instance
- [ ] **DETC-03**: Multiple mobs of the same class create multiple independent timed squares
- [ ] **DETC-04**: Continue scanning nameplates during combat to detect newly-aggro'd mobs

## Out of Scope

| Feature | Reason |
|---------|--------|
| NPC ID matching | Nameplate class-based detection is simpler and sufficient |
| Custom sound files | Text-to-speech is built-in, no sound file management needed |
| Configurable display position | Top-left default for v0.0.2, configurability later |
| Ability severity/priority ordering | All abilities show equally for now |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DISP-01 | Phase 5 | Complete |
| DISP-02 | Phase 5 | Complete |
| DISP-03 | Phase 5 | Complete |
| DISP-04 | Phase 5 | Complete |
| DISP-05 | Phase 5 | Complete |
| DISP-06 | Phase 5 | Pending |
| DISP-07 | Phase 6 | Pending |
| DISP-08 | Phase 5 | Complete |
| DATA-06 | Phase 4 | Complete |
| DATA-07 | Phase 4 | Complete |
| DATA-08 | Phase 4 | Complete |
| DATA-09 | Phase 4 | Complete |
| DETC-01 | Phase 6 | Pending |
| DETC-02 | Phase 6 | Pending |
| DETC-03 | Phase 6 | Pending |
| DETC-04 | Phase 6 | Pending |

**Coverage:**
- v0.0.2 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-03-15*
