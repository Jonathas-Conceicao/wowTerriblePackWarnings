# Phase 13: Configuration UI and Pack Polish - Context

**Gathered:** 2026-03-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Config window for browsing dungeon→mob→skill hierarchy with per-skill settings (toggle, label, sound/TTS alert), plus mob count display in pull rows. Validated against WindrunnerSpire's existing 4 abilities. No new dungeon data, no cast detection, no per-dungeon route storage — those are Phases 14-16.

</domain>

<decisions>
## Implementation Decisions

### Config Window Layout
- Separate window from TPW pack frame — own position, sizing, movable
- Opens via `/tpw config` slash command and/or a button on the pack window
- Wide rectangular frame (wider than pack window)
- Left panel: scrollable dungeon→mob tree
- Right panel: selected mob's details and per-skill settings

### Left Panel — Dungeon/Mob Tree
- Dungeon names as collapsible headers (▼ expanded / ► collapsed)
- Click header to toggle expand/collapse
- Mob rows underneath each dungeon: round NPC portrait + mob name (same portrait style as PackFrame.lua)
- Click a mob row to load its skills on the right panel
- Mobs are deduplicated per dungeon (each unique npcID appears once)

### Right Panel — Mob Details
- Header: mob name + class (e.g. "Nerubian Spellguard — PALADIN")
- Scrollable list of abilities for that mob

### Per-Skill Settings
- **Enabled checkbox**: toggle tracking on/off (global, not per-route)
- **Label field**: editable, defaults to current label from AbilityDB, empty allowed
- **Timing info**: read-only display ("First cast: 50s, Cooldown: 50s") shown only for timed abilities
- **Sound dropdown**: single dropdown, first option is "TTS" (default), followed by WoW built-in sounds organized by CDM categories. Preview sound on selection.
- **TTS text field**: editable when "TTS" selected in dropdown, defaults to spell name. Grayed out and non-editable when a sound file is selected.
- **Spell tooltip**: hovering the skill row (or a (?) icon) shows WoW spell tooltip via GameTooltip:SetSpellByID()
- **Reset button**: per-skill reset clears all custom overrides back to defaults
- **Reset All button**: per-dungeon, resets all skills for that dungeon

### Alert Model
- Single dropdown controls alert type: "TTS" or a specific WoW sound
- Default for unconfigured skills: TTS with spell name as text
- Sound and TTS are mutually exclusive — dropdown selection determines which is active
- TTS text field state follows dropdown: enabled for "TTS", disabled/grayed for any sound

### Mob Count Display (Pull Rows)
- Pull rows in pack window show count per mob type (e.g. "3x Spellguard")
- Claude's discretion on exact visual approach (text overlay on portraits vs separate label)
- Must be visually clear at a glance for route navigation

### Claude's Discretion
- Exact window dimensions and proportions
- ScrollFrame implementation details for both panels
- Mob count visual approach (overlay vs label — MDT uses "x"..quantity on portraits)
- SavedVariables schema for skillConfig (sparse overrides recommended per research)
- How the config button integrates with the pack window (if added)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing UI Pattern
- `UI/PackFrame.lua` — ScrollFrame + ScrollChild pattern, NPC portrait rendering (GetPortraitTexture), circular mask, boss detection, pull row creation
- `Display/IconDisplay.lua` — GameTooltip:SetSpellByID() pattern for spell tooltips, CreateIconSlot for spell icon rendering

### Data Schema
- `Data/WindrunnerSpire.lua` — AbilityDB schema (npcID → { mobClass, abilities = [{name, spellID, first_cast, cooldown, label, ttsMessage}] })
- `Import/Pipeline.lua` — DUNGEON_IDX_MAP (dungeonIdx → key/name), BuildPack ability merging, PackDatabase structure

### Sound Alert Reference
- `.planning/research/FEATURES.md` — CDM soundKitID catalog (67 sounds, 6 categories), PlaySound API usage
- `.planning/research/STACK.md` — CDM dropdown build pattern (BuildSoundMenus), ScrollFrame config UI pattern

### Architecture
- `.planning/research/ARCHITECTURE.md` — skillConfig schema design, ConfigFrame placement, integration points

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PackFrame.lua` ScrollFrame + UIPanelScrollFrameTemplate: same pattern for config window scroll panels
- `PackFrame.lua` GetPortraitTexture(): NPC portrait with displayId → class icon → question mark fallback
- `PackFrame.lua` npcIdToDisplayId / npcIdToClass lookups: reuse for config mob display
- `IconDisplay.lua` GameTooltip:SetSpellByID(): exact pattern needed for skill tooltip in config
- `IconDisplay.lua` C_Spell.GetSpellTexture(): resolve spell icons for display in config

### Established Patterns
- Namespace: `local addonName, ns = ...` shared across all files
- SavedVariables: `ns.db = TerriblePackWarningsDB` initialized in Core.lua ADDON_LOADED
- Frame templates: BasicFrameTemplateWithInset for windows, GameMenuButtonTemplate for buttons
- UISpecialFrames for Escape-to-close behavior

### Integration Points
- `Core.lua` slash command handler: add `/tpw config` command
- `Core.lua` ADDON_LOADED: initialize skillConfig defaults in SavedVariables
- `Import/Pipeline.lua` BuildPack(): must respect skillConfig enabled/disabled state when building pack abilities
- `UI/PackFrame.lua` PopulateList(): add mob count display to pull rows, add config button if desired

</code_context>

<specifics>
## Specific Ideas

- ASCII mockup approved: left panel with collapsible dungeon headers + portrait mob rows, right panel with mob header + scrollable ability cards
- Sound dropdown: "TTS" as first/default option, then CDM-categorized WoW sounds below
- TTS text field visually disabled (grayed) when sound is selected — clear visual state coupling
- Both per-skill and per-dungeon reset buttons

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 13-configuration-ui-and-pack-polish*
*Context gathered: 2026-03-17*
