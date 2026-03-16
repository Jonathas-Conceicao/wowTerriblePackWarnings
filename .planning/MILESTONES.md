# Milestones

## v0.0.2 Display Rework (Shipped: 2026-03-16)

**Phases completed:** 4 phases, 7 plans
**Code:** 1,239 lines of Lua across 7 files
**Timeline:** 2026-03-15 to 2026-03-16

**Key accomplishments:**
- Custom WeakAura-style spell icon display replacing DBM/ET/RaidNotice adapters
- Horizontal icon row with cooldown sweep animation, integer countdown, and red glow at 5 seconds
- Text-to-speech warnings via C_VoiceChat.SpeakText with custom short callouts per ability
- Nameplate-based mob detection: 0.25s poll, UnitClass matching, per-mob independent timer instances
- Full Windrunner Spire route: 17 packs with 4 tracked abilities (Spellguard's Protection, Spirit Bolt, Fire Spit, Interrupting Screech)
- Icon labels ("DR", "Bolt", "DMG", "Kick") and spell tooltip on mouseover
- Data schema: flat pack.abilities with mobClass, timed/untimed, label, ttsMessage fields

**Requirements:** 16/16 v0.0.2 requirements completed (DISP-01 through DISP-08, DATA-06 through DATA-09, DETC-01 through DETC-04)

---

## v0.0.1 MVP Proof of Concept (Shipped: 2026-03-15)

**Phases completed:** 3 phases, 8 plans
**Code:** 768 lines of Lua across 6 files
**Timeline:** 3 days (2026-03-13 to 2026-03-15)

**Key accomplishments:**
- Loadable WoW Midnight addon with TOC, namespace, SavedVariables, and dev tooling (install/release scripts, GitHub Actions)
- Windrunner Spire pack database with ability timers (first_cast + cooldown repeat)
- 3-tier display adapter: DBM bars > Encounter Timeline > RaidNotice fallback with pcall-protected API calls
- Timer scheduler with auto-repeating ability warnings and 5-second pre-warn alerts
- Combat state machine: auto-start on PLAYER_REGEN_DISABLED, auto-advance packs on combat end, zone-change full reset
- Pack selection UI: accordion window with dungeon headers, click-to-select, combat state indicators (active/completed), live refresh on auto-advance
- Zone auto-detection via GetInstanceInfo for automatic dungeon selection

**Requirements:** 14/14 v1 requirements completed (FOUND-01/02, DATA-01/02, WARN-01/02/03, CMBT-01/02/03, UI-01/02/03/04)

---

