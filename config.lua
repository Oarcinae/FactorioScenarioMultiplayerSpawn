-- config.lua
-- Feb 2019
-- Configuration Options
-- 
-- You should be able to leave most of the settings here as defaults.
-- The only thing you definitely want to change are the welcome messages.

--------------------------------------------------------------------------------
-- Messages
-- You will want to change some of these to be your own.
-- Make sure SERVER_OWNER_IS_OARC = false
--------------------------------------------------------------------------------

-- This stuff is printed in the console. It's probably ignored most of the time.
WELCOME_MSG = "[INSERT SERVER OWNER MSG HERE!]"
GAME_MODE_MSG = "In the current game mode, a satellite must be launched from an existing far away rocket silo to win!"
MODULES_ENABLED = "Soft Mods Enabled: Separate Spawns, Long-Reach, Autofill, Player List"

-- This stuff is shown in the welcome GUI. Make sure it's valid.
WELCOME_MSG_TITLE = "[INSERT SERVER OWNER MSG HERE!]"
SERVER_MSG = "Rules: Be polite. Ask before changing other players's stuff. Have fun!\n"..
"This server is running a custom scenario that changes spawn locations."

SCENARIO_INFO_MSG = "Latest updates in this scenario version:\n"..
"0.17 experimental release. Improved enemy difficulty/spawning!\n"..
"This scenario gives you and/or your friends your own starting area.\n"..
"You can be on the main team or your own. All teams are friendly.\n"..
"If you leave in the first 15 minutes, your base and character will be deleted!"

SPAWN_WARN_MSG = "Due to the way this scenario works, it may take some time for the land around your new spawn area to generate... Please wait for 10-20 seconds when you select your first spawn."

CONTACT_MSG = "Contact: SteamID:Oarc | oarcinae@gmail.com | discord.gg/TPYxRrS"

-- This should be false for you, it's just a convenience for me.
SERVER_OWNER_IS_OARC = false


--------------------------------------------------------------------------------
-- Module Enables
-- These enables are not fully tested! For example, disabling separate spawns
-- will probably break the frontier rocket silo mode
--------------------------------------------------------------------------------

-- Separate spawns
-- This is the core of the mod. Probably not a good idea to disable it.
ENABLE_SEPARATE_SPAWNS = true

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

-- Enable Undecorator
-- Removes decorative items to reduce save file size.
ENABLE_UNDECORATOR = true

-- Enable Tags
ENABLE_TAGS = true

-- Enable Long Reach
ENABLE_LONGREACH = true

-- Enable Autofill
ENABLE_AUTOFILL = true

-- Enable Playerlist
ENABLE_PLAYER_LIST = true
PLAYER_LIST_OFFLINE_PLAYERS = true -- List offline players as well.

-- Enable shared vision between teams (all teams are COOP regardless)
ENABLE_SHARED_TEAM_VISION = true

-- Enable map regrowth, see regrowth_map.lua for more info.
-- I'm not a fan of this anymore, but it helps keep the map size down
ENABLE_REGROWTH = false

-- If you have regrowth enabled, this should also be enabled.
-- It removes bases for players that join and leave the game quickly.
-- This can also be used without enabling regrowth.
ENABLE_ABANDONED_BASE_REMOVAL = true

-- Enable the new 0.17 research queue by default.
ENABLE_RESEARCH_QUEUE = true

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
-- Might want to disable this if you're using ENABLE_VANILLA_SPAWNS
OARC_MODIFIED_ENEMY_SPAWNING = true

--------------------------------------------------------------------------------
-- Spawn Options
--------------------------------------------------------------------------------

---------------------------------------
-- Starting Items
---------------------------------------
-- Items provided to the player the first time they join
PLAYER_SPAWN_START_ITEMS = {
    {name="pistol", count=1},
    {name="firearm-magazine", count=100},
    {name="iron-plate", count=8},
    {name="burner-mining-drill", count = 1},
    {name="stone-furnace", count = 1},
    -- {name="iron-plate", count=20},
    -- {name="burner-mining-drill", count = 1},
    -- {name="stone-furnace", count = 1},
    -- {name="power-armor", count=1},
    -- {name="fusion-reactor-equipment", count=1},
    -- {name="battery-mk2-equipment", count=3},
    -- {name="exoskeleton-equipment", count=1},
    -- {name="personal-roboport-mk2-equipment", count=3},
    -- {name="solar-panel-equipment", count=7},
    -- {name="construction-robot", count=100},
    -- {name="repair-pack", count=100},
    -- {name="steel-axe", count=3},
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
CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS = 5

-- Near Distance in chunks
NEAR_MIN_DIST = 0
NEAR_MAX_DIST = 50

-- Far Distance in chunks
FAR_MIN_DIST = 200
FAR_MAX_DIST = 300

---------------------------------------
-- Vanilla spawn point options
-- (only applicable if ENABLE_VANILLA_SPAWNS is enabled.)
---------------------------------------

-- Num total spawns pre-assigned (minimum number)
VANILLA_SPAWN_COUNT = 100

-- Num tiles between each spawn. (I recommend at least 1000)
VANILLA_SPAWN_SPACING = 2000

---------------------------------------
-- Resource & Spawn Circle Options
---------------------------------------

-- Allow players to choose to spawn with a moat
SPAWN_MOAT_CHOICE_ENABLED = true
-- If you change the spawn area size, you might have to adjust this as well
MOAT_SIZE_MODIFIER = 1

-- THIS IS WHAT SETS THE SPAWN CIRCLE SIZE!
-- Create a circle of land area for the spawn
-- If you make this much bigger than a few chunks, good luck.
ENFORCE_LAND_AREA_TILE_DIST = CHUNK_SIZE*1.8


-- This is where you can modify what resources spawn, how much, where, etc.
-- Once you have a config you like, it's a good idea to save it for later use
-- so you don't lost it if you update the scenario.
OARC_CFG = {
    -- Misc spawn related config.
    gen_settings = {
        -- Start resource shape. true = circle, false = square.
        resources_circle_shape = true,
        -- Force the land area circle at the spawn to be fully grass
        force_grass = true,
        -- Spawn a circle/octagon of trees around the base outline.
        tree_circle = true,
        tree_octagon = false,
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
        radius = 44,
        -- At what angle (in radians) do resources start.
        -- 0 means starts directly east.
        -- Resources are placed clockwise from there.
        angle_offset = 2.32, -- 2.32 is approx SSW.
        -- At what andle do we place the last resource.
        -- angle_offset and angle_final determine spacing and placement.
        angle_final = 4.46 -- 4.46 is approx NNW.
    },
    -- Resource tiles
    resource_tiles =
    {
        ["iron-ore"] = 
        {
            amount = 1500,
            size = 16,
            x_offset = -29,
            y_offset = 16
        },
        ["copper-ore"] = 
        {
            amount = 1500,
            size = 14,
            x_offset = -28,
            y_offset = -3
        },
        ["stone"] = 
        {
            amount = 1000,
            size = 12,
            x_offset = -27,
            y_offset = -34
        },
        ["coal"] = 
        {
            amount = 1500,
            size = 12,
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

        -- ANGELS example
        -- ["angels-ore1"] = 
        -- {
        --     amount = 1500,
        --     size = 16,
        --     x_offset = -29,
        --     y_offset = 16
        -- },
        -- ["angels-ore3"] = 
        -- {
        --     amount = 1500,
        --     size = 14,
        --     x_offset = -28,
        --     y_offset = -3
        -- },
        -- ["angels-ore5"] = 
        -- {
        --     amount = 1000,
        --     size = 12,
        --     x_offset = -27,
        --     y_offset = -34
        -- },
        -- ["angels-ore6"] = 
        -- {
        --     amount = 1500,
        --     size = 12,
        --     x_offset = -27,
        --     y_offset = -20
        -- },
        -- ["coal"] = 
        -- {
        --     amount = 0,
        --     size = 0,
        --     x_offset = 17,
        --     y_offset = -34
        -- }
    },
    -- Special resources like oil
    resource_patches =
    {
        ["crude-oil"] = 
        {
            num_patches = 2,
            amount = 300000,
            x_offset_start = 0,
            y_offset_start = 48,
            x_offset_next = 4,
            y_offset_next = 0
        }
    }
}



---------------------------------------
-- Safe Spawn Area Options
---------------------------------------

-- Safe area has no aliens
-- +/- this in x and y direction
SAFE_AREA_TILE_DIST = CHUNK_SIZE*10

-- Warning area has significantly reduced aliens
-- +/- this in x and y direction
WARNING_AREA_TILE_DIST = CHUNK_SIZE*20

-- 1 : X (spawners alive : spawners destroyed) in this area
WARN_AREA_REDUCTION_RATIO = 20

-- Danger area has slightly reduce aliens
REDUCED_DANGER_AREA_TILE_DIST = CHUNK_SIZE*50

-- 1 : X (spawners alive : spawners destroyed) in this area
REDUCED_DANGER_AREA_REDUCTION_RATIO = 5

---------------------------------------
-- Other Forces/Teams Options
---------------------------------------

-- Separate teams
-- This allows you to join your own force/team. Everyone is still COOP/PvE, all
-- teams are friendly and cease-fire.
ENABLE_SEPARATE_TEAMS = true

-- Main force is what default players join
MAIN_FORCE = "Main Force"

-- Enable if people can spawn at the main base
-- THIS CURRENTLY IS BROKEN! YOU WILL NOT GET ANY RESOURCES IF YOU USE RSO!
ENABLE_DEFAULT_SPAWN = false -- DON'T USE THIS

-- Enable if people can allow others to join their base
ENABLE_SHARED_SPAWNS = true
MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN = 0

-- Share local team chat with all teams
-- This makes it so you don't have to use /s
-- but it means you can't talk privately with your own team.
ENABLE_SHARED_TEAM_CHAT = true

---------------------------------------
-- Special Action Cooldowns
---------------------------------------
RESPAWN_COOLDOWN_IN_MINUTES = 15
RESPAWN_COOLDOWN_TICKS = TICKS_PER_MINUTE * RESPAWN_COOLDOWN_IN_MINUTES

-- Require playes to be online for at least X minutes
-- Else their character is removed and their spawn point is freed up for use
MIN_ONLINE_TIME_IN_MINUTES = 15
MIN_ONLINE_TIME = TICKS_PER_MINUTE * MIN_ONLINE_TIME_IN_MINUTES

--------------------------------------------------------------------------------
-- ANTI-Griefing stuff ( I don't personally maintain this as I don't care for it.)
-- These things were added from other people's requests/changes.
-- It is very very basic only, nothing fancy.
--------------------------------------------------------------------------------
-- Enable this to disable some basic things like friendly fire, deconstructing from map view, etc.
ENABLE_ANTI_GRIEFING = true

-- Makes blueprint ghosts dissapear if they have been placed longer than this
GHOST_TIME_TO_LIVE = 15 * TICKS_PER_MINUTE -- set to 0 for infinite ghost life

--------------------------------------------------------------------------------
-- Frontier Rocket Silo Options
--------------------------------------------------------------------------------

-- Number of silos found in the wild.
-- These will spawn in a circle at given distance from the center of the map
-- If you set this number too high, you'll have a lot of delay at the start of the game.
SILO_NUM_SPAWNS = 3

-- How many chunks away from the center of the map should the silo be spawned
SILO_CHUNK_DISTANCE = 200

-- If this is enabled, you get ONE silo at the location specified below.
SILO_FIXED_POSITION = false

-- If you want to set a fixed spawn location for a single silo
SILO_POSITION = {x = 0, y = 100}

-- Set this to false so that you have to search for the silo's.
ENABLE_SILO_VISION = true

-- Add beacons around the silo (Philip's mod)
ENABLE_SILO_BEACONS = false
ENABLE_SILO_RADAR = false

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
-- Enable this to disable some basic things like friendly fire, deconstructing from map view, etc.
ENABLE_ANTI_GRIEFING = true

-- Makes blueprint ghosts dissapear if they have been placed longer than this
GHOST_TIME_TO_LIVE = 0 * TICKS_PER_MINUTE -- set to 0 for infinite ghost life

-------------------------------------------------------------------------------
-- DEBUG / Custom stuff
--------------------------------------------------------------------------------

-- DEBUG prints for me in game.
global.oarcDebugEnabled = false

-- These are my specific welcome messages that get used only if I am the user
-- that creates the game.
WELCOME_MSG_OARC = "Welcome to Oarc's official server! Join the discord here: discord.gg/TPYxRrS"
WELCOME_MSG_TITLE_OARC = "Welcome to Oarc's Server!"
