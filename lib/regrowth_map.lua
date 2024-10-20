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

--- These chunks are marked for removal. They will be deleted by the regrowth system.
--- If it gets refreshed before it is removed, then it will be marked safe again
REGROWTH_FLAG_REMOVAL = -1

--- If a chunk is marked "active", then it will only be checked by the "world eater" system if that is enabled.
--- World eater does more extensive checks to see if a chunk might be safe to delete. For example, if a player builds
--- stuff in a chunk it will be marked as "active" and won't be checked by the regrowth system.
REGROWTH_FLAG_ACTIVE = -2

--- These chunks will NEVER be deleted by the regrowth + world eater systems. However, they can be overwritten in some
--- cases. Like when a player leaves the game early and their spawn is deleted.
REGROWTH_FLAG_PERMANENT = -3



--- Radius in chunks around a player to mark as safe.
REGROWTH_ACTIVE_AREA_AROUND_PLAYER = 2

---The removal list contains chunks that are marked for removal. Each entry is a table with the following fields:
---@alias RemovalListEntry { pos : ChunkPosition, force: boolean, surface: string }


---Init globals for regrowth
---@return nil
function RegrowthInit()
    storage.rg = {}
    storage.rg.player_refresh_index = nil

    storage.rg.force_removal_flag = -2000 -- Set to a negative number to disable it by default

    storage.rg.current_surface = nil -- The current surface we are iterating through
    storage.rg.current_surface_index = 1
    storage.rg.active_surfaces = {} -- List of all surfaces with regrowth enabled
    storage.rg.chunk_iter = nil -- We only iterate through onface at a time

    storage.rg.we_chunk_iter = nil
    storage.rg.we_current_surface = nil
    storage.rg.we_current_surface_index = 1


    ---@type LuaEntity[]
    storage.rg.spidertrons = {} -- List of all spidertrons in the game
    storage.rg_spidertron_index = 1

    ---@type RemovalListEntry[]
    storage.rg.removal_list = {}

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
    RegrowthDisableSurface(surface_name )
end

---Initialize the new surface for regrowth
---@param surface_name string - The surface name to act on
---@return nil
function InitSurface(surface_name)

    if (not IsSurfaceBlacklisted(surface_name) and not TableContains(storage.rg.active_surfaces, surface_name)) then
        log("Adding surface to regrowth: " .. surface_name)

        -- Add a new surface to the regrowth map (Don't overwrite if it already exists)
        if (storage.rg[surface_name] == nil) then
            storage.rg[surface_name] = {}
        end

        -- This is a 2D array of chunk positions and their last tick updated / status (Don't overwrite if it already exists)
        if (storage.rg[surface_name].map == nil) then
            storage.rg[surface_name].map = {}
        end

        -- Set the current surface to the first one found if none are set.
        if (storage.rg.current_surface == nil) then
            storage.rg.current_surface = surface_name
            storage.rg.we_current_surface = surface_name
        end

        storage.rg[surface_name].active = true
        table.insert(storage.rg.active_surfaces, surface_name)
    end
end

function RegrowthDisableSurface(surface_name)

    -- We don't want to delete the surface history in case it's re-enabled later!
    -- storage.rg[surface_name] = nil

    storage.rg[surface_name].active = false
    TableRemoveOneUsingPairs(storage.rg.active_surfaces, surface_name)

    -- Make sure indices are reset if needed
    if (storage.rg.current_surface == surface_name) then
        storage.rg.current_surface = nil
        storage.rg.current_surface_index = 1
    end
    if (storage.rg.we_current_surface == surface_name) then
        storage.rg.we_current_surface = nil
        storage.rg.we_current_surface_index = 1
    end
    if #storage.rg.active_surfaces > 0 then
        storage.rg.current_surface = storage.rg.active_surfaces[1]
        storage.rg.we_current_surface = storage.rg.active_surfaces[1]
    end
end

---Simple check to see if a surface is enabled for regrowth
---@param surface_name string - The surface name to act on
---@return boolean
function IsRegrowthEnabledOnSurface(surface_name)
    if (storage.rg[surface_name] == nil) then return false end
    return storage.rg[surface_name].active
end

---Enables a surface by initializing it.
---@param surface_name string - The surface name to act on
---@return nil
function RegrowthEnableSurface(surface_name)
    InitSurface(surface_name)
end

---Trigger an immediate cleanup of any chunks that are marked for removal.
---@return nil
function TriggerCleanup()
    storage.rg.force_removal_flag = game.tick
end

-- Turn this into a admin GUI button.
-- function RegrowthForceRemoveChunksCmd(cmd_table)
--     if (game.players[cmd_table.player_index].admin) then
--         TriggerCleanup()
--     end
-- end

---Get the next player index available. This is used to loop through ONLINE players to refresh the areas around them.
---@return integer
function GetNextConnectedPlayerIndex()
    if (storage.rg.player_refresh_index == nil) or (game.connected_players[storage.rg.player_refresh_index] == nil) then
        storage.rg.player_refresh_index = 1
    else
        storage.rg.player_refresh_index = storage.rg.player_refresh_index + 1
    end

    if (storage.rg.player_refresh_index > #game.connected_players) then
        storage.rg.player_refresh_index = 1
    end

    return storage.rg.player_refresh_index
end

---@alias ActiveSurfaceInfo { surface : string, index : integer }

---Sets the current surface to the next active surface. This is used to loop through surfaces.
---@param current_index integer - The current index in the active surfaces list
---@return ActiveSurfaceInfo - The new current surface name and index
function GetNextActiveSurface(current_index)

    local count = #(storage.rg.active_surfaces)
    local next_index = current_index + 1

    if (next_index > count) then
        next_index = 1
    end

    local next_surface = storage.rg.active_surfaces[next_index]

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

    -- Surface not init or not active, ignore it.
    if not IsRegrowthEnabledOnSurface(surface_name) then return end

    -- If this is the first chunk in that row:
    if (storage.rg[surface_name].map[c_pos.x] == nil) then
        storage.rg[surface_name].map[c_pos.x] = {}
    end

    -- Only update it if it isn't already set!
    if (storage.rg[surface_name].map[c_pos.x][c_pos.y] == nil) then
        storage.rg[surface_name].map[c_pos.x][c_pos.y] = game.tick
        -- log("RegrowthChunkGenerate: " .. c_pos.x .. "," .. c_pos.y .. " on surface: " .. surface_name)
    end
end

---Mark an area for "immediate" forced removal, this will override any pemranent flags.
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

            if (storage.rg[surface_name].map[x] == nil) then
                storage.rg[surface_name].map[x] = {}
            end
            storage.rg[surface_name].map[x][y] = REGROWTH_FLAG_REMOVAL

            ---@type RemovalListEntry
            local removal_entry = { pos = { x = x, y = y }, force = true, surface = surface_name }
            table.insert(storage.rg.removal_list, removal_entry)
        end
    end
end

-- ---Downgrades permanent flag to semi-permanent.
-- ---@param surface_name string - The surface name to act on
-- ---@param pos TilePosition - The tile position to mark
-- ---@param chunk_radius integer - The radius in chunks around the position to mark
-- ---@return nil
-- function RegrowthMarkAreaNotPermanentOVERWRITE(surface_name, pos, chunk_radius)
--     local c_pos = GetChunkPosFromTilePos(pos)
--     for i = -chunk_radius, chunk_radius do
--         local x = c_pos.x + i
--         for k = -chunk_radius, chunk_radius do
--             local y = c_pos.y + k

--             if (storage.rg[surface_name].map[x] and
--                     storage.rg[surface_name].map[x][y] and
--                     (storage.rg[surface_name].map[x][y] == REGROWTH_FLAG_PERMANENT)) then
--                 storage.rg[surface_name].map[x][y] = REGROWTH_FLAG_ACTIVE
--             end
--         end
--     end
-- end

---Marks a chunk containing a position to be relatively permanent.
---@param surface_name string - The surface name to act on
---@param c_pos ChunkPosition - The chunk position to mark
---@param permanent boolean - If true, the chunk will be marked as permanent
---@return nil
function MarkChunkSafe(surface_name, c_pos, permanent)
    if (storage.rg[surface_name].map[c_pos.x] == nil) then
        storage.rg[surface_name].map[c_pos.x] = {}
    end

    if (permanent) then
        storage.rg[surface_name].map[c_pos.x][c_pos.y] = REGROWTH_FLAG_PERMANENT

    -- Make sure we don't overwrite unless it's a permanent flag
    elseif (storage.rg[surface_name].map[c_pos.x][c_pos.y] and
            (storage.rg[surface_name].map[c_pos.x][c_pos.y] ~= REGROWTH_FLAG_PERMANENT)) then
        storage.rg[surface_name].map[c_pos.x][c_pos.y] = REGROWTH_FLAG_ACTIVE
    end
end

---Marks a safe area around a CHUNK position to be relatively permanent.
---@param surface_name string - The surface name to act on
---@param c_pos ChunkPosition - The chunk position to mark
---@param chunk_radius integer - The radius in chunks around the position to mark
---@param permanent boolean - If true, the chunk will be marked as permanent
---@return nil
function RegrowthMarkAreaSafeGivenChunkPos(surface_name, c_pos, chunk_radius, permanent)
    if (storage.rg[surface_name] == nil) then return end

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
    if not IsRegrowthEnabledOnSurface(surface_name) then return end

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

    if (storage.rg[surface_name].map[c_pos.x] == nil) then
        storage.rg[surface_name].map[c_pos.x] = {}
    end
    if (storage.rg[surface_name].map[c_pos.x][c_pos.y] >= REGROWTH_FLAG_REMOVAL) then
        storage.rg[surface_name].map[c_pos.x][c_pos.y] = game.tick + bonus_time
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

            if (storage.rg[surface_name].map[x] == nil) then
                storage.rg[surface_name].map[x] = {}
            end
            if ((storage.rg[surface_name].map[x][y] == nil) or (storage.rg[surface_name].map[x][y] >= REGROWTH_FLAG_REMOVAL)) then
                storage.rg[surface_name].map[x][y] = game.tick + bonus_time
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
    if (storage.rg[surface_name] == nil) then return end

    ---@type integer
    local radar_range = event.radar.prototype.max_distance_of_nearby_sector_revealed --TODO: Space age quality might affect this?
    RefreshAreaChunkPosition(surface_name, event.chunk_position, radar_range, 0)
end

---Refresh all chunks near a single player. Cyles through all connected players.
---@return nil
function RefreshPlayerArea()
    player_index = GetNextConnectedPlayerIndex()
    if (player_index and game.connected_players[player_index]) then
        local player = game.connected_players[player_index]
        local surface_name = player.surface.name

        if (not player.character) then return end
        if (storage.rg[surface_name] == nil) or (not storage.rg[surface_name].active) then return end

        RefreshArea(surface_name, player.position, REGROWTH_ACTIVE_AREA_AROUND_PLAYER, 0)
    end
end

---Updates the chunk_iter and returns the next chunk from it. May not be valid if it no chunks exist.
---@return ChunkPositionAndArea?
function GetNextChunkAndUpdateIter()

    -- Make sure we have a valid iterator!
    if (not storage.rg.chunk_iter or not storage.rg.chunk_iter.valid) then
        storage.rg.chunk_iter = game.surfaces[storage.rg.current_surface].get_chunks()
    end

    local next_chunk = storage.rg.chunk_iter()

    -- Check if we reached the end
    if (next_chunk == nil) then

        -- Switch to the next active surface
        local next_surface_info = GetNextActiveSurface(storage.rg.current_surface_index)
        storage.rg.current_surface = next_surface_info.surface
        storage.rg.current_surface_index = next_surface_info.index
        storage.rg.chunk_iter = game.surfaces[storage.rg.current_surface].get_chunks()
        next_chunk = storage.rg.chunk_iter()
    end

    return next_chunk
end

---Updates the chunk_iter (for World Eater) and returns the next chunk from it. May not be valid if it no chunks exist.
---@return ChunkPositionAndArea?
function GetNextChunkAndUpdateWorldEaterIter()

    -- Make sure we have a valid iterator!
    if (not storage.rg.we_chunk_iter or not storage.rg.we_chunk_iter.valid) then
        storage.rg.we_chunk_iter = game.surfaces[storage.rg.we_current_surface].get_chunks()
    end

    local next_chunk = storage.rg.we_chunk_iter()

    -- Check if we reached the end
    if (next_chunk == nil) then

        -- Switch to the next active surface
        local next_surface_info = GetNextActiveSurface(storage.rg.we_current_surface_index)
        storage.rg.we_current_surface = next_surface_info.surface
        storage.rg.we_current_surface_index = next_surface_info.index
        storage.rg.we_chunk_iter = game.surfaces[storage.rg.we_current_surface].get_chunks()
        next_chunk = storage.rg.we_chunk_iter()
    end

    return next_chunk
end

---Gets the next chunk the array map and checks to see if it has timed out.
---Adds it to the removal list if it has.
---@return nil
function RegrowthSingleStepArray()

    local next_chunk = GetNextChunkAndUpdateIter()
    if (next_chunk == nil) then return end
    local current_surface = storage.rg.current_surface

    -- It's possible that if regrowth is disabled/enabled during runtime we might miss on_chunk_generated.
    -- This will catch that case and add the chunk to the map.
    if (storage.rg[current_surface].map[next_chunk.x] == nil) then
        storage.rg[current_surface].map[next_chunk.x] = {}
    end
    if (storage.rg[current_surface].map[next_chunk.x][next_chunk.y] == nil and game.surfaces[current_surface].is_chunk_generated(next_chunk)) then
        log("RegrowthSingleStepArray: Chunk not in map: " .. next_chunk.x .. "," .. next_chunk.y .. " on surface: " .. current_surface)
        local has_player_entities = CheckIfChunkHasAnyPlayerEntities(current_surface, next_chunk)
        if has_player_entities then
            storage.rg[current_surface].map[next_chunk.x][next_chunk.y] = REGROWTH_FLAG_ACTIVE
        else
            storage.rg[current_surface].map[next_chunk.x][next_chunk.y] = game.tick
        end
        return
    end

    -- If the chunk has timed out, add it to the removal list
    local c_timer = storage.rg[current_surface].map[next_chunk.x][next_chunk.y]
    local interval_ticks = storage.ocfg.regrowth.cleanup_interval * TICKS_PER_MINUTE
    if ((c_timer ~= nil) and (c_timer >= 0) and ((c_timer + interval_ticks) < game.tick)) then
        -- Check chunk actually exists
        if (game.surfaces[current_surface].is_chunk_generated({ x = next_chunk.x, y = next_chunk.y })) then

            ---@type RemovalListEntry
            local removal_entry = {pos = {x = next_chunk.x, y = next_chunk.y }, force = false, surface = current_surface}
            table.insert(storage.rg.removal_list, removal_entry)
            storage.rg[current_surface].map[next_chunk.x][next_chunk.y] = REGROWTH_FLAG_REMOVAL
        else
            log("WARN - RegrowthSingleStepArray: Chunk not generated?: " .. next_chunk.x .. "," .. next_chunk.y .. " on surface: " .. current_surface)
            storage.rg[current_surface].map[next_chunk.x][next_chunk.y] = nil
        end
    end
end

---Remove all chunks at same time to reduce impact to FPS/UPS
---@return nil
function OarcRegrowthRemoveAllChunks()
    for key, c_remove in pairs(storage.rg.removal_list) do
        local c_pos = c_remove.pos
        local surface_name = c_remove.surface

        -- Confirm chunk is still marked for removal or is a force removal, if it's nil, something else happened?
        if (storage.rg[surface_name].map[c_pos.x] ~= nil) then

            -- If it is FORCE removal, then remove it regardless of pollution.
            if (c_remove.force) then
                game.surfaces[surface_name].delete_chunk(c_pos)
                storage.rg[surface_name].map[c_pos.x][c_pos.y] = nil

            elseif (storage.rg[surface_name].map[c_pos.x][c_pos.y] == REGROWTH_FLAG_REMOVAL) then

                -- If regrowth is disabled, remove the chunnk from the map without deleting it.
                if (not storage.ocfg.regrowth.enable_regrowth or  not storage.rg[surface_name].active) then
                    storage.rg[surface_name].map[c_pos.x][c_pos.y] = nil

                -- If it is a normal timeout removal, don't do it if there is pollution in the chunk.
                elseif (game.surfaces[surface_name].get_pollution({ c_pos.x * 32, c_pos.y * 32 }) > 0) then
                    storage.rg[surface_name].map[c_pos.x][c_pos.y] = game.tick

                -- Else delete the chunk
                else
                    game.surfaces[surface_name].delete_chunk(c_pos)
                    storage.rg[surface_name].map[c_pos.x][c_pos.y] = nil
                end
            end

            -- If we hit here, the chunk was probably refreshed or something and so we don't want to delete it.
            -- We won't check it again since we clear the removal list after this. This should be correct.
        else
            -- This should never happen, TODO: check if it does?
            log("WARN - OarcRegrowthRemoveAllChunks: Chunk not in map: " .. c_pos.x .. "," .. c_pos.y .. " on surface: " .. surface_name)
        end

        -- Remove entry
        storage.rg.removal_list[key] = nil
    end

    -- MUST GET A NEW CHUNK ITERATOR ON DELETE CHUNK!
    storage.rg.chunk_iter = nil
    storage.rg.we_chunk_iter = nil
end

---This is the main work function, it checks a single chunk in the list per tick. It works according to the rules
---listed in the header of this file.
---@return nil
function RegrowthOnTick()

    if (#storage.rg.active_surfaces > 0) then

        -- Every half a second, refresh all chunks near a single player
        -- Cyles through all players. Tick is offset by 2
        if ((game.tick % (30)) == 2) then
            RefreshPlayerArea()
        end

        -- Refresh a single spidertron every tick
        RefreshSpidertronArea()

        -- Every tick, check a few points in the 2d array of the only active surface
        for i = 1, 20 do
            RegrowthSingleStepArray()
        end

        if (storage.ocfg.regrowth.enable_world_eater) then
            WorldEaterSingleStep()
        end
    end

    -- Allow enable/disable of auto cleanup, can change during runtime.
    local interval_ticks = storage.ocfg.regrowth.cleanup_interval * TICKS_PER_MINUTE
    -- Send a broadcast warning before it happens.
    if ((game.tick % interval_ticks) == interval_ticks - (60 * 30 + 1)) then
        if (#storage.rg.removal_list > 100) then
            SendBroadcastMsg("Map cleanup in 30 seconds... Unused and old map chunks will be deleted!")
        end
    end

    -- Delete all listed chunks across all active surfaces
    if ((game.tick % interval_ticks) == interval_ticks - 1) then
        if (#storage.rg.removal_list > 100) then
            OarcRegrowthRemoveAllChunks()
            SendBroadcastMsg("Map cleanup done, sorry for your loss.")
        end
    end
end

-- This function removes any chunks flagged but on demand.
-- Controlled by the storage.rg.force_removal_flag
function RegrowthForceRemovalOnTick()
    -- Catch force remove flag
    if (game.tick == storage.rg.force_removal_flag + 60) then
        SendBroadcastMsg("Map cleanup (forced) in 30 seconds... Unused and old map chunks will be deleted!")
    end

    if (game.tick == storage.rg.force_removal_flag + (60 * 30 + 60)) then
        OarcRegrowthRemoveAllChunks()
        SendBroadcastMsg("Map cleanup done, sorry for your loss.")
    end
end

function WorldEaterSingleStep()

    local next_chunk = GetNextChunkAndUpdateWorldEaterIter()
    if (not next_chunk) then return end    
    local current_surface = storage.rg.we_current_surface

    -- Do we have it in our map?
    if (not storage.rg[current_surface].map[next_chunk.x] or not storage.rg[current_surface].map[next_chunk.x][next_chunk.y]) then
        return -- Chunk isn't in our map so we don't care?
    end

    -- Search for any abandoned radars and destroy them?
    local abandoned_radars = game.surfaces[current_surface].find_entities_filtered { area = next_chunk.area,
        force = { ABANDONED_FORCE_NAME },
        name = "radar" }
    for k, v in pairs(abandoned_radars) do
        v.die(nil)
    end

    -- Search for any entities with _DESTROYED_ force and kill them.
    -- local destroy_entities = game.surfaces[current_surface].find_entities_filtered { area = next_chunk.area,
    --     force = { DESTROYED_FORCE_NAME } }
    -- for k, v in pairs(destroy_entities) do
    --     v.die(nil)
    -- end

    local c_timer = storage.rg[current_surface].map[next_chunk.x][next_chunk.y]

    -- Only check chunnks that are flagged as "active".
    -- Others are either permanent or will be handled by the default regrowth checks.
    if (c_timer == REGROWTH_FLAG_ACTIVE) then
        local area = {
            left_top = { next_chunk.area.left_top.x - 8, next_chunk.area.left_top.y - 8 },
            right_bottom = { next_chunk.area.right_bottom.x + 8, next_chunk.area.right_bottom.y + 8 }
        }

        local entities = game.surfaces[current_surface].find_entities_filtered { area = area, force = ENEMY_FORCES_NAMES_INCL_NEUTRAL, invert = true }
        for _, v in pairs(entities) do
            if (v.last_user) then
                return -- This means we're done checking this chunk. It has an active player entity.
            end
        end

        local moving_entities = game.surfaces[current_surface].find_entities_filtered {
            area = area,
            type = { "character", "logistics-robot", "construction-robot", "car", "spider-vehicle" },
        }
        if (#moving_entities > 0) then
            return -- It's possible there are some moving entities with no last user set.
        end

        -- Destroy the entities that lack an owner! (player was removed)
        for _, v in pairs(entities) do
            if (v and v.valid) then
                v.die(nil)
            end
        end
        -- SendBroadcastMsg(next_chunk.x .. "," .. next_chunk.y .. " WorldEaterSingleStep")
        storage.rg[current_surface].map[next_chunk.x][next_chunk.y] = game.tick -- Set the timer on it.

    end
end


---Checks if a chunk has any player entities in or near it.
---@param surface_name string - The surface name to act on
---@param chunk ChunkPositionAndArea - The chunk position to check
---@return boolean
function CheckIfChunkHasAnyPlayerEntities(surface_name, chunk)

    -- Check around the chunk for anything overlapping to be safe!
    local area = {
        left_top = { chunk.area.left_top.x - 8, chunk.area.left_top.y - 8 },
        right_bottom = { chunk.area.right_bottom.x + 8, chunk.area.right_bottom.y + 8 }
    }

    local entities = game.surfaces[surface_name].find_entities_filtered { area = area, force = ENEMY_FORCES_NAMES_INCL_NEUTRAL, invert = true }
    for _, v in pairs(entities) do
        if (v.last_user) then
            return true -- YES there is player stuff here.
        end
    end

    local moving_entities = game.surfaces[surface_name].find_entities_filtered {
        area = area,
        type = { "character", "logistics-robot", "construction-robot", "car", "spider-vehicle" },
    }
    if (#moving_entities > 0) then
        return true -- Any of these entities are player controlled and count!
    end

    return false
end


---When an entity is built, if it is a spidertron we add it to our list
---@param event EventData.on_built_entity
---@return nil
function RegrowthOnBuiltEntity(event)
    if (event.created_entity and event.created_entity.valid and event.created_entity.type == "spider-vehicle") then
        
        table.insert(storage.rg.spidertrons, event.created_entity)
        log("Added spidertron to regrowth tracking")

        if storage.rg.spidertron_chunk_radius == nil then
            storage.rg.spidertron_chunk_radius = game.entity_prototypes["spidertron"].chunk_exploration_radius
        end
    end
end


---On tick, we refresh a single spidertron's area.
---@return nil
function RefreshSpidertronArea()
    if (#storage.rg.spidertrons > 0) then

        local spidertron = storage.rg.spidertrons[storage.rg_spidertron_index]

        if (spidertron and spidertron.valid) then

            --Check if this surface is active.
            local surface_name = spidertron.surface.name
            if (storage.rg[surface_name] ~= nil) and (storage.rg[surface_name].active) then
                RefreshArea(spidertron.surface.name, spidertron.position, storage.rg.spidertron_chunk_radius, 0)
            end

            UpdateSpidertronIndex() -- Go to next valid spidertron on the next tick
        else
            table.remove(storage.rg.spidertrons, storage.rg_spidertron_index)
            log("Removed spidertron from regrowth tracking")
        end
    end
end

---Updates the spidertron index to the next one in the list.
---@return nil
function UpdateSpidertronIndex()
    storage.rg_spidertron_index = storage.rg_spidertron_index + 1
    if (storage.rg_spidertron_index > #storage.rg.spidertrons) then
        storage.rg_spidertron_index = 1
    end
end