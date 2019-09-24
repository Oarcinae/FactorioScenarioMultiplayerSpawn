-- oarc_utils.lua
-- Nov 2016
--
-- My general purpose utility functions for factorio
-- Also contains some constants and gui styles

require("lib/oarc_gui_utils")
require("mod-gui")

--------------------------------------------------------------------------------
-- Useful constants
--------------------------------------------------------------------------------
CHUNK_SIZE = 32
MAX_FORCES = 64
TICKS_PER_SECOND = 60
TICKS_PER_MINUTE = TICKS_PER_SECOND * 60
TICKS_PER_HOUR = TICKS_PER_MINUTE * 60
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- General Helper Functions
--------------------------------------------------------------------------------

-- Prints flying text.
-- Color is optional
function FlyingText(msg, pos, color, surface)
    if color == nil then
        surface.create_entity({ name = "flying-text", position = pos, text = msg })
    else
        surface.create_entity({ name = "flying-text", position = pos, text = msg, color = color })
    end
end

-- Broadcast messages to all connected players
function SendBroadcastMsg(msg)
    for name,player in pairs(game.connected_players) do
        player.print(msg)
    end
end

-- Send a message to a player, safely checks if they exist and are online.
function SendMsg(playerName, msg)
    if ((game.players[playerName] ~= nil) and (game.players[playerName].connected)) then
        game.players[playerName].print(msg)
    end
end

-- Simple way to write to a file. Always appends. Only server.
-- Has a global setting for enable/disable
function ServerWriteFile(filename, msg)
    if (global.ocfg.enable_server_write_files) then
        game.write_file(filename, msg, true, 0)
    end
end

-- Useful for displaying game time in mins:secs format
function formattime(ticks)
  local seconds = ticks / 60
  local minutes = math.floor((seconds)/60)
  local seconds = math.floor(seconds - 60*minutes)
  return string.format("%dm:%02ds", minutes, seconds)
end

-- Useful for displaying game time in mins:secs format
function formattime_hours_mins(ticks)
  local seconds = ticks / 60
  local minutes = math.floor((seconds)/60)
  local hours   = math.floor((minutes)/60)
  local minutes = math.floor(minutes - 60*hours)
  return string.format("%dh:%02dm", hours, minutes)
end

-- Simple function to get total number of items in table
function TableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- Fisher-Yares shuffle
-- https://stackoverflow.com/questions/35572435/how-do-you-do-the-fisher-yates-shuffle-in-lua
function FYShuffle(tInput)
    local tReturn = {}
    for i = #tInput, 1, -1 do
        local j = math.random(i)
        tInput[i], tInput[j] = tInput[j], tInput[i]
        table.insert(tReturn, tInput[i])
    end
    return tReturn
end

-- Simple function to get distance between two positions.
function getDistance(posA, posB)
    -- Get the length for each of the components x and y
    local xDist = posB.x - posA.x
    local yDist = posB.y - posA.y

    return math.sqrt( (xDist ^ 2) + (yDist ^ 2) )
end

-- Given a table of positions, returns key for closest to given pos.
function GetClosestPosFromTable(pos, pos_table)

    local closest_dist = nil
    local closest_key = nil

    for k,p in pairs(pos_table) do
        local new_dist = getDistance(pos, p)
        if (closest_dist == nil) then
            closest_dist = new_dist
            closest_key = k
        elseif (closest_dist > new_dist) then
            closest_dist = new_dist
            closest_key = k
        end
    end
end

-- Chart area for a force
function ChartArea(force, position, chunkDist, surface)
    force.chart(surface,
        {{position.x-(CHUNK_SIZE*chunkDist),
        position.y-(CHUNK_SIZE*chunkDist)},
        {position.x+(CHUNK_SIZE*chunkDist),
        position.y+(CHUNK_SIZE*chunkDist)}})
end

-- Give player these default items.
function GivePlayerItems(player)
    for _,item in pairs(PLAYER_RESPAWN_START_ITEMS) do
        player.insert(item)
    end
end

-- Starter only items
function GivePlayerStarterItems(player)
    for _,item in pairs(PLAYER_SPAWN_START_ITEMS) do
        player.insert(item)
    end

    if ENABLE_POWER_ARMOR_QUICK_START then
        GiveQuickStartPowerArmor(player)
    end
end

-- Cheater's quick start
function GiveQuickStartPowerArmor(player)
    player.insert{name="power-armor", count = 1}

    if player and player.get_inventory(defines.inventory.character_armor) ~= nil and player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
        local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
            if p_armor ~= nil then
                  p_armor.put({name = "fusion-reactor-equipment"})
                  p_armor.put({name = "exoskeleton-equipment"})
                  p_armor.put({name = "battery-mk2-equipment"})
                  p_armor.put({name = "battery-mk2-equipment"})
                  p_armor.put({name = "personal-roboport-mk2-equipment"})
                  p_armor.put({name = "personal-roboport-mk2-equipment"})
                  p_armor.put({name = "personal-roboport-mk2-equipment"})
                  p_armor.put({name = "battery-mk2-equipment"})
                  p_armor.put({name = "solar-panel-equipment"})
                  p_armor.put({name = "solar-panel-equipment"})
                  p_armor.put({name = "solar-panel-equipment"})
                  p_armor.put({name = "solar-panel-equipment"})
                  p_armor.put({name = "solar-panel-equipment"})
                  p_armor.put({name = "solar-panel-equipment"})
                  p_armor.put({name = "solar-panel-equipment"})
            end
        player.insert{name="construction-robot", count = 100}
        player.insert{name="belt-immunity-equipment", count = 1}
    end
end

-- Create area given point and radius-distance
function GetAreaFromPointAndDistance(point, dist)
    local area = {left_top=
                    {x=point.x-dist,
                     y=point.y-dist},
                  right_bottom=
                    {x=point.x+dist,
                     y=point.y+dist}}
    return area
end

-- Check if given position is in area bounding box
function CheckIfInArea(point, area)
    if ((point.x >= area.left_top.x) and (point.x < area.right_bottom.x)) then
        if ((point.y >= area.left_top.y) and (point.y < area.right_bottom.y)) then
            return true
        end
    end
    return false
end

-- Set all forces to ceasefire
function SetCeaseFireBetweenAllForces()
    for name,team in pairs(game.forces) do
        if name ~= "neutral" and name ~= "enemy" then
            for x,y in pairs(game.forces) do
                if x ~= "neutral" and x ~= "enemy" then
                    team.set_cease_fire(x,true)
                end
            end
        end
    end
end

-- Set all forces to friendly
function SetFriendlyBetweenAllForces()
    for name,team in pairs(game.forces) do
        if name ~= "neutral" and name ~= "enemy" then
            for x,y in pairs(game.forces) do
                if x ~= "neutral" and x ~= "enemy" then
                    team.set_friend(x,true)
                end
            end
        end
    end
end

-- For each other player force, share a chat msg.
function ShareChatBetweenForces(player, msg)
    for _,force in pairs(game.forces) do
        if (force ~= nil) then
            if ((force.name ~= enemy) and
                (force.name ~= neutral) and
                (force.name ~= player) and
                (force ~= player.force)) then
                force.print(player.name..": "..msg)
            end
        end
    end
end

-- Merges force2 INTO force1 but keeps all research between both forces.
function MergeForcesKeepResearch(force1, force2)
    for techName,luaTech in pairs(force2.technologies) do
        if (luaTech.researched) then
           force1.technologies[techName].researched = true
           force1.technologies[techName].level = luaTech.level
        end
    end
    game.merge_forces(force2, force1)
end

-- Undecorator
function RemoveDecorationsArea(surface, area)
    surface.destroy_decoratives{area=area}
end

-- Remove fish
function RemoveFish(surface, area)
    for _, entity in pairs(surface.find_entities_filtered{area = area, type="fish"}) do
        entity.destroy()
    end
end

-- Get a random 1 or -1
function RandomNegPos()
    if (math.random(0,1) == 1) then
        return 1
    else
        return -1
    end
end

-- Create a random direction vector to look in
function GetRandomVector()
    local randVec = {x=0,y=0}
    while ((randVec.x == 0) and (randVec.y == 0)) do
        randVec.x = math.random(-3,3)
        randVec.y = math.random(-3,3)
    end
    log("direction: x=" .. randVec.x .. ", y=" .. randVec.y)
    return randVec
end

-- Check for ungenerated chunks around a specific chunk
-- +/- chunkDist in x and y directions
function IsChunkAreaUngenerated(chunkPos, chunkDist, surface)
    for x=-chunkDist, chunkDist do
        for y=-chunkDist, chunkDist do
            local checkPos = {x=chunkPos.x+x,
                             y=chunkPos.y+y}
            if (surface.is_chunk_generated(checkPos)) then
                return false
            end
        end
    end
    return true
end

-- Clear out enemies around an area with a certain distance
function ClearNearbyEnemies(pos, safeDist, surface)
    local safeArea = {left_top=
                    {x=pos.x-safeDist,
                     y=pos.y-safeDist},
                  right_bottom=
                    {x=pos.x+safeDist,
                     y=pos.y+safeDist}}

    for _, entity in pairs(surface.find_entities_filtered{area = safeArea, force = "enemy"}) do
        entity.destroy()
    end
end

-- Function to find coordinates of ungenerated map area in a given direction
-- starting from the center of the map
function FindMapEdge(directionVec, surface)
    local position = {x=0,y=0}
    local chunkPos = {x=0,y=0}

    -- Keep checking chunks in the direction of the vector
    while(true) do

        -- Set some absolute limits.
        if ((math.abs(chunkPos.x) > 1000) or (math.abs(chunkPos.y) > 1000)) then
            break

        -- If chunk is already generated, keep looking
        elseif (surface.is_chunk_generated(chunkPos)) then
            chunkPos.x = chunkPos.x + directionVec.x
            chunkPos.y = chunkPos.y + directionVec.y

        -- Found a possible ungenerated area
        else

            chunkPos.x = chunkPos.x + directionVec.x
            chunkPos.y = chunkPos.y + directionVec.y

            -- Check there are no generated chunks in a 10x10 area.
            if IsChunkAreaUngenerated(chunkPos, 10, surface) then
                position.x = (chunkPos.x*CHUNK_SIZE) + (CHUNK_SIZE/2)
                position.y = (chunkPos.y*CHUNK_SIZE) + (CHUNK_SIZE/2)
                break
            end
        end
    end

    -- log("spawn: x=" .. position.x .. ", y=" .. position.y)
    return position
end

-- Find random coordinates within a given distance away
-- maxTries is the recursion limit basically.
function FindUngeneratedCoordinates(minDistChunks, maxDistChunks, surface)
    local position = {x=0,y=0}
    local chunkPos = {x=0,y=0}

    local maxTries = 100
    local tryCounter = 0

    local minDistSqr = minDistChunks^2
    local maxDistSqr = maxDistChunks^2

    while(true) do
        chunkPos.x = math.random(0,maxDistChunks) * RandomNegPos()
        chunkPos.y = math.random(0,maxDistChunks) * RandomNegPos()

        local distSqrd = chunkPos.x^2 + chunkPos.y^2

        -- Enforce a max number of tries
        tryCounter = tryCounter + 1
        if (tryCounter > maxTries) then
            log("FindUngeneratedCoordinates - Max Tries Hit!")
            break

        -- Check that the distance is within the min,max specified
        elseif ((distSqrd < minDistSqr) or (distSqrd > maxDistSqr)) then
            -- Keep searching!

        -- Check there are no generated chunks in a 10x10 area.
        elseif IsChunkAreaUngenerated(chunkPos, CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS, surface) then
            position.x = (chunkPos.x*CHUNK_SIZE) + (CHUNK_SIZE/2)
            position.y = (chunkPos.y*CHUNK_SIZE) + (CHUNK_SIZE/2)
            break -- SUCCESS
        end
    end

    log("spawn: x=" .. position.x .. ", y=" .. position.y)
    return position
end

-- General purpose function for removing a particular recipe
function RemoveRecipe(force, recipeName)
    local recipes = force.recipes
    if recipes[recipeName] then
        recipes[recipeName].enabled = false
    end
end

-- General purpose function for adding a particular recipe
function AddRecipe(force, recipeName)
    local recipes = force.recipes
    if recipes[recipeName] then
        recipes[recipeName].enabled = true
    end
end

-- General command for disabling a tech.
function DisableTech(force, techName)
    if force.technologies[techName] then
        force.technologies[techName].enabled = false
        force.technologies[techName].visible_when_disabled = true
    end
end

-- General command for enabling a tech.
function EnableTech(force, techName)
    if force.technologies[techName] then
        force.technologies[techName].enabled = true
    end
end


-- Get an area given a position and distance.
-- Square length = 2x distance
function GetAreaAroundPos(pos, dist)

    return {left_top=
                    {x=pos.x-dist,
                     y=pos.y-dist},
            right_bottom=
                    {x=pos.x+dist,
                     y=pos.y+dist}}
end

-- Gets chunk position of a tile.
function GetChunkPosFromTilePos(tile_pos)
    return {x=math.floor(tile_pos.x/32), y=math.floor(tile_pos.y/32)}
end

-- Get the left_top
function GetChunkTopLeft(pos)
    return {x=pos.x-(pos.x % 32), y=pos.y-(pos.y % 32)}
end

-- Get area given chunk
function GetAreaFromChunkPos(chunk_pos)
    return {left_top={x=chunk_pos.x*32, y=chunk_pos.y*32},
            right_bottom={x=chunk_pos.x*32+31, y=chunk_pos.y*32+31}}
end

-- Removes the entity type from the area given
function RemoveInArea(surface, area, type)
    for key, entity in pairs(surface.find_entities_filtered{area=area, type= type}) do
        if entity.valid and entity and entity.position then
            entity.destroy()
        end
    end
end

-- Removes the entity type from the area given
-- Only if it is within given distance from given position.
function RemoveInCircle(surface, area, type, pos, dist)
    for key, entity in pairs(surface.find_entities_filtered{area=area, type= type}) do
        if entity.valid and entity and entity.position then
            if ((pos.x - entity.position.x)^2 + (pos.y - entity.position.y)^2 < dist^2) then
                entity.destroy()
            end
        end
    end
end

-- Create another surface so that we can modify map settings and not have a screwy nauvis map.
function CreateGameSurface()

    -- Get starting surface settings.
    local nauvis_settings =  game.surfaces["nauvis"].map_gen_settings

    if global.ocfg.enable_vanilla_spawns then
        nauvis_settings.starting_points = CreateVanillaSpawns(global.ocfg.vanilla_spawn_count, global.ocfg.vanilla_spawn_spacing)

        -- ENFORCE ISLAND MAP GEN
        if (global.ocfg.silo_islands) then
            nauvis_settings.property_expression_names.elevation = "0_17-island"
        end
    end

    -- Create new game surface
    local s = game.create_surface(GAME_SURFACE_NAME, nauvis_settings)

    -- Add surface and safe areas
    if global.ocfg.enable_regrowth then
        remote.call("oarc_regrowth", "add_surface", s.index)
        remote.call("oarc_regrowth", "area_offlimits_chunkpos", s.index, {x=0,y=0}, 10)
    end
end

--------------------------------------------------------------------------------
-- Functions for removing/modifying enemies
--------------------------------------------------------------------------------

-- Convenient way to remove aliens, just provide an area
function RemoveAliensInArea(surface, area)
    for _, entity in pairs(surface.find_entities_filtered{area = area, force = "enemy"}) do
        entity.destroy()
    end
end

-- Make an area safer
-- Reduction factor divides the enemy spawns by that number. 2 = half, 3 = third, etc...
-- Also removes all big and huge worms in that area
function ReduceAliensInArea(surface, area, reductionFactor)
    for _, entity in pairs(surface.find_entities_filtered{area = area, force = "enemy"}) do
        if (math.random(0,reductionFactor) > 0) then
            entity.destroy()
        end
    end
end

-- Downgrades worms in an area based on chance.
-- 100% small would mean all worms are changed to small.
function DowngradeWormsInArea(surface, area, small_percent, medium_percent, big_percent)

    local worm_types = {"small-worm-turret", "medium-worm-turret", "big-worm-turret", "behemoth-worm-turret"}

    for _, entity in pairs(surface.find_entities_filtered{area = area, name = worm_types}) do

        -- Roll a number between 0-100
        local rand_percent = math.random(0,100)
        local worm_pos = entity.position
        local worm_name = entity.name

        -- If number is less than small percent, change to small
        if (rand_percent <= small_percent) then
            if (not (worm_name == "small-worm-turret")) then
                entity.destroy()
                surface.create_entity{name = "small-worm-turret", position = worm_pos, force = game.forces.enemy}
            end

        -- ELSE If number is less than medium percent, change to small
        elseif (rand_percent <= medium_percent) then
            if (not (worm_name == "medium-worm-turret")) then
                entity.destroy()
                surface.create_entity{name = "medium-worm-turret", position = worm_pos, force = game.forces.enemy}
            end

        -- ELSE If number is less than big percent, change to small
        elseif (rand_percent <= big_percent) then
            if (not (worm_name == "big-worm-turret")) then
                entity.destroy()
                surface.create_entity{name = "big-worm-turret", position = worm_pos, force = game.forces.enemy}
            end

        -- ELSE ignore it.
        end
    end
end

function DowngradeWormsDistanceBasedOnChunkGenerate(event)
    if (getDistance({x=0,y=0}, event.area.left_top) < (global.ocfg.near_dist_end*CHUNK_SIZE)) then
        DowngradeWormsInArea(event.surface, event.area, 100, 100, 100)
    elseif (getDistance({x=0,y=0}, event.area.left_top) < (global.ocfg.far_dist_start*CHUNK_SIZE)) then
        DowngradeWormsInArea(event.surface, event.area, 50, 90, 100)
    elseif (getDistance({x=0,y=0}, event.area.left_top) < (global.ocfg.far_dist_end*CHUNK_SIZE)) then
        DowngradeWormsInArea(event.surface, event.area, 20, 80, 97)
    else
        DowngradeWormsInArea(event.surface, event.area, 0, 20, 90)
    end
end

-- A function to help me remove worms in an area.
-- Yeah kind of an unecessary wrapper, but makes my life easier to remember the worm types.
function RemoveWormsInArea(surface, area, small, medium, big, behemoth)
    local worm_types = {}

    if (small) then
        table.insert(worm_types, "small-worm-turret")
    end
    if (medium) then
        table.insert(worm_types, "medium-worm-turret")
    end
    if (big) then
        table.insert(worm_types, "big-worm-turret")
    end
    if (behemoth) then
        table.insert(worm_types, "behemoth-worm-turret")
    end

    -- Destroy
    if (TableLength(worm_types) > 0) then
        for _, entity in pairs(surface.find_entities_filtered{area = area, name = worm_types}) do
                entity.destroy()
        end
    else
        log("RemoveWormsInArea had empty worm_types list!")
    end
end

-- Add Long Reach to Character
function GivePlayerLongReach(player)
    player.character.character_build_distance_bonus = BUILD_DIST_BONUS
    player.character.character_reach_distance_bonus = REACH_DIST_BONUS
    -- player.character.character_resource_reach_distance_bonus  = RESOURCE_DIST_BONUS
end

-- General purpose cover an area in tiles.
function CoverAreaInTiles(surface, area, tile_name)
    tiles = {}
    for x = area.left_top.x,area.left_top.x+31 do
        for y = area.left_top.y,area.left_top.y+31 do
            table.insert(tiles, {name = tile_name, position = {x=x, y=y}})
        end
    end
    surface.set_tiles(tiles, true)
end

--------------------------------------------------------------------------------
-- Anti-griefing Stuff & Gravestone (My own version)
--------------------------------------------------------------------------------
function AntiGriefing(force)
    force.zoom_to_world_deconstruction_planner_enabled=false
    SetForceGhostTimeToLive(force)
end

function SetForceGhostTimeToLive(force)
    if GHOST_TIME_TO_LIVE ~= 0 then
        force.ghost_time_to_live = GHOST_TIME_TO_LIVE+1
    end
end

function SetItemBlueprintTimeToLive(event)
    local type = event.created_entity.type
    if type == "entity-ghost" or type == "tile-ghost" then
        if GHOST_TIME_TO_LIVE ~= 0 then
            event.created_entity.time_to_live = GHOST_TIME_TO_LIVE
        end
    end
end

--------------------------------------------------------------------------------
-- Gravestone soft mod. With my own modifications/improvements.
--------------------------------------------------------------------------------
-- Return steel chest entity (or nil)
function DropEmptySteelChest(player)
    local pos = player.surface.find_non_colliding_position("steel-chest", player.position, 15, 1)
    if not pos then
        return nil
    end
    local grave = player.surface.create_entity{name="steel-chest", position=pos, force="neutral"}
    return grave
end

function DropGravestoneChests(player)

    local grave
    local count = 0

    -- Make sure we save stuff we're holding in our hands.
    player.clean_cursor()

    -- Loop through a players different inventories
    -- Put it all into a chest.
    -- If the chest is full, create a new chest.
    for i, id in ipairs{
        defines.inventory.character_armor,
        defines.inventory.character_main,
        defines.inventory.character_guns,
        defines.inventory.character_ammo,
        defines.inventory.character_vehicle,
        defines.inventory.character_trash} do

        local inv = player.get_inventory(id)

        -- No idea how inv can be nil sometimes...?
        if (inv ~= nil) then
            if ((#inv > 0) and not inv.is_empty()) then
                for j = 1, #inv do
                    if inv[j].valid_for_read then

                        -- Create a chest when counter is reset
                        if (count == 0) then
                            grave = DropEmptySteelChest(player)
                            if (grave == nil) then
                                -- player.print("Not able to place a chest nearby! Some items lost!")
                                return
                            end
                            grave_inv = grave.get_inventory(defines.inventory.chest)
                        end
                        count = count + 1

                        -- Copy the item stack into a chest slot.
                        grave_inv[count].set_stack(inv[j])

                        -- Reset counter when chest is full
                        if (count == #grave_inv) then
                            count = 0
                        end
                    end
                end
            end

            -- Clear the player inventory so we don't have duplicate items lying around.
            inv.clear()
        end
    end

    if (grave ~= nil) then
        player.print("Successfully dropped your items into a chest! Go get them quick!")
    end
end

-- Dump player items into a chest after the body expires.
function DropGravestoneChestFromCorpse(corpse)
    if ((corpse == nil) or (corpse.character_corpse_player_index == nil)) then return end

    local grave, grave_inv
    local count = 0

    local inv = corpse.get_inventory(defines.inventory.character_corpse)

    -- No idea how inv can be nil sometimes...?
    if (inv ~= nil) then
        if ((#inv > 0) and not inv.is_empty()) then
            for j = 1, #inv do
                if inv[j].valid_for_read then

                    -- Create a chest when counter is reset
                    if (count == 0) then
                        grave = DropEmptySteelChest(corpse)
                        if (grave == nil) then
                            -- player.print("Not able to place a chest nearby! Some items lost!")
                            return
                        end
                        grave_inv = grave.get_inventory(defines.inventory.chest)
                    end
                    count = count + 1

                    -- Copy the item stack into a chest slot.
                    grave_inv[count].set_stack(inv[j])

                    -- Reset counter when chest is full
                    if (count == #grave_inv) then
                        count = 0
                    end
                end
            end
        end

        -- Clear the player inventory so we don't have duplicate items lying around.
        -- inv.clear()
    end

    if (grave ~= nil) and (game.players[corpse.character_corpse_player_index] ~= nil)then
        game.players[corpse.character_corpse_player_index].print("Your corpse got eaten by biters! They kindly dropped your items into a chest! Go get them quick!")
    end

end

--------------------------------------------------------------------------------
-- Item/Inventory stuff (used in autofill)
--------------------------------------------------------------------------------

-- Transfer Items Between Inventory
-- Returns the number of items that were successfully transferred.
-- Returns -1 if item not available.
-- Returns -2 if can't place item into destInv (ERROR)
function TransferItems(srcInv, destEntity, itemStack)
    -- Check if item is in srcInv
    if (srcInv.get_item_count(itemStack.name) == 0) then
        return -1
    end

    -- Check if can insert into destInv
    if (not destEntity.can_insert(itemStack)) then
        return -2
    end

    -- Insert items
    local itemsRemoved = srcInv.remove(itemStack)
    itemStack.count = itemsRemoved
    return destEntity.insert(itemStack)
end

-- Attempts to transfer at least some of one type of item from an array of items.
-- Use this to try transferring several items in order
-- It returns once it successfully inserts at least some of one type.
function TransferItemMultipleTypes(srcInv, destEntity, itemNameArray, itemCount)
    local ret = 0
    for _,itemName in pairs(itemNameArray) do
        ret = TransferItems(srcInv, destEntity, {name=itemName, count=itemCount})
        if (ret > 0) then
            return ret -- Return the value succesfully transferred
        end
    end
    return ret -- Return the last error code
end

-- Autofills a turret with ammo
function AutofillTurret(player, turret)
    local mainInv = player.get_main_inventory()
    if (mainInv == nil) then return end

    -- Attempt to transfer some ammo
    local ret = TransferItemMultipleTypes(mainInv, turret, {"uranium-rounds-magazine", "piercing-rounds-magazine", "firearm-magazine"}, AUTOFILL_TURRET_AMMO_QUANTITY)

    -- Check the result and print the right text to inform the user what happened.
    if (ret > 0) then
        -- Inserted ammo successfully
        -- FlyingText("Inserted ammo x" .. ret, turret.position, my_color_red, player.surface)
    elseif (ret == -1) then
        FlyingText("Out of ammo!", turret.position, my_color_red, player.surface)
    elseif (ret == -2) then
        FlyingText("Autofill ERROR! - Report this bug!", turret.position, my_color_red, player.surface)
    end
end

-- Autofills a vehicle with fuel, bullets and shells where applicable
function AutoFillVehicle(player, vehicle)
    local mainInv = player.get_main_inventory()
    if (mainInv == nil) then return end

    -- Attempt to transfer some fuel
    if ((vehicle.name == "car") or (vehicle.name == "tank") or (vehicle.name == "locomotive")) then
        TransferItemMultipleTypes(mainInv, vehicle, {"nuclear-fuel", "rocket-fuel", "solid-fuel", "coal", "wood"}, 50)
    end

    -- Attempt to transfer some ammo
    if ((vehicle.name == "car") or (vehicle.name == "tank")) then
        TransferItemMultipleTypes(mainInv, vehicle, {"uranium-rounds-magazine", "piercing-rounds-magazine", "firearm-magazine"}, 100)
    end

    -- Attempt to transfer some tank shells
    if (vehicle.name == "tank") then
        TransferItemMultipleTypes(mainInv, vehicle, {"explosive-uranium-cannon-shell", "uranium-cannon-shell", "explosive-cannon-shell", "cannon-shell"}, 100)
    end
end

--------------------------------------------------------------------------------
-- Resource patch and starting area generation
--------------------------------------------------------------------------------

-- Enforce a circle of land, also adds trees in a ring around the area.
function CreateCropCircle(surface, centerPos, chunkArea, tileRadius, fillTile)

    local tileRadSqr = tileRadius^2

    local dirtTiles = {}
    for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
        for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do

            -- This ( X^2 + Y^2 ) is used to calculate if something
            -- is inside a circle area.
            local distVar = math.floor((centerPos.x - i)^2 + (centerPos.y - j)^2)

            -- Fill in all unexpected water in a circle
            if (distVar < tileRadSqr) then
                if (surface.get_tile(i,j).collides_with("water-tile") or
                    global.ocfg.spawn_config.gen_settings.force_grass or
                    (game.active_mods["oarc-restricted-build"])) then
                    table.insert(dirtTiles, {name = fillTile, position ={i,j}})
                end
            end

            -- Create a circle of trees around the spawn point.
            if ((distVar < tileRadSqr-200) and
                (distVar > tileRadSqr-400)) then
                surface.create_entity({name="tree-02", amount=1, position={i, j}})
            end
        end
    end

    surface.set_tiles(dirtTiles)
end

-- COPIED FROM jvmguy!
-- Enforce a square of land, with a tree border
-- this is equivalent to the CreateCropCircle code
function CreateCropOctagon(surface, centerPos, chunkArea, tileRadius, fillTile)

    local dirtTiles = {}
    for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
        for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do

            local distVar1 = math.floor(math.max(math.abs(centerPos.x - i), math.abs(centerPos.y - j)))
            local distVar2 = math.floor(math.abs(centerPos.x - i) + math.abs(centerPos.y - j))
            local distVar = math.max(distVar1*1.1, distVar2 * 0.707*1.1);

            -- Fill in all unexpected water in a circle
            if (distVar < tileRadius+2) then
                if (surface.get_tile(i,j).collides_with("water-tile") or
                    global.ocfg.spawn_config.gen_settings.force_grass or
                    (game.active_mods["oarc-restricted-build"])) then
                    table.insert(dirtTiles, {name = fillTile, position ={i,j}})
                end
            end

            -- Create a tree ring
            if ((distVar < tileRadius) and
                (distVar > tileRadius-2)) then
                surface.create_entity({name="tree-01", amount=1, position={i, j}})
            end
        end
    end
    surface.set_tiles(dirtTiles)
end

-- Add a circle of water
function CreateMoat(surface, centerPos, chunkArea, tileRadius, fillTile)

    local tileRadSqr = tileRadius^2

    local waterTiles = {}
    for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
        for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do

            -- This ( X^2 + Y^2 ) is used to calculate if something
            -- is inside a circle area.
            local distVar = math.floor((centerPos.x - i)^2 + (centerPos.y - j)^2)

            -- Create a circle of water
            if ((distVar < tileRadSqr+(1500*global.ocfg.spawn_config.gen_settings.moat_size_modifier)) and
                (distVar > tileRadSqr)) then
                table.insert(waterTiles, {name = "water", position ={i,j}})
            end

            -- Enforce land inside the edges of the circle to make sure it's
            -- a clean transition
            -- if ((distVar <= tileRadSqr) and
            --     (distVar > tileRadSqr-10000)) then
            --     table.insert(waterTiles, {name = fillTile, position ={i,j}})
            -- end
        end
    end

    surface.set_tiles(waterTiles)
end

-- Create a horizontal line of water
function CreateWaterStrip(surface, leftPos, length)
    local waterTiles = {}
    for i=0,length,1 do
        table.insert(waterTiles, {name = "water", position={leftPos.x+i,leftPos.y}})
    end
    surface.set_tiles(waterTiles)
end

-- Function to generate a resource patch, of a certain size/amount at a pos.
function GenerateResourcePatch(surface, resourceName, diameter, pos, amount)
    local midPoint = math.floor(diameter/2)
    if (diameter == 0) then
        return
    end
    for y=-midPoint, midPoint do
        for x=-midPoint, midPoint do
            if (not global.ocfg.spawn_config.gen_settings.resources_circle_shape or ((x)^2 + (y)^2 < midPoint^2)) then
                surface.create_entity({name=resourceName, amount=amount,
                    position={pos.x+x, pos.y+y}})
            end
        end
    end
end




--------------------------------------------------------------------------------
-- Holding pen for new players joining the map
--------------------------------------------------------------------------------
function CreateWall(surface, pos)
    local wall = surface.create_entity({name="stone-wall", position=pos, force=MAIN_TEAM})
    if wall then
        wall.destructible = false
        wall.minable = false
    end
end

function CreateHoldingPen(surface, chunkArea, sizeTiles, sizeMoat)
    if (((chunkArea.left_top.x >= -(sizeTiles+sizeMoat+CHUNK_SIZE)) and (chunkArea.left_top.x <= (sizeTiles+sizeMoat+CHUNK_SIZE))) and
        ((chunkArea.left_top.y >= -(sizeTiles+sizeMoat+CHUNK_SIZE)) and (chunkArea.left_top.y <= (sizeTiles+sizeMoat+CHUNK_SIZE)))) then

        -- Remove stuff
        RemoveAliensInArea(surface, chunkArea)
        RemoveInArea(surface, chunkArea, "tree")
        RemoveInArea(surface, chunkArea, "resource")
        RemoveInArea(surface, chunkArea, "cliff")

        -- This loop runs through each tile
        local grassTiles = {}
        local waterTiles = {}
        for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
            for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do

                -- Are we within the moat area?
                if ((i>-(sizeTiles+sizeMoat)) and (i<((sizeTiles+sizeMoat)-1)) and
                    (j>-(sizeTiles+sizeMoat)) and (j<((sizeTiles+sizeMoat)-1))) then

                    -- Are we within the land area? Place land.
                    if ((i>-(sizeTiles)) and (i<((sizeTiles)-1)) and
                        (j>-(sizeTiles)) and (j<((sizeTiles)-1))) then
                        table.insert(grassTiles, {name = "grass-1", position ={i,j}})

                    -- Else, surround with water.
                    else
                        table.insert(waterTiles, {name = "water", position ={i,j}})
                    end
                end
            end
        end
        surface.set_tiles(waterTiles)
        surface.set_tiles(grassTiles)
    end
end

--------------------------------------------------------------------------------
-- EVENT SPECIFIC FUNCTIONS
--------------------------------------------------------------------------------

-- Display messages to a user everytime they join
function PlayerJoinedMessages(event)
    local player = game.players[event.player_index]
    player.print(global.ocfg.welcome_msg)
end

-- Remove decor to save on file size
function UndecorateOnChunkGenerate(event)
    local surface = event.surface
    local chunkArea = event.area
    RemoveDecorationsArea(surface, chunkArea)
    RemoveFish(surface, chunkArea)
end

-- Give player items on respawn
-- Intended to be the default behavior when not using separate spawns
function PlayerRespawnItems(event)
    GivePlayerItems(game.players[event.player_index])
end

function PlayerSpawnItems(event)
    GivePlayerStarterItems(game.players[event.player_index])
end

-- Autofill softmod
function Autofill(event)
    local player = game.players[event.player_index]
    local eventEntity = event.created_entity

    -- Make sure player isn't dead?
    if (player.character == nil) then return end

    if (eventEntity.name == "gun-turret") then
        AutofillTurret(player, eventEntity)
    end

    if ((eventEntity.name == "car") or (eventEntity.name == "tank") or (eventEntity.name == "locomotive")) then
        AutoFillVehicle(player, eventEntity)
    end
end

-- Map loaders to logistics tech for unlocks.
local loaders_technology_map = {
    ['logistics'] = 'loader',
    ['logistics-2'] = 'fast-loader',
    ['logistics-3'] = 'express-loader'
}

function EnableLoaders(event)
    local research = event.research
    local recipe = loaders_technology_map[research.name]
    if recipe then
        research.force.recipes[recipe].enabled = true
    end
end
