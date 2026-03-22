---
status: diagnosed
phase: 14-ability-data-foundation
source: [14-01-SUMMARY.md, 14-02-SUMMARY.md]
started: 2026-03-17T09:00:00Z
updated: 2026-03-20T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Config window shows all 9 dungeons
expected: Open config window (/tpw config). Left panel lists all 9 Midnight S1 dungeons as collapsible headers.
result: pass

### 2. New dungeon mob list expands correctly
expected: Expand a populated dungeon (e.g., Algethar Academy). Mob list shows NPC portraits + names. No duplicate mobs.
result: pass

### 3. New dungeon abilities show as unchecked by default
expected: Click a mob from a new dungeon. Right panel shows abilities with checkboxes UNCHECKED by default.
result: pass

### 4. WindrunnerSpire existing abilities remain checked
expected: Expand Windrunner Spire, click Nerubian Spellguard. Original hand-authored abilities show CHECKED. New MDT-added abilities show UNCHECKED.
result: pass

### 5. Spell icons and names resolve dynamically
expected: Ability rows show spell icons (not grey) and spell names (not blank). Names come from C_Spell.GetSpellInfo.
result: issue
reported: "Most skills have icons but one on Crawth (Algethar Academy) is fully grey. Most skills don't have names — only hand-authored ones do. Need to resolve names and icons dynamically via C_Spell.GetSpellInfo. Also missing Seat of the Triumvirate and Magisters' Terrace dungeon data — should extract from MDT."
severity: major

### 6. Enabling a new ability works
expected: Check an unchecked ability, re-import route, ability icon appears on display when mob is in pull.
result: issue
reported: "Enabled the skill, pulled a pack and skill didn't show. No context for the reason it didn't work."
severity: major

### 7. Stub dungeons show correctly
expected: Stub dungeons show no mobs or don't appear in config tree.
result: issue
reported: "Dungeons were hidden due to no AbilityDB entries — should show empty to avoid confusion. Murder Row is NOT a Season 1 dungeon and should be removed entirely. Re-read MDT repo for updated Magisters Terrace and Seat of the Triumvirate data."
severity: major

### 8. No Lua errors on load
expected: After /reload, no Lua errors. Addon loads cleanly.
result: pass

## Summary

total: 8
passed: 5
issues: 3
pending: 0
skipped: 0

## Gaps

- truth: "Spell icons and names resolve dynamically for all abilities"
  status: diagnosed
  reason: "User reported: Most skills have icons but Crawth has grey icon. Most skills don't have names. Need C_Spell.GetSpellInfo dynamic resolution. Missing Seat of the Triumvirate and Magisters Terrace data from MDT."
  severity: major
  test: 5
  root_cause: |
    Two distinct problems in UI/ConfigFrame.lua PopulateRightPanel:

    1. Ability names: Line 378 sets `abilityName:SetText(ability.name or "")`. All Phase 14 Data/*.lua entries
       (e.g., AlgetharAcademy.lua) are authored with only `{ spellID = ..., defaultEnabled = false }` — no
       `name` field is present. The only entries with names are hand-authored WindrunnerSpire.lua entries.
       There is no fallback call to C_Spell.GetSpellInfo(ability.spellID) anywhere in ConfigFrame.lua.

    2. Spell icon (grey for Crawth spellID 181089): Line 362 calls `C_Spell.GetSpellTexture(ability.spellID)`
       with no fallback beyond `SetColorTexture(0.2, 0.2, 0.2, 1)` (grey). If C_Spell.GetSpellTexture returns
       nil for a given spellID (possibly because it is not cached client-side or the spell does not exist),
       the grey fallback fires. No attempt is made to use C_Spell.GetSpellInfo which returns a texture field
       as part of its result table, nor is there any deferred/async resolution.

    Fix: In PopulateRightPanel, replace `ability.name or ""` with a helper that calls
    `C_Spell.GetSpellInfo(ability.spellID)` and extracts `.name` if `ability.name` is nil.
    Replace the bare `C_Spell.GetSpellTexture` call with a helper that tries GetSpellTexture first,
    then falls back to the `.iconID` field of C_Spell.GetSpellInfo, then to the grey color.
    Also update the TTS default text (line 496: `ability.ttsMessage or ability.name or ""`) with the
    same dynamic lookup so TTS text also resolves correctly for spells without hand-authored names.
  artifacts:
    - "UI/ConfigFrame.lua:362 — C_Spell.GetSpellTexture with no dynamic fallback"
    - "UI/ConfigFrame.lua:378 — ability.name with no C_Spell.GetSpellInfo fallback"
    - "UI/ConfigFrame.lua:496 — TTS default falls back to ability.name which is nil for new spells"
    - "Data/AlgetharAcademy.lua — example: all entries have only spellID + defaultEnabled, no name field"
  missing:
    - "Helper function: GetSpellNameSafe(spellID) -> string (C_Spell.GetSpellInfo fallback)"
    - "Helper function: GetSpellIconSafe(spellID) -> texture (GetSpellTexture -> GetSpellInfo.iconID -> grey)"
  debug_session: ""

- truth: "Enabling a defaultEnabled=false ability via config checkbox makes it appear on display"
  status: diagnosed
  reason: "User reported: enabled the skill, pulled a pack and skill didn't show, no context for the reason"
  severity: major
  test: 6
  root_cause: |
    The flow has two separate paths that do not share the same rebuild step:

    Path A (working): Checkbox OnClick (ConfigFrame.lua:344-352) writes
    `ns.db.skillConfig[npcID][spellID].enabled = nil` (checked) or `false` (unchecked).
    Then the user re-imports via the Import button. Import.RunFromString -> RunFromPreset -> BuildPack
    calls MergeSkillConfig which reads skillConfig correctly. The rebuilt pack is stored in
    ns.PackDatabase["imported"] and also serialized into ns.db.importedRoute.packs.

    Path B (broken): Import.RestoreFromSaved (Pipeline.lua:186-196) restores
    `ns.PackDatabase["imported"] = saved.packs` DIRECTLY from the serialized ns.db.importedRoute.packs
    that were saved at the time of the last import. If the user checks an ability and then triggers a
    restore (e.g., /reload or re-login without re-importing), the restored packs still reflect the old
    skillConfig state because RestoreFromSaved does NOT call BuildPack — it just copies the stale
    serialized packs.

    However the user said they DID re-import. In that case the actual bug is:
    MergeSkillConfig (Pipeline.lua:32-44) checks `if ability.defaultEnabled == false then return nil`
    when cfg is nil. When the user checks the checkbox, the handler sets `cfg.enabled = nil` (line 348),
    which means the key `enabled` is absent. On re-import, MergeSkillConfig reads cfg (which now exists
    as an empty table `{}`), so it passes the `if not cfg` guard. Then line 46 checks
    `if cfg.enabled == false` — this is false because cfg.enabled is nil. So the ability IS included.
    The pack is rebuilt correctly.

    The remaining suspect is NameplateScanner.lua: Scanner:OnMobsAdded (line 62) iterates
    `activePack.abilities` and matches on `ability.mobClass == classBase`. If the new ability's
    `mobClass` in the merged table does not match the class string returned by `UnitClass()` for
    that mob's nameplate, the ability is silently skipped. All Phase 14 data files hard-code
    `mobClass = "WARRIOR"` as a placeholder regardless of actual mob class. If the actual
    `UnitClass()` for that nameplate returns a different class token (e.g., the mob's true class
    in Midnight), there is a mismatch and the ability never fires. This is the most likely cause
    for the ability not appearing on display after re-import: the placeholder `mobClass = "WARRIOR"`
    does not match the actual class token for that mob on the nameplate.

    Secondary cause: RestoreFromSaved does not rebuild packs from current skillConfig — it replays
    stale serialized data. If the user enables an ability, saves (without re-importing), then
    reloads, the ability will still be absent because the saved packs predate the checkbox change.
  artifacts:
    - "Import/Pipeline.lua:28-57 — MergeSkillConfig reads cfg.enabled == false correctly"
    - "Import/Pipeline.lua:186-196 — RestoreFromSaved copies stale packs, does not call BuildPack"
    - "Engine/NameplateScanner.lua:62-83 — OnMobsAdded filters on ability.mobClass == classBase"
    - "Data/AlgetharAcademy.lua — all entries have mobClass = 'WARRIOR' (placeholder)"
  missing:
    - "Correct mobClass values for all new dungeon mobs (requires in-game UnitClass() verification or research)"
    - "RestoreFromSaved should rebuild packs via BuildPack rather than copying serialized data, so skillConfig changes take effect after /reload"
  debug_session: ""

- truth: "All S1 dungeons visible in config tree even if no ability data exists"
  status: diagnosed
  reason: "User reported: dungeons hidden due to no AbilityDB entries — should show empty. Murder Row not S1, remove it. Re-read MDT for Magisters Terrace and Seat of the Triumvirate updates."
  severity: major
  test: 7
  root_cause: |
    1. Empty dungeons hidden: BuildDungeonIndex (ConfigFrame.lua:207-235) builds its mob list by
       iterating ns.DungeonEnemies[dungeonIdx] and including only entries where `ns.AbilityDB[enemy.id]`
       exists (line 216). Then line 222 `if #mobs > 0` gates the entire dungeon entry — dungeons with
       enemy data in DungeonEnemies but no matching AbilityDB entries produce an empty mobs list and
       are silently dropped. Dungeons that have AbilityDB stub files with `defaultEnabled = false` only
       (e.g., AlgetharAcademy) DO appear because their npcIDs are present in AbilityDB. But any dungeon
       whose DungeonEnemies rows have no AbilityDB entries whatsoever will not appear.
       Fix: Remove the `if #mobs > 0` guard and allow dungeons to appear with an empty mob list.
       The right panel already handles the "No ability data for NPC" case (line 274); a dungeon header
       with no mobs just expands to show nothing, which is acceptable.

    2. Murder Row is NOT Season 1: MythicDungeonTools/Midnight/MurderRow.lua (dungeonIndex = 160)
       shows `mapID = 12345 -- FIXME`, `teleportId = 1216786 -- FIXME`, `zones = { 2214, 2387, 2388 } -- FIXME`,
       and `dungeonEnemies[160] = {}` — it is a placeholder stub with no real data. It should not be in
       DUNGEON_IDX_MAP. Import/Pipeline.lua:16 has `[160] = { key = "murder_row", name = "Murder Row" }`.
       Data/MurderRow.lua exists but only contains the empty table comment.
       Fix: Remove index 160 from DUNGEON_IDX_MAP in Pipeline.lua. Remove Data/MurderRow.lua and its
       TOC entry.

    3. Magisters Terrace (dungeonIndex = 153): MDT file confirms dungeonIndex = 153, mapID = 558,
       zones = {2511, 2515, 2516, 2517, 2518, 2519, 2520}. This is a valid S1 dungeon with real
       enemy data starting at line 59. DungeonEnemies and AbilityDB stub already exist (Phase 14).

    4. Seat of the Triumvirate (dungeonIndex = 11): MDT file confirms dungeonIndex = 11, mapID = 239,
       zones = {2097, 2098, 2099}. Real enemy data present (first entry: Merciless Subjugator id=124171).
       DungeonEnemies and AbilityDB stub already exist. No changes needed to these two dungeons' index
       entries — they are correctly mapped.
  artifacts:
    - "UI/ConfigFrame.lua:222 — if #mobs > 0 guard that hides empty dungeons"
    - "UI/ConfigFrame.lua:216 — mob filter requires ns.AbilityDB[enemy.id] to exist"
    - "Import/Pipeline.lua:16 — Murder Row entry [160] in DUNGEON_IDX_MAP"
    - "Data/MurderRow.lua — empty stub file that should be removed"
    - "MythicDungeonTools/Midnight/MurderRow.lua:10-12 — FIXME placeholders confirm non-S1 status"
    - "MythicDungeonTools/Midnight/MagistersTerrace.lua:4 — dungeonIndex = 153 confirmed valid"
    - "MythicDungeonTools/Midnight/SeatoftheTriumvirate.lua:4 — dungeonIndex = 11 confirmed valid"
  missing:
    - "Remove [160] Murder Row from DUNGEON_IDX_MAP in Pipeline.lua"
    - "Remove Data/MurderRow.lua and its TOC entry"
    - "Update BuildDungeonIndex to show empty dungeons (remove the #mobs > 0 guard)"
    - "Optionally show '(no abilities)' label in mob list when mobs list is empty"
  debug_session: ""
