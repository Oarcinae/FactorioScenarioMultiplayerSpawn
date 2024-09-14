-- Spawn control tab in the Oarc GUI, for things like sharing your base with others.

---Provides the content of the spawn control tab in the Oarc GUI.
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateSpawnControlsTab(tab_container, player)
    local spwnCtrls = tab_container.add {
        type = "scroll-pane",
        name = "spwn_ctrl_panel",
        caption = ""
    }
    ApplyStyle(spwnCtrls, my_fixed_width_style)
    spwnCtrls.style.maximal_height = 1000
    spwnCtrls.horizontal_scroll_policy = "never"

    CreateSpawnInfo(player, spwnCtrls)
    CreateSetRespawnLocationButton(player, spwnCtrls)

    if global.ocfg.gameplay.enable_shared_spawns then
        CreateSharedSpawnControls(player, spwnCtrls)
        CreateJoinQueueControls(player, spwnCtrls)
    end
end

---Display some general info about the player's home base (different from respawn point).
---There should ONLY be one of these per player? Or maybe there are one per surface
---@param player LuaPlayer
---@param container LuaGuiElement
---@return nil
function CreateSpawnInfo(player, container)
    local primary_spawn = FindPrimaryUniqueSpawn(player.name)
    if (primary_spawn == nil) then return end

    AddLabel(container, nil, { "oarc-spawn-info-header" }, "caption_label")

    local horizontal_flow = container.add { type = "flow", direction = "horizontal"}
    horizontal_flow.style.vertical_align = "center"
    AddLabel(horizontal_flow, nil, { "oarc-spawn-info-surface-label",
                                    primary_spawn.surface_name,
                                    primary_spawn.position.x,
                                    primary_spawn.position.y}, my_label_style)

    --Add empty widget
    local dragger = horizontal_flow.add {
        type = "empty-widget",
        style = "draggable_space_header"
    }
    dragger.style.horizontally_stretchable = true

    horizontal_flow.add {
        type = "sprite-button",
        sprite = "utility/gps_map_icon",
        -- caption = { "oarc-spawn-info-location-button" },
        tags = { action = "oarc_spawn_ctrl_tab", setting = "show_spawn_location" },
        style = "slot_button",
        tooltip = { "oarc-spawn-info-location-button-tooltip" },
    }

    AddSpacerLine(container)
end

---Display the shared spawn controls
---@param player LuaPlayer
---@param container LuaGuiElement
---@return nil
function CreateSharedSpawnControls(player, container)
    local primary_spawn = FindPrimaryUniqueSpawn(player.name)
    if (primary_spawn == nil) then return end

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
    AddLabel(container, nil, { "oarc-set-respawn-loc-header" }, "caption_label")

    --[[@type OarcPlayerSpawn]]
    local spawn_info = global.player_respawns[player.name][player.surface.name]
    local spawn_surface_name = spawn_info.surface
    local spawn_position = spawn_info.position

    -- Display the current respawn location
    AddLabel(container, nil, { "oarc-spawn-info-surface-label",
                                spawn_surface_name,
                                spawn_position.x,
                                spawn_position.y }, my_label_style)

    -- Sets the player's custom spawn point to their current location
    if ((game.tick - global.player_cooldowns[player.name].setRespawn) >
            (global.ocfg.gameplay.respawn_cooldown_min * TICKS_PER_MINUTE)) then
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
            { "oarc-set-respawn-loc-cooldown", FormatTime((global.ocfg.gameplay.respawn_cooldown_min * TICKS_PER_MINUTE) -
                (game.tick - global.player_cooldowns[player.name].setRespawn)) }, my_note_style)
    end
    AddLabel(container, nil, { "oarc-set-respawn-note" }, my_label_style)
    AddSpacerLine(container)
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

    if (TableLength(primary_spawn.join_queue) > 0) then
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


---Handle the gui checkboxes & radio buttons of the spawn control tab in the Oarc GUI.
---@param event EventData.on_gui_checked_state_changed
---@return nil
function SpawnCtrlGuiOptionsSelect(event)
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
        global.unique_spawns[primary_spawn.surface_name][player.name].open_access = event.element.state
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
function SpawnCtrlGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_spawn_ctrl_tab") then
        return
    end

    -- Sets a new respawn point and resets the cooldown.
    if (tags.setting == "set_respawn_location") then
        ChangePlayerRespawn(player.name, player.surface.name, player.position)
        OarcGuiRefreshContent(player)
        player.print({ "oarc-spawn-point-updated" })

    -- Shows the spawn location on the map
    elseif (tags.setting == "show_spawn_location") then
        local primary_spawn = FindPrimaryUniqueSpawn(player.name)
        local position = primary_spawn.position
        player.open_map(position, 0.05)
        player.print({"", { "oarc-spawn-gps-home-location" }, GetGPStext(primary_spawn.surface_name, position)})

    -- Accept or reject pending player join requests to a shared base
    elseif ((tags.setting == "accept_player_request") or (tags.setting == "reject_player_request")) then

        if ((event.element.parent.join_queue_dropdown == nil) or
                (event.element.parent.join_queue_dropdown.selected_index == 0)) then
            player.print({ "oarc-selected-player-not-valid" })
            OarcGuiRefreshContent(player)
            return
        end

        local join_queue_index = event.element.parent.join_queue_dropdown.selected_index
        local join_queue_player_choice = event.element.parent.join_queue_dropdown.get_item(join_queue_index) --[[@as string]]

        -- Shouldn't be able to hit this since we force a GUI refresh when they leave?
        if ((game.players[join_queue_player_choice] == nil) or (not game.players[join_queue_player_choice].connected)) then
            player.print({ "oarc-selected-player-not-wait" })
            OarcGuiRefreshContent(player)
            return
        end

        local primary_spawn = FindPrimaryUniqueSpawn(player.name)

        if (tags.setting == "reject_player_request") then

            RemovePlayerFromJoinQueue(join_queue_player_choice) -- This also refreshes the host gui

            -- Inform the host that the player was rejected
            player.print({ "oarc-reject-joiner", join_queue_player_choice })
            -- Inform the player that their request was rejected
            SendMsg(join_queue_player_choice, { "oarc-your-request-rejected" })

            -- Close the waiting players menu
            if (game.players[join_queue_player_choice].gui.screen.join_shared_spawn_wait_menu) then
                game.players[join_queue_player_choice].gui.screen.join_shared_spawn_wait_menu.destroy()
                DisplaySpawnOptions(game.players[join_queue_player_choice])
            end

        elseif (tags.setting == "accept_player_request") then
            
            -- Check if there is space first
            if (TableLength(primary_spawn.joiners) >= global.ocfg.gameplay.number_of_players_per_shared_spawn - 1) then
                player.print({ "oarc-shared-spawn-full" })
                return
            end

            -- Send an announcement
            SendBroadcastMsg({ "oarc-player-joining-base", join_queue_player_choice, player.name })

            -- Close the waiting players menu
            if (game.players[join_queue_player_choice].gui.screen.join_shared_spawn_wait_menu) then
                game.players[join_queue_player_choice].gui.screen.join_shared_spawn_wait_menu.destroy()
            end

            -- Spawn the player
            local joining_player = game.players[join_queue_player_choice]
            ChangePlayerRespawn(joining_player.name, primary_spawn.surface_name, primary_spawn.position)
            SendPlayerToSpawn(primary_spawn.surface_name, joining_player)
            GivePlayerStarterItems(joining_player)
            table.insert(global.unique_spawns[primary_spawn.surface_name][player.name].joiners, joining_player.name)
            joining_player.force = game.players[player.name].force

            -- Render some welcoming text...
            DisplayWelcomeGroundTextAtSpawn(joining_player, primary_spawn.surface_name, primary_spawn.position)

            -- Unlock spawn control gui tab
            SetOarcGuiTabEnabled(joining_player, OARC_SPAWN_CTRL_TAB_NAME, true)

            RemovePlayerFromJoinQueue(join_queue_player_choice) -- This also refreshes the host gui
        end
    end
end
