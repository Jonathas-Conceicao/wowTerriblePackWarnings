# Phase 1: Foundation and Data - Context

**Gathered:** 2026-03-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Loadable WoW Midnight addon skeleton with correct TOC, namespace conventions, a predefined pack/ability database for one dungeon (single pack), and dev tooling for local install and automated GitHub releases. No UI, no timers, no combat events — just a correct addon that loads and exposes queryable data.

</domain>

<decisions>
## Implementation Decisions

### Target Dungeon
- Dungeon: **Windrunner Spire**
- Single pack for v1 proof of concept: first pack of the dungeon
- Single mob: **Spellguard Magus** (NPC ID 232113)
- Single ability: **Spellguard's Protection** (Spell ID 1253686)
- Timing: first_cast = 50s, cooldown = 50s
- Mob identity and cast cannot be verified in-game — data is purely predefined
- No additional packs/mobs needed for v1 — this one entry proves the system

### Data Organization
- Schema supports multiple mobs and abilities per pack (future-ready), v1 ships with one entry
- Pack keys are human-readable strings (e.g., "windrunner_spire_pack_1")
- Dungeon files contain only pack/mob/ability data — no extra metadata
- File organization: Claude's discretion (subfolder vs flat)

### Namespace
- Mirror TerribleBuffTracker pattern: `local addonName, ns = ...` with ns as shared namespace
- No global TPW table for v1

### SavedVariables
- Declare SavedVariables in TOC but initialize as empty table — ready for future phases
- No user state persisted in v1 (state resets on reload)

### Dev Tooling
- Mirror TerribleBuffTracker: scripts/install.bat, scripts/release.bat, .pkgmeta, .github/workflows/release.yml
- install.bat copies addon files to local WoW AddOns folder
- release.bat creates git tag and pushes to trigger GitHub Actions
- GitHub Actions uses BigWigsMods/packager@v2

### Claude's Discretion
- Data file organization (Data/ subfolder vs flat at root)
- Exact .pkgmeta exclude patterns
- TOC metadata fields beyond required ones (Category, URL, etc.)

</decisions>

<specifics>
## Specific Ideas

- TerribleBuffTracker (C:\Users\jonat\Repositories\TerribleBuffTracker) is the reference project for addon structure, TOC format, namespace pattern, and dev tooling
- TOC should support both 120000 and 120001 interface versions (like TerribleBuffTracker does)
- Load message should follow same colored pattern: `|cff00ccffTerriblePackWarnings|r loaded. Type |cff00ff00/tpw|r to configure.`
- ADDON_LOADED handler unregisters after init, PLAYER_ENTERING_WORLD used for display init (same pattern as reference project)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- TerribleBuffTracker TOC format: dual interface version, @project-version@ for BigWigsMods packager
- TerribleBuffTracker Core.lua: event frame pattern, ADDON_LOADED + PLAYER_ENTERING_WORLD handling, slash command registration
- TerribleBuffTracker scripts/install.bat and scripts/release.bat: dev tooling templates
- TerribleBuffTracker .pkgmeta: packaging config for BigWigsMods/packager@v2

### Established Patterns
- `local addonName, ns = ...` namespace pattern
- Event frame with RegisterEvent/UnregisterEvent
- SavedVariables initialization with nil-check defaults
- Colored print for load confirmation

### Integration Points
- No existing code in TerriblePackWarnings — greenfield addon
- Data files will be loaded via TOC file listing

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation-and-data*
*Context gathered: 2026-03-13*
