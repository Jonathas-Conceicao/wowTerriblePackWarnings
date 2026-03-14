# Roadmap: TerriblePackWarnings

## Overview

Build a WoW Midnight addon that gives M+ players DBM-style ability warnings on dungeon trash packs. The work proceeds in architectural dependency order: first a correct, loadable skeleton with a well-defined data schema and full dev tooling for local iteration and automated releases; then the warning engine and combat event wiring that form the entire value proposition; finally the pack selection UI that surfaces it all to the player. Each phase can be partially validated in-game before the next begins.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation and Data** - Loadable addon skeleton with correct TOC, namespace, a fully-specified pack/ability database for one dungeon, and dev tooling for local install and automated GitHub releases (completed 2026-03-14)
- [ ] **Phase 2: Warning Engine and Combat Integration** - Timer scheduler, Boss Warnings display, and combat event wiring that delivers working in-game ability warnings
- [ ] **Phase 3: Pack Selection UI** - Scrollable grouped pack list with click-to-select, active state indicator, and slash command entry point

## Phase Details

### Phase 1: Foundation and Data
**Goal**: Players can load the addon in WoW Midnight and all pack/ability data for one dungeon is queryable via the Lua console; developers can install locally with one command and publish releases via git tag
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, DATA-01, DATA-02
**Success Criteria** (what must be TRUE):
  1. Addon appears in the WoW addon list and loads without Lua errors on a fresh install with `## Interface: 120001`
  2. `/run print(TPW.PackDatabase)` prints a non-nil table from the Lua console
  3. Every ability entry in the database has both a `first_cast` offset and a `cooldown` repeat interval
  4. `/reload` completes without taint errors or secret value violations
  5. Running `scripts/install.bat` copies addon files to the local WoW AddOns folder without error
  6. Pushing a git tag triggers the GitHub Actions release workflow and produces a packaged release artifact via BigWigsMods/packager
**Plans:** 2/2 plans complete

Plans:
- [ ] 01-01-PLAN.md — Addon skeleton: TOC, Core.lua namespace/events, and Windrunner Spire pack data
- [ ] 01-02-PLAN.md — Dev tooling: install.bat, release.bat, .pkgmeta, GitHub Actions release workflow

### Phase 2: Warning Engine and Combat Integration
**Goal**: Selecting a pack and pulling causes timed ability warnings to appear in the Boss Warnings UI (or fallback frame) and all timers clean up correctly on combat end or zone change
**Depends on**: Phase 1
**Requirements**: WARN-01, WARN-02, WARN-03, CMBT-01, CMBT-02, CMBT-03
**Success Criteria** (what must be TRUE):
  1. Running `/run TPW.Scheduler:Start("pack_key")` in the Lua console triggers ability warnings at the correct offsets
  2. Warnings appear in Blizzard's Boss Warnings UI during a dungeon trash pull; a custom fallback frame displays if the Boss Warnings API does not support trash content
  3. Entering combat with a pack selected auto-starts timers via `PLAYER_REGEN_DISABLED`
  4. All timers stop and no ghost warnings fire after combat ends (`PLAYER_REGEN_ENABLED`) or after a zone change (`PLAYER_ENTERING_WORLD`)
**Plans**: TBD

### Phase 3: Pack Selection UI
**Goal**: Players can open the addon, browse and select a pack from a grouped list, see which pack is active, and trigger a pull — all without touching the Lua console
**Depends on**: Phase 2
**Requirements**: UI-01, UI-02, UI-03, UI-04
**Success Criteria** (what must be TRUE):
  1. `/tpw` opens a window containing a scrollable list of packs organized by dungeon area
  2. Clicking a pack in the list selects it and highlights it as the active pack
  3. The highlighted pack persists visually until a different pack is selected or combat resets state
  4. A pull button or combat entry with the selected pack starts the warning engine without any console commands
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation and Data | 2/2 | Complete   | 2026-03-14 |
| 2. Warning Engine and Combat Integration | 0/TBD | Not started | - |
| 3. Pack Selection UI | 0/TBD | Not started | - |
