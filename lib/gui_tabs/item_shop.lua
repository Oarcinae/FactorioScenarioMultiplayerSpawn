-- Adding microtransactions.

---This function creates the player shop tab in the custom GUI.
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateItemShopTab(tab_container, player)

    if (player.character == nil) then
        AddLabel(tab_container, nil, "Player character not available right now.", my_warning_style)
        return
    end

    local player_inv = player.character.get_main_inventory()
    if (player_inv == nil) then
        AddLabel(tab_container, nil, "Player main inventory not available right now.", my_warning_style)
        return
    end

    local wallet = player_inv.get_item_count("coin")
    AddLabel(tab_container,
        "player_store_wallet_lbl",
        "Coins Available: " .. wallet .. "  [item=coin]",
        {top_margin=5, bottom_margin=5})
    AddLabel(tab_container, "coin_info", "Players start with some coins. Earn more coins by killing enemies.", my_note_style)
    AddLabel(tab_container, nil, "Locked items become available after playing for awhile...", my_note_style)
    if (player.admin) then
        AddLabel(tab_container, nil,  "Currently, the item list can only be edited via custom scenario or by directly setting the storage.ocfg.shop_items table.", my_note_style)
    end

    local line = tab_container.add{type="line", direction="horizontal"}
    line.style.top_margin = 5
    line.style.bottom_margin = 5

    for category,section in pairs(storage.ocfg.shop_items) do
        local flow = tab_container.add{name = category, type="flow", direction="horizontal"}
        for item_name,item in pairs(section) do

            -- Validate if item exists
            if (not prototypes.item[item_name]) then
                log("ERROR: Item not found in storage.ocfg.shop_items: " .. item_name)
                goto continue
            end

            local color = "[color=green]"
            if (item.cost > wallet) then
                color = "[color=red]"
            end
            local btn = flow.add{
                name=item_name,
                type="sprite-button",
                number=item.count,
                sprite="item/"..item_name,
                tooltip=item_name .. " Cost: "..color..item.cost.."[/color] [item=coin]",
                -- style=mod_gui.button_style,
                style="slot_button",
                tags = {
                    action = "store_item",
                    item = item_name,
                    cost = item.cost,
                    category = category
                }
            }
            if (item.play_time_locked and (player.online_time < TICKS_PER_MINUTE*15)) then
                btn.enabled = false
            end

            ::continue::
        end
        local line2 = tab_container.add{type="line", direction="horizontal"}
        line2.style.top_margin = 5
        line2.style.bottom_margin = 5
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
        local item_name = button.tags.item
        local item_cost = button.tags.cost
        local category = button.tags.category

        local item = storage.ocfg.shop_items[category][button.name]

        local player_inv = player.get_inventory(defines.inventory.character_main)
        if (player_inv == nil) then return end

        if (player_inv.get_item_count("coin") >= item.cost) then
            player_inv.insert({name = button.name, count = item.count})
            player_inv.remove({name = "coin", count = item.cost})

            if (button.parent and button.parent.parent and button.parent.parent.player_store_wallet_lbl) then
                local wallet = player_inv.get_item_count("coin")
                --button.parent.parent.player_store_wallet_lbl.caption = "Coins Available: " .. wallet .. "  [item=coin]"
                button.parent.parent.player_store_wallet_lbl.caption = { "oarc-coins-available", wallet }
            end
        else
            player.print({ "oarc-broke-message" })
        end
    end
end



---Handles the event when an entity dies.
---@param event EventData.on_post_entity_died
---@return nil
function CoinsFromEnemiesOnPostEntityDied(event)
    local coin_generation_entry = storage.ocfg.coin_generation.coin_generation_table[event.prototype.name]
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
        drop_amount = math.random(count,count * storage.ocfg.coin_generation.coin_multiplier)
    end

    if drop_amount == 0 then return end

    if storage.ocfg.coin_generation.auto_decon_coins then
        game.surfaces[surface_index].spill_item_stack{
            position=pos,
            stack={name="coin", count=math.floor(drop_amount)},
            enable_looted=true,
            force=force,
            -- allow_belts?=false,
            -- max_radius?=…,
            -- use_start_position_on_failure?=false
        }
    else
        game.surfaces[surface_index].spill_item_stack{
            position=pos,
            stack={name="coin", count=math.floor(drop_amount)},
            enable_looted=true,
            force=nil,
            -- allow_belts?=false,
            -- max_radius?=…,
            -- use_start_position_on_failure?=false
        }
    end
end
