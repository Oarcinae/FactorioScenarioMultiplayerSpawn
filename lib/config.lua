--[[
  __  __  ___  ___   __      ___   ___ _  _ ___ _  _  ___
 |  \/  |/ _ \|   \  \ \    / /_\ | _ \ \| |_ _| \| |/ __|
 | |\/| | (_) | |) |  \ \/\/ / _ \|   / .` || || .` | (_ |
 |_|  |_|\___/|___/    \_/\_/_/ \_\_|_\_|\_|___|_|\_|\___|

 DO NOT EDIT THIS FILE!
 DO NOT EDIT THIS FILE!
 DO NOT EDIT THIS FILE!

 If you want to customize settings at init, look at the TEMPLATE_SCENARIO folder!

 More settings are available here than are provided in the mod settings menu.
 Additionally, many settings are exposed in the game itself and can be changed in game.

]]

require("lib/planet_configs/nauvis")
require("lib/planet_configs/fulgora")
require("lib/planet_configs/vulcanus")
require("lib/planet_configs/gleba")
require("lib/planet_configs/aquilo")

---@alias SpawnShapeChoice "circle" | "octagon" | "square"
SPAWN_SHAPE_CHOICE_CIRCLE = "circle"
SPAWN_SHAPE_CHOICE_OCTAGON = "octagon"
SPAWN_SHAPE_CHOICE_SQUARE = "square"

---@alias SpawnResourcesShapeChoice "circle" | "square"
RESOURCES_SHAPE_CHOICE_CIRCLE = "circle"
RESOURCES_SHAPE_CHOICE_SQUARE = "square"

MAX_CRASHED_SHIP_RESOURCES_ITEMS = 5
MAX_CRASHED_SHIP_WRECKAGE_ITEMS = 1

---This only matters if you have the coin shop enabled.
---@type OarcStoreList
OARC_SHOP_ITEMS =
{
    ["Guns"] = {
        ["pistol"] = {cost = 1, count = 1, play_time_locked=false},
        ["shotgun"] = {cost = 5, count = 1, play_time_locked=false},
        ["submachine-gun"] = {cost = 10, count = 1, play_time_locked=false},
        ["flamethrower"] = {cost = 50, count = 1, play_time_locked=true},
        ["rocket-launcher"] = {cost = 50, count = 1, play_time_locked=true},
        -- ["railgun"] = {cost = 250, count = 1, play_time_locked=true}, -- Was removed awhile ago, but might return with 2.0?
    },

    ["Turrets"] = {
        ["gun-turret"] = {cost = 25, count = 1, play_time_locked=false},
        ["flamethrower-turret"] = {cost = 50, count = 1, play_time_locked=false},
        ["laser-turret"] = {cost = 75, count = 1, play_time_locked=false},
        ["artillery-turret"] = {cost = 500, count = 1, play_time_locked=true},
    },

    ["Ammo"] = {
        ["firearm-magazine"] = {cost = 10, count = 10, play_time_locked=false},
        ["piercing-rounds-magazine"] = {cost = 30, count = 10, play_time_locked=false},
        ["shotgun-shell"] = {cost = 10, count = 10, play_time_locked=false},
        ["flamethrower-ammo"] = {cost = 50, count = 10, play_time_locked=true},
        ["rocket"] = {cost = 100, count = 10, play_time_locked=true},
        -- ["railgun-dart"] = {cost = 250, count = 10, play_time_locked=true}, -- Was removed awhile ago, but might return with 2.0?
        ["atomic-bomb"] = {cost = 1000, count = 1, play_time_locked=true},
        ["artillery-shell"] = {cost = 50, count = 1, play_time_locked=true},

    },

    ["Special"] = {
        ["repair-pack"] = {cost = 1, count = 1, play_time_locked=false},
        ["raw-fish"] = {cost = 1, count = 1, play_time_locked=false},
        ["grenade"] = {cost = 20, count = 10, play_time_locked=true},
        ["cliff-explosives"] = {cost = 20, count = 10, play_time_locked=true},
        ["artillery-targeting-remote"] = {cost = 500, count = 1, play_time_locked=true},
    },

    ["Capsules/Mines"] = {
        ["land-mine"] = {cost = 20, count = 10, play_time_locked=false},
        ["defender-capsule"] = {cost = 20, count = 10, play_time_locked=false},
        ["distractor-capsule"] = {cost = 40, count = 10, play_time_locked=false},
        ["destroyer-capsule"] = {cost = 60, count = 10, play_time_locked=false},
        ["poison-capsule"] = {cost = 50, count = 10, play_time_locked=false},
        ["slowdown-capsule"] = {cost = 25, count = 10, play_time_locked=false},
    },

    ["Armor"] = {
        ["light-armor"] = {cost = 10, count = 1, play_time_locked=false},
        ["heavy-armor"] = {cost = 20, count = 1, play_time_locked=false},
        ["modular-armor"] = {cost = 200, count = 1, play_time_locked=false},
        ["power-armor"] = {cost = 1000, count = 1, play_time_locked=false},
        ["power-armor-mk2"] = {cost = 5000, count = 1, play_time_locked=false},
    },

    ["Power Equipment"] = {
        ["fusion-reactor-equipment"] = {cost = 1000, count = 1, play_time_locked=false},
        ["battery-equipment"] = {cost = 100, count = 1, play_time_locked=false},
        ["battery-mk2-equipment"] = {cost = 1000, count = 1, play_time_locked=false},
        ["solar-panel-equipment"] = {cost = 10, count = 1, play_time_locked=false},
    },

    ["Bot Equipment"] = {
        ["personal-roboport-equipment"] = {cost = 100, count = 1, play_time_locked=false},
        ["personal-roboport-mk2-equipment"] = {cost = 500, count = 1, play_time_locked=false},
        ["construction-robot"] = {cost = 100, count = 10, play_time_locked=false},
        ["roboport"] = {cost = 1000, count = 1, play_time_locked=false},
        ["storage-chest"] = {cost = 100, count = 1, play_time_locked=false},
    },

    ["Misc Equipment"] = {
        ["belt-immunity-equipment"] = {cost = 10, count = 1, play_time_locked=false},
        ["exoskeleton-equipment"] = {cost = 100, count = 1, play_time_locked=false},
        ["night-vision-equipment"] = {cost = 50, count = 1, play_time_locked=false},

        ["personal-laser-defense-equipment"] = {cost = 100, count = 1, play_time_locked=false},
        ["energy-shield-equipment"] = {cost = 50, count = 1, play_time_locked=false},
        ["energy-shield-mk2-equipment"] = {cost = 500, count = 1, play_time_locked=false},
    },

    ["Spidertron"] = {
        ["spidertron"] = {cost = 5000, count = 1, play_time_locked=false},
        ["spidertron-remote"] = {cost = 500, count = 1, play_time_locked=false},
    },
}

COIN_MULTIPLIER = 2

-- TODO: Add default values for space age new enemies
---@type table<string, number>
COIN_GENERATION_CHANCES = {
    ["small-biter"] = 0.01,
    ["medium-biter"] = 0.02,
    ["big-biter"] = 0.05,
    ["behemoth-biter"] = 1,

    ["small-spitter"] = 0.01,
    ["medium-spitter"] = 0.02,
    ["big-spitter"] = 0.05,
    ["behemoth-spitter"] = 1,

    ["small-worm-turret"] = 5,
    ["medium-worm-turret"] = 10,
    ["big-worm-turret"] = 15,
    ["behemoth-worm-turret"] = 25,

    ["biter-spawner"] = 20,
    ["spitter-spawner"] = 20,
}

---@type OarcConfig
OCFG = {

    -- Server Info - This stuff is shown in the welcome GUI and Info panel.
    ---@type OarcConfigServerInfo
    server_info = {
        welcome_msg_title = "Insert Server Title Here!",
        welcome_msg = "Insert Server Welcome Message Here!",
        discord_invite = "Insert Discord Invite Here!"
    },

    -- General gameplay related settings that I didn't want to expose in the mod settings since these should
    -- basically always be enabled unless you're making serious changes.
    ---@type OarcConfigGameplaySettings
    gameplay = {

        -- Default setting for if secondary spawns are enabled on other surfaces other than the default_surface.
        -- This is a STARTUP setting, so it can't be changed in game!!
        -- This is a STARTUP setting, so it can't be changed in game!!
        default_enable_secondary_spawns_on_other_surfaces = false,

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
        enable_moat_bridging = false,

        -- This is the radius, in chunks, that a spawn area is from any other generated
        -- chunks. It ensures the spawn area isn't too near generated/explored/existing
        -- area. The larger you make this, the further away players will spawn from
        -- generated map area (even if it is not visible on the map!).
        minimum_distance_to_existing_chunks = 20,

        -- The range in which a player can select how close to the center of the map they want to spawn.
        near_spawn_distance = 100,
        far_spawn_distance = 500,

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

        -- Friendly teams can modify each other's buildings and view each other's map area.
        enable_friendly_teams = true,

        -- This means team's turrets won't shoot other team's stuff.
        enable_cease_fire = true,

        -- Enable if players can allow others to join their base.
        -- And specify how many including the host are allowed.
        enable_shared_spawns = true,
        number_of_players_per_shared_spawn = 3,

        -- I like keeping this off... set to true if you want to shoot your own chests and stuff.
        enable_friendly_fire = false,

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

        -- Scale damage to spawners based on distance to spawn.
        scale_spawner_damage = false,

        -- -- Enemy evolution factor for the easy force (inside warning area).
        -- modified_enemy_easy_evo = 0.0,

        -- -- Enemy evolution factor for the medium force (inside danger area).
        -- modified_enemy_medium_evo = 0.3,

        -- Require playes to be online for at least X minutes
        -- Else their character is removed and their spawn point is freed up for use
        minimum_online_time = 15,

        -- Respawn cooldown in minutes.
        respawn_cooldown_min = 5,

        -- Enable shared power between bases.
        -- Creates a special power pole for cross surface connections.
        enable_shared_power = false,

        -- Enables a single shared chest using the native linked-chest entity in factorio.
        enable_shared_chest = false,

        -- Enable the coin shop GUI for players to buy items with coins.
        enable_coin_shop = false,

        -- Allow players to reset themselves in the spawn controls
        enable_player_self_reset = true,
    },

    -- This is a separate feature that is part of the mod that helps keep the map size down. Not required but useful.
    ---@type OarcConfigRegrowth
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
    ---@type OarcConfigSpawnGeneral
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

        -- Force the land area circle at the spawn to be a single tile (default grass on Nauvis), otherwise it defaults 
        -- to the existing terrain and uses landfill to fill gaps.
        force_tiles = true,

        -- Spawn a circle/octagon/square of trees around this base outline.
        shape = SPAWN_SHAPE_CHOICE_CIRCLE,

        -- Remove decorations for a cleaner look.
        remove_decoratives = false,
    },

    -- Handle placement of starting resources within the spawn area.
    ---@type OarcConfigSpawnResourcePlacementSettings
    resource_placement =
    {
        -- Autoplace resources (randomly in circle)
        -- This will ignore the fixed x_offset/y_offset values in solid_resources.
        -- Only works for solid_resources at the moment, not oil patches/water.
        enabled = true,

        -- Distance in tiles from the edge of spawn that resources are placed. Only applicable for circular spawns.
        distance_to_edge = 20,

        -- At what angle (in degrees) do resources start.
        -- 0 means starts directly east.
        -- Resources are placed clockwise from there.
        angle_offset = 120, -- Approx SSW.

        -- At what andle do we place the last resource.
        -- angle_offset and angle_final determine spacing and placement.
        angle_final = 240, -- Approx NNW.

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

        -- Randomize the order of resource placement.
        random_order = true,
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
            starting_items = VULCANUS_STARTER_ITEMS,
            spawn_config = VULCANUS_SPAWN_CONFIG
        },
        ["fulgora"] = {
            starting_items = FULGORA_STARTER_ITEMS,
            spawn_config = FULGORA_SPAWN_CONFIG
        },
        ["gleba"] = {
            starting_items = GLEBA_STARTER_ITEMS,
            spawn_config = GLEBA_SPAWN_CONFIG
        },
        ["aquilo"] = {
            starting_items = AQUILO_STARTER_ITEMS,
            spawn_config = AQUILO_SPAWN_CONFIG
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
        -- Space Age
        "platform-",
        -- Factorissimo Mod Surfaces
        "factory-power",
        "factory-floor",
        -- Factorissimo 3 Surfaces (hardcoded for now...)
        "factory-",
        "nauvis-factory-",
        "fulgora-factory-",
        "gleba-factory-",
        "vulcanus-factory-",
        "aquilo-factory-",
        -- Blueprint Sandboxes Surfaces
        "bpsb-"
    },

    -- List of items available in the coin shop (if enabled).
    ---@type OarcStoreList
    shop_items = OARC_SHOP_ITEMS,

    -- Coin generation settings for when enemies die.
    ---@type OarcCoinGenerationSettings
    coin_generation = {
        enabled = false,
        coin_multiplier = COIN_MULTIPLIER,
        coin_generation_table = COIN_GENERATION_CHANCES,
        auto_decon_coins = true,
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
---@field shop_items OarcStoreList List of items available in the coin shop (if enabled).
---@field coin_generation OarcCoinGenerationSettings Coin generation settings for when enemies die.

---@class OarcConfigServerInfo
---@field welcome_msg_title string  Title of welcome GUI window.
---@field welcome_msg string Main welcome message. (Should provide mod info.)
---@field discord_invite string Discord invite for easy copy paste.

---@class OarcConfigGameplaySettings
---@field default_enable_secondary_spawns_on_other_surfaces boolean Default setting for if secondary spawns are enabled on other surfaces other than the default_surface. This is a STARTUP setting, so it can't be changed in game.
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
---@field enable_shared_team_vision boolean Enable shared vision between teams
---@field enable_shared_team_chat boolean Share local team chat with all teams
---@field enable_friendly_teams boolean Friendly teams can modify each other's buildings.
---@field enable_cease_fire boolean This means team's turrets won't shoot other team's stuff.
---@field enable_shared_spawns boolean Enable if players can allow others to join their spawn.
---@field number_of_players_per_shared_spawn number Number of players allowed to join a shared spawn.
---@field enable_friendly_fire boolean Set to true if you want to shoot your own chests and stuff.
---@field default_surface string The starting surface of the main force.
---@field scale_resources_around_spawns boolean Scales resources so that even if you spawn "far away" from the center of the map, resources near to your spawn point scale so you aren't surrounded by 100M patches or something. This is useful depending on what map gen settings you pick.
---@field modified_enemy_spawning boolean Adjust enemy spawning based on distance to spawns. All it does it make things more balanced based on your distance and makes the game a little easier. No behemoth worms everywhere just because you spawned far away.
---@field scale_spawner_damage boolean Scale damage to spawners based on distance to spawn.
----@field modified_enemy_easy_evo number Enemy evolution factor for the easy force (inside warning area).
----@field modified_enemy_medium_evo number Enemy evolution factor for the medium force (inside danger area).
---@field minimum_online_time number Require playes to be online for at least X minutes Else their character is removed and their spawn point is freed up for use
---@field respawn_cooldown_min number Respawn cooldown in minutes.
---@field enable_shared_power boolean Enable shared power between bases. Creates a special power pole for cross surface connections.
---@field enable_shared_chest boolean Enables a single shared chest using the native linked-chest entity in factorio.
---@field enable_coin_shop boolean Enable the coin shop GUI for players to buy items with coins.
---@field enable_player_self_reset boolean Allow players to reset themselves in the spawn controls

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
---@field fill_tile string Fill tile for the spawn area (grass on Nauvis)
---@field liquid_tile string Moat and liquid strip for the spawn area (water on Nauvis)
---@field tree_entity string Tree ring entity for the spawn area (tree-02 on Nauvis)
---@field random_entities table Random entities to place around the spawn area (like rocks on nauvis, ruins on fulgora)
---@field radius_modifier number Radius modifier for the spawn area (1.0 is default)
---@field safe_area OarcConfigSpawnSafeArea How safe is the spawn area?
---@field water OarcConfigSpawnWater Water strip settings
---@field shared_power_pole_position OarcOffsetPosition Location of shared power pole relative to spawn center (if enabled)
---@field shared_chest_position OarcOffsetPosition Location of shared chest relative to spawn center (if enabled)
---@field solid_resources table<string, OarcConfigSolidResource> Spawn area config for solid resource tiles
---@field fluid_resources table<string, OarcConfigFluidResource> Spawn area config for fluid resource patches (like oil)
---@field gleba_resources table<string, OarcConfigGlebaResource> Spawn area config for gleba-style resources (like plants and stromatolites)

---@class OarcConfigSpawnGeneral
---@field spawn_radius_tiles number THIS IS WHAT SETS THE SPAWN CIRCLE SIZE! Create a circle of land area for the spawn If you make this much bigger than a few chunks, good luck.
---@field moat_width_tiles number Width of the moat around the spawn area. If you change the spawn area size, you might have to adjust this as well.
---@field tree_width_tiles number Width of the tree ring around the spawn area. If you change the spawn area size, you might have to adjust this as well.
---@field resources_shape SpawnResourcesShapeChoice The starting resources deposits shape.
---@field force_tiles boolean Force the land area circle at the spawn to be a single tile (default grass on Nauvis), otherwise it defaults to the existing terrain and uses landfill to fill gaps.
---@field shape SpawnShapeChoice Spawn a circle/octagon/square of trees around this base outline.
---@field remove_decoratives boolean Remove decorations for a cleaner look.

---@class OarcConfigSpawnSafeArea
---@field safe_radius number Safe area has no aliens This is the radius in chunks of safe area.
---@field warn_radius number Warning area has significantly reduced aliens This is the radius in chunks of warning area.
---@field warn_reduction number 1 : X (spawners alive : spawners destroyed) in this area
---@field danger_radius number Danger area has slightly reduce aliens This is the radius in chunks of danger area.
---@field danger_reduction number 1 : X (spawners alive : spawners destroyed) in this area

---@class OarcConfigSpawnWater
---@field x_offset number Location of water strip within the spawn area (horizontal)
---@field y_offset number Location of water strip within the spawn area (vertical)
---@field length number Length of water strip within the spawn area

---@alias OarcOffsetPosition { x_offset: number, y_offset: number } An offset position intended to be relative to the spawn center.

---@class OarcConfigSpawnResourcePlacementSettings
---@field enabled boolean Autoplace resources. This will ignore the fixed x_offset/y_offset values in solid_resources. Only works for solid_resources at the moment, not oil patches/water.
---@field distance_to_edge number Distance in tiles from the edge of spawn that resources are placed. Only applicable for circular spawns.
---@field angle_offset integer At what angle (in degrees) do resources start. 0 means starts directly east. Resources are placed clockwise from there. Only applicable for circular spawns.
---@field angle_final integer At what andle do we place the last resource. angle_offset and angle_final determine spacing and placement. Only applicable for circular spawns.
---@field vertical_offset number Vertical offset in tiles for the deposit resource placement. Only applicable for square spawns.
---@field horizontal_offset number Horizontal offset in tiles for the deposit resource placement. Only applicable for square spawns.
---@field linear_spacing number Spacing between resource deposits in tiles. Only applicable for square spawns.
---@field size_multiplier number Size multiplier for the starting resource deposits.
---@field amount_multiplier number Amount multiplier for the starting resource deposits.
---@field random_order boolean Randomize the order of resource placement.

---@class OarcConfigSolidResource
---@field amount integer
---@field size integer
---@field x_offset integer
---@field y_offset integer

---@class OarcConfigFluidResource
---@field num_patches integer
---@field amount integer
---@field spacing integer
---@field x_offset_start integer
---@field y_offset_start integer
---@field x_offset_next integer
---@field y_offset_next integer

---@class OarcConfigGlebaResource
---@field tile string The tile to place
---@field entities string[] The entities that can be placed on the tile
---@field size integer The size of the resource patch
---@field density number How often we attempt to place an entity per tile (so if the entity is bigger, then even a density < 1 might still completely fill the area)

---@class OarcStoreItem
---@field cost integer
---@field count integer
---@field play_time_locked boolean

---@alias OarcStoreCategory table<string, OarcStoreItem>
---@alias OarcStoreList table<string, OarcStoreCategory>


---@class OarcCoinGenerationSettings
---@field enabled boolean Enable coin generation when enemies die.
---@field coin_multiplier number If the drop count is x, then between x and x*coin_multiplier coins will be dropped.
---@field coin_generation_table table<string, number> Table of enemy unity types and their coin drop rates.
---@field auto_decon_coins boolean Automatically deconstruct coins when they are dropped.