# Feature Research

**Domain:** WoW Mythic+ dungeon helper addon — trash pack ability warning system
**Researched:** 2026-03-13
**Confidence:** MEDIUM (Midnight API landscape confirmed via Blizzard official sources; competitor feature details from web search with partial verification)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Pack selection UI | Users must manually select the pack they are pulling — core interaction contract of the addon | MEDIUM | A scrollable or grouped list (by dungeon area/room). Without this, nothing triggers. All other features depend on this. |
| Ability timer display | The core value. Users install boss mods to see "X ability in N seconds." Missing timers = addon does nothing useful. | HIGH | Predefined cooldown values per mob ability. Displayed via Blizzard's Boss Warnings system or a timer bar. This is the entire reason the addon exists. |
| Pull trigger (start timers) | Players expect warnings to begin from the moment they engage, not from arbitrary time-zero. | MEDIUM | A manual "pull" button or automatic combat-entry detection. In Midnight, combat-start events for M+ may be accessible — needs validation. If not, a manual trigger button is the fallback. |
| Stop/reset timers on combat end | Timers continuing after a wipe or pack death create noise and confusion. | LOW | Respond to PLAYER_REGEN_ENABLED or a similar out-of-combat signal. |
| Per-dungeon pack list | Users expect the addon to know which dungeon they are in and show relevant packs only. | MEDIUM | v1 covers one dungeon; this is still required for that dungeon. Grouped by area (e.g., "Entrance", "Corridor 1"). |
| Dangerous ability callouts | Users of DBM/BigWigs expect to see the ability name, a countdown, and optionally a sound. "Something is happening" without specifics is not useful. | MEDIUM | Each warning entry needs: ability name, time-until-cast, severity/priority. |
| Enable/disable toggle | All serious WoW addons have an on/off switch. Players test addons and expect to silence them instantly. | LOW | A slash command or minimap button is sufficient for v1. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Predefined cooldown timers triggered on pull (not cast detection) | Every existing trash warning tool (LittleWigs, DBM) requires `SPELL_CAST_START` from the combat log, which Midnight blocks during M+ runs. This addon's predefined approach is the only one that works under current API constraints. | HIGH | This IS the differentiator. The research gap in LittleWigs ("Important M+ Abilities missing") and BigWigs' shift to Blizzard encounter data confirms no competitor serves this niche in Midnight. |
| Boss Warnings system integration | Blizzard added a native warning UI in Midnight. Using it means zero custom frame work, familiar UX to players, and no UI clutter. Competitors who predate Midnight built custom bars/frames. | MEDIUM | Requires identifying the correct Blizzard API surface in Midnight 12+. If the Boss Warnings system is a frame that can be written to via addon APIs, this is the correct approach. Needs validation. |
| Pack-level grouping (whole pull, not individual mobs) | MDT thinks in pulls; players think in pulls. LittleWigs thinks in individual mobs. Grouping timers by pack (the unit of decision-making in M+) matches mental model better. | LOW | This is a data-modeling decision, not extra code. Pack = a named collection of mobs with a unified timer sequence. |
| Severity-tiered warnings (interrupt NOW vs heads-up) | Competitive players distinguish between "kick this" and "move out of this." A single undifferentiated warning stream is noise. Severity tiers let players tune attention. | LOW | Two tiers for v1: DANGER (interrupt/dispel required) and INFO (positional/personal cooldown). Color-coded in warning text. |
| Per-pack notes field | A short text note visible on pack selection ("watch for healer, interrupt Void Bolt"). Adds human judgment layer that automated systems cannot provide. | LOW | Static data field in the pack database. No UI complexity beyond displaying it in the selection list. |
| Slash command to select pack by name | Power users hate clicking menus mid-pull setup. `/tpw pack <name>` lets a tank select a pack from a macro. | LOW | Simple string match against pack names. Reduces friction for keyboard-centric players. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Auto-detection of current pack | "Why do I have to click? Just detect it" — feels like obvious UX improvement | Midnight blocks nameplate scanning, GUID inspection, and CLEU during M+ runs. This is not a design choice — it is an API constraint. Building a fake auto-detection that errors silently is worse than transparent manual selection. | Manual selection with a fast UI (hotkey, slash command, list pre-sorted by dungeon area). Document the limitation clearly in addon description. |
| Real-time cast detection | "Just track the cast like LittleWigs does" | SPELL_CAST_START and CLEU are restricted for enemy units during M+ in Midnight. This was the original approach of all competitors and it no longer works reliably. The whole premise of this addon is that predefined timers fill this gap. | Predefined cooldown timers from pull trigger. Accept that timers drift from reality; good-enough approximation is the value, not perfect precision. |
| MDT route integration | "Auto-advance to next pack when I move to it in my route" | High API complexity; requires reading MDT's route data structure; route position detection (player location vs pack location) is unreliable without nameplate scanning. Future milestone for a reason. | Manual pack selection. The MDT integration is the v2 dream; ship v1 without it. |
| Custom per-user timer editing | "Let me correct the cooldown values" | Opens a configuration surface that is harder to build and test than the entire rest of the addon. Timer accuracy maintenance becomes community/contributor work, not author work. Wrong timers users enter will cause bugs they blame on the addon. | Author-maintained predefined data. Accurate timers as a quality differentiator. Accept issues as bug reports. |
| Nameplate anchoring for timers | "Show the timer above the mob nameplate, like Plater does" | Nameplate access is restricted in Midnight for enemy units during instances. This is explicitly called out in the Midnight API changes. | Boss Warnings system or a fixed on-screen position. Anchoring to Blizzard's native UI elements remains permissible. |
| Multi-dungeon database for v1 | "Support all eight Midnight dungeons at launch" | Each dungeon requires research, data entry, and testing per mob per pack. Shipping unverified data for seven dungeons creates more bugs than value. First dungeon proves the concept. | One dungeon with thoroughly researched, accurate timers. Quality > quantity. Expand after validation. |
| Damage meter / performance tracking | "Add DPS tracking while you're at it" | Completely different product category. Midnight restricts the data needed for accurate meters anyway. | Use Details! or another dedicated meter addon. |

---

## Feature Dependencies

```
Pack Database (mob abilities + cooldowns per pack)
    └──required by──> Pack Selection UI
                          └──required by──> Pull Trigger
                                                └──required by──> Timer Engine
                                                                      └──required by──> Warning Display (Boss Warnings)

Pull Trigger
    └──required by──> Stop/Reset on Combat End

Warning Display (Boss Warnings)
    └──enhanced by──> Severity Tiers

Pack Selection UI
    └──enhanced by──> Per-Pack Notes Field
    └──enhanced by──> Slash Command Selection

Timer Engine ──conflicts with── Real-time Cast Detection
    (predefined timers are the fallback for what cast detection cannot do in Midnight)
```

### Dependency Notes

- **Pack Database required by Pack Selection UI:** The UI is a rendered view of the database. No data = no list.
- **Pack Selection required by Pull Trigger:** The timer engine needs to know which pack's abilities to schedule. Selection is the parameterization step.
- **Pull Trigger required by Timer Engine:** Timers are relative to pull time. The trigger sets T=0.
- **Pull Trigger required by Stop/Reset:** You can only reset what has been started. Combat-end handler must know a pull is active.
- **Timer Engine conflicts with Real-time Cast Detection:** These are two different architectural approaches. The addon commits to predefined timers because cast detection is blocked. Do not mix them — it creates confusing dual-source timing behavior.
- **Warning Display enhanced by Severity Tiers:** Tiers are cosmetic/priority metadata on existing warning entries. They require the warning display to be implemented first.

---

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept.

- [ ] Pack database for one dungeon — without data there is no product; this is the content work
- [ ] Pack selection UI (grouped list by dungeon area) — the core user interaction; must feel fast
- [ ] Manual pull trigger (button or slash command) — sets T=0 for timer scheduling
- [ ] Predefined ability timer engine — schedules warnings at T+N seconds from pull
- [ ] Warning display via Boss Warnings system (or fallback to simple chat/screen text) — the output players see
- [ ] Stop/reset on combat end — prevents stale timers from polluting subsequent pulls
- [ ] Enable/disable slash command — basic operational hygiene; players expect this

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] Severity tiers (DANGER vs INFO) — add when player feedback indicates warning noise is a problem
- [ ] Per-pack notes field — add when players report wanting human-judgment context per pack
- [ ] Slash command pack selection — add when players report the click UI as friction
- [ ] Second dungeon in database — add after first dungeon data quality is confirmed via community feedback

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] MDT route integration — requires significant API validation and a stable v1 to build on
- [ ] Auto-detection of current pack — only viable if Midnight opens a detection API; monitor Blizzard patch notes
- [ ] Community-contributed warning profiles — requires tooling for contribution review and data validation
- [ ] Multi-dungeon full coverage — natural growth once v1 concept is validated; not a v1 concern

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Pack database (one dungeon) | HIGH | MEDIUM (data entry, not code) | P1 |
| Pack selection UI | HIGH | MEDIUM | P1 |
| Manual pull trigger | HIGH | LOW | P1 |
| Predefined timer engine | HIGH | HIGH | P1 |
| Boss Warnings display | HIGH | MEDIUM (API validation needed) | P1 |
| Stop/reset on combat end | HIGH | LOW | P1 |
| Enable/disable toggle | MEDIUM | LOW | P1 |
| Severity tiers | MEDIUM | LOW | P2 |
| Per-pack notes | MEDIUM | LOW | P2 |
| Slash command pack select | MEDIUM | LOW | P2 |
| MDT integration | HIGH | HIGH | P3 |
| Auto pack detection | HIGH | HIGH (blocked by API) | P3 |
| Multi-dungeon coverage | HIGH | HIGH (data volume) | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | DBM | BigWigs / LittleWigs | MDT | TerriblePackWarnings (this addon) |
|---------|-----|---------------------|-----|----------------------------------|
| Boss ability timers | YES — full raid/dungeon coverage | YES — modular, lightweight | NO | NO (out of scope) |
| Trash mob cast warnings | PARTIAL — interrupt callouts when cast detected | PARTIAL (LittleWigs) — SPELL_CAST_START based; broken in Midnight M+ | NO | YES — predefined timers, Midnight-safe |
| Works in Midnight M+ (no CLEU) | UNCERTAIN — adapting to Blizzard encounter data; trash coverage unclear | UNCERTAIN — trash modules rely on CLEU; open issues confirm gaps | N/A | YES — predefined data, no combat log dependency |
| Manual pack selection | NO | NO | YES (route planning, not warnings) | YES — core UX model |
| Predefined cooldown timers | NO (reactive to events) | NO (reactive to events) | NO | YES — the entire approach |
| Boss Warnings native UI integration | YES (adapting) | YES (adapting) | NO | YES (design intent) |
| Route/pull planning | NO | NO | YES — full route planning | NO (out of scope v1) |
| Pack-level grouping | NO — per-ability | NO — per-ability | YES — pull groups | YES — named pack = unit of selection |

---

## Sources

- [Blizzard: Combat Philosophy and Addon Disarmament in Midnight](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight) — Official API restriction rationale
- [Warcraft Wiki: Patch 12.0.0 Planned API Changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes) — CLEU removal, secret values system
- [Icy Veins: Combat Addon Restrictions Eased in Midnight](https://www.icy-veins.com/wow/news/combat-addon-restrictions-eased-in-midnight/) — Clarification: restrictions apply during M+ runs specifically
- [GitHub: BigWigsMods/LittleWigs](https://github.com/BigWigsMods/LittleWigs) — Trash module implementation using SPELL_CAST_START; confirms CLEU dependency
- [GitHub: LittleWigs Issue #15 — Important M+ Abilities missing](https://github.com/BigWigsMods/LittleWigs/issues/15) — Confirms gap in competitor trash coverage
- [Mythic Trap: Addons](https://www.mythictrap.com/en/resources/addons) — Competitive M+ player addon recommendations; confirms cast bar (Quartz/Plater) as current interrupt awareness solution
- [Wowhead: How to Use MDT](https://www.wowhead.com/guide/how-to-use-mythic-dungeon-tools-addon-guide) — MDT feature set; route/pull planning only, no warnings
- [CurseForge: BigWigs](https://www.curseforge.com/wow/addons/bigwigs) — Current BigWigs feature set
- [CurseForge: LittleWigs](https://www.curseforge.com/wow/addons/littlewigs) — Current LittleWigs feature set

---

*Feature research for: WoW M+ dungeon helper addon — TerriblePackWarnings*
*Researched: 2026-03-13*
