-- shared_chests.lua
-- Feb 2020
-- Oarc's silly idea for a scripted item sharing solution.

-- Indestructible starting chests for deposits and withdrawing
-- Every second deposits get stored
-- Every second withdrawing filters are filled based on # of players and availability.
-- All shared.

-- Global keeps a list of all shared chests, with the player owner name.
-- Depositing can happen while players are offline
-- Withdrawing won't happen if player is offline?? Not sure about this one.

-- Globals:
--  List of input chests
--  List of output chests
--  List of items currently stored
--  List of requests by item, for each player.
--  List of requests by item, totals.

-- electric-energy-interface for sharing electricity?


-- These items won't be sucked up since they can't be removed.
EXCEPTION_LIST = {['loader'] = true,
                    ['fast-loader'] = true,
                    ['express-loader'] = true}

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
    global.shared_electricity_io = {}
    global.shared_electricity_combi = {}
    global.shared_electricity_player_limits = {}
    global.shared_electricity_combi = {}
    global.shared_chests_combinators = {}
    global.shared_items = {}
    global.shared_items['red-wire'] = 10000
    global.shared_items['green-wire'] = 10000
    global.shared_items['raw-fish'] = 10000   
    global.shared_energy_stored = SHARED_ENERGY_STARTING_VALUE
    global.shared_energy_stored_history = {start=SHARED_ENERGY_STARTING_VALUE, after_input=SHARED_ENERGY_STARTING_VALUE, after_output=SHARED_ENERGY_STARTING_VALUE}
end


function SharedEnergySpawnIOPair(player, posIn, posOut)

    local inputElec = game.surfaces[GAME_SURFACE_NAME].create_entity{name="electric-energy-interface", position=posIn, force="neutral"}
    inputElec.destructible = false
    inputElec.minable = false
    inputElec.operable = false

    local outputElec = game.surfaces[GAME_SURFACE_NAME].create_entity{name="electric-energy-interface", position=posOut, force="neutral"}
    outputElec.destructible = false
    outputElec.minable = false
    outputElec.operable = false

    local outputElecCombi = game.surfaces[GAME_SURFACE_NAME].create_entity{name="constant-combinator", position={x=posOut.x+1, y=posOut.y}, force="neutral"}
    outputElecCombi.destructible = false
    outputElecCombi.minable = false
    outputElecCombi.operable = false
    table.insert(global.shared_electricity_combi, outputElecCombi)

    inputElec.electric_buffer_size = SHARED_ELEC_INPUT_BUFFER_SIZE
    inputElec.power_production = 0 -- We disable this and never use it!
    inputElec.power_usage = 0
    inputElec.energy = 0

    -- This buffer size matters because the local circuit may charge it up if there is surplus.
    -- So the limit here is something reasonable...
    outputElec.electric_buffer_size = SHARED_ELEC_OUTPUT_BUFFER_SIZE
    outputElec.power_production = 0 -- We disable this and never use it!
    outputElec.power_usage = 0
    outputElec.energy = 0

    if global.shared_electricity_io == nil then
        global.shared_electricity_io = {}
    end

    global.shared_electricity_player_limits[player.name] = DEFAULT_SHARED_ELEC_INPUT_LIMIT

    table.insert(global.shared_electricity_io, {player=player.name, input=inputElec, output=outputElec})
end

function SharedEnergyStoreInputOnTick()
    global.shared_energy_stored_history.start = global.shared_energy_stored

    if global.shared_electricity_io ~= nil then
        for idx,elecPair in pairs(global.shared_electricity_io) do
            if (elecPair.input == nil) or (not elecPair.input.valid) or 
                (elecPair.input == nil) or (not elecPair.input.valid) then
                global.shared_electricity_io[idx] = nil
            
            -- Is input at least half full, then we can start to store energy.
            elseif (elecPair.input.energy > (SHARED_ELEC_INPUT_BUFFER_SIZE/2)) then
                    local max_input_allowed = elecPair.input.energy - (SHARED_ELEC_INPUT_BUFFER_SIZE/2) 
                    elecPair.input.power_usage = math.min(max_input_allowed, global.shared_electricity_player_limits[elecPair.player])
                    global.shared_energy_stored = global.shared_energy_stored + elecPair.input.power_usage

            -- Switch off contribution if not at least half full.
            else
                elecPair.input.power_usage = 0
            end
        end
    end

    global.shared_energy_stored_history.after_input = global.shared_energy_stored
end

-- If there is room to distribute energy, we take shared amount split by players.
function SharedEnergyDistributeOutputOnTick()
    if (global.shared_electricity_io ~= nil) and (global.shared_energy_stored > 0) then
        
        -- Share limit is total amount stored divided by outputs
        local energyShareCap = math.floor(global.shared_energy_stored / (#global.shared_electricity_io))

        -- Iterate through and fill up outputs if they are under 50%
        for idx,elecPair in pairs(global.shared_electricity_io) do
            if (elecPair.output == nil) or (not elecPair.output.valid) or 
                (elecPair.output == nil) or (not elecPair.output.valid) then
                global.shared_electricity_io[idx] = nil
            
            -- If it's not full, set production to fill (or as much as is allowed.)
            elseif (elecPair.output.energy < (SHARED_ELEC_OUTPUT_BUFFER_SIZE/2)) then
                local outBufferSpace = ((SHARED_ELEC_OUTPUT_BUFFER_SIZE/2) - elecPair.output.energy)
                elecPair.output.power_production = math.min(outBufferSpace, energyShareCap)
                global.shared_energy_stored = global.shared_energy_stored - math.min(outBufferSpace, energyShareCap)
            
            -- Switch off if we're more than half full.
            else
                elecPair.output.power_production = 0
            end
        end
    end

    -- Update combinators
    for idx,combi in pairs(global.shared_electricity_combi) do
        if (combi == nil) or (not combi.valid) then
            global.shared_electricity_combi[idx] = nil
        else
            combi.get_or_create_control_behavior().set_signal(1, {signal={type="virtual", name="signal-M"}, count=clampInt32(math.floor(global.shared_energy_stored/1000000))})
        end
    end

    global.shared_energy_stored_history.after_output = global.shared_energy_stored
end

-- This function spawns chests at the given location.
function SharedChestsSpawnInput(player, pos)

    local inputChest = game.surfaces[GAME_SURFACE_NAME].create_entity{name="logistic-chest-storage", position={pos.x, pos.y}, force="neutral"}
    inputChest.destructible = false
    inputChest.minable = false

    if global.shared_chests == nil then
        global.shared_chests = {}
    end

    local chestInfoIn = {player=player.name,type="INPUT",entity=inputChest}
    table.insert(global.shared_chests, chestInfoIn)
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
end


function SharedChestsSpawnCombinators(player, posCtrl, posStatus, posPole)

    local combiCtrl = game.surfaces[GAME_SURFACE_NAME].create_entity{name="constant-combinator", position=posCtrl, force="neutral"}
    combiCtrl.destructible = false
    combiCtrl.minable = false

    -- Fish as an example.
    combiCtrl.get_or_create_control_behavior().set_signal(1, {signal={type="item", name="raw-fish"}, count=1})

    local combiStat = game.surfaces[GAME_SURFACE_NAME].create_entity{name="constant-combinator", position=posStatus, force="neutral"}
    combiStat.destructible = false
    combiStat.minable = false
    combiStat.operable = false

    -- local pole = game.surfaces[GAME_SURFACE_NAME].create_entity{name="small-electric-pole", position=posPole, force="neutral"}
    -- pole.destructible = false
    -- pole.minable = false

    -- Wire up dat pole
    -- pole.connect_neighbour({wire=defines.wire_type.red,
    --                         target_entity=combiStat})

    if global.shared_chests_combinators == nil then
        global.shared_chests_combinators = {}
    end

    local combiPair = {player=player.name,ctrl=combiCtrl,status=combiStat}
    table.insert(global.shared_chests_combinators, combiPair)
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

-- Pull all items in the deposit chests
function SharedChestsDepositAll()
    
    if global.shared_items == nil then
        global.shared_items = {}
    end

    for idx,chestInfo in pairs(global.shared_chests) do

        local chestEntity = chestInfo.entity

        -- Delete any chest that is no longer valid.
        if ((chestEntity == nil) or (not chestEntity.valid)) then
            global.shared_chests[idx] = nil
        
        -- Take inputs and store.
        elseif (chestInfo.type == "INPUT") then

            local chestInv = chestEntity.get_inventory(defines.inventory.chest)
            
            if not chestInv.is_empty() then

                local contents = chestInv.get_contents()

                for itemName,count in pairs(contents)  do

                    if (EXCEPTION_LIST[itemName] == nil) then

                        if (global.shared_items[itemName] == nil) then
                            global.shared_items[itemName] = count
                        else
                            global.shared_items[itemName] = global.shared_items[itemName] + count
                        end

                        chestInv.remove({name=itemName, count=count})
                    end
                end
            end
        end
    end
end

-- Tally up requests by item.
function SharedChestsTallyRequests()

    -- Clear existing requests. Also serves as an init
    global.shared_requests = {}
    global.shared_requests_totals = {}

    -- For each output chest.
    for _,chestInfo in pairs(global.shared_chests) do

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
    local energy_change_add = (global.shared_energy_stored_history.after_input - global.shared_energy_stored_history.start)*60/1000000
    local energy_change_sub = (global.shared_energy_stored_history.after_input - global.shared_energy_stored_history.after_output)*60/1000000
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