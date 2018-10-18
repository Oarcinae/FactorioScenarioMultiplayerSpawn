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
    local chunkArea = event.area
    
    -- This handles chunk generation near player spawns
    -- If it is near a player spawn, it does a few things like make the area
    -- safe and provide a guaranteed area of land and water tiles.
    SetupAndClearSpawnAreas(surface, chunkArea, global.uniqueSpawns)
end


-- Call this if a player leaves the game
-- Still seems to have a bug.
function FindUnusedSpawns(event)
    local player = game.players[event.player_index]
    if (player.online_time < MIN_ONLINE_TIME) then

        DropGravestoneChests(player)

        -- Clear out global variables for that player
        if (global.playerSpawns[player.name] ~= nil) then
            global.playerSpawns[player.name] = nil
        end
      
        -- Remove them from the delayer spawn queue if they are in it
        for i=#global.delayedSpawns,1,-1 do
            delayedSpawn = global.delayedSpawns[i]

            if (player.name == delayedSpawn.playerName) then
                table.remove(global.delayedSpawns, i)
                DebugPrint("Removing player from delayed spawn queue: " .. player.name)
            end
        end

        -- Transfer or remove a shared spawn if player is owner
        if (global.sharedSpawns[player.name] ~= nil) then
            
            local teamMates = global.sharedSpawns[player.name].players

            if (#teamMates >= 1) then
                local newOwnerName = table.remove(teamMates)
                TransferOwnershipOfSharedSpawn(player.name, newOwnerName)
            else
                global.sharedSpawns[player.name] = nil
            end
        end

        -- If a uniqueSpawn was created for the player, mark it as unused.
        if (global.uniqueSpawns[player.name] ~= nil) then

            local spawnPos = global.uniqueSpawns[player.name].pos

            -- Check if it was near someone else's base.
            nearOtherSpawn = false
            for spawnPlayerName,otherSpawnPos in pairs(global.uniqueSpawns) do
                if ((spawnPlayerName ~= player.name) and (getDistance(spawnPos, otherSpawnPos.pos) < (ENFORCE_LAND_AREA_TILE_DIST*3))) then
                    DebugPrint("Won't remove base as it's close to another spawn: " .. spawnPlayerName)
                    nearOtherSpawn = true
                end
            end

            if (ENABLE_ABANDONED_BASE_REMOVAL and not nearOtherSpawn) then
				global.uniqueSpawns[player.name] = nil

				SendBroadcastMsg(player.name .. "'s base was marked for immediate clean up because they left within "..MIN_ONLINE_TIME_IN_MINUTES.." minutes of joining.")
				OarcRegrowthMarkForRemoval(spawnPos, 10)
				global.chunk_regrow.force_removal_flag = game.tick
			else
				table.insert(global.unusedSpawns, global.uniqueSpawns[player.name])
                global.uniqueSpawns[player.name] = nil
	            SendBroadcastMsg(player.name .. " base was freed up because they left within "..MIN_ONLINE_TIME_IN_MINUTES.." minutes of joining.")
			end
        end

        -- remove that player's cooldown setting
        if (global.playerCooldowns[player.name] ~= nil) then
            global.playerCooldowns[player.name] = nil
        end

        -- Remove from shared spawn player slots (need to search all)
        for _,sharedSpawn in pairs(global.sharedSpawns) do
            for key,playerName in pairs(sharedSpawn.players) do
                if (player.name == playerName) then
                    sharedSpawn.players[key] = nil;
                end
            end
        end

        -- Remove a force if this player created it and they are the only one on it
        if ((#player.force.players <= 1) and (player.force.name ~= MAIN_FORCE)) then
            game.merge_forces(player.force, MAIN_FORCE)
        end

        -- Remove the character completely
        game.remove_offline_players({player})
    end
end


--------------------------------------------------------------------------------
-- NON-EVENT RELATED FUNCTIONS
--------------------------------------------------------------------------------

-- Add a spawn to the shared spawn global
-- Used for tracking which players are assigned to it, where it is and if
-- it is open for new players to join
function CreateNewSharedSpawn(player)
    global.sharedSpawns[player.name] = {openAccess=true,
                                    position=global.playerSpawns[player.name],
                                    players={}}
end

function TransferOwnershipOfSharedSpawn(prevOwnerName, newOwnerName)
    -- Transfer the shared spawn global
    global.sharedSpawns[newOwnerName] = global.sharedSpawns[prevOwnerName]
    global.sharedSpawns[newOwnerName].openAccess = false
    global.sharedSpawns[prevOwnerName] = nil

    -- Transfer the unique spawn global
    global.uniqueSpawns[newOwnerName] = global.uniqueSpawns[prevOwnerName]
    global.uniqueSpawns[prevOwnerName] = nil

    game.players[newOwnerName].print("You have been given ownership of this base!")
end

-- Returns the number of players currently online at the shared spawn
function GetOnlinePlayersAtSharedSpawn(ownerName)
    if (global.sharedSpawns[ownerName] ~= nil) then

        -- Does not count base owner
        local count = 0

        -- For each player in the shared spawn, check if online and add to count.
        for _,player in pairs(game.connected_players) do
            if (ownerName == player.name) then
                count = count + 1
            end

            for _,playerName in pairs(global.sharedSpawns[ownerName].players) do
            
                if (playerName == player.name) then
                    count = count + 1
                end
            end
        end

        return count
    else
        return 0
    end
end

-- Get the number of currently available shared spawns
-- This means the base owner has enabled access AND the number of online players
-- is below the threshold.
function GetNumberOfAvailableSharedSpawns()
    local count = 0

    for ownerName,sharedSpawn in pairs(global.sharedSpawns) do
        if (sharedSpawn.openAccess and
            (game.players[ownerName] ~= nil) and
            game.players[ownerName].connected) then
            if ((MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN == 0) or
                (GetOnlinePlayersAtSharedSpawn(ownerName) < MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN)) then
                count = count+1
            end
        end
    end

    return count
end


-- Initializes the globals used to track the special spawn and player
-- status information
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
    if (global.waitingBuddies == nil) then
        global.waitingBuddies = {}
    end
    if (global.delayedSpawns == nil) then
        global.delayedSpawns = {}
    end
    if (global.buddySpawnOptions == nil) then
        global.buddySpawnOptions = {}
    end

    game.create_force(MAIN_FORCE)
    game.forces[MAIN_FORCE].set_spawn_position(game.forces["player"].get_spawn_position(GAME_SURFACE_NAME), GAME_SURFACE_NAME)
    
    if ENABLE_SHARED_TEAM_VISION then
        game.forces[MAIN_FORCE].share_chart = true
    end

    SetCeaseFireBetweenAllForces()
    SetFriendlyBetweenAllForces()
    if (ENABLE_ANTI_GRIEFING) then
        AntiGriefing(game.forces[MAIN_FORCE])
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
    global.playerCooldowns[player.name] = {setRespawn=game.tick}
end

function QueuePlayerForDelayedSpawn(playerName, spawn, moatEnabled)
    
    -- If we get a valid spawn point, setup the area
    if ((spawn.x ~= 0) and (spawn.y ~= 0)) then
        global.uniqueSpawns[playerName] = {pos=spawn,moat=moatEnabled}

        local delay_spawn_seconds = 5*(math.ceil(ENFORCE_LAND_AREA_TILE_DIST/CHUNK_SIZE))

        game.players[playerName].print("Generating your spawn now, please wait a few for " .. delay_spawn_seconds .. " seconds...")
        game.players[playerName].surface.request_to_generate_chunks(spawn, 4)
        delayedTick = game.tick + delay_spawn_seconds*TICKS_PER_SECOND
        table.insert(global.delayedSpawns, {playerName=playerName, spawn=spawn, moatEnabled=moatEnabled, delayedTick=delayedTick})

        DisplayPleaseWaitForSpawnDialog(game.players[playerName], delay_spawn_seconds)

    else      
        DebugPrint("THIS SHOULD NOT EVER HAPPEN! Spawn failed!")
        SendBroadcastMsg("ERROR!! Failed to create spawn point for: " .. playerName)
    end
end


-- Check a table to see if there are any players waiting to spawn
-- Check if we are past the delayed tick count
-- Spawn the players and remove them from the table.
function DelayedSpawnOnTick()
    if ((game.tick % (30)) == 1) then
        if ((global.delayedSpawns ~= nil) and (#global.delayedSpawns > 0)) then
            for i=#global.delayedSpawns,1,-1 do
                delayedSpawn = global.delayedSpawns[i]

                if (delayedSpawn.delayedTick < game.tick) then
                    -- TODO, add check here for if chunks around spawn are generated surface.is_chunk_generated(chunkPos)
                    if (game.players[delayedSpawn.playerName] ~= nil) then
                        SendPlayerToNewSpawnAndCreateIt(delayedSpawn.playerName, delayedSpawn.spawn, delayedSpawn.moatEnabled)
                    end
                    table.remove(global.delayedSpawns, i)
                end
            end
        end
    end
end

function SendPlayerToNewSpawnAndCreateIt(playerName, spawn, moatEnabled)

    -- Make sure the area is super safe.
    ClearNearbyEnemies(spawn, SAFE_AREA_TILE_DIST, game.surfaces[GAME_SURFACE_NAME])

    -- Create the spawn resources here
    CreateWaterStrip(game.surfaces[GAME_SURFACE_NAME],
                    {x=spawn.x+WATER_SPAWN_OFFSET_X, y=spawn.y+WATER_SPAWN_OFFSET_Y},
                    WATER_SPAWN_LENGTH)
    CreateWaterStrip(game.surfaces[GAME_SURFACE_NAME],
                    {x=spawn.x+WATER_SPAWN_OFFSET_X, y=spawn.y+WATER_SPAWN_OFFSET_Y+1},
                    WATER_SPAWN_LENGTH)
    GenerateStartingResources(game.surfaces[GAME_SURFACE_NAME], spawn)

    -- Send the player to that position
    game.players[playerName].teleport(spawn, GAME_SURFACE_NAME)
    GivePlayerStarterItems(game.players[playerName])

    -- Chart the area.
    ChartArea(game.players[playerName].force, game.players[playerName].position, math.ceil(ENFORCE_LAND_AREA_TILE_DIST/CHUNK_SIZE), game.players[playerName].surface)

    if (game.players[playerName].gui.center.wait_for_spawn_dialog ~= nil) then
        game.players[playerName].gui.center.wait_for_spawn_dialog.destroy()
    end
end

function SendPlayerToSpawn(player)
    if (DoesPlayerHaveCustomSpawn(player)) then
        player.teleport(global.playerSpawns[player.name], GAME_SURFACE_NAME)
    else
        player.teleport(game.forces[MAIN_FORCE].get_spawn_position(GAME_SURFACE_NAME), GAME_SURFACE_NAME)
    end
end

function SendPlayerToRandomSpawn(player)
    local numSpawns = TableLength(global.uniqueSpawns)
    local rndSpawn = math.random(0,numSpawns)
    local counter = 0

    if (rndSpawn == 0) then
        player.teleport(game.forces[MAIN_FORCE].get_spawn_position(GAME_SURFACE_NAME), GAME_SURFACE_NAME)
    else
        counter = counter + 1
        for name,spawn in pairs(global.uniqueSpawns) do
            if (counter == rndSpawn) then
                player.teleport(spawn.pos)
                break
            end
            counter = counter + 1
        end 
    end
end

function CreatePlayerCustomForce(player)
    local newForce = nil
    
    -- Check if force already exists
    if (game.forces[player.name] ~= nil) then
        DebugPrint("Force already exists!")
        player.force = game.forces[player.name]
        return game.forces[player.name]

    -- Create a new force using the player's name
    elseif (TableLength(game.forces) < MAX_FORCES) then
        newForce = game.create_force(player.name)
        if ENABLE_SHARED_TEAM_VISION then
            newForce.share_chart = true
        end
        -- Chart silo areas if necessary
        if FRONTIER_ROCKET_SILO_MODE and ENABLE_SILO_VISION then
            ChartRocketSiloAreas(game.surfaces[GAME_SURFACE_NAME], newForce)
        end
        player.force = newForce
        SetCeaseFireBetweenAllForces()
        SetFriendlyBetweenAllForces()
        if (ENABLE_ANTI_GRIEFING) then
            AntiGriefing(newForce)
        end
        SendBroadcastMsg(player.name.." has started their own team!")     
    else
        player.force = MAIN_FORCE
        player.print("Sorry, no new teams can be created. You were assigned to the default team instead.")
    end

    return newForce
end
