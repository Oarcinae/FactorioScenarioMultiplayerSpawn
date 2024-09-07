-- Contains the GUI for the regrowth controls tab.

---Used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateRegrowthControlsTab(tab_container, player)

    --- Create a table with 3 columns. Surface Name, Spawning Enabled, Regrowth Enabled
    local surface_table = tab_container.add {
        type = "table",
        name = "surface_table",
        column_count = 3,
        -- draw_horizontal_lines = true,
        -- draw_vertical_lines = true,
        -- draw_vertical_line_after_headers = true,
        style = "bordered_table",
    }

    --- Add the header row
    AddLabel(surface_table, nil, "Surface", "caption_label")
    AddLabel(surface_table, nil, "Spawning Enabled", "caption_label")
    AddLabel(surface_table, nil, "Regrowth Enabled", "caption_label")

    --- Add the rows
    for name, enabled in pairs(global.ocore.surfaces --[[@as table<string, boolean>]]) do
        AddLabel(surface_table, nil, name, my_label_style)

        AddSurfaceCheckboxSetting(surface_table, name, "spawn_enabled", enabled)

        -- AddSurfaceCheckboxSetting(surface_table, name, "regrowth_enabled", TableContains(global.rg.active_surfaces, name))
        
        -- AddCheckbox(surface_table, nil, surface_name.."_spawn_enabled", surface.spawn_enabled)
        -- AddCheckbox(surface_table, nil, surface_name.."_regrowth_enabled", surface.regrowth_enabled)
    end

    -- AddLabel(tab_container, nil, "test regrowth message my_label_style", my_label_style)
    -- AddLabel(tab_container, nil, "test regrowth message my_label_header_style", my_label_header_style)
    -- AddLabel(tab_container, nil, "test regrowth message my_label_header_grey_style", my_label_header_grey_style)
    -- AddLabel(tab_container, nil, "test regrowth message my_note_style", my_note_style)
    -- AddLabel(tab_container, nil, "test regrowth message my_warning_style", my_warning_style)
    -- AddLabel(tab_container, nil, "test regrowth message my_longer_label_style", my_longer_label_style)
end



---Creates a checkbox setting for surface related settings.
---@param parent LuaGuiElement
---@param surface_name string
---@param setting_name string
---@param state boolean
---@return nil
function AddSurfaceCheckboxSetting(parent, surface_name, setting_name, state)
    parent.add{
        type = "checkbox",
        -- caption = { "mod-setting-name."..entry.mod_key },
        state = state,
        -- enabled = enabled,
        -- tooltip = { "mod-setting-description."..entry.mod_key },
        tags = { action = "oarc_surfaces_tab", setting = setting_name, surface = surface_name },
    }
end

