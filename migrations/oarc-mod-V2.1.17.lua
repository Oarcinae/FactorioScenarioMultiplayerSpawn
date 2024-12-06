-- Add the new remove decoratives setting
if storage.ocfg.spawn_general.remove_decoratives == nil then
    log("Adding new remove_decoratives setting to spawn_general config.")
    storage.ocfg.spawn_general.remove_decoratives = false -- Defaults to false
end