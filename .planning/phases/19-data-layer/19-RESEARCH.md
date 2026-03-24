# Phase 19: Data Layer - Research

**Researched:** 2026-03-23
**Domain:** WoW addon Lua data file editing — AbilityDB schema migration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- `mobClass` (WoW UnitClassBase token) is removed from all AbilityDB entries in all Data/*.lua files
- `mobCategory` (lowercase semantic role string) replaces it as the sole mob descriptor
- Valid values: `"boss"`, `"miniboss"`, `"caster"`, `"warrior"`, `"rogue"`, `"trivial"`, `"unknown"`
- WoW class detection (`UnitClassBase`) is used only at runtime in the nameplate scanner (Phase 20), never stored in data files
- This is a breaking change to the AbilityDB schema — Phase 20 must rework the scanner's matching logic
- All 22 Skyreach mobs have specific categories per the reference table in CONTEXT.md
- Mobs that appear in DungeonEnemies but have no tracked abilities (Outcast Servant, npcID 75976) get an AbilityDB entry with `mobCategory` and an empty `abilities = {}` table
- All mobs in the 8 non-Skyreach dungeons get `mobCategory = "unknown"` as an explicit string assignment
- No mob should have a nil `mobCategory` at runtime

### Claude's Discretion

- Field placement order (mobCategory before or after abilities)
- Comment header format in data files (whether to document valid category values)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DATA-01 | Every AbilityDB npcID entry has a `mobCategory` field with one of: `"boss"`, `"miniboss"`, `"caster"`, `"warrior"`, `"rogue"`, `"trivial"`, `"unknown"` | Field replacement pattern documented below; mob counts per file verified |
| DATA-02 | All 22 Skyreach mobs have their correct category assigned per the provided table | Full Skyreach reference table in CONTEXT.md; confirmed all 21 existing entries + 1 new stub entry (75976) |
| DATA-03 | All mobs in the other 8 dungeons have `mobCategory = "unknown"` as explicit default | All 8 non-Skyreach data files identified and mob counts enumerated below |
| DATA-04 | `mobClass` (WoW class token) and `mobCategory` (semantic role) are clearly distinct fields with no naming confusion | Comment strategy documented; field naming is unambiguous by case and semantics |
</phase_requirements>

## Summary

Phase 19 is pure data file editing. There is no API research, no runtime code, and no new functionality — only a schema migration across 9 Lua data files. The change is: remove `mobClass = "WARRIOR"` from every AbilityDB entry and replace it with `mobCategory = "<value>"`. For Skyreach, the 22 specific values come from the reference table. For the other 8 dungeons, the value is always `"unknown"`. One new stub entry must be added (npcID 75976, Outcast Servant) because it appears in DungeonEnemies but currently has no AbilityDB entry.

The breaking change implication is documented but out of scope for this phase: `mobClass` is currently read by `Engine/NameplateScanner.lua` (lines 76, 107, 119, 250), `Import/Pipeline.lua` (lines 41, 53, 105, 107), `UI/PackFrame.lua` (lines 28–29, 68–70), and `UI/ConfigFrame.lua` (lines 20–21, 48–50, 563–564). All of these break when `mobClass` is gone. Phase 20 owns those fixes.

**Primary recommendation:** Edit all 9 Data/*.lua files in a single plan, verifying mob count completeness per file against DungeonEnemies before committing.

## Standard Stack

No new libraries. This phase uses only the existing Lua table literal syntax in WoW addon data files.

## Architecture Patterns

### Existing AbilityDB Entry Structure (before Phase 19)

```lua
-- MobName (npcID)
ns.AbilityDB[npcID] = {
    mobClass = "WARRIOR",    -- WoW UnitClassBase token: uppercase, e.g. "WARRIOR", "MAGE"
    abilities = {
        { spellID = 123456, defaultEnabled = false },
    },
}
```

### Target AbilityDB Entry Structure (after Phase 19)

```lua
-- MobName (npcID)
ns.AbilityDB[npcID] = {
    mobCategory = "warrior",  -- semantic role: boss/miniboss/caster/warrior/rogue/trivial/unknown
    abilities = {
        { spellID = 123456, defaultEnabled = false },
    },
}
```

Key decisions on Claude's discretion items:
- **Field placement:** `mobCategory` goes in the same position as `mobClass` (first field, before `abilities`). Consistent placement is easier to grep and scan.
- **Comment header:** Replace the existing per-file header comment. New header documents the field distinction explicitly. Example:

```lua
-- Skyreach ability database
-- Keyed by npcID
-- mobCategory: semantic role — "boss"|"miniboss"|"caster"|"warrior"|"rogue"|"trivial"|"unknown"
--   (distinct from mobClass WoW token e.g. "WARRIOR"; mobClass is runtime-only, not stored here)
```

### New Stub Entry Pattern (for mobs with no abilities)

```lua
-- Outcast Servant (75976) — in DungeonEnemies, no tracked abilities
ns.AbilityDB[75976] = {
    mobCategory = "warrior",
    abilities = {},
}
```

### Anti-Patterns to Avoid

- **Mixing `mobClass` and `mobCategory` values:** Never write `mobCategory = "WARRIOR"` (uppercase). The uppercase form is the WoW class token; the lowercase is the semantic role. If they look the same visually it creates confusion — the vocabulary difference (uppercase vs lowercase) is the entire disambiguation.
- **Leaving any entry without `mobCategory`:** Every entry must have the field as an explicit string. Nil at runtime is a bug, not a default.
- **Forgetting the stub entry:** npcID 75976 (Outcast Servant) has no current AbilityDB entry but is in DungeonEnemies[151]. It must get a stub entry with `abilities = {}`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mob count verification | Runtime assertion code | Manual cross-reference against DungeonEnemies.lua | Phase 19 is data-only; assertions belong in Phase 20 validation |
| Category lookup | A function that maps old mobClass to mobCategory | Direct data entry from CONTEXT.md reference table | Categories are factual, not derived from class tokens |

## Common Pitfalls

### Pitfall 1: Missing the Stub Entry for Outcast Servant
**What goes wrong:** npcID 75976 appears in DungeonEnemies[151] but has no AbilityDB entry. If it is not added, Skyreach is not "fully categorized" per DATA-02 — one mob has no category at all.
**Why it happens:** Cross-referencing DungeonEnemies against AbilityDB requires a deliberate check; editing the data file directly would not reveal the gap.
**How to avoid:** Before finishing Skyreach edits, count entries in DungeonEnemies[151] (22 entries: indices 1–22) and confirm AbilityDB has 22 matching npcIDs after the edit.
**Warning signs:** DungeonEnemies[151] has 22 entries; Skyreach.lua after editing has only 21.

### Pitfall 2: Breaking the File Header Comment
**What goes wrong:** The existing file header says `-- Keyed by npcID; mobClass defaults to WARRIOR, abilities from MDT spells`. If this is left unchanged after removing `mobClass`, the comment becomes a lie and actively contributes to the mobClass/mobCategory confusion DATA-04 is meant to eliminate.
**How to avoid:** Update the header comment in every data file as part of the edit pass.

### Pitfall 3: Confusing mobCategory Value Casing
**What goes wrong:** Accidentally writing `mobCategory = "Caster"` or `mobCategory = "WARRIOR"`. The canonical vocabulary is all-lowercase.
**How to avoid:** Write `"boss"`, `"miniboss"`, `"caster"`, `"warrior"`, `"rogue"`, `"trivial"`, `"unknown"` — never capitalized.

### Pitfall 4: Partial Edit on a File
**What goes wrong:** One entry in a file retains `mobClass` because it was scrolled past. After Phase 20 ships, that single remaining `mobClass` field is silently ignored and the mob never fires abilities — no error, no warning.
**How to avoid:** After editing each file, grep the file for `mobClass` to confirm zero occurrences.

## File-by-File Scope

### Data/Skyreach.lua
- 21 existing entries — all have `mobClass = "WARRIOR"` to replace with per-mob `mobCategory`
- 1 new stub entry — npcID 75976 (Outcast Servant, `mobCategory = "warrior"`, `abilities = {}`)
- Total after edit: 22 entries matching DungeonEnemies[151] count

Skyreach category assignments (from CONTEXT.md, verbatim):

| npcID | Mob Name | Category |
|-------|----------|----------|
| 76132 | Soaring Chakram Master | warrior |
| 78932 | Driving Gale-Caller | caster |
| 250992 | Raging Squall | rogue |
| 75976 | Outcast Servant | warrior |
| 79462 | Blinding Sun Priestess | caster |
| 79466 | Initiate of the Rising Sun | caster |
| 79467 | Adept of the Dawn | caster |
| 78933 | Herald of Sunrise | miniboss |
| 76087 | Solar Construct | miniboss |
| 79093 | Skyreach Sun Talon | trivial |
| 76154 | Sun Talon Tamer | miniboss |
| 75964 | Ranjit | boss |
| 76141 | Araknath | boss |
| 76142 | Skyreach Sun Construct Prototype | unknown |
| 76143 | Rukhran | boss |
| 76149 | Dread Raven | miniboss |
| 76205 | Blooded Bladefeather | warrior |
| 76227 | Sunwings | unknown |
| 76266 | High Sage Viryx | boss |
| 76285 | Arakkoa Magnifying Glass | unknown |
| 79303 | Adorned Bladetalon | miniboss |
| 251880 | Solar Orb | trivial |

### Data/WindrunnerSpire.lua
- 30 existing entries — all get `mobCategory = "unknown"`
- Note: DungeonEnemies[152] has 31 entries. WindrunnerSpire.lua currently has 30 (Dutiful Groundskeeper, npcID 232071, and Scouting Trapper npcID 238049 are in DungeonEnemies but absent from AbilityDB). This pre-existing gap is out of scope — Phase 19 only edits existing entries and the Skyreach stub. Do not add stubs for other dungeons.

### Data/AlgetharAcademy.lua
- 16 existing entries — all get `mobCategory = "unknown"`

### Data/MagistersTerrace.lua
- 21 existing entries — all get `mobCategory = "unknown"`

### Data/MaisaraCaverns.lua
- 30 existing entries — all get `mobCategory = "unknown"`

### Data/NexusPointXenas.lua
- 29 existing entries — all get `mobCategory = "unknown"`

### Data/PitOfSaron.lua
- 22 existing entries — all get `mobCategory = "unknown"`

### Data/SeatoftheTriumvirate.lua
- 18 existing entries — all get `mobCategory = "unknown"`

## Code Examples

### Skyreach entry before and after

Before:
```lua
-- Driving Gale-Caller (78932)
ns.AbilityDB[78932] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1255377, defaultEnabled = false },
    },
}
```

After:
```lua
-- Driving Gale-Caller (78932)
ns.AbilityDB[78932] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1255377, defaultEnabled = false },
    },
}
```

### Non-Skyreach dungeon entry before and after

Before:
```lua
-- Restless Steward (232070)
ns.AbilityDB[232070] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1216135, defaultEnabled = false },
        { spellID = 1216298, defaultEnabled = false },
        { spellID = 1253700, defaultEnabled = false },
    },
}
```

After:
```lua
-- Restless Steward (232070)
ns.AbilityDB[232070] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216135, defaultEnabled = false },
        { spellID = 1216298, defaultEnabled = false },
        { spellID = 1253700, defaultEnabled = false },
    },
}
```

### New stub entry for Outcast Servant

```lua
-- Outcast Servant (75976) -- in DungeonEnemies, no tracked abilities
ns.AbilityDB[75976] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {},
}
```

### Updated file header comment

```lua
-- Skyreach ability database
-- Keyed by npcID
-- mobCategory: semantic role — "boss"|"miniboss"|"caster"|"warrior"|"rogue"|"trivial"|"unknown"
--   (not to be confused with the runtime WoW class token e.g. "WARRIOR"; that is never stored here)
```

For non-Skyreach files, same header substituting the dungeon name.

## Integration Points That Break (Phase 20 scope, not Phase 19)

The following read `mobClass` at runtime and will fail after Phase 19:

| File | Lines | What it does |
|------|-------|--------------|
| `Engine/NameplateScanner.lua` | 76, 107, 119, 250 | Matches abilities by `ability.mobClass == classBase` |
| `Import/Pipeline.lua` | 41, 53, 105, 107 | Propagates `mobClass` into merged ability tables and uses it as a dedup key |
| `UI/PackFrame.lua` | 28–29, 68–70 | Reads `mobClass` from AbilityDB for class icon display |
| `UI/ConfigFrame.lua` | 20–21, 48–50, 563–564 | Reads `mobClass` for class icon and mob header label |

Phase 19 makes these break intentionally. The addon will not function correctly between Phase 19 and Phase 20. Per the CONTEXT.md breaking change warning, these two phases should be executed together before testing in-game.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — no automated test infrastructure for Lua addon data files |
| Config file | N/A |
| Quick run command | Manual: `./scripts/install.bat` then `/tpw` in-game |
| Full suite command | Manual: deploy and test in Windrunner Spire + Skyreach with imported route |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Every AbilityDB entry has `mobCategory` field | grep check | `grep -r "mobClass" Data/` returns zero results | ❌ manual grep post-edit |
| DATA-02 | All 22 Skyreach mobs have correct category | grep + count | Count entries in Skyreach.lua = 22; spot-check npcIDs against table | ❌ manual |
| DATA-03 | All other dungeons have `mobCategory = "unknown"` | grep check | `grep "mobCategory" Data/WindrunnerSpire.lua` etc. shows only "unknown" | ❌ manual grep |
| DATA-04 | No naming confusion between mobClass and mobCategory | grep | `grep -r "mobClass" Data/` returns zero results after edit | ❌ manual grep |

### Sampling Rate

- **Per file edited:** `grep -n "mobClass" Data/<file>.lua` must return zero results
- **After all files:** `grep -rn "mobClass" Data/` must return zero results across all Data/*.lua
- **Phase gate:** Zero `mobClass` references in Data/ directory; 22 entries in Skyreach.lua; Skyreach category table spot-checked against reference

### Wave 0 Gaps

No test infrastructure to create — this phase has no automated tests. The validation strategy is post-edit grep checks and manual in-game testing in Phase 20.

## Open Questions

1. **Comment style: inline vs. header-only documentation of category vocabulary**
   - What we know: CONTEXT.md marks this as Claude's discretion
   - Recommendation: Document the full vocabulary in the file header comment only; use a brief inline comment `-- semantic role; see header for vocabulary` on each `mobCategory` line. This keeps individual entries readable without repeating the full list 30 times per file.

## Sources

### Primary (HIGH confidence)

- `Data/Skyreach.lua` — 21 existing entries confirmed; all `mobClass = "WARRIOR"`
- `Data/WindrunnerSpire.lua` — 30 existing entries confirmed
- `Data/AlgetharAcademy.lua` — 16 existing entries confirmed
- `Data/DungeonEnemies.lua` — Skyreach section (dungeonIdx 151) has 22 entries; entry [4] is npcID 75976 (Outcast Servant), confirming the stub entry requirement
- `Engine/NameplateScanner.lua` — mobClass read sites: lines 76, 107, 119, 250
- `Import/Pipeline.lua` — mobClass read sites: lines 41, 53, 105, 107
- `UI/PackFrame.lua` — mobClass read sites: lines 28–29, 68–70
- `UI/ConfigFrame.lua` — mobClass read sites: lines 20–21, 48–50, 563–564
- `.planning/phases/19-data-layer/19-CONTEXT.md` — Skyreach category table, field decisions, breaking change warning

### Secondary (MEDIUM confidence)

- `.planning/research/SUMMARY.md` — Upstream project research; confirms mobClass/mobCategory pitfall and data ownership decisions

## Metadata

**Confidence breakdown:**
- File inventory: HIGH — all 9 data files read directly; mob counts confirmed from source
- Skyreach category assignments: HIGH — verbatim from locked decisions in CONTEXT.md
- Breaking change scope: HIGH — all mobClass read sites identified by grep
- Stub entry requirement: HIGH — DungeonEnemies[151] cross-referenced directly

**Research date:** 2026-03-23
**Valid until:** Stable indefinitely — this is data file content, not API-dependent
