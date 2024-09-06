-- Spawn control tab in the Oarc GUI, for things like sharing your base with others.

---Check if shared spawn is active (enabled and open)
---@param player LuaPlayer
---@return boolean
local function IsSharedSpawnActive(player)
    if ((global.ocore.sharedSpawns[player.name] == nil) or
            (global.ocore.sharedSpawns[player.name].openAccess == false)) then
        return false
    else
        return true
    end
end

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

    if global.ocfg.gameplay.enable_shared_spawns then
        if (global.ocore.uniqueSpawns[player.name] ~= nil) then
            -- This checkbox allows people to join your base when they first start the game.
            local toggle = spwnCtrls.add {
                type = "checkbox",
                name = "accessToggle",
                tags = { action = "oarc_spawn_ctrl_tab", setting = "shared_access_toggle" },
                caption = { "oarc-spawn-allow-joiners" },
                state = IsSharedSpawnActive(player)
            }
            ApplyStyle(toggle, my_fixed_width_style)
        end
    end

    -- TODO: Figure out why this case could be hit... Fix for error report in github.
    if (global.ocore.playerCooldowns[player.name] == nil) then
        log("ERROR! playerCooldowns[player.name] is nil!")
        global.ocore.playerCooldowns[player.name] = { setRespawn = game.tick }
    end

    -- Sets the player's custom spawn point to their current location
    if ((game.tick - global.ocore.playerCooldowns[player.name].setRespawn) >
            (global.ocfg.gameplay.respawn_cooldown_min * TICKS_PER_MINUTE)) then
        local change_respawn_button = spwnCtrls.add {
            type = "button",
            tags = { action = "oarc_spawn_ctrl_tab", setting = "set_respawn_location" },
            name = "setRespawnLocation",
            caption = { "oarc-set-respawn-loc" }
        }
        change_respawn_button.style.font = "default-small-semibold"
    else
        AddLabel(spwnCtrls, nil,
            { "oarc-set-respawn-loc-cooldown", FormatTime((global.ocfg.gameplay.respawn_cooldown_min * TICKS_PER_MINUTE) -
                (game.tick - global.ocore.playerCooldowns[player.name].setRespawn)) }, my_note_style)
    end
    AddLabel(spwnCtrls, nil, { "oarc-set-respawn-note" }, my_note_style)

    -- Display a list of people in the join queue for your base.
    if (global.ocfg.gameplay.enable_shared_spawns and IsSharedSpawnActive(player)) then
        if (TableLength(global.ocore.sharedSpawns[player.name].joinQueue) > 0) then
            AddLabel(spwnCtrls, "drop_down_msg_lbl1", { "oarc-select-player-join-queue" }, my_label_style)

            local horizontal_flow = spwnCtrls.add { type = "flow", direction = "horizontal" }
            horizontal_flow.style.horizontally_stretchable = true

            horizontal_flow.add {
                name = "join_queue_dropdown",
                type = "drop-down",
                items = global.ocore.sharedSpawns[player.name].joinQueue
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
            AddLabel(spwnCtrls, "empty_join_queue_note1", { "oarc-no-player-join-reqs" }, my_note_style)
        end
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

    ---@type OarcSharedSpawn
    local sharedSpawn = global.ocore.sharedSpawns[player.name]

    -- Handle changes to spawn sharing.
    if (tags.setting == "shared_access_toggle") then
        if event.element.state then
            if DoesPlayerHaveCustomSpawn(player) then
                if (sharedSpawn == nil) then
                    CreateNewSharedSpawn(player)
                else
                    global.ocore.sharedSpawns[player.name].openAccess = true
                end

                SendBroadcastMsg({ "oarc-start-shared-base", player.name })
            end
        else
            if (sharedSpawn ~= nil) then
                global.ocore.sharedSpawns[player.name].openAccess = false
                SendBroadcastMsg({ "oarc-stop-shared-base", player.name })
            end
        end
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
        if DoesPlayerHaveCustomSpawn(player) then
            ChangePlayerSpawn(player, player.surface.name, player.position)
            OarcGuiRefreshContent(player)
            player.print({ "oarc-spawn-point-updated" })
        end


    -- Accept or reject pending player join requests to a shared base
    elseif ((tags.setting == "accept_player_request") or (tags.setting == "reject_player_request")) then
        
        if ((event.element.parent.join_queue_dropdown == nil) or
                (event.element.parent.join_queue_dropdown.selected_index == 0)) then
            player.print({ "oarc-selected-player-not-valid" })
            OarcGuiRefreshContent(player)
            return
        end

        local joinQueueIndex = event.element.parent.join_queue_dropdown.selected_index
        local joinQueuePlayerChoice = event.element.parent.join_queue_dropdown.get_item(joinQueueIndex) --[[@as string]]

        -- Shouldn't be able to hit this since we force a GUI refresh when they leave?
        if ((game.players[joinQueuePlayerChoice] == nil) or
                (not game.players[joinQueuePlayerChoice].connected)) then
            player.print({ "oarc-selected-player-not-wait" })
            OarcGuiRefreshContent(player)
            return
        end

        ---@type OarcSharedSpawn
        local sharedSpawn = global.ocore.sharedSpawns[player.name]

        if (tags.setting == "reject_player_request") then

            RemovePlayerFromJoinQueue(joinQueuePlayerChoice) -- This also refreshes the host gui

            -- Inform the host that the player was rejected
            player.print({ "oarc-reject-joiner", joinQueuePlayerChoice })
            -- Inform the player that their request was rejected
            SendMsg(joinQueuePlayerChoice, { "oarc-your-request-rejected" })

            -- Close the waiting players menu
            if (game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu) then
                game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu.destroy()
                DisplaySpawnOptions(game.players[joinQueuePlayerChoice])
            end

        elseif (tags.setting == "accept_player_request") then
            
            RemovePlayerFromJoinQueue(joinQueuePlayerChoice) -- This also refreshes the host gui

            -- Send an announcement
            SendBroadcastMsg({ "oarc-player-joining-base", joinQueuePlayerChoice, player.name })

            -- Close the waiting players menu
            if (game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu) then
                game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu.destroy()
            end

            -- Spawn the player
            local joiningPlayer = game.players[joinQueuePlayerChoice]
            ChangePlayerSpawn(joiningPlayer, sharedSpawn.surface, sharedSpawn.position)
            SendPlayerToSpawn(joiningPlayer)
            GivePlayerStarterItems(joiningPlayer)
            table.insert(sharedSpawn.players, joiningPlayer.name)
            joiningPlayer.force = game.players[player.name].force

            -- Render some welcoming text...
            DisplayWelcomeGroundTextAtSpawn(joiningPlayer, sharedSpawn.surface, sharedSpawn.position)

            -- Unlock spawn control gui tab
            SetOarcGuiTabEnabled(joiningPlayer, OARC_SPAWN_CTRL_TAB_NAME, true)
        end
    end
end
