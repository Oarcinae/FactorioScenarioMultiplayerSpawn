-- Contains the GUI for the player list tab.

---Used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreatePlayerListTab(tab_container, player)

    local scroll_pane = tab_container.add {
        type = "scroll-pane",
        direction = "vertical",
        vertical_scroll_policy = "always",
    }
    scroll_pane.style.maximal_height = 500


    -- Make a table: player name, force name, home surface, time played, gps button
    local player_table = scroll_pane.add {
        type = "table",
        column_count = 6,
        style = "bordered_table",
    }

    --- Add the header rows
    AddLabel(player_table, nil, {"oarc-player-list-tab-column-header-player"}, "caption_label")
    AddLabel(player_table, nil, {"oarc-player-list-tab-column-header-force"}, "caption_label")
    AddLabel(player_table, nil, {"oarc-player-list-tab-column-header-surface"}, "caption_label")
    AddLabel(player_table, nil, {"oarc-player-list-tab-column-header-time-player"}, "caption_label")
    AddLabel(player_table, nil, {"oarc-player-list-tab-column-header-location"}, "caption_label")
    AddLabel(player_table, nil, {"oarc-player-list-tab-column-header-status"}, "caption_label")

    -- List online players first
    for _,online_player in pairs(game.connected_players) do
        AddPlayerRow(player_table, online_player.name, true)
    end

    -- List offline players later
    for  _,player in pairs(game.players) do
        if (not player.connected) then
            AddPlayerRow(player_table, player.name, false)
        end
    end

end


---Add a row to the table for a player
---@param table LuaGuiElement
---@param player_name string
---@param online boolean
---@return nil
function AddPlayerRow(table, player_name, online)
    local player = game.players[player_name]
    if (player) then
        if player.admin then
            local label = AddLabel(table, nil, player.name, my_player_list_admin_style)
            label.tooltip = "Admin"
        else
            AddLabel(table, nil, player.name, my_label_style)
        end
        AddLabel(table, nil, player.force.name, my_label_style)

        -- List home surface name or holding pen
        local character = player.character
        if character and (character.surface.name == HOLDING_PEN_SURFACE_NAME) then
            AddLabel(table, nil, {"oarc-player-waiting-to-spawn"}, my_label_style)
        else
            local spawn = FindPlayerHomeSpawn(player.name)
            if (spawn) then
                if game.planets[spawn.surface_name] ~= nil then
                    AddLabel(table, nil, {"", "[planet=", spawn.surface_name, "] ", {"space-location-name."..spawn.surface_name}}, my_label_style)
                else
                    AddLabel(table, nil, game.surfaces[spawn.surface_name].localised_name, my_label_style)
                end
            else
                AddLabel(table, nil, "Unknown?", my_label_style) -- Shouldn't happen
            end
        end

        AddLabel(table, nil, FormatTimeHoursSecs(player.online_time), my_label_style)

        CreatePlayerGPSButton(table, player.name)

        if online then
            local label = AddLabel(table, nil, {"oarc-player-online"}, my_player_list_style)
            label.style.font_color = {r=0.1, g=1, b=0.1}
        else
            AddLabel(table, nil, {"oarc-player-offline"}, my_player_list_offline_style)
        end
    end
end


---Display a GPS button for a specific location. (For the player list)
---@param container LuaGuiElement
---@param player_name string
---@return nil
function CreatePlayerGPSButton(container, player_name)
    local flow = container.add {
        type = "flow",
        direction = "horizontal",
    }
    flow.style.vertical_align = "center"

    local gps_button = flow.add {
        type = "sprite-button",
        sprite = "utility/gps_map_icon",
        tags = {
            action = "oarc_player_list_tab",
            setting = "show_location",
            player_name = player_name,
        },
        style = "slot_button",
        tooltip = {"oarc-player-list-tab-location-button-tooltip"},
    }
    gps_button.style.width = 28
    gps_button.style.height = 28

    local surface_name
    if game.players[player_name].character ~= nil then
        surface_name = game.players[player_name].character.surface.name
    else
        surface_name = game.players[player_name].surface.name
    end

    if game.planets[surface_name] ~= nil then
        AddLabel(flow, nil, {"", "[planet=", surface_name, "] ", {"space-location-name."..surface_name}}, my_label_style)
    else
        AddLabel(flow, nil, game.surfaces[surface_name].localised_name, my_label_style)
    end
end

---Handle the gui click of the player list tab in the Oarc GUI.
---@param event EventData.on_gui_click
---@return nil
function PlayerListTabGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_player_list_tab") then
        return
    end

    -- Shows the player's current location on the map
    if (tags.setting == "show_location") then
        local player_name = tags.player_name --[[@as string]]
        local target_player = game.players[player_name]

        if (target_player == nil) then
            SendErrorMsg(player, {"oarc-player-not-found", player_name})
            return
        end

        local position, surface
        if (target_player.character) then
            position = target_player.character.position
            surface = target_player.character.surface
        else
            position = target_player.position
            surface = target_player.surface
        end
        player.set_controller{type = defines.controllers.remote, position = position, surface = surface}
        CompatSend(player, {"", target_player.name, ": ", GetGPStext(surface.name, position)})
    end
end