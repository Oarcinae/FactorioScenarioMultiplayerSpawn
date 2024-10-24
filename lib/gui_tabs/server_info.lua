---Display current game options and server info, maybe have some admin controls here

---Creates the content for the game settings used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateServerInfoTab(tab_container, player)

    AddLabel(tab_container, nil, { "oarc-experimental-warning" }, my_longer_label_style)
    AddSpacerLine(tab_container)

    -- General Server Info:
    if (storage.ocfg.server_info.welcome_msg ~= " ") then
        AddLabel(tab_container, nil, {"oarc-server-info-tab-welcome-msg-title"}, "caption_label")
        AddLabel(tab_container, nil, storage.ocfg.server_info.welcome_msg, my_longer_label_style)
        AddSpacerLine(tab_container)
    end

    if (storage.ocfg.server_info.discord_invite ~= " ") then
        local horizontal_flow = tab_container.add{
            type="flow", direction="horizontal"
        }
        AddLabel(horizontal_flow, nil, {"oarc-server-info-tab-discord-invite"}, "caption_label")
        horizontal_flow.add{
            type="textfield",
            tooltip={"oarc-server-info-tab-discord-invite-tooltip"},
            text=storage.ocfg.server_info.discord_invite
        }
        AddSpacerLine(tab_container)
    end

    AddLabel(tab_container, nil, {"oarc-server-info-tab-map-info-label"}, "caption_label")
    AddLabel(tab_container, nil,  {"oarc-server-info-tab-server-run-time", FormatTimeHoursSecs(game.tick)}, my_label_style)
    --TODO: Add more stuff here maybe? Like in the old version?

    if (storage.ocfg.regrowth.enable_abandoned_base_cleanup) then
        local label = AddLabel(tab_container, nil, {"oarc-server-info-leave-warning", storage.ocfg.gameplay.minimum_online_time}, my_longer_label_style)
        label.style.font_color=my_color_red
    end

    -- Ending Spacer
    AddSpacerLine(tab_container)

    -- ADMIN CONTROLS
    if (player.admin) then
        player_list = {}
        for _, p in pairs(game.connected_players) do
            table.insert(player_list, p.name)
        end

        AddLabel(tab_container, nil, {"oarc-server-info-admin-controls"}, "caption_label")

        local horizontal_flow = tab_container.add{
            type="flow", direction="horizontal"
        }
        horizontal_flow.style.horizontally_stretchable = true

        AddLabel(horizontal_flow, nil, {"oarc-server-info-ban-select-player"}, my_label_style)
        local drop_down = horizontal_flow.add{
            name = "ban_players_dropdown",
            tags = { action = "oarc_server_info_tab", setting = "ban_players_dropdown" },
            type = "drop-down",
            items = player_list
        }

        -- If there is only one player, select it by default (for testing convenience)
        if (#player_list == 1) then
            drop_down.selected_index = 1
        end

        local dragger = horizontal_flow.add{
            type="empty-widget",
            style="draggable_space_header"
        }
        dragger.style.horizontally_stretchable = true

        horizontal_flow.add{
            name="ban_player",
            tags = { action = "oarc_server_info_tab", setting = "ban_player" },
            type="button",
            caption={"oarc-server-info-button-ban-player"},
            style = "red_button"
        }
         horizontal_flow.add{
            name="restart_player",
            tags = { action = "oarc_server_info_tab", setting = "restart_player" },
            type="button",
            caption={"oarc-server-info-button-restart-player"},
            style = "red_button"
        }
    end
end


---Server info gui click event handler
---@param event EventData.on_gui_click
---@return nil
function ServerInfoTabGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_server_info_tab") then
        return
    end

    local player_dropdown = event.element.parent.ban_players_dropdown

    if (tags.setting == "ban_player") then
        local pIndex = player_dropdown.selected_index

        if (pIndex ~= 0) then
            local banPlayer = player_dropdown.get_item(pIndex)
            if (game.players[banPlayer]) then
                game.ban_player(banPlayer --[[@as string]], "Banned from admin panel by " .. player.name)
                log("Banning " .. banPlayer)
            end
        end
    end

    if (tags.setting == "restart_player") then
        local pIndex = player_dropdown.selected_index

        if (pIndex ~= 0) then
            local resetPlayer = player_dropdown.get_item(pIndex)

            if not game.players[resetPlayer] or not game.players[resetPlayer].connected then
                SendMsg(player.name, {"oarc-player-not-found", resetPlayer})
                return
            end

            if PlayerHasDelayedSpawn(resetPlayer--[[@as string]]) then
                SendMsg(player.name, {"oarc-player-about-to-spawn", resetPlayer})
                return
            end

            log("Resetting " .. resetPlayer)
            RemoveOrResetPlayer(game.players[resetPlayer], false)
        else
            SendMsg(player.name, {"oarc-player-none-selected"})
            return
        end
    end
end