# Phase 04: Data Schema and Pack Update - Research

**Researched:** 2026-03-15
**Domain:** Lua data schema design for WoW addon ability tracking
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Abilities can be **timed** (has `first_cast` + `cooldown`) or **untimed** (`cooldown = nil`, icon-only display)
- Each ability entry includes a `mobClass` field — a UnitClass string (e.g. "PALADIN", "WARRIOR") used for nameplate filtering
- Empty/nil `mobClass` means the ability is always tracked regardless of detected mobs
- Mob `name` field dropped from schema — detection is class-based, not name-based
- Mob `npcID` field can be dropped — not used for class-based detection
- Windrunner Spire Pack 1 contains two abilities:
  - Spellguard's Protection: spellID 1253686, mobClass "PALADIN", first_cast 50s, cooldown 50s (timed)
  - Spirit Bolt: spellID 1216135, mobClass "WARRIOR", cooldown nil (untimed, icon-only)
- Ability `name` kept in data for now (used in TTS warnings in Phase 5)

### Claude's Discretion
- Whether to keep the nested mobs → abilities structure or flatten to a per-pack ability list
- Field naming conventions (mobClass vs mob_class vs class)
- Whether to keep `key` and `displayName` on pack entries

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DATA-06 | Each ability entry supports optional timer (nil cooldown = untimed/icon-only) | Schema design: `cooldown = nil` signals untimed; Scheduler reads `first_cast` and `cooldown` — both must be present or absent together |
| DATA-07 | Each ability entry includes mobClass filter (UnitClass value, e.g. "PALADIN") for nameplate detection | UnitClass returns uppercase English class token (second return value); confirmed in NameplateSummary.lua reference |
| DATA-08 | Mob name field dropped from data schema (filter by class, not name) | `name` field on mob subtable removed; mob subtable collapses or is removed entirely |
| DATA-09 | Update Windrunner Spire Pack 1: Spellguard's Protection (1253686, PALADIN, 50s) and Spirit Bolt (1216135, WARRIOR, untimed) | Direct data replacement in Data/WindrunnerSpire.lua |
</phase_requirements>

---

## Summary

This phase is a pure data restructuring task. No new Lua features, APIs, or third-party libraries are involved. The scope is one file (`Data/WindrunnerSpire.lua`) plus a decision about schema shape that downstream consumers (Scheduler and CombatWatcher) must continue to read correctly.

The central design question is whether to keep the nested `mobs → abilities` two-level structure or flatten to a single `abilities` array on the pack. Since mob-level fields (`name`, `npcID`) are being removed and the only mob-level distinguishing datum (`mobClass`) is moving onto individual ability entries, the nested structure no longer carries its weight. Flattening to `pack.abilities` is the correct call: it simplifies both the data file and the iteration in Scheduler/CombatWatcher.

The Scheduler currently iterates `pack.mobs` then `mob.abilities`. That loop must be updated to `pack.abilities` in Phase 5 (or treated as a compatibility concern noted here). Because CONTEXT.md explicitly scopes this phase to data changes only, the Scheduler and CombatWatcher are **not modified here** — but the planner must know that Scheduler:Start will break if called against the new schema unless the iteration is patched simultaneously or the schema retains compatibility shims.

**Primary recommendation:** Flatten to `pack.abilities`, add `mobClass` and handle `nil` cooldown at the ability level. Keep `key` and `displayName` on pack entries because PackFrame.lua and CombatWatcher both read them. Update WindrunnerSpire.lua to the new shape with the two confirmed abilities.

---

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Lua table literals | WoW Lua 5.1 compat | Data definition | Only option in WoW addon environment |
| `local addonName, ns = ...` pattern | Established in all project files | Namespace sharing | Project convention — used consistently |
| `ns.PackDatabase` keyed by dungeon slug | Established | Central data registry | Core.lua initializes, all data files append |

### No External Libraries
This phase uses no libraries. It is pure Lua table construction.

---

## Architecture Patterns

### Current Schema (to be replaced)

```lua
-- Data/WindrunnerSpire.lua — current shape
packs[#packs + 1] = {
    key         = "windrunner_spire_pack_1",
    displayName = "Windrunner Spire -- Pack 1",
    mobs = {
        {
            name  = "Spellguard Magus",   -- DROPPING
            npcID = 232113,               -- DROPPING
            abilities = {
                {
                    name       = "Spellguard's Protection",
                    spellID    = 1253686,
                    first_cast = 50,
                    cooldown   = 50,
                    -- mobClass absent -- ADDING
                },
            },
        },
    },
}
```

### Recommended Schema (new shape)

The `mobs` subtable is dropped. Abilities are listed directly on the pack. Each ability carries its own `mobClass` for filtering.

```lua
-- Data/WindrunnerSpire.lua — new shape
packs[#packs + 1] = {
    key         = "windrunner_spire_pack_1",
    displayName = "Windrunner Spire -- Pack 1",
    abilities = {
        {
            name       = "Spellguard's Protection",
            spellID    = 1253686,
            mobClass   = "PALADIN",
            first_cast = 50,
            cooldown   = 50,
        },
        {
            name     = "Spirit Bolt",
            spellID  = 1216135,
            mobClass = "WARRIOR",
            -- first_cast and cooldown absent = untimed
        },
    },
}
```

**Why flatten:** The only mob-level fields were `name` and `npcID`, both being dropped. `mobClass` belongs on the ability (one mob class produces one ability). Keeping a `mobs` wrapper for a single datum would be indirection without benefit.

**Why keep `key` and `displayName`:**
- `PackFrame.lua` reads `pack.displayName` directly at line 168 (`displayName = pack.displayName`)
- `CombatWatcher:OnCombatEnd` reads `dungeon[currentPackIndex].displayName` at line 106
- `CombatWatcher:SelectPack` reads `dungeon[packIndex].displayName` at line 62
- `key` is not actively read by any current consumer but serves as a stable identifier for future SavedVariables or external references — keep it

### Field Naming Convention

Use **camelCase** (`mobClass`, `first_cast`, `cooldown`, `spellID`, `displayName`) to match the existing field names in the codebase (`first_cast`, `cooldown`, `spellID`, `displayName` are already camelCase or snake_case mixed). Specifically:

- `mobClass` — matches the convention of `displayName` (camelCase compound noun)
- Do NOT use `mob_class` (only `first_cast` uses underscore in existing schema, and that was pre-existing)
- Do NOT use `class` — reserved keyword conflict risk in Lua (it is not actually reserved in Lua 5.1, but it is semantically confusing; avoid)

### Untimed Ability Convention

Untimed abilities omit `first_cast` and `cooldown` entirely (both nil by absence). The Scheduler currently reads both fields unconditionally — this will break if called against an untimed ability. The schema must make the nil pattern explicit so Phase 5 can write a guard:

```lua
-- Scheduler guard pattern (Phase 5 concern, documented here for planner awareness)
if ability.cooldown then
    scheduleAbility(ability)
else
    -- show static icon only
end
```

This phase does NOT modify Scheduler.lua. It only defines the data shape that Scheduler will need to handle in Phase 5.

### Per-Dungeon File Pattern

```
Data/
├── WindrunnerSpire.lua    -- updated this phase
└── [FutureDungeon].lua    -- new dungeons just add a file
```

Each file follows the same three-line header and `packs[#packs + 1] = { ... }` append pattern. Adding a dungeon requires no changes to Core.lua or PackDatabase — the namespace table is pre-initialized.

### Anti-Patterns to Avoid

- **Keeping `mobs` wrapper with only `abilities`:** Adds a level of indirection with no remaining payload. `for _, mob in ipairs(pack.mobs) do for _, ab in ipairs(mob.abilities) do` becomes `for _, ab in ipairs(pack.abilities) do`.
- **Using `class` as a field name:** Confusing given WoW's concept of player class and Lua's use of the word in OOP patterns.
- **Storing computed/derived fields in data:** `mobClass` is raw UnitClass token — no transformation. Downstream code does the comparison.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mob class detection | Custom name → class mapping table | `UnitClass(unit)` second return value | WoW API returns uppercase token directly; name-based mapping would break on localization |
| Schema validation | Runtime field validation loop | Careful authoring + nil-guards in consumers | WoW addon data files are trusted at load time; validate at consumer (Scheduler) not in data layer |

---

## Common Pitfalls

### Pitfall 1: Scheduler Breaks on Schema Change
**What goes wrong:** Scheduler:Start iterates `pack.mobs` then `mob.abilities`. After flattening to `pack.abilities`, the `pack.mobs` table is nil and `ipairs(pack.mobs)` errors.
**Why it happens:** The schema change affects the data shape but Scheduler is not modified in this phase.
**How to avoid:** The planner must decide: (a) update Scheduler iteration in this phase as a two-task wave, or (b) leave Scheduler broken until Phase 5 and note that `/tpw start` will error in the interim. Option (b) is acceptable since this is a dev-only state — the UI still loads, pack selection still works, only timer start breaks.
**Warning signs:** `attempt to call a nil value` in Scheduler:Start log output.

### Pitfall 2: UnitClass Token Casing
**What goes wrong:** `mobClass = "Paladin"` (mixed case) never matches `UnitClass()` return value `"PALADIN"` (all caps).
**Why it happens:** Data authored by hand with inconsistent casing.
**How to avoid:** Always use ALLCAPS for mobClass values. The NameplateSummary.lua reference confirms: `local _, classBase = UnitClass(npUnit)` returns `"PALADIN"`, `"WARRIOR"`, etc. in uppercase.

### Pitfall 3: Untimed Ability Picked Up by Old Scheduler
**What goes wrong:** Old Scheduler calls `ability.first_cast - 5` where `first_cast` is nil, producing a Lua error.
**Why it happens:** Spirit Bolt has no `first_cast` or `cooldown`. Scheduler does not guard against nil.
**How to avoid:** Document explicitly that Scheduler will error on untimed abilities until Phase 5 adds the nil guard. If testing in this phase, do not trigger combat start with the new data loaded against the old Scheduler.

### Pitfall 4: `displayName` Field Accidentally Dropped
**What goes wrong:** PackFrame.lua errors at `data.displayName = pack.displayName` because pack no longer has `displayName`.
**Why it happens:** Schema cleanup removes more than intended.
**How to avoid:** Explicitly keep `key` and `displayName` on pack entries — confirmed required by PackFrame.lua lines 164-168 and CombatWatcher lines 62, 106.

---

## Code Examples

### UnitClass API — confirmed by NameplateSummary.lua
```lua
-- Source: C:/Users/jonat/Repositories/WeakerScripts/Samples/NameplateSummary.lua, line 67
local _, classBase = UnitClass(npUnit)
-- classBase is e.g. "PALADIN", "WARRIOR", "MAGE" — always uppercase English token
-- Returns nil if unit has no class (non-player mobs that are class-typed return the class)
```

### Completed WindrunnerSpire.lua after phase
```lua
-- Source: Data/WindrunnerSpire.lua (post-phase shape)
local addonName, ns = ...

ns.PackDatabase["windrunner_spire"] = ns.PackDatabase["windrunner_spire"] or {}
local packs = ns.PackDatabase["windrunner_spire"]

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_1",
    displayName = "Windrunner Spire -- Pack 1",
    abilities = {
        {
            name       = "Spellguard's Protection",
            spellID    = 1253686,
            mobClass   = "PALADIN",
            first_cast = 50,
            cooldown   = 50,
        },
        {
            name     = "Spirit Bolt",
            spellID  = 1216135,
            mobClass = "WARRIOR",
            -- no first_cast, no cooldown = untimed (icon-only)
        },
    },
}
```

### Scheduler iteration change (Phase 5 concern, shown for context)
```lua
-- Current (Phase 3 era):
for _, mob in ipairs(pack.mobs) do
    for _, ability in ipairs(mob.abilities) do
        scheduleAbility(ability)
    end
end

-- Required in Phase 5:
for _, ability in ipairs(pack.abilities) do
    if ability.cooldown then
        scheduleAbility(ability)
    else
        -- queue untimed icon display
    end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mob-keyed nested structure with name/npcID | Pack-level flat ability list with mobClass | Phase 4 | Simplifies iteration; loses mob grouping (not needed) |
| Name-based mob detection | UnitClass-based nameplate detection | v0.0.2 decision | More robust; locale-independent |
| All abilities timed | Timed + untimed distinction | Phase 4 | Enables icon-only display for unpredictable abilities |

---

## Open Questions

1. **Should Scheduler be updated in this phase or Phase 5?**
   - What we know: Scheduler iteration breaks the moment `pack.mobs` disappears.
   - What's unclear: Whether the planner scopes this phase strictly to the data file or includes the Scheduler iteration change as a companion task.
   - Recommendation: Include the Scheduler iteration update as a second task in this phase (it is a 3-line change: `pack.mobs → pack.abilities` loop, plus a nil guard on `cooldown`). Leaving it broken risks confusion. However, CONTEXT.md says "this phase only changes data structures," so the planner should decide — both options are valid.

2. **Does `mobClass = nil` (absent) need explicit documentation?**
   - What we know: CONTEXT.md says "Empty/nil mobClass means the ability is always tracked regardless of detected mobs."
   - What's unclear: Whether any Phase 4 ability needs this case.
   - Recommendation: No Phase 4 ability uses nil mobClass, so no test case exists yet. Document the convention in a comment in the data file; no code required this phase.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — WoW addon; no automated test runner detected |
| Config file | N/A |
| Quick run command | Load addon in WoW client; check for Lua errors in chat |
| Full suite command | `/tpw status` + `/tpw start` + verify chat output |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-06 | Spirit Bolt has no cooldown field; Spellguard's Protection has cooldown 50 | manual | Load addon, inspect `ns.PackDatabase` via `/print` in-game | ❌ Wave 0 |
| DATA-07 | Each ability has `mobClass` field matching UnitClass token | manual | `/run print(ns.PackDatabase["windrunner_spire"][1].abilities[1].mobClass)` → should print `PALADIN` | ❌ Wave 0 |
| DATA-08 | No `name` field on mob subtable; no `mobs` key on pack | manual | `/run print(ns.PackDatabase["windrunner_spire"][1].mobs)` → should print `nil` | ❌ Wave 0 |
| DATA-09 | Pack 1 has exactly two abilities with correct spellIDs | manual | `/run for i,a in ipairs(ns.PackDatabase["windrunner_spire"][1].abilities) do print(a.name, a.spellID) end` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Reload UI (`/reload`) and check for Lua errors
- **Per wave merge:** Run all four in-game `/run` verification commands above
- **Phase gate:** All four checks pass before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] No automated test infrastructure exists for WoW addons — all validation is manual in-game `/run` commands
- [ ] Verification script: consider a `/tpw debug-schema` slash command that prints all pack data to chat (optional, not required for phase gate)

*(WoW addon Lua cannot be tested outside the WoW client without third-party tooling. Manual in-game verification is the correct approach for this project.)*

---

## Sources

### Primary (HIGH confidence)
- `Data/WindrunnerSpire.lua` — current schema examined directly
- `Engine/Scheduler.lua` — confirmed field reads: `ability.first_cast`, `ability.cooldown`, `ability.name`, `ability.spellID`
- `Engine/CombatWatcher.lua` — confirmed reads: `pack.displayName`, `pack.mobs` (iteration), `dungeon[packIndex].displayName`
- `UI/PackFrame.lua` — confirmed reads: `pack.displayName` (line 168)
- `C:/Users/jonat/Repositories/WeakerScripts/Samples/NameplateSummary.lua` — confirms `UnitClass()` returns uppercase token as second value
- `.planning/phases/04-data-schema-and-pack-update/04-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence)
- WoW API convention: UnitClass second return value is always uppercase English class token (consistent with all known WoW addon documentation and the reference script)

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Schema design: HIGH — derived directly from reading all consumer files
- UnitClass token format: HIGH — confirmed by in-project reference script
- Scheduler break risk: HIGH — verified by reading Scheduler.lua iteration code
- Pack data values (spellIDs, timings): HIGH — copied verbatim from CONTEXT.md locked decisions

**Research date:** 2026-03-15
**Valid until:** Stable — no external dependencies; valid until schema consumers change
