-- Contains the GUI for the controlling various settings of the mod.

---Creates the content in the tab used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
function CreateSettingsControlsTab(tab_container, player)
    AddLabel(tab_container, nil, { "oarc-settings-tab-title" }, my_label_header_style)

    if (player.admin) then
        AddLabel(tab_container, nil, { "oarc-settings-tab-admin-warning" }, my_warning_style)
    end

    for index,entry in pairs(OCFG_KEYS) do
        if (entry.type == "boolean") then
            AddCheckboxSetting(tab_container, index, entry, player.admin)
        elseif (entry.type == "string") then
            AddTextfieldSetting(tab_container, index, entry, player.admin)
        elseif (entry.type == "integer") then
            AddIntegerSetting(tab_container, index, entry, player.admin)
        end
    end
end

---Handles the click event for the tab used by AddOarcGuiTab
---@param event EventData.on_gui_click
---@return nil
function SettingsControlsTabGuiClick(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab") then return end
    local setting_name = gui_elem.tags.setting

    for index,entry in pairs(OCFG_KEYS) do
        if (index == setting_name) then
            if (entry.type == "boolean") then
                SetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys, gui_elem.state)
                settings.global[entry.mod_key] = { value = gui_elem.state }
            end
        end
    end
end

---Handles the text entry event for the tab used by AddOarcGuiTab
---@param event EventData.on_gui_text_changed
---@return nil
function SettingsControlsTabGuiTextChanged(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab") then return end
    local setting_name = gui_elem.tags.setting

    for index,entry in pairs(OCFG_KEYS) do
        if (index == setting_name) then
            if (entry.type == "string") or (entry.type == "integer") then
                SetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys, gui_elem.text)
                settings.global[entry.mod_key] = { value = gui_elem.text }
            end
        end
    end
end

---Creates a checkbox setting
---@param tab_container LuaGuiElement
---@param index string
---@param entry OarcSettingsLookup
---@param enabled boolean
---@return nil
function AddCheckboxSetting(tab_container, index, entry, enabled)
    tab_container.add{
        type = "checkbox",
        caption = { "mod-setting-name."..entry.mod_key },
        state = GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys),
        enabled = enabled,
        tooltip = { "mod-setting-description."..entry.mod_key },
        tags = { action = "oarc_settings_tab", setting = index },
    }
end

---Creates a textfield setting
---@param tab_container LuaGuiElement
---@param index string
---@param entry OarcSettingsLookup
---@param enabled boolean
---@return nil
function AddTextfieldSetting(tab_container, index, entry, enabled)
    local horizontal_flow = tab_container.add {
        type = "flow",
        direction = "horizontal",
    }
    horizontal_flow.add {
        type = "label",
        caption = { "mod-setting-name."..entry.mod_key },
        tooltip = { "mod-setting-description."..entry.mod_key },
    }
    horizontal_flow.add {
        type = "textfield",
        caption = { "mod-setting-name."..entry.mod_key },
        text = GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys),
        enabled = enabled,
        tooltip = { "mod-setting-description."..entry.mod_key },
        tags = { action = "oarc_settings_tab", setting = index },
    }
end

---Creates an integer setting
---@param tab_container LuaGuiElement
---@param index string
---@param entry OarcSettingsLookup
---@param enabled boolean
---@return nil
function AddIntegerSetting(tab_container, index, entry, enabled)
    local horizontal_flow = tab_container.add {
        type = "flow",
        direction = "horizontal",
    }
    horizontal_flow.add {
        type = "label",
        caption = { "mod-setting-name."..entry.mod_key },
        tooltip = { "mod-setting-description."..entry.mod_key },
    }
    horizontal_flow.add {
        type = "textfield",
        numeric = true,
        caption = { "mod-setting-name."..entry.mod_key },
        text = GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys),
        enabled = enabled,
        tooltip = { "mod-setting-description."..entry.mod_key },
        tags = { action = "oarc_settings_tab", setting = index },
    }
end