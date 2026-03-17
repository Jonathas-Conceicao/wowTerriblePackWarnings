# Roadmap: TerriblePackWarnings

## Milestones

- v0.0.1 MVP Proof of Concept -- Phases 1-3 (shipped 2026-03-15)
- v0.0.2 Display Rework -- Phases 4-7 (shipped 2026-03-16)
- v0.0.3 MDT Import -- Phases 8-10 (shipped 2026-03-16)
- v0.0.4 Cleanup and Polish -- Phases 11-12 (shipped 2026-03-16)
- v0.1.0 Configuration and Skill Data -- Phases 13-16 (active)

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

<details>
<summary>v0.0.3 MDT Import (Phases 8-10) -- SHIPPED 2026-03-16</summary>

- [x] Phase 8: Ability Database and Decode Library (2/2 plans) -- completed 2026-03-16
- [x] Phase 9: Import Pipeline (2/2 plans) -- completed 2026-03-16
- [x] Phase 10: Route UI Overhaul (1/1 plans) -- completed 2026-03-16

See: `.planning/milestones/v0.0.3-ROADMAP.md` for full details.

</details>

<details>
<summary>v0.0.4 Cleanup and Polish (Phases 11-12) -- SHIPPED 2026-03-16</summary>

- [x] Phase 11: Documentation and CI (1/1 plans) -- completed 2026-03-16
- [x] Phase 12: Code Cleanup (1/1 plans) -- completed 2026-03-16

See: `.planning/milestones/v0.0.4-ROADMAP.md` for full details.

</details>

### v0.1.0 Configuration and Skill Data (Phases 13-16)

- [x] **Phase 13: Configuration UI and Pack Polish** - Config tree, dungeon selector, and mob count display validated against existing WindrunnerSpire data (completed 2026-03-17)
- [ ] **Phase 14: Ability Data Foundation** - All remaining 8 dungeon AbilityDB files authored and visible in the proven config UI
- [ ] **Phase 15: Per-Dungeon Route Storage** - Structural refactor retiring `PackDatabase["imported"]` across all four dependent files; auto-switching on zone-in
- [ ] **Phase 16: Cast Detection and Sound Alerts** - Untimed skill highlighting via UnitCastingInfo nameplate polling; per-skill sound alert with throttle

## Phase Details

### Phase 13: Configuration UI and Pack Polish
**Goal**: Players can open a config window to see dungeon mobs and skills, toggle or customize per-skill settings, and the pack selection window shows mob counts per portrait — validated immediately against the existing WindrunnerSpire ability data
**Depends on**: Nothing (WindrunnerSpire.lua already has 4 abilities; no new data required to build and test the UI)
**Requirements**: CFG-01, CFG-02, CFG-03, CFG-04, CFG-05, ROUTE-04
**Success Criteria** (what must be TRUE):
  1. Opening the config window with a WindrunnerSpire route loaded shows a left panel with the dungeon expanding to its deduplicated mob list, each mob expanding to its ability rows
  2. Selecting a WindrunnerSpire ability in the left panel shows its settings on the right: enabled checkbox, custom label field, TTS text field, and sound dropdown
  3. Disabling a WindrunnerSpire ability via checkbox removes its icon from the display on the next pack activation — the icon does not appear even if the mob is detected
  4. Setting a custom label for a WindrunnerSpire ability shows that label on the spell icon display instead of the default spell name
  5. Hovering an ability row in the config window shows the WoW spell tooltip for that spellID
  6. Each pull row in the TPW window shows a count for each mob type (e.g., "3x Spellguard") rather than unlabeled portrait icons
**Plans:** 3/3 plans complete
Plans:
- [x] 13-01-PLAN.md -- Data layer: Sounds.lua, MergeSkillConfig, mobCounts, skillConfig init, TOC
- [x] 13-02-PLAN.md -- PackFrame mob count overlays and Config button (ROUTE-04)
- [x] 13-03-PLAN.md -- ConfigFrame window with dungeon-mob tree and per-skill settings (CFG-01 through CFG-05)

### Phase 14: Ability Data Foundation
**Goal**: All 9 Midnight S1 dungeon ability data files exist with valid spellIDs, WARRIOR defaults, and dynamically resolved spell names and icons — and all dungeons are immediately visible and navigable in the config UI from Phase 13
**Depends on**: Phase 13 (config UI must exist so new dungeon data files surface there for validation)
**Requirements**: DATA-13, DATA-14, DATA-15
**Success Criteria** (what must be TRUE):
  1. Opening the config window shows all 9 dungeons in the left panel, each expandable to its mob list with ability rows
  2. Every mob in all 9 dungeons defaults to WARRIOR class so the nameplate scanner can match them on import
  3. Spell names and icons for all dungeons resolve without a manual cache — they appear correctly on first window open after addon load with no grey question marks
**Plans:** 2 plans
Plans:
- [ ] 14-01-PLAN.md -- defaultEnabled mechanism in MergeSkillConfig/ConfigFrame + WindrunnerSpire MDT reconciliation
- [ ] 14-02-PLAN.md -- 8 new dungeon AbilityDB data files + TOC and install.bat updates

### Phase 15: Per-Dungeon Route Storage
**Goal**: Each dungeon holds its own imported route independently; the addon correctly restores multi-dungeon state on load and auto-selects the right dungeon on zone-in
**Depends on**: Phase 14 (all 9 dungeon AbilityDB files must exist so zone keys map to real dungeon data)
**Requirements**: ROUTE-01, ROUTE-02, ROUTE-03
**Success Criteria** (what must be TRUE):
  1. Importing a route for Dungeon A then importing a route for Dungeon B leaves Dungeon A's route intact — both are retrievable independently
  2. After a /reload, previously imported routes for all dungeons are still present with no re-import required
  3. Entering a Midnight S1 dungeon zone automatically switches the active dungeon view to match, with no manual selection needed
**Plans**: TBD

### Phase 16: Cast Detection and Sound Alerts
**Goal**: Untimed skills light up when a same-class mob is casting, timed skills pre-warn at 5 seconds with a configured sound or TTS, and alert stacking is throttled when multiple mobs cast the same ability
**Depends on**: Phase 15 (per-dungeon keys must exist so the active pack has a dungeon context for ability lookup)
**Requirements**: HILITE-01, HILITE-02, ALERT-01, ALERT-02, ALERT-03
**Success Criteria** (what must be TRUE):
  1. When a WARRIOR-class mob begins casting an untimed ability, the corresponding icon on the display lights up within one 0.25s poll tick and clears when the cast ends
  2. A timed skill's icon shows a red glow and plays its configured alert (sound or TTS) exactly 5 seconds before the predicted cast
  3. When five mobs of the same class cast the same untimed ability simultaneously, only one alert sound plays per throttle window (no audio stacking)
  4. A player can assign any of the WoW built-in CDM sounds to a skill via a dropdown and hear a preview on selection
  5. Each skill has exactly one active alert type — switching to sound disables TTS for that skill and vice versa
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation and Data | v0.0.1 | 2/2 | Complete | 2026-03-14 |
| 2. Warning Engine and Combat Integration | v0.0.1 | 4/4 | Complete | 2026-03-15 |
| 3. Pack Selection UI | v0.0.1 | 2/2 | Complete | 2026-03-15 |
| 4. Data Schema and Pack Update | v0.0.2 | 1/1 | Complete | 2026-03-15 |
| 5. Custom Spell Icon Display | v0.0.2 | 2/2 | Complete | 2026-03-15 |
| 6. Nameplate Detection and Mob Lifecycle | v0.0.2 | 2/2 | Complete | 2026-03-15 |
| 7. Complete Dungeon Route | v0.0.2 | 2/2 | Complete | 2026-03-16 |
| 8. Ability Database and Decode Library | v0.0.3 | 2/2 | Complete | 2026-03-16 |
| 9. Import Pipeline | v0.0.3 | 2/2 | Complete | 2026-03-16 |
| 10. Route UI Overhaul | v0.0.3 | 1/1 | Complete | 2026-03-16 |
| 11. Documentation and CI | v0.0.4 | 1/1 | Complete | 2026-03-16 |
| 12. Code Cleanup | v0.0.4 | 1/1 | Complete | 2026-03-16 |
| 13. Configuration UI and Pack Polish | v0.1.0 | 3/3 | Complete | 2026-03-17 |
| 14. Ability Data Foundation | v0.1.0 | 0/2 | Not started | - |
| 15. Per-Dungeon Route Storage | v0.1.0 | 0/? | Not started | - |
| 16. Cast Detection and Sound Alerts | v0.1.0 | 0/? | Not started | - |
