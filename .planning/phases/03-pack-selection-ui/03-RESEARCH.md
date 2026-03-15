# Phase 3: Pack Selection UI - Research

**Researched:** 2026-03-15
**Domain:** WoW Addon Lua/XML — pure Lua UI frames, ScrollBox tree list, BackdropTemplate, UISpecialFrames, SavedVariables position persistence
**Confidence:** HIGH (core WoW frame APIs are stable and well-documented; ScrollBox tree list API is current)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Medium dialog size (~300x400px), standard WoW panel look
- Accordion-style sections: dungeon names as collapsible headers, packs listed underneath
- Each pack row shows **name only** (no mob count or mob names)
- Window is **movable**, position **saved in SavedVariables** across sessions
- Standard title bar with addon name and close button
- Selected pack gets a **border + icon** (glowing border and/or checkmark)
- Pack rows show **combat state**: active pack has a "fighting" indicator, completed packs show a checkmark
- Clicking any pack re-selects it (including completed packs — for wipe recovery)
- Selection **persists** when window is closed/reopened, clears on zone change (existing Reset behavior)
- **No pull button** — selecting a pack sets it as active, timers auto-start on combat (PLAYER_REGEN_DISABLED)
- Window **stays open during combat** so player can see active pack and re-select if needed
- Clicking a pack under a different dungeon requires **clicking the dungeon header first** (expand accordion), then clicking the pack
- Pack list **live-updates** when auto-advance moves to next pack on combat end
- `/tpw` with no arguments **toggles** the window (open if closed, close if open)
- Existing subcommands (`select`, `start`, `stop`, `status`) **kept alongside UI** for power users and debugging
- **Escape closes** the window (register with UISpecialFrames)

### Claude's Discretion
- Exact frame dimensions and backdrop style
- Accordion expand/collapse animation (or instant toggle)
- Combat state icon choices (skull, swords, checkmark, etc.)
- ScrollFrame implementation details
- How to refresh the pack list when auto-advance fires (callback, event, polling)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UI-01 | Scrollable pack list grouped by dungeon area | ScrollBox tree list (`CreateScrollBoxListTreeListView` + `CreateTreeDataProvider`) provides native collapsible hierarchy; nodes support `ToggleCollapsed()` for accordion behavior |
| UI-02 | Click-to-select a pack from the list | Tree list element initializer sets `OnClick` script on each row button; click calls `CombatWatcher:SelectDungeon(key)` then sets `currentPackIndex` |
| UI-03 | Visual indicator showing which pack is currently active/selected | Row buttons track selection by comparing `CombatWatcher:GetState()` return values; selected row gets highlighted texture or `SetBackdropBorderColor`; combat state drives icon via built-in WoW texture paths |
| UI-04 | Slash command `/tpw` to open the addon | Core.lua slash handler already registered; bare `/tpw` (no cmd match) must call `TPWFrame:Show()`/`:Hide()` toggle; frame named globally to satisfy `UISpecialFrames` requirement |
</phase_requirements>

---

## Summary

Phase 3 builds a pure Lua + XML addon window — no external libraries. The window is a standard WoW dialog frame (BackdropTemplate for styling, `BasicFrameTemplateWithInset` or equivalent for title bar) containing a ScrollBox tree list that renders dungeon headers as collapsible nodes and pack names as leaf rows.

The modern WoW ScrollBox API (introduced in Dragonflight, current in Midnight) is the correct tool. It provides a tree list view with built-in `node:ToggleCollapsed()` — the exact behavior needed for accordion dungeon sections. The older `FauxScrollFrame`/`HybridScrollFrame` approach is legacy and not recommended for new addons targeting Interface 120000+.

The main implementation complexity is live-updating the UI when `CombatWatcher` state changes (auto-advance on combat end). The cleanest approach without adding event infrastructure is a thin callback hook: `CombatWatcher` calls an optional `ns.PackUI:Refresh()` function after state transitions. This avoids polling and keeps UI as an optional subscriber.

**Primary recommendation:** Build `UI/PackFrame.lua` (pure Lua) with a globally-named frame, ScrollBox tree list for the accordion list, BackdropTemplate for styling, UISpecialFrames for Escape handling, and a `Refresh()` method called from `CombatWatcher` state transitions. Register the frame name globally so UISpecialFrames works. TOC gets `UI\PackFrame.lua` appended after the Engine files.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `CreateFrame` | Native (all versions) | Create any UI frame type | Foundation of all WoW addon UI |
| `BackdropTemplate` | Native (Patch 9.0.1+, current) | Frame background + border styling | Replaced SetBackdrop in 9.0.1; required mixin for modern backdrop usage |
| `WowScrollBoxList` template | Native (Dragonflight+, current) | Scrollable list container | Modern replacement for FauxScrollFrame; supports tree lists natively |
| `CreateScrollBoxListTreeListView` | Native (Dragonflight+, current) | Tree list view with collapsible nodes | Provides ToggleCollapsed, hierarchical data — exact fit for accordion |
| `CreateTreeDataProvider` | Native (Dragonflight+, current) | Data binding for tree list | Insert dungeon nodes, insert pack children into each node |
| `ScrollUtil.InitScrollBoxListWithScrollBar` | Native (Dragonflight+, current) | Wire ScrollBox + ScrollBar + ScrollView | Standard initialization pattern |
| `UISpecialFrames` | Native (all versions) | Register frame for Escape key close | Table that WoW checks on Escape; frame must have a global name |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `MinimalScrollBar` template | Native (Dragonflight+) | Thin scrollbar matching modern UI | Use when window content may exceed frame height |
| `UIPanelButtonTemplate` | Native (all versions) | Standard button for list rows | Simple, styled button matching WoW panel aesthetic |
| `GameFontNormal` / `GameFontHighlight` | Native | Standard text fonts | Use for pack row labels to match native feel |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ScrollBox tree list | FauxScrollFrame (legacy) | FauxScrollFrame is simpler but deprecated; requires manual layout math; no native tree/node concept |
| ScrollBox tree list | Manual accordion (show/hide child frames) | Manual approach avoids ScrollBox complexity but requires layout recalculation on expand/collapse and doesn't handle overflow scrolling |
| BackdropTemplate | Texture layers manually | BackdropTemplate is the supported API; manual textures work but require more code |

**Installation:** No external dependencies — pure WoW FrameXML APIs. TOC update only.

---

## Architecture Patterns

### Recommended File Structure
```
TerriblePackWarnings/
├── Core.lua                    -- Slash command: add toggle logic for bare /tpw
├── Engine/
│   ├── Scheduler.lua
│   └── CombatWatcher.lua       -- Add optional ns.PackUI:Refresh() callback hook
├── Display/
│   └── BossWarnings.lua
├── Data/
│   └── WindrunnerSpire.lua
└── UI/
    └── PackFrame.lua           -- New: entire window, accordion list, combat state
```

### TOC Load Order
```
Core.lua
Engine\Scheduler.lua
Engine\CombatWatcher.lua
Display\BossWarnings.lua
Data\WindrunnerSpire.lua
UI\PackFrame.lua
```

PackFrame.lua must load after CombatWatcher.lua (needs `ns.CombatWatcher` reference) and after all Data files (needs `ns.PackDatabase` populated).

---

### Pattern 1: ScrollBox Tree List (Accordion)

**What:** Tree list with collapsible dungeon headers and pack leaf rows.
**When to use:** Any time data has a two-level hierarchy — dungeon → packs.

```lua
-- Source: https://warcraft.wiki.gg/wiki/Making_scrollable_frames

local ScrollBox = CreateFrame("Frame", nil, contentFrame, "WowScrollBoxList")
ScrollBox:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 4, -4)
ScrollBox:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -4, 4)

local ScrollBar = CreateFrame("EventFrame", nil, contentFrame, "MinimalScrollBar")
ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT", 2, 0)
ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT", 2, 0)

local ScrollView = CreateScrollBoxListTreeListView()
ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)

local function ElementInitializer(button, node)
    local data = node:GetData()
    if data.isDungeon then
        -- Dungeon header row
        button:SetText(data.displayName)
        button:SetScript("OnClick", function()
            node:ToggleCollapsed()
            ScrollBox:ScrollToBegin() -- optional: scroll to top after expand
        end)
    else
        -- Pack leaf row
        button:SetText(data.displayName)
        button:SetScript("OnClick", function()
            ns.CombatWatcher:SelectDungeon(data.dungeonKey)
            -- also set pack index directly:
            -- CombatWatcher needs a SelectPack(dungeonKey, packIndex) or
            -- UI calls SelectDungeon then adjusts currentPackIndex
            ns.PackUI:Refresh()
        end)
    end
end

ScrollView:SetElementInitializer("UIPanelButtonTemplate", ElementInitializer)

local DataProvider = CreateTreeDataProvider()
ScrollView:SetDataProvider(DataProvider)

-- Populate from ns.PackDatabase
for dungeonKey, packs in pairs(ns.PackDatabase) do
    local dungeonNode = DataProvider:Insert({ isDungeon = true, displayName = dungeonKey, key = dungeonKey })
    for i, pack in ipairs(packs) do
        dungeonNode:Insert({ isDungeon = false, displayName = pack.displayName, dungeonKey = dungeonKey, packIndex = i })
    end
end
```

---

### Pattern 2: Frame Backdrop (Standard WoW Panel Look)

**What:** BackdropTemplate mixin applied to main window frame.
**When to use:** Any addon window needing native WoW dialog appearance.

```lua
-- Source: https://warcraft.wiki.gg/wiki/BackdropTemplate

local frame = CreateFrame("Frame", "TPWPackFrame", UIParent, "BackdropTemplate")
frame:SetSize(300, 400)
frame:SetPoint("CENTER")

frame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 8,
    edgeSize = 8,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
})
frame:SetBackdropColor(0, 0, 0, 0.85)
frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
```

Alternative: use `"BasicFrameTemplateWithInset"` template which provides a pre-styled title bar with close button — reduces boilerplate significantly.

```lua
local frame = CreateFrame("Frame", "TPWPackFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(300, 400)
frame:SetPoint("CENTER")
frame.TitleText:SetText("TerriblePackWarnings")
```

---

### Pattern 3: Escape Key Close (UISpecialFrames)

**What:** Register the frame so pressing Escape closes it.
**When to use:** All closable addon windows.

```lua
-- Source: https://warcraft.wiki.gg/wiki/Make_frames_closable_with_the_Escape_key

-- Frame MUST have a global name for UISpecialFrames to work
local frame = CreateFrame("Frame", "TPWPackFrame", UIParent, "BasicFrameTemplateWithInset")
_G["TPWPackFrame"] = frame  -- ensure global lookup works
tinsert(UISpecialFrames, "TPWPackFrame")
```

---

### Pattern 4: Movable Frame with Position Persistence

**What:** Drag to move, save position in SavedVariables, restore on login.
**When to use:** All addon windows with `window is movable` requirement.

```lua
-- Source: https://us.forums.blizzard.com/en/wow/t/saving-addon-position/1201232

-- Enable dragging
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save immediately on drag stop
    ns.db.windowPos = {
        point  = "BOTTOMLEFT",
        x      = self:GetLeft(),
        y      = self:GetTop(),   -- GetTop() is relative to UIParent BOTTOMLEFT
    }
end)

-- Restore position on ADDON_LOADED (after ns.db is initialized)
local function RestorePosition()
    local pos = ns.db.windowPos
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    end
end
```

**Key pitfall:** `GetTop()` returns the Y coordinate relative to UIParent's BOTTOMLEFT. To restore correctly, use `SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)` — not `"TOPLEFT"` as the reference anchor. See Common Pitfalls section.

---

### Pattern 5: Slash Command Toggle

**What:** `/tpw` with no arguments toggles window visibility.
**When to use:** Update Core.lua's slash handler.

```lua
-- Update existing SlashCmdList["TERRIBLEPACKWARNINGS"] in Core.lua
SlashCmdList["TERRIBLEPACKWARNINGS"] = function(msg)
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    if cmd == nil or cmd == "" then
        -- Bare /tpw — toggle window
        if ns.PackUI then
            ns.PackUI:Toggle()
        end
    elseif cmd == "select" then
        -- ... existing handlers unchanged ...
    end
end
```

---

### Pattern 6: Live Refresh via CombatWatcher Callback Hook

**What:** CombatWatcher notifies UI after state transitions (auto-advance).
**When to use:** Live-updating the selection highlight without polling.

```lua
-- In CombatWatcher.lua, after OnCombatEnd advances the index:
function CombatWatcher:OnCombatEnd()
    -- ... existing logic ...
    if ns.PackUI and ns.PackUI.Refresh then
        ns.PackUI:Refresh()
    end
end

-- In CombatWatcher.lua, after Reset():
function CombatWatcher:Reset()
    -- ... existing logic ...
    if ns.PackUI and ns.PackUI.Refresh then
        ns.PackUI:Refresh()
    end
end

-- In PackFrame.lua:
function ns.PackUI:Refresh()
    -- Re-read CombatWatcher:GetState() and update row highlights
    local state, dungeonKey, packIndex = ns.CombatWatcher:GetState()
    -- iterate DataProvider nodes, update button appearance
end
```

The nil guard (`if ns.PackUI and ns.PackUI.Refresh`) makes this safe — CombatWatcher loads before PackFrame.lua, so the callback is absent until the UI module loads.

---

### Anti-Patterns to Avoid

- **Using `FauxScrollFrame` or `HybridScrollFrame`:** These are legacy templates. Use `WowScrollBoxList` + `CreateScrollBoxListTreeListView` for new code targeting Interface 120000+.
- **Manual accordion (show/hide child frames):** Works, but requires manual Y-offset recalculation on every expand/collapse, doesn't scroll-clip content, more code to maintain than the tree list approach.
- **Polling CombatWatcher state with `OnUpdate`:** Wasteful. Use the callback hook pattern instead.
- **Unnamed frame + UISpecialFrames:** UISpecialFrames requires a globally-addressable frame name. A frame created with `CreateFrame("Frame", nil, ...)` (nil name) cannot be registered.
- **Restoring position with `"TOPLEFT"` anchor to UIParent:** `GetTop()` is bottom-left-relative. Must use `"BOTTOMLEFT"` as the reference point when restoring, or use `GetLeft()`/`GetBottom()` with the matching anchor.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Collapsible tree hierarchy | Custom show/hide expand logic | `CreateScrollBoxListTreeListView` + `CreateTreeDataProvider` | Built-in node collapse/expand, handles layout and scroll clipping automatically |
| Scrollable overflow content | Manual scroll math with OnUpdate | `WowScrollBoxList` + `ScrollUtil.InitScrollBoxListWithScrollBar` | Handles virtualization, scroll position, bar sync |
| Escape key handling | `OnKeyDown` interceptor | `UISpecialFrames` table registration | WoW handles this globally; custom key handlers can conflict with game inputs |
| Draggable frame | Custom mouse tracking | `SetMovable` + `RegisterForDrag` + `StartMoving` / `StopMovingOrSizing` | Built-in engine support; handles edge clamping correctly |

**Key insight:** WoW FrameXML already ships the tree-list accordion pattern (used in the reputation frame). Reusing those APIs produces native behavior without custom layout math.

---

## Common Pitfalls

### Pitfall 1: Frame Position Restore — Wrong Anchor
**What goes wrong:** Window appears off-screen or at wrong position after reload.
**Why it happens:** `GetTop()` returns Y-coordinate relative to UIParent's bottom-left corner. If you save this value and then restore with `SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)`, you use a different coordinate origin and the window is misplaced.
**How to avoid:** Always pair `GetLeft()`/`GetTop()` restore with `SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)`.
**Warning signs:** Window jumps further up screen each reload, or disappears entirely.

### Pitfall 2: UISpecialFrames Requires Named Frame
**What goes wrong:** Escape key does nothing.
**Why it happens:** `UISpecialFrames` stores frame names as strings and uses `_G[name]` to find them. A frame created with `nil` name has no global lookup.
**How to avoid:** Always give the main window frame a string name: `CreateFrame("Frame", "TPWPackFrame", ...)` and ensure `_G["TPWPackFrame"]` points to it.
**Warning signs:** Escape closes nothing; pressing Escape causes taint errors.

### Pitfall 3: PackFrame Loads Before CombatWatcher
**What goes wrong:** `ns.CombatWatcher` is nil when PackFrame.lua runs.
**Why it happens:** TOC load order is sequential. If `UI\PackFrame.lua` is listed before `Engine\CombatWatcher.lua`, the namespace reference doesn't exist yet.
**How to avoid:** In TOC, list Engine files before UI files. Use lazy references (access `ns.CombatWatcher` inside functions, not at module scope).
**Warning signs:** Lua error "attempt to index global 'ns' (a nil value)" or "attempt to index field 'CombatWatcher' (a nil value)" at startup.

### Pitfall 4: DataProvider Re-population Without Clearing
**What goes wrong:** Pack list shows duplicates after a Refresh.
**Why it happens:** Calling `DataProvider:Insert()` again on an existing provider appends, not replaces.
**How to avoid:** Either rebuild DataProvider from scratch (`DataProvider = CreateTreeDataProvider()`) and re-call `ScrollView:SetDataProvider()`, or track and update node states without rebuilding. For small lists (one dungeon, few packs), rebuilding is fine.
**Warning signs:** Dungeon headers or pack rows appear multiple times.

### Pitfall 5: BackdropTemplate Not Inherited
**What goes wrong:** `frame:SetBackdrop()` raises "attempt to call a nil value".
**Why it happens:** `SetBackdrop` is not available on plain Frame objects — it requires the BackdropTemplate mixin to be applied.
**How to avoid:** Always include `"BackdropTemplate"` in the template parameter of `CreateFrame`, or use a built-in template like `"BasicFrameTemplateWithInset"` that already includes it.
**Warning signs:** `SetBackdrop` errors on frame creation.

---

## Code Examples

### Complete Frame Bootstrap
```lua
-- Source: verified against warcraft.wiki.gg/wiki/BackdropTemplate
--         and warcraft.wiki.gg/wiki/Make_frames_closable_with_the_Escape_key

local addonName, ns = ...

ns.PackUI = {}
local PackUI = ns.PackUI

local frame = CreateFrame("Frame", "TPWPackFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(300, 400)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    ns.db.windowPos = { x = self:GetLeft(), y = self:GetTop() }
end)
frame:Hide()

frame.TitleText:SetText("TerriblePackWarnings")

-- Escape to close
tinsert(UISpecialFrames, "TPWPackFrame")

function PackUI:Show() frame:Show() end
function PackUI:Hide() frame:Hide() end
function PackUI:Toggle()
    if frame:IsShown() then frame:Hide() else frame:Show() end
end
```

### Restore Position After ADDON_LOADED
```lua
-- Source: https://us.forums.blizzard.com/en/wow/t/saving-addon-position/1201232
-- Called inside ADDON_LOADED handler in Core.lua after ns.db is set:
local function RestoreWindowPosition()
    local pos = ns.db and ns.db.windowPos
    if pos then
        frame:ClearAllPoints()
        -- GetTop() is relative to UIParent BOTTOMLEFT, so restore with BOTTOMLEFT anchor
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    end
end
```

### Tree DataProvider Population
```lua
-- Source: warcraft.wiki.gg/wiki/Making_scrollable_frames (tree list section)
local DataProvider = CreateTreeDataProvider()

for dungeonKey, packs in pairs(ns.PackDatabase) do
    local dungeonNode = DataProvider:Insert({
        isDungeon    = true,
        displayName  = dungeonKey,  -- replace with human-readable name if added to DB
        key          = dungeonKey,
    })
    for i, pack in ipairs(packs) do
        dungeonNode:Insert({
            isDungeon   = false,
            displayName = pack.displayName,
            dungeonKey  = dungeonKey,
            packIndex   = i,
        })
    end
end
```

### Combat State in Row Buttons
```lua
-- Inside ElementInitializer, for pack leaf rows:
local function UpdateRowAppearance(button, data, state, activeDungeon, activePackIndex)
    -- Default: normal appearance
    button:SetFontString(button:GetFontString())  -- reset

    local isActive   = (activeDungeon == data.dungeonKey and activePackIndex == data.packIndex and state == "active")
    local isSelected = (activeDungeon == data.dungeonKey and activePackIndex == data.packIndex and state ~= "idle")
    local isComplete = (activeDungeon == data.dungeonKey and data.packIndex < activePackIndex)

    if isActive then
        button:GetFontString():SetTextColor(1, 0.5, 0)   -- orange: fighting
    elseif isSelected then
        button:GetFontString():SetTextColor(0, 1, 0)     -- green: selected/ready
    elseif isComplete then
        button:GetFontString():SetTextColor(0.5, 0.5, 0.5)  -- grey: done
    else
        button:GetFontString():SetTextColor(1, 1, 1)     -- white: default
    end
end
```

Text color is simpler than texture icons and has zero risk of missing texture paths. Icons (checkmark, swords) can be added via `button:CreateTexture()` using built-in WoW paths such as `"Interface\\Buttons\\UI-CheckMark"` — but color coding alone satisfies the requirement.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `FauxScrollFrame` / manual scroll math | `WowScrollBoxList` + `ScrollUtil` | Dragonflight 10.0 | New addons should use ScrollBox; FauxScrollFrame still works but is legacy |
| `frame:SetBackdrop()` on plain Frame | `CreateFrame(..., "BackdropTemplate")` + `SetBackdrop()` | Shadowlands 9.0.1 | Plain Frame no longer has `SetBackdrop`; must inherit BackdropTemplate |
| Manual accordion (show/hide frames) | `CreateScrollBoxListTreeListView` + node `ToggleCollapsed()` | Dragonflight 10.0 | Native tree list handles layout and clip automatically |

**Deprecated/outdated:**
- `FauxScrollFrameTemplate`: Still functional but no longer recommended; poor DX for hierarchical data.
- `SetBackdrop` on non-BackdropTemplate frames: Silently fails or errors in modern WoW.

---

## Open Questions

1. **`CombatWatcher:SelectPack(dungeonKey, packIndex)` API gap**
   - What we know: `CombatWatcher:SelectDungeon(key)` always resets to pack 1. The UI needs to select any pack by index (wipe recovery click).
   - What's unclear: Does a new API need to be added, or should the UI call `SelectDungeon` then mutate `currentPackIndex` via a new `SetPackIndex` method?
   - Recommendation: Plan 03-01 (or whichever plan adds CombatWatcher API) should add `CombatWatcher:SelectPack(dungeonKey, packIndex)` that sets dungeon + explicit index + transitions to "ready".

2. **Human-readable dungeon display names**
   - What we know: `ns.PackDatabase` keys are snake_case strings like `"windrunner_spire"`. Accordion headers will show these raw strings unless a display name is available.
   - What's unclear: PackDatabase entries don't include a dungeon-level `displayName` field — only pack-level `displayName` exists.
   - Recommendation: Add a `dungeonDisplayName` field to the first pack entry, or add a separate `ns.DungeonNames` lookup table in Phase 3.

3. **ScrollBox behavior in combat (restricted environment)**
   - What we know: The window stays open during combat per locked decisions.
   - What's unclear: Whether Midnight's restricted addon environment blocks any ScrollBox or frame manipulation APIs during `PLAYER_REGEN_DISABLED`.
   - Recommendation: Test window interaction (scroll, click rows) during combat in-game before finalizing. If taint occurs on DataProvider mutations during combat, fall back to read-only display and refresh only outside combat.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — WoW addon; in-game manual testing only |
| Config file | none |
| Quick run command | Load addon in WoW client, `/tpw` to open window |
| Full suite command | Walk through UAT checklist in `03-UAT.md` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UI-01 | Scrollable pack list grouped by dungeon | manual-only | `/tpw` → verify dungeon headers expand/collapse, list scrolls | N/A |
| UI-02 | Click-to-select a pack from the list | manual-only | Click pack row → `/tpw status` shows correct dungeon+pack | N/A |
| UI-03 | Visual indicator for active/selected pack | manual-only | Pull pack → verify row color change; advance → verify highlight moves | N/A |
| UI-04 | `/tpw` toggles the window | manual-only | `/tpw` once opens, `/tpw` again closes | N/A |

**Manual-only justification:** WoW addon Lua runs inside the game client. There is no headless test runner for WoW FrameXML. All UI validation must be done in-game.

### Sampling Rate
- **Per task commit:** Load addon in game, run affected slash commands, verify no Lua errors in `/console scriptErrors 1` output
- **Per wave merge:** Full UAT checklist walkthrough
- **Phase gate:** All UI-01 through UI-04 manual checks pass before `/gsd:verify-work`

### Wave 0 Gaps
None — no test infrastructure to create. In-game validation is the only mechanism.

---

## Sources

### Primary (HIGH confidence)
- [warcraft.wiki.gg — Making scrollable frames](https://warcraft.wiki.gg/wiki/Making_scrollable_frames) — ScrollBox linear + tree list patterns, DataProvider, TreeListView, ToggleCollapsed
- [warcraft.wiki.gg — BackdropTemplate](https://warcraft.wiki.gg/wiki/BackdropTemplate) — SetBackdrop, ApplyBackdrop, backdropInfo table structure
- [warcraft.wiki.gg — Make frames closable with Escape](https://warcraft.wiki.gg/wiki/Make_frames_closable_with_the_Escape_key) — UISpecialFrames, tinsert pattern, named frame requirement
- [warcraft.wiki.gg — UIOBJECT Frame](https://warcraft.wiki.gg/wiki/UIOBJECT_Frame) — SetMovable, EnableMouse, RegisterForDrag, StartMoving, StopMovingOrSizing, SetPoint, GetLeft, GetTop

### Secondary (MEDIUM confidence)
- [Blizzard forums — Saving addon position](https://us.forums.blizzard.com/en/wow/t/saving-addon-position/1201232) — BOTTOMLEFT anchor correction for GetTop() restore; verified anchor math explained in thread
- [warcraft.wiki.gg — BackdropTemplate issues thread](https://us.forums.blizzard.com/en/wow/t/backdroptemplate-issues/1125674) — confirmation that SetBackdrop on non-template frames fails in 9.0.1+

### Tertiary (LOW confidence — validate in-game)
- General community consensus that FauxScrollFrame is legacy; no single official deprecation notice found — inferred from Blizzard's documentation focus on ScrollBox
- ScrollBox behavior during restricted combat environment — no official documentation; requires in-game validation

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — BackdropTemplate, UISpecialFrames, SetMovable/RegisterForDrag are stable APIs documented on warcraft.wiki.gg; ScrollBox tree list documented with full code examples
- Architecture: HIGH — file structure follows existing project patterns; TOC load order is deterministic
- Pitfalls: HIGH for backdrop/UISpecialFrames/position anchor (well-documented); MEDIUM for ScrollBox in combat (untested scenario)

**Research date:** 2026-03-15
**Valid until:** 2026-06-15 (stable APIs; WoW UI rarely changes fundamentals between patches)
