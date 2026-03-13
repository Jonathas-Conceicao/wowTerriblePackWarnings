# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-13)

**Core value:** When a player selects a pack and pulls, they see accurate, timed ability warnings for that pack's dangerous mob abilities in Blizzard's native Boss Warning UI.
**Current focus:** Phase 1 — Foundation and Data

## Current Position

Phase: 1 of 3 (Foundation and Data)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-03-13 — Roadmap revised (added FOUND-02 dev tooling to Phase 1)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: -
- Trend: -

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Manual pack selection over auto-detection: Midnight API blocks combat log and nameplate scanning
- Predefined cooldown timers over cast bar triggers: Cast bar detection unavailable in Midnight API
- Plain Lua + XML, no libraries: Keep it simple for v1
- Boss Warnings API over custom frames: Native UX, less addon UI to maintain
- Dev tooling mirrors TerribleBuffTracker: install.bat, release.bat, .pkgmeta, GitHub Actions via BigWigsMods/packager@v2

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 2]: `C_EncounterEvents` API applicability to dungeon trash content is unconfirmed — design `BossWarnings.lua` as a swappable layer from day one; validate in-game before building the full timer system around it
- [Phase 2]: `PLAYER_REGEN_DISABLED` behavior during M+ keystone runs (vs normal dungeon) not empirically verified — test before relying on it for auto-trigger

## Session Continuity

Last session: 2026-03-13
Stopped at: Roadmap revised, ready to plan Phase 1
Resume file: None
