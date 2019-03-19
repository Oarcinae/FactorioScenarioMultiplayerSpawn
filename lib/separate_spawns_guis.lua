-- separate_spawns_guis.lua
-- Nov 2016

-- I made a separate file for all the GUI related functions

require("lib/separate_spawns")

local SPAWN_GUI_MAX_WIDTH = 500
local SPAWN_GUI_MAX_HEIGHT = 1000

-- Use this for testing shared spawns...
-- local sharedSpawnExample1 = {openAccess=true,
--                             position={x=50,y=50},
--                             players={"ABC", "DEF"}}
-- local sharedSpawnExample2 = {openAccess=false,
--                             position={x=200,y=200},
--                             players={"ABC", "DEF"}}
-- local sharedSpawnExample3 = {openAccess=true,
--                             position={x=400,y=400},
--                             players={"A", "B", "C", "D"}}
-- global.sharedSpawns = {testName1=sharedSpawnExample1,
--                        testName2=sharedSpawnExample2,
--                        Oarc=sharedSpawnExample3}


-- A display gui message
-- Meant to be display the first time a player joins.
function DisplayWelcomeTextGui(player)
    if (TableLength(player.gui.center.children) > 0) then
        DebugPrint("DisplayWelcomeTextGui called while some other dialog is already displayed!")
        return
    end
    player.gui.center.add{name = "welcome_msg",
                            type = "frame",
                            direction = "vertical",
                            caption=global.welcome_msg_title}
    local wGui = player.gui.center.welcome_msg

    wGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    wGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT

    -- Start with server message.
    AddLabel(wGui, "server_msg_lbl1", SERVER_MSG, my_label_style)
    AddLabel(wGui, "contact_info_msg_lbl1", CONTACT_MSG, my_label_style)
    AddSpacer(wGui, "server_msg_spacer1")

    -- Informational message about the scenario
    AddLabel(wGui, "scenario_info_msg_lbl1", SCENARIO_INFO_MSG, my_label_style)
    AddSpacer(wGui, "scenario_info_msg_spacer1")

    -- Warning about spawn creation time
    AddLabel(wGui, "spawn_time_msg_lbl1", SPAWN_WARN_MSG, my_warning_style)
    local button_flow = wGui.add{type = "flow"}
    button_flow.style.horizontal_align = "right"
    button_flow.style.horizontally_stretchable = true
    button_flow.add{name = "welcome_okay_btn",
                    type = "button",
                    caption="I Understand",
                    style = "confirm_button"}
    

end


-- Handle the gui click of the welcome msg
function WelcomeTextGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (buttonClicked == "welcome_okay_btn") then
        if (player.gui.center.welcome_msg ~= nil) then
            player.gui.center.welcome_msg.destroy()
        end
        DisplaySpawnOptions(player)
    end
end


-- Display the spawn options and explanation
function DisplaySpawnOptions(player)
    if (player == nil) then
        DebugPrint("DisplaySpawnOptions with no valid player...")
        return
    end

    if (player.gui.center.spawn_opts ~= nil) then
        DebugPrint("Tried to display spawn options when it was already displayed!")
        return
    end
    player.gui.center.add{name = "spawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Spawn Options"}
    local sGui = player.gui.center.spawn_opts
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    local warn_msg = "Click the INFO button in the top left to learn more about this scenario! This is your ONLY chance to choose a spawn option. Choose carefully..."
    AddLabel(sGui, "warning_lbl1", warn_msg, my_warning_style)
    AddLabel(sGui, "spawn_msg_lbl1", SPAWN_MSG1, my_label_style)

    -- Button and message about the regular vanilla spawn
    if ENABLE_DEFAULT_SPAWN then
        sGui.add{name = "default_spawn_btn",
                    type = "button",
                    caption="Vanilla Spawn"}
        local normal_spawn_text = "This is the default spawn behavior of a vanilla game. You join the default team in the center of the map."
        AddLabel(sGui, "normal_spawn_lbl1", normal_spawn_text, my_label_style)
        -- AddSpacerLine(sGui, "normal_spawn_spacer")
    end

    -- The main spawning options. Solo near and solo far.
    -- If enable, you can also choose to be on your own team.
    local soloSpawnFlow = sGui.add{name = "spawn_solo_flow",
                                    type = "frame",
                                    direction="vertical",
                                    style = "bordered_frame"}
    
    -- Radio buttons to pick your team.
    if (ENABLE_SEPARATE_TEAMS) then
        soloSpawnFlow.add{name = "isolated_spawn_main_team_radio",
                        type = "radiobutton",
                        caption="Join Main Team (shared research)",
                        state=true}                  
        soloSpawnFlow.add{name = "isolated_spawn_new_team_radio",
                        type = "radiobutton",
                        caption="Create Your Own Team (own research tree)",
                        state=false}
    end

    -- OPTIONS frame
    AddLabel(soloSpawnFlow, "options_spawn_lbl1",
        "Additional spawn options can be selected here. Not all are compatible with each other.", my_label_style)

    -- Allow players to spawn with a moat around their area.
    if (SPAWN_MOAT_CHOICE_ENABLED) then
        soloSpawnFlow.add{name = "isolated_spawn_moat_option_checkbox",
                        type = "checkbox",
                        caption="Surround your spawn with a moat",
                        state=false}
    end
    if (ENABLE_VANILLA_SPAWNS) then
        soloSpawnFlow.add{name = "isolated_spawn_vanilla_option_checkbox",
                        type = "checkbox",
                        caption="Use a pre-set vanilla spawn point",
                        state=false}
    end

    -- Isolated spawn options. The core gameplay of this scenario.
    local soloSpawnbuttons = soloSpawnFlow.add{name = "spawn_solo_flow",
                                                type = "flow",
                                                direction="horizontal"}
    soloSpawnbuttons.style.horizontal_align = "center"
    soloSpawnbuttons.style.horizontally_stretchable = true
    soloSpawnbuttons.add{name = "isolated_spawn_near",
                    type = "button",
                    caption="Solo Spawn (Near)",
                    style = "confirm_button"}
    soloSpawnbuttons.add{name = "isolated_spawn_far",
                    type = "button",
                    caption="Solo Spawn (Far)",
                    style = "confirm_button"}
    AddLabel(soloSpawnFlow, "isolated_spawn_lbl1",
        "You are spawned in a new area, with some starting resources.", my_label_style)


    -- Spawn options to join another player's base.
    local sharedSpawnFrame = sGui.add{name = "spawn_shared_flow",
                                    type = "frame",
                                    direction="vertical",
                                    style = "bordered_frame"}
    if ENABLE_SHARED_SPAWNS then
        local numAvailSpawns = GetNumberOfAvailableSharedSpawns()
        if (numAvailSpawns > 0) then
            sharedSpawnFrame.add{name = "join_other_spawn",
                            type = "button",
                            caption="Join Someone (" .. numAvailSpawns .. " available)"}
            local join_spawn_text = "You are spawned in someone else's base. This requires at least 1 person to have allowed access to their base. This choice is final and you will not be able to create your own spawn later."
            AddLabel(sharedSpawnFrame, "join_other_spawn_lbl1", join_spawn_text, my_label_style)
        else
            AddLabel(sharedSpawnFrame, "join_other_spawn_lbl1", "There are currently no shared bases availble to spawn at.", my_label_style)
            sharedSpawnFrame.add{name = "join_other_spawn_check",
                            type = "button",
                            caption="Check Again"}
        end
    else
        AddLabel(sharedSpawnFrame, "join_other_spawn_lbl1",
            "Shared spawns are disabled in this mode.", my_warning_style)
    end

    -- Awesome buddy spawning system
    local buddySpawnFrame = sGui.add{name = "spawn_buddy_flow",
                                    type = "frame",
                                    direction="vertical",
                                    style = "bordered_frame"}

    if ENABLE_SHARED_SPAWNS and ENABLE_BUDDY_SPAWN then
        -- AddSpacerLine(buddySpawnFrame, "buddy_spawn_msg_spacer")
        buddySpawnFrame.add{name = "buddy_spawn",
                        type = "button",
                        caption="Buddy Spawn"}
        AddLabel(buddySpawnFrame, "buddy_spawn_lbl1",
            "The buddy system requires 2 players in this menu at the same time, you spawn beside each other, each with your own resources.", my_label_style)
    end

    -- Some final notes
    if (MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN > 0) then
        AddLabel(sGui, "max_players_lbl2",
                "If you create your own spawn point you can allow up to " .. MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN-1 .. " other online players to join.",
                my_note_style)
    end
    local spawn_distance_notes="Near spawn is between " .. NEAR_MIN_DIST .. "-" .. NEAR_MAX_DIST ..  " chunks away from the center of the map.\n"..
    "Far spawn is between " .. FAR_MIN_DIST .. "-" .. FAR_MAX_DIST ..  " chunks away from the center of the map.\n"..
    "Solo spawns are dangerous! Expect a fight to reach other players."
    AddLabel(sGui, "note_lbl1", spawn_distance_notes, my_note_style)
end


-- This just updates the radio buttons/checkboxes when players click them.
function SpawnOptsRadioSelect(event)
    if not (event and event.element and event.element.valid) then return end
    local elemName = event.element.name

    if (elemName == "isolated_spawn_main_team_radio") then
        event.element.parent.isolated_spawn_new_team_radio.state=false
    elseif (elemName == "isolated_spawn_new_team_radio") then
        event.element.parent.isolated_spawn_main_team_radio.state=false
    end

    if (elemName == "buddy_spawn_main_team_radio") then
        event.element.parent.buddy_spawn_new_team_radio.state=false
        event.element.parent.buddy_spawn_buddy_team_radio.state=false
    elseif (elemName == "buddy_spawn_new_team_radio") then
        event.element.parent.buddy_spawn_main_team_radio.state=false
        event.element.parent.buddy_spawn_buddy_team_radio.state=false
    elseif (elemName == "buddy_spawn_buddy_team_radio") then
        event.element.parent.buddy_spawn_main_team_radio.state=false
        event.element.parent.buddy_spawn_new_team_radio.state=false
    end

    if (elemName == "isolated_spawn_moat_option_checkbox") then
        event.element.parent.isolated_spawn_vanilla_option_checkbox.state = false;
    elseif (elemName == "isolated_spawn_vanilla_option_checkbox") then
        event.element.parent.isolated_spawn_moat_option_checkbox.state = false;
    end
end


-- Handle the gui click of the spawn options
function SpawnOptsGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.center.spawn_opts == nil) then
        return -- Gui event unrelated to this gui.
    end

    local pgcs = player.gui.center.spawn_opts

    local joinMainTeamRadio, joinOwnTeamRadio, moatChoice = false

    -- Check if a valid button on the gui was pressed
    -- and delete the GUI
    if ((elemName == "default_spawn_btn") or
        (elemName == "isolated_spawn_near") or
        (elemName == "isolated_spawn_far") or
        (elemName == "join_other_spawn") or
        (elemName == "buddy_spawn") or
        (elemName == "join_other_spawn_check")) then

        if (ENABLE_SEPARATE_TEAMS) then
            joinMainTeamRadio =
                pgcs.spawn_solo_flow.isolated_spawn_main_team_radio.state
            joinOwnTeamRadio =
                pgcs.spawn_solo_flow.isolated_spawn_new_team_radio.state
        else
            joinMainTeamRadio = true
            joinOwnTeamRadio = false
        end
        if (SPAWN_MOAT_CHOICE_ENABLED) then
            moatChoice = 
                pgcs.spawn_solo_flow.isolated_spawn_moat_option_checkbox.state
        end
        if (ENABLE_VANILLA_SPAWNS) then
            vanillaChoice = 
                pgcs.spawn_solo_flow.isolated_spawn_vanilla_option_checkbox.state 
        end
        pgcs.destroy()   
    else       
        return -- Do nothing, no valid element item was clicked.
    end

    if (elemName == "default_spawn_btn") then
        GivePlayerStarterItems(player)
        ChangePlayerSpawn(player, player.force.get_spawn_position(GAME_SURFACE_NAME))
        SendBroadcastMsg(player.name .. " is joining the main force!")
        ChartArea(player.force, player.position, math.ceil(ENFORCE_LAND_AREA_TILE_DIST/CHUNK_SIZE), player.surface)
        -- Create the button at the top left for setting respawn point and sharing base.
        CreateSpawnCtrlGui(player)

    elseif ((elemName == "isolated_spawn_near") or (elemName == "isolated_spawn_far")) then

        -- Create a new spawn point
        local newSpawn = {x=0,y=0}

        -- Create a new force for player if they choose that radio button
        if ENABLE_SEPARATE_TEAMS and joinOwnTeamRadio then
            local newForce = CreatePlayerCustomForce(player)
        end

        -- Find an unused vanilla spawn
        if (vanillaChoice) then
            rand_index = math.random(#global.vanillaSpawns)
            newSpawn.x = global.vanillaSpawns[rand_index].x
            newSpawn.y = global.vanillaSpawns[rand_index].y
            table.remove(global.vanillaSpawns, rand_index)

        -- Default OARC-type pre-set layout spawn.
        else
            -- Find coordinates of a good place to spawn
            if (elemName == "isolated_spawn_far") then
                newSpawn = FindUngeneratedCoordinates(FAR_MIN_DIST,FAR_MAX_DIST, player.surface)
            elseif (elemName == "isolated_spawn_near") then
                newSpawn = FindUngeneratedCoordinates(NEAR_MIN_DIST,NEAR_MAX_DIST, player.surface)
            end
        end

        -- If that fails, find a random map edge in a rand direction.
        if ((newSpawn.x == 0) and (newSpawn.x == 0)) then
            newSpawn = FindMapEdge(GetRandomVector(), player.surface)
            DebugPrint("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
        end

        -- Create that player's spawn in the global vars
        ChangePlayerSpawn(player, newSpawn)
        
        -- Send the player there
        QueuePlayerForDelayedSpawn(player.name, newSpawn, moatChoice, vanillaChoice)
        if (elemName == "isolated_spawn_near") then
            SendBroadcastMsg(player.name .. " is joining the game from a distance!")
        elseif (elemName == "isolated_spawn_far") then
            SendBroadcastMsg(player.name .. " is joining the game from a great distance!")
        end

        -- Create the button at the top left for setting respawn point and sharing base.
        CreateSpawnCtrlGui(player)

        player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!")
        player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!")
        player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!!")

    elseif (elemName == "join_other_spawn") then
        DisplaySharedSpawnOptions(player)

    -- Provide a way to refresh the gui to check if people have shared their
    -- bases.
    elseif (elemName == "join_other_spawn_check") then
        DisplaySpawnOptions(player)

    -- Hacky buddy spawn system
    elseif (elemName == "buddy_spawn") then
        table.insert(global.waitingBuddies, player.name)
        SendBroadcastMsg(player.name .. " is looking for a buddy.")

        DisplayBuddySpawnOptions(player)
    end
end


-- Display the spawn options and explanation
function DisplaySharedSpawnOptions(player)
    player.gui.center.add{name = "shared_spawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Available Bases to Join:"}

    local shGuiFrame = player.gui.center.shared_spawn_opts
    local shGui = shGuiFrame.add{type="scroll-pane", name="spawns_scroll_pane", caption=""}
    ApplyStyle(shGui, my_fixed_width_style)
    shGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    shGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    shGui.horizontal_scroll_policy = "never"


    for spawnName,sharedSpawn in pairs(global.sharedSpawns) do
        if (sharedSpawn.openAccess and
            (game.players[spawnName] ~= nil) and
            game.players[spawnName].connected) then
            local spotsRemaining = MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN - GetOnlinePlayersAtSharedSpawn(spawnName)
            if (MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN == 0) then
                shGui.add{type="button", caption=spawnName, name=spawnName}
            elseif (spotsRemaining > 0) then
                shGui.add{type="button", caption=spawnName .. " (" .. spotsRemaining .. " spots remaining)", name=spawnName}
            end
            if (shGui.spawnName ~= nil) then
                -- AddSpacer(buddyGui, spawnName .. "spacer_lbl")
                ApplyStyle(shGui[spawnName], my_small_button_style)
            end
        end
    end


    shGui.add{name = "shared_spawn_cancel",
                    type = "button",
                    caption="Cancel (Return to Previous Options)",
                    style = "back_button"}
end

-- Handle the gui click of the shared spawn options
function SharedSpwnOptsGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name  

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (event.element.parent) then
        if (event.element.parent.name ~= "spawns_scroll_pane") then
            return
        end
    end

    -- Check for cancel button, return to spawn options
    if (buttonClicked == "shared_spawn_cancel") then
        DisplaySpawnOptions(player)
        if (player.gui.center.shared_spawn_opts ~= nil) then
            player.gui.center.shared_spawn_opts.destroy()
        end

    -- Else check for which spawn was selected
    -- If a spawn is removed during this time, the button will not do anything
    else
        for spawnName,sharedSpawn in pairs(global.sharedSpawns) do
            if ((buttonClicked == spawnName) and
                (game.players[spawnName] ~= nil) and
                (game.players[spawnName].connected)) then
                
                -- Add the player to that shared spawns join queue.
                if (global.sharedSpawns[spawnName].joinQueue == nil) then
                    global.sharedSpawns[spawnName].joinQueue = {}
                end
                table.insert(global.sharedSpawns[spawnName].joinQueue, player.name)

                -- Clear the shared spawn options gui.
                if (player.gui.center.shared_spawn_opts ~= nil) then
                    player.gui.center.shared_spawn_opts.destroy()
                end

                -- Display wait menu with cancel button.
                DisplaySharedSpawnJoinWaitMenu(player)

                -- Tell other player they are requesting a response.
                game.players[spawnName].print(player.name .. " is requesting to join your base!")
                break
            end
        end
    end
end

function DisplaySharedSpawnJoinWaitMenu(player)

    player.gui.center.add{name = "join_shared_spawn_wait_menu",
                            type = "frame",
                            direction = "vertical",
                            caption="Waiting for spawn owner to respond..."}
    local sGui = player.gui.center.join_shared_spawn_wait_menu
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(sGui, "warning_lbl1", "You will spawn once the host selects yes...", my_warning_style)   
    sGui.add{name = "cancel_shared_spawn_wait_menu",
                    type = "button",
                    caption="Cancel (Return to starting spawn options)",
                    style = "back_button"}
end

-- Handle the gui click of the buddy wait menu
function SharedSpawnJoinWaitMenuClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.center.join_shared_spawn_wait_menu == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Check if player is cancelling the request.
    if (elemName == "cancel_shared_spawn_wait_menu") then
        player.gui.center.join_shared_spawn_wait_menu.destroy() 
        DisplaySpawnOptions(player)
        
        -- Find and remove the player from the joinQueue they were in.
        for spawnName,sharedSpawn in pairs(global.sharedSpawns) do
            if (sharedSpawn.joinQueue ~= nil) then
                for index,requestingPlayer in pairs(sharedSpawn.joinQueue) do
                    if (requestingPlayer == player.name) then
                        table.remove(global.sharedSpawns[spawnName].joinQueue, index)
                        game.players[spawnName].print(player.name .. " cancelled their request to join your spawn.")
                        return
                    end
                end
            end
        end

        DebugPrint("ERROR! Failed to remove player from joinQueue!")
        player.print("ERROR! Failed to remove player from joinQueue!")
    end
end


function CreateSpawnCtrlGui(player)
  if player and (player.gui.top.spwn_ctrls == nil) then
      player.gui.top.add{name="spwn_ctrls", type="button", caption="Spawn Ctrl"}
  end   
end


local function IsSharedSpawnActive(player)
    if ((global.sharedSpawns[player.name] == nil) or
        (global.sharedSpawns[player.name].openAccess == false)) then
        return false
    else
        return true
    end
end


-- Get a random warp point to go to
function GetRandomSpawnPoint()
    local numSpawnPoints = TableLength(global.sharedSpawns)
    if (numSpawnPoints > 0) then
        local randSpawnNum = math.random(1,numSpawnPoints)
        local counter = 1
        for _,sharedSpawn in pairs(global.sharedSpawns) do
            if (randSpawnNum == counter) then
                return sharedSpawn.position
            end
            counter = counter + 1
        end
    end

    return {x=0,y=0}
end


-- This is a toggle function, it either shows or hides the spawn controls
function ExpandSpawnCtrlGui(player, tick)
    local spwnCtrlPanel = player.gui.left["spwn_ctrl_panel"]
    if (spwnCtrlPanel) then
        spwnCtrlPanel.destroy()
    else
        local spwnCtrlPanel = player.gui.left.add{type="frame",
                            name="spwn_ctrl_panel", caption="Spawn Controls:"}
        local spwnCtrls = spwnCtrlPanel.add{type="scroll-pane",
                            name="spwn_ctrl_panel", caption=""}
        ApplyStyle(spwnCtrls, my_fixed_width_style)
        spwnCtrls.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
        spwnCtrls.horizontal_scroll_policy = "never"

        if ENABLE_SHARED_SPAWNS then
            if (global.uniqueSpawns[player.name] ~= nil) then
                -- This checkbox allows people to join your base when they first
                -- start the game.
                spwnCtrls.add{type="checkbox", name="accessToggle",
                                caption="Allow others to join your base.",
                                state=IsSharedSpawnActive(player)}
                ApplyStyle(spwnCtrls["accessToggle"], my_fixed_width_style)
            end
        end


        -- Sets the player's custom spawn point to their current location
        if ((tick - global.playerCooldowns[player.name].setRespawn) > RESPAWN_COOLDOWN_TICKS) then
            spwnCtrls.add{type="button", name="setRespawnLocation", caption="Set New Respawn Location (1 hour cooldown)"}
            spwnCtrls["setRespawnLocation"].style.font = "default-small-semibold"

        else
            AddLabel(spwnCtrls, "respawn_cooldown_note1", "Set Respawn Cooldown Remaining: " .. formattime(RESPAWN_COOLDOWN_TICKS-(tick - global.playerCooldowns[player.name].setRespawn)), my_note_style)           
        end
        AddLabel(spwnCtrls, "respawn_cooldown_note2", "This will set your respawn point to your current location.", my_note_style)

        -- Display a list of people in the join queue for your base.
        if (ENABLE_SHARED_SPAWNS and IsSharedSpawnActive(player)) then
            if ((global.sharedSpawns[player.name].joinQueue ~= nil) and
                (#global.sharedSpawns[player.name].joinQueue > 0)) then


                AddLabel(spwnCtrls, "drop_down_msg_lbl1", "Select a player from the join queue:", my_label_style)
                spwnCtrls.add{name = "join_queue_dropdown",
                                type = "drop-down",
                                items = global.sharedSpawns[player.name].joinQueue}
                spwnCtrls.add{name = "accept_player_request",
                                type = "button",
                                caption="Accept"}
                spwnCtrls.add{name = "reject_player_request",
                                type = "button",
                                caption="Reject"}
            else
                AddLabel(spwnCtrls, "empty_join_queue_note1", "You have no players requesting to join you at this time.", my_note_style)
            end
            spwnCtrls.add{name = "join_queue_spacer", type = "label",
                            caption=" "}
        end
    end
end


function SpawnCtrlGuiOptionsSelect(event)
    if not (event and event.element and event.element.valid) then return end
        
    local player = game.players[event.element.player_index]
    local name = event.element.name

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    -- Handle changes to spawn sharing.
    if (name == "accessToggle") then
        if event.element.state then
            if DoesPlayerHaveCustomSpawn(player) then
                if (global.sharedSpawns[player.name] == nil) then
                    CreateNewSharedSpawn(player)
                else
                    global.sharedSpawns[player.name].openAccess = true
                end
                
                SendBroadcastMsg("New players can now join " .. player.name ..  "'s base!")
            end
        else
            if (global.sharedSpawns[player.name] ~= nil) then
                global.sharedSpawns[player.name].openAccess = false
                SendBroadcastMsg("New players can no longer join " .. player.name ..  "'s base!")
            end
        end
    end
end

function SpawnCtrlGuiClick(event) 
    if not (event and event.element and event.element.valid) then return end
        
    local player = game.players[event.element.player_index]
    local elemName = event.element.name

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (elemName == "spwn_ctrls") then
        ExpandSpawnCtrlGui(player, event.tick)
    end

    if (event.element.parent) then
        if (event.element.parent.name ~= "spwn_ctrl_panel") then
            return
        end
    end

    -- Sets a new respawn point and resets the cooldown.
    if (elemName == "setRespawnLocation") then
        if DoesPlayerHaveCustomSpawn(player) then
            ChangePlayerSpawn(player, player.position)
            ExpandSpawnCtrlGui(player, event.tick) 
            player.print("Re-spawn point updated!")
        end
    end

    -- Accept or reject pending player join requests to a shared base
    if ((elemName == "accept_player_request") or (elemName == "reject_player_request")) then

        if ((event.element.parent.join_queue_dropdown == nil) or
            (event.element.parent.join_queue_dropdown.selected_index == 0)) then
            player.print("Selected player is no longer waiting to join!")
            ExpandSpawnCtrlGui(player, event.tick) 
            return
        end

        local joinQueueIndex = event.element.parent.join_queue_dropdown.selected_index
        local joinQueuePlayerChoice = event.element.parent.join_queue_dropdown.get_item(joinQueueIndex)

        if ((game.players[joinQueuePlayerChoice] == nil) or
            (not game.players[joinQueuePlayerChoice].connected)) then
            player.print("Selected player is no longer waiting to join!")
            ExpandSpawnCtrlGui(player, event.tick) 
            return
        end

        if (elemName == "reject_player_request") then
            player.print("You rejected " .. joinQueuePlayerChoice .. "'s request to join your base.")
            SendMsg(joinQueuePlayerChoice, "Your request to join was rejected.")
            ExpandSpawnCtrlGui(player, event.tick) 
            
            -- Close the waiting players menu
            if (game.players[joinQueuePlayerChoice].gui.center.join_shared_spawn_wait_menu) then
                game.players[joinQueuePlayerChoice].gui.center.join_shared_spawn_wait_menu.destroy()
                DisplaySpawnOptions(game.players[joinQueuePlayerChoice])
            end
            
            -- Find and remove the player from the joinQueue they were in.
            for index,requestingPlayer in pairs(global.sharedSpawns[player.name].joinQueue) do
                if (requestingPlayer == joinQueuePlayerChoice) then
                    table.remove(global.sharedSpawns[player.name].joinQueue, index)
                    return
                end
            end
        
        elseif (elemName == "accept_player_request") then

            -- Find and remove the player from the joinQueue they were in.
            for index,requestingPlayer in pairs(global.sharedSpawns[player.name].joinQueue) do
                if (requestingPlayer == joinQueuePlayerChoice) then
                    table.remove(global.sharedSpawns[player.name].joinQueue, index)
                end
            end

            -- If player exists, then do stuff.
            if (game.players[joinQueuePlayerChoice]) then
                -- Send an announcement
                SendBroadcastMsg(joinQueuePlayerChoice .. " is joining " .. player.name .. "'s base!")
            
                -- Close the waiting players menu
                if (game.players[joinQueuePlayerChoice].gui.center.join_shared_spawn_wait_menu) then
                    game.players[joinQueuePlayerChoice].gui.center.join_shared_spawn_wait_menu.destroy() 
                end
            
                -- Spawn the player
                local joiningPlayer = game.players[joinQueuePlayerChoice]
                ChangePlayerSpawn(joiningPlayer, global.sharedSpawns[player.name].position)
                SendPlayerToSpawn(joiningPlayer)
                GivePlayerStarterItems(joiningPlayer)
                table.insert(global.sharedSpawns[player.name].players, joiningPlayer.name)
                joiningPlayer.force = game.players[player.name].force

                -- Create the button at the top left for setting respawn point and sharing base.
                CreateSpawnCtrlGui(joiningPlayer)
                ExpandSpawnCtrlGui(player, event.tick) 
            else
                SendBroadcastMsg(joinQueuePlayerChoice .. " left the game. What an ass.")
            end
        end
    end
end

-- Display the buddy spawn menu
function DisplayBuddySpawnOptions(player)
    player.gui.center.add{name = "buddy_spawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Buddy Spawn Options"}
    local buddyGui = player.gui.center.buddy_spawn_opts
    buddyGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    buddyGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    buddy_info_msg="To use this, make sure you and your buddy are in this menu at the same time. Only one of you must send the request. Select your buddy from the list (refresh if your buddy's name is not visible) and select your spawn options. Click one of the request buttons to send the request. The other buddy can then accept (or deny) the request. This will allow you both to spawn next to each other, each with your own spawn area. Once a buddy accepts a spawn request, it is final!"
    AddLabel(buddyGui, "buddy_info_msg", buddy_info_msg, my_label_style)
    -- AddSpacerLine(buddyGui, "buddy_info_spacer")

    buddyList = {}
    for _,buddyName in pairs(global.waitingBuddies) do
        if (buddyName ~= player.name) then
            table.insert(buddyList, buddyName)
        end
    end

    AddLabel(buddyGui, "drop_down_msg_lbl1", "First, select a buddy from the waiting list. Then choose the spawn options and send your request:", my_label_style)
    buddyGui.add{name = "waiting_buddies_dropdown",
                    type = "drop-down",
                    items = buddyList}
    buddyGui.add{name = "refresh_buddy_list",
                    type = "button",
                    caption="Refresh Buddy List"}
    -- AddSpacerLine(buddyGui, "waiting_buddies_spacer")

    -- The buddy spawning options.
    local buddySpawnFlow = buddyGui.add{name = "spawn_buddy_flow",
                                    type = "flow",
                                    direction="vertical"}
    

    -- Allow picking of teams
    if (ENABLE_SEPARATE_TEAMS) then
        buddySpawnFlow.add{name = "buddy_spawn_main_team_radio",
                        type = "radiobutton",
                        caption="Join Main Team (shared research)",
                        state=true}
        buddySpawnFlow.add{name = "buddy_spawn_new_team_radio",
                        type = "radiobutton",
                        caption="Create Your Own Team (own research tree)",
                        state=false}
        buddySpawnFlow.add{name = "buddy_spawn_buddy_team_radio",
                        type = "radiobutton",
                        caption="Create Your Own Buddy Team (buddy and you share research)",
                        state=false}
    end
    if (SPAWN_MOAT_CHOICE_ENABLED) then
        buddySpawnFlow.add{name = "buddy_spawn_moat_option_checkbox",
                        type = "checkbox",
                        caption="Surround your spawn with a moat",
                        state=false}
    end

    AddSpacer(buddyGui, "buddy_options_spacer")
    buddySpawnFlow.add{name = "buddy_spawn_request_near",
                    type = "button",
                    caption="Request Buddy Spawn (Near)"}
    buddySpawnFlow.add{name = "buddy_spawn_request_far",
                    type = "button",
                    caption="Request Buddy Spawn (Far)"}
    AddSpacerLine(buddyGui, "buddy_spawn_spacer")



    buddyGui.add{name = "buddy_spawn_cancel",
                    type = "button",
                    caption="Cancel (Return to Previous Options)",
                    style = "back_button"}

    -- Some final notes
    AddSpacerLine(buddyGui, "note_spacer1")

    if (MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN > 0) then
        AddLabel(buddyGui, "buddy_max_players_lbl1",
                "You can allow up to " .. MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN-1 .. " other online players to join.",
                my_note_style)
    end
    local spawn_distance_notes="Near spawn is between " .. NEAR_MIN_DIST .. "-" .. NEAR_MAX_DIST ..  " chunks away from the center of the map.\n"..
    "Far spawn is between " .. FAR_MIN_DIST .. "-" .. FAR_MAX_DIST ..  " chunks away from the center of the map.\n"..
    "Solo spawns are dangerous! Expect a fight to reach other players."
    AddLabel(buddyGui, "note_lbl1", spawn_distance_notes, my_note_style)
end



-- Handle the gui click of the spawn options
function BuddySpawnOptsGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.center.buddy_spawn_opts == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Just refresh the buddy list dropdown values only.
    if (elemName == "refresh_buddy_list") then 
        player.gui.center.buddy_spawn_opts.waiting_buddies_dropdown.clear_items()

        for _,buddyName in pairs(global.waitingBuddies) do
            if (player.name ~= buddyName) then
                player.gui.center.buddy_spawn_opts.waiting_buddies_dropdown.add_item(buddyName)
            end
        end
        return
    end

    -- Handle the cancel button to exit this menu
    if (elemName == "buddy_spawn_cancel") then 
        player.gui.center.buddy_spawn_opts.destroy() 
        DisplaySpawnOptions(player)

        -- Remove them from the buddy list when they cancel
        for i=#global.waitingBuddies,1,-1 do
            local name = global.waitingBuddies[i]
            if (name == player.name) then
                table.remove(global.waitingBuddies, i)
            end
        end
    end

    local joinMainTeamRadio, joinOwnTeamRadio, joinBuddyTeamRadio, moatChoice = false
    local buddyChoice = nil

    -- Handle the spawn request button clicks
    if ((elemName == "buddy_spawn_request_near") or
        (elemName == "buddy_spawn_request_far")) then

        local buddySpawnGui = player.gui.center.buddy_spawn_opts

        local dropDownIndex = buddySpawnGui.waiting_buddies_dropdown.selected_index
        if (dropDownIndex > 0) then
            buddyChoice = buddySpawnGui.waiting_buddies_dropdown.get_item(dropDownIndex)
        else
            player.print("You have not selected a valid buddy! Please try again.")
            return
        end

        local buddyIsStillWaiting = false
        for _,buddyName in pairs(global.waitingBuddies) do
            if (buddyChoice == buddyName) then
                if (game.players[buddyChoice]) then
                    buddyIsStillWaiting = true
                end
                break
            end
        end
        if (not buddyIsStillWaiting) then
            player.print("Selected buddy is no longer available! Please try again.")
            player.gui.center.buddy_spawn_opts.destroy()
            DisplayBuddySpawnOptions(player)
            return
        end

        if (ENABLE_SEPARATE_TEAMS) then
            joinMainTeamRadio = buddySpawnGui.spawn_buddy_flow.buddy_spawn_main_team_radio.state
            joinOwnTeamRadio = buddySpawnGui.spawn_buddy_flow.buddy_spawn_new_team_radio.state
            joinBuddyTeamRadio = buddySpawnGui.spawn_buddy_flow.buddy_spawn_buddy_team_radio.state
        else
            joinMainTeamRadio = true
            joinOwnTeamRadio = false
            joinBuddyTeamRadio = false
        end
        if (SPAWN_MOAT_CHOICE_ENABLED) then
            moatChoice =  buddySpawnGui.spawn_buddy_flow.buddy_spawn_moat_option_checkbox.state
        end

        -- Save the chosen spawn options somewhere for later use.
        global.buddySpawnOptions[player.name] = {joinMainTeamRadio=joinMainTeamRadio,
                                                    joinOwnTeamRadio=joinOwnTeamRadio,
                                                    joinBuddyTeamRadio=joinBuddyTeamRadio,
                                                    moatChoice=moatChoice,
                                                    buddyChoice=buddyChoice,
                                                    distChoice=elemName}

        player.gui.center.buddy_spawn_opts.destroy()   

        -- Display prompts to the players
        DisplayBuddySpawnWaitMenu(player)
        DisplayBuddySpawnRequestMenu(game.players[buddyChoice], player.name)
        if (game.players[buddyChoice].gui.center.buddy_spawn_opts ~= nil) then
            game.players[buddyChoice].gui.center.buddy_spawn_opts.destroy()
        end

        -- Remove them from the buddy list while they make up their minds.
        for i=#global.waitingBuddies,1,-1 do
            name = global.waitingBuddies[i]
            if ((name == player.name) or (name == buddyChoice)) then
                table.remove(global.waitingBuddies, i)
            end
        end

    else       
        return -- Do nothing, no valid element item was clicked.
    end
end


function DisplayBuddySpawnWaitMenu(player)

    player.gui.center.add{name = "buddy_wait_menu",
                            type = "frame",
                            direction = "vertical",
                            caption="Waiting for buddy to respond..."}
    local sGui = player.gui.center.buddy_wait_menu
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(sGui, "warning_lbl1", "You will spawn once your buddy selects yes...", my_warning_style)
    AddSpacer(sGui, "warning_spacer")    
    sGui.add{name = "cancel_buddy_wait_menu",
                    type = "button",
                    caption="Cancel (Return to starting spawn options)"}
end

-- Handle the gui click of the buddy wait menu
function BuddySpawnWaitMenuClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.center.buddy_wait_menu == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Check if player is cancelling the request.
    if (elemName == "cancel_buddy_wait_menu") then
        player.gui.center.buddy_wait_menu.destroy() 
        DisplaySpawnOptions(player)

        local buddy = game.players[global.buddySpawnOptions[player.name].buddyChoice]

        if (buddy.gui.center.buddy_request_menu ~= nil) then
            buddy.gui.center.buddy_request_menu.destroy() 
        end
        if (buddy.gui.center.buddy_spawn ~= nil) then
            buddy.gui.center.buddy_spawn_opts.destroy()
        end 
        DisplaySpawnOptions(buddy)

        buddy.print(player.name .. " cancelled their buddy request!")
    end
end

function DisplayBuddySpawnRequestMenu(player, requestingBuddyName)

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    player.gui.center.add{name = "buddy_request_menu",
                            type = "frame",
                            direction = "vertical",
                            caption="Buddy Request!"}
    local sGui = player.gui.center.buddy_request_menu
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(sGui, "warning_lbl1", requestingBuddyName .. " is requesting a buddy spawn from you!", my_warning_style)
    
    local teamText = "error!"
    if (global.buddySpawnOptions[requestingBuddyName].joinMainTeamRadio) then
        teamText = "the main team"
    elseif (global.buddySpawnOptions[requestingBuddyName].joinOwnTeamRadio) then
        teamText = "on separate teams"
    elseif (global.buddySpawnOptions[requestingBuddyName].joinBuddyTeamRadio) then
        teamText = "a buddy team"
    end

    local moatText = " "
    if (global.buddySpawnOptions[requestingBuddyName].moatChoice) then
        moatText = " surrounded by a moat "
    end

    local distText = "error!"
    if (global.buddySpawnOptions[requestingBuddyName].distChoice == "buddy_spawn_request_near") then
        distText = "near to the center of the map!"
    elseif (global.buddySpawnOptions[requestingBuddyName].distChoice == "buddy_spawn_request_far") then
        distText = "far from the center of the map!"
    end


    local requestText = requestingBuddyName .. " would like to join " .. teamText .. " next to you" .. moatText .. distText
    AddLabel(sGui, "note_lbl1", requestText, my_warning_style)
    AddSpacer(sGui, "note_spacer1")  


    sGui.add{name = "accept_buddy_request",
                    type = "button",
                    caption="Accept"}
    sGui.add{name = "decline_buddy_request",
                    type = "button",
                    caption="Decline"}
end

-- Handle the gui click of the buddy request menu
function BuddySpawnRequestMenuClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name
    local requesterName = nil
    local requesterOptions = {}

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.center.buddy_request_menu == nil) then
        return -- Gui event unrelated to this gui.
    end



    -- Check if it's a button press and lookup the matching buddy info
    if ((elemName == "accept_buddy_request") or (elemName == "decline_buddy_request")) then
        for name,opts in pairs(global.buddySpawnOptions) do
            if (opts.buddyChoice == player.name) then
                requesterName = name
                requesterOptions = opts
            end
        end
        
        if (requesterName == nil) then
            player.print("Error! Invalid buddy info...")
            DebugPrint("Error! Invalid buddy info...")

            player.gui.center.buddy_request_menu.destroy() 
            DisplaySpawnOptions(player)
        end
    else
        return -- Not a button click
    end

    -- Handle player accepted
    if (elemName == "accept_buddy_request") then

        if (game.players[requesterName].gui.center.buddy_wait_menu ~= nil) then
            game.players[requesterName].gui.center.buddy_wait_menu.destroy() 
        end
        if (player.gui.center.buddy_request_menu ~= nil) then
            player.gui.center.buddy_request_menu.destroy()
        end 

        -- Create a new spawn point
        local newSpawn = {x=0,y=0}

        -- Create a new force for each player if they chose that option
        if requesterOptions.joinOwnTeamRadio then
            local newForce = CreatePlayerCustomForce(player)
            local buddyForce = CreatePlayerCustomForce(game.players[requesterName])

        -- Create a new force for the combined players if they chose that option
        elseif requesterOptions.joinBuddyTeamRadio then
            local buddyForce = CreatePlayerCustomForce(game.players[requesterName])
            player.force = buddyForce
        end

        -- Find coordinates of a good place to spawn
        if (requesterOptions.distChoice == "buddy_spawn_request_far") then
            newSpawn = FindUngeneratedCoordinates(FAR_MIN_DIST,FAR_MAX_DIST, player.surface)
        elseif (requesterOptions.distChoice == "buddy_spawn_request_near") then
            newSpawn = FindUngeneratedCoordinates(NEAR_MIN_DIST,NEAR_MAX_DIST, player.surface)
        end

        -- If that fails, find a random map edge in a rand direction.
        if ((newSpawn.x == 0) and (newSpawn.x == 0)) then
            newSpawn = FindMapEdge(GetRandomVector(), player.surface)
            DebugPrint("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
        end

        -- Create that spawn in the global vars
        local buddySpawn = {x=0,y=0}
        if (requesterOptions.moatChoice) then
            buddySpawn = {x=newSpawn.x+(ENFORCE_LAND_AREA_TILE_DIST*2)+10, y=newSpawn.y}
        else
            buddySpawn = {x=newSpawn.x+(ENFORCE_LAND_AREA_TILE_DIST*2), y=newSpawn.y}
        end
        ChangePlayerSpawn(player, newSpawn)
        ChangePlayerSpawn(game.players[requesterName], buddySpawn)
        
        -- Send the player there
        QueuePlayerForDelayedSpawn(player.name, newSpawn, requesterOptions.moatChoice, false)
        QueuePlayerForDelayedSpawn(requesterName, buddySpawn, requesterOptions.moatChoice, false)
        SendBroadcastMsg(requesterName .. " and " .. player.name .. " are joining the game together!")
       
        -- Create the button at the top left for setting respawn point and sharing base.
        CreateSpawnCtrlGui(player)
        CreateSpawnCtrlGui(game.players[requesterName])

        player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!")
        player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!")
        player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!!")
        game.players[requesterName].print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!")
        game.players[requesterName].print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!")
        game.players[requesterName].print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!!")


    end

    -- Check if player is cancelling the request.
    if (elemName == "decline_buddy_request") then
        player.gui.center.buddy_request_menu.destroy() 
        DisplaySpawnOptions(player)

        local requesterBuddy = game.players[requesterName]

        if (requesterBuddy.gui.center.buddy_wait_menu ~= nil) then
            requesterBuddy.gui.center.buddy_wait_menu.destroy() 
        end
        if (requesterBuddy.gui.center.buddy_spawn ~= nil) then
            requesterBuddy.gui.center.buddy_spawn_opts.destroy()
        end 
        DisplaySpawnOptions(requesterBuddy)

        requesterBuddy.print(player.name .. " declined your buddy request!")
    end
end


function DisplayPleaseWaitForSpawnDialog(player, delay_seconds)
    
    player.gui.center.add{name = "wait_for_spawn_dialog",
                            type = "frame",
                            direction = "vertical",
                            caption="Please wait!"}
    local pleaseWaitGui = player.gui.center.wait_for_spawn_dialog
    pleaseWaitGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    pleaseWaitGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    local wait_warning_text = "Your spawn is being created now.\n"..
        "You will be teleported there in "..delay_seconds.." seconds!\n"..
        "Please standby..."

    AddLabel(pleaseWaitGui, "warning_lbl1", wait_warning_text, my_warning_style)
end