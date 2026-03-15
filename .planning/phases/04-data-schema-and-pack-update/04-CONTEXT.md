# Phase 4: Data Schema and Pack Update - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Restructure ability data to support timed and untimed skills with mob class filters for nameplate-based detection. Update Windrunner Spire Pack 1 with accurate data. This phase only changes data structures — no display or detection logic.

</domain>

<decisions>
## Implementation Decisions

### Schema Changes
- Abilities can be **timed** (has `first_cast` + `cooldown`) or **untimed** (`cooldown = nil`, icon-only display)
- Each ability entry includes a `mobClass` field — a UnitClass string (e.g. "PALADIN", "WARRIOR") used for nameplate filtering
- Empty/nil `mobClass` means the ability is always tracked regardless of detected mobs
- Mob `name` field dropped from schema — detection is class-based, not name-based
- Mob `npcID` field can be dropped — not used for class-based detection

### Pack Data
- Windrunner Spire Pack 1 contains two abilities:
  - Spellguard's Protection: spellID 1253686, mobClass "PALADIN", first_cast 50s, cooldown 50s (timed)
  - Spirit Bolt: spellID 1216135, mobClass "WARRIOR", cooldown nil (untimed, icon-only)
- Ability `name` kept in data for now (used in TTS warnings in Phase 5)

### Claude's Discretion
- Whether to keep the nested mobs → abilities structure or flatten to a per-pack ability list
- Field naming conventions (mobClass vs mob_class vs class)
- Whether to keep `key` and `displayName` on pack entries

</decisions>

<specifics>
## Specific Ideas

- The schema should be simple enough that adding new dungeons later is just adding a new data file
- Untimed abilities are for skills that can be interrupted/stunned/delayed, making timer prediction unreliable

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Data/WindrunnerSpire.lua`: Current pack data file — needs restructuring
- `ns.PackDatabase`: Shared namespace table populated at load time

### Established Patterns
- `local addonName, ns = ...` namespace for all files
- Data files use `packs[#packs + 1] = { ... }` to append ordered entries
- PackDatabase is keyed by dungeon slug ("windrunner_spire")

### Integration Points
- `Engine/Scheduler.lua`: Reads ability `first_cast`, `cooldown`, `name`, `spellID` — will need updating in Phase 5
- `Engine/CombatWatcher.lua`: Iterates `pack.mobs` and `mob.abilities` — schema change affects iteration
- `UI/PackFrame.lua`: Reads `pack.displayName` — unchanged

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-data-schema-and-pack-update*
*Context gathered: 2026-03-15*
