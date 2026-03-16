# Phase 10: Route UI Overhaul - Research

**Researched:** 2026-03-16
**Domain:** WoW Addon UI — creature portrait rendering, scroll frame, editbox popup, confirmation dialogs
**Confidence:** HIGH (primary findings all verified from MDT source code in the same repository)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Pull row layout**: MDT-style compact — pull number + round NPC portrait icons inline, no ability text
- **Portrait size**: 20–24px round icons arranged horizontally per pull row
- **Active pull highlight**: current pull gets colored background/border, completed pulls greyed out; same state pattern as v0.0.2 (green selected, orange active, grey completed)
- **Import button**: opens a popup editbox (multi-line, separate frame) for pasting MDT string; player pastes, clicks "Import" to confirm
- **Clear button**: shows confirmation dialog ("Are you sure?") before clearing
- **Clear behavior**: removes all imported data from PackDatabase and SavedVariables
- **Slash commands**: `/tpw import` and `/tpw clear` still work alongside UI buttons
- **Header**: display imported dungeon name and total pull count (e.g. "Windrunner Spire — 17 pulls"); empty state when no route imported
- **Portrait source**: use displayId from DungeonEnemies data via SetPortraitTextureFromCreatureDisplayID or equivalent
- **Portrait fallback**: if displayId is missing/invalid, show a class icon based on mob's class data

### Claude's Discretion
- Exact popup editbox dimensions and positioning
- Circular mask implementation (texture mask vs SetMask vs circular border overlay)
- How to get creature portrait from displayId (SetPortraitTextureFromCreatureDisplayID, ModelScene, or texture atlas)
- Pull row height and spacing
- Button styling (standard WoW button templates)
- Confirmation dialog style

### Deferred Ideas (OUT OF SCOPE)
- Detailed ability configuration screen per mob
- Mob tooltips on portrait hover showing mob name and abilities
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UI-09 | Pack list shows indexed pulls with round NPC portrait icons per mob in each pack | SetPortraitTextureFromCreatureDisplayID + Circle_White overlay pattern confirmed from MDT source; portrait creation loop with mask documented below |
| UI-10 | Import button opens text editbox for pasting MDT/KSG export string | Multi-line EditBox API documented; popup frame pattern described |
| UI-11 | Clear button removes all imported route data, leaving pack list empty | ns.Import.Clear() already exists; confirmation via StaticPopup documented |
| UI-12 | Display imported dungeon name and pull count in the UI header | dungeonName and pack count both available in ns.db.importedRoute |
</phase_requirements>

---

## Summary

Phase 10 replaces PackFrame.lua's accordion dungeon list with a flat indexed pull list, MDT-style, showing round NPC portrait icons per pull. The critical research question was how to render creature portraits from displayId and how to make them circular. Both questions are fully answered by MDT's own source code in the local repository.

**Portrait rendering:** MDT uses `SetPortraitTextureFromCreatureDisplayID(texture, displayId)` to paint a creature portrait onto a plain Texture object. Circular cropping is achieved by layering a `Circle_White.tga` overlay texture on top at a slightly larger size — this acts as a circular border/mask. MDT does NOT use `SetMask` or `MaskTexture` for its pull button portraits (those are only used on the map blip icons); the pull-button portraits use the simpler overlay border approach.

**Import popup:** A standard `CreateFrame("Frame")` with a multi-line `CreateFrame("EditBox")` child. No AceGUI needed. The editbox needs `SetMultiLine(true)`, `SetAutoFocus(true)`, and a `ScrollFrame` parent if the pasted string might be very long (MDT export strings are 500–2000+ characters).

**Confirmation dialog:** WoW's built-in `StaticPopupDialogs` + `StaticPopup_Show()` is the cleanest approach for a simple "Are you sure?" clear confirmation with no extra dependencies.

**Primary recommendation:** Follow MDT's exact pull-button portrait pattern — `SetPortraitTextureFromCreatureDisplayID` + `Circle_White` overlay border. Wire Import and Clear through existing `ns.Import` API. Build the popup as a simple frame-with-editbox, not a StaticPopup (StaticPopups have character limits on their editboxes).

---

## Standard Stack

### Core
| Library/API | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| `SetPortraitTextureFromCreatureDisplayID` | WoW built-in | Paints creature portrait onto a Texture | Used by MDT, confirmed working in retail |
| `CreateFrame("EditBox")` | WoW built-in | Multi-line paste input | Native WoW API, no deps |
| `StaticPopupDialogs` + `StaticPopup_Show` | WoW built-in | Confirmation dialog | WoW-idiomatic two-button confirm |
| `BasicFrameTemplateWithInset` | WoW built-in | Frame chrome (already used by PackFrame) | Matches existing TPW style |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `UIPanelScrollFrameTemplate` | WoW built-in | Scroll container for pull rows | Already used in PackFrame; keep pattern |
| `Circle_White.tga` from MDT | local | Circular border overlay for portraits | Use as overlay, OR copy pattern with a solid ring texture |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Circle_White` overlay border | `SetMask` / `MaskTexture` XML | MaskTexture is more correct but requires XML or SetMask API; MDT's blip icons use it but pull-button portraits do NOT — overlay border is simpler and works fine at 20–24px |
| `StaticPopup_Show` for import | Custom popup frame | StaticPopup editboxes have a `maxLetters` cap (~255 by default); MDT strings can be 2000+ chars, so a custom frame is required for the import editbox specifically |

**Installation:** No new libraries needed. All APIs are WoW built-ins.

---

## Architecture Patterns

### Recommended Project Structure
No new files required. All changes go into `UI/PackFrame.lua` (full rewrite).

```
UI/
└── PackFrame.lua   -- Full rewrite: pull list + portraits + import popup + clear button
```

### Pattern 1: Pull Row with Portrait Icons (MDT-verified)

**What:** Each pull row is a Button containing a pull-number label and N portrait textures laid out left-to-right.

**When to use:** For each entry in `ns.PackDatabase["imported"]`.

**Example — portrait texture creation loop (from MDT AceGUIWidget-MythicDungeonToolsPullButton.lua, lines 984–1009):**
```lua
-- Source: C:/Users/jonat/Repositories/MythicDungeonTools/AceGUIWidgets/AceGUIWidget-MythicDungeonToolsPullButton.lua
local portraitSize = ROW_HEIGHT - 9   -- ~23px for ROW_HEIGHT=32; scale to your ROW_HEIGHT
local maxPortraitCount = 8            -- cap to avoid overflow
local enemyPortraits = {}

for i = 1, maxPortraitCount do
    -- Portrait texture (creature face)
    enemyPortraits[i] = row:CreateTexture(nil, "BACKGROUND", nil, 2)
    enemyPortraits[i]:SetSize(portraitSize, portraitSize)
    if i == 1 then
        enemyPortraits[i]:SetPoint("LEFT", row, "LEFT", portraitSize, 0)
    else
        enemyPortraits[i]:SetPoint("LEFT", enemyPortraits[i - 1], "RIGHT", -2, 0)
    end
    enemyPortraits[i]:Hide()

    -- Circular border overlay (what makes them "round")
    enemyPortraits[i].overlay = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    enemyPortraits[i].overlay:SetTexture("Interface\\Addons\\MythicDungeonTools\\Textures\\Circle_White")
    enemyPortraits[i].overlay:SetVertexColor(0.7, 0.7, 0.7)
    enemyPortraits[i].overlay:SetPoint("CENTER", enemyPortraits[i], "CENTER")
    enemyPortraits[i].overlay:SetSize(portraitSize + 3, portraitSize + 3)
    enemyPortraits[i].overlay:Hide()
end
```

**Example — painting portrait from displayId (MDT SetNPCData, line 873):**
```lua
-- Source: MDT AceGUIWidget-MythicDungeonToolsPullButton.lua line 873
if data.displayId then
    SetPortraitTextureFromCreatureDisplayID(enemyPortraits[i], data.displayId)
else
    -- Fallback: generic question mark or class icon
    enemyPortraits[i]:SetTexture("Interface\\Icons\\achievement_boss_hellfire_mannorothreanimated")
end
enemyPortraits[i]:Show()
enemyPortraits[i].overlay:Show()
```

**Key detail:** `SetPortraitTextureFromCreatureDisplayID` takes the Texture frame object directly as the first argument, not a path. The texture is painted async/internally by the WoW client.

### Pattern 2: Building npcID → displayId Lookup

The pack stores `npcIDs` array and abilities. To show portraits we need `displayId` per npcID. `DungeonEnemies.lua` has `{ id = npcID, displayId = ... }`. Need a reverse lookup table.

```lua
-- Build once at load time
local npcIdToDisplayId = {}
for dungeonIdx, enemies in pairs(ns.DungeonEnemies) do
    for _, enemy in pairs(enemies) do
        if enemy.id and enemy.displayId then
            npcIdToDisplayId[enemy.id] = enemy.displayId
        end
    end
end
```

Then to render: `local displayId = npcIdToDisplayId[npcID]`

### Pattern 3: Import Popup EditBox

**What:** A separate frame with a large multi-line EditBox for pasting. NOT a StaticPopup (character limit).

**Key EditBox APIs:**
```lua
-- Source: WoW API documentation / standard addon patterns
local editbox = CreateFrame("EditBox", nil, popupFrame, "InputBoxTemplate")
editbox:SetMultiLine(true)
editbox:SetMaxLetters(0)          -- 0 = unlimited
editbox:SetAutoFocus(true)
editbox:SetFontObject(ChatFontNormal)
editbox:SetWidth(260)

-- Wrap it in a scroll frame for long strings
local scrollFrame = CreateFrame("ScrollFrame", nil, popupFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(270, 120)
scrollFrame:SetScrollChild(editbox)

-- On confirm:
local str = editbox:GetText()
if str and str ~= "" then
    ns.Import.RunFromString(str)
    editbox:SetText("")
    popupFrame:Hide()
end
```

### Pattern 4: StaticPopup Confirmation Dialog

**What:** WoW built-in two-button confirm dialog for the Clear action.

```lua
-- Source: WoW API — StaticPopupDialogs pattern used across all addons
StaticPopupDialogs["TPW_CONFIRM_CLEAR"] = {
    text = "Clear imported route? This cannot be undone.",
    button1 = "Clear",
    button2 = "Cancel",
    OnAccept = function()
        ns.Import.Clear()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Trigger it:
StaticPopup_Show("TPW_CONFIRM_CLEAR")
```

**Note:** Define `StaticPopupDialogs["TPW_CONFIRM_CLEAR"]` at file scope (outside functions), not inside a click handler — the definition must happen once at load time.

### Pattern 5: Header Row with Dungeon Name and Pull Count

```lua
-- Reads from ns.db.importedRoute (set by Pipeline.lua)
local function UpdateHeader()
    if ns.db and ns.db.importedRoute then
        local r = ns.db.importedRoute
        headerText:SetText(string.format("%s  —  %d pulls", r.dungeonName, #r.packs))
        headerText:SetTextColor(1, 0.82, 0)
    else
        headerText:SetText("No route imported")
        headerText:SetTextColor(0.6, 0.6, 0.6)
    end
end
```

### Pattern 6: Active / Selected / Completed Pull State

Preserve the v0.0.2 state coloring pattern but apply it to pull row backgrounds instead of text colors:

```lua
-- Source: existing PackFrame.lua pattern, adapted for pull rows
local curState, activeDungeon, activePackIndex = ns.CombatWatcher:GetState()
local sameDungeon = (activeDungeon == "imported")

if sameDungeon and pullIndex == activePackIndex and curState == "active" then
    row.background:SetColorTexture(1, 0.5, 0, 0.3)       -- orange: actively fighting
elseif sameDungeon and pullIndex == activePackIndex then
    row.background:SetColorTexture(0, 1, 0, 0.2)          -- green: selected/ready
elseif sameDungeon and activePackIndex and pullIndex < activePackIndex then
    row.background:SetColorTexture(0.3, 0.3, 0.3, 0.3)   -- grey: completed
else
    row.background:SetColorTexture(0, 0, 0, 0)             -- transparent: default
end
```

### Anti-Patterns to Avoid

- **Using StaticPopup for Import EditBox:** StaticPopup's built-in EditBox has a ~255 character limit. MDT export strings are 500–2000+ characters. Must use a custom popup frame.
- **Calling SetPortraitTextureFromCreatureDisplayID on a model frame:** The function takes a Texture region, not a Model or Frame. Calling it on the wrong object type silently fails.
- **Creating portrait textures every Refresh call:** Pool portrait textures per row at creation time and hide/show them during refresh. Creating new textures every call leaks memory.
- **Reusing the accordion expand state:** The new UI has no accordions. Remove `expandedDungeons` table entirely — it served the old dungeon-header pattern.
- **Forgetting nil guard on ns.db.importedRoute:** Must check nil before reading `.dungeonName` / `.packs` — the route may not be imported yet.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Creature portrait rendering | Custom texture atlas lookup | `SetPortraitTextureFromCreatureDisplayID` | WoW engine handles the async load and caching |
| Confirmation dialog | Custom "Are you sure?" frame | `StaticPopup_Show` | Built-in, handles escape, stacking, UI integration automatically |
| Circular portrait crop | Shader/clipping code | `Circle_White.tga` overlay (MDT pattern) | Proven in MDT; works at 20–24px; one extra texture per portrait |

**Key insight:** MDT already solved all three hard UI problems for this phase. Follow MDT's exact patterns rather than inventing alternatives.

---

## Common Pitfalls

### Pitfall 1: Circle_White Path Has Addon Dependency
**What goes wrong:** Copying MDT's path `"Interface\\Addons\\MythicDungeonTools\\Textures\\Circle_White"` — this only works if MDT is installed. TPW cannot depend on MDT files at runtime.
**Why it happens:** MDT uses its own bundled texture at that path.
**How to avoid:** Either (a) copy `Circle_White.tga` into `Interface\\Addons\\TerriblePackWarnings\\Textures\\` and reference that path, OR (b) use the WoW built-in circular mask texture `"Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"` which is always present (it's what MDT uses in its XML for blip icons). The TempPortraitAlphaMask approach uses the `SetMask` API.
**Warning signs:** Portraits load but the circular overlay is invisible or throws an error.

**Recommended approach — use WoW's built-in mask instead of Circle_White:**
```lua
-- Uses SetMask with the same texture MDT uses in DungeonEnemies.xml
portrait:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
-- No overlay texture needed — SetMask makes the portrait itself circular
```
This is cleaner than the Circle_White overlay and has zero external dependencies.

### Pitfall 2: SetPortraitTextureFromCreatureDisplayID Fails Silently on Bad displayId
**What goes wrong:** If displayId is 0, nil, or an invalid ID, the texture renders blank/white with no error.
**Why it happens:** The API is fire-and-forget; WoW just skips the paint if the ID is invalid.
**How to avoid:** Check `displayId and displayId > 0` before calling. Use a fallback texture for the else branch.

### Pitfall 3: EditBox Paste Requires Focus
**What goes wrong:** Player opens import popup but text won't paste because the EditBox doesn't have keyboard focus.
**Why it happens:** `SetAutoFocus(true)` only works when the frame is first shown; showing/hiding the frame without re-calling `editbox:SetFocus()` loses focus.
**How to avoid:** In the popup frame's `OnShow` script, call `editbox:SetFocus()` and `editbox:SetText("")`.

### Pitfall 4: Pull Row Pool Gets Stale After Clear
**What goes wrong:** After `Import.Clear()`, `ns.PackDatabase["imported"]` becomes nil. PopulateList iterates it — need to guard against nil.
**Why it happens:** `pairs(nil)` throws a Lua error.
**How to avoid:** Guard: `if ns.PackDatabase["imported"] then ... end` before iterating, and show the empty-state header when nil.

### Pitfall 5: StaticPopupDialogs Key Collision
**What goes wrong:** Another addon (or future code) defines `StaticPopupDialogs["TPW_CONFIRM_CLEAR"]` under the same key.
**Why it happens:** StaticPopupDialogs is a global table shared across all addons.
**How to avoid:** Prefix with addon name — `"TPW_CONFIRM_CLEAR"` is already specific enough. Just don't use generic names like `"CONFIRM"`.

---

## Code Examples

### Full Portrait Creation at Row Build Time
```lua
-- Source: MDT AceGUIWidget-MythicDungeonToolsPullButton.lua (adapted for TPW)
local PORTRAIT_SIZE = 22
local MAX_PORTRAITS = 8

local function CreatePullRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(28)

    -- Background for state highlight
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    -- Pull number label (e.g. "3")
    row.pullNum = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.pullNum:SetWidth(20)
    row.pullNum:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.pullNum:SetJustifyH("CENTER")

    -- Portrait texture pool
    row.portraits = {}
    for i = 1, MAX_PORTRAITS do
        local tex = row:CreateTexture(nil, "ARTWORK")
        tex:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
        if i == 1 then
            tex:SetPoint("LEFT", row.pullNum, "RIGHT", 4, 0)
        else
            tex:SetPoint("LEFT", row.portraits[i-1], "RIGHT", 1, 0)
        end
        -- Circular mask using WoW built-in (no external dep)
        tex:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        tex:Hide()
        row.portraits[i] = tex
    end

    return row
end
```

### Populating a Pull Row
```lua
-- Source: pattern derived from MDT SetNPCData + TPW pipeline data
local function PopulatePullRow(row, packIndex, pack, npcIdToDisplayId)
    row.pullNum:SetText(tostring(packIndex))

    -- Hide all portraits first
    for _, tex in ipairs(row.portraits) do
        tex:Hide()
    end

    -- Show one portrait per unique npcID in this pull
    local slot = 0
    for _, npcID in ipairs(pack.npcIDs) do
        slot = slot + 1
        if slot > MAX_PORTRAITS then break end
        local tex = row.portraits[slot]
        local displayId = npcIdToDisplayId[npcID]
        if displayId and displayId > 0 then
            SetPortraitTextureFromCreatureDisplayID(tex, displayId)
        else
            tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        tex:Show()
    end

    -- State coloring
    local curState, activeDungeon, activePack = ns.CombatWatcher:GetState()
    if activeDungeon == "imported" and activePack then
        if packIndex == activePack and curState == "active" then
            row.bg:SetColorTexture(1, 0.5, 0, 0.25)
        elseif packIndex == activePack then
            row.bg:SetColorTexture(0, 1, 0, 0.15)
        elseif packIndex < activePack then
            row.bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)
        else
            row.bg:SetColorTexture(0, 0, 0, 0)
        end
    else
        row.bg:SetColorTexture(0, 0, 0, 0)
    end

    row:SetScript("OnClick", function()
        ns.CombatWatcher:SelectPack("imported", packIndex)
        -- Refresh to update state coloring
        ns.PackUI:Refresh()
    end)
end
```

### Import Popup Frame
```lua
-- Source: standard WoW addon editbox popup pattern
local importPopup = CreateFrame("Frame", "TPWImportPopup", UIParent, "BasicFrameTemplateWithInset")
importPopup:SetSize(320, 200)
importPopup:SetPoint("CENTER")
importPopup:Hide()
importPopup.TitleText:SetText("Import MDT Route")
tinsert(UISpecialFrames, "TPWImportPopup")

local editScrollFrame = CreateFrame("ScrollFrame", nil, importPopup, "UIPanelScrollFrameTemplate")
editScrollFrame:SetPoint("TOPLEFT", importPopup, "TOPLEFT", 12, -30)
editScrollFrame:SetPoint("BOTTOMRIGHT", importPopup, "BOTTOMRIGHT", -34, 40)

local editBox = CreateFrame("EditBox", nil, editScrollFrame)
editBox:SetSize(270, 120)
editBox:SetMultiLine(true)
editBox:SetMaxLetters(0)
editBox:SetAutoFocus(false)
editBox:SetFontObject(ChatFontNormal)
editBox:SetScript("OnEscapePressed", function() importPopup:Hide() end)
editScrollFrame:SetScrollChild(editBox)

importPopup:SetScript("OnShow", function()
    editBox:SetText("")
    editBox:SetFocus()
end)

local confirmBtn = CreateFrame("Button", nil, importPopup, "GameMenuButtonTemplate")
confirmBtn:SetSize(80, 22)
confirmBtn:SetPoint("BOTTOMRIGHT", importPopup, "BOTTOMRIGHT", -12, 8)
confirmBtn:SetText("Import")
confirmBtn:SetScript("OnClick", function()
    local str = editBox:GetText()
    if str and str ~= "" then
        ns.Import.RunFromString(str)
        importPopup:Hide()
    end
end)

local cancelBtn = CreateFrame("Button", nil, importPopup, "GameMenuButtonTemplate")
cancelBtn:SetSize(80, 22)
cancelBtn:SetPoint("RIGHT", confirmBtn, "LEFT", -4, 0)
cancelBtn:SetText("Cancel")
cancelBtn:SetScript("OnClick", function() importPopup:Hide() end)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Accordion dungeon list (PackFrame v0.0.2) | Flat indexed pull list (this phase) | Phase 10 | Removes dungeon header rows; always shows "imported" only |
| Text-only pack rows (`Pack 1`, `Pack 2`) | Pull rows with portrait icons | Phase 10 | Visual identity matching MDT's pull panel |
| No import/clear buttons | Import + Clear in footer | Phase 10 | Paste workflow without slash commands |

**Deprecated:**
- `expandedDungeons` table: no accordions in new UI
- `DUNGEON_NAMES` lookup: header now reads from `ns.db.importedRoute.dungeonName`
- Per-dungeon iteration in PopulateList: new code iterates `ns.PackDatabase["imported"]` directly

---

## Open Questions

1. **Circle_White vs TempPortraitAlphaMask**
   - What we know: MDT's pull buttons use `Circle_White.tga` (addon-local) as an overlay; MDT's map blips use `TempPortraitAlphaMask` as a MaskTexture in XML
   - What's unclear: Does `SetMask` with `TempPortraitAlphaMask` work correctly on a plain Texture in Lua (not XML) in Midnight 12+?
   - Recommendation: Try `SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")` first since it has no external dep. If it clips incorrectly, fall back to copying the Circle_White overlay approach (which is definitively proven in MDT's pull buttons).

2. **Portrait rendering async timing**
   - What we know: `SetPortraitTextureFromCreatureDisplayID` is asynchronous in some WoW builds
   - What's unclear: Whether there's a flicker on first render or if portraits appear blank until the next frame
   - Recommendation: This is a cosmetic edge case; accept any first-frame flicker. No workaround needed for v0.0.3.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — WoW addon, no automated test runner |
| Config file | N/A |
| Quick run command | Load addon in WoW client: `/reload` |
| Full suite command | Manual verification checklist (see below) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UI-09 | Pull rows show indexed pulls with round NPC portrait icons | manual-smoke | `/tpw` then observe pull list with imported route | N/A |
| UI-10 | Import button opens editbox popup; paste + Import button triggers import | manual-smoke | Click Import button, paste MDT string, click Import | N/A |
| UI-11 | Clear button shows confirmation; accepting clears pack list to empty state | manual-smoke | Click Clear button, confirm, verify list is empty | N/A |
| UI-12 | Header shows dungeon name and pull count | manual-smoke | Import a route, `/tpw`, verify header text | N/A |

**Justification for manual-only:** WoW addon UI cannot be tested outside the WoW client. There is no headless Lua runtime compatible with WoW's UI API (CreateFrame, etc.).

### Sampling Rate
- **Per task commit:** `/reload` in WoW client, open `/tpw`, visually verify
- **Per wave merge:** Full manual checklist — import a route, verify portraits, test import popup, test clear confirmation, verify header
- **Phase gate:** All four requirements verified manually before `/gsd:verify-work`

### Wave 0 Gaps
None — no test files needed. Verification is entirely manual in-game.

---

## Sources

### Primary (HIGH confidence)
- `C:/Users/jonat/Repositories/MythicDungeonTools/AceGUIWidgets/AceGUIWidget-MythicDungeonToolsPullButton.lua` — SetPortraitTextureFromCreatureDisplayID usage, portrait texture creation loop, Circle_White overlay pattern, maxPortraitCount=7, portraitSize=height-9
- `C:/Users/jonat/Repositories/MythicDungeonTools/Modules/DungeonEnemies.xml` — MaskTexture with `Interface\CHARACTERFRAME\TempPortraitAlphaMask` confirmed as WoW built-in circular mask
- `C:/Users/jonat/Repositories/TerriblePackWarnings/UI/PackFrame.lua` — existing frame structure, scroll frame setup, combat state pattern to preserve
- `C:/Users/jonat/Repositories/TerriblePackWarnings/Import/Pipeline.lua` — RunFromString, Clear, RestoreFromSaved APIs; ns.db.importedRoute structure (dungeonName, packs array)
- `C:/Users/jonat/Repositories/TerriblePackWarnings/Data/DungeonEnemies.lua` — displayId confirmed present per enemy entry

### Secondary (MEDIUM confidence)
- WoW addon community pattern for StaticPopupDialogs — widely used, structure is well-known; confirmed present in WoW API but not verified against Midnight 12 specifically
- Multi-line EditBox + ScrollFrame pattern — standard WoW addon pattern, verified by observation in many addons

### Tertiary (LOW confidence)
- `SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")` on a plain Texture in Lua — confirmed it works in the XML context; Lua `SetMask` equivalent assumed to work but not directly tested in this codebase

---

## Metadata

**Confidence breakdown:**
- Portrait rendering (SetPortraitTextureFromCreatureDisplayID): HIGH — read directly from MDT source in this repo
- Circle_White overlay vs SetMask: MEDIUM — overlay confirmed; SetMask via Lua is assumed equivalent to XML MaskTexture
- StaticPopup confirmation: MEDIUM — universal WoW pattern, not verified in Midnight 12 environment specifically
- Import EditBox pattern: HIGH — standard WoW CreateFrame("EditBox") APIs, used everywhere
- Data availability (displayId, dungeonName, packs): HIGH — read directly from TPW source files

**Research date:** 2026-03-16
**Valid until:** 2026-06-16 (stable WoW UI APIs, no expected churn)
