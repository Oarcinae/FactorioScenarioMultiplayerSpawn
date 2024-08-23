-- This file is used to validate the config.lua file and handle any mod conflicts.

function ValidateAndLoadConfig()

    -- Save the config into the global table.
    ---@class OarcConfig
    global.ocfg = OCFG

    CacheModSettings()

    GetScenarioOverrideSettings()


    -- Validate enable_main_team and enable_separate_teams.
    -- Force enable_main_team if both are disabled.
    if (not global.ocfg.gameplay.enable_main_team and not global.ocfg.gameplay.enable_separate_teams) then
        log("Both main force and separate teams are disabled! Enabling main force. Please check your mod settings or config!")
        global.ocfg.gameplay.enable_main_team = true
    end

    -- TODO: Vanilla spawn point are not implemented yet.
    -- Validate enable_shared_spawns and enable_buddy_spawn.
    -- if (global.ocfg.enable_vanilla_spawns) then
    --     global.ocfg.enable_buddy_spawn = false
    -- end

end

-- Read in the mod settings and copy them to the OARC_CFG table, overwriting the defaults in config.lua.
function CacheModSettings()

    log("Copying mod settings to OCFG table...")

    -- TODO: Vanilla spawn point are not implemented yet.
    -- settings.global["oarc-mod-enable-vanilla-spawn-points"].value   
    -- settings.global["oarc-mod-number-of-vanilla-spawn-points"].value
    -- settings.global["oarc-mod-vanilla-spawn-point-spacing"].value

    -- Copy in the global settings from the mod settings.
    global.ocfg.server_info.welcome_msg_title = settings.global["oarc-mod-welcome-msg-title"].value --[[@as string]]
    global.ocfg.server_info.welcome_msg = settings.global["oarc-mod-welcome-msg"].value --[[@as string]]
    global.ocfg.server_info.server_msg = settings.global["oarc-mod-server-msg"].value --[[@as string]]

    global.ocfg.gameplay.enable_main_team = settings.global["oarc-mod-enable-main-team"].value --[[@as boolean]]
    global.ocfg.gameplay.enable_separate_teams = settings.global["oarc-mod-enable-separate-teams"].value --[[@as boolean]]
    global.ocfg.gameplay.enable_spawning_on_other_surfaces = settings.global["oarc-mod-enable-spawning-on-other-surfaces"].value --[[@as boolean]]

    global.ocfg.gameplay.allow_moats_around_spawns = settings.global["oarc-mod-allow-moats-around-spawns"].value --[[@as boolean]]
    global.ocfg.gameplay.enable_moat_bridging = settings.global["oarc-mod-enable-moat-bridging"].value --[[@as boolean]]
    global.ocfg.gameplay.minimum_distance_to_existing_chunks = settings.global["oarc-mod-minimum-distance-to-existing-chunks"].value --[[@as integer]]
    global.ocfg.gameplay.near_spawn_min_distance = settings.global["oarc-mod-near-spawn-min-distance"].value --[[@as integer]]
    global.ocfg.gameplay.near_spawn_max_distance = settings.global["oarc-mod-near-spawn-max-distance"].value --[[@as integer]]
    global.ocfg.gameplay.far_spawn_min_distance = settings.global["oarc-mod-far-spawn-min-distance"].value --[[@as integer]]
    global.ocfg.gameplay.far_spawn_max_distance = settings.global["oarc-mod-far-spawn-max-distance"].value --[[@as integer]]

    global.ocfg.gameplay.enable_buddy_spawn = settings.global["oarc-mod-enable-buddy-spawn"].value --[[@as boolean]]
    global.ocfg.gameplay.enable_offline_protection = settings.global["oarc-mod-enable-offline-protection"].value --[[@as boolean]]
    global.ocfg.gameplay.enable_shared_team_vision = settings.global["oarc-mod-enable-shared-team-vision"].value --[[@as boolean]]
    global.ocfg.gameplay.enable_shared_team_chat = settings.global["oarc-mod-enable-shared-team-chat"].value --[[@as boolean]]
    global.ocfg.gameplay.enable_shared_spawns = settings.global["oarc-mod-enable-shared-spawns"].value --[[@as boolean]]
    global.ocfg.gameplay.number_of_players_per_shared_spawn = settings.global["oarc-mod-number-of-players-per-shared-spawn"].value --[[@as integer]]
    global.ocfg.gameplay.enable_friendly_fire = settings.global["oarc-mod-enable-friendly-fire"].value --[[@as boolean]]

    global.ocfg.gameplay.main_force_name = settings.global["oarc-mod-main-force-name"].value --[[@as string]]
    global.ocfg.gameplay.default_surface = settings.global["oarc-mod-default-surface"].value --[[@as string]]
    global.ocfg.gameplay.scale_resources_around_spawns = settings.global["oarc-mod-scale-resources-around-spawns"].value --[[@as boolean]]
    global.ocfg.gameplay.modified_enemy_spawning = settings.global["oarc-mod-modified-enemy-spawning"].value --[[@as boolean]]
    global.ocfg.gameplay.minimum_online_time = settings.global["oarc-mod-minimum-online-time"].value --[[@as integer]]
    global.ocfg.gameplay.respawn_cooldown_min = settings.global["oarc-mod-respawn-cooldown-min"].value --[[@as integer]]

    global.ocfg.regrowth.enable_regrowth = settings.global["oarc-mod-enable-regrowth"].value --[[@as boolean]]
    global.ocfg.regrowth.enable_world_eater = settings.global["oarc-mod-enable-world-eater"].value --[[@as string]]
    global.ocfg.regrowth.enable_abandoned_base_cleanup = settings.global["oarc-mod-enable-abandoned-base-cleanup"].value --[[@as boolean]]
end

function GetScenarioOverrideSettings()

    if remote.interfaces["oarc_scenario"] then

        log("Getting scenario ode settings...")
        local scenario_settings = remote.call("oarc_scenario", "get_scenario_settings")

        -- Overwrite the non mod settings with the scenario settings.
        global.ocfg = scenario_settings

    else
        log("No scenario settings found.")
    end

end

---Handles the event when a mod setting is changed in the mod settings menu.
---@param event EventData.on_runtime_mod_setting_changed
---@return nil
function RuntimeModSettingChanged(event)

    log("on_runtime_mod_setting_changed" .. event.setting)

    if (event.setting == "oarc-mod-welcome-msg-title") then
        global.ocfg.server_info.welcome_msg_title = settings.global["oarc-mod-welcome-msg-title"].value --[[@as string]]
    elseif (event.setting == "oarc-mod-welcome-msg") then
        global.ocfg.server_info.welcome_msg = settings.global["oarc-mod-welcome-msg"].value --[[@as string]]
    elseif (event.setting == "oarc-mod-server-msg") then
        global.ocfg.server_info.server_msg = settings.global["oarc-mod-server-msg"].value --[[@as string]]
    elseif (event.setting == "oarc-mod-enable-main-team") then
        global.ocfg.gameplay.enable_main_team = settings.global["oarc-mod-enable-main-team"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-enable-separate-teams") then
        global.ocfg.gameplay.enable_separate_teams = settings.global["oarc-mod-enable-separate-teams"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-enable-spawning-on-other-surfaces") then
        global.ocfg.gameplay.enable_spawning_on_other_surfaces = settings.global["oarc-mod-enable-spawning-on-other-surfaces"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-allow-moats-around-spawns") then
        global.ocfg.gameplay.allow_moats_around_spawns = settings.global["oarc-mod-allow-moats-around-spawns"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-enable-moat-bridging") then
        global.ocfg.gameplay.enable_moat_bridging = settings.global["oarc-mod-enable-moat-bridging"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-minimum-distance-to-existing-chunks") then
        global.ocfg.gameplay.minimum_distance_to_existing_chunks = settings.global["oarc-mod-minimum-distance-to-existing-chunks"].value --[[@as integer]]
    elseif (event.setting == "oarc-mod-near-spawn-min-distance") then
        global.ocfg.gameplay.near_spawn_min_distance = settings.global["oarc-mod-near-spawn-min-distance"].value --[[@as integer]]
    elseif (event.setting == "oarc-mod-near-spawn-max-distance") then
        global.ocfg.gameplay.near_spawn_max_distance = settings.global["oarc-mod-near-spawn-max-distance"].value --[[@as integer]]
    elseif (event.setting == "oarc-mod-far-spawn-min-distance") then
        global.ocfg.gameplay.far_spawn_min_distance = settings.global["oarc-mod-far-spawn-min-distance"].value --[[@as integer]]
    elseif (event.setting == "oarc-mod-far-spawn-max-distance") then
        global.ocfg.gameplay.far_spawn_max_distance = settings.global["oarc-mod-far-spawn-max-distance"].value --[[@as integer]]
    elseif (event.setting == "oarc-mod-enable-buddy-spawn") then
        global.ocfg.gameplay.enable_buddy_spawn = settings.global["oarc-mod-enable-buddy-spawn"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-enable-offline-protection") then
        global.ocfg.gameplay.enable_offline_protection = settings.global["oarc-mod-enable-offline-protection"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-enable-shared-team-vision") then
        global.ocfg.gameplay.enable_shared_team_vision = settings.global["oarc-mod-enable-shared-team-vision"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-enable-shared-team-chat") then
        global.ocfg.gameplay.enable_shared_team_chat = settings.global["oarc-mod-enable-shared-team-chat"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-enable-shared-spawns") then
        global.ocfg.gameplay.enable_shared_spawns = settings.global["oarc-mod-enable-shared-spawns"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-number-of-players-per-shared-spawn") then
        global.ocfg.gameplay.number_of_players_per_shared_spawn = settings.global["oarc-mod-number-of-players-per-shared-spawn"].value --[[@as integer]]
    elseif (event.setting == "oarc-mod-enable-friendly-fire") then
        global.ocfg.gameplay.enable_friendly_fire = settings.global["oarc-mod-enable-friendly-fire"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-main-force-name") then
        global.ocfg.gameplay.main_force_name = settings.global["oarc-mod-main-force-name"].value --[[@as string]]
    elseif (event.setting == "oarc-mod-default-surface") then
        global.ocfg.gameplay.default_surface = settings.global["oarc-mod-default-surface"].value --[[@as string]]
    elseif (event.setting == "oarc-mod-scale-resources-around-spawns") then
        global.ocfg.gameplay.scale_resources_around_spawns = settings.global["oarc-mod-scale-resources-around-spawns"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-modified-enemy-spawning") then
        global.ocfg.gameplay.modified_enemy_spawning = settings.global["oarc-mod-modified-enemy-spawning"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-minimum-online-time") then
        global.ocfg.gameplay.minimum_online_time = settings.global["oarc-mod-minimum-online-time"].value --[[@as integer]]
    elseif (event.setting == "oarc-mod-respawn-cooldown-min") then
        global.ocfg.gameplay.respawn_cooldown_min = settings.global["oarc-mod-respawn-cooldown-min"].value --[[@as integer]]
    elseif (event.setting == "oarc-mod-enable-regrowth") then
        global.ocfg.regrowth.enable_regrowth = settings.global["oarc-mod-enable-regrowth"].value --[[@as boolean]]
    elseif (event.setting == "oarc-mod-enable-world-eater") then
        global.ocfg.regrowth.enable_world_eater = settings.global["oarc-mod-enable-world-eater"].value --[[@as string]]
    elseif (event.setting == "oarc-mod-enable-abandoned-base-cleanup") then
        global.ocfg.regrowth.enable_abandoned_base_cleanup = settings.global["oarc-mod-enable-abandoned-base-cleanup"].value --[[@as boolean]]
    else
        error("Unknown oarc-mod setting changed: " .. event.setting)
    end
end