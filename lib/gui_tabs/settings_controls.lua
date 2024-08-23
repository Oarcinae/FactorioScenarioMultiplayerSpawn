-- Contains the GUI for the controlling various settings of the mod.

---Creates the content in the tab used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
function CreateSettingsControlsTab(tab_container, player)
    AddLabel(tab_container, nil, { "oarc-settings-tab-title" }, my_label_header_style)

    if (player.admin) then
        AddLabel(tab_container, nil, { "oarc-settings-tab-admin-warning" }, my_warning_style)
    end

    AddTextfieldSetting(tab_container, "welcome_msg_title", { "mod-setting-name.oarc-mod-welcome-msg-title" },
        global.ocfg.server_info.welcome_msg_title, player.admin, { "mod-setting-description.oarc-mod-welcome-msg-title" })

    AddCheckboxSetting(tab_container, "enable_main_team", { "mod-setting-name.oarc-mod-enable-main-team" },
        global.ocfg.gameplay.enable_main_team, player.admin, { "mod-setting-description.oarc-mod-enable-main-team" })

end

---Handles the click event for the tab used by AddOarcGuiTab
---@param event EventData.on_gui_click
---@return nil
function SettingsControlsTabGuiClick(event)
    if not (event.element.valid) then return end
    local gui_elem = event.element
    -- local player = game.players[event.player_index]

    if (gui_elem.tags.action ~= "oarc_settings_tab") then return end

    local setting_name = gui_elem.tags.setting

    if (setting_name == "enable_main_team") then
        log("enable_main_team: " .. tostring(gui_elem.state))
        global.ocfg.gameplay.enable_main_team = gui_elem.state
        settings.global["oarc-mod-enable-main-team"] = { value = gui_elem.state }
    end
end

---Creates a checkbox setting in the tab used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param setting_name string
---@param setting_caption LocalisedString
---@param setting_state boolean
---@param enabled boolean
---@param tooltip LocalisedString
---@return nil
function AddCheckboxSetting(tab_container, setting_name, setting_caption, setting_state, enabled, tooltip)
    tab_container.add {
        type = "checkbox",
        caption = setting_caption,
        state = setting_state,
        enabled = enabled,
        tooltip = tooltip,
        tags = { action = "oarc_settings_tab", setting = setting_name },
    }
end

---Creates a textfield setting in the tab used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param setting_name string
---@param setting_caption LocalisedString
---@param setting_string string
---@param enabled boolean
---@param tooltip LocalisedString
---@return nil
function AddTextfieldSetting(tab_container, setting_name, setting_caption, setting_string, enabled, tooltip)
    tab_container.add {
        type = "textfield",
        caption = setting_caption,
        text = setting_string,
        enabled = enabled,
        tooltip = tooltip,
        tags = { action = "oarc_settings_tab", setting = setting_name },
    }
end