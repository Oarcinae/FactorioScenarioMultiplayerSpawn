---Display current game options and server info, maybe have some admin controls here

---Creates the content for the game settings used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateServerInfoTab(tab_container, player)

    -- General Server Info:
    if (global.ocfg.server_info.welcome_msg ~= " ") then
        AddLabel(tab_container, nil, "Welcome Message", "caption_label")
        AddLabel(tab_container, nil, global.ocfg.server_info.welcome_msg, my_longer_label_style)
        AddSpacerLine(tab_container)
    end

    if (global.ocfg.server_info.discord_invite ~= " ") then
        local horizontal_flow = tab_container.add{
            type="flow", direction="horizontal"
        }
        AddLabel(horizontal_flow, nil, "Discord Invite:", "caption_label")
        horizontal_flow.add{
            type="textfield",
            tooltip="Come join the discord (copy this invite)!",
            text=global.ocfg.server_info.discord_invite
        }
        AddSpacerLine(tab_container)
    end

    -- Enemy Settings:
    local enemy_expansion_txt = "disabled"
    if game.map_settings.enemy_expansion.enabled then enemy_expansion_txt = "enabled" end

    local enemy_text="Server Run Time: " .. FormatTimeHoursSecs(game.tick) .. "\n" ..
    -- "Current Evolution: " .. string.format("%.4f", game.forces["enemy"].evolution_factor) .. "\n" ..
    -- "Enemy evolution time/pollution/destroy factors: " .. game.map_settings.enemy_evolution.time_factor .. "/" ..
    -- game.map_settings.enemy_evolution.pollution_factor .. "/" ..
    -- game.map_settings.enemy_evolution.destroy_factor .. "\n" ..
    "Enemy expansion is " .. enemy_expansion_txt

    AddLabel(tab_container, nil, "Map Info", "caption_label")
    AddLabel(tab_container, "enemy_info", enemy_text, my_longer_label_style)
    -- AddSpacerLine(tab_container)

    -- Soft Mods:
    -- local soft_mods_string = "Oarc Core"

    -- if (global.ocfg.regrowth.enable_regrowth) then
    --     soft_mods_string = soft_mods_string .. ", Regrowth"
    -- end
    -- if (global.ocfg.gameplay.enable_offline_protection) then
    --     soft_mods_string = soft_mods_string .. ", Offline Attack Inhibitor"
    -- end

    -- local game_info_str = "Soft Mods: " .. soft_mods_string

    -- Spawn options:
    -- if (global.ocfg.gameplay.enable_separate_teams) then
    --     game_info_str = game_info_str.."\n".."You are allowed to spawn on your own team (have your own research tree). All teams are friendly!"
    -- end
    -- game_info_str = game_info_str.."\n".."You are spawned with a fix set of starting resources."
    -- if (global.ocfg.gameplay.enable_buddy_spawn) then
    --     game_info_str = game_info_str.."\n".."You can chose to spawn alongside a buddy if you spawn together at the same time."
    -- end
    -- -- end
    -- if (global.ocfg.gameplay.enable_shared_spawns) then
    --     game_info_str = game_info_str.."\n".."Spawn hosts may choose to share their spawn and allow other players to join them."
    -- end
    -- if (global.ocfg.gameplay.enable_separate_teams and global.ocfg.gameplay.enable_shared_team_vision) then
    --     game_info_str = game_info_str.."\n".."Everyone (all teams) have shared vision."
    -- end

    -- if (global.ocfg.gameplay.enable_regrowth) then
    --     game_info_str = game_info_str.."\n".."Old parts of the map will slowly be deleted over time (chunks without any player buildings)."
    -- end
    -- if (global.ocfg.enable_power_armor_start or global.ocfg.enable_modular_armor_start) then
    --     game_info_str = game_info_str.."\n".."Quicker start enabled."
    -- end
    -- if (global.ocfg.lock_goodies_rocket_launch) then
    --     game_info_str = game_info_str.."\n".."Some technologies and recipes are locked until you launch a rocket!"
    -- end



    -- AddLabel(tab_container, "game_info_label", game_info_str, my_longer_label_style)

    if (global.ocfg.regrowth.enable_abandoned_base_cleanup) then
        AddLabel(tab_container, "leave_warning_msg", "If you leave within " .. global.ocfg.gameplay.minimum_online_time .. " minutes of joining, your base and character will be deleted.", my_longer_label_style)
        tab_container.leave_warning_msg.style.font_color=my_color_red
    end

    -- Ending Spacer
    AddSpacerLine(tab_container)

    -- ADMIN CONTROLS
    if (player.admin) then
        player_list = {}
        for _,player in pairs(game.connected_players) do
            table.insert(player_list, player.name)
        end

        AddLabel(tab_container, nil, "Admin Controls", "caption_label")

        local horizontal_flow = tab_container.add{
            type="flow", direction="horizontal"
        }
        horizontal_flow.style.horizontally_stretchable = true

        AddLabel(horizontal_flow, nil, "Select Player:", my_label_style) --TODO: localize
        horizontal_flow.add{
            name = "ban_players_dropdown",
            tags = { action = "oarc_server_info_tab", setting = "ban_players_dropdown" },
            type = "drop-down",
            items = player_list
        }

        local dragger = horizontal_flow.add{
            type="empty-widget",
            style="draggable_space_header"
        }
        dragger.style.horizontally_stretchable = true

        horizontal_flow.add{
            name="ban_player",
            tags = { action = "oarc_server_info_tab", setting = "ban_player" },
            type="button",
            caption="Ban Player",
            style = "red_button"
        }
         horizontal_flow.add{
            name="restart_player",
            tags = { action = "oarc_server_info_tab", setting = "restart_player" },
            type="button",
            caption="Restart Player",
            style = "red_button"
        }
    end
end


---Server info gui click event handler
---@param event EventData.on_gui_click
---@return nil
function ServerInfoGuiClick(event)
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
                SendMsg(player.name, "Player " .. resetPlayer .. " is not found?")
                return
            end

            if PlayerHasDelayedSpawn(resetPlayer--[[@as string]]) then
                SendMsg(player.name, "Player " .. resetPlayer .. " is about to spawn, try again later.")
                return
            end

            log("Resetting " .. resetPlayer)
            RemoveOrResetPlayer(game.players[resetPlayer], false)
            SeparateSpawnsInitPlayer(resetPlayer --[[@as string]])
        else
            SendMsg(player.name, "No player selected!")
            return
        end
    end
end