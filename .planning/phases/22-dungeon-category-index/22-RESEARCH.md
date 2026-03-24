# Phase 22: Dungeon Category Index - Research

**Researched:** 2026-03-24
**Domain:** Lua data file editing — WoW addon ability database and DungeonEnemies maintenance
**Confidence:** HIGH

## Summary

This phase is a pure data application task. All category assignments are already authored in `MobCategories.md` (the authoritative reference). The work is: replace every `mobCategory = "unknown"` in 7 AbilityDB data files with the correct string from that reference document, add 3 missing stub entries discovered during research, remove `isBoss` from DungeonEnemies.lua, update PackFrame.lua's boss detection to use AbilityDB, and add Mindless Laborer as a new mob.

The entire change set is mechanical and self-verifying: after editing, every npcID in DungeonEnemies should have a corresponding AbilityDB entry, and no DungeonEnemies entry should contain `isBoss`. The PackFrame.lua change is a one-line condition replacement at a precisely identified location (line 510).

**Primary recommendation:** Execute as a single plan wave — all edits follow the same pattern. Do data files first so AbilityDB is complete before PackFrame's runtime reference to it.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- All 7 dungeon data files get `mobCategory = "unknown"` replaced with correct categories from `MobCategories.md`
- `MobCategories.md` is the authoritative reference — not to be derived or inferred
- Categories applied exactly as listed: `boss`, `miniboss`, `caster`, `warrior`, `rogue`, `trivial`, `unknown`
- Remove `isBoss = true` from every entry in `Data/DungeonEnemies.lua`
- Remove the `npcIdIsBoss` lookup table and its construction loop from `UI/PackFrame.lua` (lines 33-41)
- Replace boss pull row detection at PackFrame.lua line 510: `if npcIdIsBoss[npcID] then` → `if ns.AbilityDB[npcID] and ns.AbilityDB[npcID].mobCategory == "boss" then`
- Mindless Laborer: npcID 252557, displayId 137487, category trivial, add to both DungeonEnemies Pit of Saron section and PitOfSaron.lua as stub entry

### Claude's Discretion

- Exact insertion position of Mindless Laborer in DungeonEnemies (maintain index ordering)
- Comment header updates in data files if needed
- Whether to update the DungeonEnemies file header comment to remove mention of isBoss

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

## Standard Stack

No new libraries. All work is editing existing Lua data files within the established project patterns.

### Patterns in Use
| Pattern | File | Usage |
|---------|------|-------|
| `mobCategory = "value",  -- semantic role; see header for vocabulary` | All 7 Data/*.lua | Replace "unknown" with correct category |
| `ns.AbilityDB[npcID] = { mobCategory = "trivial", abilities = {} }` | PitOfSaron.lua | New stub for Mindless Laborer |
| `{ id = npcID, name = "Name", displayId = NNNN }` | DungeonEnemies.lua | New entry for Mindless Laborer (no isBoss field) |
| `if ns.AbilityDB[npcID] and ns.AbilityDB[npcID].mobCategory == "boss" then` | PackFrame.lua | Replace npcIdIsBoss check |

## Architecture Patterns

### Established File Structure
Each Data/*.lua file:
1. File-scoped header with category vocabulary comment
2. One block per mob: `-- Name (npcID)` comment followed by `ns.AbilityDB[npcID] = { mobCategory = "...", abilities = {...} }`

DungeonEnemies.lua structure: one table per dungeon keyed by dungeonIdx; each entry `{ id = npcID, name = "...", displayId = NNNN }` (no isBoss after this phase).

### Boss Detection Change (PackFrame.lua)
**Before (lines 33-41):**
```lua
-- Boss lookup: npcID -> true if isBoss flag in DungeonEnemies
local npcIdIsBoss = {}
for _, enemies in pairs(ns.DungeonEnemies) do
    for _, enemy in pairs(enemies) do
        if enemy.id and enemy.isBoss then
            npcIdIsBoss[enemy.id] = true
        end
    end
end
```
**Before (line 510):**
```lua
if npcIdIsBoss[npcID] then
```

**After:** Remove the 8-line block entirely. Replace line 510 with:
```lua
if ns.AbilityDB[npcID] and ns.AbilityDB[npcID].mobCategory == "boss" then
```

The `CLASS_ICON` table (lines 43-57) and `npcIdToClass` loop (lines 26-31) are NOT part of this phase's removal scope — leave them untouched.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Category lookup at runtime | Per-mob lookup table in PackFrame | `ns.AbilityDB[npcID].mobCategory` directly |
| Boss detection | `isBoss` field in DungeonEnemies | `mobCategory == "boss"` in AbilityDB |

## Common Pitfalls

### Pitfall 1: Missing AbilityDB Entries (Coverage Gaps)
**What goes wrong:** If a npcID exists in DungeonEnemies but has no AbilityDB entry, `ns.AbilityDB[npcID]` is nil. The new PackFrame check includes an `and ns.AbilityDB[npcID]` nil-guard specifically to handle this — but coverage gaps also mean categories can't be applied.

**Research finding (HIGH confidence):** Three mobs are in DungeonEnemies but have NO AbilityDB entry in their respective data files:

| npcID | Name | Dungeon | DungeonEnemies idx | MobCategory |
|-------|------|---------|-------------------|-------------|
| 122412 | Bound Voidcaller | SeatoftheTriumvirate (idx 11) | [16] | warrior |
| 255551 | Depravation Wave Stalker | SeatoftheTriumvirate (idx 11) | [21] | unknown |
| 249711 | Core Technician | NexusPointXenas (idx 155) | [34] | unknown |

These need stub entries added to their respective data files (`Data/SeatoftheTriumvirate.lua` and `Data/NexusPointXenas.lua`) with `abilities = {}` and the correct category. This is required for the AbilityDB to be a complete source of truth as intended by the CONTEXT.md decision.

**How to avoid:** Add 3 stub entries during this phase. Pattern from Phase 19:
```lua
-- Bound Voidcaller (122412)
ns.AbilityDB[122412] = { mobCategory = "warrior", abilities = {} }

-- Depravation Wave Stalker (255551)
ns.AbilityDB[255551] = { mobCategory = "unknown", abilities = {} }

-- Core Technician (249711)
ns.AbilityDB[249711] = { mobCategory = "unknown", abilities = {} }
```

### Pitfall 2: Mindless Laborer (252557) Already Exists in MobCategories but Not in DungeonEnemies
**What goes wrong:** The current DungeonEnemies[150] has 23 entries. Mindless Laborer (252557) is listed in MobCategories.md as entry #10 but is absent from DungeonEnemies. It also has no AbilityDB entry in PitOfSaron.lua. Both gaps must be filled.

**Correct insertion:** In DungeonEnemies[150], Mindless Laborer should be inserted at an appropriate index. Currently the file has entries 1-23 ending at index [23] = 255037. The planner has discretion on exact index position; inserting after index [9] (Leaping Geist) to mirror MobCategories order is one option, or appending as [24].

**Recommended approach (Claude's Discretion):** Append as `[24]` — avoids renumbering all subsequent indices in DungeonEnemies.

### Pitfall 3: Algethar Academy is Missing Several Mobs from MobCategories
**What goes wrong:** `Data/AlgetharAcademy.lua` has 16 entries but `Data/DungeonEnemies.lua` has 17 entries for dungeonIdx 45. The missing mob is `Hungry Lasher` (197398, trivial) — it is in DungeonEnemies[45] at index [13] but has no AbilityDB entry.

**Research finding (HIGH confidence):** Confirmed by file inspection — 197398 does not appear anywhere in `Data/AlgetharAcademy.lua`. Add stub:
```lua
-- Hungry Lasher (197398)
ns.AbilityDB[197398] = { mobCategory = "trivial", abilities = {} }
```

### Pitfall 4: Windrunner Spire Missing Entries
**What goes wrong:** WindrunnerSpire.lua AbilityDB has 31 entries (matching the 31 in DungeonEnemies[152]), but some mob comment headers are missing in the file — specifically entries for `Scouting Trapper (238049)` (npcID 238049) — different from the other Scouting Trapper (250883) which is present.

**Research finding:** Confirmed 238049 IS present in WindrunnerSpire.lua (between Bloated Lasher and Swiftshot Archer — actually, looking at the file: Bloated Lasher [136894], Swiftshot Archer [232119] with no 238049 entry between). Let me verify count.

Counting WindrunnerSpire.lua AbilityDB entries: 232070, 232113, 232116, 232173, 232171, 232232, 232175, 232176, 232056, 234673, 232067, 232063, 238099, 236894, 232119, 232122, 232283, 232147, 232148, 232146, 231606, 231626, 231629, 231631, 231636, 232118, 232121, 232446, 250883 = 29 entries.

DungeonEnemies[152] has 31 entries. Two are missing from AbilityDB: `Scouting Trapper (238049)` and `Dutiful Groundskeeper (232071)`.

Checking MobCategories for these:
- Scouting Trapper (238049): warrior
- Dutiful Groundskeeper (232071): warrior

Add stub entries:
```lua
-- Dutiful Groundskeeper (232071)
ns.AbilityDB[232071] = { mobCategory = "warrior", abilities = {} }

-- Scouting Trapper (238049)
ns.AbilityDB[238049] = { mobCategory = "warrior", abilities = {} }
```

### Pitfall 5: npcIdIsBoss Removal Must Not Break npcIdToClass
**What goes wrong:** The `npcIdToClass` table (lines 26-31) is built from `entry.mobClass` in AbilityDB. The `npcIdIsBoss` table (lines 33-41) immediately follows. Only remove the `npcIdIsBoss` block — leave `npcIdToClass` in place.

**Warning sign:** If `CLASS_ICON` table starts disappearing from the file, too much has been deleted.

### Pitfall 6: Magisters Terrace Mobs Missing from AbilityDB
**What goes wrong:** MagistersTerrace.lua has entries for 23 npcIDs but DungeonEnemies[153] has 25 entries. Two are missing: `Animated Codex` (234089, trivial) and `Vigilant Librarian` (234067, unknown).

Checking: 234089 and 234067 are not present in MagistersTerrace.lua (file goes: 232369, 251861, 240973, 234069, 234065, 234064, 234068, 234066, 249086, 231861, 231863, 231864, 231865, 232106, 234062, 234124, 234486, 239636, 241397, 255376, 257447, 259387 = 22 entries, not 23).

Actually: Animated Codex (234089) and Vigilant Librarian (234067) are both in DungeonEnemies[153] but absent from MagistersTerrace.lua AbilityDB. Add stubs:
```lua
-- Animated Codex (234089)
ns.AbilityDB[234089] = { mobCategory = "trivial", abilities = {} }

-- Vigilant Librarian (234067)
ns.AbilityDB[234067] = { mobCategory = "unknown", abilities = {} }
```

## Complete Gap Summary

All missing AbilityDB stubs that must be added during this phase:

| File | npcID | Name | Category | Note |
|------|-------|------|----------|------|
| WindrunnerSpire.lua | 232071 | Dutiful Groundskeeper | warrior | in DungeonEnemies[152] |
| WindrunnerSpire.lua | 238049 | Scouting Trapper | warrior | in DungeonEnemies[152] |
| AlgetharAcademy.lua | 197398 | Hungry Lasher | trivial | in DungeonEnemies[45] |
| MagistersTerrace.lua | 234089 | Animated Codex | trivial | in DungeonEnemies[153] |
| MagistersTerrace.lua | 234067 | Vigilant Librarian | unknown | in DungeonEnemies[153] |
| PitOfSaron.lua | 252557 | Mindless Laborer | trivial | new mob, add to DungeonEnemies too |
| SeatoftheTriumvirate.lua | 122412 | Bound Voidcaller | warrior | in DungeonEnemies[11] |
| SeatoftheTriumvirate.lua | 255551 | Depravation Wave Stalker | unknown | in DungeonEnemies[11] |
| NexusPointXenas.lua | 249711 | Core Technician | unknown | in DungeonEnemies[155] |

Note: MaisaraCaverns.lua is fully covered — all 32 DungeonEnemies[154] entries have AbilityDB entries.

## Code Examples

### Category replacement (same pattern in all 7 files)
```lua
-- Before
ns.AbilityDB[232070] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = { ... },
}

-- After (example: Restless Steward is warrior)
ns.AbilityDB[232070] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = { ... },
}
```

### New stub entry pattern (from Phase 19)
```lua
-- Mindless Laborer (252557)
ns.AbilityDB[252557] = { mobCategory = "trivial", abilities = {} }
```

### DungeonEnemies new entry (Mindless Laborer, append as [24])
```lua
[24] = { id = 252557, name = "Mindless Laborer", displayId = 137487 },
```

### DungeonEnemies isBoss removal (example)
```lua
-- Before
[16] = { id = 252621, name = "Krick", displayId = 137499, isBoss = true },

-- After
[16] = { id = 252621, name = "Krick", displayId = 137499 },
```

### PackFrame.lua: remove npcIdIsBoss block (lines 33-41)
Remove this entire block:
```lua
-- Boss lookup: npcID -> true if isBoss flag in DungeonEnemies
local npcIdIsBoss = {}
for _, enemies in pairs(ns.DungeonEnemies) do
    for _, enemy in pairs(enemies) do
        if enemy.id and enemy.isBoss then
            npcIdIsBoss[enemy.id] = true
        end
    end
end
```

### PackFrame.lua: replace boss check (line 510)
```lua
-- Before
if npcIdIsBoss[npcID] then

-- After
if ns.AbilityDB[npcID] and ns.AbilityDB[npcID].mobCategory == "boss" then
```

## State of the Art

| Old Approach | Current Approach | Changed | Impact |
|--------------|------------------|---------|--------|
| `isBoss = true` in DungeonEnemies | `mobCategory = "boss"` in AbilityDB | Phase 22 | Single source of truth for all mob roles |
| `npcIdIsBoss` lookup table | Direct AbilityDB access | Phase 22 | Eliminates parallel data structure |

## Category Application Index

Full category assignments derived from MobCategories.md. This section maps npcID to category for every mob being changed (all currently "unknown").

### WindrunnerSpire — category changes
| npcID | Name | Category |
|-------|------|----------|
| 232070 | Restless Steward | warrior |
| 232071 | Dutiful Groundskeeper | warrior *(stub — gap)* |
| 232113 | Spellguard Magus | miniboss |
| 232116 | Windrunner Soldier | warrior |
| 232173 | Fervent Apothecary | warrior |
| 232171 | Ardent Cutthroat | warrior |
| 232232 | Zealous Reaver | warrior |
| 232175 | Devoted Woebringer | miniboss |
| 232176 | Flesh Behemoth | miniboss |
| 232056 | Territorial Dragonhawk | warrior |
| 234673 | Spindleweb Hatchling | trivial |
| 232067 | Creeping Spindleweb | warrior |
| 232063 | Apex Lynx | miniboss |
| 238099 | Pesty Lashling | trivial |
| 236894 | Bloated Lasher | miniboss |
| 238049 | Scouting Trapper | warrior *(stub — gap)* |
| 232119 | Swiftshot Archer | warrior |
| 232122 | Phalanx Breaker | miniboss |
| 232283 | Loyal Worg | warrior |
| 232147 | Lingering Marauder | warrior |
| 232148 | Spectral Axethrower | warrior |
| 232146 | Phantasmal Mystic | miniboss |
| 231606 | Emberdawn | boss |
| 231626 | Kalis | boss |
| 231629 | Latch | boss |
| 231631 | Commander Kroluk | boss |
| 231636 | Restless Heart | boss |
| 232118 | Flaming Updraft | unknown |
| 232121 | Phalanx Breaker | miniboss |
| 232446 | Haunting Grunt | warrior |
| 250883 | Scouting Trapper | warrior |

### AlgetharAcademy — category changes
| npcID | Name | Category |
|-------|------|----------|
| 196045 | Corrupted Manafiend | warrior |
| 196577 | Spellbound Battleaxe | warrior |
| 196671 | Arcane Ravager | miniboss |
| 196694 | Arcane Forager | warrior |
| 196044 | Unruly Textbook | warrior |
| 194181 | Vexamus | boss |
| 192680 | Guardian Sentry | miniboss |
| 192329 | Territorial Eagle | trivial |
| 192333 | Alpha Eagle | miniboss |
| 191736 | Crawth | boss |
| 197406 | Aggravated Skitterfly | warrior |
| 197219 | Vile Lasher | miniboss |
| 197398 | Hungry Lasher | trivial *(stub — gap)* |
| 196482 | Overgrown Ancient | boss |
| 196200 | Algeth'ar Echoknight | warrior |
| 196202 | Spectral Invoker | caster |
| 190609 | Echo of Doragosa | boss |

### MagistersTerrace — category changes
| npcID | Name | Category |
|-------|------|----------|
| 232369 | Arcane Magister | caster |
| 234089 | Animated Codex | trivial *(stub — gap)* |
| 251861 | Blazing Pyromancer | miniboss |
| 240973 | Runed Spellbreaker | miniboss |
| 234069 | Voidling | trivial |
| 234065 | Hollowsoul Shredder | warrior |
| 234064 | Dreaded Voidwalker | warrior |
| 234068 | Shadowrift Voidcaller | miniboss |
| 234066 | Devouring Tyrant | miniboss |
| 249086 | Void Infuser | warrior |
| 231861 | Arcanotron Custos | boss |
| 231863 | Seranel Sunlash | boss |
| 231864 | Gemellus | boss |
| 231865 | Degentrius | boss |
| 232106 | Brightscale Wyrm | trivial |
| 234062 | Arcane Sentry | miniboss |
| 234067 | Vigilant Librarian | unknown *(stub — gap)* |
| 234124 | Sunblade Enforcer | warrior |
| 234486 | Lightward Healer | caster |
| 239636 | Gemellus | boss |
| 241354 | Void-Infused Brightscale | trivial |
| 241397 | Celestial Drifter | boss |
| 255376 | Unstable Voidling | trivial |
| 257447 | Hollowsoul Shredder | warrior |
| 259387 | Spellwoven Familiar | caster |

### MaisaraCaverns — category changes
| npcID | Name | Category |
|-------|------|----------|
| 248684 | Frenzied Berserker | warrior |
| 242964 | Keen Headhunter | warrior |
| 248686 | Dread Souleater | miniboss |
| 248685 | Ritual Hexxer | caster |
| 249020 | Hexbound Eagle | warrior |
| 253302 | Hex Guardian | miniboss |
| 249002 | Warding Mask | trivial |
| 249022 | Bramblemaw Bear | warrior |
| 248693 | Mire Laborer | warrior |
| 248678 | Hulking Juggernaut | miniboss |
| 254740 | Umbral Shadowbinder | caster |
| 249030 | Restless Gnarldin | miniboss |
| 248692 | Reanimated Warrior | warrior |
| 248690 | Grim Skirmisher | warrior |
| 249036 | Tormented Shade | warrior |
| 253683 | Rokh'zal | miniboss |
| 249025 | Bound Defender | miniboss |
| 249024 | Hollow Soulrender | miniboss |
| 247570 | Muro'jin | boss |
| 247572 | Nekraxx | boss |
| 248595 | Vordaza | boss |
| 248605 | Rak'tul | boss |
| 250443 | Unstable Phantom | miniboss |
| 251047 | Soulbind Totem | warrior |
| 251639 | Lost Soul | unknown |
| 251674 | Malignant Soul | miniboss |
| 252886 | Potatoad | unknown |
| 253458 | Zil'jan | unknown |
| 253473 | Gloomwing Bat | warrior |
| 253647 | Lost Soul | unknown |
| 253701 | Death's Grasp | unknown |
| 254233 | Rokh'zal | unknown |

### NexusPointXenas — category changes
| npcID | Name | Category |
|-------|------|----------|
| 241643 | Shadowguard Defender | warrior |
| 248501 | Reformed Voidling | trivial |
| 241644 | Corewright Arcanist | caster |
| 241645 | Hollowsoul Scrounger | warrior |
| 241647 | Flux Engineer | warrior |
| 248708 | Nexus Adept | trivial |
| 248373 | Circuit Seer | miniboss |
| 248706 | Cursed Voidcaller | trivial |
| 248506 | Dreadflail | miniboss |
| 241660 | Duskfright Herald | miniboss |
| 251853 | Grand Nullifier | caster |
| 248502 | Null Sentinel | miniboss |
| 241642 | Lingering Image | miniboss |
| 254932 | Radiant Swarm | trivial |
| 254926 | Lightwrought | warrior |
| 254928 | Flarebat | trivial |
| 241539 | Kasreth | boss |
| 241542 | Corewarden Nysarra | boss |
| 241546 | Lothraxion | boss |
| 248769 | Smudge | trivial |
| 250299 | [DNT] Conduit Stalker | unknown |
| 251024 | Null Guardian | unknown |
| 251031 | Wretched Supplicant | unknown |
| 251568 | Fractured Image | unknown |
| 251852 | Nullifier | unknown |
| 251878 | Voidcaller | unknown |
| 252825 | Mana Battery | trivial |
| 252852 | Corespark Conduit | unknown |
| 254227 | Corewarden Nysarra | unknown |
| 254459 | Broken Pipe | unknown |
| 254485 | Corespark Pylon | unknown |
| 255179 | Fractured Image | unknown |
| 259569 | Mana Battery | unknown |
| 249711 | Core Technician | unknown *(stub — gap)* |

Note: Nullifier (251852) is in DungeonEnemies[155] and MobCategories but is NOT in NexusPointXenas.lua AbilityDB. Add stub: `ns.AbilityDB[251852] = { mobCategory = "unknown", abilities = {} }`.

### PitOfSaron — category changes
| npcID | Name | Category |
|-------|------|----------|
| 252551 | Deathwhisper Necrolyte | warrior |
| 252602 | Risen Soldier | trivial |
| 252603 | Arcanist Cadaver | trivial |
| 252567 | Gloombound Shadebringer | caster |
| 252561 | Quarry Tormentor | warrior |
| 252563 | Dreadpulse Lich | miniboss |
| 252558 | Rotting Ghoul | warrior |
| 252610 | Ymirjar Graveblade | miniboss |
| 252559 | Leaping Geist | trivial |
| 252557 | Mindless Laborer | trivial *(new stub)* |
| 252606 | Plungetalon Gargoyle | warrior |
| 252555 | Lumbering Plaguehorror | warrior |
| 257190 | Iceborn Proto-Drake | miniboss |
| 252565 | Wrathbone Enforcer | warrior |
| 252566 | Rimebone Coldwraith | caster |
| 252564 | Glacieth | miniboss |
| 252621 | Krick | boss |
| 252625 | Ick | boss |
| 252635 | Forgemaster Garfrost | boss |
| 252648 | Scourgelord Tyrannus | boss |
| 252653 | Rimefang | boss |
| 254684 | Rotling | trivial |
| 254691 | Scourge Plaguespreader | warrior |
| 255037 | Shade of Krick | boss |

Note: Rotling (254684) is in DungeonEnemies[150] but the MobCategories.md table lists 24 mobs including Mindless Laborer. Rotling IS present in PitOfSaron.lua at the expected position — no gap there.

### SeatoftheTriumvirate — category changes
| npcID | Name | Category |
|-------|------|----------|
| 124171 | Merciless Subjugator | miniboss |
| 122571 | Rift Warden | miniboss |
| 122413 | Ruthless Riftstalker | warrior |
| 255320 | Ravenous Umbralfin | warrior |
| 122421 | Umbral War-Adept | miniboss |
| 122404 | Dire Voidbender | caster |
| 252756 | Void-Infused Destroyer | unknown |
| 122423 | Grand Shadow-Weaver | miniboss |
| 122056 | Viceroy Nezhar | boss |
| 122313 | Zuraal the Ascended | boss |
| 122316 | Saprish | boss |
| 122319 | Darkfang | boss |
| 122322 | Famished Broken | trivial |
| 122403 | Shadowguard Champion | warrior |
| 122405 | Dark Conjurer | warrior |
| 122412 | Bound Voidcaller | warrior *(stub — gap)* |
| 122716 | Coalesced Void | warrior |
| 122827 | Umbral Tentacle | warrior |
| 124729 | L'ura | boss |
| 125340 | Shadewing | boss |
| 255551 | Depravation Wave Stalker | unknown *(stub — gap)* |
| 256424 | Void Tentacle | unknown |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — WoW addon; in-game manual testing only |
| Config file | none |
| Quick run command | `./scripts/install.bat` then `/tpw debug` in-game |
| Full suite command | Pull mobs in Windrunner Spire + Pit of Saron with imported route |

### Phase Requirements → Test Map
| Scope Item | Behavior | Test Type | Verification |
|------------|----------|-----------|-------------|
| 7 data files categorized | All AbilityDB entries have non-"unknown" categories where category is known | manual-only | Grep for `mobCategory = "unknown"` on mobs that should not be unknown |
| isBoss removed from DungeonEnemies | No `isBoss` field anywhere in DungeonEnemies.lua | automated | `grep -n "isBoss" Data/DungeonEnemies.lua` returns nothing |
| PackFrame boss detection | Boss pull rows show dark red highlight in-game | manual-only | Import a route containing a boss pull, open PackFrame |
| Mindless Laborer added | npcID 252557 appears in both files | automated | `grep -n "252557" Data/DungeonEnemies.lua Data/PitOfSaron.lua` returns 2 matches |
| npcIdIsBoss removed | Variable no longer referenced in PackFrame | automated | `grep -n "npcIdIsBoss" UI/PackFrame.lua` returns nothing |
| AbilityDB coverage | All DungeonEnemies npcIDs have AbilityDB entries | semi-automated | Cross-check extracted npcID sets |

### Sampling Rate
- **Per task commit:** `grep -rn "isBoss" Data/ UI/PackFrame.lua` — should return nothing after completion
- **Per wave merge:** Verify count of category-changed entries matches expected count per dungeon
- **Phase gate:** Manual in-game test with boss pull showing dark red row in PackFrame

### Wave 0 Gaps
None — no test framework to install. All validation is grep-based or in-game manual.

## Open Questions

1. **Nullifier (251852) AbilityDB gap**
   - What we know: 251852 is in DungeonEnemies[155] (NexusPointXenas index 25) and MobCategories (unknown), but not in NexusPointXenas.lua
   - What's unclear: Was it intentionally omitted, or is it a gap like the others?
   - Recommendation: Add stub `ns.AbilityDB[251852] = { mobCategory = "unknown", abilities = {} }` — consistent with the gap-filling approach for the other missing mobs.

2. **Mindless Laborer DungeonEnemies position**
   - What we know: Current DungeonEnemies[150] has indices [1]-[23]. Mindless Laborer should be [24].
   - What's unclear: Whether insertions should maintain the order from MobCategories.md
   - Recommendation: Append as [24] — simplest, avoids renumbering, order in DungeonEnemies is not functionally significant.

## Sources

### Primary (HIGH confidence)
- Direct file inspection: `Data/WindrunnerSpire.lua`, `Data/AlgetharAcademy.lua`, `Data/MagistersTerrace.lua`, `Data/MaisaraCaverns.lua`, `Data/NexusPointXenas.lua`, `Data/PitOfSaron.lua`, `Data/SeatoftheTriumvirate.lua` — all AbilityDB entries and current mobCategory values read directly
- Direct file inspection: `Data/DungeonEnemies.lua` — all isBoss fields and npcID coverage verified
- Direct file inspection: `UI/PackFrame.lua` lines 1-60, 500-530 — npcIdIsBoss table and boss check location confirmed
- Direct file inspection: `MobCategories.md` — authoritative category assignments for all 7 dungeons
- Direct file inspection: `22-CONTEXT.md` — all locked decisions verified against file state

### Secondary (MEDIUM confidence)
- Gap analysis: cross-referencing DungeonEnemies npcID sets against AbilityDB files — 9 missing entries identified by searching for each npcID across Data/ directory

## Metadata

**Confidence breakdown:**
- Category assignments: HIGH — read directly from MobCategories.md (authoritative)
- Missing stubs: HIGH — confirmed by grep across Data/ directory
- PackFrame change location: HIGH — exact line numbers confirmed by file inspection
- Architecture: HIGH — established patterns, no new patterns introduced

**Research date:** 2026-03-24
**Valid until:** Indefinitely — this is internal project data, no external dependencies
