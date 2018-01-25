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

OTHER_MSG1 = "Latest updates in this scenario version:"
OTHER_MSG2 = "0.16 experimental release. Now with BUDDY SPAWN system."
-- Optional other messages below:
OTHER_MSG3 = "Standard multiplayer spawn allows spawning in far locations."
OTHER_MSG4 = "You can be on the main team or your own."
OTHER_MSG5 = "If you leave in the first 15 minutes, your base and character will be deleted!"


WELCOME_MSG3 = "Due to the way this scenario works, it may take some time for the land"
WELCOME_MSG4 = "around your new spawn area to generate..."
WELCOME_MSG5 = "Please wait for 10-20 seconds when you select your first spawn."
WELCOME_MSG6 = "Contact: SteamID:Oarc | oarcinae@gmail.com"

SPAWN_MSG1 = "Current Spawn Mode: WILDERNESS"
SPAWN_MSG2 = "In this mode, there is no default spawn. Everyone starts in the wild!"
SPAWN_MSG3 = "Resources are spread out far apart but are quite rich."

-- These are my specific welcome messages that get used only if I am the user
-- that creates the game.
SERVER_OWNER_IS_OARC = false -- This should be false for you, it's just a convenience for me.
WELCOME_MSG_OARC = "Welcome to Oarc's official server! Join the discord here: discord.gg/TPYxRrS"
WELCOME_MSG_TITLE_OARC = "Welcome to Oarc's Server!"


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

-- RSO soft-mod (included in the scenario)
ENABLE_RSO = true

-- Frontier style rocket silo mode
FRONTIER_ROCKET_SILO_MODE = false

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

-- Enable Gravestone Chests
ENABLE_GRAVESTONE_ON_DEATH = false

 -- Items dumped into chest when you leave.
ENABLE_GRAVESTONE_ON_LEAVING = false
 -- If anyone leaves within first X minutes, items get dumped into chest.
ENABLE_GRAVESTONE_ON_LEAVING_TIME_MINS = 15

-- Enable quick start items
ENABLE_POWER_ARMOR_QUICK_START = false

-- Enable shared vision between teams (all teams are COOP regardless)
ENABLE_SHARED_TEAM_VISION = true

-- Enable map regrowth, see regrowth_map.lua for more info.
ENABLE_REGROWTH = false
-- If you have regrowth enabled, this should also be enabled.
-- It removes bases for players that join and leave the game quickly.
-- This can also be used without enabling regrowth.
ENABLE_ABANDONED_BASE_REMOVAL = true

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
NEAR_MIN_DIST = 0 --50
NEAR_MAX_DIST = 50 --125
                   --
-- Far Distance in chunks
FAR_MIN_DIST = 200 --50
FAR_MAX_DIST = 300 --125
          
---------------------------------------
-- Resource & Spawn Circle Options
---------------------------------------

-- Enable this to have a vanilla style starting spawn for all new spawns.
-- This scenario normally gives you a fixed circle with resources.
-- USE_VANILLA_STARTING_SPAWN = true
-- TODO - Requires pre-allocating spawns...

-- Allow players to choose to spawn with a moat
SPAWN_MOAT_CHOICE_ENABLED = true

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
SAFE_AREA_TILE_DIST = CHUNK_SIZE*5

-- Warning area has reduced aliens
-- +/- this in x and y direction
WARNING_AREA_TILE_DIST = CHUNK_SIZE*10

-- 1 : X (spawners alive : spawners destroyed) in this area
WARN_AREA_REDUCTION_RATIO = 5


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
ENABLE_DEFAULT_SPAWN = false

-- Enable if people can allow others to join their base
ENABLE_SHARED_SPAWNS = true
MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN = 3

-- Share local team chat with all teams
-- This makes it so you don't have to use /s
-- but it means you can't talk privately with your own team.
ENABLE_SHARED_TEAM_CHAT = true

---------------------------------------
-- Special Action Cooldowns
---------------------------------------
RESPAWN_COOLDOWN_IN_MINUTES = 60
RESPAWN_COOLDOWN_TICKS = TICKS_PER_MINUTE * RESPAWN_COOLDOWN_IN_MINUTES

-- Require playes to be online for at least 5 minutes
-- Else their character is removed and their spawn point is freed up for use
MIN_ONLINE_TIME_IN_MINUTES = 10
MIN_ONLINE_TIME = TICKS_PER_MINUTE * MIN_ONLINE_TIME_IN_MINUTES


--------------------------------------------------------------------------------
-- Alien Options
--------------------------------------------------------------------------------

-- Enable/Disable enemy expansion
ENEMY_EXPANSION = true

-- Divide the alien evolution factors by this number to reduce it (or multiply if < 1)
ENEMY_TIME_FACTOR_DISABLE = true -- Set this to true to disable time based evolution completely.
ENEMY_TIME_FACTOR_DIVISOR = 1
ENEMY_POLLUTION_FACTOR_DISABLE = true -- Set this to true to disable pollution based evolution completely.
ENEMY_POLLUTION_FACTOR_DIVISOR = 1
ENEMY_DESTROY_FACTOR_DIVISOR = 1

--------------------------------------------------------------------------------
-- Frontier Rocket Silo Options
--------------------------------------------------------------------------------

SILO_CHUNK_DISTANCE_X = 15
SILO_DISTANCE_X = SILO_CHUNK_DISTANCE_X*CHUNK_SIZE + CHUNK_SIZE/2
SILO_DISTANCE_Y = 16

-- Should be in the middle of a chunk
SILO_POSITION = {x = SILO_DISTANCE_X, y = SILO_DISTANCE_Y}

-- If this is enabled, the static position is ignored.
ENABLE_RANDOM_SILO_POSITION = true

--------------------------------------------------------------------------------
-- Long Reach Options
--------------------------------------------------------------------------------

BUILD_DIST_BONUS = 125
REACH_DIST_BONUS = BUILD_DIST_BONUS
RESOURCE_DIST_BONUS = 2

--------------------------------------------------------------------------------
-- Autofill Options
--------------------------------------------------------------------------------

AUTOFILL_TURRET_AMMO_QUANTITY = 10

--------------------------------------------------------------------------------
-- RSO Soft-Mod Configurations
-- Configure these to tweak the RSO values.
--------------------------------------------------------------------------------
-- CONFIGURE STUFF INSIDE rso_config.lua
-- RSO resources can be very lucky/unlucky...
-- don't complain if you can't find a resource.


--------------------------------------------------------------------------------
-- MAP CONFIGURATION OPTIONS
-- Configure these if you are running headless since there is no way to set
-- resources otherwise.
--------------------------------------------------------------------------------

-- Set this to true if you are creating the scenario at the cmd line.
CMD_LINE_MAP_GEN = true

-- Adjust settings here to set your map stuff.
-- "Sizes can be specified as none, very-low, low, normal, high, very-high"
global.clMapGen = {}
global.clMapGen.terrain_segmentation="normal"
global.clMapGen.water="normal"
global.clMapGen.starting_area="low"
global.clMapGen.peaceful_mode=false
global.clMapGen.seed=nil;
-- These are my go to default vanilla settings, it's not RSO, but it's okay.
global.clMapGen.autoplace_controls = {
    
    -- Resources and enemies only matter if you are NOT using RSO.
    ["coal"]={frequency="very-low", size= "low", richness= "high"},
    ["copper-ore"]={frequency= "very-low", size= "low", richness= "high"},
    ["crude-oil"]={frequency= "low", size= "low", richness= "high"},
    ["enemy-base"]={frequency= "low", size= "normal", richness= "normal"},
    ["iron-ore"]={frequency= "very-low", size= "low", richness= "high"},
    ["stone"]={frequency= "very-low", size= "low", richness= "high"},
    ["uranium-ore"]={frequency= "low", size= "low", richness= "high"},

    ["desert"]={frequency= "normal", size= "normal", richness= "normal"},
    ["dirt"]={frequency= "normal", size= "normal", richness= "normal"},
    ["grass"]={frequency= "normal", size= "normal", richness= "normal"},
    ["sand"]={frequency= "normal", size= "normal", richness= "normal"},
    ["trees"]={frequency= "normal", size= "normal", richness= "normal"}
}
-- Cliff defaults are 10 and 10, set both to 0 to turn cliffs off I think?
global.clMapGen.cliff_settings={cliff_elevation_0=10, cliff_elevation_interval=10, name="cliff"}

-------------------------------------------------------------------------------
-- DEBUG
--------------------------------------------------------------------------------

-- DEBUG prints for me
global.oarcDebugEnabled = false
