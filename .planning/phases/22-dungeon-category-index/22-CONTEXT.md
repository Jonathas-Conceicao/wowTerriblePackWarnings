# Phase 22: Dungeon Category Index - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Apply mob categories from MobCategories.md to all 7 remaining dungeon data files (WindrunnerSpire, AlgetharAcademy, MagistersTerrace, MaisaraCaverns, NexusPointXenas, PitOfSaron, SeatoftheTriumvirate). Remove the `isBoss` field from DungeonEnemies.lua entirely — boss detection is now handled by `mobCategory = "boss"` in AbilityDB. Update PackFrame.lua to use AbilityDB for boss pull row highlighting. Add new mob Mindless Laborer to Pit of Saron.

</domain>

<decisions>
## Implementation Decisions

### Category application
- All 7 dungeon data files get their `mobCategory = "unknown"` values replaced with the correct categories from `MobCategories.md`
- `MobCategories.md` at project root is the authoritative reference — data files reference it
- Categories are applied exactly as listed: boss, miniboss, caster, warrior, rogue, trivial, unknown

### isBoss removal
- Remove `isBoss = true` from every entry in `Data/DungeonEnemies.lua`
- Remove the `npcIdIsBoss` lookup table and its construction loop from `UI/PackFrame.lua`
- Replace boss pull row detection in PackFrame with `ns.AbilityDB[npcID].mobCategory == "boss"` — every mob has an AbilityDB entry with mobCategory set (including stub entries for mobs with no abilities), so AbilityDB is a complete source

### New mob: Mindless Laborer
- npcID: 252557
- displayId: 137487
- name: "Mindless Laborer"
- category: trivial
- Dungeon: Pit of Saron
- Add to both `Data/DungeonEnemies.lua` (Pit of Saron section) and `Data/PitOfSaron.lua` (AbilityDB stub entry with `mobCategory = "trivial"` and `abilities = {}`)

### Claude's Discretion
- Exact insertion position of Mindless Laborer in DungeonEnemies (maintain index ordering)
- Comment header updates in data files if needed
- Whether to update the DungeonEnemies file header comment to remove mention of isBoss

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Category source (authoritative)
- `MobCategories.md` — All 7 dungeons with correct per-mob categories. This is the single source of truth for category assignments.

### Data files to modify (category application)
- `Data/WindrunnerSpire.lua` — 31 mobs, replace "unknown" with correct categories
- `Data/AlgetharAcademy.lua` — 17 mobs
- `Data/MagistersTerrace.lua` — 25 mobs
- `Data/MaisaraCaverns.lua` — 32 mobs
- `Data/NexusPointXenas.lua` — 34 mobs
- `Data/PitOfSaron.lua` — 24 mobs (23 existing + 1 new Mindless Laborer stub)
- `Data/SeatoftheTriumvirate.lua` — 22 mobs

### isBoss removal
- `Data/DungeonEnemies.lua` — Remove all `isBoss = true` fields, update header comment
- `UI/PackFrame.lua` — Lines 33-41: remove `npcIdIsBoss` table. Line 510: replace with AbilityDB category check.

### Prior phase context
- `.planning/phases/19-data-layer/19-CONTEXT.md` — Established the mobCategory field pattern and stub entry convention

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 19 established the pattern: `mobCategory = "value",  -- semantic role; see header for vocabulary`
- Stub entry pattern: `ns.AbilityDB[npcID] = { mobCategory = "trivial", abilities = {} }`
- `ns.AbilityDB[npcID].mobCategory` is already readable from any file via the shared namespace

### Established Patterns
- Data file header documents vocabulary: `-- mobCategory: boss | miniboss | caster | warrior | rogue | trivial | unknown`
- DungeonEnemies entries: `{ id = npcID, name = "Name", displayId = NNNN }`

### Integration Points
- `UI/PackFrame.lua` line 510: `if npcIdIsBoss[npcID] then` → replace with `if ns.AbilityDB[npcID] and ns.AbilityDB[npcID].mobCategory == "boss" then`
- `Data/DungeonEnemies.lua`: Pit of Saron section needs new entry for Mindless Laborer (252557, displayId 137487)

</code_context>

<specifics>
## Specific Ideas

No specific requirements — mechanical data application from MobCategories.md reference doc.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 22-dungeon-category-index*
*Context gathered: 2026-03-24*
