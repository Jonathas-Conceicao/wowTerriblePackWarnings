# Project Research Summary

**Project:** TerriblePackWarnings v0.1.1 — Mob Category System
**Domain:** WoW Midnight (12.0) Mythic+ nameplate scanning addon
**Researched:** 2026-03-23
**Confidence:** HIGH

## Executive Summary

The v0.1.1 milestone adds a per-mob category system (boss/miniboss/caster/warrior/rogue/trivial/unknown) to the existing TerriblePackWarnings nameplate scanner. No comparable M+ addon provides semantic role-based category filtering — MDT exposes only a binary `isBoss` flag, BigWigs has no category concept for trash, and Plater uses per-user custom scripts. TPW's approach is a novel, statically-hardcoded category per npcID in the AbilityDB data files, combined with runtime detection of structural tiers (boss/miniboss/trivial) from WoW APIs at `NAME_PLATE_UNIT_ADDED`. The feature delivers meaningful noise reduction for players: by defaulting `trivial = false` in the category filter, the addon is quieter out of the box without any manual configuration.

The recommended implementation uses three confirmed-stable Midnight APIs: `UnitClassification(unitToken)`, `UnitIsLieutenant(unitToken)`, and `UnitClassBase(unitToken)`. All three are marked `AllowedWhenUntainted` with no return-value Secret Value restrictions, and Blizzard's own nameplate code calls `UnitClassification` on nameplate unit tokens directly. One API explicitly documented alongside these — `UnitEffectiveLevel` — is a critical trap: it takes a `cstring` name argument (not a unit token), and getting a unit name from a nameplate requires `UnitName`, which returns a Secret Value in instances. `UnitEffectiveLevel` must not be used at all for category detection.

The feature is architecturally additive and low-risk. The implementation touches five files in a strict dependency order (Scanner → Pipeline → Skyreach data → Scanner filter → ConfigFrame display). No SavedVariables schema migration is needed. `UnitIsLieutenant` is the only unverified API — it is documented in 12.0.0 with correct taint annotations but appears in no Blizzard UI Lua file, so it requires in-game validation before being treated as reliable.

---

## Key Findings

### Recommended Stack

No new libraries or frameworks are needed for v0.1.1. The existing Lua 5.1 + native WoW API stack handles everything. The three APIs central to this milestone (`UnitClassification`, `UnitIsLieutenant`, `UnitClassBase`) are all stable, non-secret, and confirmed safe on nameplate unit tokens in Midnight dungeon instances. The `UNIT_CLASSIFICATION_CHANGED` event must be registered in Core.lua alongside the new classification caching — Blizzard's own nameplate classification frame uses this event for updates, confirming classification can change mid-encounter and the cache must be kept current.

**Core technologies:**
- `UnitClassification(unitToken)`: structural tier detection — confirmed used by `Blizzard_NamePlateUnitFrame.lua` on nameplate tokens; no Secret Value restrictions; returns `"worldboss"`, `"elite"`, `"rareelite"`, `"rare"`, `"normal"`, `"trivial"`, `"minus"`
- `UnitIsLieutenant(unitToken)`: miniboss tier signal — documented in 12.0.0, not exercised in any Blizzard UI file; wrap in `pcall` until in-game verified
- `UnitClassBase(unitToken)`: role-based category mapping (caster/warrior/rogue) — already in production use in v0.1.0; no changes needed
- `UNIT_CLASSIFICATION_CHANGED` event: cache invalidation for classification — confirmed real in `Blizzard_NamePlateClassificationFrame.lua` line 26; must be registered alongside `NAME_PLATE_UNIT_ADDED`

**Explicitly excluded:**
- `UnitEffectiveLevel`: unusable for nameplate-based detection — takes `cstring` name, not `UnitToken`; name retrieval from nameplates requires `UnitName` which is `SecretWhenUnitIdentityRestricted` in instances
- `ScrollBox/DataProvider`, `UIDropDownMenu`, `ResizeLayoutFrame`: not needed; existing `ScrollFrame + UIPanelScrollFrameTemplate` pattern from `PackFrame.lua` is sufficient for any ConfigFrame additions

### Expected Features

The research identified a clear MVP scope with explicit P1 and P2 priority tiers.

**Must have (table stakes for v0.1.1 launch):**
- `mobCategory` field on all Skyreach npcID entries in `Data/Skyreach.lua` — pilot dungeon fully categorized
- All other dungeons default to `"unknown"` (absent field = unknown; never nil at runtime via `entry.mobCategory or "unknown"`)
- `Pipeline.lua` propagates `mobCategory` from AbilityDB into merged ability tables (one-line addition in `MergeSkillConfig`)
- `NameplateScanner.lua` caches `UnitClassification` + `UnitIsLieutenant` at `NAME_PLATE_UNIT_ADDED`; registers `UNIT_CLASSIFICATION_CHANGED` for cache updates
- `categoryFilter` table in `TerriblePackWarningsDB` with defaults: `trivial = false`, all others `true`
- Category filter check in `OnMobsAdded` with unknown-as-wildcard invariant enforced: `ability.mobCategory == "unknown" OR ability.mobCategory == runtimeCategory`
- Category tag (read-only, color-coded) appended to mob header in `ConfigFrame.lua`
- Category filter toggle panel in `ConfigFrame.lua` (checkboxes for each category except "unknown")

**Should have (after in-game validation):**
- Expand category assignments to remaining 7 dungeons — after Skyreach accuracy is confirmed
- Color-coded category display using WoW color escape codes (boss=gold, miniboss=orange, caster=cyan, warrior=brown, rogue=yellow, trivial=dark gray, unknown=gray)
- `ShouldShowAbility(ability, runtimeCategory)` extracted as a named helper predicate

**Defer (v2+):**
- Per-category sound/alert override — defer until base category filter is validated useful
- Category color coding in PackFrame portrait rows

**Anti-features (never build):**
- User-editable categories — categories are factual properties of NPCs; user overrides create silent filter breakage and a support surface with no benefit
- Per-ability `mobCategory` field — category is a property of the npcID, not the spellID; duplicating per-ability creates inconsistency risk

### Architecture Approach

The v0.1.1 delta is strictly additive: new fields on existing data structures, new cached values in `plateCache`, one new lookup table (`activeCategoryByClass`), and one new filter predicate in `OnMobsAdded`. The hot Tick() loop is unchanged — category detection runs once per mob at `NAME_PLATE_UNIT_ADDED`, derived category is stored once per classBase in `activeCategoryByClass`, and the filter check in `OnMobsAdded` is a two-line guard outside the tick body.

The canonical data ownership is: `AbilityDB` holds the hardcoded semantic role (caster/warrior/rogue/trivial); `plateCache` holds the runtime-detected structural tier (boss/miniboss/trivial from WoW APIs). These two sources compose but never merge — `mobCategory` must not enter the SavedVariables-backed packed route data.

**Major components and their v0.1.1 changes:**
1. `Data/Skyreach.lua` — add `mobCategory` field to all npcID entries; all other Data/*.lua unchanged
2. `Engine/NameplateScanner.lua` — extend `plateCache` with `classification`/`isLieutenant`; add `activeCategoryByClass` table; add `DeriveCategory()` helper; add category filter in `OnMobsAdded`; register `UNIT_CLASSIFICATION_CHANGED`
3. `Import/Pipeline.lua` — propagate `mobCategory` in `MergeSkillConfig`; read from `ns.AbilityDB[npcID]`, NOT from individual ability entries
4. `UI/ConfigFrame.lua` — append read-only category tag to mob header; add category filter checkboxes panel
5. `Core.lua` — register `UNIT_CLASSIFICATION_CHANGED` event; route to new scanner handler

**Dependency-respecting build order:** Scanner extension (step 2) → Pipeline propagation (step 3) → Skyreach data (step 1) → Scanner filter activation (step 2 continued) → ConfigFrame display (step 4/5)

### Critical Pitfalls

1. **`UnitEffectiveLevel` is unusable for nameplate category detection** — it takes a `cstring` name argument, not a `UnitToken`. Getting a nameplate mob's name requires `UnitName(npUnit)`, which is `SecretWhenUnitIdentityRestricted` in dungeon instances. The entire chain is blocked. Do not implement it; grep for `UnitEffectiveLevel` at the end — must return zero results.

2. **Unknown wildcard must be an explicit positive exemption, never a nil check** — writing `if not ability.mobCategory or ability.mobCategory == detectedCategory` treats absent fields as wildcards and silently breaks as entries accumulate without the field. The correct form: `if ability.mobCategory == "unknown" or ability.mobCategory == runtimeCategory`. `"unknown"` is the explicit string; nil is never valid at the filter call site.

3. **`mobCategory` must never enter SavedVariables via Pipeline's merged ability object** — if `category` is added to the merged ability table in `MergeSkillConfig`, it gets written into `ns.db.importedRoutes` on import. All routes saved before the field was added will lack it, creating migration debt where none was needed. Category belongs in `AbilityDB` and `plateCache` only.

4. **`UnitClassification` must be cached at event time and updated via `UNIT_CLASSIFICATION_CHANGED`, not polled per tick** — calling it per tick at 20 nameplates adds ~40 extra API calls per tick (240/sec) with no benefit; classification is stable between events. `UNIT_CLASSIFICATION_CHANGED` exists precisely for invalidation. Cache at `NAME_PLATE_UNIT_ADDED`, update in handler, never call in `Tick()`.

5. **`mobClass` (WoW class token `"WARRIOR"`) and `mobCategory` (semantic role `"warrior"`) must not be conflated** — `classBarIds` and `classHasUntimed` in the scanner are keyed on `mobClass` WoW class strings. If `mobCategory` values are accidentally used as keys, no timer ever spawns — no nameplate returns `"caster"` or `"warrior"` from `UnitClass()`. The value sets must remain visually distinct: `mobClass` is uppercase WoW tokens; `mobCategory` is lowercase role strings.

---

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Data Layer and Schema Definition
**Rationale:** All downstream code depends on a settled `mobCategory` field definition. Establishing the schema, documenting the two-field distinction (`mobClass` vs `mobCategory`), and populating Skyreach data are pure data work with no code dependencies — they unblock all later phases and provide immediate visual value in ConfigFrame once Phase 4 lands. Doing this first prevents the `mobClass`/`mobCategory` confusion pitfall by locking in the value vocabulary before any code references it.
**Delivers:** `mobCategory` on all Skyreach npcID entries; explicit comment header in each data file documenting valid category values and field semantics; confirmed `"unknown"` as the explicit default string (never nil)
**Addresses:** Category field in AbilityDB (FEATURES P1); Skyreach pilot dungeon fully categorized
**Avoids:** `mobClass`/`mobCategory` confusion pitfall (Pitfall 4); nil-as-wildcard footgun (Pitfall 3); SavedVariables contamination decided before code is written (Pitfall 6)
**Research flag:** Skip — schema is fully specified in ARCHITECTURE.md; work is data entry, not API research

### Phase 2: Runtime Detection in NameplateScanner
**Rationale:** Scanner changes are the critical path — they block the filter feature. Extending `plateCache` and wiring `UNIT_CLASSIFICATION_CHANGED` before writing any filter logic ensures the cache is populated and up-to-date before it is consumed. `UnitIsLieutenant` must be wrapped in `pcall` here and its behavior confirmed with an in-game test before Phase 3 filter logic treats it as reliable.
**Delivers:** `classification` and `isLieutenant` cached in `plateCache` at `NAME_PLATE_UNIT_ADDED`; `DeriveCategory()` helper; `activeCategoryByClass` table populated per session and wiped on `Stop()`; `UNIT_CLASSIFICATION_CHANGED` registered and routed to a new `OnClassificationChanged` handler; `pcall` guard on `UnitIsLieutenant`
**Uses:** `UnitClassification` (HIGH confidence), `UnitIsLieutenant` (MEDIUM confidence — needs in-game validation), `UNIT_CLASSIFICATION_CHANGED` event (confirmed in Blizzard source)
**Avoids:** Per-tick polling pitfall (Pitfall 5); taint contamination from UI paths (Pitfall 2); `UnitEffectiveLevel` usage (Pitfall 1)
**Research flag:** Needs in-game validation — `UnitIsLieutenant` is unverified in any known codebase; test whether it returns meaningful values on the first dungeon pull

### Phase 3: Pipeline Propagation
**Rationale:** One-line change to `MergeSkillConfig` but must be correct before the filter in Phase 4 is meaningful. Delivering this as a discrete step prevents accidentally routing `mobCategory` into the SavedVariables-backed route data — the decision was made in Phase 1 but the implementation boundary is enforced here.
**Delivers:** `mobCategory` field on all merged ability tables produced by `MergeSkillConfig`; confirmed `entry.mobCategory or "unknown"` pattern (never nil); confirmed category is read from `ns.AbilityDB[npcID]`, not per-ability entries
**Avoids:** SavedVariables contamination (Pitfall 6); per-ability category duplication anti-pattern

### Phase 4: Category Filter in NameplateScanner
**Rationale:** With runtime detection (Phase 2) and propagated category fields (Phase 3) both in place, the filter predicate can be written correctly from the first line. The unknown-as-wildcard invariant is the only non-obvious logic; it must be verified with both Skyreach (filtered) and non-Skyreach (wildcard passes all) dungeon routes before shipping.
**Delivers:** `ShouldShowAbility(ability, runtimeCategory)` predicate helper; category filter guard in `OnMobsAdded`; debug validation pass at `Scanner:Start()` for missing category fields; `categoryFilter` SavedVariable with `trivial = false` default
**Addresses:** Per-category on/off toggle (FEATURES P1); unknown-as-wildcard invariant (FEATURES table stakes); sensible default filter state (trivial suppressed)
**Avoids:** Wildcard logic failure modes A and B (Pitfall 3); taint contamination from config writes (Pitfall 2)
**Research flag:** Needs dual in-dungeon verification — (1) Skyreach route: only matching categories show; (2) non-Skyreach route: all abilities display despite `"unknown"` category

### Phase 5: ConfigFrame Display
**Rationale:** Purely cosmetic; no functional dependency on any other phase beyond Skyreach data (Phase 1) for non-"unknown" labels. Can be parallelized with Phase 4 without risk, but is lower priority if time is constrained.
**Delivers:** Color-coded read-only category tag in mob header (`"MobName - WARRIOR [caster]"`); category filter checkbox panel (one per category; "unknown" excluded — always on, never shown); no editable controls for category; WoW color escape codes for each category tier
**Addresses:** Category visible in config (FEATURES P1); category filter toggle UI (FEATURES P1)
**Avoids:** User-editable category anti-feature; nil write path for category in config handlers (taint Pitfall 2)
**Research flag:** Skip — one-line `SetText` change and CheckButton creation are established patterns already in ConfigFrame.lua and PackFrame.lua

### Phase Ordering Rationale

- Phase 1 before everything: schema vocabulary must be locked before any code references the fields; prevents the `mobClass`/`mobCategory` naming confusion pitfall from manifesting in implementation
- Phase 2 before Phase 4: scanner state (`activeCategoryByClass`) must exist before the filter reads it; `UNIT_CLASSIFICATION_CHANGED` must be wired before the cache is depended on
- Phase 3 before Phase 4: merged abilities must carry `mobCategory` before the filter can apply non-wildcard checks — Phase 4 with only Phase 2 complete would see all abilities as `"unknown"` (safe, but the feature would be a no-op)
- Phase 4 before Phase 5: correct filtering is more important than display; the checkbox UI is meaningless if the underlying filter logic is wrong
- Phase 5 last: additive display change; shipping with "unknown" labels before Phase 1 is complete does not break anything

### Research Flags

Needs in-game validation during Phase 2:
- **`UnitIsLieutenant` runtime behavior:** Documented in 12.0.0 API docs with correct taint annotation but appears in zero Blizzard UI Lua files. Test on the first dungeon pull with `pcall` wrapping. If it returns nil or errors for all mobs, remove it and collapse `"miniboss"` to `"unknown"` for this milestone.

Needs dual verification during Phase 4:
- **Unknown-as-wildcard correctness:** Import a WindrunnerSpire route (all `"unknown"` categories) and confirm all abilities still display correctly. Import a Skyreach route and confirm category filtering applies. Both scenarios must pass before shipping.

Phases with standard patterns (no additional research needed):
- **Phase 1:** Pure data entry in the established `Data/*.lua` table format; no API risk
- **Phase 3:** Single-field addition to existing `MergeSkillConfig`; identical pattern to existing `mobClass` propagation
- **Phase 5:** ScrollFrame layout, color escape codes, and CheckButton creation are all established patterns already used in `PackFrame.lua` and `ConfigFrame.lua`

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All APIs verified against wow-ui-source 12.0.1.66337; taint annotations confirmed; `UnitClassification` usage confirmed in Blizzard's own nameplate code on nameplate unit tokens |
| Features | HIGH | Feature scope is well-defined; no novel UX patterns; competitor analysis confirms this is novel but design space is well-understood from first principles |
| Architecture | HIGH | All integration points derived from direct source analysis of the v0.1.0 codebase; build order has clear dependency rationale; no speculative components |
| Pitfalls | HIGH | Critical pitfalls verified against API documentation with exact line references; `UnitEffectiveLevel` trap confirmed with full call-chain analysis; taint model consistent with existing codebase patterns |

**Overall confidence:** HIGH

### Gaps to Address

- **`UnitIsLieutenant` runtime behavior (MEDIUM confidence):** Documented in 12.0.0, not used by any Blizzard UI code. Wrap in `pcall` at implementation time. Have a fallback plan ready: if it misbehaves, remove it and treat all non-boss mobs without explicit `mobCategory = "miniboss"` in data files as `"unknown"`. Recovery cost is LOW — one function call removed.

- **Skyreach `mobCategory` accuracy:** Category assignments are authored based on mob names and spell lists in the data files, not confirmed against in-game combat behavior. Some mobs may be miscategorized (a mob named "Warrior" may primarily cast spells). Validate during the first post-implementation dungeon run and update before treating Skyreach as reference data for expanding to other dungeons.

- **`UNIT_CLASSIFICATION_CHANGED` trigger frequency in M+:** Confirmed the event exists and Blizzard uses it in their nameplate code, but the exact conditions that fire it in Midnight M+ dungeon content are not documented. In practice it fires on boss phase transitions and elite promotions. Low risk — the cache is always correct at nameplate-add time; the event only matters for mid-combat classification changes.

---

## Sources

### Primary (HIGH confidence)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` — `UnitClassification` (line 947), `UnitIsLieutenant` (line 1995), `UnitEffectiveLevel` (line 1086, cstring arg confirmed), `UnitName` (line 2345, SecretWhenUnitIdentityRestricted), `UnitCastingInfo`/`UnitChannelInfo` (lines 811–877)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateUnitFrame.lua` line 359 — `UnitClassification` called on nameplate unit token in Blizzard's own code; confirms Midnight M+ compatibility
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateClassificationFrame.lua` line 26 — `UNIT_CLASSIFICATION_CHANGED` event registration confirmed; full return value set confirmed
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_UnitFrame/Mainline/TargetFrame.lua` lines 370–440 — `UnitClassification` full branch coverage and `UnitIsBossMob` usage (line 427)
- `C:/Users/jonat/Repositories/MythicDungeonTools/Midnight/WindrunnerSpire.lua` and `MaisaraCaverns.lua` — MDT enemy/spell table structure; confirmed `isBoss` boolean only, no role-based categories
- `C:/Users/jonat/Repositories/TerriblePackWarnings/Engine/NameplateScanner.lua` — plateCache structure; existing API call patterns confirmed working in production; integration points for new fields
- `C:/Users/jonat/Repositories/TerriblePackWarnings/Import/Pipeline.lua` — `MergeSkillConfig` output fields; SavedVariables write path confirmed

### Secondary (MEDIUM confidence)
- Warcraft Wiki: https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes — `UnitIsLieutenant` listed as newly added in 12.0.0
- Warcraft Wiki: https://warcraft.wiki.gg/wiki/API_UnitClassification — return value set and `AllowedWhenUntainted` annotation

### Tertiary (needs in-game validation)
- `UnitIsLieutenant` runtime behavior in Midnight M+ dungeons — documented with correct taint annotation, not exercised in any known Blizzard Lua file; behavior unverified until first dungeon pull

---
*Research completed: 2026-03-23*
*Ready for roadmap: yes*
