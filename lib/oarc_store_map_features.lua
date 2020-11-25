-- oarc_store_map_features.lua
-- May 2020
-- Adding microtransactions.

require("lib/shared_chests")
require("lib/map_features")
local mod_gui = require("mod-gui")

OARC_STORE_MAP_TEXT = 
{
    special_chests = "Special buildings for sharing or monitoring items and energy. This will convert the closest wooden chest (to you) within 16 tiles into a special building of your choice. Make sure to leave enough space! The combinators and accumulators can take up several tiles around them.",
    special_chunks = "Map features that can be built on the special empty chunks found on the map. You must be standing inside an empty special chunk to be able to build these. Each player can only build one of each type. [color=red]THESE FEATURES ARE PERMANENT AND CAN NOT BE REMOVED![/color]",
    special_buttons = "Special buttons like teleporting home and placing waterfill.",
    reset_buttons = "Reset your player and base. [color=red]Choose carefully! Can't be undone.[/color] If you don't own a base and your own force, some options may not be available to you."
}

-- N = number already purchased
-- Cost = initial + (additional * ( N^multiplier ))
OARC_STORE_MAP_FEATURES = 
{
    special_chests = {
        ["logistic-chest-storage"] = {
            initial_cost = 200,
            additional_cost = 20,
            multiplier_cost = 2,
            max_cost = 2000,
            -- limit = 100,
            text="Input chest for storing shared items."},
        ["logistic-chest-requester"] = {
            initial_cost = 200,
            additional_cost = 50,
            multiplier_cost = 2,
            max_cost = 4000,
            -- limit = 100,
            text="Output chest for requesting shared items."},
        ["constant-combinator"] = {
            initial_cost = 50, 
            text="Combinator setup to monitor shared items."},
        ["accumulator"] = {
            initial_cost = 200,
            additional_cost = 50,
            multiplier_cost = 2,
            max_cost = 2000,
            -- limit = 100,
            text="INPUT for shared energy system. [color=red]Only starts to share once it is charged to 50%.[/color]"},
        ["electric-energy-interface"] = {
            initial_cost = 200,
            additional_cost = 100,
            multiplier_cost = 2,
            max_cost = 4000,
            -- limit = 100,
            text="OUTPUT for shared energy system. [color=red]Will NOT power other special eletric interfaces! You especially can't power special chunks with this![/color]"},
        ["deconstruction-planner"] = {
            initial_cost = 0,
            text="Removes the closest special building within range. NO REFUNDS!"},
    },

    special_chunks = {
        ["electric-furnace"] = {
            initial_cost = 1000,
            additional_cost = 1000,
            multiplier_cost = 2,
            -- limit = 3,
            text="Build a special furnace chunk here. Contains 4 furnaces that run at very high speeds. [color=red]Requires energy from the shared storage. Modules have no effect![/color]"},
        ["oil-refinery"] = {
            initial_cost = 1000,
            additional_cost = 1000,
            multiplier_cost = 2,
            -- limit = 3,
            text="Build a special oil refinery chunk here. Contains 2 refineries and some chemical plants that run at very high speeds. [color=red]Requires energy from the shared storage. Modules have no effect![/color]"},
        ["assembling-machine-3"] = {
            initial_cost = 1000,
            additional_cost = 1000,
            multiplier_cost = 2,
            -- limit = 3,
            text="Build a special assembly machine chunk here. Contains 6 assembling machines that run at very high speeds. [color=red]Requires energy from the shared storage. Modules have no effect![/color]"},
        ["centrifuge"] = {
            initial_cost = 1000,
            additional_cost = 1000,
            multiplier_cost = 2,
            -- limit = 1,
            text="Build a special centrifuge chunk here. Contains 1 centrifuge that runs at very high speeds. [color=red]Requires energy from the shared storage. Modules have no effect![/color]"},
        ["rocket-silo"] = {
            initial_cost = 1000,
            additional_cost = 0,
            multiplier_cost = 2,
            max_cost = 10000,
            -- limit = 2,
            text="Convert this special chunk into a rocket launch pad. This allows you to build a rocket silo here!"},
    },

    -- special_chunks_upgrades = {
    --     ["big-electric-pole"] = {
    --         cost = 0,
    --         text = "Upgrade your special chunk so that it pulls power from the cloud! Refills the accumulator from the cloud automatically if it falls below 50%."
    --     }

    -- }

    special_buttons = {
        ["assembling-machine-1"] = {
            initial_cost = 10,
            text="Teleport home."},
        ["offshore-pump"] = {
            initial_cost = 50,
            text="Converts the closest empty wooden chest into a water tile!"
        }
    },

    reset_buttons = {
        ["electronic-circuit"] = {
            initial_cost = 5000,
            solo_force = true,
            text="DESTROY your base and restart. This allows you to choose a new spawn and will completely destroy all your buildings and your force. All technology progress will be reset. You get to keep your current items and armor! [color=red]THERE IS NO CONFIRMATION PROMPT! THIS CAN NOT BE UNDONE![/color]"
        },
        ["advanced-circuit"] = {
            initial_cost = 5000,
            solo_force = true,
            text="ABANDON your base and restart. This allows you to choose a new spawn and will move all your buildings to a neutral force. They will still be on the map and can be interacted with, but will not be owned by any player or player force. All radars will be destroyed to help trim map size. You get to keep your current items and armor! [color=red]THERE IS NO CONFIRMATION PROMPT! THIS CAN NOT BE UNDONE![/color]"
        },
        ["processing-unit"] = {
            initial_cost = 5000,
            text="Restart your game. This will reset your player, your force and your base. [color=red]THERE IS NO CONFIRMATION PROMPT! THIS CAN NOT BE UNDONE![/color]"
        }
    }
}

function CreateMapFeatureStoreTab(tab_container, player)

    local player_inv = player.get_main_inventory()
    if (player_inv == nil) then return end

    local wallet = player_inv.get_item_count("coin")
    AddLabel(tab_container,
        "map_feature_store_wallet_lbl",
        "Coins Available: " .. wallet .. "  [item=coin]",
        {top_margin=5, bottom_margin=5})
    AddLabel(tab_container, "coin_info", "Players start with some coins. Earn more coins by killing enemies.", my_note_style)

    local line = tab_container.add{type="line", direction="horizontal"}
    line.style.top_margin = 5
    line.style.bottom_margin = 5

    for category,section in pairs(OARC_STORE_MAP_FEATURES) do

        if (not global.ocfg.enable_chest_sharing and (category == "special_chests")) then
            goto SKIP_CATEGORY
        end

        if (not global.ocfg.enable_magic_factories and (category == "special_chunks")) then
            goto SKIP_CATEGORY
        end

        AddLabel(tab_container,
                nil,
                OARC_STORE_MAP_TEXT[category],
                {bottom_margin=5, maximal_width = 400, single_line = false})
        local flow = tab_container.add{name = category, type="flow", direction="horizontal"}
        for item_name,item in pairs(section) do

            local blocked = false
            if (item.solo_force and ((player.force.name == global.ocfg.main_force) or
                                     (not global.ocore.playerSpawns[player.name]))) then
                blocked = true
            end

            local count = OarcMapFeaturePlayerCountGet(player, category, item_name)
            local cost = OarcMapFeatureCostScaling(player, category, item_name)
            local color = "[color=green]"
            if ((cost > wallet) or (cost < 0) or blocked) then
                color = "[color=red]"
            end
            local btn = flow.add{name=item_name,
                        type="sprite-button",
                        -- number=item.count,
                        sprite="item/"..item_name,
                        -- tooltip=item.text.." Cost: "..color..cost.."[/color] [item=coin]",
                        style=mod_gui.button_style}
            if (cost < 0) then
                btn.enabled = false
                btn.tooltip = item.text .. "\n "..color..
                                 "Limit: ("..count.."/"..item.limit..") [/color]"
            elseif (blocked) then
                btn.enabled = false
                btn.tooltip = item.text .. " (This is only allowed for players on their own force that own the spawn. If you have other players on your force, they must reset first before you can use this.)" .." Cost: "..color..cost.."[/color] [item=coin]"
            elseif (item.limit) then
                btn.tooltip = item.text .. "\nCost: "..color..cost.."[/color] [item=coin] "..
                                "Limit: ("..count.."/"..item.limit..")"
            else
                btn.tooltip = item.text.." Cost: "..color..cost.."[/color] [item=coin]"
            end
            
        end

        -- Spacer
        local line2 = tab_container.add{type="line", direction="horizontal"}
        line2.style.top_margin = 5
        line2.style.bottom_margin = 5

        ::SKIP_CATEGORY::
    end
end

function OarcMapFeatureInitGlobalCounters()
    global.oarc_store = {}
    global.oarc_store.pmf_counts = {}
end

function OarcMapFeaturePlayerCreatedEvent(player)
    global.oarc_store.pmf_counts[player.name] = {}
end

function OarcMapFeaturePlayerCountGet(player, category_name, feature_name)
    if (not global.oarc_store.pmf_counts[player.name][feature_name]) then
        global.oarc_store.pmf_counts[player.name][feature_name] = 0
        return 0
    end
    
    return global.oarc_store.pmf_counts[player.name][feature_name]
end

function OarcMapFeaturePlayerCountChange(player, category_name, feature_name, change)

    if (not global.oarc_store.pmf_counts[player.name][feature_name]) then
        if (change < 0) then
            log("ERROR - OarcMapFeaturePlayerCountChange - Removing when count is not set??")
        end
        global.oarc_store.pmf_counts[player.name][feature_name] = change
        return
    end

    -- Update count
    global.oarc_store.pmf_counts[player.name][feature_name] = global.oarc_store.pmf_counts[player.name][feature_name] + change

    -- Make sure we don't go below 0.
    if (global.oarc_store.pmf_counts[player.name][feature_name] < 0) then
        global.oarc_store.pmf_counts[player.name][feature_name] = 0
    end
end



-- Return cost (0 or more) or return -1 if disabled.
function OarcMapFeatureCostScaling(player, category_name, feature_name)

    local map_feature = OARC_STORE_MAP_FEATURES[category_name][feature_name]

    -- Check limit first.
    local count = OarcMapFeaturePlayerCountGet(player, category_name, feature_name)
    if (map_feature.limit and (count >= map_feature.limit)) then
        return -1
    end

    if (map_feature.initial_cost and map_feature.additional_cost and map_feature.multiplier_cost) then
        local calc_cost = (map_feature.initial_cost + (map_feature.additional_cost*(count^map_feature.multiplier_cost)))
        if (map_feature.max_cost) then
            return math.min(map_feature.max_cost, calc_cost)
        else
            return calc_cost
        end
    else
        return map_feature.initial_cost
    end
end

function OarcMapFeatureStoreButton(event)
    local button = event.element
    local player = game.players[event.player_index]

    local player_inv = player.get_inventory(defines.inventory.character_main)
    if (player_inv == nil) then return end
    local wallet = player_inv.get_item_count("coin")

    local map_feature = OARC_STORE_MAP_FEATURES[button.parent.name][button.name]

    -- Calculate cost based on how many player has purchased?
    local cost = OarcMapFeatureCostScaling(player, button.parent.name, button.name)

    -- Check if we have enough money
    if (wallet < cost) then
        player.print("You're broke! Go kill some enemies or beg for change...")
        return
    end

    if (player.vehicle) then
        player.print("Sir, please step out of the vehicle before you try to make any purchases...")
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
        result = RequestSpawnSpecialChunk(player, SpawnFurnaceChunk, button.name)
    elseif (button.name == "oil-refinery") then
        result = RequestSpawnSpecialChunk(player, SpawnOilRefineryChunk, button.name)
    elseif (button.name == "assembling-machine-3") then
        result = RequestSpawnSpecialChunk(player, SpawnAssemblyChunk, button.name)
    elseif (button.name == "centrifuge") then
        result = RequestSpawnSpecialChunk(player, SpawnCentrifugeChunk, button.name)
    elseif (button.name == "rocket-silo") then
        result = RequestSpawnSpecialChunk(player, SpawnSiloChunk, button.name)
    elseif (button.name == "assembling-machine-1") then
        SendPlayerToSpawn(player)
        result = true
    elseif (button.name == "offshore-pump") then
        result = ConvertWoodenChestToWaterFill(player)
    elseif (button.name == "electronic-circuit") then
        ResetPlayerAndDestroyForce(player)
        result = true
    elseif (button.name == "advanced-circuit") then
        ResetPlayerAndAbandonForce(player)
        result = true
    elseif (button.name == "processing-unit") then
        ResetPlayerAndMergeForceToNeutral(player)
        result = true
    end

    -- On success, we deduct money
    if (result) then
        player_inv.remove({name = "coin", count = cost})
    end

    -- Refresh GUI:
    FakeTabChangeEventOarcStore(player)
end
