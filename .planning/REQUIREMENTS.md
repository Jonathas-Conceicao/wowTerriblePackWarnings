# Requirements: TerriblePackWarnings

**Defined:** 2026-03-17
**Core Value:** When a player imports a route and pulls, they see accurate, timed ability warnings via custom spell icon display with per-mob detection.

## v0.1.0 Requirements

Requirements for Configuration and Skill Data milestone. Each maps to roadmap phases.

### Ability Data

- [ ] **DATA-13**: All 9 Midnight S1 dungeons have ability data files with spellIDs extracted from MDT source
- [ ] **DATA-14**: Mobs default to WARRIOR class when imported from MDT (MDT lacks class data)
- [ ] **DATA-15**: Spell names and icons resolved dynamically via C_Spell.GetSpellInfo at addon load

### Configuration UI

- [ ] **CFG-01**: Config window with left panel showing dungeon list expandable to deduplicated mobs
- [ ] **CFG-02**: Right panel shows selected mob's skills with per-skill settings
- [x] **CFG-03**: User can toggle tracking on/off for each skill via checkbox
- [x] **CFG-04**: User can set custom label per skill (current label as default, empty allowed)
- [ ] **CFG-05**: User can see WoW spell tooltip when hovering a skill in the config window

### Alerts

- [ ] **ALERT-01**: Per-skill sound alert dropdown with WoW built-in sounds (CDM-style, categorized, preview on select)
- [ ] **ALERT-02**: Per-skill editable TTS text field (current text as default)
- [ ] **ALERT-03**: Alert type is sound OR TTS per skill (mutually exclusive)

### Highlighting

- [ ] **HILITE-01**: Untimed skills highlight when any mob of same class is casting (via UnitCastingInfo nameplate polling)
- [ ] **HILITE-02**: Timed skills highlight 5 seconds before cast with configured alert

### Route Management

- [ ] **ROUTE-01**: Each dungeon stores its own imported route independently in SavedVariables
- [ ] **ROUTE-02**: TPW window has dungeon selector to switch active dungeon view
- [ ] **ROUTE-03**: Active dungeon auto-switches on zone-in via GetInstanceInfo
- [x] **ROUTE-04**: Pull rows show mob count per type (e.g. "3x Spellguard")

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Community Data

- **COMM-01**: Community-contributed warning profiles
- **COMM-02**: Shareable per-skill configuration presets

### Advanced Detection

- **DETC-05**: Refine mob classes beyond default WARRIOR based on in-game observation

## Out of Scope

| Feature | Reason |
|---------|--------|
| Combat log event parsing | Blocked by Midnight API restrictions (CLEU disabled) |
| Auto-detection of current pack without route | No reliable API |
| Route editing within TPW | Editing stays in MDT/Keystone.guru |
| Sound AND TTS simultaneously | User chose mutually exclusive alert types |
| Sound throttle | Deferred — evaluate after testing multi-mob scenarios |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CFG-01 | Phase 13 | Pending |
| CFG-02 | Phase 13 | Pending |
| CFG-03 | Phase 13 | Complete |
| CFG-04 | Phase 13 | Complete |
| CFG-05 | Phase 13 | Pending |
| ROUTE-04 | Phase 13 | Complete |
| DATA-13 | Phase 14 | Pending |
| DATA-14 | Phase 14 | Pending |
| DATA-15 | Phase 14 | Pending |
| ROUTE-01 | Phase 15 | Pending |
| ROUTE-02 | Phase 15 | Pending |
| ROUTE-03 | Phase 15 | Pending |
| HILITE-01 | Phase 16 | Pending |
| HILITE-02 | Phase 16 | Pending |
| ALERT-01 | Phase 16 | Pending |
| ALERT-02 | Phase 16 | Pending |
| ALERT-03 | Phase 16 | Pending |

**Coverage:**
- v0.1.0 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-17*
*Last updated: 2026-03-17 after roadmap revision (phase order resequenced: UI first, data second)*
