# Phase 18: Profiles and Skill Config Rework - Research

**Researched:** 2026-03-21
**Domain:** WoW addon SavedVariables schema, Lua UI (EditBox numeric input, dropdown popups), LibDeflate/AceSerializer encode, profile data architecture
**Confidence:** HIGH — all findings sourced from direct code inspection of project files and bundled libraries

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Skill Defaults and Data File Changes**
- All skills default to: unchecked, untimed, empty timer fields, no label — completely blank
- Erase timing data (first_cast, cooldown) and labels from all Data/*.lua files — profiles set these now
- mobClass stays in Data files — NOT user-editable, fixed per mob
- TTS defaults to spell name (resolved dynamically via C_Spell.GetSpellInfo) — user can override in profile
- `defaultEnabled = false` remains on all MDT-imported abilities (unchecked by default)
- Existing WindrunnerSpire hand-authored timing/labels/ttsMessage removed from Data file

**Per-Skill Timer UI**
- Timed/untimed toggle checkbox per skill
- When timed is checked: two number input fields appear — "First Cast" and "Cooldown" (in seconds)
- When untimed: fields visible but grayed out (indicates they exist but do nothing)
- Fields have NO default values (empty when untimed or newly enabled)
- Validation: positive numbers only, max 1200 seconds (20 minutes), numeric characters only
- On blur/close: if value exceeds 1200, clamp to 1200

**Per-Skill Sound Alert Checkbox (PROF-07)**
- Separate checkbox from skill enable/disable — two independent checkboxes
- Skill tracking checkbox: controls whether icon shows on display
- Sound alert checkbox: controls whether sound/TTS fires on trigger
- Can track a skill visually without sound, or have sound without tracking (edge case but allowed)
- Untimed skills: sound fires on class cast detection state transition (no-glow -> glow)
- Timed skills: sound fires at 5s pre-warning (SetUrgent)

**Profile System Behavior**
- Profiles store: per-skill enable/disable, timed toggle, first_cast, cooldown, label, sound/TTS selection, sound alert checkbox
- Profiles do NOT store: routes, combat mode, window positions, debug state
- Switching profiles rebuilds pack abilities from new profile's skill config (automatic, packs re-merge)
- Default profile is always blank (all skills unchecked/untimed)
- Fixed naming: "Default", "Profile 1", "Profile 2", etc. — no renaming
- Profiles are account-wide (stored in SavedVariables)
- Delete button disabled for Default profile
- Maximum profile count: Claude's discretion (suggest 10-20)

**Profile Import/Export**
- Reuse LibDeflate + AceSerializer (already bundled) — same encode/decode chain as MDT import
- Serialize profile skill config table, compress, base64 — produces compact shareable string
- Import always creates a NEW profile (never overwrites existing) and auto-selects it as active
- Export serializes the currently active profile
- Import/Export use the same paste popup pattern as MDT route import

**Profile UI in Config Window**
- Widen config window (from 580px to ~700px or more) to fit profile controls
- Single top bar row: [Route] [Reset All] [Default v] [New] [Del] [Imp] [Exp]  ...  [Search]
- Profile dropdown shows current profile name with v indicator
- [New] creates next sequential profile ("Profile 1", "Profile 2", etc.) — blank, auto-selected
- [Del] deletes current profile, switches to Default — disabled when Default is selected
- [Imp] opens paste popup (same pattern as MDT import) — creates new profile from string
- [Exp] copies current profile string to an editbox popup for copying
- Search box stays right-aligned

### Claude's Discretion
- Exact window width increase
- How timer input fields are styled (pushed-in background like label/TTS fields)
- SavedVariables schema for profiles (suggest `ns.db.profiles = { ["Default"] = {}, ["Profile 1"] = {...} }`)
- How pack rebuild is triggered on profile switch
- Profile dropdown popup implementation (reuse sound popup pattern)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PROF-01 | All skills default to unchecked, untimed, empty timer fields — no pre-enabled skills | Data file erasure + schema default; MergeSkillConfig reads from active profile only |
| PROF-02 | Per-skill timed/untimed toggle with first_cast and cooldown number inputs (grayed out when untimed) | EditBox numeric input pattern; grayed state via Enable/Disable + SetAlpha |
| PROF-03 | Profile system — account-wide profiles stored in SavedVariables, default profile is blank | Schema v1 -> v2 migration pattern in Core.lua; ns.db.profiles nested table |
| PROF-04 | Profile selector dropdown in config window with "New Profile" option | Sound popup pattern is reusable; profile dropdown is same scroll-list mechanism |
| PROF-05 | Delete profile button (disabled for default profile) | btn:Disable() / btn:SetAlpha() already used for TTS/sound disable pattern |
| PROF-06 | Import/export profile buttons (serialized string for sharing) | LibDeflate:CompressDeflate + :EncodeForPrint (reverse of decode chain); import popup frame pattern in PackFrame.lua |
| PROF-07 | Per-skill sound alert checkbox — untimed plays on class cast detection, timed plays at 5s pre-warning | Sound alert checkbox must gate PlaySound/TTS calls in IconDisplay and NameplateScanner |
</phase_requirements>

---

## Summary

Phase 18 reworks the skill configuration system end-to-end: stripping timing data from Data files, adding a profile layer above `ns.db.skillConfig`, adding per-skill timer UI controls, and wiring a profile import/export chain using the already-bundled LibDeflate + AceSerializer libraries in reverse.

The existing codebase already has almost every pattern needed. The sound popup (`BuildSoundPopup`) is a direct template for the profile dropdown. The import popup frame in PackFrame.lua is a direct template for profile import/export. The `AddEditBoxBackground` function provides timer field styling. Schema migration in Core.lua already handles v0->v1; a v1->v2 migration follows the same pattern. The only genuinely new technical ground is numeric EditBox validation (no built-in `SetNumeric` in WoW's Lua API — must be done via `OnTextChanged`) and wiring the sound alert checkbox gate through `IconDisplay` and `NameplateScanner`.

**Primary recommendation:** Structure work as five distinct sub-tasks: (1) data file cleanup, (2) schema + Core.lua migration, (3) MergeSkillConfig profile pivot, (4) Config UI changes, (5) profile import/export.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AceSerializer-3.0 | bundled | Lua table -> string serialization | Already bundled; MDT decode uses it |
| LibDeflate | bundled | Deflate compress/decompress + base64 | Already bundled; MDT decode uses it |
| LibStub | bundled | Library registry for the above | Required by both libs |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| C_Timer.NewTimer | WoW API | Debounce for search; deferred ops | Already used in ConfigFrame for search debounce |
| UICheckButtonTemplate | WoW template | Checkboxes | Already used in ConfigFrame for skill enable checkbox |
| GameMenuButtonTemplate | WoW template | Buttons | Used throughout for all buttons |
| UIPanelScrollFrameTemplate | WoW template | Scrollable lists | Used in sound popup and import popup |

No new libraries are needed. All required tools are already in the project.

---

## Architecture Patterns

### Profile Data Schema (v2)

```lua
-- ns.db after schema migration to v2:
ns.db.schemaVersion = 2
ns.db.profiles = {
    ["Default"] = {},  -- always blank; never deleted
    ["Profile 1"] = {
        skillConfig = {
            -- [npcID][spellID] = { enabled, timed, first_cast, cooldown, label, ttsMessage, soundKitID, soundEnabled }
            [232113] = {
                [1253686] = {
                    enabled     = true,   -- nil means "not set" (same as false for PROF-01)
                    timed       = true,
                    first_cast  = 50,
                    cooldown    = 50,
                    label       = "DR",
                    ttsMessage  = "Shield",
                    soundKitID  = nil,    -- nil = TTS mode
                    soundEnabled = true,
                },
            },
        },
    },
}
ns.db.activeProfile = "Default"
```

**Key design:** `ns.db.skillConfig` becomes a redirect alias to `ns.db.profiles[ns.db.activeProfile].skillConfig`. This is the minimal-impact path — `MergeSkillConfig` only needs one change: its `ns.db.skillConfig` reference becomes `ns.db.profiles[ns.db.activeProfile].skillConfig`.

### Schema Migration (v1 -> v2)

Core.lua ADDON_LOADED currently handles v0->v1. Extend the pattern:

```lua
-- In ADDON_LOADED, after existing v0->v1 migration:
if ns.db.schemaVersion == 1 then
    -- Migrate flat skillConfig into Default profile
    ns.db.profiles = { ["Default"] = {} }
    -- Old skillConfig is per-user custom data — migrate into Default profile
    if ns.db.skillConfig and next(ns.db.skillConfig) then
        ns.db.profiles["Default"].skillConfig = ns.db.skillConfig
    else
        ns.db.profiles["Default"].skillConfig = {}
    end
    ns.db.skillConfig = nil   -- retire flat field
    ns.db.activeProfile = "Default"
    ns.db.schemaVersion = 2
end
-- Initialize new fields if absent
ns.db.profiles = ns.db.profiles or { ["Default"] = { skillConfig = {} } }
ns.db.activeProfile = ns.db.activeProfile or "Default"
```

**IMPORTANT:** The old `ns.db.skillConfig` must NOT be initialized with `or {}` after migration, since we've retired it. Replace the existing `ns.db.skillConfig = ns.db.skillConfig or {}` line entirely.

### MergeSkillConfig Profile Pivot

Current (Pipeline.lua line 28-30):
```lua
local cfg = ns.db.skillConfig
    and ns.db.skillConfig[npcID]
    and ns.db.skillConfig[npcID][ability.spellID]
```

After pivot (single reference change):
```lua
local profileCfg = ns.db.profiles
    and ns.db.profiles[ns.db.activeProfile]
    and ns.db.profiles[ns.db.activeProfile].skillConfig
local cfg = profileCfg
    and profileCfg[npcID]
    and profileCfg[npcID][ability.spellID]
```

Also: `MergeSkillConfig` must now read `cfg.timed`, `cfg.first_cast`, and `cfg.cooldown` from profile (not from `ability.*`), since Data files will no longer carry timing. The merged ability's `first_cast`/`cooldown` should come from cfg only:

```lua
return {
    name        = ability.name,
    spellID     = ability.spellID,
    mobClass    = mobClass,
    first_cast  = cfg and cfg.timed and cfg.first_cast or nil,
    cooldown    = cfg and cfg.timed and cfg.cooldown   or nil,
    label       = cfg and cfg.label      ~= nil and cfg.label      or nil,
    ttsMessage  = cfg and cfg.ttsMessage ~= nil and cfg.ttsMessage or nil,
    soundKitID  = cfg and cfg.soundKitID or nil,
    soundEnabled = cfg and cfg.soundEnabled,
}
```

When `first_cast` and `cooldown` are nil, `Scheduler:Start` already handles this (untimed path: `if ability.cooldown then ... else ShowStaticIcon`).

### Profile Rebuild on Switch

When user switches active profile:
1. Set `ns.db.activeProfile = newProfileName`
2. Call `Import.RestoreAllFromSaved()` — this already re-runs `BuildPack` for all saved routes, which calls `MergeSkillConfig` fresh against the current active profile
3. No other changes needed — the data flow already rebuilds everything

### Numeric EditBox Pattern (WoW Lua 5.1)

WoW does not expose a `SetNumeric(true)` API in Midnight. Numeric-only input requires `OnTextChanged` filtering:

```lua
local function MakeNumericEditBox(parent, width, height)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(width, height)
    eb:SetFontObject(ChatFontNormal)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(5)  -- max "1200" = 4 chars, plus possible partial input
    eb:SetTextInsets(4, 4, 2, 2)
    AddEditBoxBackground(eb)  -- reuse existing function
    eb:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local text = self:GetText()
        -- Strip non-digits
        local clean = text:gsub("[^0-9]", "")
        if clean ~= text then
            self:SetText(clean)
            self:SetCursorPosition(#clean)
        end
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        local val = tonumber(self:GetText())
        if val then
            if val > 1200 then
                self:SetText("1200")
            elseif val <= 0 then
                self:SetText("")
            end
        else
            self:SetText("")
        end
    end)
    return eb
end
```

**Caveats:**
- `OnEditFocusLost` fires reliably when the editbox loses focus (tab, click away, escape)
- `OnEnterPressed` should also trigger the clamp+save, then call `self:ClearFocus()`
- Do NOT use `:SetNumericFieldValue()` — that is a Retail-only API not confirmed in Midnight

### Profile Dropdown Pattern

The existing `BuildSoundPopup` / `ShowSoundPopup` pattern is a scroll-list popup anchored to a button. The profile dropdown follows the same pattern:

```lua
local profileDropdown = nil  -- singleton, built on first use

local function BuildProfileDropdown()
    profileDropdown = CreateFrame("Frame", "TPWProfileDropdown", UIParent, "BasicFrameTemplateWithInset")
    profileDropdown:SetSize(160, 220)
    profileDropdown:Hide()
    profileDropdown:SetFrameStrata("DIALOG")
    profileDropdown.TitleText:SetText("Profiles")
    tinsert(UISpecialFrames, "TPWProfileDropdown")
    -- scroll + buttons built dynamically in ShowProfileDropdown
end

local function ShowProfileDropdown(anchorBtn, onSelect)
    if not profileDropdown then BuildProfileDropdown() end
    -- Rebuild button list from ns.db.profiles keys
    -- Each button calls onSelect(profileName) and hides dropdown
    profileDropdown:ClearAllPoints()
    profileDropdown:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, 0)
    profileDropdown:Show()
end
```

### Import/Export Chain (Encode = Reverse Decode)

Decode chain (Decode.lua): `strip "!"` -> `DecodeForPrint` -> `DecompressDeflate` -> `Deserialize`

Encode chain (new Profile.lua or inline):
```lua
local function EncodeProfile(skillConfigTable)
    local serialized = AceSerializer:Serialize(skillConfigTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded    = LibDeflate:EncodeForPrint(compressed)
    return "!" .. encoded
end

local function DecodeProfile(str)
    local encoded = str:gsub("^%!", "")
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return nil, "DecodeForPrint failed" end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "DecompressDeflate failed" end
    local ok, data = AceSerializer:Deserialize(decompressed)
    if not ok then return nil, "Deserialize failed: " .. tostring(data) end
    return data, nil
end
```

The library functions are confirmed present in the bundled libs:
- `AceSerializer:Serialize(...)` — line 122 of AceSerializer-3.0.lua
- `LibDeflate:CompressDeflate(str, configs)` — line 2010 of LibDeflate.lua
- `LibDeflate:EncodeForPrint(str)` — line 3217 of LibDeflate.lua

### ConfigFrame Top Bar Layout (widened to ~720px)

Current width: 580px. New width: ~720px to accommodate profile controls between Reset All and Search.

Current top bar (580px): `[Route 80px] [Reset All 80px] .................. [Search 200px]`
New top bar (720px):      `[Route 70px] [Reset All 70px] [ProfileBtn 100px] [New 50px] [Del 50px] [Imp 50px] [Exp 50px] .... [Search 160px]`

Spacing between buttons: 8px. Total control width: 70+8+70+8+100+8+50+8+50+8+50+8+50 = 488px. With 12px left margin + 12px right margin + 160px search = 672px. Use 720px as final width.

All existing anchors are relative to `configFrame` TOPLEFT / TOPRIGHT, so widening only affects:
- `configFrame:SetSize(720, 480)` — the frame itself
- `rightScrollFrame` TOPRIGHT anchor stays at configFrame BOTTOMRIGHT
- Vertical divider at x=225 may need adjustment if left panel stays 225px wide

### Import Popup Reuse (Profile Import/Export)

PackFrame.lua already has the complete pattern (lines 113-165):
- Separate `CreateFrame` (not StaticPopup — avoids 255 char limit)
- `SetFrameStrata("DIALOG")`
- `tinsert(UISpecialFrames, name)` for Escape to close
- ScrollFrame + multi-line EditBox inside
- Import button + Cancel button at bottom

Profile import popup: identical structure, but Import button calls `DecodeProfile`, creates new sequential profile name, stores skillConfig, switches to it, rebuilds packs.

Profile export popup: same frame structure, but opens read-only with the encoded string pre-filled, user copies manually. (No "Export" button needed — the text is the export.)

### Data File Changes (WindrunnerSpire.lua)

Three mobs have hand-authored timing/label/ttsMessage that must be erased:
- npcID 232113 (Spellguard Magus): remove `name`, `first_cast=50`, `cooldown=50`, `label="DR"`, `ttsMessage="Shield"` — keep `spellID=1253686` only, add `defaultEnabled=false`
- npcID 232121 (Phalanx Breaker variant): remove `name`, `first_cast=20`, `cooldown=25`, `label="Kick"`, `ttsMessage="Stop Casting"` — keep `spellID=471643`, add `defaultEnabled=false`
- npcID 232122 (Phalanx Breaker): same removal for spellID 471643

Mobs with only `name` and `label` (no timing):
- npcID 232056 (Territorial Dragonhawk): remove `name="Fire Spit"`, `label="DMG"` from spellID 1216848
- npcID 232070 (Restless Steward): remove `name="Spirit Bolt"`, `label="Bolt"` from spellID 1216135
- npcID 236891 (variant): remove `name="Fire Spit"` from spellID 1216848

After cleanup, every ability entry in WindrunnerSpire.lua has only `spellID` and `defaultEnabled=false`. The `name` field removal is correct because `GetSpellNameSafe` already falls back to `C_Spell.GetSpellInfo`.

Other Data/*.lua files: already have only `spellID` + `defaultEnabled=false` — no changes needed.

### Sound Alert Checkbox Integration

The `cfg.soundEnabled` field (PROF-07) gates whether sound/TTS fires. Integration points:

**Timed skills — Scheduler.lua:**
The merged ability carries `soundEnabled`. In `scheduleAbility`, when the preWarn fires `SetUrgent(barId)`, `SetUrgent` already fires the alert. `IconDisplay.SetUrgent` must check the ability's `soundEnabled` before calling `PlaySound`/`SpeakText`. The ability table must carry `soundEnabled` through the merge into scheduleAbility.

**Untimed skills — NameplateScanner.lua:**
`OnCastStart` calls `IconDisplay.SetCastHighlight(key, ability)`. `SetCastHighlight` already receives the ability table, so it checks `ability.soundEnabled` before firing alert.

**IconDisplay.lua changes:**
- `SetUrgent(barId)`: needs access to the ability's `soundEnabled` flag. Either pass it as a parameter or store it in the icon slot at `ShowIcon` time.
- `SetCastHighlight(key, ability)`: already receives ability, add `if ability.soundEnabled ~= false then` guard before PlaySound/TTS.

Current `ShowIcon` signature: `ShowIcon(barId, spellID, ttsMessage, first_cast, label, soundKitID)`. Add `soundEnabled` as seventh parameter, or embed in a config table. Adding as seventh parameter is simplest given existing call sites.

### PopulateRightPanel Changes

The right panel currently reads from `ns.db.skillConfig[npcID][spellID]`. After the pivot it reads from the active profile's skillConfig. All write paths in ConfigFrame.lua must redirect similarly:

Current pattern (found throughout ConfigFrame.lua):
```lua
ns.db.skillConfig[npcID_cb] = ns.db.skillConfig[npcID_cb] or {}
ns.db.skillConfig[npcID_cb][spellID_cb] = ns.db.skillConfig[npcID_cb][spellID_cb] or {}
ns.db.skillConfig[npcID_cb][spellID_cb].enabled = false
```

After pivot, introduce a helper:
```lua
local function GetSkillConfig()
    local p = ns.db.profiles[ns.db.activeProfile]
    p.skillConfig = p.skillConfig or {}
    return p.skillConfig
end
```

Then replace all `ns.db.skillConfig` references with `GetSkillConfig()`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lua table serialization | Custom recursive serializer | `AceSerializer:Serialize` | Handles cycles, escaping, type tagging correctly |
| Binary compression + printable encoding | Custom base64 or zlib wrapper | `LibDeflate:CompressDeflate` + `LibDeflate:EncodeForPrint` | Battle-tested; identical chain MDT uses |
| Popup frame for copy-paste | StaticPopup | Dedicated `CreateFrame` (as in PackFrame.lua) | StaticPopup has a 255-char text limit; export strings will be longer |
| Schema versioning | Ad-hoc field presence checks | `ns.db.schemaVersion` integer (existing pattern) | One canonical check, migrate once |

---

## Common Pitfalls

### Pitfall 1: ns.db.skillConfig References Scattered Across Files
**What goes wrong:** After the profile pivot, any code that still writes to `ns.db.skillConfig` directly will create a new top-level key in SavedVariables instead of writing to the active profile.
**Why it happens:** `ns.db.skillConfig` is written in at least 8 places in ConfigFrame.lua (checkBtn OnClick, labelEditBox, ttsEditBox, soundBtn, resetBtn, Reset All StaticPopup, ShowSoundPopup).
**How to avoid:** Introduce `GetSkillCfg(npcID, spellID)` and `SetSkillCfg(npcID, spellID, key, value)` helpers or a `GetSkillConfig()` table accessor, and replace all direct references.
**Warning signs:** Config changes not persisting after reload, or changes to one profile affecting another.

### Pitfall 2: RestoreAllFromSaved Called Before Profiles Initialized
**What goes wrong:** Core.lua calls `Import.RestoreAllFromSaved()` during ADDON_LOADED. MergeSkillConfig will reference `ns.db.profiles[ns.db.activeProfile]`. If the profiles table isn't initialized before RestoreAllFromSaved runs, it will nil-error.
**How to avoid:** Schema migration and `ns.db.profiles` initialization must happen BEFORE the RestoreAllFromSaved call in ADDON_LOADED. Current order already handles this pattern (migration runs first); keep it that way.

### Pitfall 3: Numeric EditBox — SetNumeric Does Not Exist
**What goes wrong:** Some WoW API documentation references `EditBox:SetNumeric(true)` — this API is not available in Midnight (and was removed from many contexts). Using it silently does nothing and allows text characters through.
**How to avoid:** Always use the `OnTextChanged` gsub pattern with `[^0-9]` stripping. Test in-game — `SetNumeric` absence will cause no error but the filter won't work.

### Pitfall 4: AceSerializer:Serialize Reuses Internal Buffer
**What goes wrong:** `AceSerializer:Serialize` uses a module-level `serializeTbl` that is reset at the start of each call. If Serialize is called in a coroutine or reentrantly (unlikely in WoW, but possible if called from an OnUpdate), the table may be in a dirty state.
**How to avoid:** Only call Serialize from single-threaded contexts (button click, not ticker). In WoW addons this is always the case, but worth knowing.

### Pitfall 5: Profile Dropdown Z-Order / ESC Handling
**What goes wrong:** A custom popup frame not added to UISpecialFrames won't close on Escape key. It may also render below other DIALOG-strata frames.
**How to avoid:** Call `tinsert(UISpecialFrames, "TPWProfileDropdown")` and set `SetFrameStrata("DIALOG")` — same as sound popup and import popup already do.

### Pitfall 6: Export String Displayed in StaticPopup
**What goes wrong:** If the export popup uses StaticPopup, strings longer than ~255 characters will be silently truncated. Profile exports will almost certainly exceed this limit once any skills are configured.
**How to avoid:** Use a dedicated `CreateFrame` + EditBox (same pattern as PackFrame.lua import popup), pre-fill with the export string and call `SetFocus()` so the user can Ctrl+A, Ctrl+C.

### Pitfall 7: Timed checkbox visibility with grayed fields
**What goes wrong:** The CONTEXT.md specifies that when untimed, the timer fields are "visible but grayed out." If grayed means `Disable()` + `SetAlpha(0.4)`, the EditBox text can still be read (correctly) but if grayed means `Hide()`, the user loses context of what the fields do.
**How to avoid:** Use `Enable()`/`Disable()` + `SetAlpha(1.0/0.4)` pattern (already used for TTS/sound disable in ConfigFrame.lua) — keeps fields visible.

### Pitfall 8: Profile name collision on New
**What goes wrong:** Generating "Profile 1", "Profile 2" etc. must check for existing keys. If a user deletes "Profile 1" and creates a new one, should it be "Profile 1" again or "Profile 3"?
**How to avoid:** Find the maximum existing numeric suffix and increment: iterate `ns.db.profiles` keys, extract trailing numbers, use `max + 1`. This avoids collisions regardless of deletion history.

---

## Code Examples

### Encode Profile for Export
```lua
-- Source: LibDeflate.lua (EncodeForPrint line 3217), AceSerializer-3.0.lua (Serialize line 122)
local LibDeflate   = LibStub:GetLibrary("LibDeflate")
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

local function EncodeProfile(skillConfigTable)
    local serialized = AceSerializer:Serialize(skillConfigTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded    = LibDeflate:EncodeForPrint(compressed)
    return "!" .. encoded
end
```

### Decode Profile for Import
```lua
-- Mirrors ns.MDTDecode in Import/Decode.lua exactly
local function DecodeProfile(str)
    local encoded = str:gsub("^%!", "")
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return nil, "DecodeForPrint failed" end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "DecompressDeflate failed" end
    local ok, data = AceSerializer:Deserialize(decompressed)
    if not ok then return nil, "Deserialize failed" end
    return data, nil
end
```

### Numeric EditBox (validated, clamped)
```lua
-- Pattern: OnTextChanged strips non-digits; OnEditFocusLost clamps 1-1200
local eb = CreateFrame("EditBox", nil, parent)
eb:SetSize(60, 20)
eb:SetFontObject(ChatFontNormal)
eb:SetAutoFocus(false)
eb:SetMaxLetters(5)
eb:SetTextInsets(4, 4, 2, 2)
AddEditBoxBackground(eb)  -- existing ConfigFrame helper
eb:SetScript("OnTextChanged", function(self, userInput)
    if not userInput then return end
    local text = self:GetText()
    local clean = text:gsub("[^0-9]", "")
    if clean ~= text then
        self:SetText(clean)
        self:SetCursorPosition(#clean)
    end
end)
local function ClampAndSave(self, npcID, spellID, field)
    local val = tonumber(self:GetText())
    if val then
        if val > 1200 then val = 1200 end
        if val <= 0   then val = nil  end
    end
    self:SetText(val and tostring(val) or "")
    -- Write to active profile skillConfig
    local sc = GetSkillConfig()
    sc[npcID] = sc[npcID] or {}
    sc[npcID][spellID] = sc[npcID][spellID] or {}
    sc[npcID][spellID][field] = val
end
eb:SetScript("OnEditFocusLost", function(self) ClampAndSave(self, npcID_cb, spellID_cb, "first_cast") end)
eb:SetScript("OnEnterPressed",  function(self) ClampAndSave(self, npcID_cb, spellID_cb, "first_cast"); self:ClearFocus() end)
```

### Profile Switch + Pack Rebuild
```lua
local function SwitchProfile(profileName)
    ns.db.activeProfile = profileName
    -- Rebuild all packs from saved routes using new profile's skillConfig
    ns.Import.RestoreAllFromSaved()
    -- Refresh config right panel if open
    if selectedNpcID then PopulateRightPanel(selectedNpcID) end
end
```

### New Profile Name Generation
```lua
local function NextProfileName()
    local maxN = 0
    for name in pairs(ns.db.profiles) do
        local n = tonumber(name:match("^Profile (%d+)$"))
        if n and n > maxN then maxN = n end
    end
    return "Profile " .. (maxN + 1)
end
```

### GetSkillConfig Helper (profile-aware accessor)
```lua
local function GetSkillConfig()
    local profile = ns.db.profiles[ns.db.activeProfile]
    if not profile then
        -- Fallback: switch to Default if active profile was deleted
        ns.db.activeProfile = "Default"
        profile = ns.db.profiles["Default"]
    end
    profile.skillConfig = profile.skillConfig or {}
    return profile.skillConfig
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Flat `ns.db.skillConfig` | `ns.db.profiles[active].skillConfig` | Phase 18 | All reads/writes must go through profile layer |
| Timing data in Data files | Timing data in profile skillConfig | Phase 18 | Data files become pure spellID+mobClass registries |
| Single global skill config | Per-profile skill config (up to ~15 profiles) | Phase 18 | Profile switch triggers full pack rebuild |

---

## Open Questions

1. **Maximum profile count**
   - What we know: CONTEXT.md says "Claude's discretion, suggest 10-20"
   - What's unclear: Whether to enforce a hard cap in the UI or just in documentation
   - Recommendation: Enforce 15 as a soft cap (disable [New] when 15 profiles exist); display count in button tooltip

2. **Export popup — editable or read-only?**
   - What we know: User must be able to Ctrl+A, Ctrl+C the export string
   - What's unclear: Whether a read-only MultiLine EditBox supports SelectAll/copy in WoW
   - Recommendation: Use a regular (editable) EditBox, pre-fill with export string; user can edit and re-import if desired. Call `eb:HighlightText()` after `SetText` and `SetFocus()` to pre-select all for easy copy.

3. **Reset All behavior after profile addition**
   - What we know: "Reset All" currently wipes `ns.db.skillConfig[npcID]` for all npcIDs
   - What's unclear: Should Reset All wipe the ACTIVE PROFILE's skillConfig, or wipe ALL profiles?
   - Recommendation: Wipe only the active profile's skillConfig (user is working within a profile context). Update StaticPopup text to say "reset current profile's skill config."

---

## Validation Architecture

`nyquist_validation` is enabled in config.json.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — WoW addon; all testing is in-game manual |
| Config file | N/A |
| Quick run command | `./scripts/install.bat` then `/reload` in WoW |
| Full suite command | In-game: `/tpw`, configure skills, `/reload`, verify persistence |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROF-01 | All skills unchecked/untimed after data file cleanup | manual | install + in-game check | N/A — in-game |
| PROF-02 | Timed toggle shows/grays timer fields; values clamp to 1200 | manual | install + in-game check | N/A |
| PROF-03 | Profiles persist across /reload; Default always blank | manual | install + in-game check | N/A |
| PROF-04 | Profile dropdown shows all profiles; New creates sequential name | manual | install + in-game check | N/A |
| PROF-05 | Delete disabled for Default; deleting Profile N switches to Default | manual | install + in-game check | N/A |
| PROF-06 | Export string decodes back to same skillConfig table | manual | import exported string -> compare | N/A |
| PROF-07 | Sound checkbox unchecked = no audio; checked = audio fires | manual | install + in-game check | N/A |

### Sampling Rate
- **Per task commit:** `./scripts/install.bat` + `/reload` in WoW, spot-check the changed feature
- **Per wave merge:** Full manual pass through all PROF-01 through PROF-07
- **Phase gate:** All 7 requirements manually verified before `/gsd:verify-work`

### Wave 0 Gaps
None — no automated test infrastructure exists or is needed for a WoW addon. All verification is in-game.

---

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `UI/ConfigFrame.lua` — PopulateRightPanel, BuildSoundPopup, BuildConfigFrame, top bar layout, AddEditBoxBackground
- Direct code inspection: `Import/Pipeline.lua` — MergeSkillConfig, BuildPack, RestoreAllFromSaved
- Direct code inspection: `Import/Decode.lua` — full MDT decode chain (encode chain is exact reverse)
- Direct code inspection: `Core.lua` — ADDON_LOADED handler, schema migration v0->v1 pattern, ns.db initialization
- Direct code inspection: `UI/PackFrame.lua` — importPopup frame pattern (lines 113-165)
- Direct code inspection: `Engine/Scheduler.lua` — ability table consumption, first_cast/cooldown fields
- Direct code inspection: `Engine/NameplateScanner.lua` — OnMobsAdded, OnCastStart, SetCastHighlight call sites
- Direct code inspection: `Data/WindrunnerSpire.lua` — exactly which entries have timing/label data to erase
- Direct code inspection: `Libs/AceSerializer-3.0/AceSerializer-3.0.lua` — `AceSerializer:Serialize` confirmed at line 122
- Direct code inspection: `Libs/LibDeflate/LibDeflate.lua` — `LibDeflate:CompressDeflate` at line 2010, `LibDeflate:EncodeForPrint` at line 3217

### Secondary (MEDIUM confidence)
- WoW Lua EditBox documentation: `SetNumeric` not used in Midnight; `OnTextChanged` pattern is the established workaround confirmed by prior phases in this project
- `UISpecialFrames` pattern for Escape-to-close confirmed by existing TPWSoundPopup and TPWImportPopup usage

### Tertiary (LOW confidence)
- `EditBox:HighlightText()` for pre-selecting export string — standard WoW API, high probability it works in Midnight but not directly verified in this codebase

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries confirmed present and API-verified in bundled source
- Architecture: HIGH — all patterns sourced from existing project code; profile schema follows established migration pattern
- Pitfalls: HIGH for pitfalls 1-6, MEDIUM for pitfall 7 (grayed vs hidden is a style choice, not a bug)

**Research date:** 2026-03-21
**Valid until:** 2026-04-21 (stable WoW API domain; LibDeflate/AceSerializer don't change)
