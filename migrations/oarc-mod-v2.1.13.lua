---For each planet's surface, mark the center of the map permanently safe from regrowth.
-- If we can detect and redirect cargo-pods, then this can be removed.

-- TODO: Hopefully a temporary measure to make sure map center never gets deleted.
-- If we can detect and redirect cargo-pods, then this can be removed.

-- Loop through each surface
for _,surface in pairs(game.surfaces) do
    if (storage.rg[surface.name] ~= nil) then
        for i = -2, 2 do
            for j = -2, 2 do
                MarkChunkSafe(surface.name, { x = i, y = j }, true)
            end
        end
        log("Applying migration for V2.1.13: Marked center of "..surface.name.." safe from regrowth.")
    end
end

-- Make sure vulcanus config is set up if it is missing or outdated.
if script.active_mods["space-age"] ~= nil then
    if (storage.ocfg.surfaces_config["vulcanus"] == nil) or
        (storage.ocfg.surfaces_config["vulcanus"].spawn_config.liquid_tile ~= "lava") then
        storage.ocfg.surfaces_config["vulcanus"] =
        {
            spawn_config = VULCANUS_SPAWN_CONFIG,
            starting_items = VULCANUS_STARTER_ITEMS
        }
        log("Updating vulcanus config with new spawn_config and starting_items.")
    end
end

-- Make sure gleba config is set up if it is missing or outdated.
if script.active_mods["space-age"] ~= nil then
    if (storage.ocfg.surfaces_config["gleba"] == nil) or
        (storage.ocfg.surfaces_config["gleba"].spawn_config.gleba_resources == nil) or
        (#storage.ocfg.surfaces_config["gleba"].spawn_config.gleba_resources == 0) then
        storage.ocfg.surfaces_config["gleba"] =
        {
            spawn_config = GLEBA_SPAWN_CONFIG,
            starting_items = GLEBA_STARTER_ITEMS
        }
        log("Updating gleba config with new spawn_config and starting_items.")
    end
end

-- Make sure aquilo config is set up if it is missing or outdated.
if script.active_mods["space-age"] ~= nil then
    if (storage.ocfg.surfaces_config["aquilo"] == nil) or
        (storage.ocfg.surfaces_config["aquilo"].spawn_config.fill_tile ~= "ice-smooth") then
        storage.ocfg.surfaces_config["aquilo"] =
        {
            spawn_config = AQUILO_SPAWN_CONFIG,
            starting_items = AQUILO_STARTER_ITEMS
        }
        log("Updating aquilo config with new spawn_config and starting_items.")
    end
end