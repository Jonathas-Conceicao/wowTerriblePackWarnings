# Phase 18: Profiles and Skill Config Rework - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Rework skill config: all skills default blank/unchecked/untimed. Add timed/untimed toggle with first_cast and cooldown number inputs. Add per-skill sound alert checkbox. Account-wide profile system with create/delete/import/export. Widen config window to fit profile controls.

</domain>

<decisions>
## Implementation Decisions

### Skill Defaults and Data File Changes
- All skills default to: unchecked, untimed, empty timer fields, no label — completely blank
- Erase timing data (first_cast, cooldown) and labels from all Data/*.lua files — profiles set these now
- mobClass stays in Data files — NOT user-editable, fixed per mob
- TTS defaults to spell name (resolved dynamically via C_Spell.GetSpellInfo) — user can override in profile
- `defaultEnabled = false` remains on all MDT-imported abilities (unchecked by default)
- Existing WindrunnerSpire hand-authored timing/labels/ttsMessage removed from Data file

### Per-Skill Timer UI
- Timed/untimed toggle checkbox per skill
- When timed is checked: two number input fields appear — "First Cast" and "Cooldown" (in seconds)
- When untimed: fields visible but grayed out (indicates they exist but do nothing)
- Fields have NO default values (empty when untimed or newly enabled)
- Validation: positive numbers only, max 1200 seconds (20 minutes), numeric characters only
- On blur/close: if value exceeds 1200, clamp to 1200

### Per-Skill Sound Alert Checkbox (PROF-07)
- Separate checkbox from skill enable/disable — two independent checkboxes
- Skill tracking checkbox: controls whether icon shows on display
- Sound alert checkbox: controls whether sound/TTS fires on trigger
- Can track a skill visually without sound, or have sound without tracking (edge case but allowed)
- Untimed skills: sound fires on class cast detection state transition (no-glow → glow)
- Timed skills: sound fires at 5s pre-warning (SetUrgent)

### Profile System Behavior
- Profiles store: per-skill enable/disable, timed toggle, first_cast, cooldown, label, sound/TTS selection, sound alert checkbox
- Profiles do NOT store: routes, combat mode, window positions, debug state
- Switching profiles rebuilds pack abilities from new profile's skill config (automatic, packs re-merge)
- Default profile is always blank (all skills unchecked/untimed)
- Fixed naming: "Default", "Profile 1", "Profile 2", etc. — no renaming
- Profiles are account-wide (stored in SavedVariables)
- Delete button disabled for Default profile
- Maximum profile count: Claude's discretion (suggest 10-20)

### Profile Import/Export
- Reuse LibDeflate + AceSerializer (already bundled) — same encode/decode chain as MDT import
- Serialize profile skill config table, compress, base64 — produces compact shareable string
- Import always creates a NEW profile (never overwrites existing) and auto-selects it as active
- Export serializes the currently active profile
- Import/Export use the same paste popup pattern as MDT route import

### Profile UI in Config Window
- Widen config window (from 580px to ~700px or more) to fit profile controls
- Single top bar row: [Route] [Reset All] [Default ▼] [New] [Del] [Imp] [Exp]  ...  [Search]
- Profile dropdown shows current profile name with ▼ indicator
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Skill Config System
- `UI/ConfigFrame.lua` — PopulateRightPanel, per-skill checkbox/label/sound/TTS widgets, AddEditBoxBackground, top bar layout
- `Import/Pipeline.lua` — MergeSkillConfig reads ns.db.skillConfig, BuildPack merges abilities

### Data Files to Modify
- `Data/WindrunnerSpire.lua` — Has hand-authored timing/labels to erase (keep mobClass + spellID only)
- All other `Data/*.lua` files — Already have spellID + defaultEnabled only (no changes needed)

### Import/Export Libraries
- `Import/Decode.lua` — LibDeflate + AceSerializer decode chain (reusable for profile encode/decode)
- `Libs/` — LibDeflate, AceSerializer, LibStub already bundled

### SavedVariables
- `Core.lua` — ADDON_LOADED handler initializes ns.db fields, schema migration pattern

### Display System
- `Display/IconDisplay.lua` — SetUrgent (timed pre-warning), SetCastHighlight (untimed cast detection)
- `Engine/NameplateScanner.lua` — OnMobsAdded uses pack.abilities for icon creation
- `Engine/Scheduler.lua` — scheduleAbility reads first_cast/cooldown from ability table

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ConfigFrame.lua` AddEditBoxBackground — pushed-in style for timer input fields
- `ConfigFrame.lua` sound popup pattern — reusable for profile dropdown
- `Import/Decode.lua` MDTDecode chain — reusable in reverse for profile export (encode)
- `PackFrame.lua` import popup — same paste popup pattern for profile import

### Established Patterns
- `ns.db.skillConfig[npcID][spellID]` — existing per-skill override storage
- `MergeSkillConfig` — already respects cfg.enabled, cfg.label, cfg.ttsMessage, cfg.soundKitID
- Schema migration via `ns.db.schemaVersion` in Core.lua ADDON_LOADED

### Integration Points
- `Core.lua` ADDON_LOADED — initialize profiles, migrate schema, set active profile
- `ConfigFrame.lua` PopulateRightPanel — add timed toggle + timer fields + sound alert checkbox
- `Pipeline.lua` MergeSkillConfig — read from active profile instead of flat skillConfig
- `Pipeline.lua` RestoreAllFromSaved — rebuild packs after profile switch

</code_context>

<specifics>
## Specific Ideas

- ASCII mockup approved: top bar with [Route] [Reset All] [Default ▼] [New] [Del] [Imp] [Exp] ... [Search]
- Profile dropdown works like the dungeon dropdown — click button, popup list appears
- Timer fields feel like the existing label/TTS edit boxes — pushed-in background, numeric only
- Widen window so controls don't feel cramped

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 18-profiles-and-skill-config-rework*
*Context gathered: 2026-03-21*
