-- game_opts.lua
-- Jan 2018
-- Display current game options, maybe have some admin controls here

-- Main Configuration File
require("config")
require("lib/oarc_utils")
require("lib/separate_spawns")

function CreateGameOptionsGui(event)
    local player = game.players[event.player_index]
    if player.gui.top.game_options == nil then
        player.gui.top.add{name="game_options", type="button", caption="Info"}
    end   
end

local function ExpandGameOptionsGui(player)
    local frame = player.gui.left["game_options_panel"]
    if (frame) then
        frame.destroy()
    else
        local frame = player.gui.left.add{type="frame",
                                            name="game_options_panel", 
                                            caption="Server Info:",
                                            direction="vertical"}

        -- General Server Info:
        AddLabel(frame, "info_1", WELCOME_MSG, my_longer_label_style)
        AddLabel(frame, "info_2", SERVER_MSG, my_longer_label_style)
        AddSpacer(frame, "info_spacer1")

        -- Enemy Settings:
        local enemy_expansion_txt = "disabled"
        if game.map_settings.enemy_expansion.enabled then enemy_expansion_txt = "enabled" end

        local enemy_text="Server Run Time: " .. formattime_hours_mins(game.tick) .. "\n" ..
        "Current Evolution: " .. string.format("%.4f", game.forces["enemy"].evolution_factor) .. "\n" ..
        "Enemy evolution time factor: " .. game.map_settings.enemy_evolution.time_factor .. "\n" ..
        "Enemy evolution pollution factor: " .. game.map_settings.enemy_evolution.pollution_factor .. "\n" ..
        "Enemy evolution destroy factor: " .. game.map_settings.enemy_evolution.destroy_factor .. "\n" ..
        "Enemy expansion is " .. enemy_expansion_txt

        AddLabel(frame, "enemy_info", enemy_text, my_longer_label_style)
        AddSpacer(frame, "enemy_info_spacer1")

        -- Game Mode:
        AddLabel(frame, "core_mod_en", "Core game mode (separate spawns) is enabled.", my_longer_label_style)
        if (not ENABLE_SEPARATE_SPAWNS) then
            frame.core_mod_en.caption="Core game mode (separate spawns) is DISABLED."
            frame.core_mod_en.style.font_color=my_color_red
        end

        -- Soft Mods:
        local soft_mods_string = "Oarc Core"
        if (not ENABLE_SEPARATE_SPAWNS) then
            soft_mods_string = "Oarc Core [DISABLED!]"
        end
        -- if (ENABLE_RSO) then
        --     soft_mods_string = soft_mods_string .. ", RSO"
        -- end
        if (ENABLE_UNDECORATOR) then
            soft_mods_string = soft_mods_string .. ", Undecorator"
        end
        if (ENABLE_TAGS) then
            soft_mods_string = soft_mods_string .. ", Tags"
        end
        if (ENABLE_LONGREACH) then
            soft_mods_string = soft_mods_string .. ", Long Reach"
        end
        if (ENABLE_AUTOFILL) then
            soft_mods_string = soft_mods_string .. ", Auto Fill"
        end
        if (ENABLE_PLAYER_LIST) then
            soft_mods_string = soft_mods_string .. ", Player List"
        end

        local game_info_str = "Soft Mods Enabled: " .. soft_mods_string

        -- Spawn options:
        if (ENABLE_SEPARATE_TEAMS) then
            game_info_str = game_info_str.."\n".."You are allowed to spawn on your own team (have your own research tree). All teams are friendly!"
        end
        if (ENABLE_BUDDY_SPAWN) then
            game_info_str = game_info_str.."\n".."You can chose to spawn alongside a buddy if you spawn together at the same time."
        end
        if (ENABLE_SHARED_SPAWNS) then
            game_info_str = game_info_str.."\n".."Spawn hosts may choose to share their spawn and allow other players to join them."
        end
        if (ENABLE_SEPARATE_TEAMS and ENABLE_SHARED_TEAM_VISION) then
            game_info_str = game_info_str.."\n".."Everyone (all teams) have shared vision."
        end
        if (FRONTIER_ROCKET_SILO_MODE) then
            game_info_str = game_info_str.."\n".."Silos are NOT craftable. There is at least one already located on the map."
        end
        if (ENABLE_REGROWTH) then
            game_info_str = game_info_str.."\n".."Old parts of the map will slowly be deleted over time (chunks without any player buildings)."
        end
        if (ENABLE_POWER_ARMOR_QUICK_START) then
            game_info_str = game_info_str.."\n".."Power armor quick start enabled."
        end

        AddLabel(frame, "game_info_label", game_info_str, my_longer_label_style)

        if (ENABLE_ABANDONED_BASE_REMOVAL) then
            AddLabel(frame, "leave_warning_msg", "If you leave within " .. MIN_ONLINE_TIME_IN_MINUTES .. " minutes of joining, your base and character will be deleted.", my_longer_label_style)
            frame.leave_warning_msg.style.font_color=my_color_red
        end

        -- Ending Spacer
        AddSpacer(frame, "end_spacer")

        -- ADMIN CONTROLS
        if (player.admin) then
            player_list = {}
            for _,player in pairs(game.connected_players) do
                table.insert(player_list, player.name)
            end
            frame.add{name = "ban_players_dropdown",
                            type = "drop-down",
                            items = player_list}
            frame.add{name="ban_player", type="button", caption="Ban Player"}
            frame.add{name="restart_player", type="button", caption="Restart Player"}
            
            AddLabel(frame, "restart_warning_msg", "You might CRASH the scenario by using Restart Player. Not 100% tested yet. Will not work if player has any center gui visible.", my_longer_label_style)
            frame.restart_warning_msg.style.font_color=my_color_red
        end
    end
end

function GameOptionsGuiClick(event) 
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.element.player_index]
    local name = event.element.name

    if (name == "game_options") then
        ExpandGameOptionsGui(player)        
    end

    if (name == "ban_player") then
        local pIndex = event.element.parent.ban_players_dropdown.selected_index

        if (pIndex ~= 0) then
            local banPlayer = event.element.parent.ban_players_dropdown.get_item(pIndex)
            if (game.players[banPlayer]) then
                game.ban_player(banPlayer, "Banned from admin panel.")
                log("Banning " .. banPlayer)
            end
        end
    end

    if (name == "restart_player") then
        local pIndex = event.element.parent.ban_players_dropdown.selected_index

        if (pIndex ~= 0) then
            local resetPlayer = event.element.parent.ban_players_dropdown.get_item(pIndex)
            if (game.players[resetPlayer]) then
                SeparateSpawnsPlayerCreated(resetPlayer)
                log("Resetting " .. resetPlayer)
            end
        end
    end
end
