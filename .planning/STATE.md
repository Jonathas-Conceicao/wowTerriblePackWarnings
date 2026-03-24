---
gsd_state_version: 1.0
milestone: v0.0
milestone_name: milestone
status: planning
stopped_at: Completed 22-02-PLAN.md
last_updated: "2026-03-24T06:23:37.970Z"
last_activity: 2026-03-23 — Roadmap created, 3 phases defined (19-21)
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 6
  completed_plans: 6
---

---
gsd_state_version: 1.0
milestone: v0.0
milestone_name: milestone
status: planning
stopped_at: Completed 22-02-PLAN.md
last_updated: "2026-03-24T06:04:14.978Z"
last_activity: 2026-03-23 — Roadmap created, 3 phases defined (19-21)
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 6
  completed_plans: 6
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-23)

**Core value:** When a player imports a route and pulls, they see accurate, timed ability warnings via custom spell icon display with per-mob detection.
**Current focus:** Phase 19 — Data Layer

## Current Position

Phase: 19 of 21 (Data Layer)
Plan: — of — (not yet planned)
Status: Ready to plan
Last activity: 2026-03-23 — Roadmap created, 3 phases defined (19-21)

Progress: [░░░░░░░░░░░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 38 (across v0.0.1-v0.1.0)
- Phases completed: 18
- Milestones shipped: 5

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [v0.1.1]: Categories are hardcoded per-mob, non-editable by user
- [v0.1.1]: Unknown category = wildcard at runtime (false positives over false negatives)
- [v0.1.1]: UnitEffectiveLevel is EXCLUDED — unusable on nameplates (takes cstring name, not unit token)
- [v0.1.1]: Runtime detection uses UnitClassification + UnitIsLieutenant (pcall-wrapped) + UnitClassBase
- [v0.1.1]: Skyreach is first fully-categorized dungeon; all others default to "unknown" explicit string
- [v0.1.1]: mobCategory must NOT enter SavedVariables via Pipeline merged ability tables
- [Phase 19-data-layer]: Plan entry count table slightly off for some files; actual file counts are authoritative (pre-existing, not changed)
- [Phase 19-data-layer]: mobCategory uses lowercase semantic roles (boss/miniboss/caster/warrior/rogue/trivial/unknown), not WoW class tokens
- [Phase 19-data-layer]: Outcast Servant stub entry ensures full DungeonEnemies coverage with empty abilities array
- [Phase 20-01]: DeriveCategory priority chain locked: boss -> lieutenant pcall -> non-elite trivial -> PALADIN caster -> ROGUE rogue -> WARRIOR warrior -> unknown fallback
- [Phase 20-01]: ability.mobCategory unknown is a wildcard: fires for ALL mob categories (false positives over false negatives)
- [Phase 21-config-display]: CATEGORY_COLORS defined as file-scoped local before PopulateRightPanel; dead npcIdToClass and CLASS_ICON tables removed (entry.mobClass gone since Phase 19); gsub hyphen escape uses '%-' pattern; categoryMatch uses catEntry to avoid shadowing
- [Phase 22-dungeon-category-index]: Pre-existing missing entries added alongside plan-specified stubs to achieve full MobCategories.md coverage
- [Phase 22-dungeon-category-index]: All 7 dungeon AbilityDB files now have correct semantic mob categories; mobs genuinely unknown retain 'unknown' as wildcard
- [Phase 22]: Boss detection consolidated into AbilityDB as single source of truth; isBoss field removed from DungeonEnemies entirely

### Roadmap Evolution

- Phases 1-3: v0.0.1 MVP (shipped)
- Phases 4-7: v0.0.2 Display Rework (shipped)
- Phases 8-10: v0.0.3 MDT Import (shipped)
- Phases 11-12: v0.0.4 Cleanup and Polish (shipped)
- Phases 13-18: v0.1.0 Configuration and Skill Data (shipped)
- Phases 19-22: v0.1.1 Adding Mob Categories (current)
  - Phase 22 added: Dungeon Category Index (categorize remaining 7 dungeons)

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 20]: UnitIsLieutenant is unverified in any Blizzard UI source — wrap in pcall, validate in-game during Phase 20 execution. If it misbehaves, remove it and collapse miniboss detection to "unknown" for this milestone.

## Session Continuity

Last session: 2026-03-24T06:01:26.258Z
Stopped at: Completed 22-02-PLAN.md
Resume file: None
Next action: /gsd:plan-phase 19
