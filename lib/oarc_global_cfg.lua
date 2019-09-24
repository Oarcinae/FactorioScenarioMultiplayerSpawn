-- oarc_global_cfg.lua
-- April 2019
--
-- Here is where we store/init config values to the global table.
-- Allows runtime modification of game settings if we want it.
-- Also allows supporting both MOD and SCENARIO versions.

-- DON'T JUDGE ME


-- That's a LOT of settings.
function InitOarcConfig()

    global.ocfg = {}

    if (game.active_mods["clean-tutorial-grid"]) then
        global.ocfg.locked_build_area_tile = "clean-tutorial-grid"
    else
        global.ocfg.locked_build_area_tile = "tutorial-grid"
    end

     -- SCENARIO VERSION
    if (not game.active_mods["oarc-mod"]) then
        global.ocfg.welcome_title = WELCOME_MSG_TITLE
        global.ocfg.welcome_msg = WELCOME_MSG
        global.ocfg.server_rules = SERVER_MSG
        global.ocfg.minimum_online_time = MIN_ONLINE_TIME_IN_MINUTES
        global.ocfg.server_contact = CONTACT_MSG
        global.ocfg.enable_vanilla_spawns = ENABLE_VANILLA_SPAWNS
        global.ocfg.enable_buddy_spawn = ENABLE_BUDDY_SPAWN
        global.ocfg.frontier_rocket_silo = FRONTIER_ROCKET_SILO_MODE
        global.ocfg.silo_islands = SILO_ISLANDS_MODE
        global.ocfg.enable_undecorator = ENABLE_UNDECORATOR
        global.ocfg.enable_tags = ENABLE_TAGS
        global.ocfg.enable_long_reach = ENABLE_LONGREACH
        global.ocfg.enable_autofill = ENABLE_AUTOFILL
        global.ocfg.enable_loaders = ENABLE_LOADERS
        global.ocfg.enable_player_list = ENABLE_PLAYER_LIST
        global.ocfg.list_offline_players = PLAYER_LIST_OFFLINE_PLAYERS
        global.ocfg.enable_shared_team_vision = ENABLE_SHARED_TEAM_VISION
        global.ocfg.enable_regrowth = ENABLE_REGROWTH
        global.ocfg.enable_abandoned_base_removal = ENABLE_ABANDONED_BASE_REMOVAL
        global.ocfg.enable_research_queue = ENABLE_RESEARCH_QUEUE
        global.ocfg.lock_goodies_rocket_launch = LOCK_GOODIES_UNTIL_ROCKET_LAUNCH

        global.ocfg.modified_enemy_spawning = OARC_MODIFIED_ENEMY_SPAWNING
        global.ocfg.near_dist_start = NEAR_MIN_DIST
        global.ocfg.near_dist_end = NEAR_MAX_DIST
        global.ocfg.far_dist_start = FAR_MIN_DIST
        global.ocfg.far_dist_end = FAR_MAX_DIST
        global.ocfg.vanilla_spawn_count = VANILLA_SPAWN_COUNT
        global.ocfg.vanilla_spawn_spacing = VANILLA_SPAWN_SPACING

        global.ocfg.spawn_config = OARC_CFG

        global.ocfg.enable_separate_teams = ENABLE_SEPARATE_TEAMS
        global.ocfg.main_force = MAIN_FORCE
        global.ocfg.enable_shared_spawns = ENABLE_SHARED_SPAWNS
        global.ocfg.max_players_shared_spawn = MAX_PLAYERS_AT_SHARED_SPAWN
        global.ocfg.enable_shared_chat = ENABLE_SHARED_TEAM_CHAT
        global.ocfg.respawn_cooldown_min = RESPAWN_COOLDOWN_IN_MINUTES
        global.ocfg.frontier_silo_count = SILO_NUM_SPAWNS
        global.ocfg.frontier_silo_distance = SILO_CHUNK_DISTANCE
        global.ocfg.frontier_fixed_pos = SILO_FIXED_POSITION
        global.ocfg.frontier_pos_table = SILO_POSITIONS
        global.ocfg.frontier_silo_vision = ENABLE_SILO_VISION
        global.ocfg.frontier_allow_build = ENABLE_SILO_PLAYER_BUILD

        global.ocfg.enable_server_write_files = ENABLE_SERVER_WRITE_FILES

    -- MOD VERSION
    else
        log("Oarc MOD! Version: " .. game.active_mods["oarc-mod"].version)

        global.ocfg.welcome_title = settings.global["oarc-welcome-title"].value
        global.ocfg.welcome_msg = settings.global["oarc-welcome-msg"].value
        global.ocfg.server_rules = settings.global["oarc-server-rules"].value
        global.ocfg.minimum_online_time = settings.global["oarc-minimum-online-time"].value
        global.ocfg.server_contact = settings.global["oarc-server-contact"].value
        global.ocfg.enable_vanilla_spawns = settings.global["oarc-enable-vanilla-spawns"].value
        global.ocfg.enable_buddy_spawn = settings.global["oarc-enable-buddy-spawn"].value
        global.ocfg.frontier_rocket_silo = settings.global["oarc-frontier-rocket-silo"].value
        global.ocfg.enable_undecorator = settings.global["oarc-enable-undecorator"].value
        global.ocfg.enable_tags = settings.global["oarc-enable-tags"].value
        global.ocfg.enable_long_reach = settings.global["oarc-enable-long-reach"].value
        global.ocfg.enable_autofill = settings.global["oarc-enable-autofill"].value
        global.ocfg.enable_loaders = false
        global.ocfg.enable_player_list = settings.global["oarc-enable-player-list"].value
        global.ocfg.list_offline_players = settings.global["oarc-list-offline-players"].value
        global.ocfg.enable_shared_team_vision = settings.global["oarc-enable-shared-team-vision"].value
        global.ocfg.enable_regrowth = settings.global["oarc-enable-regrowth"].value
        global.ocfg.enable_research_queue = settings.global["oarc-enable-research-queue"].value
        global.ocfg.lock_goodies_rocket_launch = false
        global.ocfg.modified_enemy_spawning = settings.global["oarc-modified-enemy-spawning"].value
        global.ocfg.near_dist_start = settings.global["oarc-near-dist-start"].value
        global.ocfg.near_dist_end = settings.global["oarc-near-dist-end"].value
        global.ocfg.far_dist_start = settings.global["oarc-far-dist-start"].value
        global.ocfg.far_dist_end = settings.global["oarc-far-dist-end"].value
        global.ocfg.vanilla_spawn_count = settings.global["oarc-vanilla-spawn-count"].value
        global.ocfg.vanilla_spawn_spacing = settings.global["oarc-vanilla-spawn-spacing"].value

        global.ocfg.spawn_config = {
            gen_settings = {
                land_area_tiles = settings.global["oarc-enforce-land-area-tile-dist"].value,
                moat_choice_enabled = settings.global["oarc-allow-moat-choice"].value,
                moat_size_modifier = settings.global["oarc-moat-size-mod"].value,
                resources_circle_shape = settings.global["oarc-resource-shape-circle"].value,
                force_grass = settings.global["oarc-force-grass"].value,
                tree_circle = settings.global["oarc-tree-circle"].value,
                tree_octagon = settings.global["oarc-tree-octagon"].value,
            },
            safe_area =
            {
                safe_radius = CHUNK_SIZE*10,
                warn_radius = CHUNK_SIZE*20,
                warn_reduction = 20,
                danger_radius = CHUNK_SIZE*50,
                danger_reduction = 5,
            },
            water = {
                x_offset = settings.global["oarc-water-x-offset"].value,
                y_offset = settings.global["oarc-water-y-offset"].value,
                length = settings.global["oarc-water-length"].value,
            },
            resource_rand_pos_settings =
            {
                enabled = settings.global["oarc-resource-rand-pos-enabled"].value,
                radius = settings.global["oarc-resource-rand-pos-radius"].value,
                angle_offset = settings.global["oarc-resource-rand-pos-angle-offset"].value,
                angle_final = settings.global["oarc-resource-rand-pos-angle-final"].value,
            },
            resource_tiles =
            {
                [settings.global["oarc-resource-1-name"].value] =
                {
                    amount = settings.global["oarc-resource-1-amount"].value,
                    size = settings.global["oarc-resource-1-size"].value,
                    x_offset = -29,
                    y_offset = 16
                },
                [settings.global["oarc-resource-2-name"].value] =
                {
                    amount = settings.global["oarc-resource-2-amount"].value,
                    size = settings.global["oarc-resource-2-size"].value,
                    x_offset = -28,
                    y_offset = -3
                },
                [settings.global["oarc-resource-3-name"].value] =
                {
                    amount = settings.global["oarc-resource-3-amount"].value,
                    size = settings.global["oarc-resource-3-size"].value,
                    x_offset = -27,
                    y_offset = -34
                },
                [settings.global["oarc-resource-4-name"].value] =
                {
                    amount = settings.global["oarc-resource-4-amount"].value,
                    size = settings.global["oarc-resource-4-size"].value,
                    x_offset = -27,
                    y_offset = -20
                }
                -- [settings.global["oarc-resource-5-name"].value] =
                -- {
                --     amount = settings.global["oarc-resource-5-amount"].value,
                --     size = settings.global["oarc-resource-5-size"].value,
                --     x_offset = -27,
                --     y_offset = -20
                -- }
            },
            resource_patches =
            {
                [settings.global["oarc-resource-patch-1-name"].value] =
                {
                    num_patches = settings.global["oarc-resource-patch-1-count"].value,
                    amount = settings.global["oarc-resource-patch-1-amount"].value,
                    x_offset_start = 0,
                    y_offset_start = 48,
                    x_offset_next = 4,
                    y_offset_next = 0
                }
            },
        }

        global.ocfg.enable_separate_teams = settings.global["oarc-enable-separate-teams"].value
        global.ocfg.main_force = settings.global["oarc-main-force"].value
        global.ocfg.enable_shared_spawns = settings.global["oarc-enable-shared-spawns"].value
        global.ocfg.max_players_shared_spawn = settings.global["oarc-max-players-shared-spawn"].value
        global.ocfg.enable_shared_chat = settings.global["oarc-enable-shared-chat"].value
        global.ocfg.respawn_cooldown_min = settings.global["oarc-respawn-cooldown-min"].value
        global.ocfg.frontier_silo_count = settings.global["oarc-frontier-silo-count"].value
        global.ocfg.frontier_silo_distance = settings.global["oarc-frontier-silo-distance"].value
        global.ocfg.frontier_fixed_pos = false
        global.ocfg.frontier_pos_table = {{x = 0, y = 100}}
        global.ocfg.frontier_silo_vision = settings.global["oarc-frontier-silo-vision"].value
        global.ocfg.frontier_allow_build = true
    end


    -----------------------
    -- VALIDATION CHECKS --
    -----------------------

    if (not global.ocfg.frontier_rocket_silo or not global.ocfg.enable_vanilla_spawns) then
        global.ocfg.silo_islands = false
    end

    if (global.ocfg.enable_vanilla_spawns) then
        global.ocfg.enable_buddy_spawn = false
    end

end