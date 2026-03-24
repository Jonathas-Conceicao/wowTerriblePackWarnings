# Phase 19: Data Layer - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add `mobCategory` field to every AbilityDB npcID entry across all 9 dungeon data files. Remove the `mobClass` field entirely — it is replaced by `mobCategory` as the sole mob descriptor in data files. Skyreach gets real category values from the provided reference table; all other dungeons default to `"unknown"`. Mobs with no tracked abilities still get a category-only AbilityDB entry if they appear in DungeonEnemies for a categorized dungeon (Skyreach).

</domain>

<decisions>
## Implementation Decisions

### Field replacement: mobClass removed, mobCategory added
- `mobClass` (WoW UnitClassBase token) is **removed** from all AbilityDB entries in all Data/*.lua files
- `mobCategory` (lowercase semantic role string) replaces it as the sole mob descriptor
- Valid values: `"boss"`, `"miniboss"`, `"caster"`, `"warrior"`, `"rogue"`, `"trivial"`, `"unknown"`
- WoW class detection (`UnitClassBase`) is used only at runtime in the nameplate scanner (Phase 20), never stored in data files
- This is a breaking change to the AbilityDB schema — Phase 20 must rework the scanner's matching logic to use category instead of mobClass

### Skyreach category assignments
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

### Mobs without abilities
- Mobs that appear in DungeonEnemies but have no tracked abilities still get an AbilityDB entry with `mobCategory` and an empty `abilities = {}` table
- This keeps category data complete for all mobs in a categorized dungeon
- Applies to Skyreach only for now (Outcast Servant, npcID 75976)

### Other dungeons
- All mobs in the 8 non-Skyreach dungeons get `mobCategory = "unknown"` as an explicit string assignment
- No mob should have a nil `mobCategory` at runtime

### Claude's Discretion
- Field placement order (mobCategory before or after abilities)
- Comment header format in data files (whether to document valid category values)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Data files to modify
- `Data/Skyreach.lua` — Pilot dungeon: remove mobClass, add mobCategory with real values
- `Data/WindrunnerSpire.lua` — Remove mobClass, add mobCategory = "unknown"
- `Data/AlgetharAcademy.lua` — Remove mobClass, add mobCategory = "unknown"
- `Data/MagistersTerrace.lua` — Remove mobClass, add mobCategory = "unknown"
- `Data/MaisaraCaverns.lua` — Remove mobClass, add mobCategory = "unknown"
- `Data/NexusPointXenas.lua` — Remove mobClass, add mobCategory = "unknown"
- `Data/PitOfSaron.lua` — Remove mobClass, add mobCategory = "unknown"
- `Data/SeatoftheTriumvirate.lua` — Remove mobClass, add mobCategory = "unknown"

### Reference data
- `Data/DungeonEnemies.lua` — Cross-reference for Skyreach mobs (includes npcID 75976 Outcast Servant which has no current AbilityDB entry)

### Research context
- `.planning/research/SUMMARY.md` — API research, pitfalls (mobClass vs mobCategory confusion), architecture decisions

</canonical_refs>

<code_context>
## Existing Code Insights

### Established Patterns
- AbilityDB entries: `ns.AbilityDB[npcID] = { mobClass = "WARRIOR", abilities = { ... } }` — mobClass field being removed
- All data files share the same structure: `local addonName, ns = ...` header, `ns.AbilityDB = ns.AbilityDB or {}` guard, then npcID entries with comment labels
- Comment format: `-- MobName (npcID)` before each entry

### Integration Points
- `Engine/NameplateScanner.lua` — Currently reads `mobClass` from AbilityDB for nameplate matching. Will break after Phase 19; Phase 20 reworks this to use `mobCategory`
- `Import/Pipeline.lua` — `MergeSkillConfig` reads `mobClass` from AbilityDB entries. Must be updated in Phase 20
- `UI/ConfigFrame.lua` — May reference `mobClass` for display. Phase 21 adds category display

### Breaking Change Warning
Removing `mobClass` will break the nameplate scanner until Phase 20 reworks it. Phase 19 and 20 should be executed together or the addon will not function between them.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — standard data file editing with the provided Skyreach category table.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 19-data-layer*
*Context gathered: 2026-03-23*
