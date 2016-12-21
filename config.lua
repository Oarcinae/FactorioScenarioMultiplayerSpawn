-- config.lua
-- Dec 2016
-- Configuration Options

--------------------------------------------------------------------------------
-- Messages
--------------------------------------------------------------------------------

WELCOME_MSG = "[INSERT SERVER OWNER MSG HERE!]"
-- WELCOME_MSG = "Welcome to Oarc's official server! Join the discord here: discord.gg/Wj56gkU"
GAME_MODE_MSG = "In the current game mode, a satellite must be launched from an existing far away rocket silo to win!"
-- GAME_MODE_MSG = "The current game mode is just basic vanilla!"
MODULES_ENABLED = "Mods Enabled: Separate Spawns, RSO, Gravestone Chests, Long-Reach, Autofill, Blueprint Strings"
-- MODULES_ENABLED = "Mods Enabled: Gravestone-Chests"

WELCOME_MSG_TITLE = "[INSERT SERVER OWNER MSG HERE!]"
-- WELCOME_MSG_TITLE = "Welcome to Oarc's Server"
WELCOME_MSG1 = "Rules: Be polite. Ask before changing other players's stuff. Have fun!"
WELCOME_MSG2 = "This server is running a custom scenario that changes spawn locations."

OTHER_MSG1 = "Latest updates in this scenario version (0.2.7):"
OTHER_MSG2 = "Blueprint String Softmod, Bug fix for alien settings"


WELCOME_MSG3 = "Due to the way this scenario works, it may take some time for the land"
WELCOME_MSG4 = "around your new spawn area to generate..."
WELCOME_MSG5 = "Please wait for 10-20 seconds when you select your first spawn."
WELCOME_MSG6 = "Contact: SteamID:Oarc | Twitter:@_Oarc_ | oarcinae@gmail.com"


SPAWN_MSG1 = "Current Spawn Mode: HARDCORE WILDERNESS (Always in BETA)"
SPAWN_MSG2 = "In this mode, there is no default spawn. Everyone starts in the wild!"
SPAWN_MSG3 = "Resources are spread out far apart but are quite rich."

--------------------------------------------------------------------------------
-- Module Enables
-- These enables are not fully tested! For example, disable separate spawns
-- will probably break the frontier rocket silo mode
--------------------------------------------------------------------------------

-- Frontier style rocket silo mode
FRONTIER_ROCKET_SILO_MODE = true

-- Separate spawns
ENABLE_SEPARATE_SPAWNS = true

-- Enable Scenario version of RSO
ENABLE_RSO = true

-- Enable Gravestone Chests
ENABLE_GRAVESTONE_CHESTS = true

-- Enable Undecorator
ENABLE_UNDECORATOR = true

-- Enable Tags
ENABLE_TAGS = true

-- Enable Long Reach
ENABLE_LONGREACH = true

-- Enable Autofill
ENABLE_AUTOFILL = true

-- Enable BPS
ENABLE_BLUEPRINT_STRING = true

--------------------------------------------------------------------------------
-- Spawn Options
--------------------------------------------------------------------------------

---------------------------------------
-- Distance Options
---------------------------------------
-- Near Distance in chunks
NEAR_MIN_DIST = 25 --50
NEAR_MAX_DIST = 100 --125
                   --
-- Far Distance in chunks
FAR_MIN_DIST = 100 --50
FAR_MAX_DIST = 200 --125
                   --
---------------------------------------
-- Resource Options
---------------------------------------
-- This is an example of how I set my resources in the game.

    -- Start resource amounts
    START_IRON_AMOUNT = 1500
    START_COPPER_AMOUNT = 1500
    START_STONE_AMOUNT = 1500
    START_COAL_AMOUNT = 1500
    START_OIL_AMOUNT = 30000

    -- Start resource shape
    -- If this is true, it will be a circle
    -- If false, it will be a square
    ENABLE_RESOURCE_SHAPE_CIRCLE = true

    -- Start resource position and size
    -- Position is relative to player starting location
    START_RESOURCE_STONE_POS_X = -25
    START_RESOURCE_STONE_POS_Y = -31
    START_RESOURCE_STONE_SIZE = 15

    START_RESOURCE_COAL_POS_X = -25
    START_RESOURCE_COAL_POS_Y = -16
    START_RESOURCE_COAL_SIZE = 15

    START_RESOURCE_COPPER_POS_X = -25
    START_RESOURCE_COPPER_POS_Y = 0
    START_RESOURCE_COPPER_SIZE = 15

    START_RESOURCE_IRON_POS_X = -25
    START_RESOURCE_IRON_POS_Y = 15
    START_RESOURCE_IRON_SIZE = 15

    START_RESOURCE_OIL_POS_X = -30
    START_RESOURCE_OIL_POS_Y = 0

-- This is Philip017's default settings as another example.

    -- -- Start resource amounts
    -- START_IRON_AMOUNT = 1200
    -- START_COPPER_AMOUNT = 1200
    -- START_STONE_AMOUNT = 1500
    -- START_COAL_AMOUNT = 1500
    -- START_OIL_AMOUNT = 30000

    -- -- Stat resource shape
    -- -- If this is true, it will be a circle
    -- -- If false, it will be a square
    -- ENABLE_RESOURCE_SHAPE_CIRCLE = true

    -- -- Start resource position and size
    -- -- Position is relative to player starting location
    -- START_RESOURCE_STONE_POS_X = -22
    -- START_RESOURCE_STONE_POS_Y = -30
    -- START_RESOURCE_STONE_SIZE = 12

    -- START_RESOURCE_COAL_POS_X = -22
    -- START_RESOURCE_COAL_POS_Y = -17
    -- START_RESOURCE_COAL_SIZE = 12

    -- START_RESOURCE_COPPER_POS_X = -23
    -- START_RESOURCE_COPPER_POS_Y = -4
    -- START_RESOURCE_COPPER_SIZE = 14

    -- START_RESOURCE_IRON_POS_X = -24
    -- START_RESOURCE_IRON_POS_Y = 11
    -- START_RESOURCE_IRON_SIZE = 16

    -- START_RESOURCE_OIL_POS_X = -30
    -- START_RESOURCE_OIL_POS_Y = 0



-- Force the land area circle at the spawn to be fully grass
ENABLE_SPAWN_FORCE_GRASS = true

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

-- Create a circle of land area for the spawn
ENFORCE_LAND_AREA_TILE_DIST = 40


---------------------------------------
-- Other Forces/Teams Options
---------------------------------------

-- I am not currently implementing other teams. It gets too complicated.
-- Enable if people can join their own teams
-- ENABLE_OTHER_TEAMS = false

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


-- Allow players to choose another spawn in the first 10 minutes
-- This does not allow creating a new spawn point. Only joining other players.
-- SPAWN_CHANGE_GRACE_PERIOD_IN_MINUTES = 10
-- SPAWN_GRACE_TIME = TICKS_PER_MINUTE * SPAWN_CHANGE_GRACE_PERIOD_IN_MINUTES


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

BUILD_DIST_BONUS = 15
REACH_DIST_BONUS = BUILD_DIST_BONUS
RESOURCE_DIST_BONUS = 2

--------------------------------------------------------------------------------
-- Autofill Options
--------------------------------------------------------------------------------

AUTOFILL_TURRET_AMMO_QUANTITY = 10

--------------------------------------------------------------------------------
-- Use rso_config and rso_resourece_config for RSO config settings
--------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- DEBUG
--------------------------------------------------------------------------------

-- DEBUG prints for me
global.oarcDebugEnabled = false