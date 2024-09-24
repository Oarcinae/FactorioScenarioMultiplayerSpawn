-- My general purpose utility functions and constants for factorio
-- Also contains some constants

require("lib/oarc_gui_utils")
require("mod-gui")

local util = require("util")

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



-- --------------------------------------------------------------------------------
-- -- General Helper Functions
-- --------------------------------------------------------------------------------

-- -- Prints flying text.
-- -- Color is optional
-- function FlyingText(msg, pos, color, surface)
--     if color == nil then
--         surface.create_entity({ name = "flying-text", position = pos, text = msg })
--     else
--         surface.create_entity({ name = "flying-text", position = pos, text = msg, color = color })
--     end
-- end

-- Get a printable GPS string
---@param surface_name string
---@param position MapPosition
---@return string
function GetGPStext(surface_name, position)
    return "[gps=" .. position.x .. "," .. position.y .. "," .. surface_name .. "]"
end

-- -- Requires having an on_tick handler.
-- function DisplaySpeechBubble(player, text, timeout_secs)

--     if (global.oarc_speech_bubbles == nil) then
--         global.oarc_speech_bubbles = {}
--     end

--     if (player and player.character) then
--         local sp = player.surface.create_entity{name = "compi-speech-bubble",
--                                                 position = player.position,
--                                                 text = text,
--                                                 source = player.character}
--         table.insert(global.oarc_speech_bubbles, {entity=sp,
--                         timeout_tick=game.tick+(timeout_secs*TICKS_PER_SECOND)})
--     end
-- end

---Render some text on the ground. Visible to all players. Forever.
---@param surface LuaSurface
---@param position MapPosition
---@param scale number
---@param text string
---@param color Color
---@param alignment TextAlign?
---@return nil
function RenderPermanentGroundText(surface, position, scale, text, color, alignment)
    rendering.draw_text { text = text,
        surface = surface,
        target = position,
        color = color,
        scale = scale,
        --Allowed fonts: default-dialog-button default-game compilatron-message-font default-large default-large-semibold default-large-bold heading-1 compi
        font = "compi",
        alignment = alignment,
        draw_on_ground = true }
end

---A standardized helper text that fades out over time
---@param text string|LocalisedString
---@param surface LuaSurface
---@param position MapPosition
---@param ttl number
---@param alignment TextAlign?
---@return nil
function TemporaryHelperText(text, surface, position, ttl, alignment)
    local rid = rendering.draw_text { text = text,
        surface = surface,
        target = position,
        color = { 0.7, 0.7, 0.7, 0.7 },
        scale = 1,
        font = "compi",
        time_to_live = ttl,
        alignment = alignment,
        draw_on_ground = false }
    table.insert(global.oarc_renders_fadeout, rid)
end

-- -- Every second, check a global table to see if we have any speech bubbles to kill.
-- function TimeoutSpeechBubblesOnTick()
--     if ((game.tick % (TICKS_PER_SECOND)) == 3) then
--         if (global.oarc_speech_bubbles and (#global.oarc_speech_bubbles > 0)) then
--             for k,sp in pairs(global.oarc_speech_bubbles) do
--                 if (game.tick > sp.timeout_tick) then
--                     if (sp.entity ~= nil) and (sp.entity.valid) then
--                         sp.entity.start_fading_out()
--                     end
--                     table.remove(global.oarc_speech_bubbles, k)
--                 end
--             end
--         end
--     end
-- end

---Every tick, check a global table to see if we have any rendered thing that needs fading out.
---@return nil
function FadeoutRenderOnTick()
    if (global.oarc_renders_fadeout and (#global.oarc_renders_fadeout > 0)) then
        for k, rid in pairs(global.oarc_renders_fadeout) do
            if (rendering.is_valid(rid)) then
                local ttl = rendering.get_time_to_live(rid)
                if ((ttl > 0) and (ttl < 200)) then
                    local color = rendering.get_color(rid)
                    if (color.a > 0.005) then
                        rendering.set_color(rid, { r = color.r, g = color.g, b = color.b, a = color.a - 0.005 })
                    end
                end
            else
                global.oarc_renders_fadeout[k] = nil
            end
        end
    end
end

--- Broadcast messages to all connected players
---@param msg LocalisedString
---@return nil
function SendBroadcastMsg(msg)
    for name, player in pairs(game.connected_players) do
        player.print(msg)
    end
end

---Send a message to a player, safely checks if they exist and are online.
---@param playerName string
---@param msg LocalisedString
---@return nil
function SendMsg(playerName, msg)
    if ((game.players[playerName] ~= nil) and (game.players[playerName].connected)) then
        game.players[playerName].print(msg)
    end
end

---Checks if a string starts with another string
---@param string string The string to check
---@param start string The starting string to look for
function StringStartsWith(string, start)
    return string:sub(1, #start) == start
end

---Checks if a surface is blacklisted based on the global.ocfg settings
---@param surface_name string
---@return boolean --true if blacklisted
function IsSurfaceBlacklisted(surface_name)
    if (global.ocfg.surfaces_blacklist == nil) then
        for _,name in pairs(global.ocfg.surfaces_blacklist) do
            if (name == surface_name) then
                return true
            end
        end
    end

    if (global.ocfg.surfaces_blacklist_match == nil) then
        for _,match in pairs(global.ocfg.surfaces_blacklist_match) do
            if (StringStartsWith(surface_name, match)) then
                return true
            end
        end
    end

    return false
end

-- -- Simple way to write to a file. Always appends. Only server.
-- -- Has a global setting for enable/disable
-- function ServerWriteFile(filename, msg)
--     if (global.ocfg.enable_server_write_files) then
--         game.write_file(filename, msg, true, 0)
--     end
-- end

---Useful for displaying game time in mins:secs format
---@param ticks number
---@return string
function FormatTime(ticks)
  local seconds = ticks / 60
  local minutes = math.floor((seconds)/60)
  local seconds = math.floor(seconds - 60*minutes)
  return string.format("%dm:%02ds", minutes, seconds)
end

---Useful for displaying game time in hrs:mins format
---@param ticks number
---@return string
function FormatTimeHoursSecs(ticks)
  local seconds = ticks / 60
  local minutes = math.floor((seconds)/60)
  local hours   = math.floor((minutes)/60)
  local minutes = math.floor(minutes - 60*hours)
  return string.format("%dh:%02dm", hours, minutes)
end

-- -- Simple math clamp
-- function clamp(val, min, max)
--     if (val > max) then
--         return max
--     elseif (val < min) then
--         return min
--     end
--     return val
-- end
-- function clampInt32(val)
--     return clamp(val, MAX_INT32_NEG, MAX_INT32_POS)
-- end

-- function MathRound(num)
--     return math.floor(num+0.5)
-- end

-- Fisher-Yares shuffle
-- https://stackoverflow.com/questions/35572435/how-do-you-do-the-fisher-yates-shuffle-in-lua
---@param T table
---@return table
function FYShuffle(T)
    local tReturn = {}
    for i = #T, 1, -1 do
        local j = math.random(i)
        T[i], T[j] = T[j], T[i]
        table.insert(tReturn, T[i])
    end
    return tReturn
end

---Check if a table contains a value
---@param table table
---@param val any
---@return boolean
function TableContains(table, val)
    for _, value in pairs(table) do
        if value == val then
            return true
        end
    end
    return false
end

---Get a key from a table given a value (if it exists)
---@param table table
---@param val any
---@return any
function GetTableKey(table, val)
    for k, v in pairs(table) do
        if v == val then
            return k
        end
    end
    return nil
end

-- ---Remove a value from a table
-- ---@param table table
-- ---@param val any
-- ---@return nil
-- function TableRemove(t, val)
--     for i = #t, 1, -1 do
--         if t[i] == val then
--             table.remove(t, i)
--         end
--     end
-- end

function TableRemoveOneUsingPairs(t, val)
    for k,v in pairs(t) do
        if v == val then
            table.remove(t, k)
            return
        end
    end
end

-- -- Get a random KEY from a table.
-- function GetRandomKeyFromTable(t)
--     local keyset = {}
--     for k,v in pairs(t) do
--         table.insert(keyset, k)
--     end
--     return keyset[math.random(#keyset)]
-- end

-- -- A safer way to attempt to get the next key in a table. CHECK TABLE SIZE BEFORE CALLING THIS!
-- -- Ensures the key points to a valid entry before calling next. Otherwise it restarts.
-- -- If you get nil as a return, it means you hit the return.
-- function NextButChecksKeyIsValidFirst(table_in, key)
--     -- if (table_size(table_in) == 0) then you're fucked end
--     if ((not key) or (not table_in[key])) then
--         return next(table_in, nil)
--     else
--         return next(table_in, key)
--     end
-- end

-- -- Gets the next key, even if we have to start again.
-- function NextKeyInTableIncludingRestart(table_in, key)
--     local next_key = NextButChecksKeyIsValidFirst(table_in, key)
--     if (not next_key) then
--         return NextButChecksKeyIsValidFirst(table_in, next_key)
--     else
--         return next_key
--     end
-- end

-- function GetRandomValueFromTable(t)
--     return t[GetRandomKeyFromTable(t)]
-- end

-- -- Given a table of positions, returns key for closest to given pos.
-- function GetClosestPosFromTable(pos, pos_table)

--     local closest_dist = nil
--     local closest_key = nil

--     for k,p in pairs(pos_table) do
--         local new_dist = util.distance(pos, p)
--         if (closest_dist == nil) then
--             closest_dist = new_dist
--             closest_key = k
--         elseif (closest_dist > new_dist) then
--             closest_dist = new_dist
--             closest_key = k
--         end
--     end

--     if (closest_key == nil) then
--         log("GetClosestPosFromTable ERROR - None found?")
--         return nil
--     end

--     return pos_table[closest_key]
-- end

-- Chart area for a force
---@param force string|integer|LuaForce
---@param position MapPosition
---@param chunkDist number
---@param surface LuaSurface|string|integer
function ChartArea(force, position, chunkDist, surface)
    force.chart(surface,
        { { position.x - (CHUNK_SIZE * chunkDist),
            position.y - (CHUNK_SIZE * chunkDist) },
            { position.x + (CHUNK_SIZE * chunkDist),
                position.y + (CHUNK_SIZE * chunkDist) } })
end

---Gives the player the respawn items if there are any
---@param player LuaPlayer
---@return nil
function GivePlayerRespawnItems(player)
    local surface_name = player.surface.name
    if (global.ocfg.surfaces_config[surface_name] == nil) then
        error("GivePlayerRespawnItems - Missing surface config! " .. surface_name)
        return
    end

    local respawnItems = global.ocfg.surfaces_config[surface_name].starting_items.player_respawn_items

    util.insert_safe(player, respawnItems)
end

---Gives the player the starter items if there are any
---@param player LuaPlayer
---@return nil
function GivePlayerStarterItems(player)
    local surface_name = player.surface.name
    if (global.ocfg.surfaces_config[surface_name] == nil) then
        error("GivePlayerStarterItems - Missing surface config! " .. surface_name)
        return
    end

    local startItems = global.ocfg.surfaces_config[surface_name].starting_items.player_start_items

    util.insert_safe(player, startItems)
end

---Half-heartedly attempts to remove starter items from the player. Probably more trouble than it's worth.
---@param player LuaPlayer
---@return nil
function RemovePlayerStarterItems(player)
    local surface_name = player.surface.name
    if (global.ocfg.surfaces_config[surface_name]) ~= nil then
        local startItems = global.ocfg.surfaces_config[surface_name].starting_items.player_start_items
        util.remove_safe(player, startItems)
    end
end

--- Delete all chunks on a surface
--- @param surface LuaSurface
--- @return nil
function DeleteAllChunks(surface)
    for chunk in surface.get_chunks() do
        surface.delete_chunk({chunk.x, chunk.y})
    end
end


-- -- Modular armor quick start
-- function GiveQuickStartModularArmor(player)
--     player.insert{name="modular-armor", count = 1}

--     if player and player.get_inventory(defines.inventory.character_armor) ~= nil and player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
--         local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
--             if p_armor ~= nil then
--                 p_armor.put({name = "personal-roboport-equipment"})
--                 p_armor.put({name = "battery-mk2-equipment"})
--                 p_armor.put({name = "personal-roboport-equipment"})
--                 for i=1,15 do
--                     p_armor.put({name = "solar-panel-equipment"})
--                 end
--             end
--         player.insert{name="construction-robot", count = 40}
--     end
-- end

-- -- Cheater's quick start
-- function GiveQuickStartPowerArmor(player)
--     player.insert{name="power-armor", count = 1}

--     if player and player.get_inventory(defines.inventory.character_armor) ~= nil and player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
--         local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
--             if p_armor ~= nil then
--                 p_armor.put({name = "fusion-reactor-equipment"})
--                 p_armor.put({name = "exoskeleton-equipment"})
--                 p_armor.put({name = "battery-mk2-equipment"})
--                 p_armor.put({name = "battery-mk2-equipment"})
--                 p_armor.put({name = "personal-roboport-mk2-equipment"})
--                 p_armor.put({name = "personal-roboport-mk2-equipment"})
--                 p_armor.put({name = "personal-roboport-mk2-equipment"})
--                 p_armor.put({name = "battery-mk2-equipment"})
--                 for i=1,7 do
--                     p_armor.put({name = "solar-panel-equipment"})
--                 end
--             end
--         player.insert{name="construction-robot", count = 100}
--         player.insert{name="belt-immunity-equipment", count = 1}
--     end
-- end

-- TEST_KIT = {
--     {name="infinity-chest", count = 50},
--     {name="infinity-pipe", count = 50},
--     {name="electric-energy-interface", count = 50},
--     {name="express-loader", count = 50},
--     {name="express-transport-belt", count = 50},
-- }

-- function GiveTestKit(player)
--     for _,item in pairs(TEST_KIT) do
--         player.insert(item)
--     end
-- end

-- Safer teleport
---@param player LuaPlayer
---@param surface LuaSurface
---@param target_pos MapPosition
function SafeTeleport(player, surface, target_pos)
    local safe_pos = surface.find_non_colliding_position("character", target_pos, 15, 1)
    if (not safe_pos) then
        player.teleport(target_pos, surface)
    else
        player.teleport(safe_pos, surface)
    end
end

-- Duplicate function ??
-- -- Create area given point and radius-distance
-- function GetAreaFromPointAndDistance(point, dist)
--     local area = {left_top=
--                     {x=point.x-dist,
--                      y=point.y-dist},
--                   right_bottom=
--                     {x=point.x+dist,
--                      y=point.y+dist}}
--     return area
-- end

---Check if given position is in area bounding box
---@param point MapPosition
---@param area BoundingBox
---@return boolean
function CheckIfInArea(point, area)
    if ((point.x >= area.left_top.x) and (point.x < area.right_bottom.x)) then
        if ((point.y >= area.left_top.y) and (point.y < area.right_bottom.y)) then
            return true
        end
    end
    return false
end

---Configures the friend and cease fire relationships between all player forces.
---@param cease_fire boolean
---@param friends boolean
---@return nil
function ConfigurePlayerForceRelationships(cease_fire, friends)
    local player_forces = {}

    for name, force in pairs(game.forces) do
        if name ~= "neutral" and name ~= ABANDONED_FORCE_NAME and not TableContains(ENEMY_FORCES_NAMES, name) then
            table.insert(player_forces, force)
        end
    end

    for _, force1 in pairs(player_forces) do
        for _, force2 in pairs(player_forces) do
            if force1.name ~= force2.name then
                force1.set_cease_fire(force2, cease_fire)
                force1.set_friend(force2, friends)

                force2.set_cease_fire(force1, cease_fire)
                force2.set_friend(force1, friends)
            end
        end
    end
end

-- ---Set all forces to ceasefire
-- ---@return nil
-- function SetCeaseFireBetweenAllPlayerForces()
--     for name, team in pairs(game.forces) do
--         if name ~= "neutral" and name ~= ABANDONED_FORCE_NAME and not TableContains(ENEMY_FORCES_NAMES, name) then
--             for x, _ in pairs(game.forces) do
--                 if x ~= "neutral" and x ~= ABANDONED_FORCE_NAME and not TableContains(ENEMY_FORCES_NAMES, x) then
--                     team.set_cease_fire(x, true)
--                 end
--             end
--         end
--     end
-- end

-- ---Set all forces to friendly
-- ---@return nil
-- function SetFriendlyBetweenAllPlayerForces()
--     for name, team in pairs(game.forces) do
--         if name ~= "neutral" and name ~= ABANDONED_FORCE_NAME and not TableContains(ENEMY_FORCES_NAMES, name) then
--             for x, _ in pairs(game.forces) do
--                 if x ~= "neutral" and x ~= ABANDONED_FORCE_NAME and not TableContains(ENEMY_FORCES_NAMES, x) then
--                     team.set_friend(x, true)
--                 end
--             end
--         end
--     end
-- end


---For each other player force, share a chat msg.
---@param player LuaPlayer
---@param msg LocalisedString
---@return nil
function ShareChatBetweenForces(player, msg)
    for _,force in pairs(game.forces) do
        if (force ~= nil) then
            if ((force.name ~= "enemy") and
                (force.name ~= "enemy-easy") and
                (force.name ~= "neutral") and
                (force.name ~= "player") and
                (force ~= player.force)) then
                force.print(player.name..": "..msg)
            end
        end
    end
end

-- -- Merges force2 INTO force1 but keeps all research between both forces.
-- function MergeForcesKeepResearch(force1, force2)
--     for techName,luaTech in pairs(force2.technologies) do
--         if (luaTech.researched) then
--            force1.technologies[techName].researched = true
--            force1.technologies[techName].level = luaTech.level
--         end
--     end
--     game.merge_forces(force2, force1)
-- end

-- -- Undecorator
-- function RemoveDecorationsArea(surface, area)
--     surface.destroy_decoratives{area=area}
-- end

-- -- Remove fish
-- function RemoveFish(surface, area)
--     for _, entity in pairs(surface.find_entities_filtered{area = area, type="fish"}) do
--         entity.destroy()
--     end
-- end

-- -- Render a path
-- function RenderPath(path, ttl, players)
--     local last_pos = path[1].position
--     local color = {r = 1, g = 0, b = 0, a = 0.5}

--     for i,v in pairs(path) do
--         if (i ~= 1) then

--             color={r = 1/(1+(i%3)), g = 1/(1+(i%5)), b = 1/(1+(i%7)), a = 0.5}
--             rendering.draw_line{color=color,
--                                 width=2,
--                                 from=v.position,
--                                 to=last_pos,
--                                 surface=game.surfaces[GAME_SURFACE_NAME],
--                                 players=players,
--                                 time_to_live=ttl}
--         end
--         last_pos = v.position
--     end
-- end

---Get a random 1 or -1
---@return number
function RandomNegPos()
    if (math.random(0,1) == 1) then
        return 1
    else
        return -1
    end
end

---Create a random direction vector to look in, returns normalized vector
---@return MapPosition
function GetRandomVector()
    local randVec = {x=0,y=0}
    while ((randVec.x == 0) and (randVec.y == 0)) do
        randVec.x = math.random() * 2 - 1
        randVec.y = math.random() * 2 - 1
    end
    -- Normalize the vector
    local magnitude = math.sqrt((randVec.x^2) + (randVec.y^2))
    randVec.x = randVec.x / magnitude
    randVec.y = randVec.y / magnitude
    log("direction: x=" .. randVec.x .. ", y=" .. randVec.y)
    return randVec
end

---Check for ungenerated chunks around a specific chunk +/- chunkDist in x and y directions
---@param chunkPos MapPosition
---@param chunkDist integer
---@param surface LuaSurface
---@return boolean
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
---@param pos MapPosition
---@param safeDist number
---@param surface LuaSurface
function ClearNearbyEnemies(pos, safeDist, surface)
    local safeArea = {
        left_top =
        {
            x = pos.x - safeDist,
            y = pos.y - safeDist
        },
        right_bottom =
        {
            x = pos.x + safeDist,
            y = pos.y + safeDist
        }
    }

    for _, entity in pairs(surface.find_entities_filtered { area = safeArea, force = "enemy" }) do
        entity.destroy()
    end
end

-- ---Function to find coordinates of ungenerated map area in a given direction starting from the center of the map
-- ---@param direction_vector MapPosition
-- ---@param surface LuaSurface
-- ---@return MapPosition
-- function FindMapEdge(direction_vector, surface)
--     local position = {x=0,y=0}
--     local chunk_position = {x=0,y=0}

--     -- Keep checking chunks in the direction of the vector
--     while(true) do

--         -- Set some absolute limits.
--         if ((math.abs(chunk_position.x) > 1000) or (math.abs(chunk_position.y) > 1000)) then
--             break

--         -- If chunk is already generated, keep looking
--         elseif (surface.is_chunk_generated(chunk_position)) then
--             chunk_position.x = chunk_position.x + direction_vector.x
--             chunk_position.y = chunk_position.y + direction_vector.y

--         -- Found a possible ungenerated area
--         else

--             chunk_position.x = chunk_position.x + direction_vector.x
--             chunk_position.y = chunk_position.y + direction_vector.y

--             -- Check there are no generated chunks in a 10x10 area.
--             if IsChunkAreaUngenerated(chunk_position, 10, surface) then
--                 position.x = (chunk_position.x*CHUNK_SIZE) + (CHUNK_SIZE/2)
--                 position.y = (chunk_position.y*CHUNK_SIZE) + (CHUNK_SIZE/2)
--                 break
--             end
--         end
--     end

--     -- log("spawn: x=" .. position.x .. ", y=" .. position.y)
--     return position
-- end


---Pick a random direction, go at least the minimum distance, and start looking for ungenerated chunks
---We try a few times (hardcoded) and then try a different random direction if we fail (up to max_tries)
---@param surface LuaSurface
---@param minimum_distance_chunks number Distance in chunks to start looking for ungenerated chunks
---@param max_tries integer Maximum number of tries to find a spawn point
---@return MapPosition
function FindUngeneratedCoordinates(surface, minimum_distance_chunks, max_tries)

    --- Get a random vector, figure out how many times to multiply it to get the minimum distance
    local direction_vector = GetRandomVector()
    local start_distance_tiles = minimum_distance_chunks * CHUNK_SIZE
    
    local final_position = {x=0,y=0}
    local tries_remaining = max_tries - 1

    -- Starting search position
    local search_pos = {
        x=direction_vector.x * start_distance_tiles,
        y=direction_vector.y * start_distance_tiles
    }

    -- We check up to THIS many times, each jump moves out by minimum_distance_to_existing_chunks
    local jumps_count = 3

    local minimum_distance_to_existing_chunks = global.ocfg.gameplay.minimum_distance_to_existing_chunks

    -- Keep checking chunks in the direction of the vector, assumes this terminates...
    while(true) do

        local chunk_position = GetChunkPosFromTilePos(search_pos)

        if (jumps_count <= 0) then

            if (tries_remaining > 0) then
                return FindUngeneratedCoordinates(surface, minimum_distance_chunks, tries_remaining)
            else
                log("WARNING - FindUngeneratedCoordinates - Hit max distance!")
                break
            end

        -- If chunk is already generated, keep looking further out
        elseif (surface.is_chunk_generated(chunk_position)) then

            -- For debugging, ping the map
            -- SendBroadcastMsg("GENERATED: " .. GetGPStext(surface.name, {x=chunk_position.x*32, y=chunk_position.y*32}))

             -- Move out a bit more to give some space and then check the surrounding area
             search_pos.x = search_pos.x + (direction_vector.x * CHUNK_SIZE * minimum_distance_to_existing_chunks)
             search_pos.y = search_pos.y + (direction_vector.y * CHUNK_SIZE * minimum_distance_to_existing_chunks)

        -- Found a possible ungenerated area
        elseif IsChunkAreaUngenerated(chunk_position, minimum_distance_to_existing_chunks, surface) then

            -- For debugging, ping the map
            -- SendBroadcastMsg("SUCCESS: " .. GetGPStext(surface.name, {x=chunk_position.x*32, y=chunk_position.y*32}))

            -- Place the spawn in the center of a chunk
            final_position.x = (chunk_position.x * CHUNK_SIZE) + (CHUNK_SIZE/2)
            final_position.y = (chunk_position.y * CHUNK_SIZE) + (CHUNK_SIZE/2)
            break
        
        -- The area around the chunk is not clear, keep looking
        else

            -- For debugging, ping the map
            -- SendBroadcastMsg("NOT CLEAR: " .. GetGPStext(surface.name, {x=chunk_position.x*32, y=chunk_position.y*32}))

            -- Move out a bit more to give some space and then check the surrounding area
            search_pos.x = search_pos.x + (direction_vector.x * CHUNK_SIZE * minimum_distance_to_existing_chunks)
            search_pos.y = search_pos.y + (direction_vector.y * CHUNK_SIZE * minimum_distance_to_existing_chunks)
        end

        jumps_count = jumps_count - 1
    end

    if (final_position.x == 0 and final_position.y == 0) then
        log("WARNING! FindUngeneratedCoordinates - Failed to find a spawn point!")
    end

    return final_position
end

-- -- General purpose function for removing a particular recipe
-- function RemoveRecipe(force, recipeName)
--     local recipes = force.recipes
--     if recipes[recipeName] then
--         recipes[recipeName].enabled = false
--     end
-- end

-- -- General purpose function for adding a particular recipe
-- function AddRecipe(force, recipeName)
--     local recipes = force.recipes
--     if recipes[recipeName] then
--         recipes[recipeName].enabled = true
--     end
-- end

-- -- General command for disabling a tech.
-- function DisableTech(force, techName)
--     if force.technologies[techName] then
--         force.technologies[techName].enabled = false
--         force.technologies[techName].visible_when_disabled = true
--     end
-- end

-- -- General command for enabling a tech.
-- function EnableTech(force, techName)
--     if force.technologies[techName] then
--         force.technologies[techName].enabled = true
--     end
-- end


---Get a square area given a position and distance. Square length = 2x distance
---@param pos MapPosition
---@param dist number
---@return BoundingBox
function GetAreaAroundPos(pos, dist)
    return {
        left_top =
        {
            x = pos.x - dist,
            y = pos.y - dist
        },
        right_bottom =
        {
            x = pos.x + dist,
            y = pos.y + dist
        }
    }
end

---Gets chunk position of a tile.
---@param tile_pos TilePosition
---@return ChunkPosition
function GetChunkPosFromTilePos(tile_pos)
    return {x=math.floor(tile_pos.x/32), y=math.floor(tile_pos.y/32)}
end

-- function GetCenterTilePosFromChunkPos(c_pos)
--     return {x=c_pos.x*32 + 16, y=c_pos.y*32 + 16}
-- end

-- -- Get the left_top
-- function GetChunkTopLeft(pos)
--     return {x=pos.x-(pos.x % 32), y=pos.y-(pos.y % 32)}
-- end

-- -- Get area given chunk
-- function GetAreaFromChunkPos(chunk_pos)
--     return {left_top={x=chunk_pos.x*32, y=chunk_pos.y*32},
--             right_bottom={x=chunk_pos.x*32+31, y=chunk_pos.y*32+31}}
-- end

-- Removes the entity type from the area given
-- function RemoveInArea(surface, area, type)
--     for key, entity in pairs(surface.find_entities_filtered{area=area, type= type}) do
--         if entity.valid and entity and entity.position then
--             entity.destroy()
--         end
--     end
-- end

---Removes the entity type from the area given. Only if it is within given distance from given position.
---@param surface LuaSurface
---@param area BoundingBox
---@param type string|string[]
---@param pos MapPosition
---@param dist number
---@return nil
function RemoveInCircle(surface, area, type, pos, dist)
    for _, entity in pairs(surface.find_entities_filtered { area = area, type = type }) do
        if entity.valid and entity and entity.position then
            if ((pos.x - entity.position.x) ^ 2 + (pos.y - entity.position.y) ^ 2 < dist ^ 2) then
                entity.destroy()
            end
        end
    end
end

---Removes the entity type from the area given. Only if it is within given distance from given position.
---@param surface LuaSurface
---@param area BoundingBox
---@param type string|string[]
---@param pos MapPosition
---@param dist number
---@return nil
function RemoveInSquare(surface, area, type, pos, dist)
    for _, entity in pairs(surface.find_entities_filtered { area = area, type = type }) do
        if entity.valid and entity and entity.position then
            local max_distance = math.max(math.abs(pos.x - entity.position.x), math.abs(pos.y - entity.position.y))
            if (max_distance < dist) then
                entity.destroy()
            end
        end
    end
end

-- -- For easy local testing of map gen settings. Just set what you want and uncomment usage in CreateGameSurface!
-- function SurfaceSettingsHelper(settings)

--     settings.terrain_segmentation = 4
--     settings.water = 3
--     settings.starting_area = 0

--     local r_freq = 1.20
--     local r_rich = 5.00
--     local r_size = 0.18

--     settings.autoplace_controls["coal"].frequency = r_freq
--     settings.autoplace_controls["coal"].richness = r_rich
--     settings.autoplace_controls["coal"].size = r_size
--     settings.autoplace_controls["copper-ore"].frequency = r_freq
--     settings.autoplace_controls["copper-ore"].richness = r_rich
--     settings.autoplace_controls["copper-ore"].size = r_size
--     settings.autoplace_controls["crude-oil"].frequency = r_freq
--     settings.autoplace_controls["crude-oil"].richness = r_rich
--     settings.autoplace_controls["crude-oil"].size = r_size
--     settings.autoplace_controls["iron-ore"].frequency = r_freq
--     settings.autoplace_controls["iron-ore"].richness = r_rich
--     settings.autoplace_controls["iron-ore"].size = r_size
--     settings.autoplace_controls["stone"].frequency = r_freq
--     settings.autoplace_controls["stone"].richness = r_rich
--     settings.autoplace_controls["stone"].size = r_size
--     settings.autoplace_controls["uranium-ore"].frequency = r_freq*0.5
--     settings.autoplace_controls["uranium-ore"].richness = r_rich
--     settings.autoplace_controls["uranium-ore"].size = r_size

--     settings.autoplace_controls["enemy-base"].frequency = 0.80
--     settings.autoplace_controls["enemy-base"].richness = 0.70
--     settings.autoplace_controls["enemy-base"].size = 0.70

--     settings.autoplace_controls["trees"].frequency = 1.00
--     settings.autoplace_controls["trees"].richness = 1.00
--     settings.autoplace_controls["trees"].size = 1.00

--     settings.cliff_settings.cliff_elevation_0 = 3
--     settings.cliff_settings.cliff_elevation_interval = 200
--     settings.cliff_settings.richness = 3

--     settings.property_expression_names["control-setting:aux:bias"] = "0.00"
--     settings.property_expression_names["control-setting:aux:frequency:multiplier"] = "5.00"
--     settings.property_expression_names["control-setting:moisture:bias"] = "0.40"
--     settings.property_expression_names["control-setting:moisture:frequency:multiplier"] = "50"

--     return settings
-- end

-- -- Create another surface so that we can modify map settings and not have a screwy nauvis map.
-- function CreateGameSurface()

--     if (GAME_SURFACE_NAME ~= "nauvis") then

--         -- Get starting surface settings.
--         local nauvis_settings =  game.surfaces["nauvis"].map_gen_settings

--         if global.ocfg.enable_vanilla_spawns then
--             nauvis_settings.starting_points = CreateVanillaSpawns(global.ocfg.vanilla_spawn_count, global.ocfg.vanilla_spawn_spacing)

--             -- ENFORCE ISLAND MAP GEN
--             if (global.ocfg.silo_islands) then
--                 nauvis_settings.property_expression_names.elevation = "0_17-island"
--             end
--         end

--         -- Enable this to test things out easily.
--         -- nauvis_settings = SurfaceSettingsHelper(nauvis_settings)

--         -- Create new game surface
--         local s = game.create_surface(GAME_SURFACE_NAME, nauvis_settings)

--     end

--     -- Add surface and safe areas
--     if global.ocfg.enable_regrowth then
--         RegrowthMarkAreaSafeGivenChunkPos({x=0,y=0}, 4, true)
--     end
-- end

-- function CreateTileArrow(surface, pos, type)

--     tiles = {}

--     if (type == "LEFT") then
--         table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x, pos.y}})
--         table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+1, pos.y}})
--         table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+2, pos.y}})
--         table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+3, pos.y}})
--         table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x, pos.y+1}})
--         table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+1, pos.y+1}})
--         table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+2, pos.y+1}})
--         table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+3, pos.y+1}})
--     elseif (type == "RIGHT") then
--         table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x, pos.y}})
--         table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+1, pos.y}})
--         table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+2, pos.y}})
--         table.insert(tiles, {name = "hazard-concrete-right", position = {pos.x+3, pos.y}})
--         table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x, pos.y+1}})
--         table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+1, pos.y+1}})
--         table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+2, pos.y+1}})
--         table.insert(tiles, {name = "hazard-concrete-left", position = {pos.x+3, pos.y+1}})
--     end

--     surface.set_tiles(tiles, true)
-- end

-- -- Allowed colors: red, green, blue, orange, yellow, pink, purple, black, brown, cyan, acid
-- function CreateFixedColorTileArea(surface, area, color)

--     tiles = {}

--     for i=area.left_top.x,area.right_bottom.x do
--         for j=area.left_top.y,area.right_bottom.y do
--             table.insert(tiles, {name = color.."-refined-concrete", position = {i,j}})
--         end
--     end

--     surface.set_tiles(tiles, true)
-- end

-- -- Find closest player-owned entity
-- function FindClosestPlayerOwnedEntity(player, name, radius)

--     local entities = player.surface.find_entities_filtered{position=player.position,
--                                             radius=radius,
--                                             name=name,
--                                             force=player.force}
--     if (not entities or (#entities == 0)) then return nil end

--     return player.surface.get_closest(player.position, entities)
-- end

-- -- Add Long Reach to Character
-- function GivePlayerLongReach(player)
--     player.character.character_build_distance_bonus = BUILD_DIST_BONUS
--     player.character.character_reach_distance_bonus = REACH_DIST_BONUS
--     -- player.character.character_resource_reach_distance_bonus  = RESOURCE_DIST_BONUS
-- end

-- -- General purpose cover an area in tiles.
-- function CoverAreaInTiles(surface, area, tile_name)
--     tiles = {}
--     for x = area.left_top.x,area.left_top.x+31 do
--         for y = area.left_top.y,area.left_top.y+31 do
--             table.insert(tiles, {name = tile_name, position = {x=x, y=y}})
--         end
--     end
--     surface.set_tiles(tiles, true)
-- end

-- --------------------------------------------------------------------------------
-- -- Anti-griefing Stuff & Gravestone (My own version)
-- --------------------------------------------------------------------------------
-- function AntiGriefing(force)
--     force.zoom_to_world_deconstruction_planner_enabled=false
--     SetForceGhostTimeToLive(force)
-- end

-- function SetForceGhostTimeToLive(force)
--     if global.ocfg.ghost_ttl ~= 0 then
--         force.ghost_time_to_live = global.ocfg.ghost_ttl+1
--     end
-- end

-- function SetItemBlueprintTimeToLive(event)
--     local type = event.created_entity.type
--     if type == "entity-ghost" or type == "tile-ghost" then
--         if global.ocfg.ghost_ttl ~= 0 then
--             event.created_entity.time_to_live = global.ocfg.ghost_ttl
--         end
--     end
-- end

-- --------------------------------------------------------------------------------
-- -- Gravestone soft mod. With my own modifications/improvements.
-- --------------------------------------------------------------------------------
-- -- Return steel chest entity (or nil)
-- function DropEmptySteelChest(player)
--     local pos = player.surface.find_non_colliding_position("steel-chest", player.position, 15, 1)
--     if not pos then
--         return nil
--     end
--     local grave = player.surface.create_entity{name="steel-chest", position=pos, force="neutral"}
--     return grave
-- end

-- function DropGravestoneChests(player)

--     local grave
--     local count = 0

--     -- Make sure we save stuff we're holding in our hands.
--     player.clean_cursor()

--     -- Loop through a players different inventories
--     -- Put it all into a chest.
--     -- If the chest is full, create a new chest.
--     for i, id in ipairs{
--         defines.inventory.character_armor,
--         defines.inventory.character_main,
--         defines.inventory.character_guns,
--         defines.inventory.character_ammo,
--         defines.inventory.character_vehicle,
--         defines.inventory.character_trash} do

--         local inv = player.get_inventory(id)

--         -- No idea how inv can be nil sometimes...?
--         if (inv ~= nil) then
--             if ((#inv > 0) and not inv.is_empty()) then
--                 for j = 1, #inv do
--                     if inv[j].valid_for_read then

--                         -- Create a chest when counter is reset
--                         if (count == 0) then
--                             grave = DropEmptySteelChest(player)
--                             if (grave == nil) then
--                                 -- player.print("Not able to place a chest nearby! Some items lost!")
--                                 return
--                             end
--                             grave_inv = grave.get_inventory(defines.inventory.chest)
--                         end
--                         count = count + 1

--                         -- Copy the item stack into a chest slot.
--                         grave_inv[count].set_stack(inv[j])

--                         -- Reset counter when chest is full
--                         if (count == #grave_inv) then
--                             count = 0
--                         end
--                     end
--                 end
--             end

--             -- Clear the player inventory so we don't have duplicate items lying around.
--             inv.clear()
--         end
--     end

--     if (grave ~= nil) then
--         player.print("Successfully dropped your items into a chest! Go get them quick!")
--     end
-- end

-- -- Dump player items into a chest after the body expires.
-- function DropGravestoneChestFromCorpse(corpse)
--     if ((corpse == nil) or (corpse.character_corpse_player_index == nil)) then return end

--     local grave, grave_inv
--     local count = 0

--     local inv = corpse.get_inventory(defines.inventory.character_corpse)

--     -- No idea how inv can be nil sometimes...?
--     if (inv ~= nil) then
--         if ((#inv > 0) and not inv.is_empty()) then
--             for j = 1, #inv do
--                 if inv[j].valid_for_read then

--                     -- Create a chest when counter is reset
--                     if (count == 0) then
--                         grave = DropEmptySteelChest(corpse)
--                         if (grave == nil) then
--                             -- player.print("Not able to place a chest nearby! Some items lost!")
--                             return
--                         end
--                         grave_inv = grave.get_inventory(defines.inventory.chest)
--                     end
--                     count = count + 1

--                     -- Copy the item stack into a chest slot.
--                     grave_inv[count].set_stack(inv[j])

--                     -- Reset counter when chest is full
--                     if (count == #grave_inv) then
--                         count = 0
--                     end
--                 end
--             end
--         end

--         -- Clear the player inventory so we don't have duplicate items lying around.
--         -- inv.clear()
--     end

--     if (grave ~= nil) and (game.players[corpse.character_corpse_player_index] ~= nil)then
--         game.players[corpse.character_corpse_player_index].print("Your corpse got eaten by biters! They kindly dropped your items into a chest! Go get them quick!")
--     end

-- end

-- --------------------------------------------------------------------------------
-- -- Item/Inventory stuff (used in autofill)
-- --------------------------------------------------------------------------------

-- -- Transfer Items Between Inventory
-- -- Returns the number of items that were successfully transferred.
-- -- Returns -1 if item not available.
-- -- Returns -2 if can't place item into destInv (ERROR)
-- function TransferItems(srcInv, destEntity, itemStack)
--     -- Check if item is in srcInv
--     if (srcInv.get_item_count(itemStack.name) == 0) then
--         return -1
--     end

--     -- Check if can insert into destInv
--     if (not destEntity.can_insert(itemStack)) then
--         return -2
--     end

--     -- Insert items
--     local itemsRemoved = srcInv.remove(itemStack)
--     itemStack.count = itemsRemoved
--     return destEntity.insert(itemStack)
-- end

-- -- Attempts to transfer at least some of one type of item from an array of items.
-- -- Use this to try transferring several items in order
-- -- It returns once it successfully inserts at least some of one type.
-- function TransferItemMultipleTypes(srcInv, destEntity, itemNameArray, itemCount)
--     local ret = 0
--     for _,itemName in pairs(itemNameArray) do
--         ret = TransferItems(srcInv, destEntity, {name=itemName, count=itemCount})
--         if (ret > 0) then
--             return ret -- Return the value succesfully transferred
--         end
--     end
--     return ret -- Return the last error code
-- end

-- -- Autofills a turret with ammo
-- function AutofillTurret(player, turret)
--     local mainInv = player.get_main_inventory()
--     if (mainInv == nil) then return end

--     -- Attempt to transfer some ammo
--     local ret = TransferItemMultipleTypes(mainInv, turret, {"uranium-rounds-magazine", "piercing-rounds-magazine", "firearm-magazine"}, AUTOFILL_TURRET_AMMO_QUANTITY)

--     -- Check the result and print the right text to inform the user what happened.
--     if (ret > 0) then
--         -- Inserted ammo successfully
--         -- FlyingText("Inserted ammo x" .. ret, turret.position, my_color_red, player.surface)
--     elseif (ret == -1) then
--         FlyingText("Out of ammo!", turret.position, my_color_red, player.surface)
--     elseif (ret == -2) then
--         FlyingText("Autofill ERROR! - Report this bug!", turret.position, my_color_red, player.surface)
--     end
-- end

-- -- Autofills a vehicle with fuel, bullets and shells where applicable
-- function AutoFillVehicle(player, vehicle)
--     local mainInv = player.get_main_inventory()
--     if (mainInv == nil) then return end

--     -- Attempt to transfer some fuel
--     if ((vehicle.name == "car") or (vehicle.name == "tank") or (vehicle.name == "locomotive")) then
--         TransferItemMultipleTypes(mainInv, vehicle, {"nuclear-fuel", "rocket-fuel", "solid-fuel", "coal", "wood"}, 50)
--     end

--     -- Attempt to transfer some ammo
--     if ((vehicle.name == "car") or (vehicle.name == "tank")) then
--         TransferItemMultipleTypes(mainInv, vehicle, {"uranium-rounds-magazine", "piercing-rounds-magazine", "firearm-magazine"}, 100)
--     end

--     -- Attempt to transfer some tank shells
--     if (vehicle.name == "tank") then
--         TransferItemMultipleTypes(mainInv, vehicle, {"explosive-uranium-cannon-shell", "uranium-cannon-shell", "explosive-cannon-shell", "cannon-shell"}, 100)
--     end
-- end

-- --------------------------------------------------------------------------------
-- -- Resource patch and starting area generation
-- --------------------------------------------------------------------------------

---Circle spawn shape (handles land, trees and moat)
---@param surface LuaSurface
---@param centerPos MapPosition
---@param chunkArea BoundingBox
---@param tileRadius number
---@param fillTile string
---@param moat boolean
---@param bridge boolean
---@return nil
function CreateCropCircle(surface, centerPos, chunkArea, tileRadius, fillTile, moat, bridge)
    local tile_radius_sqr = tileRadius ^ 2

    local moat_width = global.ocfg.spawn_general.moat_width_tiles
    local moat_radius_sqr = ((tileRadius + moat_width)^2)

    local tree_width = global.ocfg.spawn_general.tree_width_tiles
    local tree_radius_sqr_inner = ((tileRadius - 1 - tree_width) ^ 2) -- 1 less to make sure trees are inside the spawn area
    local tree_radius_sqr_outer = ((tileRadius - 1) ^ 2)

    local dirtTiles = {}
    for i = chunkArea.left_top.x, chunkArea.right_bottom.x, 1 do
        for j = chunkArea.left_top.y, chunkArea.right_bottom.y, 1 do
            
            -- This ( X^2 + Y^2 ) is used to calculate if something is inside a circle area.
            -- We avoid using sqrt for performance reasons.
            local distSqr = math.floor((centerPos.x - i) ^ 2 + (centerPos.y - j) ^ 2)

            -- Fill in all unexpected water (or force grass)
            if (distSqr <= tile_radius_sqr) then
                if (surface.get_tile(i, j).collides_with("water-tile") or
                        global.ocfg.spawn_general.force_grass) then
                    table.insert(dirtTiles, { name = fillTile, position = { i, j } })
                end
            end

            -- Create a tree ring
            if ((distSqr < tree_radius_sqr_outer) and (distSqr > tree_radius_sqr_inner)) then
                surface.create_entity({ name = "tree-02", amount = 1, position = { i, j } })
            end

            -- Fill moat with water.
            if (moat) then
                if (bridge and ((j == centerPos.y - 1) or (j == centerPos.y) or (j == centerPos.y + 1))) then
                    -- This will leave the tiles "as is" on the left and right of the spawn which has the effect of creating
                    -- land connections if the spawn is on or near land.
                elseif ((distSqr < moat_radius_sqr) and (distSqr > tile_radius_sqr)) then
                    table.insert(dirtTiles, { name = "water", position = { i, j } })
                end
            end
        end
    end

    surface.set_tiles(dirtTiles)
end

---` spawn shape (handles land, trees and moat) (Curtesy of jvmguy)
---@param surface LuaSurface
---@param centerPos MapPosition
---@param chunkArea BoundingBox
---@param tileRadius number
---@param fillTile string
---@param moat boolean
---@param bridge boolean
---@return nil
function CreateCropOctagon(surface, centerPos, chunkArea, tileRadius, fillTile, moat, bridge)

    local moat_width = global.ocfg.spawn_general.moat_width_tiles
    local moat_width_outer = tileRadius + moat_width

    local tree_width = global.ocfg.spawn_general.tree_width_tiles
    local tree_distance_inner = tileRadius - tree_width

    local dirtTiles = {}
    for i = chunkArea.left_top.x, chunkArea.right_bottom.x, 1 do
        for j = chunkArea.left_top.y, chunkArea.right_bottom.y, 1 do

            local distVar1 = math.floor(math.max(math.abs(centerPos.x - i), math.abs(centerPos.y - j)))
            local distVar2 = math.floor(math.abs(centerPos.x - i) + math.abs(centerPos.y - j))
            local distVar = math.max(distVar1, distVar2 * 0.707);

            -- Fill in all unexpected water (or force grass)
            if (distVar <= tileRadius) then
                if (surface.get_tile(i, j).collides_with("water-tile") or
                        global.ocfg.spawn_general.force_grass) then
                    table.insert(dirtTiles, { name = fillTile, position = { i, j } })
                end
            end

            -- Create a tree ring
            if ((distVar < tileRadius) and (distVar >= tree_distance_inner)) then
                surface.create_entity({ name = "tree-01", amount = 1, position = { i, j } })
            end

            -- Fill moat with water
            if (moat) then
                if (bridge and ((j == centerPos.y - 1) or (j == centerPos.y) or (j == centerPos.y + 1))) then
                    -- This will leave the tiles "as is" on the left and right of the spawn which has the effect of creating
                    -- land connections if the spawn is on or near land.
                elseif ((distVar > tileRadius) and (distVar <= moat_width_outer)) then
                    table.insert(dirtTiles, { name = "water", position = { i, j } })
                end
            end
        end
    end
    surface.set_tiles(dirtTiles)
end

---Square spawn shape (handles land, trees and moat) 
---@param surface LuaSurface
---@param centerPos MapPosition
---@param chunkArea BoundingBox
---@param tileRadius number
---@param fillTile string
---@param moat boolean
---@param bridge boolean
---@return nil
function CreateCropSquare(surface, centerPos, chunkArea, tileRadius, fillTile, moat, bridge)

    local moat_width = global.ocfg.spawn_general.moat_width_tiles
    local moat_width_outer = tileRadius + moat_width

    local tree_width = global.ocfg.spawn_general.tree_width_tiles
    local tree_distance_inner = tileRadius - tree_width

    local dirtTiles = {}
    for i = chunkArea.left_top.x, chunkArea.right_bottom.x, 1 do
        for j = chunkArea.left_top.y, chunkArea.right_bottom.y, 1 do

            -- Max distance from center (either x or y)
            local max_distance = math.max(math.abs(centerPos.x - i), math.abs(centerPos.y - j))

            -- Fill in all unexpected water (or force grass)
            if (max_distance <= tileRadius) then
                if (surface.get_tile(i, j).collides_with("water-tile") or
                        global.ocfg.spawn_general.force_grass) then
                    table.insert(dirtTiles, { name = fillTile, position = { i, j } })
                end
            end

            -- Create a tree ring
            if ((max_distance < tileRadius) and (max_distance >= tree_distance_inner)) then
                surface.create_entity({ name = "tree-02", amount = 1, position = { i, j } })
            end

            -- Fill moat with water
            if (moat) then
                if (bridge and ((j == centerPos.y - 1) or (j == centerPos.y) or (j == centerPos.y + 1))) then
                    -- This will leave the tiles "as is" on the left and right of the spawn which has the effect of creating
                    -- land connections if the spawn is on or near land.
                elseif ((max_distance > tileRadius) and (max_distance <= moat_width_outer)) then
                    table.insert(dirtTiles, { name = "water", position = { i, j } })
                end
            end
        end
    end

    surface.set_tiles(dirtTiles)
end

---Add a circle of water
---@param surface LuaSurface
---@param centerPos MapPosition
---@param chunkArea BoundingBox
---@param tileRadius number
---@param moatTile string
---@param bridge boolean
---@param shape SpawnShapeChoice
---@return nil
function CreateMoat(surface, centerPos, chunkArea, tileRadius, moatTile, bridge, shape)
    local tileRadSqr = tileRadius ^ 2

    local tiles = {}
    for i = chunkArea.left_top.x, chunkArea.right_bottom.x, 1 do
        for j = chunkArea.left_top.y, chunkArea.right_bottom.y, 1 do
            if (bridge and ((j == centerPos.y - 1) or (j == centerPos.y) or (j == centerPos.y + 1))) then
                -- This will leave the tiles "as is" on the left and right of the spawn which has the effect of creating
                -- land connections if the spawn is on or near land.
            else
                -- This ( X^2 + Y^2 ) is used to calculate if something
                -- is inside a circle area.
                local distVar = math.floor((centerPos.x - i) ^ 2 + (centerPos.y - j) ^ 2)

                -- Create a circle of water
                if ((distVar < tileRadSqr + (1500 * global.ocfg.spawn_general.moat_width_tiles)) and
                        (distVar > tileRadSqr)) then
                    table.insert(tiles, { name = moatTile, position = { i, j } })
                end
            end
        end
    end

    surface.set_tiles(tiles)
end

-- Create a horizontal line of water
---@param surface LuaSurface
---@param leftPos TilePosition
---@param length integer
function CreateWaterStrip(surface, leftPos, length)
    local waterTiles = {}
    for i = 0, length-1, 1 do
        table.insert(waterTiles, { name = "water", position = { leftPos.x + i, leftPos.y } })
    end
    surface.set_tiles(waterTiles)
end

--- Function to generate a resource patch, of a certain size/amount at a pos.
---@param surface LuaSurface
---@param resourceName string
---@param diameter integer
---@param position TilePosition
---@param amount integer
function GenerateResourcePatch(surface, resourceName, diameter, position, amount)
    local midPoint = math.floor(diameter / 2)
    if (diameter == 0) then
        return
    end

    -- Right now only 2 shapes are supported. Circle and Square.
    local square_shape = (global.ocfg.spawn_general.resources_shape == RESOURCES_SHAPE_CHOICE_SQUARE)

    for y = -midPoint, midPoint do
        for x = -midPoint, midPoint do

            -- Either it's a square, or it's a circle so we check if it's inside the circle.
            if (square_shape or ((x) ^ 2 + (y) ^ 2 < midPoint ^ 2)) then
                surface.create_entity({
                    name = resourceName,
                    amount = amount,
                    position = { position.x + x, position.y + y }
                })
            end
        end
    end
end

-- --------------------------------------------------------------------------------
-- -- Holding pen for new players joining the map
-- --------------------------------------------------------------------------------
-- function CreateWall(surface, pos)
--     local wall = surface.create_entity({name="stone-wall", position=pos, force=MAIN_TEAM})
--     if wall then
--         wall.destructible = false
--         wall.minable = false
--     end
-- end

-- function CreateHoldingPen(surface, chunkArea)
--     local radiusTiles = global.ocfg.spawn_config.general.spawn_radius_tiles-10
--     if (((chunkArea.left_top.x >= -(radiusTiles+2*CHUNK_SIZE)) and (chunkArea.left_top.x <= (radiusTiles+2*CHUNK_SIZE))) and
--         ((chunkArea.left_top.y >= -(radiusTiles+2*CHUNK_SIZE)) and (chunkArea.left_top.y <= (radiusTiles+2*CHUNK_SIZE)))) then

--         -- Remove stuff
--         RemoveAliensInArea(surface, chunkArea)
--         RemoveInArea(surface, chunkArea, "tree")
--         RemoveInArea(surface, chunkArea, "resource")
--         RemoveInArea(surface, chunkArea, "cliff")

--         CreateCropCircle(surface, {x=0,y=0}, chunkArea, radiusTiles, "landfill")
--         CreateMoat(surface, {x=0,y=0}, chunkArea, radiusTiles, "water", false)
--         CreateMoat(surface, {x=0,y=0}, chunkArea, radiusTiles+10, "out-of-map", false)
--         CreateMoat(surface, {x=0,y=0}, chunkArea, 2, "out-of-map", false)
--     end
-- end

-- --------------------------------------------------------------------------------
-- -- EVENT SPECIFIC FUNCTIONS
-- --------------------------------------------------------------------------------

-- -- Display messages to a user everytime they join
-- function PlayerJoinedMessages(event)
--     local player = game.players[event.player_index]
--     player.print(global.ocfg.welcome_msg)
--     if (global.oarc_announcements) then
--         player.print(global.oarc_announcements)
--     end
-- end

-- -- Remove decor to save on file size
-- function UndecorateOnChunkGenerate(event)
--     local surface = event.surface
--     local chunkArea = event.area
--     RemoveDecorationsArea(surface, chunkArea)
--     -- If you care to, you can remove all fish with the Undecorator option here:
--     -- RemoveFish(surface, chunkArea)
-- end

-- -- Autofill softmod
-- function Autofill(event)
--     local player = game.players[event.player_index]
--     local eventEntity = event.created_entity

--     -- Make sure player isn't dead?
--     if (player.character == nil) then return end

--     if (eventEntity.name == "gun-turret") then
--         AutofillTurret(player, eventEntity)
--     end

--     if ((eventEntity.name == "car") or (eventEntity.name == "tank") or (eventEntity.name == "locomotive")) then
--         AutoFillVehicle(player, eventEntity)
--     end
-- end
