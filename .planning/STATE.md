---
gsd_state_version: 1.0
milestone: v0.0
milestone_name: milestone
status: "Roadmap approved — ready for /gsd:plan-phase 13"
stopped_at: Phase 18 complete — profiles and skill config rework done
last_updated: "2026-03-22T08:50:39.795Z"
last_activity: "2026-03-17 — Roadmap revised: Config UI and Pack Polish moved to Phase 13 (validated against WindrunnerSpire data), Ability Data Foundation moved to Phase 14"
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 16
  completed_plans: 16
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
- [Phase 13]: cfg.enabled == false strict equality in MergeSkillConfig — nil means default = enabled, only false means explicitly disabled
- [Phase 13-02]: countLabel FontString created lazily on tex in PopulateList (not CreatePullRow) so row reuse works correctly across refreshes
- [Phase 13-02]: configBtn anchored LEFT of clearBtn via SetPoint(RIGHT, clearBtn, LEFT) matching importBtn/clearBtn chain pattern
- [Phase 14]: defaultEnabled=false for new MDT-sourced abilities; existing hand-authored entries remain enabled by default
- [Phase 14]: New npcIDs from MDT use mobClass=WARRIOR as default; npcIDs with no spells (232071, 250883) omitted
- [Phase 14]: MDT spells tables contain exactly one spellID per mob for all 8 new dungeons
- [Phase 14-ability-data-foundation]: GetSpellNameSafe returns ability.name if present rather than always querying the API — hand-authored names take precedence
- [Phase 14-ability-data-foundation]: GetSpellIconSafe returns nil so callers can apply their own grey fallback; BuildDungeonIndex shows all 9 dungeons unconditionally
- [Phase 14-ability-data-foundation]: Save preset in ns.db.importedRoute so RestoreFromSaved rebuilds from current skillConfig on login
- [Phase 14-ability-data-foundation]: Legacy fallback in RestoreFromSaved preserves compatibility with pre-preset saves
- [Phase 14-ability-data-foundation]: Murder Row removed from DUNGEON_IDX_MAP and all file references — not a Midnight S1 dungeon
- [Phase 15-per-dungeon-route-storage]: Per-dungeon keyed storage: PackDatabase[dungeonKey] and ns.db.importedRoutes[dungeonKey] replace single imported key
- [Phase 15-per-dungeon-route-storage]: ZONE_DUNGEON_MAP expanded to 8 S1 dungeons with best-guess instance names requiring in-game verification
- [Phase 15-per-dungeon-route-storage]: GetSelectedDungeonKey() centralizes ns.db.selectedDungeon access so all per-dungeon reads go through one function
- [Phase 15-per-dungeon-route-storage]: Combat mode toggle buttons use alpha+tinted background via UpdateModeButtons() called in both Refresh() and Initialize
- [Phase 16-cast-detection-and-sound-alerts]: Orange cast glow uses separate castGlowTextures (not recolored glowTextures) — red and orange glows coexist without conflict
- [Phase 16-cast-detection-and-sound-alerts]: PlaySound uses Master channel per locked CONTEXT.md decision; soundKitID nil means TTS mode (mutually exclusive)
- [Phase 17-command-rework-and-config-search]: Bare /tpw defaults to config window (was route window) — config is the primary UX entry point
- [Phase 17-command-rework-and-config-search]: configBtn removed from PackFrame footer; clearBtn at BOTTOMLEFT, importBtn at BOTTOMRIGHT
- [Phase 17-02]: Route button in Config top bar calls ns.PackUI.Toggle() — opens route window from config window
- [Phase 17-02]: Reset All in Config top bar resets ALL dungeons globally via StaticPopup confirmation (was per-dungeon)
- [Phase 17-02]: Config search debounce 0.3s via C_Timer.NewTimer; mob name match shows all abilities, spell name match filters to matched spells only
- [Phase 18-01]: Profile skillConfig stores only user overrides; all abilities default to unchecked (defaultEnabled=false) — timing comes from profile cfg.timed only
- [Phase 18-01]: Schema v1->v2 migration moves flat skillConfig to profiles[Default].skillConfig and retires the field; activeProfile defaults to Default
- [Phase 18-profiles-and-skill-config-rework]: timed field saved as true or nil; soundEnabled as true or nil; UpdateDelButton stored on configFrame for StaticPopup access; Profile dropdown uses ASCII v suffix
- [Phase 18]: soundEnabled stored as false on slot; nil from old data means sound off; SetCastHighlight gates on ability.soundEnabled from ability table at call time; export auto-selects text via HighlightText

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

Last session: 2026-03-21T23:53:46.994Z
Stopped at: Phase 18 complete — profiles and skill config rework done
Resume file: None
Next action: /gsd:plan-phase 13
