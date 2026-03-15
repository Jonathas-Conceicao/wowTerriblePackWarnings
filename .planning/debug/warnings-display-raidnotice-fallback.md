---
status: diagnosed
trigger: "Warnings display as RaidNotice text in middle of screen instead of Encounter Timeline bars or DBM bars, despite EncounterTimeline being detected at load."
created: 2026-03-14T00:00:00Z
updated: 2026-03-14T00:00:00Z
---

## Current Focus

hypothesis: ET_Show and DBM_Show both hard-code RaidNotice text instead of using their respective bar/timer APIs; ShowTimer calls the correct adapter API but Show never does
test: Read all adapter Show functions and compare to ShowTimer functions
expecting: Show functions should use adapter-specific display but instead all use RaidNotice_AddMessage
next_action: report findings

## Symptoms

expected: Warnings appear as Encounter Timeline bars or DBM bars when those addons are detected
actual: Warnings always appear as RaidNotice text in the middle of the screen
errors: None (functionally wrong, not erroring)
reproduction: /tpw select windrunner_spire, /tpw start, observe warnings
started: Since implementation

## Eliminated

(none needed - root cause found on first pass)

## Evidence

- timestamp: 2026-03-14T00:01:00Z
  checked: Display/BossWarnings.lua lines 65-67 (ET_Show function)
  found: ET_Show calls RaidNotice_AddMessage(RaidBossEmoteFrame, ...) - identical to the RaidNotice fallback
  implication: EncounterTimeline adapter's Show function does NOT use C_EncounterTimeline API at all

- timestamp: 2026-03-14T00:01:00Z
  checked: Display/BossWarnings.lua lines 94-96 (DBM_Show function)
  found: DBM_Show calls RaidNotice_AddMessage(RaidBossEmoteFrame, ...) - identical to the RaidNotice fallback
  implication: DBM adapter's Show function does NOT use DBM bar API at all

- timestamp: 2026-03-14T00:01:00Z
  checked: Display/BossWarnings.lua lines 40-50 (ET_ShowTimer function)
  found: ET_ShowTimer correctly calls C_EncounterTimeline.AddScriptEvent(eventInfo)
  implication: Timer bar creation works via the correct API

- timestamp: 2026-03-14T00:01:00Z
  checked: Display/BossWarnings.lua lines 73-77 (DBM_ShowTimer function)
  found: DBM_ShowTimer correctly calls DBT:CreateBar(duration, barID, spellID)
  implication: Timer bar creation works via the correct API

- timestamp: 2026-03-14T00:02:00Z
  checked: Engine/Scheduler.lua lines 29-54 (scheduleAbility function)
  found: Scheduler calls BOTH BossWarnings.Show() (for text alerts at pre-warn and cast time) AND BossWarnings.ShowTimer() (for countdown bars). The Show() calls are the ones producing the RaidNotice text.
  implication: The timer bars (ShowTimer) may be working correctly via adapter APIs, but the text alerts (Show) always fall through to RaidNotice regardless of adapter

- timestamp: 2026-03-14T00:03:00Z
  checked: C_EncounterTimeline API surface
  found: C_EncounterTimeline.AddScriptEvent is used for ShowTimer but there is no equivalent call in ET_Show. ET_Show should likely also use AddScriptEvent or a similar timeline-specific display method rather than RaidNotice.
  implication: The Show functions are stubs/placeholders that were never implemented with adapter-specific logic

## Resolution

root_cause: |
  TWO related issues in Display/BossWarnings.lua:

  1. **ET_Show (line 65-67) and DBM_Show (line 94-96) are copy-paste stubs** that both call
     `RaidNotice_AddMessage(RaidBossEmoteFrame, ...)` -- the exact same implementation as the
     RaidNotice fallback (RN_Show, line 102-104). All three Show functions are identical.
     This means that regardless of which adapter is detected, all text warnings always
     display as RaidNotice text in the center of the screen.

  2. **The Scheduler calls Show() for all warning text** (pre-warn at line 31 and cast alert
     at line 39). These are the visible warnings the user sees. ShowTimer() (line 54) creates
     bars correctly via adapter APIs, but the text alerts dominate the user experience and
     always use RaidNotice.

  The adapter detection works correctly. The ShowTimer path works correctly per adapter.
  Only the Show() path is broken -- it was never given adapter-specific implementations.

fix: (not applied - diagnosis only)
verification: (not applied - diagnosis only)
files_changed: []
