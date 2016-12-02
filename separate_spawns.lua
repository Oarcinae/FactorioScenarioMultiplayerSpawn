-- separate_spawns.lua
-- Nov 2016
--
-- Code that handles everything regarding giving each player a separate spawn
-- Includes the GUI stuff


--------------------------------------------------------------------------------
-- EVENT RELATED FUNCTIONS
--------------------------------------------------------------------------------

-- When a new player is created, present the spawn options
-- Assign them to the main force so they can communicate with the team
-- without shouting.
function SeparateSpawnsPlayerCreated(event)
    local player = game.players[event.player_index]
    player.force = MAIN_FORCE
    DisplayWelcomeTextGui(player)
    global.playerCooldowns[player.name] = {setRespawn=event.tick}
end


-- Check if the player has a different spawn point than the default one
-- Make sure to give the default starting items
function SeparateSpawnsPlayerRespawned(event)
    local player = game.players[event.player_index]
    SendPlayerToSpawn(player)
end





-- This is the main function that creates the spawn area
-- Provides resources, land and a safe zone
function SeparateSpawnsGenerateChunk(event)
    local surface = event.surface
    if surface.name ~= "nauvis" then return end
    local chunkArea = event.area
    
    -- This handles chunk generation near player spawns
    -- If it is near a player spawn, it does a few things like make the area
    -- safe and provide a guaranteed area of land and water tiles.
    for name,spawnPos in pairs(global.playerSpawns) do

        local landArea = {left_top=
                            {x=spawnPos.x-ENFORCE_LAND_AREA_TILE_DIST,
                             y=spawnPos.y-ENFORCE_LAND_AREA_TILE_DIST},
                          right_bottom=
                            {x=spawnPos.x+ENFORCE_LAND_AREA_TILE_DIST,
                             y=spawnPos.y+ENFORCE_LAND_AREA_TILE_DIST}}

        local safeArea = {left_top=
                            {x=spawnPos.x-SAFE_AREA_TILE_DIST,
                             y=spawnPos.y-SAFE_AREA_TILE_DIST},
                          right_bottom=
                            {x=spawnPos.x+SAFE_AREA_TILE_DIST,
                             y=spawnPos.y+SAFE_AREA_TILE_DIST}}

        local warningArea = {left_top=
                                {x=spawnPos.x-WARNING_AREA_TILE_DIST,
                                 y=spawnPos.y-WARNING_AREA_TILE_DIST},
                            right_bottom=
                                {x=spawnPos.x+WARNING_AREA_TILE_DIST,
                                 y=spawnPos.y+WARNING_AREA_TILE_DIST}}

        local chunkAreaCenter = {x=chunkArea.left_top.x+(CHUNK_SIZE/2),
                                 y=chunkArea.left_top.y+(CHUNK_SIZE/2)}

                                 

        -- Make chunks near a spawn safe by removing enemies
        if CheckIfInArea(chunkAreaCenter,safeArea) then
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, force = "enemy"}) do
                entity.destroy()
            end
        
        -- Create a warning area with reduced enemies
        elseif CheckIfInArea(chunkAreaCenter,warningArea) then
            local counter = 0
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, force = "enemy"}) do
                if ((counter % WARN_AREA_REDUCTION_RATIO) ~= 0) then
                    entity.destroy()
                end
                counter = counter + 1
            end

            -- Remove all big and huge worms
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, name = "medium-worm-turret"}) do
                    entity.destroy()
            end
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, name = "big-worm-turret"}) do
                    entity.destroy()
            end

        end

        -- Fill in any water to make sure we have guaranteed land mass at the spawn point.
        if CheckIfInArea(chunkAreaCenter,landArea) then

            -- remove trees in the immediate areas?
            for key, entity in pairs(surface.find_entities_filtered({area=chunkArea, type= "tree"})) do
                if ((spawnPos.x - entity.position.x)^2 + (spawnPos.y - entity.position.y)^2 < ENFORCE_LAND_AREA_TILE_DIST^2) then
                    entity.destroy()
                end
            end

            CreateCropCircle(surface, spawnPos, chunkArea, ENFORCE_LAND_AREA_TILE_DIST)
        end

        -- Provide a guaranteed spot of water to use for power generation
        -- A desert biome will shrink the water area!!
        if CheckIfInArea(spawnPos,chunkArea) then
            local waterTiles = {{name = "water", position ={spawnPos.x+0,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+1,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+2,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+3,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+4,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+5,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+6,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+7,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+8,spawnPos.y-30}}}
            -- DebugPrint("Setting water tiles in this chunk! " .. chunkArea.left_top.x .. "," .. chunkArea.left_top.y)
            surface.set_tiles(waterTiles)
        end
    end
end


-- Call this if a player leaves the game
-- Seems to be susceptiable to causing desyncs...
function FindUnusedSpawns(event)
    local player = game.players[event.player_index]
    if (player.online_time < MIN_ONLINE_TIME) then

        -- Clear out global variables for that player???
        if (global.playerSpawns[player.name] ~= nil) then
            global.playerSpawns[player.name] = nil
        end

        -- If a uniqueSpawn was created for the player, mark it as unused.
        if (global.uniqueSpawns[player.name] ~= nil) then
            table.insert(global.unusedSpawns, global.uniqueSpawns[player.name])
            global.uniqueSpawns[player.name] = nil
            SendBroadcastMsg(player.name .. " base was freed up because they left within 5 minutes of joining.")
        end
        
        if (global.sharedSpawns[player.name] ~= nil) then
            global.sharedSpawns[player.name] = nil
        end

        if (global.playerCooldowns[player.name] ~= nil) then
            global.playerCooldowns[player.name] = nil
        end

        game.remove_offline_players({player})
    end
end



--------------------------------------------------------------------------------
-- NON-EVENT RELATED FUNCTIONS
-- These should be local functions where possible!
--------------------------------------------------------------------------------

function InitSpawnGlobalsAndForces()
    -- Containes an array of all player spawns
    -- A secondary array tracks whether the character will respawn there.
    if (global.playerSpawns == nil) then
        global.playerSpawns = {}
    end
    if (global.uniqueSpawns == nil) then
        global.uniqueSpawns = {}
    end
    if (global.sharedSpawns == nil) then
        global.sharedSpawns = {}
    end
    if (global.unusedSpawns == nil) then
        global.unusedSpawns = {}
    end
    if (global.playerCooldowns == nil) then
        global.playerCooldowns = {}
    end

    game.create_force(MAIN_FORCE)
    game.forces[MAIN_FORCE].set_spawn_position(game.forces["player"].get_spawn_position("nauvis"), "nauvis")
    SetCeaseFireBetweenAllForces()
end

function GenerateStartingResources(player)
    local surface = player.surface

    -- Generate stone
    local stonePos = {x=player.position.x-25,
                  y=player.position.y-31}

    -- Generate coal
    local coalPos = {x=player.position.x-25,
                  y=player.position.y-16}

    -- Generate copper ore
    local copperOrePos = {x=player.position.x-25,
                  y=player.position.y+0}
                  
    -- Generate iron ore
    local ironOrePos = {x=player.position.x-25,
                  y=player.position.y+15}

    -- Tree generation is taken care of in chunk generation

    -- Generate oil patches
    surface.create_entity({name="crude-oil", amount=START_OIL_AMOUNT,
                    position={player.position.x-30, player.position.y-2}})
    surface.create_entity({name="crude-oil", amount=START_OIL_AMOUNT,
                    position={player.position.x-30, player.position.y+2}})

    for y=0, 15 do
        for x=0, 15 do
            if ((x-7)^2 + (y - 7)^2 < 7^2) then
                surface.create_entity({name="iron-ore", amount=START_IRON_AMOUNT,
                    position={ironOrePos.x+x, ironOrePos.y+y}})
                surface.create_entity({name="copper-ore", amount=START_COPPER_AMOUNT,
                    position={copperOrePos.x+x, copperOrePos.y+y}})
                surface.create_entity({name="stone", amount=START_STONE_AMOUNT,
                    position={stonePos.x+x, stonePos.y+y}})
                surface.create_entity({name="coal", amount=START_COAL_AMOUNT,
                    position={coalPos.x+x, coalPos.y+y}})
            end
        end
    end
end

function DoesPlayerHaveCustomSpawn(player)
    for name,spawnPos in pairs(global.playerSpawns) do
        if (player.name == name) then
            return true
        end
    end
    return false
end

function ChangePlayerSpawn(player, pos)
    global.playerSpawns[player.name] = pos
end

function SendPlayerToNewSpawnAndCreateIt(player, spawn)
    -- Send the player to that position
    player.teleport(spawn)
    GivePlayerStarterItems(player)
    ChartArea(player.force, player.position, 4)

    -- If we get a valid spawn point, setup the area
    if ((spawn.x ~= 0) and (spawn.y ~= 0)) then
        global.uniqueSpawns[player.name] = spawn
        GenerateStartingResources(player)
        ClearNearbyEnemies(player, SAFE_AREA_TILE_DIST)
    else      
        DebugPrint("THIS SHOULD NOT EVER HAPPEN! Spawn failed!")
        SendBroadcastMsg("Failed to create spawn point for: " .. player.name)
    end
end

function SendPlayerToSpawn(player)
    if (DoesPlayerHaveCustomSpawn(player)) then
        player.teleport(global.playerSpawns[player.name])
    else
        player.teleport(game.forces[MAIN_FORCE].get_spawn_position("nauvis"))
    end
end

function SendPlayerToRandomSpawn(player)
    local numSpawns = TableLength(global.uniqueSpawns)
    local rndSpawn = math.random(0,numSpawns)
    local counter = 0

    if (rndSpawn == 0) then
        player.teleport(game.forces[MAIN_FORCE].get_spawn_position("nauvis"))
    else
        counter = counter + 1
        for name,spawnPos in pairs(global.uniqueSpawns) do
            if (counter == rndSpawn) then
                player.teleport(spawnPos)
                break
            end
            counter = counter + 1
        end 
    end
end




--------------------------------------------------------------------------------
-- UNUSED CODE
-- Either didn't work, or not used or not tested....
--------------------------------------------------------------------------------



-- local tick_counter = 0
-- function ShareVision(event)
--     if (tick_counter > (TICKS_PER_SECOND*30)) then
--         ShareVisionForAllForces()
--         tick_counter = 0
--     end
--     tick_counter = tick_counter + 1
-- end

-- function CreatePlayerCustomForce(player)
--     local newForce = nil
    
--     -- Check if force already exists
--     if (game.forces[player.name] ~= nil) then
--         return game.forces[player.name]

--     -- Create a new force using the player's name
--     elseif (TableLength(game.forces) < MAX_FORCES) then
--         newForce = game.create_force(player.name)
--         player.force = newForce
--         SetCeaseFireBetweenAllForces()        
--     else
--         player.force = MAIN_FORCE
--         player.print("Sorry, no new teams can be created. You were assigned to the default team instead.")
--     end

--     return newForce
-- end