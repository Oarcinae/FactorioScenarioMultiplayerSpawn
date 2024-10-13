--This file will let admins configure the "surfaces_config" table that is NOT available in the mod settings.

---Creates the tab content, used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateSurfaceConfigTab(tab_container, player)

    local note = AddLabel(tab_container, nil, "This lets you configure the surface settings, it is only available to admins. These settings are NOT available in the mod settings page. If you want to automatically set these on the start of a new game using a custom file, please check out the included template scenario in the mod folder. I really question my sanity for bothering to make this GUI interface. Send help.", my_note_style) -- TODO: Localize
    note.style.maximal_width = 600
    local warn = AddLabel(tab_container, nil, "WARNING: These settings are NOT sanitized, you might crash the game if you pick bad values!", my_warning_style) -- TODO: Localize
    warn.style.maximal_width = 600

    -- Drop down to select surface that you want to configure
    local selected_surface_name = CreateSurfaceDropdown(tab_container)
    -- AddSpacer(tab_container)

    local content = tab_container.add {
        type = "flow",
        direction = "vertical",
        name = "surface_config_content_flow"
    }
    content.style.maximal_height = 600
    CreateSurfaceConfigContent(content, selected_surface_name)
end

---Create surface config content section below the surface selection dropdown
---@param container LuaGuiElement
---@param surface_name string
---@return nil
function CreateSurfaceConfigContent(container, surface_name)

    -- Vertical scroll pane with dividers for each section for the surface config
    local scroll_pane = container.add {
        type = "scroll-pane",
        direction = "vertical",
        vertical_scroll_policy = "always",
    }
    scroll_pane.style.top_margin = 10

    -- TODO: Localize EVERTYHING?

    AddLabel(scroll_pane, nil, "Starting And Respawn Items", my_label_header2_style)
    local starting_items_flow = scroll_pane.add { type = "flow", direction = "horizontal" }
    CreateItemsSection(starting_items_flow, surface_name, "Starting Items", "player_start_items")
    CreateItemsSection(starting_items_flow, surface_name, "Respawn Items", "player_respawn_items")
    AddSpacerLine(scroll_pane)

    AddLabel(scroll_pane, nil, "Crashed Ship Items", my_label_header2_style)
    CreateCrashSiteEnable(scroll_pane, surface_name)
    local crash_site_flow = scroll_pane.add { type = "flow", direction = "horizontal" }
    CreateItemsSection(crash_site_flow, surface_name, "Crashed Ship (Max 5)", "crashed_ship_resources", MAX_CRASHED_SHIP_RESOURCES_ITEMS)
    CreateItemsSection(crash_site_flow, surface_name, "Ship Wreckage (Max 1)", "crashed_ship_wreakage", MAX_CRASHED_SHIP_WRECKAGE_ITEMS)
    AddSpacerLine(scroll_pane)

    AddLabel(scroll_pane, nil, "Spawn Area Resources", my_label_header2_style)
    local spawn_config_flow = scroll_pane.add { type = "flow", direction = "horizontal" }
    CreateSolidResourcesConfig(spawn_config_flow, surface_name)
    CreateFluidResourcesConfig(spawn_config_flow, surface_name)
    AddSpacerLine(scroll_pane)

    AddLabel(scroll_pane, nil, "Spawn Area Misc", my_label_header2_style)
    local misc_config_flow = scroll_pane.add { type = "flow", direction = "horizontal" }
    CreateMiscConfig(misc_config_flow, surface_name)
    CreateSafeAreaConfig(misc_config_flow, surface_name)
end


---Create a checkbox to enable/disable the crashed ship
---@param container LuaGuiElement
---@param surface_name string
---@return nil
function CreateCrashSiteEnable(container, surface_name)
    local crashed_ship_enabled = global.ocfg.surfaces_config[surface_name].starting_items.crashed_ship

    local crashed_ship_flow = container.add {
        type = "flow",
        direction = "horizontal"
    }
    crashed_ship_flow.style.vertical_align = "center"

    AddLabel(crashed_ship_flow, nil, "Enable Crashed Ship: ", "caption_label") -- TODO: Localize
    local crashed_ship_enabled_checkbox = crashed_ship_flow.add {
        type = "checkbox",
        state = crashed_ship_enabled,
        tags = {
            action = "oarc_surface_config_tab",
            setting = "crashed_ship_enabled",
            surface_name = surface_name
        },
        tooltip = "Enables the factorio style ship crash with items. If this is disabled, the crashed ship items and wreckage won't do anything." -- TODO: Localize
    }
end

---Create surface dropdown selection
---@param container LuaGuiElement
---@return string --The default selected surface name
function CreateSurfaceDropdown(container)
    local surface_names = {}
    for surface_name,_ in pairs(global.ocfg.surfaces_config) do
        table.insert(surface_names, surface_name)
    end
    table.sort(surface_names)

    local selected_surface_name = surface_names[1]

    local horizontal_flow = container.add {
        type = "flow",
        direction = "horizontal"
    }
    horizontal_flow.style.vertical_align = "center"
    AddLabel(horizontal_flow, nil, "Select Surface: ", "caption_label")

    local surface_dropdown = horizontal_flow.add {
        type = "drop-down",
        name = "surface_dropdown",
        items = surface_names,
        selected_index = 1,
        tags = {
            action = "oarc_surface_config_tab",
            setting = "surface_dropdown"
        },
        tooltip = "Select the surface you want to configure." -- TODO: Localize
    }

    local dragger = horizontal_flow.add{ type="empty-widget", style="draggable_space_header" }
    dragger.style.horizontally_stretchable = true

    -- A button to revert config to default (from OCFG hardcoded.)
    local revert_button = horizontal_flow.add {
        type = "button",
        caption = "Revert", -- TODO: Localize
        tooltip = "Revert to default.", -- TODO: Localize
        style = "red_button",
        tags = {
            action = "oarc_surface_config_tab",
            setting = "revert_to_default"
        }
    }

    -- Add button to copy nauvis config to current selected surface (if not nauvis)
    local copy_button = horizontal_flow.add {
        type = "button",
        caption = "Copy Nauvis", -- TODO: Localize
        tooltip = "Copy Nauvis settings to this surface.", -- TODO: Localize
        style = "red_button",
        tags = {
            action = "oarc_surface_config_tab",
            setting = "copy_nauvis"
        }
    }

    return selected_surface_name
end


---Create an items selection section
---@param container LuaGuiElement
---@param surface_name string
---@param header string
---@param setting_name string
---@param max_count integer?
---@return nil
function CreateItemsSection(container, surface_name, header, setting_name, max_count)

    local items = global.ocfg.surfaces_config[surface_name].starting_items[setting_name]

    if (items == nil) then
        error("No items found for setting: " .. setting_name .. " for surface: " .. surface_name)
    end

    if (max_count and (table_size(items) > max_count)) then
        -- This would only happen with a bad config.
        error("Too many items in starting items list!?")
    end

    local vertical_flow = container.add {
        type = "frame",
        direction = "vertical",
        -- style = "inside_shallow_frame"
    }
    vertical_flow.style.padding = 5
    vertical_flow.style.horizontally_stretchable = false
    vertical_flow.style.vertically_stretchable = true
    
    AddLabel(vertical_flow, nil, header, my_label_header2_style)

    local table = vertical_flow.add {
        type = "table",
        column_count = 3,
        -- style = "bordered_table",
        tags = {
            surface_name = surface_name,
            setting = setting_name,
            max_count = max_count or 0
        }
    }

    --Add headers
    AddLabel(table, nil, "Item", my_label_style)
    AddLabel(table, nil, "Count", my_label_style)
    AddLabel(table, nil, "", my_label_style)

    for item_name, item_count in pairs(items) do
        SurfaceConfigItemListDisplayRow(table, item_name, item_count)
    end

    -- Add a button to add another row
    if (max_count == nil) or (max_count == 0) or (table_size(items) < max_count) then
        SurfaceConfigItemListAddRowButton(table)
    end
end




---Adds a row to a table with an item and count
---@param table LuaGuiElement
---@param item_name string?
---@param item_count integer?
---@return nil
function SurfaceConfigItemListDisplayRow(table, item_name, item_count)
    -- Create choose elem button
    local button = table.add {
        type = "choose-elem-button",
        elem_type = "item",
        item = item_name,
        tags = {
            action = "oarc_surface_config_tab",
            elem_button = true,
            item_name = item_name or ""
        },
    }
    button.style.width = 28
    button.style.height = 28

    -- Create number textfield
    local textfield = table.add {
        type = "textfield",
        text = tostring(item_count or 0),
        numeric = true,
        allow_decimal = false,
        tooltip = {"oarc-settings-tab-text-field-enter-tooltip" },
        tags = {
            action = "oarc_surface_config_tab",
            item_number_textfield = true,
            item_name = item_name or ""
        }
    }
    if (item_name == "") then
        textfield.style = "invalid_value_textfield"
    end
    textfield.style.width = 40

    -- Create a button to remove the row
    local remove_button = table.add {
        type = "sprite-button",
        sprite = "utility/deconstruction_mark",
        tooltip = "Remove Item", -- TODO: Localize
        tags = {
            action = "oarc_surface_config_tab",
            remove_row_button = true,
            item_name = item_name or ""
        }
    }
    remove_button.style.width = 28
    remove_button.style.height = 28
end


---Add the add row button to the table
---@param table LuaGuiElement
---@return nil
function SurfaceConfigItemListAddRowButton(table)
    -- Add a button to add another row
    local add_row_button = table.add {
        type = "choose-elem-button",
        elem_type = "entity",
        -- type = "sprite-button",
        -- sprite = "utility/check_mark_green",
        tooltip = "Add Item", -- TODO: Localize
        tags = {
            action = "oarc_surface_config_tab",
            add_row_button = true
        }
    }
    add_row_button.style.width = 28
    add_row_button.style.height = 28
end




---Create the safe area config section
---@param container LuaGuiElement
---@param surface_name string
---@return nil
function CreateSafeAreaConfig(container, surface_name)

    local safe_area_flow = container.add {
        type = "frame",
        direction = "vertical",
        -- style = "inside_shallow_frame"
    }
    safe_area_flow.style.padding = 5
    safe_area_flow.style.horizontally_stretchable = false
    safe_area_flow.style.vertically_stretchable = true

    local header = AddLabel(safe_area_flow, nil, "Safe Area Config", my_label_header2_style) -- TODO: Localize
    header.tooltip = "This controls how safe the area around the spawns is." -- TODO: Localize

     -- TODO: Localize
    CreateSpawnConfigIntegerField(safe_area_flow, surface_name, "Safe Area Radius", "safe_area", "safe_radius", "This is the radius in chunks around the spawn in which no enemies will spawn.")
    CreateSpawnConfigIntegerField(safe_area_flow, surface_name, "Warn Area Radius", "safe_area", "warn_radius", "This is the radius in chunks around the spawn in which enemies will be significantly reduced.")
    CreateSpawnConfigIntegerField(safe_area_flow, surface_name, "Warn Area Reduction", "safe_area", "warn_reduction", "This is the reduction factor to reduce the number of enemies in the warn area. 10 means (1/10)th the number of enemies.")
    CreateSpawnConfigIntegerField(safe_area_flow, surface_name, "Danger Area Radius", "safe_area", "danger_radius", "This is the radius in chunks around the spawn in which enemies will be slightly reduced.")
    CreateSpawnConfigIntegerField(safe_area_flow, surface_name, "Danger Area Reduction", "safe_area", "danger_reduction", "This is the reduction factor to reduce the number of enemies in the danger area. 10 means (1/10)th the number of enemies.")
end


---Create an integer textfield with a label
---@param container LuaGuiElement
---@param surface_name string
---@param label string
---@param setting_name string
---@param entry_name string
---@param tooltip string
---@return nil
function CreateSpawnConfigIntegerField(container, surface_name, label, setting_name, entry_name, tooltip)

    local value = global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][entry_name]

    local flow = container.add {
        type = "flow",
        direction = "horizontal"
    }

    AddLabel(flow, nil, label, my_label_style)

    local dragger = flow.add{ type="empty-widget", style="draggable_space_header" }
    dragger.style.horizontally_stretchable = true

    -- Create number textfield
    local textfield = flow.add {
        type = "textfield",
        text = tostring(value),
        tooltip = tooltip,
        numeric = true,
        allow_decimal = false,
        tags = {
            action = "oarc_surface_config_tab",
            surface_name = surface_name,
            setting = setting_name,
            entry = entry_name,
            spawn_config_textfield = true
        }
    }
    textfield.style.width = 50
end


---Create the solid resources config section
---@param container LuaGuiElement
---@param surface_name string
---@return nil
function CreateSolidResourcesConfig(container, surface_name)

    local solid_resources = global.ocfg.surfaces_config[surface_name].spawn_config.solid_resources

    local solid_resources_flow = container.add {
        type = "frame",
        direction = "vertical",
        -- style = "inside_shallow_frame"
    }
    solid_resources_flow.style.padding = 5
    solid_resources_flow.style.horizontally_stretchable = false
    solid_resources_flow.style.vertically_stretchable = true

    local header = AddLabel(solid_resources_flow, nil, "Solid Resources Config", my_label_header2_style) -- TODO: Localize
    header.tooltip = "This controls the resources that will spawn around the spawn area." -- TODO: Localize

    -- Create a table to display the resources
    local table = solid_resources_flow.add {
        type = "table",
        column_count = 4,
        tags = {
            surface_name = surface_name,
            setting = "solid_resources"
        }
    }

    --Add headers
    AddLabel(table, nil, "Type", my_label_style)
    AddLabel(table, nil, "Amount", my_label_style)
    AddLabel(table, nil, "Size", my_label_style)
    AddLabel(table, nil, "", my_label_style)

    for resource_name, resource_data in pairs(solid_resources) do
        SolidResourcesConfigDisplayRow(table, resource_name, resource_data.amount, resource_data.size)
    end

    SurfaceConfigSolidResourcesAddRowButton(table)
end

---Create the fluid resources config section
---@param container LuaGuiElement
---@param surface_name string
---@return nil
function CreateFluidResourcesConfig(container, surface_name)

    local fluid_resources = global.ocfg.surfaces_config[surface_name].spawn_config.fluid_resources

    local fluid_resources_flow = container.add {
        type = "frame",
        direction = "vertical",
        -- style = "inside_shallow_frame"
    }
    fluid_resources_flow.style.padding = 5
    fluid_resources_flow.style.horizontally_stretchable = false
    fluid_resources_flow.style.vertically_stretchable = true

    local header = AddLabel(fluid_resources_flow, nil, "Fluid Resources Config", my_label_header2_style) -- TODO: Localize
    header.tooltip = "This controls the fluid resources that will spawn around the spawn area." -- TODO: Localize

    -- Create a table to display the resources
    local fluid_table = fluid_resources_flow.add {
        type = "table",
        column_count = 4,
        tags = {
            surface_name = surface_name,
            setting = "fluid_resources"
        }
    }

    --Add headers
    AddLabel(fluid_table, nil, "Type", my_label_style)
    AddLabel(fluid_table, nil, "Count", my_label_style)
    AddLabel(fluid_table, nil, "Amount", my_label_style)
    AddLabel(fluid_table, nil, "", my_label_style)

    for resource_name, resource_data in pairs(fluid_resources) do
        FluidResourcesConfigDisplayRow(fluid_table, resource_name, resource_data.num_patches, resource_data.amount)
    end

    SurfaceConfigFluidResourcesAddRowButton(fluid_table)
end

---Create the water strip config section
---@param container LuaGuiElement
---@param surface_name string
---@return nil
function CreateMiscConfig(container, surface_name)

    local misc_flow = container.add {
        type = "frame",
        direction = "vertical",
        -- style = "inside_shallow_frame"
    }
    misc_flow.style.padding = 5
    misc_flow.style.horizontally_stretchable = false

    AddLabel(misc_flow, nil, "Misc Config", my_label_header2_style) -- TODO: Localize

    AddLabel(misc_flow, nil, "Water", my_player_list_style)
    CreateSpawnConfigIntegerField(misc_flow, surface_name, "Water Length", "water", "length", "This is the length in tiles of the water strip around the spawn area.")
    CreateSpawnConfigIntegerField(misc_flow, surface_name, "Water X Offset", "water", "x_offset", "This is the x_offset in tiles, from the north of the spawn area.")
    CreateSpawnConfigIntegerField(misc_flow, surface_name, "Water Y Offset", "water", "y_offset", "This is the y_offset in tiles, from the north of the spawn area.")
    AddSpacerLine(misc_flow)

    AddLabel(misc_flow, nil, "Shared Chest", my_player_list_style)
    CreateSpawnConfigIntegerField(misc_flow, surface_name, "Chest X Offset", "shared_chest_position", "x_offset", "This is the x_offset in tiles, from the east of the spawn area.")
    CreateSpawnConfigIntegerField(misc_flow, surface_name, "Chest Y Offset", "shared_chest_position", "y_offset", "This is the y_offset in tiles, from the east of the spawn area.")
    AddSpacerLine(misc_flow)

    AddLabel(misc_flow, nil, "Shared Power Pole", my_player_list_style)
    CreateSpawnConfigIntegerField(misc_flow, surface_name, "Power X Offset", "shared_power_pole_position", "x_offset", "This is the x_offset in tiles, from the east of the spawn area.")
    CreateSpawnConfigIntegerField(misc_flow, surface_name, "Power Y Offset", "shared_power_pole_position", "y_offset", "This is the y_offset in tiles, from the east of the spawn area.")
end

---Adds a row to a table with a resource, amount, and size
---@param table LuaGuiElement
---@param resource_name string?
---@param amount integer
---@param size integer
---@return nil
function SolidResourcesConfigDisplayRow(table, resource_name, amount, size)
    -- Create choose elem button
    local button = table.add {
        type = "choose-elem-button",
        elem_type = "entity",
        elem_filters = {{filter = "type", type = "resource"}},
        tags = {
            action = "oarc_surface_config_tab",
            resource_elem_button = true,
            resource_name = resource_name or ""
        },
    }
    button.elem_value = resource_name
    button.style.width = 28
    button.style.height = 28

    -- Create number textfield
    local amount_textfield = table.add {
        type = "textfield",
        text = tostring(amount),
        numeric = true,
        allow_decimal = false,
        tags = {
            action = "oarc_surface_config_tab",
            resource_amount_textfield = true,
            resource_name = resource_name or ""
        }
    }
    amount_textfield.style.width = 50

    -- Create number textfield
    local size_textfield = table.add {
        type = "textfield",
        text = tostring(size),
        numeric = true,
        allow_decimal = false,
        tags = {
            action = "oarc_surface_config_tab",
            resource_size_textfield = true,
            resource_name = resource_name or ""
        }
    }
    size_textfield.style.width = 50

    -- Create a button to remove the row
    local remove_button = table.add {
        type = "sprite-button",
        sprite = "utility/deconstruction_mark",
        tooltip = "Remove Resource", -- TODO: Localize
        tags = {
            action = "oarc_surface_config_tab",
            resource_remove_row_button = true,
            resource_name = resource_name or ""
        }
    }
    remove_button.style.width = 28
    remove_button.style.height = 28
end

---Add the add row button to the table for solid resources
---@param table LuaGuiElement
---@return nil
function SurfaceConfigSolidResourcesAddRowButton(table)
    -- Add a button to add another row
    local add_row_button = table.add {
        type = "choose-elem-button",
        elem_type = "entity",
        -- type = "sprite-button",
        -- sprite = "utility/check_mark_green",
        tooltip = "Add Item", -- TODO: Localize
        tags = {
            action = "oarc_surface_config_tab",
            resource_add_row_button = true
        }
    }
    add_row_button.style.width = 28
    add_row_button.style.height = 28
end

---Adds a row to a table with a fluid resource, amount, count, spacing, and vertical offset
---@param table LuaGuiElement
---@param resource_name string?
---@param count integer
---@param amount integer
---@return nil
function FluidResourcesConfigDisplayRow(table, resource_name, count, amount)
    
    -- Create choose elem button
    local button = table.add {
        type = "choose-elem-button",
        elem_type = "entity",
        elem_filters = {{filter = "type", type = "resource"}},
        tags = {
            action = "oarc_surface_config_tab",
            fluid_resource_elem_button = true,
            resource_name = resource_name or ""
        },
    }
    button.elem_value = resource_name
    button.style.width = 28
    button.style.height = 28


    -- Number of fluid patches
    local count_textfield = table.add {
        type = "textfield",
        text = tostring(count),
        numeric = true,
        allow_decimal = false,
        tags = {
            action = "oarc_surface_config_tab",
            fluid_resource_count_textfield = true,
            resource_name = resource_name or ""
        }
    }
    count_textfield.style.width = 40

    -- Amount of fluid per patch
    local amount_textfield = table.add {
        type = "textfield",
        text = tostring(amount),
        numeric = true,
        allow_decimal = false,
        tags = {
            action = "oarc_surface_config_tab",
            fluid_resource_amount_textfield = true,
            resource_name = resource_name or ""
        }
    }
    amount_textfield.style.width = 60

    -- Create a button to remove the row
    local remove_button = table.add {
        type = "sprite-button",
        sprite = "utility/deconstruction_mark",
        tooltip = "Remove Resource",
        tags = {
            action = "oarc_surface_config_tab",
            resource_remove_row_button = true,
            resource_name = resource_name or ""
        }
    }
    remove_button.style.width = 28
    remove_button.style.height = 28
end

---Add the add row button to the table for fluid resources
---@param table LuaGuiElement
---@return nil
function SurfaceConfigFluidResourcesAddRowButton(table)
    -- Add a button to add another row
    local add_row_button = table.add {
        type = "choose-elem-button",
        elem_type = "entity",
        -- type = "sprite-button",
        -- sprite = "utility/check_mark_green",
        tooltip = "Add Item", -- TODO: Localize
        tags = {
            action = "oarc_surface_config_tab",
            fluid_resource_add_row_button = true
        }
    }
    add_row_button.style.width = 28
    add_row_button.style.height = 28
end

--[[
  _____   _____ _  _ _____   _  _   _   _  _ ___  _    ___ ___  ___ 
 | __\ \ / / __| \| |_   _| | || | /_\ | \| |   \| |  | __| _ \/ __|
 | _| \ V /| _|| .` | | |   | __ |/ _ \| .` | |) | |__| _||   /\__ \
 |___| \_/ |___|_|\_| |_|   |_||_/_/ \_\_|\_|___/|____|___|_|_\|___/

]]

---Handle the surface dropdown selection
---@param event EventData.on_gui_selection_state_changed
---@return nil
function SurfaceConfigTabGuiSelect(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_surface_config_tab") then
        return
    end

    if (tags.setting == "surface_dropdown") then
        local selected_surface_name = event.element.items[event.element.selected_index] --[[@as string]]

        local content_flow = event.element.parent.parent["surface_config_content_flow"]
        if (content_flow == nil) then
            error("Content flow is nil? This shouldn't happen on surface dropdown select! " .. selected_surface_name)
        end

        -- Recreate the content section
        content_flow.clear()
        CreateSurfaceConfigContent(content_flow, selected_surface_name)
    end
end


---Handle on_gui_text_changed events
---@param event EventData.on_gui_text_changed
---@return nil
function SurfaceConfigTabGuiTextChanged(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_surface_config_tab") then
        return
    end

    if (tags.item_number_textfield or tags.fluid_resource_count_textfield) then
        event.element.style = "invalid_value_textfield"
        event.element.style.width = 40
    elseif (tags.resource_amount_textfield or tags.resource_size_textfield or tags.spawn_config_textfield) then
        event.element.style = "invalid_value_textfield"
        event.element.style.width = 50
    elseif tags.fluid_resource_amount_textfield then
        event.element.style = "invalid_value_textfield"
        event.element.style.width = 60
    end
end


---Handle on_gui_confirmed events
---@param event EventData.on_gui_confirmed
---@return nil
function SurfaceConfigTabGuiConfirmed(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_surface_config_tab") then
        return
    end

    if (tags.item_number_textfield) then

        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]
        local item_name = tags.item_name --[[@as string]]

        -- Check if an item is selected first.
        if (tags.item_name == "") then
            player.print("Please select an item first!")
            event.element.text = "0"
            return
        end

        -- Update the count
        local count = tonumber(event.element.text) or 0
        global.ocfg.surfaces_config[surface_name].starting_items[setting_name][item_name] = count

        event.element.style = "textbox"
        event.element.style.width = 40

    elseif (tags.resource_amount_textfield or tags.resource_size_textfield) then

        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]
        local resource_name = tags.resource_name --[[@as string]]

        -- Check if an item is selected first.
        if (tags.resource_name == "") then
            player.print("Please select a resource first!")
            event.element.text = "0"
            return
        end

        -- Update the count
        local count = tonumber(event.element.text) or 0

        if (tags.resource_amount_textfield) then
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][resource_name].amount = count
        elseif (tags.resource_size_textfield) then
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][resource_name].size = count
        end

        event.element.style = "textbox"
        event.element.style.width = 50

    elseif (tags.fluid_resource_count_textfield or tags.fluid_resource_amount_textfield) then

        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]
        local resource_name = tags.resource_name --[[@as string]]

        -- Check if an item is selected first.
        if (tags.resource_name == "") then
            player.print("Please select a resource first!")
            event.element.text = "0"
            return
        end

        -- Update the count
        local count = tonumber(event.element.text) or 0

        event.element.style = "textbox"
        if (tags.fluid_resource_count_textfield) then
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][resource_name].num_patches = count
            event.element.style.width = 40
        elseif (tags.fluid_resource_amount_textfield) then
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][resource_name].amount = count
            event.element.style.width = 60
        end


    elseif (tags.spawn_config_textfield) then
        local surface_name = tags.surface_name --[[@as string]]
        local setting_name = tags.setting --[[@as string]]
        local entry_name = tags.entry --[[@as string]]

        local value = tonumber(event.element.text) or 0
        global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][entry_name] = value

        event.element.style = "textbox"
        event.element.style.width = 50

    end
end

---Handle elem changed events
---@param event EventData.on_gui_elem_changed
---@return nil
function SurfaceConfigTabGuiElemChanged(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_surface_config_tab") then
        return
    end

    if (tags.elem_button) then
        local new_item_name = event.element.elem_value --[[@as string]]

        if (new_item_name == nil) then
            return
        end

        local old_item_name = tags.item_name --[[@as string]]

        -- if the new item name is the same as the old item name, do nothing.
        if (new_item_name == tags.item_name) then
            return
        end

        -- otherwise, check if the new item name is already in the list.
        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]

        if (global.ocfg.surfaces_config[surface_name].starting_items[setting_name][new_item_name]) then
            player.print("Item already exists in list! " .. new_item_name)
            event.element.elem_value = nil
            return
        end

        -- Update the item name in the list, keep the old count.
        if (old_item_name ~= "") then
            global.ocfg.surfaces_config[surface_name].starting_items[setting_name][new_item_name] = global.ocfg.surfaces_config[surface_name].starting_items[setting_name][old_item_name]
            global.ocfg.surfaces_config[surface_name].starting_items[setting_name][old_item_name] = nil
        else
            global.ocfg.surfaces_config[surface_name].starting_items[setting_name][new_item_name] = 0
        end

        -- Update all tags with the new item name.
        for _, child in pairs(event.element.parent.children) do
            if (child.tags.item_name == old_item_name) then
                local tags_copy = child.tags
                tags_copy.item_name = new_item_name
                child.tags = tags_copy
            end
        end
    
    elseif (tags.resource_elem_button) then
        local new_resource_name = event.element.elem_value --[[@as string]]

        if (new_resource_name == nil) then
            return
        end

        if (game.entity_prototypes[new_resource_name].resource_category ~= "basic-solid") then
            player.print("Resource must be a solid resource! " .. new_resource_name)
            event.element.elem_value = nil
            return
        end

        local old_resource_name = tags.resource_name --[[@as string]]

        -- if the new resource name is the same as the old resource name, do nothing.
        if (new_resource_name == tags.resource_name) then
            return
        end

        -- otherwise, check if the new resource name is already in the list.
        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]

        if (global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][new_resource_name]) then
            player.print("Resource already exists in list! " .. new_resource_name)
            event.element.elem_value = nil
            return
        end

        -- Update the resource name in the list, keep the old amount and size.
        if (old_resource_name ~= "") then
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][new_resource_name] = global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][old_resource_name]
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][old_resource_name] = nil
        else
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][new_resource_name] = {amount=0, size=0, x_offset=0, y_offset=0}
        end

        -- Update all tags with the new resource name.
        for _, child in pairs(event.element.parent.children) do
            if (child.tags.resource_name == old_resource_name) then
                local tags_copy = child.tags
                tags_copy.resource_name = new_resource_name
                child.tags = tags_copy
            end
        end

    elseif (tags.fluid_resource_elem_button) then
        local new_resource_name = event.element.elem_value --[[@as string]]

        if (new_resource_name == nil) then
            return
        end

        if (game.entity_prototypes[new_resource_name].resource_category ~= "basic-fluid") then
            player.print("Resource must be a fluid resource! " .. new_resource_name)
            event.element.elem_value = nil
            return
        end

        local old_resource_name = tags.resource_name --[[@as string]]

        -- if the new resource name is the same as the old resource name, do nothing.
        if (new_resource_name == tags.resource_name) then
            return
        end

        -- otherwise, check if the new resource name is already in the list.
        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]

        if (global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][new_resource_name]) then
            player.print("Resource already exists in list! " .. new_resource_name)
            event.element.elem_value = nil
            return
        end

        -- Update the resource name in the list, keep the old amount and size.
        if (old_resource_name ~= "") then
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][new_resource_name] = global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][old_resource_name]
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][old_resource_name] = nil
        else
            global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][new_resource_name] = {num_patches=0, amount=0, x_offset=0, y_offset=0}
        end

        -- Update all tags with the new resource name.
        for _, child in pairs(event.element.parent.children) do
            if (child.tags.resource_name == old_resource_name) then
                local tags_copy = child.tags
                tags_copy.resource_name = new_resource_name
                child.tags = tags_copy
            end
        end
    end
end

---Handle the surface config tab button clicks
---@param event EventData.on_gui_click
---@return nil
function SurfaceConfigTabGuiClick(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "oarc_surface_config_tab") then
        return
    end

    if (tags.remove_row_button) then
        
        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]
        local item_name = tags.item_name --[[@as string]]
        local max_count = parent.tags.max_count --[[@as integer]]

        -- Nil the entry
        global.ocfg.surfaces_config[surface_name].starting_items[setting_name][item_name] = nil

        -- Delete the row by removing the child elements from the table.
        local parent = event.element.parent --[[@as LuaGuiElement]] -- Ass(u)me that the parent is a table.
        for _, child in pairs(parent.children) do
            if (child.tags and child.tags.item_name == tags.item_name) then
                child.destroy()
            end
        end

        -- Only add the add row if we haven't reached the max count AND the children count is 1 more than % 3.
        local table_modulo_3 = #parent.children % 3
        if table_modulo_3 == 0 then
            SurfaceConfigItemListAddRowButton(parent)
        end


    elseif (tags.add_row_button) then

        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]
        local max_count = parent.tags.max_count --[[@as integer]]
        if (parent == nil) then
            error("Parent is nil? This shouldn't happen on add row button click! " .. setting_name)
        end

        -- Delete the button and add a new row and then add the button back.
        event.element.destroy()
        SurfaceConfigItemListDisplayRow(parent)

        -- Only add the add row if we haven't reached the max count.
        local item_count = (#parent.children - 3) / 3
        if (max_count == nil) or (max_count == 0) or (item_count < max_count) then
            SurfaceConfigItemListAddRowButton(parent)
        end

    elseif (tags.setting == "crashed_ship_enabled") then
        local surface_name = tags.surface_name --[[@as string]]
        global.ocfg.surfaces_config[surface_name].starting_items.crashed_ship = event.element.state

    elseif (tags.setting == "revert_to_default") then

        local surface_name = event.element.parent["surface_dropdown"].items[event.element.parent["surface_dropdown"].selected_index] --[[@as string]]

        player.print("Revert to default: " .. surface_name)
        global.ocfg.surfaces_config[surface_name].starting_items = table.deepcopy(NAUVIS_STARTER_ITEMS)
        global.ocfg.surfaces_config[surface_name].spawn_config = table.deepcopy(NAUVIS_SPAWN_CONFIG)

        -- Recreate the content section
        local content_flow = event.element.parent.parent["surface_config_content_flow"]
        if (content_flow == nil) then
            error("Content flow is nil? This shouldn't happen on revert to default! " .. surface_name)
        end
        content_flow.clear()
        CreateSurfaceConfigContent(content_flow, surface_name)

    elseif (tags.setting == "copy_nauvis") then

        local surface_name = event.element.parent["surface_dropdown"].items[event.element.parent["surface_dropdown"].selected_index] --[[@as string]]

        if (surface_name == "nauvis") then
            player.print("Already on nauvis, select a different surface to copy nauvis settings to!")
            return
        end

        player.print("Copy nauvis to " .. surface_name)
        global.ocfg.surfaces_config[surface_name].starting_items = global.ocfg.surfaces_config["nauvis"].starting_items
        global.ocfg.surfaces_config[surface_name].spawn_config = global.ocfg.surfaces_config["nauvis"].spawn_config

        -- Recreate the content section
        local content_flow = event.element.parent.parent["surface_config_content_flow"]
        if (content_flow == nil) then
            error("Content flow is nil? This shouldn't happen on copy nauvis! " .. surface_name)
        end
        content_flow.clear()
        CreateSurfaceConfigContent(content_flow, surface_name)

    elseif (tags.resource_remove_row_button) then
        local resource_name = tags.resource_name --[[@as string]]
        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]

        -- Nil the entry
        global.ocfg.surfaces_config[surface_name].spawn_config[setting_name][resource_name] = nil

        -- Delete the row by removing the child elements from the table.
        for _, child in pairs(parent.children) do
            if (child.tags.resource_name == resource_name) then
                child.destroy()
            end
        end

    elseif (tags.resource_add_row_button) then

        local parent = event.element.parent
        local setting_name = parent.tags.setting --[[@as string]]

        if (parent == nil) then
            error("Parent is nil? This shouldn't happen on add row button click! " .. setting_name)
        end

        -- Delete the button and add a new row and then add the button back.
        event.element.destroy()
        SolidResourcesConfigDisplayRow(parent, nil, 0, 0)

        -- Add the add row button back.
        SurfaceConfigSolidResourcesAddRowButton(parent)

    elseif (tags.fluid_resource_add_row_button) then

        local parent = event.element.parent
        local setting_name = parent.tags.setting --[[@as string]]

        if (parent == nil) then
            error("Parent is nil? This shouldn't happen on add row button click! " .. setting_name)
        end

        -- Delete the button and add a new row and then add the button back.
        event.element.destroy()
        FluidResourcesConfigDisplayRow(parent, nil, 0, 0)

        -- Add the add row button back.
        SurfaceConfigFluidResourcesAddRowButton(parent)
    end
end