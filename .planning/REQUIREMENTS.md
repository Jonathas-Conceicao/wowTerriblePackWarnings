# Requirements: TerriblePackWarnings

**Defined:** 2026-03-16
**Core Value:** Clean up, polish, and prepare the addon for broader testing.

## v0.0.4 Requirements

### Documentation

- [ ] **DOC-01**: README.md with project description, WIP notice, gallery (ws_fst_pack.png), features, usage, known issues, AI usage, license
- [ ] **DOC-02**: TOC updated with CurseForge project ID 1487612, Wago ID ZKbxadN1, and blp icon texture

### CI/Release

- [ ] **CI-01**: Release workflow and .pkgmeta match TerribleBuffTracker patterns (secrets, ignore list, package-as)
- [ ] **CI-02**: Release script (scripts/release.bat) works end-to-end

### Code Cleanup

- [ ] **CLEAN-01**: Remove all DEBUG flags and dbg() logging from production code
- [ ] **CLEAN-02**: Remove /tpw show and /tpw hide debug commands
- [ ] **CLEAN-03**: Remove unused variables, especially globals; remove single-use function/identifier definitions where inlining is clearer
- [ ] **CLEAN-04**: Audit and document any hot paths in the game loop (0.25s nameplate scanner tick) for review

## Out of Scope

| Feature | Reason |
|---------|--------|
| New features or abilities | This is a cleanup milestone only |
| CurseForge/Wago publishing | Just add the IDs, actual publishing is manual |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DOC-01 | Phase 11 | Pending |
| DOC-02 | Phase 11 | Pending |
| CI-01 | Phase 11 | Pending |
| CI-02 | Phase 11 | Pending |
| CLEAN-01 | Phase 12 | Pending |
| CLEAN-02 | Phase 12 | Pending |
| CLEAN-03 | Phase 12 | Pending |
| CLEAN-04 | Phase 12 | Pending |

**Coverage:**
- v0.0.4 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0

---
*Requirements defined: 2026-03-16*
