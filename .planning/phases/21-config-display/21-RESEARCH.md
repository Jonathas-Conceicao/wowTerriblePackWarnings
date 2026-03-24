# Phase 21: Config Display - Research

**Researched:** 2026-03-23
**Domain:** WoW addon Lua UI — FontString text, WoW color escape codes, substring search filter
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Replace the broken `entry.mobClass` read (line 563) with `entry.mobCategory`
- Format: `"MobName [Category]"` with color-coded category tag using WoW color escape codes
- Tag is read-only — no editable controls, purely informational
- Category matching added to `ApplySearchFilter` — search text compared against mob's `mobCategory` value
- Partial matches enabled: "cast" matches "caster", "war" matches "warrior", "tri" matches "trivial"
- Hyphen normalization: strip hyphens from search text before matching — "mini-boss" becomes "miniboss", matches naturally via substring
- Category match behaves like mob name match: shows the mob with all its abilities visible (not filtered to specific spells)
- "unknown" is searchable — returns all mobs without a specific category

### Claude's Discretion
- Exact color values for each category tag
- Category tag font style (bold, italic, or plain)
- Whether to capitalize the tag display ("Boss" vs "boss")
- Search match priority when category matches overlap with mob/spell name matches
- Category match scope: all abilities shown (consistent with mob name match behavior)

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UI-01 | Mob header row in config tree shows a read-only color-coded category tag (e.g., `[Caster]`) | Lines 563-564 in ConfigFrame.lua are the only change point; replace `entry.mobClass` with `entry.mobCategory` and format with WoW color escape |
| UI-02 | Category tag is non-editable — purely informational display | The header uses a FontString (`headerNameStr:SetText()`), not an EditBox — no changes needed to make it read-only, it already is |
| UI-03 | Config search matches mob category (e.g., searching "boss", "mini-boss", "miniboss", "rogue" shows matching mobs) | Add category check in `ApplySearchFilter` at line 1152, after mob name check, before ability name check |
</phase_requirements>

---

## Summary

Phase 21 is a focused two-touch change inside `UI/ConfigFrame.lua`. The entire implementation lives in one file with two distinct locations:

1. **Header fix (lines 563-564):** The field `entry.mobClass` no longer exists since Phase 19. It reads as nil, which falls back to "UNKNOWN" for every mob. Replacing the read with `entry.mobCategory` and rendering it with a WoW color escape sequence fixes the broken display and adds the category tag.

2. **Search extension (lines 1142-1178 of `ApplySearchFilter`):** The existing search already does mob name substring matching and spell name substring matching. A third branch for category matching is added after the mob name check. The normalized filter text (hyphens stripped) is compared against `ns.AbilityDB[npcID].mobCategory` via substring find. A category hit behaves identically to a mob name hit: the mob is shown with all abilities, no spell-level filtering.

The data source (`ns.AbilityDB[npcID].mobCategory`) is fully populated from Phase 19 (Skyreach mobs with precise categories, all others with `"unknown"` explicit string) and is always available when these code paths run.

**Primary recommendation:** Two edits, both inside `UI/ConfigFrame.lua`. No new files, no new modules, no external dependencies.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| WoW Lua 5.1 | 5.1 (Midnight) | Addon scripting | Platform-mandated |
| FontString (WoW API) | N/A | Read-only text display | Built-in widget already in use |

### No External Libraries Required

The color escape pattern (`|cffRRGGBB...|r`) and `string.find` are both built into WoW Lua. No additional libraries needed.

---

## Architecture Patterns

### Pattern 1: WoW Color Escape for Category Tag

**What:** Wrap the category string with `|cffRRGGBB` prefix and `|r` suffix. Concatenate with the mob name string before calling `:SetText()`.

**When to use:** Any time colored inline text is needed in a FontString.

```lua
-- Source: standard WoW addon pattern (see TerriblePackWarnings UI/ConfigFrame.lua existing usage)
local categoryTag = "|cff" .. COLOR_HEX .. "[" .. displayText .. "]|r"
headerNameStr:SetText(mobName .. " " .. categoryTag)
```

**Color scheme (Claude's discretion — high readability on dark WoW UI):**
| Category | Hex | Rationale |
|----------|-----|-----------|
| boss | FFD700 | Gold — traditional boss color in WoW UI |
| miniboss | FF8C00 | Dark orange — between elite and boss |
| caster | 00BFFF | Cyan/deep sky blue — mage/caster convention |
| warrior | CD853F | Peru/brown — physical melee convention |
| rogue | FFE566 | Yellow — rogue class color approximation |
| trivial | 808080 | Gray — low priority/trivial |
| unknown | A0A0A0 | Light gray — no data |

**Capitalization:** Capitalize first letter only — `"Boss"`, `"Caster"` etc. Consistent with WoW's own classification labels.

### Pattern 2: Search Filter Category Branch

**What:** After the mob name check, before the ability name check, check `ns.AbilityDB[npcID].mobCategory` against the normalized filter.

**When to use:** Extending `ApplySearchFilter` with an additional match dimension.

```lua
-- Source: ConfigFrame.lua ApplySearchFilter (lines 1142-1178), extended
local filter = text:lower():gsub("-", "")  -- strip hyphens for mini-boss -> miniboss

-- Existing mob name check (unchanged):
local mobNameMatch = (mob.name or ""):lower():find(filter, 1, true)

-- NEW: category check
local entry = ns.AbilityDB[npcID]
local categoryMatch = false
if entry and entry.mobCategory then
    categoryMatch = entry.mobCategory:find(filter, 1, true) ~= nil
end

if mobNameMatch or categoryMatch then
    currentMatchedMobs[npcID] = true
    -- Do NOT populate currentMatchedSpells (show all abilities)
else
    -- existing ability name check block (unchanged)
end
```

### Anti-Patterns to Avoid
- **Reading `entry.mobClass`:** Field was removed in Phase 19. Never reference it — use `entry.mobCategory`.
- **Putting category match inside the ability-name else-branch:** Category match should show all abilities (like mob name match), not filter to matched spells. Keep it in the same branch as `mobNameMatch`.
- **Normalizing the stored category value:** The stored values use no hyphens (`miniboss`, not `mini-boss`). Only normalize the user's input. Don't mutate `entry.mobCategory`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Colored text in FontString | Custom texture/frame overlay | `|cffRRGGBB...|r` escape codes | Built into WoW's FontString rendering |
| Substring search | Regex library | `string.find(s, pattern, 1, true)` | The `true` flag disables Lua pattern matching, making it a plain substring search — already used in this file |

---

## Common Pitfalls

### Pitfall 1: Hyphen normalization applied to the wrong side
**What goes wrong:** Normalizing `entry.mobCategory` instead of the search filter, or normalizing both.
**Why it happens:** Over-engineering the normalization.
**How to avoid:** Only strip hyphens from `filter` (the user input). The stored category strings never contain hyphens. The normalization is purely to handle user typing "mini-boss".
**Warning signs:** If "miniboss" stops matching when the user types "miniboss" (no hyphen).

### Pitfall 2: Category match accidentally filters abilities
**What goes wrong:** Category match lands inside the `else` block and populates `currentMatchedSpells[npcID]`, causing `PopulateRightPanel` to filter abilities when the mob was matched by category.
**Why it happens:** Copying the ability-name match block structure instead of the mob-name match block structure.
**How to avoid:** When `categoryMatch` is true, set `currentMatchedMobs[npcID] = true` and do NOT set `currentMatchedSpells[npcID]`. This is identical to what `mobNameMatch` does.

### Pitfall 3: Color codes break if hex is wrong length
**What goes wrong:** The `|cff` prefix expects exactly 6 hex digits. A 5-digit or 7-digit hex silently corrupts the following text.
**Why it happens:** Manual hex string construction.
**How to avoid:** Define all color strings as constants at the top of the code block. Double-check all are exactly 6 characters.

### Pitfall 4: `entry` nil when AbilityDB has no entry for a mob
**What goes wrong:** `entry.mobCategory` throws a nil-index error.
**Why it happens:** `BuildDungeonIndex` gates mobs on `ns.AbilityDB[enemy.id]` being non-nil, so in theory every mob in the list has an entry — but defensive coding is warranted.
**How to avoid:** Guard with `if entry and entry.mobCategory then` before accessing `entry.mobCategory`.

---

## Code Examples

### Header text with color-coded category tag (full replacement for lines 563-564)

```lua
-- Source: ConfigFrame.lua lines 563-564 (replacement)
local CATEGORY_COLORS = {
    boss      = "FFD700",
    miniboss  = "FF8C00",
    caster    = "00BFFF",
    warrior   = "CD853F",
    rogue     = "FFE566",
    trivial   = "808080",
    unknown   = "A0A0A0",
}
local cat = entry.mobCategory or "unknown"
local colorHex = CATEGORY_COLORS[cat] or "A0A0A0"
local displayCat = cat:sub(1,1):upper() .. cat:sub(2)  -- capitalize first letter
local categoryTag = "|cff" .. colorHex .. "[" .. displayCat .. "]|r"
headerNameStr:SetText(mobName .. " " .. categoryTag)
```

### ApplySearchFilter category matching (addition at line ~1142)

```lua
-- Source: ConfigFrame.lua ApplySearchFilter extension
local filter = text:lower():gsub("-", "")  -- strip hyphens

-- Inside the dungeonEntry/mob loop, after mobNameMatch is computed:
local entry = ns.AbilityDB[npcID]
local categoryMatch = false
if entry and entry.mobCategory then
    categoryMatch = entry.mobCategory:find(filter, 1, true) ~= nil
end

if mobNameMatch or categoryMatch then
    currentMatchedMobs[npcID] = true
    -- Do NOT set currentMatchedSpells — show all abilities for this mob
else
    -- existing ability name check (unchanged)
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `entry.mobClass or "UNKNOWN"` in header | `entry.mobCategory` with color tag | Phase 19 broke it; Phase 21 fixes it | Header shows accurate category instead of "UNKNOWN" for every mob |
| Search: mob name + spell name only | Search: mob name + category + spell name | Phase 21 addition | Users can type "boss" or "caster" to filter |

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None (WoW addon — manual in-game testing only) |
| Config file | N/A |
| Quick run command | `./scripts/install.bat` then `/tpw` in-game |
| Full suite command | Manual checklist below |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UI-01 | Mob header shows color-coded `[Category]` tag | manual | `./scripts/install.bat`, open config, select any Skyreach mob | N/A |
| UI-02 | Category tag is not editable | manual | Click the header text — no input field should appear | N/A |
| UI-03 | Searching "boss", "caster", "rogue", "mini-boss", "miniboss", "unknown" returns matching mobs | manual | Type each term into config search box, verify correct mobs appear | N/A |

### Sampling Rate
- **Per task commit:** Install and open config window, spot-check one mob header
- **Per wave merge:** Run full manual checklist below

### Manual Test Checklist
1. Open config window (`/tpw` → config button)
2. Select a Skyreach boss (e.g., Rukhmar) — header should show gold `[Boss]` tag
3. Select a Skyreach caster — header should show cyan `[Caster]` tag
4. Select any non-Skyreach mob — header should show gray `[Unknown]` tag
5. Search "boss" — only boss-category mobs visible
6. Search "caster" — only caster-category mobs visible
7. Search "mini-boss" — miniboss mobs visible (hyphen normalized)
8. Search "war" — warrior mobs visible (partial match)
9. Search "unknown" — all non-Skyreach mobs visible
10. Clear search — all mobs restored

### Wave 0 Gaps
None — no automated test infrastructure exists or is expected for WoW addon UI. Manual testing is the sole validation method per project conventions.

---

## Open Questions

1. **`CATEGORY_COLORS` constant placement**
   - What we know: Must be defined before `PopulateRightPanel` uses it
   - What's unclear: Whether to define at module top, inside PopulateRightPanel as a local, or as a shared ns.* constant
   - Recommendation: Define as a local table immediately before (or at the top of) `PopulateRightPanel`. If `ApplySearchFilter` also needs it for any reason (it doesn't currently), promote to module-level local.

2. **`string.gsub("-", "")` vs `string.gsub("%-", "")**
   - What we know: In Lua pattern matching, `-` is a special quantifier character
   - What's unclear: Whether `string.find`/`gsub` plain flag (4th arg `true`) applies to gsub
   - Recommendation: Use `string.gsub(filter, "%-", "")` — the `%-` escapes the hyphen in Lua patterns. `gsub` does NOT have a plain-text flag like `find`. This is the safe form.

---

## Sources

### Primary (HIGH confidence)
- Direct source read: `UI/ConfigFrame.lua` lines 533-566 (header), 1115-1234 (ApplySearchFilter) — broken state confirmed
- Direct source read: `Data/Skyreach.lua` lines 1-50 — `mobCategory` field values confirmed
- Direct source read: `.planning/phases/21-config-display/21-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence)
- WoW color escape pattern `|cffRRGGBB...|r` — standard documented WoW addon pattern, confirmed in use throughout WoW addon ecosystem

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no external libraries; all tools are built-in WoW Lua or already in use in this file
- Architecture: HIGH — both change points are directly identified from source reads with exact line numbers
- Pitfalls: HIGH — derived from direct source analysis plus Lua pattern-matching knowledge (gsub hyphen escaping)

**Research date:** 2026-03-23
**Valid until:** N/A — no external dependencies that can change; research is valid until the source files change
