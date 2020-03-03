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

     -- SCENARIO VERSION (ONLY - no more mod version.)
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
    global.ocfg.enable_chest_sharing = ENABLE_CHEST_SHARING
    global.ocfg.enable_offline_protect = ENABLE_OFFLINE_PROTECTION
    global.ocfg.enable_power_armor_start = ENABLE_POWER_ARMOR_QUICK_START
    global.ocfg.enable_modular_armor_start = ENABLE_MODULAR_ARMOR_QUICK_START
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