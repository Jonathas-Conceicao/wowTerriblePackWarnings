# Phase 7: Complete Dungeon Route - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Populate all 17 Windrunner Spire packs for a full dungeon route. Add tooltip on icon mouseover and optional short labels on each icon. Add two new abilities (Fire Spit, Interrupting Screech) to the data schema.

</domain>

<decisions>
## Implementation Decisions

### Pack Data — Full Windrunner Spire Route (17 packs)

| Pack | Abilities |
|------|-----------|
| 1 | Spellguard's Protection (1253686, PALADIN, 50s/50s, label="DR", tts="Shield") + Spirit Bolt (1216135, WARRIOR, untimed, label="Bolt") |
| 2 | Spirit Bolt (1216135, WARRIOR, untimed, label="Bolt") |
| 3 | Fire Spit (1216848, WARRIOR, untimed, label="DMG") |
| 4 | — (empty, no tracked abilities) |
| 5 | — (empty) |
| 6 | Fire Spit (1216848, WARRIOR, untimed, label="DMG") |
| 7 | — (empty) |
| 8 | Spirit Bolt (1216135, WARRIOR, untimed, label="Bolt") |
| 9 | — (empty) |
| 10 | — (empty) |
| 11 | — (empty) |
| 12 | — (empty) |
| 13 | Interrupting Screech (471643, PALADIN, first_cast=20s, cooldown=25s, label="Kick", tts="Stop Casting") |
| 14 | — (empty) |
| 15 | — (empty) |
| 16 | — (empty) |
| 17 | — (empty) |

- All 17 packs appear in the Pack Selection UI (including empty ones for route progression)
- Empty packs have `abilities = {}` — no icons spawn during combat

### New Abilities

- **Fire Spit** (spellID 1216848): mobClass "WARRIOR", untimed, label "DMG", no TTS
- **Interrupting Screech** (spellID 471643): mobClass "PALADIN", first_cast 20s, cooldown 25s, label "Kick", ttsMessage "Stop Casting"

### Data Schema Addition: `label` field
- Each ability can have an optional `label` string — short text displayed on top of the icon square
- If nil/absent, no label is shown
- Existing abilities get labels: "DR" (Spellguard's Protection), "Bolt" (Spirit Bolt)

### Icon Tooltip
- Mousing over an icon square shows the **WoW HUD tooltip** for that spell (via GameTooltip:SetSpellByID or equivalent)
- Standard WoW tooltip behavior — shows on hover, hides on leave

### Claude's Discretion
- Label font size, color, and positioning on the icon
- Tooltip anchor position relative to the icon
- How to handle GameTooltip for spell tooltips (SetSpellByID vs SetHyperlink)
- Pack displayName format for packs 2-17

</decisions>

<specifics>
## Specific Ideas

- Labels should be small and not obscure the spell icon — positioned on top edge or corner
- The route represents a standard M+ path through Windrunner Spire
- Empty packs still auto-advance on combat end, giving the player visual route progress

</specifics>

<code_context>
## Existing Code Insights

### Files to Modify
- `Data/WindrunnerSpire.lua`: Currently has 1 pack — expand to 17
- `Display/IconDisplay.lua`: Add label text rendering + tooltip on mouseover
- `Engine/Scheduler.lua`: No changes needed — already handles timed/untimed via pack.abilities

### Established Patterns
- Pack data uses `packs[#packs + 1] = { key, displayName, abilities = { ... } }`
- Abilities have: name, spellID, mobClass, first_cast (optional), cooldown (optional), ttsMessage (optional)
- New field: label (optional string)

### Integration Points
- IconDisplay.CreateIconSlot needs: label FontString + OnEnter/OnLeave for tooltip
- NameplateScanner already handles empty packs gracefully (no abilities = no icons)
- PackFrame UI will show all 17 packs in the accordion

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-complete-dungeon-route*
*Context gathered: 2026-03-15*
