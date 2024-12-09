-- Add the new remove decoratives setting
if storage.ocfg.spawn_general.remove_decoratives == nil then
    log("Adding new remove_decoratives setting to spawn_general config.")
    storage.ocfg.spawn_general.remove_decoratives = false
end

-- Add the new random order setting
if storage.ocfg.resource_placement.random_order == nil then
    log("Adding new random_order setting to resource_placement config.")
    storage.ocfg.resource_placement.random_order = true
end