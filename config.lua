-- config.lua
-- Configuration Options

--------------------------------------------------------------------------------
-- Useful constants
--------------------------------------------------------------------------------
CHUNK_SIZE = 32
MAX_FORCES = 64
--------------------------------------------------------------------------------


WELCOME_MSG = "Welcome to Oarc's server! This is a BETA test of my custom scenario."
GAME_MODE_MSG = "In the current game mode, a satellite must be launched from the rocket silo to the far east to win!"
-- GAME_MODE_MSG = "The current game mode is just basic vanilla!"
MODULES_ENABLED = "Mods Enabled: Separate Spawns, RSO, Gravestone Chests"
-- MODULES_ENABLED = "Mods Enabled: Gravestone-Chests"

--------------------------------------------------------------------------------
-- Module Enables
-- These enables are not fully tested! For example, disable separate spawns
-- will probably break the frontier rocket silo mode
--------------------------------------------------------------------------------

-- Separate spawns
FRONTIER_ROCKET_SILO_MODE = true

-- Frontier style rocket silo mode
ENABLE_SEPARATE_SPAWNS = true

-- Enable Scenario version of RSO
ENABLE_RSO = true

-- Enable Gravestone Chests
ENABLE_GRAVESTONE_CHESTS = true

-- Enable Undecorator
ENABLE_UNDECORATOR = true

-- DEBUG prints for me
global.oarcDebugEnabled = false
global.spawnDebugEnabled = false

--------------------------------------------------------------------------------
-- Spawn Options
--------------------------------------------------------------------------------

---------------------------------------
-- Distance Options
---------------------------------------

-- Distance in chunks
FAR_MIN_DIST = 50
FAR_MAX_DIST = 125
---------------------------------------
-- Resource Options
---------------------------------------

-- Start resource amounts
START_IRON_AMOUNT = 1500
START_COPPER_AMOUNT = 1500
START_STONE_AMOUNT = 1500
START_COAL_AMOUNT = 1500
START_OIL_AMOUNT = 30000


---------------------------------------
-- Safe Spawn Area Options
---------------------------------------

-- Safe area has no aliens
-- +/- this in x and y direction
SAFE_AREA_TILE_DIST = 300

-- Warning area has reduced aliens
-- +/- this in x and y direction
WARNING_AREA_TILE_DIST = 500

-- 1 : X (spawners alive : spawners destroyed) in this area
WARN_AREA_REDUCTION_RATIO = 15

-- Create a circle of land area for the spawn
ENFORCE_LAND_AREA_TILE_DIST = 40


---------------------------------------
-- Other Forces/Teams Options
---------------------------------------

-- Enable if people can join their own teams
ENABLE_OTHER_TEAMS = false

-- Main force is what default players join
MAIN_FORCE = "main_force"


---------------------------------------
-- Alien Options
---------------------------------------

-- Disable enemy expansion
ENEMY_EXPANSION = false


-- Divide the alien factors by this number to reduce it (or multiply if < 1)
ENEMY_POLLUTION_FACTOR_DIVISOR = 10
ENEMY_DESTROY_FACTOR_DIVISOR = 2



--------------------------------------------------------------------------------
-- Frontier Options
--------------------------------------------------------------------------------

SILO_CHUNK_DISTANCE_X = 250
SILO_DISTANCE_X = SILO_CHUNK_DISTANCE_X*CHUNK_SIZE + CHUNK_SIZE/2
SILO_DISTANCE_Y = 16

-- Should be in the middle of a chunk
SILO_POSITION = {x = SILO_DISTANCE_X, y = SILO_DISTANCE_Y}
