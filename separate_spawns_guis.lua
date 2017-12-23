-- separate_spawns_guis.lua
-- Nov 2016

-- I made a separate file for all the GUI related functions

require("separate_spawns")

local SPAWN_GUI_MAX_WIDTH = 550
local SPAWN_GUI_MAX_HEIGHT = 750

-- Use this for testing shared spawns...
-- local sharedSpawnExample1 = {openAccess=true,
--                             position={x=50,y=50},
--                             players={"ABC", "DEF"}}
-- local sharedSpawnExample2 = {openAccess=false,
--                             position={x=200,y=200},
--                             players={"ABC", "DEF"}}
-- local sharedSpawnExample3 = {openAccess=true,
--                             owner="testName1",
--                             players={"A", "B", "C", "D"}}
-- global.sharedSpawns = {testName1=sharedSpawnExample1,
--                        testName2=sharedSpawnExample2,
--                        testName3=sharedSpawnExample3}


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
    
    if (ENABLE_SEPARATE_TEAMS) then
        soloSpawnFlow.add{name = "isolated_spawn_main_team_radio",
                        type = "radiobutton",
                        caption="Join Main Team (shared research)",
                        state=true}
        soloSpawnFlow.add{name = "isolated_spawn_new_team_radio",
                        type = "radiobutton",
                        caption="Create Your Own Team (own research tree)",
                        state=false}
        if (SPAWN_MOAT_CHOICE_ENABLED) then
            soloSpawnFlow.add{name = "isolated_spawn_moat_option_checkbox",
                            type = "checkbox",
                            caption="Surround your spawn with a moat",
                            state=false}
        end
        -- soloSpawnFlow.add{name = "team_chat_warning_lbl1", type = "label",
        --                 caption="You must type '/s' before your msg to chat with other teams!!!"}
        -- ApplyStyle(soloSpawnFlow.team_chat_warning_lbl1, my_warning_style)
        soloSpawnFlow.add{name = "team_chat_warning_spacer", type = "label",
                    caption=" "}
        ApplyStyle(soloSpawnFlow.team_chat_warning_spacer, my_spacer_style)
    end

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

    -- Hack for a 2 player twin spawn.
    if BUDDY_SPAWN then
        sGui.add{name = "buddy_spawn",
                        type = "button",
                        caption="Buddy Spawn"}
        sGui.add{name = "buddy_spawn_lbl1", type = "label",
                        caption="You spawn with a buddy. You must both click this together."}
    end

    -- Some final notes
    sGui.add{name = "note_spacer1", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    sGui.add{name = "note_spacer2", type = "label",
                    caption=" "}

    if MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN then
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


function SpawnOptsGuiOptionsSelect(event)
    if not (event and event.element and event.element.valid) then return end
    local elemName = event.element.name

    -- This just updates the radio buttons.
    if (elemName == "isolated_spawn_main_team_radio") then
        event.element.parent.isolated_spawn_new_team_radio.state=false
    elseif (elemName == "isolated_spawn_new_team_radio") then
        event.element.parent.isolated_spawn_main_team_radio.state=false
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
            if (SPAWN_MOAT_CHOICE_ENABLED) then
                moatChoice = 
                    player.gui.center.spawn_opts.spawn_solo_flow.isolated_spawn_moat_option_checkbox.state
            end
        end
        player.gui.center.spawn_opts.destroy()   
    else       
        return -- Do nothing, no valid element item was clicked.
    end

    if (elemName == "default_spawn_btn") then
        GivePlayerStarterItems(player)
        ChangePlayerSpawn(player, player.force.get_spawn_position(GAME_SURFACE_NAME))
        SendBroadcastMsg(player.name .. " joined the main force!")
        ChartArea(player.force, player.position, 4, player.surface)
        -- Create the button at the top left for setting respawn point and sharing base.
        CreateSpawnCtrlGui(player)

    elseif ((elemName == "isolated_spawn_near") or (elemName == "isolated_spawn_far")) then

        -- Create a new spawn point
        local newSpawn = {x=0,y=0}

        -- Create a new force for player if they choose that radio button
        if ENABLE_SEPARATE_TEAMS and joinOwnTeamRadio then
            local newForce = CreatePlayerCustomForce(player)

            if (FRONTIER_ROCKET_SILO_MODE and (newForce ~= nil)) then
                ChartRocketSiloArea(newForce, game.surfaces[GAME_SURFACE_NAME])
            end
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
        SendPlayerToNewSpawnAndCreateIt(player, newSpawn, moatChoice)
        if (elemName == "isolated_spawn_near") then
            SendBroadcastMsg(player.name .. " joined the game from a distance!")
        elseif (elemName == "isolated_spawn_far") then
            SendBroadcastMsg(player.name .. " joined the game from a great distance!")
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

        if (TableLength(global.waitingBuddies) == 0) then
            table.insert(global.waitingBuddies, player.name)
            SendBroadcastMsg(player.name .. " is waiting for a buddy.")

        else
            buddy_name = table.remove(global.waitingBuddies)

            -- Create a new spawn point
            local newSpawn = {x=0,y=0}

            -- Create a new force for player if they choose that radio button
            if ENABLE_SEPARATE_TEAMS and joinOwnTeamRadio then
                local newForce = CreatePlayerCustomForce(player)
                local buddyForce = CreatePlayerCustomForce(game.players[buddy_name])

                if (FRONTIER_ROCKET_SILO_MODE and newForce and buddyForce) then
                    ChartRocketSiloArea(newForce, game.surfaces[GAME_SURFACE_NAME])
                    ChartRocketSiloArea(buddyForce, game.surfaces[GAME_SURFACE_NAME])
                end
            end

            -- Find coordinates of a good place to spawn
            newSpawn = FindUngeneratedCoordinates(NEAR_MIN_DIST,NEAR_MAX_DIST, player.surface)

            -- If that fails, find a random map edge in a rand direction.
            if ((newSpawn.x == 0) and (newSpawn.x == 0)) then
                newSpawn = FindMapEdge(GetRandomVector(), player.surface)
                DebugPrint("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
            end

            -- Create that spawn in the global vars
            buddySpawn = {x=newSpawn.x+(CHUNK_SIZE*4), y=newSpawn.y}
            ChangePlayerSpawn(player, newSpawn)
            ChangePlayerSpawn(game.players[buddy_name], buddySpawn)
            
            -- Send the player there
            SendPlayerToNewSpawnAndCreateIt(player, newSpawn, moatChoice)
            SendPlayerToNewSpawnAndCreateIt(game.players[buddy_name], buddySpawn, moatChoice)
            SendBroadcastMsg(player.name .. " and " .. buddy_name .. " joined the game from a distance!")
           
            -- Create the button at the top left for setting respawn point and sharing base.
            CreateSpawnCtrlGui(player)
            CreateSpawnCtrlGui(game.players[buddy_name])

            player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!")
            player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!")
            player.print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!!")
            game.players[buddy_name].print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!")
            game.players[buddy_name].print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!")
            game.players[buddy_name].print("PLEASE WAIT WHILE YOUR SPAWN POINT IS GENERATED!!!")
        end
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
        if sharedSpawn.openAccess then
            local spotsRemaining = MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN - GetOnlinePlayersAtSharedSpawn(spawnName)
            if (spotsRemaining > 0) then
                shGui.add{type="button", caption=spawnName .. " (" .. spotsRemaining .. " spots remaining)", name=spawnName}
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
            if ((buttonClicked == spawnName) and (game.players[spawnName] ~= nil)) then
                ChangePlayerSpawn(player,sharedSpawn.position)
                SendPlayerToSpawn(player)
                GivePlayerStarterItems(player)
                table.insert(sharedSpawn.players, player.name)
                SendBroadcastMsg(player.name .. " joined " .. spawnName .. "'s base!")
                player.force = game.players[spawnName].force
                if (player.gui.center.shared_spawn_opts ~= nil) then
                    player.gui.center.shared_spawn_opts.destroy()
                end
                -- Create the button at the top left for setting respawn point and sharing base.
                CreateSpawnCtrlGui(player)
                break
            end
        end
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
    local name = event.element.name

    if not player then
        DebugPrint("Another gui click happened with no valid player...")
        return
    end

    if (name == "spwn_ctrls") then
        ExpandSpawnCtrlGui(player, event.tick)       
    end

    if (event.element.parent) then
        if (event.element.parent.name ~= "spwn_ctrl_panel") then
            return
        end
    end

    -- Sets a new respawn point and resets the cooldown.
    if (name == "setRespawnLocation") then
        if DoesPlayerHaveCustomSpawn(player) then
            ChangePlayerSpawn(player, player.position)
            ExpandSpawnCtrlGui(player, event.tick) 
            player.print("Re-spawn point updated!")
        end
    end
end
