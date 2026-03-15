# Roadmap: TerriblePackWarnings

## Milestones

- ✅ **v0.0.1 MVP** - Phases 1-3 (shipped 2026-03-15)
- 🚧 **v0.0.2 Display Rework** - Phases 4-6 (in progress)

## Phases

<details>
<summary>✅ v0.0.1 MVP Proof of Concept (Phases 1-3) -- SHIPPED 2026-03-15</summary>

- [x] Phase 1: Foundation and Data (2/2 plans) -- completed 2026-03-14
- [x] Phase 2: Warning Engine and Combat Integration (4/4 plans) -- completed 2026-03-15
- [x] Phase 3: Pack Selection UI (2/2 plans) -- completed 2026-03-15

See: `.planning/milestones/v0.0.1-ROADMAP.md` for full details.

</details>

### 🚧 v0.0.2 Display Rework (In Progress)

**Milestone Goal:** Replace DBM/ET/RaidNotice adapters with custom WeakAura-style spell icon display, using nameplate scanning to detect mobs and create independent timer instances per mob.

**Phase Numbering:**
- Integer phases (4, 5, 6): Planned milestone work
- Decimal phases (4.1, 5.1): Urgent insertions (marked with INSERTED)

- [x] **Phase 4: Data Schema and Pack Update** - Restructure ability data to support timed/untimed skills, mob class filters, and updated Windrunner Spire pack (completed 2026-03-15)
- [ ] **Phase 5: Custom Spell Icon Display** - Render horizontal spell icon squares with cooldown sweeps, countdowns, red glow, TTS, replacing all legacy adapters
- [ ] **Phase 6: Nameplate Detection and Mob Lifecycle** - Scan nameplates to detect mob classes, spawn per-mob timer instances, and clear icons when mobs die

## Phase Details

### Phase 4: Data Schema and Pack Update
**Goal**: Ability data supports timed and untimed skills with mob class filters, ready for the new display and detection systems
**Depends on**: Phase 3 (v0.0.1 complete)
**Requirements**: DATA-06, DATA-07, DATA-08, DATA-09
**Success Criteria** (what must be TRUE):
  1. An ability entry with nil cooldown is treated as untimed (icon-only, no countdown)
  2. Each ability entry carries a mobClass field (e.g. "PALADIN") used for nameplate filtering
  3. Mob name is no longer part of the ability data schema
  4. Windrunner Spire Pack 1 contains Spellguard's Protection (spellID 1253686, PALADIN, 50s) and Spirit Bolt (spellID 1216135, WARRIOR, untimed)
**Plans:** 1/1 plans complete

Plans:
- [ ] 04-01-PLAN.md -- Flat ability schema, Scheduler/CombatWatcher iteration patch

### Phase 5: Custom Spell Icon Display
**Goal**: Players see ability warnings as horizontal spell icon squares with cooldown animations, replacing all DBM/ET/RaidNotice adapters
**Depends on**: Phase 4
**Requirements**: DISP-01, DISP-02, DISP-03, DISP-04, DISP-05, DISP-06, DISP-08
**Success Criteria** (what must be TRUE):
  1. A horizontal row of square spell icons appears at top-left of screen during combat, growing rightward as abilities are tracked
  2. Timed abilities show the spell icon with a cooldown sweep animation and integer countdown; one icon appears per mob instance
  3. Untimed abilities show as a single static icon with no sweep or countdown, regardless of how many mobs of that class exist
  4. When 5 seconds remain before a timed cast, the icon gains a red glow border and text-to-speech announces the ability name
  5. DBM bars, Encounter Timeline, and RaidNotice display adapters are fully removed from the codebase
**Plans:** 2/2 plans executed

Plans:
- [x] 05-01-PLAN.md -- Create IconDisplay module and add ttsMessage to pack data
- [x] 05-02-PLAN.md -- Wire Scheduler to IconDisplay, delete BossWarnings, update TOC/install

### Phase 6: Nameplate Detection and Mob Lifecycle
**Goal**: The addon detects mobs via nameplate scanning and manages timer instance lifecycle (creation and cleanup) per mob
**Depends on**: Phase 5
**Requirements**: DETC-01, DETC-02, DETC-03, DETC-04, DISP-07
**Success Criteria** (what must be TRUE):
  1. On combat start, nameplates are scanned and mobs matching a skill's mobClass each spawn an independent timed icon
  2. Three Paladins in combat produce three separate Spellguard's Protection icons, each with independent countdowns
  3. Mobs entering combat after the initial pull are detected and spawn new timer instances
  4. When all mobs of a tracked skill's class die, all icons for that skill are cleared from the display
**Plans:** 2/2 plans executed

Plans:
- [x] 06-01-PLAN.md -- Refactor Scheduler (StartAbility/StopAbility), create NameplateScanner module
- [x] 06-02-PLAN.md -- Wire scanner into CombatWatcher, update TOC, in-game verification

## Progress

**Execution Order:**
Phases execute in numeric order: 4 → 5 → 6

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation and Data | v0.0.1 | 2/2 | Complete | 2026-03-14 |
| 2. Warning Engine and Combat Integration | v0.0.1 | 4/4 | Complete | 2026-03-15 |
| 3. Pack Selection UI | v0.0.1 | 2/2 | Complete | 2026-03-15 |
| 4. Data Schema and Pack Update | 1/1 | Complete   | 2026-03-15 | - |
| 5. Custom Spell Icon Display | v0.0.2 | 2/2 | Complete | 2026-03-15 |
| 6. Nameplate Detection and Mob Lifecycle | v0.0.2 | 2/2 | Complete | 2026-03-15 |
