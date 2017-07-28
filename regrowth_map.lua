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


REGROWTH_TIMEOUT_TICKS = 60*10 -- 1 hour

-- Init globals and set player join area to be off limits.
function OarcRegrowthInit()
    global.chunk_regrow = {}
    global.chunk_regrow.map = {}
    global.chunk_regrow.list = {}
    global.chunk_regrow.num_chunks = 0
    global.chunk_regrow.chunk_index = 1
    global.chunk_regrow.rso_region_roll_counter = 0

    OarcRegrowthOffLimits({x=0,y=0}, 15)
end


-- Adds new chunks to the global table to track them.
-- This should always be called first in the chunk generate sequence
-- (Compared to other RSO & Oarc related functions...)
function OarcRegrowthChunkGenerate(event)

    local x = event.area.left_top.x
    local y = event.area.left_top.y
    if (global.chunk_regrow.map[x] == nil) then
        global.chunk_regrow.map[x] = {}
    end

    -- There are some chunks that might already be added to the table
    -- before a chunk generate event happens for them.
    if (global.chunk_regrow.map[x][y] == nil) then
        global.chunk_regrow.map[x][y] = game.tick
    end
    
    -- Always add new chunks to the list, they will be removed later
    -- if they are offlimits.
    table.insert(global.chunk_regrow.list, event.area.left_top)
    global.chunk_regrow.num_chunks = global.chunk_regrow.num_chunks + 1
end

-- Mark an area for removal
-- Intended to be used for cleaning abandoned spawns
function OarcRegrowthMarkForRemoval(pos, chunk_radius)
    local c_pos = {x=pos.x-(pos.x % 32),
                    y=pos.y-(pos.y % 32)}
    for i=-chunk_radius,chunk_radius do
        for k=-chunk_radius,chunk_radius do
            local x = c_pos.x+(i*32)
            local y = c_pos.y+(k*32)

            if (global.chunk_regrow.map[x] == nil) then
                global.chunk_regrow.map[x] = {}
            end
            global.chunk_regrow.map[x][y] = 1
            table.insert(global.chunk_regrow.list, c_pos)
        end
    end
end

-- Marks a safe area around around a position that won't ever be deleted.
function OarcRegrowthOffLimits(pos, chunk_radius)
    local c_pos = {x=pos.x-(pos.x % 32),
                    y=pos.y-(pos.y % 32)}
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


-- Refreshes timers on all chunks around a certain area
function OarcRegrowthRefreshArea(pos, chunk_radius)
    local c_pos = {x=pos.x-(pos.x % 32),
                    y=pos.y-(pos.y % 32)}
    for i=-chunk_radius,chunk_radius do
        for k=-chunk_radius,chunk_radius do
            local x = c_pos.x+(i*32)
            local y = c_pos.y+(k*32)

            if (global.chunk_regrow.map[x] == nil) then
                global.chunk_regrow.map[x] = {}
            end
            global.chunk_regrow.map[x][y] = game.tick
        end
    end
end

-- Refreshes timers on all chunks near an ACTIVE radar
function OarcRegrowthSectorScan(event)
    OarcRegrowthRefreshArea(event.radar.position, 17)
end


-- This is the main work function, it checks a single chunk in the list
-- per tick. It works according to the rules listed in the header of this
-- file.
function OarcRegrowthOnTick(event)

    -- We always check of value exists first... Due to the way events work, 
    -- this is a necessary check.
    if (global.chunk_regrow.list[global.chunk_regrow.chunk_index]) then

        -- Position of left_top of the chunk in the list.
        local x = global.chunk_regrow.list[global.chunk_regrow.chunk_index].x
        local y = global.chunk_regrow.list[global.chunk_regrow.chunk_index].y
        local pos = {x=x,y=y}

        -- Confirm we have a matching chunk in our map array
        if (global.chunk_regrow.map[x][y] ~= nil) then

            -- Check this chunk is NOT timed out, this should be the most common reason
            -- to go to the next list item, so I put it first to optimize the logic
            if ((global.chunk_regrow.map[x][y]+REGROWTH_TIMEOUT_TICKS) > game.tick) then
                goto GO_NEXT_CHUNK
            end

            -- Check if this chunk is off limits
            if (global.chunk_regrow.map[x][y] == -1) then
                global.chunk_regrow.num_chunks = global.chunk_regrow.num_chunks - 1
                table.remove(global.chunk_regrow.list, global.chunk_regrow.chunk_index)
                global.chunk_regrow.chunk_index = global.chunk_regrow.chunk_index - 1
                goto GO_NEXT_CHUNK
            end

            -- Check for pollution, refresh timer if found
            if (game.surfaces[GAME_SURFACE_NAME].get_pollution(pos) > 0) then
                global.chunk_regrow.map[x][y] = game.tick
                goto GO_NEXT_CHUNK
            end

            -- Check for players nearby, don't delete anything near players.
            -- And refresh the area around them if they happen to be near.
            local players_found = game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{area = {{x-(32*2), y-(32*2)}, {x+(32*2), y+(32*2)}}, type= "player"}
            if (next(players_found) ~= nil) then
                OarcRegrowthRefreshArea(pos, 2)
                goto GO_NEXT_CHUNK
            end

            -- Check for railway lines
            local railway_found = game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{area = {{x-(32*2), y-(32*2)}, {x+(32*2), y+(32*2)}}, name= "railway"}
            if (next(railway_found) ~= nil) then
                OarcRegrowthRefreshArea(pos, 2)
                goto GO_NEXT_CHUNK
            end


            -- Else, let's see if we can delete the chunk.
            local chunk_x = x/32
            local chunk_y = y/32

            -- Only delete chunks near map edges.
            local ungenerate_chunk_count = 0
            for i=-1,1 do
                for k=-1,1 do
                    if (not game.surfaces[GAME_SURFACE_NAME].is_chunk_generated({chunk_x+i,chunk_y+k})) then
                        ungenerate_chunk_count = ungenerate_chunk_count +1
                    end
                end
            end

            -- Delete the chunk and remove it from the list.              
            if (ungenerate_chunk_count >= 3) then
                game.surfaces[GAME_SURFACE_NAME].delete_chunk({chunk_x,chunk_y})
                global.chunk_regrow.num_chunks = global.chunk_regrow.num_chunks -1
                table.remove(global.chunk_regrow.list, global.chunk_regrow.chunk_index)
                global.chunk_regrow.chunk_index = global.chunk_regrow.chunk_index - 1
                global.chunk_regrow.map[x][y] = nil
                DebugPrint("Deleting Chunk: X="..x..",Y="..y)
            end
        else
            DebugPrint("No matching map entry: X="..x..",Y="..y)
        end

        ::GO_NEXT_CHUNK::
        global.chunk_regrow.chunk_index = global.chunk_regrow.chunk_index + 1
        if (global.chunk_regrow.chunk_index > global.chunk_regrow.num_chunks) then
            global.chunk_regrow.chunk_index = 1
        end

    end
end