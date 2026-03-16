# Roadmap: TerriblePackWarnings

## Milestones

- v0.0.1 MVP Proof of Concept -- Phases 1-3 (shipped 2026-03-15)
- v0.0.2 Display Rework -- Phases 4-7 (shipped 2026-03-16)
- v0.0.3 MDT Import -- Phases 8-10 (shipped 2026-03-16)
- v0.0.4 Cleanup and Polish -- Phases 11-12 (in progress)

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

### v0.0.4 Cleanup and Polish (In Progress)

- [x] **Phase 11: Documentation and CI** - README, TOC metadata, release workflow, and release script (completed 2026-03-16)
- [x] **Phase 12: Code Cleanup** - Remove debug artifacts, unused code, and audit hot paths (completed 2026-03-16)

## Phase Details

### Phase 11: Documentation and CI
**Goal**: The addon is presentable and releasable -- README describes the project, TOC has correct project IDs, and CI can produce a release
**Depends on**: Phase 10
**Requirements**: DOC-01, DOC-02, CI-01, CI-02
**Success Criteria** (what must be TRUE):
  1. A user visiting the GitHub repo sees a README with project description, WIP notice, feature list, usage instructions, gallery screenshot, known issues, AI disclosure, and license
  2. The TOC file contains CurseForge project ID 1487612, Wago ID ZKbxadN1, and references a blp icon texture
  3. The GitHub Actions release workflow and .pkgmeta match TerribleBuffTracker patterns (secrets, ignore list, package-as)
  4. Running scripts/release.bat produces a working release package end-to-end
**Plans:** 1/1 plans complete
Plans:
- [x] 11-01-PLAN.md -- Create README, update TOC metadata, verify CI/release pipeline

### Phase 12: Code Cleanup
**Goal**: Production code contains no debug artifacts, no dead code, and hot paths are documented for future optimization
**Depends on**: Phase 11
**Requirements**: CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04
**Success Criteria** (what must be TRUE):
  1. No DEBUG flags or dbg() calls exist anywhere in the shipped Lua files
  2. The /tpw slash command handler has no show or hide debug subcommands
  3. No unused global variables or single-use wrapper functions remain where inlining is clearer
  4. The 0.25s nameplate scanner tick and any other game-loop hot paths have inline comments documenting their cost and review status
**Plans:** 1/1 plans complete
Plans:
- [ ] 12-01-PLAN.md -- Remove debug artifacts, dead code, and audit hot paths

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
| 11. Documentation and CI | v0.0.4 | Complete    | 2026-03-16 | 2026-03-16 |
| 12. Code Cleanup | 1/1 | Complete    | 2026-03-16 | - |
