# Roadmap: TerriblePackWarnings

## Milestones

- v0.0.1 MVP Proof of Concept -- Phases 1-3 (shipped 2026-03-15)
- v0.0.2 Display Rework -- Phases 4-7 (shipped 2026-03-16)
- v0.0.3 MDT Import -- Phases 8-10 (in progress)

## Phases

<details>
<summary>v0.0.1 MVP Proof of Concept (Phases 1-3) -- SHIPPED 2026-03-15</summary>

- [x] Phase 1: Foundation and Data (2/2 plans) -- completed 2026-03-14
- [x] Phase 2: Warning Engine and Combat Integration (4/4 plans) -- completed 2026-03-15
- [x] Phase 3: Pack Selection UI (2/2 plans) -- completed 2026-03-15

See: `.planning/milestones/v0.0.1-ROADMAP.md` for full details.

</details>

<details>
<summary>v0.0.2 Display Rework (Phases 4-7) -- SHIPPED 2026-03-16</summary>

- [x] Phase 4: Data Schema and Pack Update (1/1 plans) -- completed 2026-03-15
- [x] Phase 5: Custom Spell Icon Display (2/2 plans) -- completed 2026-03-15
- [x] Phase 6: Nameplate Detection and Mob Lifecycle (2/2 plans) -- completed 2026-03-15
- [x] Phase 7: Complete Dungeon Route (2/2 plans) -- completed 2026-03-16

See: `.planning/milestones/v0.0.2-ROADMAP.md` for full details.

</details>

### v0.0.3 MDT Import (In Progress)

- [x] **Phase 8: Ability Database and Decode Library** - NpcID-keyed ability data and LibDeflate+AceSerializer decoding (completed 2026-03-16)
- [x] **Phase 9: Import Pipeline** - Extract pulls from decoded data and dynamically build packs (completed 2026-03-16)
- [x] **Phase 10: Route UI Overhaul** - MDT-style pull display with NPC portraits, import/clear controls (completed 2026-03-16)

## Phase Details

### Phase 8: Ability Database and Decode Library
**Goal**: Addon has an npcID-keyed ability database and can decode MDT export strings into raw Lua tables
**Depends on**: Phase 7
**Requirements**: DATA-10, DATA-11, IMPORT-01
**Success Criteria** (what must be TRUE):
  1. Each npcID in the database maps to its abilities with cooldown, label, tts, and mobClass fields
  2. Multiple npcIDs can reference the same ability spell (shared ability support works)
  3. An MDT export string pasted in-game decodes into a Lua table without errors
**Plans**: 2 plans
Plans:
- [ ] 08-01-PLAN.md — AbilityDB data rewrite and library bundling
- [ ] 08-02-PLAN.md — MDT decode utility and /tpw decode command

### Phase 9: Import Pipeline
**Goal**: Decoded MDT data produces a fully populated PackDatabase with per-pull ability warnings ready for combat
**Depends on**: Phase 8
**Requirements**: IMPORT-02, IMPORT-03, IMPORT-04, DATA-12
**Success Criteria** (what must be TRUE):
  1. Pull list with npcIDs is correctly extracted from decoded MDT preset data
  2. Each pull's npcIDs are matched against the ability database to produce pack abilities with correct mobClasses
  3. PackDatabase is populated from imported route data (no hardcoded pack definitions used)
  4. Selecting an imported pack and pulling mobs triggers the existing warning/timer system
**Plans**: 2 plans
Plans:
- [ ] 09-01-PLAN.md — DungeonEnemies data bundle and import pipeline module
- [ ] 09-02-PLAN.md — Core.lua wiring, TOC load order, and PackFrame UI update

### Phase 10: Route UI Overhaul
**Goal**: Player can paste an MDT string, see indexed pulls with NPC portraits, and manage imported routes
**Depends on**: Phase 9
**Requirements**: UI-09, UI-10, UI-11, UI-12
**Success Criteria** (what must be TRUE):
  1. Pack list shows numbered pulls with round NPC portrait icons for each mob in the pull
  2. Import button opens a text editbox where player can paste an MDT/Keystone.guru export string
  3. Clear button removes all imported route data and empties the pack list
  4. UI header displays the imported dungeon name and total pull count
**Plans**: 1 plan
Plans:
- [ ] 10-01-PLAN.md — PackFrame rewrite with pull rows, portraits, import popup, and clear confirmation

## Progress

**Execution Order:** Phases execute in numeric order: 8 -> 9 -> 10

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation and Data | v0.0.1 | 2/2 | Complete | 2026-03-14 |
| 2. Warning Engine and Combat Integration | v0.0.1 | 4/4 | Complete | 2026-03-15 |
| 3. Pack Selection UI | v0.0.1 | 2/2 | Complete | 2026-03-15 |
| 4. Data Schema and Pack Update | v0.0.2 | 1/1 | Complete | 2026-03-15 |
| 5. Custom Spell Icon Display | v0.0.2 | 2/2 | Complete | 2026-03-15 |
| 6. Nameplate Detection and Mob Lifecycle | v0.0.2 | 2/2 | Complete | 2026-03-15 |
| 7. Complete Dungeon Route | v0.0.2 | 2/2 | Complete | 2026-03-16 |
| 8. Ability Database and Decode Library | 2/2 | Complete   | 2026-03-16 | - |
| 9. Import Pipeline | 2/2 | Complete   | 2026-03-16 | - |
| 10. Route UI Overhaul | 1/1 | Complete    | 2026-03-16 | - |
