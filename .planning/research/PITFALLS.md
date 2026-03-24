# Pitfalls Research

**Domain:** Adding mob category detection to existing WoW Midnight nameplate scanning addon (v0.1.1)
**Researched:** 2026-03-23
**Confidence:** HIGH — critical API findings verified against WoW UI source at `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` and Blizzard nameplate source

---

## Critical Pitfalls

### Pitfall 1: UnitEffectiveLevel Is Blocked by the Secret Value Chain

**What goes wrong:**
`UnitEffectiveLevel` takes a `cstring` name argument — NOT a unit token (UnitDocumentation.lua line 1092: `{ Name = "name", Type = "cstring", Nilable = false }`). The only way to call it from a nameplate unit token would be `UnitEffectiveLevel(UnitName(npUnit))`. However, `UnitName` has `SecretWhenUnitIdentityRestricted = true` (UnitDocumentation.lua line 2347), meaning it returns a Secret Value in dungeon instances. A Secret Value cannot be used as a plain `cstring` argument. The chain breaks: nameplate token → `UnitName(npUnit)` → Secret Value → `UnitEffectiveLevel` errors or returns garbage. `UnitEffectiveLevel` is effectively unusable for any nameplate-based category detection in Midnight dungeons.

**Why it happens:**
`UnitClassification` and `UnitIsLieutenant` both take `UnitToken` arguments and work directly with nameplate tokens. It is natural to assume `UnitEffectiveLevel` works the same way. The Midnight API changes docs list `UnitIsLieutenant` as newly added without noting `UnitEffectiveLevel`'s different argument type. The two APIs are mentioned together in design documents but behave completely differently.

**How to avoid:**
Remove `UnitEffectiveLevel` from the category detection plan entirely. Use only `UnitClassification` (returns `"elite"`, `"rare"`, `"rareelite"`, `"worldboss"`, `"normal"`, `"trivial"`, `"minus"`) and `UnitIsLieutenant` (returns `bool`). Both take `UnitToken` and work with nameplate unit tokens. These two APIs provide sufficient signal: classification string distinguishes normal/elite/boss-tier, and `UnitIsLieutenant` adds a miniboss signal.

**Warning signs:**
- Lua error: `"attempt to use a Secret Value as a string"` when calling UnitEffectiveLevel
- `UnitEffectiveLevel` returns the same value for all nameplates (silent failure — the name resolves to something but not the mob)
- Category detection works in the open world but silently fails in dungeons/instances

**Phase to address:**
Phase 1 (API Verification). Verify all three API signatures against UnitDocumentation.lua before writing any detection code. Do not implement `UnitEffectiveLevel` at all.

---

### Pitfall 2: AllowedWhenUntainted — Taint Contamination Breaks the Detection APIs

**What goes wrong:**
`UnitClassification`, `UnitIsLieutenant`, `UnitClass`, `UnitCanAttack`, and `UnitAffectingCombat` all share the same flag: `SecretArguments = "AllowedWhenUntainted"`. This means these functions can only receive Secret Values (like nameplate unit tokens in instances) when the calling code is untainted. If the scanner's tick function runs in a tainted execution context, the API calls will fail or return nil. The existing APIs work because C_Timer tickers run untainted by default. The risk introduced in this milestone: if a new code path for category filtering is wired directly from a UI interaction (e.g., a category checkbox callback that writes directly into scanner state), that interaction taints the calling context. Any scanner state that flows through a tainted write path can poison the ticker's closure.

**Why it happens:**
Taint propagates through upvalues. If a tainted function modifies `activePack` or `plateCache` directly, the scanner's closure captures those tainted values, and subsequent API calls using them fail. This is subtle because the ticker itself is not tainted — only the values it operates on.

**How to avoid:**
Keep all category filter configuration reads in the scanner happening only at `Scanner:Start()` time, not during the tick loop. Write any new category-related settings to `ns.db` (SavedVariables) from UI code, and have `Start()` read `ns.db` once to build its working state. Never write directly to `activePack`, `plateCache`, or any scanner-local table from a UI event handler or checkbox callback. This is the same isolation pattern the existing system uses for all skill configuration.

**Warning signs:**
- `"attempt to use a Secret Value..."` errors appearing specifically after opening or interacting with the config window
- Classification detection stops working after a UI button click, even without reloading
- `UnitClassification(npUnit)` returns nil for unit tokens that previously returned valid strings

**Phase to address:**
Phase 1 (API Verification) — audit the isolation boundary before writing any code. Phase 2 (Runtime Detection) — add no UI→scanner direct state writes when wiring the category display in ConfigFrame.

---

### Pitfall 3: Unknown Wildcard Logic Silently Disables 87% of Abilities

**What goes wrong:**
Two opposite failure modes exist for the wildcard filter logic:

**Mode A (too strict):** The filter requires `ability.category == detectedCategory`. `"unknown"` in AbilityDB never equals any detected category string (`"normal"`, `"elite"`, etc.). All `"unknown"`-category mobs have their abilities filtered out. Since all 7 non-Skyreach dungeons default to `"unknown"`, this silently disables ability detection for all content except Skyreach. No error fires.

**Mode B (too broad):** The guard is written as `if not ability.category or ability.category == detectedCategory`. A missing `category` field (nil) is treated as wildcard. Any future AbilityDB entry added without a category field will accidentally bypass all filtering, even in fully-categorized dungeons.

**Why it happens:**
The intent ("unknown means never filtered") and the filter implementation ("only show if category matches") are in tension. Both failure modes are written as correct-looking Lua without errors. The symptoms only appear in live dungeon testing.

**How to avoid:**
Use an explicit string `"unknown"` in AbilityDB — never `nil` — and write the filter as a positive exemption: `if ability.category == "unknown" or ability.category == runtimeCategory then show end`. Add a validation pass at `Scanner:Start()` (behind `ns.db.debug`) that logs a warning for any ability with a nil or missing `category` field. Require every AbilityDB entry to have an explicit `category` field regardless of value.

**Warning signs:**
- All abilities show for every mob regardless of type (Mode B — wildcard too broad)
- After adding the filter, abilities stop showing entirely for non-Skyreach dungeons (Mode A — wildcard not firing)
- Skyreach abilities show correctly but zero abilities appear for Pit of Saron or Algethar Academy

**Phase to address:**
Phase 2 (Runtime Detection) — write the filter with explicit wildcard exemption from the first line of code, never as a refinement pass. Phase 3 (Data Layer) — validation pass at Start() for missing category fields.

---

### Pitfall 4: mobClass and category Field Confusion in the Scanner's Index Tables

**What goes wrong:**
The current system uses `mobClass` (e.g., `"WARRIOR"`, `"MAGE"`) on ability objects to match `UnitClass()` return values. The new `category` field (e.g., `"caster"`, `"miniboss"`) has overlapping semantic territory. Confusion between them in the scanner produces silent logic errors: using `ability.category` where `ability.mobClass` was intended in `classBarIds` and `classHasUntimed` lookups, or copying `category` into the per-ability object's `mobClass` field during MergeSkillConfig in Pipeline.lua. Both fields use plain strings and both describe mob type — the bug runs without errors but tracks the wrong dimension entirely.

The specific silent failure: if `classBarIds["caster"]` is populated instead of `classBarIds["MAGE"]`, the scanner tracks zero mobs (no nameplate unit will ever return `"caster"` from `UnitClass()`), and no timers spawn.

**Why it happens:**
`mobClass = "WARRIOR"` means "WoW creature class token for UnitClass() matching." `category = "warrior"` means "gameplay role tier for display/filtering." The category value `"warrior"` looks like a valid class name (WoW returns uppercase `"WARRIOR"` but the lowercase `"warrior"` category is visually similar). The names and values are close enough that incorrect usage goes unnoticed during code review.

**How to avoid:**
Name the category values with terms that cannot be confused with WoW class tokens: use `"boss"`, `"miniboss"`, `"caster"`, `"melee"`, `"trivial"`, `"unknown"` — not `"warrior"` or any other WoW class name. Add a comment at the top of each AbilityDB data file explaining the two fields: `mobClass` = WoW UnitClass token (must match UnitClass() return exactly), `category` = gameplay tier (used for display only, never for UnitClass matching). Do not propagate `category` into merged ability objects in Pipeline.lua — the scanner uses `mobClass` for detection; `category` is only needed in UI display paths.

**Warning signs:**
- No ability timers spawn on pull despite mobs being in combat (classBarIds keyed on category instead of mobClass)
- `classHasUntimed` lookup returns nil for all classes (wrong key used during Start())
- Category display in ConfigFrame shows WoW class names ("WARRIOR") instead of tier labels

**Phase to address:**
Phase 1 (Data Layer Schema) — document the distinction in code comments before writing any data entries. Use separate, visually distinct value sets for each field.

---

### Pitfall 5: Over-Caching or Under-Caching Classification in the Hot Loop

**What goes wrong:**
Two caching failure modes:

**Mode A (no cache, per-tick calls):** `UnitClassification` and `UnitIsLieutenant` are called on every nameplate on every 0.25s tick. The existing tick already makes ~20 `UnitAffectingCombat` calls for 20 nameplates. Adding 2 more classification calls per nameplate triples the API call budget to ~60 calls/tick (240/sec). The UNIT_CLASSIFICATION_CHANGED event (confirmed in Blizzard_NamePlateClassificationFrame.lua line 26) exists precisely because classification can change and Blizzard's own nameplate system uses event-driven updates rather than polling.

**Mode B (cached at add time, no update):** `UnitClassification` is cached at `NAME_PLATE_UNIT_ADDED` but `UNIT_CLASSIFICATION_CHANGED` is not registered. If a mob changes classification mid-encounter (confirmed as a real WoW event), the cached value becomes stale. Ability display may show wrong category or miss a category transition.

**Why it happens:**
The existing system caches `UnitClass` and `UnitCanAttack` at add time because they are stable per mob. It is natural to apply the same rule to `UnitClassification`. But classification is explicitly designed to change, which is why `UNIT_CLASSIFICATION_CHANGED` exists.

**How to avoid:**
Cache `UnitClassification` and `UnitIsLieutenant` at `NAME_PLATE_UNIT_ADDED` — do NOT call them per tick. Additionally register `UNIT_CLASSIFICATION_CHANGED` in Core.lua and route it to a new handler that updates only the specific `plateCache[unitToken].category` entry. The pattern: event-driven cache for stable-ish values, event-driven update for values that can change, never per-tick polling for classification. The updated plateCache entry: `{ hostile, classBase, category }` where category is derived at add-time and updated on classification-changed.

**Warning signs:**
- Tick time measurably increases after adding classification calls
- `/tpw status` reports category as "elite" for mobs that are clearly normal-tier
- Category display works on the first pull but shows wrong values after a boss phase transition

**Phase to address:**
Phase 2 (Runtime Detection) — wire `UNIT_CLASSIFICATION_CHANGED` event registration in Core.lua at the same time as implementing classification caching in `OnNameplateAdded`. These two changes must ship together.

---

### Pitfall 6: SavedVariables Schema Migration Is Not Needed — But Looks Like It Is

**What goes wrong:**
The `category` field lives in AbilityDB data files (Lua source), not in `TerriblePackWarningsDB` SavedVariables. Merged ability objects produced by Pipeline.lua's `MergeSkillConfig` do not need to carry `category` because the scanner uses `mobClass` for detection. The config UI reads `category` from `ns.AbilityDB[npcID].category` at display time, not from saved data. No schema migration is needed. However, if a developer adds `category` to the merged ability object produced by `MergeSkillConfig` (to "make it available everywhere"), it gets written into `ns.db.importedRoutes[dungeonKey].packs` on import. Then it IS in SavedVariables, stale entries from before category was added will lack the field, and a migration is suddenly needed where none was required.

**Why it happens:**
The Pipeline produces flat ability objects that flow through multiple systems. Adding fields to that object feels like the natural "make the data available" approach. The consequence (writing derived data into SavedVariables and creating migration debt) is non-obvious because the route data is saved to disk as part of the import flow.

**How to avoid:**
Do not add `category` to the merged ability object in Pipeline.lua. Keep `category` on `AbilityDB` entries only. In the scanner, derive the runtime category from `plateCache[unitToken].category` (detected via API), not from `ability.category`. In ConfigFrame.lua, read `ns.AbilityDB[npcID].category` at UI draw time. No SavedVariables migration needed. If in doubt: schemaVersion stays at 2 for this milestone.

**Warning signs:**
- `ability.category` referenced inside NameplateScanner.lua (wrong — scanner should use plateCache)
- `ns.db.importedRoutes[key].packs[i].abilities[j].category` exists in saved data after an import
- A schemaVersion bump appears in Core.lua for this milestone without a clear reason

**Phase to address:**
Phase 1 (Data Layer Schema) — decide the canonical location of `category` before writing any code, and document it. The decision: AbilityDB for the hardcoded tier, plateCache for the runtime-detected tier. These are separate data and should never merge.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Leave all non-Skyreach mobs as `"unknown"` category permanently | No data entry work for 7 dungeons | Feature is invisible in all but one dungeon; users see no benefit in 87% of content | Acceptable in v0.1.1 if scoped as Skyreach-only; must be filled in later milestones |
| Inline the category filter condition directly in OnMobsAdded without extracting a predicate function | Simpler first implementation | Category logic mixed with mob tracking logic; future changes to filtering (user-configurable category toggle) require understanding the full mob-add flow | Marginal — extract a `ShouldShowAbility(ability, runtimeCategory)` helper at minimum |
| Use `ability.category == nil` as the wildcard check | Saves writing `category = "unknown"` on 190+ entries | Silent breakage when new entries added without category; nil and unknown are indistinguishable in debug output | Never |
| Add `category` to merged ability object in Pipeline.lua | Category available everywhere via ability reference | Pollutes SavedVariables; creates migration debt; stale entries after data file updates | Never |
| Call UnitClassification per-tick without caching | Simpler — no event wiring needed | ~40 extra API calls per tick at 20 nameplates; unnecessary given UNIT_CLASSIFICATION_CHANGED event exists | Never |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| plateCache in NameplateScanner | Adding `category` to merged ability objects in Pipeline.lua instead of the nameplate cache | `category` is a runtime property of a live unit; put it in `plateCache[unitToken].category`, not in ability objects |
| AbilityDB data files | Writing `category = "warrior"` (lowercase, looks like a WoW class name) | Use values that are visually distinct from WoW class tokens: `"melee"`, `"caster"`, `"miniboss"`, `"boss"`, `"trivial"`, `"unknown"` |
| Core.lua event routing | Implementing classification caching without wiring `UNIT_CLASSIFICATION_CHANGED` | Register `UNIT_CLASSIFICATION_CHANGED` in Core.lua alongside `NAME_PLATE_UNIT_ADDED`; route to a new `Scanner:OnClassificationChanged(unitToken)` method |
| UnitEffectiveLevel | Calling `UnitEffectiveLevel(npUnit)` with a nameplate unit token | This API takes a `cstring` name, not a unit token; `UnitName` returns Secret Values in instances; do not use this API at all for category detection |
| ConfigFrame display | Reading `ability.category` from the merged pack ability object | Read `ns.AbilityDB[npcID].category` directly at UI draw time; the merged object does not and should not carry `category` |
| SchemaVersion | Bumping schemaVersion because category was added | Category is in AbilityDB source files, not SavedVariables; no migration needed unless `category` is accidentally added to the packed data |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Calling UnitClassification per-tick per-nameplate | Tick time measurably increases; profiler flags NameplateScanner:Tick | Cache at NAME_PLATE_UNIT_ADDED; update on UNIT_CLASSIFICATION_CHANGED event only | At ~15+ nameplates (common in large pulls) |
| Calling UnitIsLieutenant per-tick per-nameplate | Same as above; combined with UnitClassification adds 40+ extra calls/tick | Cache at NAME_PLATE_UNIT_ADDED alongside UnitClassification | Immediately visible at any non-trivial pull size |
| Category filter as O(abilities) scan inside the tick loop | Tick time grows with pack size | Category filter belongs in OnMobsAdded (called only on count change), not the per-tick body | At 30+ abilities in a large multi-mob pull |

---

## "Looks Done But Isn't" Checklist

- [ ] **UnitEffectiveLevel absent from codebase:** Search for `UnitEffectiveLevel` string in all .lua files — must return zero results after implementation
- [ ] **Classification cached at add time:** `/tpw debug` shows category logged per nameplate at `NAME_PLATE_UNIT_ADDED` time, not per-tick
- [ ] **UNIT_CLASSIFICATION_CHANGED registered:** Event appears in Core.lua's RegisterEvent list and routes to a Scanner handler; verify the handler updates plateCache
- [ ] **Unknown wildcard fires:** Import and activate a non-Skyreach dungeon route; abilities must still display for all mobs despite `category = "unknown"` in AbilityDB
- [ ] **Skyreach category populated:** Every Skyreach npcID in AbilityDB has an explicit `category` field — no Skyreach mob falls through to `"unknown"` unintentionally
- [ ] **No category in SavedVariables:** After an import, inspect `ns.db.importedRoutes[key].packs[i].abilities[j]` — no `category` field should appear; schemaVersion stays at 2
- [ ] **mobClass lookup still correct:** After implementing category, `classBarIds` and `classHasUntimed` in NameplateScanner must still key on `ability.mobClass` (a WoW class token), not `ability.category`
- [ ] **Config UI shows category as read-only:** ConfigFrame displays category label but has no input field for it; no `cfg.category` write path exists anywhere

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| UnitEffectiveLevel used and breaking in instances | LOW | Remove all UnitEffectiveLevel calls; UnitClassification string gives sufficient tier signal without needing level data |
| Unknown wildcard filtering all non-Skyreach abilities | LOW | Invert the filter guard condition; add debug log at ability-show time; 5-line fix |
| Taint contamination from UI code path | MEDIUM | Audit all new scanner state writes added in this milestone; move any UI-triggered writes to happen only at Start() via clean rebuild; no refactor of existing code needed |
| mobClass/category confusion in scanner index tables | MEDIUM | Grep for `ability.category` in NameplateScanner.lua — should be zero; grep for `category` as a classBarIds or classHasUntimed key — should be zero; fix any found occurrences |
| Category accidentally written into SavedVariables | LOW | Remove `category` from MergeSkillConfig output; re-import any routes to get clean saved data; no schemaVersion bump needed |
| Missing UNIT_CLASSIFICATION_CHANGED wiring | LOW | Add event registration and one-line cache update handler; no scanner restart needed; plateCache self-corrects on next nameplate re-add |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| UnitEffectiveLevel API signature mismatch | Phase 1: API Verification | Grep for "UnitEffectiveLevel" — zero results |
| Taint contamination from new code paths | Phase 1: API Verification + Phase 2: Runtime Detection | Full combat session after config window interactions; no taint errors in chat |
| Unknown wildcard logic (Mode A or B) | Phase 2: Runtime Detection | Non-Skyreach dungeon test: all abilities must display; Skyreach test: only matching categories display |
| mobClass vs category field confusion | Phase 1: Data Layer Schema | Inspect classBarIds keys after a pull: must be WoW class tokens (e.g., "WARRIOR"), not category strings (e.g., "melee") |
| Classification over/under caching | Phase 2: Runtime Detection | Profile tick duration before/after; confirm UNIT_CLASSIFICATION_CHANGED appears in Core.lua RegisterEvent list |
| Category leaked into SavedVariables | Phase 1: Data Layer Schema | Inspect packed ability objects in SavedVariables after import: no category field present |
| schemaVersion bump without justification | Phase 1: Data Layer Schema | schemaVersion remains 2 at end of milestone; verify in Core.lua |

---

## Sources

- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` — authoritative API signatures and Secret Value flags: `UnitClassification` (line 947, `SecretArguments = "AllowedWhenUntainted"`, `UnitToken` arg), `UnitEffectiveLevel` (line 1086, `SecretArguments = "AllowedWhenUntainted"`, `cstring` arg — NOT a unit token), `UnitIsLieutenant` (line 1995, `SecretArguments = "AllowedWhenUntainted"`, `UnitToken` arg), `UnitName` (line 2345, `SecretWhenUnitIdentityRestricted = true` — returns Secret Value in instances)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateClassificationFrame.lua` — confirms `UNIT_CLASSIFICATION_CHANGED` event is real and Blizzard's own nameplate system uses event-driven classification updates (line 26)
- `Engine/NameplateScanner.lua` (this repo) — confirmed existing APIs (`UnitClass`, `UnitCanAttack`, `UnitAffectingCombat`) have same `AllowedWhenUntainted` flag; plateCache pattern; tick cost analysis
- `Import/Pipeline.lua` (this repo) — MergeSkillConfig output fields; SavedVariables write path; confirmed `category` is NOT currently in merged ability objects
- Warcraft Wiki: https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes — `UnitIsLieutenant` listed as newly added in 12.0.0
- Warcraft Wiki: https://warcraft.wiki.gg/wiki/API_UnitClassification — return values: "worldboss", "rareelite", "elite", "rare", "normal", "trivial", "minus"; marked `AllowedWhenUntainted` in 12.0.1

---
*Pitfalls research for: TerriblePackWarnings v0.1.1 — Adding Mob Category Detection*
*Researched: 2026-03-23*
