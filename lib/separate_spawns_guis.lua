-- I made a separate file for all the GUI related functions. Yay me.

local SPAWN_GUI_MAX_WIDTH = 500
local SPAWN_GUI_MAX_HEIGHT = 1000

---A display gui message. Meant to be display the first time a player joins.
---@param player LuaPlayer
---@return boolean
function DisplayWelcomeTextGui(player)
    if ((player.gui.screen["join_shared_spawn_wait_menu"] ~= nil) or
            (player.gui.screen["buddy_wait_menu"] ~= nil) or
            (player.gui.screen["buddy_request_menu"] ~= nil) or
            (player.gui.screen["wait_for_spawn_dialog"] ~= nil)) then
        log("DisplayWelcomeTextGui called while some other dialog is already displayed!")
        return false
    end

    --Delete existing guis
    if (player.gui.screen.welcome_msg ~= nil) then
        player.gui.screen.welcome_msg.destroy()
    end
    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end
    if (player.gui.screen.self_reset_confirm ~= nil) then
        player.gui.screen.self_reset_confirm.destroy()
    end

    local welcome_gui = player.gui.screen.add {
        name = "welcome_msg",
        type = "frame",
        direction = "vertical",
        caption = storage.ocfg.server_info.welcome_msg_title
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

    -- Informational message about the scenario
    if (storage.ocfg.server_info.welcome_msg ~= " ") then
        AddLabel(welcome_gui_if, nil, storage.ocfg.server_info.welcome_msg, my_label_style)
        AddSpacer(welcome_gui_if)
    end

    -- Warnings about the scenario
    AddLabel(welcome_gui_if, nil, { "oarc-scenario-info-warn-msg" }, my_note_style)

    -- Confirm button
    local button_flow = welcome_gui.add {
        type = "flow",
        style = "dialog_buttons_horizontal_flow",
    }
    button_flow.style.horizontally_stretchable = true

    local dragger = button_flow.add {
        type = "empty-widget",
        style = "draggable_space",
    }
    dragger.style.left_margin = 0
    dragger.style.horizontally_stretchable = true
    dragger.style.height = 30

    local confirm_button = button_flow.add {
        name = "welcome_okay_btn",
        tags = { action = "oarc_spawn_options", setting = "welcome_okay" },
        type = "button",
        caption = { "oarc-i-understand" },
        style = "confirm_button",
    }
    confirm_button.style.horizontal_align = "right"

    return true
end

---Handle the gui click of the welcome msg
---@param event EventData.on_gui_click
---@return nil
function WelcomeTextGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name

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
        style = "inside_shallow_frame",
        direction = "vertical"
    }

    -- SUB HEADING w/ LABEL
    local subhead = inside_frame.add{
        type="frame",
        name="sub_header",
        style = "subheader_frame"
    }
    subhead.style.height = 46
    subhead.style.horizontally_stretchable = true
    AddLabel(subhead, "warning_lbl1", { "oarc-click-info-btn-help" }, my_note_style)

    return inside_frame
end

---Show the surface select dropdown
---@param parent_flow LuaGuiElement
---@return nil
function CreateSurfaceSelectDropdown(parent_flow)
    local surfacesHorizontalFlow = parent_flow.add {
        name = "surfaces_horizontal_flow",
        type = "flow",
        direction = "horizontal"
    }

    local surface_list = GetAllowedSurfaces()

    -- Get the index of the default surface if it exists
    local default_surface_index = 1
    for i,surface in ipairs(surface_list) do
        if (surface == storage.ocfg.gameplay.default_surface) then
            default_surface_index = i
            break
        end
    end

    AddLabel(surfacesHorizontalFlow, "surfacesHorizontalFlowLabel", "Select Surface: ", my_label_style)
    surfacesHorizontalFlow.add {
        name = "surface_select_dropdown",
        tags = { action = "oarc_spawn_options", setting = "surface_select" },
        type = "drop-down",
        items = surface_list,
        selected_index = default_surface_index,
        tooltip = { "oarc-surface-select-tooltip" },
        enabled = #surface_list > 1
    }
end

---Display the team select radio buttons
---@param parent_flow LuaGuiElement
---@param enable_main_team boolean
---@param enable_separate_teams boolean
---@return nil
function DisplayTeamSelectRadioButtons(parent_flow, enable_main_team, enable_separate_teams)
    if enable_main_team then
        parent_flow.add {
            name = "isolated_spawn_main_team_radio",
            tags = { action = "oarc_spawn_options", setting = "team_select", value = SPAWN_TEAM_CHOICE.join_main_team },
            type = "radiobutton",
            caption = { "oarc-join-main-team-radio" },
            tooltip = { "oarc-join-main-team-tooltip" },
            -- If separate teams are not enabled, default to joining the main team, and disable the radio buttons.
            state = true,
            -- ignored_by_interaction = not enable_separate_teams,
            -- enabled = enable_separate_teams
        }
    end

    if (enable_separate_teams) then
        parent_flow.add {
            name = "isolated_spawn_new_team_radio",
            tags = { action = "oarc_spawn_options", setting = "team_select", value = SPAWN_TEAM_CHOICE.join_own_team },
            type = "radiobutton",
            caption = { "oarc-create-own-team-radio" },
            tooltip = { "oarc-create-own-team-tooltip" },
            -- If main team is not enabled, default to joining the a separate team, and disable the radio buttons.
            state = not enable_main_team,
            -- ignored_by_interaction = not enable_main_team,
            -- enabled = enable_main_team
        }
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
    slider_flow.style.horizontally_stretchable = true

    local label = slider_flow.add {
        type = "label",
        caption = { "oarc-spawn-distance-slider-label" },
        tooltip = { "oarc-spawn-distance-slider-tooltip" }
    }
    label.style.horizontal_align = "left"
    local slider = slider_flow.add {
        name = "spawn_distance_slider",
        type = "slider",
        tags = { action = "oarc_spawn_options", setting = "distance_select" },
        minimum_value = minimum_distance,
        maximum_value = maximum_distance,
        value = minimum_distance,
        discrete_slider = true,
        value_step = 1,
        tooltip = { "oarc-spawn-distance-slider-tooltip" }
    }
    slider.style.horizontally_stretchable = true
    local text_value = slider_flow.add {
        name = "spawn_distance_slider_value",
        type = "textfield",
        ignored_by_interaction = true,
        caption = minimum_distance,
        style = "slider_value_textfield",
        text = tostring(minimum_distance)
    }
    text_value.style.horizontal_align = "right"
    text_value.style.width = 50
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
    spawn_settings_frame.style.margin = 4
    spawn_settings_frame.style.bottom_margin = 0

    AddLabel(spawn_settings_frame, nil, { "oarc-spawn-menu-settings-header" }, my_label_header_style)
    AddLabel(spawn_settings_frame, nil, { "oarc-spawn-menu-settings-info" }, my_label_style)

    -- Pick surface
    CreateSurfaceSelectDropdown(spawn_settings_frame)

    -- Radio buttons to pick your team.
    DisplayTeamSelectRadioButtons(spawn_settings_frame, gameplay.enable_main_team, gameplay.enable_separate_teams)

    -- Allow players to spawn with a moat around their area.
    if (gameplay.allow_moats_around_spawns) then
        spawn_settings_frame.add {
            name = "isolated_spawn_moat_option_checkbox",
            tags = { action = "oarc_spawn_options", setting = "moat_option" },
            type = "checkbox",
            caption = { "oarc-moat-option" },
            state = true, -- Default to true
            tooltip = { "oarc-moat-option-tooltip" }
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
    solo_spawn_frame.style.margin = 4
    solo_spawn_frame.style.bottom_margin = 0

    AddLabel(solo_spawn_frame, nil, { "oarc-spawn-menu-solo-header" }, my_label_header_style)
    AddLabel(solo_spawn_frame, nil, { "oarc-starting-area-normal" }, my_label_style)
    
    -- A note about sharing spawns
    if enable_shared_spawns and (max_shared_players > 1) then
        AddLabel(solo_spawn_frame, nil, { "oarc-max-players-shared-spawn", max_shared_players - 1 },  my_label_style)
    end

    local button_flow = solo_spawn_frame.add {
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
        style = "green_button"
    }
end

---Creates the shared spawn frame for joining another player's base
---@param parent_flow LuaGuiElement
---@param enable_shared_spawns boolean
---@return nil
function CreateSharedSpawnFrame(parent_flow, enable_shared_spawns)

    local shared_spawn_frame = parent_flow.shared_spawn_frame
    local prev_selected_host = nil ---@type string?
    local prev_selected_spawn = nil ---@type OarcUniqueSpawn?

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
        shared_spawn_frame.style.margin = 4
        shared_spawn_frame.style.bottom_margin = 0

    --- Let's us refresh the frame if it already exists instead of recreating it
    else
        -- Save the previous selected host so we can reselect it after the frame is recreated
        if (shared_spawn_frame.shared_spawn_horizontal_flow ~= nil) then
            local dropdown = shared_spawn_frame.shared_spawn_horizontal_flow.shared_spawn_select_dropdown
            local index = dropdown.selected_index
            if index > 0 then
                prev_selected_host = dropdown.get_item(index) --[[@as string]]
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


    local avail_spawns = GetAvailableSharedSpawns()
    local num_avail_spawns = #avail_spawns.hosts

    if (num_avail_spawns > 0) then

        AddLabel(shared_spawn_frame, nil, { "oarc-join-someone-info" }, my_label_style)

        local new_selected_index = 0
        if prev_selected_host then
            for i,host in ipairs(avail_spawns.hosts) do
                if host == prev_selected_host then
                    new_selected_index = i
                    break
                end
            end
        end

        local horizontal_flow = shared_spawn_frame.add {
            name = "shared_spawn_horizontal_flow",
            type = "flow",
            direction = "horizontal",
            style = "dialog_buttons_horizontal_flow"
        }
        horizontal_flow.style.horizontally_stretchable = true

        local label = AddLabel(horizontal_flow, nil, { "oarc-join-someone-dropdown-label" }, my_label_style)
        label.style.horizontal_align = "left"

        local dropdown = horizontal_flow.add {
            name = "shared_spawn_select_dropdown",
            tags = { action = "oarc_spawn_options", setting = "shared_spawn_select" },
            type = "drop-down",
            items = avail_spawns.hosts,
            selected_index = new_selected_index,
            tooltip = { "oarc-join-someone-dropdown-tooltip" }
        }
        dropdown.style.horizontal_align = "left"

        local dragger = horizontal_flow.add {
            type = "empty-widget",
            style = "draggable_space",
        }
        dragger.style.horizontally_stretchable = true

        local button = horizontal_flow.add {
            name = "join_other_spawn",
            tags = { action = "oarc_spawn_options", setting = "join_other_spawn" },
            type = "button",
            tooltip = { "oarc-join-shared-button-tooltip" },
            enabled = new_selected_index > 0
        }
        if new_selected_index == 0 then
            button.caption = { "oarc-join-shared-button-disable" }
            button.style = "red_button"
        else
            button.caption = { "oarc-join-shared-button-enable", prev_selected_host, avail_spawns.spawns[new_selected_index].surface_name }
            button.style = "green_button"
        end

        button.style.horizontal_align = "right"

    else
        AddLabel(shared_spawn_frame, nil, { "oarc-no-shared-avail" }, my_label_style)
    end
end

---Refresh the shared spawn frame if it exists
---@param player LuaPlayer
---@return nil
function RefreshSharedSpawnFrameIfExist(player)
    local spawn_opts = player.gui.screen.spawn_opts
    if spawn_opts == nil then return end
    CreateSharedSpawnFrame(spawn_opts.spawn_opts_if, storage.ocfg.gameplay.enable_shared_spawns)
end

---Creates the buddy spawn frame for spawning with a buddy
---@param parent_flow LuaGuiElement
---@param player LuaPlayer
---@param enable_buddy_spawn boolean
---@param enable_separate_teams boolean
---@return nil
function CreateBuddySpawnFrame(parent_flow, player, enable_buddy_spawn, enable_separate_teams)

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
        buddy_spawn_frame.style.margin = 4

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

    AddLabel(buddy_spawn_frame, nil, { "oarc-spawn-menu-buddy-header" }, my_label_header_style)

    if not enable_buddy_spawn then
        AddLabel(buddy_spawn_frame, nil, { "oarc-buddy-spawn-disabled" }, my_warning_style)
        return
    end

    -- Warnings and explanations...
    AddLabel(buddy_spawn_frame, nil, { "oarc-buddy-spawn-instructions" }, my_label_style)

    if (enable_separate_teams) then
        buddy_spawn_frame.add {
            tags = { action = "oarc_spawn_options", setting = "buddy_team_select" },
            type = "checkbox",
            caption = { "oarc-create-buddy-team" },
            state = false,
            tooltip = { "oarc-create-buddy-team-tooltip" }
        }
    end

    ---@type string[]
    local avail_buddies = GetOtherPlayersInSpawnMenu(player)

    -- log("Available buddies: " .. serpent.block(avail_buddies))

    local previous_index = 0
    if selected_buddy then
        for i,host in ipairs(avail_buddies) do
            if host == selected_buddy then
                previous_index = i
                break
            end
        end
    end

    local buddy_button_horizontal_flow = buddy_spawn_frame.add {
        type = "flow",
        direction = "horizontal",
        style = "dialog_buttons_horizontal_flow"
    }
    buddy_button_horizontal_flow.style.horizontally_stretchable = true

    local label = AddLabel(buddy_button_horizontal_flow, nil, { "oarc-buddy-select-label" }, my_label_style)
    label.style.horizontal_align = "left"

    local buddy_dropdown = buddy_button_horizontal_flow.add {
        name = "waiting_buddies_dropdown",
        tags = { action = "oarc_spawn_options", setting = "buddy_select" },
        type = "drop-down",
        items = avail_buddies,
        selected_index = previous_index,
        tooltip = { "oarc-buddy-select-tooltip" }
    }
    buddy_dropdown.style.horizontal_align = "left"

    local empty = buddy_button_horizontal_flow.add {
        type = "empty-widget",
        style = "draggable_space",
    }
    empty.style.horizontally_stretchable = true

    local button = buddy_button_horizontal_flow.add {
        name = "buddy_spawn_request",
        tags = { action = "oarc_spawn_options", setting = "buddy_spawn_request" },
        type = "button",
        caption = { "oarc-buddy-spawn" },
        style = "green_button",
        tooltip = { "oarc-buddy-spawn-tooltip" }
    }
    button.style.horizontal_align = "right"
end

---Refresh the buddy list without recreating any GUI elements
---@param player LuaPlayer
---@param dropdown LuaGuiElement The buddy dropdown element
---@return nil
function RefreshBuddyList(player, dropdown)
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
    local gameplay = storage.ocfg.gameplay

    -- Create the primary frame and a warning label
    local sGui = CreateSpawnMenuGuiFrame(player)

    -- Create the default settings entry for the OarcSpawnChoices table
    local default_team = SPAWN_TEAM_CHOICE.join_main_team
    if (not gameplay.enable_main_team and gameplay.enable_separate_teams) then
        default_team = SPAWN_TEAM_CHOICE.join_own_team
    end
    ---@type OarcSpawnChoices
    local spawn_choices_entry = {
        surface_name = gameplay.default_surface,
        team = default_team,
        moat = gameplay.allow_moats_around_spawns,
        buddy = nil,
        distance = gameplay.near_spawn_distance,
        host = nil,
        buddy_team = false
    }
    storage.spawn_choices[player.name] = spawn_choices_entry

    CreateSpawnSettingsFrame(sGui, gameplay) -- The settings for configuring a spawn
    CreateSoloSpawnFrame(sGui, gameplay.enable_shared_spawns, gameplay.number_of_players_per_shared_spawn) -- The primary method of spawning
    CreateSharedSpawnFrame(sGui, gameplay.enable_shared_spawns) -- Spawn options to join another player's base.
    CreateBuddySpawnFrame(sGui, player, gameplay.enable_buddy_spawn, gameplay.enable_separate_teams) -- Awesome buddy spawning system

    script.raise_event("oarc-mod-on-spawn-choices-gui-displayed", { player_index = player.index, gui_element = sGui })
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
        storage.spawn_choices[player.name].team = tags.value --[[@as SpawnTeamChoice]]

        -- Need to handle the radio button logic manually
        if (elemName == "isolated_spawn_main_team_radio") then
            if (event.element.parent.isolated_spawn_new_team_radio ~= nil) then
                event.element.parent.isolated_spawn_new_team_radio.state = false
            end
        elseif (elemName == "isolated_spawn_new_team_radio") then
            if (event.element.parent.isolated_spawn_main_team_radio ~= nil) then
                event.element.parent.isolated_spawn_main_team_radio.state = false
            end
        end

    elseif (tags.setting == "buddy_team_select") then
        storage.spawn_choices[player.name].buddy_team = event.element.state

    elseif (tags.setting == "moat_option") then
        storage.spawn_choices[player.name].moat = event.element.state
    end
end

---Handle the gui click of the spawn options
---@param event EventData.on_gui_click
---@return nil
function SpawnOptsGuiClick(event)
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
        PrimarySpawnRequest(player)
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
    elseif (tags.setting == "surface_select") then
        event.element.items = GetAllowedSurfaces()
    end
end

---Request a buddy spawn. Requires the buddy to accept or reject the request.
---@param player LuaPlayer
---@return nil
function RequestBuddySpawn(player)
    local buddy_choice = storage.spawn_choices[player.name].buddy
    if (buddy_choice == nil) then SendErrorMsg(player, { "oarc-invalid-buddy" }) return end
    local buddy = game.players[buddy_choice]
    if (buddy == nil) then SendErrorMsg(player, { "oarc-invalid-buddy" }) return end
    -- Confirm the buddy is still in the spawn menu!
    if (buddy.gui.screen.spawn_opts == nil) then SendErrorMsg(player, { "oarc-invalid-buddy", buddy.name }) return end

    DisplayBuddySpawnWaitMenu(player)
    DisplayBuddySpawnRequestMenu(buddy, player.name)
end

---Handle buddy spawn wait menu cancel (waiting for buddy to accept or decline proposal)
---@param player LuaPlayer
---@return nil
function CancelBuddySpawnWaitMenu(player)

    ---@type OarcSpawnChoices
    local spawn_choices = storage.spawn_choices[player.name]
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

    CompatSend(buddy, { "oarc-buddy-cancel-request", player.name })
end

---Request to join someone's shared spawn
---@param player LuaPlayer
---@return nil
function RequestToJoinSharedSpawn(player)

    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end

    local host_name = storage.spawn_choices[player.name].host_name
    if (host_name == nil) then SendErrorMsg(player, { "oarc-no-shared-spawn-selected" }) return end

    -- Clear the spawn options gui
    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end

    if ((game.players[host_name] ~= nil) and (game.players[host_name].connected)) then
        local primary_spawn = FindPrimaryUniqueSpawn(host_name)
        table.insert(storage.unique_spawns[primary_spawn.surface_name][host_name].join_queue, player.name)

        -- Display wait menu with cancel button.
        DisplaySharedSpawnJoinWaitMenu(player)

        -- Tell other player they are requesting a response. Print it with color orange
        CompatSend(game.players[host_name], { "oarc-player-requesting-join-you", player.name }, { color = { r = 1, g = 0.5, b = 0 }, sound_path = "utility/scenario_message" })
        OarcGuiRefreshContent(game.players[host_name])
    else
        SendErrorMsg(player, { "oarc-invalid-host-shared-spawn" })

        DisplaySpawnOptions(player)
    end
end


---Cancel shared spawn request from the waiting menu
---@param player LuaPlayer
---@return nil
function CancelSharedSpawnRequest(player)

    local host_name = storage.spawn_choices[player.name].host_name
    if (host_name ~= nil) and (game.players[host_name] ~= nil) then
        CompatSend(game.players[host_name], { "oarc-player-cancel-join-request", player.name })
    end

    --- Destroy the waiting menu and display the spawn options again.
    player.gui.screen.join_shared_spawn_wait_menu.destroy()
    DisplaySpawnOptions(player)

    RemovePlayerFromJoinQueue(player.name)

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
        storage.spawn_choices[player.name].distance = distance
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
        local surface_name = event.element.get_item(index) --[[@as string]]
        storage.spawn_choices[player.name].surface_name = surface_name
        log("GUI DEBUG Selected surface: " .. surface_name)

    elseif (tags.setting == "shared_spawn_select") then
        SharedSpawnSelect(event.element, player)

    elseif (tags.setting == "buddy_select") then
        local index = event.element.selected_index
        if (index > 0) then
            local buddyName = event.element.get_item(index) --[[@as string]]
            storage.spawn_choices[player.name].buddy = buddyName
            log("GUI DEBUG Selected buddy: " .. buddyName)
        else
            storage.spawn_choices[player.name].buddy = nil
        end
    end
end

---Handles the shared spawn host dropdown selection. Updates the join button and sets the host spawn choice entry.
---@param gui_element LuaGuiElement
---@param player LuaPlayer
---@return nil
function SharedSpawnSelect(gui_element, player)
    local index = gui_element.selected_index
    if (index > 0) then
        local host_name = gui_element.get_item(index) --[[@as string]]
        local button = gui_element.parent.join_other_spawn

        local primary_spawn = FindPrimaryUniqueSpawn(host_name)
        if (primary_spawn and 
                IsSharedSpawnOpen(primary_spawn.surface_name, host_name) and
                not IsSharedSpawnFull(primary_spawn.surface_name, host_name)) then
            storage.spawn_choices[player.name].host_name = host_name
            button.enabled = true
            button.caption = { "oarc-join-shared-button-enable", host_name, primary_spawn.surface_name }
            button.style = "green_button"
        else
            SendErrorMsg(player, { "oarc-invalid-host-shared-spawn" })
            storage.spawn_choices[player.name].host_name = nil
            gui_element.selected_index = 0
            button.enabled = false
            button.caption = { "oarc-join-shared-button-disable" }
            button.style = "red_button"
        end

    else
        storage.spawn_choices[player.name].host_name = nil
    end
end

---Requests the generation of a spawn point for the player (their first primary spawn)
---@param player LuaPlayer
---@return nil
function PrimarySpawnRequest(player)
    -- Get the player's spawn choices
    ---@type OarcSpawnChoices
    local spawn_choices = storage.spawn_choices[player.name]
    if (spawn_choices == nil) then error("ERROR! No spawn choices found for player!") return end

    -- N/A for solo spawns so clear these!
    storage.spawn_choices[player.name].host_name = nil
    storage.spawn_choices[player.name].buddy = nil

    -- Find coordinates of a good place to spawn
    local spawn_position = FindUngeneratedCoordinates(spawn_choices.surface_name, spawn_choices.distance, 3)

    -- If that fails, just throw a warning and don't spawn them. They can try again.
    if ((spawn_position.x == 0) and (spawn_position.y == 0)) then
        SendErrorMsg(player, { "oarc-no-ungenerated-land-error" })
        return
    end

    -- Create a new force for player if they choose that radio button
    if spawn_choices.team ~= SPAWN_TEAM_CHOICE.join_main_team then
        CreatePlayerCustomForce(player)
    end

    -- Queue spawn generation and the player.
    local delayed_spawn = GenerateNewSpawn(player.name, spawn_choices.surface_name, spawn_position, spawn_choices, true)
    QueuePlayerForSpawn(player.name, delayed_spawn)

    SendBroadcastMsg({"", { "oarc-player-is-joining", player.name, spawn_choices.surface_name }, " ", GetGPStext(spawn_choices.surface_name, spawn_position)}, {color = player.color})

    -- Unlock spawn control gui tab
    SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_TAB_NAME, true)

    -- Destroy the spawn options gui
    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end
end

---Display shared spawn join wait menu to the requesting player
---@param player LuaPlayer
---@return nil
function DisplaySharedSpawnJoinWaitMenu(player)

    if (player.gui.screen.spawn_opts ~= nil) then
        player.gui.screen.spawn_opts.destroy()
    end

    local sGui = player.gui.screen.add {
        name = "join_shared_spawn_wait_menu",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-waiting-for-spawn-owner" }
    }

    sGui.auto_center = true
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    sGui.style.padding = 5

    local sGui_if = sGui.add {
        type = "frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }

    -- Warnings and explanations...
    AddLabel(sGui_if, "warning_lbl1", { "oarc-you-will-spawn-once-host" }, my_note_style)


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

    local dragger = button_flow.add{type="empty-widget", style="draggable_space"}
    dragger.style.right_margin = 0
    dragger.style.horizontally_stretchable = true
    dragger.style.height = 30
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
    AddLabel(buddy_wait_menu_if, nil, { "oarc-wait-buddy-select-yes" }, my_note_style)
    AddSpacer(buddy_wait_menu_if)

    local button_flow = buddy_wait_menu.add {
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

    local dragger = button_flow.add{type="empty-widget", style="draggable_space"}
    dragger.style.right_margin = 0
    dragger.style.horizontally_stretchable = true
    dragger.style.height = 30
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
    AddLabel(buddy_request_gui_if, nil, { "oarc-buddy-requesting-from-you", requesting_buddy_name }, my_note_style)
    AddSpacer(buddy_request_gui_if)

    ---@type OarcSpawnChoices
    local spawn_choices = storage.spawn_choices[requesting_buddy_name]

    ---@type LocalisedString
    local teamText = "error!"
    if (spawn_choices.buddy_team) then
        teamText = { "oarc-buddy-txt-buddy-team" }
    elseif (spawn_choices.team == SPAWN_TEAM_CHOICE.join_main_team) then
        teamText = { "oarc-buddy-txt-main-team" }
    elseif (spawn_choices.team == SPAWN_TEAM_CHOICE.join_own_team) then
        teamText = { "oarc-buddy-txt-new-teams" }
    end
    

    ---@type LocalisedString
    local moatText = " "
    if (spawn_choices.moat) then
        moatText = { "oarc-buddy-txt-moat" }
    end

    ---@type LocalisedString
    local surfaceText = { "oarc-buddy-txt-surface", spawn_choices.surface_name}

    ---@type LocalisedString
    local distText = { "oarc-buddy-txt-distance", spawn_choices.distance}

    ---@type LocalisedString
    local requestText = { "", requesting_buddy_name, { "oarc-buddy-txt-would-like" }, " ", teamText, { "oarc-buddy-txt-next-to-you" },
        moatText, surfaceText, distText }

    AddLabel(buddy_request_gui_if, nil, requestText, my_label_style)


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

---Handles spawning the buddies together once the request has been accepted
---@param player LuaPlayer The player that is accepting the buddy request
---@param requesting_buddy_name string The name of the player that is requesting to buddy spawn
---@return nil
function AcceptBuddyRequest(player, requesting_buddy_name)

    ---@type OarcSpawnChoices
    local spawn_choices = storage.spawn_choices[requesting_buddy_name]
    local requesting_buddy = game.players[requesting_buddy_name]
    local surface = game.surfaces[spawn_choices.surface_name]

    -- Copy the buddy's spawn choices to the accepting player
    spawn_choices.host_name = nil -- N/A for buddy spawns so clear it.
    storage.spawn_choices[player.name] = table.deepcopy(spawn_choices)
    storage.spawn_choices[player.name].buddy = requesting_buddy_name
    local buddy_choices = storage.spawn_choices[player.name]

    -- Find coordinates of a good place to spawn
    local spawn_position = FindUngeneratedCoordinates(spawn_choices.surface_name, spawn_choices.distance, 3)

    -- If that fails, just throw a warning and don't spawn them. They can try again.
    if ((spawn_position.x == 0) and (spawn_position.y == 0)) then
        SendErrorMsg(player, { "oarc-no-ungenerated-land-error" })
        return
    end

    -- Create a new force for the combined players if they chose that option
    if spawn_choices.buddy_team then
        local buddyForce = CreatePlayerCustomForce(requesting_buddy)
        player.force = buddyForce
    -- Create a new force for each player if they chose that option
    elseif spawn_choices.team == SPAWN_TEAM_CHOICE.join_own_team then
        CreatePlayerCustomForce(player)
        CreatePlayerCustomForce(requesting_buddy)
    end

    -- Destroy GUIs
    if (requesting_buddy.gui.screen.buddy_wait_menu ~= nil) then
        requesting_buddy.gui.screen.buddy_wait_menu.destroy()
    end
    if (player.gui.screen.buddy_request_menu ~= nil) then
        player.gui.screen.buddy_request_menu.destroy()
    end

    -- Create that spawn in the global vars
    local buddy_position = GetBuddySpawnPosition(spawn_position, spawn_choices.surface_name)


    -- Queue spawn generation for the requesting buddy FIRST. (left)
    local delayed_spawn = GenerateNewSpawn(requesting_buddy_name, spawn_choices.surface_name, spawn_position, spawn_choices, true)
    QueuePlayerForSpawn(requesting_buddy_name, delayed_spawn)

    -- ORDER MATTERS! Otherwise sometimes chunks don't generate properly!
    -- Queue spawn generation for the accepting buddy SECOND. (right)
    local delayed_spawn = GenerateNewSpawn(player.name, buddy_choices.surface_name, buddy_position, buddy_choices, true)
    QueuePlayerForSpawn(player.name, delayed_spawn)


    SendBroadcastMsg({"", {"oarc-buddies-are-joining", requesting_buddy_name, player.name, spawn_choices.surface_name}, " ", GetGPStext(spawn_choices.surface_name, spawn_position)})

    -- Unlock spawn control gui tab
    SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_TAB_NAME, true)
    SetOarcGuiTabEnabled(requesting_buddy, OARC_SPAWN_CTRL_TAB_NAME, true)
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

    CompatSend(requester_buddy, { "oarc-buddy-declined", player.name })
end

---Display the please wait dialog
---@param player LuaPlayer
---@param delay_seconds integer
---@param surface LuaSurface
---@param position MapPosition
---@return nil
function DisplayPleaseWaitForSpawnDialog(player, delay_seconds, surface, position)
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

    local pleaseWaitGui_if = pleaseWaitGui.add {
        type = "frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }

    pleaseWaitGui_if.add {
        type = "minimap",
        position = position,
        surface_index = surface.index,
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
    SpawnOptsGuiClick(event)
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