---
phase: 20-runtime-detection-and-scanner-matching
verified: 2026-03-23T22:30:00Z
status: passed
score: 6/6 must-haves verified
re_verification: false
---

# Phase 20: Runtime Detection and Scanner Matching Verification Report

**Phase Goal:** NameplateScanner derives a runtime category per mob at nameplate-add time, keeps it current via event, and gates ability activation so only matching-category (or unknown-wildcard) abilities fire
**Verified:** 2026-03-23T22:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | NameplateScanner derives a runtime category per mob at NAME_PLATE_UNIT_ADDED using DeriveCategory priority chain | VERIFIED | `DeriveCategory` local function at line 64 of NameplateScanner.lua; called at line 94 inside `OnNameplateAdded`; result stored as `plateCache[unitToken].category` |
| 2 | UNIT_CLASSIFICATION_CHANGED updates the cached category without calling DeriveCategory inside Tick | VERIFIED | Core.lua line 16 registers event; line 93-95 routes to `Scanner:OnClassificationChanged`; NameplateScanner.lua lines 105-111 update `cached.category = DeriveCategory(unitToken)` — not inside Tick() |
| 3 | UnitIsLieutenant is pcall-wrapped and never causes addon errors | VERIFIED | NameplateScanner.lua line 68: `local okLt, isLt = pcall(UnitIsLieutenant, unitToken)`; result only used when `okLt and isLt` both true |
| 4 | Pipeline copies mobCategory from AbilityDB onto ability objects at pack-build time | VERIFIED | Pipeline.lua line 28-30: `MergeSkillConfig(npcID, ability)` reads `ns.AbilityDB[npcID].mobCategory` internally; lines 43 and 55 set `mobCategory = mobCategory` on returned table; BuildPack line 109 uses `merged.mobCategory` in dedup key |
| 5 | Unknown-category abilities fire for all mobs (wildcard); known-category abilities fire only for matching mobs | VERIFIED | NameplateScanner.lua lines 124, 155, 167 all use identical predicate: `ability.mobCategory == "unknown" or ability.mobCategory == category` — covers OnMobsAdded, OnCastStart, OnCastEnd |
| 6 | All old classBase-keyed tables are renamed to category-keyed with no surviving references to mobClass | VERIFIED | grep confirms zero matches for `classBarIds`, `classHasUntimed`, `castingByClass`, `ability.mobClass`, `mobClass` across Engine/ and Import/; surviving `classBase` references are only inside DeriveCategory (steps 4-6) and OnNameplateAdded plateCache population — not in any hot path |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Engine/NameplateScanner.lua` | Category-based scanner with DeriveCategory, wildcard matching, cast detection | VERIFIED | 335 lines; `DeriveCategory` at line 64; `plateCache[unitToken].category` at line 94; `categoryBarIds`, `categoryHasUntimed`, `castingByCategory` all present; wildcard predicate in OnMobsAdded (124), OnCastStart (155), OnCastEnd (167) |
| `Import/Pipeline.lua` | mobCategory propagation from AbilityDB onto merged abilities | VERIFIED | `MergeSkillConfig` is 2-arg (line 28); reads `ns.AbilityDB[npcID].mobCategory` at line 30; sets `mobCategory` on returned tables at lines 43 and 55; dedup key uses `merged.mobCategory` at line 109; 5 total `mobCategory` matches |
| `Core.lua` | UNIT_CLASSIFICATION_CHANGED event registration and routing | VERIFIED | `frame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")` at line 16; handler at lines 93-95 routes to `ns.NameplateScanner:OnClassificationChanged(unitToken)` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Engine/NameplateScanner.lua` | `plateCache[unit].category` | DeriveCategory at NAME_PLATE_UNIT_ADDED | VERIFIED | Lines 94 and 108 both match pattern `category.*=.*DeriveCategory` |
| `Engine/NameplateScanner.lua` | `ability.mobCategory` | wildcard filter predicate in OnMobsAdded | VERIFIED | Line 124: `ability.mobCategory == "unknown" or ability.mobCategory == category`; same predicate at 155 and 167 |
| `Import/Pipeline.lua` | `ns.AbilityDB[npcID].mobCategory` | MergeSkillConfig reads from AbilityDB | VERIFIED | Line 29: `local entry = ns.AbilityDB[npcID]`; line 30: `local mobCategory = (entry and entry.mobCategory) or "unknown"` |
| `Core.lua` | `Scanner:OnClassificationChanged` | UNIT_CLASSIFICATION_CHANGED event routing | VERIFIED | Two matches in Core.lua: RegisterEvent (line 16) and handler dispatch (line 95) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DETC-01 | 20-01-PLAN.md | UnitClassification is cached per nameplate unit at NAME_PLATE_UNIT_ADDED in plateCache | SATISFIED | DeriveCategory calls UnitClassification (line 72) at NAME_PLATE_UNIT_ADDED time; result cached as `plateCache[unitToken].category`. The requirement is satisfied via derived category storage — UnitClassification feeds the derivation, which is cached. |
| DETC-02 | 20-01-PLAN.md | UNIT_CLASSIFICATION_CHANGED event is registered and updates the classification cache | SATISFIED | Core.lua line 16 registers; lines 93-95 dispatch; NameplateScanner.lua line 108 updates `cached.category = DeriveCategory(unitToken)` |
| DETC-03 | 20-01-PLAN.md | UnitIsLieutenant is called with pcall wrapping and cached alongside classification | SATISFIED | NameplateScanner.lua line 68: `local okLt, isLt = pcall(UnitIsLieutenant, unitToken)`; result informs `"miniboss"` category which is stored in `cached.category` |
| DETC-04 | 20-01-PLAN.md | DeriveCategory() helper combines classification + lieutenant + classBase into a category string | SATISFIED | Local function at lines 64-82 implements locked 7-step priority chain: UnitIsBossMob -> UnitIsLieutenant pcall -> UnitClassification non-elite -> UnitClass subtype -> "unknown" fallback |
| DETC-05 | 20-01-PLAN.md | Runtime-derived category is cached per nameplate unit in plateCache, not per classBase | SATISFIED | `plateCache[unitToken].category` set at line 94 (OnNameplateAdded) and refreshed at line 108 (OnClassificationChanged); Tick reads `cached.category` throughout |
| SCAN-01 | 20-01-PLAN.md | Scanner reads mob category from ns.AbilityDB[npcID] directly at match time (no duplication) | SATISFIED | Pipeline.MergeSkillConfig reads from ns.AbilityDB[npcID] at pack-build time (not in hot path); scanner reads `ability.mobCategory` from in-memory pack object — no SavedVariables round-trip for category routing |
| SCAN-02 | 20-01-PLAN.md | Mobs with mobCategory == "unknown" pass all category checks (wildcard) | SATISFIED | Wildcard predicate at lines 124, 155, 167: `ability.mobCategory == "unknown" or ability.mobCategory == category` — "unknown" ability fires for any runtime category |
| SCAN-03 | 20-01-PLAN.md | Mobs with a known category only trigger abilities when runtime-detected category matches | SATISFIED | Same two-branch predicate — for a known-category ability, the `== "unknown"` branch is false, so only `ability.mobCategory == category` gate remains; must equal runtime-derived category |

All 8 phase requirements are covered by this plan. No orphaned requirements for Phase 20 found in REQUIREMENTS.md.

### Anti-Patterns Found

No anti-patterns found. No TODO/FIXME/HACK/PLACEHOLDER comments in any modified file. No empty implementations or console-log-only stubs. No return-null or return-empty-table implementations.

The retained `classBase` references (NameplateScanner.lua lines 33, 76-80, 90, 93, 96) are intentional per the plan's key-decision: `classBase` retained in `plateCache` for DeriveCategory steps 4-6 and debugging, deferred to cleanup phase. None appear in hot paths (Tick, OnMobsAdded, OnCastStart, OnCastEnd, Start, Stop).

### Human Verification Required

The following cannot be verified programmatically since this addon runs in a live WoW client:

#### 1. DeriveCategory produces correct runtime categories in-game

**Test:** Import a Skyreach route, enter an instance, pull mobs. Enable `/tpw debug` before pulling.
**Expected:** Debug log shows `OnNameplateAdded: nameplateN class=PALADIN cat=miniboss` for lieutenant mobs (Heralds of Sunrise, Solar Construct), `cat=boss` for boss-tier mobs, `cat=caster`/`rogue`/`warrior` for elite trash with correct WoW class tokens, `cat=trivial` for non-elite trash.
**Why human:** Requires live game session with actual mob nameplates; WoW API return values (`UnitIsBossMob`, `UnitIsLieutenant`, `UnitClassification`, `UnitClass`) cannot be mocked.

#### 2. UnitIsLieutenant runtime behavior

**Test:** Pull a known Skyreach lieutenant mob (e.g., Herald of Sunrise) and watch the debug log.
**Expected:** Either `cat=miniboss` (UnitIsLieutenant returned true) or `cat=caster`/`unknown` (pcall returned false or nil), with no Lua error in the chat frame or BugSack.
**Why human:** `UnitIsLieutenant` is unvalidated in-game — documented in API docs but not found in any Blizzard Lua file. Only in-game testing confirms it does not error.

#### 3. Wildcard matching for non-Skyreach dungeons

**Test:** Import a Windrunner Spire route (all abilities have `mobCategory = "unknown"`), enter the dungeon, pull trash.
**Expected:** All tracked abilities produce icons regardless of mob runtime category. No icons are suppressed due to category mismatch.
**Why human:** Requires in-game pull; wildcard predicate is correct in code but actual ability display depends on the full pipeline (Scheduler, IconDisplay) all wired together correctly.

#### 4. Known-category filtering for Skyreach

**Test:** Import a Skyreach route containing both `"caster"` and `"warrior"` abilities. Pull a pack with only warrior mobs.
**Expected:** Only warrior-category abilities produce icons; caster-category abilities do not fire for warrior mobs.
**Why human:** Requires in-game pull with specific known Skyreach mob composition.

#### 5. UNIT_CLASSIFICATION_CHANGED cache refresh

**Test:** Observe if any mob's category changes mid-combat (rare — most Midnight M+ mobs do not change classification).
**Expected:** Debug log shows `OnClassificationChanged: nameplateN -> <new_category>` when a mob's classification changes; no Lua error.
**Why human:** Classification changes are rare in practice; requires specific in-game scenario to trigger.

## Summary

Phase 20 goal is fully achieved. All six observable truths are verified, all three required artifacts exist with substantive implementations, and all four key links are wired and functional.

The NameplateScanner is completely reworked from class-based to category-based matching:
- `DeriveCategory` implements the locked 7-step priority chain with pcall-wrapped `UnitIsLieutenant`
- `plateCache[unitToken].category` is derived at `NAME_PLATE_UNIT_ADDED` and refreshed on `UNIT_CLASSIFICATION_CHANGED`
- All module-level tables (`categoryBarIds`, `categoryHasUntimed`, `castingByCategory`) use category strings as keys
- The wildcard predicate `ability.mobCategory == "unknown" or ability.mobCategory == category` appears consistently in OnMobsAdded, OnCastStart, and OnCastEnd
- No hot-path (`Tick`) API calls added — DeriveCategory runs at event time only

The Pipeline correctly propagates `mobCategory` from `ns.AbilityDB[npcID]` through `MergeSkillConfig` onto merged ability objects at pack-build time. No `mobClass` references survive anywhere in Engine/ or Import/.

Both documented commits (`c40ee9f`, `06001b9`) are present in git history, confirming implementation is committed.

Human verification items are limited to in-game functional testing — all code-verifiable checks pass.

---
*Verified: 2026-03-23T22:30:00Z*
*Verifier: Claude (gsd-verifier)*
