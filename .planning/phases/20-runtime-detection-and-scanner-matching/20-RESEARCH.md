# Phase 20: Runtime Detection and Scanner Matching - Research

**Researched:** 2026-03-23
**Domain:** WoW Midnight (12.0) nameplate scanner — category-based mob matching
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Category matching model (replaces class-based)**
- Scanner shifts from class-based to category-based matching entirely
- `Tick()` counts mobs by their derived category (from `plateCache[unit].category`), not by `classBase`
- `OnMobsAdded(category, delta)` fires per category instead of per class
- Abilities match via `ability.mobCategory == detectedCategory`
- Timer tracking: `categoryBarIds[category]` replaces `classBarIds[classBase]` — same logic, different key
- Cast detection switches to category-based: `categoryHasUntimed`, `castingByCategory`, `OnCastStart(category)`, `OnCastEnd(category)`
- No new API calls in the hot loop — `Tick()` reads `plateCache[unit].category` which was populated at `NAME_PLATE_UNIT_ADDED`

**Pipeline propagation**
- `Pipeline.MergeSkillConfig` copies `mobCategory` from `ns.AbilityDB[npcID]` onto each ability object (replacing the old `mobClass` copy)
- This is runtime-only — category comes from AbilityDB each time packs are built, does NOT get saved to SavedVariables
- Scanner reads `ability.mobCategory` on the ability object, not from AbilityDB lookup

**DeriveCategory priority chain (locked)**
Runtime category detection runs once per mob at `NAME_PLATE_UNIT_ADDED`:
1. `UnitIsBossMob(unit)` returns true → `"boss"`
2. `UnitIsLieutenant(unit)` returns true (pcall-wrapped) → `"miniboss"`
3. `UnitClassification(unit)` is NOT `"elite"` (i.e., `"normal"`, `"trivial"`, `"minus"`, `"rare"`, `"rareelite"`) → `"trivial"`
4. (Elite mobs only) `UnitClassBase(unit)` == `"PALADIN"` → `"caster"`
5. (Elite mobs only) `UnitClassBase(unit)` == `"ROGUE"` → `"rogue"`
6. (Elite mobs only) `UnitClassBase(unit)` == `"WARRIOR"` → `"warrior"`
7. Anything else → `"unknown"` + debug log warning

Key: lieutenants are often PALADINs — step 2 runs before step 4, so a PALADIN lieutenant → miniboss, not caster.

**Unknown/wildcard matching rules**
- Ability is unknown (`ability.mobCategory == "unknown"`) → fires for ANY mob entering combat, regardless of mob's runtime category
- Mob runtime is unknown (unexpected class like Evoker) → only triggers abilities whose `mobCategory == "unknown"`. Debug log if any mob gets unknown at runtime.
- Both known → must match exactly (`ability.mobCategory == mob's runtime category`)
- The explicit string `"unknown"` is used — never nil. `nil` is a bug.

**Event handling**
- `UNIT_CLASSIFICATION_CHANGED` registered in `Core.lua`, routed to scanner handler that updates `plateCache[unit].category`
- `UnitIsLieutenant` wrapped in `pcall` — if it errors or returns nil, that step is skipped (falls through to classification/class checks)
- All new API calls (`UnitClassification`, `UnitIsLieutenant`, `UnitIsBossMob`) happen at event time only, NEVER in `Tick()`

### Claude's Discretion
- Exact variable naming for renamed tables (categoryBarIds vs classCategoryBarIds etc.)
- How to handle the `spellIndex` and `classHasUntimed` rework (now `categoryHasUntimed`)
- Whether to extract `DeriveCategory` as a local function or a Scanner method
- Debug log formatting for the category detection results

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DETC-01 | `UnitClassification` is cached per nameplate unit at `NAME_PLATE_UNIT_ADDED` in `plateCache` | Confirmed: `UnitClassification` is stable, non-secret, called directly on nameplate unit tokens in Blizzard's own nameplate code. Cache pattern already established for `hostile` and `classBase` in existing `plateCache`. |
| DETC-02 | `UNIT_CLASSIFICATION_CHANGED` event is registered and updates the classification cache | Confirmed: Event confirmed real in `Blizzard_NamePlateClassificationFrame.lua` line 26. Must be registered in `Core.lua` and routed to `Scanner:OnClassificationChanged(unit)`. |
| DETC-03 | `UnitIsLieutenant` is called with `pcall` wrapping and cached alongside classification | MEDIUM: Documented in 12.0.0, not in any Blizzard Lua file. Must use `pcall`. If it errors, falls through to classification check. |
| DETC-04 | `DeriveCategory()` helper combines classification + lieutenant + classBase into a category string | Clear from locked priority chain. Implement as a local function in NameplateScanner.lua. |
| DETC-05 | Runtime-derived category is cached per nameplate unit in `plateCache`, not per classBase | Confirmed pattern: `plateCache[unitToken].category = DeriveCategory(unitToken)` at event time. |
| SCAN-01 | Scanner reads mob category from `ns.AbilityDB[npcID]` directly at match time (no duplication) | Note: CONTEXT.md overrides earlier research note — category IS copied onto ability objects via Pipeline.MergeSkillConfig at pack-build time; the "no duplication" constraint means it does NOT go into SavedVariables. Scanner reads `ability.mobCategory` on the in-memory ability object. |
| SCAN-02 | Mobs with `mobCategory == "unknown"` pass all category checks (wildcard — false positives over false negatives) | Correct filter form: `ability.mobCategory == "unknown" or ability.mobCategory == runtimeCategory`. Nil is never valid at this call site. |
| SCAN-03 | Mobs with a known category only trigger abilities when runtime-detected category matches | Flows from SCAN-02 — the same two-branch predicate handles both cases. |
</phase_requirements>

---

## Summary

Phase 20 reworks `Engine/NameplateScanner.lua` and `Import/Pipeline.lua` to replace all class-based matching (`classBase` / `mobClass`) with category-based matching (`category` / `mobCategory`). This is the phase that repairs the intentional breaking change from Phase 19 — which removed `mobClass` from the AbilityDB schema, leaving the scanner's matching logic broken.

The work has two distinct components. First, the **detection side**: `OnNameplateAdded` now calls `DeriveCategory(unitToken)` using `UnitIsBossMob`, `UnitIsLieutenant` (pcall-wrapped), `UnitClassification`, and `UnitClassBase` to produce a runtime category string, storing it as `plateCache[unit].category`. A new `Core.lua` event registration routes `UNIT_CLASSIFICATION_CHANGED` to `Scanner:OnClassificationChanged(unit)` to keep the cache current. No classification API is ever called inside `Tick()`. Second, the **matching side**: every internal scanner table keyed by `classBase` is renamed and rekeyed to `category`, `MergeSkillConfig` in Pipeline copies `mobCategory` from `ns.AbilityDB[npcID]` onto each ability object, and `OnMobsAdded` gains a two-branch predicate (`ability.mobCategory == "unknown" OR ability.mobCategory == detectedCategory`) that implements the wildcard rule.

**Primary recommendation:** Treat this as two sequential tasks — (1) detection caching (OnNameplateAdded, OnClassificationChanged, DeriveCategory), then (2) scanner matching rework (table renames + Pipeline change + filter predicate). Both must land together before the addon is functional.

---

## Standard Stack

### Core
| API / Event | Source | Purpose | Why Standard |
|-------------|--------|---------|--------------|
| `UnitClassification(unitToken)` | WoW native | Structural tier detection (elite/normal/trivial/boss) | `AllowedWhenUntainted`; called by Blizzard's own `Blizzard_NamePlateUnitFrame.lua` on nameplate tokens; no Secret Value restrictions |
| `UnitIsBossMob(unitToken)` | WoW native | Boss tier detection | Used by `TargetFrame.lua` line 427; same taint profile as `UnitClassification` |
| `UnitIsLieutenant(unitToken)` | WoW native | Miniboss tier detection | Documented in 12.0.0 API docs with `AllowedWhenUntainted`; not in any Blizzard Lua file — must pcall-wrap |
| `UnitClassBase(unitToken)` | WoW native | Role sub-typing (PALADIN/ROGUE/WARRIOR → caster/rogue/warrior) | Already in production use in v0.1.0 nameplate scanner; stable |
| `UNIT_CLASSIFICATION_CHANGED` | WoW event | Classification cache invalidation | Confirmed in `Blizzard_NamePlateClassificationFrame.lua` line 26 |

### No New Libraries
This phase requires no new libraries or packages. The existing Lua 5.1 + native WoW API stack handles everything. No `npm install` equivalent applies.

---

## Architecture Patterns

### File Modification Map
| File | Change Type | What Changes |
|------|-------------|-------------|
| `Engine/NameplateScanner.lua` | Major rework | DeriveCategory added; plateCache gains `category`; all `classBase`-keyed tables renamed; Tick, OnMobsAdded, OnCastStart, OnCastEnd, Start, Stop updated |
| `Import/Pipeline.lua` | One-line change | `MergeSkillConfig` copies `mobCategory` from `ns.AbilityDB[npcID]` instead of `mobClass` |
| `Core.lua` | One event registration | `UNIT_CLASSIFICATION_CHANGED` registered; routed to new scanner handler |

### Pattern 1: DeriveCategory — local function in NameplateScanner.lua

```lua
-- Source: locked DeriveCategory priority chain (20-CONTEXT.md)
local function DeriveCategory(unitToken)
    -- Step 1: boss check
    if UnitIsBossMob(unitToken) then
        return "boss"
    end
    -- Step 2: lieutenant check (pcall — API unverified in-game)
    local okLt, isLt = pcall(UnitIsLieutenant, unitToken)
    if okLt and isLt then
        return "miniboss"
    end
    -- Step 3: non-elite classification → trivial
    local classification = UnitClassification(unitToken)
    if classification ~= "elite" and classification ~= "worldboss" then
        return "trivial"
    end
    -- Steps 4-6: elite mobs — use WoW class for role sub-typing
    local _, classBase = UnitClass(unitToken)
    if classBase == "PALADIN" then return "caster" end
    if classBase == "ROGUE"   then return "rogue" end
    if classBase == "WARRIOR" then return "warrior" end
    -- Step 7: unexpected class
    dbg("DeriveCategory: unknown class " .. tostring(classBase) .. " unit=" .. unitToken)
    return "unknown"
end
```

**Critical note on step 3:** The classification values that are NOT `"elite"` (and not `"worldboss"`) are: `"normal"`, `"trivial"`, `"minus"`, `"rare"`, `"rareelite"`. The CONTEXT.md specifies classifying these all as semantic `"trivial"`. `"worldboss"` nameplates do not appear in M+ instances, but guarding against it (by treating worldboss as a boss via `UnitIsBossMob` catching it in step 1, or falling through to trivial) is safe behavior.

### Pattern 2: plateCache extension

Current structure (v0.1.0):
```lua
plateCache[unitToken] = {
    hostile   = hostile,
    classBase = classBase,
}
```

New structure (Phase 20):
```lua
plateCache[unitToken] = {
    hostile   = hostile,
    classBase = classBase,     -- still needed for DeriveCategory steps 4-6 and cast detection key
    category  = DeriveCategory(unitToken),
}
```

`classBase` remains in `plateCache` because `DeriveCategory` uses it at cache-build time, and it may still be needed for cast detection. The category field is the new primary routing key.

### Pattern 3: Table renames in NameplateScanner.lua

| Old name | New name | Keyed by |
|----------|----------|----------|
| `classBarIds[classBase]` | `categoryBarIds[category]` | runtime category string |
| `classHasUntimed[classBase]` | `categoryHasUntimed[category]` | runtime category string |
| `castingByClass[classBase]` | `castingByCategory[category]` | runtime category string |
| `prevCounts[classBase]` | `prevCounts[category]` | runtime category string |

The `spellIndex` table (spellID → ability) is unchanged; it does not need rekeying.

### Pattern 4: OnMobsAdded filter predicate

```lua
-- Source: wildcard matching rule, 20-CONTEXT.md
function Scanner:OnMobsAdded(category, delta)
    categoryBarIds[category] = categoryBarIds[category] or {}

    for _, ability in ipairs(activePack.abilities) do
        -- Wildcard: "unknown" ability fires for ANY mob category
        -- Exact: known ability only fires when runtime category matches
        if ability.mobCategory == "unknown" or ability.mobCategory == category then
            if ability.cooldown then
                for i = 1, delta do
                    timerCounter = timerCounter + 1
                    local barId = "mob_" .. category .. "_" .. timerCounter
                    table.insert(categoryBarIds[category], barId)
                    ns.Scheduler:StartAbility(ability, barId)
                end
            else
                if not staticShown[ability.spellID] then
                    staticShown[ability.spellID] = true
                    ns.IconDisplay.ShowStaticIcon("static_" .. ability.spellID, ability.spellID, ability.label, ability.ttsMessage, ability.soundKitID, ability.soundEnabled)
                end
            end
        end
    end
end
```

### Pattern 5: Tick() reconcile loop update

The Tick() reconcile is structurally identical — only the key source changes:

```lua
-- Old: newCounts[cached.classBase]
-- New: newCounts[cached.category]
if cached and cached.hostile and cached.category then
    local inCombat = UnitAffectingCombat(npUnit)
    if inCombat then
        newCounts[cached.category] = (newCounts[cached.category] or 0) + 1
    end
end
```

### Pattern 6: Pipeline MergeSkillConfig change

```lua
-- Old (before Phase 19/20):
local function MergeSkillConfig(npcID, ability, mobClass)
    ...
    return {
        ...
        mobClass = mobClass,   -- removed
    }
end
-- Called as: MergeSkillConfig(npcID, ability, entry.mobClass)

-- New (Phase 20):
local function MergeSkillConfig(npcID, ability)
    local entry = ns.AbilityDB[npcID]
    local mobCategory = entry and entry.mobCategory or "unknown"
    ...
    return {
        ...
        mobCategory = mobCategory,
    }
end
-- Called as: MergeSkillConfig(npcID, ability)
-- Also update BuildPack call site: MergeSkillConfig(npcID, ability)
-- Also update dedup key: merged.spellID .. "_" .. merged.mobCategory
```

**SavedVariables safety:** `mobCategory` is populated on the in-memory `pack.abilities` table. This table IS saved to `ns.db.importedRoutes[dungeonKey].packs` in `RunFromPreset`. This means `mobCategory` does enter SavedVariables via the `packs` array — however, that data is rebuilt fresh from `ns.AbilityDB` on every `RestoreAllFromSaved()` call (which calls `BuildPack` again). The SavedVariables copy is stale reference data, but the live copy used by the scanner is always freshly built. The critical constraint ("category must not be read from SavedVariables") is respected because `RestoreAllFromSaved` always rebuilds packs from `ns.AbilityDB`, never reads `.packs` directly from the saved route.

### Pattern 7: UNIT_CLASSIFICATION_CHANGED handler

```lua
-- In Core.lua — add to event registrations:
frame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")

-- In Core.lua OnEvent handler — add case:
elseif event == "UNIT_CLASSIFICATION_CHANGED" then
    local unitToken = ...
    ns.NameplateScanner:OnClassificationChanged(unitToken)

-- In NameplateScanner.lua — new handler:
function Scanner:OnClassificationChanged(unitToken)
    local cached = plateCache[unitToken]
    if cached then
        cached.category = DeriveCategory(unitToken)
        dbg("OnClassificationChanged: " .. unitToken .. " -> " .. cached.category)
    end
end
```

### Pattern 8: Start() and Stop() cleanup

All four renamed tables must be added to the `wipe()` calls in `Start()` and `Stop()`:

```lua
-- Start(): replace classBarIds/classHasUntimed/castingByClass with:
wipe(categoryBarIds)
wipe(categoryHasUntimed)
wipe(castingByCategory)

-- Stop(): same wipes
-- Also update the categoryHasUntimed build loop:
for _, ability in ipairs(pack.abilities) do
    if not ability.cooldown then
        spellIndex[ability.spellID] = ability
        categoryHasUntimed[ability.mobCategory] = true
    end
end
```

### Anti-Patterns to Avoid

- **Calling DeriveCategory inside Tick():** DeriveCategory calls `UnitIsBossMob`, `UnitIsLieutenant`, `UnitClassification`, `UnitClass` — four API calls per mob per tick. These are event-time operations only. `Tick()` reads `cached.category`, never derives it.
- **Keying tables with `mobCategory` values from AbilityDB directly:** `categoryBarIds["caster"]` is correct only when `"caster"` is the runtime-derived category from `DeriveCategory`. A mob in the `"caster"` category must be detected at runtime as a caster — the data file's `mobCategory` is the *target*, the runtime category is the *key*. They match when detection works correctly; mismatches are a bug to debug, not suppress.
- **Using nil instead of `"unknown"` for fallback categories:** `ability.mobCategory` must be `"unknown"` (explicit string) when the ability should be a wildcard. `nil` would pass the `== "unknown"` check silently if the predicate were `not ability.mobCategory`, but would fail the correct explicit check. Always guard with the explicit string.
- **Dedup key still using `mobClass`:** The `seenAbility` key in `BuildPack` is currently `merged.spellID .. "_" .. merged.mobClass`. After Phase 20, this must become `merged.spellID .. "_" .. merged.mobCategory`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| pcall wrapping for `UnitIsLieutenant` | Custom error-handling wrapper | Lua built-in `pcall(UnitIsLieutenant, unitToken)` | Standard Lua 5.1 pattern; already used in v0.1.0 for `UnitCastingInfo`/`UnitChannelInfo` |
| Classification change detection | Per-tick polling | `UNIT_CLASSIFICATION_CHANGED` event | Blizzard provides exact event for this; polling adds ~40 extra API calls/tick for no benefit |
| "Is this mob known to the pack?" | Separate lookup table | Read `ability.mobCategory` directly from merged ability table | Already propagated by Pipeline; no second lookup needed |

---

## Common Pitfalls

### Pitfall 1: Nil category at filter call site
**What goes wrong:** `plateCache[unit].category` is nil (e.g., if `DeriveCategory` was not called or returned nil). The nil propagates into `newCounts[nil]` in Tick(), corrupting the counts table silently.
**Why it happens:** `DeriveCategory` always returns a string (step 7 is `return "unknown"`), but if there's an early-return bug or the function is not called, the field may be absent.
**How to avoid:** The final line of `DeriveCategory` is `return "unknown"` — there is no code path that returns nil. In `OnNameplateAdded`, set `category = DeriveCategory(unitToken)` unconditionally.
**Warning signs:** Debug log never shows category-specific messages; `newCounts` always empty; timers never spawn.

### Pitfall 2: Lieutenant before class (priority chain violation)
**What goes wrong:** A PALADIN lieutenant is categorized as `"caster"` instead of `"miniboss"` because the class check (step 4) runs before the lieutenant check (step 2).
**Why it happens:** Most WoW lieutenants use the PALADIN class token. If steps are reordered, the class check fires first.
**How to avoid:** Follow the locked priority chain exactly: boss → lieutenant → classification tier → class sub-type.
**Warning signs:** In a Skyreach run, `Herald of Sunrise` or `Solar Construct` shows caster icons instead of miniboss icons.

### Pitfall 3: mobCategory vs mobClass confusion in table keys
**What goes wrong:** `categoryBarIds["WARRIOR"]` is set (using WoW class token) instead of `categoryBarIds["warrior"]` (lowercase semantic role). No timer ever spawns because `DeriveCategory` returns `"warrior"` (lowercase), which never matches `"WARRIOR"` (uppercase WoW token).
**Why it happens:** The naming overlap (`mobClass = "WARRIOR"`, `mobCategory = "warrior"`) is easy to confuse. In `OnMobsAdded`, the argument is the runtime category, which is always lowercase.
**How to avoid:** All semantic category strings are lowercase. WoW class tokens are uppercase. Keep them distinct.
**Warning signs:** Icons never appear for `"warrior"` mobs; debug shows `category=warrior` but `categoryBarIds` is always empty.

### Pitfall 4: dedup key collision after rename
**What goes wrong:** Two abilities with the same `spellID` from different npcIDs deduplicate when they should not (because the category suffix changed).
**Why it happens:** `seenAbility` key changes from `spellID .. "_" .. mobClass` to `spellID .. "_" .. mobCategory`. If the rename is missed, all abilities with the same spellID and same category (even from different mobs) deduplicate to one entry.
**How to avoid:** Update the dedup key in `BuildPack` alongside the `MergeSkillConfig` return value.
**Warning signs:** Fewer abilities than expected in a multi-mob pack; some mobs produce no icons.

### Pitfall 5: UnitIsLieutenant causing addon errors
**What goes wrong:** `UnitIsLieutenant` throws an error in some zone or with some argument, breaking `OnNameplateAdded` and preventing the cache from populating.
**Why it happens:** The API is undocumented in Blizzard Lua files; its behavior on invalid unit tokens or in specific zone contexts is unknown.
**How to avoid:** Always call as `local ok, isLt = pcall(UnitIsLieutenant, unitToken)`. Only treat `isLt` as true if `ok` is also true. The fallback is safe — a failed `UnitIsLieutenant` simply falls through to the classification tier check.
**Warning signs:** Lua error stack trace mentioning `UnitIsLieutenant`; OnNameplateAdded errors in `!BugSack` or similar.

### Pitfall 6: UNIT_CLASSIFICATION_CHANGED fires for player units
**What goes wrong:** `OnClassificationChanged` attempts `DeriveCategory` on a non-nameplate unit (e.g., the player), calling `UnitIsBossMob("player")`. This is safe (returns false) but wastes cycles and may produce spurious debug logs.
**Why it happens:** `UNIT_CLASSIFICATION_CHANGED` can fire for any unit that has a classification, not just nameplates.
**How to avoid:** Guard in `OnClassificationChanged`: only update if `plateCache[unitToken]` already exists (i.e., the unit is a known nameplate). This check is already implied by `if cached then` in Pattern 7.
**Warning signs:** Debug logs showing classification changed for `"player"` or `"party1"`.

---

## Code Examples

### Complete OnNameplateAdded (updated)
```lua
-- Source: patterns derived from 20-CONTEXT.md decisions
function Scanner:OnNameplateAdded(unitToken)
    local hostile  = UnitCanAttack("player", unitToken)
    local _, classBase = UnitClass(unitToken)
    plateCache[unitToken] = {
        hostile   = hostile,
        classBase = classBase,
        category  = DeriveCategory(unitToken),
    }
    dbg("OnNameplateAdded: " .. unitToken .. " class=" .. tostring(classBase) .. " cat=" .. plateCache[unitToken].category)
end
```

### Cast detection check in Tick() — category key
```lua
-- classHasUntimed → categoryHasUntimed; cached.classBase → cached.category for the outer check
if categoryHasUntimed[cached.category] then
    -- ... pcall UnitCastingInfo / UnitChannelInfo unchanged ...
    if isCasting then
        newCasting[cached.category] = true
    end
end
```

### Pipeline MergeSkillConfig signature simplification
```lua
-- Remove mobClass parameter; read mobCategory from AbilityDB inside function
local function MergeSkillConfig(npcID, ability)
    local entry = ns.AbilityDB[npcID]
    local mobCategory = (entry and entry.mobCategory) or "unknown"
    ...
    return {
        spellID      = ability.spellID,
        mobCategory  = mobCategory,     -- replaces mobClass
        ...
    }
end

-- BuildPack call site — remove third arg:
local merged = MergeSkillConfig(npcID, ability)

-- BuildPack dedup key — update to use mobCategory:
local key = merged.spellID .. "_" .. merged.mobCategory
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `classBarIds[classBase]` (WoW class token key) | `categoryBarIds[category]` (semantic role key) | Phase 20 | Matching is now role-based, not class-based; enables non-elite mobs, bosses, and minibosses to be correctly gated |
| `ability.mobClass` propagated from AbilityDB | `ability.mobCategory` propagated from AbilityDB | Phase 19/20 | `mobClass` removed from data schema entirely; replaced by semantic role vocabulary |
| No runtime detection | `DeriveCategory()` at `NAME_PLATE_UNIT_ADDED` | Phase 20 | Structural tier (boss/miniboss/trivial) now detected from WoW APIs, not assumed from data-file assertions |

**Removed/dead after Phase 20:**
- `classBarIds` — replaced by `categoryBarIds`
- `classHasUntimed` — replaced by `categoryHasUntimed`
- `castingByClass` — replaced by `castingByCategory`
- `ability.mobClass` field — removed in Phase 19; Phase 20 ensures no surviving references
- `MergeSkillConfig(npcID, ability, mobClass)` third parameter — removed
- `entry.mobClass` read in Pipeline — removed

---

## Open Questions

1. **UnitIsLieutenant runtime behavior**
   - What we know: Documented in 12.0.0 API docs with `AllowedWhenUntainted`; not present in any Blizzard Lua file; behavior on non-nameplate units or invalid tokens unknown
   - What's unclear: Whether it returns a meaningful non-nil value for any mob in M+ content; whether it can throw in edge cases
   - Recommendation: pcall-wrap as specified. If no mob ever gets `"miniboss"` from `UnitIsLieutenant` during in-game testing, add a debug log noting this and document as unvalidated. The feature still works correctly (those mobs fall to classification/class checks).

2. **classBase still needed post-rename?**
   - What we know: `DeriveCategory` uses `UnitClass` at cache-build time (step 4-6 of priority chain). After the category is cached, the scanner uses `category` for all hot-path keying.
   - What's unclear: Whether `classBase` in `plateCache` is needed for anything after Phase 20, or whether it becomes dead weight.
   - Recommendation: Retain `classBase` in `plateCache` — it is used by `DeriveCategory` and may be useful for debugging. Remove only in a cleanup phase.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — WoW addon (Lua); no automated test runner |
| Config file | N/A |
| Quick run command | `./scripts/install.bat` then in-game `/tpw debug`, pull mobs |
| Full suite command | In-game: Skyreach pull with imported route + non-Skyreach run |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DETC-01 | `UnitClassification` cached at `NAME_PLATE_UNIT_ADDED` | manual | `/tpw debug` — watch for "OnNameplateAdded: ... cat=" log lines | ❌ Wave 0 |
| DETC-02 | `UNIT_CLASSIFICATION_CHANGED` updates cache | manual | Observe debug log when mob classification changes mid-combat | ❌ Wave 0 |
| DETC-03 | `UnitIsLieutenant` wrapped in pcall | manual | Verify no Lua errors on nameplate add; `/tpw debug` shows miniboss detection | ❌ Wave 0 |
| DETC-04 | `DeriveCategory()` produces correct categories | manual | Pull known Skyreach mobs; compare debug category log vs. expected from Phase 19 table | ❌ Wave 0 |
| DETC-05 | Category cached per unit in `plateCache` | manual | Debug log shows category per unit token, not per classBase | ❌ Wave 0 |
| SCAN-01 | Scanner reads `ability.mobCategory` from merged ability (built from AbilityDB at pack-build time) | manual | Import route; verify pack.abilities have mobCategory field (print in debug) | ❌ Wave 0 |
| SCAN-02 | Unknown mobCategory = wildcard, fires for all mobs | manual | Import non-Skyreach route; confirm all abilities display normally | ❌ Wave 0 |
| SCAN-03 | Known category only triggers when runtime matches | manual | Import Skyreach route; confirm non-matching-category mobs produce no icons | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `./scripts/install.bat` and load in WoW; check for Lua errors via `/tpw status`
- **Per wave merge:** Full in-game scenario: pull Skyreach pack + pull non-Skyreach pack; confirm both success criteria
- **Phase gate:** Both success scenarios verified before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] No automated tests exist for this addon — all validation is manual in-game
- [ ] Manual test checklist file (could be created as notes during implementation): `DETC-01` through `SCAN-03` per table above

*(WoW addons have no standard automated test infrastructure; all validation is manual in-game.)*

---

## Sources

### Primary (HIGH confidence)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` — `UnitClassification` (line 947), `UnitIsLieutenant` (line 1995), `UnitIsBossMob`, taint annotations confirmed
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateUnitFrame.lua` line 359 — `UnitClassification` called on nameplate unit token in Blizzard's own nameplate code
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateClassificationFrame.lua` line 26 — `UNIT_CLASSIFICATION_CHANGED` event registration confirmed
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_UnitFrame/Mainline/TargetFrame.lua` lines 427 — `UnitIsBossMob` usage confirmed
- `C:/Users/jonat/Repositories/TerriblePackWarnings/Engine/NameplateScanner.lua` — current v0.1.0 implementation; all integration points and reusable patterns confirmed by direct read
- `C:/Users/jonat/Repositories/TerriblePackWarnings/Import/Pipeline.lua` — `MergeSkillConfig` current signature, `BuildPack` dedup key, SavedVariables write path confirmed
- `C:/Users/jonat/Repositories/TerriblePackWarnings/Data/Skyreach.lua` — Phase 19 output; `mobCategory` field format confirmed
- `.planning/phases/20-runtime-detection-and-scanner-matching/20-CONTEXT.md` — locked decisions, priority chain, wildcard rules
- `.planning/research/SUMMARY.md` — prior API research with Blizzard source line references

### Secondary (MEDIUM confidence)
- `.planning/phases/19-data-layer/19-CONTEXT.md` — `mobClass` removal decisions, category vocabulary
- Warcraft Wiki: `UnitIsLieutenant` documented as newly added in 12.0.0

### Tertiary (LOW confidence — needs in-game validation)
- `UnitIsLieutenant` runtime behavior in Midnight M+ dungeons — test during Phase 20 execution

---

## Metadata

**Confidence breakdown:**
- Standard stack (APIs): HIGH — all APIs verified in wow-ui-source; `UnitIsLieutenant` MEDIUM due to no Blizzard Lua usage found
- Architecture (patterns): HIGH — derived directly from current source code read + locked CONTEXT.md decisions
- Pitfalls: HIGH — all documented against direct source analysis and locked constraints

**Research date:** 2026-03-23
**Valid until:** 2026-04-22 (stable WoW API; unlikely to change within 30 days)
