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

MAX_INT32_POS = 2147483647
MAX_INT32_NEG = -2147483648
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

-- Get a printable GPS string
function GetGPStext(pos)
    return "[gps=" .. pos.x .. "," .. pos.y .. "]"
end

-- Requires having an on_tick handler.
function DisplaySpeechBubble(player, text, timeout_secs)

    if (global.oarc_speech_bubbles == nil) then
        global.oarc_speech_bubbles = {}
    end

    if (player and player.character) then
        local sp = player.surface.create_entity{name = "compi-speech-bubble",
                                                position = player.position,
                                                text = text,
                                                source = player.character}
        table.insert(global.oarc_speech_bubbles, {entity=sp,
                        timeout_tick=game.tick+(timeout_secs*TICKS_PER_SECOND)})
    end
end

-- Render some text on the ground. Visible to all players. Forever.
function RenderPermanentGroundText(surface, position, scale, text, color)
    rendering.draw_text{text=text,
                    surface=surface,
                    target=position,
                    color=color,
                    scale=scale,
                    --Allowed fonts: default-dialog-button default-game compilatron-message-font default-large default-large-semibold default-large-bold heading-1 compi
                    font="compi",
                    draw_on_ground=true}
end 

-- A standardized helper text that fades out over time
function TemporaryHelperText(text, position, ttl)
    local rid = rendering.draw_text{text=text,
                    surface=game.surfaces[GAME_SURFACE_NAME],
                    target=position,
                    color={0.7,0.7,0.7,0.7},
                    scale=1,
                    font="compi",
                    time_to_live=ttl,
                    draw_on_ground=false}
    table.insert(global.oarc_renders_fadeout, rid)
end

-- Every second, check a global table to see if we have any speech bubbles to kill.
function TimeoutSpeechBubblesOnTick()
    if ((game.tick % (TICKS_PER_SECOND)) == 3) then
        if (global.oarc_speech_bubbles and (#global.oarc_speech_bubbles > 0)) then
            for k,sp in pairs(global.oarc_speech_bubbles) do
                if (game.tick > sp.timeout_tick) then
                    if (sp.entity ~= nil) and (sp.entity.valid) then
                        sp.entity.start_fading_out()
                    end
                    table.remove(global.oarc_speech_bubbles, k)
                end
            end
        end
    end
end

-- Every tick, check a global table to see if we have any rendered thing that needs fading out.
function FadeoutRenderOnTick()
    if (global.oarc_renders_fadeout and (#global.oarc_renders_fadeout > 0)) then
        for k,rid in pairs(global.oarc_renders_fadeout) do
            if (rendering.is_valid(rid)) then
                local ttl = rendering.get_time_to_live(rid)
                if ((ttl > 0) and (ttl < 200)) then
                    local color = rendering.get_color(rid)
                    if (color.a > 0.005) then
                        rendering.set_color(rid, {r=color.r, g=color.g, b=color.b, a=color.a-0.005})
                    end
                end
            else
                global.oarc_renders_fadeout[k] = nil
            end
        end
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

-- Simple math clamp
function clamp(val, min, max)
    if (val > max) then
        return max
    elseif (val < min) then
        return min
    end
    return val
end
function clampInt32(val)
    return clamp(val, MAX_INT32_NEG, MAX_INT32_POS)
end

function MathRound(num)
    return math.floor(num+0.5)
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

-- Get a random KEY from a table.
function GetRandomKeyFromTable(t)
    local keyset = {}
    for k,v in pairs(t) do
        table.insert(keyset, k)
    end
    return keyset[math.random(#keyset)]
end

-- A safer way to attempt to get the next key in a table. CHECK TABLE SIZE BEFORE CALLING THIS!
-- Ensures the key points to a valid entry before calling next. Otherwise it restarts.
-- If you get nil as a return, it means you hit the return.
function NextButChecksKeyIsValidFirst(table_in, key)
    -- if (table_size(table_in) == 0) then you're fucked end
    if ((not key) or (not table_in[key])) then
        return next(table_in, nil)
    else
        return next(table_in, key)
    end
end

-- Gets the next key, even if we have to start again.
function NextKeyInTableIncludingRestart(table_in, key)
    local next_key = NextButChecksKeyIsValidFirst(table_in, key)
    if (not next_key) then
        return NextButChecksKeyIsValidFirst(table_in, next_key)
    else
        return next_key
    end
end

function GetRandomValueFromTable(t)
    return t[GetRandomKeyFromTable(t)]
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

    if (closest_key == nil) then
        log("GetClosestPosFromTable ERROR - None found?")
        return nil
    end

    return pos_table[closest_key]
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
    for name,count in pairs(PLAYER_RESPAWN_START_ITEMS) do
        player.insert({name=name, count=count})
    end
end

-- Starter only items
function GivePlayerStarterItems(player)
    for name,count in pairs(PLAYER_SPAWN_START_ITEMS) do
        player.insert({name=name, count=count})
    end

    if global.ocfg.enable_power_armor_start then
        GiveQuickStartPowerArmor(player)
    elseif global.ocfg.enable_modular_armor_start then
        GiveQuickStartModularArmor(player)
    end
end

-- Modular armor quick start
function GiveQuickStartModularArmor(player)
    player.insert{name="modular-armor", count = 1}

    if player and player.get_inventory(defines.inventory.character_armor) ~= nil and player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
        local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
            if p_armor ~= nil then
                p_armor.put({name = "personal-roboport-equipment"})
                p_armor.put({name = "battery-mk2-equipment"})
                p_armor.put({name = "personal-roboport-equipment"})
                for i=1,15 do
                    p_armor.put({name = "solar-panel-equipment"})
                end
            end
        player.insert{name="construction-robot", count = 40}
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
                for i=1,7 do
                    p_armor.put({name = "solar-panel-equipment"})
                end
            end
        player.insert{name="construction-robot", count = 100}
        player.insert{name="belt-immunity-equipment", count = 1}
    end
end

TEST_KIT = {
    {name="infinity-chest", count = 50},
    {name="infinity-pipe", count = 50},
    {name="electric-energy-interface", count = 50},
    {name="express-loader", count = 50},
    {name="express-transport-belt", count = 50},
}

function GiveTestKit(player)
    for _,item in pairs(TEST_KIT) do
        player.insert(item)
    end
end

-- Safer teleport
function SafeTeleport(player, surface, target_pos)
    local safe_pos = surface.find_non_colliding_position("character", target_pos, 15, 1)
    if (not safe_pos) then
        player.teleport(target_pos, surface)
    else
        player.teleport(safe_pos, surface)
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
        if name ~= "neutral" and name ~= "enemy" and name ~= global.ocore.abandoned_force then
            for x,y in pairs(game.forces) do
                if x ~= "neutral" and x ~= "enemy" and name ~= global.ocore.abandoned_force then
                    team.set_cease_fire(x,true)
                end
            end
        end
    end
end

-- Set all forces to friendly
function SetFriendlyBetweenAllForces()
    for name,team in pairs(game.forces) do
        if name ~= "neutral" and name ~= "enemy" and name ~= global.ocore.abandoned_force then
            for x,y in pairs(game.forces) do
                if x ~= "neutral" and x ~= "enemy" and name ~= global.ocore.abandoned_force then
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

-- Render a path
function RenderPath(path, ttl, players)
    local last_pos = path[1].position
    local color = {r = 1, g = 0, b = 0, a = 0.5}

    for i,v in pairs(path) do
        if (i ~= 1) then

            color={r = 1/(1+(i%3)), g = 1/(1+(i%5)), b = 1/(1+(i%7)), a = 0.5}
            rendering.draw_line{color=color,
                                width=2,
                                from=v.position,
                                to=last_pos,
                                surface=game.surfaces[GAME_SURFACE_NAME],
                                players=players,
                                time_to_live=ttl}
        end
        last_pos = v.position
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

function GetCenterTilePosFromChunkPos(c_pos)
    return {x=c_pos.x*32 + 16, y=c_pos.y*32 + 16}
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

-- For easy local testing of map gen settings. Just set what you want and uncomment usage in CreateGameSurface!
function SurfaceSettingsHelper(settings)

    settings.terrain_segmentation = 4
    settings.water = 3
    settings.starting_area = 0

    local r_freq = 1.20
    local r_rich = 5.00
    local r_size = 0.18

    settings.autoplace_controls["coal"].frequency = r_freq
    settings.autoplace_controls["coal"].richness = r_rich
    settings.autoplace_controls["coal"].size = r_size
    settings.autoplace_controls["copper-ore"].frequency = r_freq
    settings.autoplace_controls["copper-ore"].richness = r_rich
    settings.autoplace_controls["copper-ore"].size = r_size
    settings.autoplace_controls["crude-oil"].frequency = r_freq
    settings.autoplace_controls["crude-oil"].richness = r_rich
    settings.autoplace_controls["crude-oil"].size = r_size
    settings.autoplace_controls["iron-ore"].frequency = r_freq
    settings.autoplace_controls["iron-ore"].richness = r_rich
    settings.autoplace_controls["iron-ore"].size = r_size
    settings.autoplace_controls["stone"].frequency = r_freq
    settings.autoplace_controls["stone"].richness = r_rich
    settings.autoplace_controls["stone"].size = r_size
    settings.autoplace_controls["uranium-ore"].frequency = r_freq*0.5
    settings.autoplace_controls["uranium-ore"].richness = r_rich
    settings.autoplace_controls["uranium-ore"].size = r_size

    settings.autoplace_controls["enemy-base"].frequency = 0.80
    settings.autoplace_controls["enemy-base"].richness = 0.70
    settings.autoplace_controls["enemy-base"].size = 0.70

    settings.autoplace_controls["trees"].frequency = 1.00
    settings.autoplace_controls["trees"].richness = 1.00
    settings.autoplace_controls["trees"].size = 1.00

    settings.cliff_settings.cliff_elevation_0 = 3
    settings.cliff_settings.cliff_elevation_interval = 200
    settings.cliff_settings.richness = 3

    settings.property_expression_names["control-setting:aux:bias"] = "0.00"
    settings.property_expression_names["control-setting:aux:frequency:multiplier"] = "5.00"
    settings.property_expression_names["control-setting:moisture:bias"] = "0.40"
    settings.property_expression_names["control-setting:moisture:frequency:multiplier"] = "50"

    return settings
end

-- Create another surface so that we can modify map settings and not have a screwy nauvis map.
function CreateGameSurface()

    if (GAME_SURFACE_NAME ~= "nauvis") then

        -- Get starting surface settings.
        local nauvis_settings =  game.surfaces["nauvis"].map_gen_settings

        if global.ocfg.enable_vanilla_spawns then
            nauvis_settings.starting_points = CreateVanillaSpawns(global.ocfg.vanilla_spawn_count, global.ocfg.vanilla_spawn_spacing)

            -- ENFORCE ISLAND MAP GEN
            if (global.ocfg.silo_islands) then
                nauvis_settings.property_expression_names.elevation = "0_17-island"
            end
        end

        -- Enable this to test things out easily.
        -- nauvis_settings = SurfaceSettingsHelper(nauvis_settings)

        -- Create new game surface
        local s = game.create_surface(GAME_SURFACE_NAME, nauvis_settings)

    end

    -- Add surface and safe areas
    if global.ocfg.enable_regrowth then
        RegrowthMarkAreaSafeGivenChunkPos({x=0,y=0}, 4, true)
    end
end

function CreateTileArrow(surface, pos, type)

    tiles = {}

    if (type == "LEFT") then
        table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x, pos.y}})
        table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+1, pos.y}})
        table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+2, pos.y}})
        table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+3, pos.y}})
        table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x, pos.y+1}})
        table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+1, pos.y+1}})
        table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+2, pos.y+1}})
        table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+3, pos.y+1}})
    elseif (type == "RIGHT") then
        table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x, pos.y}})
        table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+1, pos.y}})
        table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+2, pos.y}})
        table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+3, pos.y}})
        table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x, pos.y+1}})
        table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+1, pos.y+1}})
        table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+2, pos.y+1}})
        table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+3, pos.y+1}})
    end
    
    surface.set_tiles(tiles, true)
end

-- Allowed colors: red, green, blue, orange, yellow, pink, purple, black, brown, cyan, acid
function CreateFixedColorTileArea(surface, area, color)

    tiles = {}

    for i=area.left_top.x,area.right_bottom.x do
        for j=area.left_top.y,area.right_bottom.y do
            table.insert(tiles, {name = color.."-refined-concrete", position = {i,j}})
        end
    end

    surface.set_tiles(tiles, true)
end

-- Find closest player-owned entity
function FindClosestPlayerOwnedEntity(player, name, radius)

    local entities = player.surface.find_entities_filtered{position=player.position,
                                            radius=radius,
                                            name=name,
                                            force=player.force}
    if (not entities or (#entities == 0)) then return nil end

    return player.surface.get_closest(player.position, entities)
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
    -- TODO: Mess with permission groups and shit
end

function SetForceGhostTimeToLive(force)
    if global.ocfg.ghost_ttl ~= 0 then
        force.ghost_time_to_live = global.ocfg.ghost_ttl+1
    end
end

function SetItemBlueprintTimeToLive(event)
    local type = event.created_entity.type
    if type == "entity-ghost" or type == "tile-ghost" then
        if global.ocfg.ghost_ttl ~= 0 then
            event.created_entity.time_to_live = global.ocfg.ghost_ttl
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
            if ((distVar < tileRadSqr-100) and
                (distVar > tileRadSqr-500)) then
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
function CreateMoat(surface, centerPos, chunkArea, tileRadius, moatTile, bridge)

    local tileRadSqr = tileRadius^2

    local tiles = {}
    for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
        for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do

            if (bridge and ((j == centerPos.y-1) or (j == centerPos.y) or (j == centerPos.y+1))) then
                -- This will leave the tiles "as is" on the left and right of the spawn which has the effect of creating
                -- land connections if the spawn is on or near land.
            else

                -- This ( X^2 + Y^2 ) is used to calculate if something
                -- is inside a circle area.
                local distVar = math.floor((centerPos.x - i)^2 + (centerPos.y - j)^2)

                -- Create a circle of water
                if ((distVar < tileRadSqr+(1500*global.ocfg.spawn_config.gen_settings.moat_size_modifier)) and
                    (distVar > tileRadSqr)) then
                    table.insert(tiles, {name = moatTile, position ={i,j}})
                end
            end
        end
    end

    surface.set_tiles(tiles)
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

function CreateHoldingPen(surface, chunkArea)
    local radiusTiles = global.ocfg.spawn_config.gen_settings.land_area_tiles-10
    if (((chunkArea.left_top.x >= -(radiusTiles+2*CHUNK_SIZE)) and (chunkArea.left_top.x <= (radiusTiles+2*CHUNK_SIZE))) and
        ((chunkArea.left_top.y >= -(radiusTiles+2*CHUNK_SIZE)) and (chunkArea.left_top.y <= (radiusTiles+2*CHUNK_SIZE)))) then

        -- Remove stuff
        RemoveAliensInArea(surface, chunkArea)
        RemoveInArea(surface, chunkArea, "tree")
        RemoveInArea(surface, chunkArea, "resource")
        RemoveInArea(surface, chunkArea, "cliff")

        CreateCropCircle(surface, {x=0,y=0}, chunkArea, radiusTiles, "landfill")
        CreateMoat(surface, {x=0,y=0}, chunkArea, radiusTiles, "water", false)
        CreateMoat(surface, {x=0,y=0}, chunkArea, radiusTiles+10, "out-of-map", false)
        CreateMoat(surface, {x=0,y=0}, chunkArea, 2, "out-of-map", false)
    end
end

--------------------------------------------------------------------------------
-- EVENT SPECIFIC FUNCTIONS
--------------------------------------------------------------------------------

-- Display messages to a user everytime they join
function PlayerJoinedMessages(event)
    local player = game.players[event.player_index]
    player.print(global.ocfg.welcome_msg)
    if (global.oarc_announcements) then
        player.print(global.oarc_announcements)
    end
end

-- Remove decor to save on file size
function UndecorateOnChunkGenerate(event)
    local surface = event.surface
    local chunkArea = event.area
    RemoveDecorationsArea(surface, chunkArea)
    -- If you care to, you can remove all fish with the Undecorator option here:
    -- RemoveFish(surface, chunkArea)
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
