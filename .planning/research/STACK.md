# Stack Research

**Domain:** World of Warcraft Midnight (12.0) addon — dungeon pack warning timers
**Researched:** 2026-03-17 (v0.1.0 update; original 2026-03-13); 2026-03-23 (v0.1.1 update)
**Confidence:** HIGH (all v0.1.0 findings verified from local source files; original v0.0.x stack unchanged; v0.1.1 findings verified from wow-ui-source 12.0.1.66337)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Lua 5.1 (WoW dialect) | WoW embedded | All addon logic | The only scripting language the WoW client exposes. No choice here. |
| XML (FRAMES_XML) | Standard | Frame and template declarations | Right tool for static frame structure and template inheritance; avoids boilerplate `CreateFrame` calls for persistent UI elements. |
| TOC manifest | Interface 120001 | Addon metadata and load order | 12.0.0+ strictly requires a matching interface version; addons without `120001` or higher will not load. |

### Timing and Scheduling

| Technology | Purpose | Why |
|------------|---------|-----|
| `C_Timer.After(seconds, fn)` | Fire a one-shot callback after N seconds | Confirmed available and AllowedWhenUntainted in 12.0.1. Standard, heap-based, no OnUpdate overhead. |
| `C_Timer.NewTicker(seconds, fn, iterations)` | Repeating timer | Returns a cancelable handle with `:Cancel()`. Used for the 0.25s nameplate poll loop. |

### UI Widgets

| Technology | Purpose | Why |
|------------|---------|-----|
| `CreateFrame("Frame")` | Root container / event bus | Canonical Midnight approach. No Ace3 dependency, no taint risk. |
| `CreateFrame("Button", ...)` | Clickable rows (pack list, config tree headers) | Standard interactive element. |
| `CreateFrame("ScrollFrame", ...)` inherits `UIPanelScrollFrameTemplate` | Scrollable lists | Used in PackFrame.lua. Same pattern fits the config panel. |
| `CreateFrame("Frame")` + `CooldownFrameTemplate` | Spell icon with cooldown sweep | Proven in existing IconDisplay.lua. |

### Saved State

| Technology | Purpose | Pattern |
|------------|---------|---------|
| `SavedVariables: TerriblePackWarningsDB` in TOC | Account-wide persistence | Initialize from defaults on `ADDON_LOADED`. Per-skill settings and per-dungeon routes stored here. |

---

## v0.1.0 New API: MDT Ability Data Extraction

### Source Location

All nine Midnight S1 dungeon files are at:
`C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\<DungeonName>.lua`

Files: `WindrunnerSpire.lua`, `MaisaraCaverns.lua`, `AlgetharAcademy.lua`, `MagistersTerrace.lua`,
`MurderRow.lua`, `NexusPointXenas.lua`, `PitOfSaron.lua`, `SeatoftheTriumvirate.lua`, `Skyreach.lua`

### Table Path

```
MDT.dungeonEnemies[dungeonIndex][enemyIndex]
```

Each enemy record shape (verified in WindrunnerSpire.lua and MaisaraCaverns.lua):

```lua
{
  ["name"]        = "Restless Steward",   -- mob display name (string)
  ["id"]          = 232070,               -- npcID (number) — primary key for AbilityDB
  ["count"]       = 7,                    -- M+ count value
  ["health"]      = 1242693,
  ["scale"]       = 1.2,
  ["displayId"]   = 136509,               -- creature display ID (used for NPC portraits)
  ["creatureType"]= "Undead",
  ["level"]       = 90,
  ["spells"]      = {
    [1216135] = {},                        -- key = spellID (number), value always = {} (empty)
    [1216298] = {},
    [1253700] = {},
  },
  ["clones"]      = { ... },
}
```

### Critical Finding: spells table has no metadata

The `spells` table is `spellID -> {}`. The value is **always an empty table** in all nine Midnight
dungeon files. MDT stores only which spell IDs are associated with each mob — no name, cooldown,
description, or priority data inside the spell entry.

To resolve names and icons from extracted spell IDs at addon load time:

```lua
local spellInfo = C_Spell.GetSpellInfo(spellID)
-- spellInfo.name      : string — spell display name
-- spellInfo.iconID    : fileID — texture for the spell icon
-- spellInfo.castTime  : number — cast duration in ms (0 for instant)
-- spellInfo.spellID   : number
-- Returns nil if spellID not found
```

`C_Spell.GetSpellInfo` has `SecretArguments = "AllowedWhenTainted"` — it is available to addon code
at all times. Source: `wow-ui-source/.../SpellDocumentation.lua` lines 336–350.

### Dungeon Index and Map ID Reference

| Dungeon | dungeonIndex | mapID |
|---------|-------------|-------|
| WindrunnerSpire | 152 | 557 |
| MaisaraCaverns | 154 | 560 |
| (remaining 7: read from each file's `MDT.mapInfo[dungeonIndex].mapID`) | — | — |

### Extraction Pattern for AbilityDB Population

For each dungeon file: iterate `MDT.dungeonEnemies[dungeonIndex]`, for each enemy iterate
`enemy.spells` keys. Each key is a spellID. Build `ns.AbilityDB[enemy.id]`:

```lua
ns.AbilityDB[npcID] = {
  mobClass  = "WARRIOR",   -- default: no class data in MDT; WARRIOR matches UnitClass for most humanoids
  abilities = {
    {
      spellID = spellID,
      -- name resolved via C_Spell.GetSpellInfo(spellID).name at load time
      -- first_cast and cooldown: nil = untimed (user cannot cast-time from MDT data)
      -- label, ttsMessage: populated from per-skill config or hardcoded per dungeon
    },
  },
}
```

Untimed is the correct default — MDT has no timing data. Users configure timing in the settings UI
or it is added manually per dungeon in Data/ files.

---

## v0.1.0 New API: Cast Detection

### API Signatures (verified from UnitDocumentation.lua lines 811–877)

**`UnitCastingInfo(unitToken)`** — 11 return values:
```
name, displayName, textureID, startTimeMs, endTimeMs,
isTradeskill, castID, notInterruptible, castingSpellID, castBarID, delayTimeMs
```
The **9th return value** is `castingSpellID` (number) — use this for spell matching.

**`UnitChannelInfo(unitToken)`** — 11 return values:
```
name, displayName, textureID, startTimeMs, endTimeMs,
isTradeskill, notInterruptible, spellID, isEmpowered, numEmpowerStages, castBarID
```
The **8th return value** is `spellID` (number).

Both functions return `nil` for all values when the unit is not casting/channeling.

### Restriction Flag

Both APIs carry `SecretWhenUnitSpellCastRestricted = true` in the documentation. This flag is a
PvP-context restriction controlled by a CVar/game state — not a dungeon or nameplate restriction.
The unit token type is `UnitTokenPvPRestrictedForAddOns`, which includes nameplate units
(`nameplateN`). In PvE M+ dungeon content, this restriction is inactive.

**Verdict: `UnitCastingInfo("nameplateN")` and `UnitChannelInfo("nameplateN")` work in M+ dungeons.**

Confidence: MEDIUM. The API is documented as available and the PvP-only restriction matches the
design intent. Validate in first in-dungeon test session — if spellID returns nil for visible casts,
the restriction may be active in instanced content (would require fallback to nameplate event-based
detection).

**Note:** The earlier STACK.md (v0.0.x) listed `UnitCastingInfo` as unavailable in instances — that
assessment was based on general "Secret Values" caution before detailed API verification. The actual
documentation shows the restriction is `SecretWhenUnitSpellCastRestricted` (PvP), not a blanket
instance block. Updated conclusion: attempt it, validate early.

### Integration with Existing NameplateScanner

Add to the existing 0.25s tick loop in `Engine/NameplateScanner.lua`. Build a `watchedSpells`
lookup at pack activation (O(1) per cast check):

```lua
-- At pack activation, build reverse lookup for untimed abilities
local watchedSpells = {}
for _, ability in ipairs(activePack.abilities) do
  if not ability.cooldown then  -- untimed abilities only
    watchedSpells[ability.spellID] = ability
  end
end

-- Inside the 0.25s ticker, for each unitToken in plateCache:
local _, _, _, _, _, _, _, _, castingSpellID = UnitCastingInfo(unitToken)
if not castingSpellID then
  local _, _, _, _, _, _, _, channelSpellID = UnitChannelInfo(unitToken)
  castingSpellID = channelSpellID
end
if castingSpellID and watchedSpells[castingSpellID] then
  local ability = watchedSpells[castingSpellID]
  -- trigger untimed highlight for this ability
  ns.IconDisplay.TriggerUntimedHighlight(ability.spellID)
end
```

---

## v0.1.0 New API: Sound Alerts

### PlaySound Signature (verified from SoundDocumentation.lua lines 52–71)

```lua
local success, soundHandle = PlaySound(soundKitID, uiSoundSubType, forceNoDuplicates, runFinishCallback, overridePriority)
```

Only `soundKitID` is required. For alert sounds:

```lua
PlaySound(soundKitID)  -- plays on default sound channel, no duplicates logic needed
```

### CDM-Curated Sound Kit IDs

Blizzard's Cooldown Manager (CDM) ships a purpose-built set of alert-appropriate sounds in
`CooldownViewerSoundAlertData.lua`. These are safe to use — they are WoW built-in soundKitIDs
that exist in the client independently of CDM:

| Category | Sound | soundKitID |
|----------|-------|-----------|
| Impacts | Low Thud | 316531 |
| Impacts | Metal Clanks | 316532 |
| Impacts | Anvil Strike | 316528 |
| Impacts | Pop Click | 316434 |
| Instruments | Bell Ring | 316493 |
| Instruments | Chime Ascending | 316447 |
| Instruments | Warhorn | 316723 |
| Devices | Air Horn | 316436 |
| Devices | Boat Horn | 316442 |
| War3 | Fanfare | 316769 |
| War3 | Wolf Howl | 316766 |
| Animals | Wolf | 316415 |

**Recommended defaults for TPW:**
- Pre-warning (5s before timed cast): `316493` (Bell Ring — short, clear, unmistakable)
- Untimed cast detected: `316531` (Low Thud — CDM's own default for new sound alerts)

Source: `CooldownViewerSoundAlertData.lua` (full list) and `CooldownViewerAlert.lua` line 51
(`defaultPayloadForAlertType` defaults to `ImpactsLowThud` = 316531).

### How CDM Plays Sounds

```lua
-- From CooldownViewerAlert.lua line 231-236:
local function CooldownViewerAlert_PlaySoundAlert(_cooldownItem, spellName, alert)
  local soundKit = CooldownViewerAlert_GetPayloadContextData(alert)
  if soundKit then
    PlaySound(soundKit)   -- bare call, no flags
  end
end
```

TPW does not need CDM's enum indirection. Store `soundKitID` directly in per-skill config and call
`PlaySound(soundKitID)` directly.

### Sound Dropdown for Config UI

Present a flat dropdown of ~12 named sounds from the CDM curated list. Store the name and
soundKitID pairs as a static table in a new `Data/Sounds.lua` file:

```lua
ns.AlertSounds = {
  { name = "Bell Ring",  soundKitID = 316493 },
  { name = "Low Thud",   soundKitID = 316531 },
  { name = "Air Horn",   soundKitID = 316436 },
  { name = "Warhorn",    soundKitID = 316723 },
  { name = "Fanfare",    soundKitID = 316769 },
  { name = "Wolf Howl",  soundKitID = 316766 },
  -- ... extend as needed
}
```

Use a plain `Button` that shows selected sound name and opens a simple popup list — consistent with
TPW's existing style and avoids `UIDropDownMenu` deprecation issues.

---

## v0.1.0 New API: Config Panel ScrollFrame + Expandable Hierarchy

### Recommended Pattern

Use the same `ScrollFrame + UIPanelScrollFrameTemplate + manual child frame stacking` already in
`UI/PackFrame.lua`. Do not use `ScrollBox`/`DataProvider` — it requires Blizzard Mixin
infrastructure not present in TPW and is overkill for a static config tree.

CDM's settings panel (`CooldownViewerSettings.xml` lines 201–220) confirms this is the correct
approach even for Blizzard's own production Midnight addons:

```xml
<ScrollFrame parentKey="CooldownScroll" inherits="ScrollFrameTemplate">
  <ScrollChild>
    <Frame parentKey="Content">
      <!-- category frames stacked vertically here -->
    </Frame>
  </ScrollChild>
</ScrollFrame>
```

### Collapse/Expand Implementation

CDM uses `CooldownViewerCategoryMixin` with `isCollapsed` state toggled on header click, then
calls `RefreshLayout()` to rebuild visible frames (source: `CooldownViewerSettings.lua` lines
97–103). For TPW, a simpler implementation:

```lua
local node = {
  header   = CreateFrame("Button", nil, scrollChild),  -- clickable dungeon/mob header
  content  = CreateFrame("Frame", nil, scrollChild),   -- children container
  expanded = true,
}
node.header:SetScript("OnClick", function()
  node.expanded = not node.expanded
  node.content:SetShown(node.expanded)
  RebuildLayout()  -- reposition all nodes top-to-bottom with SetPoint
end)
```

`RebuildLayout` iterates all nodes in order, setting each node's `TOPLEFT` anchor relative to the
bottom of the previous visible frame. Matches the row construction pattern in `PackFrame.lua`.

After expand/collapse, update scroll child height:
```lua
scrollChild:SetHeight(totalHeight)
scrollFrame:UpdateScrollChildRect()
```

### Three-Level Hierarchy

```
Dungeon (collapsible header)
  └── Mob (collapsible sub-header, indented 8px)
        └── Skill row (leaf, not collapsible)
              ├── CheckButton (enable/disable tracking)
              ├── EditBox (custom label, 8 chars)
              ├── EditBox (TTS text, 30 chars)
              └── Button (sound selection → popup list)
```

Skill rows are read from `ns.AbilityDB` organized by dungeon→npcID→ability array.

### ResizeLayoutFrame vs Manual Layout

CDM uses `ResizeLayoutFrame` (inherits="ResizeLayoutFrame" in `CooldownViewerSettingsCategoryTemplate`).
This requires child frames to expose `GetLayoutChildrenBounds`. For TPW, manual `SetPoint` anchoring
is simpler, already proven in `PackFrame.lua`, and has no extra dependency.

---

## v0.1.1 New API: Mob Category Detection

### Goal

Derive per-mob categories (boss, miniboss, caster, warrior, rogue, trivial, unknown) at nameplate
scan time. Categories are used for alert filtering — e.g., suppress certain warnings when no
warrior-type mob is alive.

### API Inventory

All four APIs below are verified in `wow-ui-source 12.0.1.66337` — specifically
`Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`. All carry
`SecretArguments = "AllowedWhenUntainted"`, meaning addon code (which is always untainted) may call
them freely. None have `SecretWhen*` or `ConditionalSecret` on their **return values** — the
results are not Secret Values.

#### `UnitClassification(unitToken)` — string

Returns the PvE difficulty tier of a unit. Verified return strings from Blizzard UI source
(NamePlateClassificationFrame.lua, TargetFrame.lua, UnitFrame.lua):

| Return value | Meaning |
|---|---|
| `"worldboss"` | World boss / instanced boss |
| `"elite"` | Elite mob |
| `"rareelite"` | Rare elite |
| `"rare"` | Rare mob |
| `"normal"` | Standard trash mob |
| `"minus"` | "Minus" mob — counts as 0 for M+ percent, reduced scaling |
| `"trivial"` | Grey-skull trivial (level too low relative to player) |

Not documented but implied by the `"minus"` check in `UnitFrame.lua` line 1020: returns a non-nil
string even for nameplateN units. Safe to call at `NAME_PLATE_UNIT_ADDED` and cache.

**Confidence: HIGH** — return values confirmed from two Blizzard UI files
(`Blizzard_NamePlateClassificationFrame.lua` and `Blizzard_UnitFrame/Mainline/TargetFrame.lua`).

**In Midnight dungeons:** Trash mobs return `"normal"`. Bosses return `"worldboss"`. No
`SecretWhen*` restriction on the return — value is readable. The nameplate-specific frame
(`Blizzard_NamePlateClassificationFrame.lua`) calls `UnitClassification(self.unitToken)` directly,
confirming it works on `nameplateN` tokens.

#### `UnitIsBossMob(unitToken)` — bool

Returns `true` if the unit is considered a boss by the game engine. Distinct from
`UnitClassification() == "worldboss"` in subtle ways (some lieutenants may return `true` here).
Used by `TargetFrame.lua` line 427 for gold dragon portrait frame display.

**Confidence: HIGH** — verified in UnitDocumentation.lua (line 1720) and TargetFrame.lua (line 427).

Use this as the authoritative boss signal, not `UnitClassification() == "worldboss"`, since it is
a single boolean and covers edge cases.

#### `UnitIsLieutenant(unitToken)` — bool

Returns `true` if the unit is a "lieutenant" — Blizzard's term for a miniboss-tier enemy that is
above trash but below a full boss. Present in the API documentation (UnitDocumentation.lua line
1995) but **has zero usage in any Blizzard UI file** in the 12.0.1.66337 source tree.

**Confidence: MEDIUM** — documented and has correct signature, but no Blizzard UI code exercises
it. In-game behavior unverified. Use with `pcall` defensively:

```lua
local ok, isLt = pcall(UnitIsLieutenant, unitToken)
local isLieutenant = ok and isLt or false
```

#### `UnitClassBase(unitToken)` — classFilename, classID

Returns the mob's class tag (e.g., `"WARRIOR"`, `"MAGE"`, `"ROGUE"`). Already used in the existing
`NameplateScanner.lua` (`OnNameplateAdded`). The `className` (localized display name) is marked
`ConditionalSecret = true` in `UnitClass()`, but `UnitClassBase()` returns only `classFilename` and
`classID` — neither is marked secret.

**Confidence: HIGH** — already in production use in TPW v0.1.0.

#### `UnitEffectiveLevel(unitToken)` — number

Returns the unit's effective level (scaling applied level for instanced content). Argument is typed
as `cstring` in the documentation, but in practice accepts `UnitToken` (confirmed by Blizzard usage
in `TargetFrame.lua` line 267: `UnitEffectiveLevel(self.unit)` where `self.unit` is a unit token).

**Not needed for the category system.** Level data is not a reliable discriminator for
boss/miniboss/trash in Mythic+ — all Midnight S1 mobs scale to player item level and return similar
effective levels. Omit from the detection logic.

**Confidence: HIGH** — available, but not useful for this feature.

### Secret Value Status Summary

| API | Return Secret? | Safe in Midnight M+? |
|-----|---------------|----------------------|
| `UnitClassification(nameplateN)` | No | Yes — no `SecretWhen*` on return |
| `UnitIsBossMob(nameplateN)` | No | Yes — no `SecretWhen*` on return |
| `UnitIsLieutenant(nameplateN)` | No | Yes — no `SecretWhen*` on return; behavior unverified |
| `UnitClassBase(nameplateN)` | No | Yes — already in use in v0.1.0 |
| `UnitEffectiveLevel(nameplateN)` | No | Yes — but not useful for category detection |

### Recommended Category Detection Logic

Derive category at `NAME_PLATE_UNIT_ADDED`, cache in `plateCache`. This is the right place: it runs
once per mob appearance, not in the hot 0.25s tick loop.

```lua
function Scanner:OnNameplateAdded(unitToken)
    local hostile = UnitCanAttack("player", unitToken)
    local classFilename, _ = UnitClassBase(unitToken)

    local category = "unknown"
    if UnitIsBossMob(unitToken) then
        category = "boss"
    else
        local ok, isLt = pcall(UnitIsLieutenant, unitToken)
        if ok and isLt then
            category = "miniboss"
        elseif classFilename == "MAGE" or classFilename == "PRIEST" or classFilename == "WARLOCK"
               or classFilename == "SHAMAN" or classFilename == "DRUID" or classFilename == "EVOKER" then
            category = "caster"
        elseif classFilename == "ROGUE" or classFilename == "DEMONHUNTER" then
            category = "rogue"
        elseif classFilename == "WARRIOR" or classFilename == "PALADIN" or classFilename == "DEATHKNIGHT"
               or classFilename == "MONK" or classFilename == "HUNTER" then
            category = "warrior"
        end
        -- "trivial" comes from UnitClassification if needed:
        local classification = UnitClassification(unitToken)
        if classification == "trivial" or classification == "minus" then
            category = "trivial"
        end
    end

    plateCache[unitToken] = {
        hostile   = hostile,
        classBase = classFilename,
        category  = category,
    }
end
```

**Design notes:**
- `UnitIsBossMob` checked first — authoritative, no ambiguity.
- `UnitIsLieutenant` wrapped in `pcall` since no in-game verification exists.
- Class-to-category mapping is heuristic; Skyreach data will be manually hardcoded in AbilityDB
  so runtime detection is a fallback for unknown mobs.
- `"trivial"` and `"minus"` mobs are explicitly suppressed (never generate alerts). The
  `classification == "minus"` check catches the special M+ zero-count mobs.
- Category `"unknown"` is the wildcard: unknown mobs are never filtered, so warnings still fire.

### Integration Points with Existing NameplateScanner

The existing `plateCache` already stores `hostile` and `classBase`. Add `category` as a third field
at `NAME_PLATE_UNIT_ADDED` — zero changes to the 0.25s tick loop.

The `OnMobsAdded` / `OnCastStart` handlers currently filter by `ability.mobClass == classBase`.
Add a secondary filter: `ability.category == nil or ability.category == cached.category` where
`ability.category` is the new field in AbilityDB entries (nil = no category filter = applies to
all).

### AbilityDB Schema Extension

Add an optional `category` field per mob entry in Data/ files:

```lua
ns.AbilityDB[npcID] = {
    mobClass = "MAGE",
    category = "caster",   -- new field; nil means "unknown" (wildcard)
    abilities = { ... },
}
```

For Skyreach: hardcode `category` on every npcID. For all other dungeons: omit `category` (nil),
which means unknown and passes all filters.

### What NOT to Use for Category Detection

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `UnitEffectiveLevel` for boss/trash discrimination | All M+ mobs scale to similar levels — not a reliable discriminator | `UnitIsBossMob` for bosses, `UnitClassification` for trivial |
| `UnitClassification() == "worldboss"` as boss signal | Does not cover all boss-tier mobs; `UnitIsBossMob` is the canonical check | `UnitIsBossMob(unitToken)` |
| `UnitClassification` as primary category signal | Only reliable for trivial/minus — normal/elite strings don't map to caster/warrior/rogue | `UnitClassBase` for class-based categories |
| Polling classification APIs in the 0.25s tick | Classification is stable for the lifetime of a nameplate (mob doesn't change tier mid-combat) | Cache at `NAME_PLATE_UNIT_ADDED`, read from cache in tick |

---

## API Reference Summary

| API | Key Return Values | Notes |
|-----|------------------|-------|
| `C_Spell.GetSpellInfo(spellID)` | `{name, iconID, castTime, spellID}` table | Returns nil if not found. Available to all addon code. |
| `UnitCastingInfo(unitToken)` | 9th return = `castingSpellID` | Works on `nameplateN` units in PvE. Validate in-game. |
| `UnitChannelInfo(unitToken)` | 8th return = `spellID` | Same availability as UnitCastingInfo. |
| `PlaySound(soundKitID)` | `success, soundHandle` | Pass soundKitID directly. One argument is sufficient. |
| `MDT.dungeonEnemies[idx][i].spells` | `{[spellID] = {}, ...}` | Keys are spell IDs. Values always empty in Midnight MDT data. |
| `MDT.dungeonEnemies[idx][i].id` | npcID (number) | Primary key for `ns.AbilityDB`. |
| `MDT.dungeonEnemies[idx][i].name` | mob display name (string) | Use for config UI labels. |
| `UnitClassification(unitToken)` | `"worldboss"`, `"elite"`, `"rareelite"`, `"rare"`, `"normal"`, `"minus"`, `"trivial"` | No Secret Value restriction. Cache at nameplate added. |
| `UnitIsBossMob(unitToken)` | `bool` | Authoritative boss check. No Secret Value restriction. |
| `UnitIsLieutenant(unitToken)` | `bool` | Miniboss check. Documented, not exercised in Blizzard UI. Use pcall. |
| `UnitClassBase(unitToken)` | `classFilename, classID` | Already in use. Maps to caster/warrior/rogue categories. |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| New external libraries | No new Libs needed for v0.1.0–v0.1.1 features | Native WoW API throughout |
| `ScrollBox` / `DataProvider` pattern | Requires Blizzard Mixin infrastructure not in TPW | `ScrollFrame + UIPanelScrollFrameTemplate` (already in PackFrame.lua) |
| `UIDropDownMenu_Initialize` | Deprecated in Midnight | Simple Button + popup list frame |
| `DropdownButton:SetupMenu()` | Modern pattern but requires `rootDescription` Mixin infrastructure | Simple Button + popup list frame (consistent with TPW style) |
| `SOUNDKIT` constants for alert sounds | SOUNDKIT maps UI-event sounds (cursor clicks, window open) — not the CDM alert sounds | Raw soundKitID numbers from CDM's curated table |
| Auto-deriving ability timers from cast timing | Cast detection is for untimed skill highlights only | Keep predefined cooldowns for timed abilities; use cast detection only for untimed |
| `ResizeLayoutFrame` | Requires children to expose `GetLayoutChildrenBounds` | Manual `SetPoint` anchoring (already used in PackFrame.lua) |
| `UnitEffectiveLevel` for category detection | Level not a reliable boss/trash discriminator in scaled M+ content | `UnitIsBossMob` + `UnitClassBase` |
| Polling classification in the 0.25s tick loop | Classification is stable per nameplate lifetime | Cache once at `NAME_PLATE_UNIT_ADDED` |

---

## Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `./scripts/install.bat` | Deploy to WoW addons folder | Use `./` prefix (not `cmd.exe /c`) |
| `/tpw debug` | Enable debug logging | Toggle `ns.db.debug` |
| `/tpw status` | Print current state | CombatWatcher + Scanner state |
| WoW in-game `/api` | Browse live API | Verify UnitCastingInfo behavior on nameplates in-dungeon |
| CVar `secretSpellcastsForced` | Simulate spell cast restriction outside instance | Test restricted code paths without entering M+ |

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Native `PlaySound(soundKitID)` | `C_EncounterEvents.SetEventSound` | Only if integrating with the Boss Timeline HUD (not a v0.1.0 goal) |
| Manual ScrollFrame layout | `ResizeLayoutFrame` + `GridLayoutFrame` | Only if building a fully dynamic drag-reorder UI like CDM |
| Flat sound list (8–12 options) | Full CDM nested category menu (60+ sounds) | Full list if users request more variety; the flat list covers the useful range |
| UnitCastingInfo polling in existing 0.25s loop | Separate ticker for cast detection | Adding to existing loop avoids timer proliferation; 0.25s resolution is sufficient for cast detection |
| `UnitIsBossMob` as boss signal | `UnitClassification() == "worldboss"` | If `UnitIsBossMob` is found to misbehave in-game; the classification string is a valid fallback |

---

## Version Compatibility

| Component | Interface | Notes |
|-----------|----------|-------|
| TOC `## Interface` | 120001 | Hard requirement |
| `C_Timer.After` | 120001 | AllowedWhenUntainted confirmed |
| `C_Spell.GetSpellInfo` | 120001 | AllowedWhenTainted — available to addon code |
| `UnitCastingInfo` / `UnitChannelInfo` | 120001 | SecretWhenUnitSpellCastRestricted (PvP only) — validate in-dungeon |
| `PlaySound(soundKitID)` | All modern | Stable |
| `ScrollFrame + UIPanelScrollFrameTemplate` | All modern | Stable |
| `CreateFrame("CheckButton")` | All modern | Stable |
| `UnitClassification(nameplateN)` | 120001 | No return value restrictions. Confirmed in NamePlateClassificationFrame.lua. |
| `UnitIsBossMob(nameplateN)` | 120001 | No return value restrictions. Confirmed in TargetFrame.lua. |
| `UnitIsLieutenant(nameplateN)` | 120001 | Documented. Not used in any Blizzard UI file — verify in-game. |
| `UnitClassBase(nameplateN)` | 120001 | In production use in TPW v0.1.0. |

---

## Sources

- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\WindrunnerSpire.lua` — MDT enemy/spell table structure (HIGH confidence, direct source read)
- `C:\Users\jonat\Repositories\MythicDungeonTools\Midnight\MaisaraCaverns.lua` — Confirmed same structure across dungeons (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\UnitDocumentation.lua` lines 811–877 — UnitCastingInfo/UnitChannelInfo return values and restriction flags (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\UnitDocumentation.lua` lines 912–960 — UnitClassBase, UnitClassification signatures; no SecretWhen on returns (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\UnitDocumentation.lua` lines 1720–1733 — UnitIsBossMob signature (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\UnitDocumentation.lua` lines 1995–2008 — UnitIsLieutenant signature (HIGH confidence for existence; MEDIUM for in-game behavior)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\UnitDocumentation.lua` lines 1086–1099 — UnitEffectiveLevel signature (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_NamePlates\Blizzard_NamePlateClassificationFrame.lua` lines 77–127 — UnitClassification return values in use: "elite", "worldboss", "rare", "rareelite" (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_NamePlates\Blizzard_NamePlateUnitFrame.lua` line 359 — `UnitClassification(unitToken) == "minus"` confirms "minus" is a valid return (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_UnitFrame\Mainline\TargetFrame.lua` lines 370–440 — UnitClassification full branch coverage ("minus", "rare", "rareelite", "elite"); UnitIsBossMob usage line 427 (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_UnitFrame\Mainline\UnitFrame.lua` line 1020 — UnitClassification("minus") usage (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\SoundDocumentation.lua` lines 52–71 — PlaySound signature (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\SpellDocumentation.lua` lines 336–350, 1061–1073 — C_Spell.GetSpellInfo signature and SpellInfo struct (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_CooldownViewer\CooldownViewerSoundAlertData.lua` — CDM-curated soundKitID list with category organization (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_CooldownViewer\CooldownViewerAlert.lua` lines 231–236, 50–52 — PlaySound call pattern and default sound selection (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_CooldownViewer\CooldownViewerSettings.xml` lines 100–134, 201–220 — ScrollFrame layout pattern and collapsible category template (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_CooldownViewer\CooldownViewerSettings.lua` lines 97–103, 127–148 — Collapse/expand mixin pattern and category list structure (HIGH confidence)
- `C:\Users\jonat\Repositories\wow-ui-source\Interface\AddOns\Blizzard_CombatAudioAlerts\Blizzard_CombatAudioAlertManager.lua` lines 826–862 — UnitCastingInfo/UnitChannelInfo usage pattern (HIGH confidence)
- `C:\Users\jonat\Repositories\TerriblePackWarnings\UI\PackFrame.lua` — Existing ScrollFrame + manual row layout pattern (HIGH confidence)
- `C:\Users\jonat\Repositories\TerriblePackWarnings\Engine\NameplateScanner.lua` — Existing 0.25s tick loop and plateCache structure for integration point (HIGH confidence)

---

*Stack research for: TerriblePackWarnings v0.1.1 — Mob Category Detection milestone*
*Researched: 2026-03-23*
