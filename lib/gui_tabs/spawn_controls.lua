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
        caption = "" }
    ApplyStyle(spwnCtrls, my_fixed_width_style)
    spwnCtrls.style.maximal_height = 1000
    spwnCtrls.horizontal_scroll_policy = "never"

    if global.ocfg.gameplay.enable_shared_spawns then
        if (global.ocore.uniqueSpawns[player.name] ~= nil) then
            -- This checkbox allows people to join your base when they first
            -- start the game.
            spwnCtrls.add { type = "checkbox", name = "accessToggle",
                caption = { "oarc-spawn-allow-joiners" },
                state = IsSharedSpawnActive(player) }
            ApplyStyle(spwnCtrls["accessToggle"], my_fixed_width_style)
        end
    end

    -- @todo Figure out why this case could be hit... Fix for error report in github.
    if (global.ocore.playerCooldowns[player.name] == nil) then
        log("ERROR! playerCooldowns[player.name] is nil!")
        global.ocore.playerCooldowns[player.name] = { setRespawn = game.tick }
    end

    -- Sets the player's custom spawn point to their current location
    if ((game.tick - global.ocore.playerCooldowns[player.name].setRespawn) >
            (global.ocfg.gameplay.respawn_cooldown_min * TICKS_PER_MINUTE)) then
        spwnCtrls.add { type = "button", name = "setRespawnLocation", caption = { "oarc-set-respawn-loc" } }
        spwnCtrls["setRespawnLocation"].style.font = "default-small-semibold"
    else
        AddLabel(spwnCtrls, "respawn_cooldown_note1",
            { "oarc-set-respawn-loc-cooldown", FormatTime((global.ocfg.gameplay.respawn_cooldown_min * TICKS_PER_MINUTE) -
                (game.tick - global.ocore.playerCooldowns[player.name].setRespawn)) }, my_note_style)
    end
    AddLabel(spwnCtrls, "respawn_cooldown_note2", { "oarc-set-respawn-note" }, my_note_style)

    -- Display a list of people in the join queue for your base.
    if (global.ocfg.gameplay.enable_shared_spawns and IsSharedSpawnActive(player)) then
        if (TableLength(global.ocore.sharedSpawns[player.name].joinQueue) > 0) then
            AddLabel(spwnCtrls, "drop_down_msg_lbl1", { "oarc-select-player-join-queue" }, my_label_style)
            spwnCtrls.add { name = "join_queue_dropdown",
                type = "drop-down",
                items = global.ocore.sharedSpawns[player.name].joinQueue }
            spwnCtrls.add { name = "accept_player_request",
                type = "button",
                caption = { "oarc-accept" } }
            spwnCtrls.add { name = "reject_player_request",
                type = "button",
                caption = { "oarc-reject" } }
        else
            AddLabel(spwnCtrls, "empty_join_queue_note1", { "oarc-no-player-join-reqs" }, my_note_style)
        end
        spwnCtrls.add { name = "join_queue_spacer", type = "label",
            caption = " " }
    end
end

---Handle the gui checkboxes & radio buttons of the spawn control tab in the Oarc GUI.
---@param event EventData.on_gui_checked_state_changed
---@return nil
function SpawnCtrlGuiOptionsSelect(event)
    if not (event and event.element and event.element.valid) then return end

    local player = game.players[event.player_index]
    local name = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    ---@type OarcSharedSpawn
    local sharedSpawn = global.ocore.sharedSpawns[player.name]

    -- Handle changes to spawn sharing.
    if (name == "accessToggle") then
        if event.element.state then
            if DoesPlayerHaveCustomSpawn(player) then
                if (sharedSpawn == nil) then
                    CreateNewSharedSpawn(player)
                else
                    sharedSpawn.openAccess = true
                end

                SendBroadcastMsg({ "oarc-start-shared-base", player.name })
            end
        else
            if (sharedSpawn ~= nil) then
                sharedSpawn.openAccess = false
                SendBroadcastMsg({ "oarc-stop-shared-base", player.name })
            end
        end
        FakeTabChangeEventOarcGui(player)

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
    if not (event and event.element and event.element.valid) then return end

    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (event.element.parent) then
        if (event.element.parent.name ~= "spwn_ctrl_panel") then
            return
        end
    end

    -- Sets a new respawn point and resets the cooldown.
    if (elemName == "setRespawnLocation") then
        if DoesPlayerHaveCustomSpawn(player) then
            ChangePlayerSpawn(player, player.surface.name, player.position)
            FakeTabChangeEventOarcGui(player)
            player.print({ "oarc-spawn-point-updated" })
        end
    end

    -- Accept or reject pending player join requests to a shared base
    if ((elemName == "accept_player_request") or (elemName == "reject_player_request")) then
        if ((event.element.parent.join_queue_dropdown == nil) or
                (event.element.parent.join_queue_dropdown.selected_index == 0)) then
            player.print({ "oarc-selected-player-not-wait" })
            FakeTabChangeEventOarcGui(player)
            return
        end

        local joinQueueIndex = event.element.parent.join_queue_dropdown.selected_index
        local joinQueuePlayerChoice = event.element.parent.join_queue_dropdown.get_item(joinQueueIndex) --[[@as string]]

        if ((game.players[joinQueuePlayerChoice] == nil) or
                (not game.players[joinQueuePlayerChoice].connected)) then
            player.print({ "oarc-selected-player-not-wait" })
            FakeTabChangeEventOarcGui(player)
            return
        end

        ---@type OarcSharedSpawn
        local sharedSpawn = global.ocore.sharedSpawns[player.name]

        if (elemName == "reject_player_request") then
            player.print({ "oarc-reject-joiner", joinQueuePlayerChoice })
            SendMsg(joinQueuePlayerChoice, { "oarc-your-request-rejected" })
            FakeTabChangeEventOarcGui(player)

            -- Close the waiting players menu
            if (game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu) then
                game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu.destroy()
                DisplaySpawnOptions(game.players[joinQueuePlayerChoice])
            end

            -- Find and remove the player from the joinQueue they were in.
            for index, requestingPlayer in pairs(sharedSpawn.joinQueue) do
                if (requestingPlayer == joinQueuePlayerChoice) then
                    sharedSpawn.joinQueue[index] = nil
                    return
                end
            end
        elseif (elemName == "accept_player_request") then
            -- Find and remove the player from the joinQueue they were in.
            for index, requestingPlayer in pairs(sharedSpawn.joinQueue) do
                if (requestingPlayer == joinQueuePlayerChoice) then
                    sharedSpawn.joinQueue[index] = nil
                end
            end

            -- If player exists, then do stuff.
            if (game.players[joinQueuePlayerChoice]) then
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
            else
                SendBroadcastMsg({ "oarc-player-left-while-joining", joinQueuePlayerChoice })
            end
        end
    end
end
