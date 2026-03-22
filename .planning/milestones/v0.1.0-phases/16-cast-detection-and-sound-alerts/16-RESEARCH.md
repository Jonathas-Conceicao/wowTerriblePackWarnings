# Phase 16: Cast Detection and Sound Alerts - Research

**Researched:** 2026-03-20
**Domain:** WoW addon engine — nameplate cast polling, sound playback, glow rendering
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Untimed Cast Highlight Behavior**
- Orange glow border (distinct from red glow used for timed 5s pre-warnings)
- Cast highlight clears when cast ends (UnitCastingInfo returns nil — next poll tick, 0.25s)
- State transition model:
  - No cast → casting: orange glow ON + play alert (if sound/TTS enabled for that skill)
  - Casting → casting: glow stays, NO repeated alert
  - Casting → no cast: glow OFF
  - No cast → casting again: glow ON + play alert again
- Default behavior: glow only (no alert). Alert playback is opt-in per skill via config toggle.
- Detection is per-class: if ANY mob of the matching class is casting, the skill glows.
- Alert only fires on state transition (not-glowing → glowing).

**Sound vs TTS Alert Delivery**
- Sound/TTS mutually exclusive per skill (decided in Phase 13, carried forward)
- PlaySound uses Master channel: `PlaySound(soundKitID, "Master")` — always audible
- No throttle — every alert fires individually.
- Timed skills: alert fires at 5 seconds before predicted cast (existing SetUrgent behavior, now with PlaySound support)
- Untimed skills: alert fires on cast detection state transition (no-glow → glow)

**UnitCastingInfo Fallback**
- Degrade gracefully if UnitCastingInfo is restricted on nameplate units
- Untimed skills show as static icons (current behavior) with no cast highlight
- Timed skills still work normally (timer-based, not cast-dependent)
- No errors, no user warning — silent fallback
- Test UnitCastingInfo("nameplateN") in first in-dungeon session

### Claude's Discretion
- spellID O(1) lookup index structure (built at NameplateScanner:Start() time per STATE.md pitfall)
- How to integrate UnitCastingInfo call into existing 0.25s Tick() loop efficiently
- Orange glow implementation (separate glow textures or recolor existing)
- How cast state tracking is stored per-class in NameplateScanner

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| HILITE-01 | Untimed skills highlight when any mob of same class is casting (via UnitCastingInfo nameplate polling) | UnitCastingInfo confirmed available on nameplate units in dungeon context; spellID at return position 9; cast state per-class stored in NameplateScanner |
| HILITE-02 | Timed skills highlight 5 seconds before cast with configured alert | SetUrgent already fires red glow + TTS; adding PlaySound call at same point covers this requirement |
| ALERT-01 | Per-skill sound alert dropdown with WoW built-in sounds (CDM-style, categorized, preview on select) | Fully implemented in Phase 13 ConfigFrame.lua — soundKitID stored in skillConfig and merged by MergeSkillConfig |
| ALERT-02 | Per-skill editable TTS text field (current text as default) | Fully implemented in Phase 13 ConfigFrame.lua — ttsMessage stored in skillConfig and merged by MergeSkillConfig |
| ALERT-03 | Alert type is sound OR TTS per skill (mutually exclusive) | Mutual exclusivity enforced in ConfigFrame.lua UI coupling; soundKitID nil means TTS mode |
</phase_requirements>

---

## Summary

Phase 16 wires together three engine changes: (1) UnitCastingInfo polling in the existing 0.25s Tick() loop to drive per-class cast state, (2) orange glow display on untimed static icons when their class is casting, and (3) PlaySound/TTS alert playback at the two trigger points — cast state transitions for untimed skills and SetUrgent for timed skills.

The WoW API documentation (verified from the local wow-ui-source repo) confirms UnitCastingInfo returns the spellID at position 9 (`castingSpellID`). The function is marked `SecretWhenUnitSpellCastRestricted` and takes `UnitTokenPvPRestrictedForAddOns` — meaning the secret behavior is PvP-only; dungeon nameplate units are not PvP-restricted, so the full return (including spellID) should be available. This matches the STATE.md note that it is "documented as PvP-restricted only, not dungeon-blocked."

ALERT-01, ALERT-02, and ALERT-03 are already fully implemented in Phase 13 (Config UI). This phase's work is purely engine plumbing: reading the soundKitID/ttsMessage values from the already-merged ability table and calling PlaySound or TrySpeak at the right moments. No UI work is needed here.

**Primary recommendation:** Extend NameplateScanner with a spellID→classBase index and a castingByClass state table; extend IconDisplay with SetCastHighlight/ClearCastHighlight using a second set of colored edge textures; add PlaySound to SetUrgent and to the cast transition path.

---

## Standard Stack

### Core
| API | Returns | Purpose |
|-----|---------|---------|
| `UnitCastingInfo(unit)` | name, displayName, textureID, startTimeMs, endTimeMs, isTradeskill, castID, notInterruptible, **castingSpellID(9)**, castBarID, delayTimeMs | Detect active cast on nameplate unit; returns nil when not casting |
| `UnitChannelInfo(unit)` | name, displayName, textureID, startTimeMs, endTimeMs, isTradeskill, notInterruptible, **spellID(8)**, isEmpowered, numEmpowerStages, castBarID | Detect active channel (different position for spellID than UnitCastingInfo) |
| `PlaySound(soundKitID, channel)` | success, soundHandle | Play a WoW built-in sound; use `"Master"` channel to bypass SFX mute |
| `C_VoiceChat.SpeakText(voiceID, text, rate, volume, overlap)` | — | TTS callout (already implemented in TrySpeak) |

### Confirmed Return Signatures

**UnitCastingInfo** (verified from `CastingBarFrame.lua` line 332 and `UnitDocumentation.lua`):
```lua
-- Position: 1       2           3          4           5         6              7        8                  9
local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
-- Returns nil (all values nil) when unit is not casting
```

**UnitChannelInfo** (verified from `CastingBarFrame.lua` line 419 and `UnitDocumentation.lua`):
```lua
-- Position: 1       2          3          4           5         6              7                  8         9            10          11
local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID, isEmpowered, numStages, castBarID = UnitChannelInfo(unit)
-- NOTE: castID is absent (no GUID), notInterruptible is at position 7 (not 8), spellID at position 8
```

**PlaySound** (verified from `SoundDocumentation.lua`):
```lua
PlaySound(soundKitID, "Master")  -- "Master" respects volume sliders but bypasses SFX-mute
PlaySound(soundKitID, "SFX")     -- SFX channel (mutable by player SFX slider)
-- Returns: success (bool), soundHandle (number)
-- "Master" confirmed by WoW community convention; Blizzard FrameXML uses "SFX" internally
```

**Note on channel string:** The Blizzard source uses `"SFX"` in its own code (e.g. `Blizzard_ArtifactPowerButton.lua`). The CONTEXT.md decision specifies `"Master"`. These are distinct channels: "SFX" is muted by the SFX slider; "Master" respects only the Master volume. Use `"Master"` as locked in the decision.

---

## Architecture Patterns

### spellID O(1) Lookup Index

Built once at `NameplateScanner:Start(pack)`, cleared at `Stop()`. Keyed by spellID for direct hash lookup in the hot loop.

```lua
-- Module-level in NameplateScanner.lua
local spellIndex = {}  -- spellID -> classBase (for untimed skills only)

-- In Scanner:Start(pack):
wipe(spellIndex)
for _, ability in ipairs(pack.abilities) do
    if not ability.cooldown then  -- untimed only; timed skills use timer system
        spellIndex[ability.spellID] = ability.mobClass
    end
end
```

This satisfies the STATE.md pitfall: "never iterate ability list per nameplate per tick."

### Cast State Tracking Per-Class

```lua
-- Module-level in NameplateScanner.lua
local castingByClass = {}  -- classBase -> bool (true = at least one mob casting a tracked spell)

-- Used in Tick() to detect transitions:
--   nil/false -> true  = new cast started
--   true -> nil/false  = cast ended
```

### UnitCastingInfo Integration in Tick()

Add a second pass after the existing combat-count loop. The existing loop already iterates all nameplates; the cast pass reuses the same `plates` table from the same tick.

```lua
function Scanner:Tick()
    -- ... existing combat-count pass (unchanged) ...

    -- Cast detection pass: build newCasting table
    local newCasting = {}  -- classBase -> bool

    for _, plate in ipairs(plates) do
        local npUnit = plate.namePlateUnitToken or plate.unitToken
        if npUnit then
            local cached = plateCache[npUnit]
            if cached and cached.hostile and cached.classBase then
                -- pcall guard for graceful fallback if API is restricted
                local ok, spellID = pcall(function()
                    local _, _, _, _, _, _, _, _, sid = UnitCastingInfo(npUnit)
                    if sid and spellIndex[sid] then return sid end
                    local _, _, _, _, _, _, _, sid2 = UnitChannelInfo(npUnit)
                    if sid2 and spellIndex[sid2] then return sid2 end
                    return nil
                end)
                if ok and spellID then
                    newCasting[cached.classBase] = true
                end
            end
        end
    end

    -- Reconcile cast state transitions
    for classBase, _ in pairs(newCasting) do
        if not castingByClass[classBase] then
            castingByClass[classBase] = true
            -- Transition: not casting -> casting
            Scanner:OnCastStart(classBase)
        end
    end
    for classBase, _ in pairs(castingByClass) do
        if not newCasting[classBase] then
            castingByClass[classBase] = nil
            -- Transition: casting -> not casting
            Scanner:OnCastEnd(classBase)
        end
    end
end
```

**Performance note:** Two API calls per nameplate per tick (UnitCastingInfo + UnitChannelInfo) in the worst case. At 20 nameplates this adds ~40 calls per tick to the existing ~20. Still well within acceptable range. Early-exit optimization: if `UnitCastingInfo` returns a non-nil spellID that exists in spellIndex, skip `UnitChannelInfo`.

### Cast Lifecycle Handlers

```lua
function Scanner:OnCastStart(classBase)
    -- Glow all untimed static icons whose mobClass == classBase
    for _, ability in ipairs(activePack.abilities) do
        if not ability.cooldown and ability.mobClass == classBase then
            local key = "static_" .. ability.spellID
            ns.IconDisplay.SetCastHighlight(key, ability)
        end
    end
end

function Scanner:OnCastEnd(classBase)
    for _, ability in ipairs(activePack.abilities) do
        if not ability.cooldown and ability.mobClass == classBase then
            local key = "static_" .. ability.spellID
            ns.IconDisplay.ClearCastHighlight(key)
        end
    end
end
```

**Alternative considered:** Store the ability reference in spellIndex for O(1) OnCastStart/OnCastEnd. This avoids iterating activePack.abilities at cast time. Use this if cast frequency is high in testing. The current pattern (iterate abilities) is fine for typical 1-3 cast events per combat.

### Orange Glow in IconDisplay

The existing `CreateGlowTextures` builds 4 red edge textures (OVERLAY, color 1,0,0,1). Orange glow uses a parallel set of textures with color (1, 0.5, 0, 1). Two options:

**Option A: Separate orange textures (recommended)**
```lua
local function CreateCastGlowTextures(slot)
    if slot.castGlowTextures then return end
    local g = {}
    local color = {1, 0.5, 0, 1}  -- orange
    -- Same geometry as CreateGlowTextures but different field name and color
    g.top    = slot:CreateTexture(nil, "OVERLAY")
    g.top:SetColorTexture(color[1], color[2], color[3], color[4])
    g.top:SetPoint("TOPLEFT",    slot, "TOPLEFT",    0, 0)
    g.top:SetPoint("TOPRIGHT",   slot, "TOPRIGHT",   0, 0)
    g.top:SetHeight(GLOW_WIDTH)
    -- ... (bottom, left, right same pattern) ...
    slot.castGlowTextures = g
end

local function ShowCastGlow(slot)
    CreateCastGlowTextures(slot)
    for _, tex in pairs(slot.castGlowTextures) do tex:Show() end
end

local function HideCastGlow(slot)
    if not slot.castGlowTextures then return end
    for _, tex in pairs(slot.castGlowTextures) do tex:Hide() end
end
```

**Option B: Recolor existing textures**
Call `glowTextures.top:SetColorTexture(1, 0.5, 0, 1)` to switch color. Simpler but requires tracking "current glow color" and restoring to red after. Rejected: SetUrgent could fire while cast glow is active (timed ability), causing a color conflict.

**Decision for planner:** Use Option A (separate cast glow textures). Avoids any state conflict with the red urgent glow.

New public methods on IconDisplay:
```lua
function ns.IconDisplay.SetCastHighlight(instanceKey, ability)
    local slot = slotsByKey[instanceKey]
    if not slot then return end
    ShowCastGlow(slot)
    -- Fire alert on transition (caller guarantees this is only called once per transition)
    if ability.soundKitID then
        PlaySound(ability.soundKitID, "Master")
    elseif ability.ttsMessage then
        TrySpeak(ability.ttsMessage)
    end
end

function ns.IconDisplay.ClearCastHighlight(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end
    HideCastGlow(slot)
end
```

### PlaySound Addition to SetUrgent

```lua
function ns.IconDisplay.SetUrgent(instanceKey)
    local slot = slotsByKey[instanceKey]
    if not slot then return end

    ShowGlow(slot)  -- red glow (existing)

    -- Sound/TTS alert (new in Phase 16)
    if slot.soundKitID then
        PlaySound(slot.soundKitID, "Master")
    else
        TrySpeak(slot.ttsMessage)  -- existing behavior preserved
    end

    dbg("SetUrgent: " .. instanceKey)
end
```

This requires `slot.soundKitID` to be stored at ShowIcon time. ShowIcon must accept and store the soundKitID from the ability.

### ShowIcon Signature Extension

```lua
-- Current:
function ns.IconDisplay.ShowIcon(instanceKey, spellID, ttsMessage, duration, label)

-- Extended:
function ns.IconDisplay.ShowIcon(instanceKey, spellID, ttsMessage, duration, label, soundKitID)
    -- ...existing...
    slot.soundKitID = soundKitID  -- may be nil (TTS mode)
end
```

Scheduler must pass `ability.soundKitID` when calling ShowIcon:
```lua
-- In scheduleAbility():
ns.IconDisplay.ShowIcon(barId, ability.spellID, ability.ttsMessage, ability.first_cast, ability.label, ability.soundKitID)
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cast detection | Custom event listener or timer-based inference | `UnitCastingInfo` / `UnitChannelInfo` in existing 0.25s tick | API is already available on nameplate units in dungeon context |
| Sound playback | Custom audio system | `PlaySound(soundKitID, "Master")` | Native WoW API; handles all channel routing, volume scaling |
| TTS | Custom synthesis | `C_VoiceChat.SpeakText` | Already implemented in `TrySpeak`; don't duplicate |
| Cast state machine | Per-unit tracking table | Per-class boolean in `castingByClass` | Individual mob tracking not reliable (mob can be off-screen); class-level is the right granularity |

---

## Common Pitfalls

### Pitfall 1: UnitChannelInfo spellID position differs from UnitCastingInfo
**What goes wrong:** Code uses position 9 for both functions (treating them as symmetric). UnitChannelInfo has no `castID` field, shifting all subsequent positions. spellID is at position 8 in UnitChannelInfo, position 9 in UnitCastingInfo.
**How to avoid:** Use named local variables, not numeric select(). Reference the verified signatures above.
**Warning signs:** Cast detection working for casts but not channels, or channels always returning nil spellID.

### Pitfall 2: spellIndex not cleared at Scanner:Stop()
**What goes wrong:** Stale spellIndex from previous pack persists into next pack. Wrong abilities respond to casts.
**How to avoid:** `wipe(spellIndex)` and `wipe(castingByClass)` in both `Scanner:Stop()` and before populating in `Scanner:Start(pack)`.

### Pitfall 3: SetCastHighlight called on non-existent slot
**What goes wrong:** Cast starts before static icon is shown (e.g., mob enters combat but pack hasn't fired OnMobsAdded yet). nil slot causes a no-op but could mask a bug.
**How to avoid:** `if not slot then return end` guard (already shown in pattern above). This is correct behavior — no slot means the icon isn't visible yet, so no glow needed.

### Pitfall 4: Cast glow and urgent glow on same icon simultaneously
**What goes wrong:** A timed skill's red urgent glow (SetUrgent) fires while the class is also casting. If glow textures are shared, they conflict.
**How to avoid:** Use separate `glowTextures` (red, SetUrgent) and `castGlowTextures` (orange, SetCastHighlight) on the same slot. They can coexist visually — both sets of 4 edge textures shown at once.

### Pitfall 5: Alert fires for timed skills via both SetUrgent and SetCastHighlight
**What goes wrong:** A timed skill that is also tracked by the cast detection system fires its alert twice — once from the timer (SetUrgent) and once from the cast poll.
**How to avoid:** spellIndex should only contain untimed skills (`if not ability.cooldown`). Timed skills only alert via SetUrgent.

### Pitfall 6: castingByClass not reset between combat sessions
**What goes wrong:** Combat ends with a class still marked as casting. Next combat starts with orange glow already on.
**How to avoid:** `wipe(castingByClass)` in `Scanner:Stop()`.

### Pitfall 7: plates table reuse across Tick() passes
**What goes wrong:** The cast detection pass builds `local plates = C_NamePlate.GetNamePlates()` independently from the combat-count pass, doubling the API call.
**How to avoid:** Capture `plates` once at the top of `Tick()` and reuse for both passes.

---

## Code Examples

### spellIndex Build (Start)
```lua
-- Source: verified against existing NameplateScanner:Start() pattern
function Scanner:Start(pack)
    if tickerHandle then return end
    activePack = pack
    wipe(prevCounts)
    wipe(classBarIds)
    wipe(staticShown)
    wipe(spellIndex)       -- new
    wipe(castingByClass)   -- new
    timerCounter = 0

    -- Build O(1) lookup for untimed spell detection
    for _, ability in ipairs(pack.abilities) do
        if not ability.cooldown then
            spellIndex[ability.spellID] = ability.mobClass
        end
    end

    tickerHandle = C_Timer.NewTicker(0.25, function() Scanner:Tick() end)
    Scanner:Tick()
end
```

### Cast Detection in Tick()
```lua
-- Source: verified UnitCastingInfo signature from CastingBarFrame.lua line 332
-- Integrated after existing combat-count reconcile block

local newCasting = {}
for _, plate in ipairs(plates) do  -- reuse plates captured at top of Tick()
    local npUnit = plate.namePlateUnitToken or plate.unitToken
    if npUnit then
        local cached = plateCache[npUnit]
        if cached and cached.hostile and cached.classBase then
            local sid
            local ok, result = pcall(function()
                local _,_,_,_,_,_,_,_, s = UnitCastingInfo(npUnit)
                if s and spellIndex[s] then return s end
                local _,_,_,_,_,_,_, s2 = UnitChannelInfo(npUnit)
                if s2 and spellIndex[s2] then return s2 end
                return nil
            end)
            if ok then sid = result end
            if sid then
                newCasting[cached.classBase] = true
            end
        end
    end
end

for classBase in pairs(newCasting) do
    if not castingByClass[classBase] then
        castingByClass[classBase] = true
        Scanner:OnCastStart(classBase)
    end
end
for classBase in pairs(castingByClass) do
    if not newCasting[classBase] then
        castingByClass[classBase] = nil
        Scanner:OnCastEnd(classBase)
    end
end
```

### Orange Glow via Separate Textures
```lua
-- Source: extends existing CreateGlowTextures pattern in IconDisplay.lua
local function CreateCastGlowTextures(slot)
    if slot.castGlowTextures then return end
    local g = {}
    g.top = slot:CreateTexture(nil, "OVERLAY")
    g.top:SetColorTexture(1, 0.5, 0, 1)
    g.top:SetPoint("TOPLEFT",  slot, "TOPLEFT",  0, 0)
    g.top:SetPoint("TOPRIGHT", slot, "TOPRIGHT", 0, 0)
    g.top:SetHeight(GLOW_WIDTH)
    g.bottom = slot:CreateTexture(nil, "OVERLAY")
    g.bottom:SetColorTexture(1, 0.5, 0, 1)
    g.bottom:SetPoint("BOTTOMLEFT",  slot, "BOTTOMLEFT",  0, 0)
    g.bottom:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 0, 0)
    g.bottom:SetHeight(GLOW_WIDTH)
    g.left = slot:CreateTexture(nil, "OVERLAY")
    g.left:SetColorTexture(1, 0.5, 0, 1)
    g.left:SetPoint("TOPLEFT",    slot, "TOPLEFT",    0, 0)
    g.left:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 0, 0)
    g.left:SetWidth(GLOW_WIDTH)
    g.right = slot:CreateTexture(nil, "OVERLAY")
    g.right:SetColorTexture(1, 0.5, 0, 1)
    g.right:SetPoint("TOPRIGHT",    slot, "TOPRIGHT",    0, 0)
    g.right:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 0, 0)
    g.right:SetWidth(GLOW_WIDTH)
    slot.castGlowTextures = g
end
```

---

## Requirement Coverage

| Req | Status | How Met |
|-----|--------|---------|
| HILITE-01 | New engine work | spellIndex + castingByClass in NameplateScanner; SetCastHighlight/ClearCastHighlight in IconDisplay |
| HILITE-02 | Partial (add PlaySound) | SetUrgent already fires red glow + TTS; add PlaySound call; pass soundKitID through ShowIcon → slot |
| ALERT-01 | Already complete (Phase 13) | soundKitID stored in skillConfig; MergeSkillConfig passes it through to pack.abilities |
| ALERT-02 | Already complete (Phase 13) | ttsMessage stored in skillConfig; MergeSkillConfig passes it through |
| ALERT-03 | Already complete (Phase 13) | ConfigFrame.lua disables TTS editbox when soundKitID != nil; nil soundKitID means TTS mode |

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual in-game testing (no automated test harness for WoW addon) |
| Config file | n/a |
| Quick run command | `./scripts/install.bat` then `/reload` |
| Full suite command | Pull mobs in Windrunner Spire with imported route |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Verification |
|--------|----------|-----------|-------------|
| HILITE-01 | Untimed skill icon shows orange glow when a same-class mob casts | Manual in-dungeon | Pull a Windrunner Spire pack, observe orange glow when mob casts |
| HILITE-01 | Orange glow clears within 0.25s after cast ends | Manual in-dungeon | Watch glow disappear after cast finishes |
| HILITE-01 | No repeated alert while cast is ongoing | Manual in-dungeon | Verify sound/TTS plays once per cast, not every 0.25s |
| HILITE-02 | Timed skill shows red glow + fires sound/TTS at 5s pre-warning | Manual in-dungeon | Configure a sound for a timed skill, observe alert at 5s mark |
| ALERT-01/02/03 | Sound or TTS plays at alert trigger, not both | Manual in-dungeon | Configure sound; confirm no TTS fires simultaneously |
| HILITE-01 | Graceful fallback if UnitCastingInfo restricted | Manual (first dungeon test) | Confirm no Lua errors if API returns nil silently |

### Sampling Rate
- **Per task commit:** Install and do `/tpw status` — verify no Lua errors
- **Per wave merge:** Full in-dungeon pull test in Windrunner Spire
- **Phase gate:** All HILITE and ALERT requirements verified before `/gsd:verify-work`

### Wave 0 Gaps
None — no automated test infrastructure required. All validation is manual in-game.

---

## Open Questions

1. **UnitCastingInfo on nameplate units in Midnight 12.0**
   - What we know: API docs say `UnitTokenPvPRestrictedForAddOns` and `SecretWhenUnitSpellCastRestricted` — both are PvP-only restrictions per documentation and STATE.md research
   - What's unclear: Whether Midnight introduced any additional restrictions beyond PvP zones
   - Recommendation: Test on first in-dungeon session; pcall guard is in place for silent fallback

2. **UnitChannelInfo spellID position — position 7 vs 8**
   - What we know: The UnitDocumentation.lua lists notInterruptible(7), spellID(8). CastingBarFrame.lua line 419 uses: `name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID, isEmpowered, numStages, castBarID` — confirms 8.
   - What's unclear: Nothing — both sources agree.
   - Recommendation: Use position 8.

---

## Sources

### Primary (HIGH confidence)
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` — UnitCastingInfo and UnitChannelInfo return signatures, PvP restriction type
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/CastingBarFrame.lua` lines 332, 419 — Blizzard's own usage confirming position-based destructuring of both functions
- `C:/Users/jonat/Repositories/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/SoundDocumentation.lua` — PlaySound signature with uiSoundSubType parameter
- `Engine/NameplateScanner.lua` — current Tick() structure, plateCache, classBarIds
- `Engine/Scheduler.lua` — scheduleAbility, SetUrgent call site, barTimers
- `Display/IconDisplay.lua` — CreateGlowTextures, ShowGlow/HideGlow, SetUrgent, TrySpeak
- `Import/Pipeline.lua` — MergeSkillConfig showing soundKitID flows through to pack.abilities
- `Data/Sounds.lua` — AlertSounds catalog confirming soundKitID = nil means TTS

### Secondary (MEDIUM confidence)
- WoW community convention: `"Master"` string for PlaySound bypasses SFX channel mute. Blizzard source uses `"SFX"`. Both are valid strings; the decision to use `"Master"` is locked in CONTEXT.md.

---

## Metadata

**Confidence breakdown:**
- UnitCastingInfo API: HIGH — verified from wow-ui-source APIDocumentation and CastingBarFrame usage
- UnitChannelInfo API: HIGH — same sources, both agree on position 8 for spellID
- PlaySound channel string: MEDIUM — `"Master"` is convention, Blizzard internally uses `"SFX"`; locked by user decision
- Orange glow implementation: HIGH — direct extension of existing CreateGlowTextures pattern
- Cast state tracking design: HIGH — extends existing classBarIds pattern with a castingByClass table
- MergeSkillConfig soundKitID flow: HIGH — read directly from Pipeline.lua source

**Research date:** 2026-03-20
**Valid until:** 2026-04-20 (WoW API stable; Midnight not in rapid flux)
