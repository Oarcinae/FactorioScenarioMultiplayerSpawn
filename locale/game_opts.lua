-- game_opts.lua
-- Jan 2018
-- Display current game options, maybe have some admin controls here

-- Main Configuration File
require("config")
require("locale/oarc_utils")

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
        frame.add{name = "info_1", type = "label",
                        caption=WELCOME_MSG_OARC}
        frame.add{name = "info_2", type = "label",
                        caption=WELCOME_MSG1}
        frame.add{name = "info_3", type = "label",
                        caption=WELCOME_MSG2}
        frame.add{name = "info_4", type = "label",
                        caption=WELCOME_MSG6}
        frame.add{name = "info_spacer", type = "label",
                        caption=" "}
        ApplyStyle(frame.info_1, my_longer_label_style)
        ApplyStyle(frame.info_2, my_longer_label_style)
        ApplyStyle(frame.info_3, my_longer_label_style)
        ApplyStyle(frame.info_4, my_longer_label_style)
        ApplyStyle(frame.info_spacer, my_spacer_style)


        -- Enemy Settings:
        frame.add{name = "server_time", type = "label",
                        caption="Server Run Time: " .. formattime_hours_mins(game.tick)}
        frame.add{name = "evo_now", type = "label",
                        caption="Current Evolution: " .. string.format("%.4f", game.forces["enemy"].evolution_factor)}
        frame.add{name = "evo_factor_time", type = "label",
                        caption="Enemy evolution time factor: " .. game.map_settings.enemy_evolution.time_factor}
        frame.add{name = "evo_factor_pollution", type = "label",
                        caption="Enemy evolution pollution factor: " .. game.map_settings.enemy_evolution.pollution_factor}
        frame.add{name = "evo_factor_destroy", type = "label",
                        caption="Enemy evolution destroy factor: " .. game.map_settings.enemy_evolution.destroy_factor}
        if game.map_settings.enemy_expansion.enabled then
            enemy_expansion_txt = "enabled"
        else
            enemy_expansion_txt = "disabled"
        end
        frame.add{name = "enemy_expansion", type = "label",
                        caption="Enemy expansion is " .. enemy_expansion_txt}
        frame.add{name = "enemy_spacer", type = "label",
                        caption=" "}
        ApplyStyle(frame.server_time, my_longer_label_style)
        ApplyStyle(frame.evo_now, my_longer_label_style)
        ApplyStyle(frame.evo_factor_time, my_longer_label_style)
        ApplyStyle(frame.evo_factor_pollution, my_longer_label_style)
        ApplyStyle(frame.evo_factor_destroy, my_longer_label_style)
        ApplyStyle(frame.enemy_expansion, my_longer_label_style)
        ApplyStyle(frame.enemy_spacer, my_spacer_style)


        -- Game Mode:
        frame.add{name = "core_mod_en", type = "label",
                        caption="Core game mode (separate spawns) is enabled."}
        ApplyStyle(frame.core_mod_en, my_longer_label_style)
        if (not ENABLE_SEPARATE_SPAWNS) then
            frame.core_mod_en.caption="Core game mode (separate spawns) is DISABLED."
            frame.core_mod_en.font_color=my_color_red
        end

        -- Soft Mods:
        if (ENABLE_SEPARATE_SPAWNS) then
            soft_mods_string = "Oarc Core"
        else
            soft_mods_string = "Oarc Core [DISABLED!]"
        end
        if (ENABLE_RSO) then
            soft_mods_string = soft_mods_string .. ", RSO"
        end
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
        frame.add{name = "soft_mods", type = "label",
                        caption="Soft Mods Enabled: " .. soft_mods_string}
        ApplyStyle(frame.soft_mods, my_longer_label_style)

        -- Spawn options:
        if (ENABLE_SEPARATE_TEAMS) then
            frame.add{name = "separate_teams_mod", type = "label",
                        caption="You are allowed to spawn on your own team (have your own research tree). All teams are COOP."}
            ApplyStyle(frame.separate_teams_mod, my_longer_label_style)
        end
        if (ENABLE_BUDDY_SPAWN) then
            frame.add{name = "buddy_spawn_mod", type = "label",
                        caption="You can chose to spawn alongside a buddy if you spawn together at the same time."}
                    ApplyStyle(frame.buddy_spawn_mod, my_longer_label_style)
        end
        if (ENABLE_SHARED_SPAWNS) then
            frame.add{name = "share_spawn_mod", type = "label",
                        caption="Spawn hosts may choose to share their spawn and allow other players to join them."}
                    ApplyStyle(frame.share_spawn_mod, my_longer_label_style)
        end
        if (ENABLE_SEPARATE_TEAMS and ENABLE_SHARED_TEAM_VISION) then
            frame.add{name = "shared_team_vision_mod", type = "label",
                        caption="Everyone (all teams) have shared vision."}
                    ApplyStyle(frame.shared_team_vision_mod, my_longer_label_style)
        end

        -- Silo:
        if (FRONTIER_ROCKET_SILO_MODE) then
            frame.add{name = "silo_mod", type = "label",
                        caption="Silos are NOT craftable. There is at least one already located on the map."}
                    ApplyStyle(frame.silo_mod, my_longer_label_style)
        end

        -- Regrowth:
        if (ENABLE_REGROWTH) then
            frame.add{name = "regrowth_mod", type = "label",
                        caption="Old parts of the map will slowly be deleted over time (chunks without any player buildings)."}
                    ApplyStyle(frame.regrowth_mod, my_longer_label_style)
        end

        -- Minimum Play Time:
        if (ENABLE_ABANDONED_BASE_REMOVAL) then
            frame.add{name = "base_removal", type = "label",
                        caption="If you leave within " .. MIN_ONLINE_TIME_IN_MINUTES .. " minutes of joining, your base and character will be deleted."}
            ApplyStyle(frame.base_removal, my_longer_warning_style)
        end

        -- Quick Start:
        if (ENABLE_POWER_ARMOR_QUICK_START) then
            frame.add{name = "power_armor_quick_start", type = "label",
                        caption="Power armor quick start enabled."}
                    ApplyStyle(frame.power_armor_quick_start, my_longer_label_style)
        end

        -- Ending Spacer
        frame.add{name = "end_spacer", type = "label",
                        caption=" "}
        ApplyStyle(frame.end_spacer, my_spacer_style)

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
        banIndex = event.element.parent.ban_players_dropdown.selected_index

        if (banIndex ~= 0) then
            banPlayer = event.element.parent.ban_players_dropdown.get_item(banIndex)
            if (game.players[banPlayer]) then
                game.ban_player(banPlayer, "Banned for griefing - Banned from admin panel.")
                DebugPrint("Banning " .. banPlayer)
            end
        end
    end
end
