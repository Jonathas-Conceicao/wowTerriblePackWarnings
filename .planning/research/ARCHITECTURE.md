# Architecture Research

**Domain:** WoW Midnight (12.0) addon — v0.1.1 per-mob category system integration
**Researched:** 2026-03-23
**Confidence:** HIGH — derived from direct source analysis of all relevant Lua files in the current v0.1.0 codebase.

---

## Current Architecture (v0.1.0 baseline)

### Relevant Data Structures

**AbilityDB entry (current):**
```lua
ns.AbilityDB[npcID] = {
    mobClass  = "WARRIOR",  -- WoW class string, used by NameplateScanner for UnitClassBase matching
    abilities = {
        { spellID = 123456, defaultEnabled = false },
    },
}
```

**plateCache entry (NameplateScanner, current):**
```lua
plateCache[unitToken] = {
    hostile   = bool,      -- from UnitCanAttack, cached at NAME_PLATE_UNIT_ADDED
    classBase = string,    -- from UnitClass(unitToken)[2], cached at NAME_PLATE_UNIT_ADDED
}
```

**Merged ability in pack (current):**
```lua
{
    spellID      = number,
    mobClass     = string,    -- copied from AbilityDB entry
    first_cast   = number|nil,
    cooldown     = number|nil,
    label        = string|nil,
    ttsMessage   = string,
    soundKitID   = number|nil,
    soundEnabled = bool,
}
```

### NameplateScanner Detection Loop (current)

The scanner matches mobs by `UnitClassBase` only:

```
NAME_PLATE_UNIT_ADDED → cache { hostile, classBase } → never touched again in the hot loop
Tick() → UnitAffectingCombat(npUnit) → count hostile in-combat mobs by classBase
       → compare count vs tracked timers → OnMobsAdded(classBase, delta)
OnMobsAdded: iterates activePack.abilities, matches ability.mobClass == classBase
```

---

## Target Architecture (v0.1.1)

### 1. Category Field in AbilityDB

Add `mobCategory` as an optional field alongside `mobClass` on each AbilityDB npcID entry.

```lua
ns.AbilityDB[npcID] = {
    mobClass    = "MAGE",            -- WoW class string (unchanged, still required for detection)
    mobCategory = "caster",          -- new: one of boss|miniboss|caster|warrior|rogue|trivial|unknown
    abilities   = { ... },
}
```

**Field rules:**
- `mobCategory` is present only in data files where it has been explicitly set (currently: Skyreach only).
- Absent means `"unknown"`. Pipeline.lua reads `entry.mobCategory or "unknown"` — never nil at runtime.
- `mobCategory` is hardcoded in data files, never written to SavedVariables. It is not user-editable.
- The categories `"caster"`, `"warrior"`, `"rogue"` describe combat role, not WoW class. A `"caster"` mob may have `mobClass = "MAGE"` or `"WARLOCK"` etc. The two fields are orthogonal.

**No new file needed.** This is a field addition to existing Data/*.lua entries. For this milestone, only `Data/Skyreach.lua` receives fully populated `mobCategory` values. All other Data/*.lua files remain at `mobCategory` absent (implicit `"unknown"`).

---

### 2. plateCache Extended for Category Detection

Category detection uses WoW APIs that are not available from the nameplate unit token at `NAME_PLATE_UNIT_ADDED` alone, or requires polling. The relevant APIs are:

| API | When Available | Return |
|-----|---------------|--------|
| `UnitClassification(unit)` | Stable at `NAME_PLATE_UNIT_ADDED` | `"worldboss"`, `"elite"`, `"rareelite"`, `"rare"`, `"normal"`, `"trivial"`, `"minus"` |
| `UnitEffectiveLevel(unit)` | Stable at `NAME_PLATE_UNIT_ADDED` | number (player-relative level) |
| `UnitIsLieutenant(unit)` | Stable at `NAME_PLATE_UNIT_ADDED` | bool (Midnight-specific lieutenant designation) |
| `UnitClassBase(unit)` | Stable at `NAME_PLATE_UNIT_ADDED` | string (WoW class string, already cached as `classBase`) |

All four APIs are stable and non-secret in Midnight. They can all be called at `NAME_PLATE_UNIT_ADDED` and cached. No hot-loop polling needed.

**plateCache extended:**
```lua
plateCache[unitToken] = {
    hostile        = bool,
    classBase      = string,
    classification = string,    -- UnitClassification return (new)
    isLieutenant   = bool,      -- UnitIsLieutenant return (new)
    effectiveLevel = number,    -- UnitEffectiveLevel return (new)
}
```

**Detection function (derives runtime category from plateCache entry):**

```lua
-- Engine/NameplateScanner.lua (new local helper)
local function DeriveCategory(cached)
    local c = cached.classification
    if c == "worldboss" then return "boss" end
    if cached.isLieutenant then return "miniboss" end
    if c == "trivial" or c == "minus" then return "trivial" end
    -- Role-based: defer to AbilityDB category (already merged into ability.mobCategory)
    -- Unknown by default — wildcard passes all filters
    return "unknown"
end
```

Note: `"caster"`, `"warrior"`, `"rogue"` cannot be reliably derived from WoW APIs alone (classification and level do not encode combat role). These categories must come from the hardcoded `mobCategory` field in AbilityDB. Runtime detection via APIs covers `"boss"`, `"miniboss"`, and `"trivial"` only. This is sufficient for alert filtering since role-based categories are only meaningful when the data author has explicitly set them.

---

### 3. Category Propagation Through Pipeline.lua

Pipeline.lua's `MergeSkillConfig` currently builds merged ability tables without `mobCategory`. It must propagate the field.

**Change to `MergeSkillConfig`:**

```lua
local function MergeSkillConfig(npcID, ability, mobClass)
    -- ... existing merge logic ...
    return {
        spellID      = ability.spellID,
        mobClass     = mobClass,
        mobCategory  = entry.mobCategory or "unknown",   -- new field
        -- ... rest of fields unchanged ...
    }
end
```

`entry` here is `ns.AbilityDB[npcID]`. The category is a property of the NPC entry, not the individual ability, so it is read from `entry` not `ability`. All abilities from the same npcID share the same `mobCategory`.

**"unknown" wildcard contract:**

Any ability with `mobCategory == "unknown"` passes all category filters. This is the safe default — false positives (displaying an alert when no mob of that category is present) are preferable to false negatives (silently dropping an alert for a dangerous mob). This contract is enforced at the filter call site, not in Pipeline.

---

### 4. NameplateScanner Filtering

The current scanner matches only by `classBase`. The category filter adds a second dimension.

**No changes to the hot-loop Tick() scan.** The scan counts mobs by `classBase` as before. Category filtering happens in `OnMobsAdded` and `OnCastStart/End`, where abilities are iterated.

**Change to `OnMobsAdded`:**

```lua
function Scanner:OnMobsAdded(classBase, delta)
    classBarIds[classBase] = classBarIds[classBase] or {}

    for _, ability in ipairs(activePack.abilities) do
        if ability.mobClass == classBase then
            -- Category filter: unknown passes always
            local runtimeCategory = activeCategoryByClass[classBase]  -- see below
            if ability.mobCategory == "unknown"
               or runtimeCategory == nil
               or ability.mobCategory == runtimeCategory
            then
                -- spawn timer or static icon (unchanged logic)
            end
        end
    end
end
```

`activeCategoryByClass` is a module-level table keyed by classBase, populated when a mob is first counted in `Tick()`:

```lua
-- module-level in NameplateScanner.lua
local activeCategoryByClass = {}
```

Populated in `Tick()` when a mob enters combat:

```lua
-- Inside Tick(), after newCounts tallying, when a mob is first seen:
if not activeCategoryByClass[cached.classBase] then
    activeCategoryByClass[cached.classBase] = DeriveCategory(cached)
end
```

Wiped in `Scanner:Stop()`.

**Why this approach over per-tick filtering:**

`DeriveCategory` is called once per classBase per combat session, not every tick. The result is cached in `activeCategoryByClass`. This means zero extra API overhead in the hot loop after first detection.

**classHasUntimed** (existing O(1) gate for cast detection) already filters by classBase. No change needed there.

---

### 5. ConfigFrame Display

ConfigFrame currently shows the mob header as:

```lua
headerNameStr:SetText(mobName .. " - " .. mobClass)
```

Change to include category:

```lua
local entry = ns.AbilityDB[npcID]
local mobClass = entry and entry.mobClass or "UNKNOWN"
local mobCategory = entry and entry.mobCategory or "unknown"
headerNameStr:SetText(mobName .. " - " .. mobClass .. " [" .. mobCategory .. "]")
```

This is a one-line change in `PopulateRightPanel`. No new widgets required. The category label is non-interactive — no button, no dropdown. It is informational only.

**Search does not filter by category.** The existing search filters by mob name and spell name. Adding category to search scope is out of scope for this milestone.

---

### 6. Data File Changes (Skyreach only)

`Data/Skyreach.lua` receives `mobCategory` values for every npcID entry. All other Data/*.lua files remain unchanged (absent `mobCategory` = implicit `"unknown"`).

Example after change:

```lua
-- Data/Skyreach.lua
ns.AbilityDB[76132] = {
    mobClass    = "WARRIOR",
    mobCategory = "warrior",   -- Soaring Chakram Master: melee-focused mob
    abilities = {
        { spellID = 1254666, defaultEnabled = false },
    },
}

ns.AbilityDB[79462] = {
    mobClass    = "WARRIOR",
    mobCategory = "caster",    -- Blinding Sun Priestess: cast-heavy healer
    abilities = {
        { spellID = 152953,  defaultEnabled = false },
        { spellID = 1273356, defaultEnabled = false },
    },
}
```

The set of valid category values is: `boss`, `miniboss`, `caster`, `warrior`, `rogue`, `trivial`, `unknown`. No enum or validation table is required in Lua — data authors are responsible for correct values. A comment at the top of each categorized data file listing valid values is sufficient documentation.

---

## System Overview (v0.1.1 delta)

```
NAME_PLATE_UNIT_ADDED
    → Scanner:OnNameplateAdded(unitToken)
    → UnitCanAttack, UnitClass, UnitClassification,    ← new: 3 extra API calls
      UnitIsLieutenant, UnitEffectiveLevel
    → plateCache[unitToken] = { hostile, classBase,
                                classification,        ← new fields
                                isLieutenant,
                                effectiveLevel }

Tick() every 0.25s — unchanged hot path
    → count hostile in-combat mobs by classBase        ← unchanged
    → when new classBase first seen:
        DeriveCategory(cached) → activeCategoryByClass ← new (once per session)
    → OnMobsAdded(classBase, delta)
        → per-ability: mobClass match + category filter ← new filter
        → spawn timer or static icon (unchanged)

Pipeline.BuildPack()
    → MergeSkillConfig(npcID, ability, mobClass)
    → merged.mobCategory = entry.mobCategory or "unknown"  ← new field

ConfigFrame.PopulateRightPanel(npcID)
    → header shows: "MobName - CLASS [category]"           ← new label
```

---

## Data Flows

### Category Read Path

```
Data/Skyreach.lua (load time)
    → ns.AbilityDB[npcID].mobCategory = "caster"

Import.BuildPack() → MergeSkillConfig()
    → merged.mobCategory = "caster"
    → packed into activePack.abilities[n].mobCategory

NameplateScanner:OnMobsAdded(classBase, delta)
    → ability.mobCategory == "caster"
    → activeCategoryByClass["WARRIOR"] == "caster"   (derived from UnitClassification)
    → filter passes → spawn icon
```

### Unknown Wildcard Path

```
Data/WindrunnerSpire.lua (load time)
    → ns.AbilityDB[232070].mobCategory = nil (absent)

Pipeline → merged.mobCategory = "unknown"

NameplateScanner:OnMobsAdded
    → ability.mobCategory == "unknown"
    → wildcard: skip filter entirely → spawn icon regardless of runtime category
```

### Category Display Path

```
User opens ConfigFrame, selects a mob
    → PopulateRightPanel(npcID)
    → ns.AbilityDB[npcID].mobCategory = "caster" (or nil → "unknown")
    → headerNameStr:SetText("Blinding Sun Priestess - WARRIOR [caster]")
```

---

## Component Build Order

Build in this order to respect dependencies:

**Step 1: Data/Skyreach.lua — Add mobCategory fields**
- Pure data change. No code dependencies.
- Adds `mobCategory` to all Skyreach npcID entries.
- Unblocks visual verification in ConfigFrame header once Step 5 is done.
- Can be done independently of all other steps.

**Step 2: Engine/NameplateScanner.lua — Extend plateCache**
- Add `classification`, `isLieutenant`, `effectiveLevel` fields in `OnNameplateAdded`.
- Add `activeCategoryByClass` table, populated in `Tick()` on first mob sighting.
- Add `DeriveCategory(cached)` local helper.
- Wipe `activeCategoryByClass` in `Stop()`.
- No upstream dependencies. Does not break existing behavior (new fields ignored until Step 3).

**Step 3: Engine/NameplateScanner.lua — Category filter in OnMobsAdded**
- Add category check in `OnMobsAdded` using `activeCategoryByClass`.
- Requires Step 2 (activeCategoryByClass must exist).
- Requires Step 4 (abilities must carry `mobCategory` field, or falls back to "unknown" wildcard).
- Safe to ship with "unknown" only until Step 4 is complete — all wildcards pass.

**Step 4: Import/Pipeline.lua — Propagate mobCategory in MergeSkillConfig**
- Add `mobCategory = entry.mobCategory or "unknown"` to merged ability table.
- No upstream code dependencies (reads from AbilityDB which is always loaded before Pipeline).
- Must be complete before Step 3 filtering is meaningful for non-unknown categories.

**Step 5: UI/ConfigFrame.lua — Show category in mob header**
- Change one line in `PopulateRightPanel`.
- No dependencies beyond Step 1 (needs data to show something other than "unknown").
- Can ship as pure "unknown" labels even before Step 1 without breaking anything.

**Correct sequential order: 2 → 4 → 1 → 3 → 5**

Rationale:
- Step 2 before 3: scanner state must exist before filter can use it.
- Step 4 before 3: merged abilities must carry the field before filter can read it.
- Step 1 before 3 activation: without real category data, all filters pass via wildcard — this is safe, but the feature is a no-op until Skyreach data has values.
- Step 5 last: purely cosmetic, no functional dependency.

---

## Internal Module Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Data/Skyreach.lua → Pipeline | `ns.AbilityDB[npcID].mobCategory` read in `MergeSkillConfig` | Read-only; Pipeline is sole consumer at build time |
| Pipeline → NameplateScanner | `ability.mobCategory` in merged pack abilities | Scanner reads field; never writes it |
| NameplateScanner → plateCache | `classification`, `isLieutenant`, `effectiveLevel` cached at event | Hot loop reads cache; no API calls per tick for these fields |
| NameplateScanner → activeCategoryByClass | Derived once per classBase per session from `DeriveCategory(cached)` | Internal scanner state; wiped at `Stop()` |
| AbilityDB → ConfigFrame | `ns.AbilityDB[npcID].mobCategory` read directly in `PopulateRightPanel` | Display only; no write path |

---

## Anti-Patterns

### Anti-Pattern 1: Deriving combat role (caster/warrior/rogue) from WoW APIs alone

**What people do:** Attempt to infer `"caster"` vs `"warrior"` from `UnitClassification` or `UnitEffectiveLevel` without hardcoded data.

**Why it's wrong:** WoW's classification API only exposes rarity/power tier (elite, rare, boss). It has no concept of combat role. `UnitClassBase` returns the WoW class string (e.g., `"MAGE"`), which correlates with role but is unreliable for NPCs — many trash mobs use `"WARRIOR"` regardless of actual combat role. There is no API that returns "this mob is a caster" reliably.

**Do this instead:** Hardcode `mobCategory` in AbilityDB for dungeons where accurate filtering matters. Leave others as `"unknown"` (wildcard) until someone verifies in-game.

### Anti-Pattern 2: Polling category APIs in the hot Tick() loop

**What people do:** Call `UnitClassification(npUnit)` every tick for each nameplate.

**Why it's wrong:** Classification is stable for a given NPC — it never changes mid-combat. Calling it every 0.25s is pure waste. At 20 nameplates this adds 20 API calls per tick for no benefit.

**Do this instead:** Cache `classification`, `isLieutenant`, `effectiveLevel` in `plateCache` at `NAME_PLATE_UNIT_ADDED` — exactly where `hostile` and `classBase` are already cached. Derive category once when the classBase is first seen in combat; store in `activeCategoryByClass`.

### Anti-Pattern 3: Making mobCategory user-editable

**What people do:** Add a dropdown in ConfigFrame for users to override the mob category.

**Why it's wrong:** Category is a factual property of the NPC used for alert filtering. User overrides create a support surface ("why aren't my alerts firing?") and SavedVariables writes with no clear benefit. Users cannot verify category by inspection — it requires in-game testing with each mob type.

**Do this instead:** Display category as read-only text in the mob header. Category changes go through a new addon version, not user config.

### Anti-Pattern 4: Storing mobCategory in per-ability entries rather than per-npcID entries

**What people do:** Add `mobCategory` to each ability in the `abilities` array:

```lua
ns.AbilityDB[79462] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 152953, mobCategory = "caster", defaultEnabled = false },
    },
}
```

**Why it's wrong:** Category is a property of the mob (npcID), not the ability (spellID). All abilities from the same mob share the same category. Duplicating it per-ability is redundant and creates inconsistency risk if one ability is accidentally given a different category.

**Do this instead:** `mobCategory` lives on the npcID entry. Pipeline reads `entry.mobCategory` once per npcID and copies it to all merged abilities.

---

## Sources

- Direct source analysis: `Engine/NameplateScanner.lua`, `Import/Pipeline.lua`, `UI/ConfigFrame.lua`, `Data/Skyreach.lua`, `Data/WindrunnerSpire.lua` — read 2026-03-23
- `.planning/PROJECT.md` — v0.1.1 milestone requirements, read 2026-03-23
- WoW API: `UnitClassification`, `UnitIsLieutenant`, `UnitEffectiveLevel` return values — stable non-secret Midnight APIs, confirmed available for nameplate units at `NAME_PLATE_UNIT_ADDED`

---
*Architecture research for: TerriblePackWarnings v0.1.1 — per-mob category system integration*
*Researched: 2026-03-23*
