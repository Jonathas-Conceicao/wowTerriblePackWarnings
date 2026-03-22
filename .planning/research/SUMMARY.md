# Project Research Summary

**Project:** TerriblePackWarnings v0.1.0 — Configuration and Skill Data
**Domain:** WoW Midnight (12.0) Mythic+ dungeon pack warning addon
**Researched:** 2026-03-17
**Confidence:** HIGH

## Executive Summary

TerriblePackWarnings is a WoW Midnight (12.0) addon that gives Mythic+ players real-time ability warnings for dungeon trash packs. The v0.1.0 milestone expands the working v0.0.4 foundation into a full-featured warning system: per-dungeon route storage for all 9 Midnight S1 dungeons, per-skill configuration UI, cast detection for untimed abilities, and sound alert selection. Research was conducted entirely against primary sources — local copies of `wow-ui-source`, `MythicDungeonTools`, and the existing TerriblePackWarnings codebase — so confidence across all four research areas is HIGH.

The recommended approach is conservative: extend the existing architecture without introducing new libraries or UI frameworks. The `NameplateScanner`'s existing 0.25s tick loop is the only valid cast detection mechanism in Midnight (COMBAT_LOG_EVENT_UNFILTERED is disabled), so untimed ability highlighting integrates directly into that loop. The configuration UI follows the same `ScrollFrame + UIPanelScrollFrameTemplate + manual row stacking` pattern already proven in `PackFrame.lua`. Sound alerts use raw `soundKitID` values from Blizzard's Cooldown Manager (CDM) curated library via bare `PlaySound(soundKitID)` calls. All 9 dungeon ability datasets must be hand-authored in `Data/*.lua` files — MDT's `spells` table is a spellID reference list only, with no timing, label, or priority data.

The most significant risks are architectural rather than API-level. The `PackDatabase["imported"]` single-key pattern must be atomically refactored across four files simultaneously or the system silently breaks. `UnitCastingInfo` must be paired with a pre-built spellID index at pack activation to avoid O(nameplates x abilities) performance in the tick loop. Sound and TTS alerts must be throttled per spellID to prevent audio stacking when multiple mobs cast the same ability. None of these risks are novel — the research identifies exact code patterns to address each one before implementation begins.

## Key Findings

### Recommended Stack

No new external libraries are needed for v0.1.0. The entire feature set is implementable with native WoW API. Blizzard's own Cooldown Manager (CDM) in `wow-ui-source` is an authoritative implementation reference for every new UI component in this milestone — its ScrollFrame layout, collapse/expand pattern, sound library, and PlaySound usage are all directly applicable.

**Core technologies:**
- Lua 5.1 (WoW dialect) + TOC `## Interface: 120001` — only language available; 120001 is a hard load requirement
- `C_Spell.GetSpellInfo(spellID)` — resolves spell names and icons from raw MDT spellIDs; marked `AllowedWhenTainted`, available everywhere
- `UnitCastingInfo("nameplateN")` / `UnitChannelInfo("nameplateN")` — cast detection for untimed abilities; restriction flag is `SecretWhenUnitSpellCastRestricted` (PvP-only), not a dungeon block; validate in first in-dungeon session
- `PlaySound(soundKitID)` — one-argument call; soundKitIDs from CDM's `CooldownViewerSoundAlertData.lua` (67 curated sounds, 6 categories)
- `ScrollFrame + UIPanelScrollFrameTemplate + manual SetPoint stacking` — config tree layout; same pattern as existing `PackFrame.lua`; avoids ScrollBox/DataProvider which requires Mixin infrastructure not in TPW
- `SavedVariables: TerriblePackWarningsDB` with `schemaVersion` field — must be established before writing any new v0.1.0 fields

**Avoid:**
- `UIDropDownMenu_Initialize` (deprecated in Midnight) — use Button + popup list instead
- `ScrollBox`/`DataProvider` — requires Blizzard Mixin infrastructure not present in TPW
- `SOUNDKIT.*` constants for alert sounds — maps UI interaction sounds, not CDM alert sounds; use raw numeric IDs from CDM's curated table
- `ResizeLayoutFrame` — requires `GetLayoutChildrenBounds` on children; manual `SetPoint` is simpler and already proven

### Expected Features

**Must have (v0.1.0 launch):**
- AbilityDB data for all 9 Midnight S1 dungeons — foundational; blocks all other features until done
- Per-dungeon route storage (`ns.db.importedRoutes[dungeonKey]`) — replaces flat `PackDatabase["imported"]`; enables independent routes per dungeon
- Dungeon selector in TPW window — dropdown or tab bar showing all 9 dungeons with status
- Zone-in auto-switch on `PLAYER_ENTERING_WORLD` — zero-click correct dungeon selection using `C_Map.GetBestMapForUnit` + mapID table
- Config window with dungeon→mob→skill tree — per-skill: enable/disable checkbox, custom label, TTS text field, sound dropdown
- Mob count overlay on pack portraits ("x3" format, sorted by count descending, MDT pattern)
- Untimed skill highlighting via `UnitCastingInfo` polling — fires on cast start, clears on cast end
- Sound alert per skill — selected from CDM 67-sound library, stored as soundKitID in `ns.db.skillConfig`

**Should have (v0.1.x after validation):**
- Sound preview on dropdown select — `PlaySound` call from the dropdown `OnClick` handler
- TTS text override per skill — unique differentiator; already in schema, surface it in config UI

**Defer (v2+):**
- Config profile import/export — serialization complexity before core value is proven
- Multiple route presets per dungeon — not the TPW use case
- Volume slider per skill category — user's Master volume is sufficient for v0.1.0
- Config filter/search — add only after users report navigation difficulty

**Anti-features (never build):**
- Real-time cast detection via CLEU — blocked in Midnight M+
- Total forces count / percent bar — belongs in MDT, not TPW
- Multiple route presets per dungeon — single active route is the use case; re-import to replace
- Global mute toggle — per-skill checkbox plus CombatWatcher idle state covers this

### Architecture Approach

The v0.1.0 architecture extends the existing layered design (UI → Engine → Display → Import/Data → Persistence) with targeted additions to each layer. The key structural changes are: (1) `PackDatabase["imported"]` retires in favor of `PackDatabase[dungeonKey]` across four files in one atomic refactor; (2) eight new `Data/*.lua` files following the `WindrunnerSpire.lua` schema; (3) `NameplateScanner.Tick()` gains `UnitCastingInfo` polling with a pre-built O(1) spellID index; (4) `IconDisplay.lua` gains `SetCastHighlight`/`ClearCastHighlight` for untimed highlights; (5) new `UI/ConfigFrame.lua` built lazily on first open. No new libraries, no new timers, no new namespace patterns.

**Major components (new or changed):**
1. `Data/*.lua` (8 new files) — hand-authored AbilityDB entries for 8 remaining dungeons; schema matches `WindrunnerSpire.lua` exactly
2. `UI/ConfigFrame.lua` (new) — lazily constructed dungeon→mob→skill config tree; reads `ns.AbilityDB`, writes `ns.db.skillConfig[npcID][spellID]`
3. `Import/Pipeline.lua` (extended) — per-dungeon key writes, `MergeSkillConfig()` sparse-override helper, `importedRoutes` map restore
4. `Engine/NameplateScanner.lua` (extended) — `UnitCastingInfo` polling in existing `Tick()`, pre-built spellID index at `Start()`, `castHighlightActive` table
5. `Engine/CombatWatcher.lua` (extended) — full 9-dungeon `ZONE_DUNGEON_MAP`, `Reset()` iterates `importedRoutes` for auto-select
6. `Display/IconDisplay.lua` (extended) — `SetCastHighlight`/`ClearCastHighlight`, `PlaySound` at alert trigger, per-spellID throttle table in `SetUrgent`
7. `UI/PackFrame.lua` (extended) — dungeon selector widget, mob count "x3" overlay on portrait frames

**Recommended build order (dependencies flow downward):**
1. Data files (8 dungeons) — no code dependencies; unblocks everything else
2. IconDisplay highlight + sound — no upstream dependencies
3. NameplateScanner cast detection — depends on step 2
4. Pipeline per-dungeon key + skillConfig merge — cross-cutting refactor; atomic across four files
5. CombatWatcher zone map + auto-switch — depends on step 4
6. ConfigFrame — depends on steps 1 and 4
7. PackFrame dungeon selector + mob count — depends on step 4

### Critical Pitfalls

1. **`UnitCastingInfo` O(N×M) tick loop** — Build a `spellID → ability` O(1) lookup index at `NameplateScanner:Start(pack)` time. Gate the call behind a class filter. Never iterate the ability list per nameplate per tick. This is the highest-impact performance risk and has zero recovery cost if done correctly from the start.

2. **"imported" key migration breaks CombatWatcher silently** — The migration across `Pipeline.lua`, `CombatWatcher.lua`, `PackFrame.lua`, and `Import.lua` must be atomic. Grep all files for the `"imported"` literal and `importedRoute` before shipping. A partial migration produces no Lua errors but leaves the system in idle state with no diagnostic feedback.

3. **Sound and TTS alert stacking on multi-mob pulls** — Add a per-spellID throttle table (`alertThrottle[spellID] = GetTime()`) in `SetUrgent` before the `PlaySound` and `TrySpeak` calls. Build this simultaneously with the sound dropdown — do not defer. At 5 mobs casting the same ability, five `PlaySound` calls in 0.25s create audio chaos.

4. **SavedVariables schema corruption on upgrade** — Add `schemaVersion` to `TerriblePackWarningsDB` before writing any new v0.1.0 fields. On `ADDON_LOADED`, detect the old single-route structure (`ns.db.importedRoute` exists, `ns.db.importedRoutes` does not) and migrate. Users should not need to re-import after an addon update.

5. **MDT ability data is a spellID list, not an ability database** — MDT's `spells` table is `{[spellID] = {}}` with always-empty sub-tables (confirmed in all 9 dungeon files). Timing, labels, and danger classification must be hand-authored. Validate every spellID with `C_Spell.GetSpellInfo(id)` in-game before committing. Plan time for manual authoring; automated extraction produces unusable empty entries.

## Implications for Roadmap

The feature set falls into four natural phases ordered by dependency graph and risk. The ordering follows the component build order from ARCHITECTURE.md.

### Phase 1: Ability Data Foundation

**Rationale:** AbilityDB population is a hard prerequisite for every other feature. Config UI, cast detection, dungeon selector, and mob count display all need populated `ns.AbilityDB` entries before they have anything to render or match against. This work is pure data authoring with no code risk — the right thing to do first and can be validated independently of all other work.
**Delivers:** `Data/*.lua` files for all 9 dungeons; every npcID and spellID validated in-game via `C_Spell.GetSpellInfo`; `Data/DungeonEnemies.lua` updated with mapID entries for all 9 dungeons
**Addresses:** AbilityDB all 9 dungeons (P1); mob count display data foundation; `ZONE_DUNGEON_MAP` mapID table
**Avoids:** Pitfall 8 (MDT data gaps) — manual authoring workflow established before any code depends on it; grey placeholder icons from invalid spellIDs caught before shipping
**Research flag:** Skip — WindrunnerSpire.lua is the complete pattern; work is data entry with in-game verification, not API research

### Phase 2: Per-Dungeon Route Storage (Structural Refactor)

**Rationale:** The `PackDatabase["imported"]` single-key pattern blocks multi-dungeon support and must be refactored before any UI takes dependencies on per-dungeon keys. This is the highest-risk architectural change because it touches four files simultaneously and fails silently if done partially. Doing it second while the codebase is still clean avoids compounding the refactor with new UI code taking the wrong pattern.
**Delivers:** `ns.db.importedRoutes[dungeonKey]` map, per-dungeon PackDatabase keys, `MergeSkillConfig()` sparse-override helper, `schemaVersion` in SavedVariables, old-to-new migration on `ADDON_LOADED`
**Addresses:** Per-dungeon route storage (P1); schema migration safety; Import.Clear() per-dungeon scope
**Avoids:** Pitfall 7 (migration breaking CombatWatcher) — done atomically with grep verification; Pitfall 3 (schema corruption) — schemaVersion established here before config writes begin
**Research flag:** Skip — ARCHITECTURE.md provides exact code changes for all four affected files and the full data flow

### Phase 3: Cast Detection and Sound Alerts

**Rationale:** Cast detection extends `NameplateScanner.Tick()` at a well-understood integration point. Sound alert throttling must be built alongside the sound dropdown — not deferred — because multi-mob test scenarios are the only way to validate the throttle behavior. Both features share the same `SetUrgent` call path and should be developed and tested together.
**Delivers:** `UnitCastingInfo` polling in `Tick()` with O(1) spellID index; `SetCastHighlight`/`ClearCastHighlight` in `IconDisplay.lua`; `PlaySound` at alert trigger points; per-spellID throttle in `SetUrgent`; `Data/Sounds.lua` with CDM 67-sound library; sound dropdown UI
**Addresses:** Untimed cast detection (P1); timed pre-warning sound (P1); sound throttle (Pitfall 5)
**Avoids:** Pitfall 1 (O(N×M) tick loop) — spellID index built at `Start()` time; Pitfall 5 (sound stacking) — throttle built simultaneously with PlaySound
**Research flag:** Needs early in-game validation — `UnitCastingInfo` on nameplate units is documented as PvP-restricted (not dungeon-blocked) but must be confirmed against a live hostile cast in the first test session. If the 9th return value is nil in M+ content, the fallback is nameplate event-based detection.

### Phase 4: Configuration UI and Pack Selection Polish

**Rationale:** ConfigFrame depends on Phase 1 (AbilityDB populated) and Phase 2 (skillConfig schema defined in SavedVariables). PackFrame dungeon selector depends on Phase 2 (per-dungeon PackDatabase keys). Building this last ensures the data and engine layers it depends on are stable and the UI only needs to render correct data, not work around engine limitations.
**Delivers:** `UI/ConfigFrame.lua` (lazily constructed) with dungeon→mob→skill tree, per-skill checkbox/label/TTS/sound widgets; PackFrame dungeon selector; mob count "x3" portrait overlay; zone-in auto-switch in CombatWatcher; `/tpw config` slash command
**Addresses:** Config window tree (P1); per-skill toggle/label/TTS (P1); dungeon selector (P1); zone-in auto-switch (P1); mob count display (P1); sound dropdown (P1)
**Avoids:** Pitfall 6 (config frame hitch) — lazy construction, accordion expand/collapse, frame pool from PackFrame pattern; Pitfall 4 (config bloat) — sparse-default skillConfig storage, orphan cleanup on route clear; UX pitfall of disabled skills leaving icons visible — disabled skills remove icon from IconDisplay entirely
**Research flag:** Skip for core layout (established ScrollFrame + accordion pattern from CDM). Sound dropdown popup is a minor question — reuse existing popup patterns from the PackFrame import dialog.

### Phase Ordering Rationale

- Phase 1 before everything: ability data is the single blocker with zero code risk; front-loading this eliminates the most common integration failure (empty or invalid AbilityDB)
- Phase 2 before UI: the structural refactor must complete before PackFrame or ConfigFrame take dependencies on per-dungeon keys; a partial migration is worse than no migration and produces no error signals
- Phase 3 before Phase 4: cast detection and sound must be testable independently of the config UI; the sound throttle must be proven against multi-mob pulls before the config UI exposes per-skill sound selection to users
- Phase 4 last: config UI and pack selection polish are the user-visible surface; building last ensures the data and engine layers they depend on are stable

### Research Flags

Needs early in-game validation (Phase 3):
- **`UnitCastingInfo("nameplateN")` in M+ dungeons** — documented as PvP-restricted only, not dungeon-blocked. Must be confirmed with a live test against a visible hostile cast. If the 9th return value is nil in instanced content, the fallback path (nameplate event-based detection) is a contained change to `NameplateScanner.lua`.

Data lookup needed before Phase 2 ships:
- **9-dungeon `ZONE_DUNGEON_MAP` mapIDs** — 7 of the 9 mapIDs need to be read from `MDT.mapInfo[dungeonIndex].mapID` in each dungeon file. This is a one-time lookup, not an API question.

Phases with standard patterns (skip deeper research):
- **Phase 1:** WindrunnerSpire.lua is the complete pattern; data entry + in-game spellID verification
- **Phase 2:** ARCHITECTURE.md provides exact code changes; migration pattern is fully specified
- **Phase 4:** CDM's CooldownViewerSettings.lua / .xml is a complete implementation reference for the ScrollFrame + accordion config tree

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All APIs verified against wow-ui-source: UnitDocumentation.lua (UnitCastingInfo), SoundDocumentation.lua (PlaySound), SpellDocumentation.lua (C_Spell.GetSpellInfo). CDM source confirms ScrollFrame and PlaySound patterns for production Midnight addons. |
| Features | HIGH | MDT source confirms `spells` table structure across all 9 dungeon files. PackFrame.lua confirms existing portrait pool pattern. Feature set derived from CDM (config pattern), MDT (dungeon switching pattern), and existing TPW codebase. |
| Architecture | HIGH | Derived from direct source read of all 10 existing Lua files + TOC. Every integration point, data flow, and build order step is fully specified with exact code samples in ARCHITECTURE.md. |
| Pitfalls | HIGH (API), MEDIUM (throttle threshold) | API behavior verified from wow-ui-source and existing codebase. The 3-second sound throttle window is a reasonable starting value but the exact threshold needs validation against real multi-mob pulls — expose as a named constant, not a magic number. |

**Overall confidence:** HIGH

### Gaps to Address

- **`UnitCastingInfo` in M+ instances:** One in-dungeon validation pass at the start of Phase 3. The documented restriction is PvP-only, but the annotation `SecretWhenUnitSpellCastRestricted` should be confirmed inactive in instanced content. Recovery cost is LOW — the fallback is contained to `NameplateScanner.lua`.

- **Sound throttle threshold:** The 3-second per-spellID throttle window is research-derived, not benchmarked. Define it as `ALERT_THROTTLE_SECONDS = 3` in `IconDisplay.lua` and tune during Phase 3 testing. Do not hardcode inline.

- **7 remaining dungeon mapIDs:** Windrunner Spire (mapID 557) and Maisara Caverns (mapID 560) are confirmed. The remaining 7 need to be read from `MDT.mapInfo[dungeonIndex].mapID` in each MDT dungeon file. This is a 5-minute lookup task, not a research question.

## Sources

### Primary (HIGH confidence)
- `wow-ui-source/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` lines 811–877 — UnitCastingInfo/UnitChannelInfo signatures, return value positions, restriction flag `SecretWhenUnitSpellCastRestricted`
- `wow-ui-source/Blizzard_APIDocumentationGenerated/SoundDocumentation.lua` lines 52–71 — PlaySound signature and parameters
- `wow-ui-source/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua` lines 336–350 — C_Spell.GetSpellInfo signature; `AllowedWhenTainted` status
- `wow-ui-source/Blizzard_CooldownViewer/CooldownViewerSoundAlertData.lua` — CDM 67-sound library with all soundKitIDs and category names
- `wow-ui-source/Blizzard_CooldownViewer/CooldownViewerAlert.lua` lines 231–236 — PlaySound bare call pattern; default sound selection
- `wow-ui-source/Blizzard_CooldownViewer/CooldownViewerSettings.lua` / `.xml` lines 97–103, 201–220 — ScrollFrame layout, collapse/expand mixin pattern, category list structure
- `wow-ui-source/Blizzard_CombatAudioAlerts/Blizzard_CombatAudioAlertManager.lua` — UnitCastingInfo usage for cast detection; confirms UNIT_SPELLCAST_START is player/target only (not arbitrary nameplates)
- `wow-ui-source/Blizzard_NamePlates/Blizzard_ClassNameplateBar.lua` — `select(9, UnitCastingInfo(unit))` pattern for spellID extraction
- `MythicDungeonTools/Midnight/WindrunnerSpire.lua` — MDT enemy/spell table structure; `spells` sub-tables confirmed always `{}`
- `MythicDungeonTools/Midnight/MaisaraCaverns.lua` — Confirms same MDT structure across multiple dungeon files
- `MythicDungeonTools/AceGUIWidgets/AceGUIWidget-MythicDungeonToolsPullButton.lua` — Portrait count display ("x"..data.quantity), count-descending sort pattern
- `MythicDungeonTools/Modules/DungeonSelect.lua` — Dungeon switching pattern, per-dungeon preset storage structure
- All 10 Lua files in TerriblePackWarnings v0.0.4 — direct source analysis for all integration questions and build order

### Secondary (MEDIUM confidence)
- Sound throttle 3-second window — derived from common addon alert practice; not benchmarked against Midnight specifically

---
*Research completed: 2026-03-17*
*Ready for roadmap: yes*
