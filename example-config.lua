-- example-config.lua (Rename this file to config.lua to use it)
-- May 26 2020 (updated on)
-- Configuration Options
--
-- You should be safe to leave most of the settings here as defaults if you want.
-- The only thing you definitely want to change are the welcome messages.

--------------------------------------------------------------------------------
-- Messages
-- You will want to change some of these to be your own.
--------------------------------------------------------------------------------

-- This stuff is shown in the welcome GUI and Info panel. Make sure it's valid.
WELCOME_MSG_TITLE = "[INSERT SERVER OWNER MSG HERE test title!]"
WELCOME_MSG = "[INSERT SERVER OWNER MSG HERE test msg!]" -- Printed to player on join as well.
SERVER_MSG = "Rules: Be polite. Ask before changing other players's stuff. Have fun!\n"..
"This server is running a custom scenario that allows individual starting areas on the map."

SCENARIO_INFO_MSG = "Latest updates in this scenario version:\n"..
"Item & energy sharing system! No attacks on your base while you are offline!\n"..
"This scenario gives you and/or your friends your own starting area.\n"..
"You can be on the main team or your own. All teams are friendly.\n"..
"If you leave in the first 15 minutes, your base and character will be deleted!"

CONTACT_MSG = "Contact: SteamID:Oarc | oarcinae@gmail.com | Discord:Oarc#8695"
DISCORD_INV = "discord.gg/trnpcen"

------------------------------------------------------------------------------------------------------------------------
-- Module Enables
-- Each of the following things enable special features. These can't be changed once the game starts.
------------------------------------------------------------------------------------------------------------------------

-- This allows 2 players to spawn next to each other in the wilderness, each with their own starting point. It adds more
-- GUI selection options.
ENABLE_BUDDY_SPAWN = true

-- Frontier style rocket silo mode. This means you can't build silos, but some spawn out in the wild for you to use.
-- if ENABLE_MAGIC_FACTORIES=false, you will find a few special areas to launch rockets from.
-- If ENABLE_MAGIC_FACTORIES=true, you must buy a silo at one of the special chunks.
FRONTIER_ROCKET_SILO_MODE = true

-- Enable Undecorator. Removes decorative items to reduce save file size.
ENABLE_UNDECORATOR = true

-- Enable Tags (Players can add a name-tag to explain what type of role they are doing if they want.)
ENABLE_TAGS = true

-- Enable Long Reach
ENABLE_LONGREACH = true

-- Enable Autofill (My autofill is very simplistic, if you are using a similar mod disable this!)
ENABLE_AUTOFILL = true

-- Enable auto decon of miners (My miner decon is very simplistic, if you are using a similar mod disable this!)
ENABLE_MINER_AUTODECON = true

-- Enable Playerlist
ENABLE_PLAYER_LIST = true
PLAYER_LIST_OFFLINE_PLAYERS = true -- List offline players as well.

-- Enable shared vision between teams (all teams are COOP regardless)
ENABLE_SHARED_TEAM_VISION = true

-- Cleans up unused chunks periodically. Helps keep map size down.
ENABLE_REGROWTH = true
-- This removes player bases when they leave shortly after joining. Only works if you have regrowth enabled!
ENABLE_ABANDONED_BASE_REMOVAL = true

-- Enable the research queue by default for all forces.
ENABLE_RESEARCH_QUEUE = true

-- This enables coin drops from enemies and a shop (GUI) to buy stuff from.
ENABLE_COIN_SHOP = false

-- Enable item & energy sharing system. 
ENABLE_ITEM_AND_ENERGY_SHARING = false -- REQUIRES ENABLE_COIN_SHOP=true!

-- Enable magic chunks around the map that let you buy powerful factories that smelt/assemble/process very very quickly.
ENABLE_MAGIC_FACTORIES = false -- REQUIRES ENABLE_COIN_SHOP=true!

-- This inhibits enemy attacks on bases where all players are offline.
-- Not 100% guaranteed.
ENABLE_OFFLINE_PROTECTION = true

-- This allows you to set the tech price multiplier for the game, but 
-- have it only affect the main force. We just pad all non-main forces lab prod bonus.
-- This has no effect unless the tech multiplier is more than 1!
ENABLE_FORCE_LAB_PROD_BONUS = true

-- Lock various recipes and technologies behind a rocket launch.
-- Each team/force must launch their own rocket to unlock this!
LOCK_GOODIES_UNTIL_ROCKET_LAUNCH = true
LOCKED_TECHNOLOGIES = {
    {t="atomic-bomb"},{t="power-armor-mk2"},{t="artillery"},{t="spidertron"}
}
LOCKED_RECIPES = {
    {r="productivity-module-3"},{r="speed-module-3"}
}

-- Give cheaty items on start.
ENABLE_POWER_ARMOR_QUICK_START = false
ENABLE_MODULAR_ARMOR_QUICK_START = false

------------------------------------------------------------------------------------------------------------------------
-- MAP CONFIGURATION OPTIONS
-- In past versions I had a way to config map settings here to be used for cmd
-- line launching, but now you should just be using --map-gen-settings and
-- --map-settings option since it works with --start-server-load-scenario
-- Read the README.md file for instructions.
------------------------------------------------------------------------------------------------------------------------

-- This scales resources so that even if you spawn "far away" from the center
-- of the map, resources near to your spawn point scale so you aren't
-- surrounded by 100M patches or something. This is useful depending on what
-- map gen settings you pick.
SCALE_RESOURCES_AROUND_SPAWNS = true

------------------------------------------------------------------------------------------------------------------------
-- Alien Options
------------------------------------------------------------------------------------------------------------------------

-- Adjust enemy spawning based on distance to spawns. All it does it make things
-- more balanced based on your distance and makes the game a little easier.
-- No behemoth worms everywhere just because you spawned far away.
-- If you're trying out the vanilla spawning, you might want to disable this.
OARC_MODIFIED_ENEMY_SPAWNING = true

------------------------------------------------------------------------------------------------------------------------
-- Starting Items
------------------------------------------------------------------------------------------------------------------------
-- Items provided to the player the first time they join
PLAYER_SPAWN_START_ITEMS = {
    ["pistol"]=1,
    ["firearm-magazine"]=200,
    ["iron-plate"]=100,
    ["burner-mining-drill"] = 4,
    ["stone-furnace"] = 4,
    ["coal"] = 50,
    ["stone"] = 50,

    ["coin"] = 2500, -- Don't give coins unless you have shared chests enabled.
}

-- Items provided after EVERY respawn (disabled by default)
PLAYER_RESPAWN_START_ITEMS = {
    -- ["pistol"]=1,
    -- ["firearm-magazine"]=100,
}

------------------------------------------------------------------------------------------------------------------------
-- Distance Options
------------------------------------------------------------------------------------------------------------------------

-- This is the radius, in chunks, that a spawn area is from any other generated
-- chunks. It ensures the spawn area isn't too near generated/explored/existing
-- area. The larger you make this, the further away players will spawn from
-- generated map area (even if it is not visible on the map!).
CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS = 10

-- Near Distance in chunks
-- When a player selects "near" spawn, they will be in or as close to this range as possible.
NEAR_MIN_DIST = 50
NEAR_MAX_DIST = 100

-- Far Distance in chunks
-- When a player selects "far" spawn, they will be at least this distance away.
FAR_MIN_DIST = 200
FAR_MAX_DIST = 300



------------------------------------------------------------------------------------------------------------------------
-- Resource & Spawn Circle Options
------------------------------------------------------------------------------------------------------------------------

-- This is where you can modify what resources spawn, how much, where, etc.
-- Once you have a config you like, it's a good idea to save it for later use
-- so you don't lost it if you update the scenario.
OARC_CFG = {

    -- Misc spawn related config.
    gen_settings = {

        -- THIS IS WHAT SETS THE SPAWN CIRCLE SIZE!
        -- Create a circle of land area for the spawn
        -- If you make this much bigger than a few chunks, good luck.
        land_area_tiles = CHUNK_SIZE*2,

        -- Allow players to choose to spawn with a moat
        moat_choice_enabled = true,
        -- If there is a moat, this attempts to connect to land to avoid "turtling"
        moat_bridging = true, 

        -- If you change the spawn area size, you might have to adjust this as well
        moat_size_modifier = 1,

        -- Start resource shape. true = circle, false = square.
        resources_circle_shape = true,

        -- Force the land area circle at the spawn to be fully grass
        force_grass = true,

        -- Spawn a circle/octagon of trees around the base outline.
        tree_circle = true,
        tree_octagon = false,

        -- Add a crashed ship like a vanilla game (create_crash_site)
        -- Resources go in the ship itself. (5 slots)
        -- Wreakage is distributed in small pieces. (I recommend only 1 item type.)
        crashed_ship = true,
        crashed_ship_resources = {
                                    ["electronic-circuit"] = 200,
                                    ["iron-gear-wheel"] = 100,
                                    ["copper-cable"] = 200,
                                    -- ["spidertron"] = 1,
                                    ["steel-plate"] = 100
                                 },
        crashed_ship_wreakage = {
                                    ["iron-plate"] = 100
                                },
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

    -- Location of water strip (horizontal)
    water = {
        x_offset = -4,
        y_offset = -48,
        length = 8
    },

    -- Handle placement of starting resources
    resource_rand_pos_settings =
    {
        -- Autoplace resources (randomly in circle)
        -- This will ignore the fixed x_offset/y_offset values in resource_tiles.
        -- Only works for resource_tiles at the moment, not oil patches/water.
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

    -- Resource tiles
    -- If you are running with mods like bobs/angels, you'll want to customize this.
    resource_tiles =
    {
        ["iron-ore"] =
        {
            amount = 1500,
            size = 18,
            x_offset = -29,
            y_offset = 16
        },
        ["copper-ore"] =
        {
            amount = 1200,
            size = 18,
            x_offset = -28,
            y_offset = -3
        },
        ["stone"] =
        {
            amount = 1200,
            size = 16,
            x_offset = -27,
            y_offset = -34
        },
        ["coal"] =
        {
            amount = 1200,
            size = 16,
            x_offset = -27,
            y_offset = -20
        }--,
        -- ["uranium-ore"] =
        -- {
        --     amount = 0,
        --     size = 0,
        --     x_offset = 17,
        --     y_offset = -34
        -- }

        -- ####### Bobs + Angels #######
        -- DISABLE STARTING OIL PATCHES!
        -- Coal                = coal
        -- Saphirite           = angels-ore1
        -- Stiratite           = angels-ore3
        -- Rubyte              = angels-ore5
        -- Bobmonium           = angels-ore6

        -- ########## Bobs Ore ##########
        -- Iron                = iron-ore
        -- Copper              = copper-ore
        -- Coal                = coal
        -- Stone               = stone
        -- Tin                 = tin-ore
        -- Lead (Galena)       = lead-ore

        -- See https://github.com/Oarcinae/FactorioScenarioMultiplayerSpawn/issues/11#issuecomment-479724909
        -- for full examples.
    },

    -- Special resource patches like oil
    resource_patches =
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

---------------------------------------
-- Other Forces/Teams Options
---------------------------------------

-- Separate teams
-- This allows you to join your own force/team. Everyone is still COOP/PvE, all
-- teams are friendly and cease-fire.
ENABLE_SEPARATE_TEAMS = true

-- Main force is what default players join
MAIN_FORCE = "Main Force"

-- Enable if players can allow others to join their base.
-- And specify how many including the host are allowed.
ENABLE_SHARED_SPAWNS = true
MAX_PLAYERS_AT_SHARED_SPAWN = 3

-- Share local team chat with all teams
-- This makes it so you don't have to use /s
-- But it also means you can't talk privately with your own team.
ENABLE_SHARED_TEAM_CHAT = true

---------------------------------------
-- Special Action Cooldowns
---------------------------------------
RESPAWN_COOLDOWN_IN_MINUTES = 15

-- Require playes to be online for at least X minutes
-- Else their character is removed and their spawn point is freed up for use
MIN_ONLINE_TIME_IN_MINUTES = 15

--------------------------------------------------------------------------------
-- Frontier Rocket Silo Options
--------------------------------------------------------------------------------

-- Number of silos found in the wild.
-- These will spawn in a circle at given distance from the center of the map
-- If you set this number too high, you'll have a lot of delay at the start of the game.
SILO_NUM_SPAWNS = 5

-- How many chunks away from the center of the map should the silo be spawned
SILO_CHUNK_DISTANCE = 200

-- If this is enabled, you get silos at the positions specified below.
-- (The other settings above are ignored in this case.)
SILO_FIXED_POSITION = false

-- If you want to set fixed spawn locations for some silos.
SILO_POSITIONS = {{x = -1000, y = -1000},
                  {x = -1000, y = 1000},
                  {x = 1000,  y = -1000},
                  {x = 1000,  y = 1000}}

-- Set this to false so that you have to search for the silo's.
ENABLE_SILO_VISION = true

-- Add beacons around the silo (Philip's mod)
ENABLE_SILO_BEACONS = false
ENABLE_SILO_RADAR = false

-- Allow silos to be built by the player, but forces them to build in
-- the fixed locations. If this is false, silos are built and assigned
-- only to the main force. This can cause a problem for non main forces
-- when playing with LOCK_GOODIES_UNTIL_ROCKET_LAUNCH enabled.
ENABLE_SILO_PLAYER_BUILD = true


--------------------------------------------------------------------------------
-- Long Reach Options
--------------------------------------------------------------------------------
BUILD_DIST_BONUS = 64
REACH_DIST_BONUS = BUILD_DIST_BONUS
RESOURCE_DIST_BONUS = 2

--------------------------------------------------------------------------------
-- Autofill Options
--------------------------------------------------------------------------------
AUTOFILL_TURRET_AMMO_QUANTITY = 10

--------------------------------------------------------------------------------
-- ANTI-Griefing stuff ( I don't personally maintain this as I don't care for it.)
-- These things were added from other people's requests/changes and are disabled by default.
--------------------------------------------------------------------------------
-- Enable this to disable deconstructing from map view, and setting a time limit
-- on ghost placements.
ENABLE_ANTI_GRIEFING = false

-- Makes blueprint ghosts dissapear if they have been placed longer than this
-- ONLY has an effect if ENABLE_ANTI_GRIEFING is true!
GHOST_TIME_TO_LIVE = 10 * TICKS_PER_MINUTE

-- I like keeping this off... set to true if you want to shoot your own chests
-- and stuff.
ENABLE_FRIENDLY_FIRE = false


------------------------------------------------------------------------------------------------------------------------
-- EXPERIMENTAL FEATURES
-- The following things are not recommended unless you really know what you are doing and are okay with crashes and
-- editing lua code.
------------------------------------------------------------------------------------------------------------------------

-- This turns on writing chat and certain events to specific files so that I can use that for discord integration. I
-- suggest you leave this off unless you know what you are doing.
ENABLE_SERVER_WRITE_FILES = false

-- Enable this to have a vanilla style starting spawn. This changes the experience pretty drastically. If you enable
-- this, you will NOT get the option to spawn using the "pre-fab" fixed layout spawns. This is because the spawn types
-- just don't balance well with each other.
ENABLE_VANILLA_SPAWNS = false

-- Vanilla spawn point options (only applicable if ENABLE_VANILLA_SPAWNS is enabled.)

-- Num total spawns pre-assigned (minimum number)
-- Points are in an even grid layout.
VANILLA_SPAWN_COUNT = 60

-- Num tiles between each spawn. (I recommend at least 1000)
VANILLA_SPAWN_SPACING = 2000

-- Silo Islands
-- This options is only valid when used with ENABLE_VANILLA_SPAWNS and FRONTIER_ROCKET_SILO_MODE!
-- This spreads out rocket silos on every OTHER island/vanilla spawn
SILO_ISLANDS_MODE = false

-- This is part of regrowth, and if both are enabled, any chunks which aren't active and have no entities will
-- eventually be deleted over time. DO NOT USE THIS WITH MODS!
ENABLE_WORLD_EATER = false 