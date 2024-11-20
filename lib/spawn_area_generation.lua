-- --------------------------------------------------------------------------------
-- -- Resource patch and starting area generation
-- --------------------------------------------------------------------------------

---Circle spawn shape (handles land, trees and moat)
---@param surface LuaSurface
---@param unique_spawn OarcUniqueSpawn
---@param chunk_area BoundingBox
---@return nil
function CreateCropCircle(surface, unique_spawn, chunk_area)

    --- Repeated code... TODO: Extract into a function
    --------------------------------------------
    local spawn_general = storage.ocfg.spawn_general
    local spawn_config = storage.ocfg.surfaces_config[surface.name].spawn_config

    local spawn_pos = unique_spawn.position
    local tile_radius = spawn_general.spawn_radius_tiles * spawn_config.radius_modifier

    local fill_tile = "landfill"
    if spawn_general.force_tiles then
        fill_tile = spawn_config.fill_tile
    end

    local liquid_tile = spawn_config.liquid_tile
    local fish_enabled = (liquid_tile == "water")

    local moat = unique_spawn.moat and liquid_tile ~= "lava"
    local bridge = storage.ocfg.gameplay.enable_moat_bridging

    local moat_width = storage.ocfg.spawn_general.moat_width_tiles
    local tree_width = storage.ocfg.spawn_general.tree_width_tiles
    --------------------------------------------

    local tile_radius_sqr = tile_radius ^ 2
    local moat_radius_sqr = ((tile_radius + moat_width) ^ 2)
    local tree_radius_sqr_inner = ((tile_radius - 1 - tree_width) ^ 2) -- 1 less to make sure trees are inside the spawn area
    local tree_radius_sqr_outer = ((tile_radius - 1) ^ 2)


    local dirtTiles = {}
    for i = chunk_area.left_top.x, chunk_area.right_bottom.x, 1 do
        for j = chunk_area.left_top.y, chunk_area.right_bottom.y, 1 do
            -- This ( X^2 + Y^2 ) is used to calculate if something is inside a circle area.
            -- We avoid using sqrt for performance reasons.
            local distSqr = math.floor((spawn_pos.x - i) ^ 2 + (spawn_pos.y - j) ^ 2)

            -- Fill in all unexpected water (or force grass)
            if (distSqr <= tile_radius_sqr) then
                if (surface.get_tile(i, j).collides_with("water_tile") or
                        storage.ocfg.spawn_general.force_tiles) then
                    table.insert(dirtTiles, { name = fill_tile, position = { i, j } })
                end
            end

            -- Fill moat with water.
            if (moat) then
                if (bridge and ((j == spawn_pos.y - 1) or (j == spawn_pos.y) or (j == spawn_pos.y + 1))) then
                    -- This will leave the tiles "as is" on the left and right of the spawn which has the effect of creating
                    -- land connections if the spawn is on or near land.
                elseif ((distSqr < moat_radius_sqr) and (distSqr > tile_radius_sqr)) then
                    table.insert(dirtTiles, { name = liquid_tile, position = { i, j } })

                    --5% chance of fish in water
                    if fish_enabled and (math.random(1, 20) == 1) then
                        surface.create_entity({ name = "fish", position = { i + 0.5, j + 0.5 } })
                    end
                end
            end
        end
    end

    surface.set_tiles(dirtTiles)

    --Create trees (needs to be done after setting tiles!)
    local tree_entity = spawn_config.tree_entity
    if (tree_entity == nil) then return end

    for i = chunk_area.left_top.x, chunk_area.right_bottom.x, 1 do
        for j = chunk_area.left_top.y, chunk_area.right_bottom.y, 1 do
            local distSqr = math.floor((spawn_pos.x - i) ^ 2 + (spawn_pos.y - j) ^ 2)
            if ((distSqr < tree_radius_sqr_outer) and (distSqr > tree_radius_sqr_inner)) then
                local pos = surface.find_non_colliding_position(tree_entity, { i, j }, 2, 0.5)
                if (pos ~= nil) then
                    surface.create_entity({ name = tree_entity, position = pos })
                end
            end
        end
    end
end

---Octagon spawn shape (handles land, trees and moat) (Curtesy of jvmguy)
---@param surface LuaSurface
---@param unique_spawn OarcUniqueSpawn
---@param chunk_area BoundingBox
---@return nil
function CreateCropOctagon(surface, unique_spawn, chunk_area)
    --------------------------------------------
    local spawn_general = storage.ocfg.spawn_general
    local spawn_config = storage.ocfg.surfaces_config[surface.name].spawn_config

    local spawn_pos = unique_spawn.position
    local tile_radius = spawn_general.spawn_radius_tiles * spawn_config.radius_modifier

    local fill_tile = "landfill"
    if spawn_general.force_tiles then
        fill_tile = spawn_config.fill_tile
    end

    local liquid_tile = spawn_config.liquid_tile
    local fish_enabled = (liquid_tile == "water")

    local moat = unique_spawn.moat and liquid_tile ~= "lava"
    local bridge = storage.ocfg.gameplay.enable_moat_bridging

    local moat_width = storage.ocfg.spawn_general.moat_width_tiles
    local tree_width = storage.ocfg.spawn_general.tree_width_tiles
    --------------------------------------------

    local moat_width_outer = tile_radius + moat_width
    local tree_distance_inner = tile_radius - tree_width

    local dirtTiles = {}
    for i = chunk_area.left_top.x, chunk_area.right_bottom.x, 1 do
        for j = chunk_area.left_top.y, chunk_area.right_bottom.y, 1 do
            local distVar1 = math.floor(math.max(math.abs(spawn_pos.x - i), math.abs(spawn_pos.y - j)))
            local distVar2 = math.floor(math.abs(spawn_pos.x - i) + math.abs(spawn_pos.y - j))
            local distVar = math.max(distVar1, distVar2 * 0.707);

            -- Fill in all unexpected water (or force grass)
            if (distVar <= tile_radius) then
                if (surface.get_tile(i, j).collides_with("water_tile") or
                        storage.ocfg.spawn_general.force_tiles) then
                    table.insert(dirtTiles, { name = fill_tile, position = { i, j } })
                end
            end

            -- Fill moat with water
            if (moat) then
                if (bridge and ((j == spawn_pos.y - 1) or (j == spawn_pos.y) or (j == spawn_pos.y + 1))) then
                    -- This will leave the tiles "as is" on the left and right of the spawn which has the effect of creating
                    -- land connections if the spawn is on or near land.
                elseif ((distVar > tile_radius) and (distVar <= moat_width_outer)) then
                    table.insert(dirtTiles, { name = liquid_tile, position = { i, j } })

                    --5% chance of fish in water
                    if fish_enabled and (math.random(1, 20) == 1) then
                        surface.create_entity({ name = "fish", position = { i + 0.5, j + 0.5 } })
                    end
                end
            end
        end
    end
    surface.set_tiles(dirtTiles)


    --Create trees (needs to be done after setting tiles!)
    local tree_entity = spawn_config.tree_entity
    if (tree_entity == nil) then return end

    --Create trees (needs to be done after setting tiles!)
    for i = chunk_area.left_top.x, chunk_area.right_bottom.x, 1 do
        for j = chunk_area.left_top.y, chunk_area.right_bottom.y, 1 do
            local distVar1 = math.floor(math.max(math.abs(spawn_pos.x - i), math.abs(spawn_pos.y - j)))
            local distVar2 = math.floor(math.abs(spawn_pos.x - i) + math.abs(spawn_pos.y - j))
            local distVar = math.max(distVar1, distVar2 * 0.707);

            if ((distVar < tile_radius) and (distVar >= tree_distance_inner)) then
                local pos = surface.find_non_colliding_position(tree_entity, { i, j }, 2, 0.5)
                if (pos ~= nil) then
                    surface.create_entity({ name = tree_entity, position = pos })
                end
            end
        end
    end
end

---Square spawn shape (handles land, trees and moat)
---@param surface LuaSurface
---@param unique_spawn OarcUniqueSpawn
---@param chunk_area BoundingBox
---@return nil
function CreateCropSquare(surface, unique_spawn, chunk_area)
    --------------------------------------------
    local spawn_general = storage.ocfg.spawn_general
    local spawn_config = storage.ocfg.surfaces_config[surface.name].spawn_config

    local spawn_pos = unique_spawn.position
    local tile_radius = spawn_general.spawn_radius_tiles * spawn_config.radius_modifier

    local fill_tile = "landfill"
    if spawn_general.force_tiles then
        fill_tile = spawn_config.fill_tile
    end

    local liquid_tile = spawn_config.liquid_tile
    local fish_enabled = (liquid_tile == "water")

    local moat = unique_spawn.moat and liquid_tile ~= "lava"
    local bridge = storage.ocfg.gameplay.enable_moat_bridging

    local moat_width = storage.ocfg.spawn_general.moat_width_tiles
    local tree_width = storage.ocfg.spawn_general.tree_width_tiles
    --------------------------------------------

    local moat_width_outer = tile_radius + moat_width
    local tree_distance_inner = tile_radius - tree_width

    local dirtTiles = {}
    for i = chunk_area.left_top.x, chunk_area.right_bottom.x, 1 do
        for j = chunk_area.left_top.y, chunk_area.right_bottom.y, 1 do
            -- Max distance from center (either x or y)
            local max_distance = math.max(math.abs(spawn_pos.x - i), math.abs(spawn_pos.y - j))

            -- Fill in all unexpected water (or force grass)
            if (max_distance <= tile_radius) then
                if (surface.get_tile(i, j).collides_with("water_tile") or
                        storage.ocfg.spawn_general.force_tiles) then
                    table.insert(dirtTiles, { name = fill_tile, position = { i, j } })
                end
            end

            -- Fill moat with water
            if (moat) then
                if (bridge and ((j == spawn_pos.y - 1) or (j == spawn_pos.y) or (j == spawn_pos.y + 1))) then
                    -- This will leave the tiles "as is" on the left and right of the spawn which has the effect of creating
                    -- land connections if the spawn is on or near land.
                elseif ((max_distance > tile_radius) and (max_distance <= moat_width_outer)) then
                    table.insert(dirtTiles, { name = liquid_tile, position = { i, j } })

                    --5% chance of fish in water
                    if fish_enabled and (math.random(1, 20) == 1) then
                        surface.create_entity({ name = "fish", position = { i + 0.5, j + 0.5 } })
                    end
                end
            end
        end
    end

    surface.set_tiles(dirtTiles)

    --Create trees (needs to be done after setting tiles!)
    local tree_entity = spawn_config.tree_entity
    if (tree_entity == nil) then return end

    --Create trees (needs to be done after setting tiles!)
    for i = chunk_area.left_top.x, chunk_area.right_bottom.x, 1 do
        for j = chunk_area.left_top.y, chunk_area.right_bottom.y, 1 do
            local max_distance = math.max(math.abs(spawn_pos.x - i), math.abs(spawn_pos.y - j))
            if ((max_distance < tile_radius) and (max_distance >= tree_distance_inner)) then
                local pos = surface.find_non_colliding_position(tree_entity, { i, j }, 2, 0.5)
                if (pos ~= nil) then
                    surface.create_entity({ name = tree_entity, position = pos })
                end
            end
        end
    end
end

-- Create a horizontal line of tiles (typically used for water)
---@param surface LuaSurface
---@param leftPos TilePosition
---@param length integer
---@param tile_name string
---@return nil
function CreateTileStrip(surface, leftPos, length, tile_name)
    local waterTiles = {}
    for i = 0, length - 1, 1 do
        table.insert(waterTiles, { name = tile_name, position = { leftPos.x + i, leftPos.y } })
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
    local square_shape = (storage.ocfg.spawn_general.resources_shape == RESOURCES_SHAPE_CHOICE_SQUARE)

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

--- Function to generate a resource patch, of a certain size/amount at a pos.
---@param surface LuaSurface
---@param position MapPosition
---@return nil
function PlaceRandomEntities(surface, position)
    local spawn_config = storage.ocfg.surfaces_config[surface.name].spawn_config
    local random_entities = spawn_config.random_entities
    if (random_entities == nil) then return end

    local tree_width = storage.ocfg.spawn_general.tree_width_tiles
    local radius = storage.ocfg.spawn_general.spawn_radius_tiles * spawn_config.radius_modifier - tree_width

    --Iterate through the random entities and place them
    for _, entry in pairs(random_entities) do
        local entity_name = entry.name

        for i = 1, entry.count do
            local random_pos = GetRandomPointWithinCircle(radius, position)
            local open_pos = surface.find_non_colliding_position(entity_name, random_pos, tree_width, 0.5)

            if (open_pos ~= nil) then
                surface.create_entity({
                    name = entity_name,
                    position = open_pos
                })
            end
        end
    end
end

--- Randomly place lightning attractors specific for Fulgora. This should space them out so they don't overlap too much.
---@param surface LuaSurface
---@param position MapPosition
---@return nil
function PlaceFulgoranLightningAttractors(surface, position, count)
    local spawn_config = storage.ocfg.surfaces_config[surface.name].spawn_config
    local radius = storage.ocfg.spawn_general.spawn_radius_tiles * spawn_config.radius_modifier

    -- HARDCODED FOR NOW
    local ATTRACTOR_NAME = "fulgoran-ruin-attractor"
    local ATTRACTOR_RADIUS = 20

    --Iterate through and place them and use the largest available entity
    for i = 1, count do
        local random_pos = GetRandomPointWithinCircle(radius, position)
        local open_pos = surface.find_non_colliding_position("crash-site-spaceship", random_pos, 1, 0.5)

        if (open_pos ~= nil) then
            surface.create_entity({
                name = ATTRACTOR_NAME,
                position = open_pos,
                force = "player" -- Same as native game
            })
        end
    end
end
