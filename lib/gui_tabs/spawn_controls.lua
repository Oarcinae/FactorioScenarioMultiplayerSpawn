-- Spawn control tab in the Oarc GUI, for things like sharing your base with others.

local RESET_GUI_MAX_WIDTH = 500
local RESET_GUI_MAX_HEIGHT = 1000

---Provides the content of the spawn control tab in the Oarc GUI.
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateSpawnControlsTab(tab_container, player)
    local spwnCtrls = tab_container.add {
        type = "scroll-pane",
        vertical_scroll_policy = "auto",
    }
    -- ApplyStyle(spwnCtrls, my_fixed_width_style)
    spwnCtrls.style.maximal_height = GENERIC_GUI_MAX_HEIGHT
    spwnCtrls.style.padding = 5

    -- Don't show anything WHILE they are still generating a spawn:
    if PlayerHasDelayedSpawn(player.name--[[@as string]]) then
        AddLabel(spwnCtrls, nil, { "oarc-spawn-controls-disabled-delayed" }, my_warning_style)
        return
    end

    CreatePrimarySpawnInfo(player, spwnCtrls)
    CreateSecondarySpawnInfo(player, spwnCtrls)
    CreateSetRespawnLocationButton(player, spwnCtrls)

    if storage.ocfg.gameplay.enable_shared_spawns then
        CreateSharedSpawnControls(player, spwnCtrls)
        CreateJoinQueueControls(player, spwnCtrls)
    end

    CreatePlayerResetControls(spwnCtrls)
end

---Display some general info about the player's home base (different from respawn point).
---There should ONLY be one of these per player? Or maybe there are one per surface
---@param player LuaPlayer
---@param container LuaGuiElement
---@return nil
function CreatePrimarySpawnInfo(player, container)
    local primary_spawn = FindPrimaryUniqueSpawn(player.name)
    if (primary_spawn == nil) then return end

    AddLabel(container, nil, { "oarc-primary-spawn-info-header" }, "caption_label")
    AddLabel(container, nil, { "oarc-primary-spawn-info-note" }, my_label_style)

    local horizontal_flow = container.add { type = "flow", direction = "horizontal"}
    horizontal_flow.style.vertical_align = "center"
    AddLabel(horizontal_flow, nil, { "oarc-primary-spawn-info-surface-label",
                                    primary_spawn.surface_name,
                                    primary_spawn.position.x,
                                    primary_spawn.position.y}, my_label_style)

    --Add empty widget
    local dragger = horizontal_flow.add {
        type = "empty-widget",
        style = "draggable_space_header"
    }
    dragger.style.horizontally_stretchable = true

    CreateGPSButton(horizontal_flow, primary_spawn.surface_name, primary_spawn.position)
end

---Display some general info about the player's secondary spawn points.
---@param player LuaPlayer
---@param container LuaGuiElement
---@return nil
function CreateSecondarySpawnInfo(player, container)
    local secondary_spawns = FindSecondaryUniqueSpawns(player.name)
    if (secondary_spawns == nil) or (table_size(secondary_spawns) == 0) then return end

    AddSpacerLine(container)
    AddLabel(container, nil, { "oarc-secondary-spawn-info-header" }, "caption_label")
    AddLabel(container, nil, { "oarc-secondary-spawn-info-note" }, my_label_style)

    for _,secondary_spawn in pairs(secondary_spawns) do
        local horizontal_flow = container.add { type = "flow", direction = "horizontal"}
        horizontal_flow.style.vertical_align = "center"
        AddLabel(horizontal_flow, nil, { "oarc-secondary-spawn-info-surface-label",
                                        secondary_spawn.surface_name,
                                        secondary_spawn.position.x,
                                        secondary_spawn.position.y}, my_label_style)

        --Add empty widget
        local dragger = horizontal_flow.add {
            type = "empty-widget",
            style = "draggable_space_header"
        }
        dragger.style.horizontally_stretchable = true

        CreateGPSButton(horizontal_flow, secondary_spawn.surface_name, secondary_spawn.position)
    end
end

---Display the shared spawn controls
---@param player LuaPlayer
---@param container LuaGuiElement
---@return nil
function CreateSharedSpawnControls(player, container)
    local primary_spawn = FindPrimaryUniqueSpawn(player.name)
    if (primary_spawn == nil) then return end

    AddSpacerLine(container)
    AddLabel(container, nil, { "oarc-shared-spawn-controls" }, "caption_label")

    local shared_spawn_open = IsSharedSpawnOpen(primary_spawn.surface_name, player.name)
    local shared_spawn_full = IsSharedSpawnFull(primary_spawn.surface_name, player.name)

    -- This checkbox allows people to join your base when they first start the game.
    local toggle = container.add {
        type = "checkbox",
        name = "accessToggle",
        tags = { action = "oarc_spawn_ctrl_tab", setting = "shared_access_toggle" },
        caption = { "oarc-shared-spawn-allow-joiners" },
        state = shared_spawn_open,
        enabled = not shared_spawn_full -- Disable if the shared spawn is full
    }

    if shared_spawn_open and shared_spawn_full then
        AddLabel(container, nil, { "oarc-shared-spawn-full" }, my_note_style)
    end

    ApplyStyle(toggle, my_fixed_width_style)
end

---Display the set respawn location button in the spawn control tab.
---@param player LuaPlayer
---@param container LuaGuiElement
---@return nil
function CreateSetRespawnLocationButton(player, container)

    AddSpacerLine(container)
    AddLabel(container, nil, { "oarc-set-respawn-loc-header" }, "caption_label")

    -- Check if player has a valid character
    if (player.character == nil) then
        AddLabel(container, nil, { "oarc-no-valid-player-character" }, my_warning_style)
        return
    end

    -- Check if player is in a vehicle
    if player.driving then
        AddLabel(container, nil, { "oarc-player-character-in-vehicle" }, my_warning_style)
        return
    end

    local surface_name = player.character.surface.name
    --[[@type OarcPlayerSpawn]]
    local respawn_info = storage.player_respawns[player.name][surface_name]

    if (respawn_info == nil) then
        AddLabel(container, nil, { "oarc-no-respawn-this-surface" }, my_warning_style)
        return
    end

    local respawn_surface_name = respawn_info.surface
    local respawn_position = respawn_info.position

    -- Display the current respawn location
    local horizontal_flow = container.add { type = "flow", direction = "horizontal"}
    horizontal_flow.style.vertical_align = "center"
    AddLabel(horizontal_flow, nil, { "oarc-set-respawn-loc-info-surface-label",
                                respawn_surface_name,
                                respawn_position.x,
                                respawn_position.y }, my_label_style)

    --Add empty widget
    local dragger = horizontal_flow.add {
        type = "empty-widget",
        style = "draggable_space_header"
    }
    dragger.style.horizontally_stretchable = true

    local teleport_button = horizontal_flow.add {
        type = "button",
        tags = { action = "oarc_spawn_ctrl_tab", setting = "teleport_home", surface = respawn_surface_name, position = respawn_position },
        caption = { "oarc-teleport-home" },
        tooltip = { "oarc-teleport-home-tooltip" },
        style = "green_button"
    }
    teleport_button.style.height = 26
    CreateGPSButton(horizontal_flow, respawn_surface_name, respawn_position)

    -- Sets the player's custom spawn point to their current location
    if ((game.tick - storage.player_cooldowns[player.name].setRespawn) >
            (storage.ocfg.gameplay.respawn_cooldown_min * TICKS_PER_MINUTE)) then
        local change_respawn_button = container.add {
            type = "button",
            tags = { action = "oarc_spawn_ctrl_tab", setting = "set_respawn_location" },
            name = "setRespawnLocation",
            caption = { "oarc-set-respawn-loc" },
            tooltip = { "oarc-set-respawn-loc-tooltip" },
            style = "red_button"
        }
        change_respawn_button.style.font = "default-small-semibold"
    else
        AddLabel(container, nil,
            { "oarc-set-respawn-loc-cooldown", FormatTime((storage.ocfg.gameplay.respawn_cooldown_min * TICKS_PER_MINUTE) -
                (game.tick - storage.player_cooldowns[player.name].setRespawn)) }, my_note_style)
    end
    AddLabel(container, nil, { "oarc-set-respawn-note" }, my_label_style)
end

---Display a list of people in the join queue for a shared spawn.
---@param player LuaPlayer
---@param container LuaGuiElement
---@return nil
function CreateJoinQueueControls(player, container)
    local primary_spawn = FindPrimaryUniqueSpawn(player.name)
    if (primary_spawn == nil) then return end

    local shared_spawn_open = IsSharedSpawnOpen(primary_spawn.surface_name, player.name)
    local shared_spawn_full = IsSharedSpawnFull(primary_spawn.surface_name, player.name)

    -- Only show this if the player has an open and not full shared spawn
    if (not shared_spawn_open or shared_spawn_full) then return end

    if (table_size(primary_spawn.join_queue) > 0) then
        AddLabel(container, nil, { "oarc-join-queue-header" }, "caption_label")
        AddLabel(container, "drop_down_msg_lbl1", { "oarc-select-player-join-queue" }, my_label_style)

        local horizontal_flow = container.add { type = "flow", direction = "horizontal" }
        horizontal_flow.style.horizontally_stretchable = true

        horizontal_flow.add {
            name = "join_queue_dropdown",
            type = "drop-down",
            items = primary_spawn.join_queue
        }

        local dragger = horizontal_flow.add {
            type = "empty-widget",
            style = "draggable_space_header"
        }
        dragger.style.horizontally_stretchable = true

        horizontal_flow.add {
            name = "accept_player_request",
            tags = { action = "oarc_spawn_ctrl_tab", setting = "accept_player_request" },
            type = "button",
            style = "green_button",
            caption = { "oarc-accept" }
        }
        horizontal_flow.add {
            name = "reject_player_request",
            tags = { action = "oarc_spawn_ctrl_tab", setting = "reject_player_request" },
            type = "button",
            style = "red_button",
            caption = { "oarc-reject" }
        }
    else
        AddLabel(container, "empty_join_queue_note1", { "oarc-no-player-join-reqs" }, my_note_style)
    end
    
end


---Display a GPS button for a specific location.
---@param container LuaGuiElement
---@param surface_name string
---@param position MapPosition
---@return nil
function CreateGPSButton(container, surface_name, position)
    local gps_button = container.add {
        type = "sprite-button",
        sprite = "utility/gps_map_icon",
        tags = {
            action = "oarc_spawn_ctrl_tab",
            setting = "show_location",
            surface = surface_name,
            position = position
        },
        style = "slot_button",
        tooltip = { "oarc-spawn-info-location-button-tooltip" },
    }
    gps_button.style.width = 28
    gps_button.style.height = 28
end

---Create the GUI controls for self-resetting the player.
---@param container LuaGuiElement
---@return nil
function CreatePlayerResetControls(container)
    if not storage.ocfg.gameplay.enable_player_self_reset then return end

    AddSpacerLine(container)
    AddLabel(container, nil, { "oarc-player-reset-header" }, "caption_label")
    AddLabel(container, nil, { "oarc-player-reset-note" }, my_longer_label_style)

    local horizontal_flow = container.add { type = "flow", direction = "horizontal" }
    
    local dragger = horizontal_flow.add {
        type = "empty-widget",
        style = "draggable_space_header"
    }
    dragger.style.horizontally_stretchable = true

    local reset_button = horizontal_flow.add {
        type = "button",
        tags = { action = "oarc_spawn_ctrl_tab", setting = "player_reset" },
        caption = { "oarc-player-reset" },
        tooltip = { "oarc-player-reset-tooltip" },
        style = "red_button"
    }
    reset_button.style.font = "default-small-semibold"
end

---Display a confirmation GUI for the player to reset themselves.
---@param player LuaPlayer
---@return nil
function DisplayPlayerResetConfirmationGUI(player)

    if (player.gui.screen.self_reset_confirm ~= nil) then
        player.gui.screen.self_reset_confirm.destroy()
    end

    local self_reset_gui = player.gui.screen.add {
        name = "self_reset_confirm",
        type = "frame",
        direction = "vertical",
        caption = { "oarc-player-reset" }
    }
    self_reset_gui.auto_center = true
    self_reset_gui.style.maximal_width = RESET_GUI_MAX_WIDTH
    self_reset_gui.style.maximal_height = RESET_GUI_MAX_HEIGHT
    self_reset_gui.style.padding = 5

    local self_reset_gui_if = self_reset_gui.add {
        type = "frame",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical"
    }

    AddLabel(self_reset_gui_if, nil, { "oarc-player-reset-are-you-sure" }, my_warning_style)
    AddSpacer(self_reset_gui_if)

    local horizontal_flow = self_reset_gui_if.add { type = "flow", direction = "horizontal" }
    horizontal_flow.style.horizontally_stretchable = true

    local cancel_button = horizontal_flow.add {
        type = "button",
        tags = { action = "oarc_spawn_ctrl_tab", setting = "player_reset_cancel" },
        caption = { "oarc-cancel-button-caption" },
        style = "back_button"
    }

    local dragger = horizontal_flow.add {
        type = "empty-widget",
        style = "draggable_space_header"
    }
    dragger.style.horizontally_stretchable = true

    local reset_button = horizontal_flow.add {
        type = "button",
        tags = { action = "oarc_spawn_ctrl_tab", setting = "player_reset_confirm" },
        caption = { "oarc-confirm-button-caption" },
        tooltip = { "oarc-player-reset" },
        style = "confirm_button"
    }
end

---Handle the gui checkboxes & radio buttons of the spawn control tab in the Oarc GUI.
---@param event EventData.on_gui_checked_state_changed
---@return nil
function SpawnCtrlGuiOptionsCheckedStateChanged(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_spawn_ctrl_tab") then
        return
    end

    -- Handle changes to spawn sharing.
    if (tags.setting == "shared_access_toggle") then
        if event.element.state then
            SendBroadcastMsg({ "oarc-start-shared-base", player.name })
        else
            SendBroadcastMsg({ "oarc-stop-shared-base", player.name })
        end
        local primary_spawn = FindPrimaryUniqueSpawn(player.name)
        storage.unique_spawns[primary_spawn.surface_name][player.name].open_access = event.element.state
        OarcGuiRefreshContent(player)

        -- Refresh the shared spawn spawn gui for all players
        for _,p in pairs(game.connected_players) do
            RefreshSharedSpawnFrameIfExist(p)
        end
    end
end

---Handle the gui click of the spawn control tab in the Oarc GUI.
---@param event EventData.on_gui_click
---@return nil
function SpawnCtrlTabGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_spawn_ctrl_tab") then
        return
    end

    -- Sets a new respawn point and resets the cooldown.
    if (tags.setting == "set_respawn_location") then

        -- Check if player has a valid character
        if (player.character == nil) then 
            CompatSend(player, { "oarc-no-valid-player-character" })
            return
        end

        -- Check if player is in a vehicle
        if player.driving then
            CompatSend(player, { "oarc-player-character-in-vehicle" })
            return
        end

        -- Check if the surface is blacklisted
        local surface_name = player.character.surface.name
        if IsSurfaceBlacklisted(surface_name) then
            CompatSend(player, {"oarc-no-respawn-this-surface"})
            return
        end

        SetPlayerRespawn(player.name, surface_name, player.character.position, true)
        OarcGuiRefreshContent(player)
        CompatSend(player, { "oarc-spawn-point-updated" })

    -- Shows the spawn location on the map
    elseif (tags.setting == "show_location") then
        local surface_name = tags.surface --[[@as string]]
        local position = tags.position --[[@as MapPosition]]

        player.set_controller{type = defines.controllers.remote, position = position, surface = surface_name}
        CompatSend(player, {"", { "oarc-spawn-gps-location" }, " ", GetGPStext(surface_name, position)})

    -- Teleports the player to their home base
    elseif (tags.setting == "teleport_home") then
        local surface_name = tags.surface --[[@as string]]
        local position = tags.position --[[@as MapPosition]]

        -- Check if player has a valid character
        if (player.character == nil) then 
            CompatSend(player, { "oarc-no-valid-player-character" })
            return
        end

        -- Check if player is in a vehicle
        if player.driving then
            CompatSend(player, { "oarc-player-character-in-vehicle" })
            return
        end

        SafeTeleport(player, game.surfaces[surface_name], position)

    -- Self reset the player
    elseif (tags.setting == "player_reset") then
        DisplayPlayerResetConfirmationGUI(player)

    -- Cancel the self reset
    elseif (tags.setting == "player_reset_cancel") then
        if (player.gui.screen.self_reset_confirm) then
            player.gui.screen.self_reset_confirm.destroy()
        end

    -- Confirm the self reset
    elseif (tags.setting == "player_reset_confirm") then
        if (player.gui.screen.self_reset_confirm) then
            player.gui.screen.self_reset_confirm.destroy()
        end
        RemoveOrResetPlayer(player, false)

    -- Accept or reject pending player join requests to a shared base
    elseif ((tags.setting == "accept_player_request") or (tags.setting == "reject_player_request")) then

        if ((event.element.parent.join_queue_dropdown == nil) or
                (event.element.parent.join_queue_dropdown.selected_index == 0)) then
            CompatSend(player, { "oarc-selected-player-not-valid" })
            OarcGuiRefreshContent(player)
            return
        end

        local join_queue_index = event.element.parent.join_queue_dropdown.selected_index
        local join_queue_player_choice = event.element.parent.join_queue_dropdown.get_item(join_queue_index) --[[@as string]]

        -- Shouldn't be able to hit this since we force a GUI refresh when they leave?
        if ((game.players[join_queue_player_choice] == nil) or (not game.players[join_queue_player_choice].connected)) then
            CompatSend(player, { "oarc-selected-player-not-wait" })
            OarcGuiRefreshContent(player)
            return
        end

        local primary_spawn = FindPrimaryUniqueSpawn(player.name)

        if (tags.setting == "reject_player_request") then

            RemovePlayerFromJoinQueue(join_queue_player_choice) -- This also refreshes the host gui

            -- Inform the host that the player was rejected
            CompatSend(player, { "oarc-reject-joiner", join_queue_player_choice })
            -- Inform the player that their request was rejected
            SendMsg(join_queue_player_choice, { "oarc-your-request-rejected" })

            -- Close the waiting players menu
            if (game.players[join_queue_player_choice].gui.screen.join_shared_spawn_wait_menu) then
                game.players[join_queue_player_choice].gui.screen.join_shared_spawn_wait_menu.destroy()
                DisplaySpawnOptions(game.players[join_queue_player_choice])
            end

        elseif (tags.setting == "accept_player_request") then
            
            -- Check if there is space first
            if (table_size(primary_spawn.joiners) >= storage.ocfg.gameplay.number_of_players_per_shared_spawn - 1) then
                CompatSend(player, { "oarc-shared-spawn-full" })
                return
            end

            -- Send an announcement
            SendBroadcastMsg({ "oarc-player-joining-base", join_queue_player_choice, player.name })

            -- Close the waiting players menu
            if (game.players[join_queue_player_choice].gui.screen.join_shared_spawn_wait_menu) then
                game.players[join_queue_player_choice].gui.screen.join_shared_spawn_wait_menu.destroy()
            end

            local joining_player = game.players[join_queue_player_choice]
            local joining_player_name = joining_player.name

            -- Assign force
            joining_player.force = game.players[player.name].force

            -- Add the player to ALL spawns owned by the host.
            for surface_name, unique_spawn_entry in pairs(storage.unique_spawns) do
                for player_name, unique_spawn in pairs(unique_spawn_entry) do
                    if (player_name == player.name) then
                        table.insert(unique_spawn.joiners, joining_player_name)
                        SetPlayerRespawn(joining_player_name, surface_name, unique_spawn.position, true)
                    end
                end
            end

            -- Send player to the host's primary spawn.
            SendPlayerToNewSpawn(joining_player_name, primary_spawn.surface_name, true)

            -- Render some welcoming text...
            DisplayWelcomeGroundTextAtSpawn(primary_spawn.surface_name, primary_spawn.position)

            -- Unlock spawn control gui tab
            SetOarcGuiTabEnabled(joining_player, OARC_SPAWN_CTRL_TAB_NAME, true)

            RemovePlayerFromJoinQueue(join_queue_player_choice) -- This also refreshes the host gui
        end
    end
end
