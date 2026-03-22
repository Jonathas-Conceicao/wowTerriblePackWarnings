# Phase 16: Cast Detection and Sound Alerts - Context

**Gathered:** 2026-03-20
**Updated:** 2026-03-21 (post-implementation findings recorded)
**Status:** Complete

<domain>
## Phase Boundary

Engine features: untimed skill highlighting via UnitCastingInfo nameplate polling, timed skill pre-warning at 5 seconds with configured sound or TTS, and alert delivery with per-skill sound/TTS configuration. Last phase of v0.1.0 milestone.

</domain>

<decisions>
## Implementation Decisions

### Untimed Cast Highlight Behavior
- Orange glow border (distinct from red glow used for timed 5s pre-warnings)
- Cast highlight clears when cast ends (UnitCastingInfo returns nil — next poll tick, 0.25s)
- State transition model for alerts:
  - No cast → casting: orange glow ON + play alert (if sound/TTS enabled for that skill)
  - Casting → casting: glow stays, NO repeated alert
  - Casting → no cast: glow OFF
  - No cast → casting again: glow ON + play alert again
- Default behavior: glow only (no alert). Alert playback is opt-in per skill via config toggle.
- Since individual mobs can't be tracked reliably, detection is per-class: if ANY mob of the matching class is casting, the skill glows. Alert only fires on state transition (not-glowing → glowing).

### Sound vs TTS Alert Delivery
- Sound/TTS mutually exclusive per skill (decided in Phase 13, carried forward)
- PlaySound uses Master channel: `PlaySound(soundKitID, "Master")` — always audible
- No throttle — every alert fires individually. Users manage noise via config toggles.
- Timed skills: alert fires at 5 seconds before predicted cast (existing SetUrgent behavior, now with PlaySound support)
- Untimed skills: alert fires on cast detection state transition (no-glow → glow)

### UnitCastingInfo — Secret Values (Discovered During Implementation)
- UnitCastingInfo IS available on nameplate units in Midnight dungeons
- However, spellID (return position 9) is a **Secret Value** — cannot be used as table key ("table index is secret")
- UnitChannelInfo spellID (position 8) has the same restriction
- UnitHealth / UnitHealthMax are also Secret Values — cannot do math
- **What works:** UnitCastingInfo name (position 1) returns a usable string
- Cast detection uses **name presence check** (non-nil = casting) instead of spellID matching
- Detection is class-based: if ANY mob of tracked class is casting anything, glow all untimed skills for that class
- pcall wraps all UnitCastingInfo/UnitChannelInfo calls for silent fallback

### Glow Implementation (Resolved During Implementation)
- ActionButton_ShowOverlayGlow is NOT available as a global in Midnight (moved to Blizzard_ActionBar mixin)
- Both red (timed pre-warning) and orange (cast detection) glows use 2px edge textures via CreateGlowTextures
- CreateGlowTextures is parameterized: `(slot, r, green, b, field)` — separate texture sets for red and orange
- Both glow types can coexist on the same icon slot without conflict

### Claude's Discretion (Resolved)
- spellID index built at Start() — stores untimed abilities for class lookup (not used as table key)
- UnitCastingInfo polled in Tick() after UnitAffectingCombat check, wrapped in pcall
- Orange glow uses separate `castGlowTextures` field (not recolored `glowTextures`)
- Cast state tracked per-class via `castingByClass` table, wiped at Start() and Stop()

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Engine Code
- `Engine/NameplateScanner.lua` — 0.25s poll loop, OnMobsAdded/OnMobsRemoved, UnitClass matching, plateCache
- `Engine/Scheduler.lua` — timer scheduling with per-barId tracking, SetUrgent 5s pre-warning
- `Display/IconDisplay.lua` — ShowIcon, ShowStaticIcon, SetUrgent (red glow + TTS), CancelIcon, glow textures

### Alert System
- `Data/Sounds.lua` — ns.AlertSounds catalog (TTS + 11 CDM soundKitIDs)
- `UI/ConfigFrame.lua` — per-skill soundKitID and ttsMessage in skillConfig, sound dropdown popup

### STATE.md Pitfalls
- Build spellID O(1) lookup index at NameplateScanner:Start() — never iterate ability list per nameplate per tick
- Alert throttle table simultaneously with PlaySound (user chose no throttle — skip this)
- Validate UnitCastingInfo("nameplateN") in first in-dungeon test session

### Import Pipeline
- `Import/Pipeline.lua` — MergeSkillConfig merges soundKitID into ability; BuildPack produces pack.abilities with soundKitID field

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `IconDisplay.lua` ShowGlow/HideGlow — red glow textures, reusable pattern for orange glow variant
- `IconDisplay.lua` TrySpeak — TTS callout, reusable for untimed cast alerts
- `IconDisplay.lua` SetUrgent — fires red glow + TTS at 5s pre-warning, needs PlaySound addition
- `NameplateScanner.lua` plateCache — existing per-nameplate cache with UnitClass, UnitCanAttack, UnitAffectingCombat

### Established Patterns
- plateCache populated at NAME_PLATE_UNIT_ADDED, only UnitAffectingCombat polled in hot loop
- classBarIds tracks per-class timer bar IDs in NameplateScanner
- Scheduler fires SetUrgent 5 seconds before ability cast time

### Integration Points
- `NameplateScanner:Start(pack)` — build spellID index from pack.abilities here
- `NameplateScanner:Tick()` — add UnitCastingInfo poll after existing UnitAffectingCombat check
- `IconDisplay.SetUrgent` — add PlaySound(soundKitID, "Master") when ability has soundKitID
- `IconDisplay` — add SetCastHighlight/ClearCastHighlight for orange glow (new methods)

</code_context>

<specifics>
## Specific Ideas

- Orange glow = visually distinct from red. Orange means "mob is casting NOW", red means "ability coming in 5 seconds"
- State transition model prevents alert spam: only fires on the edge (no-glow → glow), not while already glowing
- Master audio channel ensures alerts are always heard even if player has SFX muted

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 16-cast-detection-and-sound-alerts*
*Context gathered: 2026-03-20*
