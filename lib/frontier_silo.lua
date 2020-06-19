-- frontier_silo.lua
-- Jan 2018
-- My take on frontier silos for my Oarc scenario

require("config")
require("lib/oarc_utils")

--------------------------------------------------------------------------------
-- Frontier style rocket silo stuff
--------------------------------------------------------------------------------


function SpawnSilosAndGenerateSiloAreas()

    -- Special silo islands mode "boogaloo"
    if (global.ocfg.silo_islands) then

        local num_spawns = #global.vanillaSpawns
        local new_spawn_list = {}

        -- Pick out every OTHER vanilla spawn for the rocket silos.
        for k,v in pairs(global.vanillaSpawns) do
            if ((k <= num_spawns/2) and (k%2==1)) then
                SetFixedSiloPosition({x=v.x,y=v.y})
            elseif ((k > num_spawns/2) and (k%2==0)) then
                SetFixedSiloPosition({x=v.x,y=v.y})
            else
                table.insert(new_spawn_list, v)
            end
        end
        global.vanillaSpawns = new_spawn_list

    -- A set of fixed silo positions
    elseif (global.ocfg.frontier_fixed_pos) then
        for k,v in pairs(global.ocfg.frontier_pos_table) do
            SetFixedSiloPosition(v)
        end

    -- Random locations on a circle.
    else
        SetRandomSiloPosition(global.ocfg.frontier_silo_count)

    end

    -- Freezes the game at the start to generate all the chunks.
    GenerateRocketSiloAreas(game.surfaces[GAME_SURFACE_NAME])
end

-- This creates a random silo position, stored to global.siloPosition
-- It uses the config setting global.ocfg.frontier_silo_distance and spawns the
-- silo somewhere on a circle edge with radius using that distance.
function SetRandomSiloPosition(num_silos)
    if (global.siloPosition == nil) then
        global.siloPosition = {}
    end

    local random_angle_offset = math.random(0, math.pi * 2)

    for i=1,num_silos do
        local theta = ((math.pi * 2) / num_silos);
        local angle = (theta * i) + random_angle_offset;

        local tx = (global.ocfg.frontier_silo_distance*CHUNK_SIZE * math.cos(angle))
        local ty = (global.ocfg.frontier_silo_distance*CHUNK_SIZE * math.sin(angle))

        -- Ensure it's centered around a chunk
        local tx = (tx - (tx % CHUNK_SIZE)) + CHUNK_SIZE/2
        local ty = (ty - (ty % CHUNK_SIZE)) + CHUNK_SIZE/2

        table.insert(global.siloPosition, {x=math.floor(tx), y=math.floor(ty)})

        log("Silo position: " .. tx .. ", " .. ty .. ", " .. angle)
    end
end

-- Sets the global.siloPosition var to the set in the config file
function SetFixedSiloPosition(pos)
    table.insert(global.siloPosition, pos)
end

-- Create a rocket silo at the specified positionmmmm
-- Also makes sure tiles and entities are cleared if required.
local function CreateRocketSilo(surface, siloPosition, force)

    -- Delete any entities beneath the silo?
    for _, entity in pairs(surface.find_entities_filtered{area = {{siloPosition.x-5,
                                                                    siloPosition.y-6},
                                                                    {siloPosition.x+6,
                                                                    siloPosition.y+6}}}) do
        entity.destroy()
    end

    -- Remove nearby enemies again
    for _, entity in pairs(surface.find_entities_filtered{area = {{siloPosition.x-(CHUNK_SIZE*4),
                                                                    siloPosition.y-(CHUNK_SIZE*4)},
                                                                    {siloPosition.x+(CHUNK_SIZE*4),
                                                                    siloPosition.y+(CHUNK_SIZE*4)}}, force = "enemy"}) do
        entity.destroy()
    end

    -- Set tiles below the silo
    tiles = {}
    for dx = -6,5 do
        for dy = -6,5 do
            if (game.active_mods["oarc-restricted-build"]) then
                table.insert(tiles, {name = global.ocfg.locked_build_area_tile,
                                    position = {siloPosition.x+dx, siloPosition.y+dy}})
            else
                if ((dx % 2 == 0) or (dx % 2 == 0)) then
                    table.insert(tiles, {name = "concrete",
                                        position = {siloPosition.x+dx, siloPosition.y+dy}})
                else
                    table.insert(tiles, {name = "hazard-concrete-left",
                                        position = {siloPosition.x+dx, siloPosition.y+dy}})
                end
            end
        end
    end
    surface.set_tiles(tiles, true)

    -- Create indestructible silo and assign to a force
    if not global.ocfg.frontier_allow_build then
        local silo = surface.create_entity{name = "rocket-silo", position = {siloPosition.x+0.5, siloPosition.y}, force = force}
        silo.destructible = false
        silo.minable = false
    end

    -- TAG it on the main force at least.
    game.forces[global.ocfg.main_force].add_chart_tag(game.surfaces[GAME_SURFACE_NAME],
                                            {position=siloPosition, text="Rocket Silo",
                                                icon={type="item",name="rocket-silo"}})

    -- Make silo safe from being removed.
    if global.ocfg.enable_regrowth then
        RegrowthMarkAreaSafeGivenTilePos(siloPosition, 5, true)
    end

    if ENABLE_SILO_BEACONS then
        PhilipsBeacons(surface, siloPosition, game.forces[global.ocfg.main_force])
    end
    if ENABLE_SILO_RADAR then
        PhilipsRadar(surface, siloPosition, game.forces[global.ocfg.main_force])
    end

end

-- Generates all rocket silos, should be called after the areas are generated
-- Includes a crop circle
function GenerateAllSilos()

    -- Create each silo in the list
    for idx,siloPos in pairs(global.siloPosition) do
        CreateRocketSilo(game.surfaces[GAME_SURFACE_NAME], siloPos, global.ocfg.main_force)
    end
end

-- Validates any attempt to build a silo.
-- Should be call in on_built_entity and on_robot_built_entity
function BuildSiloAttempt(event)

    -- Validation
    if (event.created_entity == nil) then return end

    local e_name = event.created_entity.name
    if (event.created_entity.name == "entity-ghost") then
        e_name =event.created_entity.ghost_name
    end

    if (e_name ~= "rocket-silo") then return end

    -- Check if it's in the right area.
    local epos = event.created_entity.position

    for k,v in pairs(global.siloPosition) do
        if (getDistance(epos, v) <= 1) then
            if (event.created_entity.name ~= "entity-ghost") then
                SendBroadcastMsg("Rocket silo has been built!")
            end
            return -- THIS MEANS WE SUCCESFULLY BUILT THE SILO (ghost or actual building.)
        end
    end

    -- If we get here, means it wasn't in a valid position. Need to remove it.
    if (event.created_entity.last_user ~= nil) then
        FlyingText("Can't build silo here! Check the map!", epos, my_color_red, event.created_entity.surface)
        if (event.created_entity.name == "entity-ghost") then
            event.created_entity.destroy()
        else
            event.created_entity.last_user.mine_entity(event.created_entity, true)
        end
    else
        log("ERROR! Rocket-silo had no valid last user?!?!")
    end
end

-- Generate clean land and trees around silo area
function GenerateRocketSiloChunks()

    -- Silo generation can take awhile depending on the number of silos.
    -- if (game.tick < #global.siloPosition*10*TICKS_PER_SECOND) then
        local surface = game.surfaces[GAME_SURFACE_NAME]
        -- local chunkArea = event.area

        -- local chunkAreaCenter = {x=chunkArea.left_top.x+(CHUNK_SIZE/2),
        --                          y=chunkArea.left_top.y+(CHUNK_SIZE/2)}

        for _,siloPos in pairs(global.siloPosition) do
            local siloArea = {left_top=
                                {x=siloPos.x-(CHUNK_SIZE*2),
                                 y=siloPos.y-(CHUNK_SIZE*2)},
                              right_bottom=
                                {x=siloPos.x+(CHUNK_SIZE*2),
                                 y=siloPos.y+(CHUNK_SIZE*2)}}


            -- Clear enemies directly next to the rocket
            -- if CheckIfInArea(chunkAreaCenter,siloArea) then
                for _, entity in pairs(surface.find_entities_filtered{area = siloArea, force = "enemy"}) do
                    entity.destroy()
                end

                -- Remove trees/resources inside the spawn area
                RemoveInCircle(surface, siloArea, "tree", siloPos, (CHUNK_SIZE*1.5)+5)
                RemoveInCircle(surface, siloArea, "resource", siloPos, (CHUNK_SIZE*1.5)+5)
                RemoveInCircle(surface, siloArea, "cliff", siloPos, (CHUNK_SIZE*1.5)+5)
                RemoveDecorationsArea(surface, siloArea)

                -- Create rocket silo
                CreateCropOctagon(surface, siloPos, siloArea, (CHUNK_SIZE*1.5)+4, "landfill")
            -- end
        end
    -- end
end

-- Generate chunks where we plan to place the rocket silos.
function GenerateRocketSiloAreas(surface)
    for idx,siloPos in pairs(global.siloPosition) do
        surface.request_to_generate_chunks({siloPos.x, siloPos.y}, 1)
    end
    if (global.ocfg.frontier_silo_vision) then
        ChartRocketSiloAreas(surface, game.forces[global.ocfg.main_force])
    end

    game.surfaces[GAME_SURFACE_NAME].force_generate_chunk_requests() -- Block and generate all to be sure.

    GenerateRocketSiloChunks()
    GenerateAllSilos()
end

-- Chart chunks where we plan to place the rocket silos.
function ChartRocketSiloAreas(surface, force)
    for idx,siloPos in pairs(global.siloPosition) do
        force.chart(surface, {{siloPos.x-(CHUNK_SIZE*1),
                                siloPos.y-(CHUNK_SIZE*1)},
                                {siloPos.x+(CHUNK_SIZE*1),
                                siloPos.y+(CHUNK_SIZE*1)}})
    end
end

function PhilipsBeacons(surface, siloPos, force)

    -- Add Beacons
    -- x = right, left; y = up, down
    -- top 1 left 1
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x-8, siloPos.y-8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- top 2
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x-5, siloPos.y-8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- top 3
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x-2, siloPos.y-8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- top 4
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x+2, siloPos.y-8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- top 5
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x+5, siloPos.y-8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- top 6 right 1
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x+8, siloPos.y-8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- left 2
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x-8, siloPos.y-5}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- left 3
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x-8, siloPos.y-2}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- left 4
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x-8, siloPos.y+2}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- left 5
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x-8, siloPos.y+5}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- left 6 bottom 1
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x-8, siloPos.y+8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- left 7 bottom 2
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x-5, siloPos.y+8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- right 2
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x+8, siloPos.y-5}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- right 3
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x+8, siloPos.y-2}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- right 4
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x+8, siloPos.y+2}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- right 5
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x+8, siloPos.y+5}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- right 6 bottom 3
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x+5, siloPos.y+8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- right 7 bottom 4
    local beacon = surface.create_entity{name = "beacon", position = {siloPos.x+8, siloPos.y+8}, force = force}
    beacon.destructible = false
    beacon.minable = false
    -- substations
    -- top left
    local substation = surface.create_entity{name = "substation", position = {siloPos.x-5, siloPos.y-5}, force = force}
    substation.destructible = false
    substation.minable = false
    -- top right
    local substation = surface.create_entity{name = "substation", position = {siloPos.x+6, siloPos.y-5}, force = force}
    substation.destructible = false
    substation.minable = false
    -- bottom left
    local substation = surface.create_entity{name = "substation", position = {siloPos.x-5, siloPos.y+6}, force = force}
    substation.destructible = false
    substation.minable = false
    -- bottom right
    local substation = surface.create_entity{name = "substation", position = {siloPos.x+6, siloPos.y+6}, force = force}
    substation.destructible = false
    substation.minable = false

    -- end adding beacons
end

function PhilipsRadar(surface, siloPos, force)

    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-43, siloPos.y+3}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-43, siloPos.y-3}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-40, siloPos.y-6}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-37, siloPos.y-6}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-34, siloPos.y-6}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-34, siloPos.y-3}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-34, siloPos.y}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-34, siloPos.y+3}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-43, siloPos.y-6}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-40, siloPos.y+3}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "solar-panel", position = {siloPos.x-37, siloPos.y+3}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "radar", position = {siloPos.x-43, siloPos.y}, force = force}
    radar.destructible = false
    local substation = surface.create_entity{name = "substation", position = {siloPos.x-38, siloPos.y-1}, force = force}
    substation.destructible = false
    local radar = surface.create_entity{name = "accumulator", position = {siloPos.x-40, siloPos.y-1}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "accumulator", position = {siloPos.x-40, siloPos.y-3}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "accumulator", position = {siloPos.x-40, siloPos.y+1}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "accumulator", position = {siloPos.x-38, siloPos.y-3}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "accumulator", position = {siloPos.x-38, siloPos.y+1}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "accumulator", position = {siloPos.x-36, siloPos.y-1}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "accumulator", position = {siloPos.x-36, siloPos.y-3}, force = force}
    radar.destructible = false
    local radar = surface.create_entity{name = "accumulator", position = {siloPos.x-36, siloPos.y+1}, force = force}
    radar.destructible = false
end