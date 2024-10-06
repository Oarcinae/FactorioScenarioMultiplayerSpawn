--This file will let admins configure the "surfaces_config" table that is NOT available in the mod settings.

---Creates the tab content, used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateSurfaceConfigTab(tab_container, player)

    local note = AddLabel(tab_container, nil, "This lets you configure the surface settings, it is only available to admins. These settings are NOT available in the mod settings page. If you want to automatically set these on the start of a new game using a custom file, please check out the included template scenario in the mod folder. I really question my sanity for bothering to make this GUI interface. Send help.", my_note_style) -- TODO: Localize
    note.style.maximal_width = 700

    -- Drop down to select surface that you want to configure
    local selected_surface_name = CreateSurfaceDropdown(tab_container)
    -- AddSpacer(tab_container)

    local content = tab_container.add {
        type = "flow",
        direction = "vertical",
        name = "surface_config_content_flow"
    }
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

    -- Add a checkbox to enable/disable the crashed ship.
    CreateCrashSiteEnable(scroll_pane, surface_name)

    local starting_items_flow = scroll_pane.add {
        type = "flow",
        direction = "horizontal"
    }

     -- TODO: Localize
    CreateItemsSection(starting_items_flow, surface_name, "Starting Items", "player_start_items")
    CreateItemsSection(starting_items_flow, surface_name, "Respawn Items", "player_respawn_items")
    CreateItemsSection(starting_items_flow, surface_name, "Crashed Ship (Max 5)", "crashed_ship_resources", MAX_CRASHED_SHIP_RESOURCES_ITEMS)
    CreateItemsSection(starting_items_flow, surface_name, "Ship Wreckage (Max 1)", "crashed_ship_wreakage", MAX_CRASHED_SHIP_WRECKAGE_ITEMS)

    local spawn_config_flow = scroll_pane.add {
        type = "flow",
        direction = "horizontal"
    }

    -- Create an choose-elem-button for the testing
    local button = spawn_config_flow.add {
        type = "choose-elem-button",
        elem_type = "entity",
        elem_filters = {{filter = "type", type = "resource"}, {filter = "minable", mode = "and"}},
    }

    -- Spawn Config (safe area)
    -- Spawn Config (water strip) (Note offset from north of spawn.)
    -- Spawn Config (shared power pole position) (Note offset from west of spawn.)
    -- Spawn Config (shared chest position) (Note offset from west of spawn.)
    -- Spawn Config (resources and amounts (and maybe x/y positions)) (Note offset is center and not used if auto place.)
    -- Spawn Config (fluid resources) (Note offset from south of spawn.)
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

        player.print("Selected surface: " .. selected_surface_name)
    end
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
        type = "flow",
        direction = "vertical"
    }

    AddLabel(vertical_flow, nil, header, my_label_header2_style)

    local table = vertical_flow.add {
        type = "table",
        column_count = 3,
        style = "bordered_table",
        tags = {
            surface_name = surface_name,
            setting = setting_name,
            max_count = max_count or 0
        }
    }

    --Add headers
    AddLabel(table, nil, "Item", "caption_label")
    AddLabel(table, nil, "Count", "caption_label")
    AddLabel(table, nil, "Remove", "caption_label")

    for item_name, item_count in pairs(items) do
        SurfaceConfigItemListDisplayRow(table, item_name, item_count)
    end

    -- Add a button to add another row
    if (max_count == nil) or (max_count == 0) or (table_size(items) < max_count) then
        SurfaceConfigItemListAddRowButton(table)
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
        player.print("Selected item: " .. new_item_name)

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
        player.print("Update item: " .. old_item_name .. " to " .. new_item_name .. " for surface " .. surface_name)
        global.ocfg.surfaces_config[surface_name].starting_items[setting_name][new_item_name] = global.ocfg.surfaces_config[surface_name].starting_items[setting_name][old_item_name]
        global.ocfg.surfaces_config[surface_name].starting_items[setting_name][old_item_name] = nil

        -- Update all tags with the new item name.
        for _, child in pairs(event.element.parent.children) do
            if (child.tags.item_name == old_item_name) then
                local tags_copy = child.tags
                tags_copy.item_name = new_item_name
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
        player.print("Remove item: " .. tags.item_name)
        
        local parent = event.element.parent
        local surface_name = parent.tags.surface_name --[[@as string]]
        local setting_name = parent.tags.setting --[[@as string]]
        local item_name = tags.item_name --[[@as string]]
        local max_count = parent.tags.max_count --[[@as integer]]

        -- Nil the entry
        player.print("Remove item: " .. item_name .. " for surface " .. surface_name)
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

        player.print("Add row: " .. setting_name)

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
        player.print("Crashed Ship Enabled: " .. tostring(event.element.state))
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

        player.print("Copy Nauvis: " .. surface_name)
        global.ocfg.surfaces_config[surface_name].starting_items = global.ocfg.surfaces_config["nauvis"].starting_items
        global.ocfg.surfaces_config[surface_name].spawn_config = global.ocfg.surfaces_config["nauvis"].spawn_config

        -- Recreate the content section
        local content_flow = event.element.parent.parent["surface_config_content_flow"]
        if (content_flow == nil) then
            error("Content flow is nil? This shouldn't happen on copy nauvis! " .. surface_name)
        end
        content_flow.clear()
        CreateSurfaceConfigContent(content_flow, surface_name)
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
        type = "sprite-button",
        sprite = "utility/check_mark_green",
        tooltip = "Add Item", -- TODO: Localize
        tags = {
            action = "oarc_surface_config_tab",
            add_row_button = true
        }
    }
    add_row_button.style.width = 28
    add_row_button.style.height = 28
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

    if (tags.item_number_textfield) then
        player.print("Selected item: " .. tags.item_name .. " count: " .. event.element.text)

        event.element.style = "invalid_value_textfield"
        event.element.style.width = 40
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
        player.print("Selected item: " .. tags.item_name .. " count: " .. event.element.text)

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
    end
end