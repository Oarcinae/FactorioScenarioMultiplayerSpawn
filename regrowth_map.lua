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


REGROWTH_TIMEOUT_TICKS = 60*30 -- 1 hour

-- Init globals and set player join area to be off limits.
function OarcRegrowthInit()
    global.chunk_regrow = {}
    global.chunk_regrow.map = {}
    global.chunk_regrow.list = {}
    global.chunk_regrow.num_chunks = 0
    global.chunk_regrow.chunk_index = 1
    global.chunk_regrow.rso_region_roll_counter = 0
    global.chunk_regrow.player_refresh_index = 1

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

-- Marks a chunk a position that won't ever be deleted.
function OarcRegrowthOffLimitsChunk(pos)
    local c_pos = {x=pos.x-(pos.x % 32),
                    y=pos.y-(pos.y % 32)}

    if (global.chunk_regrow.map[c_pos.x] == nil) then
        global.chunk_regrow.map[c_pos.y] = {}
    end
    global.chunk_regrow.map[c_pos.x][c_pos.y] = -1
end


-- Marks a safe area around a position that won't ever be deleted.
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

-- Refreshes timers on a chunk containing position
function OarcRegrowthRefreshChunk(pos)
    local c_pos = {x=pos.x-(pos.x % 32),
                    y=pos.y-(pos.y % 32)}

    if (global.chunk_regrow.map[c_pos.x] == nil) then
        global.chunk_regrow.map[c_pos.y] = {}
    end
    if (global.chunk_regrow.map[c_pos.x][c_pos.y] ~= -1) then
        global.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick
    end
    global.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick
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
            if (global.chunk_regrow.map[x][y] ~= -1) then
                global.chunk_regrow.map[x][y] = game.tick
            end
        end
    end
end

-- Refreshes timers on all chunks near an ACTIVE radar
function OarcRegrowthSectorScan(event)
    OarcRegrowthRefreshArea(event.radar.position, 16)
end


-- This is the main work function, it checks a single chunk in the list
-- per tick. It works according to the rules listed in the header of this
-- file.
function OarcRegrowthOnTick(event)

    -- Every half a second, refresh all chunks near a single player
    if ((game.tick % (30))==2) then
        global.chunk_regrow.player_refresh_index = global.chunk_regrow.player_refresh_index + 1
        if (global.chunk_regrow.player_refresh_index > #game.connected_players) then
            global.chunk_regrow.player_refresh_index = 1
        end
        for _,force in pairs(game.forces) do
            if (force ~= nil) then
                if ((force.name ~= enemy) and
                    (force.name ~= neutral) and
                    (force.name ~= player)) then

                    if (game.connected_players[global.chunk_regrow.player_refresh_index]) then
                        OarcRegrowthRefreshArea(game.connected_players[global.chunk_regrow.player_refresh_index].position, 20)
                    end
                end
            end
        end

    end

    -- Every 5 ticks
    if (((game.tick % 5) ==0 ) and (global.chunk_regrow.list[global.chunk_regrow.chunk_index] ~= nil)) then

        -- Position of left_top of the chunk in the list.
        local x = global.chunk_regrow.list[global.chunk_regrow.chunk_index].x
        local y = global.chunk_regrow.list[global.chunk_regrow.chunk_index].y
        local pos = {x=x,y=y}

        -- Confirm we have a matching chunk in our map array
        if (global.chunk_regrow.map[x][y] ~= nil) then

            -- Check this chunk is NOT timed out, this should be the most common reason
            -- to go to the next list item, so I put it first to optimize the logic
            if ((global.chunk_regrow.map[x][y]+REGROWTH_TIMEOUT_TICKS) > game.tick) then
                -- Do nothing
             
            -- Check if this chunk is off limits
            elseif (global.chunk_regrow.map[x][y] == -1) then
                -- DebugPrint("Marking chunk as off limits: X:"..x.." Y:"..y)
                global.chunk_regrow.num_chunks = global.chunk_regrow.num_chunks - 1
                table.remove(global.chunk_regrow.list, global.chunk_regrow.chunk_index)
                global.chunk_regrow.chunk_index = global.chunk_regrow.chunk_index - 1

            -- Check for pollution, refresh timer if found
            elseif (game.surfaces[GAME_SURFACE_NAME].get_pollution(pos) > 0) then
                global.chunk_regrow.map[x][y] = game.tick

            -- Else, let's see if we can delete the chunk.
            else

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
                    -- DebugPrint("Deleting Chunk: X="..x..",Y="..y)
                end
            end
        else
            -- I don't think should ever happen...
            DebugPrint("No matching map entry: X="..x..",Y="..y)
            global.chunk_regrow.num_chunks = global.chunk_regrow.num_chunks -1
            table.remove(global.chunk_regrow.list, global.chunk_regrow.chunk_index)
            global.chunk_regrow.chunk_index = global.chunk_regrow.chunk_index - 1
        end

        global.chunk_regrow.chunk_index = global.chunk_regrow.chunk_index + 1
        if (global.chunk_regrow.chunk_index > global.chunk_regrow.num_chunks) then
            global.chunk_regrow.chunk_index = 1
        end

    end
end