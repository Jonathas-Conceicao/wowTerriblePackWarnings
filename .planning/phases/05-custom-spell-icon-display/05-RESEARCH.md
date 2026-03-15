# Phase 5: Custom Spell Icon Display - Research

**Researched:** 2026-03-15
**Domain:** WoW Addon UI — Frame creation, Cooldown widget, TTS API, glow libraries
**Confidence:** HIGH (core APIs verified against warcraft.wiki.gg official docs, patch 12.0.0 current)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Icon Layout**
- Horizontal row of square spell icons anchored at top-left of screen, growing rightward toward center
- Each square shows the spell icon from spellID (via GetSpellTexture or equivalent)
- Timed abilities: cooldown sweep animation (WoW-style clock) + integer countdown number
- Untimed abilities: static icon only (no sweep, no countdown), one icon regardless of mob count
- Timed abilities show one icon per mob instance (multiple mobs = multiple squares)

**Urgency Indicators**
- Red glow border appears on timed squares when 5 seconds remain before cast
- No other color shifts or animations for urgency

**TTS Warnings**
- TTS fires for timed abilities only at 5 seconds remaining — untimed icons are silent
- Each ability entry has a custom `ttsMessage` field with a short callout (e.g. "Shield")
- TTS does NOT use the full ability name — short combat-ready callouts only
- Data schema addition: `ttsMessage = "Shield"` on Spellguard's Protection, no ttsMessage on Spirit Bolt
- TTS API is uncertain — researcher should investigate

**Legacy Adapter Removal**
- Delete `Display/BossWarnings.lua` entirely
- Remove all references to `ns.BossWarnings` from Scheduler.lua
- Scheduler.lua calls replaced with new display system API
- TOC file updated to remove BossWarnings.lua and add new display file

### Claude's Discretion
- Icon square size and spacing
- Border style when not glowing
- Whether icons appear/disappear with animation or instantly
- Sweep direction (clockwise vs counterclockwise)
- How timer reset looks visually when a repeating ability cycles
- New display module file name and API shape
- How to handle the Scheduler → Display integration (callback, direct call, event)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DISP-01 | Horizontal row of square spell icons at top-left of screen, growing rightward | Frame layout with SetPoint("TOPLEFT") + sequential x-offset positioning |
| DISP-02 | Each timed square shows spell icon with cooldown sweep animation and integer countdown | Cooldown widget SetCooldown() + SetHideCountdownNumbers(false) or custom FontString ticker |
| DISP-03 | Untimed skills display as static icons, one icon regardless of mob count | Icon frame with texture only, no Cooldown child; single-instance guard in display state |
| DISP-04 | Red glow border on timed squares when 5 seconds remain | LibCustomGlow PixelGlow_Start with {1,0,0,1} color on 5s pre-warn |
| DISP-05 | TTS announces ability name 5 seconds before timed cast fires | C_VoiceChat.SpeakText() using C_TTSSettings.GetVoiceOptionID() for voiceID |
| DISP-06 | Remove DBM/EncounterTimeline/RaidNotice display adapters | Delete Display/BossWarnings.lua, update TOC and Scheduler.lua |
| DISP-08 | Timed skills show one icon per mob instance; untimed show one icon total | Display state tracks icons by (abilityKey, instanceID) for timed, (abilityKey) for untimed |
</phase_requirements>

---

## Summary

Phase 5 replaces `Display/BossWarnings.lua` with a self-contained custom display module that renders spell icons in a horizontal row at top-left. The WoW frame API is mature and well-documented; all five technical sub-problems (icon layout, cooldown sweep, spell texture, red glow, TTS) have verified API solutions.

The most uncertain area is TTS. `C_VoiceChat.SpeakText` is a real, non-protected API available in Midnight (patch 12.0.0+) and requires a voiceID obtained via `C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)`. The 12.0.0 API signature changed — the `destination` parameter was removed and `overlap` added. Any sample code older than January 2026 will have the wrong signature. The function is marked `AllowedWhenTainted` so no secure environment restrictions apply.

For the red glow, the built-in Blizzard overlay glow (`ActionButton_ShowOverlayGlow`) taints action bars irreversibly. The correct approach for custom frames is LibCustomGlow (Stanzilla), which has a February 2026 release and is the ecosystem standard. It must be embedded in a `Libs/` subfolder since this addon has no external library dependency mechanism.

The cooldown sweep comes free from `CreateFrame("Cooldown")` with `SetCooldown(GetTime(), duration)`. Built-in countdown numbers are controlled by `SetHideCountdownNumbers`. For the integer countdown required by DISP-02, the Cooldown widget's built-in number is sufficient (driven by game engine, not per-frame Lua ticks), but the planner should decide whether to use it or a custom FontString ticker for styling control.

**Primary recommendation:** New module at `Display/IconDisplay.lua`. Embed LibCustomGlow in `Libs/LibCustomGlow/`. Use `C_VoiceChat.SpeakText` with `C_TTSSettings.GetVoiceOptionID` for TTS; no sound file fallback needed.

---

## Standard Stack

### Core
| Library / API | Version / Patch | Purpose | Why Standard |
|---------------|-----------------|---------|--------------|
| WoW Cooldown widget | Built-in (12.0.x) | Clock-sweep animation on icon frames | Native to WoW UI, zero dependencies, free timer drive |
| C_Spell.GetSpellTexture | Built-in (11.0+) | SpellID → icon fileID | Preferred modern API over legacy GetSpellTexture |
| C_VoiceChat.SpeakText | Built-in (9.1+, updated 12.0) | Text-to-speech callout | Non-protected, AllowedWhenTainted, no file management |
| C_TTSSettings.GetVoiceOptionID | Built-in (9.1.5+) | Retrieve player's preferred TTS voiceID | Required to call SpeakText without hardcoding voice index |
| LibCustomGlow-1.0 | 1.3.5 (Feb 2026) | Red glow border on frames | Taint-safe replacement for Blizzard overlay glow APIs |
| LibStub | Embedded | Library versioning shim for LibCustomGlow | Required by LibCustomGlow |

### Supporting
| Library / API | Purpose | When to Use |
|---------------|---------|-------------|
| C_Timer.NewTimer | Pre-warn and cast timing (already used in Scheduler) | Existing mechanism — no change |
| CreateFrame("Frame") | Container per icon slot | One per tracked mob/ability instance |
| CreateFrame("Cooldown") | Sweep overlay child of icon frame | Only on timed ability icons |
| FontString (GameFontNormalLarge) | Integer countdown label | If built-in Cooldown number styling is insufficient |
| PlaySoundFile | Fallback sound (addon .ogg) | Only if TTS is unavailable at runtime |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| LibCustomGlow | ActionButton_ShowOverlayGlow | Blizzard API taints action bars — never use on custom frames |
| C_VoiceChat.SpeakText | PlaySoundFile with bundled DBM .ogg | TTS requires no bundled files; .ogg fallback requires shipping audio assets |
| Built-in Cooldown number | Custom C_Timer.NewTicker + FontString | Custom gives styling control; built-in is simpler and always accurate |

**Installation (embed in addon Libs folder):**
```bash
# Copy LibCustomGlow source into Libs/LibCustomGlow/
# Add to TOC before Display/IconDisplay.lua:
# Libs\LibCustomGlow\LibStub.lua
# Libs\LibCustomGlow\LibCustomGlow-1.0.lua
```

---

## Architecture Patterns

### Recommended Project Structure
```
Display/
└── IconDisplay.lua       -- new display module (replaces BossWarnings.lua)
Libs/
├── LibCustomGlow/
│   ├── LibStub.lua
│   └── LibCustomGlow-1.0.lua
```

TOC load order:
```
Libs\LibCustomGlow\LibStub.lua
Libs\LibCustomGlow\LibCustomGlow-1.0.lua
Core.lua
Engine\Scheduler.lua
Engine\CombatWatcher.lua
Display\IconDisplay.lua
Data\WindrunnerSpire.lua
UI\PackFrame.lua
```

### Pattern 1: Icon Slot Frame Construction
**What:** Each tracked ability instance gets a parent Frame containing a spell icon Texture and a Cooldown child. Timed instances also get the Cooldown active; untimed instances leave it idle.

**When to use:** Called from `IconDisplay.ShowIcon(key, spellID, duration)` and `IconDisplay.ShowStaticIcon(key, spellID)`.

**Example:**
```lua
-- Source: warcraft.wiki.gg/wiki/UIOBJECT_Cooldown
local slot = CreateFrame("Frame", nil, UIParent)
slot:SetSize(40, 40)
slot:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xOffset, -8)

local icon = slot:CreateTexture(nil, "BACKGROUND")
icon:SetAllPoints(slot)
local iconID = C_Spell.GetSpellTexture(spellID)
icon:SetTexture(iconID)

-- Timed only:
local cd = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
cd:SetAllPoints(slot)
cd:SetHideCountdownNumbers(false)   -- show built-in integer
cd:SetDrawEdge(true)
cd:SetCooldown(GetTime(), duration) -- starts sweep immediately
```

### Pattern 2: Icon Slot Horizontal Layout
**What:** Container frame anchored TOPLEFT to UIParent. Each new slot is positioned relative to the previous, offset rightward by (ICON_SIZE + PADDING).

**When to use:** Every time an icon is added or removed, re-layout all visible slots.

**Example:**
```lua
-- Source: warcraft.wiki.gg SetPoint documentation
local ICON_SIZE = 40
local ICON_PADDING = 4
local ANCHOR_X = 8
local ANCHOR_Y = -8

-- Re-layout: iterate active slots in order, set SetPoint
for i, slot in ipairs(activeSlots) do
    slot:ClearAllPoints()
    slot:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
        ANCHOR_X + (i - 1) * (ICON_SIZE + ICON_PADDING),
        ANCHOR_Y)
end
```

### Pattern 3: Red Glow at 5 Seconds
**What:** LibCustomGlow PixelGlow_Start with red color, called when the pre-warn timer fires (5s before cast).

**When to use:** In the Scheduler's pre-warn callback, after calling `IconDisplay.SetUrgent(key)`.

**Example:**
```lua
-- Source: github.com/Stanzilla/LibCustomGlow
local LCG = LibStub("LibCustomGlow-1.0")

-- Start red glow
LCG.PixelGlow_Start(slot, {1, 0, 0, 1}, 8, 0.25, nil, 2)

-- Stop glow (on cancel or cycle reset)
LCG.PixelGlow_Stop(slot)
```

### Pattern 4: TTS Callout
**What:** Obtain player's preferred voice at module load (or lazily on first use), call SpeakText with short message.

**When to use:** In pre-warn timer callback, when `ability.ttsMessage` is non-nil.

**Example:**
```lua
-- Source: warcraft.wiki.gg/wiki/API_C_VoiceChat.SpeakText (post-12.0.0 signature)
-- Source: warcraft.wiki.gg/wiki/API_C_TTSSettings.GetVoiceOptionID
local function GetVoiceID()
    -- Enum.TtsVoiceType.Standard = 0
    return C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)
end

local function SpeakWarning(message)
    local voiceID = GetVoiceID()
    if voiceID then
        -- Post-12.0.0: SpeakText(voiceID, text, rate, volume, overlap)
        C_VoiceChat.SpeakText(voiceID, message, 0, 100, false)
    end
end
```

### Pattern 5: Cooldown Reset on Repeating Ability
**What:** When a repeating ability fires, its icon needs a fresh sweep starting from the new cast time. Call `cd:SetCooldown(GetTime(), cooldown)` again on the existing slot — this resets the animation in-place.

**When to use:** In `scheduleAbility` recursion, instead of creating a new slot, reuse and reset the existing one.

**Example:**
```lua
-- Reset existing slot's cooldown for next cycle
local slot = activeSlots[key]
if slot and slot.cd then
    slot.cd:SetCooldown(GetTime(), newDuration)
    LCG.PixelGlow_Stop(slot) -- clear urgency from previous cycle
end
```

### Anti-Patterns to Avoid

- **Using ActionButton_ShowOverlayGlow on custom frames:** Taints action bars permanently during the session. Use LibCustomGlow instead.
- **Hardcoding voiceID = 0:** Voice IDs are not guaranteed stable across locales or system configurations. Always retrieve via C_TTSSettings.GetVoiceOptionID.
- **Using the pre-12.0.0 SpeakText signature (with destination param):** The `destination` argument was removed in patch 12.0.0 (Jan 20, 2026). The current signature is `SpeakText(voiceID, text, rate, volume, overlap)`.
- **Storing old GetSpellInfo for icon:** Use `C_Spell.GetSpellTexture(spellID)` directly; it returns fileID. The legacy `GetSpellTexture` also works but C_Spell namespace is preferred post-11.0.
- **Creating icon frames inside the Cooldown frame:** The Cooldown frame is a child of the icon container. Icon texture goes on the container, Cooldown overlays it.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Glow border effect | Custom texture + animation frame | LibCustomGlow-1.0 | Blizzard glow APIs taint action bars; hand-rolled animation is complex and not pixel-accurate |
| Text-to-speech | PlaySoundFile + bundled voice .ogg files | C_VoiceChat.SpeakText | Built-in TTS requires no asset management; ogg files add package weight and require voice recording |
| Cooldown sweep animation | Manual arc/swipe texture rotation | Cooldown widget | The native widget handles all rendering, timing accuracy, and edge rendering automatically |
| Spell icon texture lookup | Storing icon paths in data | C_Spell.GetSpellTexture(spellID) | Game always has the correct icon for any spellID; hardcoded paths break on patches |

**Key insight:** WoW's built-in Cooldown widget provides free, GPU-accelerated, perfectly-timed sweep animation. Any hand-rolled equivalent would be less accurate and more CPU-intensive.

---

## Common Pitfalls

### Pitfall 1: Wrong SpeakText Signature (Pre-12.0.0 Code)
**What goes wrong:** Calling `C_VoiceChat.SpeakText(voiceID, text, Enum.VoiceTtsDestination.LocalPlayback, rate, volume)` crashes silently or speaks garbage on Midnight.
**Why it happens:** The `destination` parameter was removed in patch 12.0.0 (January 20, 2026). All pre-Midnight examples online use the old signature.
**How to avoid:** Use the 5-parameter form: `SpeakText(voiceID, text, rate, volume, overlap)`.
**Warning signs:** `/run C_VoiceChat.SpeakText(...)` in chat produces no speech and no Lua error.

### Pitfall 2: TTS Voice ID Is Nil
**What goes wrong:** `C_TTSSettings.GetVoiceOptionID` returns nil if the player has never configured TTS in game settings.
**Why it happens:** TTS voice settings default to unset until the player visits the TTS accessibility menu.
**How to avoid:** Guard with `if voiceID then` before calling SpeakText. Consider falling back to the first available voice from `C_VoiceChat.GetTtsVoices()`.
**Warning signs:** Silent pre-warn despite correct code path being reached.

### Pitfall 3: Cooldown Frame Not Visible Over Icon Texture
**What goes wrong:** The Cooldown sweep renders behind the icon texture and is invisible.
**Why it happens:** Frame strata/level ordering — Cooldown frame must be at a higher layer than the icon texture.
**How to avoid:** Create the icon Texture at "BACKGROUND" layer, ensure the Cooldown frame is a child of the container (not of the texture). `cd:SetAllPoints(slot)` after `cd = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")` gives correct stacking.
**Warning signs:** Icon appears but no sweep animation is visible.

### Pitfall 4: LibCustomGlow Not Available (Missing Embed)
**What goes wrong:** `LibStub("LibCustomGlow-1.0")` returns nil; glow calls error.
**Why it happens:** LibCustomGlow is not an Ace3 auto-managed library — it must be manually embedded in the addon's Libs folder and listed in the TOC.
**How to avoid:** Add both LibStub.lua and LibCustomGlow-1.0.lua to `Libs/LibCustomGlow/` and list them in the TOC before IconDisplay.lua. Guard with `local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)` to fail gracefully if absent.
**Warning signs:** Lua error at addon load: `attempt to call nil value (global 'LibStub')`.

### Pitfall 5: Icon Slots Not Re-Laid Out After Cancel
**What goes wrong:** Removing a middle icon leaves a gap; subsequent icons don't slide left.
**Why it happens:** Each slot has an absolute TOPLEFT offset calculated at creation time.
**How to avoid:** Maintain an ordered list of active slots. After any add/remove, iterate and re-apply `SetPoint` for all remaining slots.
**Warning signs:** Visual holes in the icon row after an ability is cancelled.

### Pitfall 6: Scheduler Coupling — BossWarnings API Shape Mismatch
**What goes wrong:** Scheduler calls `ns.BossWarnings.Show(text, duration)` and `ShowTimer(id, text, duration, spellID)` — the new module must expose compatible signatures OR Scheduler must be updated simultaneously.
**Why it happens:** The existing Scheduler.lua calls `ns.BossWarnings.Show` (text alert) and `ns.BossWarnings.ShowTimer` (countdown bar). The new display is icon-based, not text/bar-based — the API shapes are different.
**How to avoid:** Rewrite Scheduler.lua calls in this phase. The new API will be `ns.IconDisplay.ShowIcon(instanceKey, spellID, ttsMessage, duration)` and `ns.IconDisplay.CancelIcon(instanceKey)` / `ns.IconDisplay.CancelAll()`. Scheduler must pass `spellID` for icon lookup, not just `name`.
**Warning signs:** Lua error at combat start: `attempt to call nil value (field 'Show')`.

---

## Code Examples

Verified patterns from official sources:

### Full Icon Slot Construction
```lua
-- Source: warcraft.wiki.gg/wiki/UIOBJECT_Cooldown + C_Spell.GetSpellTexture
local function CreateIconSlot(parent, spellID, duration)
    local slot = CreateFrame("Frame", nil, parent)
    slot:SetSize(ICON_SIZE, ICON_SIZE)

    -- Icon texture (BACKGROUND so Cooldown renders above it)
    local tex = slot:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(slot)
    local iconID = C_Spell.GetSpellTexture(spellID)
    if iconID then tex:SetTexture(iconID) end

    -- Cooldown sweep (timed only)
    if duration then
        local cd = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
        cd:SetAllPoints(slot)
        cd:SetDrawEdge(true)
        cd:SetHideCountdownNumbers(false) -- engine-driven integer countdown
        cd:SetCooldown(GetTime(), duration)
        slot.cd = cd
    end

    return slot
end
```

### TTS With Voice Fallback
```lua
-- Source: warcraft.wiki.gg/wiki/API_C_VoiceChat.SpeakText (12.0.0 signature)
-- Source: warcraft.wiki.gg/wiki/API_C_TTSSettings.GetVoiceOptionID
local function TrySpeak(message)
    if not message then return end
    -- Prefer player's configured voice
    local voiceID = C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)
    if not voiceID then
        -- Fall back to first available system voice
        local voices = C_VoiceChat.GetTtsVoices()
        if voices and voices[1] then
            voiceID = voices[1].voiceID
        end
    end
    if voiceID then
        C_VoiceChat.SpeakText(voiceID, message, 0, 100, false)
    end
end
```

### Pixel Glow Start/Stop
```lua
-- Source: github.com/Stanzilla/LibCustomGlow LibCustomGlow-1.0.lua
local LCG = LibStub("LibCustomGlow-1.0")
local RED = {1, 0, 0, 1}

-- At 5s remaining:
LCG.PixelGlow_Start(slot, RED, 8, 0.25, nil, 2)

-- On cancel or cycle reset:
LCG.PixelGlow_Stop(slot)
```

### Scheduler Integration Sketch
```lua
-- In Scheduler.lua — replace BossWarnings calls with ns.IconDisplay calls
-- ShowTimer equivalent:
ns.IconDisplay.ShowIcon(barId, ability.spellID, ability.ttsMessage, ability.first_cast)

-- Show (pre-warn or cast alert) — no longer needed as a separate text call;
-- IconDisplay handles urgency at 5s automatically via SetUrgent(key)

-- CancelAllTimers equivalent:
ns.IconDisplay.CancelAll()
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| C_VoiceChat.SpeakText with `destination` param | SpeakText without `destination`, adds `overlap` | Patch 12.0.0, Jan 20 2026 | All pre-Midnight code examples use wrong signature |
| GetSpellTexture (global) | C_Spell.GetSpellTexture (namespace) | Patch 11.0.0 | Both work; C_Spell preferred for future-proofing |
| ActionButton_ShowOverlayGlow | LibCustomGlow or LibButtonGlow-1.0 | ~2019 (taint discovered) | Never use Blizzard API on custom frames |

**Deprecated/outdated:**
- `C_VoiceChat.SpeakText(voiceID, text, destination, rate, volume)` — 5-arg with destination: removed in 12.0.0. Current signature is `SpeakText(voiceID, text, rate, volume, overlap)`.
- `GetSpellInfo` returning icon: still works but C_Spell.GetSpellTexture is cleaner for icon-only lookups.

---

## Open Questions

1. **Countdown number styling — built-in vs custom FontString**
   - What we know: Cooldown widget has built-in integer countdown, controlled by `SetHideCountdownNumbers`. Default behavior appears to show numbers but is not explicitly documented.
   - What's unclear: Whether the built-in number font/size/color is acceptable for this display (small, WoW-default white), or if a custom FontString is needed for legibility at the chosen icon size.
   - Recommendation: Start with built-in (`SetHideCountdownNumbers(false)`). If too small or wrong color, add a custom FontString on top. Planner can make this a discretion call.

2. **TTS availability when player has no TTS configured**
   - What we know: `GetVoiceOptionID` can return nil. `GetTtsVoices()` will list system voices if any are installed.
   - What's unclear: On some Linux/Wine setups common for WoW testing, system TTS voices may not exist.
   - Recommendation: Wrap all TTS calls defensively. If both voiceID sources fail, skip silently (no fallback sound needed per REQUIREMENTS.md "Custom sound files: Out of Scope").

3. **Scheduler API shape change scope**
   - What we know: Scheduler currently calls `BossWarnings.Show(name, dur)` and `BossWarnings.ShowTimer(id, name, dur, spellID)`. The new display needs spellID for every icon.
   - What's unclear: Whether Scheduler passes spellID to the new `ShowIcon` call (already available as `ability.spellID`) or if the display module needs to look it up.
   - Recommendation: Scheduler passes `spellID` directly — it already has it. New signature: `IconDisplay.ShowIcon(instanceKey, spellID, ttsMessage, duration)`.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — WoW addon; manual in-game verification only |
| Config file | None |
| Quick run command | `/reload` in-game after install |
| Full suite command | Manual walkthrough: enter combat with pack selected, verify icons |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DISP-01 | Icons appear at top-left in horizontal row | manual | `/tpw start` in-game, observe UI | N/A |
| DISP-02 | Timed icon shows sweep + integer countdown | manual | Select Windrunner Spire Pack 1, enter combat | N/A |
| DISP-03 | Spirit Bolt (untimed) shows one static icon | manual | Same pull as above, check Spirit Bolt icon | N/A |
| DISP-04 | Red glow appears at 5s remaining | manual | Wait for countdown to reach 5s | N/A |
| DISP-05 | TTS speaks ttsMessage at 5s | manual | Listen for voice callout at 5s mark | N/A |
| DISP-06 | BossWarnings.lua removed, no errors at load | manual | `/reload` + check for Lua errors in chat | N/A |
| DISP-08 | Two PALADINs = two timed icons for Protection | manual | Pull pack with multiple PALADIN mobs | N/A |

### Sampling Rate
- **Per task commit:** `/reload` in-game, check for Lua errors
- **Per wave merge:** Full manual walkthrough per requirement above
- **Phase gate:** All manual checks pass before `/gsd:verify-work`

### Wave 0 Gaps
- None for test infrastructure (no automated test framework applicable)
- Wave 0 must: create `Display/IconDisplay.lua`, create `Libs/LibCustomGlow/` with embedded library files, update TOC, update `scripts/install.bat`

---

## Sources

### Primary (HIGH confidence)
- [warcraft.wiki.gg/wiki/API_C_VoiceChat.SpeakText](https://warcraft.wiki.gg/wiki/API_C_VoiceChat.SpeakText) — full signature, 12.0.0 change, AllowedWhenTainted status
- [warcraft.wiki.gg/wiki/API_C_TTSSettings.GetVoiceOptionID](https://warcraft.wiki.gg/wiki/API_C_TTSSettings.GetVoiceOptionID) — voiceID retrieval, Enum.TtsVoiceType values
- [warcraft.wiki.gg/wiki/UIOBJECT_Cooldown](https://warcraft.wiki.gg/wiki/UIOBJECT_Cooldown) — SetCooldown, SetDrawEdge, SetHideCountdownNumbers, SetDrawSwipe, SetReverse methods
- [warcraft.wiki.gg/wiki/API_C_Spell.GetSpellTexture](https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellTexture) — parameters, return values, Midnight availability
- [warcraft.wiki.gg/wiki/API_PlaySoundFile](https://warcraft.wiki.gg/wiki/API_PlaySoundFile) — addon-directory .ogg support, path format
- [github.com/Stanzilla/LibCustomGlow/blob/master/LibCustomGlow-1.0.lua](https://github.com/Stanzilla/LibCustomGlow/blob/master/LibCustomGlow-1.0.lua) — PixelGlow_Start/Stop full signatures

### Secondary (MEDIUM confidence)
- [wowace.com/projects/libbuttonglow-1-0](https://www.wowace.com/projects/libbuttonglow-1-0) — LibButtonGlow-1.0 v1.3.5 (Feb 2026), taint warning confirmed
- [wowpedia.fandom.com/wiki/API_Cooldown_SetCooldown](https://wow.gamepedia.com/API_Cooldown_SetCooldown) — SetCooldown parameter semantics, CooldownFrameTemplate

### Tertiary (LOW confidence)
- WebSearch community sources for LibCustomGlow color parameter format {r,g,b,a} — consistent across multiple examples but not from official docs page directly

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs verified against warcraft.wiki.gg official documentation
- Architecture: HIGH — patterns derived directly from verified API shapes and existing project conventions
- Pitfalls: HIGH for TTS signature (documented breaking change); MEDIUM for Cooldown stacking order (community pattern, consistent)
- TTS API specifics: MEDIUM — post-12.0.0 signature confirmed from wiki, but wiki notes examples are "out of date"; live testing required

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable APIs; TTS signature change already absorbed)
