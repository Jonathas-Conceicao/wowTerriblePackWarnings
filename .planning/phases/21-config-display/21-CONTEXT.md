# Phase 21: Config Display - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add read-only color-coded category tags to mob header rows in the config window, and extend the search filter to match category terms. The config window currently shows "MobName - WARRIOR" (broken since Phase 19 removed mobClass) — this phase fixes the header to show "MobName [Category]" with color coding, and adds category as a searchable field alongside mob name and spell name.

</domain>

<decisions>
## Implementation Decisions

### Category tag in mob header
- Replace the broken `entry.mobClass` read (line 563) with `entry.mobCategory`
- Format: `"MobName [Category]"` with color-coded category tag using WoW color escape codes
- Tag is read-only — no editable controls, purely informational
- Color scheme per category is Claude's discretion (research suggested: boss=gold, miniboss=orange, caster=cyan, warrior=brown, rogue=yellow, trivial=dark gray, unknown=gray)

### Search matching rules
- Category matching added to `ApplySearchFilter` — search text compared against mob's `mobCategory` value
- **Partial matches enabled**: "cast" matches "caster", "war" matches "warrior", "tri" matches "trivial"
- **Hyphen normalization**: strip hyphens from search text before matching — "mini-boss" becomes "miniboss", matches naturally via substring
- Category match behaves like mob name match: shows the mob with all its abilities visible (not filtered to specific spells)
- "unknown" is searchable — returns all mobs without a specific category

### Claude's Discretion
- Exact color values for each category tag
- Category tag font style (bold, italic, or plain)
- Whether to capitalize the tag display ("Boss" vs "boss")
- Search match priority when category matches overlap with mob/spell name matches
- Category match scope: all abilities shown (consistent with mob name match behavior)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Config UI (primary modification target)
- `UI/ConfigFrame.lua` — Lines 533-566: PopulateRightPanel header (broken mobClass read at line 563). Lines 1115-1194: ApplySearchFilter (add category matching). Line 1152: mob name match pattern to replicate for category.

### Data source
- `Data/Skyreach.lua` — Reference for mobCategory values on AbilityDB entries

### Prior context
- `.planning/phases/19-data-layer/19-CONTEXT.md` — mobCategory vocabulary (boss, miniboss, caster, warrior, rogue, trivial, unknown)
- `.planning/phases/20-runtime-detection-and-scanner-matching/20-CONTEXT.md` — Pipeline now copies mobCategory onto ability objects

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ApplySearchFilter(text)` at line 1115 — existing search function to extend with category matching
- `headerNameStr:SetText()` at line 564 — existing header text setter to modify
- WoW color escape codes: `"|cffRRGGBB" .. text .. "|r"` — standard pattern for colored text in WoW

### Established Patterns
- Search: `filter = text:lower()` then `string:find(filter, 1, true)` for substring matching
- Mob name match shows all abilities; spell name match shows only matched spells
- `currentMatchedMobs[npcID] = true` marks a mob as visible in search results
- 0.3s debounce via `C_Timer.NewTimer` on search input

### Integration Points
- `PopulateRightPanel(npcID)` line 563 — header text, replace `entry.mobClass` with `entry.mobCategory`
- `ApplySearchFilter` line 1152 — add category check alongside mob name check
- `ns.AbilityDB[npcID].mobCategory` — source of category data for both header and search

### Broken State
- Line 563: `local mobClass = entry.mobClass or "UNKNOWN"` — `entry.mobClass` is nil since Phase 19. Reads as "UNKNOWN" for all mobs. Must be fixed.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — standard WoW addon UI text and search enhancement.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 21-config-display*
*Context gathered: 2026-03-23*
