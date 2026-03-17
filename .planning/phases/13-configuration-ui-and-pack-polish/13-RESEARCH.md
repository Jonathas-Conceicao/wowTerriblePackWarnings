# Phase 13: Configuration UI and Pack Polish - Research

**Researched:** 2026-03-17
**Domain:** WoW Midnight (12.0) addon UI — config window (dungeon/mob/skill tree), per-skill SavedVariables, mob count display in pull rows
**Confidence:** HIGH — all findings sourced from direct analysis of local source files (wow-ui-source, MythicDungeonTools, existing TPW code)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Config Window Layout**
- Separate window from TPW pack frame — own position, sizing, movable
- Opens via `/tpw config` slash command and/or a button on the pack window
- Wide rectangular frame (wider than pack window)
- Left panel: scrollable dungeon→mob tree
- Right panel: selected mob's details and per-skill settings

**Left Panel — Dungeon/Mob Tree**
- Dungeon names as collapsible headers (▼ expanded / ► collapsed)
- Click header to toggle expand/collapse
- Mob rows underneath each dungeon: round NPC portrait + mob name (same portrait style as PackFrame.lua)
- Click a mob row to load its skills on the right panel
- Mobs are deduplicated per dungeon (each unique npcID appears once)

**Right Panel — Mob Details**
- Header: mob name + class (e.g. "Nerubian Spellguard — PALADIN")
- Scrollable list of abilities for that mob

**Per-Skill Settings**
- Enabled checkbox: toggle tracking on/off (global, not per-route)
- Label field: editable, defaults to current label from AbilityDB, empty allowed
- Timing info: read-only display ("First cast: 50s, Cooldown: 50s") shown only for timed abilities
- Sound dropdown: single dropdown, first option is "TTS" (default), followed by WoW built-in sounds organized by CDM categories. Preview sound on selection.
- TTS text field: editable when "TTS" selected in dropdown, defaults to spell name. Grayed out and non-editable when a sound file is selected.
- Spell tooltip: hovering the skill row (or a (?) icon) shows WoW spell tooltip via GameTooltip:SetSpellByID()
- Reset button: per-skill reset clears all custom overrides back to defaults
- Reset All button: per-dungeon, resets all skills for that dungeon

**Alert Model**
- Single dropdown controls alert type: "TTS" or a specific WoW sound
- Default for unconfigured skills: TTS with spell name as text
- Sound and TTS are mutually exclusive — dropdown selection determines which is active
- TTS text field state follows dropdown: enabled for "TTS", disabled/grayed for any sound

**Mob Count Display (Pull Rows)**
- Pull rows in pack window show count per mob type (e.g. "3x Spellguard")
- Must be visually clear at a glance for route navigation

### Claude's Discretion
- Exact window dimensions and proportions
- ScrollFrame implementation details for both panels
- Mob count visual approach (overlay vs label — MDT uses "x"..quantity on portraits)
- SavedVariables schema for skillConfig (sparse overrides recommended per research)
- How the config button integrates with the pack window (if added)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CFG-01 | Config window with left panel showing dungeon list expandable to deduplicated mobs | ScrollFrame + collapsible node pattern from CDM; ns.AbilityDB provides dungeon/mob data |
| CFG-02 | Right panel shows selected mob's skills with per-skill settings | Click mob row → populate right panel from ns.AbilityDB[npcID].abilities; CheckButton + EditBox + Button per skill row |
| CFG-03 | User can toggle tracking on/off for each skill via checkbox | CheckButton writes ns.db.skillConfig[npcID][spellID].enabled = false; Pipeline.BuildPack skips disabled abilities via MergeSkillConfig |
| CFG-04 | User can set custom label per skill (current label as default, empty allowed) | EditBox writes ns.db.skillConfig[npcID][spellID].label; merged at BuildPack time; empty string is valid |
| CFG-05 | User can see WoW spell tooltip when hovering a skill in the config window | GameTooltip:SetSpellByID(spellID) — exact pattern already in IconDisplay.lua slot OnEnter handler |
| ROUTE-04 | Pull rows show mob count per type (e.g. "3x Spellguard") | Pipeline.BuildPack must track quantity per npcID; PackFrame portrait frames need FontString overlay; MDT uses "x"..quantity pattern |
</phase_requirements>

---

## Summary

Phase 13 is a pure UI and data-plumbing phase. It has no new engine complexity — all the hard pieces (ScrollFrame patterns, SavedVariables, portrait rendering, tooltip API) already exist in PackFrame.lua and IconDisplay.lua. The work is wiring a new ConfigFrame into the existing architecture, adding `skillConfig` to SavedVariables, teaching Pipeline.BuildPack to merge skill overrides, and adding mob count tracking and display to pull rows.

The entire phase is validated against the existing `WindrunnerSpire.lua` data (6 npcIDs, 4 distinct abilities). No new dungeon data files are required. This is the key design choice: Phase 13 proves the config tree is correct before Phase 14 populates 8 more dungeons.

The critical constraint is that `skillConfig` changes do NOT hot-swap live pack data. They take effect on the next import or route rebuild. This is an acceptable v0.1.0 limitation — stated in ARCHITECTURE.md. The planner must not plan any live-reload mechanism.

**Primary recommendation:** Build in this order: (1) `skillConfig` schema + MergeSkillConfig in Pipeline, (2) mob count tracking in BuildPack + count display in PackFrame, (3) ConfigFrame.lua lazy construction + left/right panel layout, (4) per-skill widgets (checkbox, label EditBox, TTS EditBox, sound dropdown), (5) `/tpw config` slash command + optional config button in PackFrame footer.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Lua 5.1 (WoW dialect) | WoW embedded | All addon logic | Only scripting language the client exposes |
| `CreateFrame("Frame")` | Interface 120001 | Config window root, scroll child, panel containers | Canonical Midnight approach, no Ace3 dependency |
| `CreateFrame("ScrollFrame", ..., "UIPanelScrollFrameTemplate")` | Interface 120001 | Both left and right scrollable panels | Already used in PackFrame.lua; same pattern fits config panels |
| `CreateFrame("Button", ..., "BasicFrameTemplateWithInset")` | Interface 120001 | Config window chrome with title bar | Same template used for TPWPackFrame and TPWImportPopup |
| `CreateFrame("CheckButton")` | Interface 120001 | Per-skill enable/disable toggle | Standard WoW checkbox widget |
| `CreateFrame("EditBox")` | Interface 120001 | Label and TTS text fields | Standard WoW text input; needs OnEscapePressed handler |
| `GameTooltip:SetSpellByID(spellID)` | Interface 120001 | Spell tooltip on hover | Exact pattern already in IconDisplay.lua slot OnEnter |
| `SetPortraitTextureFromCreatureDisplayID` | Interface 120001 | NPC portrait in mob tree rows | Already used in PackFrame.lua GetPortraitTexture |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `C_Spell.GetSpellTexture(spellID)` | Interface 120001 | Spell icon for skill rows in config | In right panel ability rows for visual context |
| `PlaySound(soundKitID)` | All modern | Preview sound on dropdown select | Call immediately from dropdown OnClick |
| `C_VoiceChat.SpeakText(voiceID, text, 0, 100, false)` | Interface 120001 | TTS preview in config | Same pattern as IconDisplay.lua TrySpeak |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual ScrollFrame + SetPoint layout | ScrollBox / DataProvider | ScrollBox requires Blizzard Mixin infrastructure not present in TPW; overkill for static config tree |
| Simple Button + popup list for sound dropdown | UIDropDownMenu_Initialize | UIDropDownMenu is deprecated in Midnight |
| Simple Button + popup list for sound dropdown | DropdownButton:SetupMenu() | Modern but requires rootDescription Mixin infrastructure not present in TPW |
| ResizeLayoutFrame | Manual SetPoint anchoring | ResizeLayoutFrame requires children to expose GetLayoutChildrenBounds; manual anchoring already proven in PackFrame.lua |

**Installation:** No new libraries. Phase 13 uses only native WoW API.

---

## Architecture Patterns

### Recommended Project Structure (additions for Phase 13)

```
TerriblePackWarnings/
├── Core.lua                 # +"/tpw config" slash command branch
├── TerriblePackWarnings.toc # +UI\ConfigFrame.lua at end
├── Import/
│   └── Pipeline.lua         # +MergeSkillConfig helper, +npcCount tracking in BuildPack
├── UI/
│   ├── PackFrame.lua        # +mob count FontString overlays, +Config button in footer
│   └── ConfigFrame.lua      # NEW — lazy config window
└── (Data/, Engine/, Display/ unchanged in Phase 13)
```

### Pattern 1: Sparse skillConfig Override Schema

**What:** Per-skill user overrides stored in `ns.db.skillConfig[npcID][spellID]`. Only user-modified fields are stored — never a full copy of ability data. Defaults remain in AbilityDB.

**When to use:** Whenever Pipeline.BuildPack assembles abilities for a pack; whenever ConfigFrame reads current values for display; whenever ConfigFrame writes a user change.

**Example:**
```lua
-- Source: .planning/research/ARCHITECTURE.md — Q2 answer

-- Stored in TerriblePackWarningsDB at ADDON_LOADED (initialize to {} if nil):
ns.db.skillConfig = ns.db.skillConfig or {}

-- ConfigFrame writes on checkbox change:
ns.db.skillConfig[npcID] = ns.db.skillConfig[npcID] or {}
ns.db.skillConfig[npcID][spellID] = ns.db.skillConfig[npcID][spellID] or {}
ns.db.skillConfig[npcID][spellID].enabled = false  -- or nil to re-enable (default = enabled)

-- ConfigFrame writes on label edit:
ns.db.skillConfig[npcID][spellID].label = "BLOCK"  -- or nil to use AbilityDB default

-- ConfigFrame writes on sound selection:
-- nil means TTS mode (default); a soundKitID number means that sound
ns.db.skillConfig[npcID][spellID].soundKitID = 316493  -- Bell Ring
ns.db.skillConfig[npcID][spellID].ttsMessage = nil      -- only used in TTS mode

-- To reset a skill: set ns.db.skillConfig[npcID][spellID] = nil
-- To reset all skills for a dungeon: iterate AbilityDB[npcID] for all dungeon npcIDs,
-- set each skillConfig[npcID] = nil
```

### Pattern 2: MergeSkillConfig in Pipeline.BuildPack

**What:** A merge helper called per ability when building a pack. Returns nil for disabled abilities (pack silently drops them), or returns a merged ability table with user overrides applied.

**When to use:** Called inside BuildPack for every ability entry before inserting into pack.abilities.

**Example:**
```lua
-- Source: .planning/research/ARCHITECTURE.md — Q2 answer

local function MergeSkillConfig(npcID, ability, mobClass)
    local cfg = ns.db.skillConfig
        and ns.db.skillConfig[npcID]
        and ns.db.skillConfig[npcID][ability.spellID]
    if not cfg then
        -- No override: return ability unchanged (but copy to avoid mutating AbilityDB)
        return {
            name       = ability.name,
            spellID    = ability.spellID,
            mobClass   = mobClass,
            first_cast = ability.first_cast,
            cooldown   = ability.cooldown,
            label      = ability.label,
            ttsMessage = ability.ttsMessage,
        }
    end
    if cfg.enabled == false then return nil end  -- disabled: omit from pack
    return {
        name       = ability.name,
        spellID    = ability.spellID,
        mobClass   = mobClass,
        first_cast = ability.first_cast,
        cooldown   = ability.cooldown,
        label      = cfg.label      ~= nil and cfg.label      or ability.label,
        ttsMessage = cfg.ttsMessage ~= nil and cfg.ttsMessage or ability.ttsMessage,
        soundKitID = cfg.soundKitID,  -- nil means TTS mode
    }
end
```

### Pattern 3: ConfigFrame Lazy Construction

**What:** ConfigFrame is built on first open, not at file scope. Guard: `if not configFrame then ... build ... end` at top of ConfigFrame.Open().

**When to use:** Always for config windows opened infrequently. Never build dozens of widgets at ADDON_LOADED.

**Example:**
```lua
-- Source: .planning/research/ARCHITECTURE.md — Q5 answer

local configFrame = nil

local function BuildConfigFrame()
    configFrame = CreateFrame("Frame", "TPWConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(580, 480)   -- wider than pack window (300px)
    configFrame:SetPoint("CENTER")
    configFrame:Hide()
    configFrame.TitleText:SetText("TerriblePackWarnings — Config")
    tinsert(UISpecialFrames, "TPWConfigFrame")
    -- ... build left panel, right panel, etc.
end

ns.ConfigUI = {}
function ns.ConfigUI.Toggle()
    if not configFrame then BuildConfigFrame() end
    if configFrame:IsShown() then configFrame:Hide() else configFrame:Show() end
end
```

### Pattern 4: Collapsible Tree with RebuildLayout

**What:** Each dungeon node has a header Button and a content Frame. Toggling `node.expanded` shows/hides the content frame, then `RebuildLayout()` repositions all nodes top-to-bottom.

**When to use:** Left panel of ConfigFrame for the dungeon→mob tree.

**Example:**
```lua
-- Source: .planning/research/STACK.md — "Collapse/Expand Implementation" section

local nodes = {}

local function RebuildLayout(scrollChild)
    local yOffset = 0
    for _, node in ipairs(nodes) do
        node.header:ClearAllPoints()
        node.header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        node.header:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
        yOffset = yOffset + node.header:GetHeight()

        if node.expanded and node.content then
            node.content:ClearAllPoints()
            node.content:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            node.content:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
            node.content:SetHeight(node.contentHeight)
            node.content:Show()
            yOffset = yOffset + node.contentHeight
        elseif node.content then
            node.content:Hide()
        end
    end
    scrollChild:SetHeight(math.max(yOffset, 1))
    scrollFrame:UpdateScrollChildRect()
end
```

### Pattern 5: Mob Count Tracking in BuildPack

**What:** BuildPack tracks how many times each npcID appears in a pull (clone count from MDT pullData), stores as `pack.mobCounts[npcID] = count`. PackFrame reads this for the "x3" label.

**When to use:** Inside BuildPack when iterating pullData clones, before deduplication.

**Example:**
```lua
-- Source: .planning/research/FEATURES.md — Feature Area 4; MDT AceGUIWidget analysis

-- In BuildPack, before the seenNpc guard:
local mobCounts = {}  -- npcID -> count
for enemyIdx, clones in pairs(pullData) do
    if tonumber(enemyIdx) and enemies[enemyIdx] then
        local npcID = enemies[enemyIdx].id
        -- clones is a table; count its entries
        local cloneCount = 0
        for _ in pairs(clones) do cloneCount = cloneCount + 1 end
        mobCounts[npcID] = (mobCounts[npcID] or 0) + cloneCount
    end
end
pack.mobCounts = mobCounts

-- In PackFrame, portrait FontString overlay (per portrait slot):
-- After GetPortraitTexture(tex, npcID), if mobCounts[npcID] > 1:
if not tex.countLabel then
    tex.countLabel = row:CreateFontString(nil, "OVERLAY")
    tex.countLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    tex.countLabel:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 0, 0)
end
local count = pack.mobCounts and pack.mobCounts[npcIDs[p]] or 1
if count > 1 then
    tex.countLabel:SetText("x" .. count)
    tex.countLabel:Show()
else
    tex.countLabel:Hide()
end
```

### Pattern 6: Sound Dropdown as Button + Popup List

**What:** A Button showing the current sound name. On click, a small popup frame appears listing all sounds + "TTS" option. Selecting an option updates the button text, plays a preview, writes to skillConfig.

**When to use:** Per-skill sound/TTS selector in the right panel of ConfigFrame.

**Example:**
```lua
-- Source: .planning/research/STACK.md — "Sound Dropdown for Config UI" section

-- Data/Sounds.lua (new file) provides:
ns.AlertSounds = {
    { name = "TTS",             soundKitID = nil },     -- nil = TTS mode
    { name = "Bell Ring",       soundKitID = 316493 },
    { name = "Low Thud",        soundKitID = 316531 },
    { name = "Air Horn",        soundKitID = 316436 },
    { name = "Warhorn",         soundKitID = 316723 },
    { name = "Fanfare",         soundKitID = 316769 },
    { name = "Wolf Howl",       soundKitID = 316766 },
    { name = "Chime Ascending", soundKitID = 316447 },
    { name = "Anvil Strike",    soundKitID = 316528 },
    { name = "Metal Clanks",    soundKitID = 316532 },
    { name = "Bell Trill",      soundKitID = 316712 },
    { name = "Rooster",         soundKitID = 316765 },
}

-- On option select:
if soundKitID then
    PlaySound(soundKitID)  -- preview
    skillConfig.soundKitID = soundKitID
    ttsEditBox:Disable()
    ttsEditBox:SetAlpha(0.4)
else  -- TTS selected
    skillConfig.soundKitID = nil
    ttsEditBox:Enable()
    ttsEditBox:SetAlpha(1.0)
end
```

### Pattern 7: Spell Tooltip in Config Row (CFG-05)

**What:** Skill rows in the right panel enable mouse, set OnEnter/OnLeave to show GameTooltip using SetSpellByID.

**When to use:** Every skill row in the right panel.

**Example:**
```lua
-- Source: Display/IconDisplay.lua lines 88-96 (direct source read)
-- Exact same pattern already proven in IconDisplay.lua CreateIconSlot

skillRow:EnableMouse(true)
skillRow:SetScript("OnEnter", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetSpellByID(self.spellID)
    GameTooltip:Show()
end)
skillRow:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
```

### Anti-Patterns to Avoid

- **Storing full ability copies in skillConfig:** Bloats SavedVariables and shadows future AbilityDB changes. Store ONLY user-modified fields; merge defaults at BuildPack time.
- **Eager ConfigFrame construction at file scope:** Wastes memory and login time. ConfigFrame is opened rarely — build lazily.
- **Using UIDropDownMenu_Initialize:** Deprecated in Midnight. Use a simple Button + popup list.
- **Using ScrollBox / DataProvider:** Requires Blizzard Mixin infrastructure not in TPW. Use manual ScrollFrame + SetPoint.
- **Hot-swapping in-memory pack data from ConfigFrame:** Changes take effect on next import or route rebuild only. Do not plan a live-reload mechanism for v0.1.0.
- **Sorting npcIDs in pack.npcIDs array:** Sort portrait display order by mobCount descending at display time in PackFrame, not at storage time in BuildPack.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Spell tooltip | Custom tooltip frame | `GameTooltip:SetSpellByID(spellID)` | Built-in, already used in IconDisplay.lua; handles localization, icon, description automatically |
| NPC portrait | Custom portrait fetch | `SetPortraitTextureFromCreatureDisplayID` + `GetPortraitTexture` helper from PackFrame.lua | Already implemented and tested; handles fallback chain to class icon to question mark |
| Scrollable list | Custom virtual scroll | `ScrollFrame + UIPanelScrollFrameTemplate` | Already used in PackFrame.lua; static config tree does not need virtualization |
| Sound preview | Custom audio routing | `PlaySound(soundKitID)` bare call | One argument is sufficient; no channel routing needed for config preview |
| Checkbox | Custom toggle button | `CreateFrame("CheckButton")` | Standard WoW widget; handles checked/unchecked state and visual |
| Text input | Custom input handling | `CreateFrame("EditBox")` with `OnEscapePressed` | Standard WoW widget; requires escape-to-defocus handler to avoid trapping input |

**Key insight:** Every UI widget needed for Phase 13 is a standard WoW API frame type. Zero custom rendering is required.

---

## Common Pitfalls

### Pitfall 1: skillConfig enabled=nil vs enabled=false

**What goes wrong:** Code checks `if cfg.enabled == false` but a user who re-enables a skill sets `cfg.enabled = nil` (by clearing the key). If the check is `if not cfg.enabled` it treats nil (default = enabled) the same as false (explicitly disabled).

**Why it happens:** Lua's nil-as-absence pattern. The sparse schema stores nothing for enabled skills; only `enabled = false` is stored for disabled ones.

**How to avoid:** The merge helper must check `cfg.enabled == false` explicitly (strict equality). `nil` means "use default" which is enabled.

**Warning signs:** Skills that should appear in packs are missing even though no checkbox was unchecked.

---

### Pitfall 2: EditBox trapping keyboard input

**What goes wrong:** Player types in the label or TTS EditBox, then the game receives no keyboard input (can't move, abilities don't fire) until clicking elsewhere or reloading.

**Why it happens:** EditBox:SetFocus() keeps focus until explicitly cleared. In WoW addon UI, EditBoxes must call `self:ClearFocus()` on Enter and on Escape.

**How to avoid:** Always set both scripts on every EditBox:
```lua
editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
```

**Warning signs:** Player cannot move or use abilities after clicking into a config EditBox.

---

### Pitfall 3: scrollChild height not updated after expand/collapse

**What goes wrong:** Collapsing a dungeon tree node hides child frames visually but the scroll child height is not updated, leaving dead scroll space. Expanding a node causes content to overflow outside the scroll area.

**Why it happens:** ScrollFrame does not automatically recalculate scroll range when child frames change size/visibility.

**How to avoid:** After every expand/collapse, call:
```lua
scrollChild:SetHeight(totalContentHeight)
scrollFrame:UpdateScrollChildRect()
```
Always compute `totalContentHeight` by summing all visible node heights in `RebuildLayout`.

**Warning signs:** Scroll bar shows incorrect range; content appears clipped or scroll area has empty space at bottom.

---

### Pitfall 4: ConfigFrame right panel not cleared on mob switch

**What goes wrong:** Clicking a different mob in the left panel shows the new mob's skills overlaid on top of the previous mob's skill widgets — duplicate/orphaned frames are visible.

**Why it happens:** Right panel widgets are created fresh each time without hiding or repositioning the old ones.

**How to avoid:** Maintain a `rightPanelRows` table. On every mob selection, iterate and hide all existing right panel rows before building new ones. Alternatively, pool right panel rows and reuse them (like PackFrame does with `rows` table).

**Warning signs:** Skills from a previously viewed mob remain visible when a different mob is selected.

---

### Pitfall 5: pack.npcIDs does not include clone counts (ROUTE-04)

**What goes wrong:** Currently `pack.npcIDs` is a deduplicated list (one entry per unique npcID). The mob count ("x3") requires knowing how many of each npcID appeared in the pull, which is distinct from the deduplication guard.

**Why it happens:** The existing BuildPack `seenNpc` guard correctly deduplicates for the ability list but discards clone count information in the process.

**How to avoid:** Before the `seenNpc` guard, iterate pullData to count clones per npcID and store as `pack.mobCounts[npcID]`. The count loop and the dedup loop are separate passes (or a combined loop that counts first, then deduplicates npcIDs).

**Warning signs:** All portrait overlays show "x1" even for pulls with multiple copies of the same mob type.

---

### Pitfall 6: AbilityDB organized by npcID, not dungeon

**What goes wrong:** The left panel tree needs to enumerate mobs by dungeon. But `ns.AbilityDB` is a flat map of `npcID -> entry`. There is no index from dungeon to its npcIDs in AbilityDB.

**Why it happens:** AbilityDB is designed for runtime lookup by npcID (fast), not for UI enumeration by dungeon.

**How to avoid:** ConfigFrame must build a dungeon-keyed index at BuildConfigFrame time:
```lua
local dungeonMobs = {}  -- dungeonKey -> array of { npcID, mobName }
-- Iterate ns.DungeonEnemies (already organized by dungeonIdx),
-- cross-reference with ns.AbilityDB to find mobs that have tracked abilities.
for dungeonIdx, enemies in pairs(ns.DungeonEnemies) do
    local dungeonKey = DUNGEON_IDX_MAP[dungeonIdx] and DUNGEON_IDX_MAP[dungeonIdx].key
    if dungeonKey then
        dungeonMobs[dungeonKey] = dungeonMobs[dungeonKey] or {}
        for _, enemy in pairs(enemies) do
            if enemy.id and ns.AbilityDB[enemy.id] then
                table.insert(dungeonMobs[dungeonKey], {
                    npcID = enemy.id,
                    name  = enemy.name,
                })
            end
        end
    end
end
```
`DUNGEON_IDX_MAP` already exists in Pipeline.lua — ConfigFrame will need access to the same mapping. Either expose it on `ns` or duplicate it in ConfigFrame.lua.

**Warning signs:** Config window left panel is empty or shows all mobs under one generic category.

---

## Code Examples

Verified patterns from existing source files:

### Existing ScrollFrame pattern (PackFrame.lua lines 194-200)
```lua
-- Source: UI/PackFrame.lua — direct source read 2026-03-17
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -46)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 35)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(250)
scrollFrame:SetScrollChild(scrollChild)
```

### Existing NPC portrait (PackFrame.lua lines 59-75)
```lua
-- Source: UI/PackFrame.lua — direct source read 2026-03-17
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

### Existing spell tooltip (IconDisplay.lua lines 88-96)
```lua
-- Source: Display/IconDisplay.lua — direct source read 2026-03-17
slot:EnableMouse(true)
slot:SetScript("OnEnter", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetSpellByID(self.spellID)
    GameTooltip:Show()
end)
slot:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
```

### Existing import popup (model for config window popup list)
```lua
-- Source: UI/PackFrame.lua lines 96-106 — direct source read 2026-03-17
-- BasicFrameTemplateWithInset + UISpecialFrames pattern for Escape-to-close
local importPopup = CreateFrame("Frame", "TPWImportPopup", UIParent, "BasicFrameTemplateWithInset")
importPopup:SetSize(320, 200)
importPopup:SetPoint("CENTER")
importPopup:Hide()
importPopup:SetFrameStrata("DIALOG")
importPopup.TitleText:SetText("Import MDT Route")
tinsert(UISpecialFrames, "TPWImportPopup")
```

### Current Pipeline.BuildPack (before Phase 13 changes)
```lua
-- Source: Import/Pipeline.lua lines 23-68 — direct source read 2026-03-17
-- NOTE: seenNpc deduplication currently discards clone count information.
-- Phase 13 adds mobCounts tracking BEFORE the seenNpc guard.
local seenNpc = {}
for enemyIdx, clones in pairs(pullData) do
    if tonumber(enemyIdx) and enemies[enemyIdx] then
        local npcID = enemies[enemyIdx].id
        if not seenNpc[npcID] then
            seenNpc[npcID] = true
            table.insert(pack.npcIDs, npcID)
            -- ... build abilities
        end
    end
end
```

### PlaySound for sound preview (from STACK.md verified source)
```lua
-- Source: .planning/research/STACK.md — SoundDocumentation.lua verified
-- Only soundKitID is required. No extra flags needed for config preview.
PlaySound(316493)  -- Bell Ring preview
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `UIDropDownMenu_Initialize` | Simple Button + popup list | Midnight (deprecated) | UIDropDownMenu APIs are deprecated; simple popup list is the correct approach for TPW |
| `SOUNDKIT` constants | Raw soundKitID numbers | Always separate concerns | SOUNDKIT maps UI event sounds; CDM alert sounds use their own soundKitIDs not in SOUNDKIT |
| Single "imported" PackDatabase key | Per-dungeon key (Phase 15) | Phase 15 (future) | Phase 13 still uses "imported" key — per-dungeon refactor is Phase 15 scope |

**Deprecated / not applicable in Phase 13:**
- `ScrollBox / DataProvider`: Modern Blizzard pattern but requires Mixin infrastructure not in TPW
- `ResizeLayoutFrame`: Requires `GetLayoutChildrenBounds` on children; manual SetPoint is simpler

---

## Phase 13 Scope Boundary (Critical)

Phase 13 does NOT include:
- Per-dungeon route storage refactor (`"imported"` → `dungeonKey`) — this is Phase 15
- Additional dungeon data files (Phase 14)
- Cast detection / UnitCastingInfo polling (Phase 16)
- Sound playback during combat (Phase 16)
- Zone auto-switch (Phase 15/16)
- Dungeon selector UI in PackFrame (Phase 15)

Phase 13 DOES include:
- `ns.db.skillConfig` schema initialization in Core.lua ADDON_LOADED
- `MergeSkillConfig` helper in Pipeline.lua (called in BuildPack)
- `pack.mobCounts` tracking in BuildPack
- Portrait count overlays in PackFrame pull rows (ROUTE-04)
- `UI/ConfigFrame.lua` — lazy config window with left + right panels
- Per-skill: enabled checkbox, label EditBox, TTS EditBox, sound Button+popup (CFG-01 through CFG-05)
- `/tpw config` slash command in Core.lua
- Optional: Config button in PackFrame footer

The config window reads `ns.AbilityDB` (WindrunnerSpire.lua has 6 npcIDs, 4 distinct abilities). That is sufficient to validate the entire tree and all per-skill controls.

---

## Open Questions

1. **DUNGEON_IDX_MAP accessibility from ConfigFrame**
   - What we know: `DUNGEON_IDX_MAP` is a `local` in Pipeline.lua
   - What's unclear: ConfigFrame needs dungeon name + key to build the tree headers. Options: (a) expose DUNGEON_IDX_MAP on `ns`, (b) duplicate a read-only copy in ConfigFrame.lua, (c) derive dungeon grouping from DungeonEnemies + AbilityDB cross-reference
   - Recommendation: Expose as `ns.DUNGEON_IDX_MAP` in Pipeline.lua — one line change, clean access

2. **Right panel scroll vs static layout**
   - What we know: WindrunnerSpire mobs have 1 ability each; worst case in future dungeons may be 3-4 abilities per mob
   - What's unclear: Whether a ScrollFrame for the right panel is needed at all given small ability counts
   - Recommendation: Use ScrollFrame for the right panel for future-proofing; cost is minimal given the same pattern is used in the left panel

3. **Reset All dungeon scope**
   - What we know: "Reset All" per dungeon should clear all skillConfig entries for mobs belonging to that dungeon
   - What's unclear: The mapping from dungeonKey to its set of npcIDs must be derived (not stored); it requires iterating DungeonEnemies[dungeonIdx] and filtering by AbilityDB presence
   - Recommendation: Compute this in the Reset All handler at click time — no need to store the inverse index permanently

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual in-game testing only (no automated test runner for WoW addons) |
| Config file | None |
| Quick run command | `./scripts/install.bat` then `/reload` in-game |
| Full suite command | In-game test session per success criteria checklist |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CFG-01 | Config window opens with dungeon list; WindrunnerSpire expands to show its mobs | manual | `/tpw config` in-game, observe left panel | ❌ Wave 0 |
| CFG-02 | Click a mob row; right panel shows its abilities with all settings fields | manual | Click mob row in config window | ❌ Wave 0 |
| CFG-03 | Uncheck a skill; re-import; icon does not appear when pack is active | manual | Uncheck, re-import route, pull mobs | ❌ Wave 0 |
| CFG-04 | Set custom label; re-import; custom label appears on spell icon display | manual | Edit label, re-import route, pull mobs | ❌ Wave 0 |
| CFG-05 | Hover skill row in config; WoW spell tooltip appears | manual | Mouse over ability row in config window | ❌ Wave 0 |
| ROUTE-04 | Pull rows show "x3" (or similar count) on portraits where multiple of same mob type appear | manual | Import WS route with multi-mob pulls, observe PackFrame | ❌ Wave 0 |

All tests are manual-only. WoW addons have no viable automated test runner — the client must be running.

### Sampling Rate
- **Per task commit:** Deploy with `./scripts/install.bat`, `/reload` in-game, smoke-test the specific feature added
- **Per wave merge:** Full in-game session covering all 6 requirements above
- **Phase gate:** All 6 success criteria TRUE before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `UI/ConfigFrame.lua` — does not exist yet; created in Wave 1
- [ ] `Data/Sounds.lua` — sound list for dropdown; created in Wave 1
- [ ] `ns.db.skillConfig` initialization — added to Core.lua ADDON_LOADED in Wave 1
- [ ] `MergeSkillConfig` + `pack.mobCounts` — added to Pipeline.lua in Wave 1

No automated test files to create — manual in-game testing is the only option for WoW addon verification.

---

## Sources

### Primary (HIGH confidence)
- `C:\Users\jonat\Repositories\TerriblePackWarnings\UI\PackFrame.lua` — ScrollFrame pattern, GetPortraitTexture, portrait pool, PopulateList structure, row creation
- `C:\Users\jonat\Repositories\TerriblePackWarnings\Display\IconDisplay.lua` — GameTooltip:SetSpellByID pattern, CreateIconSlot, ShowStaticIcon signature
- `C:\Users\jonat\Repositories\TerriblePackWarnings\Import\Pipeline.lua` — BuildPack structure, DUNGEON_IDX_MAP, seenNpc dedup, "imported" key usage
- `C:\Users\jonat\Repositories\TerriblePackWarnings\Core.lua` — ADDON_LOADED handler, ns.db initialization, slash command structure
- `C:\Users\jonat\Repositories\TerriblePackWarnings\Data\WindrunnerSpire.lua` — AbilityDB schema, 6 npcIDs, 4 abilities (validation data for Phase 13)
- `.planning/research/ARCHITECTURE.md` — skillConfig schema, MergeSkillConfig, ConfigFrame placement, integration Q&A
- `.planning/research/STACK.md` — ScrollFrame config UI pattern, sound dropdown approach, collapse/expand implementation
- `.planning/research/FEATURES.md` — mob count display pattern (MDT "x3" source), CDM sound library (67 sounds, 6 categories)

### Secondary (MEDIUM confidence)
- `C:\Users\jonat\Repositories\MythicDungeonTools\AceGUIWidgets\AceGUIWidget-MythicDungeonToolsPullButton.lua` — mob count per portrait, "x"..quantity pattern, sort-by-count descending (verified from FEATURES.md)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_CooldownViewer\CooldownViewerSettings.xml` — ScrollFrame layout, collapsible category pattern (verified from STACK.md)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_CooldownViewer\CooldownViewerSoundAlertData.lua` — 67 CDM soundKitIDs in 6 categories (verified from FEATURES.md)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all widgets and APIs already used in existing TPW code
- Architecture: HIGH — derived from direct analysis of all TPW source files + wow-ui-source
- Pitfalls: HIGH — sourced from existing code analysis and documented in ARCHITECTURE.md anti-patterns
- Sound data: HIGH — soundKitIDs verified from wow-ui-source CDM files

**Research date:** 2026-03-17
**Valid until:** 2026-04-17 (WoW API is stable; CDM soundKitIDs are baked into client)
