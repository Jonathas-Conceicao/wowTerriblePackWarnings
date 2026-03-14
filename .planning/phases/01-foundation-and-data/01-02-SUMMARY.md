---
phase: 01-foundation-and-data
plan: 02
subsystem: infra
tags: [batch-scripts, github-actions, bigwigsmods-packager, ci-cd, pkgmeta]

# Dependency graph
requires: []
provides:
  - "Local install script (scripts/install.bat) for copying addon to WoW AddOns folder"
  - "Release script (scripts/release.bat) for creating git tags and triggering CI"
  - "BigWigsMods/packager config (.pkgmeta) with package-as name and ignore list"
  - "GitHub Actions release workflow (.github/workflows/release.yml) triggered on tag push"
affects: []

# Tech tracking
tech-stack:
  added: [BigWigsMods/packager@v2, actions/checkout@v4]
  patterns: [tag-triggered-release, local-install-script]

key-files:
  created:
    - scripts/install.bat
    - scripts/release.bat
    - .pkgmeta
    - .github/workflows/release.yml
  modified: []

key-decisions:
  - "Added .planning and .github to .pkgmeta ignore list (not in reference project)"
  - "Added .git to .pkgmeta ignore list for completeness"

patterns-established:
  - "Dev tooling mirrors TerribleBuffTracker: install.bat copies to WoW AddOns, release.bat tags and pushes"
  - "Release pipeline: git tag push -> GitHub Actions -> BigWigsMods/packager@v2"

requirements-completed: [FOUND-02]

# Metrics
duration: 1min
completed: 2026-03-13
---

# Phase 1 Plan 2: Dev Tooling Summary

**Local install script, release tagging script, .pkgmeta config, and GitHub Actions CI pipeline mirroring TerribleBuffTracker**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-14T01:59:23Z
- **Completed:** 2026-03-14T02:00:27Z
- **Tasks:** 2
- **Files created:** 4

## Accomplishments
- install.bat copies TOC, Core.lua, and Data/WindrunnerSpire.lua to WoW AddOns folder with proper Data/ subfolder mkdir
- release.bat accepts version argument, creates annotated git tag, pushes to origin with error handling
- .pkgmeta configures BigWigsMods/packager with TerriblePackWarnings package name and comprehensive ignore list
- GitHub Actions release workflow triggers on any tag push and runs BigWigsMods/packager@v2

## Task Commits

Each task was committed atomically:

1. **Task 1: Create install.bat and release.bat scripts** - `fe8a926` (feat)
2. **Task 2: Create .pkgmeta and GitHub Actions release workflow** - `2316557` (feat)

## Files Created/Modified
- `scripts/install.bat` - Copies addon files including Data/ subfolder to WoW AddOns directory
- `scripts/release.bat` - Creates annotated git tag and pushes to trigger CI
- `.pkgmeta` - BigWigsMods/packager config with package-as name and ignore patterns
- `.github/workflows/release.yml` - GitHub Actions workflow using BigWigsMods/packager@v2

## Decisions Made
- Added .planning, .github, and .git to .pkgmeta ignore list (not present in TerribleBuffTracker reference but needed for this project)
- CF_API_KEY and WAGO_API_TOKEN left commented out in workflow (ready for future use when API keys are available)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Dev tooling complete; developer can install addon locally via install.bat once addon source files (TOC, Core.lua, Data/) exist
- Release pipeline ready; pushing a git tag will trigger GitHub Actions to package the addon
- Addon source files (from Plan 01) are prerequisite for install.bat to work end-to-end

---
*Phase: 01-foundation-and-data*
*Completed: 2026-03-13*
