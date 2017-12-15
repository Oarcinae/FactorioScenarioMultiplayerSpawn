-- frontier_silo.lua
-- Nov 2016

require("config")
require("locale/oarc_utils")

-- Create a rocket silo
local function CreateRocketSilo(surface, chunkArea, force)
    if CheckIfInArea(global.siloPosition, chunkArea) then

        -- Delete any entities beneat the silo?
        for _, entity in pairs(surface.find_entities_filtered{area = {{global.siloPosition.x-5, global.siloPosition.y-6},{global.siloPosition.x+6, global.siloPosition.y+6}}}) do
            entity.destroy()
        end

        -- Set tiles below the silo
        local tiles = {}
        local i = 1
        for dx = -6,6 do
            for dy = -7,6 do
                tiles[i] = {name = "grass-1", position = {global.siloPosition.x+dx, global.siloPosition.y+dy}}
                i=i+1
            end
        end
        surface.set_tiles(tiles, false)
        tiles = {}
        i = 1
        for dx = -5,5 do
            for dy = -6,5 do
                tiles[i] = {name = "concrete", position = {global.siloPosition.x+dx, global.siloPosition.y+dy}}
                i=i+1
            end
        end
        surface.set_tiles(tiles, true)

        -- Create silo and assign to a force
        local silo = surface.create_entity{name = "rocket-silo", position = {global.siloPosition.x+0.5, global.siloPosition.y}, force = force}
        silo.destructible = false
        silo.minable = false

        -- Make silo safe from being removed.
        if ENABLE_REGROWTH then
            OarcRegrowthOffLimits(global.siloPosition, 5)
        end
    end
end

-- Generates the rocket silo during chunk generation event
-- Includes a crop circle
function GenerateRocketSiloChunk(event)
    local surface = event.surface
    local chunkArea = event.area

    local chunkAreaCenter = {x=chunkArea.left_top.x+(CHUNK_SIZE/2),
                             y=chunkArea.left_top.y+(CHUNK_SIZE/2)}
    local safeArea = {left_top=
                        {x=global.siloPosition.x-150,
                         y=global.siloPosition.y-150},
                      right_bottom=
                        {x=global.siloPosition.x+150,
                         y=global.siloPosition.y+150}}
                             

    -- Clear enemies directly next to the rocket
    if CheckIfInArea(chunkAreaCenter,safeArea) then
        for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, force = "enemy"}) do
            entity.destroy()
        end
    end

    -- Remove trees/resources inside the spawn area
    RemoveInCircle(surface, chunkArea, "tree", global.siloPosition, ENFORCE_LAND_AREA_TILE_DIST+5)
    RemoveInCircle(surface, chunkArea, "resource", global.siloPosition, ENFORCE_LAND_AREA_TILE_DIST+5)
    RemoveInCircle(surface, chunkArea, "cliff", global.siloPosition, ENFORCE_LAND_AREA_TILE_DIST+5)
    RemoveDecorationsArea(surface, chunkArea)

    -- Create rocket silo
    CreateRocketSilo(surface, chunkArea, MAIN_FORCE)
    CreateCropOctagon(surface, global.siloPosition, chunkArea, 40)

end

function ChartRocketSiloArea(force, surface)
    force.chart(surface, {{global.siloPosition.x-(CHUNK_SIZE*2), global.siloPosition.y-(CHUNK_SIZE*2)}, {global.siloPosition.x+(CHUNK_SIZE*2), global.siloPosition.y+(CHUNK_SIZE*2)}})
end