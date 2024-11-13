-- Contains the GUI for the controlling various settings of the mod.

---Creates the content in the tab used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
function CreateSettingsControlsTab(tab_container, player)

    if (player.admin) then
        local label = AddLabel(tab_container, nil, { "oarc-settings-tab-admin-warning" }, my_warning_style)

    else
        local label = AddLabel(tab_container, nil, { "oarc-settings-tab-player-warning" }, my_warning_style)

    end

    local label = AddLabel(tab_container, nil, { "oarc-settings-tab-description" }, my_label_style)
    label.style.bottom_padding = 5
    label.style.maximal_width = 600

    local flow = tab_container.add { type = "flow", direction = "horizontal", }
    
    local scroll_pane_left = flow.add {
        type = "scroll-pane",
        direction = "vertical",
        vertical_scroll_policy = "always",
    }
    scroll_pane_left.style.maximal_height = GENERIC_GUI_MAX_HEIGHT
    scroll_pane_left.style.padding = 5
    scroll_pane_left.style.right_margin = 2
    CreateModSettingsSection(scroll_pane_left, player)

    local scroll_pane_right = flow.add {
        type = "scroll-pane",
        direction = "vertical",
        vertical_scroll_policy = "always",
    }
    scroll_pane_right.style.maximal_height = GENERIC_GUI_MAX_HEIGHT
    scroll_pane_right.style.padding = 5
    scroll_pane_right.style.left_margin = 2

    CreateSurfaceSettingsSection(scroll_pane_right, player)
    AddSpacerLine(scroll_pane_right)

    if (player.admin) then
        CreateSettingsExportSection(scroll_pane_right, player)
    end
end

---Create the content for the mod settings section
---@param container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateModSettingsSection(container, player)
    AddLabel(container, nil, { "oarc-settings-tab-title-mod-settings" }, my_label_header2_style)

    for index,entry in pairs(OCFG_KEYS) do
        if (entry.type == "header") then
            AddSpacerLine(container)
            AddLabel(container, nil, entry.text, "caption_label")
        elseif (entry.type == "subheader") then
            AddLabel(container, nil, entry.text, "bold_label")
        elseif (entry.type == "boolean") then
            AddCheckboxSetting(container, index, entry, player.admin)
        elseif (entry.type == "string") then
            AddTextfieldSetting(container, index, entry, player.admin)
        elseif (entry.type == "integer") then
            AddIntegerSetting(container, index, entry, player.admin)
        elseif (entry.type == "double") then
            AddDoubleSetting(container, index, entry, player.admin)
        elseif (entry.type == "string-list") then
            AddStringListDropdownSetting(container, index, entry, player.admin)
        end
    end
end

---Create the content for the surface settings section
---@param container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateSurfaceSettingsSection(container, player)
    AddLabel(container, nil, { "oarc-settings-tab-title-surface" }, my_label_header2_style)
    local warning = AddLabel(container, nil, { "oarc-settings-tab-surfaces-warning" }, my_warning_style)
    warning.style.maximal_width = 300

    --- Create a table with 3 columns. Surface Name, Spawning Enabled, Regrowth Enabled
    local surface_table = container.add {
        type = "table",
        name = "surface_table",
        column_count = 4,
        style = "bordered_table",
    }

    --- Add the header row
    AddLabel(surface_table, nil, {"oarc-settings-tab-surface-column-header"}, "caption_label")
    AddLabel(surface_table, nil, {"oarc-settings-tab-surface-spawning-enabled"}, "caption_label")
    AddLabel(surface_table, nil, {"oarc-settings-tab-surface-secondary-enabled"}, "caption_label")
    AddLabel(surface_table, nil, {"oarc-settings-tab-surface-regrowth-enabled"}, "caption_label")

    --- Add the rows
    for name, allowed in pairs(storage.oarc_surfaces) do
        AddLabel(surface_table, nil, name, my_label_style)
        AddSurfaceCheckboxSetting(surface_table, name, "spawn_enabled", allowed.primary, player.admin,
                                    { "oarc-settings-tab-surface-checkbox-tooltip" })
        AddSurfaceCheckboxSetting(surface_table, name, "secondary_enabled", allowed.secondary, player.admin,
                                    { "oarc-settings-tab-surface-secondary-checkbox-tooltip" })
        
        local regrowth_enabled = TableContains(storage.rg.active_surfaces, name)
        AddSurfaceCheckboxSetting(surface_table, name, "regrowth_enabled", regrowth_enabled, player.admin,
                                    {"oarc-settings-tab-surface-regrowth-checkbox-tooltip"})
    end
    
end

---Create the content for the settings export section. Exports the entire storage.ocfg table into a string.
---@param container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateSettingsExportSection(container, player)
    AddLabel(container, nil, { "oarc-settings-tab-title-export" }, my_label_header2_style)

    local horizontal_flow = container.add {
        type = "flow",
        direction = "horizontal",
    }

    local export_button = horizontal_flow.add {
        type = "button",
        caption = { "oarc-settings-tab-export-button" },
        style = "green_button",
        tooltip = { "oarc-settings-tab-export-button-tooltip" },
        tags = {
            action = "oarc_settings_tab_right_pane",
            setting = "oarc_settings_export"
        },
    }

    local import_button = horizontal_flow.add {
        type = "button",
        caption = { "oarc-settings-tab-import-button" },
        tooltip = { "oarc-settings-tab-import-button-tooltip" },
        style = "red_button",
        tags = {
            action = "oarc_settings_tab_right_pane",
            setting = "oarc_settings_import"
        },
    }

    local export_textfield = container.add {
        type = "textfield",
        name = "export_textfield",
        text = " ",
        tags = {
            action = "oarc_settings_tab_right_pane",
            setting = "oarc_settings_textfield"
        },
    }
    export_textfield.style.horizontally_stretchable = true
    export_textfield.style.maximal_width = 500
end

---Handles the click event for the tab used by AddOarcGuiTab
---@param event EventData.on_gui_click
---@return nil
function SettingsControlsTabGuiClick(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab_left_pane") then return end
    local index = gui_elem.tags.setting

    local entry = OCFG_KEYS[index]
    if (entry.type == "boolean") then
        if (entry.mod_key ~= "") then
            settings.global[entry.mod_key] = { value = gui_elem.state }
        else
            SetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys, gui_elem.state)
        end
    end
end

---Handles the text entry event for the tab used by AddOarcGuiTab
---@param event EventData.on_gui_text_changed
---@return nil
function SettingsControlsTabGuiTextChanged(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab_left_pane") then return end
    local index = gui_elem.tags.setting
    local value = gui_elem.text
    local entry = OCFG_KEYS[index]
    
    if (entry.type == "string") then
        gui_elem.style = "invalid_value_textfield"
    elseif (entry.type == "integer") then
        gui_elem.style = "invalid_value_textfield"
        gui_elem.style.width = 50
    end
end

---Handles the confirmed text entry event
---@param event EventData.on_gui_confirmed
---@return nil
function SettingsControlsTabGuiTextconfirmed(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab_left_pane") then return end
    local index = gui_elem.tags.setting
    local value = gui_elem.text
    local entry = OCFG_KEYS[index]
    
    if (entry.type == "string") then
        if value == "" then -- Force a non-empty string!
            value = " "
            gui_elem.text = " "
        end
        gui_elem.style = "textbox"
        settings.global[entry.mod_key] = { value = gui_elem.text }
    elseif (entry.type == "integer") then
        local safe_value = GetSafeIntValueForModSetting(value, entry.mod_key)
        if not pcall(function() settings.global[entry.mod_key] = { value = safe_value } end) then
            settings.global[entry.mod_key] = { value = prototypes.mod_setting[entry.mod_key].default_value }
            log("Error setting value for " .. entry.mod_key .. " to " .. safe_value)
        end
        gui_elem.text = tostring(settings.global[entry.mod_key].value)
        gui_elem.style = "textbox"
        gui_elem.style.width = 50

        local slider = gui_elem.parent["slider"]
        slider.slider_value = settings.global[entry.mod_key].value --[[@as integer]]
    elseif (entry.type == "double") then
        local safe_value = GetSafeDoubleValueForModSetting(value, entry.mod_key)
        if not pcall(function() settings.global[entry.mod_key] = { value = safe_value } end) then
            settings.global[entry.mod_key] = { value = prototypes.mod_setting[entry.mod_key].default_value }
            log("Error setting value for " .. entry.mod_key .. " to " .. safe_value)
        end
        gui_elem.text = string.format("%.2f", settings.global[entry.mod_key].value)
        gui_elem.style = "textbox"
        gui_elem.style.width = 50

        local slider = gui_elem.parent["slider"]
        slider.slider_value = settings.global[entry.mod_key].value --[[@as number]]
    end
end


---Handles slider value changes
---@param event EventData.on_gui_value_changed
---@return nil
function SettingsControlsTabGuiValueChanged(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab_slider") then return end
    local index = gui_elem.tags.setting
    local value = gui_elem.slider_value
    local entry = OCFG_KEYS[index]

    if (entry.type == "integer") then
        local textfield = gui_elem.parent["textfield"]
        settings.global[entry.mod_key] = { value = value } -- Assumes that the slider can only produce valid inputs!
        textfield.text = tostring(value)
    elseif (entry.type == "double") then
        local textfield = gui_elem.parent["textfield"]
        settings.global[entry.mod_key] = { value = value } -- Assumes that the slider can only produce valid inputs!
        textfield.text = string.format("%.2f", value)
    end
end

---Makes sure a given value is within the min/max range of a mod setting
---@param input string|number|integer
---@param mod_key string
---@return integer
function GetSafeIntValueForModSetting(input, mod_key)
    local value_num = tonumber(input)
    if not value_num then
        value_num = tonumber(prototypes.mod_setting[mod_key].default_value)
    else
        local minimum = prototypes.mod_setting[mod_key].minimum_value
        local maximum = prototypes.mod_setting[mod_key].maximum_value
        if minimum ~= nil then
            value_num = math.max(value_num, minimum)
        end
        if maximum ~= nil then
            value_num = math.min(value_num, maximum)
        end
        value_num = math.floor(value_num)
    end
    return value_num --[[@as integer]]
end

---Makes sure a given value is within the min/max range of a mod setting (double)
---@param input string|number|integer
---@param mod_key string
---@return number
function GetSafeDoubleValueForModSetting(input, mod_key)
    local value_num = tonumber(input)
    if not value_num then
        value_num = tonumber(prototypes.mod_setting[mod_key].default_value)
    else
        local minimum = prototypes.mod_setting[mod_key].minimum_value
        local maximum = prototypes.mod_setting[mod_key].maximum_value
        if minimum ~= nil then
            value_num = math.max(value_num, minimum)
        end
        if maximum ~= nil then
            value_num = math.min(value_num, maximum)
        end
    end
    return value_num --[[@as number]]
end

---Creates a checkbox setting
---@param tab_container LuaGuiElement
---@param index string
---@param entry OarcSettingsLookup
---@param enabled boolean
---@return nil
function AddCheckboxSetting(tab_container, index, entry, enabled)
    local caption, tooltip = GetCaptionAndTooltip(entry)
    tab_container.add{
        type = "checkbox",
        caption = caption,
        state = GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys),
        enabled = enabled,
        tooltip = tooltip,
        tags = { action = "oarc_settings_tab_left_pane", setting = index },
    }
end

---Gets the caption and tooltip for a setting entry whether it is a mod setting or not.
---@param entry OarcSettingsLookup
---@return LocalisedString, LocalisedString
function GetCaptionAndTooltip(entry)
    local caption
    local tooltip
    if (entry.mod_key == "") then
        caption = entry.caption
        tooltip = entry.tooltip
    else
        caption = { "mod-setting-name."..entry.mod_key }
        tooltip = { "mod-setting-description."..entry.mod_key }
    end
    return caption, tooltip
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
    local dragger = horizontal_flow.add {
        type = "empty-widget",
    }
    dragger.style.horizontally_stretchable = true
    
    local tooltip = {"", {"mod-setting-description."..entry.mod_key }, " ", { "oarc-settings-tab-text-field-enter-tooltip" }}

    horizontal_flow.add {
        type = "textfield",
        caption = { "mod-setting-name."..entry.mod_key },
        text = GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys),
        enabled = enabled,
        tooltip = tooltip,
        tags = { action = "oarc_settings_tab_left_pane", setting = index  },
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
    local dragger = horizontal_flow.add {
        type = "empty-widget",
    }
    dragger.style.horizontally_stretchable = true

    local slider = horizontal_flow.add {
        name = "slider",
        type = "slider",
        minimum_value = prototypes.mod_setting[entry.mod_key].minimum_value,
        maximum_value = prototypes.mod_setting[entry.mod_key].maximum_value,
        value = GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys),
        enabled = enabled,
        tooltip = { "mod-setting-description."..entry.mod_key },
        tags = { action = "oarc_settings_tab_slider", setting = index },
        discrete_values = true,
        value_step = 1,
    }

    local tooltip = {"", {"mod-setting-description."..entry.mod_key }, " ", { "oarc-settings-tab-text-field-enter-tooltip" }}
    local textfield = horizontal_flow.add {
        name = "textfield",
        type = "textfield",
        numeric = true,
        caption = { "mod-setting-name."..entry.mod_key },
        text = GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys),
        enabled = enabled,
        tooltip = tooltip,
        tags = { action = "oarc_settings_tab_left_pane", setting = index },
    }
    textfield.style.width = 50
end

---Creates a double setting
---@param tab_container LuaGuiElement
---@param index string
---@param entry OarcSettingsLookup
---@param enabled boolean
---@return nil
function AddDoubleSetting(tab_container, index, entry, enabled)
    local horizontal_flow = tab_container.add {
        type = "flow",
        direction = "horizontal",
    }
    horizontal_flow.add {
        type = "label",
        caption = { "mod-setting-name."..entry.mod_key },
        tooltip = { "mod-setting-description."..entry.mod_key },
    }
    local dragger = horizontal_flow.add {
        type = "empty-widget",
    }
    dragger.style.horizontally_stretchable = true

    local slider = horizontal_flow.add {
        name = "slider",
        type = "slider",
        minimum_value = prototypes.mod_setting[entry.mod_key].minimum_value,
        maximum_value = prototypes.mod_setting[entry.mod_key].maximum_value,
        value = GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys),
        enabled = enabled,
        tooltip = { "mod-setting-description."..entry.mod_key },
        tags = { action = "oarc_settings_tab_slider", setting = index },
        discrete_values = false,
        value_step = 0.01,
    }

    local tooltip = {"", {"mod-setting-description."..entry.mod_key }, " ", { "oarc-settings-tab-text-field-enter-tooltip" }}
    local textfield = horizontal_flow.add {
        name = "textfield",
        type = "textfield",
        numeric = true,
        allow_decimal = true,
        caption = { "mod-setting-name."..entry.mod_key },
        text = string.format("%.2f", GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys)),
        enabled = enabled,
        tooltip = tooltip,
        tags = { action = "oarc_settings_tab_left_pane", setting = index },
    }
    textfield.style.width = 50
end

---Create a dropdown setting for a string setting with allowed_values set
---@param tab_container LuaGuiElement
---@param index string
---@param entry OarcSettingsLookup
---@param enabled boolean
---@return nil
function AddStringListDropdownSetting(tab_container, index, entry, enabled)
    local horizontal_flow = tab_container.add {
        type = "flow",
        direction = "horizontal",
    }
    horizontal_flow.add {
        type = "label",
        caption = { "mod-setting-name."..entry.mod_key },
        tooltip = { "mod-setting-description."..entry.mod_key },
    }
    local dragger = horizontal_flow.add {
        type = "empty-widget",
    }
    dragger.style.horizontally_stretchable = true

    local allowed_values = prototypes.mod_setting[entry.mod_key].allowed_values --[[@as string[] ]]
    
    local selected_index = 1
    for i,v in pairs(allowed_values) do
        if (v == GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys)) then
            selected_index = i
            break
        end
    end

    local dropdown = horizontal_flow.add {
        type = "drop-down",
        items = allowed_values,
        selected_index = selected_index,
        enabled = enabled,
        tooltip = { "mod-setting-description."..entry.mod_key },
        tags = { action = "oarc_settings_tab_left_pane", setting = index },
    }
end

---Creates a checkbox setting for surface related settings.
---@param parent LuaGuiElement
---@param surface_name string
---@param setting_name string
---@param state boolean
---@param admin boolean
---@param tooltip LocalisedString
---@return nil
function AddSurfaceCheckboxSetting(parent, surface_name, setting_name, state, admin, tooltip)
    parent.add{
        name = surface_name.."_"..setting_name,
        type = "checkbox",
        state = state,
        tags = { action = "oarc_settings_tab_right_pane", setting = setting_name, surface = surface_name },
        enabled = admin,
        tooltip = tooltip,
    }
end

---Handles the click event for surface related settings
---@param event EventData.on_gui_click
---@return nil
function SettingsSurfaceControlsTabGuiClick(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab_right_pane") then return end
    local setting_name = gui_elem.tags.setting

    if (setting_name == "spawn_enabled") then
        local surface_name = gui_elem.tags.surface --[[@as string]]
        storage.oarc_surfaces[surface_name].primary = gui_elem.state

        if (#GetAllowedSurfaces() == 0) then
            log("Warning - GetAllowedSurfaces() - No surfaces found! Forcing default surface!")
            storage.oarc_surfaces[storage.ocfg.gameplay.default_surface].primary = true
            event.element.parent[storage.ocfg.gameplay.default_surface.."_spawn_enabled"].state = true
        end

    elseif (setting_name == "secondary_enabled") then
        local surface_name = gui_elem.tags.surface --[[@as string]]
        storage.oarc_surfaces[surface_name].secondary = gui_elem.state


    elseif (setting_name == "regrowth_enabled") then
        local surface_name = gui_elem.tags.surface --[[@as string]]

        if (gui_elem.state) then
            if not IsRegrowthEnabledOnSurface(surface_name) then
                RegrowthEnableSurface(surface_name)
            end
        else
            if IsRegrowthEnabledOnSurface(surface_name) then
                RegrowthDisableSurface(surface_name)
            end
        end

    elseif (setting_name == "oarc_settings_textfield") then
        gui_elem.select_all() -- Select all text when clicked

    elseif (setting_name == "oarc_settings_export") then

        log("Exported settings!")
        local export_textfield = gui_elem.parent.parent["export_textfield"]
        export_textfield.text = serpent.line(storage.ocfg, {compact = true, sparse = true})
    
    elseif (setting_name == "oarc_settings_import") then
        local player = game.players[event.player_index]
        local export_textfield = gui_elem.parent.parent["export_textfield"]
        local import_text = export_textfield.text
        local ok, copy = serpent.load(import_text)
        if (not ok) or (type(copy) ~= "table") or (next(copy) == nil) then
            log("Error importing settings!")
            player.print("Error importing settings!")
        else
            storage.ocfg = table.deepcopy(copy)
            ValidateSettings() -- Some basic validation, not 100% foolproof
            SyncModSettingsToOCFG() -- Sync the mod settings.
            log("Imported settings!")
            player.print("Imported settings!")
            OarcGuiRefreshContent(player)
        end
    end

end


---Handles dropdown selection events
---@param event EventData.on_gui_selection_state_changed
---@return nil
function SettingsControlsTabGuiSelectionStateChanged(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab_left_pane") then return end
    local index = gui_elem.tags.setting
    local entry = OCFG_KEYS[index]

    if (entry.type == "string-list") then
        settings.global[entry.mod_key] = { value = gui_elem.items[gui_elem.selected_index] }
    end
end