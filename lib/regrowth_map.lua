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

-- TODO: Make this a mod startup setting?
REGROWTH_TIMEOUT_TICKS = TICKS_PER_HOUR -- TICKS_PER_HOUR TICKS_PER_MINUTE

--- If a chunk is marked "active", then it will only be checked by the "world eater" system if that is enabled.
--- World eater does more extensive checks to see if a chunk might be safe to delete. For example, if a player builds
--- stuff in a chunk it will be marked as "active" and won't be checked by the regrowth system.
REGROWTH_FLAG_ACTIVE = -1

--- These chunks will NEVER be deleted by the regrowth + world eater systems. However, they can be overwritten in some
--- cases. Like when a player leaves the game early and their spawn is deleted.
REGROWTH_FLAG_PERMANENT = -2

--- Radius in chunks around a player to mark as safe.
REGROWTH_ACTIVE_AREA_AROUND_PLAYER = 4

---The removal list contains chunks that are marked for removal. Each entry is a table with the following fields:
---@alias RemovalListEntry { pos : ChunkPosition, force: boolean, surface: string }


---Init globals for regrowth
---@return nil
function RegrowthInit()
    global.rg = {}
    global.rg.player_refresh_index = nil

    global.rg.force_removal_flag = -2000 -- Set to a negative number to disable it by default
    global.rg.timeout_ticks = REGROWTH_TIMEOUT_TICKS

    global.rg.current_surface = nil -- The current surface we are iterating through
    global.rg.current_surface_index = 1
    global.rg.active_surfaces = {} -- List of all surfaces with regrowth enabled
    global.rg.chunk_iter = nil -- We only iterate through onface at a time
    
    
    global.rg.world_eater_iter = nil
    global.rg.we_current_surface = nil
    global.rg.we_current_surface_index = 1

    ---@type table<integer, RemovalListEntry>
    global.rg.removal_list = {}

    for surface_name,_ in pairs(game.surfaces) do
        InitSurface(surface_name --[[@as string]])
    end
end

---Called when a new surface is created. This is used to add new surfaces to the regrowth map.
---@param event EventData.on_surface_created
---@return nil
function RegrowthSurfaceCreated(event)
    InitSurface(game.surfaces[event.surface_index].name)
end

---Called when a surface is deleted. This is used to remove surfaces from the regrowth map.
---@param event EventData.on_pre_surface_deleted
---@return nil
function RegrowthSurfaceDeleted(event)
    log("WARNING - RegrowthSurfaceDeleted: " .. game.surfaces[event.surface_index].name)
    local surface_name = game.surfaces[event.surface_index].name
    global.rg[surface_name] = nil
    for key,value in pairs(global.rg.active_surfaces) do
        if (value == surface_name) then
            table.remove(global.rg.active_surfaces, key)
            break
        end
    end
    --TODO: Check if we need to reset any of the indexes in use.
end

---Initialize the new surface for regrowth
---@param surface_name string - The surface name to act on
---@return nil
function InitSurface(surface_name)

    local enable_regrowth_on_surface = true -- TODO: Default to true? Or make it a setting?
    for _, blacklist_surface_name in pairs(global.ocfg.regrowth.surface_blacklist) do
        if (surface_name == blacklist_surface_name) then
            log("RegrowthInit: Blacklisted surface found: " .. surface_name)
            enable_regrowth_on_surface = false
            return
        end
    end

    if (enable_regrowth_on_surface) then
        -- Add a new surface to the regrowth map
        global.rg[surface_name] = {}

        -- This is a 2D array of chunk positions and their last tick updated / status
        global.rg[surface_name].map = {}

        -- Set the current surface tone found
        if (global.rg.current_surface == nil) then
            global.rg.current_surface = surface_name
            global.rg.we_current_surface = surface_name
        end

        table.insert(global.rg.active_surfaces, surface_name)
    end
end

---Trigger an immediate cleanup of any chunks that are marked for removal.
---@return nil
function TriggerCleanup()
    global.rg.force_removal_flag = game.tick
end

-- Turn this into a admin GUI button.
-- function RegrowthForceRemoveChunksCmd(cmd_table)
--     if (game.players[cmd_table.player_index].admin) then
--         TriggerCleanup()
--     end
-- end

---Get the next player index available. This is used to loop through players to refresh the areas around them.
---@return integer
function GetNextPlayerIndex()
    if (not global.rg.player_refresh_index or not game.players[global.rg.player_refresh_index]) then
        global.rg.player_refresh_index = 1
    else
        global.rg.player_refresh_index = global.rg.player_refresh_index + 1
    end

    -- TODO: This may be an issue since I think the player index might be a sparse array?
    if (global.rg.player_refresh_index > #game.players) then
        global.rg.player_refresh_index = 1
    end

    return global.rg.player_refresh_index
end

---@alias ActiveSurfaceInfo { surface : string, index : integer }

---Sets the current surface to the next active surface. This is used to loop through surfaces.
---@param current_index integer - The current index in the active surfaces list
---@return ActiveSurfaceInfo - The new current surface name and index
function GetNextActiveSurface(current_index)

    local count = #(global.rg.active_surfaces)
    local next_index = current_index + 1

    if (next_index > count) then
        next_index = 1
    end

    local next_surface = global.rg.active_surfaces[next_index]

    return { surface = next_surface, index = next_index }
end

---Adds new chunks to the global table to track them.
---This should always be called first in the chunk generate sequence
---(Compared to other RSO & Oarc related functions...)
---@param event EventData.on_chunk_generated
---@return nil
function RegrowthChunkGenerate(event)
    local c_pos = event.position
    local surface_name = event.surface.name

    -- Surface not in regrowth map, ignore it.
    if (global.rg[surface_name] == nil) then return end

    -- If this is the first chunk in that row:
    if (global.rg[surface_name].map[c_pos.x] == nil) then
        global.rg[surface_name].map[c_pos.x] = {}
    end

    -- Only update it if it isn't already set!
    if (global.rg[surface_name].map[c_pos.x][c_pos.y] == nil) then
        global.rg[surface_name].map[c_pos.x][c_pos.y] = game.tick
    end
end

---Mark an area for "immediate" forced removal
---@param surface_name string - The surface name to act on
---@param pos TilePosition - The tile position to mark for removal
---@param chunk_radius integer - The radius in chunks around the position to mark for removal
---@return nil
function RegrowthMarkAreaForRemoval(surface_name, pos, chunk_radius)
    local c_pos = GetChunkPosFromTilePos(pos)
    for i = -chunk_radius, chunk_radius do
        local x = c_pos.x + i
        for k = -chunk_radius, chunk_radius do
            local y = c_pos.y + k

            if (global.rg[surface_name].map[x] ~= nil) then
                global.rg[surface_name].map[x][y] = nil
            end

            ---@type RemovalListEntry
            local removal_entry = { pos = { x = x, y = y }, force = true, surface = surface_name }
            table.insert(global.rg.removal_list, removal_entry)
        end
        if (table_size(global.rg[surface_name].map[x]) == 0) then
            global.rg[surface_name].map[x] = nil
        end
    end
end

---Downgrades permanent flag to semi-permanent.
---@param surface_name string - The surface name to act on
---@param pos TilePosition - The tile position to mark
---@param chunk_radius integer - The radius in chunks around the position to mark
---@return nil
function RegrowthMarkAreaNotPermanentOVERWRITE(surface_name, pos, chunk_radius)
    local c_pos = GetChunkPosFromTilePos(pos)
    for i = -chunk_radius, chunk_radius do
        local x = c_pos.x + i
        for k = -chunk_radius, chunk_radius do
            local y = c_pos.y + k

            if (global.rg[surface_name].map[x] and
                    global.rg[surface_name].map[x][y] and
                    (global.rg[surface_name].map[x][y] == REGROWTH_FLAG_PERMANENT)) then
                global.rg[surface_name].map[x][y] = REGROWTH_FLAG_ACTIVE
            end
        end
    end
end

---Marks a chunk containing a position to be relatively permanent.
---@param surface_name string - The surface name to act on
---@param c_pos ChunkPosition - The chunk position to mark
---@param permanent boolean - If true, the chunk will be marked as permanent
---@return nil
function MarkChunkSafe(surface_name, c_pos, permanent)
    if (global.rg[surface_name].map[c_pos.x] == nil) then
        global.rg[surface_name].map[c_pos.x] = {}
    end

    if (permanent) then
        global.rg[surface_name].map[c_pos.x][c_pos.y] = REGROWTH_FLAG_PERMANENT

    -- Make sure we don't overwrite unless it's a permanent flag
    elseif (global.rg[surface_name].map[c_pos.x][c_pos.y] and
            (global.rg[surface_name].map[c_pos.x][c_pos.y] ~= REGROWTH_FLAG_PERMANENT)) then
        global.rg[surface_name].map[c_pos.x][c_pos.y] = REGROWTH_FLAG_ACTIVE
    end
end

---Marks a safe area around a CHUNK position to be relatively permanent.
---@param surface_name string - The surface name to act on
---@param c_pos ChunkPosition - The chunk position to mark
---@param chunk_radius integer - The radius in chunks around the position to mark
---@param permanent boolean - If true, the chunk will be marked as permanent
---@return nil
function RegrowthMarkAreaSafeGivenChunkPos(surface_name, c_pos, chunk_radius, permanent)
    if (global.rg == nil) then return end

    for i = -chunk_radius, chunk_radius do
        for j = -chunk_radius, chunk_radius do
            MarkChunkSafe(surface_name, { x = c_pos.x + i, y = c_pos.y + j }, permanent)
        end
    end
end

---Marks a safe area around a TILE position to be relatively permanent.
---@param surface_name string - The surface name to act on
---@param pos TilePosition - The tile position to mark
---@param chunk_radius integer - The radius in chunks around the position to mark
---@param permanent boolean - If true, the chunk will be marked as permanent
---@return nil
function RegrowthMarkAreaSafeGivenTilePos(surface_name, pos, chunk_radius, permanent)
    if (global.rg == nil) then return end

    local c_pos = GetChunkPosFromTilePos(pos)
    RegrowthMarkAreaSafeGivenChunkPos(surface_name, c_pos, chunk_radius, permanent)
end

---Refreshes timers on a chunk containing position
---@param surface_name string - The surface name to act on
---@param pos TilePosition - The tile position to mark
---@param bonus_time integer - The bonus time to add to the current game tick
---@return nil
function RefreshChunkTimer(surface_name, pos, bonus_time)
    local c_pos = GetChunkPosFromTilePos(pos)

    if (global.rg[surface_name].map[c_pos.x] == nil) then
        global.rg[surface_name].map[c_pos.x] = {}
    end
    if (global.rg[surface_name].map[c_pos.x][c_pos.y] >= 0) then
        global.rg[surface_name].map[c_pos.x][c_pos.y] = game.tick + bonus_time
    end
end


---Refreshes timers on all chunks around a certain area
---@param surface_name string - The surface name to act on
---@param pos TilePosition - The tile position to mark
---@param chunk_radius integer - The radius in chunks around the position to mark
---@param bonus_time integer - The bonus time to add to the current game tick
---@return nil
function RefreshArea(surface_name, pos, chunk_radius, bonus_time)
    local c_pos = GetChunkPosFromTilePos(pos)

    RefreshAreaChunkPosition(surface_name, c_pos, chunk_radius, bonus_time)
end

---Refreshes timers on all chunks around a certain area
---@param surface_name string - The surface name to act on
---@param c_pos ChunkPosition - The chunk position to mark
---@param chunk_radius integer - The radius in chunks around the position to mark
---@param bonus_time integer - The bonus time to add to the current game tick
---@return nil
function RefreshAreaChunkPosition(surface_name, c_pos, chunk_radius, bonus_time)
    for i = -chunk_radius, chunk_radius do
        local x = c_pos.x + i
        for k = -chunk_radius, chunk_radius do
            local y = c_pos.y + k

            if (global.rg[surface_name].map[x] == nil) then
                global.rg[surface_name].map[x] = {}
            end
            if ((global.rg[surface_name].map[x][y] == nil) or (global.rg[surface_name].map[x][y] >= 0)) then
                global.rg[surface_name].map[x][y] = game.tick + bonus_time
            end
        end
    end
end

---Refreshes timers on all chunks near an ACTIVE radar
---@param event EventData.on_sector_scanned
---@return nil
function RegrowthSectorScan(event)
    local surface_name = event.radar.surface.name

    -- Surface not in regrowth map, ignore it.
    if (global.rg[surface_name] == nil) then return end

    ---@type integer
    local radar_range = event.radar.prototype.max_distance_of_nearby_sector_revealed
    RefreshAreaChunkPosition(surface_name, event.chunk_position, radar_range, 0)
end

---Refresh all chunks near a single player. Cyles through all connected players.
---@return nil
function RefreshPlayerArea()
    player_index = GetNextPlayerIndex()
    if (player_index and game.connected_players[player_index]) then
        local player = game.connected_players[player_index]
        local surface_name = player.surface.name

        if (not player.character) then return end
        if (global.rg[surface_name] == nil) then return end

        RefreshArea(surface_name, player.position, REGROWTH_ACTIVE_AREA_AROUND_PLAYER, 0)
    end
end

---Gets the next chunk the array map and checks to see if it has timed out.
---Adds it to the removal list if it has.
---@return nil
function RegrowthSingleStepArray()
    local current_surface = global.rg.current_surface

    -- Make sure we have a valid iterator!
    if (not global.rg.chunk_iter or not global.rg.chunk_iter.valid) then
        global.rg.chunk_iter = game.surfaces[current_surface].get_chunks()
    end

    local next_chunk = global.rg.chunk_iter()

    -- Check if we reached the end
    if (not next_chunk) then

        -- Switch to the next active surface
        -- TODO: Validate this
        local next_surface_info = GetNextActiveSurface(global.rg.current_surface_index)
        global.rg.current_surface = next_surface_info.surface
        global.rg.current_surface_index = next_surface_info.index

        -- log("RegrowthSingleStepArray: Switching to next surface: " .. global.rg.current_surface)

        current_surface = global.rg.current_surface
        global.rg.chunk_iter = game.surfaces[current_surface].get_chunks()
        next_chunk = global.rg.chunk_iter()

        -- Possible that there are no chunks in this surface?
        if (not next_chunk) then
            return
        end
    end

    -- Do we have it in our map?
    if (not global.rg[current_surface].map[next_chunk.x] or not global.rg[current_surface].map[next_chunk.x][next_chunk.y]) then
        --TODO: Confirm this is the right thing to do? What chunk should not be in our map at all?
        return -- Chunk isn't in our map so we don't care?
    end

    -- If the chunk has timed out, add it to the removal list
    local c_timer = global.rg[current_surface].map[next_chunk.x][next_chunk.y]
    if ((c_timer ~= nil) and (c_timer >= 0) and ((c_timer + global.rg.timeout_ticks) < game.tick)) then
        -- Check chunk actually exists
        if (game.surfaces[current_surface].is_chunk_generated({ x = next_chunk.x, y = next_chunk.y })) then

            ---@type RemovalListEntry
            local removal_entry = {pos = {x = next_chunk.x, y = next_chunk.y }, force = false, surface = current_surface}
            table.insert(global.rg.removal_list, removal_entry)
            global.rg[current_surface].map[next_chunk.x][next_chunk.y] = nil
        end
    end
end

---Remove all chunks at same time to reduce impact to FPS/UPS
---@return nil
function OarcRegrowthRemoveAllChunks()
    for key, c_remove in pairs(global.rg.removal_list) do
        local c_pos = c_remove.pos
        local surface_name = c_remove.surface

        -- Confirm chunk is still expired
        if (not global.rg[surface_name].map[c_pos.x] or not global.rg[surface_name].map[c_pos.x][c_pos.y]) then
            -- If it is FORCE removal, then remove it regardless of pollution.
            if (c_remove.force) then
                game.surfaces[surface_name].delete_chunk(c_pos)

            -- If it is a normal timeout removal, don't do it if there is pollution in the chunk.
            elseif (game.surfaces[surface_name].get_pollution({ c_pos.x * 32, c_pos.y * 32 }) > 0) then
                global.rg[surface_name].map[c_pos.x][c_pos.y] = game.tick

            -- Else delete the chunk
            else
                game.surfaces[surface_name].delete_chunk(c_pos)
            end
        end

        -- Remove entry
        global.rg.removal_list[key] = nil
    end

    -- MUST GET A NEW CHUNK ITERATOR ON DELETE CHUNK!
    global.rg.chunk_iter = nil
    global.rg.world_eater_iter = nil
end

---This is the main work function, it checks a single chunk in the list per tick. It works according to the rules
---listed in the header of this file.
---@return nil
function RegrowthOnTick()

    -- Every half a second, refresh all chunks near a single player
    -- Cyles through all players. Tick is offset by 2
    if ((game.tick % (30)) == 2) then
        RefreshPlayerArea()
    end

    -- Every tick, check a few points in the 2d array of the only active surface According to /measured-command this
    -- shouldn't take more than 0.1ms on average
    for i = 1, 20 do
        RegrowthSingleStepArray()
    end

    if (global.ocfg.regrowth.enable_world_eater) then
        WorldEaterSingleStep()
    end

    -- Allow enable/disable of auto cleanup, can change during runtime.
    local interval_ticks = global.rg.timeout_ticks
    -- Send a broadcast warning before it happens.
    if ((game.tick % interval_ticks) == interval_ticks - (60 * 30 + 1)) then
        if (#global.rg.removal_list > 100) then
            SendBroadcastMsg("Map cleanup in 30 seconds... Unused and old map chunks will be deleted!")
        end
    end

    -- Delete all listed chunks across all active surfaces
    if ((game.tick % interval_ticks) == interval_ticks - 1) then
        if (#global.rg.removal_list > 100) then
            OarcRegrowthRemoveAllChunks()
            SendBroadcastMsg("Map cleanup done, sorry for your loss.")
        end
    end
end

-- This function removes any chunks flagged but on demand.
-- Controlled by the global.rg.force_removal_flag
function RegrowthForceRemovalOnTick()
    -- Catch force remove flag
    if (game.tick == global.rg.force_removal_flag + 60) then
        SendBroadcastMsg("Map cleanup (forced) in 30 seconds... Unused and old map chunks will be deleted!")
    end

    if (game.tick == global.rg.force_removal_flag + (60 * 30 + 60)) then
        OarcRegrowthRemoveAllChunks()
        SendBroadcastMsg("Map cleanup done, sorry for your loss.")
    end
end

function WorldEaterSingleStep()
    local current_surface = global.rg.we_current_surface

    -- Make sure we have a valid iterator!
    if (not global.rg.world_eater_iter or not global.rg.world_eater_iter.valid) then
        global.rg.world_eater_iter = game.surfaces[current_surface].get_chunks()
    end

    local next_chunk = global.rg.world_eater_iter()

    -- Check if we reached the end
    if (not next_chunk) then

        -- Switch to the next active surface
        -- TODO: Validate this
        local next_surface_info = GetNextActiveSurface(global.rg.we_current_surface_index)
        global.rg.we_current_surface = next_surface_info.surface
        global.rg.we_current_surface_index = next_surface_info.index
        current_surface = global.rg.we_current_surface

        -- log("WorldEaterSingleStep: Switching to next surface: " .. global.rg.we_current_surface)

        global.rg.world_eater_iter = game.surfaces[current_surface].get_chunks()
        next_chunk = global.rg.world_eater_iter()

        -- Possible that there are no chunks in this surface?
        if (not next_chunk) then
            return
        end
    end

    -- Do we have it in our map?
    if (not global.rg[current_surface].map[next_chunk.x] or not global.rg[current_surface].map[next_chunk.x][next_chunk.y]) then
        return -- Chunk isn't in our map so we don't care?
    end

    -- Search for any abandoned radars and destroy them?
    local abandoned_radars = game.surfaces[current_surface].find_entities_filtered { area = next_chunk.area,
        force = { global.ocore.abandoned_force },
        name = "radar" }
    for k, v in pairs(abandoned_radars) do
        v.die(nil)
    end

    -- Search for any entities with _DESTROYED_ force and kill them.
    local destroy_entities = game.surfaces[current_surface].find_entities_filtered { area = next_chunk.area,
        force = { global.ocore.destroyed_force } }
    for k, v in pairs(destroy_entities) do
        v.die(nil)
    end


    local c_timer = global.rg[current_surface].map[next_chunk.x][next_chunk.y]

    -- Only check chunnks that are flagged as "safe".
    -- Others are either permanent or will be handled by the default regrowth checks.
    if (c_timer == -1) then
        local area = {
            left_top = { next_chunk.area.left_top.x - 8, next_chunk.area.left_top.y - 8 },
            right_bottom = { next_chunk.area.right_bottom.x + 8, next_chunk.area.right_bottom.y + 8 }
        }

        local entities = game.surfaces[current_surface].find_entities_filtered { area = area, force = { "enemy", "neutral" }, invert = true }
        local total_count = #entities
        local has_last_user_set = false

        if (total_count > 0) then
            for k, v in pairs(entities) do
                --string.contains is valid but not in the type definitions?
                ---@diagnostic disable-next-line: undefined-field
                if (v.last_user or (v.type == "character") or string.contains(v.type, "robot")) then
                    has_last_user_set = true
                    return -- This means we're done checking this chunk.
                end
            end

            -- If all entities found have no last user, then KILL all entities!
            if (not has_last_user_set) then
                for k, v in pairs(entities) do
                    if (v and v.valid) then
                        v.die(nil)
                    end
                end
                -- SendBroadcastMsg(next_chunk.x .. "," .. next_chunk.y .. " WorldEaterSingleStep - ENTITIES FOUND")
                global.rg[current_surface].map[next_chunk.x][next_chunk.y] = game.tick -- Set the timer on it.
            end
        else
            -- SendBroadcastMsg(next_chunk.x .. "," .. next_chunk.y .. " WorldEaterSingleStep - NO ENTITIES FOUND")
            global.rg[current_surface].map[next_chunk.x][next_chunk.y] = game.tick -- Set the timer on it.
        end
    end
end
