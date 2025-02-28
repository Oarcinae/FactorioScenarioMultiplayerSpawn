local mod_gui = require("mod-gui")

---Test out all the fonts available in the game.
---@param player LuaPlayer
---@return nil
function TestFonts(player)
    local font_list = {
        "compi",
        "compilatron-message-font",
        "count-font",
        "default",
        "default-bold",
        "default-dialog-button",
        "default-dropdown",
        "default-game",
        "default-large",
        "default-large-bold",
        "default-large-semibold",
        "default-listbox",
        "default-semibold",
        "default-small",
        "default-small-bold",
        "default-small-semibold",
        "default-tiny-bold",
        "heading-1",
        "heading-2",
        "heading-3",
        "locale-pick",
        "scenario-message-dialog",
        "technology-slot-level-font",
        "var",
    }

    local test_frame = player.gui.screen.add{type="frame", name="font_test_frame", direction="vertical"}
    for _,font in pairs(font_list) do
        local test_text = test_frame.add{type="label", caption=font}
        test_text.style.font = font
    end

    test_frame.auto_center = true
end

function ClearTestFonts(player)
    if player.gui.screen.font_test_frame then
        player.gui.screen.font_test_frame.destroy()
    end
end

---Test out all the button styles available in the game.
---@param player LuaPlayer
---@return nil
function TestButtons(player)
    local button_styles = {
        "back_button",
        "big_slot_button",
        -- "blueprint_drop_slot_button",
        "blueprint_record_selection_button",
        "blueprint_record_slot_button",
        "browse_games_gui_toggle_favorite_off_button",
        "browse_games_gui_toggle_favorite_on_button",
        "cancel_close_button",
        -- "character_gui_entity_button",
        "choose_chat_icon_button",
        "choose_chat_icon_in_textbox_button",
        "close_button",
        "compact_slot_sized_button",
        "confirm_button",
        "confirm_double_arrow_button",
        "confirm_in_load_game_button",
        "control_settings_button",
        "control_settings_section_button",
        "current_research_info_button",
        "dark_button",
        "dark_rounded_button",
        "dialog_button",
        "drop_target_button",
        "dropdown_button",
        "entity_variation_button",
        "forward_button",
        "frame_action_button",
        "frame_button",
        "green_button",
        "highlighted_tool_button",
        "inventory_limit_slot_button",
        "left_slider_button",
        "locomotive_minimap_button",
        "logistic_slot_button",
        "map_generator_close_preview_button",
        "map_generator_confirm_button",
        "map_generator_preview_button",
        "map_view_add_button",
        "map_view_options_button",
        "menu_button",
        "mini_button",
        "mod_gui_button",
        "not_working_weapon_button",
        "open_armor_button",
        "other_settings_gui_button",
        "quick_bar_page_button",
        "quick_bar_slot_button",
        "recipe_slot_button",
        "red_back_button",
        "red_button",
        "red_confirm_button",
        "red_logistic_slot_button",
        "red_slot_button",
        "research_queue_cancel_button",
        "right_slider_button",
        "rounded_button",
        "shortcut_bar_button",
        "shortcut_bar_expand_button",
        "side_menu_button",
        "slider_button",
        "slot_button",
        "slot_sized_button",
        "station_train_status_button",
        "statistics_slot_button",
        "tile_variation_button",
        "tip_notice_button",
        "tip_notice_close_button",
        "tool_bar_open_button",
        "tool_button",
        "tracking_off_button",
        "tracking_on_button",
        "train_schedule_action_button",
        "train_schedule_add_station_button",
        "train_schedule_add_wait_condition_button",
        "train_schedule_comparison_type_button",
        "train_schedule_condition_time_selection_button",
        "train_schedule_delete_button",
        "train_schedule_fulfilled_delete_button",
        "train_schedule_fulfilled_item_select_button",
        "train_schedule_item_select_button",
        "train_schedule_temporary_station_delete_button",
        "train_status_button",
        -- "train_stop_entity_button",
        -- "wide_entity_button",
        "working_weapon_button",
        "yellow_logistic_slot_button",
    }

    local test_frame = player.gui.screen.add{type="scroll-pane", name="button_test_frame", direction="vertical"}
    -- test_frame.auto_center = true
    test_frame.vertical_scroll_policy = "auto"
    test_frame.style.maximal_height = 800

    for _,button_style in pairs(button_styles) do
        local test_button = test_frame.add
        {
            type="button",
            caption=button_style,
            style=button_style
        }
    end


end

function ClearTestButtons(player)
    if player.gui.screen.button_test_frame then
        player.gui.screen.button_test_frame.destroy()
    end
end


function SetNauvisChunksGenerated()
    local nauvis = game.surfaces["nauvis"]

    for x = -100, 100, 1 do
        for y = -100, 100, 1 do
            nauvis.set_chunk_generated_status({x=x, y=y}, defines.chunk_generated_status.entities)
        end
    end
end


function FlagEnemyForce(player, enemy_force_name)

    local enemy_force = game.forces[enemy_force_name]

    player.force.set_friend(enemy_force, true)
    player.force.set_cease_fire(enemy_force, true)

end

function UnflagEnemyForce(player, enemy_force_name)

    local enemy_force = game.forces[enemy_force_name]

    player.force.set_friend(enemy_force, false)
    player.force.set_cease_fire(enemy_force, false)

end

function CreateTestSurfaces()

    game.create_surface("vulcanus")
    game.create_surface("fulgora")
    game.create_surface("gleba")
    game.create_surface("aquilo")

end


---Searchs a 3x3 chunk around the map origin for "cargo-pod-container" entities and if they are on the same force
---as the player it will teleport the cargo pod to the player. This is meant to be a temporary work around since I don't
---know how to detect the cargo pod that is associated with the player or when it is sent/landed.
---@param player LuaPlayer
---@return nil
function DudeWheresMyCargoPod(player)

    if not player.character then
        SendErrorMsg(player, { "oarc-character-invalid" })
        return
    end

    local surface = player.character.surface
    local radius = CHUNK_SIZE*3
    local search_area = {{-radius,-radius},{radius,radius}}

    local pods = surface.find_entities_filtered{area=search_area, name="cargo-pod-container", force=player.force}

    if #pods == 0 then
        SendErrorMsg(player, { "oarc-no-cargo-pods" })
        return
    end

    for _,cargo_pod in pairs(pods) do

        local new_position = surface.find_non_colliding_position("cargo-pod-container", player.character.position, CHUNK_SIZE, 1)

        if new_position == nil then
            SendErrorMsg(player, { "oarc-teleport-cargo-pod-fail" })
            return
        end

        cargo_pod.teleport(new_position)
        CompatSend(player, { "oarc-teleport-cargo-pod-success" })
    end
end



---Allow players to reroll their spawn point, dangerous because this doesn't do a lot of checks.
---@param player LuaPlayer
---@return nil
function RerollSpawn(player)

    -- Make sure character is valid
    if not player.character then
        log("ERROR - RerollSpawn - No valid character for player: " .. player.name)
        return
    end

    -- Ensure we still have their previous spawn choices
    local spawn_choices = storage.spawn_choices[player.name]
    if (spawn_choices == nil) then
        log("ERROR - RerollSpawn - No spawn choices for player: " .. player.name)
        return
    end

    -- If it is a buddy spawn, tell them we don't support this:
    if (spawn_choices.buddy ~= nil) then
        SendErrorMsg(player, { "oarc-no-reroll-buddy-spawn" })
        return
    end

    local surface = player.character.surface
    local surface_name = surface.name

    -- Confirm there is AN existing spawn point for this player on this surface
    if (storage.unique_spawns[surface_name] == nil or storage.unique_spawns[surface_name][player.name] == nil) then
        log("ERROR - RerollSpawn - Can't reroll? No existing spawn for " .. player.name)
        return
    end

    -- Save a copy of the previous spawn point
    local old_spawn_point = table.deepcopy(storage.unique_spawns[surface_name][player.name])

    -- Find a new spawn point
    local spawn_position = FindUngeneratedCoordinates(surface_name, spawn_choices.distance, 3)
    -- If that fails, just throw a warning and don't spawn them. They can try again.
    if ((spawn_position.x == 0) and (spawn_position.y == 0)) then
        SendErrorMsg(player, { "oarc-no-ungenerated-land-error" })
        return
    end

    -- Remove the old spawn point
    if (storage.ocfg.regrowth.enable_abandoned_base_cleanup) then
        log("Removing base: " .. spawn_position.x .. "," .. spawn_position.y .. " on surface: " .. surface_name)

        -- Clear an area around the spawn that SHOULD not include any other bases.
        local clear_radius = storage.ocfg.gameplay.minimum_distance_to_existing_chunks - 2 -- Bring in a bit for safety.
        RegrowthMarkAreaForRemoval(surface_name, old_spawn_point.position, clear_radius)
        TriggerCleanup()
        script.raise_event("oarc-mod-on-spawn-remove-request", {spawn_data = old_spawn_point})
    end

    -- Queue spawn generation and the player.
    local delayed_spawn = GenerateNewSpawn(player.name, surface_name, spawn_position, spawn_choices, old_spawn_point.primary)
    QueuePlayerForSpawn(player.name, delayed_spawn)

    -- Send them to the holding pen
    SafeTeleport(player, game.surfaces[HOLDING_PEN_SURFACE_NAME], {x=0,y=0})

    -- Queue joiners too (if they are on this surface?)
    for _,joiner in pairs(old_spawn_point.joiners) do
        local joiner_player = game.players[joiner]
        if (joiner_player ~= nil) and joiner_player.surface.name == surface_name then
            QueuePlayerForSpawn(joiner, delayed_spawn)
            SafeTeleport(game.players[joiner], game.surfaces[HOLDING_PEN_SURFACE_NAME], {x=0,y=0})
        end
    end

    -- Announce
    SendBroadcastMsg({"", { "oarc-spawn-rerolled", player.name, surface.name }, " ", GetGPStext(surface.name, spawn_position)})
end
