-- separate_spawns.lua
-- Nov 2016
--
-- Code that handles everything regarding giving each player a separate spawn
-- Includes the GUI stuff

require("lib/oarc_utils")
require("config")

local util = require("util")
local crash_site = require("crash-site")

---@enum BuddySpawnChoice
BUDDY_SPAWN_CHOICE = {
    join_main_team = 1,
    join_own_team = 2,
    join_buddy_team = 3,
}

--[[
 _   _   _  _     _______   _____ ___ ___
| | | | | |/_\   |_   _\ \ / / _ \ __/ __|
| |_| |_| / _ \    | |  \ V /|  _/ _|\__ \
|____\___/_/ \_\   |_|   |_| |_| |___|___/
--]]

---Contains the respawn point for a player. Usually this is their home base but it can be changed.
---@alias OarcPlayerSpawn { surface: string, position: MapPosition }
---Table of [OarcSharedSpawn](lua://OarcSharedSpawn) indexed by player name.
---@alias OarcPlayerSpawnsTable table<string, OarcPlayerSpawn>

---A unique spawn point. This is what chunk generation checks against.
---@alias OarcUniqueSpawn { surface: string, position: MapPosition, moat: boolean }
---Table of [OarcUniqueSpawn](lua://OarcUniqueSpawn) indexed by a unique name.
---@alias OarcUniqueSpawnsTable table<string, OarcUniqueSpawn>

---A shared spawn point. This is a spawn point that multiple players can share.
---@alias OarcSharedSpawn { surface: string, position: MapPosition, openAccess: boolean, players: string[], joinQueue: string[] }
---Table of [OarcSharedSpawn](lua://OarcSharedSpawn) indexed by a unique name.
---@alias OarcSharedSpawnsTable table<string, OarcSharedSpawn>

---Contains player ability cooldowns. Right now this only tracks changing the respawn ability.
---@alias OarcPlayerCooldown { setRespawn: number }
---Table of [OarcPlayerCooldown](lua://OarcPlayerCooldown) indexed by player name.
---@alias OarcPlayerCooldownsTable table<string, OarcPlayerCooldown>

---Temporary data used when spawning a player. Player needs to wait while the area is prepared.
---@alias OarcDelayedSpawn { playerName: string, surface: string, position: MapPosition, moat: boolean, delayedTick: number }
---Table of [OarcDelayedSpawn](lua://OarcDelayedSpawn) indexed by player name.
---@alias OarcDelayedSpawnsTable table<string, OarcDelayedSpawn>

---This contains information of who is being asked to buddy spawn, and what options were selected.
---@alias OarcBuddySpawnOpts { teamRadioSelection: BuddySpawnChoice, moatChoice: boolean, buddyChoice: string, distChoice: string }
---Table of [OarcBuddySpawnOpts](lua://OarcBuddySpawnOpts) indexed by player name.
---@alias OarcBuddySpawnOptsTable table<string, OarcBuddySpawnOpts>

---Table of players in the "waiting room" for a buddy spawn.
---@alias OarcWaitingBuddiesTable table<string>

--[[
  ___  _  _  ___  _____
 |_ _|| \| ||_ _||_   _|
  | | | .` | | |   | |
 |___||_|\_||___|  |_|

--]]

---Initializes the globals used to track the special spawn and player status information.
---@return nil
function InitSpawnGlobalsAndForces()
    -- Core global to help me organize shit.
    if (global.ocore == nil) then
        global.ocore = {}
    end

    -- TODO: Add a global for which surfaces allow spawns.

    -- This contains each player's spawn point. Literally where they will respawn.
    -- There is a way in game to change this under one of the little menu features I added.
    ---TODO: Add support for multiple surfaces!
    if (global.ocore.playerSpawns == nil) then
        global.ocore.playerSpawns --[[@as OarcPlayerSpawnsTable]] = {}
    end

    -- This is the most important table. It is a list of all the unique spawn points.
    -- This is what chunk generation checks against.
    if (global.ocore.uniqueSpawns == nil) then
        global.ocore.uniqueSpawns --[[@as OarcUniqueSpawnsTable]] = {}
    end

    -- List of available vanilla spawns
    -- TODO: Vanilla spawn point are not implemented yet.
    -- if (global.vanillaSpawns == nil) then
    --     global.vanillaSpawns = {}
    -- end

    -- This keeps a list of any player that has shared their base.
    -- Each entry contains information about if it's open, spawn pos, and players in the group.
    if (global.ocore.sharedSpawns == nil) then
        global.ocore.sharedSpawns --[[@as OarcSharedSpawnsTable]] = {}
    end

    -- Each player has an option to change their respawn which has a cooldown when used.
    -- Other similar abilities/functions that require cooldowns could be added here.
    if (global.ocore.playerCooldowns == nil) then
        global.ocore.playerCooldowns --[[@as OarcPlayerCooldownsTable]] = {}
    end

    -- List of players in the "waiting room" for a buddy spawn.
    -- They show up in the list to select when doing a buddy spawn.
    if (global.ocore.waitingBuddies == nil) then
        global.ocore.waitingBuddies --[[@as OarcWaitingBuddiesTable]] = {}
    end

    -- Players who have made a spawn choice get put into this list while waiting.
    -- An on_tick event checks when it expires and then places down the base resources, and teleports the player.
    -- Go look at DelayedSpawnOnTick() for more info.
    if (global.ocore.delayedSpawns == nil) then
        global.ocore.delayedSpawns --[[@as OarcDelayedSpawnsTable]] = {}
    end

    -- This is what I use to communicate a buddy spawn request between the buddies.
    -- This contains information of who is asking, and what options were selected.
    if (global.ocore.buddySpawnOpts == nil) then
        global.ocore.buddySpawnOpts --[[@as OarcBuddySpawnOptsTable]] = {}
    end

    -- Buddy info: The only real use is to check if one of a buddy pair is online to see if we should allow enemy
    -- attacks on the base.
    -- global.ocore.buddyPairs[player.name] = requesterName
    -- global.ocore.buddyPairs[requesterName] = player.name
    if (global.ocore.buddyPairs == nil) then
        global.ocore.buddyPairs --[[@as table<string, string>]] = {}
    end

    --- Table contains all the renders that need to be faded out over time in the on_tick event. They are removed when they expire.
    if (global.oarc_renders_fadeout == nil) then
        global.oarc_renders_fadeout --[[@as table<integer>]] = {}
    end

    -- Name a new force to be the default force.
    -- This is what any new player is assigned to when they join, even before they spawn.
    local main_force = CreateForce(global.ocfg.gameplay.main_force_name)
    main_force.set_spawn_position({ x = 0, y = 0 }, global.ocfg.gameplay.main_force_surface)

    -- Special forces for when players with their own force want a reset.
    global.ocore.abandoned_force = "_ABANDONED_"
    global.ocore.destroyed_force = "_DESTROYED_"
    game.create_force(global.ocore.abandoned_force)
    game.create_force(global.ocore.destroyed_force)
end

--[[
  ___  _       _ __   __ ___  ___     ___  ___  ___  ___  ___  ___  ___  ___
 | _ \| |     /_\\ \ / /| __|| _ \   / __|| _ \| __|/ __||_ _|| __||_ _|/ __|
 |  _/| |__  / _ \\ V / | _| |   /   \__ \|  _/| _|| (__  | | | _|  | || (__
 |_|  |____|/_/ \_\|_|  |___||_|_\   |___/|_|  |___|\___||___||_|  |___|\___|

--]]

-- When a new player is created, present the spawn options
-- Assign them to the main force so they can communicate with the team
-- without shouting.
---@param player_index integer
---@param clear_inv boolean If true, clear the player's inventory.
---@return nil
function SeparateSpawnsPlayerCreated(player_index, clear_inv)
    local player = game.players[player_index]

    -- Make sure spawn control tab is disabled
    SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_GUI_NAME, false)
    SwitchOarcGuiTab(player, OARC_GAME_OPTS_GUI_TAB_NAME)

    -- If they are a new player, put them on the main force.
    if (player.force.name == "player") then
        player.force = global.ocfg.gameplay.main_force_name
    end

    -- Ensure cleared inventory!
    -- if (clear_inv) then
    --     player.get_inventory(defines.inventory.character_main ).clear()
    --     player.get_inventory(defines.inventory.character_guns).clear()
    --     player.get_inventory(defines.inventory.character_ammo).clear()
    --     player.get_inventory(defines.inventory.character_armor).clear()
    --     player.get_inventory(defines.inventory.character_trash).clear()
    -- end

    HideOarcGui(player)
    DisplayWelcomeTextGui(player)
end

-- Check if the player has a different spawn point than the default one
-- Make sure to give the default starting items
---@param event EventData.on_player_respawned
---@return nil
function SeparateSpawnsPlayerRespawned(event)
    local player = game.players[event.player_index]
    SendPlayerToSpawn(player)
end

--[[
  ___  ___   _ __      __ _  _     ___  ___  _____  _   _  ___
 / __|| _ \ /_\\ \    / /| \| |   / __|| __||_   _|| | | || _ \
 \__ \|  _// _ \\ \/\/ / | .` |   \__ \| _|   | |  | |_| ||  _/
 |___/|_| /_/ \_\\_/\_/  |_|\_|   |___/|___|  |_|   \___/ |_|

--]]

---Adds a new [OarcSharedSpawn](lua://OarcSharedSpawn) to the global list of shared spawns.
---@param player LuaPlayer
---@return nil
function CreateNewSharedSpawn(player)
    global.ocore.sharedSpawns[player.name] --[[@as OarcSharedSpawn]] = {
        surface = global.ocore.playerSpawns[player.name].surface,
        position = global.ocore.playerSpawns[player.name].position,
        openAccess = true,
        players = {},
        joinQueue = {}
    }
end

-- Generate the basic starter resource around a given location.
---@param surface LuaSurface
---@param position TilePosition
---@return nil
function GenerateStartingResources(surface, position)
    local rand_settings = global.ocfg.spawn_config.resource_rand_pos_settings

    -- Generate all resource tile patches
    if (not rand_settings.enabled) then
        for r_name, r_data in pairs(global.ocfg.spawn_config.resource_tiles --[[@as table<string, OarcConfigResourceTiles>]]) do
            local pos = { x = position.x + r_data.x_offset, y = position.y + r_data.y_offset }
            GenerateResourcePatch(surface, r_name, r_data.size, pos, r_data.amount)
        end

        -- Generate resources in random order around the spawn point. Tweak in config.lua
    else
        -- Create list of resource tiles
        ---@type table<string>
        local r_list = {}
        for r_name,_ in pairs(global.ocfg.spawn_config.resource_tiles --[[@as table<string, OarcConfigResourceTiles>]]) do
            if (r_name ~= "") then
                table.insert(r_list, r_name)
            end
        end
        ---@type table<string>
        local shuffled_list = FYShuffle(r_list)

        -- This places resources in a semi-circle
        local angle_offset = rand_settings.angle_offset
        local num_resources = TableLength(global.ocfg.spawn_config.resource_tiles --[[@as table<string, OarcConfigResourceTiles>]])
        local theta = ((rand_settings.angle_final - rand_settings.angle_offset) / num_resources);
        local count = 0

        for _,r_name in pairs(shuffled_list) do
            local angle = (theta * count) + angle_offset;

            local tx = (rand_settings.radius * math.cos(angle)) + position.x
            local ty = (rand_settings.radius * math.sin(angle)) + position.y

            local pos = { x = math.floor(tx), y = math.floor(ty) }

            local resourceConfig = global.ocfg.spawn_config.resource_tiles[r_name]
            GenerateResourcePatch(surface, r_name, resourceConfig.size, pos, resourceConfig.amount)
            count = count + 1
        end
    end

    -- Generate special fluid resource patches (oil)
    for r_name, r_data in pairs(global.ocfg.spawn_config.resource_patches --[[@as table<string, OarcConfigResourcePatches>]]) do
        local oil_patch_x = position.x + r_data.x_offset_start
        local oil_patch_y = position.y + r_data.y_offset_start
        for i = 1, r_data.num_patches do
            surface.create_entity({
                name = r_name,
                amount = r_data.amount,
                position = { oil_patch_x, oil_patch_y }
            })
            oil_patch_x = oil_patch_x + r_data.x_offset_next
            oil_patch_y = oil_patch_y + r_data.y_offset_next
        end
    end
end

---Sends the player to their spawn point
---@param delayedSpawn OarcDelayedSpawn
---@return nil
function SendPlayerToNewSpawnAndCreateIt(delayedSpawn)
    local ocfg --[[@as OarcConfig]] = global.ocfg

    -- DOUBLE CHECK and make sure the area is super safe.
    ClearNearbyEnemies(delayedSpawn.position, ocfg.spawn_config.safe_area.safe_radius, game.surfaces[delayedSpawn.surface])

    -- TODO: Vanilla spawn point are not implemented yet.
    -- if (not delayedSpawn.vanilla) then

    -- Generate water strip only if we don't have a moat.
    if (not delayedSpawn.moat) then
        local water_data = ocfg.spawn_config.water
        CreateWaterStrip(game.surfaces[delayedSpawn.surface],
            { x = delayedSpawn.position.x + water_data.x_offset, y = delayedSpawn.position.y + water_data.y_offset },
            water_data.length)
        CreateWaterStrip(game.surfaces[delayedSpawn.surface],
            { x = delayedSpawn.position.x + water_data.x_offset, y = delayedSpawn.position.y + water_data.y_offset + 1 },
            water_data.length)
    end

    -- Create the spawn resources here
    GenerateStartingResources(game.surfaces[delayedSpawn.surface], delayedSpawn.position)

    -- end -- Vanilla spawn point are not implemented yet.

    -- Send the player to that position
    local player = game.players[delayedSpawn.playerName]
    SafeTeleport(player, game.surfaces[delayedSpawn.surface], delayedSpawn.position)
    GivePlayerStarterItems(player)

    -- Render some welcoming text...
    DisplayWelcomeGroundTextAtSpawn(player, delayedSpawn.surface, delayedSpawn.position)

    -- Chart the area.
    ChartArea(player.force, delayedSpawn.position, math.ceil(ocfg.spawn_config.general.land_area_tiles / CHUNK_SIZE),
        player.surface)

    if (player.gui.screen.wait_for_spawn_dialog ~= nil) then
        player.gui.screen.wait_for_spawn_dialog.destroy()
    end

    if (ocfg.starting_items.crashed_ship) then
        crash_site.create_crash_site(game.surfaces[delayedSpawn.surface],
            { x = delayedSpawn.position.x + 15, y = delayedSpawn.position.y - 25 },
            ocfg.starting_items.crashed_ship_resources,
            ocfg.starting_items.crashed_ship_wreakage)
    end
end

---Displays some welcoming text at the spawn point on the ground. Fades out over time.
---@param player LuaPlayer
---@param surface LuaSurface|string
---@param position MapPosition
---@return nil
function DisplayWelcomeGroundTextAtSpawn(player, surface, position)
    -- Render some welcoming text...
    local tcolor = { 0.9, 0.7, 0.3, 0.8 }
    local ttl = 2000
    local rid1 = rendering.draw_text { text = "Welcome",
        surface = surface,
        target = { x = position.x - 21, y = position.y - 15 },
        color = tcolor,
        scale = 20,
        font = "compi",
        time_to_live = ttl,
        -- players={player},
        draw_on_ground = true,
        orientation = 0,
        -- alignment=center,
        scale_with_zoom = false,
        only_in_alt_mode = false }
    local rid2 = rendering.draw_text { text = "Home",
        surface = surface,
        target = { x = position.x - 14, y = position.y - 5 },
        color = tcolor,
        scale = 20,
        font = "compi",
        time_to_live = ttl,
        -- players={player},
        draw_on_ground = true,
        orientation = 0,
        -- alignment=center,
        scale_with_zoom = false,
        only_in_alt_mode = false }

    table.insert(global.oarc_renders_fadeout, rid1)
    table.insert(global.oarc_renders_fadeout, rid2)
end

--[[
   ___  _  _  _   _  _  _  _  __     ___  ___  _  _  ___  ___    _  _____  ___  ___   _  _
  / __|| || || | | || \| || |/ /    / __|| __|| \| || __|| _ \  /_\|_   _||_ _|/ _ \ | \| |
 | (__ | __ || |_| || .` || ' <    | (_ || _| | .` || _| |   / / _ \ | |   | || (_) || .` |
  \___||_||_| \___/ |_|\_||_|\_\    \___||___||_|\_||___||_|_\/_/ \_\|_|  |___|\___/ |_|\_|

--]]

---Clear the spawn areas. This should be run inside the chunk generate event and be given a list of all
---unique spawn points. This clears enemies in the immediate area, creates a slightly safe area around it,
---Resources are generated at a delayed time when the player is moved to the spawn point!
---@param surface LuaSurface
---@param chunkArea BoundingBox
---@return nil
function SetupAndClearSpawnAreas(surface, chunkArea)
    local spawn_config --[[@as OarcConfigSpawn]] = global.ocfg.spawn_config

    for name, spawn in pairs(global.ocore.uniqueSpawns --[[@as OarcUniqueSpawnsTable]]) do
        if (spawn.surface ~= surface.name) then
            return
        end

        -- Create a bunch of useful area and position variables
        local landArea = GetAreaAroundPos(spawn.position, spawn_config.general.land_area_tiles + CHUNK_SIZE)
        -- local safeArea = GetAreaAroundPos(spawn.position, spawn_config.safe_area.safe_radius)
        -- local warningArea = GetAreaAroundPos(spawn.position, spawn_config.safe_area.warn_radius)
        -- local reducedArea = GetAreaAroundPos(spawn.position, spawn_config.safe_area.danger_radius)
        local chunkAreaCenter = {
            x = chunkArea.left_top.x + (CHUNK_SIZE / 2),
            y = chunkArea.left_top.y + (CHUNK_SIZE / 2)
        }
        local spawnPosOffset = {
            x = spawn.position.x + spawn_config.general.land_area_tiles,
            y = spawn.position.y + spawn_config.general.land_area_tiles
        }

        -- Make chunks near a spawn safe by removing enemies
        if (util.distance(spawn.position, chunkAreaCenter) < spawn_config.safe_area.safe_radius) then
            RemoveAliensInArea(surface, chunkArea)

            -- Create a warning area with heavily reduced enemies
        elseif (util.distance(spawn.position, chunkAreaCenter) < spawn_config.safe_area.warn_radius) then
            ReduceAliensInArea(surface, chunkArea, spawn_config.safe_area.warn_reduction)
            -- DowngradeWormsInArea(surface, chunkArea, 100, 100, 100)
            RemoveWormsInArea(surface, chunkArea, false, true, true, true) -- remove all non-small worms.

            -- Create a third area with moderatly reduced enemies
        elseif (util.distance(spawn.position, chunkAreaCenter) < spawn_config.safe_area.danger_radius) then
            ReduceAliensInArea(surface, chunkArea, spawn_config.safe_area.danger_reduction)
            -- DowngradeWormsInArea(surface, chunkArea, 50, 100, 100)
            RemoveWormsInArea(surface, chunkArea, false, false, true, true) -- remove all huge/behemoth worms.
        end

        -- TODO: Vanilla spawn point are not implemented yet.
        -- if (not spawn.vanilla) then

        local enable_test = global.ocfg.mod_overlap.enable_moat_bridging

        -- If the chunk is within the main land area, then clear trees/resources
        -- and create the land spawn areas (guaranteed land with a circle of trees)
        if CheckIfInArea(chunkAreaCenter, landArea) then
            -- Remove trees/resources inside the spawn area
            RemoveInCircle(surface, chunkArea, "tree", spawn.position, spawn_config.general.land_area_tiles)
            RemoveInCircle(surface, chunkArea, "resource", spawn.position, spawn_config.general.land_area_tiles + 5)
            RemoveInCircle(surface, chunkArea, "cliff", spawn.position, spawn_config.general.land_area_tiles + 5)

            local fill_tile = "landfill"
            if (spawn_config.general.tree_circle) then
                CreateCropCircle(surface, spawn.position, chunkArea, spawn_config.general.land_area_tiles, fill_tile)
            end
            if (spawn_config.general.tree_octagon) then
                CreateCropOctagon(surface, spawn.position, chunkArea, spawn_config.general.land_area_tiles, fill_tile)
            end
            -- TODO: Confirm removal of global setting check of enable_allow_moats_around_spawns is okay?
            if (spawn.moat) then
                CreateMoat(surface,
                    spawn.position,
                    chunkArea,
                    spawn_config.general.land_area_tiles,
                    "water",
                    global.ocfg.mod_overlap.enable_moat_bridging)
            end
        end

        -- end -- Vanilla spawn point are not implemented yet.
    end
end

---This is the main function that creates the spawn area. Provides resources, land and a safe zone.
---@param event EventData.on_chunk_generated
---@return nil
function SeparateSpawnsGenerateChunk(event)
    local surface = event.surface
    local chunkArea = event.area

    -- Modify enemies first.
    if global.ocfg.gameplay.oarc_modified_enemy_spawning then
        DowngradeWormsDistanceBasedOnChunkGenerate(event)
    end

    -- Downgrade resources near to spawns
    if global.ocfg.gameplay.scale_resources_around_spawns then
        DowngradeResourcesDistanceBasedOnChunkGenerate(surface, chunkArea)
    end

    -- This handles chunk generation near player spawns
    -- If it is near a player spawn, it does a few things like make the area
    -- safe and provide a guaranteed area of land and water tiles.
    SetupAndClearSpawnAreas(surface, chunkArea)
end

---Based on the danger distance, you get full resources, and it is exponential from the spawn point to that distance.
---@param surface LuaSurface
---@param chunkArea BoundingBox
---@return nil
function DowngradeResourcesDistanceBasedOnChunkGenerate(surface, chunkArea)
    local closestSpawn = GetClosestUniqueSpawn(surface, chunkArea.left_top)

    if (closestSpawn == nil) then return end

    local distance = util.distance(chunkArea.left_top, closestSpawn.position)
    -- Adjust multiplier to bring it in or out
    local modifier = (distance / (global.ocfg.spawn_config.safe_area.danger_radius * 1)) ^ 3
    if modifier < 0.1 then modifier = 0.1 end
    if modifier > 1 then return end

    local ore_per_tile_cap = math.floor(100000 * modifier)

    for key, entity in pairs(surface.find_entities_filtered { area = chunkArea, type = "resource" }) do
        if entity.valid and entity and entity.position and entity.amount then
            local new_amount = math.ceil(entity.amount * modifier)
            if (new_amount < 1) then
                entity.destroy()
            else
                if (entity.name ~= "crude-oil") then
                    entity.amount = math.min(new_amount, ore_per_tile_cap)
                else
                    entity.amount = new_amount
                end
            end
        end
    end
end

-- I wrote this to ensure everyone gets safer spawns regardless of evolution level.
-- This is intended to downgrade any biters/spitters spawning near player bases.
-- I'm not sure the performance impact of this but I'm hoping it's not bad.
---@param event EventData.on_entity_spawned|EventData.on_biter_base_built
---@return nil
function ModifyEnemySpawnsNearPlayerStartingAreas(event)
    if (not event.entity or not (event.entity.force.name == "enemy") or not event.entity.position) then
        log("ModifyBiterSpawns - Unexpected use.")
        return
    end

    local enemy_pos = event.entity.position
    local surface = event.entity.surface
    local enemy_name = event.entity.name

    local closest_spawn = GetClosestUniqueSpawn(surface, enemy_pos)

    if (closest_spawn == nil) then
        -- log("GetClosestUniqueSpawn ERROR - None found?")
        return
    end

    -- No enemies inside safe radius!
    if (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.spawn_config.safe_area.safe_radius) then
        event.entity.destroy()

        -- Warn distance is all SMALL only.
    elseif (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.spawn_config.safe_area.warn_radius) then
        if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter") or (enemy_name == "medium-biter")) then
            event.entity.destroy()
            surface.create_entity { name = "small-biter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded biter close to spawn.")
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter") or (enemy_name == "medium-spitter")) then
            event.entity.destroy()
            surface.create_entity { name = "small-spitter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded spitter close to spawn.")
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret") or (enemy_name == "medium-worm-turret")) then
            event.entity.destroy()
            surface.create_entity { name = "small-worm-turret", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded worm close to spawn.")
        end

        -- Danger distance is MEDIUM max.
    elseif (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.spawn_config.safe_area.danger_radius) then
        if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-biter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded biter further from spawn.")
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-spitter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded spitter further from spawn
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-worm-turret", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded worm further from spawn.")
        end
    end
end

--[[
   ___  _     ___    _    _  _  _   _  ___
  / __|| |   | __|  /_\  | \| || | | || _ \
 | (__ | |__ | _|  / _ \ | .` || |_| ||  _/
  \___||____||___|/_/ \_\|_|\_| \___/ |_|

--]]

---Resets the player and destroys their force if they are not on the main one.
---@param player LuaPlayer
---@return nil
function ResetPlayerAndDestroyForce(player)
    local player_old_force = player.force

    player.force = global.ocfg.gameplay.main_force_name

    if ((#player_old_force.players == 0) and (player_old_force.name ~= global.ocfg.gameplay.main_force_name)) then
        SendBroadcastMsg("Team " ..
            player_old_force.name .. " has been destroyed! All buildings will slowly be destroyed now.")
        log("DestroyForce - FORCE DESTROYED: " .. player_old_force.name)
        game.merge_forces(player_old_force, global.ocore.destroyed_force)
    end

    RemoveOrResetPlayer(player, false, false, true, true)
    SeparateSpawnsPlayerCreated(player.index, false)
end

---Resets the player and merges their force into the abandoned_force.
---@param player LuaPlayer
---@return nil
function ResetPlayerAndAbandonForce(player)
    local player_old_force = player.force

    player.force = global.ocfg.gameplay.main_force_name

    if ((#player_old_force.players == 0) and (player_old_force.name ~= global.ocfg.gameplay.main_force_name)) then
        SendBroadcastMsg("Team " .. player_old_force.name .. " has been abandoned!")
        log("AbandonForce - FORCE ABANDONED: " .. player_old_force.name)
        game.merge_forces(player_old_force, global.ocore.abandoned_force)
    end

    RemoveOrResetPlayer(player, false, false, false, false)
    SeparateSpawnsPlayerCreated(player.index, false)
end

---Reset player and merge their force to neutral
---@param player LuaPlayer
---@return nil
function ResetPlayerAndMergeForceToNeutral(player)
    RemoveOrResetPlayer(player, false, true, true, true)
    SeparateSpawnsPlayerCreated(player.index, true)
end

---Kicks player from game and marks player for removal from globals.
---@param player LuaPlayer
---@return nil
function KickAndMarkPlayerForRemoval(player)
    game.kick_player(player, "KickAndMarkPlayerForRemoval")
    if (not global.ocore.player_removal_list) then
        global.ocore.player_removal_list = {}
    end
    table.insert(global.ocore.player_removal_list, player)
end

---Call this if a player leaves the game early (or a player wants an early game reset)
---@param player LuaPlayer
---@param remove_player boolean Deletes player from the game assuming they are offline.
---@param remove_force boolean
---@param remove_base boolean
---@param immediate boolean
function RemoveOrResetPlayer(player, remove_player, remove_force, remove_base, immediate)
    if (not player) then
        log("ERROR - CleanupPlayer on NIL Player!")
        return
    end

    -- If this player is staying in the game, lets make sure we don't delete them along with the map chunks being
    -- cleared.
    player.teleport({ x = 0, y = 0 }, global.ocfg.gameplay.main_force_surface)
    local player_old_force = player.force
    player.force = global.ocfg.gameplay.main_force_name

    -- Clear globals
    CleanupPlayerGlobals(player.name) -- Except global.ocore.uniqueSpawns

    -- Clear their unique spawn (if they have one)
    UniqueSpawnCleanupRemove(player.name, remove_base, immediate) -- Specifically global.ocore.uniqueSpawns

    -- Remove a force if this player created it and they are the only one on it
    if (remove_force) then
        if ((#player_old_force.players == 0) and (player_old_force.name ~= global.ocfg.gameplay.main_force_name)) then
            log("RemoveOrResetPlayer - FORCE REMOVED: " .. player_old_force.name)
            game.merge_forces(player_old_force, "neutral")
        end
    end

    -- Remove the character completely
    if (remove_player) then
        game.remove_offline_players({ player })
    end
end

---Cleans up a player's unique spawn point.
---TODO: Move relevant stuff to regrowth?
---@param playerName string
---@param cleanup boolean
---@param immediate boolean Trrigger cleanup immediately.
---@return nil
function UniqueSpawnCleanupRemove(playerName, cleanup, immediate)
    if (global.ocore.uniqueSpawns[playerName] == nil) then return end -- Safety
    log("UniqueSpawnCleanupRemove - " .. playerName)

    local spawnPos = global.ocore.uniqueSpawns[playerName].pos
    local land_area_tiles = global.ocfg.spawn_config.general.land_area_tiles

    -- Check if it was near someone else's base. (Really just buddy base is possible I think.)
    nearOtherSpawn = false
    for spawnPlayerName, otherSpawnPos in pairs(global.ocore.uniqueSpawns) do
        if ((spawnPlayerName ~= playerName) and
                (util.distance(spawnPos, otherSpawnPos.pos) < (land_area_tiles * 3))) then
            log("Won't remove base as it's close to another spawn: " .. spawnPlayerName)
            nearOtherSpawn = true
        end
    end

    -- Unused Chunk Removal mod (aka regrowth)
    if (cleanup and global.ocfg.mod_overlap.enable_abandoned_base_cleanup and
            (not nearOtherSpawn) and global.ocfg.mod_overlap.enable_regrowth) then
        -- TODO: Vanilla spawn point are not implemented yet.
        -- if (global.ocore.uniqueSpawns[playerName].vanilla) then
        --     log("Returning a vanilla spawn back to available.")
        --     table.insert(global.vanillaSpawns, { x = spawnPos.x, y = spawnPos.y })
        -- end

        if (immediate) then
            log("IMMEDIATE Removing base: " .. spawnPos.x .. "," .. spawnPos.y)
            RegrowthMarkAreaForRemoval(spawnPos, math.ceil(land_area_tiles / CHUNK_SIZE))
            TriggerCleanup()
        else
            log("Removing permanent flags on base: " .. spawnPos.x .. "," .. spawnPos.y)
            RegrowthMarkAreaNotPermanentOVERWRITE(spawnPos,
                math.ceil(land_area_tiles / CHUNK_SIZE))
        end
    end

    global.ocore.uniqueSpawns[playerName] = nil
end

---Cleans up all references to a player in the global tables.
---@param playerName string
---@return nil
function CleanupPlayerGlobals(playerName)
    -- Clear the buddy pair IF one exists
    if (global.ocore.buddyPairs[playerName] ~= nil) then
        local buddyName = global.ocore.buddyPairs[playerName]
        global.ocore.buddyPairs[playerName] = nil
        global.ocore.buddyPairs[buddyName] = nil
    end

    -- Remove them from the buddy waiting list
    for index, name in pairs(global.ocore.waitingBuddies --[[@as OarcWaitingBuddiesTable]]) do
        if (name == playerName) then
            global.ocore.waitingBuddies[index] = nil
            break
        end
    end

    -- Clear buddy spawn options (should already be cleared, but just in case it isn't)
    if (global.ocore.buddySpawnOpts[playerName] ~= nil) then
        global.ocore.buddySpawnOpts[playerName] = nil
    end

    -- Transfer or remove a shared spawn if player is owner
    if (global.ocore.sharedSpawns[playerName] ~= nil) then
        local sharedSpawn = global.ocore.sharedSpawns[playerName] --[[@as OarcSharedSpawn]]
        local teamMates = sharedSpawn.players

        if (#teamMates >= 1) then
            local newOwnerName = table.remove(teamMates) -- Remove 1 to use as new owner.
            TransferOwnershipOfSharedSpawn(playerName, newOwnerName)
            SendBroadcastMsg(playerName .. "has left so " .. newOwnerName .. " now owns their base.")
        else
            global.ocore.sharedSpawns[playerName] = nil
        end
    end

    -- Remove from other shared spawns (need to search all)
    for _, sharedSpawn in pairs(global.ocore.sharedSpawns --[[@as OarcSharedSpawnsTable]]) do
        for key, name in pairs(sharedSpawn.players) do
            if (playerName == name) then
                sharedSpawn.players[key] = nil;
                goto LOOP_BREAK -- Nest loop break.
            end
        end
    end
    ::LOOP_BREAK::

    -- Clear their personal spawn point info
    if (global.ocore.playerSpawns[playerName] ~= nil) then
        global.ocore.playerSpawns[playerName] = nil
    end

    -- Remove them from the delayed spawn queue if they are in it
    for index, delayedSpawn in pairs(global.ocore.delayedSpawns --[[@as OarcDelayedSpawnsTable]]) do
        if (playerName == delayedSpawn.playerName) then
            ---TODO: Vanilla spawn point are not implemented yet.
            -- if (delayedSpawn.vanilla) then
            --     log("Returning a vanilla spawn back to available.")
            --     table.insert(global.vanillaSpawns, { x = delayedSpawn.pos.x, y = delayedSpawn.pos.y })
            -- end

            global.ocore.delayedSpawns[index] = nil
            log("Removing player from delayed spawn queue: " .. playerName)
            break
        end
    end

    if (global.ocore.playerCooldowns[playerName] ~= nil) then
        global.ocore.playerCooldowns[playerName] = nil
    end
end

---Transfers ownership of a shared spawn to another player.
---@param prevOwnerName string
---@param newOwnerName string
---@return nil
function TransferOwnershipOfSharedSpawn(prevOwnerName, newOwnerName)
    -- Transfer the shared spawn global
    global.ocore.sharedSpawns[newOwnerName] = global.ocore.sharedSpawns[prevOwnerName] --[[@as OarcSharedSpawn]]
    global.ocore.sharedSpawns[newOwnerName].openAccess = false
    global.ocore.sharedSpawns[prevOwnerName] = nil

    -- Transfer the unique spawn global
    global.ocore.uniqueSpawns[newOwnerName] = global.ocore.uniqueSpawns[prevOwnerName] --[[@as OarcUniqueSpawn]]
    global.ocore.uniqueSpawns[prevOwnerName] = nil

    game.players[newOwnerName].print("You have been given ownership of this base!")
end

--[[
  _  _  ___  _     ___  ___  ___     ___  _____  _   _  ___  ___
 | || || __|| |   | _ \| __|| _ \   / __||_   _|| | | || __|| __|
 | __ || _| | |__ |  _/| _| |   /   \__ \  | |  | |_| || _| | _|
 |_||_||___||____||_|  |___||_|_\   |___/  |_|   \___/ |_|  |_|

--]]

---Same as GetClosestPosFromTable but specific to global.ocore.uniqueSpawns
---@param surface LuaSurface
---@param pos MapPosition
---@return OarcUniqueSpawn?
function GetClosestUniqueSpawn(surface, pos)
    local closest_dist = nil
    local closest_key = nil

    for k, s in pairs(global.ocore.uniqueSpawns --[[@as OarcUniqueSpawnsTable]]) do
        if (s.surface ~= surface.name) then
            goto CONTINUE
        end

        local new_dist = util.distance(pos, s.position)
        if (closest_dist == nil) then
            closest_dist = new_dist
            closest_key = k
        elseif (closest_dist > new_dist) then
            closest_dist = new_dist
            closest_key = k
        end

        ::CONTINUE:: -- Continue loop label
    end

    if (closest_key == nil) then
        -- log("GetClosestUniqueSpawn ERROR - None found?")
        return nil
    end

    return global.ocore.uniqueSpawns[closest_key]
end

---Return the owner of the shared spawn for this player. May return nil if player has not spawned yet.
---@param playerName string
---@return string?
function FindPlayerSharedSpawn(playerName)
    -- If the player IS an owner, he can't be in any other shared base.
    if (global.ocore.sharedSpawns[playerName] ~= nil) then
        return playerName
    end

    -- Otherwise, search all shared spawns for this player and return the owner.
    for ownerName, sharedSpawn in pairs(global.ocore.sharedSpawns --[[@as OarcSharedSpawnsTable]]) do
        for _, sharingPlayerName in pairs(sharedSpawn.players) do
            if (playerName == sharingPlayerName) then
                return ownerName
            end
        end
    end

    -- Lastly, return nil if not found. Means player hasn't been assigned a base yet.
    return nil
end

---Returns the number of players currently online at the shared spawn
---@param ownerName string
---@return number
function GetOnlinePlayersAtSharedSpawn(ownerName)
    local sharedSpawn = global.ocore.sharedSpawns[ownerName] --[[@as OarcSharedSpawn]]

    if (sharedSpawn ~= nil) then
        -- Does not count base owner
        local count = 0

        -- For each player in the shared spawn, check if online and add to count.
        for _, player in pairs(game.connected_players) do
            if (ownerName == player.name) then
                count = count + 1
            end


            for _, playerName in pairs(sharedSpawn.players) do
                if (playerName == player.name) then
                    count = count + 1
                end
            end
        end

        return count
    else
        return 0
    end
end

-- Get the number of currently available shared spawns.
-- This means the base owner has enabled access AND the number of online players
-- is below the threshold.
---@return number
function GetNumberOfAvailableSharedSpawns()
    local count = 0

    local number_of_players_per_shared_spawn = global.ocfg.mod_overlap.number_of_players_per_shared_spawn

    for ownerName, sharedSpawn in pairs(global.ocore.sharedSpawns --[[@as OarcSharedSpawnsTable]]) do
        if (sharedSpawn.openAccess and
                (game.players[ownerName] ~= nil) and
                game.players[ownerName].connected) then
            if ((number_of_players_per_shared_spawn == 0) or
                    (#global.ocore.sharedSpawns[ownerName].players < number_of_players_per_shared_spawn)) then
                count = count + 1
            end
        end
    end

    return count
end

---Checks if player has a custom spawn point set.
---@param player LuaPlayer
---@return boolean
function DoesPlayerHaveCustomSpawn(player)
    for name, spawnPos in pairs(global.ocore.playerSpawns --[[@as OarcPlayerSpawnsTable]]) do
        if (player.name == name) then
            return true
        end
    end
    return false
end

---Gets the custom spawn point for a player if they have one.
---@param player LuaPlayer
---@return OarcPlayerSpawn?
function GetPlayerCustomSpawn(player)
    for name, playerSpawn in pairs(global.ocore.playerSpawns --[[@as OarcPlayerSpawnsTable]]) do
        if (player.name == name) then
            return playerSpawn
        end
    end
    return nil
end

---Sets the custom spawn point for a player.
---@param player LuaPlayer
---@param surface string
---@param position MapPosition
---@return nil
function ChangePlayerSpawn(player, surface, position)

    ---@type OarcPlayerSpawn
    local updatedPlayerSpawn = {}
    updatedPlayerSpawn.surface = surface
    updatedPlayerSpawn.position = position

    global.ocore.playerSpawns[player.name] = updatedPlayerSpawn
    global.ocore.playerCooldowns[player.name] = { setRespawn = game.tick }
end

---Queue a player for a delayed spawn.
---@param playerName string
---@param surface string
---@param spawnPosition MapPosition
---@param moatEnabled boolean
---@param vanillaSpawn boolean
---@return nil
function QueuePlayerForDelayedSpawn(playerName, surface, spawnPosition, moatEnabled, vanillaSpawn)
    -- If we get a valid spawn point, setup the area
    if ((spawnPosition.x ~= 0) or (spawnPosition.y ~= 0)) then
        ---@type OarcUniqueSpawn
        local newUniqueSpawn = {}
        newUniqueSpawn.surface = surface
        newUniqueSpawn.position = spawnPosition
        newUniqueSpawn.moat = moatEnabled

        ---TODO: Vanilla spawn point are not implemented yet.
        -- newUniqueSpawn.vanilla = vanillaSpawn
        global.ocore.uniqueSpawns[playerName] = newUniqueSpawn

        local delay_spawn_seconds = 5 * (math.ceil(global.ocfg.spawn_config.general.land_area_tiles / CHUNK_SIZE))

        ---TODO: Move text to locale.
        game.players[playerName].print("Generating your spawn now, please wait for at least " ..
            delay_spawn_seconds .. " seconds...")
        game.surfaces[surface].request_to_generate_chunks(spawnPosition, 4)


        ---@type OarcDelayedSpawn
        local delayedSpawn = {}
        delayedSpawn.playerName = playerName
        delayedSpawn.surface = surface
        delayedSpawn.position = spawnPosition
        delayedSpawn.moat = moatEnabled
        delayedSpawn.delayedTick = game.tick + delay_spawn_seconds * TICKS_PER_SECOND

        table.insert(global.ocore.delayedSpawns, delayedSpawn)

        HideOarcGui(game.players[playerName])
        DisplayPleaseWaitForSpawnDialog(game.players[playerName], delay_spawn_seconds)

        RegrowthMarkAreaSafeGivenTilePos(spawnPosition,
            math.ceil(global.ocfg.spawn_config.general.land_area_tiles / CHUNK_SIZE), true)
    else
        log("THIS SHOULD NOT EVER HAPPEN! Spawn failed!")
        SendBroadcastMsg("ERROR!! Failed to create spawn point for: " .. playerName)
    end
end

-- Check a table to see if there are any players waiting to spawn
-- Check if we are past the delayed tick count
-- Spawn the players and remove them from the table.
---@return nil
function DelayedSpawnOnTick()
    if ((game.tick % (30)) == 1) then
        if ((global.ocore.delayedSpawns ~= nil) and (#global.ocore.delayedSpawns > 0)) then

            --TODO: Investigate this magic indexing with ints and keys?
            -- I think this loop removes from the back of the table to the front??
            for i = #global.ocore.delayedSpawns, 1, -1 do
                delayedSpawn = global.ocore.delayedSpawns[i] --[[@as OarcDelayedSpawn]]

                if (delayedSpawn.delayedTick < game.tick) then
                    -- TODO: add check here for if chunks around spawn are generated surface.is_chunk_generated(chunkPos)
                    if (game.players[delayedSpawn.playerName] ~= nil) then
                        SendPlayerToNewSpawnAndCreateIt(delayedSpawn)
                    end
                    table.remove(global.ocore.delayedSpawns, i)
                end
            end
        end
    end
end

---Send player to their custom spawn point if one exists, otherwise to the force's spawn point.
---@param player LuaPlayer
---@return nil
function SendPlayerToSpawn(player)
    local playerSpawn = GetPlayerCustomSpawn(player)
    if (playerSpawn ~= nil) then
        SafeTeleport(player,
            game.surfaces[playerSpawn.surface],
            playerSpawn.position)
    else
        local gameplayConfig = global.ocfg.gameplay --[[@as OarcConfigGameplaySettings]]
        SafeTeleport(player,
        game.surfaces[gameplayConfig.main_force_surface],
            game.forces[gameplayConfig.main_force_name].get_spawn_position(gameplayConfig.main_force_surface))
    end
end

---Send player to a random spawn point.
---@param player LuaPlayer
---@return nil
function SendPlayerToRandomSpawn(player)
    local numSpawns = TableLength(global.ocore.uniqueSpawns)
    local rndSpawn = math.random(0, numSpawns)
    local counter = 0

    if (rndSpawn == 0) then
        local gameplayConfig = global.ocfg.gameplay --[[@as OarcConfigGameplaySettings]]
        player.teleport(game.forces[gameplayConfig.main_force_name].get_spawn_position(gameplayConfig.main_force_surface), gameplayConfig.main_force_surface)
    else
        counter = counter + 1
        for name, spawn in pairs(global.ocore.uniqueSpawns --[[@as OarcUniqueSpawnsTable]]) do
            if (counter == rndSpawn) then
                player.teleport(spawn.position)
                break
            end
            counter = counter + 1
        end
    end
end

--[[
  ___  ___   ___   ___  ___     ___  ___  ___  ___  ___  ___  ___  ___
 | __|/ _ \ | _ \ / __|| __|   / __|| _ \| __|/ __||_ _|| __||_ _|/ __|
 | _|| (_) ||   /| (__ | _|    \__ \|  _/| _|| (__  | | | _|  | || (__
 |_|  \___/ |_|_\ \___||___|   |___/|_|  |___|\___||___||_|  |___|\___|

--]]


---Create a new force
---@param force_name string
---@return LuaForce
function CreateForce(force_name)
    local newForce = nil

    -- Check if force already exists
    if (game.forces[force_name] ~= nil) then
        log("Force already exists!")
        return CreateForce(force_name .. "_") -- Append a character to make the force name unique.

        -- Create a new force
    elseif (TableLength(game.forces) < MAX_FORCES) then
        newForce = game.create_force(force_name)
        if global.ocfg.mod_overlap.enable_shared_team_vision then
            newForce.share_chart = true
        end

        -- This now defaults to true?
        -- if global.ocfg.enable_research_queue then
        --     newForce.research_queue_enabled = true
        -- end


        SetCeaseFireBetweenAllForces()
        SetFriendlyBetweenAllForces()

        newForce.friendly_fire = global.ocfg.mod_overlap.enable_friendly_fire

        -- if (global.ocfg.enable_anti_grief) then
        --     AntiGriefing(newForce)
        -- end

    else
        log("TOO MANY FORCES!!! - CreateForce()")
        return game.forces[global.ocfg.gameplay.main_force_name]
    end

    -- Add productivity bonus for solo teams.
    -- if (ENABLE_FORCE_LAB_PROD_BONUS) then
    --     local tech_mult = game.difficulty_settings.technology_price_multiplier
    --     if (tech_mult > 1) and (force_name ~= global.ocfg.main_force) then
    --         newForce.laboratory_productivity_bonus = (tech_mult - 1)
    --     end
    -- end

    -- Loot distance buff
    -- newForce.character_loot_pickup_distance_bonus = 16

    return newForce
end

---Create a new player force and assign the player to it.
---@param player LuaPlayer
---@return LuaForce
function CreatePlayerCustomForce(player)
    local newForce = CreateForce(player.name)
    player.force = newForce

    if (newForce.name == player.name) then
        SendBroadcastMsg(player.name .. " has started their own team!")
    else
        player.print("Sorry, no new teams can be created. You were assigned to the default team instead.")
    end

    return newForce
end

--[[
 __   __ _    _  _  ___  _     _       _     ___  ___   _ __      __ _  _  ___
 \ \ / //_\  | \| ||_ _|| |   | |     /_\   / __|| _ \ /_\\ \    / /| \| |/ __|
  \ V // _ \ | .` | | | | |__ | |__  / _ \  \__ \|  _// _ \\ \/\/ / | .` |\__ \
   \_//_/ \_\|_|\_||___||____||____|/_/ \_\ |___/|_| /_/ \_\\_/\_/  |_|\_||___/

--]]

-- Function to generate some map_gen_settings.starting_points
-- You should only use this at the start of the game really.
-- function CreateVanillaSpawns(count, spacing)
--     local points = {}

--     -- Get an ODD number from the square of the input count.
--     -- Always rounding up so we don't end up with less points that requested.
--     local sqrt_count = math.ceil(math.sqrt(count))
--     if (sqrt_count % 2 == 0) then
--         sqrt_count = sqrt_count + 1
--     end

--     -- Need to know how much to offset the grid.
--     local sqrt_half = math.floor((sqrt_count - 1) / 2)

--     if (sqrt_count < 1) then
--         log("CreateVanillaSpawns less than 1!!")
--         return
--     end

--     if (global.vanillaSpawns == nil) then
--         global.vanillaSpawns = {}
--     end

--     -- This should give me points centered around 0,0 I think.
--     for i = -sqrt_half, sqrt_half, 1 do
--         for j = -sqrt_half, sqrt_half, 1 do
--             if (i ~= 0 or j ~= 0) then -- EXCEPT don't put 0,0
--                 local x_pos = (i * spacing)
--                 x_pos = x_pos - (x_pos % CHUNK_SIZE) + (CHUNK_SIZE / 2)
--                 local y_pos = (j * spacing)
--                 y_pos = y_pos - (y_pos % CHUNK_SIZE) + (CHUNK_SIZE / 2)

--                 table.insert(points, { x = x_pos, y = y_pos })
--                 table.insert(global.vanillaSpawns, { x = x_pos, y = y_pos })
--             end
--         end
--     end

--     -- Do something with the return value.
--     return points
-- end

-- -- Useful when combined with something like CreateVanillaSpawns
-- -- Where it helps ensure ALL chunks generated use new map_gen_settings.
-- function DeleteAllChunksExceptCenter(surface)
--     -- Delete the starting chunks that make it into the game before settings are changed.
--     for chunk in surface.get_chunks() do
--         -- Don't delete the chunk that might contain players lol.
--         -- This is really only a problem for launching AS the host. Not headless
--         if ((chunk.x ~= 0) and (chunk.y ~= 0)) then
--             surface.delete_chunk({ chunk.x, chunk.y })
--         end
--     end
-- end

-- -- Find a vanilla spawn as close as possible to the given target_distance
-- function FindUnusedVanillaSpawn(surface, target_distance)
--     local best_key = nil
--     local best_distance = nil

--     for k, v in pairs(global.vanillaSpawns) do
--         -- Check if chunks nearby are not generated.
--         local chunk_pos = GetChunkPosFromTilePos(v)
--         if IsChunkAreaUngenerated(chunk_pos, CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS, surface) then
--             -- Is this our first valid find?
--             if ((best_key == nil) or (best_distance == nil)) then
--                 best_key = k
--                 best_distance = math.abs(math.sqrt((v.x ^ 2) + (v.y ^ 2)) - target_distance)

--                 -- Check if it is closer to target_distance than previous option.
--             else
--                 local new_distance = math.abs(math.sqrt((v.x ^ 2) + (v.y ^ 2)) - target_distance)
--                 if (new_distance < best_distance) then
--                     best_key = k
--                     best_distance = new_distance
--                 end
--             end

--             -- If it's not a valid spawn anymore, let's remove it.
--         else
--             log("Removing vanilla spawn due to chunks generated: x=" .. v.x .. ",y=" .. v.y)
--             table.remove(global.vanillaSpawns, k)
--         end
--     end

--     local spawn_pos = { x = 0, y = 0 }
--     if ((best_key ~= nil) and (global.vanillaSpawns[best_key] ~= nil)) then
--         spawn_pos.x = global.vanillaSpawns[best_key].x
--         spawn_pos.y = global.vanillaSpawns[best_key].y
--         table.remove(global.vanillaSpawns, best_key)
--     end
--     log("Found unused vanilla spawn: x=" .. spawn_pos.x .. ",y=" .. spawn_pos.y)
--     return spawn_pos
-- end

-- function ValidateVanillaSpawns(surface)
--     for k, v in pairs(global.vanillaSpawns) do
--         -- Check if chunks nearby are not generated.
--         local chunk_pos = GetChunkPosFromTilePos(v)
--         if not IsChunkAreaUngenerated(chunk_pos, CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS + 15, surface) then
--             log("Removing vanilla spawn due to chunks generated: x=" .. v.x .. ",y=" .. v.y)
--             table.remove(global.vanillaSpawns, k)
--         end
--     end
-- end
