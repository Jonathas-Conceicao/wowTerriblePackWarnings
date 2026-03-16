# Phase 10: Route UI Overhaul - Context

**Gathered:** 2026-03-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Overhaul the pack selection UI to display imported MDT routes as indexed pulls with round NPC portrait icons. Add Import button (opens paste popup) and Clear button (with confirmation) at the bottom of the window. Show dungeon name and pull count in header.

</domain>

<decisions>
## Implementation Decisions

### Pull Row Layout
- **MDT-style compact**: pull number + round NPC portrait icons inline, no ability text
- Abilities are NOT shown in this screen — only during combat via the icon bar
- Portrait icons are **small (20-24px)** — fits many mobs per row
- **Active pull highlighted**: current pull gets colored background/border, completed pulls greyed out
- Same combat state indicator pattern as v0.0.2 (green selected, orange active, grey completed)

### Import/Clear Controls
- Both buttons at the **bottom of the main window**, always visible
- **Import button** opens a **popup editbox** (multi-line, separate frame) for pasting MDT string. Player pastes, clicks "Import" to confirm.
- **Clear button** shows **confirmation dialog** ("Are you sure?") before clearing
- Clear removes all imported data from PackDatabase and SavedVariables
- `/tpw import` and `/tpw clear` slash commands still work alongside UI buttons

### NPC Portrait Rendering
- Render using **displayId** from DungeonEnemies data (via SetPortraitTextureFromCreatureDisplayID or equivalent)
- **Circular mask** — true round portrait like MDT mob icons
- **Fallback**: if displayId is missing/invalid, show a **class icon** based on the mob's class data
- Portraits are 20-24px round icons arranged horizontally in each pull row

### Header
- Display imported dungeon name and total pull count (e.g. "Windrunner Spire — 17 pulls")
- When no route imported, show "No route imported" or similar empty state

### Claude's Discretion
- Exact popup editbox dimensions and positioning
- Circular mask implementation (texture mask vs SetMask vs circular border overlay)
- How to get creature portrait from displayId (SetPortraitTextureFromCreatureDisplayID, ModelScene, or texture atlas)
- Pull row height and spacing
- Button styling (standard WoW button templates)
- Confirmation dialog style

</decisions>

<specifics>
## Specific Ideas

- The UI should feel like MDT's pull list — compact, numbered, with small mob portraits
- Detailed ability configuration per mob is a future phase (not in scope here)
- The popup for import should be large enough to paste a full MDT string (they can be long)

</specifics>

<code_context>
## Existing Code Insights

### Files to Modify
- `UI/PackFrame.lua`: Major rewrite — replace accordion dungeon list with numbered pull rows + portraits
- `scripts/install.bat`: May need updates if new files are created

### Existing Assets
- `ns.Import.RunFromString(str)`: Pipeline already handles import from string
- `ns.Import.Clear()`: Pipeline already handles clearing
- `ns.PackDatabase["imported"]`: Contains the pack array after import
- `Data/DungeonEnemies.lua`: Has displayId for each mob (for portrait rendering)
- `ns.db.importedRoute`: SavedVariables with dungeon name and pack data

### Integration Points
- PackFrame currently reads ns.PackDatabase and uses accordion with dungeon headers
- CombatWatcher:SelectPack and GetState still drive combat state indicators
- NameplateScanner/Scheduler consume pack.abilities — no changes needed

</code_context>

<deferred>
## Deferred Ideas

- Detailed ability configuration screen per mob — future phase
- Mob tooltips on portrait hover showing mob name and abilities — future phase

</deferred>

---

*Phase: 10-route-ui-overhaul*
*Context gathered: 2026-03-16*
