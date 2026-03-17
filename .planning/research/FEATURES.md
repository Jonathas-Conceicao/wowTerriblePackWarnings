# Feature Research

**Domain:** WoW Mythic+ addon — configuration UI, ability data population, cast detection, sound alerts, per-dungeon route management
**Researched:** 2026-03-17
**Confidence:** HIGH (sourced directly from wow-ui-source and MythicDungeonTools repositories)

---

## Feature Area 1: Configuration Panel (Dungeon → Mob → Skill Hierarchy)

### How WoW addons do per-spell config trees

**Pattern source:** Blizzard_CooldownViewer (`CooldownViewerSettings.lua`, `CooldownViewerSettingsAlerts.lua`)

CDM (Cooldown Manager) in Midnight uses a three-layer hierarchy:
1. Top-level: category list (spells by type/class, collapsible with `SetCollapsed`)
2. Mid-level: spell/cooldown item row (icon, name, drag-to-reorder)
3. Detail panel: slides in to the right (`SetPoint("TOPLEFT", owner, "TOPRIGHT", ...)`) for per-spell alert editing

Key patterns observed:
- The edit panel is a separate frame docked to the right, not inline with the list. It opens when a row is clicked.
- Per-cooldown alerts support multiple entries (one spell can have several alerts).
- Alert type is picked first (Sound vs Visual), then event type (available/expiring), then payload (which sound).
- CDM stores enum integers (`CooldownViewerSound.*`) not soundKitIDs — soundKitIDs are in the data table for playback only.

For TPW, the appropriate simplification is a flat tree inside a scrollable list:
- Level 1: Dungeon name (read-only header, built from AbilityDB keys)
- Level 2: Mob name row (collapsible)
- Level 3: Skill row with inline controls (checkbox, label EditBox, TTS EditBox, sound dropdown)

This avoids the CDM slide-out panel complexity while matching the expected WoW addon config UX. WeakAuras uses a similar inline-row approach for aura-per-aura settings.

**Complexity note:** Tree rendering with a flat pool of reusable frames (like DBM option rows) is the pattern. Avoid ScrollingMessageFrame — use a manual ScrollFrame with a frame pool.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Per-skill enable/disable checkbox | Every WoW config addon supports disabling individual alerts | LOW | Boolean stored per (npcID, spellID) in SavedVariables |
| Custom label per skill | WeakAuras, DBM all let users rename displayed text | LOW | EditBox, stored as string override on top of default name |
| Keyboard-accessible EditBoxes | WoW addons that trap keys must handle escape/enter | LOW | `EditBox:SetScript("OnEscapePressed", ...)` pattern |
| Settings persist across sessions | SavedVariables pattern — users expect zero re-config per session | LOW | Write to `TerriblePackWarningsDB` on change |
| Visual scan of all skills at once | Users want to see what's configured for a dungeon without clicking per-mob | MEDIUM | Scrollable list with all mobs and skills visible |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| TTS text override per skill | Per-skill TTS callout ("big hit!", "move!") is unique to TPW | LOW | EditBox alongside label field, passed to C_VoiceChat.SpeakText |
| Sound dropdown per skill (CDM-style) | Familiar UX from built-in CDM, skill-level granularity | MEDIUM | See Feature Area 2 for sound list |
| Dungeon → Mob → Skill collapsible tree | Organized hierarchy vs flat lists in most addons | MEDIUM | Frame pool + toggle logic |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Global mute toggle in config | "Disable all sounds fast" seems useful | Creates confusion when sounds return unexpectedly; users forget state | Per-skill checkbox; CombatWatcher already handles idle state |
| Import/export config profiles | Power users want to share settings | Adds serialization complexity and a separate UI surface before core works | Defer to future milestone; SavedVariables portability is a v2 concern |
| In-config sound preview button | CDM does this (play sample button per row) | Requires PlaySound call from UI context — works but adds frame-per-row complexity | Add as P2 enhancement after dropdown works |

---

## Feature Area 2: Sound Alert System

### CDM sound pattern (verified from wow-ui-source)

**Source files:** `CooldownViewerSoundAlertData.lua`, `CooldownViewerSettingsConstants.lua`, `CooldownViewerSettingsAlerts.lua`

CDM organizes sounds into 6 named categories using a nested table (`CooldownViewerSoundData`). Each entry has:
- `soundEnum` — integer constant from `CooldownViewerSound` enum (stable, never changes)
- `soundKitID` — the WoW internal ID used with `PlaySound`
- `text` — localized display string

The dropdown is built recursively from this table using `BuildSoundMenus`, which creates nested submenus for each category. A "play sample" utility button is attached to each row via `MenuTemplates.AttachUtilityButton`.

For TPW, the sound dropdown should use the same `soundKitID` values directly via `PlaySound(soundKitID, "Master")`. There is no need to replicate the CDM enum layer — TPW can store `soundKitID` integers directly in SavedVariables.

### Sound Library — All CDM Sounds with SoundKitIDs

**Category: Animals (10 sounds)**

| Name | soundKitID |
|------|-----------|
| Cat | 316401 |
| Chicken | 316406 |
| Cow | 316407 |
| Gnoll | 316409 |
| Goat | 316715 |
| Lion | 316411 |
| Panther | 316412 |
| Rattlesnake | 316413 |
| Sheep | 316414 |
| Wolf | 316415 |

**Category: Devices (11 sounds)**

| Name | soundKitID |
|------|-----------|
| Boat Horn | 316442 |
| Air Horn | 316436 |
| Bike Horn | 316713 |
| Cash Register | 316446 |
| Jackpot Bell | 316717 |
| Jackpot Coins | 316718 |
| Jackpot Fail | 316719 |
| Rotary Phone Dial | 316433 |
| Rotary Phone Ring | 316492 |
| Stove Pipe | 316425 |
| Trashcan Lid | 316430 |

**Category: Impacts (10 sounds)**

| Name | soundKitID |
|------|-----------|
| Anvil Strike | 316528 |
| Bubble Smash | 316419 |
| Low Thud | 316531 |
| Metal Clanks | 316532 |
| Metal Rattle | 316486 |
| Metal Scrape | 316484 |
| Metal Warble | 316536 |
| Pop Click | 316434 |
| Strange Clang | 316453 |
| Sword Scrape | 316535 |

**Category: Instruments (12 sounds)**

| Name | soundKitID |
|------|-----------|
| Bell Ring | 316493 |
| Bell Trill | 316712 |
| Brass | 316722 |
| Chime Ascending | 316447 |
| Guitar Chug | 316477 |
| Guitar Pinch | 316482 |
| Pitch Pipe Distressed | 316509 |
| Pitch Pipe Note | 316501 |
| Synth Big | 316540 |
| Synth Buzz | 316476 |
| Synth High | 316460 |
| Warhorn | 316723 |

**Category: War2 (12 sounds)**

| Name | soundKitID |
|------|-----------|
| Abstract Whoosh | 316731 |
| Choir | 316733 |
| Construction | 316735 |
| Magic Chimes | 316736 |
| Pig Squeal | 316745 |
| Saws | 316738 |
| Seal | 316746 |
| Slow | 316748 |
| Smith | 316749 |
| Synth Stinger | 316739 |
| Trumpet Rally | 316740 |
| Zippy Magic | 316737 |

**Category: War3 (12 sounds)**

| Name | soundKitID |
|------|-----------|
| Bell | 316773 |
| Crunchy Bell | 316774 |
| Drum Splash | 316768 |
| Error | 316775 |
| Fanfare | 316769 |
| Gate Open | 316776 |
| Gold | 316770 |
| Magic Shimmer | 316778 |
| Ringout | 316771 |
| Rooster | 316765 |
| Shimmer Bell | 316779 |
| Wolf Howl | 316766 |

**Recommended defaults for TPW:**
- Timed skill pre-warning (5s): `316447` (Chime Ascending) — distinct, not alarming
- Untimed skill cast detection: `316531` (Low Thud) — immediate, punchy
- "None" option: store `0` or `nil`, skip PlaySound call

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| None option in sound dropdown | Users who prefer TTS-only expect a silent option | LOW | Sentinel value (0 or nil), skip PlaySound call |
| Immediate playback on select (preview) | CDM does this; users expect to hear the sound before committing | LOW | Call PlaySound from dropdown OnClick |
| Sound fires at correct moment | Alert happens at ability trigger, not randomly | LOW | Scheduler already owns timing; just call PlaySound there |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Per-skill sound selection vs global | Skill-specific sounds help distinguish alert types audibly | MEDIUM | Stored per (npcID, spellID); loaded from SavedVariables in Scheduler |
| CDM-identical sound library | Users who use CDM recognize sounds; zero learning curve | LOW | Use same soundKitIDs sourced from wow-ui-source |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Custom file path sound support | Power users want their own sounds | WoW sandboxes file access; only WoW data directory sound paths work | Use the full CDM library — 67 sounds is enough variety |
| Volume slider per skill | CDM has category volume control | Adds SavedVariable complexity before core value is proven | Use Master channel; global volume is user's responsibility |

---

## Feature Area 3: Per-Dungeon Route Management

### How route addons handle multiple dungeons

**Source:** `MythicDungeonTools/Modules/DungeonSelect.lua`, MDT preset data structures

MDT stores routes as presets keyed by dungeon index:

```
db.presets[currentDungeonIdx][presetIdx].value.pulls
```

Each dungeon has its own independent preset list. Dungeon switching via `MDT:UpdateToDungeon(dungeonIdx)` replaces the active data set entirely without destroying other dungeon data.

The dungeon selector in MDT is a row of 40x40 icon buttons along the top of the main frame. Each button shows the dungeon icon (from `mapInfo.iconId` or `C_Spell.GetSpellTexture(teleportId)`), a short name label (`mapInfo.shortName`), and a hover tooltip with full name and timer. A `selectedTexture` atlas overlay (`bags-glow-artifact`) marks the active dungeon.

For TPW, the dungeon selector should be simpler:
- A dropdown or tab-style button row of dungeon short names (9 dungeons for Midnight S1)
- Selected dungeon determines which route slot is active
- Zone-in auto-switch using `PLAYER_ENTERING_WORLD` checking `C_Map.GetBestMapForUnit("player")` against a mapID table

Storage pattern: `TerriblePackWarningsDB.routes[dungeonKey]` where `dungeonKey` is the dungeon name or index from `DungeonEnemies`. Each slot holds the processed pack data for that dungeon's imported route (same structure as current `PackDatabase["imported"]`).

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Per-dungeon route storage (independent) | Importing WS route should not overwrite a previously imported GB route | LOW | Nest route data under dungeon key in SavedVariables |
| Dungeon selector UI visible in TPW window | Users need to know which dungeon is active | LOW | Dropdown or button row; 9 dungeons for S1 |
| Zone-in auto-switch to correct dungeon | M+ players enter dungeon and expect correct route to be active | MEDIUM | Event: PLAYER_ENTERING_WORLD + C_Map.GetBestMapForUnit; compare to mapID table |
| Clear route per dungeon (not all dungeons) | Clearing WS data should not affect GB data | LOW | Clear only `routes[dungeonKey]` |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Zone-in auto-switch | Zero-click correct dungeon on zone-in, unlike MDT which requires manual selection | MEDIUM | mapID to dungeonKey lookup table needed; dungeon mapIDs available via C_ChallengeMode or hardcoded |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Multiple presets per dungeon | MDT supports multiple route presets per dungeon | Not needed for TPW — one active route per dungeon is the use case | Single route slot per dungeon; re-import to replace |
| Route editing within TPW | Users might want to add/remove pulls | Route editing belongs in MDT/Keystone.guru; TPW is a read-only consumer | Hard import boundary: TPW only reads, never edits route structure |

---

## Feature Area 4: Mob Count Display in Pull Rows

### How MDT shows mob counts per pull

**Source:** `AceGUIWidget-MythicDungeonToolsPullButton.lua`, `SetNPCData` method (lines 855–882)

MDT's pull row contains:
1. A pull number label (`self.pullNumber:SetText(self.index)`)
2. Up to `maxPortraitCount = 7` portrait slots
3. Each portrait shows `fontString:SetText("x"..data.quantity)` — the count of that mob type in the pull
4. Portraits are sorted `table.sort(enemyTable, function(a,b) return a.count > b.count end)` — most frequent mob type first
5. A `percentageFontString` shows pull forces count or percent for route planning purposes

The portrait fontstring uses `OUTLINE` font drawn over the portrait texture. The `quantity` field on each enemy entry reflects the count of that specific NPC type in the pull group.

For TPW's existing PackFrame (already has `MAX_PORTRAITS = 8` and a portrait pool), adding mob counts requires:
- Tracking quantity per (pull, npcID) when building pack data from the MDT route during import
- Adding a FontString overlay on each portrait frame (same "x3" format)
- Sorting portraits by quantity descending before display

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Count label on each portrait ("x3") | MDT shows this; users familiar with MDT expect the same visual | LOW | Add FontString overlay to existing portrait frames in PackFrame |
| Sorting by count descending | MDT does this; most common mob visible first | LOW | Sort at display time, not storage time |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Count per mob type not just total | Distinct per-type counts help identify which mob is the threat | LOW | Already the MDT pattern; natural to replicate |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Total forces count / percent bar | MDT shows cumulative forces count and running percentage per pull | Not applicable to TPW (no Keystone forces tracking) | Omit entirely; TPW pull rows are read-only displays |

---

## Feature Area 5: Untimed Skill Highlighting via Cast Detection

### How cast detection works in Midnight (no CLEU)

**Source:** CLAUDE.md constraints, `Blizzard_CombatAudioAlertManager.lua` patterns, PROJECT.md

Midnight disables `COMBAT_LOG_EVENT_UNFILTERED`. The only cast detection available for hostile nameplates is polling `UnitCastingInfo(unitID)` and `UnitChannelInfo(unitID)` on the nameplate unit token within the existing 0.25s poll loop.

`UnitCastingInfo` returns: `name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID`

The Blizzard CombatAudioAlert system (using `UNIT_SPELLCAST_START` etc.) works for `"player"` and `"target"` unit tokens only — not for arbitrary nameplate units. This confirms nameplate polling is the only valid path for TPW.

Detection approach for untimed skills:
- During the poll loop, for each plate in `plateCache`, call `UnitCastingInfo(unitToken)`
- Compare the returned `spellID` against the skill's spellID from AbilityDB
- On match: trigger the untimed skill highlight immediately (no timer, direct show)
- Guard against re-triggering: track `lastCastID` per unit to avoid repeat fires for the same cast

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Highlight shows when cast begins | Users expect instant feedback on dangerous cast start | MEDIUM | Add spellID check to existing poll loop; castID dedup guard |
| Highlight clears when cast ends | Stale highlight after cast end confuses users | LOW | Clear when UnitCastingInfo returns nil for that unit |
| TTS fires on cast detect | Verbal warning is the primary alert modality in TPW | LOW | Same TTS call path as timed skills; call C_VoiceChat.SpeakText |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| 5s pre-warning on timed + cast detection for untimed | Covers both predictive and reactive warning patterns in one addon | MEDIUM | Timed is already built; untimed adds the reactive layer |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| UNIT_SPELLCAST_START event for nameplates | Event is available for player/target but Midnight blocks it for arbitrary nameplate units | Using it would silently fail for the main use case | Polling UnitCastingInfo in the existing loop is the only valid approach |

---

## Feature Dependencies

```
Per-Dungeon Route Storage
    └──required by──> Dungeon Selector UI
                          └──required by──> Zone-in Auto-Switch

AbilityDB Population (all 9 dungeons)
    └──required by──> Config Tree (must have data to configure)
    └──required by──> Mob Count Display (needs pull->npcID->count data)
    └──required by──> Untimed Cast Detection (needs spellID per skill)

Config Tree (Dungeon->Mob->Skill)
    └──required by──> Per-Skill Toggles
    └──required by──> Custom Label Override
    └──required by──> TTS Text Override
    └──required by──> Sound Dropdown per Skill

Untimed Cast Detection
    └──depends on──> Nameplate Poll Loop (already exists)
    └──depends on──> AbilityDB spellID entries

Sound Dropdown
    └──enhances──> Timed Pre-Warning
    └──enhances──> Untimed Cast Detection alert
```

### Dependency Notes

- **AbilityDB population required first:** Config tree and mob count display both need ability data before the UI has anything to render. Populate all 9 dungeons before building config UI.
- **Per-dungeon route storage before dungeon selector:** The selector has nothing to switch between if route storage is still flat. Migrate `PackDatabase["imported"]` to `PackDatabase[dungeonKey]` first.
- **Untimed cast detection requires spellID in AbilityDB:** MDT ability data includes `spellId` per enemy spell entry — this is the field to match against `UnitCastingInfo`. Verify all added abilities include spellID when populating AbilityDB from MDT data.
- **Sound dropdown is independent:** Can be built without other features, but loading/saving requires config tree storage to exist first.

---

## MVP Definition for v0.1.0

### Launch With

- [ ] AbilityDB data for all 9 Midnight S1 dungeons (untimed, WARRIOR default class) — foundational data layer for all other features
- [ ] Per-dungeon route storage (`routes[dungeonKey]`) — enables independent route per dungeon
- [ ] Dungeon selector in TPW window — lets users switch active dungeon
- [ ] Zone-in auto-switch on `PLAYER_ENTERING_WORLD` — zero-click correct dungeon on zone-in
- [ ] Mob count display on pull rows ("x3" overlay on portraits) — visual completeness
- [ ] Config window with dungeon->mob->skill tree — per-skill settings access point
- [ ] Per-skill: enable/disable checkbox, custom label, TTS text field, sound dropdown
- [ ] Untimed skill highlighting via UnitCastingInfo polling
- [ ] Timed skill 5s pre-warning highlight with sound alert

### Add After Validation (v1.x)

- [ ] Sound preview button in dropdown — add after dropdown itself is validated working
- [ ] Config search/filter — add after users report difficulty finding skills in large dungeons

### Future Consideration (v2+)

- [ ] Community config profiles and import/export
- [ ] Multiple route presets per dungeon
- [ ] Volume control per skill category

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| AbilityDB all 9 dungeons | HIGH | MEDIUM (MDT data extraction, manual work per dungeon) | P1 |
| Per-dungeon route storage | HIGH | LOW (data structure change + migration) | P1 |
| Config window tree | HIGH | MEDIUM (frame pool + ScrollFrame) | P1 |
| Per-skill toggle/label/TTS | HIGH | LOW (EditBox + checkbox per row) | P1 |
| Sound dropdown (CDM library) | MEDIUM | MEDIUM (CDM sound table + dropdown build) | P1 |
| Dungeon selector UI | HIGH | LOW (dropdown or button row) | P1 |
| Zone-in auto-switch | HIGH | MEDIUM (mapID lookup table) | P1 |
| Mob count display | MEDIUM | LOW (FontString overlay on existing portraits) | P1 |
| Untimed cast detection | HIGH | MEDIUM (spellID match in poll loop + castID dedup) | P1 |
| Sound preview button | LOW | LOW | P2 |
| Config filter/search | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for v0.1.0 launch
- P2: Should have, add when core is stable
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | MDT | DBM/BigWigs | Our Approach |
|---------|-----|-------------|--------------|
| Dungeon switching | Icon button row (40x40), all dungeons, selectedTexture overlay | N/A (boss-only addon) | Dropdown or tab bar (9 dungeons for S1) |
| Pull mob counts | "x3" portrait label, sorted by count descending | N/A | Same pattern: "x3" overlay on portrait |
| Per-skill config | N/A (MDT is planner, not alerter) | Per-boss enable/disable, preset sound select | Per-skill tree with checkbox/label/TTS/sound |
| Sound alerts | N/A | Limited preset sounds (raid warning, bell) | Full CDM 67-sound library via soundKitID |
| Cast detection | N/A | CLEU-based (blocked in Midnight) | UnitCastingInfo nameplate polling in existing loop |

---

## Sources

- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_CooldownViewer/CooldownViewerSoundAlertData.lua` — CDM sound library (67 sounds, 6 categories, all soundKitIDs verified)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_CooldownViewer/CooldownViewerSettingsConstants.lua` — CooldownViewerSound enum (integer identifiers, 0–67)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_CooldownViewer/CooldownViewerSettingsAlerts.lua` — CDM dropdown build pattern (BuildSoundMenus, nested menus, play sample button via MenuTemplates.AttachUtilityButton)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_CooldownViewer/CooldownViewerSettings.lua` — Category collapse/expand pattern, frame pool patterns
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_CombatAudioAlerts/Blizzard_CombatAudioAlertManager.lua` — UnitCastingInfo usage for cast detection, UNIT_SPELLCAST_START event scope (player/target only)
- `C:/Users/jonat/Repositories/MythicDungeonTools/AceGUIWidgets/AceGUIWidget-MythicDungeonToolsPullButton.lua` — SetNPCData method, portrait count display ("x"..data.quantity), count-descending sort pattern
- `C:/Users/jonat/Repositories/MythicDungeonTools/Modules/DungeonSelect.lua` — Dungeon switching pattern (UpdateToDungeon), icon button row, per-dungeon preset storage structure
- `C:/Users/jonat/Repositories/TerriblePackWarnings/UI/PackFrame.lua` — Existing portrait pool, MAX_PORTRAITS=8 constant, npcID/displayId lookup

---
*Feature research for: TerriblePackWarnings v0.1.0 — Configuration and Skill Data milestone*
*Researched: 2026-03-17*
