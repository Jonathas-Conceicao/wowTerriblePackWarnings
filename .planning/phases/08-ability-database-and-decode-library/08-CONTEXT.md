# Phase 8: Ability Database and Decode Library - Context

**Gathered:** 2026-03-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Create an npcID-keyed ability database for Windrunner Spire mobs and bundle LibDeflate + AceSerializer for MDT string decoding. Remove hardcoded pack data — addon won't have packs until Phase 9 import pipeline.

</domain>

<decisions>
## Implementation Decisions

### Ability Database Structure
- **Per-dungeon files**: Data/WindrunnerSpire.lua becomes an npcID → abilities mapping (not hardcoded packs)
- **npcID is the primary key**: each npcID maps to `{ mobClass, abilities = { ... } }`
- **mobClass stored per-npcID** (not per-ability): e.g. npcID 232113 → mobClass "PALADIN", abilities have cooldown/label/tts/spellID
- **Multiple npcIDs can share same ability**: 232122 and 232121 both have Interrupting Screech
- **Remove hardcoded pack data**: WindrunnerSpire.lua no longer populates PackDatabase with packs — just registers ability data
- Data lives in a new namespace table: `ns.AbilityDB[npcID] = { mobClass, abilities }`

### NPC-to-Ability Mapping (Windrunner Spire)
| NPC ID | MobClass | Abilities |
|--------|----------|-----------|
| 232113 | PALADIN | Spellguard's Protection (1253686, 50s/50s, label="DR", tts="Shield") |
| 232070 | WARRIOR | Spirit Bolt (1216135, untimed, label="Bolt") |
| 236891 | WARRIOR | Fire Spit (1216848, untimed, label="DMG") |
| 232056 | WARRIOR | Fire Spit (1216848, untimed, label="DMG") |
| 232122 | PALADIN | Interrupting Screech (471643, 20s/25s, label="Kick", tts="Stop Casting") |
| 232121 | PALADIN | Interrupting Screech (471643, 20s/25s, label="Kick", tts="Stop Casting") |

### Library Bundling
- Follow **MDT's own pattern**: LibStub + .pkgmeta externals
- Bundle **AceSerializer-3.0** (not LibSerialize) + **LibDeflate**
- Libs declared as externals in .pkgmeta so BigWigsMods packager fetches them on release
- For local dev: copy lib files into Libs/ folder manually (install.bat or git submodule)
- TOC file lists lib files before addon files (LibStub first, then libs, then addon code)

### Decode Function
- Create a decode utility module that takes an MDT export string → returns raw Lua table
- Handles the `!` prefix detection (modern compression format)
- Chain: string → LibDeflate decode → LibDeflate decompress → AceSerializer deserialize → Lua table
- Expose via `ns.MDTDecode(exportString)` returning `(success, data)` or `(false, errorMsg)`

### Claude's Discretion
- Exact Libs/ folder structure and TOC ordering
- Whether to use LibStub-1.0 from .pkgmeta or embed directly
- Decode module file name and location (e.g. Libs/MDTDecode.lua or Import/Decode.lua)
- How to handle legacy MDT strings (without `!` prefix)

</decisions>

<specifics>
## Specific Ideas

- The AbilityDB should be simple enough that adding a new dungeon is just adding a new data file that registers npcIDs
- The decode function should be tested via `/tpw decode <string>` slash command for development
- Reference: MDT's Transmission.lua shows the exact encode/decode chain

</specifics>

<code_context>
## Existing Code Insights

### Files to Modify
- `Data/WindrunnerSpire.lua`: Replace hardcoded packs with npcID → ability registration
- `TerriblePackWarnings.toc`: Add Libs entries before addon files
- `.pkgmeta`: Add external library declarations

### Files to Create
- `Libs/` folder with LibStub, AceSerializer-3.0, LibDeflate
- Decode utility module (new file)
- `ns.AbilityDB` initialization (likely in Core.lua or new Data/init.lua)

### Established Patterns
- `local addonName, ns = ...` namespace
- Data files populate namespace tables at load time
- `scripts/install.bat` copies files to WoW AddOns folder

### Integration Points
- Phase 9 import pipeline will call `ns.MDTDecode(string)` to get raw data
- Phase 9 will iterate decoded pulls and look up `ns.AbilityDB[npcID]` to build packs
- NameplateScanner still reads `ability.mobClass` — this field is now inherited from the npcID entry

### Reference Code
- MDT Transmission.lua (C:\Users\jonat\Repositories\MythicDungeonTools\Modules\Transmission.lua) — decode chain
- MDT .pkgmeta — external lib declarations

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-ability-database-and-decode-library*
*Context gathered: 2026-03-16*
