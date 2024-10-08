-- Migrate safe_radius, warn_radius and danger_radius to be chunks instead of tiles.
for surface_name, surface_config in pairs(global.ocfg.surfaces_config) do
    
    -- If the safe_area is greater than 3 chunks, then it's likely in chunks...
    if surface_config.spawn_config.safe_area.safe_radius >= (3 * 32) then
        log("Oarc-mod: Migrating safe_radius, warn_radius and danger_radius to be chunks instead of tiles.")
        local safe_radius = surface_config.spawn_config.safe_area.safe_radius
        global.ocfg.surfaces_config[surface_name].spawn_config.safe_area.safe_radius = math.ceil(safe_radius / 32)

        local warn_radius = surface_config.spawn_config.safe_area.warn_radius
        global.ocfg.surfaces_config[surface_name].spawn_config.safe_area.warn_radius = math.ceil(warn_radius / 32)

        local danger_radius = surface_config.spawn_config.safe_area.danger_radius
        global.ocfg.surfaces_config[surface_name].spawn_config.safe_area.danger_radius = math.ceil(danger_radius / 32)
    end
end