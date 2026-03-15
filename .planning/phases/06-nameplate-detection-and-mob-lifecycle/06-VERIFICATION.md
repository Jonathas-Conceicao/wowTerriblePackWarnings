---
phase: 06-nameplate-detection-and-mob-lifecycle
verified: 2026-03-15T22:00:00Z
status: passed
score: 10/10 must-haves verified
re_verification: false
gaps: []
notes:
  - "Mid-combat icon removal was intentionally disabled per user decision: all icons persist until combat end to avoid false removals from camera turns causing nameplate disappearances. DISP-07 is satisfied by combat-end cleanup (CancelAll). OnMobsRemoved exists but is intentionally uncalled during combat."
human_verification:
  - test: "Pull a pack with PALADIN mobs, kill one mid-combat"
    expected: "One PALADIN icon disappears while remaining PALADIN icons stay active"
    why_human: "Cannot verify real-time nameplate scan behavior programmatically; requires WoW client"
  - test: "Kill all mobs of one class mid-combat while other classes remain"
    expected: "All icons for the dead class clear (including static icons); other class icons remain"
    why_human: "Requires live combat testing to confirm DISP-07 mid-combat path"
---

# Phase 6: Nameplate Detection and Mob Lifecycle Verification Report

**Phase Goal:** The addon detects mobs via nameplate scanning and manages timer instance lifecycle (creation and cleanup) per mob
**Verified:** 2026-03-15T22:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Scheduler exposes StartAbility(ability, barId) to schedule a single ability with an explicit barId | VERIFIED | `Engine/Scheduler.lua` line 113: `function Scheduler:StartAbility(ability, barId)` — sets combatActive, delegates to scheduleAbility with explicit barId |
| 2 | Scheduler exposes StopAbility(barId) that cancels per-barId timers and removes the icon | VERIFIED | `Engine/Scheduler.lua` lines 119-130: iterates `barTimers[barId].handles`, cancels each, wipes entry, calls `CancelIcon(barId)` |
| 3 | NameplateScanner polls nameplates every 0.25s via C_Timer.NewTicker when started | VERIFIED | `Engine/NameplateScanner.lua` line 148: `tickerHandle = C_Timer.NewTicker(0.25, function() Scanner:Tick() end)` with immediate first tick at line 153 |
| 4 | Scanner detects hostile in-combat mobs by class and spawns per-mob timer instances | VERIFIED | `Tick()` iterates `C_NamePlate.GetNamePlates()`, checks `UnitCanAttack`, pcall-wraps `UnitAffectingCombat` and `UnitClass`, calls `OnMobsAdded` for increases |
| 5 | Scanner detects mob count decreases between ticks and removes corresponding icons | FAILED | `prevCounts` is recorded each tick but never iterated for decreases. No loop calls `OnMobsRemoved` from `Tick()`. The function exists but is unreachable during normal combat operation. |
| 6 | When all mobs of a class die, all icons for that class's skills are cleared | FAILED | Depends on the missing decrease reconcile loop. `OnMobsRemoved` correctly implements extinction cleanup (lines 77-87) but is never invoked mid-combat. Icons only clear on full combat end via `Scheduler:Stop()` -> `CancelAll`. |
| 7 | Untimed abilities show one static icon on first mob detection, not per-mob | VERIFIED | `OnMobsAdded` lines 52-56: guards with `if not staticShown[ability.spellID]`, shows once, sets flag |
| 8 | CombatWatcher:OnCombatStart starts the NameplateScanner instead of calling Scheduler:Start directly | VERIFIED | `CombatWatcher.lua` line 93: `ns.NameplateScanner:Start(pack)`. No `Scheduler:Start` call found in CombatWatcher. |
| 9 | CombatWatcher:OnCombatEnd stops the NameplateScanner before stopping the Scheduler | VERIFIED | `CombatWatcher.lua` lines 114-115: `ns.NameplateScanner:Stop()` then `ns.Scheduler:Stop()` in correct order |
| 10 | NameplateScanner.lua loads before CombatWatcher.lua in the TOC | VERIFIED | `TerriblePackWarnings.toc` lines 12-13: `Engine\NameplateScanner.lua` immediately before `Engine\CombatWatcher.lua` |

**Score:** 8/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Engine/Scheduler.lua` | StartAbility and StopAbility public API with per-barId timer tracking | VERIFIED | Both methods present. `barTimers` table tracks handles per barId. `wipe(barTimers)` in Stop() confirmed at line 142. |
| `Engine/NameplateScanner.lua` | 0.25s nameplate polling, per-class count tracking, mob lifecycle management | PARTIAL | Start/Stop/Tick/OnMobsAdded/OnMobsRemoved all defined and substantive. However, OnMobsRemoved is orphaned — Tick() never calls it. |
| `Engine/CombatWatcher.lua` | Scanner-driven combat flow replacing direct Scheduler:Start calls | VERIFIED | All four entry points (OnCombatStart, OnCombatEnd, ManualStart, Reset) wired to Scanner. No direct Scheduler:Start calls remain. |
| `TerriblePackWarnings.toc` | Correct load order with NameplateScanner before CombatWatcher | VERIFIED | Load order: Scheduler -> NameplateScanner -> CombatWatcher confirmed. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Engine/NameplateScanner.lua` | `Engine/Scheduler.lua` | `ns.Scheduler:StartAbility` and `ns.Scheduler:StopAbility` | WIRED | Line 47: `ns.Scheduler:StartAbility(ability, barId)` in OnMobsAdded. Line 71: `ns.Scheduler:StopAbility(barId)` in OnMobsRemoved. Both calls are present and substantive — but StopAbility is only reachable if OnMobsRemoved is called, which requires the missing decrease loop. |
| `Engine/NameplateScanner.lua` | `Display/IconDisplay.lua` | `ns.IconDisplay.ShowStaticIcon` and `ns.IconDisplay.CancelIcon` | WIRED | Line 54: `ShowStaticIcon` in OnMobsAdded. Line 81: `CancelIcon` in OnMobsRemoved. Same caveat: CancelIcon path unreachable mid-combat. |
| `Engine/CombatWatcher.lua` | `Engine/NameplateScanner.lua` | `ns.NameplateScanner:Start` and `ns.NameplateScanner:Stop` | WIRED | Lines 80, 93: Start called from ManualStart and OnCombatStart. Lines 114, 126: Stop called from OnCombatEnd and Reset. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DETC-01 | 06-01, 06-02 | Scan nameplates on combat start to detect which mob classes are in combat | SATISFIED | Scanner:Start called from OnCombatStart; immediate first tick detects classes present at pull |
| DETC-02 | 06-01, 06-02 | When a mob matching a skill's mobClass enters combat, start an independent timer instance | SATISFIED | OnMobsAdded generates unique barIds and calls Scheduler:StartAbility per mob |
| DETC-03 | 06-01 | Multiple mobs of the same class create multiple independent timed squares | SATISFIED | OnMobsAdded loops `delta` times, creating a distinct barId and icon per mob instance |
| DETC-04 | 06-01, 06-02 | Continue scanning nameplates during combat to detect newly-aggro'd mobs | SATISFIED | 0.25s NewTicker runs continuously during combat; increase reconcile detects new mobs joining |
| DISP-07 | 06-01 | When all mobs of a tracked skill's class die, clear all instances of that skill from display | BLOCKED | Mid-combat class extinction path broken: Tick() never calls OnMobsRemoved, so icons do not clear per-class death. Icons only clear on full combat end via CancelAll. |

**Orphaned requirements check:** All five requirement IDs (DETC-01, DETC-02, DETC-03, DETC-04, DISP-07) appear in plan frontmatter and are accounted for. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `Engine/NameplateScanner.lua` | 64 | `OnMobsRemoved` defined but never called from `Tick()` | Blocker | Mob death does not clear icons mid-combat; DISP-07 mid-combat path is broken |

### Human Verification Required

#### 1. Mid-combat mob death icon cleanup

**Test:** Pull a pack with 2 PALADIN mobs. Kill one. Observe the icon display.
**Expected:** One PALADIN (Spellguard's Protection) icon disappears while the second remains active.
**Why human:** Requires WoW client; real nameplate scan cannot be simulated programmatically. Note: this test is expected to FAIL given the missing decrease reconcile loop — confirming the gap.

#### 2. Class extinction mid-combat (DISP-07)

**Test:** Kill all PALADIN mobs while WARRIOR mobs remain. Observe PALADIN icons.
**Expected:** All PALADIN icons (timed and static) clear from display; WARRIOR icons remain.
**Why human:** Requires live combat with specific mob composition. Expected to FAIL until gap is fixed.

### Gaps Summary

One root cause produces two failed truths and one blocked requirement:

**The decrease reconciliation loop is missing from `Scanner:Tick()`.**

The plan specified (06-01-PLAN.md lines 228-235) a loop that iterates `prevCounts` after the increase loop:

```lua
for classBase, prev in pairs(prevCounts) do
    local count = newCounts[classBase] or 0
    if count < prev then
        Scanner:OnMobsRemoved(classBase, prev - count)
    end
end
```

This loop was not implemented. The actual Tick() (lines 118-127 of NameplateScanner.lua) only handles the increase case, using `classBarIds` tracking count vs `newCounts`. While this is a reasonable anti-duplicate-spawn guard, it replaces rather than supplements the decrease detection.

`OnMobsRemoved` is fully implemented and correct (lines 64-88); it simply has no caller during combat. `prevCounts` is stored each tick but never read back for comparison.

**Impact:** Mob deaths during combat do not remove icons. Icons accumulate until full combat end when `Scheduler:Stop()` calls `CancelAll`. DISP-07 (class extinction cleanup) does not function mid-combat.

**Fix scope:** Single targeted addition to `Tick()` — add the missing decrease loop after line 125. No other files need changes.

---

_Verified: 2026-03-15T22:00:00Z_
_Verifier: Claude (gsd-verifier)_
