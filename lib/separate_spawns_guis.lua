-- I made a separate file for all the GUI related functions. Yay me.

local SPAWN_GUI_MAX_WIDTH = 500
local SPAWN_GUI_MAX_HEIGHT = 1000

---A display gui message. Meant to be display the first time a player joins.
---@param player LuaPlayer
---@return boolean
function DisplayWelcomeTextGui(player)
    if ((player.gui.screen["welcome_msg"] ~= nil) or
            (player.gui.screen["spawn_opts"] ~= nil) or
            (player.gui.screen["shared_spawn_opts"] ~= nil) or
            (player.gui.screen["join_shared_spawn_wait_menu"] ~= nil) or
            (player.gui.screen["buddy_spawn_opts"] ~= nil) or
            (player.gui.screen["buddy_wait_menu"] ~= nil) or
            (player.gui.screen["buddy_request_menu"] ~= nil) or
            (player.gui.screen["wait_for_spawn_dialog"] ~= nil)) then
        log("DisplayWelcomeTextGui called while some other dialog is already displayed!")
        return false
    end

    local wGui = player.gui.screen.add { name = "welcome_msg",
        type = "frame",
        direction = "vertical",
        caption = global.ocfg.server_info.welcome_msg_title }
    wGui.auto_center = true

    wGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    wGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT

    -- Start with server message.
    AddLabel(wGui, "server_msg_lbl1", global.ocfg.server_info.server_msg, my_label_style)
    -- AddLabel(wGui, "contact_info_msg_lbl1", global.ocfg.server_contact, my_label_style)
    AddSpacer(wGui)

    -- Informational message about the scenario
    AddLabel(wGui, "scenario_info_msg_lbl1", global.ocfg.server_info.welcome_msg, my_label_style)
    AddSpacer(wGui)

    -- Warning about spawn creation time
    AddLabel(wGui, "spawn_time_msg_lbl1", { "oarc-spawn-time-warning-msg" }, my_warning_style)

    -- Confirm button
    AddSpacerLine(wGui)
    local button_flow = wGui.add { type = "flow" }
    button_flow.style.horizontal_align = "right"
    button_flow.style.horizontally_stretchable = true
    button_flow.add { name = "welcome_okay_btn",
        type = "button",
        caption = { "oarc-i-understand" },
        style = "confirm_button" }

    return true
end

---Handle the gui click of the welcome msg
---@param event EventData.on_gui_click
---@return nil
function WelcomeTextGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (buttonClicked == "welcome_okay_btn") then
        if (player.gui.screen.welcome_msg ~= nil) then
            player.gui.screen.welcome_msg.destroy()
        end
        DisplaySpawnOptions(player)
    end
end

---Creates the spawn options gui frame to hold all the spawn options.
---@param player LuaPlayer
---@return LuaGuiElement
function CreateSpawnOptionsGuiFrame(player)
    local spawn_opts_gui = player.gui.screen.add {
        name = "spawn_opts",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-spawn-options" }
    }
    spawn_opts_gui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    spawn_opts_gui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    spawn_opts_gui.auto_center = true
    return spawn_opts_gui
end

---Show the surface select dropdown
---@param parent_flow LuaGuiElement
---@return nil
function ShowSurfaceSelectDropdown(parent_flow)
    local surfacesHorizontalFlow = parent_flow.add {
        name = "surfaces_horizontal_flow",
        type = "flow",
        direction = "horizontal"
    }

    local surface_list = GetAllowedSurfaces()

    AddLabel(surfacesHorizontalFlow, "surfacesHorizontalFlowLabel", "Select Surface: ", my_label_style)
    surfacesHorizontalFlow.add {
        name = "surface_select_dropdown",
        tags = { action = "oarc_spawn_options", setting = "surface_select" },
        type = "drop-down",
        items = surface_list,
        selected_index = 1
    }
end

---Display the team select radio buttons
---@param parent_flow LuaGuiElement
---@param enable_separate_teams boolean
---@param enable_buddy_spawn boolean
---@return nil
function DisplayTeamSelectRadioButtons(parent_flow, enable_separate_teams, enable_buddy_spawn)

    local main_team_radio = parent_flow.add {
        name = "isolated_spawn_main_team_radio",
        tags = { action = "oarc_spawn_options", setting = "team_select", value = SPAWN_TEAM_CHOICE.join_main_team },
        type = "radiobutton",
        caption = { "oarc-join-main-team-radio" },
        state = true
    }

    if (enable_separate_teams) then
        parent_flow.add {
            name = "isolated_spawn_new_team_radio",
            tags = { action = "oarc_spawn_options", setting = "team_select", value = SPAWN_TEAM_CHOICE.join_own_team },
            type = "radiobutton",
            caption = { "oarc-create-own-team-radio" },
            state = false
        }
        if (enable_buddy_spawn) then
            parent_flow.add {
                name = "isolated_spawn_buddy_team_radio",
                tags = { action = "oarc_spawn_options", setting = "team_select", value = SPAWN_TEAM_CHOICE.join_buddy_team },
                type = "radiobutton",
                caption = { "oarc-create-buddy-team" },
                state = false
            }
        end
    else
        -- If separate teams are not enabled, default to joining the main team, and disable the radio buttons.
        main_team_radio.ignored_by_interaction = true
    end
end

---Create a distance select slider
---@param parent_flow LuaGuiElement
---@param minimum_distance number
---@param maximum_distance number
---@return nil
function CreateDistanceSelectSlider(parent_flow, minimum_distance, maximum_distance)
    local sliderFlow = parent_flow.add { name = "spawn_distance_slider_flow",
        type = "flow",
        direction = "horizontal",
        style = "player_input_horizontal_flow"
    }
    sliderFlow.style.horizontal_align = "center"
    sliderFlow.add { name = "spawn_distance_slider_label",
        type = "label",
        caption = "test" }
    sliderFlow.add { name = "spawn_distance_slider",
        type = "slider",
        tags = { action = "oarc_spawn_options", setting = "distance_select" },
        minimum_value = minimum_distance,
        maximum_value = maximum_distance,
        value = minimum_distance,
        discrete_slider = true,
        value_step = 1,
    }
    sliderFlow.add { name = "spawn_distance_slider_value",
        type = "textfield",
        ignored_by_interaction = true,
        caption = minimum_distance,
        style = "slider_value_textfield",
        text = tostring(minimum_distance)
    }
end

---Create a confim button for player to request spawn creation
---@param parent_flow LuaGuiElement
---@return nil
function CreateSpawnRequestButton(parent_flow)
    local spawnRequestFlow = parent_flow.add {
        name = "spawn_request_flow",
        type = "flow",
        direction = "horizontal"
    }
    spawnRequestFlow.style.horizontal_align = "right"
    spawnRequestFlow.style.horizontally_stretchable = true
    spawnRequestFlow.add {
        name = "spawn_request",
        tags = { action = "oarc_spawn_options", setting = "spawn_request" },
        type = "button",
        caption = { "oarc-solo-spawn-near" },
        style = "confirm_button"
    }
end

---Creates the shared spawn frame for joining another player's base
---@param parent_flow LuaGuiElement
---@param enable_shared_spawns boolean
---@return nil
function CreateSharedSpawnFrame(parent_flow, enable_shared_spawns)

    local sharedSpawnFrame = parent_flow.spawn_shared_flow
    if sharedSpawnFrame == nil then
        sharedSpawnFrame = parent_flow.add {
            name = "spawn_shared_flow",
            type = "frame",
            direction = "vertical",
            style = "bordered_frame"
        }
    --- Let's us refresh the frame if it already exists
    else
        for _,child in pairs(sharedSpawnFrame.children) do
            child.destroy()
        end
    end

    if enable_shared_spawns then
        local numAvailSpawns = GetNumberOfAvailableSharedSpawns()
        if (numAvailSpawns > 0) then
            sharedSpawnFrame.add {
                name = "join_other_spawn",
                tags = { action = "oarc_spawn_options", setting = "join_other_spawn" },
                type = "button",
                caption = { "oarc-join-someone-avail", numAvailSpawns }
            }
            local join_spawn_text = { "oarc-join-someone-info" }
            AddLabel(sharedSpawnFrame, "join_other_spawn_lbl1", join_spawn_text, my_label_style)
        else
            AddLabel(sharedSpawnFrame, "join_other_spawn_lbl1", { "oarc-no-shared-avail" }, my_label_style)
            sharedSpawnFrame.add {
                name = "join_other_spawn_check",
                type = "button",
                caption = { "oarc-join-check-again" }
            }
        end
    else
        AddLabel(sharedSpawnFrame, "join_other_spawn_lbl1", { "oarc-shared-spawn-disabled" }, my_warning_style)
    end
end

---Refresh the shared spawn frame if it exists
---@param player LuaPlayer
---@return nil
function RefreshSharedSpawnFrameIfExist(player)
    local spawn_opts = player.gui.screen.spawn_opts
    if spawn_opts == nil then return end
    CreateSharedSpawnFrame(spawn_opts, global.ocfg.gameplay.enable_shared_spawns)
end

---Creates the buddy spawn frame for spawning with a buddy
---@param parent_flow LuaGuiElement
---@return nil
function CreateBuddySpawnFrame(parent_flow, enable_buddy_spawn)
    if enable_buddy_spawn then -- TODO: Confirm if this must also require enable_shared_spawns!!
        local buddySpawnFrame = parent_flow.add {
            name = "spawn_buddy_flow",
            type = "frame",
            direction = "vertical",
            style = "bordered_frame"
        }

        -- AddSpacerLine(buddySpawnFrame, "buddy_spawn_msg_spacer")
        buddySpawnFrame.add {
            name = "buddy_spawn",
            type = "button",
            caption = { "oarc-buddy-spawn" }
        }
        AddLabel(buddySpawnFrame, "buddy_spawn_lbl1", { "oarc-buddy-spawn-info" }, my_label_style)
    end
end


---Display the spawn options and explanation
---@param player LuaPlayer
---@return nil
function DisplaySpawnOptions(player)
    if (player == nil) then
        log("DisplaySpawnOptions with no valid player...")
        return
    end

    if (player.gui.screen.spawn_opts ~= nil) then
        log("Tried to display spawn options when it was already displayed!")
        return
    end

    -- Get gameplay settings from config
    local gameplay = global.ocfg.gameplay

    -- Create the primary frame and a warning label
    local sGui = CreateSpawnOptionsGuiFrame(player)
    AddLabel(sGui, "warning_lbl1", { "oarc-click-info-btn-help" }, my_warning_style)

    -- Create the default settings entry for the OarcSpawnChoices table
    ---@type OarcSpawnChoices
    local spawn_choices_entry = {
        surface = global.ocfg.gameplay.default_surface,
        team = SPAWN_TEAM_CHOICE.join_main_team,
        moat = false,
        buddy = nil,
        distance = global.ocfg.gameplay.near_spawn_distance
    }
    global.ocore.spawnChoices[player.name] = spawn_choices_entry

    -- Holds the main spawn options
    local soloSpawnFlow = sGui.add {
        name = "spawn_solo_flow",
        type = "frame",
        direction = "vertical",
        style = "bordered_frame"
    }

    -- Pick surface
    if (gameplay.enable_spawning_on_other_surfaces) then
        ShowSurfaceSelectDropdown(soloSpawnFlow)
    end

    -- Radio buttons to pick your team.
    DisplayTeamSelectRadioButtons(soloSpawnFlow, gameplay.enable_separate_teams, gameplay.enable_buddy_spawn)

    -- Allow players to spawn with a moat around their area.
    --TODO: Vanilla spawn points are not implemented yet.
    -- and not global.ocfg.enable_vanilla_spawns
    if (gameplay.allow_moats_around_spawns) then
        soloSpawnFlow.add {
            name = "isolated_spawn_moat_option_checkbox",
            type = "checkbox",
            caption = { "oarc-moat-option" },
            state = false
        }
    end
    -- if (global.ocfg.enable_vanilla_spawns and (TableLength(global.vanillaSpawns) > 0)) then
    --     soloSpawnFlow.add{name = "isolated_spawn_vanilla_option_checkbox",
    --                     type = "checkbox",
    --                     caption="Use a pre-set vanilla spawn point. " .. TableLengthglobal.vanillaSpawns .. " available.",
    --                     state=false}
    -- end

    CreateDistanceSelectSlider(soloSpawnFlow, gameplay.near_spawn_distance, gameplay.far_spawn_distance)

    -- The confirm button to request a spawn
    CreateSpawnRequestButton(soloSpawnFlow)


    -- if (global.ocfg.enable_vanilla_spawns) then
    --     AddLabel(soloSpawnFlow, "isolated_spawn_lbl1",
    --         {"oarc-starting-area-vanilla"}, my_label_style)
    --     AddLabel(soloSpawnFlow, "vanilla_spawn_lbl2",
    --         {"oarc-vanilla-spawns-available", TableLength(global.vanillaSpawns)}, my_label_style)
    -- else
    AddLabel(soloSpawnFlow, "isolated_spawn_lbl1", { "oarc-starting-area-normal" }, my_label_style)
    -- end

    -- Spawn options to join another player's base.
    CreateSharedSpawnFrame(sGui, gameplay.enable_shared_spawns)

    -- Awesome buddy spawning system
    ---TODO: Vanilla spawn points are not implemented yet.
    -- if (not global.ocfg.enable_vanilla_spawns) then
    CreateBuddySpawnFrame(sGui, gameplay.enable_buddy_spawn)
    -- end

    -- Some final notes
    if (gameplay.number_of_players_per_shared_spawn > 0) then
        AddLabel(sGui, "max_players_lbl2",
            { "oarc-max-players-shared-spawn", gameplay.number_of_players_per_shared_spawn - 1 },
            my_note_style)
    end

    local spawn_distance_notes = { "oarc-spawn-dist-notes" }
    AddLabel(sGui, "note_lbl1", spawn_distance_notes, my_note_style)
end


---This just updates the radio buttons/checkboxes when players click them.
---@param event EventData.on_gui_checked_state_changed
---@return nil
function SpawnOptsRadioSelect(event)
    if not event.element.valid then return end
    local elemName = event.element.name
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_spawn_options") then
        return
    end

    if (tags.setting == "team_select") then
        global.ocore.spawnChoices[player.name].team = tags.value

        -- Need to handle the radio button logic manually
        if (elemName == "isolated_spawn_main_team_radio") then
            if (event.element.parent.isolated_spawn_new_team_radio ~= nil) then
                event.element.parent.isolated_spawn_new_team_radio.state = false
            end
            if (event.element.parent.isolated_spawn_buddy_team_radio ~= nil) then
                event.element.parent.isolated_spawn_buddy_team_radio.state = false
            end
        elseif (elemName == "isolated_spawn_new_team_radio") then
            event.element.parent.isolated_spawn_main_team_radio.state = false
            if (event.element.parent.isolated_spawn_buddy_team_radio ~= nil) then
                event.element.parent.isolated_spawn_buddy_team_radio.state = false
            end
        elseif (elemName == "isolated_spawn_buddy_team_radio") then
            event.element.parent.isolated_spawn_main_team_radio.state = false
            event.element.parent.isolated_spawn_new_team_radio.state = false
        end
    end
end

---Handle the gui click of the spawn options
---@param event EventData.on_gui_click
---@return nil
function SpawnChoicesGuiClickNew(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_spawn_options") then
        return
    end
    local setting_name = tags.setting

    if (tags.setting == "spawn_request") then
        SpawnRequest(player)
    end
end

---Handle slider value changes
---@param event EventData.on_gui_value_changed
---@return nil
function SpawnOptsValueChanged(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_spawn_options") then
        return
    end

    if (tags.setting == "distance_select") then
        local distance = event.element.slider_value
        global.ocore.spawnChoices[player.name].distance = distance
        event.element.parent.spawn_distance_slider_value.text = tostring(distance)
        -- log("GUI DEBUG Selected distance: " .. distance)
    end
end

---Handle dropdown selection changes
---@param event EventData.on_gui_selection_state_changed
---@return nil
function SpawnOptsSelectionChanged(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_spawn_options") then
        return
    end

    if (tags.setting == "surface_select") then
        local index = event.element.selected_index
        local surfaceName = event.element.get_item(index) --[[@as string]]
        global.ocore.spawnChoices[player.name].surface = surfaceName
        log("GUI DEBUG Selected surface: " .. surfaceName)
    end
end

---Requests the generation of a spawn point for the player
---@param player LuaPlayer
---@return nil
function SpawnRequest(player)
    -- Get the player's spawn choices
    ---@type OarcSpawnChoices
    local spawnChoices = global.ocore.spawnChoices[player.name]
    if (spawnChoices == nil) then error("ERROR! No spawn choices found for player!") return end

    -- Cache some useful variables
    local gameplay = global.ocfg.gameplay
    local surface = game.surfaces[spawnChoices.surface]

    -- Create a new force for player if they choose that radio button
    if spawnChoices.team ~= SPAWN_TEAM_CHOICE.join_main_team then
        CreatePlayerCustomForce(player)
    end

    -- Find coordinates of a good place to spawn
    local newSpawn = { x = 0, y = 0 }
    newSpawn = FindUngeneratedCoordinates(gameplay.near_spawn_distance, gameplay.far_spawn_distance, surface)

    -- If that fails, find a random map edge in a rand direction.
    if ((newSpawn.x == 0) and (newSpawn.y == 0)) then
        newSpawn = FindMapEdge(GetRandomVector(), surface)
        log("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
    end

    -- Create that player's spawn in the global vars
    ChangePlayerSpawn(player, spawnChoices.surface, newSpawn)

    -- Send the player there
     -- global.ocfg.enable_vanilla_spawns --TODO: Vanilla spawn points are not implemented yet.
    QueuePlayerForDelayedSpawn(player.name, spawnChoices.surface, newSpawn, spawnChoices.moat, false)
    SendBroadcastMsg({ "oarc-player-is-joining-far", player.name, spawnChoices.surface })

    -- Unlock spawn control gui tab
    SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_TAB_NAME, true)

    player.print({ "oarc-please-wait" })
    player.print({ "", { "oarc-please-wait" }, "!" })
    player.print({ "", { "oarc-please-wait" }, "!!" })

    -- Destroy the spawn options gui
    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end
end

---Handle the gui click of the spawn options
---@param event EventData.on_gui_click
---@return nil
function SpawnOptsGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.spawn_opts == nil) then
        return -- Gui event unrelated to this gui.
    end

    local pgcs = player.gui.screen.spawn_opts

    local joinOwnTeamRadio, moatChoice = false, false
    local surfaceName = global.ocfg.gameplay.default_surface -- Default to default surface
    local surface = game.surfaces[surfaceName]

    -- Check if a valid button on the gui was pressed
    -- and delete the GUI
    if ((elemName == "default_spawn_btn") or
            (elemName == "isolated_spawn_near") or
            (elemName == "isolated_spawn_far") or
            (elemName == "join_other_spawn") or
            (elemName == "buddy_spawn") or
            (elemName == "join_other_spawn_check")) then
        if (global.ocfg.gameplay.enable_separate_teams) then
            joinMainTeamRadio = pgcs.spawn_solo_flow.isolated_spawn_main_team_radio.state
            joinOwnTeamRadio = pgcs.spawn_solo_flow.isolated_spawn_new_team_radio.state
        else
            joinMainTeamRadio = true
            joinOwnTeamRadio = false
        end
        ---TODO: Vanilla spawn points are not implemented yet.  and not global.ocfg.enable_vanilla_spawns
        if (global.ocfg.gameplay.allow_moats_around_spawns and
                (pgcs.spawn_solo_flow.isolated_spawn_moat_option_checkbox ~= nil)) then
            moatChoice = pgcs.spawn_solo_flow.isolated_spawn_moat_option_checkbox.state
        end

        -- Override the default surface if the player selected a different one.
        local surfaceDropdownIndex = pgcs.spawn_solo_flow.surfaces_horizontal_flow.surface_select_dropdown.selected_index

        -- Index 0 means nothing was selected!
        if (surfaceDropdownIndex ~= 0) then
            surfaceName = pgcs.spawn_solo_flow.surfaces_horizontal_flow.surface_select_dropdown.get_item(surfaceDropdownIndex) --[[@as string]]
            surface = game.surfaces[surfaceName]
        end

        -- if (global.ocfg.enable_vanilla_spawns and
        --     (pgcs.spawn_solo_flow.isolated_spawn_vanilla_option_checkbox ~= nil)) then
        --     vanillaChoice = pgcs.spawn_solo_flow.isolated_spawn_vanilla_option_checkbox.state
        -- end
        pgcs.destroy()
    else
        return -- Do nothing, no valid element item was clicked.
    end

    -- Default spawn should always spawn on a default surface I think?
    if (elemName == "default_spawn_btn") then
        GivePlayerStarterItems(player)

        local defaultSurfaceName = global.ocfg.gameplay.default_surface
        local defaultSurface = game.surfaces[defaultSurfaceName]
        local spawnPosition = player.force.get_spawn_position(defaultSurface)

        ChangePlayerSpawn(player, defaultSurfaceName, spawnPosition)
        SendBroadcastMsg({ "oarc-player-is-joining-main-force", player.name, defaultSurfaceName })
        ChartArea(player.force, player.position,
            math.ceil(global.ocfg.surfaces_config[defaultSurfaceName].spawn_config.general.spawn_radius_tiles / CHUNK_SIZE),
            defaultSurface)
        -- Unlock spawn control gui tab
        SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_TAB_NAME, true)

    elseif ((elemName == "isolated_spawn_near") or (elemName == "isolated_spawn_far")) then
        --- MOVED
    elseif (elemName == "join_other_spawn") then
        DisplaySharedSpawnOptions(player)

        -- Provide a way to refresh the gui to check if people have shared their
        -- bases.
    elseif (elemName == "join_other_spawn_check") then
        DisplaySpawnOptions(player)

        -- Hacky buddy spawn system
    elseif (elemName == "buddy_spawn") then
        table.insert(global.ocore.waitingBuddies --[[@as OarcWaitingBuddiesTable]], player.name)
        SendBroadcastMsg({ "oarc-looking-for-buddy", player.name })

        DisplayBuddySpawnOptions(player)
    end
end

---Display the spawn options and explanation
---@param player LuaPlayer
---@return nil
function DisplaySharedSpawnOptions(player)
    player.gui.screen.add { name = "shared_spawn_opts",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-avail-bases-join" } }

    local shGuiFrame = player.gui.screen.shared_spawn_opts
    shGuiFrame.auto_center = true
    local shGui = shGuiFrame.add { type = "scroll-pane", name = "spawns_scroll_pane", caption = "" }
    ApplyStyle(shGui, my_fixed_width_style)
    shGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    shGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    shGui.horizontal_scroll_policy = "never"


    for spawnName, sharedSpawn in pairs(global.ocore.sharedSpawns) do
        if (sharedSpawn.openAccess and
                (game.players[spawnName] ~= nil) and
                game.players[spawnName].connected) then
            local spotsRemaining = global.ocfg.gameplay.number_of_players_per_shared_spawn - TableLength(global.ocore.sharedSpawns[spawnName].players)
            if (global.ocfg.gameplay.number_of_players_per_shared_spawn == 0) then
                shGui.add { type = "button", caption = spawnName, name = spawnName }
            elseif (spotsRemaining > 0) then
                shGui.add { type = "button", caption = { "oarc-spawn-spots-remaining", spawnName, spotsRemaining }, name = spawnName }
            end
            if (shGui.spawnName ~= nil) then
                -- AddSpacer(buddyGui, spawnName .. "spacer_lbl")
                ApplyStyle(shGui[spawnName], my_small_button_style)
            end
        end
    end


    shGui.add { name = "shared_spawn_cancel",
        type = "button",
        caption = { "oarc-cancel-return-to-previous" },
        style = "back_button" }
end

---Handle the gui click of the shared spawn options
---@param event EventData.on_gui_click
---@return nil
function SharedSpwnOptsGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
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
        if (player.gui.screen.shared_spawn_opts ~= nil) then
            player.gui.screen.shared_spawn_opts.destroy()
        end

        -- Else check for which spawn was selected
        -- If a spawn is removed during this time, the button will not do anything
    else
        for spawnName, sharedSpawn in pairs(global.ocore.sharedSpawns --[[@as OarcSharedSpawnsTable]]) do
            if ((buttonClicked == spawnName) and
                    (game.players[spawnName] ~= nil) and
                    (game.players[spawnName].connected)) then
                -- Add the player to that shared spawns join queue.
                table.insert(global.ocore.sharedSpawns[spawnName].joinQueue, player.name)

                -- Clear the shared spawn options gui.
                if (player.gui.screen.shared_spawn_opts ~= nil) then
                    player.gui.screen.shared_spawn_opts.destroy()
                end

                -- Display wait menu with cancel button.
                DisplaySharedSpawnJoinWaitMenu(player)

                -- Tell other player they are requesting a response.
                game.players[spawnName].print({ "oarc-player-requesting-join-you", player.name })
                break
            end
        end
    end
end

---Display shared spawn join wait menu
---@param player LuaPlayer
---@return nil
function DisplaySharedSpawnJoinWaitMenu(player)
    local sGui = player.gui.screen.add { name = "join_shared_spawn_wait_menu",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-waiting-for-spawn-owner" } }
    sGui.auto_center = true
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(sGui, "warning_lbl1", { "oarc-you-will-spawn-once-host" }, my_warning_style)
    sGui.add { name = "cancel_shared_spawn_wait_menu",
        type = "button",
        caption = { "oarc-cancel-return-to-previous" },
        style = "back_button" }
end

---Handle the gui click of the shared spawn join wait menu
---@param event EventData.on_gui_click
---@return nil
function SharedSpawnJoinWaitMenuClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.join_shared_spawn_wait_menu == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Check if player is cancelling the request.
    if (elemName == "cancel_shared_spawn_wait_menu") then
        player.gui.screen.join_shared_spawn_wait_menu.destroy()
        DisplaySpawnOptions(player)

        -- Find and remove the player from the joinQueue they were in.
        for spawnName, sharedSpawn in pairs(global.ocore.sharedSpawns --[[@as OarcSharedSpawnsTable]]) do
            for index, requestingPlayer in pairs(sharedSpawn.joinQueue) do
                if (requestingPlayer == player.name) then
                    global.ocore.sharedSpawns[spawnName].joinQueue[index] = nil
                    game.players[spawnName].print({ "oarc-player-cancel-join-request", player.name })
                    return
                end
            end
        end

        log("ERROR! Failed to remove player from joinQueue!")
    end
end

---Display the buddy spawn menu
---@param player LuaPlayer
---@return nil
function DisplayBuddySpawnOptions(player)
    local buddyGui = player.gui.screen.add { name = "buddy_spawn_opts",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-buddy-spawn-options" } }
    buddyGui.auto_center = true
    buddyGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    buddyGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT

    ---@type OarcConfigGameplaySettings
    local gameplay = global.ocfg.gameplay

    -- Warnings and explanations...
    AddLabel(buddyGui, "buddy_info_msg", { "oarc-buddy-spawn-instructions" }, my_label_style)
    AddSpacer(buddyGui)

    -- The buddy spawning options.
    local buddySpawnFlow = buddyGui.add { name = "spawn_buddy_flow",
        type = "frame",
        direction = "vertical",
        style = "bordered_frame" }

    ---@type string[]
    local buddyList = {}
    for _, buddyName in pairs(global.ocore.waitingBuddies --[[@as OarcWaitingBuddiesTable]]) do
        if (buddyName ~= player.name) then
            table.insert(buddyList, buddyName)
        end
    end

    AddLabel(buddySpawnFlow, "drop_down_msg_lbl1", { "oarc-buddy-select-info" }, my_label_style)
    buddySpawnFlow.add { name = "waiting_buddies_dropdown",
        type = "drop-down",
        items = buddyList }
    buddySpawnFlow.add { name = "refresh_buddy_list",
        type = "button",
        caption = { "oarc-buddy-refresh" } }
    -- AddSpacerLine(buddySpawnFlow)

    -- Pick surface
    if (gameplay.enable_spawning_on_other_surfaces) then

        local surfacesHorizontalFlow = buddySpawnFlow.add { name = "buddy_surfaces_horizontal_flow",
            type = "flow",
            direction = "horizontal" }

        ---@type string[]
        local surfaceList = {}
        for surfaceName,allowed in pairs(global.ocore.surfaces) do
            if allowed then
                table.insert(surfaceList, surfaceName)
            end
        end

        AddLabel(surfacesHorizontalFlow, "buddySurfacesHorizontalFlowLabel", "Select Surface: ", my_label_style)
        surfacesHorizontalFlow.add { name = "buddy_surface_select_dropdown",
            type = "drop-down",
            items = surfaceList,
            selected_index = 1}
    end

    -- Allow picking of teams
    if (gameplay.enable_separate_teams) then
        buddySpawnFlow.add { name = "buddy_spawn_main_team_radio",
            type = "radiobutton",
            caption = { "oarc-join-main-team-radio" },
            state = true }
        buddySpawnFlow.add { name = "buddy_spawn_new_team_radio",
            type = "radiobutton",
            caption = { "oarc-create-own-team-radio" },
            state = false }
        buddySpawnFlow.add { name = "buddy_spawn_buddy_team_radio",
            type = "radiobutton",
            caption = { "oarc-create-buddy-team" },
            state = false }
    end
    if (gameplay.allow_moats_around_spawns) then
        buddySpawnFlow.add { name = "buddy_spawn_moat_option_checkbox",
            type = "checkbox",
            caption = { "oarc-moat-option" },
            state = false }
    end

    -- AddSpacerLine(buddySpawnFlow)
    buddySpawnFlow.add { name = "buddy_spawn_request_near",
        type = "button",
        caption = { "oarc-buddy-spawn-near" },
        style = "confirm_button" }
    buddySpawnFlow.add { name = "buddy_spawn_request_far",
        type = "button",
        caption = { "oarc-buddy-spawn-far" },
        style = "confirm_button" }

    AddSpacer(buddyGui)
    buddyGui.add { name = "buddy_spawn_cancel",
        type = "button",
        caption = { "oarc-cancel-return-to-previous" },
        style = "back_button" }

    -- Some final notes
    AddSpacerLine(buddyGui)
    if (gameplay.number_of_players_per_shared_spawn > 0) then
        AddLabel(buddyGui, "buddy_max_players_lbl1",
            { "oarc-max-players-shared-spawn", gameplay.number_of_players_per_shared_spawn - 1 },
            my_note_style)
    end
    local spawn_distance_notes = { "oarc-spawn-dist-notes" }
    AddLabel(buddyGui, "note_lbl1", spawn_distance_notes, my_note_style)
end

---Handle the gui click of the buddy spawn options
---@param event EventData.on_gui_click
---@return nil
function BuddySpawnOptsGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.buddy_spawn_opts == nil) then
        return -- Gui event unrelated to this gui.
    end

    local waiting_buddies_dropdown = player.gui.screen.buddy_spawn_opts.spawn_buddy_flow.waiting_buddies_dropdown

    -- Just refresh the buddy list dropdown values only.
    if (elemName == "refresh_buddy_list") then
        waiting_buddies_dropdown.clear_items()

        for _, buddyName in pairs(global.ocore.waitingBuddies --[[@as OarcWaitingBuddiesTable]]) do
            if (player.name ~= buddyName) then
                waiting_buddies_dropdown.add_item(buddyName)
            end
        end
        return
    end

    -- Handle the cancel button to exit this menu
    if (elemName == "buddy_spawn_cancel") then
        player.gui.screen.buddy_spawn_opts.destroy()
        DisplaySpawnOptions(player)

        -- Remove them from the buddy list when they cancel
        for i = #global.ocore.waitingBuddies, 1, -1 do
            if (global.ocore.waitingBuddies[i] == player.name) then
                global.ocore.waitingBuddies[i] = nil
            end
        end
    end

    local moatChoice = false
    local buddyChoice = nil

    -- Handle the spawn request button clicks
    if ((elemName == "buddy_spawn_request_near") or
            (elemName == "buddy_spawn_request_far")) then
        local buddySpawnGui = player.gui.screen.buddy_spawn_opts.spawn_buddy_flow

        local dropDownIndex = buddySpawnGui.waiting_buddies_dropdown.selected_index
        if ((dropDownIndex > 0) and (dropDownIndex <= #buddySpawnGui.waiting_buddies_dropdown.items)) then
            buddyChoice = buddySpawnGui.waiting_buddies_dropdown.get_item(dropDownIndex) --[[@as string]]
        else
            player.print({ "oarc-invalid-buddy" })
            return
        end

        local buddyIsStillWaiting = false
        for _, buddyName in pairs(global.ocore.waitingBuddies --[[@as OarcWaitingBuddiesTable]]) do
            if (buddyChoice == buddyName) then
                if (game.players[buddyChoice]) then
                    buddyIsStillWaiting = true
                end
                break
            end
        end
        if (not buddyIsStillWaiting) then
            player.print({ "oarc-buddy-not-avail" })
            player.gui.screen.buddy_spawn_opts.destroy()
            DisplayBuddySpawnOptions(player)
            return
        end

        -- Override the default surface if the player selected a different one.
        local surfaceDropdownIndex = buddySpawnGui.surfaces_horizontal_flow.surface_select_dropdown.selected_index
        local surfaceName = global.ocfg.gameplay.default_surface

        -- Index 0 means nothing was selected!
        if (surfaceDropdownIndex ~= 0) then
            surfaceName = buddySpawnGui.surfaces_horizontal_flow.surface_select_dropdown.get_item(surfaceDropdownIndex) --[[@as string]]
        end

        ---@type SpawnTeamChoice
        local buddyTeamRadioSelection = nil
        if (global.ocfg.gameplay.enable_separate_teams) then
            if buddySpawnGui.buddy_spawn_main_team_radio.state then
                buddyTeamRadioSelection = SPAWN_TEAM_CHOICE.join_main_team
            elseif buddySpawnGui.buddy_spawn_new_team_radio.state then
                buddyTeamRadioSelection = SPAWN_TEAM_CHOICE.join_own_team
            elseif buddySpawnGui.buddy_spawn_buddy_team_radio.state then
                buddyTeamRadioSelection = SPAWN_TEAM_CHOICE.join_buddy_team
            end
        else
            buddyTeamRadioSelection = SPAWN_TEAM_CHOICE.join_main_team
        end

        if (global.ocfg.gameplay.allow_moats_around_spawns) then
            moatChoice = buddySpawnGui.buddy_spawn_moat_option_checkbox.state
        end

        -- Save the chosen spawn options somewhere for later use.
        ---@type OarcBuddySpawnOpts
        local buddySpawnOpts = {}
        buddySpawnOpts.teamRadioSelection = buddyTeamRadioSelection
        buddySpawnOpts.moatChoice = moatChoice
        buddySpawnOpts.buddyChoice = buddyChoice
        buddySpawnOpts.distChoice = elemName
        buddySpawnOpts.surface = surfaceName
        global.ocore.buddySpawnOpts[player.name] = buddySpawnOpts

        player.gui.screen.buddy_spawn_opts.destroy()

        -- Display prompts to the players
        DisplayBuddySpawnWaitMenu(player)
        DisplayBuddySpawnRequestMenu(game.players[buddyChoice], player.name)
        if (game.players[buddyChoice].gui.screen.buddy_spawn_opts ~= nil) then
            game.players[buddyChoice].gui.screen.buddy_spawn_opts.destroy()
        end

        -- Remove them from the buddy list while they make up their minds.
        for i = #global.ocore.waitingBuddies, 1, -1 do
            name = global.ocore.waitingBuddies[i]
            if ((name == player.name) or (name == buddyChoice)) then
                global.ocore.waitingBuddies[i] = nil
            end
        end
    else
        return -- Do nothing, no valid element item was clicked.
    end
end

---Display the buddy spawn wait menu
---@param player LuaPlayer
---@return nil
function DisplayBuddySpawnWaitMenu(player)
    local sGui = player.gui.screen.add { name = "buddy_wait_menu",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-waiting-for-buddy" } }
    sGui.auto_center = true
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(sGui, "warning_lbl1", { "oarc-wait-buddy-select-yes" }, my_warning_style)
    AddSpacer(sGui)
    sGui.add { name = "cancel_buddy_wait_menu",
        type = "button",
        caption = { "oarc-cancel-return-to-previous" } }
end

---Handle the gui click of the buddy wait menu
---@param event EventData.on_gui_click
---@return nil
function BuddySpawnWaitMenuClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.buddy_wait_menu == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Check if player is cancelling the request.
    if (elemName == "cancel_buddy_wait_menu") then
        player.gui.screen.buddy_wait_menu.destroy()
        DisplaySpawnOptions(player)

        ---@type OarcBuddySpawnOpts
        local buddySpawnOpts = global.ocore.buddySpawnOpts[player.name]
        local buddy = game.players[buddySpawnOpts.buddyChoice]

        -- Catch a case where the buddy has left the game early and no longer exists.
        if (buddy == nil) then
            return
        end

        if (buddy.gui.screen.buddy_request_menu ~= nil) then
            buddy.gui.screen.buddy_request_menu.destroy()
        end
        if (buddy.gui.screen.buddy_spawn ~= nil) then
            buddy.gui.screen.buddy_spawn_opts.destroy()
        end
        DisplaySpawnOptions(buddy)

        buddy.print({ "oarc-buddy-cancel-request", player.name })
    end
end

---Display the buddy spawn request menu
---@param player LuaPlayer
---@param requestingBuddyName string
---@return nil
function DisplayBuddySpawnRequestMenu(player, requestingBuddyName)
    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    local sGui = player.gui.screen.add { name = "buddy_request_menu",
        type = "frame",
        direction = "vertical",
        caption = "Buddy Request!" }
    sGui.auto_center = true
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(sGui, "warning_lbl1", { "oarc-buddy-requesting-from-you", requestingBuddyName }, my_warning_style)

    ---@type OarcBuddySpawnOpts
    local buddySpawnOpts = global.ocore.buddySpawnOpts[requestingBuddyName]

    ---@type LocalisedString
    local teamText = "error!"
    if (buddySpawnOpts.teamRadioSelection == SPAWN_TEAM_CHOICE.join_main_team) then
        teamText = { "oarc-buddy-txt-main-team" }
    elseif (buddySpawnOpts.teamRadioSelection == SPAWN_TEAM_CHOICE.join_own_team) then
        teamText = { "oarc-buddy-txt-new-teams" }
    elseif (buddySpawnOpts.teamRadioSelection == SPAWN_TEAM_CHOICE.join_buddy_team) then
        teamText = { "oarc-buddy-txt-buddy-team" }
    end

    ---@type LocalisedString
    local moatText = " "
    if (global.ocore.buddySpawnOpts[requestingBuddyName].moatChoice) then
        moatText = { "oarc-buddy-txt-moat" }
    end

    ---@type LocalisedString
    local distText = "error!"
    if (global.ocore.buddySpawnOpts[requestingBuddyName].distChoice == "buddy_spawn_request_near") then
        distText = { "oarc-buddy-txt-near" }
    elseif (global.ocore.buddySpawnOpts[requestingBuddyName].distChoice == "buddy_spawn_request_far") then
        distText = { "oarc-buddy-txt-far" }
    end


    local requestText = { "", requestingBuddyName, { "oarc-buddy-txt-would-like" }, teamText, { "oarc-buddy-txt-next-to-you" },
        moatText, distText }
    AddLabel(sGui, "note_lbl1", requestText, my_warning_style)
    AddSpacer(sGui)


    sGui.add { name = "accept_buddy_request",
        type = "button",
        caption = { "oarc-accept" } }
    sGui.add { name = "decline_buddy_request",
        type = "button",
        caption = { "oarc-reject" } }
end

---Handle the gui click of the buddy request menu
---@param event EventData.on_gui_click
---@return nil
function BuddySpawnRequestMenuClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name
    local requesterName = nil

    ---@type OarcBuddySpawnOpts
    local requesterOptions = {}
    requesterOptions.surface = global.ocfg.gameplay.default_surface

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.buddy_request_menu == nil) then
        return -- Gui event unrelated to this gui.
    end


    -- Check if it's a button press and lookup the matching buddy info
    if ((elemName == "accept_buddy_request") or (elemName == "decline_buddy_request")) then
        for name, opts in pairs(global.ocore.buddySpawnOpts --[[@as OarcBuddySpawnOptsTable]]) do
            if (opts.buddyChoice == player.name) then
                requesterName = name
                requesterOptions = opts
            end
        end

        -- Not sure about this error condition...
        if (requesterName == nil) then
            SendBroadcastMsg("Error! Invalid buddy info???")
            log("Error! Invalid buddy info...")

            player.gui.screen.buddy_request_menu.destroy()
            DisplaySpawnOptions(player)
            return
        end
    else
        return -- Not a button click
    end

    -- Handle player accepted
    if (elemName == "accept_buddy_request") then
        if (game.players[requesterName].gui.screen.buddy_wait_menu ~= nil) then
            game.players[requesterName].gui.screen.buddy_wait_menu.destroy()
        end
        if (player.gui.screen.buddy_request_menu ~= nil) then
            player.gui.screen.buddy_request_menu.destroy()
        end

        -- Create a new spawn point
        local newSpawn = { x = 0, y = 0 }

        -- Create a new force for each player if they chose that option
        if requesterOptions.teamRadioSelection == SPAWN_TEAM_CHOICE.join_own_team then
            CreatePlayerCustomForce(player)
            CreatePlayerCustomForce(game.players[requesterName])

            -- Create a new force for the combined players if they chose that option
        elseif requesterOptions.teamRadioSelection == SPAWN_TEAM_CHOICE.join_buddy_team then
            local buddyForce = CreatePlayerCustomForce(game.players[requesterName])
            player.force = buddyForce
        end

        ---@type OarcConfigGameplaySettings
        local gameplay = global.ocfg.gameplay
        local surface = game.surfaces[requesterOptions.surface]

        -- Find coordinates of a good place to spawn
        ---TODO: Add support for multiple surfaces.
        if (requesterOptions.distChoice == "buddy_spawn_request_far") then
            newSpawn = FindUngeneratedCoordinates(gameplay.near_spawn_distance,
                gameplay.far_spawn_distance,
                surface)
        elseif (requesterOptions.distChoice == "buddy_spawn_request_near") then
            newSpawn = FindUngeneratedCoordinates(
                gameplay.near_spawn_distance,
                gameplay.far_spawn_distance,
                surface)
        end

        -- If that fails, find a random map edge in a rand direction.
        if ((newSpawn.x == 0) and (newSpawn.x == 0)) then
            newSpawn = FindMapEdge(GetRandomVector(), surface)
            log("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
        end

        -- Create that spawn in the global vars
        local buddySpawn = { x = 0, y = 0 }
        if (requesterOptions.moatChoice) then
            buddySpawn = {
                x = newSpawn.x + (global.ocfg.surfaces_config[requesterOptions.surface].spawn_config.general.spawn_radius_tiles * 2) + 10,
                y = newSpawn.y
            }
        else
            buddySpawn = { x = newSpawn.x + (global.ocfg.surfaces_config[requesterOptions.surface].spawn_config.general.spawn_radius_tiles * 2), y = newSpawn.y }
        end
        ChangePlayerSpawn(player, requesterOptions.surface, newSpawn) --TODO: Add support for multiple surfaces
        ChangePlayerSpawn(game.players[requesterName], requesterOptions.surface, buddySpawn)

        -- Send the player there
        QueuePlayerForDelayedSpawn(player.name, requesterOptions.surface, newSpawn, requesterOptions.moatChoice, false)
        QueuePlayerForDelayedSpawn(requesterName, requesterOptions.surface, buddySpawn, requesterOptions.moatChoice, false)
        SendBroadcastMsg(requesterName .. " and " .. player.name .. " are joining the game together!")

        -- Unlock spawn control gui tab
        SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_TAB_NAME, true)
        SetOarcGuiTabEnabled(game.players[requesterName], OARC_SPAWN_CTRL_TAB_NAME, true)

        player.print({ "oarc-please-wait" })
        player.print({ "", { "oarc-please-wait" }, "!" })
        player.print({ "", { "oarc-please-wait" }, "!!" })
        game.players[requesterName].print({ "oarc-please-wait" })
        game.players[requesterName].print({ "", { "oarc-please-wait" }, "!" })
        game.players[requesterName].print({ "", { "oarc-please-wait" }, "!!" })

        global.ocore.buddyPairs[player.name] = requesterName
        global.ocore.buddyPairs[requesterName] = player.name

        -- Check if player is cancelling the request.
    elseif (elemName == "decline_buddy_request") then
        player.gui.screen.buddy_request_menu.destroy()
        DisplaySpawnOptions(player)

        local requesterBuddy = game.players[requesterName]

        if (requesterBuddy.gui.screen.buddy_wait_menu ~= nil) then
            requesterBuddy.gui.screen.buddy_wait_menu.destroy()
        end
        if (requesterBuddy.gui.screen.buddy_spawn ~= nil) then
            requesterBuddy.gui.screen.buddy_spawn_opts.destroy()
        end
        DisplaySpawnOptions(requesterBuddy)

        requesterBuddy.print({ "oarc-buddy-declined", player.name })
    end

    global.ocore.buddySpawnOpts[requesterName] = nil
end

---Display the please wait dialog
---@param player LuaPlayer
---@param delay_seconds integer
---@return nil
function DisplayPleaseWaitForSpawnDialog(player, delay_seconds)
    local pleaseWaitGui = player.gui.screen.add { name = "wait_for_spawn_dialog",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-spawn-wait" } }
    pleaseWaitGui.auto_center = true
    pleaseWaitGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    pleaseWaitGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT

    -- Warnings and explanations...
    local wait_warning_text = { "oarc-wait-text", delay_seconds }

    AddLabel(pleaseWaitGui, "warning_lbl1", wait_warning_text, my_warning_style)

    -- Show a minimap of the spawn location :)
    ---@type OarcPlayerSpawn
    local player_spawn = global.ocore.playerSpawns[player.name]

    pleaseWaitGui.add {
        type = "minimap",
        position = player_spawn.position,
        surface_index = game.surfaces[player_spawn.surface].index,
        force = player.force.name
    }
end

---Gui click event handlers
---@param event EventData.on_gui_click
---@return nil
function SeparateSpawnsGuiClick(event)
    WelcomeTextGuiClick(event)

    SpawnChoicesGuiClickNew(event)

    SpawnOptsGuiClick(event)
    SharedSpwnOptsGuiClick(event)
    BuddySpawnOptsGuiClick(event)
    BuddySpawnWaitMenuClick(event)
    BuddySpawnRequestMenuClick(event)
    SharedSpawnJoinWaitMenuClick(event)
end

---Gui checked state changed event handlers
---@param event EventData.on_gui_checked_state_changed
---@return nil
function SeparateSpawnsGuiCheckedStateChanged(event)
    SpawnOptsRadioSelect(event)
end

---Gui value changed event handlers
---@param event EventData.on_gui_value_changed
---@return nil
function SeparateSpawnsGuiValueChanged(event)
    SpawnOptsValueChanged(event)
end

---Gui selection state changed event handlers
---@param event EventData.on_gui_selection_state_changed
---@return nil
function SeparateSpawnsGuiSelectionStateChanged(event)
    SpawnOptsSelectionChanged(event)
end