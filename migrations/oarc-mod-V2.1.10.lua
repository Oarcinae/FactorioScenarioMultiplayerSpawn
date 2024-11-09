--Migrate the force_grass to force_tiles new setting!
if storage.ocfg.spawn_general.force_tiles == nil then
    storage.ocfg.spawn_general.force_tiles = true
    log("Updating spawn_general config with new 'force_tiles' setting.")
end

--Make sure new planets get init'd. No harm in running this multiple times.
SeparateSpawnsInitPlanets()

--Migrate surface config changes!