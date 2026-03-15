# Milestones

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

