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

function SharedChestsSpawnOutput(player, pos)

    local outputChest = game.surfaces[GAME_SURFACE_NAME].create_entity{name="logistic-chest-requester", position={pos.x, pos.y}, force="neutral"}
    outputChest.destructible = false
    outputChest.minable = false

    if global.shared_chests == nil then
        global.shared_chests = {}
    end

    local chestInfoOut = {player=player.name,type="OUTPUT",entity=outputChest}
    table.insert(global.shared_chests, chestInfoOut)
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
                    -- log("Input chest: " .. itemName .. " " .. count)

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
        if (chestInfo.type == "OUTPUT") then

            local chestEntity = chestInfo.entity

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

    -- log("PRE-CAP requests:")
    -- log("SHARED_ITEMS: " .. serpent.block(global.shared_items))
    -- log("SHARED_REQ: " .. serpent.block(global.shared_requests))
    -- log("SHARED_REQ_TOTAL: " .. serpent.block(global.shared_requests_totals))

    -- If demand is more than supply, limit each player's total item request to shared amount
    for reqName,reqTally in pairs(global.shared_requests) do

        local cap = 0
        local mustCap = false

        -- No shared items means nothing to supply.
        if (global.shared_items[reqName] == nil) or (global.shared_items[reqName] == 0) then
            -- log("Cap cause no shared items...")
            mustCap = true
            cap = 0

        -- Otherwise, limit by dividing by players.
        elseif (global.shared_requests_totals[reqName] > global.shared_items[reqName]) then
            mustCap = true
            cap = math.floor(global.shared_items[reqName] / TableLength(global.shared_requests[reqName]))
            -- log("Cap shared " .. global.shared_items[reqName] .. " / " .. TableLength(global.shared_requests[reqName]) .. " = " .. cap)
            -- log(serpent.block(global.shared_requests[reqName]))

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

    -- log("POST-CAP requests:")
    -- log("SHARED_ITEMS: " .. serpent.block(global.shared_items))
    -- log("SHARED_REQ: " .. serpent.block(global.shared_requests))
    -- log("SHARED_REQ_TOTAL: " .. serpent.block(global.shared_requests_totals))
end


-- Distribute requests based on demand
function SharedChestsDistributeRequests()

    -- For each output chest.
    for _,chestInfo in pairs(global.shared_chests) do
        if (chestInfo.type == "OUTPUT") then

            local chestEntity = chestInfo.entity

            -- For each request slot
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

                                    -- log("INSERT: " .. math.min(allowedAmount, global.shared_items[req.name]))
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

function SharedChestsOnTick()

    if global.shared_chests == nil then
        global.shared_chests = {}
    end

    -- Every second, we check the input chests and deposit stuff.
    if ((game.tick % (60)) == 37) then
        SharedChestsDepositAll()
        -- log("SHARED_ITEMS: " .. serpent.block(global.shared_items))
    end

    -- Every second + tick, we check the output chests for requests
    if ((game.tick % (60)) == 38) then
        SharedChestsTallyRequests()
    end

    -- Every second + 2 ticks, we distribute to the output chests.
    if ((game.tick % (60)) == 39) then
        SharedChestsDistributeRequests()
        -- log("POST DISTRIBUTE: ")
        -- log("SHARED_ITEMS: " .. serpent.block(global.shared_items))
        -- log("SHARED_REQ: " .. serpent.block(global.shared_requests))
        -- log("SHARED_REQ_TOTAL: " .. serpent.block(global.shared_requests_totals))
    end
end


function CreateSharedItemsGuiTab(tab_container, player)
    local scrollFrame = tab_container.add{type="scroll-pane",
                                    name="sharedItems-panel",
                                    direction = "vertical"}
    ApplyStyle(scrollFrame, my_shared_item_list_fixed_width_style)
    scrollFrame.horizontal_scroll_policy = "never"

    AddLabel(scrollFrame, "share_items_info", "Place items into the yellow storage chests to share. Request items from the blue requestor chests to pull out items. To refresh this view, click the tab again. Shared items are accessible by EVERYONE across all teams.", my_longer_label_style)

    AddLabel(scrollFrame, "share_items_title_msg", "Shared Items:", my_label_header_style)

    for itemName,itemCount in pairs(global.shared_items) do
        if (itemCount > 0) then
            local caption_str = itemName..": "..itemCount
            AddLabel(scrollFrame, itemName.."_itemlist", caption_str, my_player_list_style)
        end
    end

end