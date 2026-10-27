-- Fixed grid of starting points on every planet surface.
-- The engine generates a vanilla starting area at each point (MapGenSettings.starting_points), and each new spawn
-- claims the next free point, spiralling out from the center of the map.

-- Side length, in chunks, of the square area around a point that must be ungenerated for the point to be claimed.
STARTING_POINT_EXPLORED_AREA_CHUNKS = 10

-- Radius, in chunks, deleted around a point when its spawn is cleaned up. This covers 11x11 chunks, which contains the
-- whole explored area above, so the point passes the explored check again once the chunks are gone.
STARTING_POINT_CLEANUP_CHUNK_RADIUS = 5

-- Limits for the starting point config, matching the mod settings. Scenario overrides are clamped to these.
STARTING_POINTS_COUNT_MIN = 1
STARTING_POINTS_COUNT_MAX = 128
STARTING_POINTS_SPACING_CHUNKS_MIN = 20
STARTING_POINTS_SPACING_CHUNKS_MAX = 1000

---Creates every planet surface that doesn't exist yet and applies the starting point grid to all of them.
---Must be called in on_init, after the config is loaded.
---@return nil
function InitStartingPoints()

    -- Ordered list of starting points for each surface. The list order is the order they are handed out in.
    ---@type table<string, OarcStartingPoint[]>
    storage.starting_points = {}

    -- Warnings about existing starting points that were replaced, shown to each admin once.
    ---@type LocalisedString[]
    storage.starting_points_warnings = {}
    ---@type table<string, boolean>
    storage.starting_points_warned_admins = {}

    for _, planet in pairs(game.planets) do
        local surface = planet.surface
        if (surface == nil) then
            log("InitStartingPoints - Creating surface for planet: " .. planet.name)
            surface = planet.create_surface()
        end

        if (not IsSurfaceBlacklisted(surface.name)) then
            ApplyStartingPoints(surface, true)
        end
    end
end

---Fallback for planet surfaces created after game start (for example a planet added by a mod later on).
---@param surface LuaSurface
---@return nil
function StartingPointsSurfaceCreated(surface)
    if (storage.starting_points == nil) then return end -- Not initialized yet, InitStartingPoints will handle it.
    if (surface.planet == nil) then return end
    if (storage.starting_points[surface.name] ~= nil) then return end
    ApplyStartingPoints(surface, false)
end

---Gets the starting point count and spacing for a surface. Per surface config overrides the global settings.
---@param surface_name string
---@return integer count
---@return integer spacing_chunks
function GetStartingPointsConfig(surface_name)
    local count = storage.ocfg.gameplay.starting_points_count or OCFG.gameplay.starting_points_count
    local spacing_chunks = storage.ocfg.gameplay.starting_points_spacing_chunks or OCFG.gameplay.starting_points_spacing_chunks

    local surface_config = storage.ocfg.surfaces_config[surface_name]
    if (surface_config ~= nil) and (surface_config.starting_points ~= nil) then
        count = surface_config.starting_points.count or count
        spacing_chunks = surface_config.starting_points.spacing_chunks or spacing_chunks
    end

    local clamped_count = math.min(math.max(count, STARTING_POINTS_COUNT_MIN), STARTING_POINTS_COUNT_MAX)
    local clamped_spacing = math.min(math.max(spacing_chunks, STARTING_POINTS_SPACING_CHUNKS_MIN), STARTING_POINTS_SPACING_CHUNKS_MAX)
    if (clamped_count ~= count) or (clamped_spacing ~= spacing_chunks) then
        log("WARNING - GetStartingPointsConfig - Starting point config out of range for " .. surface_name ..
            ", using count = " .. clamped_count .. " and spacing_chunks = " .. clamped_spacing)
    end

    return clamped_count, clamped_spacing
end

---Builds the starting point grid. Integer grid indices (i, j) map to tile position (i, j) * spacing_chunks * 32,
---centred on the origin. Returns the count indices closest to the origin, sorted by distance and then by angle,
---so the list order is the spiral order. The origin itself is left out, because the engine always generates the
---chunks around it on nauvis before a player can claim it.
---@param count integer
---@param spacing_chunks integer
---@return MapPosition[]
function BuildStartingPointGrid(count, spacing_chunks)
    local spacing_tiles = spacing_chunks * CHUNK_SIZE

    -- The circle of this radius holds more than count indices, so the closest count are all inside the square.
    local radius = math.ceil(math.sqrt(count)) + 1

    local indices = {}
    for i = -radius, radius do
        for j = -radius, radius do
            if (i ~= 0) or (j ~= 0) then
                local angle = math.atan2(j, i)
                if (angle < 0) then
                    angle = angle + 2 * math.pi
                end
                table.insert(indices, { i = i, j = j, dist_sqr = i * i + j * j, angle = angle })
            end
        end
    end

    table.sort(indices, function(a, b)
        if (a.dist_sqr ~= b.dist_sqr) then
            return a.dist_sqr < b.dist_sqr
        end
        return a.angle < b.angle
    end)

    local grid = {}
    for n = 1, count do
        table.insert(grid, { x = indices[n].i * spacing_tiles, y = indices[n].j * spacing_tiles })
    end
    return grid
end

---Writes the starting point grid to the surface's map gen settings and sets up the starting point list.
---@param surface LuaSurface
---@param allow_clear boolean Clear the surface if it is already generated, so it regenerates with the new settings.
---@return nil
function ApplyStartingPoints(surface, allow_clear)
    local count, spacing_chunks = GetStartingPointsConfig(surface.name)
    local grid = BuildStartingPointGrid(count, spacing_chunks)

    -- Check this BEFORE writing the settings, it tells us if a clear is needed. In practice only nauvis is generated.
    local already_generated = surface.is_chunk_generated({ 0, 0 })

    local mgs = surface.map_gen_settings -- Must modify a copy and write the whole table back
    WarnIfStartingPointsModified(surface.name, mgs.starting_points)
    mgs.starting_points = grid
    surface.map_gen_settings = mgs

    -- Writing the starting points moves every force's spawn position to the first point. Freeplay charts the area
    -- around the player force's spawn position when the first player joins, which would explore that point before
    -- anyone claims it. Keep them at the origin. Forces created later are handled in StartingPointsForceCreated.
    for _, force in pairs(game.forces) do
        force.set_spawn_position({ x = 0, y = 0 }, surface)
    end

    storage.starting_points[surface.name] = {}
    for _, position in ipairs(grid) do
        table.insert(storage.starting_points[surface.name], { position = position, host_name = nil, unusable = false })
    end

    log("ApplyStartingPoints - " .. surface.name .. ": " .. count .. " starting points, " .. spacing_chunks ..
        " chunks apart. Origin chunk already generated = " .. tostring(already_generated))

    if already_generated then
        if allow_clear then
            log("ApplyStartingPoints - Clearing surface so it regenerates with the starting points: " .. surface.name)
            surface.clear(true)
        else
            -- The explored check skips any point whose area was already generated without its starting area.
            log("WARNING - ApplyStartingPoints - Surface was already generated and is not cleared: " .. surface.name)
        end
    end
end

---The engine default is a single starting point at (0,0). Anything else came from the map gen settings, a preset or
---another mod, and is about to be replaced. Log it and keep a warning for admins.
---@param surface_name string
---@param existing_points MapPosition[]?
---@return nil
function WarnIfStartingPointsModified(surface_name, existing_points)
    if (existing_points == nil) then return end

    local point_strings = {}
    local is_default = (#existing_points == 1)
    for _, point in ipairs(existing_points) do
        local x = point.x or point[1]
        local y = point.y or point[2]
        if (x ~= 0) or (y ~= 0) then
            is_default = false
        end
        table.insert(point_strings, "(" .. x .. "," .. y .. ")")
    end
    if is_default then return end

    local points_text = table.concat(point_strings, " ")
    log("ERROR - Existing starting points on surface " .. surface_name .. " are being replaced: " .. points_text ..
        " They came from the map gen settings, a preset or another mod. Oarc Classic overwrites them with its own grid.")

    local warning = { "oarc-starting-points-replaced-warning", surface_name, points_text }
    table.insert(storage.starting_points_warnings, warning)

    for _, player in pairs(game.connected_players) do
        ShowStartingPointWarnings(player)
    end
end

---Prints any starting point warnings to an admin, once per admin.
---@param player LuaPlayer
---@return nil
function ShowStartingPointWarnings(player)
    if (storage.starting_points_warnings == nil) or (#storage.starting_points_warnings == 0) then return end
    if (not player.admin) or storage.starting_points_warned_admins[player.name] then return end

    for _, warning in ipairs(storage.starting_points_warnings) do
        SendErrorMsg(player, warning)
    end
    storage.starting_points_warned_admins[player.name] = true
end

---Checks if any chunk in the area around a starting point is already generated, meaning someone else has
---explored there.
---@param surface LuaSurface
---@param position MapPosition
---@return boolean
function IsStartingPointExplored(surface, position)
    local center_chunk = GetChunkPosFromTilePos(position)
    local half = STARTING_POINT_EXPLORED_AREA_CHUNKS / 2

    -- Grid points sit on a chunk corner, so this range is centred on the point.
    for x = center_chunk.x - half, center_chunk.x + half - 1 do
        for y = center_chunk.y - half, center_chunk.y + half - 1 do
            if surface.is_chunk_generated({ x = x, y = y }) then
                return true
            end
        end
    end
    return false
end

---New forces start with their spawn position on the first starting point of every surface. A cargo pod dropping to a
---planet where the force has no spawn yet lands at that position, and the game generates chunks around it, which
---explores the point before anyone claims it. Move it to the origin, like ApplyStartingPoints does for older forces.
---@param force LuaForce
---@return nil
function StartingPointsForceCreated(force)
    if (storage.starting_points == nil) then return end -- Forces created in on_init before InitStartingPoints.
    for surface_name, _ in pairs(storage.starting_points) do
        local surface = game.surfaces[surface_name]
        if (surface ~= nil) then
            force.set_spawn_position({ x = 0, y = 0 }, surface)
        end
    end
end

---Claims the next free starting point on a surface for a host. Points that were explored by someone else are
---marked unusable and skipped. They are checked again on later claims, in case their chunks get deleted.
---@param surface_name string
---@param host_name string
---@return MapPosition? position nil if there are no free starting points.
function ClaimNextStartingPoint(surface_name, host_name)

    local surface = game.surfaces[surface_name]
    if (surface == nil) and (game.planets[surface_name] ~= nil) then
        surface = game.planets[surface_name].create_surface()
    end
    if (surface == nil) then
        log("ERROR - ClaimNextStartingPoint - No surface or planet named: " .. surface_name)
        return nil
    end

    if (storage.starting_points[surface_name] == nil) then
        if (surface.planet == nil) then
            log("ERROR - ClaimNextStartingPoint - No starting points on non planet surface: " .. surface_name)
            return nil
        end
        ApplyStartingPoints(surface, false)
    end

    for index, point in ipairs(storage.starting_points[surface_name]) do
        if (point.host_name == nil) then
            if IsStartingPointExplored(surface, point.position) then
                if (not point.unusable) then
                    point.unusable = true
                    log("ClaimNextStartingPoint - Starting point " .. index .. " at (" .. point.position.x .. "," ..
                        point.position.y .. ") on " .. surface_name .. " was already explored, marking it unusable.")
                end
            else
                point.unusable = false
                point.host_name = host_name
                log("ClaimNextStartingPoint - " .. host_name .. " claimed starting point " .. index .. " at (" ..
                    point.position.x .. "," .. point.position.y .. ") on " .. surface_name)
                return point.position
            end
        end
    end

    log("ClaimNextStartingPoint - No free starting points left on " .. surface_name)
    return nil
end

---Puts a starting point back in the pool. Cleanup deletes its chunks, so the explored check passes again and the area
---regenerates as a fresh starting area. If the chunks are not deleted, the explored check skips the point.
---@param surface_name string
---@param position MapPosition The position of the spawn on the starting point.
---@return nil
function ReleaseStartingPoint(surface_name, position)
    local points = storage.starting_points[surface_name]
    if (points == nil) then return end

    for index, point in ipairs(points) do
        if (point.position.x == position.x) and (point.position.y == position.y) then
            log("ReleaseStartingPoint - Released starting point " .. index .. " on " .. surface_name ..
                " (was claimed by " .. tostring(point.host_name) .. ")")
            ResetForceSpawnPositionOffPoint(point.host_name, surface_name, position)
            point.host_name = nil
            return
        end
    end
end

---Cargo pods without a landing pad land at the force's spawn position. If the host's force still points at a released
---point, pods would land there, generate chunks on the point and be deleted by its cleanup. Move it back to the origin
---until the force's next spawn on the surface is generated (GenerateFinalSpawnPieces). Only rerolls need this. When a
---player's spawns are cleaned up, RemoveOrResetPlayer has already moved them to the lobby force, so this does nothing.
---@param host_name string?
---@param surface_name string
---@param position MapPosition
---@return nil
function ResetForceSpawnPositionOffPoint(host_name, surface_name, position)
    if (host_name == nil) then return end
    local player = game.players[host_name]
    local surface = game.surfaces[surface_name]
    if (player == nil) or (surface == nil) then return end

    local force = player.force --[[@as LuaForce]]
    local spawn_position = force.get_spawn_position(surface)
    if (spawn_position.x == position.x) and (spawn_position.y == position.y) then
        force.set_spawn_position({ x = 0, y = 0 }, surface)
        log("ResetForceSpawnPositionOffPoint - Moved the spawn position of force " .. force.name .. " on " ..
            surface_name .. " back to the origin")
    end
end

---Moves every starting point claim from one host to another, when a spawn changes owner.
---@param old_host_name string
---@param new_host_name string
---@return nil
function TransferStartingPointClaims(old_host_name, new_host_name)
    for _, points in pairs(storage.starting_points) do
        for _, point in ipairs(points) do
            if (point.host_name == old_host_name) then
                point.host_name = new_host_name
            end
        end
    end
end

---Counts the claimed starting points on a surface.
---@param surface_name string
---@return integer claimed
---@return integer total
function GetStartingPointCounts(surface_name)
    local points = storage.starting_points[surface_name] or {}
    local claimed = 0
    for _, point in ipairs(points) do
        if (point.host_name ~= nil) then
            claimed = claimed + 1
        end
    end
    return claimed, #points
end

---@class OarcStartingPoint
---@field position MapPosition The tile position of the starting point.
---@field host_name string? The host of the spawn on this point, nil if it is free.
---@field unusable boolean Set when the area around the point was already explored by someone else.
