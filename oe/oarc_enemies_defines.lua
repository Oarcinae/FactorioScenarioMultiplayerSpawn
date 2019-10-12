-- oarc_enemies_defines.lua
-- Aug 2019
-- Some hard settings and general definitions and stuff.

-- Max number of ongoing attacks at any time.
OE_ATTACKS_MAX = 30

-- Max number of attacks when considering biter bases being destroyed.
OE_ATTACKS_MAX_RETALIATION = 150

-- Number of chunks around any building that don't allow enemy spawns.
OE_BUILDING_SAFE_AREA_RADIUS = 3

-- Timer backoff on destroyed buildings
-- Evo backoff on destroyed buildings
-- OE_BUILDING_DESTROYED_EVO_REDUCTION ??
-- OE_BUILDING_DESTROYED_TIMER_BACKOFF = ??

-- How far away can attacks start from.
OE_ATTACK_SEARCH_RADIUS_CHUNKS = 35

-- These are the types of targetted attacks that can be requested.
OE_TARGET_TYPE_PLAYER       = 1     -- Attack a player.
OE_TARGET_TYPE_AREA         = 2     -- Attacking a general area is used as a fallback.
OE_TARGET_TYPE_BUILDING     = 3     -- Attack a building of a certain type.
OE_TARGET_TYPE_DSTRYD       = 4     -- Attack areas where buildings are being destroyed (reinforce)
OE_TARGET_TYPE_ENTITY       = 5     -- Any attack on a specific entity. Like a retaliation attack.

-- This is the general flow of steps that an attack will go through
OE_PROCESS_STG_FIND_TARGET      = 0     -- First step is finding a target based on the request type.
OE_PROCESS_STG_FIND_SPAWN       = 1     -- Find a nearby spawn
OE_PROCESS_STG_SPAWN_PATH_REQ   = 2     -- Request a check if it's pathable FROM THE SPAWN POSITION
OE_PROCESS_STG_SPAWN_PATH_CALC  = 3     -- Pathing is pending from OE_PROCESS_STG_SPAWN_PATH_REQ
OE_PROCESS_STG_CREATE_GROUP     = 4     -- Create the group
OE_PROCESS_STG_CMD_GROUP        = 5     -- Command the group
OE_PROCESS_STG_GROUP_ACTIVE     = 6     -- Group is actively executing a command
OE_PROCESS_STG_CMD_FAILED       = 7     -- Group is now in a failed state, retry or fallback.
OE_PROCESS_STG_FALLBACK_ATTACK  = 8     -- Fallback to attacking local area
OE_PROCESS_STG_FALLBACK_FINAL   = 9     -- Final fallback is go autonomous
OE_PROCESS_STG_RETRY_PATH_REQ   = 10    -- This means we had a group, that failed during transit, so we want to retry path checks.
OE_PROCESS_STG_RETRY_PATH_CALC  = 11    -- Pathing is pending from OE_PROCESS_STG_RETRY_PATH_REQ
OE_PROCESS_STG_BUILD_BASE       = 12    -- Sometimes we build bases. Like if an attack was successful.

OE_GENERIC_TARGETS = {"ammo-turret",
                        "electric-turret",
                        "fluid-turret",
                        "artillery-turret",
                        "mining-drill",
                        "furnace",
                        "reactor",
                        "assembling-machine",
                        "generator"}