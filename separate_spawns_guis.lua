-- separate_spawns_guis.lua
-- Nov 2016

-- I made a separate file for all the GUI related functions

require("separate_spawns")

local SPAWN_GUI_MAX_WIDTH = 450
local SPAWN_GUI_MAX_HEIGHT = 650

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
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
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
        sGui.add{name = "normal_spawn_lbl3", type = "label",
                        caption="(Back by popular request...)"}
        ApplyStyle(sGui.normal_spawn_lbl1, my_label_style)
        ApplyStyle(sGui.normal_spawn_lbl2, my_label_style)
        ApplyStyle(sGui.normal_spawn_lbl3, my_label_style)
    else
        sGui.add{name = "normal_spawn_lbl1", type = "label",
                        caption="Default spawn is disabled in this mode."}
        ApplyStyle(sGui.normal_spawn_lbl1, my_warning_style)
    end
    sGui.add{name = "normal_spawn_spacer", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    ApplyStyle(sGui.normal_spawn_spacer, my_spacer_style)


    -- The main spawning options. Solo near and solo far.
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
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
    ApplyStyle(sGui.isolated_spawn_lbl1, my_label_style)
    ApplyStyle(sGui.isolated_spawn_lbl2, my_label_style)
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

    -- Some final notes
    sGui.add{name = "note_spacer1", type = "label",
                    caption="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"}
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


-- Handle the gui click of the spawn options
function SpawnOptsGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name


    -- Check if a valid button on the gui was pressed
    -- and delete the GUI
    if ((buttonClicked == "default_spawn_btn") or
        (buttonClicked == "isolated_spawn_near") or
        (buttonClicked == "isolated_spawn_far") or
        (buttonClicked == "join_other_spawn") or
        (buttonClicked == "join_other_spawn_check")) then

        if (player.gui.center.spawn_opts ~= nil) then
            player.gui.center.spawn_opts.destroy()
        end

    end

    if (buttonClicked == "default_spawn_btn") then
        CreateSpawnCtrlGui(player)
        GivePlayerStarterItems(player)
        ChangePlayerSpawn(player, player.force.get_spawn_position("nauvis"))
        SendBroadcastMsg(player.name .. " joined the main force!")
        ChartArea(player.force, player.position, 4)

    elseif ((buttonClicked == "isolated_spawn_near") or (buttonClicked == "isolated_spawn_far")) then
        CreateSpawnCtrlGui(player)

        -- Create a new spawn point
        local newSpawn = {x=0,y=0}

        -- Re-used abandoned spawns...
        if (#global.unusedSpawns >= 1) then
            newSpawn = table.remove(global.unusedSpawns)
            global.uniqueSpawns[player.name] = newSpawn
            player.print("Sorry! You have been assigned to an abandoned base! This is done to keep map size small.")
            ChangePlayerSpawn(player, newSpawn)
            SendPlayerToSpawn(player)
            GivePlayerStarterItems(player)
            SendBroadcastMsg(player.name .. " joined an abandoned base!")
        else

            -- Find coordinates of a good place to spawn
            if (buttonClicked == "isolated_spawn_far") then
                newSpawn = FindUngeneratedCoordinates(FAR_MIN_DIST,FAR_MAX_DIST)
            elseif (buttonClicked == "isolated_spawn_near") then
                newSpawn = FindUngeneratedCoordinates(NEAR_MIN_DIST,NEAR_MAX_DIST)
            end

            -- If that fails, find a random map edge in a rand direction.
            if ((newSpawn.x == 0) and (newSpawn.x == 0)) then
                newSpawn = FindMapEdge(GetRandomVector())
                DebugPrint("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
            end

            -- Create that spawn in the global vars
            ChangePlayerSpawn(player, newSpawn)
            
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

    elseif (buttonClicked == "join_other_spawn") then
        DisplaySharedSpawnOptions(player)
    
    -- Provide a way to refresh the gui to check if people have shared their
    -- bases.
    elseif (buttonClicked == "join_other_spawn_check") then
        DisplaySpawnOptions(player)
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
            if (buttonClicked == spawnName) then
                CreateSpawnCtrlGui(player)
                ChangePlayerSpawn(player,sharedSpawn.position)
                SendPlayerToSpawn(player)
                GivePlayerStarterItems(player)
                table.insert(sharedSpawn.players, player.name)
                SendBroadcastMsg(player.name .. " joined " .. spawnName .. "'s base!")
                if (player.gui.center.shared_spawn_opts ~= nil) then
                    player.gui.center.shared_spawn_opts.destroy()
                end
                break
            end
        end
    end
end


function CreateSpawnCtrlGui(player)
  if player.gui.top.spwn_ctrls == nil then
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


function SpawnCtrlGuiClick(event) 
    if not (event and event.element and event.element.valid) then return end
        
    local player = game.players[event.element.player_index]
    local name = event.element.name

    if (name == "spwn_ctrls") then
        ExpandSpawnCtrlGui(player, event.tick)       
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

    -- Sets a new respawn point and resets the cooldown.
    if (name == "setRespawnLocation") then
        if DoesPlayerHaveCustomSpawn(player) then
            ChangePlayerSpawn(player, player.position)
            global.playerCooldowns[player.name].setRespawn = event.tick
            ExpandSpawnCtrlGui(player, event.tick) 
            player.print("Re-spawn point updated!")
        end
    end
end
