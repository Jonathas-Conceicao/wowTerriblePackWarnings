# Pitfalls Research

**Domain:** WoW Midnight dungeon pack warning addon (timer-based, predefined data, Boss Warnings API)
**Researched:** 2026-03-13
**Confidence:** MEDIUM-HIGH (core API restrictions confirmed via Warcraft Wiki and Blizzard official docs; Boss Timeline injection API confirmed via 12.0.0 API changes; some C_EncounterTimeline parameter details are LOW confidence — unverified in public docs)

---

## Critical Pitfalls

### Pitfall 1: Calling Restricted APIs During a Mythic+ Keystone Run

**What goes wrong:**
Any API that reads combat state — unit health, auras, cooldowns, spell information — returns a "secret value" during an active Mythic+ keystone run. If your code attempts arithmetic, table indexing, or conditional logic on a secret value, Lua throws an error and your addon either silently breaks or generates a cascade of UI errors. This is not hypothetical: Blizzard's own UI code shipped with this bug in week one of Midnight.

**Why it happens:**
Developers assume that because the addon runs in a non-combat context (the user is selecting a pack before pulling), restricted APIs are safe to call. The restriction activates the moment the keystone run starts, not when combat begins. Pack selection can happen mid-run (between packs), and the restriction is already active.

**How to avoid:**
- Never call `UnitHealth`, `UnitAura`, `GetSpellCooldown`, `UnitBuff`, `UnitDebuff`, or any unit query API for combat-derived data.
- This addon does not need these APIs at all — timers are predefined. The risk is accidentally introducing them during debugging, convenience, or UI display code.
- Wrap any optional informational calls in `issecretvalue()` guards or `pcall()` if you add display features later.
- Use `C_Secrets.IsRestricted()` (or `C_RestrictedActions`) to gate any future conditional API calls.

**Warning signs:**
- Lua errors appearing when the addon is used inside a Mythic+ dungeon but not outside it.
- Errors only on the first pack selection after the key timer starts.
- The error message references a "secret value" or "restricted access."

**Phase to address:** Foundation phase (addon structure setup). Establish the rule: this addon reads no runtime combat data, period. Enforce with a code comment convention.

---

### Pitfall 2: Assuming C_EncounterTimeline.AddScriptEvent Works Like a Simple Timer

**What goes wrong:**
`C_EncounterTimeline.AddScriptEvent` exists in the 12.0.0 API, but its parameter signature, preconditions, and behavior are not fully documented in public wikis. Developers who guess at the API based on function name alone will ship code that silently does nothing, crashes on invalid parameters, or only works in boss encounters (not trash pulls). The Boss Warnings timeline may also require an active encounter state to display events.

**Why it happens:**
The function name implies "add a custom event to the Boss Timeline." The actual behavior may require specific event data structures, severity levels, or may only render during an `ENCOUNTER_TIMELINE_STATE_UPDATED` active state. Public documentation is sparse — the API exists in the 12.0 changes list but parameter documentation is absent.

**How to avoid:**
- Treat `C_EncounterTimeline.AddScriptEvent` as LOW confidence until verified in-game.
- The fallback plan is `C_EncounterWarnings.PlaySound` (confirmed to exist) plus a custom frame for timer display — avoid depending solely on Boss Timeline injection.
- Verify the API works for trash-pack contexts (not just active boss encounters) early in development by testing with a minimal stub addon before building the full timer system around it.
- Check `C_EncounterTimeline.IsFeatureAvailable()` and `C_EncounterTimeline.IsFeatureEnabled()` before calling injection functions.

**Warning signs:**
- Timers registered via `AddScriptEvent` never appear in the Boss Timeline UI.
- No error is thrown, but no visual output occurs (silent failure).
- The function works in a raid encounter but not during a trash pull.

**Phase to address:** Boss Warnings integration phase — this must be the first thing prototyped, not the last. Validate the injection API before building the full timer data system around an assumed integration point.

---

### Pitfall 3: Timer Drift — Predefined Cooldowns Diverge From Actual Mob Behavior

**What goes wrong:**
Mob ability cooldowns in Midnight dungeons are not perfectly deterministic. Most abilities have a "first cast offset" (time from pull to first cast that is shorter than the repeat cooldown), cast variance windows (±1-3 seconds), and some abilities are skipped if the mob dies or resets. Hardcoded timers that ignore the first-cast offset will show the warning 8-15 seconds late on the first cast, making the warning useless precisely when it matters most (opening burst).

**Why it happens:**
Developers model the cooldown as `ability_fires_every_X_seconds_from_pull`. In reality it is: `first_cast = pull + Y seconds`, `subsequent_casts = first_cast + X seconds`. Y is frequently different from X. DBM and BigWigs both model this explicitly in their encounter data structures.

**How to avoid:**
- The data schema for each ability must include two fields: `first_cast` (time from pack selection/pull to first expected cast) and `cooldown` (repeat interval after first cast).
- Document variance tolerance per ability — some abilities have tight windows, others are loose. Users should understand warnings are approximate.
- Test data against actual dungeon runs during development. Do not trust Wowhead cast timing data alone; it aggregates and may not reflect first-cast offset.

**Warning signs:**
- During playtesting, the first warning fires noticeably after the ability actually cast.
- Users report "the warning is always late the first time."
- Cooldown timer looks correct from the second cast onward.

**Phase to address:** Data schema design phase. Build first-cast offset into the data model from day one — retrofitting it later requires modifying every ability entry.

---

### Pitfall 4: TOC Interface Version Mismatch Causing Silent Addon Disable

**What goes wrong:**
If the TOC `## Interface:` field does not match the current WoW client version, the client marks the addon as "out of date" and may refuse to load it (or load it with a warning that prompts users to disable it). The Midnight pre-patch uses `120000` and the full Midnight launch uses `120001`. Using the wrong number, or leaving a pre-Midnight value like `110007`, causes the addon to fail silently for users who have "Load out of date AddOns" disabled.

**Why it happens:**
Developers set the TOC version during initial development and forget to update it. The expansion pre-patch and release use different interface numbers, and the version changes again with each major patch.

**How to avoid:**
- Set `## Interface: 120001` for the Midnight launch target.
- Add a `## Interface-Retail: 120001` line if targeting multi-version compatibility.
- Verify the current interface number with `/dump select(4, GetBuildInfo())` in-game before shipping.
- Add the TOC interface number as an explicit checklist item in any release process.

**Warning signs:**
- Users report the addon does not appear in their AddOns list or is grayed out.
- The addon works for the developer but not for testers on the same game version.
- No Lua errors — the addon simply never loads.

**Phase to address:** Foundation phase (TOC and addon structure setup).

---

### Pitfall 5: Initialization Race — Accessing SavedVariables Before ADDON_LOADED

**What goes wrong:**
Attempting to read or write SavedVariables (user settings, pack selection persistence) in top-level addon code — before the `ADDON_LOADED` event fires for your specific addon — results in nil reads. This silently corrupts any default value logic and can cause nil-reference crashes on first load.

**Why it happens:**
WoW executes addon Lua files on load, but SavedVariables are not populated until `ADDON_LOADED` fires with your addon's name as the argument. Developers who initialize settings in the file body rather than in an event handler hit this every time.

**How to avoid:**
- All SavedVariables access must be gated behind `ADDON_LOADED` with an explicit addon name check: `if event == "ADDON_LOADED" and arg1 == "TerriblePackWarnings" then`.
- Initialize defaults defensively: `MyAddonDB = MyAddonDB or {}` inside the event handler, not at file scope.
- `PLAYER_ENTERING_WORLD` is safe for UI setup that depends on game state (called after `ADDON_LOADED`); use it for anything that queries the world rather than saved config.

**Warning signs:**
- Settings reset to defaults every login despite being saved.
- Nil errors on first install that go away after `/reload`.
- Pack selection state not persisted between sessions.

**Phase to address:** Foundation phase (addon structure and event handling setup).

---

### Pitfall 6: Timer State Not Reset When the Player Leaves or Resets the Dungeon

**What goes wrong:**
Active timers continue running after the player dies, wipes, leaves the instance, or the keystone run ends. The user returns to a dungeon with stale timers firing for a pack they already cleared, or timers fire in the main city after logging back in.

**Why it happens:**
`C_Timer.After` and `C_Timer.NewTicker` callbacks have no automatic cancellation scope. Once scheduled, they fire unless explicitly cancelled. Developers who do not implement a cleanup path on `PLAYER_ENTERING_WORLD` (instance change), `ENCOUNTER_END`, or `PLAYER_DEAD` leave timers orphaned.

**How to avoid:**
- Maintain a table of all active `C_Timer` handles returned by `C_Timer.After` / `C_Timer.NewTicker`.
- On `PLAYER_ENTERING_WORLD` (fires on zone change and login), cancel all active timer handles and reset addon state.
- Provide an explicit "Cancel / Reset" button in the UI so users can manually clear timers if they wipe mid-pull.
- Test the specific scenario: start timers, press Escape to leave dungeon, verify no timers fire in the outdoor world.

**Warning signs:**
- Timer warning appears after a wipe when the player has run back.
- Warning fires while standing at the dungeon entrance before the next pull.
- Users report "ghost warnings" appearing unexpectedly.

**Phase to address:** Timer system phase — implement cleanup alongside timer start, not as a later addition.

---

### Pitfall 7: Global Namespace Pollution Causing Conflicts With Other Addons

**What goes wrong:**
Lua variables declared without `local` become globals accessible (and overwritable) by every other addon. A variable named `db`, `config`, `timers`, or `pack` defined at file scope collides with identically named globals in other popular addons, causing silent data corruption or crashes that appear to be the other addon's fault.

**Why it happens:**
Plain Lua defaults to global scope. New WoW addon developers coming from other languages expect variable declarations to be scoped to the file. The project uses no framework (no Ace3/AceDB), which removes the namespace protection those libraries provide.

**How to avoid:**
- Every variable that does not need cross-file access gets `local`.
- Create a single global table: `TerriblePackWarnings = TerriblePackWarnings or {}` and put all addon state inside it.
- Use the addon namespace provided by the second argument of the TOC-loaded file: `local _, ns = ...; ns.db = {}`.
- Run FindGlobals or a Lua linter to audit for accidental globals before release.

**Warning signs:**
- Errors that only appear when specific other addons are also enabled.
- Another addon's functionality changes based on whether your addon is loaded.
- A variable that should be local appears accessible via the Lua console globally.

**Phase to address:** Foundation phase. Establish scoping conventions before writing any feature code.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Single hardcoded cooldown per ability (no first-cast offset) | Simpler data schema | First warning always late; users lose trust in all warnings | Never — this is the core value proposition |
| No timer handle tracking | Simpler timer scheduling | Orphaned timers fire after wipes/zone changes; never acceptable in release | Never |
| All state in globals (no namespace table) | Slightly less typing | Conflicts with any addon sharing a common variable name | Never |
| Magic numbers for ability cooldowns inline in code | Faster initial authoring | Impossible to update data without editing code; no separation between data and logic | Never — data must be in a table |
| Skipping `ADDON_LOADED` gate for SavedVariables | Slightly simpler init | Silent nil corruption on first install; settings never persist | Never |
| Hard-coding dungeon/zone checks via string matching on zone name | No zone ID lookup needed | Zone names localize; addon breaks for non-English clients | Never for zone detection; acceptable for display labels |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| C_EncounterTimeline Boss Timeline | Assuming it works for trash pulls the same way it works for bosses | Verify `IsFeatureAvailable()` outside an active encounter; have a fallback display path |
| C_EncounterWarnings.PlaySound | Calling without checking `IsFeatureEnabled()` | Gate behind both `IsFeatureAvailable()` and `IsFeatureEnabled()` |
| C_Timer.After | Ignoring the returned timer handle | Always store the handle in a cancellation table |
| SavedVariables | Reading globals before ADDON_LOADED fires | Gate all reads and default-initialization inside the ADDON_LOADED event handler |
| TOC ## SavedVariables | Listing the variable name wrong (case mismatch) | Variable name in TOC must exactly match the global Lua variable name |
| Frame XML registration | Registering events in XML `<Scripts>` and also in Lua | Double-registration causes handlers to fire twice per event |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Using OnUpdate for timer polling instead of C_Timer | CPU spike during combat; frame rate drops | Use `C_Timer.After` for one-shot delays; `C_Timer.NewTicker` for repeating; reserve OnUpdate for sub-0.05s needs | Immediately at any scale; OnUpdate fires every frame (~60/sec) |
| Creating new table allocations inside timer callbacks | Gradual memory growth across a dungeon run | Pre-allocate data structures; pass references, not new tables | Noticeable after 30+ packs in a long session |
| Registering all events globally and filtering in OnEvent | Slight performance overhead; increases with event volume | Register only specific events you actually handle | Trivial for this addon scale; more relevant if addon grows to handle many unit events |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No visual indication that timers are running | User unsure if they selected a pack correctly | Show active state (highlighted pack, timer count, or cancel button) after selection |
| Warning fires but user does not know which ability it refers to | Warning is ignored; no value delivered | Display ability name in the warning, not just a generic alert |
| No way to cancel mid-pull | User pulls wrong pack, cannot stop phantom timers | Always provide a "Stop / Reset" button accessible during combat |
| Warnings fire at cooldown start, not before the cast | Warning arrives too late to react | Warn N seconds before expected cast (configurable lead time, default 3-5 seconds) |
| Pack list is flat with no area grouping | Users cannot find the right pack in a long list | Group packs by dungeon area/zone section |
| Timers silently continue after a wipe | User confused about state on the run-back | Auto-cancel all timers on PLAYER_DEAD or PLAYER_ENTERING_WORLD |

---

## "Looks Done But Isn't" Checklist

- [ ] **Boss Warnings integration:** Timer appears in developer testing, but only because a raid encounter was active. Verify it fires for trash pulls outside of any ENCOUNTER_START event.
- [ ] **Timer cancellation:** Timers stop on the cancel button click, but verify they also stop on: zone exit, `/reload`, PLAYER_DEAD, and dungeon completion.
- [ ] **SavedVariables persistence:** Pack selection persists across a single session but verify it survives logout, login, and `/reload ui`.
- [ ] **First-cast offset:** Warning appears correct from the second cast onward — verify it also fires correctly for the first ability cast immediately after pull.
- [ ] **Non-English clients:** Pack names and ability names display correctly. Zone detection (if used) does not rely on localized zone name strings.
- [ ] **TOC version:** Addon loads without "out of date" warning on a clean install with default client settings (Load out of date AddOns = OFF).
- [ ] **No global leaks:** Run `/dump TerriblePackWarnings` and verify all state is inside the namespace table. Verify no unexpected globals exist.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Secret value errors in Mythic+ | MEDIUM | Audit all API calls against the restricted API list; remove any combat-state queries; re-test in a keystone run |
| C_EncounterTimeline injection doesn't work for trash | HIGH | Implement fallback custom frame for warning display; this requires new UI work |
| Data schema missing first-cast offset | HIGH | Add `first_cast` field to every ability entry; update all timer scheduling logic; re-test all pack data |
| Global namespace collision with another addon | MEDIUM | Namespace all state under the addon table; this is a refactor but not a rewrite |
| Timer orphans (timers running after zone change) | LOW | Add cleanup handler on PLAYER_ENTERING_WORLD; straightforward to add at any time |
| TOC version mismatch | LOW | Update ## Interface field; 5-minute fix |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Restricted API calls in Mythic+ | Phase 1: Foundation | Test pack selection inside an active keystone run; confirm no Lua errors |
| C_EncounterTimeline injection uncertainty | Phase 2: Boss Warnings integration (prototype first) | Verify `AddScriptEvent` fires a visible event in Boss Timeline during a trash pull |
| Timer drift / missing first-cast offset | Phase 1: Data schema design | Playtest first cast of each ability in the target dungeon and compare to warning timing |
| TOC version mismatch | Phase 1: Foundation | Fresh install on clean client with "Load out of date AddOns" disabled |
| Initialization race (SavedVariables) | Phase 1: Foundation | Verify settings persist across logout/login on first install |
| Timer state not reset on zone change | Phase 2: Timer system | Zone out mid-timer; confirm no timers fire in outdoor zone |
| Global namespace pollution | Phase 1: Foundation | Run FindGlobals or `/dump` check; enforce local-by-default convention before writing feature code |

---

## Sources

- [Patch 12.0.0/Planned API changes - Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes) — Confirmed C_EncounterTimeline, C_EncounterWarnings, restriction scope
- [Patch 12.0.0/API changes - Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes) — Full API additions including C_EncounterTimeline function list
- [Combat Philosophy and Addon Disarmament in Midnight - Blizzard](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight) — Official restriction philosophy, what is and is not blocked
- [WoW Midnight's Addon Changes Part 1 - kaylriene.com](https://kaylriene.com/2025/10/03/wow-midnights-addon-combat-and-design-changes-part-1-api-anarchy-and-the-dark-black-box/) — Black box system, developer impact analysis
- [Week One of Midnight UI Era - kaylriene.com](https://kaylriene.com/2026/01/27/a-mini-summary-of-week-one-of-the-new-wow-ui-era-blizzards-own-lua-errors-the-vibecoded-addon-wars-of-2026/) — Real-world post-launch problems including Blizzard's own secret value errors
- [Cell Addon Midnight Compatibility PR #457 - GitHub](https://github.com/enderneko/Cell/pull/457) — Detailed real-world case study: secret values, CLEU removal, pcall overhead, per-field secrecy checks
- [Development clarification: secret value obfuscation - Blizzard Forums](https://us.forums.blizzard.com/en/wow/t/development-clarification-maintaining-ui-accuracy-vs-secret-value-obfuscation-in-midnight/2243547) — Official developer clarification on secret values
- [Majority of Addon Changes Finalized for Midnight Pre-Patch - Wowhead](https://www.wowhead.com/news/majority-of-addon-changes-finalized-for-midnight-pre-patch-whitelisted-spells-379738) — Whitelisted spells, GetSpellCooldownRemaining removal
- [Blizzard Relaxing More Addon Limitations - Icy Veins](https://www.icy-veins.com/wow/news/blizzard-relaxing-more-addon-limitations-in-midnight/) — Post-beta restriction relaxations
- [C_Timer.After - Warcraft Wiki](https://warcraft.wiki.gg/wiki/API_C_Timer.After) — Timer API performance characteristics vs OnUpdate
- [TOC format - Warcraft Wiki](https://warcraft.wiki.gg/wiki/TOC_format) — Interface version fields and multi-version support
- [AddOn loading process - Warcraft Wiki](https://warcraft.wiki.gg/wiki/AddOn_loading_process) — ADDON_LOADED / PLAYER_ENTERING_WORLD / VARIABLES_LOADED ordering
- [Saving variables between sessions - Wowpedia](https://wowpedia.fandom.com/wiki/Saving_variables_between_game_sessions) — SavedVariables initialization patterns and versioning

---
*Pitfalls research for: WoW Midnight dungeon pack warning addon (TerriblePackWarnings)*
*Researched: 2026-03-13*
