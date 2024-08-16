-- holding_pen.lua
-- Aug 2024

-- This file is used to create the holding pen area where players spawn in before being teleported to their own area.

HOLDING_PEN_SURFACE_NAME = "oarc_holding_pen"

function CreateHoldingPenSurface()

    ---@type MapGenSettings
    ---@diagnostic disable-next-line: missing-fields
    local map_settings = {}
    map_settings.terrain_segmentation = "none"
    map_settings.water = "none"
    map_settings.starting_area = "none"
    map_settings.peaceful_mode = true
    -- map_settings.autoplace_controls = {}
    -- map_settings.autoplace_controls["coal"].size = 0
    -- map_settings.autoplace_controls["copper-ore"].size = 0
    -- map_settings.autoplace_controls["crude-oil"].size = 0
    -- map_settings.autoplace_controls["iron-ore"].size = 0
    -- map_settings.autoplace_controls["stone"].size = 0
    -- map_settings.autoplace_controls["uranium-ore"].size = 0
    -- map_settings.autoplace_controls["enemy-base"].size = 0
    -- map_settings.autoplace_controls["trees"].size = 0
    map_settings.width = 32
    map_settings.height = 32

    -- Create a new surface for the holding pen
    if game.surfaces[HOLDING_PEN_SURFACE_NAME] == nil then
        local holding_pen_surface = game.create_surface(HOLDING_PEN_SURFACE_NAME, map_settings)
        holding_pen_surface.always_day = true
        holding_pen_surface.show_clouds = false
        holding_pen_surface.generate_with_lab_tiles = true

        RenderPermanentGroundText(holding_pen_surface, {x=-15,y=-24}, 20, "OARC", {0.9, 0.7, 0.3, 0.8})

        -- This doesn't work if loading map data. TODO: Revert this later?
        -- Disabling this let's me launch the scenario directly from the editor while using an empty blueprint.zip as 
        -- a workaround since there's a bug with the "--load-scenario" launch argument.
        -- https://forums.factorio.com/110708
        -- holding_pen_surface.request_to_generate_chunks({0,0}, 2)
        -- holding_pen_surface.force_generate_chunk_requests()
    else
        log("Holding pen surface already exists!?")
    end
end

---Creates a holding pen area
---@param surface LuaSurface
---@param chunkArea BoundingBox
function CreateHoldingPenChunks(surface, chunkArea)

    if (surface.name ~= HOLDING_PEN_SURFACE_NAME) then
        return
    end

    -- Remove ALL entities in the chunk
    for key, entity in pairs(surface.find_entities(chunkArea)) do
        if entity.type ~= "character" then
            entity.destroy()
        end
    end

    -- Makes a small circle of grass hopefully?
    local tiles = {}
    for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
        for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do
            local distance = math.floor(i^2 + j^2)
            if (distance < 10^2) then
                table.insert(tiles, {name="tutorial-grid", position={i, j}})
            else
                table.insert(tiles, {name="out-of-map", position={i, j}})
            end
        end
    end
    surface.set_tiles(tiles)
end
