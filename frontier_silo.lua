-- frontier_silo.lua
-- Nov 2016

require("config")
require("oarc_utils")

-- Create a rocket silo
local function CreateRocketSilo(surface, chunkArea)
    if CheckIfInArea(SILO_POSITION, chunkArea) then

        -- Delete any entities beneat the silo?
        for _, entity in pairs(surface.find_entities_filtered{area = {{SILO_POSITION.x-5, SILO_POSITION.y-6},{SILO_POSITION.x+6, SILO_POSITION.y+6}}}) do
            entity.destroy()
        end

        -- Set tiles below the silo
        local tiles = {}
        local i = 1
        for dx = -6,6 do
            for dy = -7,6 do
                tiles[i] = {name = "grass", position = {SILO_POSITION.x+dx, SILO_POSITION.y+dy}}
                i=i+1
            end
        end
        surface.set_tiles(tiles, false)
        tiles = {}
        i = 1
        for dx = -5,5 do
            for dy = -6,5 do
                tiles[i] = {name = "concrete", position = {SILO_POSITION.x+dx, SILO_POSITION.y+dy}}
                i=i+1
            end
        end
        surface.set_tiles(tiles, true)

        -- Create silo and assign to main force
        local silo = surface.create_entity{name = "rocket-silo", position = {SILO_POSITION.x+0.5, SILO_POSITION.y}, force = MAIN_FORCE}
        silo.destructible = false
        silo.minable = false
    end
end

-- Remove rocket silo from recipes
function RemoveRocketSiloRecipe(event)
    local recipes = event.research.force.recipes
    if recipes["rocket-silo"] then
        recipes["rocket-silo"].enabled = false
    end
end

-- Generates the rocket silo during chunk generation event
-- Includes a crop circle
function GenerateRocketSiloChunk(event)
    local surface = event.surface
    if surface.name ~= "nauvis" then return end
    local chunkArea = event.area

    local chunkAreaCenter = {x=chunkArea.left_top.x+(CHUNK_SIZE/2),
                             y=chunkArea.left_top.y+(CHUNK_SIZE/2)}
    local safeArea = {left_top=
                        {x=SILO_POSITION.x-150,
                         y=SILO_POSITION.y-150},
                      right_bottom=
                        {x=SILO_POSITION.x+150,
                         y=SILO_POSITION.y+150}}
                             

    -- Clear enemies directly next to the rocket
    if CheckIfInArea(chunkAreaCenter,safeArea) then
        for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, force = "enemy"}) do
            entity.destroy()
        end
    end

    -- Create rocket silo
    CreateRocketSilo(surface, chunkArea)
    CreateCropCircle(surface, SILO_POSITION, chunkArea, 40)
end

function ChartRocketSiloArea(force)
    force.chart(game.surfaces["nauvis"], {{SILO_POSITION.x-(CHUNK_SIZE*2), SILO_POSITION.y-(CHUNK_SIZE*2)}, {SILO_POSITION.x+(CHUNK_SIZE*2), SILO_POSITION.y+(CHUNK_SIZE*2)}})
end