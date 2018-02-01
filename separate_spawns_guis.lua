-- separate_spawns_guis.lua
-- Nov 2016

-- I made a separate file for all the GUI related functions

require("separate_spawns")

local SPAWN_GUI_MAX_WIDTH = 550
local SPAWN_GUI_MAX_HEIGHT = 800

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
    player.gui.center.add{name = "welcome_msg",
                            type = "frame",
                            direction = "vertical",
                            caption=global.welcome_msg_title}
    local wGui = player.gui.center.welcome_msg

    wGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    wGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT



    wGui.add{name = "welcome_msg_lbl1", type = "label",
                    caption=WELCOME_MSG1}
    wGui.add{name = "welcome_msg_lbl2", type = "label",
                    caption=WELCOME_MSG2}
    wGui.add{name = "welcome_msg_spacer1", type = "label",
                    caption=" "}

    ApplyStyle(wGui.welcome_msg_lbl1, my_label_style)
    ApplyStyle(wGui.welcome_msg_lbl2, my_label_style)
    ApplyStyle(wGui.welcome_msg_spacer1, my_spacer_style)

    wGui.add{name = "other_msg_lbl1", type = "label",
                    caption=OTHER_MSG1}
    wGui.add{name = "other_msg_lbl2", type = "label",
                    caption=OTHER_MSG2}
    if (OTHER_MSG3 ~= nil) then
        wGui.add{name = "other_msg_lbl3", type = "label",
                    caption=OTHER_MSG3}
        ApplyStyle(wGui.other_msg_lbl3, my_label_style)
    end
    if (OTHER_MSG4 ~= nil) then
        wGui.add{name = "other_msg_lbl4", type = "label",
                    caption=OTHER_MSG4}
        ApplyStyle(wGui.other_msg_lbl4, my_label_style)
    end
    if (OTHER_MSG5 ~= nil) then
        wGui.add{name = "other_msg_lbl5", type = "label",
                    caption=OTHER_MSG5}
        ApplyStyle(wGui.other_msg_lbl5, my_label_style)
    end
    wGui.add{name = "other_msg_spacer1", type = "label",
                    caption=" "}

    ApplyStyle(wGui.other_msg_lbl1, my_label_style)
    ApplyStyle(wGui.other_msg_lbl2, my_label_style)
    ApplyStyle(wGui.other_msg_spacer1, my_spacer_style)

    wGui.add{name = "welcome_msg_lbl3", type = "label",
                    caption=WELCOME_MSG3}
    wGui.add{name = "welcome_msg_lbl4", type = "label",
                    caption=WELCOME_MSG4}
    wGui.add{name = "welcome_msg_lbl5", type = "label",
                    caption=WELCOME_MSG5}
    wGui.add{name = "welcome_msg_lbl6", type = "label",
                    caption=WELCOME_MSG6}
    wGui.add{name = "welcome_msg_spacer2", type = "label",
                    caption=" "}

    ApplyStyle(wGui.welcome_msg_lbl3, my_warning_style)
    ApplyStyle(wGui.welcome_msg_lbl4, my_warning_style)
    ApplyStyle(wGui.welcome_msg_lbl5, my_warning_style)
    ApplyStyle(wGui.welcome_msg_lbl6, my_label_style)
    ApplyStyle(wGui.welcome_msg_spacer2, my_spacer_style)



    wGui.add{name = "welcome_okay_btn",
                    type = "button",
                    caption="I Understand"}
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
    sGui.add{name = "warning_lbl1", type = "label",
                    caption="This is your ONLY chance to choose a spawn option. Choose carefully..."}
    sGui.add{name = "warning_spacer", type = "label",
                    caption=" "}
    ApplyStyle(sGui.warning_lbl1, my_warning_style)
    ApplyStyle(sGui.warning_spacer, my_spacer_style)

    sGui.add{name = "spawn_msg_lbl1", type = "label",
                    caption=SPAWN_MSG1}
    sGui.add{name = "spawn_msg_lbl2", type = "label",
                    caption=SPAWN_MSG2}
    sGui.add{name = "spawn_msg_lbl3", type = "label",
                    caption=SPAWN_MSG3}
    sGui.add{name = "spawn_msg_spacer", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    ApplyStyle(sGui.spawn_msg_lbl1, my_label_style)
    ApplyStyle(sGui.spawn_msg_lbl2, my_label_style)
    ApplyStyle(sGui.spawn_msg_lbl3, my_label_style)
    ApplyStyle(sGui.spawn_msg_spacer, my_spacer_style)


    if ENABLE_DEFAULT_SPAWN then
        sGui.add{name = "default_spawn_btn",
                        type = "button",
                        caption="Default Spawn"}
        sGui.add{name = "normal_spawn_lbl1", type = "label",
                        caption="This is the default spawn behavior of a vanilla game."}
        sGui.add{name = "normal_spawn_lbl2", type = "label",
                        caption="You join the default team in the center of the map."}
        ApplyStyle(sGui.normal_spawn_lbl1, my_label_style)
        ApplyStyle(sGui.normal_spawn_lbl2, my_label_style)
    else
        sGui.add{name = "normal_spawn_lbl1", type = "label",
                        caption="Default spawn is disabled in this mode."}
        ApplyStyle(sGui.normal_spawn_lbl1, my_warning_style)
    end
    sGui.add{name = "normal_spawn_spacer", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    ApplyStyle(sGui.normal_spawn_spacer, my_spacer_style)


    -- The main spawning options. Solo near and solo far.
    -- If enable, you can also choose to be on your own team.
    local soloSpawnFlow = sGui.add{name = "spawn_solo_flow",
                                    type = "flow",
                                    direction="vertical"}
    

    -- Radio buttons to pick your team.
    if (ENABLE_SEPARATE_TEAMS) then
        soloSpawnFlow.add{name = "isolated_spawn_main_team_radio",
                        type = "radiobutton",
                        caption="Join Main Team (shared research)",
                        state=false}                  
        soloSpawnFlow.add{name = "isolated_spawn_new_team_radio",
                        type = "radiobutton",
                        caption="Create Your Own Team (own research tree)",
                        state=false}
    end

    -- Allow players to spawn with a moat around their area.
    if (SPAWN_MOAT_CHOICE_ENABLED) then
        soloSpawnFlow.add{name = "isolated_spawn_moat_option_checkbox",
                        type = "checkbox",
                        caption="Surround your spawn with a moat",
                        state=false}
    end

    soloSpawnFlow.add{name = "team_chat_warning_spacer", type = "label",
                caption=" "}
    ApplyStyle(soloSpawnFlow.team_chat_warning_spacer, my_spacer_style)

    soloSpawnFlow.add{name = "isolated_spawn_near",
                    type = "button",
                    caption="Solo Spawn (Near)"}
    soloSpawnFlow.add{name = "isolated_spawn_far",
                    type = "button",
                    caption="Solo Spawn (Far)"}
    
    soloSpawnFlow.add{name = "isolated_spawn_lbl1", type = "label",
                    caption="You are spawned in a new area, with some starting resources."}    
    ApplyStyle(soloSpawnFlow.isolated_spawn_lbl1, my_label_style)

    sGui.add{name = "isolated_spawn_spacer", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    ApplyStyle(sGui.isolated_spawn_spacer, my_spacer_style)


    -- Spawn options to join another player's base.
    if ENABLE_SHARED_SPAWNS then
        local numAvailSpawns = GetNumberOfAvailableSharedSpawns()
        if (numAvailSpawns > 0) then
            sGui.add{name = "join_other_spawn",
                            type = "button",
                            caption="Join Someone (" .. numAvailSpawns .. " available)"}
            sGui.add{name = "join_other_spawn_lbl1", type = "label",
                            caption="You are spawned in someone else's base."}
            sGui.add{name = "join_other_spawn_lbl2", type = "label",
                            caption="This requires at least 1 person to have allowed access to their base."}
            sGui.add{name = "join_other_spawn_lbl3", type = "label",
                            caption="This choice is final and you will not be able to create your own spawn later."}
            sGui.add{name = "join_other_spawn_spacer", type = "label",
                            caption=" "}
            ApplyStyle(sGui.join_other_spawn_lbl1, my_label_style)
            ApplyStyle(sGui.join_other_spawn_lbl2, my_label_style)
            ApplyStyle(sGui.join_other_spawn_lbl3, my_label_style)
            ApplyStyle(sGui.join_other_spawn_spacer, my_spacer_style)
        else
            sGui.add{name = "join_other_spawn_lbl1", type = "label",
                            caption="There are currently no shared bases availble to spawn at."}
            sGui.add{name = "join_other_spawn_spacer", type = "label",
                            caption=" "}
            ApplyStyle(sGui.join_other_spawn_lbl1, my_warning_style)
            ApplyStyle(sGui.join_other_spawn_spacer, my_spacer_style)
            sGui.add{name = "join_other_spawn_check",
                            type = "button",
                            caption="Check Again"}
        end
    else
        sGui.add{name = "join_other_spawn_lbl1", type = "label",
                        caption="Shared spawns are disabled in this mode."}
        ApplyStyle(sGui.join_other_spawn_lbl1, my_warning_style)
    end

    -- New awesome buddy spawning system
    if ENABLE_SHARED_SPAWNS and ENABLE_BUDDY_SPAWN then
        sGui.add{name = "buddy_spawn",
                        type = "button",
                        caption="Buddy Spawn"}
        sGui.add{name = "buddy_spawn_lbl1", type = "label",
                        caption="You spawn next to a buddy of your choosing."}
    end

    -- Some final notes
    sGui.add{name = "note_spacer1", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    sGui.add{name = "note_spacer2", type = "label",
                    caption=" "}

    if (MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN > 0) then
        sGui.add{name = "shared_spawn_note1", type = "label",
                    caption="If you create your own spawn point you can allow up to " .. MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN-1 .. " other online players to join." }
        ApplyStyle(sGui.shared_spawn_note1, my_note_style)
    end
    sGui.add{name = "note_lbl1", type = "label",
                    caption="Near spawn is between " .. NEAR_MIN_DIST*CHUNK_SIZE .. "-" .. NEAR_MAX_DIST*CHUNK_SIZE ..  " tiles away from the center of the map."}
    sGui.add{name = "note_lbl2", type = "label",
                    caption="Far spawn is between " .. FAR_MIN_DIST*CHUNK_SIZE .. "-" .. FAR_MAX_DIST*CHUNK_SIZE ..  " tiles away from the center of the map."}
    sGui.add{name = "note_lbl3", type = "label",
                    caption="Solo spawns are dangerous! Expect a fight to reach other players."}
    sGui.add{name = "note_spacer3", type = "label",
                    caption=" "}
    ApplyStyle(sGui.note_lbl1, my_note_style)
    ApplyStyle(sGui.note_lbl2, my_note_style)
    ApplyStyle(sGui.note_lbl3, my_note_style)
    ApplyStyle(sGui.note_spacer1, my_spacer_style)
    ApplyStyle(sGui.note_spacer2, my_spacer_style)
    ApplyStyle(sGui.note_spacer3, my_spacer_style)
end


-- This just updates the radio buttons when players click them.
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
                player.gui.center.spawn_opts.spawn_solo_flow.isolated_spawn_main_team_radio.state
            joinOwnTeamRadio =
                player.gui.center.spawn_opts.spawn_solo_flow.isolated_spawn_new_team_radio.state
        else
            joinMainTeamRadio = true
            joinOwnTeamRadio = false
        end
        if (SPAWN_MOAT_CHOICE_ENABLED) then
            moatChoice = 
                player.gui.center.spawn_opts.spawn_solo_flow.isolated_spawn_moat_option_checkbox.state
        end
        player.gui.center.spawn_opts.destroy()   
    else       
        return -- Do nothing, no valid element item was clicked.
    end

    if (elemName == "default_spawn_btn") then
        GivePlayerStarterItems(player)
        ChangePlayerSpawn(player, player.force.get_spawn_position(GAME_SURFACE_NAME))
        SendBroadcastMsg(player.name .. " is joining the main force!")
        ChartArea(player.force, player.position, 4, player.surface)
        -- Create the button at the top left for setting respawn point and sharing base.
        CreateSpawnCtrlGui(player)

    elseif ((elemName == "isolated_spawn_near") or (elemName == "isolated_spawn_far")) then

        -- Create a new spawn point
        local newSpawn = {x=0,y=0}

        -- Create a new force for player if they choose that radio button
        if ENABLE_SEPARATE_TEAMS and joinOwnTeamRadio then
            local newForce = CreatePlayerCustomForce(player)
        end

        -- Find coordinates of a good place to spawn
        if (elemName == "isolated_spawn_far") then
            newSpawn = FindUngeneratedCoordinates(FAR_MIN_DIST,FAR_MAX_DIST, player.surface)
        elseif (elemName == "isolated_spawn_near") then
            newSpawn = FindUngeneratedCoordinates(NEAR_MIN_DIST,NEAR_MAX_DIST, player.surface)
        end

        -- If that fails, find a random map edge in a rand direction.
        if ((newSpawn.x == 0) and (newSpawn.x == 0)) then
            newSpawn = FindMapEdge(GetRandomVector(), player.surface)
            DebugPrint("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
        end

        -- Create that spawn in the global vars
        ChangePlayerSpawn(player, newSpawn)
        
        -- Send the player there
        QueuePlayerForDelayedSpawn(player.name, newSpawn, moatChoice)
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
                shGui.add{name = spawnName .. "spacer_lbl", type = "label", caption=" "}
                ApplyStyle(shGui[spawnName], my_small_button_style)
                ApplyStyle(shGui[spawnName .. "spacer_lbl"], my_spacer_style)
            end
        end
    end


    shGui.add{name = "shared_spawn_cancel",
                    type = "button",
                    caption="Cancel (Return to Previous Options)"}
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
    sGui.add{name = "warning_lbl1", type = "label",
                    caption="You will spawn once the host selects yes..."}
    sGui.add{name = "warning_spacer", type = "label",
                    caption=" "}
    ApplyStyle(sGui.warning_lbl1, my_warning_style)
    ApplyStyle(sGui.warning_spacer, my_spacer_style)
    
    sGui.add{name = "cancel_shared_spawn_wait_menu",
                    type = "button",
                    caption="Cancel (Return to starting spawn options)"}
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
                spwnCtrls["accessToggle"].style.top_padding = 10
                spwnCtrls["accessToggle"].style.bottom_padding = 10
                ApplyStyle(spwnCtrls["accessToggle"], my_fixed_width_style)
            end
        end


        -- Sets the player's custom spawn point to their current location
        if ((tick - global.playerCooldowns[player.name].setRespawn) > RESPAWN_COOLDOWN_TICKS) then
            spwnCtrls.add{type="button", name="setRespawnLocation", caption="Set New Respawn Location (1 hour cooldown)"}
            spwnCtrls["setRespawnLocation"].style.font = "default-small-semibold"
            spwnCtrls.add{name = "respawn_cooldown_note2", type = "label",
                    caption="This will set your respawn point to your current location."}
            spwnCtrls.add{name = "respawn_cooldown_spacer1", type = "label",
                caption=" "}
            ApplyStyle(spwnCtrls.respawn_cooldown_note2, my_note_style)
            ApplyStyle(spwnCtrls.respawn_cooldown_spacer1, my_spacer_style)   
        else
            spwnCtrls.add{name = "respawn_cooldown_note1", type = "label",
                    caption="Set Respawn Cooldown Remaining: " .. formattime(RESPAWN_COOLDOWN_TICKS-(tick - global.playerCooldowns[player.name].setRespawn))}
            spwnCtrls.add{name = "respawn_cooldown_note2", type = "label",
                    caption="This will set your respawn point to your current location."}
            spwnCtrls.add{name = "respawn_cooldown_spacer1", type = "label",
                caption=" "}
            ApplyStyle(spwnCtrls.respawn_cooldown_note1, my_note_style)
            ApplyStyle(spwnCtrls.respawn_cooldown_note2, my_note_style)
            ApplyStyle(spwnCtrls.respawn_cooldown_spacer1, my_spacer_style)            
        end

        -- Display a list of people in the join queue for your base.
        if (ENABLE_SHARED_SPAWNS and IsSharedSpawnActive(player)) then
            if ((global.sharedSpawns[player.name].joinQueue ~= nil) and
                (#global.sharedSpawns[player.name].joinQueue > 0)) then

                spwnCtrls.add{name = "drop_down_msg_lbl1", type = "label",
                                caption="Select a player from the join queue:"}
                spwnCtrls.add{name = "join_queue_dropdown",
                                type = "drop-down",
                                items = global.sharedSpawns[player.name].joinQueue}
                spwnCtrls.add{name = "accept_player_request",
                                type = "button",
                                caption="Accept"}
                spwnCtrls.add{name = "reject_player_request",
                                type = "button",
                                caption="Reject"}
                ApplyStyle(spwnCtrls.drop_down_msg_lbl1, my_label_style)
            else
                spwnCtrls.add{name = "empty_join_queue_note1", type = "label",
                        caption="You have no players requesting to join you at this time."}

                ApplyStyle(spwnCtrls.empty_join_queue_note1, my_note_style)
            end
            spwnCtrls.add{name = "join_queue_spacer", type = "label",
                            caption=" "}
            ApplyStyle(spwnCtrls.join_queue_spacer, my_spacer_style)
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

        joinQueueIndex = event.element.parent.join_queue_dropdown.selected_index
        joinQueuePlayerChoice = event.element.parent.join_queue_dropdown.get_item(joinQueueIndex)

        if ((game.players[joinQueuePlayerChoice] == nil) or
            (not game.players[joinQueuePlayerChoice].connected)) then
            player.print("Selected player is no longer waiting to join!")
            ExpandSpawnCtrlGui(player, event.tick) 
            return
        end

        if (elemName == "reject_player_request") then
            player.print("You rejected " .. joinQueuePlayerChoice .. "'s request to join your base.")
            SendMsg(joinQueuePlayerChoice, "Your request to join was rejected.")
            

            game.players[joinQueuePlayerChoice].gui.center.join_shared_spawn_wait_menu.destroy() 
            DisplaySpawnOptions(game.players[joinQueuePlayerChoice])
            
            -- Find and remove the player from the joinQueue they were in.
            for index,requestingPlayer in pairs(global.sharedSpawns[player.name].joinQueue) do
                if (requestingPlayer == joinQueuePlayerChoice) then
                    table.remove(global.sharedSpawns[player.name].joinQueue, index)
                    return
                end
            end
        
        elseif (elemName == "accept_player_request") then

            -- Send an announcement
            SendBroadcastMsg(joinQueuePlayerChoice .. " is joining " .. player.name .. "'s base!")
            
            -- Close the waiting players menu
            game.players[joinQueuePlayerChoice].gui.center.join_shared_spawn_wait_menu.destroy() 
            
            -- Find and remove the player from the joinQueue they were in.
            for index,requestingPlayer in pairs(global.sharedSpawns[player.name].joinQueue) do
                if (requestingPlayer == joinQueuePlayerChoice) then
                    table.remove(global.sharedSpawns[player.name].joinQueue, index)
                end
            end

            -- Spawn the player
            joiningPlayer = game.players[joinQueuePlayerChoice]
            ChangePlayerSpawn(joiningPlayer, global.sharedSpawns[player.name].position)
            SendPlayerToSpawn(joiningPlayer)
            GivePlayerStarterItems(joiningPlayer)
            table.insert(global.sharedSpawns[player.name].players, joiningPlayer.name)
            joiningPlayer.force = game.players[player.name].force

            -- Create the button at the top left for setting respawn point and sharing base.
            CreateSpawnCtrlGui(joiningPlayer)
            ExpandSpawnCtrlGui(player, event.tick) 
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
    buddyGui.add{name = "warning_lbl1", type = "label",
                    caption="Once a buddy accepts a spawn request, it is final!"}
    buddyGui.add{name = "warning_spacer", type = "label",
                    caption=" "}
    ApplyStyle(buddyGui.warning_lbl1, my_warning_style)
    ApplyStyle(buddyGui.warning_spacer, my_spacer_style)

    buddyGui.add{name = "spawn_msg_lbl1", type = "label",
                    caption=SPAWN_MSG1}
    buddyGui.add{name = "spawn_msg_lbl2", type = "label",
                    caption=SPAWN_MSG2}
    buddyGui.add{name = "spawn_msg_lbl3", type = "label",
                    caption=SPAWN_MSG3}
    buddyGui.add{name = "spawn_msg_spacer", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    ApplyStyle(buddyGui.spawn_msg_lbl1, my_label_style)
    ApplyStyle(buddyGui.spawn_msg_lbl2, my_label_style)
    ApplyStyle(buddyGui.spawn_msg_lbl3, my_label_style)
    ApplyStyle(buddyGui.spawn_msg_spacer, my_spacer_style)

    buddyList = {}
    for _,buddyName in pairs(global.waitingBuddies) do
        if (buddyName ~= player.name) then
            table.insert(buddyList, buddyName)
        end
    end

    buddyGui.add{name = "drop_down_msg_lbl1", type = "label",
                    caption="Select a buddy from the waiting list:"}
    buddyGui.add{name = "waiting_buddies_dropdown",
                    type = "drop-down",
                    items = buddyList}
    buddyGui.add{name = "refresh_buddy_list",
                    type = "button",
                    caption="Refresh Buddy List"}
    buddyGui.add{name = "waiting_buddies_spacer", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    ApplyStyle(buddyGui.drop_down_msg_lbl1, my_label_style)
    ApplyStyle(buddyGui.waiting_buddies_spacer, my_spacer_style)


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

    buddySpawnFlow.add{name = "buddy_options_spacer", type = "label",
                caption=" "}
    ApplyStyle(buddySpawnFlow.buddy_options_spacer, my_spacer_style)


    buddySpawnFlow.add{name = "buddy_spawn_request_near",
                    type = "button",
                    caption="Request Buddy Spawn (Near)"}
    buddySpawnFlow.add{name = "buddy_spawn_request_far",
                    type = "button",
                    caption="Request Buddy Spawn (Far)"}
    
    buddySpawnFlow.add{name = "buddy_spawn_lbl1", type = "label",
                    caption="You are spawned in a new area, with some starting resources."}    
    ApplyStyle(buddySpawnFlow.buddy_spawn_lbl1, my_label_style)

    buddyGui.add{name = "buddy_spawn_spacer", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    ApplyStyle(buddyGui.buddy_spawn_spacer, my_spacer_style)


    buddyGui.add{name = "buddy_spawn_cancel",
                    type = "button",
                    caption="Cancel (Return to Previous Options)"}

    -- Some final notes
    buddyGui.add{name = "note_spacer1", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    buddyGui.add{name = "note_spacer2", type = "label",
                    caption=" "}

    if MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN then
        buddyGui.add{name = "shared_spawn_note1", type = "label",
                    caption="If you create your own spawn point you can allow up to " .. MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN-1 .. " other online players to join." }
        ApplyStyle(buddyGui.shared_spawn_note1, my_note_style)
    end
    buddyGui.add{name = "note_lbl1", type = "label",
                    caption="Near spawn is between " .. NEAR_MIN_DIST*CHUNK_SIZE .. "-" .. NEAR_MAX_DIST*CHUNK_SIZE ..  " tiles away from the center of the map."}
    buddyGui.add{name = "note_lbl2", type = "label",
                    caption="Far spawn is between " .. FAR_MIN_DIST*CHUNK_SIZE .. "-" .. FAR_MAX_DIST*CHUNK_SIZE ..  " tiles away from the center of the map."}
    buddyGui.add{name = "note_lbl3", type = "label",
                    caption="Buddy spawns are only 1 chunk apart."}
    buddyGui.add{name = "note_spacer3", type = "label",
                    caption=" "}
    ApplyStyle(buddyGui.note_lbl1, my_note_style)
    ApplyStyle(buddyGui.note_lbl2, my_note_style)
    ApplyStyle(buddyGui.note_lbl3, my_note_style)
    ApplyStyle(buddyGui.note_spacer1, my_spacer_style)
    ApplyStyle(buddyGui.note_spacer2, my_spacer_style)
    ApplyStyle(buddyGui.note_spacer3, my_spacer_style)
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
            name = global.waitingBuddies[i]
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

        buddySpawnGui = player.gui.center.buddy_spawn_opts

        dropDownIndex = buddySpawnGui.waiting_buddies_dropdown.selected_index
        if (dropDownIndex > 0) then
            buddyChoice = buddySpawnGui.waiting_buddies_dropdown.get_item(dropDownIndex)
        else
            player.print("You have not selected a valid buddy! Please try again.")
            return
        end

        buddyIsStillWaiting = false
        for _,buddyName in pairs(global.waitingBuddies) do
            if (buddyChoice == buddyName) then
                buddyIsStillWaiting = true
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
    sGui.add{name = "warning_lbl1", type = "label",
                    caption="You will spawn once your buddy selects yes..."}
    sGui.add{name = "warning_spacer", type = "label",
                    caption=" "}
    ApplyStyle(sGui.warning_lbl1, my_warning_style)
    ApplyStyle(sGui.warning_spacer, my_spacer_style)
    
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

        buddy = game.players[global.buddySpawnOptions[player.name].buddyChoice]

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
    
    player.gui.center.add{name = "buddy_request_menu",
                            type = "frame",
                            direction = "vertical",
                            caption="Buddy Request!"}
    local sGui = player.gui.center.buddy_request_menu
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    sGui.add{name = "warning_lbl1", type = "label",
                    caption=requestingBuddyName .. " is requesting a buddy spawn from you!"}
    sGui.add{name = "warning_spacer", type = "label",
                    caption=" "}
    ApplyStyle(sGui.warning_lbl1, my_warning_style)
    ApplyStyle(sGui.warning_spacer, my_spacer_style)
    

    teamText = "error!"
    if (global.buddySpawnOptions[requestingBuddyName].joinMainTeamRadio) then
        teamText = "the main team"
    elseif (global.buddySpawnOptions[requestingBuddyName].joinOwnTeamRadio) then
        teamText = "on separate teams"
    elseif (global.buddySpawnOptions[requestingBuddyName].joinBuddyTeamRadio) then
        teamText = "a buddy team"
    end

    moatText = " "
    if (global.buddySpawnOptions[requestingBuddyName].moatChoice) then
        moatText = " surrounded by a moat "
    end

    distText = "error!"
    if (global.buddySpawnOptions[requestingBuddyName].distChoice == "buddy_spawn_request_near") then
        distText = "near to the center of the map!"
    elseif (global.buddySpawnOptions[requestingBuddyName].distChoice == "buddy_spawn_request_far") then
        distText = "far from the center of the map!"
    end


    requestText = requestingBuddyName .. " would like to join " .. teamText .. " next to you" .. moatText .. distText


    sGui.add{name = "note_lbl1", type = "label",
                    caption=requestText}
    sGui.add{name = "note_spacer1", type = "label",
                    caption=" "}
    ApplyStyle(sGui.note_lbl1, my_note_style)
    ApplyStyle(sGui.note_spacer1, my_spacer_style)

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

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.center.buddy_request_menu == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Check if it's a button press and lookup the matching buddy info
    if ((elemName == "accept_buddy_request") or (elemName == "decline_buddy_request")) then

        requesterName = nil
        requesterOptions = {}
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


    -- Check if player is cancelling the request.
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

            if (FRONTIER_ROCKET_SILO_MODE and newForce and buddyForce) then
                ChartRocketSiloArea(newForce, game.surfaces[GAME_SURFACE_NAME])
                ChartRocketSiloArea(buddyForce, game.surfaces[GAME_SURFACE_NAME])
            end

        -- Create a new force for the combined players if they chose that option
        elseif requesterOptions.joinBuddyTeamRadio then
            local buddyForce = CreatePlayerCustomForce(game.players[requesterName])
            player.force = buddyForce

            if (FRONTIER_ROCKET_SILO_MODE and newForce and buddyForce) then
                ChartRocketSiloArea(buddyForce, game.surfaces[GAME_SURFACE_NAME])
            end
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
        if (requesterOptions.moatChoice) then
            buddySpawn = {x=newSpawn.x+(CHUNK_SIZE*4), y=newSpawn.y}
        else
            buddySpawn = {x=newSpawn.x+(CHUNK_SIZE*3), y=newSpawn.y}
        end
        ChangePlayerSpawn(player, newSpawn)
        ChangePlayerSpawn(game.players[requesterName], buddySpawn)
        
        -- Send the player there
        QueuePlayerForDelayedSpawn(player.name, newSpawn, requesterOptions.moatChoice)
        QueuePlayerForDelayedSpawn(requesterName, buddySpawn, requesterOptions.moatChoice)
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


    if (elemName == "decline_buddy_request") then
        player.gui.center.buddy_request_menu.destroy() 
        DisplaySpawnOptions(player)

        requesterBuddy = game.players[requesterName]

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


function DisplayPleaseWaitForSpawnDialog(player)
    
    player.gui.center.add{name = "wait_for_spawn_dialog",
                            type = "frame",
                            direction = "vertical",
                            caption="Please wait!"}
    local pleaseWaitGui = player.gui.center.wait_for_spawn_dialog
    pleaseWaitGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    pleaseWaitGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    pleaseWaitGui.add{name = "warning_lbl1", type = "label",
                    caption="Your spawn is being created now."}
    pleaseWaitGui.add{name = "warning_lbl2", type = "label",
                    caption="You will be teleported there in a few seconds!"}
    pleaseWaitGui.add{name = "warning_lbl3", type = "label",
                    caption="Please standby..."}
    pleaseWaitGui.add{name = "warning_spacer", type = "label",
                    caption=" "}
    ApplyStyle(pleaseWaitGui.warning_lbl1, my_warning_style)
    ApplyStyle(pleaseWaitGui.warning_lbl2, my_warning_style)
    ApplyStyle(pleaseWaitGui.warning_lbl3, my_warning_style)
    ApplyStyle(pleaseWaitGui.warning_spacer, my_spacer_style)

end