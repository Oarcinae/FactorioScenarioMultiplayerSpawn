-- config.lua
-- Apr 2017
-- Configuration Options
-- 
-- You should be able to leave most of the settings here as defaults.
-- The only thing you definitely want to change are the welcome messages.

--------------------------------------------------------------------------------
-- Messages
--------------------------------------------------------------------------------

WELCOME_MSG = "[INSERT SERVER OWNER MSG HERE!]"
GAME_MODE_MSG = "In the current game mode, a satellite must be launched from an existing far away rocket silo to win!"
MODULES_ENABLED = "Mods Enabled: Separate Spawns, RSO, Long-Reach, Autofill, Undecorator, Player List"

WELCOME_MSG_TITLE = "[INSERT SERVER OWNER MSG HERE!]"
WELCOME_MSG1 = "Rules: Be polite. Ask before changing other players's stuff. Have fun!"
WELCOME_MSG2 = "This server is running a custom scenario that changes spawn locations."

OTHER_MSG1 = "Latest updates in this scenario version (0.4.1):"
OTHER_MSG2 = "Gravestones are back in."

WELCOME_MSG3 = "Due to the way this scenario works, it may take some time for the land"
WELCOME_MSG4 = "around your new spawn area to generate..."
WELCOME_MSG5 = "Please wait for 10-20 seconds when you select your first spawn."
WELCOME_MSG6 = "Contact: SteamID:Oarc | oarcinae@gmail.com"

SPAWN_MSG1 = "Current Spawn Mode: HARDCORE WILDERNESS (BETA)"
SPAWN_MSG2 = "In this mode, there is no default spawn. Everyone starts in the wild!"
SPAWN_MSG3 = "Resources are spread out far apart but are quite rich."

-- These are my specific welcome messages that get used only if I am the user
-- that creates the game.
SERVER_OWNER_IS_OARC = true -- This should be false for you, it's just a convenience for me.
WELCOME_MSG_OARC = "Welcome to Oarc's official server! Join the discord here: discord.gg/TPYxRrS"
WELCOME_MSG_TITLE_OARC = "Welcome to Oarc's Server - Happy 0.15.X!"


--------------------------------------------------------------------------------
-- Module Enables
-- These enables are not fully tested! For example, disable separate spawns
-- will probably break the frontier rocket silo mode
--------------------------------------------------------------------------------

-- Frontier style rocket silo mode
FRONTIER_ROCKET_SILO_MODE = true

-- Separate spawns
-- This is the core of the mod. Probably not a good idea to disable it.
ENABLE_SEPARATE_SPAWNS = true

-- Enable Scenario version of RSO
-- You can reconfigure the RSO resource settings in the RSO files if you want to
ENABLE_RSO = true

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

-- Enable Gravestone Chests
ENABLE_GRAVESTONE_ON_DEATH = true
 -- Items dumped into chest when you leave.
ENABLE_GRAVESTONE_ON_LEAVING = false
 -- If anyone leaves within first X minutes, items get dumped into chest.
ENABLE_GRAVESTONE_ON_LEAVING_TIME_MINS = 30

-- Enable quick start items
ENABLE_POWER_ARMOR_QUICK_START = false

-- Enable shared vision between teams (all teams are still COOP)
ENABLE_SHARED_TEAM_VISION = true

--------------------------------------------------------------------------------
-- Spawn Options
--------------------------------------------------------------------------------

---------------------------------------
-- Starting Items
---------------------------------------
-- Items provided to the player the first time they join ("quick start" commented out)
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
NEAR_MIN_DIST = 25 --50
NEAR_MAX_DIST = 100 --125
                   --
-- Far Distance in chunks
FAR_MIN_DIST = 100 --50
FAR_MAX_DIST = 200 --125
          
---------------------------------------
-- Resource & Spawn Circle Options
---------------------------------------

-- Create a circle of land area for the spawn
-- This is the radius (I think?) in TILES.
ENFORCE_LAND_AREA_TILE_DIST = 48

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
START_RESOURCE_OIL_A_POS_X = -39
START_RESOURCE_OIL_A_POS_Y = -2
START_RESOURCE_OIL_B_POS_X = -39
START_RESOURCE_OIL_B_POS_Y = 2


-- Force the land area circle at the spawn to be fully grass
ENABLE_SPAWN_FORCE_GRASS = true

-- Set this to true for the spawn area to be surrounded by a circle of trees
SPAWN_TREE_CIRCLE_ENABLED = true

-- Set this to true for the spawn area to be surrounded by an octagon of trees
SPAWN_TREE_OCTAGON_ENABLED = true

---------------------------------------
-- Safe Spawn Area Options
---------------------------------------

-- Safe area has no aliens
-- +/- this in x and y direction
SAFE_AREA_TILE_DIST = CHUNK_SIZE*12

-- Warning area has reduced aliens
-- +/- this in x and y direction
WARNING_AREA_TILE_DIST = CHUNK_SIZE*20

-- 1 : X (spawners alive : spawners destroyed) in this area
WARN_AREA_REDUCTION_RATIO = 15


---------------------------------------
-- Other Forces/Teams Options
---------------------------------------

-- Separate teams
-- This allows you to join your own force/team. Everyone is still COOP/PvE, all
-- teams are friendly and cease-fire.
ENABLE_SEPARATE_TEAMS = true

-- Main force is what default players join
MAIN_FORCE = "main_force"

-- Enable if people can spawn at the main base
ENABLE_DEFAULT_SPAWN = false

-- Enable if people can allow others to join their base
ENABLE_SHARED_SPAWNS = true
MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN = 3


---------------------------------------
-- Special Action Cooldowns
---------------------------------------
RESPAWN_COOLDOWN_IN_MINUTES = 60
RESPAWN_COOLDOWN_TICKS = TICKS_PER_MINUTE * RESPAWN_COOLDOWN_IN_MINUTES

-- Require playes to be online for at least 5 minutes
-- Else their character is removed and their spawn point is freed up for use
MIN_ONLIME_TIME_IN_MINUTES = 5
MIN_ONLINE_TIME = TICKS_PER_MINUTE * MIN_ONLIME_TIME_IN_MINUTES


--------------------------------------------------------------------------------
-- Alien Options
--------------------------------------------------------------------------------

-- Enable/Disable enemy expansion (Applies to RSO as well!)
ENEMY_EXPANSION = false

-- Divide the alien factors by this number to reduce it (or multiply if < 1)
ENEMY_POLLUTION_FACTOR_DIVISOR = 10
ENEMY_DESTROY_FACTOR_DIVISOR = 5


--------------------------------------------------------------------------------
-- Frontier Rocket Silo Options
--------------------------------------------------------------------------------

SILO_CHUNK_DISTANCE_X = 250
SILO_DISTANCE_X = SILO_CHUNK_DISTANCE_X*CHUNK_SIZE + CHUNK_SIZE/2
SILO_DISTANCE_Y = 16

-- Should be in the middle of a chunk
SILO_POSITION = {x = SILO_DISTANCE_X, y = SILO_DISTANCE_Y}

-- If this is enabled, the static position is ignored.
ENABLE_RANDOM_SILO_POSITION = true

--------------------------------------------------------------------------------
-- Long Reach Options
--------------------------------------------------------------------------------

BUILD_DIST_BONUS = 20
REACH_DIST_BONUS = BUILD_DIST_BONUS
RESOURCE_DIST_BONUS = 2

--------------------------------------------------------------------------------
-- Autofill Options
--------------------------------------------------------------------------------

AUTOFILL_TURRET_AMMO_QUANTITY = 10

--------------------------------------------------------------------------------
-- Use rso_config and rso_resource_config for RSO config settings
--------------------------------------------------------------------------------
-- Don't touch unless you know what you're doing...
-- When using RSO, all resources MUST BE SET TO SIZE=NONE!
--------------------------------------------------------------------------------
MAP_SETTINGS_RSO_TERRAIN_SEGMENTATION = "very-low" -- Frequency of water
MAP_SETTINGS_RSO_WATER = "high" -- Size of water patches
MAP_SETTINGS_RSO_PEACEFUL = false -- Peaceful mode for biters/aliens
MAP_SETTINGS_RSO_SEED = math.random(999999999) -- Default is randomized map
MAP_SETTINGS_RSO_STARTING_AREA = "very-low" -- Does not affect Oarc spawn sizes.

-------------------------------------------------------------------------------
-- DEBUG
--------------------------------------------------------------------------------

-- DEBUG prints for me
global.oarcDebugEnabled = false
