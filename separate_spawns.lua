-- Separate spawns
-- Code that handles everything regarding giving each player a separate spawn
-- Includes the GUI stuff

require("event")

-- When a new player is created, present the spawn options
-- Assign them to the main force so they can communicate with the team
-- without shouting.
function PlayerCreated(event)
    local player = game.players[event.player_index]
    player.force = MAIN_FORCE
    DisplaySpawnOptions(player)
end


-- Check if the player has a different spawn point than the default one
-- Make sure to give the default starting items
function PlayerRespawned(event)
    local player = game.players[event.player_index]

    -- If a player has an active spawn, use it.
    if (DoesPlayerHaveActiveCustomSpawn(player)) then
        player.teleport(global.playerSpawns[player.name])
    end

    -- Display the respawn continue option
    DisplayRespawnContinueOption(player)
end

-- Create the appropriate force & spawn when player selects their choice
function SpawnGuiClick(event)   
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name

    -- Only clear gui if a valid button was clicked!!
    if ((buttonClicked == "normal_spawn") or
        (buttonClicked == "isolated_spawn") or
        (buttonClicked == "isolated_spawn_far") or
        (buttonClicked == "new_force") or
        (buttonClicked == "new_force_far") or
        (buttonClicked == "respawn_continue") or
        (buttonClicked == "respawn_change") or
        (buttonClicked == "respawn_custom_team") or
        (buttonClicked == "respawn_custom_spawn") or
        (buttonClicked == "respawn_surpise") or
        (buttonClicked == "respawn_mainforce")) then

        if not global.spawnDebugEnabled then
            if (player.gui.center.spawn_opts ~= nil) then
                player.gui.center.spawn_opts.destroy()
            end
            if (player.gui.center.respawn_opts ~= nil) then
                player.gui.center.respawn_opts.destroy()
            end
            if (player.gui.center.respawn_continue_opts ~= nil) then
                player.gui.center.respawn_continue_opts.destroy()
            end
        end
    end

    -- In this option, the vanilla spawn is used and the player is
    -- part of the main force.
    if (buttonClicked == "normal_spawn") then
        player.force = MAIN_FORCE
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " joined the main force!")

    -- In this option, the player gets a separate spawn point
    -- but is still part of the main force.
    elseif ((buttonClicked == "isolated_spawn") or (buttonClicked == "isolated_spawn_far")) then
        player.force = MAIN_FORCE
        
        -- Create a new spawn point
        local newSpawn = {}
        if (buttonClicked == "isolated_spawn_far") then
            newSpawn = FindUngeneratedCoordinates(FAR_MIN_DIST,FAR_MAX_DIST)
        else
            newSpawn = FindMapEdge(GetRandomVector())
        end
        global.playerSpawns[player.name] = newSpawn
        global.activePlayerSpawns[player.name] = true
        
        SendPlayerToNewSpawnAndCreateIt(player, newSpawn)
        if (buttonClicked == "isolated_spawn") then
            SendBroadcastMsg(player.name .. " joined the main force from a distance!")
        elseif (buttonClicked == "isolated_spawn_far") then
            SendBroadcastMsg(player.name .. " joined the main force from a great distance!")
        end

    -- In this option, the player is given a new force and a 
    -- separate spawn point
    elseif ((buttonClicked == "new_force") or (buttonClicked == "new_force_far")) then

        -- Create a new force using the player's name
        local newForce = CreatePlayerCustomForce(player)
        
        -- Create a new spawn point
        local newSpawn = {}
        if (buttonClicked == "new_force_far") then
            newSpawn = FindUngeneratedCoordinates(FAR_MIN_DIST,FAR_MAX_DIST)
        else
            newSpawn = FindMapEdge(GetRandomVector())
        end
        global.playerSpawns[player.name] = newSpawn
        global.activePlayerSpawns[player.name] = true
        
        -- Set the new spawn point
        if (newForce ~= nil) then
            newForce.set_spawn_position(newSpawn, "nauvis")
        end
        
        SendPlayerToNewSpawnAndCreateIt(player, newSpawn)
        SendBroadcastMsg(player.name .. " is going it alone!")

    -- Continue to respawn on your own team at that location
    elseif (buttonClicked == "respawn_continue") then
        GivePlayerItems(player)


    -- If changing your spawn behavior
    elseif (buttonClicked == "respawn_change") then
        if (DoesPlayerHaveCustomSpawn(player)) then
            DisplayRespawnOptions(player)
        else
            DisplaySpawnOptions(player)
        end

    -- Respawn with the main force in the default location
    elseif (buttonClicked == "respawn_mainforce") then
        
        -- Remove custom force if it exists
        if (player.force.name ~= MAIN_FORCE) then
            game.merge_forces(player.name, MAIN_FORCE)
        end

        -- Deactivate the stored spawn point
        ActivatePlayerCustomSpawn(player, false)
        player.teleport(player.force.get_spawn_position("nauvis"))
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " is returning to base!")

    -- Respawn in your already generated custom spawn area on the main team
    elseif (buttonClicked == "respawn_custom_spawn") then

        -- Remove custom force if it exists
        if (player.force.name ~= MAIN_FORCE) then
            game.merge_forces(player.name, MAIN_FORCE)
        end

        -- Activate the stored spawn point
        ActivatePlayerCustomSpawn(player, true)
        SendPlayerToActiveSpawn(player)
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " is returning to their outpost!")        

    -- Respawn in your already generated custom spawn area but on your own
    -- force. This force is created new if it doesn't exist.
    elseif (buttonClicked == "respawn_custom_team") then
        
        -- Create a new force using the player's name
        local newForce = CreatePlayerCustomForce(player)

        -- Set the new spawn point
        if (newForce ~= nil) then
            newForce.set_spawn_position(global.playerSpawns[player.name], "nauvis")
        end

        -- Activate the stored spawn point
        ActivatePlayerCustomSpawn(player, true)
        SendPlayerToActiveSpawn(player)
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " is returning to their outpost alone!")   

    -- lol wut
    elseif (buttonClicked == "respawn_surpise") then
        
        -- Remove custom force if it exists
        if (player.force.name ~= MAIN_FORCE) then
            game.merge_forces(player.name, MAIN_FORCE)
        end

        -- Activate the stored spawn point
        SendPlayerToRandomSpawn(player)
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " is surprised!")   

    end
end

-- This is the main function that creates the spawn area
-- Provides resources, land and a safe zone
function GenerateChunk(event)
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

function InitSpawnGlobalsAndForces()
    -- Containes an array of all player spawns
    -- A secondary array tracks whether the character will respawn there.
    if (global.playerSpawns == nil) then
        global.playerSpawns = {}
        global.activePlayerSpawns = {}
    end

    game.create_force(MAIN_FORCE)
    game.forces[MAIN_FORCE].set_spawn_position(game.forces["player"].get_spawn_position("nauvis"), "nauvis")
    SetCeaseFireBetweenAllForces()
end

function DisplaySpawnOptions(player)
    player.gui.center.add{name = "spawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Spawn Options"}
    local spawnGui = player.gui.center.spawn_opts

    spawnGui.style.maximal_width = 450
    spawnGui.style.maximal_height = 650

    spawnGui.add{name = "warning_lbl1", type = "label",
                    caption="You can only generate one custom spawn point!"}
    spawnGui.add{name = "warning_spacer", type = "label",
                    caption=" "}
    ApplyStyle(spawnGui.warning_lbl1, my_warning_style)
    ApplyStyle(spawnGui.warning_spacer, my_label_style)

    spawnGui.add{name = "normal_spawn",
                    type = "button",
                    caption="Default Spawn"}
    spawnGui.add{name = "normal_spawn_lbl1", type = "label",
                    caption="This is the default spawn behavior of a vanilla game."}
    spawnGui.add{name = "normal_spawn_lbl2", type = "label",
                    caption="You join the default team in the center of the map."}
    spawnGui.add{name = "normal_spawn_spacer", type = "label",
                    caption=" "}
    ApplyStyle(spawnGui.normal_spawn_lbl1, my_label_style)
    ApplyStyle(spawnGui.normal_spawn_lbl2, my_label_style)
    ApplyStyle(spawnGui.normal_spawn_spacer, my_label_style)

    spawnGui.add{name = "isolated_spawn",
                    type = "button",
                    caption="Isolated Spawn"}
    spawnGui.add{name = "isolated_spawn_far",
                    type = "button",
                    caption="Isolated Spawn (Far Away)"}
    spawnGui.add{name = "isolated_spawn_lbl1", type = "label",
                    caption="You are spawned in a new area, with starting resources."}
    spawnGui.add{name = "isolated_spawn_lbl2", type = "label",
                    caption="You will still be part of the default team."}
    spawnGui.add{name = "isolated_spawn_spacer", type = "label",
                    caption=" "}
    ApplyStyle(spawnGui.isolated_spawn_lbl1, my_label_style)
    ApplyStyle(spawnGui.isolated_spawn_lbl2, my_label_style)
    ApplyStyle(spawnGui.isolated_spawn_spacer, my_label_style)


    if (ENABLE_OTHER_TEAMS) then
        spawnGui.add{name = "new_force",
                        type = "button",
                        caption="Separate Team"}
        spawnGui.add{name = "new_force_far",
                        type = "button",
                        caption="Separate Team (Far Away)"}
        spawnGui.add{name = "new_force_lbl1", type = "label",
                        caption="You are spawned in a new area, with starting resources."}
        spawnGui.add{name = "new_force_lbl2", type = "label",
                        caption="You will be on your own team. (No shared vision or research with others.)"}
        spawnGui.add{name = "new_force_lbl3", type = "label",
                        caption="Do not choose this option if you are new to the game!"}
        spawnGui.add{name = "new_force_spacer", type = "label",
                        caption=" "}
        ApplyStyle(spawnGui.new_force_lbl1, my_label_style)
        ApplyStyle(spawnGui.new_force_lbl2, my_warning_style)
        ApplyStyle(spawnGui.new_force_lbl3, my_warning_style)
        ApplyStyle(spawnGui.new_force_spacer, my_label_style)
    


        spawnGui.add{name = "note_lbl1", type = "label",
                        caption="All members of a team share map vision and research."}                            
        spawnGui.add{name = "note_lbl2", type = "label",
                        caption="To talk to someone on a different team, you need to use /s to shout."}
        spawnGui.add{name = "note_lbl3", type = "label",
                        caption="All teams are neutral. This is still a cooperative PvE game... NOT PVP!"}
        ApplyStyle(spawnGui.note_lbl1, my_note_style)
        ApplyStyle(spawnGui.note_lbl2, my_note_style)
        ApplyStyle(spawnGui.note_lbl3, my_note_style)
    end

    spawnGui.add{name = "note_lbl4", type = "label",
                    caption="Far away spawn is between " .. FAR_MIN_DIST*CHUNK_SIZE .. "-" .. FAR_MAX_DIST*CHUNK_SIZE ..  " tiles away from the center of the map."}
    spawnGui.add{name = "note_lbl5", type = "label",
                    caption="Isolated spawns are dangerous! You will have to fight to reach other players."}
    spawnGui.add{name = "note_lbl6", type = "label",
                    caption="You can change your spawn options when you die."}

    ApplyStyle(spawnGui.note_lbl4, my_note_style)
    ApplyStyle(spawnGui.note_lbl5, my_note_style)
end

function DisplayRespawnContinueOption(player)

    player.gui.center.add{name = "respawn_continue_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Respawn Options"}
    local respawnGui = player.gui.center.respawn_continue_opts

    respawnGui.style.maximal_width = 450
    respawnGui.style.maximal_height = 550

    respawnGui.add{name = "respawn_continue",
                    type = "button",
                    caption="Continue"}
    respawnGui.add{name = "respawn_continue_lbl1", type = "label",
                    caption="Continue at your current spawn location."}
    respawnGui.add{name = "respawn_continue_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_continue_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_continue_spacer, my_label_style)

    respawnGui.add{name = "respawn_change",
                    type = "button",
                    caption="Change Spawn"}
    respawnGui.add{name = "respawn_change_lbl1", type = "label",
                    caption="Allow you to change your spawn and team."}
    respawnGui.add{name = "respawn_change_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_change_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_change_spacer, my_label_style)
end

function DisplayRespawnOptions(player)

    player.gui.center.add{name = "respawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Respawn Options"}
    local respawnGui = player.gui.center.respawn_opts

    respawnGui.style.maximal_width = 450
    respawnGui.style.maximal_height = 750

    -- Basically a cancel button to avoid choosing a different spawn.
    respawnGui.add{name = "respawn_continue",
                    type = "button",
                    caption="Cancel"}
    respawnGui.add{name = "respawn_continue_lbl1", type = "label",
                    caption="Continue with current spawn."}
    respawnGui.add{name = "respawn_continue_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_continue_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_continue_spacer, my_label_style)

    respawnGui.add{name = "respawn_mainforce",
                    type = "button",
                    caption="Use Default Spawn"}
    respawnGui.add{name = "respawn_mainforce_lbl1", type = "label",
                    caption="This will join the default team."}
    respawnGui.add{name = "respawn_mainforce_lbl2", type = "label",
                    caption="If you are on another team all your research will be lost!"}
    respawnGui.add{name = "respawn_mainforce_lbl3", type = "label",
                    caption="You will spawn at the default spawn point in the center."}
    respawnGui.add{name = "respawn_mainforce_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_mainforce_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_mainforce_lbl2, my_warning_style)
    ApplyStyle(respawnGui.respawn_mainforce_lbl3, my_label_style)
    ApplyStyle(respawnGui.respawn_mainforce_spacer, my_label_style)


    respawnGui.add{name = "respawn_custom_spawn",
                    type = "button",
                    caption="Custom Spawn"}
    respawnGui.add{name = "respawn_custom_lbl1", type = "label",
                    caption="This will join the default team."}
    respawnGui.add{name = "respawn_custom_lbl2", type = "label",
                    caption="If you are on another team all your research will be lost!"}
    respawnGui.add{name = "respawn_custom_lbl3", type = "label",
                    caption="You will spawn at your previous custom spawn point."}
    respawnGui.add{name = "respawn_custom_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_custom_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_custom_lbl2, my_warning_style)
    ApplyStyle(respawnGui.respawn_custom_lbl3, my_label_style)
    ApplyStyle(respawnGui.respawn_custom_spacer, my_label_style)

    if (ENABLE_OTHER_TEAMS) then
        respawnGui.add{name = "respawn_custom_team",
                        type = "button",
                        caption="Custom Team Spawn"}
        respawnGui.add{name = "respawn_custom_team_lbl1", type = "label",
                        caption="This will join your own custom team."}
        respawnGui.add{name = "respawn_custom_team_lbl2", type = "label",
                        caption="You will have your own map vision and research tree. Use /s to talk to others."}
        respawnGui.add{name = "respawn_custom_team_lbl3", type = "label",
                        caption="You will spawn at your previous custom spawn point."}
        respawnGui.add{name = "respawn_custom_team_spacer", type = "label",
                        caption=" "}
        ApplyStyle(respawnGui.respawn_custom_team_lbl1, my_label_style)
        ApplyStyle(respawnGui.respawn_custom_team_lbl2, my_warning_style)
        ApplyStyle(respawnGui.respawn_custom_team_lbl3, my_label_style)
        ApplyStyle(respawnGui.respawn_custom_team_spacer, my_label_style)
    end

    if (global.enableRespawnSurprise == true) then
        respawnGui.add{name = "respawn_surpise",
                        type = "button",
                        caption="Surprise me!"}
    end
    
    respawnGui.add{name = "respawn_note1", type = "label",
                    caption="You cannot generate new custom spawn points."}
    ApplyStyle(respawnGui.respawn_note1, my_note_style)
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

function DoesPlayerHaveActiveCustomSpawn(player)
    if (DoesPlayerHaveCustomSpawn(player)) then
        return global.activePlayerSpawns[player.name]
    else
        return false
    end
end

function ActivatePlayerCustomSpawn(player, value)
    for name,_ in pairs(global.playerSpawns) do
        if (player.name == name) then
            global.activePlayerSpawns[player.name] = value
            break
        end
    end
end

function CreatePlayerCustomForce(player)
    local newForce = nil
    
    -- Check if force already exists
    if (game.forces[player.name] ~= nil) then
        return game.forces[player.name]

    -- Create a new force using the player's name
    elseif (TableLength(game.forces) < MAX_FORCES) then
        newForce = game.create_force(player.name)
        player.force = newForce
        SetCeaseFireBetweenAllForces()        
    else
        player.force = MAIN_FORCE
        player.print("Sorry, no new teams can be created. You were assigned to the default team instead.")
    end

    return newForce
end

function SendPlayerToNewSpawnAndCreateIt(player, spawn)
    -- Send the player to that position
    player.teleport(spawn)
    GivePlayerStarterItems(player)

    -- If we get a valid spawn point, setup the area
    if (spawn ~= {x=0,y=0}) then
        GenerateStartingResources(player)
        ClearNearbyEnemies(player, SAFE_AREA_TILE_DIST)
    end
end

function SendPlayerToActiveSpawn(player)
    if (DoesPlayerHaveActiveCustomSpawn(player)) then
        player.teleport(global.playerSpawns[player.name])
    else
        player.teleport(game.forces[MAIN_FORCE].get_spawn_position("nauvis"))
    end
end

function SendPlayerToRandomSpawn(player)
    local numSpawns = TableLength(global.playerSpawns)
    local rndSpawn = math.random(0,numSpawns)
    local counter = 0

    if (rndSpawn == 0) then
        player.teleport(game.forces[MAIN_FORCE].get_spawn_position("nauvis"))
    else
        counter = counter + 1
        for name,spawnPos in pairs(global.playerSpawns) do
            if (counter == rndSpawn) then
                player.teleport(spawnPos)
                break
            end
            counter = counter + 1
        end 
    end
end


--------------------------------------------------------------------------------
-- Register event functions
-- These must be placed after the functions that are referenced!
--------------------------------------------------------------------------------

if ENABLE_SEPARATE_SPAWNS then
    Event.register(defines.events.on_player_created, PlayerCreated)
    Event.register(defines.events.on_player_respawned, PlayerRespawned)
    Event.register(defines.events.on_gui_click, SpawnGuiClick)
    Event.register(defines.events.on_chunk_generated, GenerateChunk)
end