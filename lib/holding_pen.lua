-- This file is used to create the holding pen area where players spawn in before being teleported to their own area.

HOLDING_PEN_SURFACE_NAME = "oarc_holding_pen"

function CreateHoldingPenSurface()

    if game.surfaces[HOLDING_PEN_SURFACE_NAME] ~= nil then
        log("ERROR - Holding pen surface already exists!")
        return
    end

    ---@type MapGenSettings
    ---@diagnostic disable-next-line: missing-fields
    local map_settings = {}
    -- map_settings.terrain_segmentation = "none"
    -- map_settings.water = "none"
    map_settings.starting_area = "none"
    map_settings.peaceful_mode = true
    map_settings.width = 64
    map_settings.height = 64

    -- Create a new surface for the holding pen

    local holding_pen_surface = game.create_surface(HOLDING_PEN_SURFACE_NAME, map_settings)
    holding_pen_surface.always_day = true
    holding_pen_surface.show_clouds = false
    holding_pen_surface.generate_with_lab_tiles = true
    holding_pen_surface.localised_name = {"oarc-holding-pen-surface"}

    RenderPermanentGroundText(holding_pen_surface, {x=9,y=-7}, 5, "O", {0.9, 0.7, 0.3, 0.5}, "center")
    RenderPermanentGroundText(holding_pen_surface, {x=9,y=-4}, 5, "A", {0.9, 0.7, 0.3, 0.5}, "center")
    RenderPermanentGroundText(holding_pen_surface, {x=9,y=-1}, 5, "R", {0.9, 0.7, 0.3, 0.5}, "center")
    RenderPermanentGroundText(holding_pen_surface, {x=9,y=2}, 5, "C", {0.9, 0.7, 0.3, 0.5}, "center")
end

---Creates a holding pen area
---@param event EventData.on_chunk_generated
---@return nil
function CreateHoldingPenChunks(event)

    local surface = event.surface
    local chunk_area = event.area
    local chunk_position = event.position


    if (surface.name ~= HOLDING_PEN_SURFACE_NAME) then
        return
    end

    -- Remove ALL entities in the chunk
    for _, entity in pairs(surface.find_entities(chunk_area)) do
        if entity.type ~= "character" then
            entity.destroy()
        end
    end

    -- Place tiles and trees and water for the holding pen
    local tiles = {}
    for x=chunk_area.left_top.x,chunk_area.right_bottom.x,1 do
        for y=chunk_area.left_top.y,chunk_area.right_bottom.y,1 do
            local distance_sqr = math.floor(x^2 + y^2)

            if (distance_sqr < 15^2) then
                table.insert(tiles, {name="grass-1", position={x, y}})
            elseif (distance_sqr < 20^2) then
                table.insert(tiles, {name="water", position={x, y}})

                --10% chance of fish in water
                if (math.random(1,10) == 1) then
                    surface.create_entity({name="fish", position={x + 0.5, y + 0.5}})
                end
                
            else
                table.insert(tiles, {name="out-of-map", position={x, y}})
            end

            if (distance_sqr >= 13^2) and (distance_sqr <= 15^2) then
                surface.create_entity({name="tree-01", position={x + 0.5, y + 0.5}})
            end
        end
    end
    surface.set_tiles(tiles)

    -- If this is the bottom right chunk it's safe to place stuff inside the holding pen now.
    if (chunk_position.x == 2 and chunk_position.y == 2) then

        PlaceResourcesInSemiCircleHoldingPen(surface, {x=0,y=0}, 0.2, 0.1)

        CreateWaterStrip(surface, {x=-2,y=-11}, 4)
        CreateWaterStrip(surface, {x=-2,y=-10}, 4)

        surface.create_entity({
            name = "crude-oil",
            amount = 90000,
            position = { 0, 9 }
        })

        -- Create special power pole if sharing is enabled (it will be created later when first requested otherwise)
        if (storage.ocfg.gameplay.enable_shared_power) then
            InitSharingPowerPoles()
        end
    end
end



---A special version of PlaceResourcesInSemiCircle for the holding pen
---@param surface LuaSurface
---@param position TilePosition --The center of the spawn area
---@param size_mod number
---@param amount_mod number
---@return nil
function PlaceResourcesInSemiCircleHoldingPen(surface, position, size_mod, amount_mod)

    local resources = storage.ocfg.surfaces_config["nauvis"].spawn_config.solid_resources

    -- Create list of resource tiles
    ---@type table<string>
    local r_list = {}
    for r_name, _ in pairs(resources) do
        if (r_name ~= "") then
            table.insert(r_list, r_name)
        end
    end
    ---@type table<string>
    local shuffled_list = FYShuffle(r_list)

    -- This places resources in a semi-circle
    local angle_offset = 2.32
    local num_resources = table_size(resources)
    local theta = ((4.46 - 2.32) / num_resources);
    local count = 0

    -- Unique to the holding pen size
    local radius = 15 - 6

    for _, r_name in pairs(shuffled_list) do
        local angle = (theta * count) + angle_offset;

        local tx = (radius * math.cos(angle)) + position.x
        local ty = (radius * math.sin(angle)) + position.y

        local pos = { x = math.floor(tx), y = math.floor(ty) }

        local resourceConfig = resources[r_name]
        GenerateResourcePatch(surface, r_name, resourceConfig.size * size_mod, pos, resourceConfig.amount * amount_mod)
        count = count + 1
    end
end