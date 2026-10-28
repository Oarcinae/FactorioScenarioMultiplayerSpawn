# Plan: Oarc Classic, a starting points spawn mod

## Summary
Oarc Classic is a stripped-down fork of Oarc on the long-lived `oarc-classic` branch, checked out as a worktree at `mods/oarc-classic`. At game start it writes a fixed grid of `MapGenSettings.starting_points` on every planet surface. Each new spawn claims the next free point, spiralling out from the center, and relies on the vanilla starting area for safety. There is no join limit, and points are never added after the game starts.

Phases 0 to 6 are implemented and nearly all tested (single player, dedicated server, and a three-client multiplayer test). What remains is the public release.

## Scope
- **Kept:** holding pen, offline protection, shared chat and vision, abandoned spawn cleanup, shared spawns and the join queue, secondary spawns on all planets, player list and server info tabs, respawn, cooldown, reset and remove player, spawn reroll.
- **Optional settings:** OG Oarc style spawn circle (per player, when allowed), evolution reset on new spawn. Regrowth and World Eater are left as is (off by default).
- **Removed:** item shop, buddy spawns, main team, energy and item sharing, enemy scaling, `FindUngeneratedCoordinates` and the distance settings, `minimum_distance_to_existing_chunks`, the cargo pod redirect, the `default_enable_secondary_spawns_on_other_surfaces` setting.

## Branch rules
- Never merge between `master` and `oarc-classic`. Move fixes across with `git cherry-pick`.
- Keep the branch local until Phases 1 to 6 are done and tested. No pushes before Phase 7.
- Tag releases with a prefix (`classic-1.0.0`). Point the mod portal source link at the branch URL. Exclude the worktree's `.git` file from release zips.
- Disable `oarc-mod` in Factorio while testing (`! oarc-mod` incompatibility).
- Names: settings, custom events and locale keys use the `oarc-classic-` prefix. Remote interfaces are `oarc_classic` and `oarc_classic_scenario`.

## Key design and decisions
- **Grids at game start:** `ApplyStartingPoints` runs in `on_init` for every planet, pre-creating missing surfaces with `planet.create_surface()`. Only nauvis has generated chunks then, so only nauvis needs `surface.clear(true)`. `on_surface_created` is kept as a safety net.
- **Grid:** `BuildStartingPointGrid(count, spacing_chunks)` takes the `count` indices closest to (0,0), sorted by distance then angle. (0,0) is left out, because the engine always generates it on nauvis.
- **Settings:** count (default 16, 1 to 128) and spacing in chunks (default 100, 20 to 1000) are startup settings, overridable per surface through the scenario. Changing them on an existing save has no effect, and `WarnIfStartingPointSettingsChanged` says so in chat.
- **Existing starting points:** anything other than a single (0,0) point is logged as an error, printed to admins, then overwritten. Points passed with `--map-gen-settings` are copied to every planet surface, so the error shows once per planet.
- **Claiming:** `ClaimNextStartingPoint` walks the list in order. A point with any generated chunk in the 10x10 chunk area around it is marked `unusable` and rechecked on later claims. This also wastes points that someone only walked past. Checking for player entities instead was planned and rejected because it needs too many exceptions; the reasons are in the comment on `IsStartingPointExplored`. `ReleaseStartingPoint` matches by position and also moves the host force's spawn position back to the origin (`ResetForceSpawnPositionOffPoint`), so cargo pods don't land on a released point.
- **Cleanup:** fixed 5 chunk radius (`STARTING_POINT_CLEANUP_CHUNK_RADIUS`), or the prefab's radius if larger (`GetSpawnCleanupChunkRadius`). It uses the forced regrowth removal path, so it works with regrowth off. Test servers need `"auto_pause": false`, or no cleanup runs with nobody online.
- **Gotchas fixed during testing:**
  - Writing the grid moves every force's spawn position to point 1, and freeplay charts around it. `ApplyStartingPoints` puts spawn positions back at the origin.
  - Charts survive chunk deletion and regenerate chunks. The forced removal cancels pending chart requests for forces with nobody online and uncharts deleted chunks for every force.
  - A point released less than about 31 seconds before the next claim is still generated, so it is skipped as unusable until its cleanup runs. Accepted.
- **Oarc style spawns:** runtime-global setting `oarc-classic-allow-oarc-style-spawn` (default off). The choice is stored as `prefab` per spawn, copied to secondary spawns, and rechecked when each spawn is created. Prefab-only settings are hidden while it is off.
- **Cargo pods:** no redirect. The engine lands pods at the force's spawn position, which `GenerateFinalSpawnPieces` sets once the spawn is generated. `OnCargoPodStartedAscending` still starts the secondary spawn when a pod leaves the platform.
- **Fulgora:** lightning attractors generated on the `player` force go to the force of the closest spawn's host (`AssignLightningAttractorsToClosestSpawn`). They stay on `player` if the surface has no spawn.
- **Evolution reset:** `oarc-classic-reset-evolution-on-new-spawn` (default off). `ResetEnemyEvolution(surface_name)` runs at the top of `QueueNewSpawnGeneration`, zeroes all evolution parts for that surface only, and announces it. Rerolls count, joins don't.
- **Reroll:** `/oarc-reroll-spawn [player]`. Players get one per surface, used up only if a free point was found. Admins have no limit and can target others. Before a reroll, the target's force is checked within 3 chunks of the old spawn:
  - Another force's player character (online or not) blocks the reroll, and so does any of the force's cargo pods in flight to that planet.
  - Buildings and landed cargo pods with items trigger a warning. Running the command again within 60 seconds goes ahead (`storage.reroll_confirmations`, keyed by the caller, for the same target and surface). The crash site, Fulgora ruin attractors, ghosts and empty pods don't count.
  - Joiners on the surface are still queued with the host. The command help, the FAQ and the secondary spawn tip explain all of this.

## Remaining work
- [ ] Phase 7: push the branch (`git push -u origin oarc-classic`), tag `classic-1.0.0`, build the zip without the worktree `.git` file, publish to the mod portal with the branch source link, then run a public multiplayer playtest and ship fixes.
- Every test: `factorio-current.log` has no errors.
