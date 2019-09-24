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

REGROWTH_TIMEOUT_TICKS = TICKS_PER_HOUR

-- Init globals and set player join area to be off limits.
function RegrowthInit()
    if (global.rg == nil) then
        global.rg = {}
        global.rg.surfaces_index = 1
        global.rg.player_refresh_index = 1
        global.rg.force_removal_flag = -1000
        global.rg.active_surfaces = {}
    end
end

function TriggerCleanup()
    global.rg.force_removal_flag = game.tick
end

function ForceRemoveChunksCmd(cmd_table)
    if (game.players[cmd_table.player_index].admin) then
        TriggerCleanup()
    end
end

function RegrowthAddSurface(s_index)
    RegrowthInit()

    if (global.rg[s_index] ~= nil) then
        log("ERROR - Tried to add surface that was already added?")
        return
    end

    log("Oarc Regrowth - ADD SURFACE " .. game.surfaces[s_index].name)

    global.rg[s_index] = {}
    table.insert(global.rg.active_surfaces, s_index)

    global.rg[s_index].map = {}
    global.rg[s_index].removal_list = {}
    global.rg[s_index].min_x = 0
    global.rg[s_index].max_x = 0
    global.rg[s_index].x_index = 0
    global.rg[s_index].min_y = 0
    global.rg[s_index].max_y = 0
    global.rg[s_index].y_index = 0

    -- MarkAreaSafeGivenTilePos({x=0,y=0}, 10)
end

-- Adds new chunks to the global table to track them.
-- This should always be called first in the chunk generate sequence
-- (Compared to other RSO & Oarc related functions...)
function RegrowthChunkGenerate(event)

    local s_index = event.surface.index
    local c_pos = GetChunkPosFromTilePos(event.area.left_top)

    -- Surface must be "added" first.
    if (global.rg[s_index] == nil) then return end

    -- If this is the first chunk in that row:
    if (global.rg[s_index].map[c_pos.x] == nil) then
        global.rg[s_index].map[c_pos.x] = {}
    end

    -- Confirm the chunk doesn't already have a value set:
    if (global.rg[s_index].map[c_pos.x][c_pos.y] == nil) then
        global.rg[s_index].map[c_pos.x][c_pos.y] = game.tick
    end

    -- Store min/max values for x/y dimensions:
    if (c_pos.x < global.rg[s_index].min_x) then
        global.rg[s_index].min_x = c_pos.x
    end
    if (c_pos.x > global.rg[s_index].max_x) then
        global.rg[s_index].max_x = c_pos.x
    end
    if (c_pos.y < global.rg[s_index].min_y) then
        global.rg[s_index].min_y = c_pos.y
    end
    if (c_pos.y > global.rg[s_index].max_y) then
        global.rg[s_index].max_y = c_pos.y
    end
end

-- Mark an area for "immediate" forced removal
function MarkAreaForRemoval(s_index, pos, chunk_radius)
    local c_pos = GetChunkPosFromTilePos(pos)
    for i=-chunk_radius,chunk_radius do
        for k=-chunk_radius,chunk_radius do
            local x = c_pos.x+i
            local y = c_pos.y+k

            if (global.rg[s_index].map[x] == nil) then
                global.rg[s_index].map[x] = {}
            end
            global.rg[s_index].map[x][y] = nil
            table.insert(global.rg[s_index].removal_list,
                            {pos={x=x,y=y},force=true})
        end
    end
end

-- Marks a chunk containing a position that won't ever be deleted.
function MarkChunkSafe(s_index, c_pos)
    if (global.rg[s_index].map[c_pos.x] == nil) then
        global.rg[s_index].map[c_pos.x] = {}
    end
    global.rg[s_index].map[c_pos.x][c_pos.y] = -1
end

-- Marks a safe area around a TILE position that won't ever be deleted.
function MarkAreaSafeGivenTilePos(s_index, pos, chunk_radius)
    if (global.rg[s_index] == nil) then return end

    local c_pos = GetChunkPosFromTilePos(pos)
    MarkAreaSafeGivenChunkPos(s_index, c_pos, chunk_radius)
end

-- Marks a safe area around a CHUNK position that won't ever be deleted.
function MarkAreaSafeGivenChunkPos(s_index, c_pos, chunk_radius)
    if (global.rg[s_index] == nil) then return end

    for i=-chunk_radius,chunk_radius do
        for j=-chunk_radius,chunk_radius do
            MarkChunkSafe(s_index, {x=c_pos.x+i,y=c_pos.y+j})
        end
    end
end

-- Refreshes timers on a chunk containing position
function RefreshChunkTimer(s_index, pos, bonus_time)
    local c_pos = GetChunkPosFromTilePos(pos)

    if (global.rg[s_index].map[c_pos.x] == nil) then
        global.rg[s_index].map[c_pos.x] = {}
    end
    if (global.rg[s_index].map[c_pos.x][c_pos.y] ~= -1) then
        global.rg[s_index].map[c_pos.x][c_pos.y] = game.tick + bonus_time
    end
end

-- Forcefully refreshes timers on a chunk containing position
-- Will overwrite -1 flag.
-- function OarcRegrowthForceRefreshChunk(s_index, pos, bonus_time)
--     local c_pos = GetChunkPosFromTilePos(pos)

--     if (global.rg[s_index].map[c_pos.x] == nil) then
--         global.rg[s_index].map[c_pos.x] = {}
--     end
--     global.rg[s_index].map[c_pos.x][c_pos.y] = game.tick + bonus_time
-- end

 -- Refreshes timers on all chunks around a certain area
function RefreshArea(s_index, pos, chunk_radius, bonus_time)
    local c_pos = GetChunkPosFromTilePos(pos)

    for i=-chunk_radius,chunk_radius do
        for k=-chunk_radius,chunk_radius do
            local x = c_pos.x+i
            local y = c_pos.y+k

            if (global.rg[s_index].map[x] == nil) then
                global.rg[s_index].map[x] = {}
            end
            if (global.rg[s_index].map[x][y] ~= -1) then
                global.rg[s_index].map[x][y] = game.tick + bonus_time
            end
        end
    end
end

-- Refreshes timers on all chunks near an ACTIVE radar
function RegrowthSectorScan(event)
    local s_index = event.radar.surface.index
    if (global.rg[s_index] == nil) then return end

    RefreshArea(s_index, event.radar.position, 14, 0)
    RefreshChunkTimer(s_index, event.chunk_position, 0)
end

-- Refresh all chunks near a single player. Cyles through all connected players.
function RefreshPlayerArea()
    global.rg.player_refresh_index = global.rg.player_refresh_index + 1
    if (global.rg.player_refresh_index > #game.connected_players) then
        global.rg.player_refresh_index = 1
    end
    if (game.connected_players[global.rg.player_refresh_index]) then
        local player = game.connected_players[global.rg.player_refresh_index]
        if (not player.character) then return end

        local s_index = player.character.surface.index
        if (global.rg[s_index] == nil) then return end

        RefreshArea(s_index, player.position, 4, 0)
    end
end

-- Gets the next chunk the array map and checks to see if it has timed out.
-- Adds it to the removal list if it has.
function RegrowthSingleStepArray(s_index)

    -- Increment X and reset when we hit the end.
    if (global.rg[s_index].x_index > global.rg[s_index].max_x) then
        global.rg[s_index].x_index = global.rg[s_index].min_x

        -- Increment Y and reset when we hit the end.
        if (global.rg[s_index].y_index > global.rg[s_index].max_y) then
            global.rg[s_index].y_index = global.rg[s_index].min_y
            -- log("Finished checking regrowth array. "..
            --         game.surfaces[s_index].name.." "..
            --         global.rg[s_index].min_x.." "..
            --         global.rg[s_index].max_x.." "..
            --         global.rg[s_index].min_y.." "..
            --         global.rg[s_index].max_y)
        else
            global.rg[s_index].y_index = global.rg[s_index].y_index + 1
        end
    else
        global.rg[s_index].x_index = global.rg[s_index].x_index + 1
    end

    local xidx = global.rg[s_index].x_index
    local yidx = global.rg[s_index].y_index

    if (not xidx or not yidx) then
        log("ERROR - xidx or yidx is nil?")
    end

    -- Check row exists, otherwise make one.
    if (global.rg[s_index].map[xidx] == nil) then
        global.rg[s_index].map[xidx] = {}
    end

    -- If the chunk has timed out, add it to the removal list
    local c_timer = global.rg[s_index].map[xidx][yidx]
    if ((c_timer ~= nil) and (c_timer ~= -1) and
        ((c_timer + REGROWTH_TIMEOUT_TICKS) < game.tick)) then

        -- Check chunk actually exists
        if (game.surfaces[s_index].is_chunk_generated({x=xidx, y=yidx})) then
            table.insert(global.rg[s_index].removal_list, {pos={x=xidx,
                                                            y=yidx},
                                                            force=false})
            global.rg[s_index].map[xidx][yidx] = nil
        end
    end
end

-- Remove all chunks at same time to reduce impact to FPS/UPS
function OarcRegrowthRemoveAllChunks()
    for _,s_index in pairs(global.rg.active_surfaces) do
        print(k,v)

        while (#global.rg[s_index].removal_list > 0) do
            local c_remove = table.remove(global.rg[s_index].removal_list)
            local c_pos = c_remove.pos
            local c_timer = global.rg[s_index].map[c_pos.x][c_pos.y]

            if (game.surfaces[s_index] == nil) then
                log("Error! game.surfaces[name] is nil?? WTF?")
                return
            end

            -- Confirm chunk is still expired
            if (c_timer == nil) then

                -- If it is FORCE removal, then remove it regardless of pollution.
                if (c_remove.force) then
                    game.surfaces[s_index].delete_chunk(c_pos)
                    global.rg[s_index].map[c_pos.x][c_pos.y] = nil

                -- If it is a normal timeout removal, don't do it if there is pollution in the chunk.
                elseif (game.surfaces[s_index].get_pollution({c_pos.x*32,c_pos.y*32}) > 0) then
                    global.rg[s_index].map[c_pos.x][c_pos.y] = game.tick

                -- Else delete the chunk
                else
                    game.surfaces[s_index].delete_chunk(c_pos)
                    global.rg[s_index].map[c_pos.x][c_pos.y] = nil
                end
            end
        end
    end
end

-- This is the main work function, it checks a single chunk in the list
-- per tick. It works according to the rules listed in the header of this
-- file.
function RegrowthOnTick()

    if (#global.rg.active_surfaces == 0) then return end

    -- Every half a second, refresh all chunks near a single player
    -- Cyles through all players. Tick is offset by 2
    if ((game.tick % (30)) == 2) then
        RefreshPlayerArea()
    end

    -- Iterate through the active surfaces.
    if (global.rg.surfaces_index > #global.rg.active_surfaces) then
        global.rg.surfaces_index = 1
    end
    local s_index = global.rg.active_surfaces[global.rg.surfaces_index]
    global.rg.surfaces_index = global.rg.surfaces_index+1

    if (s_index == nil) then
        log("ERROR - s_index = nil in OarcRegrowthOnTick?")
        return
    end

    -- Every tick, check a few points in the 2d array of one of the active surfaces
    -- According to /measured-command this shouldn't take more
    -- than 0.1ms on average
    for i=1,20 do
        RegrowthSingleStepArray(s_index)
    end

    -- Allow enable/disable of auto cleanup, can change during runtime.
    if (global.ocfg.enable_regrowth) then

        local interval_ticks = REGROWTH_TIMEOUT_TICKS
        -- Send a broadcast warning before it happens.
        if ((game.tick % interval_ticks) == interval_ticks-601) then
            if (#global.rg[s_index].removal_list > 100) then
                SendBroadcastMsg("Map cleanup in 10 seconds... Unused and old map chunks will be deleted!")
            end
        end

        -- Delete all listed chunks across all active surfaces
        if ((game.tick % interval_ticks) == interval_ticks-1) then
            if (#global.rg[s_index].removal_list > 100) then
                OarcRegrowthRemoveAllChunks()
                SendBroadcastMsg("Map cleanup done, sorry for your loss.")
            end
        end
    end
end

-- This function removes any chunks flagged but on demand.
-- Controlled by the global.rg.force_removal_flag
-- This function may be used outside of the normal regrowth modse.
function RegrowthForceRemovalOnTick()
    -- Catch force remove flag
    if (game.tick == global.rg.force_removal_flag+60) then
        SendBroadcastMsg("Map cleanup (forced) in 10 seconds... Unused and old map chunks will be deleted!")
    end

    if (game.tick == global.rg.force_removal_flag+660) then
        OarcRegrowthRemoveAllChunks()
        SendBroadcastMsg("Map cleanup done, sorry for your loss.")
    end
end

-- Broadcast messages to all connected players
function SendBroadcastMsg(msg)
    for name,player in pairs(game.connected_players) do
        player.print(msg)
    end
end

-- Gets chunk position of a tile.
function GetChunkPosFromTilePos(tile_pos)
    return {x=math.floor(tile_pos.x/32), y=math.floor(tile_pos.y/32)}
end