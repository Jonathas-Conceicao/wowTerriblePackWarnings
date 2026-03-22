# Pitfalls Research

**Domain:** WoW Midnight dungeon pack warning addon — v0.1.0 Configuration and Skill Data milestone
**Researched:** 2026-03-17
**Confidence:** HIGH for API behavior (verified against wow-ui-source); HIGH for schema migration patterns (derived from existing code); MEDIUM for sound throttling specifics (pattern-confirmed, not benchmarked in Midnight)

---

## Critical Pitfalls

### Pitfall 1: UnitCastingInfo Polling Adds a Second Hot Loop Without a Budget

**What goes wrong:**
Adding `UnitCastingInfo` polling for untimed skill highlighting by piggy-backing on the existing 0.25s `NameplateScanner` tick seems simple, but the cost compounds. The current tick already calls `UnitAffectingCombat` once per visible nameplate (up to 20 calls/tick). Adding `UnitCastingInfo` per-nameplate per-tick doubles the API call budget. At 20 nameplates, that is 40 additional API calls every 0.25s (160/sec) in the hot path. This is not catastrophic in isolation but becomes visible during the period when the config UI is also open (UI rendering + polling simultaneously).

More critically: `UnitCastingInfo` returns 9 values. The 9th return value is `spellID`. Matching this against the ability database on every tick for every nameplate requires iterating the ability list. With 8 dungeons each having 5-15 mobs with 1-3 abilities, the inner loop can reach 30-50 iterations per nameplate per tick. At 20 nameplates, that is 600-1000 table lookups per second.

**Why it happens:**
The existing tick is already O(nameplates). Developers assume adding one more API call per nameplate is negligible. The O(nameplates × abilities) inner loop is not obvious until the ability database grows.

**How to avoid:**
- Build a spellID → ability lookup index at `NameplateScanner:Start(pack)` time. This makes the inner tick O(1) per nameplate instead of O(abilities).
- Gate `UnitCastingInfo` calls behind a separate `castDetect` flag per ability entry. Only call it for nameplates whose cached `classBase` matches at least one untimed ability. This eliminates most calls: most nameplates will not be casting a tracked ability.
- Keep the cast detection check inside the existing 0.25s tick — do not create a second ticker. Two overlapping tickers at different intervals will not be synchronized and will create uneven CPU spikes.
- Use `pcall(UnitCastingInfo, npUnit)` as the current code already does for `UnitAffectingCombat`, since cast state can change between the nameplate being valid and the call completing.

**Warning signs:**
- Frame rate drops during large pulls (6+ mobs) when untimed detection is active.
- `/tpw status` shows cast detection active but no nameplate reductions visible.
- Profiling shows `NameplateScanner.Tick` consuming >0.5ms per call.

**Phase to address:** Cast detection phase — build the spellID index at the same time as the UnitCastingInfo call, not after.

---

### Pitfall 2: UnitCastingInfo False Positives From Shared SpellIDs Across Different Mob Classes

**What goes wrong:**
Multiple mobs in different pulls can share the same spellID (example: two different NPC types using "Fire Spit" spell 1216848). If the pack has npcID A (WARRIOR) with spellID 1216848 and the player is in a different pack containing npcID B (also WARRIOR) with the same spellID but no tracked ability, `UnitCastingInfo` will fire the highlight for npcID A's ability even though the casting mob is not in the active pack.

The converse is also true: the current `classBase` detection in `NameplateScanner` counts all in-combat hostiles of a class, not just the specific npcIDs in the active pack. A random WARRIOR mob that wandered into nameplate range while the pack is active will trigger the untimed highlight for a tracked WARRIOR ability even if that mob has nothing to do with the pack.

**Why it happens:**
The detection model uses `UnitClass` (which maps to `classBase`) as a proxy for mob identity because nameplate units do not expose npcID directly. This works for timer spawning (one timer per in-combat WARRIOR) but creates cross-pack and cross-mob false positives when the same class appears in nameplates outside the intended pack.

**How to avoid:**
- Accept this limitation as a known constraint of the CLEU-disabled Midnight API; document it for users.
- Narrow the detection window: only trigger `UnitCastingInfo` highlights when `UnitAffectingCombat` is already true for the unit (the mob is actively in combat, not just nearby).
- Do not try to match npcID from nameplate units — it is not exposed. The classBase proxy is the best available signal.
- Add a debug log line (behind `ns.db.debug`) when a cast match fires, so users can identify false positives in edge cases.
- In the config UI, document per-ability that untimed highlights are class-based, not mob-specific.

**Warning signs:**
- Untimed highlight fires when no mobs from the active pack are visible.
- Highlight fires before the player has engaged the pack.
- Same highlight fires repeatedly when pulling unrelated packs of the same class.

**Phase to address:** Cast detection phase — document the constraint explicitly in ability data comments before shipping the feature.

---

### Pitfall 3: SavedVariables Schema Migration When Ability Data Structure Changes

**What goes wrong:**
The current schema saves processed pack data directly into `ns.db.importedRoute.packs` — the full resolved ability list. When v0.1.0 adds per-skill config (toggle tracking, custom label, TTS text, sound alert), this config must live alongside or keyed against the ability entries. If the ability data structure changes (new field added, field renamed, field removed) between addon versions, the saved config becomes partially invalid but not obviously so: old saves load without error because Lua tables tolerate extra or missing keys silently.

The dangerous failure mode: a user saves a per-skill toggle. A later patch renames the field. The toggle silently stops working. The user does not notice because no error fires.

Per-dungeon route storage (the new multi-route system) will also change `ns.db.importedRoute` from a single object to a keyed table by dungeon. Any code that reads the old single-route schema will silently get `nil` and behave as if no route is imported.

**Why it happens:**
WoW addon SavedVariables have no schema versioning built in. Developers add fields incrementally and assume backward compatibility. The flat-structure assumption breaks when the top-level shape changes (single route → keyed table).

**How to avoid:**
- Add a `schemaVersion` field to `TerriblePackWarningsDB` on first write. Increment it when the schema changes.
- On `ADDON_LOADED`, read `schemaVersion` and run a migration function if it is below current. Migration can be additive (add missing fields with defaults) or destructive (wipe and re-import if structure changed fundamentally).
- For the v0.1.0 migration specifically: detect the old single-route structure (`ns.db.importedRoute.packs` exists and `ns.db.importedRoutes` does not) and migrate by copying into the new per-dungeon keyed table.
- Per-skill config should be stored separately from the processed pack data: `ns.db.skillConfig[dungeonKey][npcID][spellID]` keyed by stable identifiers. If ability data changes, the config orphan does not corrupt anything — it is just unused until the ability reappears.
- Default all per-skill config values at access time via a helper function, never assume the key exists in SavedVariables.

**Warning signs:**
- After an addon update, per-skill settings silently reset to defaults.
- The pack selection window shows "No route imported" even though the user had a route saved.
- Lua errors on load referencing `importedRoute.packs` being nil after the schema change.

**Phase to address:** SavedVariables schema design phase — establish the `schemaVersion` field and the per-dungeon keyed structure before any per-skill config is written to disk.

---

### Pitfall 4: Per-Skill Config Table Grows Unboundedly as Dungeons Are Added

**What goes wrong:**
Per-skill config stored as `ns.db.skillConfig[dungeonKey][npcID][spellID]` with one entry per configured ability will grow to cover all 9 dungeons × ~15 mobs/dungeon × ~2 abilities/mob = ~270 entries if all skills are configured. This is manageable. The problem occurs when the user imports routes for all 9 dungeons and has previously configured abilities for dungeons whose routes are later cleared or replaced: the config entries for cleared dungeons accumulate as orphans with no corresponding pack data.

Over multiple seasons, if dungeon rosters change and npcIDs change, old config entries pile up silently. The SavedVariables file grows, and on each load, `RestoreFromSaved` must traverse stale entries.

**Why it happens:**
Developers write config at user action time but never prune config on route clear or dungeon deselect. The clear operation removes `ns.db.importedRoutes[dungeonKey]` but leaves `ns.db.skillConfig[dungeonKey]` intact.

**How to avoid:**
- Keep per-skill config entries small: only store non-default values. A per-skill entry that exactly matches the default should not be persisted.
- On route import (or explicit clear), prune orphaned config entries for that dungeon: remove `ns.db.skillConfig[dungeonKey]` when a route for that dungeon is cleared.
- Do not proactively create config entries on addon load — create them only when the user explicitly changes a setting from its default.
- Add a periodic audit (on `PLAYER_ENTERING_WORLD`) that removes config entries for npcIDs not present in any currently-imported route.

**Warning signs:**
- SavedVariables file (in `WTF/Account/.../SavedVariables/TerriblePackWarnings.lua`) grows larger than ~50KB for a normal user.
- Config values for abilities that no longer exist in any route appear when iterating `ns.db.skillConfig`.

**Phase to address:** Per-skill config storage phase — establish the sparse-default pattern before any config is written.

---

### Pitfall 5: Sound Alert Stacking When Multiple Mobs Cast the Same Ability Simultaneously

**What goes wrong:**
If three WARRIOR mobs each cast the tracked ability simultaneously, the pre-warning glow triggers three separate `TrySpeak` calls within the same 0.25s tick window. The current `TrySpeak` in `IconDisplay.lua` fires `C_VoiceChat.SpeakText` with `overlap = false`, which queues speech. Three queued TTS alerts for the same ability text play sequentially, producing a stutter ("Bolt Bolt Bolt") that is disorienting and takes 3-5 seconds to clear the queue.

Adding a WoW sound file alert (via `PlaySound`) in addition to TTS compounds this: both the sound and the TTS trigger per-mob, so at 5 mobs, 5 sounds plus 5 TTS queued messages fire within the same tick.

**Why it happens:**
The current timer system spawns one barId per mob (correct for per-mob cooldown tracking) and calls `SetUrgent` per barId independently. There is no deduplication at the alert layer. The design was correct for the single-mob case but was not designed for simultaneous multi-mob pre-warnings.

**How to avoid:**
- Implement a per-ability alert throttle: track the last time an alert (sound or TTS) fired for a given `spellID`. If the same `spellID` fired an alert within the last N seconds (recommend 3 seconds), suppress the duplicate.
- The throttle should be at the `spellID` level, not the `barId` level, so all instances of the same ability share one throttle bucket.
- For TTS specifically, `C_VoiceChat.SpeakText` with `overlap = false` (the current call) already prevents simultaneous overlap, but queued messages still play sequentially. Use `overlap = true` for the first call and then throttle subsequent calls so only one fires.
- For `PlaySound`, WoW's `PlaySound` call does not queue — it plays immediately and overlapping calls produce audio chaos. Throttling is mandatory at the addon level.
- Throttle table: `alertThrottle = {}` keyed by `spellID`, value = `GetTime()` of last alert. In `SetUrgent`, check `GetTime() - (alertThrottle[spellID] or 0) > THROTTLE_SECONDS` before firing.

**Warning signs:**
- TTS fires the same phrase 3+ times in quick succession on a pull with multiple mobs.
- Sound effects overlap during large pulls.
- Users report the TTS "stutters" or "repeats itself."

**Phase to address:** Sound alert phase — build throttle into `SetUrgent` at the same time the sound dropdown is added, before testing with multi-mob packs.

---

### Pitfall 6: Config UI Frame Pooling Failure With Large Mob/Skill Trees

**What goes wrong:**
The current `PackFrame.lua` creates pull row frames once and reuses them (the `rows` array). The config window will need a dungeon → mob → skill hierarchy. If this is implemented by creating one frame per skill entry without pooling, and the full 9-dungeon dataset has ~270 abilities, opening the config window creates 270+ frames simultaneously. WoW frame creation (`CreateFrame`) has a non-trivial cost per call; 270 frames on first open produces a visible hitch (200-400ms freeze) depending on hardware.

The secondary problem: if frames are created on open and not destroyed on close (hidden instead of destroyed), they remain allocated even when the config window is closed. Across a dungeon run with repeated opens/closes, the frame pool grows stale with frames referencing ability data that may no longer be relevant.

**Why it happens:**
The pull row pattern in `PackFrame.lua` shows the right approach: create rows lazily, grow as needed, hide unused rows. Developers port this to the config UI but omit the "hide unused" step for the skill level of the hierarchy, causing all 270 rows to show even when only one dungeon is expanded.

**How to avoid:**
- Implement a virtual scroll or accordion pattern: only create frames for the currently visible (expanded) section of the hierarchy. One dungeon expanded at a time limits visible frame count to ~15 mob rows × ~2 skill rows = ~30 frames maximum.
- Use the same lazy row creation pattern from `PackFrame.lua`: grow the frame pool as the user expands sections, never shrink it (hide unused rows instead of destroying them).
- Measure: if the full expanded tree (all dungeons, all mobs) stays under 50 frames, frame pooling is not needed. Only add complexity if the actual count warrants it.
- Cap the visible height of the config window to force scrolling rather than rendering all entries.

**Warning signs:**
- Opening the config window produces a visible freeze (>100ms hitch).
- Memory usage climbs with each open/close cycle of the config window.
- `/framestackxml` or WoW profiling shows frame count increasing over time.

**Phase to address:** Config UI phase — measure frame count for the target hierarchy before deciding whether virtual scroll is required.

---

### Pitfall 7: Per-Dungeon Route Migration — Old "imported" Key Breaks CombatWatcher

**What goes wrong:**
`CombatWatcher` and `Import.Pipeline` currently use `PackDatabase["imported"]` as the single route key and `ns.db.importedRoute` as the single saved route. Both are hardcoded strings throughout the code. Migrating to per-dungeon keys (`PackDatabase["windrunner_spire"]`, `PackDatabase["pit_of_saron"]`, etc.) requires changing every reference to these strings.

The dangerous failure mode during migration: `CombatWatcher:Reset()` checks `ns.PackDatabase["imported"]` explicitly to decide whether to reset to ready state. If the per-dungeon migration is done but `CombatWatcher:Reset()` is not updated, the condition never fires and the watcher stays in `idle` state even when a route is imported. No error is thrown.

Similarly, `PackFrame.lua` calls `ns.PackDatabase["imported"]` in `PopulateList()`. After migration, `PopulateList` will render an empty list even though routes exist under per-dungeon keys.

**Why it happens:**
String keys are scattered across 4 files (`Pipeline.lua`, `CombatWatcher.lua`, `PackFrame.lua`, `Import.lua`). A partial migration that updates the data layer but not all consumers creates a silent mismatch.

**How to avoid:**
- Introduce a constant or accessor function for the active dungeon key rather than using the string literal `"imported"` everywhere.
- When implementing multi-route storage, do a grep for `"imported"` and `importedRoute` across all files before shipping. There should be zero remaining literal references after migration.
- The migration must be atomic: all consumers updated in the same commit, not incrementally.
- The `CombatWatcher:Reset()` function specifically needs to iterate `ns.db.importedRoutes` (the new per-dungeon table) rather than checking the single-route key.

**Warning signs:**
- After migration, `/tpw status` shows `idle` even with an imported route.
- The pack selection window shows "No route imported" with data in `ns.db.importedRoutes`.
- Grep for `"imported"` still returns results in consumer files after migration.

**Phase to address:** Per-dungeon route storage phase — this migration must be treated as a cross-cutting refactor, not a localized change.

---

### Pitfall 8: MDT Ability Data Missing SpellIDs or Having Stale Ability Tables

**What goes wrong:**
MDT's `dungeonEnemies[dungeonIndex][enemyIdx].spells` table is keyed by spellID and the values are empty tables `{}` (confirmed in WindrunnerSpire.lua). This provides a list of spellIDs associated with a mob but no cast timing, no label, and no indication of whether the spell is meaningful (auto-attacks and passive procs appear alongside dangerous cast abilities).

When populating AbilityDB for 9 dungeons from MDT data, developers may assume the `spells` table contains useful structured data and write code that iterates it expecting fields that do not exist. The result is either silently empty ability entries or Lua errors from accessing nil fields on the empty table.

Additionally: MDT's dungeon data is periodically updated when Blizzard re-tunes dungeons. SpellIDs that existed in early Midnight may be replaced in a later patch. AbilityDB entries pointing to a removed spellID will produce a grey placeholder icon (because `C_Spell.GetSpellTexture` returns nil for invalid IDs) with no error, silently degrading the display.

**Why it happens:**
MDT's `spells` table is documentation of what a mob can do, not a structured ability database. It provides IDs only — timing, labels, and importance classification must come from TPW's own AbilityDB. Developers misread MDT as the source of truth for ability data structure.

**How to avoid:**
- Treat MDT's `spells` table as a spellID reference list only — used to verify that a spellID exists in the game, not as a source of ability data.
- The canonical ability data for each mob must be authored manually in `Data/*.lua` files (as WindrunnerSpire.lua already does). MDT cannot be automatically converted into useful AbilityDB entries.
- When adding spellIDs to AbilityDB, verify each spellID is valid by checking `C_Spell.GetSpellInfo(spellID)` in-game (or via the debug console) before committing the data.
- For the 8 remaining dungeons, plan time for manual data authoring, not automated MDT extraction. The MDT data tells you which mobs exist and their npcIDs — that is all.

**Warning signs:**
- Ability icons display as grey question-mark squares for specific dungeons.
- `C_Spell.GetSpellTexture` returns nil for spellIDs that were copied from MDT's `spells` table.
- `/tpw debug` shows "Icon texture for spellID X = nil" in the console.

**Phase to address:** Ability data population phase — establish the manual authoring workflow with a per-dungeon checklist before attempting all 9 dungeons.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Calling `UnitCastingInfo` per-nameplate without a spellID index | Simpler implementation | O(nameplates × abilities) inner loop; frame rate drops at 15+ mobs | Never — build the index at Start() time |
| Using `"imported"` literal string as PackDatabase key throughout codebase | Works for single-route | Full refactor needed to add per-dungeon routes | Never — use a constant or function |
| Storing full processed pack data per-skill in SavedVariables | Easier to restore | Orphaned entries pile up; SavedVariables bloats | Never — store only non-default overrides |
| No schemaVersion in TerriblePackWarningsDB | Simpler init | Silent corruption on schema change; users lose settings | Never for a shipped addon |
| Sound/TTS alert without per-spellID throttle | Simpler alert code | Audio stutter on multi-mob pulls; user experience degraded | Never once multi-mob packs are tested |
| Creating all config UI frames on window open | Simpler layout code | Visible hitch on first open if >50 frames | Acceptable only if total frame count stays under 50 |
| Copying MDT `spells` table directly to AbilityDB | Faster data authoring | Invalid spellIDs; empty timing data; silent display failures | Never — MDT data is an ID reference list only |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `UnitCastingInfo(npUnit)` | Calling without pcall; nameplate unit may become invalid between tick and call | Wrap in pcall as done for UnitAffectingCombat; check return for nil before using |
| `UnitCastingInfo` return values | Assuming index 1 is spellID | Signature: `name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)` — spellID is index 9, use `select(9, UnitCastingInfo(unit))` |
| `PlaySound(soundKitID)` | Calling with numeric literal IDs from online databases | IDs change between patches; prefer `SOUNDKIT.*` constants which are stable symbolic names |
| `C_VoiceChat.SpeakText` (TTS) with `overlap = false` | Not throttling at addon level; relying on overlap=false to prevent stacking | Queue still plays sequentially; throttle at spellID level before the call |
| SavedVariables multi-route migration | Incremental updates across multiple files | Treat as atomic refactor; verify all `"imported"` literals are removed in one pass |
| MDT `dungeonEnemies[idx].spells` | Iterating and using `spells[spellID]` sub-table fields | Sub-tables are always `{}`; extract only the spellID keys, provide all other data manually |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| O(nameplates × abilities) per tick for cast detection | Frame rate drops during large pulls | Build spellID index at Start(); make inner loop O(1) per nameplate | Noticeable at 10+ mobs with 5+ abilities each |
| Two overlapping C_Timer tickers (existing 0.25s + new cast detection) | Uneven CPU spikes; doubled nameplate API calls | Add cast detection to existing Tick(); never create a second ticker | Immediately at any mob count |
| `PlaySound` called per-mob per-tick without throttle | Audio chaos; WoW client sound channel saturation | Throttle at spellID level with GetTime() delta check | At 3+ mobs casting the same ability |
| Config UI recreating all frames on each Refresh() | Hitch on every Refresh call (called on every pack selection) | Create frames once, hide unused; Refresh only updates data fields | At 30+ visible config rows |
| Iterating all `ns.db.skillConfig` on every pack activation | Slow pack activation with large config tables | Index config by the keys used at access time; do not scan the full table | At 200+ total config entries (all 9 dungeons configured) |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Config window with no "Reset to defaults" per-skill | Users cannot undo accidental changes | Add a reset button per skill row; it should delete the SavedVariables entry for that skill |
| Dungeon selector shows all 9 dungeons even when no route imported for most | Confusing; clicking unimported dungeon produces no feedback | Disable/grey out dungeon tabs with no imported route; show import button inline |
| Per-skill toggle disables a skill but leaves its icon visible | Icon appears but does not warn; user confused | Hidden skills should have their icon removed from IconDisplay entirely |
| Sound dropdown with raw numeric SoundKit IDs | Meaningless to users | Use human-readable labels (e.g. "Raid Warning", "Quest Complete", "Alarm") mapped to SOUNDKIT constants |
| Auto-switch on zone-in overrides user's current pack selection | User manually selected a pack, zone change resets it | Only auto-switch if no active pack is selected, or if the user was in a different dungeon |
| Config window does not show which abilities are in-combat | Cannot distinguish active abilities from idle ones | Show a colored indicator dot on skill rows when that skill's timer or static icon is currently active |

---

## "Looks Done But Isn't" Checklist

- [ ] **Cast detection:** UnitCastingInfo returns a spellID — verify the spellID matches the `spellID` field in AbilityDB, not just the mob class. Verify it does not fire for mobs outside the active pack.
- [ ] **Per-skill config persistence:** Config survives `/reload ui`, logout, and addon update (schema migration path is exercised).
- [ ] **Sound throttle:** With 5 WARRIOR mobs in a pack, fire the pre-warning — verify only one TTS and one sound plays, not five.
- [ ] **Multi-route storage:** Import a route for Windrunner Spire, then import a route for Pit of Saron — verify both are stored and the first is not overwritten.
- [ ] **CombatWatcher after migration:** After per-dungeon route refactor, verify `/tpw status` shows `ready` (not `idle`) after importing a route.
- [ ] **Ability data for new dungeons:** Every npcID in AbilityDB has a valid spellID — verify by checking that `C_Spell.GetSpellTexture(spellID)` returns non-nil for all entries.
- [ ] **Config UI on Refresh:** Open config window, import a new route, verify config window updates without a freeze or duplicate rows.
- [ ] **Orphan cleanup:** Import a route, configure some skills, clear the route — verify `ns.db.skillConfig` entries for that dungeon are removed.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| UnitCastingInfo O(N×M) inner loop causing frame drops | MEDIUM | Add spellID index at Start() time; refactor Tick() to use it; straightforward but requires testing all detection paths |
| False positive cast detection across packs | LOW | Accept as known limitation; add debug logging and document in config UI tooltip |
| SavedVariables schema corruption after migration | MEDIUM | Add schemaVersion check on load; provide wipe-and-reimport path as escape hatch |
| Orphaned config entries bloating SavedVariables | LOW | One-time cleanup function on ADDON_LOADED; run once, remove when all users are migrated |
| Sound stacking discovered after shipping | LOW | Add throttle table to SetUrgent; 10-line change; ship as hotfix |
| Config UI hitch on open | LOW to MEDIUM | Profile frame count; if >50, convert to accordion/virtual-scroll; pre-existing row pool pattern makes this straightforward |
| Multi-route migration breaking CombatWatcher | MEDIUM | Grep all files for "imported" literal; fix all consumers; verify with /tpw status test |
| Invalid MDT spellIDs in AbilityDB | LOW | Audit each spellID in-game via /dump C_Spell.GetSpellInfo(id); replace invalid IDs; no structural refactor needed |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| UnitCastingInfo O(N×M) performance | Cast detection phase: build spellID index before first use | Profile Tick() duration during a 10-mob pull with untimed detection active |
| UnitCastingInfo false positives | Cast detection phase: document constraint in code and config UI | Pull a pack of WARRIORs with a WARRIOR mob from a different group in range; verify no spurious highlight |
| SavedVariables schema migration | Per-dungeon route storage phase: establish schemaVersion before writing any new fields | Import a route on old schema; update addon; verify route survives and new schema fields initialize correctly |
| Per-skill config bloat | Per-skill config storage phase: implement sparse-default pattern from the start | After configuring and clearing routes repeatedly, verify SavedVariables file size stays bounded |
| Sound alert stacking | Sound alert phase: add throttle table to SetUrgent alongside the PlaySound call | Pull 5 mobs with the same tracked untimed ability; verify single TTS and single sound per pre-warning window |
| Config UI frame hitch | Config UI phase: count maximum frame count before choosing pattern | Open config with all 9 dungeons data loaded; measure open time; must be under 100ms |
| Per-dungeon route migration breaking CombatWatcher | Per-dungeon route storage phase: atomic refactor with grep verification | After migration, verify /tpw status shows ready; verify PackDatabase contains no "imported" key |
| MDT ability data gaps | Ability data population phase: manual authoring workflow with in-game spellID verification | All icons render with non-grey textures; zero "Icon texture = nil" in debug log |

---

## Sources

- `Engine/NameplateScanner.lua` (this repo) — existing tick cost analysis in source comments; plateCache pattern
- `Engine/Scheduler.lua` (this repo) — barId per-mob tracking pattern; combatActive table; timer handle tracking
- `Display/IconDisplay.lua` (this repo) — TrySpeak implementation; SetUrgent call site; no current per-spellID throttle
- `Import/Pipeline.lua` (this repo) — "imported" literal usage; single-route schema; SavedVariables layout
- `UI/PackFrame.lua` (this repo) — lazy row creation pattern; Refresh() call frequency
- `wow-ui-source/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/CastingBarFrame.lua` — UnitCastingInfo return signature confirmed: `name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID`
- `wow-ui-source/Interface/AddOns/Blizzard_NamePlates/Blizzard_ClassNameplateBar.lua` — `select(9, UnitCastingInfo(unit))` pattern for spellID extraction
- `MythicDungeonTools/Midnight/WindrunnerSpire.lua` — MDT `spells` table structure confirmed as `[spellID] = {}` (empty tables); no timing or label data

---

## Retained Pitfalls From Initial Research (Still Applicable)

The following pitfalls from the v0.0.x research remain relevant for this milestone. They are not repeated in full above but should be carried forward to any phase checklist:

- **Restricted API calls in Mythic+** — Do not add any UnitHealth, UnitAura, UnitBuff, or combat-state API calls when building the config UI or cast detection.
- **Timer state not reset on zone change** — Any new per-dungeon timer state must also be cleared in `CombatWatcher:Reset()` and on `PLAYER_ENTERING_WORLD`.
- **Global namespace pollution** — All new config and cast detection state must live inside `ns.*` or local scope. No new globals.
- **C_Timer handle tracking** — Any new timers added for untimed highlight expiry or debounce must be tracked for cancellation.

---
*Pitfalls research for: WoW Midnight dungeon pack warning addon (TerriblePackWarnings) — v0.1.0 Configuration and Skill Data milestone*
*Researched: 2026-03-17*
