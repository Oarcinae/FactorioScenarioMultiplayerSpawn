-- regrowth_map.lua
-- July 2017
--
-- Code tracks all chunks generated and allows for deleting inactive chunks
-- Relies on some changes to RSO to provide random resource locations the next
-- time the land is regenerated.
-- 
-- Basic rules of regrowth:
-- 1. Area around player is safe for quite a large distance.
-- 2. Rocket silo won't be deleted. - PERMANENT
-- 3. Chunks with pollution won't be deleted.
-- 4. Chunks with railways won't be deleted.
-- 5. Anything within radar range won't be deleted, but radar MUST be active.
--      -- This works by refreshing all chunk timers within radar range using
--      the on_sector_scanned event.
-- 6. Chunks timeout after 1 hour-ish, configurable
-- 7. For now, oarc spawns are deletion safe as well, but only immediate area.


REGROWTH_TIMEOUT_TICKS = 60*60*60 -- 1 hour

-- Init globals and set player join area to be off limits.
function OarcRegrowthInit()
    global.chunk_regrow = {}
    global.chunk_regrow.map = {}
    global.chunk_regrow.removal_list = {}
    global.chunk_regrow.rso_region_roll_counter = 0
    global.chunk_regrow.player_refresh_index = 1
    global.chunk_regrow.min_x = 0
    global.chunk_regrow.max_x = 0
    global.chunk_regrow.x_index = 0
    global.chunk_regrow.min_y = 0
    global.chunk_regrow.max_y = 0
    global.chunk_regrow.y_index = 0

    OarcRegrowthOffLimits({x=0,y=0}, 15)
end

function GetChunkTopLeft(pos)
    return {x=pos.x-(pos.x % 32), y=pos.y-(pos.y % 32)}
end

function GetChunkFromPos(pos)
    return {x=pos.x-(pos.x % 32), y=pos.y-(pos.y % 32)}
end


-- Adds new chunks to the global table to track them.
-- This should always be called first in the chunk generate sequence
-- (Compared to other RSO & Oarc related functions...)
function OarcRegrowthChunkGenerate(pos)

    -- If this is the first chunk in that row:
    if (global.chunk_regrow.map[pos.x] == nil) then
        global.chunk_regrow.map[pos.x] = {}
    end

    -- Confirm the chunk doesn't already have a value set:
    if (global.chunk_regrow.map[pos.x][pos.y] == nil) then
        global.chunk_regrow.map[pos.x][pos.y] = game.tick
    end

    -- Store min/max values for x/y dimensions:
    if (pos.x < global.chunk_regrow.min_x) then
        global.chunk_regrow.min_x = pos.x
    end
    if (pos.x > global.chunk_regrow.max_x) then
        global.chunk_regrow.max_x = pos.x
    end
    if (pos.y < global.chunk_regrow.min_y) then
        global.chunk_regrow.min_y = pos.y
    end
    if (pos.y > global.chunk_regrow.max_y) then
        global.chunk_regrow.max_y = pos.y
    end
end

-- Mark an area for immediate forced removal
function OarcRegrowthMarkForRemoval(pos, chunk_radius)
    local c_pos = GetChunkTopLeft(pos)
    for i=-chunk_radius,chunk_radius do
        for k=-chunk_radius,chunk_radius do
            local x = c_pos.x+(i*32)
            local y = c_pos.y+(k*32)

            if (global.chunk_regrow.map[x] == nil) then
                global.chunk_regrow.map[x] = {}
            end
            global.chunk_regrow.map[x][y] = nil
            table.insert(global.chunk_regrow.removal_list, {x=x,y=y})
        end
    end
end

-- Marks a chunk a position that won't ever be deleted.
function OarcRegrowthOffLimitsChunk(pos)
    local c_pos = GetChunkTopLeft(pos)

    if (global.chunk_regrow.map[c_pos.x] == nil) then
        global.chunk_regrow.map[c_pos.y] = {}
    end
    global.chunk_regrow.map[c_pos.x][c_pos.y] = -1
end


-- Marks a safe area around a position that won't ever be deleted.
function OarcRegrowthOffLimits(pos, chunk_radius)
    local c_pos = GetChunkTopLeft(pos)
    for i=-chunk_radius,chunk_radius do
        for k=-chunk_radius,chunk_radius do
            local x = c_pos.x+(i*32)
            local y = c_pos.y+(k*32)

            if (global.chunk_regrow.map[x] == nil) then
                global.chunk_regrow.map[x] = {}
            end
            global.chunk_regrow.map[x][y] = -1
        end
    end
end

-- Refreshes timers on a chunk containing position
function OarcRegrowthRefreshChunk(pos, bonus_time)
    local c_pos = GetChunkTopLeft(pos)

    if (global.chunk_regrow.map[c_pos.x] == nil) then
        global.chunk_regrow.map[c_pos.y] = {}
    end
    if (global.chunk_regrow.map[c_pos.x][c_pos.y] ~= -1) then
        global.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick + bonus_time
    end
end

-- Refreshes timers on all chunks around a certain area
function OarcRegrowthRefreshArea(pos, chunk_radius, bonus_time)
    local c_pos = {x=pos.x-(pos.x % 32),
                    y=pos.y-(pos.y % 32)}
    for i=-chunk_radius,chunk_radius do
        for k=-chunk_radius,chunk_radius do
            local x = c_pos.x+(i*32)
            local y = c_pos.y+(k*32)

            if (global.chunk_regrow.map[x] == nil) then
                global.chunk_regrow.map[x] = {}
            end
            if (global.chunk_regrow.map[x][y] ~= -1) then
                global.chunk_regrow.map[x][y] = game.tick + bonus_time
            end
        end
    end
end

-- Refreshes timers on all chunks near an ACTIVE radar
function OarcRegrowthSectorScan(event)
    OarcRegrowthRefreshArea(event.radar.position, 4, 0)
    OarcRegrowthRefreshChunk(event.chunk_position)
end

-- Refresh all chunks near a single player. Cyles through all connected players.
function OarcRegrowthRefreshPlayerArea()
    global.chunk_regrow.player_refresh_index = global.chunk_regrow.player_refresh_index + 1
    if (global.chunk_regrow.player_refresh_index > #game.connected_players) then
        global.chunk_regrow.player_refresh_index = 1
    end
    if (game.connected_players[global.chunk_regrow.player_refresh_index]) then
        OarcRegrowthRefreshArea(game.connected_players[global.chunk_regrow.player_refresh_index].position, 4, 0)
    end
end

-- Check each chunk in the 2d array for a timeout value
function OarcRegrowthCheckArray()

    -- Increment X
    if (global.chunk_regrow.x_index > global.chunk_regrow.max_x) then
        global.chunk_regrow.x_index = global.chunk_regrow.min_x
        -- Increment Y
        if (global.chunk_regrow.y_index > global.chunk_regrow.max_y) then
            global.chunk_regrow.y_index = global.chunk_regrow.min_y
        else
            global.chunk_regrow.y_index = global.chunk_regrow.y_index + 32
        end
    else
        global.chunk_regrow.x_index = global.chunk_regrow.x_index + 32
    end

    -- Check row exists, otherwise make one.
    if (global.chunk_regrow.map[global.chunk_regrow.x_index] == nil) then
        global.chunk_regrow.map[global.chunk_regrow.x_index] = {}
    end

    -- If the chunk has timed out, add it to the removal list
    local c_timer = global.chunk_regrow.map[global.chunk_regrow.x_index][global.chunk_regrow.y_index]
    if ((c_timer ~= nil) and (c_timer ~= -1) and ((c_timer+REGROWTH_TIMEOUT_TICKS) < game.tick)) then
       
        -- Check chunk actually exists
        if (game.surfaces[GAME_SURFACE_NAME].is_chunk_generated({x=(global.chunk_regrow.x_index/32),
                                                                y=(global.chunk_regrow.y_index/32)})) then
            table.insert(global.chunk_regrow.removal_list, {x=global.chunk_regrow.x_index,
                                                            y=global.chunk_regrow.y_index})
            global.chunk_regrow.map[global.chunk_regrow.x_index][global.chunk_regrow.y_index] = nil
        end
    end
end

-- Remove entries from the removal list
function OarcRegrowthRemoveChunk()

    -- Next chunk to remove
    if (#global.chunk_regrow.removal_list > 0) then
        local c_pos = table.remove(global.chunk_regrow.removal_list)
        local c_timer = global.chunk_regrow.map[c_pos.x][c_pos.y]

        -- Confirm chunk is still expired
        if (c_timer == nil) then

            -- Check for pollution
            if (game.surfaces[GAME_SURFACE_NAME].get_pollution(c_pos) > 0) then
                global.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick

            -- Else delete the chunk
            else
                game.surfaces[GAME_SURFACE_NAME].delete_chunk({c_pos.x/32,c_pos.y/32})
                global.chunk_regrow.map[c_pos.x][c_pos.y] = nil
                -- DebugPrint("Deleting Chunk: X="..c_pos.x..",Y="..c_pos.y)
            end

        else
            -- DebugPrint("Chunk no longer expired: X="..c_pos.x..",Y="..c_pos.y)
        end
    end
end

-- This is the main work function, it checks a single chunk in the list
-- per tick. It works according to the rules listed in the header of this
-- file.
function OarcRegrowthOnTick(event)

    -- Every half a second, refresh all chunks near a single player
    -- Cyles through all players. Tick is offset by 2
    if ((game.tick % (30)) == 2) then
        OarcRegrowthRefreshPlayerArea()
    end

    -- Every tick, check a few points in the 2d array
    for i=1,3 do
        OarcRegrowthCheckArray()
    end

    -- Every 30 ticks, remove a chunk from the removal list.
    if ((game.tick % 30) == 15) then
        OarcRegrowthRemoveChunk()
    end
end