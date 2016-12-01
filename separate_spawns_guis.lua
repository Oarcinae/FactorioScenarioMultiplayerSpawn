-- separate_spawns_guis.lua
-- Nov 2016

-- I made a separate file for all the GUI related functions

require("separate_spawns")


-- A display gui message
-- Meant to be display the first time a player joins.
function DisplayWelcomeTextGui(player)
    player.gui.center.add{name = "welcome_msg",
                            type = "frame",
                            direction = "vertical",
                            caption="Welcome to Oarc's Server"}
    local wGui = player.gui.center.welcome_msg

    wGui.style.maximal_width = 450
    wGui.style.maximal_height = 650



    wGui.add{name = "welcome_msg_lbl1", type = "label",
                    caption=WELCOME_MSG1}
    wGui.add{name = "welcome_msg_lbl2", type = "label",
                    caption=WELCOME_MSG2}
    wGui.add{name = "welcome_msg_spacer1", type = "label",
                    caption=" "}

    ApplyStyle(wGui.welcome_msg_lbl1, my_label_style)
    ApplyStyle(wGui.welcome_msg_lbl2, my_label_style)
    ApplyStyle(wGui.welcome_msg_spacer1, my_label_style)


    wGui.add{name = "welcome_msg_lbl3", type = "label",
                    caption=WELCOME_MSG3}
    wGui.add{name = "welcome_msg_lbl4", type = "label",
                    caption=WELCOME_MSG4}
    wGui.add{name = "welcome_msg_lbl5", type = "label",
                    caption=WELCOME_MSG5}
    wGui.add{name = "welcome_msg_spacer2", type = "label",
                    caption=" "}

    ApplyStyle(wGui.welcome_msg_lbl3, my_warning_style)
    ApplyStyle(wGui.welcome_msg_lbl4, my_warning_style)
    ApplyStyle(wGui.welcome_msg_lbl5, my_warning_style)
    ApplyStyle(wGui.welcome_msg_spacer2, my_label_style)



    wGui.add{name = "welcome_okay_btn",
                    type = "button",
                    caption="I Understand"}
end


-- Handle the gui click of the welcome msg
function WelcomeTextGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name

    if (buttonClicked == "welcome_okay_btn") then
        if (player.gui.center.welcome_msg ~= nil) then
            player.gui.center.welcome_msg.destroy()
        end
        DisplaySpawnOptions(player)
    end
end


-- Display the spawn options and explanation
function DisplaySpawnOptions(player)
    player.gui.center.add{name = "spawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Spawn Options"}
    local sGui = player.gui.center.spawn_opts

    sGui.style.maximal_width = 450
    sGui.style.maximal_height = 650

    sGui.add{name = "warning_lbl1", type = "label",
                    caption="You can only generate one custom spawn point!"}
    sGui.add{name = "warning_spacer", type = "label",
                    caption=" "}
    ApplyStyle(sGui.warning_lbl1, my_warning_style)
    ApplyStyle(sGui.warning_spacer, my_label_style)

    sGui.add{name = "spawn_msg_lbl1", type = "label",
                    caption=SPAWN_MSG1}
    sGui.add{name = "spawn_msg_lbl2", type = "label",
                    caption=SPAWN_MSG2}
    sGui.add{name = "spawn_msg_lbl3", type = "label",
                    caption=SPAWN_MSG3}
    sGui.add{name = "spawn_msg_spacer", type = "label",
                    caption=" "}
    ApplyStyle(sGui.spawn_msg_lbl1, my_label_style)
    ApplyStyle(sGui.spawn_msg_lbl2, my_label_style)
    ApplyStyle(sGui.spawn_msg_lbl3, my_label_style)
    ApplyStyle(sGui.spawn_msg_spacer, my_label_style)



    sGui.add{name = "isolated_spawn_near",
                    type = "button",
                    caption="Solo Spawn (Near)"}
    sGui.add{name = "isolated_spawn_far",
                    type = "button",
                    caption="Solo Spawn (Far)"}
    sGui.add{name = "isolated_spawn_lbl1", type = "label",
                    caption="You are spawned in a new area, with some starting resources."}
    sGui.add{name = "isolated_spawn_lbl2", type = "label",
                    caption="You will still be part of the default team."}
    sGui.add{name = "isolated_spawn_spacer", type = "label",
                    caption=" "}
    ApplyStyle(sGui.isolated_spawn_lbl1, my_label_style)
    ApplyStyle(sGui.isolated_spawn_lbl2, my_label_style)
    ApplyStyle(sGui.isolated_spawn_spacer, my_label_style)



    sGui.add{name = "note_lbl1", type = "label",
                    caption="Near spawn is between " .. NEAR_MIN_DIST*CHUNK_SIZE .. "-" .. NEAR_MAX_DIST*CHUNK_SIZE ..  " tiles away from the center of the map."}
    sGui.add{name = "note_lbl2", type = "label",
                    caption="Far spawn is between " .. FAR_MIN_DIST*CHUNK_SIZE .. "-" .. FAR_MAX_DIST*CHUNK_SIZE ..  " tiles away from the center of the map."}
    sGui.add{name = "note_lbl3", type = "label",
                    caption="Isolated spawns are dangerous! Expect a fight to reach other players."}
    sGui.add{name = "note_spacer1", type = "label",
                    caption=" "}
    ApplyStyle(sGui.note_lbl1, my_note_style)
    ApplyStyle(sGui.note_lbl2, my_note_style)
    ApplyStyle(sGui.note_lbl3, my_note_style)
    ApplyStyle(sGui.note_spacer1, my_label_style)
end


-- Handle the gui click of the spawn options
function SpawnOptsGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name


    -- Check if a valid button on the gui was pressed
    -- and delete the GUI
    if ((buttonClicked == "isolated_spawn_near") or
        (buttonClicked == "isolated_spawn_far")) then

        if (player.gui.center.spawn_opts ~= nil) then
            player.gui.center.spawn_opts.destroy()
        end
    end

    if ((buttonClicked == "isolated_spawn_near") or (buttonClicked == "isolated_spawn_far")) then
        
        -- Create a new spawn point
        local newSpawn = {x=0,y=0}

        -- Find coordinates of a good place to spawn
        if (buttonClicked == "isolated_spawn_far") then
            newSpawn = FindUngeneratedCoordinates(FAR_MIN_DIST,FAR_MAX_DIST)
        elseif (buttonClicked == "isolated_spawn_near") then
            newSpawn = FindUngeneratedCoordinates(NEAR_MIN_DIST,NEAR_MAX_DIST)
        end

        -- If that fails, find a random map edge in a rand direction.
        if (newSpawn == {x=0,y=0}) then
            newSpawn = FindMapEdge(GetRandomVector())
        end

        -- Create that spawn in the global vars
        global.playerSpawns[player.name] = newSpawn
        global.activePlayerSpawns[player.name] = true
        
        -- Send the player there
        SendPlayerToNewSpawnAndCreateIt(player, newSpawn)
        if (buttonClicked == "isolated_spawn_near") then
            SendBroadcastMsg(player.name .. " joined the main force from a distance!")
        elseif (buttonClicked == "isolated_spawn_far") then
            SendBroadcastMsg(player.name .. " joined the main force from a great distance!")
        end

        player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!")
        player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!")
        player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!!")

    end
end









--------------------------------------------------------------------------------
-- UNUSED CODE
-- Either didn't work, or not used or not tested....
--------------------------------------------------------------------------------




-- Create the appropriate force & spawn when player selects their choice
-- function SpawnGuiClick(event)   
--     local player = game.players[event.player_index]
--     local buttonClicked = event.element.name

--     DebugPrint("TEST")

--     -- Only clear gui if a valid button was clicked!!
--     if ((buttonClicked == "normal_spawn") or
--         (buttonClicked == "isolated_spawn") or
--         (buttonClicked == "isolated_spawn_far") or
--         (buttonClicked == "join_other_spawn") or
--         (buttonClicked == "new_force") or
--         (buttonClicked == "new_force_far") or
--         (buttonClicked == "respawn_continue") or
--         (buttonClicked == "respawn_change") or
--         (buttonClicked == "respawn_custom_team") or
--         (buttonClicked == "respawn_custom_spawn") or
--         (buttonClicked == "respawn_surpise") or
--         (buttonClicked == "respawn_mainforce")) then

--         if not global.spawnDebugEnabled then
--             if (player.gui.center.spawn_opts ~= nil) then
--                 player.gui.center.spawn_opts.destroy()
--             end
--             if (player.gui.center.respawn_opts ~= nil) then
--                 player.gui.center.respawn_opts.destroy()
--             end
--             if (player.gui.center.respawn_continue_opts ~= nil) then
--                 player.gui.center.respawn_continue_opts.destroy()
--             end
--         end

--         if ENABLE_WARP then
--             CreateWarpGui(event)
--         end
--     end

--     -- In this option, the vanilla spawn is used and the player is
--     -- part of the main force.
--     if (buttonClicked == "normal_spawn") then
--         player.force = MAIN_FORCE
--         GivePlayerStarterItems(player)
--         SendBroadcastMsg(player.name .. " joined the main force!")
--         ChartArea(player.force, player.position, 4)

--     -- In this option, the player gets a separate spawn point
--     -- but is still part of the main force.
--     elseif ((buttonClicked == "isolated_spawn") or (buttonClicked == "isolated_spawn_far")) then
--         player.force = MAIN_FORCE
        
--         -- Create a new spawn point
--         local newSpawn = {}
--         if (buttonClicked == "isolated_spawn_far") then
--             newSpawn = FindUngeneratedCoordinates(FAR_MIN_DIST,FAR_MAX_DIST)
--         else
--             newSpawn = FindMapEdge(GetRandomVector())
--         end
--         global.playerSpawns[player.name] = newSpawn
--         global.activePlayerSpawns[player.name] = true
        
--         SendPlayerToNewSpawnAndCreateIt(player, newSpawn)
--         if (buttonClicked == "isolated_spawn") then
--             SendBroadcastMsg(player.name .. " joined the main force from a distance!")
--         elseif (buttonClicked == "isolated_spawn_far") then
--             SendBroadcastMsg(player.name .. " joined the main force from a great distance!")
--         end

--     -- In this option, the player joins an existing base.
--     -- This uses the warp module global spawns
--     elseif (buttonClicked == "join_other_spawn") then
--         player.force = MAIN_FORCE

--         global.playerSpawns[player.name] = GetRandomWarpPoint()
--         global.activePlayerSpawns[player.name] = true

--         SendPlayerToActiveSpawn(player)
--         GivePlayerStarterItems(player)
--         SendBroadcastMsg(player.name .. " is joining some random person!")


--     -- In this option, the player is given a new force and a 
--     -- separate spawn point
--     elseif ((buttonClicked == "new_force") or (buttonClicked == "new_force_far")) then

--         -- Create a new force using the player's name
--         local newForce = CreatePlayerCustomForce(player)
        
--         -- Create a new spawn point
--         local newSpawn = {}
--         if (buttonClicked == "new_force_far") then
--             newSpawn = FindUngeneratedCoordinates(FAR_MIN_DIST,FAR_MAX_DIST)
--         else
--             newSpawn = FindMapEdge(GetRandomVector())
--         end
--         global.playerSpawns[player.name] = newSpawn
--         global.activePlayerSpawns[player.name] = true
        
--         -- Set the new spawn point
--         if (newForce ~= nil) then
--             newForce.set_spawn_position(newSpawn, "nauvis")
--         end
        
--         SendPlayerToNewSpawnAndCreateIt(player, newSpawn)
--         SendBroadcastMsg(player.name .. " is going it alone!")

--     -- Continue to respawn on your own team at that location
--     elseif (buttonClicked == "respawn_continue") then
--         GivePlayerItems(player)


--     -- If changing your spawn behavior
--     elseif (buttonClicked == "respawn_change") then
--         if (DoesPlayerHaveCustomSpawn(player)) then
--             DisplayRespawnOptions(player)
--         else
--             DisplaySpawnOptions(player)
--         end

--     -- Respawn with the main force in the default location
--     elseif (buttonClicked == "respawn_mainforce") then
        
--         -- Remove custom force if it exists
--         if (player.force.name ~= MAIN_FORCE) then
--             game.merge_forces(player.name, MAIN_FORCE)
--         end

--         -- Deactivate the stored spawn point
--         ActivatePlayerCustomSpawn(player, false)
--         SendPlayerToActiveSpawn(player)
--         GivePlayerStarterItems(player)
--         SendBroadcastMsg(player.name .. " is returning to base!")

--     -- Respawn in your already generated custom spawn area on the main team
--     elseif (buttonClicked == "respawn_custom_spawn") then

--         -- Remove custom force if it exists
--         if (player.force.name ~= MAIN_FORCE) then
--             game.merge_forces(player.name, MAIN_FORCE)
--         end

--         -- Activate the stored spawn point
--         ActivatePlayerCustomSpawn(player, true)
--         SendPlayerToActiveSpawn(player)
--         GivePlayerStarterItems(player)
--         SendBroadcastMsg(player.name .. " is returning to their outpost!")        

--     -- Respawn in your already generated custom spawn area but on your own
--     -- force. This force is created new if it doesn't exist.
--     elseif (buttonClicked == "respawn_custom_team") then
        
--         -- Create a new force using the player's name
--         local newForce = CreatePlayerCustomForce(player)

--         -- Set the new spawn point
--         if (newForce ~= nil) then
--             newForce.set_spawn_position(global.playerSpawns[player.name], "nauvis")
--         end

--         -- Activate the stored spawn point
--         ActivatePlayerCustomSpawn(player, true)
--         SendPlayerToActiveSpawn(player)
--         GivePlayerStarterItems(player)
--         SendBroadcastMsg(player.name .. " is returning to their outpost alone!")   

--     -- lol wut
--     elseif (buttonClicked == "respawn_surpise") then
        
--         -- Remove custom force if it exists
--         if (player.force.name ~= MAIN_FORCE) then
--             game.merge_forces(player.name, MAIN_FORCE)
--         end

--         -- Activate the stored spawn point
--         SendPlayerToRandomSpawn(player)
--         GivePlayerStarterItems(player)
--         SendBroadcastMsg(player.name .. " is surprised!")   

--     end
-- end