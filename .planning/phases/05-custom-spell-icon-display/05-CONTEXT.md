# Phase 5: Custom Spell Icon Display - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a custom spell icon display system replacing all legacy display adapters (DBM, Encounter Timeline, RaidNotice). Render horizontal square spell icons at top-left of screen with cooldown sweep animations, red glow urgency, and TTS warnings. Remove Display/BossWarnings.lua entirely.

</domain>

<decisions>
## Implementation Decisions

### Icon Layout
- Horizontal row of square spell icons anchored at **top-left** of screen
- Icons grow **rightward** toward center as abilities are tracked
- Each square shows the **spell icon** from spellID (via GetSpellTexture or equivalent)
- Timed abilities: **cooldown sweep animation** (WoW-style clock) + **integer countdown** number
- Untimed abilities: **static icon** only (no sweep, no countdown), **one icon** regardless of mob count
- Timed abilities show **one icon per mob instance** (multiple mobs = multiple squares)

### Urgency Indicators
- **Red glow border** appears on timed squares when **5 seconds remain** before cast
- No other color shifts or animations for urgency

### TTS Warnings
- TTS fires for **timed abilities only** at 5 seconds remaining — untimed icons are silent
- Each ability entry has a custom `ttsMessage` field with a short callout (e.g. "Shield")
- TTS does NOT use the full ability name — short combat-ready callouts only
- Data schema addition: `ttsMessage = "Shield"` on Spellguard's Protection, no ttsMessage on Spirit Bolt (untimed)
- **TTS API is uncertain** — researcher should investigate what's available in Midnight (C_VoiceChat.SpeakText, PlaySoundFile with bundled voice files from DBM, or other options)

### Legacy Adapter Removal
- **Delete** `Display/BossWarnings.lua` entirely
- **Remove** all references to `ns.BossWarnings` from Scheduler.lua
- Scheduler.lua calls to `BossWarnings.Show()`, `BossWarnings.ShowTimer()`, `BossWarnings.CancelAllTimers()` replaced with new display system API
- TOC file updated to remove BossWarnings.lua entry and add new display file

### Claude's Discretion
- Icon square size and spacing
- Border style when not glowing
- Whether icons appear/disappear with animation or instantly
- Sweep direction (clockwise vs counterclockwise)
- How timer reset looks visually when a repeating ability cycles
- New display module file name and API shape
- How to handle the Scheduler → Display integration (callback, direct call, event)

</decisions>

<specifics>
## Specific Ideas

- Reference: old dungeon WeakAura packs (wago.io/vAOPlg91t) — square icon grid with spell textures and cooldown overlays
- The display should feel like WeakAura icon groups, not like DBM bars
- Short TTS callouts like "Shield" are more useful in combat than full ability names

</specifics>

<code_context>
## Existing Code Insights

### Files to Remove
- `Display/BossWarnings.lua`: 187 lines — entire legacy adapter system (DBM, ET, RaidNotice)

### Files to Modify
- `Engine/Scheduler.lua`: Lines 40, 49 call `ns.BossWarnings.Show()`; lines 64, 107 call `ns.BossWarnings.ShowTimer()` / `CancelAllTimers()`
- `TerriblePackWarnings.toc`: Remove `Display\BossWarnings.lua`, add new display file
- `scripts/install.bat`: Remove Display directory copy, add new display file copy

### Established Patterns
- `local addonName, ns = ...` namespace for all files
- Modules expose API on `ns` namespace (e.g. `ns.PackUI`, `ns.Scheduler`)
- Debug logging with `dbg()` helper function

### Integration Points
- Scheduler calls display module for: ShowTimer (timed bar), Show (text alert), CancelAllTimers
- New display module needs: Show icon, Start cooldown, Cancel icon, Cancel all, Red glow at 5s, TTS at 5s
- CombatWatcher triggers Scheduler:Start/Stop — display follows from Scheduler

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-custom-spell-icon-display*
*Context gathered: 2026-03-15*
