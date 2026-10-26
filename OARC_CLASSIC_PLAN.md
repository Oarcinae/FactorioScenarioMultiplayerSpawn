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
| Holding pen | Prefab spawn shape at the point (crop circle, moat, scripted resources) | Item shop (`lib/gui_tabs/item_shop.lua`, coin unhide in `data.lua`) |
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
- `ApplyStartingPoints(surface)`: read `map_gen_settings`, set `starting_points`, write it back, and clear only if chunks were already generated (only nauvis in practice). Called in `on_init` for every planet, pre-creating missing surfaces as Phase 0 proved.
  - **Check for existing changes first.** The engine default is a single starting point at (0,0). If the existing `starting_points` is anything else (a different count, or a point not at (0,0)), log a clear error. The error names the surface, lists the existing points, and says they came from the map-gen settings, a preset or another mod and are being replaced. Then overwrite them anyway. Also print it to admins in game, so a host sees it without reading the log.
- `storage.starting_points[surface_name]`: an ordered list of `{position=, host_name=nil|string, unusable=false}`.
- `ClaimNextStartingPoint(surface_name, host_name)`:
  - Walks the list in order and skips entries that are claimed or unusable.
  - **Explored check:** for each candidate, checks `surface.is_chunk_generated` on every chunk in a 10x10 chunk area centred on the point. If any is generated, someone else has explored there. The entry is marked `unusable` and logged, and the walk continues.
  - Returns the first clean point and marks it claimed with the host name.
- `ReleaseStartingPoint(surface_name, host_name)`: called by cleanup. The point goes back to the pool.
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

## Phase 4: Optional prefab spawn
Add a mod setting, spawn style `natural` (default) or `prefab`. With `prefab`, keep today's pipeline centred on the claimed point:
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
  - In `GenerateFinalSpawnPieces`, after the spawn's chunks exist, find `lightning-attractor` entities on the `player` force within the 10x10 chunk area. Set their force to the spawn owner's force.
- **Evolution reset option:**
  - A runtime-global bool setting, "Reset evolution on new spawn", default off.
  - When a new primary or secondary spawn is queued, call `game.forces.enemy.set_evolution_factor(0, surface)` for that spawn's surface before generation starts.
  - The call goes at the top of `QueueNewSpawnGeneration` (`lib/separate_spawns.lua:1639`), before `request_to_generate_chunks`. Every new spawn passes through there, and it runs right after the point is claimed.
  - Joining someone else's spawn doesn't trigger it.
  - The reset affects everyone on that surface. Say so in the setting description.

## Phase 6: GUI and docs
- Simplify the spawn choice GUI to: start a new spawn, join a shared spawn, and cancel a join request.
- The spawn controls tab lists the grid's claimed and free points with `GetGPStext`.
- Update the FAQ tab, locale and changelog.

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
5. **Phase 4:** in prefab mode, the crop circle and resources are centred on the claimed point.
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
- [ ] Test (multiplayer, deferred to the Phase 6 multiplayer test): shared spawn join, and remove player

### Phase 2: Grid and assignment
- [ ] Create `lib/starting_points.lua`: `BuildStartingPointGrid`, `ApplyStartingPoints`, `ClaimNextStartingPoint`, `ReleaseStartingPoint`
- [ ] Add the explored check (10x10 chunks around the point) that marks a point `unusable`
- [ ] Add settings: starting point count (16, from 1 to 128) and spacing in chunks (100), plus the per-surface config override
- [ ] Apply grids at game start, using the route chosen in Phase 0
- [ ] In `ApplyStartingPoints`, detect existing `starting_points` other than a single (0,0) point, log a clear error (and print it to admins), then overwrite anyway
- [ ] Test: set custom starting points in the new-game map-gen settings, confirm the error appears and the grid still replaces them
- [ ] Replace the `FindUngeneratedCoordinates` calls with `ClaimNextStartingPoint`, and remove the function and the distance settings
- [ ] Add a "no free starting points" error message
- [ ] Natural spawn: slim down `GenerateFinalSpawnPieces`, and use a safe teleport in `SendPlayerToNewSpawn`
- [ ] Test: spiral order, and an explored point gets skipped

### Phase 3: Cleanup
- [ ] `UniqueSpawnCleanupRemove`: fixed `chunk_radius = 5`, drop the near-spawn check, call `ReleaseStartingPoint`
- [ ] Test: join and leave quickly, the area regenerates, and the point is reused

### Phase 4: Prefab option
- [ ] Add the spawn style setting (`natural` or `prefab`)
- [ ] Gate the crop shape, moat, resources and the surface config tab behind `prefab`
- [ ] Test: the prefab is centred on the claimed point

### Phase 5: Planets, Fulgora, evolution
- [ ] Secondary spawns always on, and remove the setting
- [ ] `SecondarySpawn` claims a point from the planet's grid
- [ ] Fulgora: reassign `player` force lightning attractors in the spawn area to the owner's force
- [ ] Add the evolution reset setting (default off), with the reset at the top of `QueueNewSpawnGeneration`
- [ ] Test on Vulcanus and Fulgora: cargo pod redirect, attractors, and evolution reads 0 in the holding pen

### Phase 6: GUI and docs
- [ ] Simplify the spawn choice GUI (new spawn, join, cancel)
- [ ] List claimed and free points in the spawn controls tab
- [ ] Update the FAQ, locale and changelog
- [ ] Multiplayer test: holding pen, join queue, offline protection

### Phase 7: Public publish and playtesting
- [ ] Push the branch (only after Phases 1 to 6 are done and tested)
- [ ] Tag `classic-1.0.0` and build the release zip without the worktree `.git` file
- [ ] Publish to the mod portal, with the source link pointing at the branch URL
- [ ] Public multiplayer playtest, then fix reported bugs and ship follow-up releases
