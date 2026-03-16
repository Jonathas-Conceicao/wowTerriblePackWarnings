# Phase 11: Documentation and CI - Context

**Gathered:** 2026-03-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Add README, update TOC with project IDs and icon, align CI/release scripts with TerribleBuffTracker patterns, ensure .pkgmeta excludes non-addon files from release packages.

</domain>

<decisions>
## Implementation Decisions

### README
- Follow TerribleBuffTracker README.md as style/size reference (C:\Users\jonat\Repositories\TerribleBuffTracker\README.md)
- Include: project description, **WIP/unreleased notice**, features list, usage instructions, known issues, AI usage disclosure, license (WTFPL)
- Gallery section with `ws_fst_pack.png` screenshot
- Tone: casual, similar to TBT ("a bad way to track packs, but that's the game we play now" style)
- User will review and modify the README, then Claude spellchecks and suggests improvements

### TOC Metadata
- Add `## X-Curse-Project-ID: 1487612`
- Add `## X-Wago-ID: ZKbxadN1`
- Add `## IconTexture: Interface\AddOns\TerriblePackWarnings\tpw_64x64` (blp file already exists at repo root)
- Keep existing TOC fields (Interface, Title, Notes, Author, Version, URL, Category, SavedVariables)

### CI/Release
- Release workflow (.github/workflows/release.yml) matches TBT pattern — already close, verify secrets setup
- .pkgmeta ignore list must exclude ALL non-addon files from release package:
  - .git, .gitignore, .github, .pkgmeta, .planning
  - CLAUDE.md, README.md, LICENSE
  - scripts/
  - *.png (screenshots — blp icon stays since it's referenced by TOC)
- Release script (scripts/release.bat) already works — verify end-to-end

### Claude's Discretion
- Exact README wording (user reviews after)
- Known issues section content (based on current limitations)
- Whether to add .gitignore updates

</decisions>

<specifics>
## Specific Ideas

- The README should feel like TBT's — short, honest, acknowledging it's a WIP
- "TerriblePackWarnings" follows the "Terrible" naming pattern from TerribleBuffTracker

</specifics>

<code_context>
## Existing Code Insights

### Files to Create
- README.md (new)

### Files to Modify
- TerriblePackWarnings.toc (add project IDs, icon)
- .pkgmeta (review ignore list)
- .github/workflows/release.yml (verify matches TBT)

### Existing Assets
- tpw_64x64.blp — icon file for TOC reference
- tpw_400x400.png — larger icon (ignored in release)
- ws_fst_pack.png — gallery screenshot
- .pkgmeta already has externals + some ignores
- release.yml already uses BigWigsMods/packager@v2

### Reference
- TBT README: C:\Users\jonat\Repositories\TerribleBuffTracker\README.md
- TBT TOC: C:\Users\jonat\Repositories\TerribleBuffTracker\TerribleBuffTracker.toc
- TBT .pkgmeta: C:\Users\jonat\Repositories\TerribleBuffTracker\.pkgmeta
- TBT release.yml: C:\Users\jonat\Repositories\TerribleBuffTracker\.github\workflows\release.yml

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 11-documentation-and-ci*
*Context gathered: 2026-03-16*
