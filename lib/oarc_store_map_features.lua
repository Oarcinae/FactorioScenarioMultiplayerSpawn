-- oarc_store_map_features.lua
-- May 2020
-- Adding microtransactions.

require("lib/shared_chests")
require("lib/map_features")

OARC_STORE_MAP_CATEGORIES = 
{
    special_chests = "Special buildings for sharing or monitoring items and energy. This will convert the closest wooden chest (to you) within 16 tiles into a special building of your choice. Make sure to leave enough space! The combinators and accumulators can take up several tiles around them.",
    special_chunks = "Map features that can be built on the special empty chunks found on the map. You must be standing inside an empty special chunk to be able to build these. [color=red]THESE FEATURES ARE PERMANENT AND CAN NOT BE REMOVED![/color]",
    special_buttons = "Special actions. Like teleporting home. (For now this is the only one...)",
}

OARC_STORE_MAP_FEATURES = 
{
    special_chests = {
        ["logistic-chest-storage"] = {cost = 500, text="Input chest for sharing items."},
        ["logistic-chest-requester"] = {cost = 500, text="Output chest for requesting shared items."},
        ["constant-combinator"] = {cost = 50, text="Combinator setup to monitor shared items."},
        ["accumulator"] = {cost = 200, text="INPUT for shared energy system."},
        ["electric-energy-interface"] = {cost = 200, text="OUTPUT for shared energy system."},
        ["deconstruction-planner"] = {cost = 0, text="Removes the closest special buildings (within 16 tiles). NO REFUNDS!"},
    },

    special_chunks = {
        ["electric-furnace"] = {cost = 500, text="Build a special furnace chunk here. Contains 4 furnaces that run at very high speeds. [color=red]Requires energy from the shared storage. Modules have no effect![/color]"},
        ["oil-refinery"] = {cost = 500, text="Build a special oil refinery chunk here. Contains 2 refineries and some chemical plants that run at very high speeds. [color=red]Requires energy from the shared storage. Modules have no effect![/color]"},
        ["assembling-machine-3"] = {cost = 500, text="Build a special assembly machine chunk here. Contains 4 assembling machines that run at very high speeds. [color=red]Requires energy from the shared storage. Modules have no effect![/color]"},
        -- ["rocket-silo"] = {cost = 1000, text="Build a special rocket silo chunk here."},
    },

    special_buttons = {
        ["assembling-machine-1"] = {cost = 10, text="Teleport home."},
    }
    
    -- ["Utility"] = {
    --  ["fusion-reactor-equipment"] = {cost = 1000},
    --  ["battery-equipment"] = {cost = 100},
    --  ["battery-mk2-equipment"] = {cost = 1000},
    --  ["solar-panel-equipment"] = {cost = 10},
    -- },
}

function CreateMapFeatureStoreTab(tab_container, player)

    local player_inv = player.get_main_inventory()
    if (player_inv == nil) then return end

    local wallet = player_inv.get_item_count("coin")
    AddLabel(tab_container,
        "map_feature_store_wallet_lbl",
        "Coins Available: " .. wallet .. "  [item=coin]",
        {top_margin=5, bottom_margin=5})

    local line = tab_container.add{type="line", direction="horizontal"}
    line.style.top_margin = 5
    line.style.bottom_margin = 5

    for category,section in pairs(OARC_STORE_MAP_FEATURES) do
        AddLabel(tab_container,
                nil,
                OARC_STORE_MAP_CATEGORIES[category],
                {bottom_margin=5, maximal_width = 400, single_line = false})
        local flow = tab_container.add{name = category, type="flow", direction="horizontal"}
        for item_name,item in pairs(section) do
            local color = "[color=green]"
            if (item.cost > wallet) then
                color = "[color=red]"
            end
            local btn = flow.add{name=item_name,
                        type="sprite-button",
                        -- number=item.count,
                        sprite="item/"..item_name,
                        tooltip=item.text.." Cost: "..color..item.cost.."[/color] [item=coin]",
                        style=mod_gui.button_style}
        end
        local line2 = tab_container.add{type="line", direction="horizontal"}
        line2.style.top_margin = 5
        line2.style.bottom_margin = 5
    end
end

function OarcMapFeatureStoreButton(event)
    local button = event.element
    local player = game.players[event.player_index]

    local player_inv = player.get_inventory(defines.inventory.character_main)
    if (player_inv == nil) then return end
    local wallet = player_inv.get_item_count("coin")

    local map_feature = OARC_STORE_MAP_FEATURES[button.parent.name][button.name]

    -- Check if we have enough money
    if (wallet < map_feature.cost) then
        player.print("You're broke! Go kill some enemies or beg for change...")
        return
    end

    -- Each button has a special function
    local result = false
    if (button.name == "logistic-chest-storage") then
        result = ConvertWoodenChestToSharedChestInput(player)
    elseif (button.name == "logistic-chest-requester") then
        result = ConvertWoodenChestToSharedChestOutput(player)
    elseif (button.name == "constant-combinator") then
        result = ConvertWoodenChestToSharedChestCombinators(player)
    elseif (button.name == "accumulator") then
        result = ConvertWoodenChestToShareEnergyInput(player)
    elseif (button.name == "electric-energy-interface") then
        result = ConvertWoodenChestToShareEnergyOutput(player)
    elseif (button.name == "deconstruction-planner") then
        result = DestroyClosestSharedChestEntity(player)
    elseif (button.name == "electric-furnace") then
        result = RequestSpawnSpecialChunk(player, SpawnFurnaceChunk)
    elseif (button.name == "oil-refinery") then
        result = RequestSpawnSpecialChunk(player, SpawnOilRefineryChunk)
    elseif (button.name == "assembling-machine-3") then
        result = RequestSpawnSpecialChunk(player, SpawnAssemblyChunk)
    elseif (button.name == "assembling-machine-1") then
        SendPlayerToSpawn(player)
        result = true
    end

    -- On success, we deduct money
    if (result) then
        player_inv.remove({name = "coin", count = map_feature.cost})
    end

    -- Update wallet:
    if (button.parent and button.parent.parent and button.parent.parent.map_feature_store_wallet_lbl) then
        local wallet = player_inv.get_item_count("coin")
        button.parent.parent.map_feature_store_wallet_lbl.caption = "Coins Available: " .. wallet .. "  [item=coin]"
    end
end
