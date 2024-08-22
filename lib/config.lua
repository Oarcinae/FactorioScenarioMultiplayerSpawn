--[[
  __  __  ___  ___   __      ___   ___ _  _ ___ _  _  ___
 |  \/  |/ _ \|   \  \ \    / /_\ | _ \ \| |_ _| \| |/ __|
 | |\/| | (_) | |) |  \ \/\/ / _ \|   / .` || || .` | (_ |
 |_|  |_|\___/|___/    \_/\_/_/ \_\_|_\_|\_|___|_|\_|\___|

 DO NOT EDIT THIS FILE! If you want to customize this, edit the config-scenario.lua file and load that scenario!
 
]]

-- More settings are available here than are provided in the mod settings menu.
-- Additionally, many settings are exposed in the game itself and can be chanced once you launch.
-- For convenience you can provide you own config-scenario.lua file in the scenarios/OARC folder to override these settings.

---@type OarcConfigStartingItems
NAUVIS_STARTER_ITEMS =
{
    player_start_items = {
        ["pistol"]=1,
        ["firearm-magazine"]=200,
        ["iron-plate"]=100,
        ["burner-mining-drill"] = 4,
        ["stone-furnace"] = 4,
        ["coal"] = 50,
        ["stone"] = 50,
    },
    player_respawn_items = {
        -- ["pistol"]=1,
        -- ["firearm-magazine"]=100,
    },

    crashed_ship = true,
    crashed_ship_resources = {
        ["electronic-circuit"] = 200,
        ["iron-gear-wheel"] = 100,
        ["copper-cable"] = 200,
        ["steel-plate"] = 100
    },
    crashed_ship_wreakage = {
        ["iron-plate"] = 100 -- I don't recommend more than 1 item type here!
    },
}

---@type OarcConfigSpawn
NAUVIS_SPAWN_CONFIG =
{
    general = {

        -- Create a circle of land area for the spawn
        -- If you make this much bigger than a few chunks, good luck.
        spawn_radius_tiles = CHUNK_SIZE*2,

        -- If you change the spawn area size, you might have to adjust this as well
        moat_size_modifier = 1,

        -- Start resource shape. true = circle, false = square.
        resources_circle_shape = true,

        -- Force the land area circle at the spawn to be fully grass, otherwise it defaults to the existing terrain.
        force_grass = true,

        -- Spawn a circle/octagon of trees around the base outline.
        tree_circle = true,
        tree_octagon = false,
    },

    -- Safe Spawn Area Options
    -- The default settings here are balanced for my recommended map gen settings (close to train world).
    safe_area =
    {
        -- Safe area has no aliens
        -- This is the radius in tiles of safe area.
        safe_radius = CHUNK_SIZE*6,

        -- Warning area has significantly reduced aliens
        -- This is the radius in tiles of warning area.
        warn_radius = CHUNK_SIZE*12,

        -- 1 : X (spawners alive : spawners destroyed) in this area
        warn_reduction = 20,

        -- Danger area has slightly reduce aliens
        -- This is the radius in tiles of danger area.
        danger_radius = CHUNK_SIZE*32,

        -- 1 : X (spawners alive : spawners destroyed) in this area
        danger_reduction = 5,
    },

    -- Location of water strip within the spawn area (horizontal)
    water = {
        x_offset = -4,
        y_offset = -48,
        length = 8,
    },

    -- Handle placement of starting resources
    resource_rand_pos_settings =
    {
        -- Autoplace resources (randomly in circle)
        -- This will ignore the fixed x_offset/y_offset values in solid_resources.
        -- Only works for solid_resources at the moment, not oil patches/water.
        enabled = true,
        -- Distance from center of spawn that resources are placed.
        radius = 45,
        -- At what angle (in radians) do resources start.
        -- 0 means starts directly east.
        -- Resources are placed clockwise from there.
        angle_offset = 2.32, -- 2.32 is approx SSW.
        -- At what andle do we place the last resource.
        -- angle_offset and angle_final determine spacing and placement.
        angle_final = 4.46 -- 4.46 is approx NNW.
    },

    -- Solid resource tiles
    -- If you are running with mods that add or change resources, you'll want to customize this.
    solid_resources = {
        ["iron-ore"] = {
            amount = 1500,
            size = 18,
            x_offset = -29,
            y_offset = 16
        },
        ["copper-ore"] = {
            amount = 1200,
            size = 18,
            x_offset = -28,
            y_offset = -3
        },
        ["stone"] = {
            amount = 1200,
            size = 16,
            x_offset = -27,
            y_offset = -34
        },
        ["coal"] = {
            amount = 1200,
            size = 16,
            x_offset = -27,
            y_offset = -20
        }
    },

    -- Fluid resource patches like oil
    -- If you are running with mods that add or change resources, you'll want to customize this.
    fluid_resources =
    {
        ["crude-oil"] =
        {
            num_patches = 2,
            amount = 900000,
            x_offset_start = -3,
            y_offset_start = 48,
            x_offset_next = 6,
            y_offset_next = 0
        }
    },
}

---@type OarcConfigSurface
NAUVIS_SURFACE_CONFIG =
{
    starting_items = NAUVIS_STARTER_ITEMS,
    spawn_config = NAUVIS_SPAWN_CONFIG
}

---@type OarcConfig
OCFG = {

    -- Server Info - This stuff is shown in the welcome GUI and Info panel.
    ---@type OarcConfigServerInfo
    server_info = {
        welcome_msg_title = "OARC V2 - TEST SERVER",
        welcome_msg = "TEMPORARY BETA TESTING OF V2 MOD!", -- Printed to player on join as well.
        server_msg = "Rules: Be polite. Ask before changing other players's stuff. Have fun!\n"..
        "This server is running a custom mod that allows individual starting areas on the map."
    },

    -- General gameplay related settings that I didn't want to expose in the mod settings since these should
    -- basically always be enabled unless you're making serious changes.
    gameplay = {

        
        -- At least one of these must be enabled! (enable_main_team and enable_separate_teams)
        -- Otherwise we default to enable_main_team = true
        -- Allow all players to join a primary force(team).
        enable_main_team = true,

        -- Allow players to create their own force(team).
        enable_separate_teams = true,

        -- Enable spawning on other surfaces other than the default "nauvis".
        enable_spawning_on_other_surfaces = true,

        -- Allow players to choose to spawn with a moat
        allow_moats_around_spawns = true,

        -- If there is a moat, this makes a small path to land to avoid "turtling", but if the spawn
        -- is in the middle of water, it won't do anything.
        enable_moat_bridging = true,

        -- This is the radius, in chunks, that a spawn area is from any other generated
        -- chunks. It ensures the spawn area isn't too near generated/explored/existing
        -- area. The larger you make this, the further away players will spawn from
        -- generated map area (even if it is not visible on the map!).
        minimum_distance_to_existing_chunks = 10,

        -- When a player selects "near" spawn, they will be within or as close to this range as possible.
        -- This is the distance in chunks to the origin.
        near_spawn_min_distance = 100,
        near_spawn_max_distance = 200,

        -- When a player selects "far" spawn, they will be AT LEAST this distance away.
        -- This is the distance in chunks to the origin.
        far_spawn_min_distance = 500,
        far_spawn_max_distance = 1000,

        -- This allows 2 players to spawn next to each other, each with their own starting area.
        enable_buddy_spawn = true,

        -- TODO: Vanilla spawn point are not implemented yet.
        -- enable_vanilla_spawn_points = true,
        -- number_of_vanilla_spawn_points = 10,
        -- vanilla_spawn_point_spacing = 100,

        -- This inhibits enemy attacks on bases where all players are offline. Not 100% guaranteed!
        enable_offline_protection = true,

        -- Enable shared vision between teams (all teams are COOP regardless)
        enable_shared_team_vision = true,

        -- Share local team chat with all teams
        -- This makes it so you don't have to use /s
        -- But it also means you can't talk privately with your own team.
        enable_shared_team_chat = true,

        -- Enable if players can allow others to join their base.
        -- And specify how many including the host are allowed.
        enable_shared_spawns = true,
        number_of_players_per_shared_spawn = 3,

        -- I like keeping this off... set to true if you want to shoot your own chests and stuff.
        enable_friendly_fire = true,

        -- The name of the main force.
        main_force_name = "Main Force",

        -- The default starting surface.
        default_surface = "nauvis",

        -- This scales resources so that even if you spawn "far away" from the center
        -- of the map, resources near to your spawn point scale so you aren't
        -- surrounded by 100M patches or something. This is useful depending on what
        -- map gen settings you pick.
        scale_resources_around_spawns = true,

        -- Adjust enemy spawning based on distance to spawns. All it does it make things
        -- more balanced based on your distance and makes the game a little easier.
        -- No behemoth worms everywhere just because you spawned far away.
        -- If you're trying out the vanilla spawning, you might want to disable this.
        modified_enemy_spawning = true,

        -- Require playes to be online for at least X minutes
        -- Else their character is removed and their spawn point is freed up for use
        -- TODO: Move this to mod settings?
        minimum_online_time = 15,

        -- Respawn cooldown in minutes.
        respawn_cooldown_min = 15,


    },

    -- This is a separate feature that is part of the mod that helps keep the map size down. Not required but useful.
    regrowth =  {
        -- Cleans up unused chunks periodically. Helps keep map size down.
        -- See description in regrowth_map.lua for more details.
        enable_regrowth = false,

        -- This is part of regrowth, and if both are enabled, any chunks which aren't active and have no entities
        -- will eventually be deleted over time. If this is disabled, any chunk with a player built entity will be 
        -- marked permanently safe even if it is removed at a later time.
        -- DO NOT USE THIS WITH MODS! (unless you know what you're doing?)
        enable_world_eater = false,

        -- This removes player bases when they leave shortly after joining.
        -- TODO: verify if this requires regrowth to be enabled!
        enable_abandoned_base_cleanup = true,

        surface_blacklist = {"oarc_holding_pen"},
    },

    -- Spawn configuration (starting items and spawn area config) for each surface.
    ---@type table<string, OarcConfigSurface>
    surfaces_config = 
    {
        ["nauvis"] = {
            starting_items = NAUVIS_STARTER_ITEMS,
            spawn_config = NAUVIS_SPAWN_CONFIG
        },
        ["vulcanus"] = {
            starting_items = NAUVIS_STARTER_ITEMS,
            spawn_config = NAUVIS_SPAWN_CONFIG
        },
        ["fulgora"] = {
            starting_items = NAUVIS_STARTER_ITEMS,
            spawn_config = NAUVIS_SPAWN_CONFIG
        },
        ["gleba"] = {
            starting_items = NAUVIS_STARTER_ITEMS,
            spawn_config = NAUVIS_SPAWN_CONFIG
        },
        ["aquilo"] = {
            starting_items = NAUVIS_STARTER_ITEMS,
            spawn_config = NAUVIS_SPAWN_CONFIG
        }
    },
}





--[[

  _   _   _  _     _______   _____ ___     _   _  _ _  _  ___ _____ _ _____ ___ ___  _  _ ___
 | | | | | |/_\   |_   _\ \ / / _ \ __|   /_\ | \| | \| |/ _ \_   _/_\_   _|_ _/ _ \| \| / __|
 | |_| |_| / _ \    | |  \ V /|  _/ _|   / _ \| .` | .` | (_) || |/ _ \| |  | | (_) | .` \__ \
 |____\___/_/ \_\   |_|   |_| |_| |___| /_/ \_\_|\_|_|\_|\___/ |_/_/ \_\_| |___\___/|_|\_|___/

 These are LUA type annotations for development and editor support.
 You can ignore this unless you're making changes to the mod, in which case it might be helpful.
]]

---@class OarcConfig
---@field server_info OarcConfigServerInfo Personalized server info for the welcome GUI and Info panel.
---@field gameplay OarcConfigGameplaySettings Various mod gameplay settings
---@field regrowth OarcConfigRegrowth Regrowth specific settings (keeps map size down)
---@field surfaces_config table<string, OarcConfigSurface> Spawn configuration (starting items and spawn area config) for each surface.

---@class OarcConfigServerInfo
---@field welcome_msg_title string  Title of welcome GUI window.
---@field welcome_msg string Main welcome message. (Should provide mod info.)
---@field server_msg string Server specific message. (Rules, etc.)

---@class OarcConfigGameplaySettings
---@field enable_main_team boolean Allows all players to join a primary force(team).
---@field enable_separate_teams boolean Allows players to create their own force(team).
---@field enable_spawning_on_other_surfaces boolean Enable spawning on other surfaces other than the default.
---@field allow_moats_around_spawns boolean Allow players to choose to spawn with a moat
---@field enable_moat_bridging boolean If there is a moat, this makes a small path to land to avoid "turtling", but if the spawn is in the middle of water, it won't do anything.
---@field minimum_distance_to_existing_chunks number The radius, in chunks, that a spawn area is from any other generated chunks. It ensures the spawn area isn't too near generated/explored/existing area.
---@field near_spawn_min_distance number When a player selects "near" spawn, they will be within or as close to this range as possible.
---@field near_spawn_max_distance number When a player selects "near" spawn, they will be within or as close to this range as possible.
---@field far_spawn_min_distance number When a player selects "far" spawn, they will be AT LEAST this distance away.
---@field far_spawn_max_distance number When a player selects "far" spawn, they will be AT LEAST this distance away.
---@field enable_buddy_spawn boolean Allow 2 players to spawn next to each other, each with their own starting area.
---@field enable_offline_protection boolean Inhibits enemy attacks on bases where all players are offline. Not 100% guaranteed!
---@field enable_shared_team_vision boolean Enable shared vision between teams (all teams are COOP regardless)
---@field enable_shared_team_chat boolean Share local team chat with all teams
---@field enable_shared_spawns boolean Enable if players can allow others to join their spawn.
---@field number_of_players_per_shared_spawn number Number of players allowed to join a shared spawn.
---@field enable_friendly_fire boolean Set to true if you want to shoot your own chests and stuff.
---@field main_force_name string The name of the main force.
---@field default_surface string The starting surface of the main force.
---@field scale_resources_around_spawns boolean Scales resources so that even if you spawn "far away" from the center of the map, resources near to your spawn point scale so you aren't surrounded by 100M patches or something. This is useful depending on what map gen settings you pick.
---@field modified_enemy_spawning boolean Adjust enemy spawning based on distance to spawns. All it does it make things more balanced based on your distance and makes the game a little easier. No behemoth worms everywhere just because you spawned far away.
---@field minimum_online_time number Require playes to be online for at least X minutes Else their character is removed and their spawn point is freed up for use
---@field respawn_cooldown_min number Respawn cooldown in minutes.


---@class OarcConfigRegrowth
---@field enable_regrowth boolean Cleans up unused chunks periodically. Helps keep map size down.
---@field enable_world_eater boolean Checks inactive chunks to see if they are empty of entities and deletes them periodically.
---@field enable_abandoned_base_cleanup boolean Removes player bases when they leave shortly after joining.
---@field surface_blacklist table<string> List of surfaces to ignore automatically.

---@class OarcConfigSurface
---@field starting_items OarcConfigStartingItems Starting items for players on this surface (including crashed ship items)
---@field spawn_config OarcConfigSpawn Spawn area config for this surface

---@class OarcConfigStartingItems
---@field crashed_ship boolean Add a crashed ship like a vanilla game (create_crash_site) Resources go in the ship itself. (5 slots max!) Wreakage is distributed in small pieces. (I recommend only 1 item type.)
---@field crashed_ship_resources table Items to be placed in the crashed ship.
---@field crashed_ship_wreakage table Items to be placed in the crashed ship. (Recommend only 1 item type!)
---@field player_start_items table Items provided to the player the first time they join
---@field player_respawn_items table Items provided after EVERY respawn (disabled by default)

---@class OarcConfigSpawn
---@field general OarcConfigSpawnGeneral General spawn settings (size, shape, etc.)
---@field safe_area OarcConfigSpawnSafeArea How safe is the spawn area?
---@field water OarcConfigSpawnWater Water strip settings
---@field resource_rand_pos_settings OarcConfigSpawnResourceRandPosSettings Resource placement settings
---@field solid_resources table<string, OarcConfigSolidResource> Spawn area config for solid resource tiles
---@field fluid_resources table<string, OarcConfigFluidResource> Spawn area config for fluid resource patches (like oil)

---@class OarcConfigSpawnGeneral
---@field spawn_radius_tiles number THIS IS WHAT SETS THE SPAWN CIRCLE SIZE! Create a circle of land area for the spawn If you make this much bigger than a few chunks, good luck.
---@field moat_size_modifier number If you change the spawn area size, you might have to adjust this as well
---@field resources_circle_shape boolean Start resource shape. true = circle, false = square.
---@field force_grass boolean Force the land area circle at the spawn to be fully grass, otherwise it defaults to the existing terrain.
---@field tree_circle boolean Spawn a circle/octagon of trees around the base outline.
---@field tree_octagon boolean Spawn a circle/octagon of trees around the base outline.

---@class OarcConfigSpawnSafeArea
---@field safe_radius number Safe area has no aliens This is the radius in tiles of safe area.
---@field warn_radius number Warning area has significantly reduced aliens This is the radius in tiles of warning area.
---@field warn_reduction number 1 : X (spawners alive : spawners destroyed) in this area
---@field danger_radius number Danger area has slightly reduce aliens This is the radius in tiles of danger area.
---@field danger_reduction number 1 : X (spawners alive : spawners destroyed) in this area

---@class OarcConfigSpawnWater
---@field x_offset number Location of water strip within the spawn area (horizontal)
---@field y_offset number Location of water strip within the spawn area (vertical)
---@field length number Length of water strip within the spawn area

---@class OarcConfigSpawnResourceRandPosSettings
---@field enabled boolean Autoplace resources (randomly in circle) This will ignore the fixed x_offset/y_offset values in solid_resources. Only works for solid_resources at the moment, not oil patches/water.
---@field radius number Distance from center of spawn that resources are placed.
---@field angle_offset number At what angle (in radians) do resources start. 0 means starts directly east. Resources are placed clockwise from there.
---@field angle_final number At what andle do we place the last resource. angle_offset and angle_final determine spacing and placement.

---@alias OarcConfigSolidResource { amount: integer, size: integer, x_offset: integer, y_offset: integer } Amount and placement of solid resource tiles in the spawn area.
---@alias OarcConfigFluidResource { num_patches: integer, amount: integer, x_offset_start: integer, y_offset_start: integer, x_offset_next: integer, y_offset_next: integer } Amount and placement of fluid resource patches in the spawn area.