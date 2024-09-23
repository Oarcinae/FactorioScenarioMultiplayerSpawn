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
    map_settings.terrain_segmentation = "none"
    map_settings.water = "none"
    map_settings.starting_area = "none"
    map_settings.peaceful_mode = true
    map_settings.width = 64
    map_settings.height = 64

    -- Create a new surface for the holding pen

    local holding_pen_surface = game.create_surface(HOLDING_PEN_SURFACE_NAME, map_settings)
    holding_pen_surface.always_day = true
    holding_pen_surface.show_clouds = false
    holding_pen_surface.generate_with_lab_tiles = true

    RenderPermanentGroundText(holding_pen_surface, {x=-15,y=-24}, 20, "OARC", {0.9, 0.7, 0.3, 0.8})
end

---Creates a holding pen area
---@param surface LuaSurface
---@param chunkArea BoundingBox
function CreateHoldingPenChunks(surface, chunkArea)

    if (surface.name ~= HOLDING_PEN_SURFACE_NAME) then
        return
    end

    -- Remove ALL entities in the chunk
    for _, entity in pairs(surface.find_entities(chunkArea)) do
        if entity.type ~= "character" then
            entity.destroy()
        end
    end

    -- Place some tutorial grid tiles for the spawn area
    local tiles = {}
    for x=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
        for y=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do
            local distance = math.floor(x^2 + y^2)

            if (distance < 10^2) then
                table.insert(tiles, {name="tutorial-grid", position={x, y}})
            else
                table.insert(tiles, {name="out-of-map", position={x, y}})
            end
        end
    end
    surface.set_tiles(tiles)
end
