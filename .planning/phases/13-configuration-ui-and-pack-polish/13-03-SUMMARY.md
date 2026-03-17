# Plan 13-03 Summary

**Status:** Complete
**Tasks:** 3/3 (2 auto + 1 human-verify checkpoint)

## What was built

### Task 1: ConfigFrame left panel (dungeon-mob tree)
- Created `UI/ConfigFrame.lua` (lazy construction on first Toggle)
- Left panel with collapsible dungeon headers `[+]/[-]` and deduplicated mob rows
- NPC portraits with circular mask + mob names, indented under headers
- Alternating row colors for mobs and dungeon headers
- Left-aligned header text

### Task 2: Right panel per-skill settings
- Enabled checkbox (UICheckButtonTemplate, visible)
- Large spell icon (44px) with ability name
- Read-only timing info for timed abilities
- Label EditBox with pushed-in background
- Sound dropdown (Button + popup) with CDM sounds, preview on select
- TTS EditBox with Play button (disabled when sound selected)
- Reset per-skill and Reset All per-dungeon buttons
- Spell tooltip on hover via GameTooltip:SetSpellByID

### Task 3: Human verification — APPROVED
All 17 test steps passed in-game.

## Additional features (from UAT feedback)
- Portrait click in Route window opens Config to that mob (out of combat)
- Pack window title renamed to "TerriblePackWarnings - Route"
- `ns.ConfigUI.OpenToMob(npcID, dungeonIdx)` API

## Commits
- `5b20cac` feat(13-03): create ConfigFrame with lazy window, dungeon-mob tree, right panel stub
- `de79a60` feat(13-03): implement right panel per-skill settings in ConfigFrame
- `bdc2aa2` fix(13-03): address in-game UI feedback (checkbox, icon size, layout, editbox backgrounds)
- `36be5d1` feat(13-03): left-align dungeon headers, mob click opens config, rename title
- `f3aa35f` fix(13-03): move header font string alignment after SetText

## Requirements covered
- CFG-01: Config window with left panel dungeon/mob tree
- CFG-02: Right panel with per-skill settings
- CFG-03: Toggle tracking on/off via checkbox
- CFG-04: Custom label per skill
- CFG-05: Spell tooltip on hover
