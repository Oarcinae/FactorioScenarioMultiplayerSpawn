-- I made a separate file for all the GUI related functions. Yay me.

local SPAWN_GUI_MAX_WIDTH = 500
local SPAWN_GUI_MAX_HEIGHT = 1000

---A display gui message. Meant to be display the first time a player joins.
---@param player LuaPlayer
---@return boolean
function DisplayWelcomeTextGui(player)
    if ((player.gui.screen["join_shared_spawn_wait_menu"] ~= nil) or
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

    AddLabel(surfacesHorizontalFlow, "surfacesHorizontalFlowLabel", { "oarc-surface-select-label" }, my_label_style)
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

---Create the frame for starting a new spawn: pick a surface (and the spawn style if allowed), then confirm.
---@param parent_flow LuaGuiElement
---@param gameplay OarcConfigGameplaySettings
---@return nil
function CreateNewSpawnFrame(parent_flow, gameplay)

    local new_spawn_frame = parent_flow.add {
        name = "new_spawn_frame",
        type = "frame",
        direction = "vertical",
        style = "bordered_frame"
    }
    new_spawn_frame.style.horizontally_stretchable = true
    new_spawn_frame.style.padding = 5
    new_spawn_frame.style.margin = 4
    new_spawn_frame.style.bottom_margin = 0

    AddLabel(new_spawn_frame, nil, { "oarc-spawn-menu-new-header" }, my_label_header_style)
    AddLabel(new_spawn_frame, nil, { "oarc-new-spawn-info" }, my_label_style)

    -- A note about sharing spawns
    if gameplay.enable_shared_spawns and (gameplay.number_of_players_per_shared_spawn > 1) then
        AddLabel(new_spawn_frame, nil, { "oarc-max-players-shared-spawn", gameplay.number_of_players_per_shared_spawn - 1 }, my_label_style)
    end

    -- Pick surface
    CreateSurfaceSelectDropdown(new_spawn_frame)

    -- Pick the OG Oarc style spawn circle, or the vanilla starting area (unchecked). Only if players are allowed it.
    if IsOarcStyleSpawnAllowed() then
        new_spawn_frame.add {
            name = "oarc_style_spawn_option_checkbox",
            tags = { action = "oarc_spawn_options", setting = "oarc_style_spawn_option" },
            type = "checkbox",
            caption = { "oarc-oarc-style-spawn-option" },
            state = false, -- Default to the vanilla starting area
            tooltip = { "oarc-oarc-style-spawn-option-tooltip" }
        }

        -- Allow players to spawn with a moat around their area. Only Oarc style spawns have a moat, so this is only
        -- enabled while the Oarc style spawn is picked.
        if (gameplay.allow_moats_around_spawns) then
            new_spawn_frame.add {
                name = "isolated_spawn_moat_option_checkbox",
                tags = { action = "oarc_spawn_options", setting = "moat_option" },
                type = "checkbox",
                caption = { "oarc-moat-option" },
                state = true, -- Default to true
                enabled = false,
                tooltip = { "oarc-moat-option-tooltip" }
            }
        end
    end

    local button_flow = new_spawn_frame.add {
        type = "flow",
        direction = "horizontal"
    }
    button_flow.style.horizontal_align = "right"
    button_flow.style.horizontally_stretchable = true
    button_flow.add {
        name = "spawn_request",
        tags = { action = "oarc_spawn_options", setting = "spawn_request" },
        type = "button",
        caption = { "oarc-new-spawn-button" },
        tooltip = { "oarc-new-spawn-button-tooltip" },
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
    ---@type OarcSpawnChoices
    local spawn_choices_entry = {
        surface_name = gameplay.default_surface,
        prefab = false,
        moat = gameplay.allow_moats_around_spawns,
        host_name = nil,
    }
    storage.spawn_choices[player.name] = spawn_choices_entry

    CreateNewSpawnFrame(sGui, gameplay) -- Start a new spawn at the next free starting point.
    CreateSharedSpawnFrame(sGui, gameplay.enable_shared_spawns) -- Or join another player's base.

    script.raise_event("oarc-classic-on-spawn-choices-gui-displayed", { player_index = player.index, gui_element = sGui })
end


---This just updates the checkboxes when players click them.
---@param event EventData.on_gui_checked_state_changed
---@return nil
function SpawnOptsRadioSelect(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_spawn_options") then
        return
    end

    if (tags.setting == "oarc_style_spawn_option") then
        storage.spawn_choices[player.name].prefab = event.element.state

        local moat_checkbox = event.element.parent["isolated_spawn_moat_option_checkbox"]
        if (moat_checkbox ~= nil) then
            moat_checkbox.enabled = event.element.state
        end
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
    elseif (tags.setting == "surface_select") then
        event.element.items = GetAllowedSurfaces()
    end
end

---Request to join someone's shared spawn
---@param player LuaPlayer
---@return nil
function RequestToJoinSharedSpawn(player)

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

    if not RemovePlayerFromJoinQueue(player.name) then
        log("ERROR! Failed to remove player from joinQueue?!")
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

    elseif (tags.setting == "shared_spawn_select") then
        SharedSpawnSelect(event.element, player)
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

    -- N/A for new spawns so clear this!
    storage.spawn_choices[player.name].host_name = nil

    -- Claim the next free starting point. If there are none left, they can still join someone else's spawn.
    local spawn_position = ClaimNextStartingPoint(spawn_choices.surface_name, player.name)
    if (spawn_position == nil) then
        SendErrorMsg(player, { "oarc-no-free-starting-points", spawn_choices.surface_name })
        return
    end

    -- Every primary spawn gets its own force.
    CreatePlayerCustomForce(player)

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

---Gui selection state changed event handlers
---@param event EventData.on_gui_selection_state_changed
---@return nil
function SeparateSpawnsGuiSelectionStateChanged(event)
    SpawnOptsSelectionChanged(event)
end