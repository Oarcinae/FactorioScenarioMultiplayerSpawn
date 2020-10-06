-- regrowth_map.lua
-- Sep 2019
-- REVERTED BACK TO SOFT MOD

-- Code tracks all chunks generated and allows for deleting of inactive chunks.
--
-- Basic rules of regrowth:
-- 1. Area around player is safe for quite a large distance.
-- 2. Chunks with pollution won't be deleted.
-- 3. Chunks with any player buildings won't be deleted.
-- 4. Anything within radar range won't be deleted, but radar MUST be active.
--      -- This works by refreshing all chunk timers within radar range using
--      the on_sector_scanned event.
-- 5. Chunks timeout after 1 hour-ish, configurable

require("lib/oarc_utils")
require("config")

REGROWTH_TIMEOUT_TICKS = TICKS_PER_HOUR -- TICKS_PER_HOUR TICKS_PER_MINUTE

-- Init globals and set player join area to be off limits.
function RegrowthInit()
    global.rg = {}
    global.rg.player_refresh_index = nil
    global.rg.force_removal_flag = -2000
    global.rg.map = {}
    global.rg.removal_list = {}
    global.rg.chunk_iter = nil
    global.rg.world_eater_iter = nil
    global.rg.timeout_ticks = REGROWTH_TIMEOUT_TICKS
end

function TriggerCleanup()
    global.rg.force_removal_flag = game.tick
end

function RegrowthForceRemoveChunksCmd(cmd_table)
    if (game.players[cmd_table.player_index].admin) then
        TriggerCleanup()
    end
end

-- Get the next player index available
function GetNextPlayerIndex(player_index)
    if (not global.rg.player_refresh_index or not game.players[global.rg.player_refresh_index]) then
        global.rg.player_refresh_index = 1
    else
        global.rg.player_refresh_index = global.rg.player_refresh_index + 1
    end

    if (global.rg.player_refresh_index > #game.players) then
        global.rg.player_refresh_index = 1
    end

    return global.rg.player_refresh_index
end

-- Adds new chunks to the global table to track them.
-- This should always be called first in the chunk generate sequence
-- (Compared to other RSO & Oarc related functions...)
function RegrowthChunkGenerate(event)
    local c_pos = GetChunkPosFromTilePos(event.area.left_top)

    -- Surface must be "added" first.
    if (global.rg == nil) then return end

    -- If this is the first chunk in that row:
    if (global.rg.map[c_pos.x] == nil) then
        global.rg.map[c_pos.x] = {}
    end

    -- Only update it if it isn't already set!
    if (global.rg.map[c_pos.x][c_pos.y] == nil) then
        global.rg.map[c_pos.x][c_pos.y] = game.tick
    end
end

-- Mark an area for "immediate" forced removal
function RegrowthMarkAreaForRemoval(pos, chunk_radius)
    local c_pos = GetChunkPosFromTilePos(pos)
    for i=-chunk_radius,chunk_radius do
        local x = c_pos.x+i
        for k=-chunk_radius,chunk_radius do
            local y = c_pos.y+k

            if (global.rg.map[x] ~= nil) then
                global.rg.map[x][y] = nil
            end
            table.insert(global.rg.removal_list, {pos={x=x,y=y},force=true})
        end
        if (table_size(global.rg.map[x]) == 0) then
            global.rg.map[x] = nil
        end
    end
end

-- Downgrades permanent flag to semi-permanent.
function RegrowthMarkAreaNotPermanentOVERWRITE(pos, chunk_radius)
    local c_pos = GetChunkPosFromTilePos(pos)
    for i=-chunk_radius,chunk_radius do
        local x = c_pos.x+i
        for k=-chunk_radius,chunk_radius do
            local y = c_pos.y+k

            if (global.rg.map[x] and global.rg.map[x][y] and (global.rg.map[x][y] == -2)) then
                global.rg.map[x][y] = -1
            end
        end
    end
end

-- Marks a chunk containing a position to be relatively permanent.
function MarkChunkSafe(c_pos, permanent)
    if (global.rg.map[c_pos.x] == nil) then
        global.rg.map[c_pos.x] = {}
    end

    if (permanent) then
        global.rg.map[c_pos.x][c_pos.y] = -2

    -- Make sure we don't overwrite...
    elseif (global.rg.map[c_pos.x][c_pos.y] and (global.rg.map[c_pos.x][c_pos.y] ~= -2)) then
        global.rg.map[c_pos.x][c_pos.y] = -1
    end
end

-- Marks a safe area around a CHUNK position to be relatively permanent.
function RegrowthMarkAreaSafeGivenChunkPos(c_pos, chunk_radius, permanent)
    if (global.rg == nil) then return end

    for i=-chunk_radius,chunk_radius do
        for j=-chunk_radius,chunk_radius do
            MarkChunkSafe({x=c_pos.x+i,y=c_pos.y+j}, permanent)
        end
    end
end

-- Marks a safe area around a TILE position to be relatively permanent.
function RegrowthMarkAreaSafeGivenTilePos(pos, chunk_radius, permanent)
    if (global.rg == nil) then return end

    local c_pos = GetChunkPosFromTilePos(pos)
    RegrowthMarkAreaSafeGivenChunkPos(c_pos, chunk_radius, permanent)
end

-- Refreshes timers on a chunk containing position
function RefreshChunkTimer(pos, bonus_time)
    local c_pos = GetChunkPosFromTilePos(pos)

    if (global.rg.map[c_pos.x] == nil) then
        global.rg.map[c_pos.x] = {}
    end
    if (global.rg.map[c_pos.x][c_pos.y] >= 0) then
        global.rg.map[c_pos.x][c_pos.y] = game.tick + bonus_time
    end
end

-- Refreshes timers on all chunks around a certain area
function RefreshArea(pos, chunk_radius, bonus_time)
    local c_pos = GetChunkPosFromTilePos(pos)

    for i=-chunk_radius,chunk_radius do
        local x = c_pos.x+i
        for k=-chunk_radius,chunk_radius do
            local y = c_pos.y+k

            if (global.rg.map[x] == nil) then
                global.rg.map[x] = {}
            end
            if ((global.rg.map[x][y] == nil) or (global.rg.map[x][y] >= 0)) then
                global.rg.map[x][y] = game.tick + bonus_time
            end
        end
    end
end

-- Refreshes timers on all chunks near an ACTIVE radar
function RegrowthSectorScan(event)
    if (event.radar.surface.name ~= GAME_SURFACE_NAME) then return end

    RefreshArea(event.radar.position, 14, 0)
end

-- Refresh all chunks near a single player. Cyles through all connected players.
function RefreshPlayerArea()
    player_index = GetNextPlayerIndex()
    if (player_index and game.connected_players[player_index]) then
        local player = game.connected_players[player_index]
        
        if (not player.character) then return end
        if (player.character.surface.name ~= GAME_SURFACE_NAME) then return end

        RefreshArea(player.position, 4, 0)
    end
end

-- Gets the next chunk the array map and checks to see if it has timed out.
-- Adds it to the removal list if it has.
function RegrowthSingleStepArray()

    -- Make sure we have a valid iterator!
    if (not global.rg.chunk_iter or not global.rg.chunk_iter.valid) then
        global.rg.chunk_iter = game.surfaces[GAME_SURFACE_NAME].get_chunks()
    end

    local next_chunk = global.rg.chunk_iter()

    -- Check if we reached the end
    if (not next_chunk) then 
        global.rg.chunk_iter = game.surfaces[GAME_SURFACE_NAME].get_chunks()
        next_chunk = global.rg.chunk_iter()
    end

    -- Do we have it in our map?
    if (not global.rg.map[next_chunk.x] or not global.rg.map[next_chunk.x][next_chunk.y]) then
        return -- Chunk isn't in our map so we don't care?
    end 

    -- If the chunk has timed out, add it to the removal list
    local c_timer = global.rg.map[next_chunk.x][next_chunk.y]
    if ((c_timer ~= nil) and (c_timer >= 0) and ((c_timer + global.rg.timeout_ticks) < game.tick)) then

        -- Check chunk actually exists
        if (game.surfaces[GAME_SURFACE_NAME].is_chunk_generated({x=next_chunk.x, y=next_chunk.y})) then
            table.insert(global.rg.removal_list, {pos={x=next_chunk.x, y=next_chunk.y}, force=false})
            global.rg.map[next_chunk.x][next_chunk.y] = nil
        end
    end
end

-- Remove all chunks at same time to reduce impact to FPS/UPS
function OarcRegrowthRemoveAllChunks()
    for key,c_remove in pairs(global.rg.removal_list) do
        local c_pos = c_remove.pos

        -- Confirm chunk is still expired
        if (not global.rg.map[c_pos.x] or not global.rg.map[c_pos.x][c_pos.y]) then

            -- If it is FORCE removal, then remove it regardless of pollution.
            if (c_remove.force) then
                game.surfaces[GAME_SURFACE_NAME].delete_chunk(c_pos)

            -- If it is a normal timeout removal, don't do it if there is pollution in the chunk.
            elseif (game.surfaces[GAME_SURFACE_NAME].get_pollution({c_pos.x*32,c_pos.y*32}) > 0) then
                global.rg.map[c_pos.x][c_pos.y] = game.tick

            -- Else delete the chunk
            else
                game.surfaces[GAME_SURFACE_NAME].delete_chunk(c_pos)
            end
        end

        -- Remove entry
        global.rg.removal_list[key] = nil
    end

    -- MUST GET A NEW CHUNK ITERATOR ON DELETE CHUNK!
    global.rg.chunk_iter = nil
    global.rg.world_eater_iter = nil
end

-- This is the main work function, it checks a single chunk in the list
-- per tick. It works according to the rules listed in the header of this
-- file.
function RegrowthOnTick()

    -- Every half a second, refresh all chunks near a single player
    -- Cyles through all players. Tick is offset by 2
    if ((game.tick % (30)) == 2) then
        RefreshPlayerArea()
    end

    -- Every tick, check a few points in the 2d array of the only active surface According to /measured-command this
    -- shouldn't take more than 0.1ms on average
    for i=1,20 do
        RegrowthSingleStepArray()
    end

    if (not global.world_eater_disable) then
        WorldEaterSingleStep()
    end

    -- Allow enable/disable of auto cleanup, can change during runtime.
    local interval_ticks = global.rg.timeout_ticks
    -- Send a broadcast warning before it happens.
    if ((game.tick % interval_ticks) == interval_ticks-(60*30 + 1)) then
        if (#global.rg.removal_list > 100) then
            SendBroadcastMsg("Map cleanup in 30 seconds... Unused and old map chunks will be deleted!")
        end
    end

    -- Delete all listed chunks across all active surfaces
    if ((game.tick % interval_ticks) == interval_ticks-1) then
        if (#global.rg.removal_list > 100) then
            OarcRegrowthRemoveAllChunks()
            SendBroadcastMsg("Map cleanup done, sorry for your loss.")
        end
    end
end

-- This function removes any chunks flagged but on demand.
-- Controlled by the global.rg.force_removal_flag
-- This function may be used outside of the normal regrowth modse.
function RegrowthForceRemovalOnTick()
    -- Catch force remove flag
    if (game.tick == global.rg.force_removal_flag+60) then
        SendBroadcastMsg("Map cleanup (forced) in 30 seconds... Unused and old map chunks will be deleted!")
    end

    if (game.tick == global.rg.force_removal_flag+(60*30 + 60)) then
        OarcRegrowthRemoveAllChunks()
        SendBroadcastMsg("Map cleanup done, sorry for your loss.")
    end
end

function WorldEaterSingleStep()

    -- Make sure we have a valid iterator!
    if (not global.rg.world_eater_iter or not global.rg.world_eater_iter.valid) then
        global.rg.world_eater_iter = game.surfaces[GAME_SURFACE_NAME].get_chunks()
    end

    local next_chunk = global.rg.world_eater_iter()

    -- Check if we reached the end
    if (not next_chunk) then 
        global.rg.world_eater_iter = game.surfaces[GAME_SURFACE_NAME].get_chunks()
        next_chunk = global.rg.world_eater_iter()
    end

    -- Do we have it in our map?
    if (not global.rg.map[next_chunk.x] or not global.rg.map[next_chunk.x][next_chunk.y]) then
        return -- Chunk isn't in our map so we don't care?
    end 

    -- Search for any abandoned radars and destroy them?
    local entities = game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{area=next_chunk.area,
                                                                                force={global.ocore.abandoned_force},
                                                                                name="radar"}
    for k,v in pairs(entities) do
        v.die(nil)
    end

    -- Search for any entities with _DESTROYED_ force and kill them.
    entities = game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{area=next_chunk.area,
                                                                                force={global.ocore.destroyed_force}}
    for k,v in pairs(entities) do
        v.die(nil)
    end

    -- If the chunk isn't marked permament, then check if we can remove it
    local c_timer = global.rg.map[next_chunk.x][next_chunk.y]
    if (c_timer == -1) then

        local area = {left_top = {next_chunk.area.left_top.x-8, next_chunk.area.left_top.y-8},
                      right_bottom = {next_chunk.area.right_bottom.x+8, next_chunk.area.right_bottom.y+8}}

        local entities = game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{area=area, force={"enemy", "neutral"}, invert=true}
        local total_count = #entities
        local has_last_user_set = false

        if (total_count > 0) then
            for k,v in pairs(entities) do
                if (v.last_user or (v.type == "character")) then
                    has_last_user_set = true
                    return -- This means we're done checking this chunk.
                end
            end

            -- If all entities found have no last user, then KILL all entities!
            if (not has_last_user_set) then
                for k,v in pairs(entities) do
                    if (v and v.valid) then
                        v.die(nil)
                    end
                end
                -- SendBroadcastMsg(next_chunk.x .. "," .. next_chunk.y .. " WorldEaterSingleStep - ENTITIES FOUND")
                global.rg.map[next_chunk.x][next_chunk.y] = game.tick -- Set the timer on it.
            end
        else
            -- SendBroadcastMsg(next_chunk.x .. "," .. next_chunk.y .. " WorldEaterSingleStep - NO ENTITIES FOUND")
            global.rg.map[next_chunk.x][next_chunk.y] = game.tick -- Set the timer on it.
        end
    end
end
