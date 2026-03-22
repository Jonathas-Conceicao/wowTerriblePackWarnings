# Phase 15: Per-Dungeon Route Storage - Research

**Researched:** 2026-03-20
**Domain:** WoW addon SavedVariables schema migration, multi-dungeon state management, UI refactor
**Confidence:** HIGH

## Summary

Phase 15 is a structural refactor that retires the `PackDatabase["imported"]` single-key pattern across four files and replaces it with a per-dungeon keyed system. All 8 S1 dungeon routes live independently in SavedVariables under `ns.db.importedRoutes[dungeonKey]`. The refactor is atomic — all four call sites change together or not at all.

The phase also adds two new UI features to PackFrame.lua: a dungeon selector dropdown (popup frame pattern reusing the sound popup approach from ConfigFrame.lua) and a combat mode selector (three mutually exclusive buttons: Auto/Manual/Disable). A new `ZONE_DUNGEON_MAP` with all 8 instance names enables auto-switch on zone-in via `GetInstanceInfo()`, which already fires through the existing `PLAYER_ENTERING_WORLD` event pathway.

SavedVariables migration is handled in the `ADDON_LOADED` handler: detect `ns.db.importedRoute` (old field), migrate its content to `ns.db.importedRoutes[dungeonKey]`, then delete the old field. No data is lost.

**Primary recommendation:** Execute the atomic grep-verified refactor first as a single wave, then layer the UI additions (dropdown + combat mode buttons) on top with the new CombatWatcher behavior.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Dungeon Selector UX**
- Dropdown at top of Route window showing current dungeon name
- Click to see all 8 S1 dungeons (just names, no route status indicators)
- When no route imported for selected dungeon: show "No route imported for [Dungeon]. Click Import to add one." with Import button visible
- Dropdown does not indicate which dungeons have routes — simple name list

**Zone-In Auto-Switch Behavior**
- On zone-in: auto-switch to that dungeon's route AND reset to pull 1
- ZONE_DUNGEON_MAP populated with hardcoded instance names for all 8 S1 dungeons
- If no route imported for the dungeon: switch anyway, show import prompt, print chat notification "TPW: No route for [Dungeon]. Import one with /tpw"
- Uses GetInstanceInfo() for zone detection (existing pattern)

**Import/Clear Per Dungeon**
- Import auto-detects dungeon from MDT string (dungeonIdx in preset) — route stored under correct dungeon automatically
- After import: Route window auto-switches to show the imported dungeon
- Importing a route for a dungeon that already has one: replace silently, no confirmation
- Clear: clears route for currently selected dungeon only, other dungeons keep their routes
- Existing confirmation dialog "Clear imported route?" still applies but now says "Clear route for [Dungeon]?"

**Combat Mode Selector**
- Three mutually exclusive buttons in Route window: Auto, Manual, Disable
- **Auto**: current behavior — auto-advance packs on combat start/end, trigger icons and warnings
- **Manual**: icons/warnings trigger for selected pack, but NO auto-advance on combat start/end. Player manually clicks pulls to navigate.
- **Disable**: addon does nothing — no scanning, no icons, no warnings
- Mode persists in SavedVariables

**SavedVariables Schema Migration**
- `ns.db.importedRoute` (single object) → `ns.db.importedRoutes` (keyed by dungeonKey, e.g. `ns.db.importedRoutes["windrunner_spire"]`)
- Add `ns.db.schemaVersion` for migration detection
- On ADDON_LOADED: if `ns.db.importedRoute` exists (old format), migrate to `importedRoutes[dungeonKey]` then delete old field
- `ns.db.combatMode` stores "auto" / "manual" / "disable" (default: "auto")
- `ns.db.selectedDungeon` stores last-selected dungeon key for Route window state persistence

### Claude's Discretion
- Exact visual treatment of combat mode buttons
- SavedVariables schema version number
- How to handle the `"imported"` key retirement across all files (atomic grep-verified refactor per STATE.md pitfall)
- RestoreFromSaved -> RestoreAllFromSaved iteration pattern
- Whether dropdown uses a popup frame (like sound popup) or a simpler approach

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ROUTE-01 | Each dungeon stores its own imported route independently in SavedVariables | SavedVariables schema migration pattern documented below; `ns.db.importedRoutes[dungeonKey]` replaces single `ns.db.importedRoute` field |
| ROUTE-02 | TPW window has dungeon selector to switch active dungeon view | Sound popup pattern from ConfigFrame.lua is directly reusable; dropdown as popup frame with 8 dungeon name buttons |
| ROUTE-03 | Active dungeon auto-switches on zone-in via GetInstanceInfo | ZONE_DUNGEON_MAP expansion documented below; existing PLAYER_ENTERING_WORLD -> CombatWatcher:Reset() pathway already in place |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| WoW Lua API (Midnight) | 12.0 | SavedVariables, frame creation, events | Only option for WoW addons |
| GetInstanceInfo() | Built-in | Returns instance name, type, difficultyID, etc. | Used by every WoW addon for zone detection |
| BasicFrameTemplateWithInset | Built-in | Frame template with title bar and close button | Already used in importPopup and configFrame |
| GameMenuButtonTemplate | Built-in | Standard button template | Already used for Import/Clear/Config footer buttons |
| StaticPopupDialogs | Built-in | Confirmation dialogs | Already used for TPW_CONFIRM_CLEAR |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UISpecialFrames | Built-in | Register frames that close on Escape | Any new popup frame that should close on Esc |
| C_Timer.After | Built-in | Deferred frame layout recalculation | Already used in PackFrame scroll centering |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Popup frame for dropdown | UIDropDownMenu | UIDropDownMenu is legacy, unreliable in Midnight; popup frame pattern already proven in this addon |
| schemaVersion integer | Boolean migration check | Integer version future-proofs additional migrations in Phase 16+ |

**Installation:** No new packages — pure WoW API.

## Architecture Patterns

### Recommended Project Structure
No new files needed. All changes are in-place modifications of existing files:

```
Core.lua                    -- migration logic + RestoreAllFromSaved call
Engine/CombatWatcher.lua    -- ZONE_DUNGEON_MAP expansion, Reset() rewrite, combat mode guards
Import/Pipeline.lua         -- RunFromPreset, RestoreAllFromSaved, Clear (per-dungeon)
UI/PackFrame.lua            -- dungeon dropdown, combat mode buttons, updated PopulateList
```

### Pattern 1: SavedVariables Schema Migration in ADDON_LOADED

**What:** Check for old-format field on load, migrate data, remove old field. Guard with schemaVersion.
**When to use:** Any time a stored field is renamed or restructured.

```lua
-- In Core.lua ADDON_LOADED handler, AFTER ns.db assignment:
local SCHEMA_VERSION = 1

if not ns.db.schemaVersion then
    -- v0.0.x -> v0.1.0 migration: importedRoute -> importedRoutes[dungeonKey]
    if ns.db.importedRoute then
        local old = ns.db.importedRoute
        local dungeonInfo = old.dungeonIdx and ns.DUNGEON_IDX_MAP[old.dungeonIdx]
        if dungeonInfo then
            ns.db.importedRoutes = ns.db.importedRoutes or {}
            ns.db.importedRoutes[dungeonInfo.key] = old
        end
        ns.db.importedRoute = nil  -- delete old field
    end
    ns.db.schemaVersion = SCHEMA_VERSION
end

-- Initialize new fields with defaults
ns.db.importedRoutes  = ns.db.importedRoutes or {}
ns.db.combatMode      = ns.db.combatMode or "auto"
ns.db.selectedDungeon = ns.db.selectedDungeon or nil
```

Note: migration reads `ns.DUNGEON_IDX_MAP` (already exposed by Pipeline.lua at file scope). Core.lua loads before Pipeline.lua per the TOC. The DUNGEON_IDX_MAP must be accessible. **Pitfall:** DUNGEON_IDX_MAP is a local in Pipeline.lua that is exposed via `ns.DUNGEON_IDX_MAP = DUNGEON_IDX_MAP` — but Pipeline.lua loads AFTER Core.lua. The migration logic in Core.lua cannot use `ns.DUNGEON_IDX_MAP` at ADDON_LOADED time if it hasn't loaded yet.

**Resolution:** Move migration logic to Pipeline.lua's module scope (runs at load time after ns.DUNGEON_IDX_MAP is set), or define a minimal inline lookup table in Core.lua's ADDON_LOADED handler. The cleanest approach: call a new `Import.Migrate()` function from Core.lua's ADDON_LOADED — Pipeline.lua loads before ADDON_LOADED fires (TOC order determines load order, ADDON_LOADED fires after all files load). Verified: TOC order is Core.lua first, then Pipeline.lua — but ALL files are loaded before ADDON_LOADED fires. So `ns.DUNGEON_IDX_MAP` IS available at ADDON_LOADED time. Confidence: HIGH (this is how Lua module loading works in WoW).

### Pattern 2: Per-Dungeon PackDatabase and RestoreAllFromSaved

**What:** Replace single `RunFromPreset` call with iteration over all saved routes.
**When to use:** Login restore.

```lua
-- In Pipeline.lua
function Import.RestoreAllFromSaved()
    if not ns.db.importedRoutes then return end
    local count = 0
    for dungeonKey, saved in pairs(ns.db.importedRoutes) do
        if saved.preset and saved.dungeonIdx then
            local packs = BuildPacksFromPreset(saved.preset, saved.dungeonIdx)
            ns.PackDatabase[dungeonKey] = packs
            count = count + 1
        end
    end
    if count > 0 then
        -- Select the last-used dungeon if present
        local selectKey = ns.db.selectedDungeon
        if selectKey and ns.PackDatabase[selectKey] then
            ns.CombatWatcher:SelectDungeon(selectKey)
        end
        print(string.format("|cff00ccffTPW|r Restored %d dungeon route(s).", count))
    end
end
```

Note: `BuildPacksFromPreset` is the refactored inner logic of `RunFromPreset` that returns packs without side effects on PackDatabase. `RunFromPreset` becomes a thin wrapper that calls `BuildPacksFromPreset` then stores results.

### Pattern 3: ZONE_DUNGEON_MAP Expansion

**What:** Hardcoded map from instance names (returned by GetInstanceInfo()) to dungeon keys.
**When to use:** In CombatWatcher:Reset() which is called on PLAYER_ENTERING_WORLD.

Current state: only "Windrunner Spire" is mapped. Needs expansion to all 8.

```lua
local ZONE_DUNGEON_MAP = {
    ["Windrunner Spire"]     = "windrunner_spire",
    ["Algethar Academy"]     = "algethar_academy",
    ["Pit of Saron"]         = "pit_of_saron",
    ["Skyreach"]             = "skyreach",
    ["Magisters' Terrace"]   = "magisters_terrace",
    ["Maisara Caverns"]      = "maisara_caverns",
    ["Nexus Point: Xenas"]   = "nexus_point_xenas",
    ["Seat of the Triumvirate"] = "seat_of_the_triumvirate",
}
```

**Critical gap — instance name verification:** The instance names above are derived from DUNGEON_IDX_MAP names in Pipeline.lua. GetInstanceInfo() returns the actual in-game instance name which may differ (e.g., possessives like "Magisters' Terrace" vs "Magisters Terrace"). These MUST be verified in-game during testing. Confidence: LOW for exact strings — they need in-game confirmation.

**Verification plan:** After implementation, enter each dungeon and print the GetInstanceInfo() return value in the ADDON_LOADED/Reset() path via debug logging. The `/tpw status` command or a new `/tpw zone` command could print this.

### Pattern 4: Combat Mode Guards in CombatWatcher

**What:** Check `ns.db.combatMode` before acting on PLAYER_REGEN_DISABLED/ENABLED.
**When to use:** OnCombatStart, OnCombatEnd.

```lua
function CombatWatcher:OnCombatStart()
    local mode = ns.db and ns.db.combatMode or "auto"
    if mode == "disable" then return end
    if state ~= "ready" then return end
    -- Manual mode: scanning still triggers but no auto-advance
    -- (scanning starts so icons show for selected pack)
    local dungeon = ns.PackDatabase[selectedDungeon]
    local pack = dungeon and dungeon[currentPackIndex]
    if not pack then return end
    ns.NameplateScanner:Start(pack)
    state = "active"
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end

function CombatWatcher:OnCombatEnd()
    local mode = ns.db and ns.db.combatMode or "auto"
    if mode == "disable" then return end
    if state ~= "active" then return end
    ns.NameplateScanner:Stop()
    ns.Scheduler:Stop()
    if mode == "manual" then
        -- Stay on current pack, return to ready without advancing
        state = "ready"
        if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
        return
    end
    -- Auto mode: advance to next pack (existing behavior)
    -- ... existing advance logic ...
end
```

### Pattern 5: Dungeon Dropdown (Popup Frame)

**What:** A popup frame listing 8 dungeon name buttons, anchored to the dropdown trigger button. Reuses the sound popup construction pattern from ConfigFrame.lua.
**When to use:** When user clicks the dungeon selector at the top of PackFrame.

```lua
-- Build once, reuse (same pattern as BuildSoundPopup in ConfigFrame.lua)
local dungeonDropdown = nil

local function BuildDungeonDropdown()
    dungeonDropdown = CreateFrame("Frame", "TPWDungeonDropdown", UIParent, "BasicFrameTemplateWithInset")
    dungeonDropdown:SetSize(200, 8 * 22 + 16)  -- 8 dungeons x 22px rows + padding
    dungeonDropdown:Hide()
    dungeonDropdown:SetFrameStrata("DIALOG")
    tinsert(UISpecialFrames, "TPWDungeonDropdown")
    -- Build one button per dungeon from ns.DUNGEON_IDX_MAP
    -- OnClick: set ns.db.selectedDungeon, refresh PackUI, hide dropdown
end

local function ShowDungeonDropdown(anchorBtn)
    if not dungeonDropdown then BuildDungeonDropdown() end
    dungeonDropdown:ClearAllPoints()
    dungeonDropdown:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, 0)
    dungeonDropdown:Show()
end
```

### Pattern 6: Combat Mode Buttons (Toggle Group)

**What:** Three buttons in the PackFrame footer. Active button gets a distinct visual state (highlight texture or pushed state). Style inspired by WoW stance bar buttons.
**When to use:** PackFrame footer, below or beside the existing Import/Clear/Config buttons.

```lua
-- Three buttons with mutual exclusion
local modeButtons = {}
local function SetCombatMode(mode)
    ns.db.combatMode = mode
    for _, btn in pairs(modeButtons) do
        btn:SetAlpha(btn.mode == mode and 1.0 or 0.5)
        -- or use btn:SetChecked() if using CheckButton template
    end
    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end
```

Visual treatment recommendation: Use `GameMenuButtonTemplate` buttons at reduced alpha (0.5) for inactive state, full alpha (1.0) for active. This matches the addon's existing button style without requiring new textures. The active button can also use a pushed background color (`SetColorTexture` on a BACKGROUND texture).

### Anti-Patterns to Avoid

- **Partial refactor:** Changing `PackDatabase["imported"]` in Pipeline.lua but forgetting PackFrame.lua line 354 (`activeDungeon == "imported"`) — this breaks row state coloring silently.
- **Migration without schemaVersion:** Running migration logic every login — will corrupt data on the second load if old field is gone.
- **Iterating DUNGEON_IDX_MAP in unspecified order:** Lua table iteration is unordered. When building the dropdown list, sort by dungeonName for consistent ordering.
- **GetInstanceInfo() before PLAYER_ENTERING_WORLD settles:** GetInstanceInfo() called too early may return the previous zone. The Reset() method is already called from PLAYER_ENTERING_WORLD which fires after the zone transition is complete — safe.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dropdown UI | Custom frame from scratch | Sound popup pattern (ConfigFrame.lua lines 107-124) | Already tested, handles Escape key via UISpecialFrames |
| Confirmation dialog | Custom frame | StaticPopupDialogs (already TPW_CONFIRM_CLEAR) | WoW standard, handles edge cases (combat, multiple dialogs) |
| Ordered dungeon list | Custom sort | table.sort on DUNGEON_IDX_MAP values | Already done in ConfigFrame.lua BuildDungeonIndex() |

**Key insight:** The sound popup construction pattern is the template for the dungeon dropdown. The two differ only in data source (AlertSounds vs DUNGEON_IDX_MAP) and OnClick behavior.

## Common Pitfalls

### Pitfall 1: Atomic Refactor Incompleteness
**What goes wrong:** Changing `PackDatabase["imported"]` in one file but missing another. The addon silently uses stale data or errors on nil dungeon keys.
**Why it happens:** "imported" appears in 4 files at 15 call sites (verified by grep above).
**How to avoid:** Run `grep -r '"imported"' *.lua` after the refactor. Zero results = complete. The grep output from research shows all 15 locations.
**Warning signs:** PackFrame shows no packs after importing; CombatWatcher:Reset() prints "unknown dungeon key 'imported'".

Complete grep inventory of all `"imported"` references that must change:

| File | Line | Current | Changes To |
|------|------|---------|-----------|
| Pipeline.lua | 152 | `ns.PackDatabase["imported"] = packs` | `ns.PackDatabase[dungeonKey] = packs` |
| Pipeline.lua | 167 | `ns.CombatWatcher:SelectDungeon("imported")` | `ns.CombatWatcher:SelectDungeon(dungeonKey)` |
| Pipeline.lua | 195 | `ns.PackDatabase["imported"] or {}` | `ns.PackDatabase[dungeonKey] or {}` |
| Pipeline.lua | 201 | `ns.PackDatabase["imported"] = saved.packs` | `ns.PackDatabase[dungeonKey] = saved.packs` |
| Pipeline.lua | 203 | `ns.CombatWatcher:SelectDungeon("imported")` | `ns.CombatWatcher:SelectDungeon(dungeonKey)` |
| Pipeline.lua | 210 | `ns.PackDatabase["imported"] = nil` | `ns.PackDatabase[dungeonKey] = nil` |
| CombatWatcher.lua | 148 | `ns.PackDatabase["imported"]` | `ns.PackDatabase[selectedDungeon]` |
| CombatWatcher.lua | 149 | `selectedDungeon = "imported"` | `selectedDungeon = detectedKey` |
| PackFrame.lua | 277 | `ns.PackDatabase["imported"]` | `ns.PackDatabase[selectedDungeonKey]` |
| PackFrame.lua | 329 | `ns.db.importedRoute and ns.db.importedRoute.dungeonIdx` | per-dungeon lookup |
| PackFrame.lua | 354 | `activeDungeon == "imported"` | `activeDungeon == selectedDungeonKey` |
| PackFrame.lua | 372 | `ns.CombatWatcher:SelectPack("imported", packIndex)` | `ns.CombatWatcher:SelectPack(selectedDungeonKey, packIndex)` |
| PackFrame.lua | 385 | `activeDungeon == "imported"` | `activeDungeon == selectedDungeonKey` |

Also: `ns.db.importedRoute` references in Pipeline.lua (lines 156, 188, 189, 211) and PackFrame.lua (lines 180, 181, 329) must migrate to `ns.db.importedRoutes[dungeonKey]`.

### Pitfall 2: Missing selectedDungeon State in PackFrame
**What goes wrong:** PackFrame needs to know which dungeon is currently selected to read the correct PackDatabase entry. If this state lives only in CombatWatcher, PackFrame must query it. If it lives in PackFrame, it may diverge from CombatWatcher's `selectedDungeon`.
**Why it happens:** Two sources of truth.
**How to avoid:** Use `ns.db.selectedDungeon` as the single source of truth for UI selection. CombatWatcher:GetState() already exposes `selectedDungeon` — PackFrame can read it from there for display. Write to `ns.db.selectedDungeon` when user changes the dropdown.

### Pitfall 3: Instance Name Mismatch for Zone Auto-Switch
**What goes wrong:** ZONE_DUNGEON_MAP key doesn't match what GetInstanceInfo() returns — auto-switch silently does nothing.
**Why it happens:** GetInstanceInfo() returns the localized instance name which may include punctuation (apostrophes, colons) not obvious from MDT data.
**How to avoid:** Add a debug print of GetInstanceInfo() in the Reset() path when `ns.db.debug` is true. After implementation, test-enter each dungeon and verify the map key matches.
**Warning signs:** Zone-in chat notification never fires; `selectedDungeon` stays nil after zone change.

### Pitfall 4: Dropdown Anchor Frame Level
**What goes wrong:** Dropdown popup appears behind other frames.
**Why it happens:** Default DIALOG strata may still be behind certain system frames.
**How to avoid:** Set `dungeonDropdown:SetFrameStrata("DIALOG")` and verify it appears above PackFrame (which uses default strata). ConfigFrame.lua's soundPopup uses "DIALOG" strata — confirmed pattern.

### Pitfall 5: Clear Affecting Wrong Dungeon
**What goes wrong:** User has dungeon A selected, imports dungeon B, clear button clears dungeon B's route (currently selected after import auto-switch).
**Why it happens:** After import auto-switches to the imported dungeon, the "currently selected dungeon" is now the one just imported.
**Expected behavior per decisions:** Clear clears the currently selected dungeon. This is correct — user sees which dungeon is selected, clear acts on it. The dialog text "Clear route for [Dungeon]?" makes this explicit.

## Code Examples

Verified patterns from existing codebase:

### GetInstanceInfo() Usage in CombatWatcher:Reset()

```lua
-- Source: Engine/CombatWatcher.lua lines 143-163
function CombatWatcher:Reset()
    ns.NameplateScanner:Stop()
    ns.Scheduler:Stop()

    -- New pattern: detect zone, auto-switch to matching dungeon
    local instanceName = select(1, GetInstanceInfo())
    local dungeonKey   = ZONE_DUNGEON_MAP[instanceName]

    if dungeonKey and ns.PackDatabase[dungeonKey] and #ns.PackDatabase[dungeonKey] > 0 then
        selectedDungeon  = dungeonKey
        currentPackIndex = 1
        state            = "ready"
        ns.db.selectedDungeon = dungeonKey
    elseif dungeonKey then
        -- Zone matched but no route imported
        selectedDungeon  = nil
        currentPackIndex = nil
        state            = "idle"
        ns.db.selectedDungeon = dungeonKey  -- still set so dropdown shows correct dungeon
        print("|cff00ccffTPW|r No route for " .. instanceName .. ". Import one with /tpw")
    else
        selectedDungeon  = nil
        currentPackIndex = nil
        state            = "idle"
    end

    if ns.PackUI and ns.PackUI.Refresh then ns.PackUI:Refresh() end
end
```

### Sound Popup Pattern (Reference for Dungeon Dropdown)

```lua
-- Source: UI/ConfigFrame.lua lines 107-124
local function BuildSoundPopup()
    soundPopup = CreateFrame("Frame", "TPWSoundPopup", UIParent, "BasicFrameTemplateWithInset")
    soundPopup:SetSize(200, 300)
    soundPopup:Hide()
    soundPopup:SetFrameStrata("DIALOG")
    soundPopup.TitleText:SetText("Select Sound")
    tinsert(UISpecialFrames, "TPWSoundPopup")

    local spScroll = CreateFrame("ScrollFrame", nil, soundPopup, "UIPanelScrollFrameTemplate")
    spScroll:SetPoint("TOPLEFT", soundPopup, "TOPLEFT", 12, -28)
    spScroll:SetPoint("BOTTOMRIGHT", soundPopup, "BOTTOMRIGHT", -34, 8)
    local spChild = CreateFrame("Frame", nil, spScroll)
    spChild:SetWidth(150)
    spScroll:SetScrollChild(spChild)

    soundPopup.scrollChild = spChild
    soundPopup.buttons = {}
end
```

### Footer Button Chain Pattern (for Combat Mode Buttons)

```lua
-- Source: UI/PackFrame.lua lines 205-223
local importBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
importBtn:SetSize(80, 22)
importBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 8)
importBtn:SetText("Import")

local clearBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
clearBtn:SetSize(80, 22)
clearBtn:SetPoint("RIGHT", importBtn, "LEFT", -8, 0)
clearBtn:SetText("Clear")

local configBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
configBtn:SetSize(80, 22)
configBtn:SetPoint("RIGHT", clearBtn, "LEFT", -8, 0)
configBtn:SetText("Config")
```

### StaticPopup Text Parameterization

```lua
-- Source: UI/PackFrame.lua lines 80-91
-- Pattern: update the dialog text before showing to include dungeon name
StaticPopupDialogs["TPW_CONFIRM_CLEAR"].text = "Clear route for " .. dungeonName .. "? This cannot be undone."
StaticPopup_Show("TPW_CONFIRM_CLEAR")
-- Note: text must be set before Show(), not as a ShowDialog parameter
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `PackDatabase["imported"]` single key | `PackDatabase[dungeonKey]` per-dungeon | Phase 15 | Multiple routes coexist |
| `ns.db.importedRoute` single object | `ns.db.importedRoutes[dungeonKey]` table | Phase 15 | Independent persistence per dungeon |
| ZONE_DUNGEON_MAP single entry | Full 8-dungeon map | Phase 15 | Auto-switch works in all S1 dungeons |
| No combat mode control | Auto/Manual/Disable selector | Phase 15 | Player controls addon behavior |

**Deprecated/outdated after this phase:**
- `ns.db.importedRoute`: deleted after migration (old field)
- `PackDatabase["imported"]`: retired, never written again
- `activeDungeon == "imported"` comparisons in PackFrame.lua: replaced with dynamic dungeon key comparison

## Open Questions

1. **Exact instance names for GetInstanceInfo()**
   - What we know: DUNGEON_IDX_MAP names match MDT data ("Magisters Terrace", "Nexus Point Xenas")
   - What's unclear: GetInstanceInfo() may return different strings ("Magisters' Terrace", "Nexus Point: Xenas")
   - Recommendation: Implement with best-guess strings, add debug print in Reset() so tester can verify each dungeon during first in-game session. The pitfall section covers this.

2. **Frame size for dungeon dropdown with 8 entries**
   - What we know: Sound popup is 200x300 with UIPanelScrollFrameTemplate for potentially 67 entries
   - What's unclear: Whether 8 fixed entries need a scroll frame or can be a fixed-height frame
   - Recommendation: Skip the scroll frame for 8 entries. Use a fixed 200x(8 * 22 + 32) = 200x208 frame with 8 buttons laid out directly. Simpler and easier to reason about.

3. **PackFrame height accommodation for combat mode buttons**
   - What we know: Frame is currently 300x400 with three footer buttons and a scroll area
   - What's unclear: Whether adding a second row of buttons (combat mode) requires increasing frame height
   - Recommendation: Add a second footer row 30px above the existing row, anchored to BOTTOMRIGHT. Increase frame height to 430 or adjust scroll area bottom anchor.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual in-game testing (no automated test infrastructure — WoW addon) |
| Config file | none |
| Quick run command | `./scripts/install.bat` then `/reload` in WoW |
| Full suite command | Manual: import routes for 2+ dungeons, /reload, zone-in, verify |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ROUTE-01 | Import dungeon A, import dungeon B, both routes persist independently after /reload | manual | `./scripts/install.bat` | N/A — in-game |
| ROUTE-02 | Dungeon selector dropdown appears, selecting a dungeon switches the pack list | manual | `./scripts/install.bat` | N/A — in-game |
| ROUTE-03 | Zone into a Midnight S1 dungeon, pack list auto-switches to that dungeon | manual | `./scripts/install.bat` | N/A — in-game |

### Sampling Rate
- **Per task commit:** `./scripts/install.bat` + `/reload` + smoke test in WoW
- **Per wave merge:** Full manual test: import two dungeons, reload, zone-in test
- **Phase gate:** All three ROUTE requirements verified before `/gsd:verify-work`

### Wave 0 Gaps
None — no test infrastructure to create. All validation is in-game manual testing.

## Sources

### Primary (HIGH confidence)
- Direct codebase read of all 4 refactor-target files (Pipeline.lua, CombatWatcher.lua, PackFrame.lua, Core.lua)
- TOC file confirms file load order — all files load before ADDON_LOADED fires
- Grep of all "imported" occurrences — complete inventory of 15 call sites across 4 files

### Secondary (MEDIUM confidence)
- GetInstanceInfo() behavior — documented WoW API, return values for M+ dungeons are instance name strings; specific strings for Midnight S1 dungeons unverified (require in-game confirmation)
- Instance names in ZONE_DUNGEON_MAP derived from DUNGEON_IDX_MAP names in Pipeline.lua (may have punctuation differences)

### Tertiary (LOW confidence)
- Exact instance name strings (e.g., apostrophes in "Magisters' Terrace") — require in-game verification

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — pure WoW API, no external libraries, all patterns verified in existing codebase
- Architecture: HIGH — refactor targets completely inventoried via grep, patterns directly from existing code
- Pitfalls: HIGH — all identified from direct code reading + STATE.md documented pitfalls
- Instance name strings: LOW — need in-game verification

**Research date:** 2026-03-20
**Valid until:** Stable — WoW addon APIs do not change between patch cycles at this level
