# Phase 17: Command Rework and Config Search - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

UX polish: rework slash commands so /tpw opens config, add search box to config window for filtering mobs and skills, remove config button from route window, add route button to config window, reposition Reset All with confirmation dialog, add mob portrait and divider to right panel header.

</domain>

<decisions>
## Implementation Decisions

### Slash Command Mapping
- `/tpw` (no args) → opens config window (was: route window)
- `/tpw config` → also opens config window (same as bare /tpw)
- `/tpw route` → opens route window
- All other commands unchanged: `debug`, `status`, `clear`, `select`, `start`, `stop`, `help`
- Subcommands are case-insensitive (e.g., `/tpw Route`, `/tpw DEBUG`, `/tpw Help` all work)
- WoW enforces lowercase on the `/tpw` part — only subcommand needs case handling

### Help Command
- `/tpw help` shows commands grouped by category with short descriptions
- Categories: Windows, Route, Debug (Claude's discretion on exact grouping and wording)

### Search Box
- Full-width search bar above both panels (below title bar, in top bar row with buttons)
- Right-aligned in the top bar row
- Debounced filtering (0.3s pause before filtering)
- Searches both mob names AND skill names (uses C_Spell.GetSpellInfo for dynamic names)
- When search matches a skill name, the parent mob appears in the tree (dungeon auto-expands)
- Selecting a mob while search is active shows only matching skills in right panel
- Closing the config window fully resets the search (clears text + restores full tree)
- No X/clear button on search box — closing window is the only reset mechanism

### Config Window Top Bar Layout
- Top bar row (below title, above panels): `[Route] [Reset All]` on left, `[Search box]` on right
- All in the same horizontal line

### Reset All Button
- Moved from bottom-right footer to top bar (left side, next to Route button)
- Now resets ALL dungeons globally (was: current dungeon only)
- Confirmation dialog: "This will reset all tracked skills and label configurations. Proceed?" with Yes/No buttons (StaticPopup)

### Route Window Button Layout
- Config button REMOVED from route window footer
- Remaining buttons: `[Clear]` on left, `[Import]` on right — spread across footer width
- Combat mode buttons row unchanged

### Config Window Right Panel Header
- Square mob portrait before mob name (same NPC portrait as left panel, using GetPortraitTexture)
- Mob name with class: `[portrait] Mob Name - CLASS`
- Visual horizontal divider line between mob header and skill list (texture line, like existing divider between left/right panels)

### Claude's Discretion
- Exact search box dimensions and EditBox styling (pushed-in background like label/TTS fields)
- Help command formatting (color codes, line breaks for chat readability)
- Portrait size in right panel header (larger than left panel 22px — suggest 32-40px)
- Divider line styling (color, thickness — match existing vertical divider pattern)
- How debounce timer is implemented (C_Timer.After with cancel pattern)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Slash Command System
- `Core.lua` — Current slash command handler, cmd/arg parsing, all existing commands

### Config Window
- `UI/ConfigFrame.lua` — BuildConfigFrame, BuildLeftPanel, PopulateRightPanel, BuildDungeonIndex, sound popup, Reset All button, GetPortraitTexture, GetSpellNameSafe

### Route Window
- `UI/PackFrame.lua` — Footer buttons (configBtn, clearBtn, importBtn), combat mode buttons, dungeon dropdown

### Search Patterns
- `UI/ConfigFrame.lua` BuildDungeonIndex — iterates ns.AbilityDB and ns.DungeonEnemies, builds sorted dungeon→mob tree. Search filtering modifies this output.
- `UI/ConfigFrame.lua` PopulateRightPanel — iterates entry.abilities. Search filtering limits which abilities are shown.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ConfigFrame.lua` AddEditBoxBackground — pushed-in EditBox styling for search box
- `ConfigFrame.lua` GetPortraitTexture — NPC portrait with displayId fallback chain
- `ConfigFrame.lua` GetSpellNameSafe — dynamic spell name resolution for search matching
- `PackFrame.lua` StaticPopup pattern (TPW_CONFIRM_CLEAR) — reusable for Reset All confirmation

### Established Patterns
- `cmd:lower()` for case-insensitive matching (Lua string method)
- `C_Timer.After(delay, callback)` for debounce
- Vertical divider in ConfigFrame: `SetColorTexture(0.4, 0.4, 0.4, 0.8)`, `SetWidth(1)`

### Integration Points
- `Core.lua` slash command handler — swap default from PackUI.Toggle to ConfigUI.Toggle
- `ConfigFrame.lua` BuildConfigFrame — add top bar row with Route/Reset All/Search
- `ConfigFrame.lua` RebuildLayout — must respect search filter state
- `PackFrame.lua` footer — remove configBtn, reposition clearBtn/importBtn

</code_context>

<specifics>
## Specific Ideas

- ASCII mockup approved: top bar with [Route] [Reset All] on left, [Search] on right
- Right panel header: square portrait + mob name + class, then horizontal divider, then skills
- Search is a quality-of-life feature for navigating 125+ mobs across 8 dungeons
- Reset All confirmation protects against accidental global reset

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 17-command-rework-and-config-search*
*Context gathered: 2026-03-20*
