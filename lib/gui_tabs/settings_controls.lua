-- Contains the GUI for the controlling various settings of the mod.

---Creates the content in the tab used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
function CreateSettingsControlsTab(tab_container, player)

    if (player.admin) then
        local label = AddLabel(tab_container, nil, { "oarc-settings-tab-admin-warning" }, my_warning_style)
        label.style.padding = 5
    else
        local label = AddLabel(tab_container, nil, { "oarc-settings-tab-player-warning" }, my_warning_style)
        label.style.padding = 5
    end

    local horizontal_flow = tab_container.add { type = "flow", direction = "horizontal", }
    
    local scroll_pane_left = horizontal_flow.add {
        type = "scroll-pane",
        direction = "vertical",
        vertical_scroll_policy = "always",
    }
    scroll_pane_left.style.maximal_height = 500
    scroll_pane_left.style.padding = 5
    scroll_pane_left.style.right_margin = 2
    CreateModSettingsSection(scroll_pane_left, player)

    local scroll_pane_right = horizontal_flow.add {
        type = "scroll-pane",
        direction = "vertical",
        vertical_scroll_policy = "always",
    }
    scroll_pane_right.style.maximal_height = 500
    scroll_pane_right.style.padding = 5
    scroll_pane_right.style.left_margin = 2
    CreateSurfaceSettingsSection(scroll_pane_right, player)
end

---Create the content for the mod settings section
---@param container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateModSettingsSection(container, player)
    AddLabel(container, nil, { "oarc-settings-tab-title" }, my_label_header2_style)

    for index,entry in pairs(OCFG_KEYS) do
        if (entry.type == "header") then
            AddSpacerLine(container)
            AddLabel(container, nil, index, "caption_label")
        elseif (entry.type == "boolean") then
            AddCheckboxSetting(container, index, entry, player.admin)
        elseif (entry.type == "string") then
            AddTextfieldSetting(container, index, entry, player.admin)
        elseif (entry.type == "integer") then
            AddIntegerSetting(container, index, entry, player.admin)
        end
    end
end

---Create the content for the surface settings section
---@param container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateSurfaceSettingsSection(container, player)
    AddLabel(container, nil, { "oarc-settings-tab-title-surface" }, my_label_header2_style)

    --- Create a table with 3 columns. Surface Name, Spawning Enabled, Regrowth Enabled
    local surface_table = container.add {
        type = "table",
        name = "surface_table",
        column_count = 2,
        style = "bordered_table",
    }

    --- Add the header row
    AddLabel(surface_table, nil, "Surface", "caption_label") ---TODO: localize
    AddLabel(surface_table, nil, "Spawning Enabled", "caption_label")

    --- Add the rows
    for name, allowed in pairs(global.ocore.surfaces --[[@as table<string, boolean>]]) do
        AddLabel(surface_table, nil, name, my_label_style)
        AddSurfaceCheckboxSetting(surface_table, name, "spawn_enabled", allowed, player.admin)
    end
end

---Handles the click event for the tab used by AddOarcGuiTab
---@param event EventData.on_gui_click
---@return nil
function SettingsControlsTabGuiClick(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab") then return end
    local index = gui_elem.tags.setting

    local entry = OCFG_KEYS[index]
    if (entry.type == "boolean") then
        settings.global[entry.mod_key] = { value = gui_elem.state }
    end
end

---Handles the text entry event for the tab used by AddOarcGuiTab
---@param event EventData.on_gui_text_changed
---@return nil
function SettingsControlsTabGuiTextChanged(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab") then return end
    local index = gui_elem.tags.setting

    local entry = OCFG_KEYS[index]
    if (entry.type == "string") or (entry.type == "integer") then
        settings.global[entry.mod_key] = { value = gui_elem.text }
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
    local dragger = horizontal_flow.add {
        type = "empty-widget",
    }
    dragger.style.horizontally_stretchable = true
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
    local dragger = horizontal_flow.add {
        type = "empty-widget",
    }
    dragger.style.horizontally_stretchable = true
    local textfield = horizontal_flow.add {
        type = "textfield",
        numeric = true,
        caption = { "mod-setting-name."..entry.mod_key },
        text = GetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys),
        enabled = enabled,
        tooltip = { "mod-setting-description."..entry.mod_key },
        tags = { action = "oarc_settings_tab", setting = index },
    }
    textfield.style.width = 100
end

---Creates a checkbox setting for surface related settings.
---@param parent LuaGuiElement
---@param surface_name string
---@param setting_name string
---@param state boolean
---@param admin boolean
---@return nil
function AddSurfaceCheckboxSetting(parent, surface_name, setting_name, state, admin)
    parent.add{
        name = surface_name.."_"..setting_name,
        type = "checkbox",
        state = state,
        tags = { action = "oarc_settings_tab_surfaces", setting = setting_name, surface = surface_name },
        enabled = admin
    }
end

---Handles the click event for surface related settings
---@param event EventData.on_gui_click
---@return nil
function SettingsSurfaceControlsTabGuiClick(event)
    if not (event.element.valid) then return end

    local gui_elem = event.element
    if (gui_elem.tags.action ~= "oarc_settings_tab_surfaces") then return end
    local setting_name = gui_elem.tags.setting
    local surface_name = gui_elem.tags.surface

    if (setting_name == "spawn_enabled") then
        global.ocore.surfaces[surface_name] = gui_elem.state

        if (#GetAllowedSurfaces() == 0) then
            log("Warning - GetAllowedSurfaces() - No surfaces found! Forcing default surface!")
            global.ocore.surfaces[global.ocfg.gameplay.default_surface] = true
            event.element.parent[global.ocfg.gameplay.default_surface.."_spawn_enabled"].state = true
        end
    end
end