-- shared_chests.lua
-- Feb 2020
-- Oarc's silly idea for a scripted item sharing solution.

-- Buffer size is the limit of joules/tick so multiply by 60 to get /sec.
SHARED_ELEC_OUTPUT_BUFFER_SIZE = 1000000000 -- Default 10000000000
SHARED_ELEC_INPUT_BUFFER_SIZE = 1000000000 -- 480000000

DEFAULT_SHARED_ELEC_INPUT_LIMIT = 16666 -- 1MW

SHARED_ENERGY_STARTING_VALUE = 0 -- 100GJ

-- How often we are executing the electricity distribution.
SHARED_ELEC_TICK_RATE = 60

function SharedChestInitItems()

    global.shared_chests = {}
    global.shared_requests = {}
    global.shared_requests_totals = {}

    global.shared_electricity_inputs = {}
    global.shared_electricity_outputs = {}

    global.shared_electricity_player_limits = {}
    global.shared_chests_combinators = {}
    global.shared_items = {}
    global.shared_items['red-wire'] = 10000
    global.shared_items['green-wire'] = 10000
    global.shared_items['raw-fish'] = 10000   
    global.shared_energy_stored = SHARED_ENERGY_STARTING_VALUE
    global.shared_energy_stored_history = {start=SHARED_ENERGY_STARTING_VALUE, after_input=SHARED_ENERGY_STARTING_VALUE, after_output=SHARED_ENERGY_STARTING_VALUE}
end

function SharedEnergySpawnInput(player, pos)

    local inputElec = game.surfaces[GAME_SURFACE_NAME].create_entity{name="electric-energy-interface", position=pos, force="neutral"}
    inputElec.destructible = false
    inputElec.minable = false
    inputElec.operable = false

    inputElec.electric_buffer_size = SHARED_ELEC_INPUT_BUFFER_SIZE
    inputElec.power_production = 0
    inputElec.power_usage = 0
    inputElec.energy = 0

    local inputElecCombi = game.surfaces[GAME_SURFACE_NAME].create_entity{name="constant-combinator", position={x=pos.x+1, y=pos.y}, force="neutral"}
    inputElecCombi.destructible = false
    inputElecCombi.minable = false
    inputElecCombi.operable = true -- Input combi can be set by the player!

    -- Default share is 1MW
    inputElecCombi.get_or_create_control_behavior().set_signal(1,
        {signal={type="virtual", name="signal-M"},
        count=1})

    TemporaryHelperText("Connect to electric network to contribute shared energy.", {pos.x+1.5, pos.y-1}, TICKS_PER_MINUTE*2)
    TemporaryHelperText("Use combinator to limit number of MW shared.", {pos.x+2.5, pos.y}, TICKS_PER_MINUTE*2)

    table.insert(global.shared_electricity_inputs, {eei=inputElec, combi=inputElecCombi})
end

function SharedEnergySpawnOutput(player, pos)

    local outputElec = game.surfaces[GAME_SURFACE_NAME].create_entity{name="electric-energy-interface", position=pos, force="neutral"}
    outputElec.destructible = false
    outputElec.minable = false
    outputElec.operable = false

    outputElec.electric_buffer_size = SHARED_ELEC_INPUT_BUFFER_SIZE
    outputElec.power_production = 0
    outputElec.power_usage = 0
    outputElec.energy = 0

    local outputElecCombi = game.surfaces[GAME_SURFACE_NAME].create_entity{name="constant-combinator", position={x=pos.x+1, y=pos.y}, force="neutral"}
    outputElecCombi.destructible = false
    outputElecCombi.minable = false
    outputElecCombi.operable = false -- Output combi is set my script!

    TemporaryHelperText("Connect to electric network to consume shared energy.", {pos.x+1.5, pos.y-1}, TICKS_PER_MINUTE*2)
    TemporaryHelperText("Combinator outputs number of MJ currently stored.", {pos.x+2.5, pos.y}, TICKS_PER_MINUTE*2)

    table.insert(global.shared_electricity_outputs, {eei=outputElec, combi=outputElecCombi})
end

function SharedEnergyStoreInputOnTick()
    global.shared_energy_stored_history.start = global.shared_energy_stored

    for idx,input in pairs(global.shared_electricity_inputs) do

        -- Check for entity no longer valid:
        if (input.eei == nil) or (not input.eei.valid) or (input.combi == nil) or (not input.combi.valid) then
            global.shared_electricity_inputs[idx] = nil
        
        -- Is input at least half full, then we can start to store energy.
        elseif (input.eei.energy > (SHARED_ELEC_INPUT_BUFFER_SIZE/2)) then

                -- Calculate the max we can share
                local max_input_allowed = input.eei.energy - (SHARED_ELEC_INPUT_BUFFER_SIZE/2) 

                -- Get the combinator limit
                local limit = 0
                local sig = input.combi.get_or_create_control_behavior().get_signal(1)
                if ((sig ~= nil) and (sig.signal ~= nil) and (sig.signal.name == "signal-M")) then
                    limit = sig.count
                end

                -- Get the minimum
                input.eei.power_usage = math.min(max_input_allowed, math.floor(limit*1000000/60))
                
                global.shared_energy_stored = global.shared_energy_stored + input.eei.power_usage

        -- Switch off contribution if not at least half full.
        else
            input.eei.power_usage = 0
        end
    end

    global.shared_energy_stored_history.after_input = global.shared_energy_stored
end

-- If there is room to distribute energy, we take shared amount split by players.
function SharedEnergyDistributeOutputOnTick()

    -- Share limit is total amount stored divided by outputs
    local energyShareCap = math.floor(global.shared_energy_stored / (#global.shared_electricity_outputs))

    -- Iterate through and fill up outputs if they are under 50%
    for idx,output in pairs(global.shared_electricity_outputs) do

        -- Check for entity no longer valid:
        if (output.eei == nil) or (not output.eei.valid) or (output.combi == nil) or (not output.combi.valid) then
            global.shared_electricity_outputs[idx] = nil
        
        
        else
            -- If it's not full, set production to fill (or as much as is allowed.)
            if (output.eei.energy < (SHARED_ELEC_OUTPUT_BUFFER_SIZE/2)) then
                local outBufferSpace = ((SHARED_ELEC_OUTPUT_BUFFER_SIZE/2) - output.eei.energy)
                output.eei.power_production = math.min(outBufferSpace, energyShareCap)
                global.shared_energy_stored = global.shared_energy_stored - math.min(outBufferSpace, energyShareCap)
            
            -- Switch off if we're more than half full.
            else
                output.eei.power_production = 0
            end

            -- Update output combinator
            output.combi.get_or_create_control_behavior().set_signal(1,
                            {signal={type="virtual", name="signal-M"},
                            count=clampInt32(math.floor(global.shared_energy_stored/1000000))})
        end
    end

    global.shared_energy_stored_history.after_output = global.shared_energy_stored
end

-- Returns NIL or position of destroyed chest.
function FindClosestWoodenChestAndDestroy(player)
    local target_chest = FindClosestPlayerOwnedEntity(player, "wooden-chest", 16)
    if (not target_chest) then
        player.print("Failed to find wooden-chest?")
        return nil
    end

    if (not target_chest.get_inventory(defines.inventory.chest).is_empty()) then
        player.print("Chest is NOT empty! Please empty it and try again.")
        return nil
    end

    local pos = target_chest.position
    if (not target_chest.destroy()) then
        player.print("ERROR - Can't remove wooden chest??")
        return nil
    end

    return {x=math.floor(pos.x),y=math.floor(pos.y)}
end

function ConvertWoodenChestToSharedChestInput(player)
    local pos = FindClosestWoodenChestAndDestroy(player)
    if (pos) then
        SharedChestsSpawnInput(player, pos)
        return true
    end
    return false
end

function ConvertWoodenChestToSharedChestOutput(player)
    local pos = FindClosestWoodenChestAndDestroy(player)
    if (pos) then
        SharedChestsSpawnOutput(player, pos)
        return true
    end
    return false
end

function ConvertWoodenChestToSharedChestCombinators(player)
    local pos = FindClosestWoodenChestAndDestroy(player)
    if (pos) then
        if (player.surface.can_place_entity{name="constant-combinator", position={pos.x,pos.y-1}}) and 
            (player.surface.can_place_entity{name="constant-combinator", position={pos.x,pos.y+1}}) then
            SharedChestsSpawnCombinators(player, {x=pos.x,y=pos.y-1}, {x=pos.x,y=pos.y+1})
            return true
        else
            player.print("Failed to place the special combinators. Please check there is enough space in the surrounding tiles!")
        end
    end
    return false
end

function ConvertWoodenChestToShareEnergyInput(player)
    local pos = FindClosestWoodenChestAndDestroy(player)
    if (pos) then
        if (player.surface.can_place_entity{name="electric-energy-interface", position=pos}) and 
            (player.surface.can_place_entity{name="constant-combinator", position={x=pos.x+1, y=pos.y}}) then
            SharedEnergySpawnInput(player, pos)
            return true
        else
            player.print("Failed to place the shared energy input. Please check there is enough space in the surrounding tiles!")
        end
    end
    return false
end

function ConvertWoodenChestToShareEnergyOutput(player)
    local pos = FindClosestWoodenChestAndDestroy(player)
    if (pos) then
        if (player.surface.can_place_entity{name="electric-energy-interface", position=pos}) and 
            (player.surface.can_place_entity{name="constant-combinator", position={x=pos.x+1, y=pos.y}}) then
            SharedEnergySpawnOutput(player, pos)
            return true
        else
            player.print("Failed to place the shared energy input. Please check there is enough space in the surrounding tiles!")
        end
    end
    return false
end

function DestroyClosestSharedChestEntity(player)
    local special_entities = game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{
                                        name={"electric-energy-interface", "constant-combinator", "logistic-chest-storage", "logistic-chest-requester"},
                                        position=player.position,
                                        radius=5,
                                        force={"neutral"},
                                        limit=1}

    if (#special_entities == 1) then
        special_entities[1].destroy()
    end
end

function SharedChestsSpawnInput(player, pos)

    local inputChest = game.surfaces[GAME_SURFACE_NAME].create_entity{name="logistic-chest-storage", position={pos.x, pos.y}, force="neutral"}
    inputChest.destructible = false
    inputChest.minable = false

    if global.shared_chests == nil then
        global.shared_chests = {}
    end

    local chestInfoIn = {player=player.name,type="INPUT",entity=inputChest}
    table.insert(global.shared_chests, chestInfoIn)

    TemporaryHelperText("Place items in to share.", {pos.x+1.5, pos.y}, TICKS_PER_MINUTE*2)
end

function SharedChestsSpawnOutput(player, pos, enable_example)

    local outputChest = game.surfaces[GAME_SURFACE_NAME].create_entity{name="logistic-chest-requester", position={pos.x, pos.y}, force="neutral"}
    outputChest.destructible = false
    outputChest.minable = false

    if (enable_example) then
        outputChest.set_request_slot({name="raw-fish", count=1}, 1)
    end

    if global.shared_chests == nil then
        global.shared_chests = {}
    end

    local chestInfoOut = {player=player.name,type="OUTPUT",entity=outputChest}
    table.insert(global.shared_chests, chestInfoOut)

    TemporaryHelperText("Set filters to request items.", {pos.x+1.5, pos.y}, TICKS_PER_MINUTE*2)
end


function SharedChestsSpawnCombinators(player, posCtrl, posStatus)

    local combiCtrl = game.surfaces[GAME_SURFACE_NAME].create_entity{name="constant-combinator", position=posCtrl, force="neutral"}
    combiCtrl.destructible = false
    combiCtrl.minable = false

    -- Fish as an example.
    combiCtrl.get_or_create_control_behavior().set_signal(1, {signal={type="item", name="raw-fish"}, count=1})

    local combiStat = game.surfaces[GAME_SURFACE_NAME].create_entity{name="constant-combinator", position=posStatus, force="neutral"}
    combiStat.destructible = false
    combiStat.minable = false
    combiStat.operable = false

    if global.shared_chests_combinators == nil then
        global.shared_chests_combinators = {}
    end

    local combiPair = {player=player.name,ctrl=combiCtrl,status=combiStat}
    table.insert(global.shared_chests_combinators, combiPair)

    TemporaryHelperText("Set signals here to monitor item counts.", {posCtrl.x+1.5, posCtrl.y}, TICKS_PER_MINUTE*2)
    TemporaryHelperText("Receive signals here to see available items.", {posStatus.x+1.5, posStatus.y}, TICKS_PER_MINUTE*2)
end

function SharedChestsUpdateCombinators()

    if global.shared_chests_combinators == nil then
        global.shared_chests_combinators = {}
    end

    for idx,combiPair in pairs(global.shared_chests_combinators) do

        -- Check if combinators still exist
        if (combiPair.ctrl == nil) or (combiPair.status == nil) or
            (not combiPair.ctrl.valid) or (not combiPair.status.valid) then
            global.shared_chests_combinators[idx] = nil
        else

            local combiCtrlBehav = combiPair.ctrl.get_or_create_control_behavior()
            local ctrlSignals = {}

            -- Get signals on the ctrl combi:
            for i=1,combiCtrlBehav.signals_count do
                local sig = combiCtrlBehav.get_signal(i)
                if ((sig ~= nil) and (sig.signal ~= nil) and (sig.signal.type == "item")) then
                    table.insert(ctrlSignals, sig.signal.name)
                end
            end
            
            local combiStatBehav = combiPair.status.get_or_create_control_behavior()
            
            -- Set signals on the status combi:
            for i=1,combiCtrlBehav.signals_count do
                if (ctrlSignals[i] ~= nil) then
                    local availAmnt = global.shared_items[ctrlSignals[i]]
                    if availAmnt == nil then availAmnt = 0 end

                    combiStatBehav.set_signal(i, {signal={type="item", name=ctrlSignals[i]}, count=clampInt32(availAmnt)})
                else
                    combiStatBehav.set_signal(i, nil)
                end
            end
        end
    end
end

function SharedChestUploadItem(item_name, count)
    if (not game.item_prototypes[item_name].has_flag("hidden")) then
        if (global.shared_items[item_name] == nil) then
            global.shared_items[item_name] = count
        else
            global.shared_items[item_name] = global.shared_items[item_name] + count
        end
        return true
    else
        return false
    end
end

function SharedChestEmptyEquipment(item_stack)
    if (item_stack == nil) then
        return 
    end
    
    if (item_stack.grid == nil) then 
        return 
    end

    local contents = item_stack.grid.get_contents()
    for item_name,count in pairs(contents) do
        SharedChestUploadItem(item_name, count)
    end
end

function SharedChestUploadChest(entity)

    local chest_inv = entity.get_inventory(defines.inventory.chest)
    if (chest_inv == nil) then return end
    if (chest_inv.is_empty()) then return end

    local contents = chest_inv.get_contents()
    for item_name,count in pairs(contents) do
        if (game.item_prototypes[item_name].equipment_grid ~= nil) then
            local item_stack = chest_inv.find_item_stack(item_name)
            while (item_stack ~= nil) do
                SharedChestEmptyEquipment(item_stack)
                item_stack.clear()
                item_stack = chest_inv.find_item_stack(item_name)
            end
        end

        if (SharedChestUploadItem(item_name, count)) then
            chest_inv.remove({name=item_name, count=count})
        end
    end
end

-- Pull all items in the deposit chests
function SharedChestsDepositAll()
    
    if global.shared_items == nil then
        global.shared_items = {}
    end

    for idx,chest_info in pairs(global.shared_chests) do

        local chest_entity = chest_info.entity

        -- Delete any chest that is no longer valid.
        if ((chest_entity == nil) or (not chest_entity.valid)) then
            global.shared_chests[idx] = nil
        
        -- Take inputs and store.
        elseif (chest_info.type == "INPUT") then
            SharedChestUploadChest(chest_entity)
        end
    end
end

-- Tally up requests by item.
function SharedChestsTallyRequests()

    -- Clear existing requests. Also serves as an init
    global.shared_requests = {}
    global.shared_requests_totals = {}

    -- For each output chest.
    for idx,chestInfo in pairs(global.shared_chests) do

        local chestEntity = chestInfo.entity

        -- Delete any chest that is no longer valid.
        if ((chestEntity == nil) or (not chestEntity.valid)) then
            global.shared_chests[idx] = nil
        
        elseif (chestInfo.type == "OUTPUT") then

            -- For each request slot
            for i = 1, chestEntity.request_slot_count, 1 do
                local req = chestEntity.get_request_slot(i)

                -- If there is a request, add the request count to our request table.
                if (req ~= nil) then

                    if global.shared_requests[req.name] == nil then
                        global.shared_requests[req.name] = {}
                    end

                    if global.shared_requests[req.name][chestInfo.player] == nil then
                        global.shared_requests[req.name][chestInfo.player] = 0
                    end

                    if global.shared_requests_totals[req.name] == nil then
                        global.shared_requests_totals[req.name] = 0
                    end

                    -- Calculate actual request to fill remainder
                    local existingAmount = chestEntity.get_inventory(defines.inventory.chest).get_item_count(req.name)
                    local requestAmount = math.max(req.count-existingAmount, 0)

                    -- Add the request counts
                    global.shared_requests[req.name][chestInfo.player] = global.shared_requests[req.name][chestInfo.player] + requestAmount
                    global.shared_requests_totals[req.name] = global.shared_requests_totals[req.name] + requestAmount
                end
            end
        end
    end


    -- If demand is more than supply, limit each player's total item request to shared amount
    for reqName,reqTally in pairs(global.shared_requests) do

        local cap = 0
        local mustCap = false

        -- No shared items means nothing to supply.
        if (global.shared_items[reqName] == nil) or (global.shared_items[reqName] == 0) then
            mustCap = true
            cap = 0

        -- Otherwise, limit by dividing by players.
        elseif (global.shared_requests_totals[reqName] > global.shared_items[reqName]) then
            mustCap = true
            cap = math.floor(global.shared_items[reqName] / TableLength(global.shared_requests[reqName]))

            -- In the case where we are rounding down to 0, let's bump the minimum distribution to 1.
            if (cap == 0) then
                cap = 1
            end
        end

        -- Limit each request to the cap.
        if mustCap then
            for player,reqCount in pairs(global.shared_requests[reqName]) do
                if (reqCount > cap) then
                    global.shared_requests[reqName][player] = cap
                end
            end
        end
    end

end


-- Distribute requests based on demand
function SharedChestsDistributeRequests()

    -- For each output chest.
    for idx,chestInfo in pairs(global.shared_chests) do
        if (chestInfo.type == "OUTPUT") then

            local chestEntity = chestInfo.entity

            -- Delete any chest that is no longer valid.
            if ((chestEntity == nil) or (not chestEntity.valid)) then
                global.shared_chests[idx] = nil

            -- For each request slot
            else
                for i = 1, chestEntity.request_slot_count, 1 do
                    local req = chestEntity.get_request_slot(i)

                    -- If there is a request, distribute items
                    if (req ~= nil) then

                        -- Make sure requests have been created.
                        -- Make sure shared items exist.
                        if (global.shared_requests_totals[req.name] ~= nil) and 
                            (global.shared_items[req.name] ~= nil) and 
                            (global.shared_requests[req.name][chestInfo.player] ~= nil) then
                            
                            if (global.shared_requests[req.name][chestInfo.player] > 0)and (global.shared_items[req.name] > 0) then

                                -- How much is already in the chest?
                                local existingAmount = chestEntity.get_inventory(defines.inventory.chest).get_item_count(req.name)
                                -- How much is required to fill the remainder request?
                                local requestAmount = math.max(req.count-existingAmount, 0)
                                -- How much is allowed based on the player's current request amount?
                                local allowedAmount = math.min(requestAmount, global.shared_requests[req.name][chestInfo.player])
                                
                                if (allowedAmount > 0) then
                                    local chestInv = chestEntity.get_inventory(defines.inventory.chest) 
                                    if chestInv.can_insert({name=req.name}) then

                                        local amnt = chestInv.insert({name=req.name, count=math.min(allowedAmount, global.shared_items[req.name])})
                                        global.shared_items[req.name] = global.shared_items[req.name] - amnt
                                        global.shared_requests[req.name][chestInfo.player] = global.shared_requests[req.name][chestInfo.player] - amnt
                                        global.shared_requests_totals[req.name] = global.shared_requests_totals[req.name] - amnt

                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function SharedChestsOnTick()

    -- Every tick we share power
    SharedEnergyStoreInputOnTick()
    SharedEnergyDistributeOutputOnTick()

    -- Every second, we check the input chests and deposit stuff.
    if ((game.tick % (60)) == 37) then
        SharedChestsDepositAll()
    end

    -- Every second, we check the output chests for requests
    if ((game.tick % (60)) == 38) then
        SharedChestsTallyRequests()
    end

    -- Every second, we distribute to the output chests.
    if ((game.tick % (60)) == 39) then
        SharedChestsDistributeRequests()
    end

    -- Every second, we update our combinator status info.
    if ((game.tick % (60)) == 40) then
        SharedChestsUpdateCombinators()
    end

end


function CreateSharedItemsGuiTab(tab_container, player)
    local scrollFrame = tab_container.add{type="scroll-pane",
                                    name="sharedItems-panel",
                                    direction = "vertical"}
    ApplyStyle(scrollFrame, my_shared_item_list_fixed_width_style)
    scrollFrame.horizontal_scroll_policy = "never"

    AddLabel(scrollFrame, "share_items_info", "Place items into the [color=yellow]yellow storage chests to share[/color].\nRequest items from the [color=blue]blue requestor chests to pull out items[/color].\nTo refresh this view, click the tab again.\nShared items are accessible by [color=red]EVERYONE and all teams[/color].\nThe combinator pair allows you to 'set' item types to watch for. Set items in the top one, and connect the bottom one to a circuit network to view the current available inventory. Items with 0 amount do not generate any signal.\nThe special accumulators share energy. The top one acts as an input, the bottom is the output.", my_longer_label_style)

    AddSpacerLine(scrollFrame)

    -- MW charging/discharging rate. (delta change * sample rate per second)
    local smelter_energy_used = 0
    if (global.magic_factory_energy_history) then
        for k,v in pairs(global.magic_factory_energy_history) do
            smelter_energy_used = smelter_energy_used + v
        end
    end
    local energy_change_add = (global.shared_energy_stored_history.after_input - global.shared_energy_stored_history.start)*60/1000000
    local energy_change_sub = (((global.shared_energy_stored_history.after_input - global.shared_energy_stored_history.after_output)*60)+smelter_energy_used)/1000000
    local energy_add_str = string.format("+%.3fMW", energy_change_add)
    local energy_sub_str = string.format("-%.3fMW", energy_change_sub)
    local rate_color = "green"
    if (energy_change_add <= energy_change_sub) then
        rate_color = "red"
    elseif (energy_change_add < (energy_change_sub+10)) then
        rate_color = "orange"
    end

    AddLabel(scrollFrame, "elec_avail_info", "[color=acid]Current electricity available: " .. string.format("%.3f", global.shared_energy_stored/1000000) .. "MJ[/color] [color=" .. rate_color .. "](" .. energy_add_str .. " " .. energy_sub_str ..")[/color]", my_longer_label_style)

    if ((global.shared_electricity_player_limits ~= nil) and 
        (global.shared_electricity_player_limits[player.name] ~= nil)) then
        
        local limit_mw_nice = string.format("%.3fMW", (global.shared_electricity_player_limits[player.name]*60 / 1000000))

        AddLabel(scrollFrame, "elec_limit_info", "Limit sharing amount (".. limit_mw_nice .."): ", my_longer_label_style)
        scrollFrame.add{type="textfield",
                            tooltip="Limit how much energy you are sharing with others!\nThis is in Joules/tick so you it is multiplied by 60 to get Watts.",
                            name="energy_share_limit_input",
                            numeric=true,
                            allow_negative=false,
                            text=global.shared_electricity_player_limits[player.name]}
    end

    AddSpacerLine(scrollFrame)
    AddLabel(scrollFrame, "share_items_title_msg", "Shared Items:", my_label_header_style)

    local sorted_items = {}
    for k in pairs(global.shared_items) do table.insert(sorted_items, k) end
    table.sort(sorted_items)

    for idx,itemName in pairs(sorted_items) do
        if (global.shared_items[itemName] > 0) then
            local caption_str = itemName..": "..global.shared_items[itemName]
            AddLabel(scrollFrame, itemName.."_itemlist", caption_str, my_player_list_style)
        end
    end

end

function SharedElectricityPlayerGuiValueChange(event)

    if (event.element.name ~= "energy_share_limit_input") then return end

    local player = game.players[event.player_index]

    if (player ~= nil) and (global.shared_electricity_player_limits ~= nil) then
        if (event.element.text == "") then 
            event.element.text = 0
        end
        if (tonumber(event.element.text) > (SHARED_ELEC_INPUT_BUFFER_SIZE/2)) then
            event.element.text = SHARED_ELEC_INPUT_BUFFER_SIZE/2
        end           

        global.shared_electricity_player_limits[player.name] = tonumber(event.element.text)
        event.element.text = global.shared_electricity_player_limits[player.name]

        local limit_mw_nice = string.format("%.3fMW", (global.shared_electricity_player_limits[player.name]*60 / 1000000))
        event.element.parent.elec_limit_info.caption = "Limit sharing amount (".. limit_mw_nice .."): "

    end
end