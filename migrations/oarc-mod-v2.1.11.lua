-- For non-supported surfaces, make sure they have the default settings.
if storage.ocfg.surfaces_config["aquilo"].spawn_config.fill_tile == nil then
    storage.ocfg.surfaces_config["aquilo"] = {
        spawn_config = NAUVIS_SPAWN_CONFIG,
        starting_items = NAUVIS_STARTER_ITEMS
    }
end
if storage.ocfg.surfaces_config["vulcanus"].spawn_config.fill_tile == nil then
    storage.ocfg.surfaces_config["vulcanus"] = {
        spawn_config = NAUVIS_SPAWN_CONFIG,
        starting_items = NAUVIS_STARTER_ITEMS
    }
end
if storage.ocfg.surfaces_config["gleba"].spawn_config.fill_tile == nil then
    storage.ocfg.surfaces_config["gleba"] = {
        spawn_config = NAUVIS_SPAWN_CONFIG,
        starting_items = NAUVIS_STARTER_ITEMS
    }
end
log("Updating non-supported surfaces with default nauvis spawn_config and starting_items.")