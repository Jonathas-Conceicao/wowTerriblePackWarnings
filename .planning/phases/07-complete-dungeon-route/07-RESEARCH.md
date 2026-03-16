# Phase 07: Complete Dungeon Route - Research

**Researched:** 2026-03-15
**Domain:** WoW Addon Lua — data expansion, GameTooltip spell API, FontString overlay labels, accordion scroll UI
**Confidence:** HIGH (all core API claims verified against warcraft.wiki.gg or direct code inspection)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- All 17 Windrunner Spire packs defined with exact abilities, spellIDs, mobClass, timing, labels, and ttsMessages as specified in the pack table in CONTEXT.md
- Empty packs (4, 5, 7, 9-12, 14-17) have `abilities = {}` and still appear in the Pack Selection UI
- New abilities: Fire Spit (1216848, WARRIOR, untimed, label="DMG") and Interrupting Screech (471643, PALADIN, first_cast=20, cooldown=25, label="Kick", ttsMessage="Stop Casting")
- `label` is an optional string field on each ability entry; nil/absent means no label rendered
- Existing abilities get labels: Spellguard's Protection gets "DR", Spirit Bolt gets "Bolt"
- Icon mouseover shows the WoW HUD GameTooltip for that spell (SetSpellByID or equivalent)
- Standard WoW tooltip behavior: show on OnEnter, hide on OnLeave

### Claude's Discretion
- Label font size, color, and positioning on the icon
- Tooltip anchor position relative to the icon
- How to handle GameTooltip for spell tooltips (SetSpellByID vs SetHyperlink)
- Pack displayName format for packs 2-17

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

## Summary

This phase has three distinct concerns: (1) data population — a mechanical expansion of `Data/WindrunnerSpire.lua` from 1 pack to 17; (2) icon label — a FontString overlay in `CreateIconSlot`; and (3) icon tooltip — OnEnter/OnLeave scripts on the slot frame calling `GameTooltip:SetSpellByID`.

The data and label work are low-risk and straightforward. The tooltip work is also standard WoW addon pattern, but requires the correct three-line idiom: `SetOwner`, `SetSpellByID`, `Hide`. The accordion scroll frame already handles dynamic height correctly — 17 expanded rows at 22px each = 374px total content height, well within the existing 400px frame with scroll.

**Primary recommendation:** Use `GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")` + `GameTooltip:SetSpellByID(spellID)` in OnEnter; `GameTooltip:Hide()` in OnLeave. Store spellID on the slot frame at creation time. Place the label FontString anchored to the bottom of the slot at size 9-10px with a dark shadow so it remains legible without obscuring the icon center.

---

## Standard Stack

### Core
| Component | Version/Source | Purpose | Why Standard |
|-----------|----------------|---------|--------------|
| `GameTooltip` global | Blizzard built-in | WoW HUD tooltip singleton | The canonical shared tooltip for all UI elements |
| `GameTooltip:SetOwner` | Blizzard built-in | Anchor tooltip to a frame | Required before any Set* call |
| `GameTooltip:SetSpellByID` | Blizzard built-in | Populate tooltip with spell data | Simplest spell tooltip API — takes raw spellID |
| `Frame:CreateFontString` | Blizzard built-in | Render text overlay on frame | Already used throughout the project |

### No Additional Libraries Required
All functionality is achievable with the existing Blizzard API. The project already avoids external libraries (confirmed by absence of any lib/ folder or .toc lib entries).

---

## Architecture Patterns

### Recommended Data Structure (17 packs)

```lua
-- Data/WindrunnerSpire.lua pattern to repeat for all 17 packs
packs[#packs + 1] = {
    key         = "windrunner_spire_pack_N",
    displayName = "Pack N",   -- format at Claude's discretion
    abilities = {
        -- timed example:
        { name="Spellguard's Protection", spellID=1253686, mobClass="PALADIN",
          first_cast=50, cooldown=50, ttsMessage="Shield", label="DR" },
        -- untimed example:
        { name="Spirit Bolt", spellID=1216135, mobClass="WARRIOR", label="Bolt" },
        -- empty pack: abilities = {}  (no entry needed here)
    },
}
```

Empty packs use `abilities = {}`. No special handling required — `NameplateScanner:Start` already guards `for _, ability in ipairs(activePack.abilities)` which iterates 0 times gracefully.

### Pattern 1: GameTooltip on a Custom Frame (OnEnter/OnLeave)

**What:** Attach spell tooltip display to the icon slot frame using the shared `GameTooltip` singleton.

**When to use:** Any custom frame that needs a WoW native spell tooltip on mouseover.

**The three-line idiom:**
```lua
-- In CreateIconSlot, after creating the frame:
slot.spellID = spellID   -- store for use in OnEnter closure

slot:EnableMouse(true)   -- required: frames are not mouse-interactive by default

slot:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetSpellByID(self.spellID)
    -- SetSpellByID triggers Show() automatically per warcraft.wiki.gg docs
end)

slot:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
```

**Anchor choice:** `"ANCHOR_TOPLEFT"` positions the tooltip below the frame's top-left corner — appropriate for icons anchored at BOTTOMLEFT of UIParent, so the tooltip appears above/beside the icon rather than off-screen below. If icons are near the top of the screen, use `"ANCHOR_BOTTOMLEFT"` instead. Since `ANCHOR_Y = 900` (near top), `"ANCHOR_BOTTOMLEFT"` is safer (tooltip opens downward).

**SetSpellByID vs SetHyperlink:**
- `SetSpellByID(id)` — takes a raw number, purpose-built for spells, simplest API. **Use this.**
- `SetHyperlink("spell:id")` — more flexible but requires string formatting; no advantage here.

**Combat safety:** `GameTooltip:SetSpellByID` is not a protected/restricted function. It is safe to call during combat. Blizzard converted all `Set*` GameTooltip APIs to secure delegates (verified via warcraft.wiki.gg and related addon issue research).

### Pattern 2: Label FontString on an 80px Icon

**What:** A small text label overlaid on the icon, positioned so it doesn't obscure the spell icon center.

**Recommended position:** Bottom edge, anchored BOTTOM with a small upward offset.

```lua
-- In CreateIconSlot, after creating the icon texture, if label provided:
if label then
    local lbl = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("BOTTOM", slot, "BOTTOM", 0, 3)
    lbl:SetFont(lbl:GetFont(), 9, "OUTLINE")   -- 9px with outline for contrast
    lbl:SetText(label)
    lbl:SetTextColor(1, 1, 1, 1)   -- white; adjust at discretion
    slot.label = lbl
end
```

**Font size rationale:** At 80px icon width, a 9-10px font string for a 2-4 character label ("DR", "Bolt", "DMG", "Kick") occupies roughly 20-35px wide and 10px tall. The `"OUTLINE"` flag adds a dark border that makes white text legible against any spell icon background. Positioning at BOTTOM with y=3 keeps it in the bottom strip, leaving the icon center fully visible.

**Alternative position:** TOP edge (y=-3 from TOPLEFT) — places label over the top strip. Either works; BOTTOM is slightly preferable because the cooldown sweep sweeps top-to-bottom (the bottom area clears first as the timer progresses), so a bottom label remains visible longer during the sweep.

**`"GameFontNormal"` template:** This is the standard WoW UI font template (Friz Quadrata, 12pt by default). Setting size to 9 via `SetFont` overrides it. Alternatively use `"GameFontNormalSmall"` which is pre-set to a smaller size (~10pt) without needing a manual SetFont call.

### Pattern 3: Propagating `label` Through the Call Chain

The `label` field lives on the ability data table. `CreateIconSlot` currently takes `(spellID, duration)`. It must also accept `label`.

The call chain:
- `NameplateScanner:OnMobsAdded` → `Scheduler:StartAbility(ability, barId)` → `scheduleAbility(ability, barId)` → `ns.IconDisplay.ShowIcon(barId, spellID, ttsMessage, duration)`
- `NameplateScanner:OnMobsAdded` → `ns.IconDisplay.ShowStaticIcon(instanceKey, spellID)`

Both `ShowIcon` and `ShowStaticIcon` public functions need a `label` parameter added, which they pass to `CreateIconSlot`. The ability object is available at the call sites, so `ability.label` can be threaded through.

**Minimum change surface:**
1. `CreateIconSlot(spellID, duration, label)` — add label param, create FontString if non-nil
2. `ns.IconDisplay.ShowIcon(instanceKey, spellID, ttsMessage, duration, label)` — add label param
3. `ns.IconDisplay.ShowStaticIcon(instanceKey, spellID, label)` — add label param
4. `Scheduler:StartAbility(ability, barId)` — already passes full ability; update ShowIcon call
5. `NameplateScanner:OnMobsAdded` — update ShowStaticIcon call to include `ability.label`
6. `scheduleAbility` — update ShowIcon call to include label from ability

The reschedule closure in `scheduleAbility` constructs a partial ability table (lines 67-73 of Scheduler.lua). That table must also carry `label` to avoid losing it on cooldown repeats.

### Anti-Patterns to Avoid

- **Do not call `GameTooltip:Show()` explicitly after `SetSpellByID`** — the Set* methods trigger Show automatically. Calling it again is a no-op but adds noise.
- **Do not call `GameTooltip:ClearLines()` before `SetSpellByID`** — `SetOwner` already clears/resets the tooltip. Adding ClearLines is redundant.
- **Do not use `"ANCHOR_NONE"` for display tooltips** — ANCHOR_NONE requires manual SetPoint positioning and is intended for invisible scanning tooltips only.
- **Do not anchor label FontString with SetAllPoints** — it would fill the entire icon and obscure the texture. Use a point-to-point anchor instead.
- **Do not chain rows by anchoring each to the previous** — PackFrame already uses absolute yOffset from scrollChild TOPLEFT. Keep this pattern for all 17 pack rows to avoid anchor chain failure.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Spell tooltip display | Custom tooltip frame with spell data lookup | `GameTooltip:SetSpellByID` | Built-in fetches name, description, cast time, reagents automatically |
| Text contrast on icon | Manual background texture behind label | `"OUTLINE"` flag on FontString | Blizzard outline renders a pixel-wide dark border on all glyph edges, sufficient contrast on any background |
| Scroll virtualization | Pool/recycle row logic for 17 items | Existing `UIPanelScrollFrameTemplate` + full row list | 17 rows at 22px = 374px; the frame height is 400px — scroll activates only if all rows exceed viewport. No virtualization needed at this scale. |

---

## Common Pitfalls

### Pitfall 1: Frame Not Mouse-Interactive
**What goes wrong:** OnEnter/OnLeave scripts are attached but never fire. GameTooltip never appears.
**Why it happens:** Frames created with `CreateFrame("Frame", ...)` have mouse interaction disabled by default. Only `Button` frames are mouse-interactive by default.
**How to avoid:** Call `slot:EnableMouse(true)` immediately after creating the slot frame, before setting OnEnter/OnLeave scripts.
**Warning signs:** Scripts attached, no errors, but hovering over the icon has no effect.

### Pitfall 2: Label Lost on Cooldown Repeat
**What goes wrong:** The label shows correctly on the first cast cycle, then disappears when the ability repeats.
**Why it happens:** `scheduleAbility` constructs a new partial ability table for the recursive reschedule call (Scheduler.lua lines 67-73). If `label` is not included in that table, `ShowIcon` receives `nil` for the label on subsequent cycles. However, since `ShowIcon` short-circuits with `existing.cd:SetCooldown` when the key already exists (line 162-168 of IconDisplay.lua), `CreateIconSlot` is NOT called again — the label FontString from the first creation remains. So this is actually NOT a problem for the displayed label.
**Conclusion (HIGH confidence):** The label is baked into the slot frame at first creation and survives cooldown resets because `ShowIcon` reuses the existing slot. No change needed to the reschedule closure for label persistence.

### Pitfall 3: GameTooltip Stays Visible After Icon Removed
**What goes wrong:** CancelIcon hides the slot frame, but GameTooltip remains visible if the cursor was over it at time of removal.
**Why it happens:** Hiding the frame does not fire OnLeave.
**How to avoid:** In `CancelIcon`, add a guard: if `GameTooltip:GetOwner() == slot then GameTooltip:Hide() end` before hiding the slot.
**Warning signs:** Tooltip persists in the corner of the screen after combat ends.

### Pitfall 4: `displayName` for Packs Without Clear Names
**What goes wrong:** Packs 2-17 have no user-facing canonical name — the user just calls them by number.
**Decision:** Use a simple format like `"Pack 2"`, `"Pack 3"`, etc. The PackFrame already renders the displayName string verbatim. No additional logic required.

### Pitfall 5: Accordion Height with 17 Rows
**What goes wrong:** Developer assumes the existing 400px frame height is enough without testing, but all 17 rows expanded = 17 × 22px = 374px content height. The scroll child height is set dynamically by `PopulateList()` via `scrollChild:SetHeight(math.max(yOffset, 1))`. This is already correct — no change needed.
**Conclusion:** 17 rows fits within 374px, which is less than the ~360px viewport of the scroll frame (400px frame minus ~40px for title bar and padding). Scrolling will activate for 17 expanded rows. This is expected and handled automatically by `UIPanelScrollFrameTemplate`.

---

## Code Examples

Verified patterns from official sources and existing codebase:

### GameTooltip: Spell Tooltip on Mouseover
```lua
-- Source: warcraft.wiki.gg/wiki/API_GameTooltip_SetOwner and UIOBJECT_GameTooltip
-- Add to CreateIconSlot after frame creation:

slot.spellID = spellID
slot:EnableMouse(true)

slot:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetSpellByID(self.spellID)
end)

slot:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
```

Note: `"ANCHOR_BOTTOMLEFT"` is chosen because the icons are placed near the top of the screen (ANCHOR_Y = 900, which is near the top in UIParent coordinates starting from bottom). ANCHOR_BOTTOMLEFT positions the tooltip below-left of the frame, keeping it on-screen.

### Label FontString on Icon
```lua
-- Source: Frame:CreateFontString Blizzard API, in-codebase pattern (PackFrame.lua line 70)
-- Add to CreateIconSlot, conditional on label parameter:

if label and label ~= "" then
    local lbl = slot:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    lbl:SetPoint("BOTTOM", slot, "BOTTOM", 0, 3)
    lbl:SetText(label)
    lbl:SetTextColor(1, 1, 1, 1)
    slot.label = lbl
end
```

### Updated CreateIconSlot Signature
```lua
-- Changed from: local function CreateIconSlot(spellID, duration)
-- Changed to:
local function CreateIconSlot(spellID, duration, label)
```

### Updated ShowIcon Signature
```lua
-- Changed from: function ns.IconDisplay.ShowIcon(instanceKey, spellID, ttsMessage, duration)
-- Changed to:
function ns.IconDisplay.ShowIcon(instanceKey, spellID, ttsMessage, duration, label)
    local slot = CreateIconSlot(spellID, duration, label)
    -- ... rest unchanged
```

### Updated ShowStaticIcon Signature
```lua
-- Changed from: function ns.IconDisplay.ShowStaticIcon(instanceKey, spellID)
-- Changed to:
function ns.IconDisplay.ShowStaticIcon(instanceKey, spellID, label)
    local slot = CreateIconSlot(spellID, nil, label)
    -- ... rest unchanged
```

### CancelIcon GameTooltip Guard
```lua
function ns.IconDisplay.CancelIcon(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end

    -- Hide tooltip if it was anchored to this slot
    if GameTooltip:GetOwner() == slot then
        GameTooltip:Hide()
    end

    slot:Hide()
    -- ... rest unchanged
```

### Data: Pack with Empty Abilities
```lua
-- Packs 4, 5, 7, 9-17 all follow this pattern:
packs[#packs + 1] = {
    key         = "windrunner_spire_pack_4",
    displayName = "Pack 4",
    abilities   = {},
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `AddSpellByID` | `SetSpellByID` | Removed ~2022 (patch 9.x era) | Use SetSpellByID exclusively |
| Manual tooltip positioning with ANCHOR_NONE | Semantic anchors (ANCHOR_TOPLEFT etc.) | Always available | Prefer semantic anchors for display tooltips |

**Deprecated/outdated:**
- `GameTooltip:AddSpellByID`: removed from the API — replaced by `SetSpellByID`.

---

## Open Questions

1. **Exact ANCHOR constant for icon position**
   - What we know: Icons are placed at ANCHOR_Y=900, which in UIParent coordinates (bottom-left origin) is near the top third of a 1080p screen. ANCHOR_BOTTOMLEFT opens the tooltip downward/leftward.
   - What's unclear: The exact pixel position depends on the player's screen resolution and UI scale. The choice may need minor in-game tuning.
   - Recommendation: Default to `"ANCHOR_BOTTOMLEFT"`. The planner can note this is adjustable without code change — just the anchor string constant.

2. **Pack displayName convention**
   - What we know: User said "Pack displayName format for packs 2-17" is Claude's discretion.
   - Recommendation: Use `"Pack N"` (e.g., `"Pack 2"`, `"Pack 13"`). Simple, unambiguous, consistent.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — WoW addons run inside the WoW client; no offline unit test framework present |
| Config file | None |
| Quick run command | `/tpw start` in-game; observe icon display and tooltip behavior |
| Full suite command | Manual in-game walkthrough: select dungeon, advance through multiple packs, verify tooltip on all icons, verify labels on labeled abilities, verify empty packs advance correctly |

### Phase Requirements → Test Map
| Behavior | Test Type | Automated Command | Notes |
|----------|-----------|-------------------|-------|
| All 17 packs appear in PackFrame accordion | manual | n/a — requires WoW client | Expand "Windrunner Spire" in UI |
| Empty packs advance on combat end with no icons | manual | n/a | Pull and wipe with empty pack selected |
| Label text renders on icon for labeled abilities | manual | n/a | `/tpw start` on Pack 1; verify "DR" and "Bolt" visible |
| No label rendered on Pack 3 Fire Spit (label "DMG" is set, so label present) | manual | n/a | Verify "DMG" appears |
| GameTooltip appears on icon mouseover | manual | n/a | Hover over any active icon |
| GameTooltip hides on mouse leave | manual | n/a | Move cursor off icon |
| GameTooltip hides when icon is cancelled mid-hover | manual | n/a | Trigger CancelAll while hovering |
| Interrupting Screech (Pack 13) triggers at 20s first_cast, 25s repeat | manual | n/a | Use `/tpw start` with pack 13 selected |

### Wave 0 Gaps
None — no test infrastructure exists or is expected for WoW addon Lua. All validation is manual in-game.

---

## Sources

### Primary (HIGH confidence)
- [warcraft.wiki.gg/wiki/UIOBJECT_GameTooltip](https://warcraft.wiki.gg/wiki/UIOBJECT_GameTooltip) — SetSpellByID signature, Set* auto-Show behavior
- [warcraft.wiki.gg/wiki/API_GameTooltip_SetOwner](https://warcraft.wiki.gg/wiki/API_GameTooltip_SetOwner) — All ANCHOR_ constants, offset parameter behavior
- [warcraft.wiki.gg/wiki/API_GameTooltip_SetHyperlink](https://warcraft.wiki.gg/wiki/API_GameTooltip_SetHyperlink) — SetHyperlink for comparison/ruling out
- `Display/IconDisplay.lua` (codebase) — existing frame creation, slot pattern
- `Data/WindrunnerSpire.lua` (codebase) — existing data schema
- `Engine/NameplateScanner.lua`, `Engine/Scheduler.lua` (codebase) — call chain for label propagation analysis

### Secondary (MEDIUM confidence)
- [kapresoft/wow-addon-actionbar-plus issue #147](https://github.com/kapresoft/wow-addon-actionbar-plus/issues/147) — confirms AddSpellByID removed, SetSpellByID is current API (closed 2022)
- [warcraft.wiki.gg/wiki/Making_scrollable_frames](https://warcraft.wiki.gg/wiki/Making_scrollable_frames) — scroll child height pattern confirmation
- WoW forum / WoWInterface search results — confirmed GameTooltip:SetSpellByID is combat-safe (not restricted)

### Tertiary (LOW confidence)
- None — all claims in this document are backed by PRIMARY or SECONDARY sources.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs verified on warcraft.wiki.gg
- Architecture: HIGH — patterns derived from existing codebase code paths and official API docs
- Pitfalls: HIGH (1, 3, 4, 5) / MEDIUM (2) — pitfall 2 requires tracing the existing code path, conclusion is HIGH confidence based on direct code inspection

**Research date:** 2026-03-15
**Valid until:** 2026-09-15 (WoW addon APIs are stable; GameTooltip API unchanged since 2022)
