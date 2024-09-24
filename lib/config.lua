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

---@alias SpawnShapeChoice "circle" | "octagon" | "square"
SPAWN_SHAPE_CHOICE_CIRCLE = "circle"
SPAWN_SHAPE_CHOICE_OCTAGON = "octagon"
SPAWN_SHAPE_CHOICE_SQUARE = "square"

---@alias SpawnResourcesShapeChoice "circle" | "square"
RESOURCES_SHAPE_CHOICE_CIRCLE = "circle"
RESOURCES_SHAPE_CHOICE_SQUARE = "square"

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

        -- Danger area has slightly reduced aliens
        -- This is the radius in tiles of danger area.
        danger_radius = CHUNK_SIZE*32,

        -- 1 : X (spawners alive : spawners destroyed) in this area
        danger_reduction = 5,
    },

    -- Location of water strip within the spawn area (2 horizontal rows)
    -- The offset is from the TOP (NORTH) of the spawn area.
    water = {
        x_offset = -4,
        y_offset = 10,
        length = 8,
    },

    -- Location of shared power pole within the spawn area (if enabled)
    -- The offset is from the RIGHT (WEST) of the spawn area.
    shared_power_pole_position = {
        x_offset=-10,
        y_offset=0
    },

    -- Location of shared chest within the spawn area (if enabled)
    -- The offset is from the RIGHT (WEST) of the spawn area.
    shared_chest_position = {
        x_offset=-10,
        y_offset=1
    },

    -- Solid resource tiles
    -- If you are running with mods that add or change resources, you'll want to customize this.
    -- Offsets only are applicable if auto placement is disabled. Offsets are from CENTER of spawn area.
    solid_resources = {
        ["iron-ore"] = {
            amount = 1500,
            size = 21,
            x_offset = -29,
            y_offset = 16
        },
        ["copper-ore"] = {
            amount = 1200,
            size = 21,
            x_offset = -28,
            y_offset = -3
        },
        ["stone"] = {
            amount = 1200,
            size = 21,
            x_offset = -27,
            y_offset = -34
        },
        ["coal"] = {
            amount = 1200,
            size = 21,
            x_offset = -27,
            y_offset = -20
        }
    },

    -- Fluid resource patches like oil
    -- If you are running with mods that add or change resources, you'll want to customize this.
    -- The offset is from the BOTTOM (SOUTH) of the spawn area.
    fluid_resources =
    {
        ["crude-oil"] =
        {
            num_patches = 2,
            amount = 900000,
            -- Starting position offset (relative to bottom/south of spawn area)
            x_offset_start = -3,
            y_offset_start = -10,
            -- Additional position offsets for each new oil patch (relative to previous oil patch)
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
        welcome_msg_title = "YOUR SERVER TITLE HERE",
        welcome_msg = "YOUR WELCOME MSG HERE",
        discord_invite = "YOUR DISCORD INVITE HERE"
    },

    -- General gameplay related settings that I didn't want to expose in the mod settings since these should
    -- basically always be enabled unless you're making serious changes.
    gameplay = {

        -- Default setting for enabling spawning on other surfaces other than the default_surface.
        -- This is a STARTUP setting, so it can't be changed in game!!
        -- This is a STARTUP setting, so it can't be changed in game!!
        default_allow_spawning_on_other_surfaces = true,

        -- The name of the main force.
        -- This is a STARTUP setting, so it can't be changed in game!!
        -- This is a STARTUP setting, so it can't be changed in game!!
        main_force_name = "Main Force",

        -- At least one of these must be enabled! (enable_main_team and enable_separate_teams)
        -- Otherwise we default to enable_main_team = true
        -- Allow all players to join a primary force(team).
        enable_main_team = true,

        -- Allow players to create their own force(team).
        enable_separate_teams = true,

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

        -- The range in which a player can select how close to the center of the map they want to spawn.
        near_spawn_distance = 100,
        far_spawn_distance = 1000,

        -- This allows 2 players to spawn next to each other, each with their own starting area.
        enable_buddy_spawn = true,

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

        -- The default starting surface.
        default_surface = "nauvis",

        -- Enable secondary spawns for players.
        -- This automatically creates a new spawn point when they first move to a separate spawns enabled surface.
        enable_secondary_spawns = true,

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

        -- Enemy evolution factor for the easy force (inside warning area).
        modified_enemy_easy_evo = 0.0,

        -- Enemy evolution factor for the medium force (inside danger area).
        modified_enemy_medium_evo = 0.3,

        -- Require playes to be online for at least X minutes
        -- Else their character is removed and their spawn point is freed up for use
        minimum_online_time = 15,

        -- Respawn cooldown in minutes.
        respawn_cooldown_min = 15,

        -- Enable shared power between bases.
        -- Creates a special power pole for cross surface connections.
        enable_shared_power = false,

        -- Enables a single shared chest using the native linked-chest entity in factorio.
        enable_shared_chest = false,
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
        enable_abandoned_base_cleanup = true,

        -- This is the interval in minutes that the regrowth cleanup will run.
        cleanup_interval = 60,
    },

    -- General spawn settings (size, shape, etc.)
    spawn_general = {

        -- Create a circle of land area for the spawn
        -- If you make this much bigger than a few chunks, good luck!
        -- (It takes a long time to generate new chunks!)
        spawn_radius_tiles = CHUNK_SIZE*2,

        -- Width of the moat around the spawn area.
        -- If you change the spawn area size, you might have to adjust this as well.
        moat_width_tiles = 8,

        -- Width of the tree ring around the spawn area.
        -- If you change the spawn area size, you might have to adjust this as well.
        tree_width_tiles = 5,

        -- Starting resources deposits shape.
        resources_shape = RESOURCES_SHAPE_CHOICE_CIRCLE,

        -- Force the land area circle at the spawn to be fully grass, otherwise it defaults to the existing terrain
        -- or uses landfill.
        force_grass = false,

        -- Spawn a circle/octagon/square of trees around this base outline.
        shape = SPAWN_SHAPE_CHOICE_CIRCLE,
    },

    -- Handle placement of starting resources within the spawn area.
    resource_placement =
    {
        -- Autoplace resources (randomly in circle)
        -- This will ignore the fixed x_offset/y_offset values in solid_resources.
        -- Only works for solid_resources at the moment, not oil patches/water.
        enabled = true,

        -- Distance in tiles from the edge of spawn that resources are placed. Only applicable for circular spawns.
        distance_to_edge = 20,

        -- At what angle (in radians) do resources start.
        -- 0 means starts directly east.
        -- Resources are placed clockwise from there.
        angle_offset = 2.32, -- 2.32 is approx SSW.

        -- At what andle do we place the last resource.
        -- angle_offset and angle_final determine spacing and placement.
        angle_final = 4.46, -- 4.46 is approx NNW.

        -- Vertical offset in tiles for the deposit resource placement. Starting from top-left corner.
        -- Only applicable for square spawns.
        vertical_offset = 20,

        -- Horizontal offset in tiles for the deposit resource placement. Starting from top-left corner.
        -- Only applicable for square spawns.
        horizontal_offset = 20,

        -- Spacing between resource deposits in tiles.
        -- Only applicable for square spawns.
        linear_spacing = 6,

        -- Size multiplier for the starting resource deposits.
        size_multiplier = 1.0,

        -- Amount multiplier for the starting resource deposits.
        amount_multiplier = 1.0,

    },

    -- Spawn configuration specific to each surface, including starting & respawn items.
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

    -- Surfaces blacklist (Ignore these surfaces completely for spawning and regrowth!)
    ---@type table<integer, string>
    surfaces_blacklist = {
        HOLDING_PEN_SURFACE_NAME,
    },

    -- Surfaces blacklist that match THE START of these strings
    -- (Ignore these surfaces completely for spawning and regrowth!)
    ---@type table<integer, string>
    surfaces_blacklist_match = {
        -- Factorissimo Mod Surfaces
        "factory-power",
        "factory-floor",
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
---@field spawn_general OarcConfigSpawnGeneral General spawn settings (size, shape, etc.)
---@field resource_placement OarcConfigSpawnResourcePlacementSettings Resource placement settings
---@field surfaces_config table<string, OarcConfigSurface> Spawn configuration (starting items and spawn area config) for each surface.
---@field surfaces_blacklist table<string> List of surfaces to ignore automatically.
---@field surfaces_blacklist_match table<string> List of surfaces to ignore automatically if the start of the string matches the surface name.

---@class OarcConfigServerInfo
---@field welcome_msg_title string  Title of welcome GUI window.
---@field welcome_msg string Main welcome message. (Should provide mod info.)
---@field discord_invite string Discord invite for easy copy paste.

---@class OarcConfigGameplaySettings
---@field default_allow_spawning_on_other_surfaces boolean Default setting for enabling spawning on other surfaces other than the default_surface. This is a STARTUP setting, so it can't be changed in game.
---@field main_force_name string The name of the main force. This is a STARTUP setting, so it can't be changed in game.
---@field enable_main_team boolean Allows all players to join a primary force(team).
---@field enable_separate_teams boolean Allows players to create their own force(team).
---@field allow_moats_around_spawns boolean Allow players to choose to spawn with a moat
---@field enable_moat_bridging boolean If there is a moat, this makes a small path to land to avoid "turtling", but if the spawn is in the middle of water, it won't do anything.
---@field minimum_distance_to_existing_chunks number The radius, in chunks, that a spawn area is from any other generated chunks. It ensures the spawn area isn't too near generated/explored/existing area.
---@field near_spawn_distance number The closest a player can spawn to the origin. (Not exact, but close).
---@field far_spawn_distance number The furthest a player can spawn from the origin. (Not exact, but close).
---@field enable_buddy_spawn boolean Allow 2 players to spawn next to each other, each with their own starting area.
---@field enable_offline_protection boolean Inhibits enemy attacks on bases where all players are offline. Not 100% guaranteed!
---@field enable_shared_team_vision boolean Enable shared vision between teams (all teams are COOP regardless)
---@field enable_shared_team_chat boolean Share local team chat with all teams
---@field enable_shared_spawns boolean Enable if players can allow others to join their spawn.
---@field number_of_players_per_shared_spawn number Number of players allowed to join a shared spawn.
---@field enable_friendly_fire boolean Set to true if you want to shoot your own chests and stuff.
---@field default_surface string The starting surface of the main force.
---@field enable_secondary_spawns boolean Enable secondary spawns for players. This automatically creates a new spawn point when they first move to a separate spawns enabled surface.
---@field scale_resources_around_spawns boolean Scales resources so that even if you spawn "far away" from the center of the map, resources near to your spawn point scale so you aren't surrounded by 100M patches or something. This is useful depending on what map gen settings you pick.
---@field modified_enemy_spawning boolean Adjust enemy spawning based on distance to spawns. All it does it make things more balanced based on your distance and makes the game a little easier. No behemoth worms everywhere just because you spawned far away.
---@field modified_enemy_easy_evo number Enemy evolution factor for the easy force (inside warning area).
---@field modified_enemy_medium_evo number Enemy evolution factor for the medium force (inside danger area).
---@field minimum_online_time number Require playes to be online for at least X minutes Else their character is removed and their spawn point is freed up for use
---@field respawn_cooldown_min number Respawn cooldown in minutes.
---@field enable_shared_power boolean Enable shared power between bases. Creates a special power pole for cross surface connections.
---@field enable_shared_chest boolean Enables a single shared chest using the native linked-chest entity in factorio.

---@class OarcConfigRegrowth
---@field enable_regrowth boolean Cleans up unused chunks periodically. Helps keep map size down.
---@field enable_world_eater boolean Checks inactive chunks to see if they are empty of entities and deletes them periodically.
---@field enable_abandoned_base_cleanup boolean Removes player bases when they leave shortly after joining.
---@field cleanup_interval number This is the interval in minutes that the regrowth cleanup will run.

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
---@field safe_area OarcConfigSpawnSafeArea How safe is the spawn area?
---@field water OarcConfigSpawnWater Water strip settings
---@field shared_power_pole_position OarcOffsetPosition Location of shared power pole relative to spawn center (if enabled)
---@field shared_chest_position OarcOffsetPosition Location of shared chest relative to spawn center (if enabled)
---@field solid_resources table<string, OarcConfigSolidResource> Spawn area config for solid resource tiles
---@field fluid_resources table<string, OarcConfigFluidResource> Spawn area config for fluid resource patches (like oil)

---@class OarcConfigSpawnGeneral
---@field spawn_radius_tiles number THIS IS WHAT SETS THE SPAWN CIRCLE SIZE! Create a circle of land area for the spawn If you make this much bigger than a few chunks, good luck.
---@field moat_width_tiles number Width of the moat around the spawn area. If you change the spawn area size, you might have to adjust this as well.
---@field tree_width_tiles number Width of the tree ring around the spawn area. If you change the spawn area size, you might have to adjust this as well.
---@field resources_shape SpawnResourcesShapeChoice The starting resources deposits shape.
---@field force_grass boolean Force the land area circle at the spawn to be fully grass, otherwise it defaults to the existing terrain.
---@field shape SpawnShapeChoice Spawn a circle/octagon/square of trees around this base outline.

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

---@alias OarcOffsetPosition { x_offset: number, y_offset: number } An offset position intended to be relative to the spawn center.

---@class OarcConfigSpawnResourcePlacementSettings
---@field enabled boolean Autoplace resources. This will ignore the fixed x_offset/y_offset values in solid_resources. Only works for solid_resources at the moment, not oil patches/water.
---@field distance_to_edge number Distance in tiles from the edge of spawn that resources are placed. Only applicable for circular spawns.
---@field angle_offset number At what angle (in radians) do resources start. 0 means starts directly east. Resources are placed clockwise from there. Only applicable for circular spawns.
---@field angle_final number At what andle do we place the last resource. angle_offset and angle_final determine spacing and placement. Only applicable for circular spawns.
---@field vertical_offset number Vertical offset in tiles for the deposit resource placement. Only applicable for square spawns.
---@field horizontal_offset number Horizontal offset in tiles for the deposit resource placement. Only applicable for square spawns.
---@field linear_spacing number Spacing between resource deposits in tiles. Only applicable for square spawns.
---@field size_multiplier number Size multiplier for the starting resource deposits.
---@field amount_multiplier number Amount multiplier for the starting resource deposits.

---@alias OarcConfigSolidResource { amount: integer, size: integer, x_offset: integer, y_offset: integer } Amount and placement of solid resource tiles in the spawn area.
---@alias OarcConfigFluidResource { num_patches: integer, amount: integer, x_offset_start: integer, y_offset_start: integer, x_offset_next: integer, y_offset_next: integer } Amount and placement of fluid resource patches in the spawn area.