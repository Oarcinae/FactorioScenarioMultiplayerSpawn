-- oarc_store_player_items.lua
-- May 2020
-- Adding microtransactions.

OARC_STORE_PLAYER_ITEMS = 
{
    ["Guns"] = {
        ["pistol"] = {cost = 1, count = 1},
        ["shotgun"] = {cost = 5, count = 1},
        ["submachine-gun"] = {cost = 10, count = 1},
        ["flamethrower"] = {cost = 100, count = 1},
        ["rocket-launcher"] = {cost = 200, count = 1},
        ["railgun"] = {cost = 1000, count = 1},
    },

    ["Ammo"] = {
        ["firearm-magazine"] = {cost = 10, count = 10},
        ["piercing-rounds-magazine"] = {cost = 30, count = 10},
        ["shotgun-shell"] = {cost = 10, count = 10},
        ["flamethrower-ammo"] = {cost = 50, count = 10},
        ["rocket"] = {cost = 100, count = 10},
        ["railgun-dart"] = {cost = 500, count = 10},
        ["atomic-bomb"] = {cost = 1000, count = 1},
    },

    ["Special"] = {
        ["repair-pack"] = {cost = 2, count = 1},
        ["raw-fish"] = {cost = 2, count = 1},
        ["grenade"] = {cost = 100, count = 10},
        ["cliff-explosives"] = {cost = 200, count = 10},
        ["defender-capsule"] = {cost = 100, count = 10},
        ["distractor-capsule"] = {cost = 200, count = 10},
        ["destroyer-capsule"] = {cost = 500, count = 10},
        ["poison-capsule"] = {cost = 200, count = 10},
        ["slowdown-capsule"] = {cost = 100, count = 10},
    },

    ["Armor"] = {
        ["light-armor"] = {cost = 10, count = 1},
        ["heavy-armor"] = {cost = 20, count = 1},
        ["modular-armor"] = {cost = 200, count = 1},
        ["power-armor"] = {cost = 1000, count = 1},
        ["power-armor-mk2"] = {cost = 5000, count = 1},
    },
    
    ["Power Equipment"] = {
        ["fusion-reactor-equipment"] = {cost = 1000, count = 1},
        ["battery-equipment"] = {cost = 100, count = 1},
        ["battery-mk2-equipment"] = {cost = 1000, count = 1},
        ["solar-panel-equipment"] = {cost = 10, count = 1},
    },

    ["Bot Equipment"] = {
        ["personal-roboport-equipment"] = {cost = 100, count = 1},
        ["personal-roboport-mk2-equipment"] = {cost = 500, count = 1},
        ["construction-robot"] = {cost = 100, count = 10},
    },

    ["Misc Equipment"] = {
        ["belt-immunity-equipment"] = {cost = 10, count = 1},
        ["exoskeleton-equipment"] = {cost = 100, count = 1},
        ["night-vision-equipment"] = {cost = 50, count = 1},

        ["personal-laser-defense-equipment"] = {cost = 200, count = 1},
        -- ["discharge-defense-equipment"] = {cost = 1, count = 1},
        ["energy-shield-equipment"] = {cost = 100, count = 1},
        ["energy-shield-mk2-equipment"] = {cost = 1000, count = 1},
    },
}

function CreatePlayerStoreTab(tab_container, player)

    local player_inv = player.get_main_inventory()
    if (player_inv == nil) then return end

    local wallet = player_inv.get_item_count("coin")
    AddLabel(tab_container,
        "player_store_wallet_lbl",
        "Coins Available: " .. wallet .. "  [item=coin]",
        {top_margin=5, bottom_margin=5})

    local line = tab_container.add{type="line", direction="horizontal"}
    line.style.top_margin = 5
    line.style.bottom_margin = 5

    for category,section in pairs(OARC_STORE_PLAYER_ITEMS) do
        local flow = tab_container.add{name = category, type="flow", direction="horizontal"}
        for item_name,item in pairs(section) do
            local color = "[color=green]"
            if (item.cost > wallet) then
                color = "[color=red]"
            end
            local btn = flow.add{name=item_name,
                        type="sprite-button",
                        number=item.count,
                        sprite="item/"..item_name,
                        tooltip=item_name .. " Cost: "..color..item.cost.."[/color] [item=coin]",
                        style=mod_gui.button_style}
        end
        local line2 = tab_container.add{type="line", direction="horizontal"}
        line2.style.top_margin = 5
        line2.style.bottom_margin = 5
    end
end

function OarcPlayerStoreButton(event)
    local button = event.element
    local player = game.players[event.player_index]

    local player_inv = player.get_inventory(defines.inventory.character_main)
    if (player_inv == nil) then return end

    local category = button.parent.name

    local item = OARC_STORE_PLAYER_ITEMS[category][button.name]

    if (player_inv.get_item_count("coin") >= item.cost) then
        player_inv.insert({name = button.name, count = item.count})
        player_inv.remove({name = "coin", count = item.cost})

        if (button.parent and button.parent.parent and button.parent.parent.player_store_wallet_lbl) then
            local wallet = player_inv.get_item_count("coin")
            button.parent.parent.player_store_wallet_lbl.caption = "Coins Available: " .. wallet .. "  [item=coin]"
        end

    else
        player.print("You're broke! Go kill some enemies or beg for change...")
    end
end