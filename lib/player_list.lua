-- oarc_player_list.lua
-- Mar 2019

--------------------------------------------------------------------------------
-- Player List GUI - My own version
--------------------------------------------------------------------------------
function CreatePlayerListGui(event)
  local player = game.players[event.player_index]
  if player.gui.top.playerList == nil then
      player.gui.top.add{name="playerList", type="button", caption="Player List"}
  end   
end

local function ExpandPlayerListGui(player)
    local frame = player.gui.left["playerList-panel"]
    if (frame) then
        frame.destroy()
    else
        local frame = player.gui.left.add{type="frame",
                                            name="playerList-panel",
                                            caption="Online:"}
        local scrollFrame = frame.add{type="scroll-pane",
                                        name="playerList-panel",
                                        direction = "vertical"}
        ApplyStyle(scrollFrame, my_player_list_fixed_width_style)
        scrollFrame.horizontal_scroll_policy = "never"
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
            AddLabel(scrollFrame, "offline_title_msg", "Offline Players:", my_label_style)
            for _,player in pairs(game.players) do
                if (not player.connected) then
                    local caption_str = player.name.." ["..player.force.name.."]".." ("..formattime_hours_mins(player.online_time)..")"
                    local text = scrollFrame.add{type="label", caption=caption_str, name=player.name.."_plist"}
                    ApplyStyle(text, my_player_list_offline_style)
                end
            end
        end
        local spacer = scrollFrame.add{type="label", caption="     ", name="plist_spacer_plist"}
        ApplyStyle(spacer, my_player_list_style_spacer)
    end
end

function PlayerListGuiClick(event) 
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.element.player_index]
    local name = event.element.name

    if (name == "playerList") then
        ExpandPlayerListGui(player)        
    end
end
