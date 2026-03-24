# Phase 20: Runtime Detection and Scanner Matching - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Rework the nameplate scanner from class-based to category-based matching. Derive runtime mob categories at `NAME_PLATE_UNIT_ADDED` using WoW APIs, cache in plateCache, and gate ability activation so only matching-category (or unknown-wildcard) abilities fire. Pipeline copies `mobCategory` from AbilityDB onto ability objects at build time. This is the phase that fixes the intentional breaking change from Phase 19 (mobClass removal).

</domain>

<decisions>
## Implementation Decisions

### Category matching model (replaces class-based)
- Scanner shifts from class-based to category-based matching entirely
- `Tick()` counts mobs by their derived category (from `plateCache[unit].category`), not by `classBase`
- `OnMobsAdded(category, delta)` fires per category instead of per class
- Abilities match via `ability.mobCategory == detectedCategory`
- Timer tracking: `categoryBarIds[category]` replaces `classBarIds[classBase]` — same logic, different key
- Cast detection switches to category-based: `categoryHasUntimed`, `castingByCategory`, `OnCastStart(category)`, `OnCastEnd(category)`
- No new API calls in the hot loop — `Tick()` reads `plateCache[unit].category` which was populated at `NAME_PLATE_UNIT_ADDED`

### Pipeline propagation
- `Pipeline.MergeSkillConfig` copies `mobCategory` from `ns.AbilityDB[npcID]` onto each ability object (replacing the old `mobClass` copy)
- This is runtime-only — category comes from AbilityDB each time packs are built, does NOT get saved to SavedVariables
- Scanner reads `ability.mobCategory` on the ability object, not from AbilityDB lookup

### DeriveCategory priority chain (locked)
Runtime category detection runs once per mob at `NAME_PLATE_UNIT_ADDED`:

1. `UnitIsBossMob(unit)` returns true → `"boss"`
2. `UnitIsLieutenant(unit)` returns true (pcall-wrapped) → `"miniboss"`
3. `UnitClassification(unit)` is NOT `"elite"` (i.e., `"normal"`, `"trivial"`, `"minus"`, `"rare"`, `"rareelite"`) → `"trivial"`
4. (Elite mobs only) `UnitClassBase(unit)` == `"PALADIN"` → `"caster"`
5. (Elite mobs only) `UnitClassBase(unit)` == `"ROGUE"` → `"rogue"`
6. (Elite mobs only) `UnitClassBase(unit)` == `"WARRIOR"` → `"warrior"`
7. Anything else → `"unknown"` + debug log warning

Key: lieutenants are often PALADINs — step 2 runs before step 4, so a PALADIN lieutenant → miniboss, not caster.

### Unknown/wildcard matching rules
- **Ability is unknown** (`ability.mobCategory == "unknown"`) → fires for ANY mob entering combat, regardless of mob's runtime category
- **Mob runtime is unknown** (unexpected class like Evoker) → only triggers abilities whose `mobCategory == "unknown"`. Debug log if any mob gets unknown at runtime.
- **Both known** → must match exactly (`ability.mobCategory == mob's runtime category`)
- The explicit string `"unknown"` is used — never nil. `nil` is a bug.

### Event handling
- `UNIT_CLASSIFICATION_CHANGED` registered in `Core.lua`, routed to scanner handler that updates `plateCache[unit].category`
- `UnitIsLieutenant` wrapped in `pcall` — if it errors or returns nil, that step is skipped (falls through to classification/class checks)
- All new API calls (`UnitClassification`, `UnitIsLieutenant`, `UnitIsBossMob`) happen at event time only, NEVER in `Tick()`

### Claude's Discretion
- Exact variable naming for renamed tables (categoryBarIds vs classCategoryBarIds etc.)
- How to handle the `spellIndex` and `classHasUntimed` rework (now `categoryHasUntimed`)
- Whether to extract `DeriveCategory` as a local function or a Scanner method
- Debug log formatting for the category detection results

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scanner (primary modification target)
- `Engine/NameplateScanner.lua` — Full file: OnNameplateAdded, OnMobsAdded, OnCastStart, OnCastEnd, Tick, Start, Stop all need category rework
- `Core.lua` — Event registration: must add UNIT_CLASSIFICATION_CHANGED handler

### Pipeline (mobCategory propagation)
- `Import/Pipeline.lua` — MergeSkillConfig: replace mobClass copy with mobCategory copy from AbilityDB

### Data (category source)
- `Data/Skyreach.lua` — Reference for mobCategory field format (Phase 19 output)

### Research
- `.planning/research/SUMMARY.md` — API details, pitfalls (UnitEffectiveLevel exclusion, plateCache caching strategy, UNIT_CLASSIFICATION_CHANGED event)
- `.planning/phases/19-data-layer/19-CONTEXT.md` — Phase 19 decisions (mobClass removed, mobCategory is sole descriptor)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `plateCache` table in NameplateScanner.lua — already caches hostile/classBase per unit. Extend with `category` field.
- `OnNameplateAdded`/`OnNameplateRemoved` — existing event handlers to extend with classification caching
- `pcall` pattern — already used for UnitCastingInfo/UnitChannelInfo in Tick(). Same pattern for UnitIsLieutenant.
- `dbg()` function — existing debug logger, use for unknown category warnings

### Established Patterns
- `plateCache[unitToken] = { hostile = bool, classBase = string }` — add `category = string`
- `classBarIds[classBase]` → rename to `categoryBarIds[category]`
- `classHasUntimed[classBase]` → rename to `categoryHasUntimed[category]`
- `castingByClass[classBase]` → rename to `castingByCategory[category]`
- Event registration in Core.lua: `frame:RegisterEvent("EVENT_NAME")` pattern

### Integration Points
- `Core.lua` lines with event routing — add `UNIT_CLASSIFICATION_CHANGED` → `Scanner:OnClassificationChanged(unit)`
- `Import/Pipeline.lua` `MergeSkillConfig` — line where `mobClass` was copied onto abilities, replace with `mobCategory`
- `Scanner:Start(pack)` — builds lookup tables from pack.abilities, must switch from mobClass to mobCategory keys

### Breaking Changes from Phase 19
- `ability.mobClass` is nil everywhere (field removed from AbilityDB, Pipeline no longer copies it)
- All references to `ability.mobClass` and `classBase`-keyed matching must be reworked

</code_context>

<specifics>
## Specific Ideas

- The reference addon's approach: non-elite = trivial, elite mobs get class-based subtyping (PALADIN=caster, ROGUE=rogue, WARRIOR=warrior), boss/lieutenant detected first
- Most lieutenants are PALADINs in WoW — the priority chain must check lieutenant BEFORE class to avoid miscategorizing minibosses as casters

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 20-runtime-detection-and-scanner-matching*
*Context gathered: 2026-03-23*
