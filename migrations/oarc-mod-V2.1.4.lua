--Need to make sure the new config settings are added.
if storage.ocfg.gameplay.enable_friendly_teams == nil then
    storage.ocfg.gameplay.enable_friendly_teams = true
    log("Updating gameplay config with new 'enable_friendly_teams' setting.")
end
if storage.ocfg.gameplay.enable_cease_fire == nil then
    storage.ocfg.gameplay.enable_cease_fire = true
    log("Updating gameplay config with new 'enable_cease_fire' setting.")
end