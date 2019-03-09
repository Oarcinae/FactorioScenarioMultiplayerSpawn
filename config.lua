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
-- GAME_MODE_MSG = "In the current game mode, a satellite must be launched from an existing far away rocket silo to win!"
-- MODULES_ENABLED = "Mods Enabled: Separate Spawns, RSO, Long-Reach, Autofill, Undecorator, Player List"
GAME_MODE_MSG = "Game modes are a WIP."
MODULES_ENABLED = "Soft Mods Enabled: None"

-- This stuff is shown in the welcome GUI. Make sure it's valid.
WELCOME_MSG_TITLE = "[INSERT SERVER OWNER MSG HERE!]"
SERVER_MSG = "Rules: Be polite. Ask before changing other players's stuff. Have fun!\n"..
"This server is running a custom scenario that changes spawn locations."

SCENARIO_INFO_MSG = "Latest updates in this scenario version:\n"..
"0.17 experimental release. Lots of features removed, still WIP!\n"..
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

-- This allows 2 players to spawn next to each other in the wilderness,
-- each with their own starting point. It adds more GUI selection options.
ENABLE_BUDDY_SPAWN = true

-- Frontier style rocket silo mode
-- This means you can't build silos, but some spawn out in the wild for you to use.
FRONTIER_ROCKET_SILO_MODE = true

-- Enable Undecorator
-- Removes decorative items to reduce save file size.
ENABLE_UNDECORATOR = false

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
ENABLE_ABANDONED_BASE_REMOVAL = false

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
-- Resource & Spawn Circle Options
---------------------------------------

-- Enable this to have a vanilla style starting spawn for all new spawns.
-- This scenario normally gives you a fixed circle with resources.
-- USE_VANILLA_STARTING_SPAWN = true
-- TODO - Requires pre-allocating spawns...

-- Allow players to choose to spawn with a moat
SPAWN_MOAT_CHOICE_ENABLED = true
-- If you change the spawn area size, you might have to adjust this as well
MOAT_SIZE_MODIFIER = 1

-- THIS IS WHAT SETS THE SPAWN CIRCLE SIZE!
-- Create a circle of land area for the spawn
-- If you make this much bigger than a few chunks, good luck.
ENFORCE_LAND_AREA_TILE_DIST = CHUNK_SIZE*1.8

-- Location of water strip (horizontal)
WATER_SPAWN_OFFSET_X = -4
WATER_SPAWN_OFFSET_Y = -38
WATER_SPAWN_LENGTH = 8

-- Start resource amounts (per tile/oil spot)
START_IRON_AMOUNT = 1500
START_COPPER_AMOUNT = 1500
START_STONE_AMOUNT = 1000
START_COAL_AMOUNT = 1500
START_URANIUM_AMOUNT = 1000
START_OIL_AMOUNT = 300000

-- Start resource shape
-- If this is true, it will be a circle
-- If false, it will be a square
ENABLE_RESOURCE_SHAPE_CIRCLE = true

-- Start resource position and size
-- Position is relative to player starting location
START_RESOURCE_STONE_POS_X = -27
START_RESOURCE_STONE_POS_Y = -34
START_RESOURCE_STONE_SIZE = 12

START_RESOURCE_COAL_POS_X = -27
START_RESOURCE_COAL_POS_Y = -20
START_RESOURCE_COAL_SIZE = 12

START_RESOURCE_COPPER_POS_X = -28
START_RESOURCE_COPPER_POS_Y = -3
START_RESOURCE_COPPER_SIZE = 14

START_RESOURCE_IRON_POS_X = -29
START_RESOURCE_IRON_POS_Y = 16
START_RESOURCE_IRON_SIZE = 16

START_RESOURCE_URANIUM_POS_X = 17
START_RESOURCE_URANIUM_POS_Y = -34
START_RESOURCE_URANIUM_SIZE = 0 -- Disabled by default.

-- Specify 2 oil spot locations for starting oil.
START_RESOURCE_OIL_NUM_PATCHES = 2
-- The first patch
START_RESOURCE_OIL_POS_X = -39
START_RESOURCE_OIL_POS_Y = -2
-- How far each patch is offset from the others and in which direction
-- Default (x=0, y=-4) means that patches spawn in a vertical row downwards.
START_RESOURCE_OIL_X_OFFSET = 0
START_RESOURCE_OIL_Y_OFFSET = -4


-- Force the land area circle at the spawn to be fully grass
ENABLE_SPAWN_FORCE_GRASS = true

-- Set this to true for the spawn area to be surrounded by a circle of trees
SPAWN_TREE_CIRCLE_ENABLED = false

-- Set this to true for the spawn area to be surrounded by an octagon of trees
-- I don't recommend using this with moatsm
SPAWN_TREE_OCTAGON_ENABLED = true

---------------------------------------
-- Safe Spawn Area Options
---------------------------------------

-- Safe area has no aliens
-- +/- this in x and y direction
SAFE_AREA_TILE_DIST = CHUNK_SIZE*5

-- Warning area has reduced aliens
-- +/- this in x and y direction
WARNING_AREA_TILE_DIST = CHUNK_SIZE*10

-- 1 : X (spawners alive : spawners destroyed) in this area
WARN_AREA_REDUCTION_RATIO = 10


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

-- Add beacons around the silo (Philip's modm)
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
-- MAP CONFIGURATION OPTIONS
-- In past versions I had a way to config map settings here to be used for cmd
-- line launching, but now you should just be using --map-gen-settings option
-- since it works with --start-server-load-scenario
-- Read the README.md file for instructions.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Alien Options
-- In past versions I had a way to config map settings here to be used for cmd
-- line launching, but now you should just be using --map-settings option
-- since it works with --start-server-load-scenario
-- Read the README.md file for instructions.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ANTI-Griefing stuff ( I don't personally maintain this as I don't care for it.)
-- These things were added from other people's requests/changes and are disabled by default.
--------------------------------------------------------------------------------
-- Enable this to disable some basic things like friendly fire, deconstructing from map view, etc.
-- ENABLE_ANTI_GRIEFING = false

-- Makes blueprint ghosts dissapear if they have been placed longer than this
-- GHOST_TIME_TO_LIVE = 0 * TICKS_PER_MINUTE -- set to 0 for infinite ghost life

-------------------------------------------------------------------------------
-- DEBUG / Custom stuff
--------------------------------------------------------------------------------
-- DEBUG prints for me
global.oarcDebugEnabled = false

-- These are my specific welcome messages that get used only if I am the user
-- that creates the game.
WELCOME_MSG_OARC = "Welcome to Oarc's official server! Join the discord here: discord.gg/TPYxRrS"
WELCOME_MSG_TITLE_OARC = "Welcome to Oarc's Server!"
