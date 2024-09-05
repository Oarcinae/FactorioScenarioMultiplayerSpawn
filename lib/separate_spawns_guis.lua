-- I made a separate file for all the GUI related functions. Yay me.

local SPAWN_GUI_MAX_WIDTH = 500
local SPAWN_GUI_MAX_HEIGHT = 1000

---A display gui message. Meant to be display the first time a player joins.
---@param player LuaPlayer
---@return boolean
function DisplayWelcomeTextGui(player)
    if ((player.gui.screen["welcome_msg"] ~= nil) or
            (player.gui.screen["spawn_opts"] ~= nil) or
            -- (player.gui.screen["shared_spawn_opts"] ~= nil) or
            (player.gui.screen["join_shared_spawn_wait_menu"] ~= nil) or
            -- (player.gui.screen["buddy_spawn_opts"] ~= nil) or
            (player.gui.screen["buddy_wait_menu"] ~= nil) or
            (player.gui.screen["buddy_request_menu"] ~= nil) or
            (player.gui.screen["wait_for_spawn_dialog"] ~= nil)) then
        log("DisplayWelcomeTextGui called while some other dialog is already displayed!")
        return false
    end

    local welcome_gui = player.gui.screen.add {
        name = "welcome_msg",
        type = "frame",
        direction = "vertical",
        caption = global.ocfg.server_info.welcome_msg_title
    }
    welcome_gui.auto_center = true
    welcome_gui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    welcome_gui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    welcome_gui.style.padding = 5

    local welcome_gui_if = welcome_gui.add {
        type = "frame",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical"
    }

    -- Start with server message.
    AddLabel(welcome_gui_if, nil, global.ocfg.server_info.server_msg, my_label_style)
    -- AddLabel(wGui, "contact_info_msg_lbl1", global.ocfg.server_contact, my_label_style)
    AddSpacer(welcome_gui_if)

    -- Informational message about the scenario
    AddLabel(welcome_gui_if, nil, global.ocfg.server_info.welcome_msg, my_label_style)
    AddSpacer(welcome_gui_if)

    -- Warnings about the scenario
    AddLabel(welcome_gui_if, nil, { "oarc-scenario-warning-msg" }, my_warning_style)

    -- Confirm button
    AddSpacerLine(welcome_gui_if)
    local button_flow = welcome_gui_if.add { type = "flow" }
    button_flow.style.horizontal_align = "right"
    button_flow.style.horizontally_stretchable = true
    button_flow.add {
        name = "welcome_okay_btn",
        tags = { action = "oarc_spawn_options", setting = "welcome_okay" },
        type = "button",
        caption = { "oarc-i-understand" },
        style = "confirm_button"
    }

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

---Creates the spawn menu gui frame to hold all the spawn options.
---@param player LuaPlayer
---@return LuaGuiElement
function CreateSpawnMenuGuiFrame(player)
    local spawn_opts_frame = player.gui.screen.add {
        name = "spawn_opts",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-spawn-options" }
    }
    spawn_opts_frame.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    spawn_opts_frame.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    spawn_opts_frame.auto_center = true
    spawn_opts_frame.style.padding = 5

    local inside_frame = spawn_opts_frame.add {
        name = "spawn_opts_if",
        type = "frame",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical"
    }

    return inside_frame
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
    
    local slider_flow = parent_flow.add {
        type = "flow",
        direction = "horizontal",
        style = "player_input_horizontal_flow"
    }
    slider_flow.style.horizontal_align = "center"

    slider_flow.add {
        type = "label",
        caption = { "oarc-spawn-distance-slider-label" }
    }
    slider_flow.add {
        name = "spawn_distance_slider",
        type = "slider",
        tags = { action = "oarc_spawn_options", setting = "distance_select" },
        minimum_value = minimum_distance,
        maximum_value = maximum_distance,
        value = minimum_distance,
        discrete_slider = true,
        value_step = 1,
    }
    slider_flow.add {
        name = "spawn_distance_slider_value",
        type = "textfield",
        ignored_by_interaction = true,
        caption = minimum_distance,
        style = "slider_value_textfield",
        text = tostring(minimum_distance)
    }
end

---Create the spawn settings frame
---@param parent_flow LuaGuiElement
---@param gameplay OarcConfigGameplaySettings
---@return nil
function CreateSpawnSettingsFrame(parent_flow, gameplay)

    local spawn_settings_frame = parent_flow.add {
        name = "spawn_settings_frame",
        type = "frame",
        direction = "vertical",
        style = "bordered_frame",
    }
    spawn_settings_frame.style.horizontally_stretchable = true
    spawn_settings_frame.style.padding = 5

    AddLabel(spawn_settings_frame, nil, { "oarc-spawn-menu-settings-header" }, my_label_header_style)
    AddLabel(spawn_settings_frame, nil, { "oarc-spawn-menu-settings-info" }, my_label_style)

    -- Pick surface
    if (gameplay.enable_spawning_on_other_surfaces) then
        ShowSurfaceSelectDropdown(spawn_settings_frame)
    end

    -- Radio buttons to pick your team.
    DisplayTeamSelectRadioButtons(spawn_settings_frame, gameplay.enable_separate_teams, gameplay.enable_buddy_spawn)

    -- Allow players to spawn with a moat around their area.
    if (gameplay.allow_moats_around_spawns) then
        spawn_settings_frame.add {
            name = "isolated_spawn_moat_option_checkbox",
            tags = { action = "oarc_spawn_options", setting = "moat_option" },
            type = "checkbox",
            caption = { "oarc-moat-option" },
            state = false
        }
    end

    CreateDistanceSelectSlider(spawn_settings_frame, gameplay.near_spawn_distance, gameplay.far_spawn_distance)
end

---Create a frame and a confim button for player to request SOLO spawn creation
---@param parent_flow LuaGuiElement
---@param enable_shared_spawns boolean
---@param max_shared_players integer
---@return nil
function CreateSoloSpawnFrame(parent_flow, enable_shared_spawns, max_shared_players)

    solo_spawn_frame = parent_flow.add {
        name = "solo_spawn_frame",
        type = "frame",
        direction = "vertical",
        style = "bordered_frame"
    }
    solo_spawn_frame.style.horizontally_stretchable = true
    solo_spawn_frame.style.padding = 5

    AddLabel(solo_spawn_frame, nil, { "oarc-spawn-menu-solo-header" }, my_label_header_style)
    AddLabel(solo_spawn_frame, nil, { "oarc-starting-area-normal" }, my_label_style)

    local button_flow = solo_spawn_frame.add {
        -- name = "solo_spawn_button_flow",
        type = "flow",
        direction = "horizontal"
    }
    button_flow.style.horizontal_align = "right"
    button_flow.style.horizontally_stretchable = true
    button_flow.add {
        name = "spawn_request",
        tags = { action = "oarc_spawn_options", setting = "spawn_request" },
        type = "button",
        caption = { "oarc-solo-spawn" },
        tooltip = { "oarc-solo-spawn-tooltip" },
        style = "confirm_button"
    }

    -- A note about sharing spawns
    if enable_shared_spawns and (max_shared_players > 1) then
        AddLabel(solo_spawn_frame, nil, { "oarc-max-players-shared-spawn", max_shared_players - 1 },  my_note_style)
    end
end

---Create a confirm button for player to request a BUDDY spawn
---@param parent_flow LuaGuiElement
---@return nil
function CreateBuddySpawnRequestButton(parent_flow)
    local buddySpawnRequestFlow = parent_flow.add {
        name = "buddy_spawn_request_flow",
        type = "flow",
        direction = "horizontal"
    }
    buddySpawnRequestFlow.style.horizontal_align = "right"
    buddySpawnRequestFlow.style.horizontally_stretchable = true
    buddySpawnRequestFlow.add {
        name = "buddy_spawn_request",
        tags = { action = "oarc_spawn_options", setting = "buddy_spawn_request" },
        type = "button",
        caption = { "oarc-buddy-spawn" },
        style = "confirm_button"
    }
end

---Creates the shared spawn frame for joining another player's base
---@param parent_flow LuaGuiElement
---@param enable_shared_spawns boolean
---@return nil
function CreateSharedSpawnFrame(parent_flow, enable_shared_spawns)

    local shared_spawn_frame = parent_flow.shared_spawn_frame
    local selected_host = nil ---@type string?

    -- Create the shared spawn frame if it doesn't exist
    if shared_spawn_frame == nil then
        shared_spawn_frame = parent_flow.add {
            name = "shared_spawn_frame",
            type = "frame",
            direction = "vertical",
            style = "bordered_frame"
        }
        shared_spawn_frame.style.horizontally_stretchable = true
        shared_spawn_frame.style.padding = 5

    --- Let's us refresh the frame if it already exists instead of recreating it
    else
        -- Save the previous selected host so we can reselect it after the frame is recreated
        if shared_spawn_frame.shared_spawn_select_dropdown ~= nil then
            local index = shared_spawn_frame.shared_spawn_select_dropdown.selected_index
            if index > 0 then
                selected_host = shared_spawn_frame.shared_spawn_select_dropdown.get_item(index) --[[@as string]]
            end
        end

        for _,child in pairs(shared_spawn_frame.children) do
            child.destroy()
        end
    end

    AddLabel(shared_spawn_frame, nil, { "oarc-spawn-menu-shared-header" }, my_label_header_style)

    if not enable_shared_spawns then
        AddLabel(shared_spawn_frame, nil, { "oarc-shared-spawn-disabled" }, my_warning_style)
        return
    end


    local avail_hosts = GetAvailableSharedSpawns()
    local num_avail_spawns = #avail_hosts

    if (num_avail_spawns > 0) then

        local previous_index = 0
        if selected_host then
            for i,host in ipairs(avail_hosts) do
                if host == selected_host then
                    previous_index = i
                    break
                end
            end
        end

        shared_spawn_frame.add {
            name = "shared_spawn_select_dropdown",
            tags = { action = "oarc_spawn_options", setting = "shared_spawn_select" },
            type = "drop-down",
            items = avail_hosts,
            selected_index = previous_index
        }

        shared_spawn_frame.add {
            name = "join_other_spawn",
            tags = { action = "oarc_spawn_options", setting = "join_other_spawn" },
            type = "button",
            caption = { "oarc-join-someone-avail", num_avail_spawns }
        }

        AddLabel(shared_spawn_frame, "join_other_spawn_lbl1", { "oarc-join-someone-info" }, my_label_style)
    else
        AddLabel(shared_spawn_frame, "join_other_spawn_lbl1", { "oarc-no-shared-avail" }, my_label_style)
    end
end

---Refresh the shared spawn frame if it exists
---@param player LuaPlayer
---@return nil
function RefreshSharedSpawnFrameIfExist(player)
    local spawn_opts = player.gui.screen.spawn_opts
    if spawn_opts == nil then return end
    CreateSharedSpawnFrame(spawn_opts.spawn_opts_if, global.ocfg.gameplay.enable_shared_spawns)
end

---Creates the buddy spawn frame for spawning with a buddy
---@param parent_flow LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateBuddySpawnFrame(parent_flow, player, enable_buddy_spawn)

    local buddy_spawn_frame = parent_flow.buddy_spawn_frame
    local selected_buddy = nil ---@type string?

    -- Create the buddy spawn frame if it doesn't exist
    if buddy_spawn_frame == nil then
        buddy_spawn_frame = parent_flow.add {
            name = "buddy_spawn_frame",
            type = "frame",
            direction = "vertical",
            style = "bordered_frame"
        }
        buddy_spawn_frame.style.horizontally_stretchable = true
        buddy_spawn_frame.style.padding = 5

    --- Let's us refresh the frame if it already exists instead of recreating it
    else
        -- Save the previous selected buddy so we can reselect it after the frame is recreated
        if buddy_spawn_frame.waiting_buddies_dropdown ~= nil then
            local index = buddy_spawn_frame.waiting_buddies_dropdown.selected_index
            if index > 0 then
                selected_buddy = buddy_spawn_frame.waiting_buddies_dropdown.get_item(index) --[[@as string]]
                --- Make sure the buddy is still valid?
                if game.players[selected_buddy] and game.players[selected_buddy].gui.screen.spawn_opts == nil then
                    selected_buddy = nil
                end
            end
        end

        for _,child in pairs(buddy_spawn_frame.children) do
            child.destroy()
        end
    end

    log("Creating buddy spawn frame for: " .. player.name)

    AddLabel(buddy_spawn_frame, nil, { "oarc-spawn-menu-buddy-header" }, my_label_header_style)

    if not enable_buddy_spawn then -- TODO: Confirm if this must also require enable_shared_spawns!!
        -- Add some note about this being disabled?
        AddLabel(buddy_spawn_frame, nil, { "oarc-buddy-spawn-disabled" }, my_label_style)
        return
    end


    -- Warnings and explanations...
    AddLabel(buddy_spawn_frame, nil, { "oarc-buddy-spawn-instructions" }, my_label_style)
    AddSpacer(buddy_spawn_frame)

    
    ---@type string[]
    local avail_buddies = GetOtherPlayersInSpawnMenu(player)

    log("Available buddies: " .. serpent.block(avail_buddies))

    local previous_index = 0
    if selected_buddy then
        for i,host in ipairs(avail_buddies) do
            if host == selected_buddy then
                previous_index = i
                break
            end
        end
    end

    AddLabel(buddy_spawn_frame, nil, { "oarc-buddy-select-info" }, my_label_style)
    buddy_spawn_frame.add {
        name = "waiting_buddies_dropdown",
        tags = { action = "oarc_spawn_options", setting = "buddy_select" },
        type = "drop-down",
        items = avail_buddies,
        selected_index = previous_index
    }
    -- buddySpawnFrame.add { name = "refresh_buddy_list",
    --     type = "button",
    --     caption = { "oarc-buddy-refresh" } }
    -- AddSpacerLine(buddySpawnFlow)

    CreateBuddySpawnRequestButton(buddy_spawn_frame)

    AddLabel(buddy_spawn_frame, "buddy_spawn_lbl1", { "oarc-buddy-spawn-info" }, my_label_style)
    
end

---Refresh the buddy list without recreating any GUI elements
---@param player LuaPlayer
---@param dropdown LuaGuiElement The buddy dropdown element
---@return nil
function RefreshBuddyList(player, dropdown)
    log("Refreshing buddy list for: " .. player.name)
    dropdown.items = GetOtherPlayersInSpawnMenu(player)
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
    ---@type OarcConfigGameplaySettings
    local gameplay = global.ocfg.gameplay

    -- Create the primary frame and a warning label
    local sGui = CreateSpawnMenuGuiFrame(player)
    AddLabel(sGui, "warning_lbl1", { "oarc-click-info-btn-help" }, my_warning_style)

    -- Create the default settings entry for the OarcSpawnChoices table
    ---@type OarcSpawnChoices
    local spawn_choices_entry = {
        surface = global.ocfg.gameplay.default_surface,
        team = SPAWN_TEAM_CHOICE.join_main_team,
        moat = false,
        buddy = nil,
        distance = global.ocfg.gameplay.near_spawn_distance,
        host = nil
    }
    global.ocore.spawnChoices[player.name] = spawn_choices_entry

    CreateSpawnSettingsFrame(sGui, gameplay) -- The settings for configuring a spawn
    CreateSoloSpawnFrame(sGui, gameplay.enable_shared_spawns, gameplay.number_of_players_per_shared_spawn) -- The primary method of spawning
    CreateSharedSpawnFrame(sGui, gameplay.enable_shared_spawns) -- Spawn options to join another player's base.
    CreateBuddySpawnFrame(sGui, player, gameplay.enable_buddy_spawn) -- Awesome buddy spawning system
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

    elseif (tags.setting == "moat_option") then
        global.ocore.spawnChoices[player.name].moat = event.element.state
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

    if (tags.setting == "welcome_okay") then
        if (player.gui.screen.welcome_msg ~= nil) then
            player.gui.screen.welcome_msg.destroy()
        end
        DisplaySpawnOptions(player)
    elseif (tags.setting == "spawn_request") then
        SpawnRequest(player)
    elseif (tags.setting == "join_other_spawn") then
        RequestToJoinSharedSpawn(player)
    elseif (tags.setting == "cancel_shared_spawn_wait_menu") then
        CancelSharedSpawnRequest(player)
    elseif (tags.setting == "buddy_select") then
        RefreshBuddyList(player, event.element)
    elseif (tags.setting == "buddy_spawn_request") then
        RequestBuddySpawn(player)
    elseif (tags.setting == "cancel_buddy_wait_menu") then
        CancelBuddySpawnWaitMenu(player)
    elseif (tags.setting == "accept_buddy_request") then
        AcceptBuddyRequest(player, tags.requesting_buddy_name --[[@as string]])
    elseif (tags.setting == "reject_buddy_request") then
        RejectBuddyRequest(player, tags.requesting_buddy_name --[[@as string]])
    end
end

---Request a buddy spawn. Requires the buddy to accept or reject the request.
---@param player LuaPlayer
---@return nil
function RequestBuddySpawn(player)
    local buddy_choice = global.ocore.spawnChoices[player.name].buddy
    if (buddy_choice == nil) then player.print({ "oarc-invalid-buddy" }) return end
    local buddy = game.players[buddy_choice]
    if (buddy == nil) then player.print({ "oarc-invalid-buddy" }) return end

    DisplayBuddySpawnWaitMenu(player)
    DisplayBuddySpawnRequestMenu(buddy, player.name)
end

---Handle buddy spawn wait menu cancel (waiting for buddy to accept or decline proposal)
---@param player LuaPlayer
---@return nil
function CancelBuddySpawnWaitMenu(player)

    ---@type OarcSpawnChoices
    local spawn_choices = global.ocore.spawnChoices[player.name]
    local buddy = game.players[spawn_choices.buddy]

    player.gui.screen.buddy_wait_menu.destroy()
    DisplaySpawnOptions(player)

    -- Catch a case where the buddy has left the game early and no longer exists.
    if (buddy == nil) then
        return
    end

    if (buddy.gui.screen.buddy_request_menu ~= nil) then
        buddy.gui.screen.buddy_request_menu.destroy()
        DisplaySpawnOptions(buddy)
    end

    buddy.print({ "oarc-buddy-cancel-request", player.name })
end

---Request to join someone's shared spawn
---@param player LuaPlayer
---@return nil
function RequestToJoinSharedSpawn(player)

    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end

    local host_name = global.ocore.spawnChoices[player.name].host
    if (host_name == nil) then player.print({ "oarc-no-shared-spawn-selected" }) return end

    -- Clear the spawn options gui
    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end

    if ((game.players[host_name] ~= nil) and (game.players[host_name].connected)) then
        table.insert(global.ocore.sharedSpawns[host_name].joinQueue, player.name)

        -- Display wait menu with cancel button.
        DisplaySharedSpawnJoinWaitMenu(player)

        -- Tell other player they are requesting a response.
        game.players[host_name].print({ "oarc-player-requesting-join-you", player.name })
        OarcGuiRefreshContent(game.players[host_name])
    else
        player.print({ "oarc-invalid-host-shared-spawn" })

        DisplaySpawnOptions(player)
    end
end


---Cancel shared spawn request from the waiting menu
---@param player LuaPlayer
---@return nil
function CancelSharedSpawnRequest(player)

    --- Destroy the waiting menu and display the spawn options again.
    player.gui.screen.join_shared_spawn_wait_menu.destroy()
    DisplaySpawnOptions(player)

    -- Find and remove the player from the joinQueue they were in.
    for host_name, shared_spawn in pairs(global.ocore.sharedSpawns --[[@as OarcSharedSpawnsTable]]) do
        for index, requestor in pairs(shared_spawn.joinQueue) do
            if (requestor == player.name) then
                global.ocore.sharedSpawns[host_name].joinQueue[index] = nil
                local host_player = game.players[host_name]
                if (host_player ~= nil) and (host_player.connected) then
                    game.players[host_name].print({ "oarc-player-cancel-join-request", player.name })
                    OarcGuiRefreshContent(game.players[host_name])
                end
                return -- Found and removed player from joinQueue
            end
        end
    end

    log("ERROR! Failed to remove player from joinQueue?!")
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

    elseif (tags.setting == "shared_spawn_select") then
        local index = event.element.selected_index
        if (index > 0) then
            local hostName = event.element.get_item(index) --[[@as string]]
            global.ocore.spawnChoices[player.name].host = hostName
            log("GUI DEBUG Selected host: " .. hostName)
        else
            global.ocore.spawnChoices[player.name].host = nil
        end
    
    elseif (tags.setting == "buddy_select") then
        local index = event.element.selected_index
        if (index > 0) then
            local buddyName = event.element.get_item(index) --[[@as string]]
            global.ocore.spawnChoices[player.name].buddy = buddyName
            log("GUI DEBUG Selected buddy: " .. buddyName)
        else
            global.ocore.spawnChoices[player.name].buddy = nil
        end
    end
end

---Requests the generation of a spawn point for the player
---@param player LuaPlayer
---@return nil
function SpawnRequest(player)
    -- Get the player's spawn choices
    ---@type OarcSpawnChoices
    local spawn_choices = global.ocore.spawnChoices[player.name]
    if (spawn_choices == nil) then error("ERROR! No spawn choices found for player!") return end

    -- Cache some useful variables
    local gameplay = global.ocfg.gameplay
    local surface = game.surfaces[spawn_choices.surface]

    -- Create a new force for player if they choose that radio button
    if spawn_choices.team ~= SPAWN_TEAM_CHOICE.join_main_team then
        CreatePlayerCustomForce(player)
    end

    -- Find coordinates of a good place to spawn
    local newSpawn = { x = 0, y = 0 }
    -- TODO: Rewrite this function to make use of spawnChoices.distance!!
    newSpawn = FindUngeneratedCoordinates(surface, spawn_choices.distance)

    -- If that fails, find a random map edge in a rand direction.
    if ((newSpawn.x == 0) and (newSpawn.y == 0)) then
        newSpawn = FindMapEdge(GetRandomVector(), surface)
        log("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
    end

    -- Create that player's spawn in the global vars
    ChangePlayerSpawn(player, spawn_choices.surface, newSpawn)

    -- Send the player there
     -- global.ocfg.enable_vanilla_spawns --TODO: Vanilla spawn points are not implemented yet.
    QueuePlayerForDelayedSpawn(player.name, spawn_choices.surface, newSpawn, spawn_choices.moat, false)
    SendBroadcastMsg({ "oarc-player-is-joining-far", player.name, spawn_choices.surface })

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
-- ---@param event EventData.on_gui_click
-- ---@return nil
-- function SpawnOptsGuiClick(event)
--     if not event.element.valid then return end
--     local player = game.players[event.player_index]
--     local elemName = event.element.name

--     if not player then
--         log("Another gui click happened with no valid player...")
--         return
--     end

--     if (player.gui.screen.spawn_opts == nil) then
--         return -- Gui event unrelated to this gui.
--     end

--     local pgcs = player.gui.screen.spawn_opts

--     local joinOwnTeamRadio, moatChoice = false, false
--     local surfaceName = global.ocfg.gameplay.default_surface -- Default to default surface
--     local surface = game.surfaces[surfaceName]

--     -- Check if a valid button on the gui was pressed
--     -- and delete the GUI
--     if ((elemName == "default_spawn_btn") or
--             (elemName == "isolated_spawn_near") or
--             (elemName == "isolated_spawn_far") or
--             (elemName == "join_other_spawn") or
--             (elemName == "buddy_spawn") or
--             (elemName == "join_other_spawn_check")) then
--         if (global.ocfg.gameplay.enable_separate_teams) then
--             joinMainTeamRadio = pgcs.spawn_solo_flow.isolated_spawn_main_team_radio.state
--             joinOwnTeamRadio = pgcs.spawn_solo_flow.isolated_spawn_new_team_radio.state
--         else
--             joinMainTeamRadio = true
--             joinOwnTeamRadio = false
--         end
--         ---TODO: Vanilla spawn points are not implemented yet.  and not global.ocfg.enable_vanilla_spawns
--         if (global.ocfg.gameplay.allow_moats_around_spawns and
--                 (pgcs.spawn_solo_flow.isolated_spawn_moat_option_checkbox ~= nil)) then
--             moatChoice = pgcs.spawn_solo_flow.isolated_spawn_moat_option_checkbox.state
--         end

--         -- Override the default surface if the player selected a different one.
--         local surfaceDropdownIndex = pgcs.spawn_solo_flow.surfaces_horizontal_flow.surface_select_dropdown.selected_index

--         -- Index 0 means nothing was selected!
--         if (surfaceDropdownIndex ~= 0) then
--             surfaceName = pgcs.spawn_solo_flow.surfaces_horizontal_flow.surface_select_dropdown.get_item(surfaceDropdownIndex) --[[@as string]]
--             surface = game.surfaces[surfaceName]
--         end

--         -- if (global.ocfg.enable_vanilla_spawns and
--         --     (pgcs.spawn_solo_flow.isolated_spawn_vanilla_option_checkbox ~= nil)) then
--         --     vanillaChoice = pgcs.spawn_solo_flow.isolated_spawn_vanilla_option_checkbox.state
--         -- end
--         pgcs.destroy()
--     else
--         return -- Do nothing, no valid element item was clicked.
--     end

--     -- Default spawn should always spawn on a default surface I think?
--     if (elemName == "default_spawn_btn") then
--         GivePlayerStarterItems(player)

--         local defaultSurfaceName = global.ocfg.gameplay.default_surface
--         local defaultSurface = game.surfaces[defaultSurfaceName]
--         local spawnPosition = player.force.get_spawn_position(defaultSurface)

--         ChangePlayerSpawn(player, defaultSurfaceName, spawnPosition)
--         SendBroadcastMsg({ "oarc-player-is-joining-main-force", player.name, defaultSurfaceName })
--         ChartArea(player.force, player.position,
--             math.ceil(global.ocfg.surfaces_config[defaultSurfaceName].spawn_config.general.spawn_radius_tiles / CHUNK_SIZE),
--             defaultSurface)
--         -- Unlock spawn control gui tab
--         SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_TAB_NAME, true)

--     elseif ((elemName == "isolated_spawn_near") or (elemName == "isolated_spawn_far")) then
--         --- MOVED
--     elseif (elemName == "join_other_spawn") then
--         DisplaySharedSpawnOptions(player)

--         -- Provide a way to refresh the gui to check if people have shared their
--         -- bases.
--     elseif (elemName == "join_other_spawn_check") then
--         DisplaySpawnOptions(player)

--         -- Hacky buddy spawn system
--     elseif (elemName == "buddy_spawn") then
--         table.insert(global.ocore.waitingBuddies --[[@as OarcWaitingBuddiesTable]], player.name)
--         SendBroadcastMsg({ "oarc-looking-for-buddy", player.name })

--         DisplayBuddySpawnOptions(player)
--     end
-- end

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
        caption = { "oarc-cancel-button-caption" },
        style = "back_button" }
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
    

    local button_flow = sGui.add {
        type = "flow",
        direction = "horizontal",
        style = "dialog_buttons_horizontal_flow"
    }
    button_flow.style.horizontally_stretchable = true

    local cancel_button = button_flow.add {
        name = "cancel_shared_spawn_wait_menu",
        type = "button",
        tags = { action = "oarc_spawn_options", setting = "cancel_shared_spawn_wait_menu" },
        caption = { "oarc-cancel-button-caption" },
        tooltip = { "oarc-return-to-previous-tooltip" },
        style = "back_button"
    }
    cancel_button.style.horizontal_align = "left"
end

---Handle the gui click of the shared spawn join wait menu
---@param event EventData.on_gui_click
---@return nil
function SharedSpawnJoinWaitMenuClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local elem_name = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.join_shared_spawn_wait_menu == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Check if player is cancelling the request.
    if (elem_name == "cancel_shared_spawn_wait_menu") then
        player.gui.screen.join_shared_spawn_wait_menu.destroy()
        DisplaySpawnOptions(player)

        -- Find and remove the player from the joinQueue they were in.
        for host_name, shared_spawn in pairs(global.ocore.sharedSpawns --[[@as OarcSharedSpawnsTable]]) do
            for index, requestor in pairs(shared_spawn.joinQueue) do
                if (requestor == player.name) then
                    global.ocore.sharedSpawns[host_name].joinQueue[index] = nil
                    local host_player = game.players[host_name]
                    if (host_player ~= nil) and (host_player.connected) then
                        game.players[host_name].print({ "oarc-player-cancel-join-request", player.name })
                        OarcGuiRefreshContent(game.players[host_name])
                    end
                    return
                end
            end
        end

        log("ERROR! Failed to remove player from joinQueue!")
    end
end

-- ---Display the buddy spawn menu
-- ---@param player LuaPlayer
-- ---@return nil
-- function DisplayBuddySpawnOptions(player)
--     local buddyGui = player.gui.screen.add { name = "buddy_spawn_opts",
--         type = "frame",
--         direction = "vertical",
--         caption = { "oarc-buddy-spawn-options" } }
--     buddyGui.auto_center = true
--     buddyGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
--     buddyGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT

--     ---@type OarcConfigGameplaySettings
--     local gameplay = global.ocfg.gameplay

--     -- Warnings and explanations...
--     AddLabel(buddyGui, "buddy_info_msg", { "oarc-buddy-spawn-instructions" }, my_label_style)
--     AddSpacer(buddyGui)

--     -- The buddy spawning options.
--     local buddySpawnFlow = buddyGui.add { name = "spawn_buddy_flow",
--         type = "frame",
--         direction = "vertical",
--         style = "bordered_frame" }

--     ---@type string[]
--     local buddyList = {}
--     for _, buddyName in pairs(global.ocore.waitingBuddies --[[@as OarcWaitingBuddiesTable]]) do
--         if (buddyName ~= player.name) then
--             table.insert(buddyList, buddyName)
--         end
--     end

--     AddLabel(buddySpawnFlow, "drop_down_msg_lbl1", { "oarc-buddy-select-info" }, my_label_style)
--     buddySpawnFlow.add {
--         name = "waiting_buddies_dropdown",
--         tags = { action = "oarc_spawn_options", setting = "buddy_select" },
--         type = "drop-down",
--         items = buddyList
--     }
--     buddySpawnFlow.add {
--         name = "refresh_buddy_list",
--         type = "button",
--         caption = { "oarc-buddy-refresh" }
--     }
--     -- AddSpacerLine(buddySpawnFlow)

--     -- Pick surface
--     if (gameplay.enable_spawning_on_other_surfaces) then

--         local surfacesHorizontalFlow = buddySpawnFlow.add { name = "buddy_surfaces_horizontal_flow",
--             type = "flow",
--             direction = "horizontal" }

--         ---@type string[]
--         local surfaceList = {}
--         for surfaceName,allowed in pairs(global.ocore.surfaces) do
--             if allowed then
--                 table.insert(surfaceList, surfaceName)
--             end
--         end

--         AddLabel(surfacesHorizontalFlow, "buddySurfacesHorizontalFlowLabel", "Select Surface: ", my_label_style)
--         surfacesHorizontalFlow.add { name = "buddy_surface_select_dropdown",
--             type = "drop-down",
--             items = surfaceList,
--             selected_index = 1}
--     end

--     -- Allow picking of teams
--     if (gameplay.enable_separate_teams) then
--         buddySpawnFlow.add { name = "buddy_spawn_main_team_radio",
--             type = "radiobutton",
--             caption = { "oarc-join-main-team-radio" },
--             state = true }
--         buddySpawnFlow.add { name = "buddy_spawn_new_team_radio",
--             type = "radiobutton",
--             caption = { "oarc-create-own-team-radio" },
--             state = false }
--         buddySpawnFlow.add { name = "buddy_spawn_buddy_team_radio",
--             type = "radiobutton",
--             caption = { "oarc-create-buddy-team" },
--             state = false }
--     end
--     if (gameplay.allow_moats_around_spawns) then
--         buddySpawnFlow.add { name = "buddy_spawn_moat_option_checkbox",
--             type = "checkbox",
--             caption = { "oarc-moat-option" },
--             state = false }
--     end

--     -- AddSpacerLine(buddySpawnFlow)
--     buddySpawnFlow.add { name = "buddy_spawn_request_near",
--         type = "button",
--         caption = { "oarc-buddy-spawn-near" },
--         style = "confirm_button" }
--     buddySpawnFlow.add { name = "buddy_spawn_request_far",
--         type = "button",
--         caption = { "oarc-buddy-spawn-far" },
--         style = "confirm_button" }

--     AddSpacer(buddyGui)
--     buddyGui.add { name = "buddy_spawn_cancel",
--         type = "button",
--         caption = { "oarc-cancel-button-caption" },
--         style = "back_button" }

--     -- Some final notes
--     AddSpacerLine(buddyGui)
--     if (gameplay.number_of_players_per_shared_spawn > 0) then
--         AddLabel(buddyGui, "buddy_max_players_lbl1",
--             { "oarc-max-players-shared-spawn", gameplay.number_of_players_per_shared_spawn - 1 },
--             my_note_style)
--     end
--     local spawn_distance_notes = { "oarc-spawn-dist-notes" }
--     AddLabel(buddyGui, "note_lbl1", spawn_distance_notes, my_note_style)
-- end

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
            -- DisplayBuddySpawnOptions(player)
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

    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end

    local buddy_wait_menu = player.gui.screen.add {
        name = "buddy_wait_menu",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-waiting-for-buddy" }
    }

    buddy_wait_menu.auto_center = true
    buddy_wait_menu.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    buddy_wait_menu.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    buddy_wait_menu.style.padding = 5

    local buddy_wait_menu_if = buddy_wait_menu.add {
        type = "frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }

    -- Warnings and explanations...
    AddLabel(buddy_wait_menu_if, nil, { "oarc-wait-buddy-select-yes" }, my_warning_style)
    AddSpacer(buddy_wait_menu_if)

    local button_flow = buddy_wait_menu_if.add {
        type = "flow",
        direction = "horizontal",
        style = "dialog_buttons_horizontal_flow"
    }
    button_flow.style.horizontally_stretchable = true

    local cancel_button = button_flow.add {
        name = "cancel_buddy_wait_menu",
        tags = { action = "oarc_spawn_options", setting = "cancel_buddy_wait_menu" },
        type = "button",
        style = "back_button",
        caption = { "oarc-cancel-button-caption" },
        tooltip = { "oarc-return-to-previous-tooltip" },
    }
    cancel_button.style.horizontal_align = "left"
end


---Display the buddy spawn request menu
---@param player LuaPlayer The player that is receiving the buddy request
---@param requesting_buddy_name string The name of the player that is requesting to buddy spawn
---@return nil
function DisplayBuddySpawnRequestMenu(player, requesting_buddy_name)

    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end

    local buddy_request_gui = player.gui.screen.add {
        name = "buddy_request_menu",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-buddy-spawn-request-header" }
    }
    buddy_request_gui.auto_center = true
    buddy_request_gui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    buddy_request_gui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    buddy_request_gui.style.padding = 5

    local buddy_request_gui_if = buddy_request_gui.add {
        type = "frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }


    -- Warnings and explanations...
    AddLabel(buddy_request_gui_if, nil, { "oarc-buddy-requesting-from-you", requesting_buddy_name }, my_warning_style)

    ---@type OarcSpawnChoices
    local spawn_choices = global.ocore.spawnChoices[requesting_buddy_name]

    ---@type LocalisedString
    local teamText = "error!"
    if (spawn_choices.team == SPAWN_TEAM_CHOICE.join_main_team) then
        teamText = { "oarc-buddy-txt-main-team" }
    elseif (spawn_choices.team == SPAWN_TEAM_CHOICE.join_own_team) then
        teamText = { "oarc-buddy-txt-new-teams" }
    elseif (spawn_choices.team == SPAWN_TEAM_CHOICE.join_buddy_team) then
        teamText = { "oarc-buddy-txt-buddy-team" }
    end

    ---@type LocalisedString
    local moatText = " "
    if (spawn_choices.moat) then
        moatText = { "oarc-buddy-txt-moat" }
    end

    ---@type LocalisedString
    local surfaceText = { "oarc-buddy-txt-surface", spawn_choices.surface}

    ---@type LocalisedString
    local distText = { "oarc-buddy-txt-distance", spawn_choices.distance}

    local requestText = { "", requesting_buddy_name, { "oarc-buddy-txt-would-like" }, teamText, { "oarc-buddy-txt-next-to-you" },
        moatText, surfaceText, distText }
    AddLabel(buddy_request_gui_if, nil, requestText, my_warning_style)
    AddSpacer(buddy_request_gui_if)

    local button_flow = buddy_request_gui.add {
        type = "flow",
        direction = "horizontal",
        style = "dialog_buttons_horizontal_flow"
    }
    button_flow.style.horizontally_stretchable = true

    local reject_button = button_flow.add {
        name = "reject_buddy_request",
        tags = { action = "oarc_spawn_options", setting = "reject_buddy_request", requesting_buddy_name = requesting_buddy_name },
        type = "button",
        style = "red_back_button",
        caption = { "oarc-reject" }
    }
    reject_button.style.horizontal_align = "left"

    local dragger = button_flow.add{type="empty-widget", style="draggable_space"}
    dragger.style.horizontally_stretchable = true
    dragger.style.height = 30

    local accept_button = button_flow.add {
        name = "accept_buddy_request",
        tags = { action = "oarc_spawn_options", setting = "accept_buddy_request", requesting_buddy_name = requesting_buddy_name },
        type = "button",
        style = "confirm_button",
        caption = { "oarc-accept" }
    }
    accept_button.style.horizontal_align = "right"

end


function AcceptBuddyRequest(player, requesting_buddy_name)

    ---@type OarcSpawnChoices
    local spawn_choices = global.ocore.spawnChoices[requesting_buddy_name]
    local requesting_buddy = game.players[requesting_buddy_name]

    if (requesting_buddy.gui.screen.buddy_wait_menu ~= nil) then
        requesting_buddy.gui.screen.buddy_wait_menu.destroy()
    end
    if (player.gui.screen.buddy_request_menu ~= nil) then
        player.gui.screen.buddy_request_menu.destroy()
    end

    -- Create a new spawn point
    local newSpawn = { x = 0, y = 0 }

    -- Create a new force for each player if they chose that option
    if spawn_choices.team == SPAWN_TEAM_CHOICE.join_own_team then
        CreatePlayerCustomForce(player)
        CreatePlayerCustomForce(requesting_buddy)

    -- Create a new force for the combined players if they chose that option
    elseif spawn_choices.team == SPAWN_TEAM_CHOICE.join_buddy_team then
        local buddyForce = CreatePlayerCustomForce(requesting_buddy)
        player.force = buddyForce
    end

    ---@type OarcConfigGameplaySettings
    local gameplay = global.ocfg.gameplay
    local surface = game.surfaces[spawn_choices.surface]

    -- Find coordinates of a good place to spawn
    newSpawn = FindUngeneratedCoordinates(surface, spawn_choices.distance)

    -- If that fails, find a random map edge in a rand direction.
    if ((newSpawn.x == 0) and (newSpawn.x == 0)) then
        newSpawn = FindMapEdge(GetRandomVector(), surface)
        log("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
    end

    -- Create that spawn in the global vars
    local buddySpawn = { x = 0, y = 0 }
    if (spawn_choices.moat) then
        buddySpawn = {
            x = newSpawn.x + (global.ocfg.surfaces_config[spawn_choices.surface].spawn_config.general.spawn_radius_tiles * 2) + 10,
            y = newSpawn.y
        }
    else
        buddySpawn = { x = newSpawn.x + (global.ocfg.surfaces_config[spawn_choices.surface].spawn_config.general.spawn_radius_tiles * 2), y = newSpawn.y }
    end
    ChangePlayerSpawn(player, spawn_choices.surface, newSpawn) --TODO: Add support for multiple surfaces
    ChangePlayerSpawn(requesting_buddy, spawn_choices.surface, buddySpawn)

    -- Send the player there
    QueuePlayerForDelayedSpawn(player.name, spawn_choices.surface, newSpawn, spawn_choices.moat, false)
    QueuePlayerForDelayedSpawn(requesting_buddy_name, spawn_choices.surface, buddySpawn, spawn_choices.moat, false)
    SendBroadcastMsg(requesting_buddy_name .. " and " .. player.name .. " are joining the game together!")

    -- Unlock spawn control gui tab
    SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_TAB_NAME, true)
    SetOarcGuiTabEnabled(requesting_buddy, OARC_SPAWN_CTRL_TAB_NAME, true)

    player.print({ "oarc-please-wait" })
    player.print({ "", { "oarc-please-wait" }, "!" })
    player.print({ "", { "oarc-please-wait" }, "!!" })
    requesting_buddy.print({ "oarc-please-wait" })
    requesting_buddy.print({ "", { "oarc-please-wait" }, "!" })
    requesting_buddy.print({ "", { "oarc-please-wait" }, "!!" })

    global.ocore.buddyPairs[player.name] = requesting_buddy_name
    global.ocore.buddyPairs[requesting_buddy_name] = player.name
end

---Rejects a buddy spawn request proposal
---@param player LuaPlayer The player that is rejecting the buddy request
---@param requesting_buddy_name string The name of the player that is requesting to buddy spawn
---@return nil
function RejectBuddyRequest(player, requesting_buddy_name)

    player.gui.screen.buddy_request_menu.destroy()
    DisplaySpawnOptions(player)

    local requester_buddy = game.players[requesting_buddy_name]

    if (requester_buddy == nil) then
        return
    end

    if (requester_buddy.gui.screen.buddy_wait_menu ~= nil) then
        requester_buddy.gui.screen.buddy_wait_menu.destroy()
        DisplaySpawnOptions(requester_buddy)
    end

    requester_buddy.print({ "oarc-buddy-declined", player.name })
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


---Get a list of OTHER players currently in the spawn menu
---@param self_player LuaPlayer
---@return table
function GetOtherPlayersInSpawnMenu(self_player)
    local other_players_in_spawn_menu = {}
    for _, player in pairs(game.connected_players) do
        if (player.gui.screen.spawn_opts ~= nil) and (self_player ~= player) then
            table.insert(other_players_in_spawn_menu, player.name)
        end
    end
    return other_players_in_spawn_menu
end

---Gui click event handlers
---@param event EventData.on_gui_click
---@return nil
function SeparateSpawnsGuiClick(event)
    WelcomeTextGuiClick(event)

    SpawnChoicesGuiClickNew(event)

    -- SpawnOptsGuiClick(event)
    -- SharedSpwnOptsGuiClick(event)
    -- BuddySpawnOptsGuiClick(event)
    -- BuddySpawnWaitMenuClick(event)
    -- BuddySpawnRequestMenuClick(event)
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