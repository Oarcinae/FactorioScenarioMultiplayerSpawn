--Adding the "spacing" setting for fluid resources config.
for surface_name, surface_config in pairs(storage.ocfg.surfaces_config) do
    local fluid_resources = surface_config.spawn_config.fluid_resources
    for fluid_name, resource in pairs(fluid_resources) do
        if resource.spacing == nil then
            resource.spacing = 6
            log("Updating fluid resources [" .. fluid_name .. "] config with new 'spacing' setting.")
        end
    end
end

--Add setting for letting players reset themselves.
if storage.ocfg.gameplay.enable_player_self_reset == nil then
    storage.ocfg.gameplay.enable_player_self_reset = true
    log("Updating gameplay config with new 'enable_player_self_reset' setting.")
end