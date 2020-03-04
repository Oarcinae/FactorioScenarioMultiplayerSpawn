-- example-config.lua (Rename this file to config.lua to use it)
-- Sep 24 2019 (updated on)
-- Configuration Options
--
-- You should be able to leave most of the settings here as defaults.
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

CONTACT_MSG = "Contact: SteamID:Oarc | oarcinae@gmail.com | discord.gg/trnpcen"

--------------------------------------------------------------------------------
-- Module Enables
--------------------------------------------------------------------------------

-- Enable this to have a vanilla style starting spawn.
-- This changes the experience pretty drastically.
-- If you enable this, you will NOT get the option to spawn using the "pre-fab"
-- fixed layout spawns. This is because the spawn types just don't balance well with
-- each other.
ENABLE_VANILLA_SPAWNS = false

-- This allows 2 players to spawn next to each other in the wilderness,
-- each with their own starting point. It adds more GUI selection options.
ENABLE_BUDDY_SPAWN = true

-- Frontier style rocket silo mode
-- This means you can't build silos, but some spawn out in the wild for you to use.
FRONTIER_ROCKET_SILO_MODE = true

-- Silo Islands
-- This options is only valid when used with ENABLE_VANILLA_SPAWNS and FRONTIER_ROCKET_SILO_MODE!
-- This spreads out rocket silos on every OTHER island/vanilla spawn
SILO_ISLANDS_MODE = false

-- Enable Undecorator
-- Removes decorative items to reduce save file size.
ENABLE_UNDECORATOR = true

-- Enable Tags
ENABLE_TAGS = true

-- Enable Long Reach
ENABLE_LONGREACH = true

-- Enable Autofill
ENABLE_AUTOFILL = true

-- Enable vanilla loaders
ENABLE_LOADERS = true

-- Enable Playerlist
ENABLE_PLAYER_LIST = true
PLAYER_LIST_OFFLINE_PLAYERS = true -- List offline players as well.

-- Enable shared vision between teams (all teams are COOP regardless)
ENABLE_SHARED_TEAM_VISION = true

-- Cleans up unused chunks periodically. Helps keep map size down.
ENABLE_REGROWTH = true

-- Only works if you have the Unused Chunk Removal mod installed.
ENABLE_ABANDONED_BASE_REMOVAL = true

-- Enable the new 0.17 research queue by default for all forces.
ENABLE_RESEARCH_QUEUE = true

-- Enable item & energy sharing system.
ENABLE_CHEST_SHARING = true

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
    {t="atomic-bomb"},{t="power-armor-mk2"},{t="artillery"}
}
LOCKED_RECIPES = {
    {r="productivity-module-3"},{r="speed-module-3"}
}

-- Give cheaty items on start.
ENABLE_POWER_ARMOR_QUICK_START = false
ENABLE_MODULAR_ARMOR_QUICK_START = true

--------------------------------------------------------------------------------
-- MAP CONFIGURATION OPTIONS
-- In past versions I had a way to config map settings here to be used for cmd
-- line launching, but now you should just be using --map-gen-settings and
-- --map-settings option since it works with --start-server-load-scenario
-- Read the README.md file for instructions.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Alien Options
--------------------------------------------------------------------------------

-- Adjust enemy spawning based on distance to spawns. All it does it make things
-- more balanced based on your distance and makes the game a little easier.
-- No behemoth worms everywhere just because you spawned far away.
-- If you're trying out the vanilla spawning, you might want to disable this.
OARC_MODIFIED_ENEMY_SPAWNING = true

---------------------------------------
-- Starting Items
---------------------------------------
-- Items provided to the player the first time they join
PLAYER_SPAWN_START_ITEMS = {
    {name="pistol", count=1},
    {name="firearm-magazine", count=200},
    {name="iron-plate", count=100},
    {name="burner-mining-drill", count = 4},
    {name="stone-furnace", count = 4},
    {name="coal", count = 50},
    {name="stone", count = 50},
}

-- Items provided after EVERY respawn (disabled by default)
PLAYER_RESPAWN_START_ITEMS = {
    -- {name="pistol", count=1},
    -- {name="firearm-magazine", count=100}
}

---------------------------------------
-- Distance Options
---------------------------------------

-- This is the radius, in chunks, that a spawn area is from any other generated
-- chunks. It ensures the spawn area isn't too near generated/explored/existing
-- area. The larger you make this, the further away players will spawn from
-- generated map area (even if it is not visible on the map!).
CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS = 10

-- Near Distance in chunks
-- When a player selects "near" spawn, they will be in or as close to this range as possible.
NEAR_MIN_DIST = 0
NEAR_MAX_DIST = 50

-- Far Distance in chunks
-- When a player selects "far" spawn, they will be at least this distance away.
FAR_MIN_DIST = 200
FAR_MAX_DIST = 300

---------------------------------------
-- Vanilla spawn point options
-- (only applicable if ENABLE_VANILLA_SPAWNS is enabled.)
---------------------------------------

-- Num total spawns pre-assigned (minimum number)
-- Not sure you need that much anyways....
-- Points are in an even grid layout.
VANILLA_SPAWN_COUNT = 60

-- Num tiles between each spawn. (I recommend at least 1000)
VANILLA_SPAWN_SPACING = 2000

---------------------------------------
-- Resource & Spawn Circle Options
---------------------------------------

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

        -- If you change the spawn area size, you might have to adjust this as well
        moat_size_modifier = 1,

        -- Start resource shape. true = circle, false = square.
        resources_circle_shape = true,

        -- Force the land area circle at the spawn to be fully grass
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
        warn_radius = CHUNK_SIZE*16,

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

--------------------------------------------------------------------------------
-- This turns on writing chat and certain events to specific files so that I can
-- use that for discord integration. I suggest you leave this off unless you
-- know what you are doing.
--------------------------------------------------------------------------------
ENABLE_SERVER_WRITE_FILES = false