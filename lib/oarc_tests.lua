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

function RecreateOarcGui(player)
    if (mod_gui.get_button_flow(player).oarc_button ~= nil) then
        mod_gui.get_button_flow(player).oarc_button.destroy()
    end

    if (mod_gui.get_frame_flow(player)[OARC_GUI] ~= nil) then
        mod_gui.get_frame_flow(player)[OARC_GUI].destroy()
    end

    InitOarcGuiTabs(player)
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