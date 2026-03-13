# Requirements: TerriblePackWarnings

**Defined:** 2026-03-13
**Core Value:** When a player selects a pack and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities in Blizzard's native Boss Warning UI.

## v1 Requirements

Requirements for initial proof of concept. Each maps to roadmap phases.

### Foundation

- [ ] **FOUND-01**: Addon loads in WoW Midnight with correct TOC (Interface 120001), namespace, and SavedVariables

### Data

- [ ] **DATA-01**: Predefined pack/mob database for one Midnight dungeon with ability names and cooldown timers
- [ ] **DATA-02**: Each ability entry includes first-cast offset and repeat cooldown

### Warning Engine

- [ ] **WARN-01**: Timer scheduler starts ability cooldown timers when a pack pull is triggered
- [ ] **WARN-02**: Warnings display through Blizzard's Boss Warnings API (with fallback frame if API doesn't support trash)
- [ ] **WARN-03**: All active timers cancel on combat end or zone change

### Combat Integration

- [ ] **CMBT-01**: Manual pull trigger button starts timers for the selected pack
- [ ] **CMBT-02**: PLAYER_REGEN_DISABLED/ENABLED detection for automatic combat start/end
- [ ] **CMBT-03**: State resets on PLAYER_ENTERING_WORLD (zone change)

### UI

- [ ] **UI-01**: Scrollable pack list grouped by dungeon area
- [ ] **UI-02**: Click-to-select a pack from the list
- [ ] **UI-03**: Visual indicator showing which pack is currently active/selected
- [ ] **UI-04**: Slash command `/tpw` to open the addon

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Data Expansion

- **DATA-03**: Pack/mob database for all Midnight M+ dungeons
- **DATA-04**: Ability severity tiers (interrupt, dodge, defensive, informational)
- **DATA-05**: Role-specific ability relevance tags (tank, healer, DPS)

### Advanced Detection

- **CMBT-04**: Auto-detection of current pack via route integration
- **CMBT-05**: MDT/Keystone.guru route import and pack tracking

### UI Enhancements

- **UI-05**: Map-based visual pack picker
- **UI-06**: Pack search/filter
- **UI-07**: Minimap button for quick access
- **UI-08**: Customizable warning sounds and colors

### Social

- **SOCL-01**: Community-contributed ability data profiles
- **SOCL-02**: Import/export pack warning profiles

## Out of Scope

| Feature | Reason |
|---------|--------|
| Combat log event parsing | Blocked by Midnight Secret Values API restriction |
| Nameplate scanning | Blocked by Midnight API restrictions |
| Real-time cast bar detection | Blocked by Midnight API restrictions |
| Auto-pack-detection without route addon | No reliable API available |
| Mobile companion app | Desktop addon only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | — | Pending |
| DATA-01 | — | Pending |
| DATA-02 | — | Pending |
| WARN-01 | — | Pending |
| WARN-02 | — | Pending |
| WARN-03 | — | Pending |
| CMBT-01 | — | Pending |
| CMBT-02 | — | Pending |
| CMBT-03 | — | Pending |
| UI-01 | — | Pending |
| UI-02 | — | Pending |
| UI-03 | — | Pending |
| UI-04 | — | Pending |

**Coverage:**
- v1 requirements: 13 total
- Mapped to phases: 0
- Unmapped: 13 ⚠️

---
*Requirements defined: 2026-03-13*
*Last updated: 2026-03-13 after initial definition*
