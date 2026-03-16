# Requirements: TerriblePackWarnings

**Defined:** 2026-03-16
**Core Value:** Clean up, polish, and prepare the addon for broader testing.

## v0.0.4 Requirements

### Documentation

- [x] **DOC-01**: README.md with project description, WIP notice, gallery (ws_fst_pack.png), features, usage, known issues, AI usage, license
- [x] **DOC-02**: TOC updated with CurseForge project ID 1487612, Wago ID ZKbxadN1, and blp icon texture

### CI/Release

- [x] **CI-01**: Release workflow and .pkgmeta match TerribleBuffTracker patterns (secrets, ignore list, package-as)
- [x] **CI-02**: Release script (scripts/release.bat) works end-to-end

### Code Cleanup

- [x] **CLEAN-01**: Remove all DEBUG flags and dbg() logging from production code
- [x] **CLEAN-02**: Remove /tpw show and /tpw hide debug commands
- [x] **CLEAN-03**: Remove unused variables, especially globals; remove single-use function/identifier definitions where inlining is clearer
- [x] **CLEAN-04**: Audit and document any hot paths in the game loop (0.25s nameplate scanner tick) for review

## Out of Scope

| Feature | Reason |
|---------|--------|
| New features or abilities | This is a cleanup milestone only |
| CurseForge/Wago publishing | Just add the IDs, actual publishing is manual |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DOC-01 | Phase 11 | Complete |
| DOC-02 | Phase 11 | Complete |
| CI-01 | Phase 11 | Complete |
| CI-02 | Phase 11 | Complete |
| CLEAN-01 | Phase 12 | Complete |
| CLEAN-02 | Phase 12 | Complete |
| CLEAN-03 | Phase 12 | Complete |
| CLEAN-04 | Phase 12 | Complete |

**Coverage:**
- v0.0.4 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0

---
*Requirements defined: 2026-03-16*
