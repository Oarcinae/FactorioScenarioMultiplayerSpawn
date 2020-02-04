-- oarc_player_list.lua
-- Mar 2019

--------------------------------------------------------------------------------
-- Player List GUI - My own version
--------------------------------------------------------------------------------
function CreatePlayerListGuiTab(tab_container, player)
    local scrollFrame = tab_container.add{type="scroll-pane",
                                    name="playerList-panel",
                                    direction = "vertical"}
    ApplyStyle(scrollFrame, my_player_list_fixed_width_style)
    scrollFrame.horizontal_scroll_policy = "never"

    AddLabel(scrollFrame, "online_title_msg", "Online Players:", my_label_header_style)
    for _,player in pairs(game.connected_players) do
        local caption_str = player.name.." ["..player.force.name.."]".." ("..formattime_hours_mins(player.online_time)..")"
        if (player.admin) then
            AddLabel(scrollFrame, player.name.."_plist", caption_str, my_player_list_admin_style)
        else
            AddLabel(scrollFrame, player.name.."_plist", caption_str, my_player_list_style)
        end
    end

    -- List offline players
    if (global.ocfg.list_offline_players) then
        AddSpacerLine(scrollFrame)
        AddLabel(scrollFrame, "offline_title_msg", "Offline Players:", my_label_header_grey_style)
        for _,player in pairs(game.players) do
            if (not player.connected) then
                local caption_str = player.name.." ["..player.force.name.."]".." ("..formattime_hours_mins(player.online_time)..")"
                local text = scrollFrame.add{type="label", caption=caption_str, name=player.name.."_plist"}
                ApplyStyle(text, my_player_list_offline_style)
            end
        end
    end
end
