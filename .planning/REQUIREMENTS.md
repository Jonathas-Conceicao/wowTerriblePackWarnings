# Requirements: TerriblePackWarnings

**Defined:** 2026-03-23
**Core Value:** When a player imports a route and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities via custom spell icon display with per-mob detection and configurable alerts.

## v0.1.1 Requirements

Requirements for mob category milestone. Each maps to roadmap phases.

### Data Layer

- [x] **DATA-01**: Every AbilityDB npcID entry has a `mobCategory` field with one of: `"boss"`, `"miniboss"`, `"caster"`, `"warrior"`, `"rogue"`, `"trivial"`, `"unknown"`
- [x] **DATA-02**: All 22 Skyreach mobs have their correct category assigned per the provided table
- [x] **DATA-03**: All mobs in the other 8 dungeons have `mobCategory = "unknown"` as explicit default
- [x] **DATA-04**: `mobClass` (WoW class token) and `mobCategory` (semantic role) are clearly distinct fields with no naming confusion

### Runtime Detection

- [x] **DETC-01**: `UnitClassification` is cached per nameplate unit at `NAME_PLATE_UNIT_ADDED` in `plateCache`
- [x] **DETC-02**: `UNIT_CLASSIFICATION_CHANGED` event is registered and updates the classification cache
- [x] **DETC-03**: `UnitIsLieutenant` is called with `pcall` wrapping and cached alongside classification
- [x] **DETC-04**: `DeriveCategory()` helper combines classification + lieutenant + classBase into a category string
- [x] **DETC-05**: Runtime-derived category is cached per nameplate unit in `plateCache`, not per classBase

### Scanner Matching

- [x] **SCAN-01**: Scanner reads mob category from `ns.AbilityDB[npcID]` directly at match time (no duplication)
- [x] **SCAN-02**: Mobs with `mobCategory == "unknown"` pass all category checks (wildcard — false positives over false negatives)
- [x] **SCAN-03**: Mobs with a known category only trigger abilities when runtime-detected category matches

### Config Display

- [x] **UI-01**: Mob header row in config tree shows a read-only color-coded category tag (e.g., `[Caster]`)
- [x] **UI-02**: Category tag is non-editable — purely informational display
- [x] **UI-03**: Config search matches mob category (e.g., searching "boss", "mini-boss", "miniboss", "rogue" shows matching mobs)

### Dungeon Category Index

- [x] **CAT-01**: Every AbilityDB entry in all 7 dungeon data files (WindrunnerSpire, AlgetharAcademy, MagistersTerrace, MaisaraCaverns, NexusPointXenas, PitOfSaron, SeatoftheTriumvirate) has its correct `mobCategory` from MobCategories.md
- [x] **CAT-02**: No mob with a known category still has `mobCategory = "unknown"` — only genuinely unknown mobs retain the unknown value
- [x] **CAT-03**: All 10 coverage-gap stubs added for full AbilityDB coverage (232071, 238049, 197398, 234089, 234067, 249711, 251852, 252557, 122412, 255551)
- [x] **CAT-04**: No `isBoss` field exists anywhere in DungeonEnemies.lua
- [x] **CAT-05**: PackFrame boss detection uses `ns.AbilityDB[npcID].mobCategory == "boss"` instead of the removed `npcIdIsBoss` lookup table
- [x] **CAT-06**: Mindless Laborer (npcID 252557, displayId 137487) is present in both DungeonEnemies.lua (Pit of Saron section) and PitOfSaron.lua (AbilityDB stub)

## Future Requirements

### Dungeon Expansion

- **DATA-05**: Expand category assignments to remaining 8 dungeons after Skyreach accuracy is confirmed in-game

### Category Enhancements

- **UI-04**: Color-coded category display in PackFrame portrait rows
- **DETC-06**: Validate UnitIsLieutenant behavior and remove pcall if confirmed stable

## Out of Scope

| Feature | Reason |
|---------|--------|
| User-editable categories | Categories are factual properties of NPCs; user overrides create silent filter breakage |
| Per-category sound/alert override | Defer until base category system is validated useful |
| categoryFilter SavedVariable | Redundant — abilities already default off, users opt-in per skill |
| Category filter checkboxes in UI | No category filter to toggle — unnecessary second layer |
| UnitEffectiveLevel for detection | Unusable on nameplates — takes cstring name arg, UnitName is Secret Value in instances |
| Pipeline propagation of category | Duplication — scanner reads from AbilityDB directly |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 19 | Complete |
| DATA-02 | Phase 19 | Complete |
| DATA-03 | Phase 19 | Complete |
| DATA-04 | Phase 19 | Complete |
| DETC-01 | Phase 20 | Complete |
| DETC-02 | Phase 20 | Complete |
| DETC-03 | Phase 20 | Complete |
| DETC-04 | Phase 20 | Complete |
| DETC-05 | Phase 20 | Complete |
| SCAN-01 | Phase 20 | Complete |
| SCAN-02 | Phase 20 | Complete |
| SCAN-03 | Phase 20 | Complete |
| UI-01 | Phase 21 | Complete |
| UI-02 | Phase 21 | Complete |
| UI-03 | Phase 21 | Complete |
| CAT-01 | Phase 22 | Planned |
| CAT-02 | Phase 22 | Planned |
| CAT-03 | Phase 22 | Planned |
| CAT-04 | Phase 22 | Planned |
| CAT-05 | Phase 22 | Planned |
| CAT-06 | Phase 22 | Planned |

**Coverage:**
- v0.1.1 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0

---
*Requirements defined: 2026-03-23*
*Last updated: 2026-03-24 after Phase 22 planning*
