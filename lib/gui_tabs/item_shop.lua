-- Adding microtransactions.

---This function creates the player shop tab in the custom GUI.
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateItemShopTab(tab_container, player)

    local player_inv = player.get_main_inventory()
    if (player_inv == nil) then return end

    local wallet_count = player_inv.get_item_count("coin")
    local wallet_lable = AddLabel(tab_container,
        "player_store_wallet_lbl",
        "Coins Available: " .. wallet_count .. "  [item=coin]",
        {top_margin=5, bottom_margin=5})
    


    AddLabel(tab_container, "coin_info", "Players start with some coins. Earn more coins by killing enemies.", my_note_style)
    AddLabel(tab_container, nil, "Locked items become available after playing for awhile...", my_note_style)
    if (player.admin) then
        AddLabel(tab_container, nil,  "Currently, the item list can only be edited via custom scenario or by directly\n setting the global.ocfg.shop_items table.", my_note_style)
    end

    local line = tab_container.add{type="line", direction="horizontal"}
    line.style.top_margin = 5
    line.style.bottom_margin = 5

    -- Create a tabbed pane for the different item categories
    local tabbed_pane = tab_container.add{type="tabbed-pane", name="item_shop_tabbed_pane"}

    if (global.shop_selected_tab == nil) then
        global.shop_selected_tab = {}
        if global.shop_selected_tab[player.name] == nil then
            global.shop_selected_tab[player.name] = 1
        end
    end

    -- For each section, add a tab
    local tab_index = 1
    for shop_category,category_items in pairs(global.ocfg.shop_items) do
        local tab = tabbed_pane.add{type="tab", caption=shop_category}
        local container = tabbed_pane.add{type="flow", direction="vertical"}
        CreateItemShopTable(container, player, shop_category, category_items, wallet_count, tab_index)
        container.style.top_margin = 5
        container.style.bottom_margin = 5
        container.style.left_margin = 5
        container.style.right_margin = 5
        tabbed_pane.add_tab(tab, container)
        tab_index = tab_index + 1
    end

    tabbed_pane.selected_tab_index = global.shop_selected_tab[player.name]
end

---Create the items table for the player shop.
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@param category_name string
---@param category_items OarcStoreCategory
---@param wallet_count integer
---@param tab_index integer
---@return nil
function CreateItemShopTable(tab_container, player, category_name, category_items, wallet_count, tab_index)

    -- Used to determine if the player has played long enough to unlock certain items
    local player_time_unlocked = player.online_time > TICKS_PER_MINUTE*15

    -- First figure out how many columns we need
    local max_columns = 0
    for _,section in pairs(global.ocfg.shop_items) do
        local count = table_size(section)
        if (count > max_columns) then
            max_columns = count
        end
    end

    -- Create the table and frame with nice styles
    local button_frame = tab_container.add{type="frame", direction="horizontal", style="slot_button_deep_frame"}
    button_frame.style.horizontally_stretchable = true
    button_frame.style.vertically_stretchable = true
    local table = button_frame.add{type="table", style = "filter_slot_table", column_count=max_columns}

    for row_name, row in pairs(category_items) do

        local column_count = max_columns

        for item_name, item in pairs(row) do

            column_count = column_count - 1

            -- Validate if item exists
            local prototype = game.item_prototypes[item_name]
            if (not prototype) then
                log("ERROR: Item not found in global.ocfg.shop_items: " .. item_name)
                goto continue
            end
            
            -- Color helps indicate if player can afford item
            local color = "[color=green]"
            if (item.cost > wallet_count) then
                color = "[color=red]"
            end

            -- Extra message if time locked
            local is_time_locked = item.play_time_locked and not player_time_unlocked
            local time_locked_text = ""
            if is_time_locked then
                time_locked_text = " [color=red]Locked until 15 minutes of playtime.[/color]"
            end

            local button = table.add{
                name=item_name,
                type="sprite-button",
                number=item.count,
                sprite="item/"..item_name,
                tooltip={"", prototype.localised_name, " Cost: ", color, item.cost, "[/color] [item=coin]", time_locked_text} ,
                style="slot_button",
                tags = {
                    action = "store_item",
                    item = item_name,
                    cost = item.cost,
                    category_name = category_name,
                    row_name = row_name,
                    tab_index = tab_index,
                }
            }

            -- Color the button if player can't afford it or it's time locked
            if (item.cost > wallet_count) or is_time_locked then
                button.style = "red_slot_button"
            end

            ::continue::
        end

        -- For remaining count, add empty elements
        if (column_count > 0) then
            for i=1, column_count do
                table.add{type="empty-widget"}
                -- log("Adding empty element")
            end
        end
    end
end


---Handles the player clicking on an item in the store.
---@param event EventData.on_gui_click
---@return nil
function OarcItemShopGuiClick(event)
    if not event.element.valid then return end
    local button = event.element
    local player = game.players[event.player_index]

    if (button.tags.action == "store_item") then
        local item_name = button.tags.item --[[@as string]]
        -- local item_cost = button.tags.cost --[[@as integer]]
        local category_name = button.tags.category_name --[[@as string]]
        local row_name = button.tags.row_name --[[@as string]]

        local item = global.ocfg.shop_items[category_name][row_name][item_name]

        local player_inv = player.get_inventory(defines.inventory.character_main)
        if (player_inv == nil) then return end

        -- Check playtime lock first
        if (item.play_time_locked and player.online_time < TICKS_PER_MINUTE*15) then
            player.print("This item is locked until you have played for at least 15 minutes.")

        -- Check if player has enough coins
        elseif (player_inv.get_item_count("coin") >= item.cost) then
            player_inv.insert({name = item_name, count = item.count})
            player_inv.remove({name = "coin", count = item.cost})

            -- Recreate the item shop table to update the button colors?
            global.shop_selected_tab[player.name] = button.tags.tab_index -- Return to the same tab
            OarcGuiRefreshContent(player)

        else
            player.print("You're broke! Go kill some enemies or beg for change...")
        end
    end
end



---Handles the event when an entity dies.
---@param event EventData.on_post_entity_died
---@return nil
function CoinsFromEnemiesOnPostEntityDied(event)
    local coin_generation_entry = global.ocfg.coin_generation.coin_generation_table[event.prototype.name]
    if (coin_generation_entry) then
        DropCoins(event.surface_index, event.position, coin_generation_entry, event.force)
    end
end

-- Drop coins, force is optional, decon is applied if force is not nil.
---@param surface_index integer
---@param pos MapPosition
---@param count number
---@param force LuaForce
function DropCoins(surface_index, pos, count, force)

    local drop_amount = 0

    -- If count is less than 1, it represents a probability to drop a single coin
    if (count < 1) then
        if (math.random() < count) then
            drop_amount = 1
        end

    -- If count is 1 or more, it represents a probability to drop at least that amount and up to multiplier times
    -- that amount.
    elseif (count >= 1) then
        drop_amount = math.random(count,count * global.ocfg.coin_generation.coin_multiplier)
    end

    if drop_amount == 0 then return end

    if global.ocfg.coin_generation.auto_decon_coins then
        game.surfaces[surface_index].spill_item_stack(pos, {name="coin", count=math.floor(drop_amount)}, true, force, false)
    else
        game.surfaces[surface_index].spill_item_stack(pos, {name="coin", count=math.floor(drop_amount)}, true, nil, false)
    end
end