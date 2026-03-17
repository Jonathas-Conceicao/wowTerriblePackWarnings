---
gsd_state_version: 1.0
milestone: v0.1.0
milestone_name: Configuration and Skill Data
status: roadmap_ready
stopped_at: Roadmap revised — phase order updated, ready to plan Phase 13
last_updated: "2026-03-17T00:00:00.000Z"
last_activity: 2026-03-17 -- Roadmap revised: Config UI moved first (Phase 13), data population second (Phase 14)
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-17)

**Core value:** When a player imports a route and pulls, they see accurate, timed ability warnings via custom spell icon display with per-mob detection.
**Current focus:** Phase 13 — Configuration UI and Pack Polish

## Current Position

Phase: 13 (not started)
Plan: —
Status: Roadmap approved — ready for /gsd:plan-phase 13
Last activity: 2026-03-17 — Roadmap revised: Config UI and Pack Polish moved to Phase 13 (validated against WindrunnerSpire data), Ability Data Foundation moved to Phase 14

Progress: [░░░░░░░░░░░░░░░░░░░░] 0% (0/4 phases)

## Performance Metrics

**Velocity:**
- Total plans completed: 22 (across v0.0.1-v0.0.4)
- Phases completed: 12
- Milestones shipped: 4

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [v0.1.0]: Default mobClass to WARRIOR for MDT-imported abilities
- [v0.1.0]: UnitCastingInfo polling for untimed skill cast detection
- [v0.1.0]: Per-dungeon route storage (independent routes, PackDatabase["imported"] retired)
- [v0.1.0]: CDM-style sound alert dropdown with WoW built-in sounds (67 soundKitIDs)
- [v0.1.0]: Sound and TTS are mutually exclusive per skill
- [v0.1.0]: Per-spellID alert throttle (ALERT_THROTTLE_SECONDS constant) to prevent audio stacking
- [v0.1.0 revision]: Config UI built first (Phase 13) against existing WindrunnerSpire data — proves the tree before populating 8 more dungeons

### Roadmap Evolution

- Phases 1-3: v0.0.1 MVP (shipped)
- Phases 4-7: v0.0.2 Display Rework (shipped)
- Phases 8-10: v0.0.3 MDT Import (shipped)
- Phases 11-12: v0.0.4 Cleanup and Polish (shipped)
- Phases 13-16: v0.1.0 Configuration and Skill Data (active)
  - Phase 13: Config UI and Pack Polish (uses WindrunnerSpire to validate)
  - Phase 14: Ability Data Foundation (populate remaining 8 dungeons after UI proven)
  - Phase 15: Per-Dungeon Route Storage (structural refactor)
  - Phase 16: Cast Detection and Sound Alerts (engine features last)

### Phase Dependency Chain

Phase 13 (UI) → Phase 14 (data) → Phase 15 (structural refactor) → Phase 16 (engine)

### Critical Pitfalls (from research)

- Phase 14: Every spellID must be validated via C_Spell.GetSpellInfo in-game — MDT spells tables are always empty ({})
- Phase 15: `PackDatabase["imported"]` retirement must be atomic across Pipeline.lua, CombatWatcher.lua, PackFrame.lua, Import.lua — grep all four before shipping
- Phase 15: Add `schemaVersion` to TerriblePackWarningsDB before writing v0.1.0 fields; migrate `importedRoute` → `importedRoutes` on ADDON_LOADED
- Phase 16: Build spellID O(1) lookup index at NameplateScanner:Start() time — never iterate ability list per nameplate per tick
- Phase 16: Alert throttle table must be built simultaneously with PlaySound, not deferred
- Phase 16: Validate UnitCastingInfo("nameplateN") in first in-dungeon test session (documented as PvP-restricted only, not dungeon-blocked)

### Pending Todos

None yet.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-03-17
Stopped at: Roadmap revised — phase order updated, ready to plan Phase 13
Resume file: None
Next action: /gsd:plan-phase 13
