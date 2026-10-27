# Plan: Oarc Classic, a starting points spawn mod

## Context
The current mod finds empty land for each player at runtime (`FindUngeneratedCoordinates`, `lib/oarc_utils.lua:622`). It then scripts a safe area there: crop circle, moat, resources, enemy removal and scaling.

The prototype proved that `MapGenSettings.starting_points` works on nauvis. The grid was written in `on_init` and followed by `surface.clear(true)`, because nauvis chunks already exist when `on_init` runs. Each point got a vanilla starting area: ore, a lake and no biters.

**Oarc Classic** is a new mod, built on a long-lived `oarc-classic` branch of this repo and stripped down. It is checked out as a git worktree at `mods/oarc-classic`. It:
- Pre-places a fixed grid of starting points on every planet surface at game start.
- Gives each new spawn the next free point, spiralling out from the center.
- Relies on vanilla starting-area generation for safety.

There is no join limit. Enemy evolution naturally discourages late joiners, and an optional evolution reset softens that. Points are never added after the game starts.

## Scope

| Keep | Optional (mod setting) | Remove |
|---|---|---|
| Holding pen | OG Oarc style spawn circle at the point (crop circle, moat, scripted resources), picked per player in the spawn menu when "Allow Oarc Style Spawn Circle" is on | Item shop (`lib/gui_tabs/item_shop.lua`, coin unhide in `data.lua`) |
| Offline protection | Reset surface evolution on each new spawn | Buddy spawns |
| Shared chat and vision | Regrowth and World Eater (already off by default in `settings.lua`, left as is) | Main team |
| Cleanup of abandoned spawns (fixed 10x10 chunk area) | | Energy and item sharing (`lib/sharing.lua`, linked chest and pole in `data.lua`, chest size startup setting) |
| Joining someone else's spawn (shared spawns, join queue) | | Enemy scaling and spawn safe areas (`lib/scaled_enemies.lua`) |
| Secondary spawns on all planets, cargo pod redirect | | `FindUngeneratedCoordinates`, near/far distance settings, minimum distance to existing chunks |
| Player list and server info tabs | | |
| Respawn handling, cooldown, reset and remove player | | |

## Phase 0: First test, setting starting points on every surface at game start
This decides the whole design, so it comes first. Do it in the prototype (this repo) before creating the branch.

**Goal:** confirm that every planet surface can get its grid in `on_init`, and that only nauvis needs `surface.clear(true)`.

**Test code** (extends the prototype in `lib/oarc_tests.lua`):
- In `on_init`, loop over `game.planets`.
  - If `planet.surface` is nil, call `planet.create_surface()`.
  - Log `is_chunk_generated({0,0})` for that surface, then write `map_gen_settings.starting_points` with the test grid.
  - Clear only if chunks were already generated.
- Hook `on_surface_created` as a fallback: when the engine creates a planet surface later (a platform arrives), apply the grid in the same tick and log `is_chunk_generated({0,0})`.

**Pass criteria:**
- The log shows `false` (not generated) for every planet except nauvis.
- With Space Age, `/c` printing `game.surfaces.vulcanus.map_gen_settings.starting_points` (and the same for the other planets) shows the grid.
- Teleporting to grid points on Vulcanus, Fulgora, Gleba and Aquilo shows a starting area at each. Use `/oarc-tp-start`, extended to take a surface argument.
- If pre-creating surfaces in `on_init` works, use that. Otherwise use the `on_surface_created` route.

**Result (2026-10-26):** passed with and without Space Age. Without Space Age only nauvis was processed and cleared, with no errors. With Space Age: Nauvis reported generated chunks and was cleared. Vulcanus, Gleba, Fulgora and Aquilo were created in `on_init` with no chunks generated, so no clear was needed, and their starting areas looked correct. `on_surface_created` did not fire during `on_init`. Grids will be applied in `on_init`.

## Phase 1: Create the mod and strip removed features
1. Create the branch and worktree. Run this from `mods/oarc-mod` while it is on `master`, with the Phase 0 prototype changes still uncommitted:
   ```
   git switch -c oarc-classic
   git add control.lua lib/oarc_commands.lua lib/oarc_tests.lua OARC_CLASSIC_PLAN.md
   git commit -m "Starting points prototype and Oarc Classic plan"
   git switch master
   git worktree add ../oarc-classic oarc-classic
   # git push -u origin oarc-classic  (deferred to Phase 7, branch stays local until the mod is done and tested)
   ```
   - The prototype and this plan only live on the branch, so `master` is left clean. A branch can only be checked out in one worktree, so `mods/oarc-mod` stays on `master`.
   - Copy the untracked `CLAUDE.md` into `mods/oarc-classic` by hand. Sessions there won't have the saved memory notes from `oarc-mod`.
   - From here on, open Claude sessions in `mods/oarc-classic`.
   - **Branch rules:** never merge between `master` and `oarc-classic`. Move fixes across with `git cherry-pick`. Tag classic releases with a prefix (for example `classic-1.0.0`). Point the mod portal source link at the branch URL. Exclude the worktree's `.git` file from release zips.
   - Disable `oarc-mod` in Factorio's mod list while testing, because of the `! oarc-mod` incompatibility.
2. In the worktree:
   - `info.json`: `name = "oarc-classic"`, `title = "Oarc Classic"`, `version = "1.0.0"`, and the incompatibility `! oarc-mod`.
   - Rename the `oarc-mod-` prefix to `oarc-classic-` on mod setting names, custom event names and locale keys. Two installed mods can't share setting names. Lua function names stay.
   - Start a fresh `changelog.txt`. Update `README.md` and the locale description.
   - **Cut the scenario template to a minimal skeleton.** Keep the override hook in the mod (`GetScenarioOverrideSettings`, `lib/config_parser.lua:271`, and the `get_mod_settings` remote interface), because it is the only way to set per-surface config such as starting point count and spacing before `on_init`, which headless servers need.
     - Rename the remote interfaces to `oarc_classic` and `oarc_classic_scenario`. An existing scenario written for the old mod must not push its differently shaped config into Oarc Classic.
     - Trim `TEMPLATE_SCENARIO/OARC/control.lua` from about 300 lines to about 40: the override interface with a couple of commented examples (including a per-surface starting points override), and the `on_init` check for `active_mods["oarc-classic"]`. Drop the custom event examples (spawn GUI insert, chunk generated near spawn, custom tab).
     - Update `TEMPLATE_SCENARIO/README.txt` and the scenario locale and description to match.
   - `example/` map-gen JSON: add a note that the mod overwrites any `starting_points` set there.
3. Delete everything in the Remove column: modules, requires, `control.lua` event hooks, settings, `lib/config.lua` keys, `lib/config_parser.lua` entries, GUI tab registry entries in `lib/oarc_gui_tabs.lua`, and locale entries.

Places with known coupling:
- **Buddy fields:**
  - `buddy_name` on `OarcUniqueSpawn` and `OarcDelayedSpawn`
  - `GetBuddySpawnPosition` (`lib/oarc_utils.lua:380`)
  - The buddy GUI flow in `lib/separate_spawns_guis.lua`
  - `disable_solo_spawns`
- **Main team:** remove `main_force_name` and the "join main team" choice. Every primary spawn gets its own force via `CreatePlayerForce` (`lib/separate_spawns.lua:2162`).
- **Scaled enemy hooks** in `control.lua`: `on_entity_spawned`, `on_biter_base_built`, `on_segment_entity_created`, the damage hooks, and the scaled-enemy calls inside `on_chunk_generated`. Keep `on_unit_group_finished_gathering`, because offline protection uses it.

Exit criteria: the mod loads and the old spawn flow still works.

## Phase 2: Starting point grid and assignment

**New module `lib/starting_points.lua`:**
- `BuildStartingPointGrid(count, spacing_chunks)`:
  - Integer grid indices (i, j) map to tile position `(i, j) * spacing_chunks * 32`, so (0,0) is at the origin.
  - It takes the `count` indices closest to (0,0), sorted by distance and then by angle. The list order is the spiral order.
  - The origin is left out of the grid and the map gen `starting_points`. The engine always generates the chunks around (0,0) on nauvis, so it would always fail the explored check. The origin gets no starting area, so it can have biters.
- `ApplyStartingPoints(surface)`: read `map_gen_settings`, set `starting_points`, write it back, and clear only if chunks were already generated (only nauvis in practice). Called in `on_init` for every planet, pre-creating missing surfaces as Phase 0 proved.
  - **Check for existing changes first.** The engine default is a single starting point at (0,0). If the existing `starting_points` is anything else (a different count, or a point not at (0,0)), log a clear error. The error names the surface, lists the existing points, and says they came from the map-gen settings, a preset or another mod and are being replaced. Then overwrite them anyway. Also print it to admins in game, so a host sees it without reading the log.
- `storage.starting_points[surface_name]`: an ordered list of `{position=, host_name=nil|string, unusable=false}`.
- `ClaimNextStartingPoint(surface_name, host_name)`:
  - Walks the list in order and skips entries that are claimed or unusable.
  - **Explored check:** for each candidate, checks `surface.is_chunk_generated` on every chunk in a 10x10 chunk area centred on the point. If any is generated, someone else has explored there. The entry is marked `unusable` and logged, and the walk continues.
  - Returns the first clean point and marks it claimed with the host name.
  - Unusable points are checked again on later claims, so a point whose chunks were still waiting for cleanup is not lost for good.
- `ReleaseStartingPoint(surface_name, position)`: called by cleanup and by `/oarc-reroll-spawn`. The point goes back to the pool. It matches by position, because a reroll briefly holds two points under the same host name.
  - Cleanup deletes its chunks, so the explored check passes again.
  - The starting point is still in the map gen settings, so the area regenerates as a fresh starting area.

**New settings** (runtime-global, read at `on_init`):
- Number of starting points per surface: default 16, minimum 1, maximum 128.
- Spacing in chunks: default 100.

These apply to every planet. The scenario template can override them per surface through `storage.ocfg.surfaces_config[surface].starting_points`.

**Use the grid when spawning:**
- Replace the `FindUngeneratedCoordinates` calls in the spawn-choice handler (`lib/separate_spawns_guis.lua`) and in `SecondarySpawn` (`lib/separate_spawns.lua:1697`) with `ClaimNextStartingPoint`.
- If no point is free, show a "no free starting points, join an existing spawn" error.
- Remove the near/far distance options from the spawn GUI. The moat option only shows in prefab mode.

**Natural spawn generation (default):**
- `QueueNewSpawnGeneration` (`:1639`) keeps requesting chunks and queuing the delayed spawn, so players wait in the holding pen while the area generates.
- `GenerateFinalSpawnPieces` (`:648`) only places the welcome text and sets the force spawn position.
- `SendPlayerToNewSpawn` (`:728`) teleports the player to `find_non_colliding_position` near the point. The vanilla starting lake can sit on top of it.

## Phase 3: Abandoned spawn cleanup (fixed area)
Keep `UniqueSpawnCleanupRemove` (`lib/separate_spawns.lua:1078`) and its existing forced-removal path:
- `RegrowthMarkAreaForRemoval` (`lib/regrowth_map.lua:247`) with `force = true` entries.
- `TriggerCleanup()`, which `OarcRegrowthRemoveAllChunks` then deletes.

The forced path deletes chunks even when regrowth and World Eater are disabled, which is the default.

Changes:
- Use a fixed `chunk_radius = 5` instead of `minimum_distance_to_existing_chunks - 2`. Centred on the point, this covers 11x11 chunks, the closest the existing radius-based function gives to 10x10. If exactly 10x10 matters, add an offset variant.
- Drop the "near another spawn" check. Grid spacing (100 chunks by default) guarantees no other spawn is in range.
- After queuing the removal, call `ReleaseStartingPoint`.
- Keep the existing minimum-online-time rule and the spawn-removed custom event.

## Phase 4: Optional prefab spawn (OG Oarc style spawn circle)
Add a runtime-global bool mod setting, "Allow Oarc Style Spawn Circle" (`oarc-classic-allow-oarc-style-spawn`, `gameplay.allow_oarc_style_spawn`, default off).
- **Off:** the spawn menu shows no style checkbox, and every new spawn uses the vanilla starting area.
- **On:** the spawn menu shows an "OG Oarc style spawn" checkbox (unchecked means the vanilla spawn). The moat checkbox is only enabled while it is ticked.
- The choice is stored per spawn as `prefab` on `OarcSpawnChoices`, `OarcUniqueSpawn` and `OarcDelayedSpawn`. Secondary spawns copy it from the primary spawn. Primary and secondary spawns check the setting again when they are created, so turning it off stops new prefab spawns.

A prefab spawn keeps today's pipeline centred on the claimed point:
- `SetupAndClearSpawnAreas` and `SeparateSpawnsGenerateChunk` (`lib/separate_spawns.lua:810`, `:868`)
- `CreateCropCircle`, `CreateCropOctagon` and `CreateCropSquare` (`lib/spawn_area_generation.lua`)
- `GenerateStartingResources` (`:421`)
- The moat option and the surface config tab (`lib/gui_tabs/surface_config.lua`)

`SetupAndClearSpawnAreas` already clears resources and cliffs in the radius, so it overrides vanilla starting ore. Keep `lib/planet_configs/*` for per-planet prefab settings.

## Phase 5: Planets, Fulgora, evolution reset
- **Secondary spawns are always on:**
  - Drop the `default_enable_secondary_spawns_on_other_surfaces` setting. Planets get `storage.oarc_surfaces[x].secondary = true`.
  - `SecondarySpawn` claims a point on the target planet's grid.
  - The cargo pod redirect code (`lib/separate_spawns.lua:1861` onward) is unchanged.
- **Fulgora lightning attractors:**
  - The problem: map gen creates them on the `player` force, so spawn owners can't deconstruct them.
  - In `on_chunk_generated` (`AssignLightningAttractorsToClosestSpawn`, called from `SeparateSpawnsGenerateChunk`), find `lightning-attractor` entities on the `player` force in the new chunk. Set their force to the force of the host of the closest spawn on that surface (`GetClosestUniqueSpawn`). If no spawn has been claimed on the surface yet, they stay on the `player` force.
  - A spawn is registered before its chunks are requested, so the spawn's own area always goes to its owner. Attractors generated later anywhere on the planet go to whichever spawn is closest at that time.
  - Oarc style spawns place extra scripted attractors after generation (`PlaceFulgoranLightningAttractors`). These are created on the owner's force directly.
- **Evolution reset option:**
  - A runtime-global bool setting, "Reset evolution on new spawn", default off.
  - When a new primary or secondary spawn is queued, call `game.forces.enemy.set_evolution_factor(0, surface)` for that spawn's surface before generation starts.
  - The call goes at the top of `QueueNewSpawnGeneration` (`lib/separate_spawns.lua:1639`), before `request_to_generate_chunks`. Every new spawn passes through there, and it runs right after the point is claimed.
  - Joining someone else's spawn doesn't trigger it.
  - The reset affects everyone on that surface. Say so in the setting description.
  - Implemented as `ResetEnemyEvolution(surface_name)`. It also zeroes the pollution, time and spawner kill parts of evolution, so the evolution GUI adds up. It logs the reset and broadcasts a chat message naming the planet.
  - Setting: `oarc-classic-reset-evolution-on-new-spawn` (`gameplay.reset_evolution_on_new_spawn`). A reroll also counts as a new spawn.

## Phase 6: GUI and docs
- Simplify the spawn choice GUI to: start a new spawn, join a shared spawn, and cancel a join request.
- Admins see one line per surface in the admin controls of the server info tab: how many of its starting points are claimed (`GetStartingPointCounts`). Players already get spawn GPS links from the player list tab.
- Update the FAQ tab, locale and changelog.
- **Spawn reroll (decided 2026-10-26: keep, limited):**
  - `/oarc-reroll-spawn [player]` (`RerollSpawn(caller, player)` in `lib/oarc_tests.lua`) moves a player's spawn on the surface they are standing on to the next free starting point and releases the old one.
  - Players can only reroll themselves, once per surface (`storage.player_rerolls[player][surface]`). The reroll is only used up if a free point was found.
  - Admins can reroll themselves or anyone else, with no limit, and that doesn't use up the target's own reroll.
  - Each reroll uses up a point from a fixed grid. If cleanup is off or the old area isn't deleted yet, the old point is skipped until its chunks are gone.

## Phase 7: Public publish and public playtesting
The branch stays local until Phases 1 to 6 are done and tested. Nothing is pushed before then.
- Push the branch: `git push -u origin oarc-classic`.
- Tag the release (`classic-1.0.0`) and build the release zip without the worktree's `.git` file.
- Publish to the mod portal, with the source link pointing at the branch URL.
- Run public playtests on a multiplayer server. Collect bug reports and fix them on the branch, with follow-up releases as needed.

## Key files
- **Modified:**
  - `control.lua`
  - `settings.lua`
  - `data.lua`
  - `info.json`
  - `lib/config.lua`
  - `lib/config_parser.lua`
  - `lib/separate_spawns.lua`
  - `lib/separate_spawns_guis.lua`
  - `lib/oarc_gui_tabs.lua`
  - `lib/gui_tabs/spawn_controls.lua`
  - `lib/gui_tabs/settings_controls.lua`
  - `lib/oarc_utils.lua`
- **Unchanged:**
  - `lib/holding_pen.lua`
  - `lib/offline_protection.lua`
  - `lib/regrowth_map.lua`
  - `lib/spawn_area_generation.lua`
  - `lib/gui_tabs/player_list.lua`
  - `lib/gui_tabs/server_info.lua`
- **New:** `lib/starting_points.lua`.
- **Deleted:**
  - `lib/scaled_enemies.lua`
  - `lib/sharing.lua`
  - `lib/gui_tabs/item_shop.lua`

## Verification (in game)
1. **Phase 0:** the pass criteria above, with and without Space Age.
2. **Phase 1:** the mod loads, and spawning, joining a shared spawn, respawning and removing a player all work. `factorio-current.log` is clean.
3. **Phase 2:**
   - The first player gets the point at the origin, and the second gets the neighbouring point.
   - Walk a character into the 10x10 area around the next free point, so its chunks generate. The next new player skips that point, and the log says it was marked unusable.
4. **Phase 3:**
   - With regrowth and World Eater off, have a player join and leave within the minimum online time.
   - The 11x11 chunks around their point are deleted and regenerate as a starting area.
   - The point is free again, and the next new player gets it.
5. **Phase 4:** with "Allow Oarc Style Spawn Circle" on, a player who ticks the OG Oarc style checkbox gets the crop circle and resources centred on the claimed point, and a player who leaves it unticked gets the vanilla starting area. With it off, the checkbox is gone.
6. **Phase 5:**
   - With Space Age, travel to Vulcanus and Fulgora. A secondary spawn lands on that planet's grid point, and the cargo pod is redirected to it.
   - On Fulgora, the attractors near the spawn belong to the player's force and can be deconstructed.
   - With the evolution reset on, `/c game.print(game.forces.enemy.get_evolution_factor("vulcanus"))` reads 0 while the player is still waiting in the holding pen for a new Vulcanus spawn. Nauvis evolution is unchanged.
7. **Multiplayer:** a host plus a second client. Check the holding pen wait, the shared spawn join queue, and offline protection.
8. **Phase 7:** the portal release installs cleanly on a fresh profile, and a public server playtest runs without errors in the log.

## Open question
- **Explored check vs entities:** the check marks a point unusable on any generated chunk, even one only generated by someone walking past. That is the requested rule. An alternative is to only reject when the area holds player-force entities, which would waste fewer points.

## Checklist
Tick items off as they land. Each phase is meant to fit in one or two prompts.

### Pending tests (running list)
Everything here is written but not yet confirmed in game. Remove items as they pass. A new Space Age game covers all of them. Numbers stay fixed so they can be referred to.

**Passed on the local test server (2026-10-26, RCON, real players driven by script, no visual checks):** 1 (early leaver removed on all three planets, points released), 4 and 11 (removed settings gone), 5 (reroll cleans the old point and frees it), 12 (only the four planets have Secondary on), 13 (vanilla and Oarc style secondary spawns on Vulcanus), 15 and 16 (Fulgora attractors go to the owner, including in chunks generated later), 18 (attractors stay on `player` with no spawn), 19 (Oarc style Fulgora attractors go to the owner), 20, 21, 22 and 24 (evolution reset off and on, only on that planet, all four parts zeroed). The log had no errors.

**Bugs found and fixed while testing (2026-10-26):**
- Nauvis point 1 was always explored before anyone joined. Writing the grid moves every force's spawn position to point 1, and freeplay charts 200 tiles around the `player` force's spawn on the first join. Fix: `ApplyStartingPoints` puts all spawn positions back at the origin.
- A cleaned up point came back explored. Charts survive chunk deletion and regenerate the chunks, and shared vision gives the lobby force a chart request around every new spawn that waits while the lobby has nobody in it, then runs (and regenerates the deleted area) as soon as someone joins. Fix: the forced removal in `OarcRegrowthRemoveAllChunks` cancels pending chart requests for forces with nobody online, and uncharts each deleted chunk for every force. Spawn owners who are offline were not affected (their force charts straight away).

**Manual check for the two fixes: passed (2026-10-27)**, on a dedicated server with real clients and a temporary `DEBUG-CHUNKGEN` log (now removed):
- The first spawn gets point 1.
- A player leaves early while nobody else is online, the cleanup runs with the lobby empty, and on rejoin point 1 is reused.
- A player waits in the holding pen for about 7 minutes while cleanups run, with no chunks regenerated inside unclaimed points.
- Rerolls with an offline spawn owner leave no regenerated chunks, and the released points are claimed again after their cleanup with no `unusable` line.
- Test servers need `"auto_pause": false`, or no cleanup runs while nobody is online.
- Note: a point released less than 31 seconds before the next claim is still generated, so it is skipped and marked unusable for now. It becomes usable again after its cleanup.

**Passed by eye (2026-10-27):** 2 (a cleaned up area comes back as a vanilla starting area), 3 (the next new player gets the freed point), 6 to 10 (Oarc style spawn option: menu checkboxes, vanilla and prefab spawns with and without a moat, the prefab-only settings shown and hidden, and a large prefab spawn fully cleaned up), and the spawn menu layout with the setting off and on.

**Passed in the multiplayer test (2026-10-27, dedicated server, three real clients):** 14 (real flights to Fulgora, Vulcanus, Gleba and Aquilo: secondary spawns on each planet's grid, cargo pods redirected, item-only pods sent to the force's spawn) and 17 (two spawns on Fulgora, attractors go to the closer spawn). Also the holding pen wait, shared spawn joins (secondary spawns copy the joiners and open access), an early leaver reset, and the admin reset from the server info tab, which released the point. The log had no errors.

**Skipped:** 23 (joining a shared spawn does not reset evolution, low risk), offline protection (for now), and a prefab player's secondary spawn being a prefab (tested earlier by hand).

**Phase 6, translations:**
25. Switch the game language to German, Russian and Chinese and look over the spawn menu, the FAQ tab and the mod settings. The text was written without a native speaker, so it is worth a check by one if possible.

**Every test:** `factorio-current.log` has no errors.

**Deferred** (from earlier phases): custom map-gen starting points are replaced with an error message (Phase 2).

### Phase 0: Starting points on every surface (in this repo)
- [x] Extend the prototype so `on_init` loops over `game.planets` and creates any missing planet surfaces
- [x] Log `is_chunk_generated({0,0})` per surface, apply the grid, and clear only if already generated
- [x] Add an `on_surface_created` fallback that applies the grid in the same tick
- [x] Extend `/oarc-tp-start` to take a surface argument
- [x] Test with Space Age: only nauvis reports generated chunks, and each planet's grid points have a starting area (verified 2026-10-26)
- [x] Test without Space Age (nauvis only): only nauvis was processed, cleared as expected, no errors (verified 2026-10-26)
- [x] Decision: apply grids in `on_init`, pre-creating every planet surface with `planet.create_surface()`. Only nauvis needs `surface.clear(true)`. Keep the `on_surface_created` hook as a safety net for planet surfaces created after game start (it did not fire during `on_init`)

### Phase 1: Create Oarc Classic and strip features
- [x] Create the `oarc-classic` branch, commit the prototype and plan there, switch `oarc-mod` back to `master`, and add the worktree at `mods/oarc-classic`
- [x] Copy `CLAUDE.md` into the worktree
- [x] Update `info.json` (name, title, 1.0.0, `! oarc-mod`)
- [x] Rename the `oarc-mod-` prefix to `oarc-classic-` in settings, custom events and locale
- [x] Fresh `changelog.txt`, and update `README.md` and the locale description
- [x] Cut `TEMPLATE_SCENARIO` to a minimal skeleton (about 40 lines), rename the remote interfaces to `oarc_classic` and `oarc_classic_scenario`, and update its README and locale
- [x] Add a note to the `example/` map-gen JSON that the mod overwrites `starting_points`
- [x] Remove the item shop (tab, coin unhide)
- [x] Remove energy and item sharing (`lib/sharing.lua`, linked chest and pole, chest size setting)
- [x] Remove enemy scaling (`lib/scaled_enemies.lua` and its event hooks)
- [x] Remove buddy spawns (fields, GUI flow, `GetBuddySpawnPosition`, `disable_solo_spawns`)
- [x] Remove the main team (`main_force_name`, "join main team" choice)
- [x] Prune `settings.lua`, `lib/config.lua`, the `lib/config_parser.lua` table, the settings tab and locale for everything above
- [x] Test (single player): the mod loads with and without Space Age, spawning works on a new own force, reset and respawn work, the GUI tabs and mod settings show no removed features, and the log is clean (verified 2026-10-26)
- [x] Test (multiplayer): shared spawn join, and remove player (verified 2026-10-27 in the Phase 6 multiplayer test)

### Phase 2: Grid and assignment (complete, 2026-10-26)
- [x] Create `lib/starting_points.lua`: `BuildStartingPointGrid`, `ApplyStartingPoints`, `ClaimNextStartingPoint`, `ReleaseStartingPoint`
- [x] Add the explored check (10x10 chunks around the point) that marks a point `unusable`
- [x] Add settings: starting point count (16, from 1 to 128) and spacing in chunks (100, from 20 to 1000), plus the per-surface config override. They are left out of the in-game settings tab, and changing them after game start only shows a message
- [x] Apply grids at game start, using the route chosen in Phase 0
- [x] In `ApplyStartingPoints`, detect existing `starting_points` other than a single (0,0) point, log a clear error (and print it to admins), then overwrite anyway. Admins who join later see it once
- [ ] Test (deferred): set custom starting points in the new-game map-gen settings, confirm the error appears and the grid still replaces them
- [x] Replace the `FindUngeneratedCoordinates` calls with `ClaimNextStartingPoint` (spawn GUI, `SecondarySpawn`, `/oarc-reroll-spawn`), and remove the function and the near/far distance settings. `minimum_distance_to_existing_chunks` stays until Phase 3, because cleanup still uses it
- [x] Add a "no free starting points" error message
- [x] Natural spawn: slim down `GenerateFinalSpawnPieces`, and use a safe teleport in `SendPlayerToNewSpawn`. Prefab pieces sit behind `IsPrefabSpawnStyle()`, which returns false until Phase 4 adds the setting. The crash site is kept in natural mode
- [x] Leave (0,0) out of the grid and the map gen starting points (the engine always generates it on nauvis)
- [x] Add `/oarc-test-planet <planet> [player]` to make a secondary spawn on another planet without flying there
- [x] Test: spiral order, and an explored point gets skipped (verified 2026-10-26: the origin was blocked, which led to the change above; explored points 4 and 5 were skipped, and a reset player's point was reused after cleanup)
- [x] Test (after the origin change): the grid points are correct, and (0,0) is not a starting point on any surface (verified 2026-10-26)
- [x] Test: `/oarc-test-planet vulcanus` makes a spawn on Vulcanus point 1, and running it again returns to the same spawn (verified 2026-10-26)

### Phase 3: Cleanup
- [x] `UniqueSpawnCleanupRemove`: fixed `chunk_radius = 5` (`STARTING_POINT_CLEANUP_CHUNK_RADIUS`, also used by `/oarc-reroll-spawn`), drop the near-spawn check (the `ReleaseStartingPoint` call already landed in Phase 2)
- [x] Remove the `minimum_distance_to_existing_chunks` setting, config key and locale entries (cleanup was the last user)
- [x] Test: join and leave quickly, and the point is reused (verified 2026-10-27, manual check above)
- [x] Test by eye: the cleaned up area regenerates as a vanilla starting area (verified 2026-10-27)

### Phase 4: Prefab option
- [x] Add the "Allow Oarc Style Spawn Circle" setting (`gameplay.allow_oarc_style_spawn`, runtime-global, default off), read by `IsOarcStyleSpawnAllowed()`. It replaced an earlier global spawn style setting
- [x] Spawn menu: when the setting is on, show the "OG Oarc style spawn" checkbox (default unchecked, meaning vanilla). The moat checkbox only shows when the setting is on, and is only enabled while the Oarc style is ticked
- [x] Store the choice per spawn (`prefab` on spawn choices, unique spawns and delayed spawns). Secondary spawns copy it from the primary spawn, and the setting is checked again whenever a spawn is created
- [x] Gate the crop shape, moat, liquid strip, resources and random entities on the spawn's `prefab` flag (`GenerateFinalSpawnPieces`, `SetupAndClearSpawnAreas` via the closest spawn)
- [x] When the setting is off, hide the `prefab_only` settings (moat, spawn area, resource placement) in the settings tab, and the resources and liquid strip sections in the surface config tab. Its starting items and crash site sections stay, because they apply to both styles. Toggling the setting refreshes the GUI
- [x] Cleanup radius for a prefab spawn is the larger of 5 chunks and the prefab's own chunk radius (`GetSpawnCleanupChunkRadius(unique_spawn)`), so a large spawn radius is still fully removed
- [x] Add an `allow_oarc_style_spawn = true` example to the template scenario
- [x] Test: with the setting off, the spawn menu has no style or moat checkbox, and spawns are vanilla (verified 2026-10-27)
- [x] Test: with it on, a ticked spawn gets the prefab centred on the claimed point (with and without moat), and an unticked spawn is vanilla (verified 2026-10-27)
- [x] Test: a prefab player's secondary spawn on another planet is also a prefab, and a vanilla player's is vanilla (tested earlier by hand)
- [x] Test: the settings tab and surface config tab hide or show the prefab-only parts when the setting is toggled (verified 2026-10-27)

### Phase 5: Planets, Fulgora, evolution
- [x] Secondary spawns always on, and remove the `default_enable_secondary_spawns_on_other_surfaces` startup setting. Every planet except the default surface gets `secondary = true` in `SeparateSpawnsInitSurface`. Non-planet surfaces from other mods have no grid, so they get neither. Admins can still toggle each surface in the settings tab
- [x] `SecondarySpawn` claims a point from the planet's grid (landed in Phase 2)
- [x] Test: in a new Space Age game, the settings tab shows Secondary ticked for Vulcanus, Fulgora, Gleba and Aquilo, and not for Nauvis. The "Enable secondary spawns by default" startup setting is gone (verified 2026-10-26, tests 4, 11 and 12)
- [x] Fulgora: in `on_chunk_generated`, give `player` force lightning attractors to the force of the closest spawn's host (left on `player` if no spawn exists on the surface). Oarc style spawns create their scripted attractors on the owner's force
- [x] Test: Fulgora attractors around a new spawn belong to the owner's force and can be deconstructed (verified 2026-10-26 and 2026-10-27, tests 15 to 19)
- [x] Add the evolution reset setting (default off), with the reset at the top of `QueueNewSpawnGeneration`
- [x] Test on Vulcanus and Fulgora: cargo pod redirect, attractors, and evolution reads 0 in the holding pen (verified 2026-10-27, tests 14, 17 and 20 to 24; 23 skipped)

### Phase 6: GUI and docs
- [x] Simplify the spawn choice GUI (new spawn, join, cancel). The spawn settings and solo spawn frames are merged into one "Start a New Spawn" frame (`CreateNewSpawnFrame`), with the surface dropdown, style and moat checkboxes, and the button. The shared spawn frame and the cancel wait menu are unchanged. Removed the unused and outdated spawn menu locale keys from every language. Also fixed: picking Join with no host selected used to close the menu with nothing to replace it, the cancel path always logged an error, and the "Select Surface" label was hardcoded. Server test passed (2026-10-26)
- [x] Test by eye: the spawn menu layout with the Oarc style setting off and on (verified 2026-10-27)
- [x] Show admins a claimed starting point count per surface in the server info tab
- [x] Update the FAQ, locale and changelog. New FAQ entries for starting points, Oarc style spawns (only shown when allowed), rerolls and the evolution reset (only shown when on), and rewrote the outdated answers (teams, secondary spawns, cleanup). German, Russian and Chinese are translated in full, including the strings they were missing before, and the broken Russian setting keys are fixed. The 1.0.0 changelog lists everything
- [x] Spawn reroll: kept, once per surface for players, no limit for admins, who can also name another player. Server test passed (2026-10-26): second reroll refused, admin unlimited, no free point keeps the reroll, a non-admin can't target someone else, and Vulcanus has its own reroll after Nauvis is used up
- [x] Multiplayer test: holding pen and join queue (verified 2026-10-27). Offline protection skipped for now

### Phase 7: Public publish and playtesting
- [ ] Push the branch (only after Phases 1 to 6 are done and tested)
- [ ] Tag `classic-1.0.0` and build the release zip without the worktree `.git` file
- [ ] Publish to the mod portal, with the source link pointing at the branch URL
- [ ] Public multiplayer playtest, then fix reported bugs and ship follow-up releases
