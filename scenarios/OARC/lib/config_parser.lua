-- config_parser.lua
-- Aug 2024
-- This file is used to validate the config.lua file and handle any mod conflicts.

function ValidateAndLoadConfig()

    -- Save the config into the global table.
    ---@class OarcConfig
    global.ocfg = OCFG

    ReadModSettings()

    -- Validate enable_main_force and enable_separate_teams.
    -- Force enable_main_force if both are disabled.
    if (not global.ocfg.mod_overlap.enable_main_force and not global.ocfg.mod_overlap.enable_separate_teams) then
        log("Both main force and separate teams are disabled! Enabling main force. Please check your mod settings or config!")
        global.ocfg.mod_overlap.enable_main_force = true
    end

    -- TODO: Vanilla spawn point are not implemented yet.
    -- Validate enable_shared_spawns and enable_buddy_spawn.
    -- if (global.ocfg.enable_vanilla_spawns) then
    --     global.ocfg.enable_buddy_spawn = false
    -- end

end

-- Read in the mod settings and copy them to the OARC_CFG table, overwriting the defaults in config.lua.
function ReadModSettings()

    if not game.active_mods["oarc-mod"] then
        return
    end

    log("Copying mod settings to OCFG table...")

    -- Copy in the startup settings from the mod settings.
    global.ocfg.mod_overlap.enable_main_force = settings.startup["oarc-mod-enable-main-force"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_separate_teams = settings.startup["oarc-mod-enable-separate-teams"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_spawning_on_other_surfaces = settings.startup["oarc-mod-enable-spawning-on-other-surfaces"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_buddy_spawn = settings.startup["oarc-mod-enable-buddy-spawn"].value --[[@as boolean]]

    -- TODO: Vanilla spawn point are not implemented yet.
    -- settings.startup["oarc-mod-enable-vanilla-spawn-points"].value   
    -- settings.startup["oarc-mod-number-of-vanilla-spawn-points"].value
    -- settings.startup["oarc-mod-vanilla-spawn-point-spacing"].value

    -- Copy in the global settings from the mod settings.
    global.ocfg.mod_overlap.enable_regrowth = settings.global["oarc-mod-enable-regrowth"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_world_eater = settings.global["oarc-mod-enable-world-eater"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_offline_protection = settings.global["oarc-mod-enable-offline-protection"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_shared_team_vision = settings.global["oarc-mod-enable-shared-team-vision"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_shared_team_chat = settings.global["oarc-mod-enable-shared-team-chat"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_shared_spawns = settings.global["oarc-mod-enable-shared-spawns"].value --[[@as boolean]]
    global.ocfg.mod_overlap.number_of_players_per_shared_spawn = settings.global["oarc-mod-number-of-players-per-shared-spawn"].value --[[@as integer]]
    global.ocfg.mod_overlap.enable_abandoned_base_cleanup = settings.global["oarc-mod-enable-abandoned-base-cleanup"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_friendly_fire = settings.global["oarc-mod-enable-friendly-fire"].value --[[@as boolean]]
    global.ocfg.mod_overlap.allow_moats_around_spawns = settings.global["oarc-mod-enable-allow-moats-around-spawns"].value --[[@as boolean]]
    global.ocfg.mod_overlap.enable_moat_bridging = settings.global["oarc-mod-enable-force-bridges-next-to-moats"].value --[[@as boolean]]
    global.ocfg.mod_overlap.minimum_distance_to_existing_chunks = settings.global["oarc-mod-minimum-distance-to-existing-chunks"].value --[[@as integer]]
    global.ocfg.mod_overlap.near_spawn_min_distance = settings.global["oarc-mod-near-spawn-min-distance"].value --[[@as integer]]
    global.ocfg.mod_overlap.near_spawn_max_distance = settings.global["oarc-mod-near-spawn-max-distance"].value --[[@as integer]]
    global.ocfg.mod_overlap.far_spawn_min_distance = settings.global["oarc-mod-far-spawn-min-distance"].value --[[@as integer]]
    global.ocfg.mod_overlap.far_spawn_max_distance = settings.global["oarc-mod-far-spawn-max-distance"].value --[[@as integer]]
end

