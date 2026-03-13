# Project Research Summary

**Project:** TerriblePackWarnings
**Domain:** World of Warcraft Midnight (12.0) addon — Mythic+ dungeon trash pack ability warning system
**Researched:** 2026-03-13
**Confidence:** MEDIUM

## Executive Summary

TerriblePackWarnings is a WoW Mythic+ helper addon built for the Midnight (12.0) era, where Blizzard's Secret Values system has rendered the entire class of reactive combat-log addons non-functional in instanced content. Every existing competitor — DBM, BigWigs, LittleWigs — relied on `COMBAT_LOG_EVENT_UNFILTERED` and enemy unit APIs that are now blocked during M+ runs. This addon occupies a real niche: predefined cooldown timers, triggered by manual pack selection, that approximate when dangerous mob abilities will fire without needing any restricted runtime data. It is less precise than the old approach but the only approach that works at all under current API constraints.

The recommended approach is a lightweight plain-Lua addon with no third-party library dependencies. The core loop is: player selects a pack from a UI list, presses pull (or `PLAYER_REGEN_DISABLED` auto-triggers), and `C_Timer.After` callbacks fire at predefined offsets to issue warnings via Blizzard's native Boss Warnings system. All data lives in static Lua tables; the engine reads them but never writes them. The only significant technical uncertainty is whether Blizzard's `C_EncounterTimeline` / `C_EncounterEvents` API surfaces correctly for dungeon trash pulls (as opposed to boss encounters only) — this must be validated in-game before committing to it as the primary warning display mechanism.

The two highest risks are both addressable with early validation. First, `C_EncounterTimeline.AddScriptEvent` may silently fail for non-boss M+ content — build the warning display as an abstracted layer from day one so a fallback custom `StatusBar` frame can be swapped in without touching the rest of the addon. Second, mob ability timing data must model first-cast offsets distinctly from repeat cooldowns — this needs to be in the data schema from the start, not retrofitted. Ship one well-researched dungeon rather than unverified data for all eight.

---

## Key Findings

### Recommended Stack

Plain Lua (WoW 5.1 dialect) with XML for static frame declarations. No third-party libraries. The TOC manifest must declare `## Interface: 120001`; there is no player override and addons with mismatched interface versions will not load. Scheduling uses `C_Timer.After` for one-shot callbacks and `C_Timer.NewTicker` where repeating is needed — both confirmed available and `AllowedWhenUntainted` in 12.0.1. The entire class of combat-data APIs (CLEU, `UnitHealth`, `UnitAura`, `GetSpellCooldown`, nameplate scanning) is blocked during M+ runs and must not appear anywhere in this addon.

**Core technologies:**
- Lua 5.1 (WoW dialect): all addon logic — the only option; no choice here
- XML (FRAMES_XML): static frame structure and template declarations — keeps layout declarative
- TOC manifest `## Interface: 120001`: hard requirement; addon will not load without exact match
- `C_Timer.After` / `C_Timer.NewTimer`: scheduling ability warnings — confirmed, no OnUpdate overhead
- `CreateFrame("StatusBar")`: countdown progress bars — Midnight added native smooth interpolation
- `CreateFrame("ScrollFrame")`: pack selection list — built-in, no library required
- `SavedVariables`: account-wide settings persistence — stable, unchanged API
- `C_EncounterEvents.SetEventColor` / `SetEventSound`: Boss Warnings integration — confirmed 12.0.1, but applicability to dungeon trash unverified (MEDIUM confidence)

**Do not use:**
- `COMBAT_LOG_EVENT_UNFILTERED` or any CLEU-derived data — blocked during M+
- `UnitCastingInfo`, `UnitAura`, `GetSpellCooldown` on enemy units — secret values
- Nameplate scanning (`C_NamePlate`, `UnitGUID` on nameplates) — enemy identity blocked in instances
- Ace3 / LibStub — unnecessary for single-purpose addon; adds ~200KB overhead and taint risk
- `OnUpdate` polling — fires every frame; use `C_Timer` and `RegisterEvent` instead

### Expected Features

The feature set is tightly scoped by what the API allows. The differentiator is not a feature list — it is that predefined-timer warnings work in Midnight M+ when everything else does not.

**Must have (v1 launch):**
- Pack database for one dungeon — no data means no product; this is the core content work
- Pack selection UI grouped by dungeon area — the primary user interaction; must be fast
- Manual pull trigger (button or slash command) — sets T=0 for all timer scheduling
- Predefined ability timer engine with first-cast offset modeling — the entire value proposition
- Warning display via Boss Warnings system or fallback text display — what the player sees
- Stop/reset timers on combat end (`PLAYER_REGEN_ENABLED`) — prevents stale warning noise
- Enable/disable slash command — operational hygiene players expect

**Should have (v1.x after validation):**
- Severity tiers (DANGER vs INFO) — reduces warning noise; add when player feedback confirms need
- Per-pack notes field — human judgment layer on pack selection
- Slash command pack selection (`/tpw pack <name>`) — reduces friction for keyboard-centric players
- Second dungeon in database — expand after first dungeon data quality confirmed

**Defer (v2+):**
- MDT route integration — requires significant API validation and a stable v1
- Auto-detection of current pack — blocked by API; monitor Blizzard patch notes
- Community-contributed warning profiles — requires tooling for contribution review
- Multi-dungeon full coverage — natural expansion, not a v1 concern

**Anti-features (do not build):**
- Real-time cast detection — this is what CLEU provided; it no longer works in Midnight M+
- Nameplate-anchored timers — enemy nameplate access is restricted in instances
- Custom per-user timer editing — creates maintenance surface that is harder to manage than author-maintained data

### Architecture Approach

The addon follows a strict layered dependency model: Data is loaded first (pure static Lua tables), then the Warning Engine (reads Data, schedules `C_Timer` handles), then Event Handlers (thin wiring that calls into Engine on combat state change), then UI (renders Data for selection, calls Engine to arm timers). Each layer depends only on layers above it — new dungeons require only new data files, and the warning display mechanism is isolated in a single wrapper module for easy swapping if the Boss Warnings API proves unsuitable.

**Major components:**
1. `Core.lua` — addon namespace (`TPW = {}`), TOC entry point, wires all components via `ADDON_LOADED`
2. `Data/PackDatabase.lua` + `Data/DungeonIndex.lua` — static mob ability tables with `first_cast` and `cooldown` fields; grouped by dungeon area
3. `Engine/WarningScheduler.lua` — manages `C_Timer` handle table; `Start(packKey)` and `CancelAll()` are the primary interface
4. `Engine/BossWarnings.lua` — thin wrapper over `C_EncounterEvents`; the only file that changes if the warning display API needs to be swapped for a custom frame
5. `Events/CombatEvents.lua` — registers `PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED` / `PLAYER_ENTERING_WORLD`; calls Scheduler
6. `UI/PackSelectFrame.lua` + `.xml` — renders DungeonIndex as a scrollable grouped list; writes `TPW.State.selectedPack` on click

**Key patterns:**
- Single global namespace table (`TPW = TPW or {}`) — all state as subtables; zero global pollution
- Event frame dispatcher — one hidden Frame registers and dispatches all events via a handler table
- Timer handle table — every `C_Timer` handle stored for group cancellation; never fire-and-forget

### Critical Pitfalls

1. **Calling restricted APIs during a keystone run** — Any combat-state API returns a secret value the moment the key timer starts (not just in combat). This addon should call zero runtime combat APIs; the risk is accidentally adding one during debugging. Establish a rule at project start: no `UnitHealth`, `UnitAura`, `GetSpellCooldown`, or CLEU calls anywhere in the codebase.

2. **C_EncounterTimeline injection silently failing for trash content** — `C_EncounterTimeline.AddScriptEvent` is in the 12.0 API list but its parameters and trash-applicability are undocumented. It may only render during an active boss `ENCOUNTER_START` state. Prototype this API call first, before building the full timer system around it. Build `BossWarnings.lua` as a swappable layer from day one.

3. **Missing first-cast offset in ability data schema** — Mob abilities have a first cast that fires at a different time than the repeat cooldown interval. Hardcoding only the cooldown means the first (most important) warning fires late every time. The data schema must include both `first_cast` (time from pull to first cast) and `cooldown` (repeat interval) as separate fields. This cannot be retrofitted cheaply.

4. **Timer state not cleared on zone change or wipe** — `C_Timer` handles do not auto-cancel. Without cleanup on `PLAYER_ENTERING_WORLD` and `PLAYER_DEAD`, timers orphan and fire as "ghost warnings" after wipes or in the outdoor world. Implement the handle table and `CancelAll()` at the same time as timer scheduling, not later.

5. **TOC interface version mismatch** — `## Interface: 120001` is mandatory and there is no player override in Midnight. Wrong version = addon invisible on clean install. Verify with `/dump select(4, GetBuildInfo())` before shipping and add to release checklist.

---

## Implications for Roadmap

Based on research, the build order follows the architectural dependency graph. Each phase can be partially validated without the phases below it (Data and Engine can be tested via `/run` console commands before any UI exists).

### Phase 1: Foundation and Data Schema

**Rationale:** Everything depends on the data layer and the project skeleton. The data schema must encode `first_cast` offsets from day one — this cannot be retrofitted. The TOC, namespace conventions, and SavedVariables initialization pattern must be correct before any feature code is written, or all subsequent phases inherit the defects.

**Delivers:** A loadable addon skeleton with correct TOC (`Interface: 120001`), the `TPW` namespace pattern, `ADDON_LOADED` gating, a defined data schema for mob abilities (with `first_cast` + `cooldown` fields), and populated pack data for the first target dungeon. Testable via `/run print(TPW.PackDatabase["pack_key"].abilities[1].first_cast)`.

**Addresses:** Pack database (one dungeon), enable/disable slash command stub

**Avoids:** TOC version mismatch, initialization race (SavedVariables), global namespace pollution, missing first-cast offset (must be in schema from the start)

### Phase 2: Warning Engine (with Boss Warnings Prototype)

**Rationale:** The Boss Warnings API applicability to dungeon trash is the highest-risk unknown in the entire project. It must be validated before the UI is built around it — silent failure is the failure mode, so this needs eyes early. The `WarningScheduler` and `BossWarnings` wrapper are built together as the core engine. The BossWarnings wrapper is explicitly designed as a swappable layer.

**Delivers:** `WarningScheduler.lua` with `Start(packKey)` / `CancelAll()` using a handle table. `BossWarnings.lua` wrapper that either calls `C_EncounterEvents` successfully in a dungeon trash context, or falls back to a simple `UIParent` text frame. Validated in-game via `/run` console commands triggering warnings manually.

**Uses:** `C_Timer.After`, `C_Timer.NewTimer`, `C_EncounterEvents.SetEventColor`, `C_EncounterEvents.SetEventSound` (or fallback `StatusBar` frame)

**Implements:** WarningScheduler, BossWarnings (Architecture components)

**Avoids:** C_EncounterTimeline injection silent failure (by validating the API and having an explicit fallback path), timer orphan state (by building handle table and CancelAll at same time as Start)

### Phase 3: Event Handling and Combat Integration

**Rationale:** With a working engine, the thin event wiring layer is straightforward. This phase connects `PLAYER_REGEN_DISABLED` (auto-start), `PLAYER_REGEN_ENABLED` (auto-cancel), and `PLAYER_ENTERING_WORLD` (cleanup on zone change) to the Scheduler. This also validates the question from STACK.md about whether `PLAYER_REGEN_DISABLED` fires correctly during M+ trash pulls.

**Delivers:** `CombatEvents.lua` that auto-starts timers on combat entry (if a pack is selected) and cancels all timers on combat exit or zone change. Full timer lifecycle tested in an actual dungeon: pull → warnings fire → combat ends → timers cancelled → no ghost warnings.

**Addresses:** Stop/reset on combat end, timer state cleanup on zone change, `PLAYER_DEAD` cleanup

**Avoids:** Timer state not cleared on zone change (PLAYER_ENTERING_WORLD handler), orphaned timers after wipes

### Phase 4: Pack Selection UI

**Rationale:** The UI is the last layer and can only be built after the data and engine are stable. It renders the DungeonIndex as a grouped scrollable list, writes `TPW.State.selectedPack` on click, and arms timers. UI is built last because its shape is driven by the data schema (which must be final) and its behavior is driven by the engine API (which must be stable).

**Delivers:** `PackSelectFrame.lua` + `.xml` with a scrollable pack list grouped by dungeon area, click-to-select behavior, visual active-state indication (which pack is selected), and a "Stop / Reset" button accessible during combat. Slash command for pack selection by name.

**Addresses:** Pack selection UI, pull trigger, per-dungeon pack list, dangerous ability callouts (via already-built engine), enable/disable toggle

**Avoids:** No visual indication timers are running (show active pack highlight), no way to cancel mid-pull (Stop/Reset button), flat unorganized pack list (area grouping in DungeonIndex)

### Phase 5: Polish and Validation

**Rationale:** A structured validation pass against the "Looks Done But Isn't" checklist from PITFALLS.md. This is not a feature phase — it is the phase where the addon is trusted. Severity tiers and per-pack notes are appropriate to add here as low-complexity enhancements once the core is confirmed stable.

**Delivers:** Addon tested against all major failure scenarios (M+ keystone run, wipe, zone change, fresh install with out-of-date disabled, `/reload ui`). Severity tiers (DANGER/INFO) added as cosmetic metadata on warning entries. Per-pack notes field added to selection UI. Global namespace audit (`FindGlobals` or `/dump TPW` check). TOC version verified for release.

**Addresses:** Severity tiers, per-pack notes, slash command pack selection (if not already in Phase 4)

**Avoids:** Secret value errors in M+ (tested in actual keystone), timer cancellation gaps, SavedVariables persistence failure, non-English client issues

### Phase Ordering Rationale

- Data before Engine: the schema is the contract; building the engine against a defined schema prevents rework
- Engine before Events: the event handler is 20 lines that calls the Scheduler; the Scheduler must exist first
- Engine before UI: the UI calls `TPW.Scheduler:Start()` — that function must exist and work before the UI is wired
- Boss Warnings prototype in Phase 2 (not deferred): the highest-risk API unknown is the warning display mechanism; finding out it does not work for trash content in Phase 4 after the UI is built is a much worse outcome than finding out in Phase 2

### Research Flags

Phases likely needing `/gsd:research-phase` during planning:
- **Phase 2 (Warning Engine):** The `C_EncounterTimeline` / `C_EncounterEvents` API behavior for dungeon trash content is the single largest unknown. The available documentation is limited to the function existing in the API changelog; parameter signatures and trash-context applicability need in-game verification. Consider a spike task at the start of this phase.
- **Phase 3 (Combat Events):** Whether `PLAYER_REGEN_DISABLED` fires reliably during M+ trash pulls (vs being suppressed or batched differently) is noted as unconfirmed in STACK.md. Test empirically before relying on it for auto-trigger.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** TOC format, ADDON_LOADED gating, SavedVariables initialization, and namespace patterns are all well-documented with HIGH-confidence sources. No research needed.
- **Phase 4 (UI):** `CreateFrame`, `ScrollFrame`, `Button`, and XML layout patterns are stable Blizzard APIs unchanged through 12.0.1. Standard addon UI patterns apply.
- **Phase 5 (Polish):** Testing and validation pass; no new API surface.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Core Lua/TOC/C_Timer APIs are HIGH confidence with official wiki sources. Boss Warnings / C_EncounterEvents applicability to dungeon trash is LOW confidence — documented as existing but not as working for non-boss content. |
| Features | MEDIUM | The restricted-API landscape is confirmed via Blizzard official docs (HIGH confidence). Competitor feature gaps confirmed via GitHub issues (MEDIUM). The differentiator claim (predefined timers as the only Midnight-compatible approach) is well-supported. |
| Architecture | MEDIUM-HIGH | Core WoW addon patterns (namespace table, event frame, C_Timer handle table, layered file structure) are well-established and documented. The component boundaries recommended here are idiomatic. Uncertainty is specifically in the BossWarnings integration layer, not in the overall architecture. |
| Pitfalls | MEDIUM-HIGH | Secret Values system restrictions confirmed via Blizzard official docs and real-world post-launch incident reports. Timer lifecycle pitfalls are well-understood. C_EncounterTimeline injection uncertainty is the one area where the pitfall is confirmed but the resolution path is partially speculative. |

**Overall confidence:** MEDIUM

### Gaps to Address

- **C_EncounterTimeline/C_EncounterWarnings trash applicability:** Must be validated in-game with a minimal stub addon before Phase 2 begins in earnest. Use `/api C_EncounterTimeline` in-game to inspect actual function signatures. If injection is boss-only, the fallback is a custom `StatusBar` frame overlay — design `BossWarnings.lua` as a swappable layer from day one to make this a one-file change.

- **PLAYER_REGEN_DISABLED in M+ trash context:** Confirmed available in Midnight 12.0.1 generally, but STACK.md flags that its exact behavior during M+ keystone runs (as opposed to normal dungeon runs) was not empirically verified. Test this in Phase 3 before the event handler becomes load-bearing.

- **Mob ability first-cast offsets:** The predefined timer data must be validated against actual dungeon runs. Wowhead cast timing data aggregates across all casts and does not reliably capture first-cast offsets. This is not a code gap — it is a data quality gap that requires playtesting with the schema in place.

- **C_EncounterEvents.AddEvent or equivalent:** `SetEventColor` and `SetEventSound` are confirmed in 12.0.1, but these customize existing events. An API for registering a new custom event (the actual injection mechanism) has not been publicly documented with parameter signatures. This needs in-game `/api` inspection.

---

## Sources

### Primary (HIGH confidence)
- [Patch 12.0.0/API changes — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes) — 437 new APIs, C_EncounterTimeline/C_EncounterWarnings namespaces confirmed, Secret Values system
- [Patch 12.0.0/Planned API changes — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes) — CLEU removal, M+ API restriction scope, C_Timer AllowedWhenUntainted
- [TOC format — Warcraft Wiki](https://warcraft.wiki.gg/wiki/TOC_format) — Interface 120001 requirement, all TOC fields
- [API C_Timer.After — Warcraft Wiki](https://warcraft.wiki.gg/wiki/API_C_Timer.After) — AllowedWhenUntainted status, usage pattern
- [Widget API — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Widget_API) — Frame types, ScrollFrame, StatusBar, confirmed 12.0.1
- [PLAYER_REGEN_DISABLED — Warcraft Wiki](https://warcraft.wiki.gg/wiki/PLAYER_REGEN_DISABLED) — confirmed Midnight 12.0.1
- [AddOn loading process — Warcraft Wiki](https://warcraft.wiki.gg/wiki/AddOn_loading_process) — ADDON_LOADED / PLAYER_ENTERING_WORLD ordering
- [Handling events — Warcraft Wiki](https://warcraft.wiki.gg/wiki/Handling_events) — event frame pattern

### Secondary (MEDIUM confidence)
- [Blizzard: How Midnight's Changes Will Impact Combat Addons](https://news.blizzard.com/en-us/article/24244638/how-midnights-upcoming-game-changes-will-impact-combat-addons) — Custom events on Boss Timeline, addon skinning
- [Blizzard: Combat Philosophy and Addon Disarmament in Midnight](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight) — Secret Values philosophy, what addons can still do
- [Wowhead: Lua API Changes for Midnight Launch](https://www.wowhead.com/news/addon-changes-for-midnight-launch-ending-soon-with-release-candidate-coming-380133) — C_EncounterEvents.SetEventColor/SetEventSound confirmed added
- [Icy Veins: Combat Addon Restrictions Eased in Midnight](https://www.icy-veins.com/wow/news/combat-addon-restrictions-eased-in-midnight/) — Restrictions apply during M+ runs specifically
- [GitHub: BigWigsMods/LittleWigs Issue #15](https://github.com/BigWigsMods/LittleWigs/issues/15) — Confirms competitor gap in M+ trash coverage
- [kaylriene.com: WoW Midnight Addon Changes Part 1](https://kaylriene.com/2025/10/03/wow-midnights-addon-combat-and-design-changes-part-1-api-anarchy-and-the-dark-black-box/) — Black box system, developer impact
- [kaylriene.com: Week One of Midnight UI Era](https://kaylriene.com/2026/01/27/a-mini-summary-of-week-one-of-the-new-wow-ui-era-blizzards-own-lua-errors-the-vibecoded-addon-wars-of-2026/) — Post-launch real-world secret value errors
- [Cell Addon Midnight Compatibility PR #457 — GitHub](https://github.com/enderneko/Cell/pull/457) — Real-world case study: secret values, CLEU removal, pcall patterns

### Tertiary (LOW confidence — needs in-game validation)
- [Wowhead: Blizzard Boss Timeline HUD Guide](https://www.wowhead.com/guide/ui/blizzard-boss-timeline-hud-features-customization) — Timeline/text warning components; no confirmation of trash-pack applicability
- Blizzard in-game `/api` command — authoritative for Midnight; referenced as the definitive verification tool for C_EncounterTimeline parameter signatures

---
*Research completed: 2026-03-13*
*Ready for roadmap: yes*
