-- separate_spawns.lua
-- Nov 2016
--
-- Code that handles everything regarding giving each player a separate spawn
-- Includes the GUI stuff

require("lib/oarc_utils")
require("config")

--------------------------------------------------------------------------------
-- EVENT RELATED FUNCTIONS
--------------------------------------------------------------------------------

-- When a new player is created, present the spawn options
-- Assign them to the main force so they can communicate with the team
-- without shouting.
function SeparateSpawnsPlayerCreated(player_index)
    local player = game.players[player_index]
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
    
    -- Modify enemies first.
    if OARC_MODIFIED_ENEMY_SPAWNING then
        DowngradeWormsDistanceBasedOnChunkGenerate(event)
    end

    -- This handles chunk generation near player spawns
    -- If it is near a player spawn, it does a few things like make the area
    -- safe and provide a guaranteed area of land and water tiles.
    SetupAndClearSpawnAreas(surface, chunkArea)
end


-- Call this if a player leaves the game
function FindUnusedSpawns(event)
    local player = game.players[event.player_index]
    if (player.online_time < MIN_ONLINE_TIME) then

        -- Clear out global variables for that player
        if (global.playerSpawns[player.name] ~= nil) then
            global.playerSpawns[player.name] = nil
        end
      
        -- Remove them from the delayed spawn queue if they are in it
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
				-- table.insert(global.unusedSpawns, global.uniqueSpawns[player.name]) -- Not used/implemented right now.
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

-- Clear the spawn areas.
-- This should be run inside the chunk generate event and be given a list of all
-- unique spawn points.
-- This clears enemies in the immediate area, creates a slightly safe area around it,
-- It no LONGER generates the resources though as that is now handled in a delayed event!
function SetupAndClearSpawnAreas(surface, chunkArea)
    for name,spawn in pairs(global.uniqueSpawns) do

        if (not spawn.vanilla) then

            -- Create a bunch of useful area and position variables
            local landArea = GetAreaAroundPos(spawn.pos, ENFORCE_LAND_AREA_TILE_DIST+CHUNK_SIZE)
            local safeArea = GetAreaAroundPos(spawn.pos, SAFE_AREA_TILE_DIST)
            local warningArea = GetAreaAroundPos(spawn.pos, WARNING_AREA_TILE_DIST)
            local reducedArea = GetAreaAroundPos(spawn.pos, REDUCED_DANGER_AREA_TILE_DIST)
            local chunkAreaCenter = {x=chunkArea.left_top.x+(CHUNK_SIZE/2),
                                             y=chunkArea.left_top.y+(CHUNK_SIZE/2)}
            local spawnPosOffset = {x=spawn.pos.x+ENFORCE_LAND_AREA_TILE_DIST,
                                             y=spawn.pos.y+ENFORCE_LAND_AREA_TILE_DIST}

            -- Make chunks near a spawn safe by removing enemies
            if CheckIfInArea(chunkAreaCenter,safeArea) then
                RemoveAliensInArea(surface, chunkArea)
            
            -- Create a warning area with heavily reduced enemies
            elseif CheckIfInArea(chunkAreaCenter,warningArea) then
                ReduceAliensInArea(surface, chunkArea, WARN_AREA_REDUCTION_RATIO)
                -- DowngradeWormsInArea(surface, chunkArea, 100, 100, 100)
                RemoveWormsInArea(surface, chunkArea, false, true, true, true) -- remove all non-small worms.

            -- Create a third area with moderatly reduced enemies
            elseif CheckIfInArea(chunkAreaCenter,reducedArea) then
                ReduceAliensInArea(surface, chunkArea, REDUCED_DANGER_AREA_REDUCTION_RATIO)
                -- DowngradeWormsInArea(surface, chunkArea, 50, 100, 100)
                RemoveWormsInArea(surface, chunkArea, false, false, true, true) -- remove all huge/behemoth worms.
            end

            -- If the chunk is within the main land area, then clear trees/resources
            -- and create the land spawn areas (guaranteed land with a circle of trees)
            if CheckIfInArea(chunkAreaCenter,landArea) then

                -- Remove trees/resources inside the spawn area
                RemoveInCircle(surface, chunkArea, "tree", spawn.pos, ENFORCE_LAND_AREA_TILE_DIST)
                RemoveInCircle(surface, chunkArea, "resource", spawn.pos, ENFORCE_LAND_AREA_TILE_DIST+5)
                RemoveInCircle(surface, chunkArea, "cliff", spawn.pos, ENFORCE_LAND_AREA_TILE_DIST+5)
                -- RemoveDecorationsArea(surface, chunkArea)

                if (OARC_CFG.gen_settings.tree_circle) then
                    CreateCropCircle(surface, spawn.pos, chunkArea, ENFORCE_LAND_AREA_TILE_DIST)
                end
                if (OARC_CFG.gen_settings.tree_octagon) then
                    CreateCropOctagon(surface, spawn.pos, chunkArea, ENFORCE_LAND_AREA_TILE_DIST)
                end
                if (SPAWN_MOAT_CHOICE_ENABLED) then
                    if (spawn.moat) then
                        CreateMoat(surface, spawn.pos, chunkArea, ENFORCE_LAND_AREA_TILE_DIST)
                    end
                end
            end
        end
    end
end

-- I wrote this to ensure everyone gets safer spawns regardless of evolution level.
-- This is intended to downgrade any biters/spitters spawning near player bases.
-- I'm not sure the performance impact of this but I'm hoping it's not bad.
function ModifyEnemySpawnsNearPlayerStartingAreas(event)

    if (not event.entity or not (event.entity.force.name == "enemy") or not event.entity.position) then
        DebugPrint("ModifyBiterSpawns - Unexpected use.")
        return
    end

    local enemy_pos = event.entity.position
    local surface = event.entity.surface
    local enemy_name = event.entity.name

    for name,spawn in pairs(global.uniqueSpawns) do
        if (getDistance(enemy_pos, spawn.pos) < WARNING_AREA_TILE_DIST) then
            if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter")) then
                event.entity.destroy()
                surface.create_entity{name = "medium-biter", position = enemy_pos, force = game.forces.enemy}
                DebugPrint("Downgraded biter close to spawn.")
            elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter")) then
                event.entity.destroy()
                surface.create_entity{name = "medium-spitter", position = enemy_pos, force = game.forces.enemy}
                DebugPrint("Downgraded spitter close to spawn.")
            end
        elseif (getDistance(enemy_pos, spawn.pos) < REDUCED_DANGER_AREA_REDUCTION_RATIO) then
            if (enemy_name == "behemoth-biter") then
                event.entity.destroy()
                surface.create_entity{name = "medium-biter", position = enemy_pos, force = game.forces.enemy}
                DebugPrint("Downgraded biter further from spawn.")
            elseif (enemy_name == "behemoth-spitter") then
                event.entity.destroy()
                surface.create_entity{name = "medium-spitter", position = enemy_pos, force = game.forces.enemy}
                DebugPrint("Downgraded spitter further from spawn.")
            end
        end
    end
end

--------------------------------------------------------------------------------
-- NON-EVENT RELATED FUNCTIONS
--------------------------------------------------------------------------------

-- Generate the basic starter resource around a given location.
function GenerateStartingResources(surface, pos)

    local rand_settings = OARC_CFG.resource_rand_pos_settings

    -- Generate all resource tile patches
    if (not rand_settings.enabled) then
        for t_name,t_data in pairs (OARC_CFG.resource_tiles) do
            local pos = {x=pos.x+t_data.x_offset, y=pos.y+t_data.y_offset}
            GenerateResourcePatch(surface, t_name, t_data.size, pos, t_data.amount)
        end
    else

        -- Create list of resource tiles
        local r_list = {}
        for k,_ in pairs(OARC_CFG.resource_tiles) do
            table.insert(r_list, k)
        end
        local shuffled_list = FYShuffle(r_list)

        -- This places resources in a semi-circle
        -- Tweak in config.lua
        local angle_offset = rand_settings.angle_offset
        local num_resources = TableLength(OARC_CFG.resource_tiles)
        local theta = ((rand_settings.angle_final - rand_settings.angle_offset) / num_resources);
        local count = 0

        for _,k_name in pairs (shuffled_list) do
            local angle = (theta * count) + angle_offset;

            local tx = (rand_settings.radius * math.cos(angle)) + pos.x
            local ty = (rand_settings.radius * math.sin(angle)) + pos.y

            local pos = {x=math.floor(tx), y=math.floor(ty)}
            GenerateResourcePatch(surface, k_name, OARC_CFG.resource_tiles[k_name].size, pos, OARC_CFG.resource_tiles[k_name].amount)
            count = count+1
        end
    end

    -- Generate special resource patches (oil)
    for p_name,p_data in pairs (OARC_CFG.resource_patches) do
        local oil_patch_x=pos.x+p_data.x_offset_start
        local oil_patch_y=pos.y+p_data.y_offset_start
        for i=1,p_data.num_patches do
            surface.create_entity({name=p_name, amount=p_data.amount,
                        position={oil_patch_x, oil_patch_y}})
            oil_patch_x=oil_patch_x+p_data.x_offset_next
            oil_patch_y=oil_patch_y+p_data.y_offset_next
        end
    end
end

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
    
    -- This contains each player's spawn point. Literally where they will respawn.
    -- There is a way in game to change this under one of the little menu features I added.
    if (global.playerSpawns == nil) then
        global.playerSpawns = {}
    end

    -- This is the most important table. It is a list of all the unique spawn points.
    -- This is what chunk generation checks against.
    -- Each entry looks like this: {pos={x,y},moat=bool,vanilla=bool}
    if (global.uniqueSpawns == nil) then
        global.uniqueSpawns = {}
    end

    -- List of available vanilla spawns
    if (global.vanillaSpawns == nil) then
        global.vanillaSpawns = {}
    end

    -- This keeps a list of any player that has shared their base.
    -- Each entry contains information about if it's open, spawn pos, and players in the group.
    if (global.sharedSpawns == nil) then
        global.sharedSpawns = {}
    end

    -- This seems to be unused right now, but I had plans to re-use spawn points in the past.
    -- if (global.unusedSpawns == nil) then
    --     global.unusedSpawns = {}
    -- end

    -- Each player has an option to change their respawn which has a cooldown when used.
    -- Other similar abilities/functions that require cooldowns could be added here.
    if (global.playerCooldowns == nil) then
        global.playerCooldowns = {}
    end

    -- List of players in the "waiting room" for a buddy spawn.
    -- They show up in the list to select when doing a buddy spawn.
    if (global.waitingBuddies == nil) then
        global.waitingBuddies = {}
    end

    -- Players who have made a spawn choice get put into this list while waiting.
    -- An on_tick event checks when it expires and then places down the base resources, and teleports the player.
    -- Go look at DelayedSpawnOnTick() for more info.
    if (global.delayedSpawns == nil) then
        global.delayedSpawns = {}
    end

    -- This is what I use to communicate a buddy spawn request between the buddies.
    -- This contains information of who is asking, and what options were selected.
    if (global.buddySpawnOptions == nil) then
        global.buddySpawnOptions = {}
    end

    -- Name a new force to be the default force.
    -- This is what any new player is assigned to when they join, even before they spawn.
    local main_force = game.create_force(MAIN_FORCE)
    main_force.set_spawn_position({x=0,y=0}, GAME_SURFACE_NAME)
    
    -- Share vision with other forces.
    if ENABLE_SHARED_TEAM_VISION then
        game.forces[MAIN_FORCE].share_chart = true
    end

    if ENABLE_RESEARCH_QUEUE then
        game.forces[MAIN_FORCE].research_queue_enabled = true
    end

    -- No PVP. This is where you would change things if you want PVP I guess.
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

function QueuePlayerForDelayedSpawn(playerName, spawn, moatEnabled, vanillaSpawn)
    
    -- If we get a valid spawn point, setup the area
    if ((spawn.x ~= 0) and (spawn.y ~= 0)) then
        global.uniqueSpawns[playerName] = {pos=spawn,moat=moatEnabled,vanilla=vanillaSpawn}

        local delay_spawn_seconds = 5*(math.ceil(ENFORCE_LAND_AREA_TILE_DIST/CHUNK_SIZE))

        game.players[playerName].print("Generating your spawn now, please wait a few for " .. delay_spawn_seconds .. " seconds...")
        game.players[playerName].surface.request_to_generate_chunks(spawn, 4)
        delayedTick = game.tick + delay_spawn_seconds*TICKS_PER_SECOND
        table.insert(global.delayedSpawns, {playerName=playerName, pos=spawn, moat=moatEnabled, vanilla=vanillaSpawn, delayedTick=delayedTick})

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
                        SendPlayerToNewSpawnAndCreateIt(delayedSpawn)
                    end
                    table.remove(global.delayedSpawns, i)
                end
            end
        end
    end
end

function SendPlayerToNewSpawnAndCreateIt(delayedSpawn)

    -- DOUBLE CHECK and make sure the area is super safe.
    ClearNearbyEnemies(delayedSpawn.pos, SAFE_AREA_TILE_DIST, game.surfaces[GAME_SURFACE_NAME])

    if (not delayedSpawn.vanilla) then

        -- Create the spawn resources here
        local water_data = OARC_CFG.water
        CreateWaterStrip(game.surfaces[GAME_SURFACE_NAME],
                        {x=delayedSpawn.pos.x+water_data.x_offset, y=delayedSpawn.pos.y+water_data.y_offset},
                        water_data.length)
        CreateWaterStrip(game.surfaces[GAME_SURFACE_NAME],
                        {x=delayedSpawn.pos.x+water_data.x_offset, y=delayedSpawn.pos.y+water_data.y_offset+1},
                        water_data.length)
        GenerateStartingResources(game.surfaces[GAME_SURFACE_NAME], delayedSpawn.pos)

    end

    -- Send the player to that position
    local player = game.players[delayedSpawn.playerName]
    player.teleport(delayedSpawn.pos, GAME_SURFACE_NAME)
    GivePlayerStarterItems(game.players[delayedSpawn.playerName])

    -- Chart the area.
    ChartArea(player.force, delayedSpawn.pos, math.ceil(ENFORCE_LAND_AREA_TILE_DIST/CHUNK_SIZE), player.surface)

    if (player.gui.center.wait_for_spawn_dialog ~= nil) then
        player.gui.center.wait_for_spawn_dialog.destroy()
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
        if ENABLE_RESEARCH_QUEUE then
            newForce.research_queue_enabled = true
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

-- Function to generate some map_gen_settings.starting_points
-- You should only use this at the start of the game really.
function CreateVanillaSpawns(count, spacing)

    local points = {}

    -- Get an ODD number from the square of the input count.
    -- Always rounding up so we don't end up with less points that requested.
    local sqrt_count = math.ceil(math.sqrt(count))
    if (sqrt_count % 2 == 0) then
        sqrt_count = sqrt_count + 1
    end

    -- Need to know how much to offset the grid.
    local sqrt_half = math.floor((sqrt_count-1)/2)
    log("sqrt_half " .. sqrt_half)

    if (sqrt_count < 1) then
        DebugPrint("CreateVanillaSpawns less than 1!!")
        return
    end

    if (global.vanillaSpawns == nil) then
        global.vanillaSpawns = {}
    end

    -- This should give me points centered around 0,0 I think.
    for i=-sqrt_half,sqrt_half,1 do
        for j=-sqrt_half,sqrt_half,1 do
            if (i~=0 or j~=0) then -- EXCEPT don't put 0,0
                table.insert(points, {x=i*spacing,y=j*spacing})
                table.insert(global.vanillaSpawns, {x=i*spacing,y=j*spacing})
            end
        end
    end

    -- Do something with the return value.
    return points
end

-- Useful when combined with something like CreateVanillaSpawns
-- Where it helps ensure ALL chunks generated use new map_gen_settings.
function DeleteAllChunksExceptCenter(surface)
    -- Delete the starting chunks that make it into the game before settings are changed.
    for chunk in surface.get_chunks() do
        -- Don't delete the chunk that might contain players lol.
        -- This is really only a problem for launching AS the host. Not headless
        if ((chunk.x ~= 0) and (chunk.y ~= 0)) then
            surface.delete_chunk({chunk.x, chunk.y})
        end
    end
end

