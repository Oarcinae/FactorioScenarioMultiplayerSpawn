--Fix missing gleba_resources for the surfaces that I didn't update in 2.1.13.
if (storage.ocfg.surfaces_config["nauvis"].spawn_config.gleba_resources == nil) then
    storage.ocfg.surfaces_config["nauvis"].spawn_config.gleba_resources = {}
    log("Fixing nauvis config with empty gleba_resources entry.")
end

if script.active_mods["space-age"] ~= nil then
    if (storage.ocfg.surfaces_config["fulgora"].spawn_config.gleba_resources == nil) then
        storage.ocfg.surfaces_config["fulgora"].spawn_config.gleba_resources = {}
        log("Fixing fulgora config with empty gleba_resources entry.")
    end
end