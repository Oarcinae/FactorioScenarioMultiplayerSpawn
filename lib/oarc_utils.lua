-- My general purpose utility functions and constants for factorio
-- Also contains some constants

-- (Ignore the diagnostic warning.)
---@diagnostic disable-next-line: different-requires
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

-- Get a printable GPS string
---@param surface_name string
---@param position MapPosition
---@return string
function GetGPStext(surface_name, position)
    return "[gps=" .. position.x .. "," .. position.y .. "," .. surface_name .. "]"
end

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
    local render_object = rendering.draw_text { text = text,
        surface = surface,
        target = position,
        color = { 0.7, 0.7, 0.7, 0.7 },
        scale = 1,
        font = "compi",
        time_to_live = ttl,
        alignment = alignment,
        draw_on_ground = false }
    local rid = render_object.id
    table.insert(storage.oarc_renders_fadeout, rid)
end

---Every tick, check a global table to see if we have any rendered thing that needs fading out.
---@return nil
function FadeoutRenderOnTick()
    if (storage.oarc_renders_fadeout and (#storage.oarc_renders_fadeout > 0)) then
        for k, rid in pairs(storage.oarc_renders_fadeout) do
            local render_object = rendering.get_object_by_id(rid)
            if (render_object and render_object.valid) then
                local ttl = render_object.time_to_live
                if ((ttl > 0) and (ttl < 200)) then
                    local color = render_object.color
                    if (color.a > 0.005) then
                        render_object.color = { r = color.r, g = color.g, b = color.b, a = color.a - 0.005 }
                    end
                end
            else
                storage.oarc_renders_fadeout[k] = nil
            end
        end
    end
end

---@type boolean?
local has_better_chat = nil
--- Safely attempts to print via the Better Chatting's interface
---@param recipient LuaGameScript|LuaForce|LuaPlayer
---@param msg LocalisedString
---@param print_settings PrintSettings?
---@return nil
function CompatSend(recipient, msg, print_settings)
    if has_better_chat == nil then
        local better_chat = remote.interfaces["better-chat"]
        has_better_chat = better_chat and better_chat["send"]
    end

    if not has_better_chat then return recipient.print(msg, print_settings) end
    print_settings = print_settings or {}


    ---@type "global"|"force"|"player", int?
    local send_level, send_index
    local recipient_type = recipient.object_name

    if recipient_type == "LuaGameScript" then
        send_level = "global"
    else
        ---@cast recipient -LuaGameScript
        send_index = recipient.index
        if recipient_type == "LuaForce" then
            send_level = "force"
        elseif recipient_type == "LuaPlayer" then
            send_level = "player"
        else
            error("Invalid Recipient", 2)
        end
    end

    remote.call("better-chat", "send", {
        message = msg,
        send_level = send_level,
        color = print_settings.color,
        recipient = send_index,
    })
end

--- Broadcast messages to all connected players
---@param msg LocalisedString
---@param print_settings PrintSettings?
---@return nil
function SendBroadcastMsg(msg, print_settings)
    CompatSend(game, msg, print_settings)
end

---Send an error message to a player using their name, but first safely checks if they exist and are online.
---@param player_name string
---@param msg LocalisedString
---@return nil
function SendErrorMsgUsingName(player_name, msg)
    local player = game.players[player_name]
    if ((player ~= nil) and (player.connected)) then
        SendErrorMsg(player, msg)
    end
end

---@param player LuaPlayer
---@param msg LocalisedString
---@return nil
function SendErrorMsg(player, msg)
    CompatSend(player, msg, { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
end

---Checks if a string starts with another string
---@param string string The string to check
---@param start string The starting string to look for
function StringStartsWith(string, start)
    return string:sub(1, #start) == start
end

---Checks if a surface is blacklisted based on the storage.ocfg settings
---@param surface_name string
---@return boolean --true if blacklisted
function IsSurfaceBlacklisted(surface_name)
    if (storage.ocfg.surfaces_blacklist ~= nil) then
        for _,name in pairs(storage.ocfg.surfaces_blacklist) do
            if (name == surface_name) then
                return true
            end
        end
    end

    if (storage.ocfg.surfaces_blacklist_match ~= nil) then
        for _,match in pairs(storage.ocfg.surfaces_blacklist_match) do
            if (StringStartsWith(surface_name, match)) then
                return true
            end
        end
    end

    return false
end

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
  local total_minutes = math.floor((seconds)/60)
  local hours   = math.floor((total_minutes)/60)
  local minutes = math.floor(total_minutes - 60*hours)
  return string.format("%dh:%02dm", hours, minutes)
end

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

function TableRemoveOneUsingPairs(t, val)
    for k,v in pairs(t) do
        if v == val then
            table.remove(t, k)
            return
        end
    end
end

---Gets a random point within a circle of a given radius and center point.
---@param radius number
---@param center MapPosition
---@return MapPosition
function GetRandomPointWithinCircle(radius, center)
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius
    local x = center.x + distance * math.cos(angle)
    local y = center.y + distance * math.sin(angle)
    return {x=x, y=y}
end

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

--- Better than util.insert_safe because we also check for 0 count items.
---@param entity LuaEntity|LuaPlayer
---@param item_dict table
---@return nil
function OarcsSaferInsert(entity, item_dict)
    if not (entity and entity.valid and item_dict) then return end
    local items = prototypes.item
    local insert = entity.insert
    for name, count in pairs(item_dict) do
        if items[name] and count > 0 then
            insert { name = name, count = count }
        else
            log("Item to insert not valid: " .. name)
        end
    end
end

--- Better than util.remove_safe because we also check for 0 count items.
---@param entity LuaEntity|LuaPlayer
---@param item_dict table
---@return nil
function OarcsSaferRemove(entity, item_dict)
    if not (entity and entity.valid and item_dict) then return end
    local items = prototypes.item
    local remove = entity.remove_item
    for name, count in pairs(item_dict) do
        if items[name] and count > 0 then
            remove { name = name, count = count }
        else
            log("Item to remove not valid: " .. name)
        end
    end
end

---Gives the player the respawn items if there are any
---@param player LuaPlayer
---@return nil
function GivePlayerRespawnItems(player)
    local surface_name = player.character.surface.name
    if (storage.ocfg.surfaces_config[surface_name] == nil) then
        error("GivePlayerRespawnItems - Missing surface config! " .. surface_name)
        return
    end

    local respawnItems = storage.ocfg.surfaces_config[surface_name].starting_items.player_respawn_items

    OarcsSaferInsert(player, respawnItems)
end

---Gives the player the starter items if there are any
---@param player LuaPlayer
---@return nil
function GivePlayerStarterItems(player)
    local surface_name = player.character.surface.name
    if (storage.ocfg.surfaces_config[surface_name] == nil) then
        error("GivePlayerStarterItems - Missing surface config! " .. surface_name)
        return
    end

    local startItems = storage.ocfg.surfaces_config[surface_name].starting_items.player_start_items

    OarcsSaferInsert(player, startItems)
end

---Half-heartedly attempts to remove starter items from the player. Probably more trouble than it's worth.
---@param player LuaPlayer
---@return nil
function RemovePlayerStarterItems(player)
    if player == nil or player.character == nil then return end
    local surface_name = player.character.surface.name
    if (storage.ocfg.surfaces_config[surface_name]) ~= nil then
        local startItems = storage.ocfg.surfaces_config[surface_name].starting_items.player_start_items
        OarcsSaferRemove(player, startItems)
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


---Get position for buddy spawn (for buddy placement)
---@param position MapPosition
---@param surface_name string
---@param moat_enabled boolean
---@return MapPosition
function GetBuddySpawnPosition(position, surface_name, moat_enabled)

    local spawn_config = storage.ocfg.surfaces_config[surface_name].spawn_config

    local x_offset = storage.ocfg.spawn_general.spawn_radius_tiles * spawn_config.radius_modifier * 2
    x_offset = x_offset + storage.ocfg.spawn_general.moat_width_tiles
    -- distance = distance + 5 -- EXTRA BUFFER?

    -- Create that spawn in the global vars
    local buddy_position = table.deepcopy(position)
    -- The x_offset must be big enough to ensure the spawns DO NOT overlap!
    buddy_position.x = buddy_position.x + x_offset

    return buddy_position
end

-- Safer teleport
---@param player LuaPlayer
---@param surface LuaSurface
---@param target_pos MapPosition
function SafeTeleport(player, surface, target_pos)
    local safe_pos = surface.find_non_colliding_position("character", target_pos, CHUNK_SIZE, 1)
    if (not safe_pos) then
        player.teleport(target_pos, surface, true)
    else
        player.teleport(safe_pos, surface, true)
    end
end


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
        if name ~= ABANDONED_FORCE_NAME and not TableContains(ENEMY_FORCES_NAMES_INCL_NEUTRAL, name) then
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


---For each other player force, share a chat msg.
---@param player LuaPlayer
---@param msg LocalisedString
---@return nil
function ShareChatBetweenForces(player, msg)
    for _,force in pairs(game.forces) do
        if (force ~= nil) then
            if ((force.name ~= "enemy") and
                (force.name ~= "neutral") and
                (force.name ~= "player") and
                (force ~= player.force)) then
                CompatSend(force, {"", player.name, ": ", msg}, { color = player.color, sound = defines.print_sound.never})
                force.play_sound{ path = "utility/chat_message", volume_modifier = 1 }
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

---Pick a random direction, go at least the minimum distance, and start looking for ungenerated chunks
---We try a few times (hardcoded) and then try a different random direction if we fail (up to max_tries)
---@param surface_name string Surface name because we might need to force the creation of a new surface
---@param minimum_distance_chunks number Distance in chunks to start looking for ungenerated chunks
---@param max_tries integer Maximum number of tries to find a spawn point
---@return MapPosition
function FindUngeneratedCoordinates(surface_name, minimum_distance_chunks, max_tries)

    local final_position = {x=0,y=0}

    -- If surface is nil, it is probably a planet? Check and create if needed.
    local surface = game.surfaces[surface_name]
    if (surface == nil) then
        if (game.planets[surface_name] == nil) then
            error("ERROR! No surface or planet found for requested player spawn!")
            return final_position
        end
        surface = game.planets[surface_name].create_surface()
        if (surface == nil) then
            error("ERROR! Failed to create planet surface for player spawn!")
            return final_position
        end
    end

    --- Get a random vector, figure out how many times to multiply it to get the minimum distance
    local direction_vector = GetRandomVector()
    local start_distance_tiles = minimum_distance_chunks * CHUNK_SIZE
    
    local tries_remaining = max_tries - 1

    -- Starting search position
    local search_pos = {
        x=direction_vector.x * start_distance_tiles,
        y=direction_vector.y * start_distance_tiles
    }

    -- We check up to THIS many times, each jump moves out by minimum_distance_to_existing_chunks
    local jumps_count = 3

    local minimum_distance_to_existing_chunks = storage.ocfg.gameplay.minimum_distance_to_existing_chunks

    -- Keep checking chunks in the direction of the vector, assumes this terminates...
    while(true) do

        local chunk_position = GetChunkPosFromTilePos(search_pos)

        if (jumps_count <= 0) then

            if (tries_remaining > 0) then
                return FindUngeneratedCoordinates(surface_name, minimum_distance_chunks, tries_remaining)
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