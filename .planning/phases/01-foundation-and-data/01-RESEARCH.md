# Phase 1: Foundation and Data - Research

**Researched:** 2026-03-13
**Domain:** WoW Midnight addon skeleton — TOC, namespace, Lua data tables, dev tooling (install.bat, release.bat, .pkgmeta, GitHub Actions)
**Confidence:** HIGH for TOC/Lua/namespace/tooling patterns (all verified against TerribleBuffTracker reference); MEDIUM for BigWigsMods/packager@v2 exclude-pattern details

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Target dungeon:** Windrunner Spire
- **Single pack for v1:** first pack of the dungeon
- **Single mob:** Spellguard Magus (NPC ID 232113)
- **Single ability:** Spellguard's Protection (Spell ID 1253686), first_cast = 50s, cooldown = 50s
- **Mob identity and cast cannot be verified in-game** — data is purely predefined
- **No additional packs/mobs needed for v1** — this one entry proves the system
- **Schema supports multiple mobs and abilities per pack** (future-ready); v1 ships with one entry
- **Pack keys are human-readable strings** (e.g., "windrunner_spire_pack_1")
- **Dungeon files contain only pack/mob/ability data** — no extra metadata
- **Namespace:** mirror TerribleBuffTracker pattern — `local addonName, ns = ...` with ns as shared namespace; no global TPW table for v1
- **SavedVariables:** declare in TOC but initialize as empty table — ready for future phases; no user state persisted in v1
- **Dev tooling:** mirror TerribleBuffTracker — scripts/install.bat, scripts/release.bat, .pkgmeta, .github/workflows/release.yml; GitHub Actions uses BigWigsMods/packager@v2
- **install.bat** copies addon files to local WoW AddOns folder
- **release.bat** creates git tag and pushes to trigger GitHub Actions
- **TOC:** dual interface versions 120000 and 120001 (same as TerribleBuffTracker)
- **Load message** follows TerribleBuffTracker colored pattern: `|cff00ccffTerriblePackWarnings|r loaded. Type |cff00ff00/tpw|r to configure.`
- **ADDON_LOADED handler** unregisters after init; PLAYER_ENTERING_WORLD used for display init (same pattern as reference project)

### Claude's Discretion

- Data file organization (Data/ subfolder vs flat at root)
- Exact .pkgmeta exclude patterns
- TOC metadata fields beyond required ones (Category, URL, etc.)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FOUND-01 | Addon loads in WoW Midnight with correct TOC (Interface 120001), namespace, and SavedVariables | TOC format, namespace pattern, SavedVariables init pattern — all verified against TerribleBuffTracker reference |
| FOUND-02 | Dev tooling: install script, release script, .pkgmeta, and GitHub Actions release workflow | install.bat, release.bat, .pkgmeta, .github/workflows/release.yml — all verified by reading TerribleBuffTracker source files |
| DATA-01 | Predefined pack/mob database for one Midnight dungeon with ability names and cooldown timers | Lua table schema, Data/ subfolder pattern, pack key conventions — documented in this research |
| DATA-02 | Each ability entry includes first-cast offset and repeat cooldown | Schema fields `first_cast` and `cooldown` — both required in the data table shape |
</phase_requirements>

---

## Summary

Phase 1 is a greenfield WoW addon skeleton. There is no new API to discover — the reference project (TerribleBuffTracker) provides verified, working patterns for every deliverable in this phase: TOC format, namespace, event frame, SavedVariables initialization, install.bat, release.bat, .pkgmeta, and the GitHub Actions workflow. All patterns can be copied with name substitutions.

The only design decision left to Claude's discretion is file organization (flat vs. Data/ subfolder). Given the architecture research's recommendation to isolate pack data in a Data/ folder for future scalability, and the fact that this addon will grow to multiple dungeons, a Data/ subfolder is the correct choice even for a one-entry v1.

The data schema for Phase 1 must be future-ready (multiple mobs per pack, multiple abilities per mob) while shipping with exactly one pack, one mob, one ability. Both `first_cast` and `cooldown` fields are required per ability entry per DATA-02.

**Primary recommendation:** Copy TerribleBuffTracker structure exactly, substituting addon name. Use Data/WindrunnerSpire.lua for the single dungeon data file.

---

## Standard Stack

### Core

| Technology | Version | Purpose | Why Standard |
|------------|---------|---------|--------------|
| Lua 5.1 (WoW dialect) | WoW embedded | All addon logic | Only scripting language exposed by the WoW client |
| TOC manifest | Interface 120000, 120001 | Addon metadata and file load order | Dual version matches TerribleBuffTracker; 120001 is hard requirement for Midnight |
| XML (optional) | Standard | Frame/template declarations | Not needed for Phase 1 — no UI; TOC file only |

### Supporting (Dev Tooling)

| Tool | Purpose | Notes |
|------|---------|-------|
| scripts/install.bat | Copy addon files to local WoW AddOns folder | Windows batch; mirrors TerribleBuffTracker exactly |
| scripts/release.bat | Create annotated git tag and push to origin | Triggers GitHub Actions; mirrors TerribleBuffTracker exactly |
| .pkgmeta | BigWigsMods/packager@v2 packaging config | Defines `package-as` name and `ignore` list |
| .github/workflows/release.yml | GitHub Actions release workflow | Triggers on any tag push; uses BigWigsMods/packager@v2 |
| BigWigsMods/packager@v2 | CurseForge/Wago/GitHub release packaging | Replaces `@project-version@` token in TOC; produces zip artifact |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Data/ subfolder | Flat root (all .lua at root) | Flat is simpler for one file; subfolder wins when data grows to 8+ dungeons. Use Data/ now. |
| Human-readable pack keys ("windrunner_spire_pack_1") | Numeric keys (1, 2, 3) | String keys are self-documenting and survive data reordering. Use strings. |

**Installation (dev):**
```bat
scripts\install.bat
```

---

## Architecture Patterns

### Recommended Project Structure

```
TerriblePackWarnings/
├── TerriblePackWarnings.toc          # Manifest: dual interface, load order
├── Core.lua                          # Namespace, ADDON_LOADED, PLAYER_ENTERING_WORLD, slash cmd
├── Data/
│   └── WindrunnerSpire.lua           # Pack/mob/ability data for Windrunner Spire
└── scripts/
    ├── install.bat                   # Copy to WoW AddOns folder
    └── release.bat                   # Tag + push to trigger GitHub Actions
```

Plus repo root files:
```
.pkgmeta
.github/workflows/release.yml
```

### Pattern 1: TOC File Format

**What:** The TOC manifest declares addon metadata and file load order. The filename must exactly match the folder name.

**Key rules:**
- `## Interface: 120000, 120001` — comma-delimited dual version, matching TerribleBuffTracker
- `## Version: @project-version@` — BigWigsMods/packager replaces this token on release
- `## SavedVariables: TerriblePackWarningsDB` — declared even though v1 initializes to empty
- Files listed in load order — Core.lua first, then Data/

```lua
## Interface: 120000, 120001
## Title: TerriblePackWarnings
## Notes: Dungeon trash pack ability timers for Mythic+
## Author: Jonathas-Conceicao
## Version: @project-version@
## URL: https://github.com/Jonathas-Conceicao/TerriblePackWarnings
## Category: Combat
## SavedVariables: TerriblePackWarningsDB

Core.lua
Data\WindrunnerSpire.lua
```

### Pattern 2: Namespace via `local addonName, ns = ...`

**What:** Every Lua file in the addon receives `addonName` and the shared addon table (`ns`) as implicit varargs via `...`. All module state attaches to `ns`. No separate global table (`TPW = {}` style is NOT used per user decision — ns is the shared namespace).

**When to use:** Every Lua file in the addon.

```lua
-- Core.lua (loaded first — establishes ns fields)
local addonName, ns = ...

ns.PackDatabase = ns.PackDatabase or {}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= addonName then return end

        if not TerriblePackWarningsDB then
            TerriblePackWarningsDB = {}
        end
        ns.db = TerriblePackWarningsDB

        print("|cff00ccffTerriblePackWarnings|r loaded. Type |cff00ff00/tpw|r to configure.")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- display init goes here in future phases
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

SLASH_TERRIBLEBUFFTRACKER1 = "/tpw"
SlashCmdList["TERRIBLEPACKWARNINGS"] = function()
    -- toggle UI — stub for Phase 1
end
```

```lua
-- Data/WindrunnerSpire.lua (loaded after Core.lua)
local addonName, ns = ...

ns.PackDatabase["windrunner_spire_pack_1"] = {
    displayName = "Windrunner Spire — Pack 1",
    mobs = {
        {
            name = "Spellguard Magus",
            npcID = 232113,
            abilities = {
                {
                    name = "Spellguard's Protection",
                    spellID = 1253686,
                    first_cast = 50,
                    cooldown = 50,
                },
            },
        },
    },
}
```

**Source:** TerribleBuffTracker/Core.lua (read directly from reference project)

### Pattern 3: SavedVariables Initialization

**What:** Check if the SavedVariables global exists; if not, initialize to an empty table. Store a reference on `ns.db`.

**When to use:** Inside the `ADDON_LOADED` handler, after confirming the event is for this addon.

```lua
-- Inside ADDON_LOADED handler:
if not TerriblePackWarningsDB then
    TerriblePackWarningsDB = {}
end
ns.db = TerriblePackWarningsDB
```

**Source:** TerribleBuffTracker/Core.lua (lines 17-24)

### Pattern 4: install.bat Structure

**What:** Windows batch script that mirrors the source tree into the WoW AddOns folder. Uses `%PROGRAMFILES(x86)%` for the default WoW install path.

```bat
@echo off
set "SOURCE=%~dp0..\"
set "DEST=%PROGRAMFILES(x86)%\World of Warcraft\_retail_\Interface\AddOns\TerriblePackWarnings"

if not exist "%DEST%" mkdir "%DEST%"

echo Copying TerriblePackWarnings to WoW retail addons folder...
copy /Y "%SOURCE%TerriblePackWarnings.toc" "%DEST%\"
copy /Y "%SOURCE%Core.lua" "%DEST%\"

if not exist "%DEST%\Data" mkdir "%DEST%\Data"
copy /Y "%SOURCE%Data\WindrunnerSpire.lua" "%DEST%\Data\"

echo Done! /reload in WoW to load the addon.
```

**Note:** Subdirectory (`Data\`) requires an explicit `mkdir` step before copying — the reference project does not use subdirs, so this is an adaptation.

**Source:** TerribleBuffTracker/scripts/install.bat (adapted)

### Pattern 5: .pkgmeta Structure

**What:** BigWigsMods/packager reads this to determine the output package name and which files to exclude from the release zip.

```yaml
package-as: TerriblePackWarnings

ignore:
  - .gitignore
  - .pkgmeta
  - CLAUDE.md
  - README.md
  - LICENSE
  - scripts
  - "*.png"
```

**Source:** TerribleBuffTracker/.pkgmeta (read directly)

### Pattern 6: GitHub Actions Release Workflow

**What:** Triggers on any tag push; runs BigWigsMods/packager@v2 which builds the release zip, substitutes `@project-version@` in the TOC, and uploads artifacts to GitHub Releases (and optionally CurseForge/Wago if API keys are set).

```yaml
name: Release AddOn

on:
  push:
    tags:
      - "**"

env:
  GITHUB_OAUTH: ${{ secrets.GITHUB_TOKEN }}
  # CF_API_KEY: ${{ secrets.CF_API_KEY }}
  # WAGO_API_TOKEN: ${{ secrets.WAGO_API_TOKEN }}

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: BigWigsMods/packager@v2
```

**Source:** TerribleBuffTracker/.github/workflows/release.yml (read directly)

### Anti-Patterns to Avoid

- **Global table per module:** `TPWDatabase = {}` as a standalone global pollutes the shared WoW namespace. Use `ns.PackDatabase` instead.
- **Hardcoding ability data in Core.lua:** Data belongs in Data/ files. Core.lua only initializes `ns.PackDatabase = ns.PackDatabase or {}` and data files populate it.
- **Missing UnregisterEvent after ADDON_LOADED:** The reference project always unregisters ADDON_LOADED after handling it to avoid re-firing if another addon loads. Copy this pattern.
- **SavedVariables without nil-check:** Always guard with `if not TerriblePackWarningsDB then` — the variable is nil on first ever load.
- **install.bat without mkdir for subdirectories:** `copy /Y` to a missing subdirectory fails silently or errors. Always `mkdir` each subdirectory before copying files into it.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release packaging | Custom zip script | BigWigsMods/packager@v2 | Handles TOC token substitution (`@project-version@`), CurseForge/Wago upload, GitHub Release asset, changelog from git log |
| TOC version token | Manual version string | `## Version: @project-version@` | packager replaces this on build; handrolled version strings go stale |
| Addon table namespace | Multiple globals per module | `local addonName, ns = ...` in every file | WoW passes the shared addon table as the second vararg automatically |

**Key insight:** Every tooling problem in this phase already has a working solution in TerribleBuffTracker. The value is in faithful reproduction, not invention.

---

## Common Pitfalls

### Pitfall 1: TOC Filename Mismatch

**What goes wrong:** Addon does not appear in the WoW addon list at all.
**Why it happens:** The TOC filename (e.g., `TerriblePackWarnings.toc`) must exactly match the containing folder name (`TerriblePackWarnings/`). A case or spelling difference causes the client to ignore the addon silently.
**How to avoid:** Name the folder and .toc file identically, including capitalization.
**Warning signs:** Addon is missing from the addon list entirely after copying files.

### Pitfall 2: Wrong or Missing Interface Version

**What goes wrong:** Addon shows as "out of date" or refuses to load.
**Why it happens:** In Midnight, there is no player override for the interface version check. If `## Interface:` is absent or does not include 120001 (or 120000), the addon will not load.
**How to avoid:** Use `## Interface: 120000, 120001` (comma-delimited dual version, matching TerribleBuffTracker).
**Warning signs:** Addon appears in the list with a yellow/red "out of date" warning; or addon does not load at all and prints no load message.

### Pitfall 3: ADDON_LOADED Fires for Every Addon

**What goes wrong:** The init code runs multiple times (once per addon that loads), initializing ns fields repeatedly or printing the load message for every addon.
**Why it happens:** `ADDON_LOADED` fires for every addon that loads, not just yours. If you omit the `if name ~= addonName then return end` guard, your handler executes for all of them.
**How to avoid:** Always check `local name = ...; if name ~= addonName then return end` at the top of the ADDON_LOADED branch. Then call `self:UnregisterEvent("ADDON_LOADED")`.
**Warning signs:** Load message prints multiple times in chat; SavedVariables gets reset on every addon load.

### Pitfall 4: Data File Loaded Before PackDatabase Initialized

**What goes wrong:** `ns.PackDatabase["windrunner_spire_pack_1"] = ...` errors because `ns.PackDatabase` is nil.
**Why it happens:** Data/WindrunnerSpire.lua executes at load time, before ADDON_LOADED fires. If Core.lua does not initialize `ns.PackDatabase = {}` at the top level (outside any event handler), the data file finds nil.
**How to avoid:** Initialize `ns.PackDatabase = ns.PackDatabase or {}` at module scope in Core.lua (not inside the event handler). Data files then safely write into the already-existing table.
**Warning signs:** Lua error on load: `attempt to index a nil value (global 'ns')` or similar.

### Pitfall 5: install.bat Subdirectory Not Created

**What goes wrong:** `copy /Y` to `%DEST%\Data\WindrunnerSpire.lua` fails because `%DEST%\Data` does not exist.
**Why it happens:** `copy` does not create intermediate directories. The reference project avoids this because it keeps all files flat. This project uses a Data/ subfolder.
**How to avoid:** Add `if not exist "%DEST%\Data" mkdir "%DEST%\Data"` before the copy for Data files.
**Warning signs:** install.bat exits with an error on the copy step; Data folder missing in WoW AddOns.

### Pitfall 6: @project-version@ Not Replaced in Dev Installs

**What goes wrong:** In-game, the addon version shows as the literal string `@project-version@`.
**Why it happens:** `@project-version@` is replaced by BigWigsMods/packager at release build time. When you copy files directly via install.bat for local dev, no substitution happens.
**How to avoid:** This is expected behavior for dev installs — document it. For a real release, the packager produces the correct zip. Alternatively, hardcode a dev version string (e.g., `## Version: dev`) for install.bat use and let the packager override it.
**Warning signs:** Version shown as `@project-version@` in the addon tooltip — normal during development, not normal in a release zip.

---

## Code Examples

### Complete Core.lua for Phase 1

```lua
-- Source: mirrors TerribleBuffTracker/Core.lua pattern
local addonName, ns = ...

-- Initialize PackDatabase at module scope so Data/ files can write into it
ns.PackDatabase = ns.PackDatabase or {}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= addonName then return end

        if not TerriblePackWarningsDB then
            TerriblePackWarningsDB = {}
        end
        ns.db = TerriblePackWarningsDB

        print("|cff00ccffTerriblePackWarnings|r loaded. Type |cff00ff00/tpw|r to configure.")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- display init placeholder for future phases
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

SLASH_TERRIBLEPACKWARNINGS1 = "/tpw"
SlashCmdList["TERRIBLEPACKWARNINGS"] = function()
    -- stub: toggle UI (Phase 3)
end
```

### Complete Data/WindrunnerSpire.lua for Phase 1

```lua
-- Source: schema designed for DATA-01, DATA-02 compliance
local addonName, ns = ...

-- Windrunner Spire — all packs for this dungeon
-- v1 ships with one pack, one mob, one ability
ns.PackDatabase["windrunner_spire_pack_1"] = {
    displayName = "Windrunner Spire — Pack 1",
    mobs = {
        {
            name = "Spellguard Magus",
            npcID = 232113,
            abilities = {
                {
                    name = "Spellguard's Protection",
                    spellID = 1253686,
                    first_cast = 50,   -- seconds after pull
                    cooldown = 50,     -- repeat interval in seconds
                },
            },
        },
    },
}
```

### Console Verification Command

After loading the addon, verify the database is populated:
```
/run print(ns and "ns exists" or "ns nil")
/run for k,v in pairs(select(2,...).PackDatabase) do print(k) end
```

Per success criterion 2, the simpler test is:
```
/run local _, ns = ...; print(ns.PackDatabase)
```

**Note:** The success criterion says `/run print(TPW.PackDatabase)` but the locked namespace decision is `ns` not `TPW`. The planner should verify whether the success criterion implies a `TPW` global or whether it should be updated to use `ns`.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single `## Interface:` version | Comma-delimited multi-version: `## Interface: 120000, 120001` | WoW 11.x | Allows one TOC to work across client builds |
| `@project-version@` manual replacement | BigWigsMods/packager@v2 handles automatically | ~2020+ (packager mature) | Release zip always has correct version string |
| Separate globals per module (`TPWScheduler = {}`) | Single shared namespace via `local addonName, ns = ...` | Modern WoW convention | Prevents global namespace pollution |

**Deprecated/outdated:**
- `wowpedia.fandom.com` as API reference: replaced by `warcraft.wiki.gg` (actively maintained for Midnight)
- `BigWigsMods/packager@v1`: superseded by @v2; the reference project uses @v2

---

## Open Questions

1. **Success criterion 2 references `TPW.PackDatabase`**
   - What we know: The locked namespace decision says no global TPW table — use `ns` pattern instead. `ns` is not accessible from `/run` console commands the same way a global is.
   - What's unclear: Did the success criterion assume a global `TPW` table, or should the verify command be adapted to check `ns` indirectly?
   - Recommendation: The planner should either (a) add `TPW = select(2, ...)` as a convenience global alias in Core.lua that makes `/run print(TPW.PackDatabase)` work, or (b) update the success criterion to a different console command. Option (a) is the simplest fix and aligns with the intent of the criterion.

2. **WoW install path in install.bat**
   - What we know: TerribleBuffTracker uses `%PROGRAMFILES(x86)%\World of Warcraft\_retail_\Interface\AddOns\`. This path is correct for the standard Blizzard launcher install.
   - What's unclear: Whether this developer has WoW installed at the default path or a custom path.
   - Recommendation: Use the default path, matching TerribleBuffTracker. If it fails, the developer can edit the DEST variable — include a comment in the script.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — WoW addon Lua runs inside the WoW client; no standalone test runner applies |
| Config file | N/A |
| Quick run command | In-game: `/reload` — verifies addon loads without Lua errors |
| Full suite command | In-game console checks (see below) — must be run manually inside the WoW client |

WoW addon Lua cannot be tested with an offline runner (pytest, jest, etc.) because it depends on the WoW client API (`CreateFrame`, `RegisterEvent`, `C_Timer`, etc.). All validation for this phase is manual in-game verification.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUND-01 | Addon appears in addon list and loads without Lua errors | manual-only | `/reload` then check chat for load message | ❌ Wave 0 (no test infra) |
| FOUND-01 | Addon visible in addon list with correct name and version | manual-only | Open WoW addon manager, confirm "TerriblePackWarnings" listed | ❌ Wave 0 |
| FOUND-01 | `/reload` completes without taint errors or secret value violations | manual-only | `/reload` and inspect error output | ❌ Wave 0 |
| FOUND-02 | `scripts/install.bat` copies files to WoW AddOns folder without error | manual-only | Run `scripts\install.bat` from Windows Explorer or cmd.exe | ❌ Wave 0 |
| FOUND-02 | Pushing a git tag triggers GitHub Actions and produces a release artifact | manual-only | Push a test tag, check GitHub Actions run, verify release zip | ❌ Wave 0 |
| DATA-01 | `/run print(TPW.PackDatabase)` (or ns equivalent) prints non-nil table | manual-only | In-game console command | ❌ Wave 0 |
| DATA-02 | Every ability entry has both `first_cast` and `cooldown` fields | code review | Inspect Data/WindrunnerSpire.lua directly | ❌ Wave 0 |

**All tests are manual-only** — this is expected and correct for WoW addon development. There is no automated test runner for the client-side Lua environment.

### Sampling Rate

- **Per task commit:** Run `scripts\install.bat`, then `/reload` in WoW, verify load message in chat
- **Per wave merge:** Full in-game checklist (all 5 success criteria from phase description)
- **Phase gate:** All 5 success criteria confirmed TRUE before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] No test infrastructure exists — this is expected for WoW addon Lua; all validation is manual in-game
- [ ] No automated framework to install; manual verification procedures documented above are sufficient
- [ ] `scripts/install.bat` — must exist and be runnable; covers FOUND-02 criterion 5

*(If a Lua linter is desired in future: `luacheck` with a WoW globals config is the community standard, but is not required for this phase.)*

---

## Sources

### Primary (HIGH confidence)

- TerribleBuffTracker/TerribleBuffTracker.toc — read directly; TOC format, dual interface version, @project-version@, SavedVariables declaration
- TerribleBuffTracker/Core.lua — read directly; namespace pattern, ADDON_LOADED/PLAYER_ENTERING_WORLD handlers, colored load message, UnregisterEvent pattern
- TerribleBuffTracker/scripts/install.bat — read directly; install.bat structure and DEST path
- TerribleBuffTracker/scripts/release.bat — read directly; git tag + push pattern
- TerribleBuffTracker/.pkgmeta — read directly; package-as, ignore list
- TerribleBuffTracker/.github/workflows/release.yml — read directly; BigWigsMods/packager@v2 action, trigger on tag push
- TerribleBuffTracker/CLAUDE.md — read directly; confirmed `local addonName, ns = ...` pattern, stylua workflow

### Secondary (MEDIUM confidence)

- .planning/research/STACK.md — project-level stack research; TOC format, C_Timer, namespace pattern, dev tooling confirmed
- .planning/research/ARCHITECTURE.md — project-level architecture research; Data/ subfolder rationale, load order, build order

### Tertiary (LOW confidence)

- None for this phase — all critical details verified from primary sources

---

## Metadata

**Confidence breakdown:**
- TOC format and namespace pattern: HIGH — verified by reading TerribleBuffTracker source directly
- Data schema: HIGH — derived from locked decisions and architecture research; straightforward Lua table design
- Dev tooling (install.bat, release.bat, .pkgmeta, GitHub Actions): HIGH — copied directly from working reference project
- BigWigsMods/packager@v2 behavior: MEDIUM — observed in reference project; packager docs not independently verified in this session

**Research date:** 2026-03-13
**Valid until:** 2026-06-13 (stable WoW addon conventions; 90 days; re-verify if WoW API changes between now and implementation)
