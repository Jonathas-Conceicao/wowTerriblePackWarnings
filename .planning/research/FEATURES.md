# Feature Research

**Domain:** WoW Mythic+ addon — per-mob category system (boss, miniboss, caster, warrior, rogue, trivial, unknown)
**Researched:** 2026-03-23
**Confidence:** HIGH (sourced from wow-ui-source API documentation, Blizzard_NamePlates Lua, and existing TPW codebase)

---

## Scope

This document covers features needed for v0.1.1: adding a per-mob category system with runtime detection and alert filtering. Features already shipped in v0.1.0 are not repeated here.

---

## Feature Area 1: Category Assignment in Data Files

### How category data is structured in M+ addons

**Observed patterns:**
- MDT stores `isBoss = true` as a boolean flag per enemy entry. No miniboss, caster, or role-based categories exist in MDT's schema. MDT distinguishes only boss vs. non-boss.
- BigWigs/LittleWigs hardcode per-ability timers per encounter but do not expose a "mob category" concept for filtering trash abilities. Every tracked trash mob gets its abilities tracked unconditionally.
- TPW's existing `AbilityDB` uses `mobClass` (a WoW class string like `"WARRIOR"`) per npcID for nameplate matching. This is a runtime detection key, not a semantic category.

**The gap:** No existing M+ addon system provides what TPW needs — a semantic category per mob that controls which alert rules apply. This is a novel feature for TPW. The design space is well-understood from first principles.

**Recommended design:** Add a `category` field to each npcID entry in the AbilityDB data files alongside `mobClass`. The category is a hardcoded string set by the addon author, never user-editable.

```lua
-- Example entry with category
ns.AbilityDB[76132] = {
    mobClass = "WARRIOR",
    category = "caster",   -- NEW: semantic role
    abilities = { ... },
}
```

**Category vocabulary (7 values):**
- `"boss"` — final encounter boss, spawns encounter-level mechanics
- `"miniboss"` — lieutenant-tier mob, higher health, dangerous abilities worth dedicated focus
- `"caster"` — ranged spellcaster, priority interrupt target
- `"warrior"` — melee DPS mob, front-line threat
- `"rogue"` — melee mob with evasion/stealth/stun abilities
- `"trivial"` — low-threat mob, abilities rarely lethal (adds, totems, summoned minions)
- `"unknown"` — not yet categorized (default for all dungeons except the pilot)

**Warrior/rogue split rationale:** The melee subtype distinction has concrete filtering value. A rogue-category mob signals "expect stuns, step out of AoE, watch for stealth re-entry" whereas a warrior-category mob signals "interrupt the big swing, face away." Collapsing both to `"melee"` loses this signal. The cost is one extra string value in the vocabulary — low.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `category` field on every npcID in AbilityDB | Without a category field there is nothing to filter on at runtime | LOW | Add field to each entry; default `"unknown"` requires no entry at all (reader falls back) |
| `"unknown"` is the default (not `nil` crash) | Addon must handle un-categorized mobs gracefully | LOW | Read as `entry.category or "unknown"` everywhere; no crash path |
| All dungeons default to `"unknown"` except pilot dungeon | Shipping partial data is better than inaccurate data | LOW | Only Skyreach categorized in v0.1.1; all others remain `"unknown"` |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Warrior/rogue melee subtype split | Finer-grained filtering than "melee vs. caster" | LOW | One extra string value; pay-off in filtering precision |
| Category visible in config UI | Players can see what category each mob is without knowing WoW internals | LOW | Read-only display field in mob header; see Feature Area 4 |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| User-editable categories | Power users want to reclassify mobs | Categories are used for filtering logic — user changes would silently break filter assumptions; requires moderation layer | Hardcode categories in addon data; update via addon releases |
| Per-category ability cooldown overrides | "Miniboss casters should have different timers than normal casters" | Adds a third config dimension (npcID × spellID × category) on top of existing two-dimensional config | Use per-skill config (npcID × spellID) already in place; categories only filter, not override |

---

## Feature Area 2: Runtime Category Detection from Nameplates

### What APIs are available in Midnight

**Verified from `wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`:**

All three candidate APIs share `SecretArguments = "AllowedWhenUntainted"` — the same annotation as `UnitClass` and `UnitCanAttack`, which TPW already calls successfully on nameplate unit tokens in `NameplateScanner.lua`. This means they are safe to call from untainted addon code on nameplate unit tokens.

| API | Signature | Returns | Confirmed use in Blizzard UI |
|-----|-----------|---------|------------------------------|
| `UnitClassification(unit)` | unit token | `"worldboss"`, `"rareelite"`, `"elite"`, `"rare"`, `"normal"`, `"trivial"`, `"minus"` | Yes — `Blizzard_NamePlateUnitFrame.lua` line 359 calls it to check `"minus"` on nameplate units |
| `UnitIsLieutenant(unit)` | unit token | `true` / `false` | API docs only; not used in any Blizzard UI Lua file in wow-ui-source |
| `UnitEffectiveLevel(unit)` | unit token (documented as "name: cstring") | number | Used on player/target tokens in Blizzard UI; same `SecretArguments` pattern |

**Key insight from `Blizzard_NamePlateUnitFrame.lua`:** Blizzard's own nameplate code calls `UnitClassification(self.unit)` on a nameplate unit token (a Secret Value), proving the pattern works in Midnight. TPW calls `UnitClass` on the same type of token and it works — `UnitClassification` is structurally identical.

**`UnitIsLieutenant` confidence note:** The function exists in the API documentation with the same taint annotation but appears in no Blizzard UI Lua files. It is likely valid but untested in any known addon context. LOW confidence on runtime behavior. Use it speculatively; wrap in `pcall` or test in-game before shipping.

**Detection logic recommended:**

```lua
-- At NAME_PLATE_UNIT_ADDED, cache alongside classBase:
local classification = UnitClassification(unitToken)
local isLieutenant = UnitIsLieutenant(unitToken)

-- Derive runtime category from classification + lieutenant flag:
local function DeriveRuntimeCategory(classification, isLieutenant)
    if isLieutenant then return "miniboss" end
    if classification == "worldboss" or classification == "rareelite" then return "boss" end
    if classification == "trivial" or classification == "minus" then return "trivial" end
    -- "elite", "rare", "normal" fall through — category comes from AbilityDB data
    return nil  -- signals "use data-file category"
end
```

The runtime-derived category acts as an override for `"boss"`, `"miniboss"`, and `"trivial"`. For `"caster"`, `"warrior"`, and `"rogue"` — which cannot be detected from WoW classification APIs — the category comes exclusively from the hardcoded data file entry.

**Why not use `UnitEffectiveLevel` for trivial detection:** Level-relative trivial detection is unreliable in instanced content where mobs are scaled. `UnitClassification` returning `"trivial"` or `"minus"` is the correct signal; it is already computed by the game engine with full scaling context.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Bosses detected at runtime (no data-file category required) | Bosses are reliably `"worldboss"` or `"rareelite"` classification; hardcoding is redundant | LOW | Read `UnitClassification` at `NAME_PLATE_UNIT_ADDED`; cache result |
| Trivial mobs detected at runtime | `"trivial"` and `"minus"` from `UnitClassification` map cleanly; avoids hand-labeling every totem | LOW | Same call as boss detection; trivial = classification is trivial or minus |
| Unknown-as-wildcard: unknown mobs never filtered | If category is unknown, all alerts for that mob fire unconditionally | LOW | Filter check: `if category == "unknown" or userWants[category] then alert end` |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Lieutenant detection via `UnitIsLieutenant` | Automatically promotes undocumented mini-boss-tier mobs without manual data work | LOW (if API works) | Cache at `NAME_PLATE_UNIT_ADDED`; verify in-game before shipping |
| Data-file category takes precedence for role-based types | Caster/warrior/rogue are semantic roles the game has no API for; data files are authoritative | LOW | Runtime detection only overrides for boss/miniboss/trivial; role-based types come from data |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Deriving `"caster"` from cast frequency at runtime | "The mob is always casting, so it must be a caster" | Cast frequency from a 0.25s poll is noisy; a warrior mob with frequent swings would be miscategorized | Hardcode `"caster"` in data files where verified; no runtime inference |
| Using `UnitEffectiveLevel` to detect trivial mobs | Level comparison seems logical | Level scaling in instanced content makes relative level unreliable; `UnitClassification` already handles trivial | Use classification API only |

---

## Feature Area 3: Filtering Alerts by Mob Category

### How category filtering works with the unknown-as-wildcard pattern

**Core invariant:** A false positive (alert fires when it arguably shouldn't) is better than a false negative (alert doesn't fire when it should). This drives the unknown-as-wildcard design.

**Filter logic:**
```
For a given alert to fire:
  IF mob.category == "unknown": ALWAYS fire (wildcard)
  ELSE: fire only if user has enabled this category in their filter settings
```

**Implementation location:** The filter check belongs in `NameplateScanner.lua` inside `OnMobsAdded` and `OnCastStart`, not in the Scheduler or IconDisplay. The scanner already has the mob context (`classBase` → npcID lookup is feasible via the pack's ability list).

**Category filter storage:** A simple boolean table in SavedVariables:
```lua
TerriblePackWarningsDB.categoryFilter = {
    boss     = true,
    miniboss = true,
    caster   = true,
    warrior  = true,
    rogue    = true,
    trivial  = false,  -- sensible default: don't alert on trivial mobs
    -- "unknown" is never stored here; always treated as true
}
```

**Complexity note:** The scanner currently iterates `activePack.abilities` and matches on `ability.mobClass`. To filter by category, the ability needs a `category` field (inherited from AbilityDB via Pipeline). This is a data propagation task: `Pipeline.lua`'s `MergeSkillConfig` must pass through `category` from the AbilityDB entry into the merged ability table.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Per-category on/off toggle | Users want to silence trivial-mob noise without disabling the full category manually per skill | MEDIUM | Boolean table in SavedVariables; UI in ConfigFrame |
| Unknown mobs always fire (wildcard) | Users must not lose alerts on un-categorized mobs | LOW | Single conditional in filter check; `category == "unknown"` bypasses filter |
| Category filter persists across sessions | User sets "ignore trivial" once | LOW | Store in `TerriblePackWarningsDB`; load on startup |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Sensible default filter state | `trivial = false` default means noise reduction without configuration | LOW | Set defaults in db initialization |
| Category filter separate from per-skill enable/disable | Users can mute a whole category without touching individual skill toggles | MEDIUM | Two independent filtering layers; category filter is coarser-grained |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Per-pull category override | "In this specific pull I don't care about warriors" | Pull-level state management adds significant complexity to the scanner; pull transitions are already edge cases | Per-category global filter is sufficient; use per-skill disable for exceptions |
| Category-based volume scaling | "Miniboss alerts should be louder" | Requires audio normalization layer; soundKitID playback has no volume parameter in `PlaySound` | Use alert sound selection per skill to convey priority |

---

## Feature Area 4: Displaying Category Info in Config UI

### What the config tree currently shows

The existing `ConfigFrame.lua` displays a mob header with format `"MobName - WARRIOR"` (mob name plus `entry.mobClass`). The category field is a natural addition to this header.

**Pattern for read-only display in WoW config UIs:**
- Blizzard's encounter journal uses colored labels with no interactable controls for metadata fields
- WeakAuras uses gray italic text for read-only tags
- MDT uses colored background rows for different enemy types (boss vs. trash)

**Recommended:** Add category as a styled tag appended to the mob header, visually distinct (e.g., italicized or color-coded) to signal it is not editable. No separate control — just text.

**Color coding by category:**

| Category | Color | Rationale |
|----------|-------|-----------|
| boss | Gold `|cffffd100` | Standard WoW boss color (used in LFG journal, MDT) |
| miniboss | Orange `|cffff7e00` | Between boss gold and normal; signals elevated threat |
| caster | Cyan `|cff00ccff` | Mage/caster class color convention |
| warrior | Gray-white `|cffc69b3d` | Warrior class color |
| rogue | Yellow `|cffffff00` | Rogue class color |
| trivial | Dark gray `|cff9d9d9d` | Low visual weight; signals low priority |
| unknown | Gray `|cff808080` | Neutral; signals "not yet categorized" |

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Category visible in mob header | Users need to know what category a mob is to understand why alerts do or don't fire | LOW | Append to existing `"MobName - WARRIOR"` header text; single `SetText` change |
| Category is not an editable control | Non-editable metadata should not look clickable | LOW | Text only, no Button or EditBox |
| Category filter toggle UI in config | Users need a way to enable/disable categories without hunting through every skill | MEDIUM | Add a row of checkboxes above the dungeon tree (one per category) |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Color-coded category tags | Immediate visual scan reveals mob priority without reading labels | LOW | WoW color escape codes in SetText |
| Category filter panel at top of config | One-click noise reduction for trivial/warrior/etc. rather than per-skill disable | MEDIUM | 7 checkboxes or toggles; reads/writes `categoryFilter` SavedVariable |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Filter mobs in config tree by category | "Show me only casters" | Config tree is already filtered by search; a second filter layer adds UI complexity before the first is validated | Search already covers this; category text in the header is scannable |
| Category edit button with confirmation | "What if the category is wrong?" | User-editable categories break the runtime detection contract (see Feature Area 1 anti-features) | Request corrections via GitHub issue; update in next addon release |

---

## Feature Dependencies

```
category field in AbilityDB data files
    └──required by──> Pipeline propagates category to pack abilities
                          └──required by──> NameplateScanner filter check
                          └──required by──> ConfigFrame category display

Runtime category detection (UnitClassification + UnitIsLieutenant)
    └──enhances──> category field (runtime override for boss/miniboss/trivial)
    └──depends on──> NAME_PLATE_UNIT_ADDED cache (already exists in plateCache)

categoryFilter SavedVariable
    └──required by──> NameplateScanner filter check (reads it per tick)
    └──required by──> ConfigFrame category filter toggles (writes it)

unknown-as-wildcard invariant
    └──constrains──> NameplateScanner filter check (unknown always passes)
    └──constrains──> categoryFilter UI (no toggle for "unknown" — it is always on)
```

### Dependency Notes

- **Pipeline must propagate `category`:** `MergeSkillConfig` in `Pipeline.lua` currently merges `spellID`, `mobClass`, and timer fields. Adding `category` requires reading it from `ns.AbilityDB[npcID].category` at merge time and including it in the returned ability table. This is a one-line addition.
- **Runtime detection is additive, not a replacement:** Data-file category is the ground truth for role-based types (caster/warrior/rogue). Runtime detection only overrides for structural types (boss/miniboss/trivial) that WoW classification APIs reliably expose. They compose, not conflict.
- **Unknown-as-wildcard is a hard constraint on filter logic:** Any future category filtering feature must respect this. Do not add an "unknown" toggle to the filter UI.
- **`UnitIsLieutenant` needs in-game validation:** Cache it at `NAME_PLATE_UNIT_ADDED` alongside `classBase`, but wrap in `pcall` until confirmed working in a real dungeon pull. It is the only API in this milestone that has no confirmed in-game usage in any known Lua file.

---

## MVP Definition for v0.1.1

### Launch With

- [ ] `category` field on all Skyreach npcID entries in `Data/Skyreach.lua` — pilot dungeon, fully categorized
- [ ] All other dungeons' AbilityDB entries default to `"unknown"` (no field = unknown; read as `entry.category or "unknown"`)
- [ ] `Pipeline.lua` propagates `category` from AbilityDB into merged ability tables
- [ ] `NameplateScanner.lua` caches `UnitClassification` + `UnitIsLieutenant` at `NAME_PLATE_UNIT_ADDED`
- [ ] Runtime category derivation: boss/miniboss/trivial overridden by runtime detection; caster/warrior/rogue from data file only
- [ ] `categoryFilter` table in `TerriblePackWarningsDB` with sensible defaults (trivial = false, all others = true)
- [ ] Filter check in `NameplateScanner:OnMobsAdded` and `OnCastStart`; unknown-as-wildcard invariant enforced
- [ ] Category tag displayed in mob header in `ConfigFrame.lua` (read-only, color-coded)
- [ ] Category filter toggle panel in `ConfigFrame.lua` (7 checkboxes, "unknown" always on, not shown)

### Add After Validation (v1.x)

- [ ] Expand category assignments to remaining 7 dungeons — trigger: Skyreach categorization confirmed accurate after in-game testing
- [ ] Add category color coding to pack selection window (PackFrame) portrait rows — trigger: user feedback requests visual priority signal in route UI

### Future Consideration (v2+)

- [ ] Per-category sound/alert override (different alert type for miniboss vs. caster) — defer until base category filter is validated useful

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| `category` field in AbilityDB (Skyreach) | HIGH | LOW (data entry for ~15 mobs) | P1 |
| Pipeline propagates category | HIGH | LOW (one-line addition to MergeSkillConfig) | P1 |
| Runtime detection (UnitClassification) | HIGH | LOW (add two calls to NAME_PLATE_UNIT_ADDED handler) | P1 |
| categoryFilter SavedVariable + defaults | HIGH | LOW (db init, trivial=false default) | P1 |
| Filter check in NameplateScanner | HIGH | LOW (two-line guard in OnMobsAdded/OnCastStart) | P1 |
| Category display in ConfigFrame header | MEDIUM | LOW (append to SetText in mob header) | P1 |
| Category filter toggle panel in ConfigFrame | MEDIUM | MEDIUM (7 checkboxes + read/write SavedVariable) | P1 |
| UnitIsLieutenant for miniboss detection | MEDIUM | LOW (one extra call, but needs in-game validation) | P2 |
| Category assignments for remaining 7 dungeons | HIGH | MEDIUM (data entry for 190+ mobs) | P2 |

**Priority key:**
- P1: Must have for v0.1.1 launch
- P2: Should have; add after in-game validation of pilot dungeon

---

## Competitor Feature Analysis

| Feature | MDT | BigWigs/LittleWigs | Plater | TPW Approach |
|---------|-----|--------------------|--------|--------------|
| Mob category field | `isBoss` boolean only; no caster/warrior/rogue/trivial | No category concept; boss mods target specific encounter bosses | Scripted per-nameplate rules (no static category system) | Hardcoded `category` field in AbilityDB, 7 values |
| Category-based filtering | N/A | N/A | Custom scripts per user | `categoryFilter` SavedVariable; unknown-as-wildcard |
| Runtime boss/lieutenant detection | Uses `isBoss` data, not runtime API | Uses encounter journal IDs, not nameplate APIs | Uses nameplate `UnitClassification` in custom scripts | `UnitClassification` + `UnitIsLieutenant` at nameplate add |
| Category in UI | Colored pull rows (boss vs. trash) | N/A | Nameplate color scripts per player | Read-only color-coded tag in ConfigFrame mob header |

---

## Sources

- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` — `UnitClassification`, `UnitIsLieutenant`, `UnitEffectiveLevel` API signatures; all confirmed `SecretArguments = "AllowedWhenUntainted"` (HIGH confidence)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateUnitFrame.lua` line 359 — Blizzard's own nameplate calls `UnitClassification(self.unit)` on a nameplate unit token; confirms the API works in Midnight on nameplate tokens (HIGH confidence)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateClassificationFrame.lua` — `UnitClassification` return value set: `"worldboss"`, `"rareelite"`, `"elite"`, `"rare"`, `"normal"`, `"trivial"`, `"minus"` (HIGH confidence)
- `C:/Users/jonat/Repositories/MythicDungeonTools/Developer/Schema.lua` and `Midnight/Skyreach.lua` — MDT's category system is `isBoss` boolean only; no caster/warrior/role categorization (HIGH confidence)
- `C:/Users/jonat/Repositories/TerriblePackWarnings/Engine/NameplateScanner.lua` — existing `plateCache` structure, `OnNameplateAdded` handler, `UnitClass`/`UnitCanAttack` calls on nameplate tokens (confirmed working pattern for `UnitClassification` addition)
- `C:/Users/jonat/Repositories/TerriblePackWarnings/Import/Pipeline.lua` — `MergeSkillConfig` function; propagation point for `category` field
- `C:/Users/jonat/Repositories/TerriblePackWarnings/UI/ConfigFrame.lua` line 563-564 — existing mob header format `"MobName - WARRIOR"`; category tag addition point

---
*Feature research for: TerriblePackWarnings v0.1.1 — Mob Category System*
*Researched: 2026-03-23*
