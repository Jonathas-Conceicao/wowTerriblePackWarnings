# TerriblePackWarnings

WoW Midnight addon (version 12.0 and up) for showing dungeon trash pack ability warnings in Mythic+.

## Key Constraints
- `COMBAT_LOG_EVENT_UNFILTERED` is disabled in Midnight — do NOT use it
- Most buff/debuff values are hidden as "Secret Values" in Midnight
- Nameplate scanning (`C_NamePlate.GetNamePlates`, `UnitClass`, `UnitAffectingCombat`) works for mob detection
- `UnitCanAttack` and `UnitClass` are stable per mob — cache them at `NAME_PLATE_UNIT_ADDED`, only poll `UnitAffectingCombat` in the hot loop
- Ability timers are predefined (not derived from cast detection) since cast events are unreliable
- MDT export strings decoded via LibDeflate + AceSerializer (bundled via LibStub)

## Architecture
- `Core.lua` — namespace, init, event routing, slash commands
- `Engine/Scheduler.lua` — timer scheduling with per-barId tracking and repeating cycles
- `Engine/NameplateScanner.lua` — 0.25s nameplate poll loop, mob class detection, per-mob timer spawning
- `Engine/CombatWatcher.lua` — combat state machine (idle/ready/active/end), auto-advance, zone reset
- `Display/IconDisplay.lua` — spell icon squares with cooldown sweep, red glow, TTS, labels, tooltips
- `Import/Decode.lua` — MDT export string decoder (LibDeflate + AceSerializer chain)
- `Import/Pipeline.lua` — decoded MDT preset → pull extraction → AbilityDB matching → PackDatabase population
- `Import/Profile.lua` — profile management (create/delete/switch, encode/decode profile strings)
- `Data/WindrunnerSpire.lua` — npcID-keyed ability database for Windrunner Spire mobs (one of 8 dungeon data files)
- `Data/DungeonEnemies.lua` — MDT enemy reference data for all 9 Midnight S1 dungeons (npcID, name, displayId, isBoss)
- `UI/PackFrame.lua` — pack selection window with pull rows, NPC portraits, import popup, clear confirmation
- `UI/ConfigFrame.lua` — per-skill configuration window with dungeon-mob tree, profiles, search
- `scripts/install.bat` — copies addon to WoW retail addons folder
- `scripts/release.bat` — tags and pushes a release (GitHub Actions handles packaging)
- `.github/workflows/release.yml` — BigWigs Packager action for CurseForge/Wago/GitHub releases
- `.pkgmeta` — BigWigs Packager config with externals and ignore list

## Source References
- Blizzard UI source: `C:\Users\jonat\Repositories\wow-ui-source` (https://github.com/Gethe/wow-ui-source)
- MythicDungeonTools: `C:\Users\jonat\Repositories\MythicDungeonTools` — MDT data structures, decode chain, portrait rendering patterns
- TerribleBuffTracker: `C:\Users\jonat\Repositories\TerribleBuffTracker` — sibling addon, style reference for README/TOC/CI patterns
- WeakerScripts: `C:\Users\jonat\Repositories\WeakerScripts` — nameplate scanning reference (`Samples/NameplateSummary.lua`)

## Patterns
- Namespace: `local addonName, ns = ...` shared across all files
- SavedVariables: `TerriblePackWarningsDB` (account-wide) — stores profiles, imported routes, combat mode, window position, debug flag
- Debug logging: `ns.db.debug` toggle via `/tpw debug`, all status prints guarded behind this flag
- Ability data keyed by npcID, runtime detection by UnitClass (nameplate scanning)
- PackDatabase[dungeonKey] holds per-dungeon pack arrays
- Nameplate cache (`plateCache`) populated at events, only `UnitAffectingCombat` polled in hot loop
- Addon icon: `tpw_64x64.blp` (BLP format required by WoW, PNG kept as source)

## Testing
- Deploy to WoW with `./scripts/install.bat`
- `/tpw` — toggle pack selection window
- `/tpw debug` — toggle debug logging
- `/tpw status` — print current state
- Import: open TPW window → Import button → paste MDT string → click Import
- Test combat: pull mobs in Windrunner Spire with an imported route active

## Workflow
- Release with `./scripts/release.bat <version>` — tags and pushes; GitHub Actions builds and uploads
- CHANGELOG.md: add new version section at the top before releasing; CI extracts it for release notes
- Run `./scripts/install.bat` to deploy locally (use `./` prefix, not `cmd.exe /c`)

## GSD Workflow
- Start each new milestone on a dedicated branch
- Merge to main by squashing with a clean commit message summarizing all changes
- Always run a cleanup phase at the end of new milestones: clean up unused variables, definitions, unify repeated behavior into shared functions, review hot paths (especially game loop tick functions), and check release scripts
