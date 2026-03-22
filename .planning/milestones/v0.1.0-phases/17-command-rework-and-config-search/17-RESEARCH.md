# Phase 17: Command Rework and Config Search - Research

**Researched:** 2026-03-20
**Domain:** WoW Lua UI — slash commands, EditBox filtering, StaticPopup, ConfigFrame restructure
**Confidence:** HIGH

## Summary

This phase is a pure UI rework against existing, well-understood code. All required patterns
are already present in the codebase — the work is reconfiguring and extending them rather than
introducing new technology. Core.lua's slash handler needs a default-target swap and a new `route`
subcommand. ConfigFrame.lua needs a top bar row, a search EditBox with debounced filtering, and
right-panel header enrichment. PackFrame.lua needs one button removed and two remaining buttons
spread wider.

The search feature is the most complex piece: BuildDungeonIndex must accept an optional filter
string and return a filtered tree; PopulateRightPanel must accept an optional set of matching
spellIDs to limit displayed abilities. The debounce is a C_Timer.After / cancel-handle pattern
already well-established in WoW addon authoring. GetSpellNameSafe already handles dynamic spell
name resolution for matching.

**Primary recommendation:** Read and edit Core.lua, ConfigFrame.lua, and PackFrame.lua directly.
No new libraries required. All patterns are already in the codebase.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Slash Command Mapping**
- `/tpw` (no args) → opens config window (was: route window)
- `/tpw config` → also opens config window (same as bare /tpw)
- `/tpw route` → opens route window
- All other commands unchanged: `debug`, `status`, `clear`, `select`, `start`, `stop`, `help`
- Subcommands are case-insensitive (e.g., `/tpw Route`, `/tpw DEBUG`, `/tpw Help` all work)
- WoW enforces lowercase on the `/tpw` part — only subcommand needs case handling

**Help Command**
- `/tpw help` shows commands grouped by category with short descriptions
- Categories: Windows, Route, Debug (Claude's discretion on exact grouping and wording)

**Search Box**
- Full-width search bar above both panels (below title bar, in top bar row with buttons)
- Right-aligned in the top bar row
- Debounced filtering (0.3s pause before filtering)
- Searches both mob names AND skill names (uses C_Spell.GetSpellInfo for dynamic names)
- When search matches a skill name, the parent mob appears in the tree (dungeon auto-expands)
- Selecting a mob while search is active shows only matching skills in right panel
- Closing the config window fully resets the search (clears text + restores full tree)
- No X/clear button on search box — closing window is the only reset mechanism

**Config Window Top Bar Layout**
- Top bar row (below title, above panels): `[Route] [Reset All]` on left, `[Search box]` on right
- All in the same horizontal line

**Reset All Button**
- Moved from bottom-right footer to top bar (left side, next to Route button)
- Now resets ALL dungeons globally (was: current dungeon only)
- Confirmation dialog: "This will reset all tracked skills and label configurations. Proceed?" with Yes/No buttons (StaticPopup)

**Route Window Button Layout**
- Config button REMOVED from route window footer
- Remaining buttons: `[Clear]` on left, `[Import]` on right — spread across footer width
- Combat mode buttons row unchanged

**Config Window Right Panel Header**
- Square mob portrait before mob name (same NPC portrait as left panel, using GetPortraitTexture)
- Mob name with class: `[portrait] Mob Name - CLASS`
- Visual horizontal divider line between mob header and skill list (texture line, like existing divider between left/right panels)

### Claude's Discretion
- Exact search box dimensions and EditBox styling (pushed-in background like label/TTS fields)
- Help command formatting (color codes, line breaks for chat readability)
- Portrait size in right panel header (larger than left panel 22px — suggest 32-40px)
- Divider line styling (color, thickness — match existing vertical divider pattern)
- How debounce timer is implemented (C_Timer.After with cancel pattern)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CMD-01 | `/tpw` opens config window; `/tpw route` opens route window; commands case-insensitive | Core.lua slash handler analyzed — swap default branch, add `route` case, apply `cmd:lower()` |
| CMD-02 | `/tpw help` shows complete list of available commands with descriptions | Existing help is a single print line — replace with multi-line grouped output |
| CMD-03 | Remove config button from route window; add route button to config window | PackFrame.lua configBtn identified at lines 312-318; ConfigFrame top bar needs routeBtn |
| SEARCH-01 | Config window search box filters dungeon/mob tree by mob name and skill name | BuildDungeonIndex returns sorted list — add filter param; GetSpellNameSafe available for name matching |
| SEARCH-02 | Selecting a mob while search active shows only matching skills; closing window resets search | PopulateRightPanel receives filtered ability set; OnHide hook clears search state and calls RebuildLayout |
| UIPOL-01 | Reposition Reset All button to work with new search box layout | resetAllBtn currently at BOTTOMRIGHT of configFrame (line 778); move anchor to top bar; update reset logic to clear all dungeons |
| UIPOL-02 | Update remaining button layout in route window after config button removal | clearBtn currently anchors RIGHT of importBtn via configBtn; remove configBtn, change clearBtn anchor to BOTTOMLEFT |
</phase_requirements>

---

## Standard Stack

### Core (all already present — no new dependencies)

| API / Pattern | Version | Purpose | Source in Codebase |
|---------------|---------|---------|-------------------|
| `SlashCmdList` + `SLASH_*` | WoW API | Slash command registration | Core.lua line 82-83 |
| `C_Timer.After(delay, fn)` | WoW API | Debounce delay | Used in PackFrame.lua line 533 |
| `StaticPopupDialogs["KEY"]` | WoW API | Confirmation dialogs | PackFrame.lua line 96-110 (TPW_CONFIRM_CLEAR) |
| `EditBox:SetScript("OnTextChanged", fn)` | WoW API | Live search trigger | Used in ConfigFrame.lua (labelEditBox, ttsEditBox) |
| `SetPortraitTextureFromCreatureDisplayID` | WoW API | NPC portrait rendering | ConfigFrame.lua line 46 (GetPortraitTexture) |
| `GetSpellNameSafe(ability)` | Local helper | Spell name for search matching | ConfigFrame.lua line 211-216 |
| `AddEditBoxBackground(eb)` | Local helper | Pushed-in EditBox visual | ConfigFrame.lua line 57-86 |

### No New Libraries Required

All patterns exist in the codebase. This phase is reconfiguration and extension only.

---

## Architecture Patterns

### Current Slash Command Structure (Core.lua lines 83-123)

```lua
-- Current: cmd/arg split, then if/elseif chain, no lowercasing
local cmd, arg = msg:match("^(%S+)%s*(.*)$")
if cmd == "select" then ...
elseif cmd == "debug" then ...
-- bare /tpw (cmd == nil) falls to else: opens PackUI
```

**What changes:**
- Add `cmd = cmd and cmd:lower() or ""` normalization immediately after the match
- Change `else` branch (bare `/tpw`) to open ConfigUI instead of PackUI
- Add `elseif cmd == "config" then ConfigUI.Toggle()` (already exists at line 115 — keep it)
- Add `elseif cmd == "route" then PackUI.Toggle()`
- Replace the single-line help print with multi-line grouped output

### Debounce Pattern for Search Box

WoW does not have a built-in debounce. Standard pattern:

```lua
local searchTimer = nil

local function ApplySearchFilter(text)
    -- do filtering work here
end

searchEditBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()
    if searchTimer then
        searchTimer:Cancel()
        searchTimer = nil
    end
    searchTimer = C_Timer.NewTimer(0.3, function()
        searchTimer = nil
        ApplySearchFilter(text)
    end)
end)
```

**Note:** `C_Timer.NewTimer` returns a handle with `:Cancel()`. This is the correct pattern for
cancellable timers. `C_Timer.After` does not return a cancellable handle — use `C_Timer.NewTimer`
for debounce.

### BuildDungeonIndex Filter Extension

Current function (ConfigFrame.lua lines 232-258) iterates `ns.DUNGEON_IDX_MAP` and
`ns.DungeonEnemies`, builds a sorted list of `{dungeonIdx, dungeonName, mobs}`.

**For search filtering**, BuildDungeonIndex should accept an optional `filterText` string:

```lua
local function BuildDungeonIndex(filterText)
    -- normalize
    local filter = filterText and filterText:lower() or nil

    for dungeonIdx, info in pairs(ns.DUNGEON_IDX_MAP) do
        local enemies = ns.DungeonEnemies[dungeonIdx]
        if enemies then
            local mobs = {}
            for _, enemy in pairs(enemies) do
                if enemy.id and ns.AbilityDB[enemy.id] and not seen[enemy.id] then
                    -- check filter
                    local include = true
                    if filter and filter ~= "" then
                        include = false
                        -- mob name match
                        if (enemy.name or ""):lower():find(filter, 1, true) then
                            include = true
                        end
                        -- skill name match
                        if not include then
                            for _, ability in ipairs(ns.AbilityDB[enemy.id].abilities or {}) do
                                local spellName = GetSpellNameSafe(ability):lower()
                                if spellName:find(filter, 1, true) then
                                    include = true
                                    break
                                end
                            end
                        end
                    end
                    if include then
                        -- store matched spellIDs for right panel filtering
                        ...
                    end
                end
            end
        end
    end
end
```

Each mob entry in the result should carry `matchedSpellIDs` — a set of spellIDs that matched the
filter. When no filter is active, `matchedSpellIDs` is nil (show all abilities).

### PopulateRightPanel Filter Extension

Current signature: `PopulateRightPanel(npcID)` — iterates all `entry.abilities`.

**Extension:** Accept optional `matchedSpellIDs` table (set of spellID → true). When present,
skip abilities not in the set:

```lua
local function PopulateRightPanel(npcID, matchedSpellIDs)
    ...
    for abilityIdx, ability in ipairs(entry.abilities) do
        -- skip if filter active and this spell not matched
        if matchedSpellIDs and not matchedSpellIDs[ability.spellID] then
            -- hide this row
            goto continue
        end
        ...
    end
end
```

**Lua note:** `goto continue` with `::continue::` label at loop bottom is idiomatic in WoW Lua
for `continue` emulation. Alternatively, wrap the body in `if not skip then ... end`.

### Module-Level Search State

Add to ConfigFrame.lua module-level state (lines 91-99):

```lua
local currentSearchText = ""         -- last applied filter
local currentMatchedSpellIDs = {}    -- npcID -> {spellID -> true} for current filter
local searchTimer = nil              -- C_Timer.NewTimer handle
```

When `ApplySearchFilter` runs:
1. Rebuild `currentMatchedSpellIDs` from BuildDungeonIndex with filter
2. Rebuild tree nodes (BuildLeftPanel or a re-population function)
3. Auto-expand dungeons that have matching mobs
4. If `selectedNpcID` is still valid under the filter, re-call PopulateRightPanel with its matched set

### Search Reset on Window Hide

```lua
configFrame:SetScript("OnHide", function()
    currentSearchText = ""
    currentMatchedSpellIDs = {}
    if searchTimer then
        searchTimer:Cancel()
        searchTimer = nil
    end
    if searchEditBox then
        searchEditBox:SetText("")
    end
    -- Rebuild tree without filter
    RebuildLayout()  -- or full re-population
end)
```

### Top Bar Row Layout (ConfigFrame)

Current left panel anchors: `SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -32)` — the -32 offset
accommodates the title bar only.

With the new top bar row (height ~30px), both left and right panels shift down:

```
configFrame (580 x 480)
├── Title bar: y = 0 to -22 (built by BasicFrameTemplateWithInset)
├── Top bar row: y = -26 to -56  (30px tall)
│   ├── routeBtn   SetPoint("TOPLEFT",  configFrame, "TOPLEFT",  12, -30)
│   ├── resetAllBtn SetPoint("LEFT", routeBtn, "RIGHT", 8, 0)
│   └── searchEditBox SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -12, -30)
│                     SetPoint("LEFT", resetAllBtn, "RIGHT", 8, 0) or fixed width
├── Vertical divider: y = -58 to bottom
├── Left panel: SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -62)  (was -32)
└── Right panel: SetPoint("TOPLEFT", configFrame, "TOPLEFT", 228, -62) (was -32)
```

Exact y-offsets are discretionary — key constraint is consistent spacing.

### Right Panel Header Enrichment

Current header is a FontString at TOPLEFT of rightScrollChild.

Replace with a sub-frame containing:
1. A portrait Texture (32x32 or 36x36, masked circular)
2. A FontString for "Mob Name - CLASS" anchored LEFT of portrait
3. A horizontal divider Texture anchored below (matching vertical divider color)

```lua
-- Right panel header container (replaces rightPanelHeader FontString)
local headerFrame = CreateFrame("Frame", nil, rightScrollChild)
headerFrame:SetPoint("TOPLEFT",  rightScrollChild, "TOPLEFT",  4, -4)
headerFrame:SetPoint("TOPRIGHT", rightScrollChild, "TOPRIGHT", -4, -4)
headerFrame:SetHeight(HEADER_PORTRAIT_SIZE + 8)

local headerPortrait = headerFrame:CreateTexture(nil, "ARTWORK")
headerPortrait:SetSize(HEADER_PORTRAIT_SIZE, HEADER_PORTRAIT_SIZE)
headerPortrait:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
headerPortrait:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")

local headerNameStr = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerNameStr:SetPoint("LEFT",  headerPortrait, "RIGHT", 6, 0)
headerNameStr:SetPoint("RIGHT", headerFrame,    "RIGHT", 0, 0)
headerNameStr:SetJustifyH("LEFT")

-- Horizontal divider below header
local hDivider = rightScrollChild:CreateTexture(nil, "ARTWORK")
hDivider:SetColorTexture(0.4, 0.4, 0.4, 0.8)   -- match vertical divider
hDivider:SetHeight(1)
hDivider:SetPoint("TOPLEFT",  rightScrollChild, "TOPLEFT",  0, -(HEADER_PORTRAIT_SIZE + 12))
hDivider:SetPoint("TOPRIGHT", rightScrollChild, "TOPRIGHT", 0, -(HEADER_PORTRAIT_SIZE + 12))
```

`PopulateRightPanel` updates `headerPortrait` via `GetPortraitTexture(headerPortrait, npcID)` and
`headerNameStr:SetText(mobName .. " - " .. mobClass)`.

The `yOffset` for skill rows (currently `local yOffset = 32`) must increase to accommodate the
taller header: `local yOffset = HEADER_PORTRAIT_SIZE + 16` or similar.

### PackFrame Footer Rework

Current footer (PackFrame.lua lines 294-318):

```
importBtn  (BOTTOMRIGHT, -12, 8)   → keep, same anchor
clearBtn   (RIGHT, importBtn, LEFT, -8, 0)  → keep anchor but spread
configBtn  (RIGHT, clearBtn, LEFT, -8, 0)   → REMOVE
```

After removing configBtn:
- `importBtn`: keep at BOTTOMRIGHT
- `clearBtn`: anchor to BOTTOMLEFT so buttons are spread across footer width

```lua
-- New clearBtn anchor (spread left)
clearBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 8)
-- importBtn stays BOTTOMRIGHT unchanged
```

Size stays 80px each. The footer has ~276px of width (300 - 12 - 12); 80 left + 80 right leaves
116px gap — visually balanced.

### Reset All — Global Reset Logic

Current Reset All (ConfigFrame.lua lines 780-792) only resets the currently selected dungeon.

New behavior: reset ALL dungeons:

```lua
resetAllBtn:SetScript("OnClick", function()
    StaticPopup_Show("TPW_CONFIRM_RESET_ALL")
end)

StaticPopupDialogs["TPW_CONFIRM_RESET_ALL"] = {
    text = "This will reset all tracked skills and label configurations. Proceed?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        -- Clear all skill config for all known npcIDs
        for npcID, _ in pairs(ns.AbilityDB or {}) do
            ns.db.skillConfig[npcID] = nil
        end
        -- Refresh right panel if a mob is selected
        if selectedNpcID then
            PopulateRightPanel(selectedNpcID)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
```

### Help Command Grouped Output

Current (Core.lua line 118):
```lua
print("|cff00ccffTPW|r Commands: select <dungeon>, start [pack#], stop, status, debug, clear, config, help")
```

New grouped format:

```lua
elseif cmd == "help" then
    local c = "|cff00ccffTPW|r"
    print(c .. " |cffffff00Windows:|r")
    print(c .. "  /tpw          - Open config window")
    print(c .. "  /tpw config   - Open config window")
    print(c .. "  /tpw route    - Open route window")
    print(c .. " |cffffff00Route:|r")
    print(c .. "  /tpw select <key> - Select dungeon")
    print(c .. "  /tpw start [#]    - Start timers (optional pack#)")
    print(c .. "  /tpw stop         - Cancel all timers")
    print(c .. "  /tpw clear        - Clear imported route")
    print(c .. " |cffffff00Debug:|r")
    print(c .. "  /tpw status   - Print current state")
    print(c .. "  /tpw debug    - Toggle debug logging")
```

Exact wording is Claude's discretion per CONTEXT.md.

### Anti-Patterns to Avoid

- **`C_Timer.After` for debounce:** It returns nil — cannot be cancelled. Use `C_Timer.NewTimer` instead.
- **Rebuilding entire left panel frame tree on every search keystroke:** Expensive. Prefer hide/show
  of existing mob rows vs. destroying and recreating frames. The nodes table already tracks frames;
  show/hide the content frames and header frames based on filter matches.
- **Setting search text from `OnTextChanged`:** Causes infinite loop. Use `if self:HasFocus()` guard
  or only set text from code paths that don't re-trigger the script.
- **Modifying `nodes` table inside `RebuildLayout`:** RebuildLayout is layout-only; filter state
  lives in module-level variables read by a search-aware rebuild function.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Confirmation dialog | Custom modal frame | `StaticPopupDialogs` + `StaticPopup_Show` | Already used for TPW_CONFIRM_CLEAR; WoW handles stacking, escape, focus |
| Debounce | Manual frame OnUpdate counter | `C_Timer.NewTimer(0.3, fn)` | Cleaner, accurate, cancellable with `:Cancel()` |
| Portrait rendering | Manual texture file path | `SetPortraitTextureFromCreatureDisplayID` + class icon fallback | Already in GetPortraitTexture |
| Spell name resolution | String table | `GetSpellNameSafe(ability)` | Already handles hand-authored names and API fallback |
| EditBox pushed-in style | Raw SetBackdrop | `AddEditBoxBackground(eb)` | Already in ConfigFrame.lua, consistent look |

---

## Common Pitfalls

### Pitfall 1: Left Panel Not Rebuilding After Filter
**What goes wrong:** Tree nodes are built once in BuildLeftPanel and never rebuilt. Filtering hides/shows
content frames but the dungeon header expand state and layout positions are stale.
**Why it happens:** RebuildLayout only repositions; it doesn't filter. If filter changes mob visibility,
RebuildLayout must know which dungeons have visible mobs.
**How to avoid:** Either (a) mark nodes as `node.hasMatches = true/false` before calling RebuildLayout
and skip hidden dungeons, or (b) rebuild the entire mob row visibility inside content frames before
calling RebuildLayout.
**Warning signs:** Collapsed dungeons still appear, or empty dungeon headers show with no mobs under them.

### Pitfall 2: Right Panel yOffset Breaks with New Header
**What goes wrong:** PopulateRightPanel starts skill rows at `local yOffset = 32`. After adding a
portrait header (32-40px) plus divider (1px) plus padding, rows overlap the header.
**Why it happens:** yOffset is hardcoded, not derived from header frame height.
**How to avoid:** Set yOffset to `HEADER_PORTRAIT_SIZE + 16` (or derive from headerFrame's actual
bottom position) before beginning skill row layout.

### Pitfall 3: Search Resets Selected Mob State Incorrectly
**What goes wrong:** When filter changes, selectedNpcID may no longer match any visible mob. Calling
PopulateRightPanel on a hidden mob causes a confusing right panel showing filtered results for a mob
not visible in the tree.
**How to avoid:** After applying a filter, check if selectedNpcID is still in the filtered set. If not,
clear selectedNpcID and set right panel to "Select a mob" state.

### Pitfall 4: StaticPopup Key Collision
**What goes wrong:** Two different dialogs registered with the same key overwrite each other.
**How to avoid:** Use `TPW_CONFIRM_RESET_ALL` (distinct from existing `TPW_CONFIRM_CLEAR`).

### Pitfall 5: Case-Insensitive Subcommand Without nil Guard
**What goes wrong:** Bare `/tpw` produces `cmd = nil`; calling `nil:lower()` errors.
**Current code:** `if cmd == "select" then` — works because nil comparisons are safe in Lua.
**With lowercasing:** `cmd = cmd and cmd:lower() or ""` — safe nil guard. Then `if cmd == "route"` works for bare `/tpw` (cmd becomes `""`), and the else branch handles it.

### Pitfall 6: configBtn Remove Breaks clearBtn Anchor
**What goes wrong:** clearBtn is anchored `SetPoint("RIGHT", importBtn, "LEFT", -8, 0)` — independent
of configBtn. Removing configBtn does not break this anchor. But the CONTEXT.md decision is to spread
Clear to the LEFT side, requiring an anchor change.
**How to avoid:** Change clearBtn to `SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 8)` at the same
time configBtn is removed. Don't just remove configBtn and leave clearBtn bunched to the right.

---

## Code Examples

### Existing Vertical Divider (match this for horizontal divider)
```lua
-- Source: ConfigFrame.lua lines 748-752
local divider = configFrame:CreateTexture(nil, "ARTWORK")
divider:SetColorTexture(0.4, 0.4, 0.4, 0.8)
divider:SetWidth(1)
divider:SetPoint("TOP",    configFrame, "TOPLEFT",    225, -30)
divider:SetPoint("BOTTOM", configFrame, "BOTTOMLEFT", 225,  8)
```

Horizontal divider uses `SetHeight(1)` and `SetPoint("TOPLEFT"/"TOPRIGHT")` instead of TOP/BOTTOM.

### Existing StaticPopup Pattern (model for Reset All dialog)
```lua
-- Source: PackFrame.lua lines 96-110
StaticPopupDialogs["TPW_CONFIRM_CLEAR"] = {
    text = "Clear imported route? This cannot be undone.",
    button1 = "Clear",
    button2 = "Cancel",
    OnAccept = function()
        local key = GetSelectedDungeonKey()
        if key then ns.Import.Clear(key) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
-- Triggered with:
StaticPopup_Show("TPW_CONFIRM_CLEAR")
```

### GetPortraitTexture (reuse in right panel header)
```lua
-- Source: ConfigFrame.lua lines 42-54
local function GetPortraitTexture(tex, npcID)
    local displayId = npcIdToDisplayId[npcID]
    if displayId and displayId > 0 then
        SetPortraitTextureFromCreatureDisplayID(tex, displayId)
        return
    end
    local mobClass = npcIdToClass[npcID]
    if mobClass and CLASS_ICON[mobClass] then
        tex:SetTexture(CLASS_ICON[mobClass])
        return
    end
    tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
end
```

### GetSpellNameSafe (use for search name matching)
```lua
-- Source: ConfigFrame.lua lines 211-216
local function GetSpellNameSafe(ability)
    if ability.name then return ability.name end
    local info = C_Spell.GetSpellInfo(ability.spellID)
    if info and info.name then return info.name end
    return "Spell " .. ability.spellID
end
```

### AddEditBoxBackground (apply to search EditBox)
```lua
-- Source: ConfigFrame.lua lines 57-86
-- Call after creating the search EditBox:
AddEditBoxBackground(searchEditBox)
```

### C_Timer.NewTimer Debounce (correct cancellable form)
```lua
-- Standard WoW addon debounce pattern (C_Timer.After cannot be cancelled)
local searchTimer = nil
editBox:SetScript("OnTextChanged", function(self)
    if searchTimer then searchTimer:Cancel() ; searchTimer = nil end
    local text = self:GetText()
    searchTimer = C_Timer.NewTimer(0.3, function()
        searchTimer = nil
        ApplySearchFilter(text)
    end)
end)
```

### Existing Left Panel Anchor (update after adding top bar)
```lua
-- Current: ConfigFrame.lua line 597-598
leftScrollFrame:SetPoint("TOPLEFT",     parent, "TOPLEFT",     12, -32)
-- After adding 30px top bar, change to:
leftScrollFrame:SetPoint("TOPLEFT",     parent, "TOPLEFT",     12, -62)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bare `/tpw` → PackUI | Bare `/tpw` → ConfigUI | Phase 17 | Users reach config directly without knowing subcommand |
| Reset All = current dungeon only | Reset All = global (all dungeons) | Phase 17 | Bulk reset now safe behind confirmation dialog |
| configBtn in PackFrame footer | Route button in ConfigFrame top bar | Phase 17 | Consistent: each window opens the other via top-level button |

---

## Open Questions

1. **Search box width vs. Route + Reset All buttons**
   - What we know: Top bar is `[Route] [Reset All] ... [Search box]`, all on one row. configFrame is 580px wide.
   - What's unclear: If Route (80px) + gap (8px) + Reset All (80px) + gap (8px) = 176px used, search gets ~580 - 176 - 24 (margins) = ~380px. That's generous — possibly too wide.
   - Recommendation: Set search box to a fixed width (e.g., 200px) anchored TOPRIGHT with margin, and leave the gap between Reset All and search empty. Keeps layout clean.

2. **Tree rebuild strategy for search**
   - What we know: nodes table holds header and content frames; BuildLeftPanel creates them once.
   - What's unclear: Whether to add show/hide logic to existing node frames or full-rebuild on each filter change.
   - Recommendation: Prefer hide/show of existing nodes and mob rows — avoids frame creation overhead on every keystroke. Mark `node.visible = false` for dungeons with no matching mobs and skip them in RebuildLayout.

3. **`OpenToMob` interaction with search state**
   - What we know: `ns.ConfigUI.OpenToMob` is called from PackFrame portrait clicks; it expands a dungeon and selects a mob.
   - What's unclear: Should OpenToMob clear the search filter?
   - Recommendation: Yes — clear search text and reset filter when OpenToMob is called, so the full tree is visible with the target mob expanded.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual in-game (no automated test runner for WoW addons) |
| Config file | n/a |
| Quick run command | `./scripts/install.bat` then `/reload` in WoW |
| Full suite command | n/a — manual test checklist per phase |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CMD-01 | `/tpw` opens config, `/tpw route` opens route, case-insensitive | manual | n/a | n/a |
| CMD-02 | `/tpw help` shows grouped commands | manual | n/a | n/a |
| CMD-03 | Config button gone from route window; route button in config window | manual | n/a | n/a |
| SEARCH-01 | Search box filters mob/skill tree in real time | manual | n/a | n/a |
| SEARCH-02 | Right panel shows only matching skills; close resets search | manual | n/a | n/a |
| UIPOL-01 | Reset All in top bar, confirmation dialog, global reset | manual | n/a | n/a |
| UIPOL-02 | Clear and Import spread in route footer | manual | n/a | n/a |

### Sampling Rate
- **Per task:** Deploy with `./scripts/install.bat`, `/reload`, exercise the changed feature
- **Phase gate:** All 7 requirements manually verified before `/gsd:verify-work`

### Wave 0 Gaps
None — no test infrastructure exists for WoW addons; all verification is manual in-game.

---

## Sources

### Primary (HIGH confidence)
- `Core.lua` (lines 82-123) — Complete slash command handler, all existing commands, bare-/tpw behavior
- `UI/ConfigFrame.lua` (full file) — BuildConfigFrame, BuildLeftPanel, BuildDungeonIndex, PopulateRightPanel, RebuildLayout, GetPortraitTexture, GetSpellNameSafe, AddEditBoxBackground, resetAllBtn, rightPanelHeader
- `UI/PackFrame.lua` (lines 293-318) — Footer buttons (configBtn, clearBtn, importBtn), StaticPopupDialogs pattern
- `.planning/phases/17-command-rework-and-config-search/17-CONTEXT.md` — All locked decisions

### Secondary (MEDIUM confidence)
- WoW addon community convention: `C_Timer.NewTimer` for cancellable timers vs `C_Timer.After` — verified by the WoW API documentation pattern where After has no return value and NewTimer returns a handle object with `:Cancel()`

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all patterns verified directly in source files
- Architecture: HIGH — existing frame structure is fully read; extension points are clear
- Pitfalls: HIGH — identified from direct code reading (anchor dependencies, yOffset hardcoding)

**Research date:** 2026-03-20
**Valid until:** 2026-04-20 (stable WoW API, no fast-moving dependencies)
