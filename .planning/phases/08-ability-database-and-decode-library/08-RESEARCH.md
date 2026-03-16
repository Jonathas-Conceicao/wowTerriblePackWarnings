# Phase 8: Ability Database and Decode Library - Research

**Researched:** 2026-03-16
**Domain:** WoW Addon library bundling (LibStub/LibDeflate/AceSerializer) + Lua data structure design
**Confidence:** HIGH

## Summary

This phase has two independent work streams: (1) replace the hardcoded pack data in WindrunnerSpire.lua with an npcID-keyed ability database, and (2) bundle LibDeflate + AceSerializer and expose a decode utility. Both are well-understood from reading MDT's own source code directly — no speculation is needed.

The decode chain is fully documented in MDT's Transmission.lua. The `!` prefix detection, the LibDeflate `EncodeForPrint`/`DecodeForPrint` + `CompressDeflate`/`DecompressDeflate` API, and AceSerializer `Serialize`/`Deserialize` are all verified from live source. MDT does NOT use LibCompress for the modern (`!`-prefixed) format — legacy strings used LibCompress, but all current MDT exports use LibDeflate.

Library bundling follows MDT's exact pattern: LibStub first, then AceSerializer-3.0, then LibDeflate, all declared as `.pkgmeta` externals and listed in a `Libs/load_libs.xml` file referenced from the TOC. Our current `.pkgmeta` has no `externals` section and our TOC lists no Libs — both need updating.

**Primary recommendation:** Copy LibDeflate.lua from MDT's `libs/LibDeflate/` directly into our `Libs/LibDeflate/`. Fetch LibStub and AceSerializer-3.0 from CurseForge SVN. Follow MDT's XML include pattern for TOC ordering.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Per-dungeon files**: Data/WindrunnerSpire.lua becomes an npcID → abilities mapping (not hardcoded packs)
- **npcID is the primary key**: each npcID maps to `{ mobClass, abilities = { ... } }`
- **mobClass stored per-npcID** (not per-ability): e.g. npcID 232113 → mobClass "PALADIN", abilities have cooldown/label/tts/spellID
- **Multiple npcIDs can share same ability**: 232122 and 232121 both have Interrupting Screech
- **Remove hardcoded pack data**: WindrunnerSpire.lua no longer populates PackDatabase with packs — just registers ability data
- Data lives in a new namespace table: `ns.AbilityDB[npcID] = { mobClass, abilities }`
- Follow **MDT's own pattern**: LibStub + .pkgmeta externals
- Bundle **AceSerializer-3.0** (not LibSerialize) + **LibDeflate**
- Libs declared as externals in .pkgmeta so BigWigsMods packager fetches them on release
- For local dev: copy lib files into Libs/ folder manually (install.bat or git submodule)
- TOC file lists lib files before addon files (LibStub first, then libs, then addon code)
- Create a decode utility module that takes an MDT export string → returns raw Lua table
- Handles the `!` prefix detection (modern compression format)
- Chain: string → LibDeflate decode → LibDeflate decompress → AceSerializer deserialize → Lua table
- Expose via `ns.MDTDecode(exportString)` returning `(success, data)` or `(false, errorMsg)`

### NPC-to-Ability Mapping (Windrunner Spire — locked)
| NPC ID | MobClass | Abilities |
|--------|----------|-----------|
| 232113 | PALADIN | Spellguard's Protection (1253686, 50s/50s, label="DR", tts="Shield") |
| 232070 | WARRIOR | Spirit Bolt (1216135, untimed, label="Bolt") |
| 236891 | WARRIOR | Fire Spit (1216848, untimed, label="DMG") |
| 232056 | WARRIOR | Fire Spit (1216848, untimed, label="DMG") |
| 232122 | PALADIN | Interrupting Screech (471643, 20s/25s, label="Kick", tts="Stop Casting") |
| 232121 | PALADIN | Interrupting Screech (471643, 20s/25s, label="Kick", tts="Stop Casting") |

### Claude's Discretion
- Exact Libs/ folder structure and TOC ordering
- Whether to use LibStub-1.0 from .pkgmeta or embed directly
- Decode module file name and location (e.g. Libs/MDTDecode.lua or Import/Decode.lua)
- How to handle legacy MDT strings (without `!` prefix)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DATA-10 | Ability database keyed by npcID — each npcID maps to its spells with cooldown, label, tts, mobClass | AbilityDB structure documented below; WindrunnerSpire.lua rewrite pattern provided |
| DATA-11 | Multiple npcIDs can share the same ability (e.g. 232122 and 232121 both have Interrupting Screech) | Each npcID gets its own entry in AbilityDB; shared ability data is duplicated by value (simple and explicit) |
| IMPORT-01 | Decode MDT export strings using LibDeflate + AceSerializer (bundled following MDT's own pattern) | Exact decode chain verified from MDT Transmission.lua; library sources and pkgmeta URLs documented |
</phase_requirements>

---

## Standard Stack

### Core Libraries
| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| LibStub | 1.0 | Library version registry used by LibDeflate and AceSerializer | CurseForge SVN: `https://repos.curseforge.com/wow/libstub/trunk` |
| LibDeflate | 1.0.2-release | DEFLATE compression/decompression + print-safe encoding | CurseForge or copy from MDT: `libs/LibDeflate/LibDeflate.lua` |
| AceSerializer-3.0 | current trunk | Lua table serialization/deserialization | CurseForge SVN: `https://repos.curseforge.com/wow/ace3/trunk/AceSerializer-3.0` |

### What MDT Actually Uses (Verified from Source)
MDT's `pkgmeta.yaml` declares both `LibCompress` and `LibDeflate`. The modern `!`-prefixed export strings use **LibDeflate only**. LibCompress handles legacy (non-`!`) strings. We only need to decode modern strings, so **LibCompress is not required**.

MDT does NOT use a `.pkgmeta` file — it uses `pkgmeta.yaml`. Both formats are accepted by the BigWigsMods packager. Our existing `.pkgmeta` (no extension) is correct format.

### Installation (local dev)
```
Libs/
  LibStub/
    LibStub.lua
  AceSerializer-3.0/
    AceSerializer-3.0.lua
    AceSerializer-3.0.xml   (optional — the .lua file is self-contained)
  LibDeflate/
    LibDeflate.lua
  load_libs.xml
```

Lib files can be obtained by:
1. Copying LibDeflate.lua directly from `C:\Users\jonat\Repositories\MythicDungeonTools\libs\LibDeflate\LibDeflate.lua`
2. Checking out LibStub and AceSerializer-3.0 from the CurseForge SVN URLs above
3. install.bat must be updated to copy the Libs/ folder tree

## Architecture Patterns

### Recommended Project Structure After Phase 8
```
TerriblePackWarnings/
  .pkgmeta                 # add externals: section
  TerriblePackWarnings.toc # add Libs/load_libs.xml before Core.lua
  Core.lua                 # add ns.AbilityDB = {} initialization
  Libs/
    load_libs.xml          # XML include file: LibStub, AceSerializer, LibDeflate
    LibStub/
      LibStub.lua
    AceSerializer-3.0/
      AceSerializer-3.0.lua
    LibDeflate/
      LibDeflate.lua
  Import/
    Decode.lua             # ns.MDTDecode — the decode utility
  Data/
    WindrunnerSpire.lua    # rewritten: npcID → abilities, no packs
  Engine/
    ...
```

### Pattern 1: AbilityDB Registration
**What:** Data files populate `ns.AbilityDB` at load time with npcID keys. Each entry stores `mobClass` once at the npcID level, and a list of ability descriptors.
**When to use:** Every dungeon data file follows this pattern.

```lua
-- Source: CONTEXT.md decisions + existing project pattern
local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

ns.AbilityDB[232113] = {
    mobClass = "PALADIN",
    abilities = {
        {
            name       = "Spellguard's Protection",
            spellID    = 1253686,
            first_cast = 50,
            cooldown   = 50,
            label      = "DR",
            ttsMessage = "Shield",
        },
    },
}

ns.AbilityDB[232070] = {
    mobClass = "WARRIOR",
    abilities = {
        {
            name   = "Spirit Bolt",
            spellID = 1216135,
            label  = "Bolt",
            -- no first_cast, no cooldown = untimed
        },
    },
}

-- Shared ability: both npcIDs get their own entry (data is duplicated by value)
ns.AbilityDB[232122] = {
    mobClass = "PALADIN",
    abilities = {
        {
            name       = "Interrupting Screech",
            spellID    = 471643,
            first_cast = 20,
            cooldown   = 25,
            label      = "Kick",
            ttsMessage = "Stop Casting",
        },
    },
}

ns.AbilityDB[232121] = {
    mobClass = "PALADIN",
    abilities = {
        {
            name       = "Interrupting Screech",
            spellID    = 471643,
            first_cast = 20,
            cooldown   = 25,
            label      = "Kick",
            ttsMessage = "Stop Casting",
        },
    },
}
```

### Pattern 2: MDT Decode Chain
**What:** Exact decode chain verified from MDT `Modules/Transmission.lua` lines 205-238.
**When to use:** `ns.MDTDecode(exportString)` for any string pasted from MDT or Keystone.guru.

```lua
-- Source: MDT Modules/Transmission.lua:205-238 (verified)
-- "fromChat" is true for paste-style strings (EncodeForPrint was used on encode)

local function MDTDecode(inString)
    -- Step 1: detect modern vs legacy format
    local encoded, usesDeflate = inString:gsub("^%!", "")
    -- usesDeflate == 1 means "!" was stripped (modern format)
    -- usesDeflate == 0 means no "!" prefix (legacy LibCompress format)

    if usesDeflate ~= 1 then
        return false, "Legacy MDT format (no ! prefix) not supported"
    end

    -- Step 2: decode the print-safe encoding
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then
        return false, "Error decoding (DecodeForPrint returned nil)"
    end

    -- Step 3: decompress
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return false, "Error decompressing (DecompressDeflate returned nil)"
    end

    -- Step 4: deserialize
    local success, data = AceSerializer:Deserialize(decompressed)
    if not success then
        return false, "Error deserializing: " .. tostring(data)
    end

    return true, data
end
```

**Key insight on fromChat:** MDT's `TableToString` uses `EncodeForPrint` when `forChat = true`. MDT export strings pasted into the UI are always created with `forChat = true`, so `DecodeForPrint` is the correct decoder. `EncodeForWoWAddonChannel`/`DecodeForWoWAddonChannel` are for in-game addon channel messages only.

### Pattern 3: TOC + XML Include Ordering
**What:** TOC references `Libs/load_libs.xml` before any addon Lua files. XML file lists libs in dependency order: LibStub first (required by LibDeflate and AceSerializer), then AceSerializer, then LibDeflate.
**When to use:** Required for LibStub-based libraries to register correctly.

```xml
<!-- Libs/load_libs.xml — verified pattern from MDT libs/load_libs.xml -->
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file='LibStub\LibStub.lua'/>
    <Script file='AceSerializer-3.0\AceSerializer-3.0.lua'/>
    <Script file='LibDeflate\LibDeflate.lua'/>
</Ui>
```

```
# TerriblePackWarnings.toc addition (before Core.lua)
Libs\load_libs.xml
Core.lua
...
```

### Pattern 4: pkgmeta externals
**What:** BigWigsMods packager reads `externals:` section and checks out SVN/git repos into the specified local paths during release packaging.
**When to use:** Required for any bundled library to be included in CurseForge/WoWInterface releases.

```yaml
# .pkgmeta additions
externals:
  Libs/LibStub: https://repos.curseforge.com/wow/libstub/trunk
  Libs/AceSerializer-3.0: https://repos.curseforge.com/wow/ace3/trunk/AceSerializer-3.0
  Libs/LibDeflate: https://repos.curseforge.com/wow/libdeflate/trunk
```

Note: LibDeflate's CurseForge project slug needs verification — MDT stores it as `libs/LibDeflate` in their yaml without an explicit SVN URL (only showing the local path in `libs/`). Copying the file directly into source control is the safest approach for local dev.

### Pattern 5: LibStub GetLibrary call
**What:** After loading, libraries are accessed via LibStub.
**When to use:** In the decode module, acquire library handles at file scope.

```lua
-- Source: MDT Modules/Transmission.lua:3-6 (verified)
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
```

### Anti-Patterns to Avoid
- **Storing mobClass per-ability instead of per-npcID:** The locked decision puts mobClass on the npcID entry. Do not carry it into individual ability records in AbilityDB.
- **Using LibCompress for modern strings:** LibCompress is the legacy path. Modern `!`-prefixed strings use LibDeflate exclusively. Do not include LibCompress.
- **Using EncodeForWoWAddonChannel for paste strings:** Chat-pasted MDT exports always use EncodeForPrint. The addon channel codec is for party/raid comm messages.
- **Adding AbilityDB packs alongside the npcID data:** Phase 8 removes packs from data files entirely. Packs are built in Phase 9 from imported routes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DEFLATE compression/decompression | Custom decompressor | LibDeflate | DEFLATE is complex; MDT's export format is byte-for-byte defined by LibDeflate's codec |
| Lua table serialization | Custom serializer | AceSerializer-3.0 | AceSerializer handles type fidelity (numbers vs strings, nested tables, booleans) correctly |
| Library version management | Manual require/dofile | LibStub | Prevents double-loading when multiple addons bundle same lib |
| Print-safe encoding | Custom base64 | LibDeflate:EncodeForPrint / DecodeForPrint | MDT's specific 6-bit codec — must use exact same encoder/decoder pair |

**Key insight:** The `!` format is a contract. MDT's encode chain is: Serialize → CompressDeflate → EncodeForPrint → prepend `!`. Our decode chain must invert exactly: strip `!` → DecodeForPrint → DecompressDeflate → Deserialize. Any deviation produces garbage.

## Common Pitfalls

### Pitfall 1: Wrong decode path for paste strings
**What goes wrong:** Using `DecodeForWoWAddonChannel` instead of `DecodeForPrint` produces nil — string silently fails to decode.
**Why it happens:** LibDeflate has two separate codec pairs. `EncodeForPrint` is for copy-paste sharing; `EncodeForWoWAddonChannel` is for in-game comms. They are NOT interchangeable.
**How to avoid:** All MDT "Share" button exports use `EncodeForPrint` (MDT's `forChat = true` path). Always use `DecodeForPrint` for user-pasted strings.
**Warning signs:** `DecodeForPrint` returns nil even though string looks valid.

### Pitfall 2: LibStub not loaded before dependent libraries
**What goes wrong:** LibDeflate or AceSerializer fails to register — they check for `LibStub` at file scope and silently fall back to a plain table, which then has no `GetLibrary` method.
**Why it happens:** WoW loads TOC files sequentially. If LibDeflate.lua runs before LibStub.lua, LibStub is nil.
**How to avoid:** `LibStub\LibStub.lua` must be the first `<Script>` in load_libs.xml.
**Warning signs:** `LibStub:GetLibrary("LibDeflate")` errors "attempt to index global 'LibStub' (a nil value)".

### Pitfall 3: AbilityDB initialized too late
**What goes wrong:** Data files run before `ns.AbilityDB = {}` is declared, causing `ns.AbilityDB[npcID] = ...` to error on nil indexing.
**Why it happens:** WoW loads TOC files in order. If Core.lua runs after WindrunnerSpire.lua, `ns` exists but `ns.AbilityDB` is nil.
**How to avoid:** Core.lua must come before Data/ files in TOC, AND Core.lua must initialize `ns.AbilityDB = ns.AbilityDB or {}` at file scope (before ADDON_LOADED). This is already the established pattern — `ns.PackDatabase` uses this same guard.
**Warning signs:** Lua error on addon load: "attempt to index field 'AbilityDB' (a nil value)".

### Pitfall 4: Legacy MDT string (no `!` prefix)
**What goes wrong:** Old MDT exports created before the LibDeflate migration have no `!` prefix. `DecodeForPrint` will be called on a LibCompress-encoded string and return garbage or nil.
**Why it happens:** MDT changed compression format. Strings without `!` need `LibCompress:Decompress` which we are not bundling.
**How to avoid:** After stripping `!`, check `usesDeflate == 1`. If false, return `(false, "Legacy format not supported")` with a clear message rather than silently failing.
**Warning signs:** User pastes a string that works in MDT but `ns.MDTDecode` returns an error.

### Pitfall 5: install.bat not updated for Libs/
**What goes wrong:** Local dev install copies addon files but not Libs/ — WoW loads the TOC, fails to find `Libs\load_libs.xml`, and the entire addon fails to load.
**Why it happens:** install.bat has explicit file copy lines; new folders must be added manually.
**How to avoid:** Add `xcopy /Y /E "%SOURCE%Libs\*" "%DEST%\Libs\"` to install.bat.

## Code Examples

### AbilityDB initialization in Core.lua
```lua
-- Source: established project pattern (see ns.PackDatabase in current Core.lua)
-- Add near top of Core.lua, before ADDON_LOADED
ns.AbilityDB = ns.AbilityDB or {}
```

### Complete decode module (Import/Decode.lua)
```lua
-- Source: MDT Modules/Transmission.lua:205-238 adapted for our namespace
local addonName, ns = ...

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

--- Decode an MDT export string into a Lua table.
-- @param inString string — the raw pasted MDT export string
-- @return boolean, table|string — (true, data) or (false, errorMessage)
function ns.MDTDecode(inString)
    local encoded, usesDeflate = inString:gsub("^%!", "")

    if usesDeflate ~= 1 then
        return false, "Legacy MDT format (no ! prefix) is not supported"
    end

    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then
        return false, "DecodeForPrint failed — string may be corrupted or wrong format"
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return false, "DecompressDeflate failed"
    end

    local success, data = AceSerializer:Deserialize(decompressed)
    if not success then
        return false, "AceSerializer:Deserialize failed: " .. tostring(data)
    end

    return true, data
end
```

### /tpw decode slash command addition to Core.lua
```lua
-- Add to SlashCmdList["TERRIBLEPACKWARNINGS"] handler:
elseif cmd == "decode" then
    if arg == "" then
        print("|cff00ccffTPW|r Usage: /tpw decode <MDT export string>")
    else
        local ok, result = ns.MDTDecode(arg)
        if ok then
            print("|cff00ccffTPW|r Decode OK. Type: " .. type(result))
            -- Phase 9 will use result.value.pulls here
        else
            print("|cff00ccffTPW|r Decode failed: " .. result)
        end
    end
```

### Updated .pkgmeta
```yaml
package-as: TerriblePackWarnings

externals:
  Libs/LibStub: https://repos.curseforge.com/wow/libstub/trunk
  Libs/AceSerializer-3.0: https://repos.curseforge.com/wow/ace3/trunk/AceSerializer-3.0
  Libs/LibDeflate: https://repos.curseforge.com/wow/libdeflate/trunk

ignore:
  - .git
  - .gitignore
  - .github
  - .pkgmeta
  - .planning
  - CLAUDE.md
  - README.md
  - LICENSE
  - scripts
  - "*.png"
```

### Updated TOC (TerriblePackWarnings.toc)
```
## Interface: 120000, 120001
## Title: TerriblePackWarnings
## Notes: Dungeon trash pack ability timers for Mythic+
## Author: Jonathas-Conceicao
## Version: @project-version@
## URL: https://github.com/Jonathas-Conceicao/TerriblePackWarnings
## Category: Combat
## SavedVariables: TerriblePackWarningsDB

Libs\load_libs.xml
Core.lua
Engine\Scheduler.lua
Engine\NameplateScanner.lua
Engine\CombatWatcher.lua
Display\IconDisplay.lua
Import\Decode.lua
Data\WindrunnerSpire.lua
UI\PackFrame.lua
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| MDT used LibCompress for all exports | MDT uses LibDeflate for `!`-prefixed exports | MDT ~v5.x+ | We must support LibDeflate path only; legacy path requires LibCompress we won't bundle |
| Hardcoded packs in data files | npcID-keyed AbilityDB; packs built at runtime from import | Phase 8 | Data files become static mob definitions, not route data |

**Deprecated/outdated:**
- `ns.PackDatabase` population in data files: replaced by `ns.AbilityDB` population. PackDatabase will be populated dynamically in Phase 9.
- Pack-keyed ability lookup (iterating `ns.PackDatabase` to find abilities by spellID in the `/tpw show` debug command): will need updating once PackDatabase is no longer pre-populated.

## Open Questions

1. **LibDeflate CurseForge SVN URL**
   - What we know: MDT's pkgmeta.yaml path is `libs/LibDeflate` but no SVN URL is shown in the excerpt. LibDeflate's CurseForge project slug is likely `libdeflate`.
   - What's unclear: The exact SVN URL `https://repos.curseforge.com/wow/libdeflate/trunk` is inferred from the slug pattern — not verified from official source.
   - Recommendation: For Phase 8, just copy LibDeflate.lua from the MDT repo (file is MIT-licensed, self-contained). The pkgmeta URL can be corrected at release time. HIGH confidence the file copy approach works immediately.

2. **`/tpw show` debug command references PackDatabase**
   - What we know: Core.lua's `/tpw show` command iterates `ns.PackDatabase` to find label/tts for a spellID. After Phase 8, PackDatabase will be empty until Phase 9 import.
   - What's unclear: Whether to update `/tpw show` now or accept that it returns nil label/tts during Phase 8 development.
   - Recommendation: Note in the plan that `/tpw show` label/tts lookup will return nil after Phase 8. Update it in Phase 9 or add an AbilityDB-based fallback.

3. **AceSerializer-3.0.xml vs standalone .lua**
   - What we know: AceSerializer-3.0 ships with both a .lua and .xml file. The .xml just includes the .lua. MDT's load_libs.xml uses `<Script file='AceSerializer-3.0\AceSerializer-3.0.lua'/>` directly.
   - Recommendation: Use the `<Script>` direct include pattern as MDT does — simpler, no nested XML.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — WoW addon, manual in-game testing |
| Config file | none |
| Quick run command | `/reload` in WoW + `/tpw decode <string>` |
| Full suite command | Manual: verify all slash commands, check AbilityDB lookups in chat |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-10 | `ns.AbilityDB[232113]` has mobClass="PALADIN" and one ability with spellID=1253686 | smoke | `/tpw` in-game verify + print | ❌ Wave 0 |
| DATA-11 | `ns.AbilityDB[232122]` and `ns.AbilityDB[232121]` both have Interrupting Screech | smoke | `/tpw` in-game verify + print | ❌ Wave 0 |
| IMPORT-01 | `ns.MDTDecode("!<valid_string>")` returns (true, table) | smoke | `/tpw decode <string>` in-game | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `/reload` in WoW, verify no Lua errors in chat
- **Per wave merge:** Manually run all `/tpw` commands; verify AbilityDB populated, decode returns table
- **Phase gate:** All three requirements manually verified before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] No automated test infrastructure exists — this is a WoW addon; manual in-game verification is the standard
- [ ] `/tpw decode` slash command subcommand (created in this phase) serves as the decode smoke test
- [ ] A debug print utility (e.g. `/tpw abdb <npcID>`) would help verify AbilityDB entries — optional but useful

*(Lua unit testing frameworks exist for WoW addons, e.g. busted + WoW mock stubs, but adding one is out of scope for Phase 8)*

## Sources

### Primary (HIGH confidence)
- `C:\Users\jonat\Repositories\MythicDungeonTools\Modules\Transmission.lua` — exact decode chain, TableToString/StringToTable implementations, library acquisition pattern
- `C:\Users\jonat\Repositories\MythicDungeonTools\pkgmeta.yaml` — exact external declarations and SVN URLs for LibStub, AceSerializer-3.0, LibCompress
- `C:\Users\jonat\Repositories\MythicDungeonTools\MythicDungeonTools.toc` — TOC structure, XML include pattern
- `C:\Users\jonat\Repositories\MythicDungeonTools\libs\load_libs.xml` — exact load_libs.xml format and ordering
- `C:\Users\jonat\Repositories\MythicDungeonTools\libs\LibDeflate\LibDeflate.lua` — LibDeflate API: EncodeForPrint, DecodeForPrint, CompressDeflate, DecompressDeflate function signatures verified
- `C:\Users\jonat\Repositories\TerriblePackWarnings\Core.lua` — existing namespace pattern, ns.PackDatabase guard, slash command structure
- `C:\Users\jonat\Repositories\TerriblePackWarnings\Data\WindrunnerSpire.lua` — current hardcoded pack structure to be replaced

### Secondary (MEDIUM confidence)
- AceSerializer-3.0 Serialize/Deserialize API — inferred from MDT usage pattern (`Serializer:Serialize(table)`, `Serializer:Deserialize(string)`) which is the documented public API

### Tertiary (LOW confidence)
- LibDeflate CurseForge SVN URL (`https://repos.curseforge.com/wow/libdeflate/trunk`) — inferred from CurseForge slug pattern; not directly verified. File copy from MDT is safer for Phase 8.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — library files verified from MDT source
- Architecture: HIGH — decode chain verified line-by-line from MDT Transmission.lua; AbilityDB structure from locked CONTEXT.md decisions
- Pitfalls: HIGH — derived directly from reading MDT source code and understanding the codec contracts

**Research date:** 2026-03-16
**Valid until:** 2026-06-16 (LibDeflate and AceSerializer are stable libraries; MDT export format is unchanged)
