-- map_features.lua
-- April 2020
-- Oarc's clone of whistlestop factories maybe?

-- Generic Utility Includes
require("lib/oarc_utils")


-- Used to generate placement of buildings.
MAGIC_BUILDING_MIN_DISTANCE = 40
MAGIC_BUILDING_MAX_DISTANCE = FAR_MAX_DIST + 50
MAGIC_BUILDING_CHUNK_SPREAD = 41


POWER_USAGE_SCALING_FACTOR = 2

-- This is a table indexed by the single INPUT item!
FURNACE_ENERGY_PER_CRAFT_SECOND = (180000 / 2) * POWER_USAGE_SCALING_FACTOR
FURNACE_RECIPES = {
    ["iron-ore"] = {recipe_name = "iron-plate",
                    recipe_energy = 3.2*FURNACE_ENERGY_PER_CRAFT_SECOND,
                    recipe_pollution = 0.053},
    ["copper-ore"] = {recipe_name = "copper-plate",
                    recipe_energy = 3.2*FURNACE_ENERGY_PER_CRAFT_SECOND,
                    recipe_pollution = 0.053},
    ["iron-plate"] = {recipe_name = "steel-plate",
                    recipe_energy = 16*FURNACE_ENERGY_PER_CRAFT_SECOND,
                    recipe_pollution = 0.267}, 
    ["stone"] = {recipe_name = "stone-brick",
                    recipe_energy = 3.2*FURNACE_ENERGY_PER_CRAFT_SECOND,
                    recipe_pollution = 0.053},
}

-- The chemplants/refineries/assemblers lookup their own recipes since they can be set by the player.
CHEMPLANT_ENERGY_PER_CRAFT_SECOND = 210000 * POWER_USAGE_SCALING_FACTOR
REFINERY_ENERGY_PER_CRAFT_SECOND = 420000 * POWER_USAGE_SCALING_FACTOR
ASSEMBLER3_ENERGY_PER_CRAFT_SECOND = (375000 / 1.25) * POWER_USAGE_SCALING_FACTOR
CENTRIFUGE_ENERGY_PER_CRAFT_SECOND = 350000 * POWER_USAGE_SCALING_FACTOR

CHEMPLANT_POLLUTION_PER_CRAFT_SECOND = 4/60
REFINERY_POLLUTION_PER_CRAFT_SECOND = 6/60
ASSEMBLER3_POLLUTION_PER_CRAFT_SECOND = 2/60
CENTRIFUGE_POLLUTION_PER_CRAFT_SECOND = 4/60


ENEMY_WORM_TURRETS =
{
    [0] = "small-worm-turret",
    [1] = "medium-worm-turret",
    [2] = "big-worm-turret"
}

NEUTRAL_FORCE_RECIPES = 
{
    -- Science packs
    ["automation-science-pack"] = true,
    ["chemical-science-pack"] = true,
    ["logistic-science-pack"] = true,
    ["military-science-pack"] = true,
    ["production-science-pack"] = true,
    ["utility-science-pack"] = true,

    -- Oil Stuff
    ["advanced-oil-processing"] = true,
    ["basic-oil-processing"] = true,
    -- ["coal-liquefaction"] = true, -- Too difficult/costly to implement

    ["heavy-oil-cracking"] = true,
    ["light-oil-cracking"] = true,

    ["solid-fuel-from-heavy-oil"] = true,
    ["solid-fuel-from-light-oil"] = true,
    ["solid-fuel-from-petroleum-gas"] = true,

    ["lubricant"] = true,
    ["plastic-bar"] = true,
    ["sulfur"] = true,
    ["sulfuric-acid"] = true,
    
    -- ["oil-refinery"] = true,
    -- ["explosives"] = true,

    -- Modules
    ["effectivity-module"] = true,
    ["effectivity-module-2"] = true,
    ["effectivity-module-3"] = true,
    ["productivity-module"] = true,
    ["productivity-module-2"] = true,
    ["productivity-module-3"] = true,
    ["speed-module"] = true,
    ["speed-module-2"] = true,
    ["speed-module-3"] = true,

    -- Intermediates
    ["advanced-circuit"] = true,
    ["battery"] = true,
    ["copper-cable"] = true,
    ["copper-plate"] = true,
    ["electric-engine-unit"] = true,
    ["electronic-circuit"] = true,
    ["engine-unit"] = true,
    ["flying-robot-frame"] = true,
    ["iron-gear-wheel"] = true,
    ["iron-plate"] = true,
    ["iron-stick"] = true,
    ["low-density-structure"] = true,
    ["processing-unit"] = true,
    ["rocket-control-unit"] = true,
    ["rocket-fuel"] = true,
    ["steel-plate"] = true,
    ["stone-brick"] = true,

    -- Misc
    ["concrete"] = true,
    ["landfill"] = true,
    ["rail"] = true,
    ["solar-panel"] = true,
    ["stone-wall"] = true,
    ["empty-barrel"] = true,
    
    -- Nuclear
    ["uranium-processing"] = true,
    -- ["kovarex-enrichment-process"] = true,
    -- ["nuclear-fuel-reprocessing"] = true,

    -- ["pipe"] = true,
    -- ["pipe-to-ground"] = true,
}

function SetNeutralForceAllowedRecipes()

    -- Neutral force requires recipes so that furnaces can smelt steel for example.
    -- game.forces["neutral"].enable_all_recipes()

    -- Disable ALL recipes
    for i,v in pairs(game.forces["neutral"].recipes) do
        game.forces["neutral"].recipes[i].enabled = false;
    end 

    -- Enable only the ones we want
    for i,v in pairs(NEUTRAL_FORCE_RECIPES) do
        game.forces["neutral"].recipes[i].enabled = true;
    end

end

function MagicFactoriesInit()

    SetNeutralForceAllowedRecipes()

    global.omagic = {}
    global.omagic.building_total_count = 0
    global.omagic.factory_positions = {}
    global.omagic.furnaces = {}
    global.omagic.chemplants = {}
    global.omagic.refineries = {}
    global.omagic.assemblers = {}
    global.omagic.centrifuges = {}

    MagicFactoryChunkGenerator()

    game.surfaces[GAME_SURFACE_NAME].force_generate_chunk_requests() -- Block and generate all to be sure.
    MagicalFactorySpawnAll()
end

function MagicFactoryChunkGenerator()
    
    -- This generates several circles of randomized chunk positions.
    for r=MAGIC_BUILDING_MIN_DISTANCE,MAGIC_BUILDING_MAX_DISTANCE,MAGIC_BUILDING_CHUNK_SPREAD do
        local random_angle_offset = math.random(0, math.pi * 2)
        local num_positions_for_circle = math.ceil((r/8)) -- This makes it so each circle has more dots, roughly spreads things out equally.

        for i=1,num_positions_for_circle do
            local theta = ((math.pi * 2) / num_positions_for_circle);
            local angle = (theta * i) + random_angle_offset;

            local chunk_x = MathRound((r * math.cos(angle)) + math.random(-2, 2))
            local chunk_y = MathRound((r * math.sin(angle)) + math.random(-2, 2))

            if (not game.surfaces[GAME_SURFACE_NAME].is_chunk_generated({chunk_x,chunk_y})) then
                
                table.insert(global.omagic.factory_positions, {x=chunk_x, y=chunk_y})
                game.surfaces[GAME_SURFACE_NAME].request_to_generate_chunks(GetCenterTilePosFromChunkPos({x=chunk_x, y=chunk_y}), 0)
                log("Magic furnace position: " .. chunk_x .. ", " .. chunk_y .. ", " .. angle)
            else
                log("Magic furnace collided with silo location?" .. chunk_x .. ", " .. chunk_y)
            end
        end
    end

    SendBroadcastMsg("Number magic chunks: " .. #global.omagic.factory_positions)
end

function FindClosestMagicChunk(player)
    if (not player or not player.character) then return end
    return GetClosestPosFromTable(GetChunkPosFromTilePos(player.character.position), global.omagic.factory_positions)
end

function IndicateClosestMagicChunk(player)
    local target_pos = GetCenterTilePosFromChunkPos(FindClosestMagicChunk(player))
    rendering.draw_line{color={r=0.5,g=0.5,b=0.5,a=0.5},
                    width=2,
                    from=player.character,
                    to=target_pos,
                    surface=player.character.surface,
                    players={player},
                    draw_on_ground=true,
                    time_to_live=60*5}
end

function MagicalFactorySpawnAll()
    for _,chunk_pos in pairs(global.omagic.factory_positions) do
        
        local pos = GetCenterTilePosFromChunkPos(chunk_pos)
        local c_area = GetAreaFromChunkPos(chunk_pos)

        -- Remove any entities in the chunk area.
        for _, entity in pairs(game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{area=c_area}) do
            entity.destroy()
        end

        -- Place landfill underneath
        local dirtTiles = {}
        for i=c_area.left_top.x,c_area.right_bottom.x,1 do
            for j=c_area.left_top.y,c_area.right_bottom.y,1 do
                table.insert(dirtTiles, {name = "landfill", position ={i,j}})
            end
        end
        game.surfaces[GAME_SURFACE_NAME].set_tiles(dirtTiles)

        -- Yay colored tiles
        CreateFixedColorTileArea(game.surfaces[GAME_SURFACE_NAME], 
                                {left_top = {x=c_area.left_top.x+2, y=c_area.left_top.y+2},
                                    right_bottom = {x=c_area.right_bottom.x-2, y=c_area.right_bottom.y-2}},
                                "black")

        -- Make it safe from regrowth
        if global.ocfg.enable_regrowth then
            RegrowthMarkAreaSafeGivenTilePos(pos, 0, true)
        end
    end
end

function SpawnEnemyTurret(pos)

    local turret = game.surfaces[GAME_SURFACE_NAME].create_entity{name="gun-turret", position=pos, force="enemy"}
    local turret_inv = turret.get_inventory(defines.inventory.turret_ammo)
    turret_inv.insert({name="uranium-rounds-magazine", count=200})

end

function RequestSpawnSpecialChunk(player, spawn_function, feature_name)
    local closest_chunk = FindClosestMagicChunk(player)
    local player_chunk = GetChunkPosFromTilePos(player.character.position)
    if ((closest_chunk.x == player_chunk.x) and (closest_chunk.y == player_chunk.y)) then
        local chunk_area = GetAreaFromChunkPos(closest_chunk)

        local entities = game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{
                                        area={left_top = {chunk_area.left_top.x+1, chunk_area.left_top.y+1},
                                                right_bottom = {chunk_area.right_bottom.x-1, chunk_area.right_bottom.y-1}},
                                                force={"enemy"},
                                                invert=true}
        
        -- Either there are no entities in the chunk (player is just on the boundary), or the only entity is the player.
        if ((#entities == 1) and (entities[1].player) and (entities[1].player == player)) or (#entities == 0) then
            spawn_function(closest_chunk)
            -- Teleport to center of chunk to be safe.
            SafeTeleport(player, game.surfaces[GAME_SURFACE_NAME], GetCenterTilePosFromChunkPos(closest_chunk))
            OarcMapFeaturePlayerCountChange(player, "special_chunks", feature_name, 1)
            return true
        else
            player.print("Looks like this chunk already has something in it other than just you the player?! " .. entities[1].name)
            return false
        end

    else
        player.print("You need to be standing inside the special chunk!")
        return false
    end

    return false
end

function SpecialChunkHelperText(pos)
    RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME].index,
        {x=pos.x-3.5,y=pos.y+1},
        1,
        "Supply energy to this interface!",
        {0.7,0.4,0.3,0.8})
    RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME].index,
        {x=pos.x-4.5,y=pos.y+2},
        1,
        "Modules/beacons DO NOT have any effect!",
        {0.7,0.4,0.3,0.8})
end

function spawnSpecialChunkInputElec(center_pos)
    local inputElec = game.surfaces[GAME_SURFACE_NAME].create_entity{name="electric-energy-interface", position=center_pos, force="neutral"}
    inputElec.destructible = false
    inputElec.minable = false
    inputElec.operable = false
    inputElec.electric_buffer_size = 1000000000
    inputElec.power_production = 0
    inputElec.power_usage = 0
    inputElec.energy = 0
    return inputElec
end

function SpawnFurnaceChunk(chunk_pos)

    center_pos = GetCenterTilePosFromChunkPos(chunk_pos)
    local furnace_chunk = {["energy_input"] = spawnSpecialChunkInputElec(center_pos),
                            ["entities"] = {}}

    -- 4x furnaces
    table.insert(furnace_chunk.entities, SpawnMagicBuilding("electric-furnace", {x=center_pos.x-12,y=center_pos.y-12}))
    table.insert(furnace_chunk.entities, SpawnMagicBuilding("electric-furnace", {x=center_pos.x+11,y=center_pos.y-12}))
    table.insert(furnace_chunk.entities, SpawnMagicBuilding("electric-furnace", {x=center_pos.x-12,y=center_pos.y+11}))
    table.insert(furnace_chunk.entities, SpawnMagicBuilding("electric-furnace", {x=center_pos.x+11,y=center_pos.y+11}))

    table.insert(global.omagic.furnaces, furnace_chunk)
    SpecialChunkHelperText(center_pos)
end

function SpawnOilRefineryChunk(chunk_pos)

    center_pos = GetCenterTilePosFromChunkPos(chunk_pos)

    local oil_chunk = {["energy_input"] = spawnSpecialChunkInputElec(center_pos),
                            ["chemplants"] = {},
                            ["refineries"] = {}}

    -- 2x Refineries
    table.insert(oil_chunk.refineries, SpawnMagicBuilding("oil-refinery", {x=center_pos.x-5,y=center_pos.y-8}))
    table.insert(oil_chunk.refineries, SpawnMagicBuilding("oil-refinery", {x=center_pos.x+5,y=center_pos.y-8}))

    -- 6x Chem Plants
    table.insert(oil_chunk.chemplants, SpawnMagicBuilding("chemical-plant", {x=center_pos.x-10,y=center_pos.y+8}))
    table.insert(oil_chunk.chemplants, SpawnMagicBuilding("chemical-plant", {x=center_pos.x-6,y=center_pos.y+8}))
    table.insert(oil_chunk.chemplants, SpawnMagicBuilding("chemical-plant", {x=center_pos.x-2,y=center_pos.y+8}))
    table.insert(oil_chunk.chemplants, SpawnMagicBuilding("chemical-plant", {x=center_pos.x+2,y=center_pos.y+8}))
    table.insert(oil_chunk.chemplants, SpawnMagicBuilding("chemical-plant", {x=center_pos.x+6,y=center_pos.y+8}))
    table.insert(oil_chunk.chemplants, SpawnMagicBuilding("chemical-plant", {x=center_pos.x+10,y=center_pos.y+8}))

    table.insert(global.omagic.refineries, oil_chunk)
    table.insert(global.omagic.chemplants, oil_chunk)
    SpecialChunkHelperText(center_pos)
end

function SpawnAssemblyChunk(chunk_pos)

    center_pos = GetCenterTilePosFromChunkPos(chunk_pos)
    local assembler_chunk = {["energy_input"] = spawnSpecialChunkInputElec(center_pos),
                            ["entities"] = {}}

    -- 6x Assemblers
    table.insert(assembler_chunk.entities, SpawnMagicBuilding("assembling-machine-3", {x=center_pos.x-12,y=center_pos.y-12}))
    table.insert(assembler_chunk.entities, SpawnMagicBuilding("assembling-machine-3", {x=center_pos.x,y=center_pos.y-12}))
    table.insert(assembler_chunk.entities, SpawnMagicBuilding("assembling-machine-3", {x=center_pos.x+11,y=center_pos.y-12}))
    table.insert(assembler_chunk.entities, SpawnMagicBuilding("assembling-machine-3", {x=center_pos.x-12,y=center_pos.y+11}))
    table.insert(assembler_chunk.entities, SpawnMagicBuilding("assembling-machine-3", {x=center_pos.x-1,y=center_pos.y+11}))
    table.insert(assembler_chunk.entities, SpawnMagicBuilding("assembling-machine-3", {x=center_pos.x+11,y=center_pos.y+11}))

    table.insert(global.omagic.assemblers, assembler_chunk)
    SpecialChunkHelperText(center_pos)
end

function SpawnCentrifugeChunk(chunk_pos)

    center_pos = GetCenterTilePosFromChunkPos(chunk_pos)
    local centrifuge_chunk = {["energy_input"] = spawnSpecialChunkInputElec(center_pos),
                            ["entities"] = {}}

    -- 1 Centrifuge (MORE THAN ENOUGH!)
    table.insert(centrifuge_chunk.entities, SpawnMagicBuilding("centrifuge", {x=center_pos.x,y=center_pos.y-10}))

    table.insert(global.omagic.centrifuges, centrifuge_chunk)
    SpecialChunkHelperText(center_pos)
end

function SpawnSiloChunk(chunk_pos)

    center_pos = GetCenterTilePosFromChunkPos(chunk_pos)

    table.insert(global.siloPosition, center_pos)
    
    RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME].index,
        {x=center_pos.x-3.25,y=center_pos.y+6},
        1,
        "You can build a silo here!",
        {0.7,0.4,0.3,0.8})

    -- Set tiles below the silo
    tiles = {}
    for dx = -6,5 do
        for dy = -6,5 do
            if (game.active_mods["oarc-restricted-build"]) then
                table.insert(tiles, {name = global.ocfg.locked_build_area_tile,
                                    position = {center_pos.x+dx, center_pos.y+dy}})
            else
                if ((dx % 2 == 0) or (dx % 2 == 0)) then
                    table.insert(tiles, {name = "concrete",
                                        position = {center_pos.x+dx, center_pos.y+dy}})
                else
                    table.insert(tiles, {name = "hazard-concrete-left",
                                        position = {center_pos.x+dx, center_pos.y+dy}})
                end
            end
        end
    end
    game.surfaces[GAME_SURFACE_NAME].set_tiles(tiles, true)
end

function SpawnMagicBuilding(entity_name, position)
    local direction = defines.direction.north
    if (entity_name == "oil-refinery") then
        direction = defines.direction.south
    end
    local magic_building = game.surfaces[GAME_SURFACE_NAME].create_entity{name=entity_name, position=position, force="neutral", direction=direction}
    magic_building.destructible = false
    magic_building.minable = false
    magic_building.operable = true
    magic_building.active = false

    global.omagic.building_total_count = global.omagic.building_total_count + 1

    return magic_building
end

function MagicFactoriesOnTick()
    MagicFurnaceOnTick()
    MagicChemplantOnTick()
    MagicRefineryOnTick()
    MagicAssemblerOnTick()
    MagicCentrifugeOnTick()
end

-- Some helpful math:
-- 94 per tick (max stack of ore in a smelter) (More like 2 or 3 ore per tick.)
-- blue belt = 45 / sec
-- 6 INPUT blue belts = 4.5 ore/tick (45 * 6 / 60) with productivity is an extra 0.9 maybe.
function MagicFurnaceOnTick()
    if not global.omagic.furnaces then return end

    for entry_idx,entry in pairs(global.omagic.furnaces) do
        
        -- Validate the entry.
        if (entry == nil) or (entry.entities == nil) or (entry.energy_input == nil) or (not entry.energy_input.valid) then
            global.omagic.furnaces[entry_idx] = nil
            log("MagicFurnaceOnTick - Magic furnace entry removed?")
            goto next_furnace_entry
        end

        local energy_share = entry.energy_input.energy/#entry.entities

        for idx,furnace in pairs(entry.entities) do

            if (furnace == nil) or (not furnace.valid) then
                global.omagic.furnaces[entry_idx] = nil
                log("MagicFurnaceOnTick - Magic furnace removed?")
                goto next_furnace_entry
            end

            local input_inv = furnace.get_inventory(defines.inventory.furnace_source)
            local input_items = input_inv.get_contents()

            -- We have something inside?
            local input_item_name = next(input_items)
            if not input_item_name then 
                goto next_furnace
            end

            -- Does the input item have a recipe?
            if not FURNACE_RECIPES[input_item_name] then 
                log("MagicFurnaceOnTick - Missing FURNACE_RECIPES?")
                goto next_furnace
            end
            local recipe = game.forces["neutral"].recipes[FURNACE_RECIPES[input_item_name].recipe_name]
            if not recipe then 
                log("MagicFurnaceOnTick - Missing neutral force recipes?")
                goto next_furnace
            end

            -- Verify 1 ingredient type and 1 product type (for furnaces)
            if (#recipe.products ~= 1) or (#recipe.ingredients ~= 1) then 
                log("MagicFurnaceOnTick - Recipe product/ingredient more than 1?")
                goto next_furnace
            end
            local recipe_ingredient = recipe.ingredients[next(recipe.ingredients)]
            local recipe_product = recipe.products[next(recipe.products)]

            local output_inv = furnace.get_inventory(defines.inventory.furnace_result)
            
            -- Can we insert at least 1 of the recipe result?
            -- if not output_inv.can_insert({name=recipe_product.name}) then goto next_furnace end
            local output_space = output_inv.get_insertable_count(recipe_product.name)
            
            -- Calculate how many times we can make the recipe.
            local ingredient_limit = math.floor(input_items[input_item_name]/recipe_ingredient.amount)
            local output_limit = math.floor(output_space/recipe_product.amount)

            -- Use shared energy pool
            local energy_limit = math.floor(energy_share/FURNACE_RECIPES[input_item_name].recipe_energy)
            local recipe_count = math.min(ingredient_limit, output_limit, energy_limit)

            -- Hit a limit somewhere?
            if (recipe_count <= 0) then goto next_furnace end

            -- Track energy usage
            entry.energy_input.energy = entry.energy_input.energy - (FURNACE_RECIPES[input_item_name].recipe_energy*recipe_count)
            furnace.surface.pollute(furnace.position, FURNACE_RECIPES[input_item_name].recipe_pollution*recipe_count)

            -- Check if it has a last_user
            if (not furnace.last_user) then
                local player_entities = game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{
                                                    position=furnace.position,
                                                    radius=10,
                                                    force={"enemy", "neutral"},
                                                    limit=1,
                                                    invert=true}
                if (player_entities and player_entities[1] and player_entities[1].last_user) then 
                    furnace.last_user = player_entities[1].last_user
                end
            end

            -- Subtract recipe count from input and Add recipe count to output
            input_inv.remove({name=recipe_ingredient.name, count=recipe_count*recipe_ingredient.amount})
            output_inv.insert({name=recipe_product.name, count=recipe_count*recipe_product.amount})
            furnace.products_finished = furnace.products_finished + recipe_count

            -- If we have a user, do the stats
            if (furnace.last_user) then
                furnace.last_user.force.item_production_statistics.on_flow(recipe_ingredient.name, -recipe_count*recipe_ingredient.amount)
                furnace.last_user.force.item_production_statistics.on_flow(recipe_product.name, recipe_count*recipe_product.amount)
            end

            ::next_furnace::
        end

        ::next_furnace_entry::
    end
end

function MagicChemplantOnTick()
    if not global.omagic.chemplants then return end

    for entry_idx,entry in pairs(global.omagic.chemplants) do

        -- Validate the entry.
        if (entry == nil) or (entry.chemplants == nil) or (entry.energy_input == nil) or (not entry.energy_input.valid) then
            global.omagic.chemplants[entry_idx] = nil
            log("MagicChemplantOnTick - Magic assembler entry removed?")
            goto next_chemplant_entry
        end

        local energy_share = entry.energy_input.energy/(#entry.chemplants + #entry.refineries)

        for idx,chemplant in pairs(entry.chemplants) do
            
            if (chemplant == nil) or (not chemplant.valid) then
                global.omagic.chemplants[idx] = nil
                log("Magic chemplant removed?")
                goto next_chemplant_entry
            end
            
            recipe = chemplant.get_recipe()

            if (not recipe) then
                goto next_chemplant -- No recipe means do nothing.
            end

            local energy_cost = recipe.energy * CHEMPLANT_ENERGY_PER_CRAFT_SECOND
            if (energy_share < energy_cost) then goto next_chemplant end -- Not enough energy!

            local input_inv = chemplant.get_inventory(defines.inventory.assembling_machine_input)
            local input_items = input_inv.get_contents()
            local input_fluids = chemplant.get_fluid_contents()

            for _,v in ipairs(recipe.ingredients) do
                if (not input_items[v.name] or (input_items[v.name] < v.amount)) then
                    if (not input_fluids[v.name] or (input_fluids[v.name] < v.amount)) then
                        goto next_chemplant -- Not enough ingredients
                    end
                end
            end

            local recipe_product = recipe.products[next(recipe.products)] -- Assume only 1 product.             

            if recipe_product.type == "fluid" then

                if ((chemplant.get_fluid_count(recipe_product.name) + recipe_product.amount) > 100) then
                    goto next_chemplant -- Not enough space for ouput
                end

                chemplant.insert_fluid({name=recipe_product.name, amount=recipe_product.amount})
                if (chemplant.last_user) then
                    chemplant.last_user.force.fluid_production_statistics.on_flow(recipe_product.name, recipe_product.amount)
                end

            -- Otherwise it must be an item type
            else

                local output_inv = chemplant.get_inventory(defines.inventory.assembling_machine_output)
            
                -- Can we insert at least 1 of the recipe result?
                if not output_inv.can_insert({name=recipe_product.name, amount=recipe_product.amount}) then goto next_chemplant end

                -- Add recipe count to output
                output_inv.insert({name=recipe_product.name, count=recipe_product.amount})
                if (chemplant.last_user) then
                    chemplant.last_user.force.item_production_statistics.on_flow(recipe_product.name, recipe_product.amount)
                end
            end

            -- Subtract ingredients from input
            for _,v in ipairs(recipe.ingredients) do
                if (input_items[v.name]) then
                    input_inv.remove({name=v.name, count=v.amount})
                    if (chemplant.last_user) then
                        chemplant.last_user.force.item_production_statistics.on_flow(v.name, -v.amount)
                    end
                elseif (input_fluids[v.name]) then
                    chemplant.remove_fluid{name=v.name, amount=v.amount}
                    if (chemplant.last_user) then
                        chemplant.last_user.force.fluid_production_statistics.on_flow(v.name, -v.amount)
                    end
                end
            end

            chemplant.products_finished = chemplant.products_finished + 1
            
            -- Track energy usage
            entry.energy_input.energy = entry.energy_input.energy - energy_cost
            chemplant.surface.pollute(chemplant.position, recipe.energy*CHEMPLANT_POLLUTION_PER_CRAFT_SECOND)


            ::next_chemplant::
        end

        ::next_chemplant_entry::
    end
end


function MagicRefineryOnTick()
    if not global.omagic.refineries then return end

    for entry_idx,entry in pairs(global.omagic.refineries) do

        -- Validate the entry.
        if (entry == nil) or (entry.refineries == nil) or (entry.energy_input == nil) or (not entry.energy_input.valid) then
            global.omagic.refineries[entry_idx] = nil
            log("MagicRefineryOnTick - Magic assembler entry removed?")
            goto next_refinery_entry
        end

        local energy_share = entry.energy_input.energy/(#entry.chemplants + #entry.refineries)

        for idx,refinery in pairs(entry.refineries) do
            
            if (refinery == nil) or (not refinery.valid) then
                global.omagic.refineries[idx] = nil
                log("Magic refinery removed?")
                goto next_refinery_entry
            end
            
            recipe = refinery.get_recipe()

            if (not recipe) then
                goto next_refinery -- No recipe means do nothing.
            end

            local energy_cost = recipe.energy * REFINERY_ENERGY_PER_CRAFT_SECOND
            if (energy_share < energy_cost) then goto next_refinery end -- Not enough energy!

            local fluidbox_copy = refinery.fluidbox

            -- If recipe is COAL LIQUEFACTION: heavy(1), steam(2), heavy(3), light(4), petro(5)
            -- if (recipe.name == "coal-liquefaction") then


            -- If recipe is Advanced OIL: water(1), crude(2), heavy(3), light(4), petro(5)
            if (recipe.name == "advanced-oil-processing") then

                if ((not refinery.fluidbox[1]) or (refinery.fluidbox[1].amount < 50)) then goto next_refinery end -- Not enough water
                if ((not refinery.fluidbox[2]) or (refinery.fluidbox[2].amount < 100)) then goto next_refinery end -- Not enough crude               
                if ((refinery.fluidbox[3]) and (refinery.fluidbox[3].amount > 25)) then goto next_refinery end -- Not enough space for heavy
                if ((refinery.fluidbox[4]) and (refinery.fluidbox[4].amount > 45)) then goto next_refinery end -- Not enough space for light
                if ((refinery.fluidbox[5]) and (refinery.fluidbox[5].amount > 55)) then goto next_refinery end -- Not enough space for petro

                refinery.remove_fluid{name="water", amount=50}
                refinery.remove_fluid{name="crude-oil", amount=100}
                refinery.insert_fluid({name="heavy-oil", amount=25})
                refinery.insert_fluid({name="light-oil", amount=45})
                refinery.insert_fluid({name="petroleum-gas", amount=55})

                if (refinery.last_user) then
                    refinery.last_user.force.fluid_production_statistics.on_flow("water", -50)
                    refinery.last_user.force.fluid_production_statistics.on_flow("crude-oil", -100)
                    refinery.last_user.force.fluid_production_statistics.on_flow("heavy-oil", 25)
                    refinery.last_user.force.fluid_production_statistics.on_flow("light-oil", 45)
                    refinery.last_user.force.fluid_production_statistics.on_flow("petroleum-gas", 55)
                end

            -- If recipe is Basic OIL:  crude(1), petro(2)
            elseif (recipe.name == "basic-oil-processing") then

                if ((not refinery.fluidbox[1]) or (refinery.fluidbox[1].amount < 100)) then goto next_refinery end -- Not enough crude
                if ((refinery.fluidbox[2]) and (refinery.fluidbox[2].amount > 45)) then goto next_refinery end -- Not enough space for petro

                refinery.remove_fluid{name="crude-oil", amount=100}
                refinery.insert_fluid({name="petroleum-gas", amount=45})

                if (refinery.last_user) then
                    refinery.last_user.force.fluid_production_statistics.on_flow("crude-oil", -100)
                    refinery.last_user.force.fluid_production_statistics.on_flow("petroleum-gas", 45)
                end

            else
                goto next_refinery -- Shouldn't hit this...
            end
           
            refinery.products_finished = refinery.products_finished + 1

            -- Track energy usage
            entry.energy_input.energy = entry.energy_input.energy - energy_cost
            refinery.surface.pollute(refinery.position, recipe.energy*REFINERY_POLLUTION_PER_CRAFT_SECOND)

            ::next_refinery::
        end

        ::next_refinery_entry::
    end
end

function MagicAssemblerOnTick()
    if not global.omagic.assemblers then return end

    for entry_idx,entry in pairs(global.omagic.assemblers) do

        -- Validate the entry.
        if (entry == nil) or (entry.entities == nil) or (entry.energy_input == nil) or (not entry.energy_input.valid) then
            global.omagic.assemblers[entry_idx] = nil
            log("MagicAssemblerOnTick - Magic assembler entry removed?")
            goto next_assembler_entry
        end

        local energy_share = entry.energy_input.energy/#entry.entities

        for idx,assembler in pairs(entry.entities) do

            if (assembler == nil) or (not assembler.valid) then
                global.omagic.assemblers[entry_idx] = nil
                log("MagicAssemblerOnTick - Magic assembler removed?")
                goto next_assembler_entry
            end
            
            recipe = assembler.get_recipe()

            if (not recipe) then
                goto next_assembler -- No recipe means do nothing.
            end

            local energy_cost = recipe.energy * ASSEMBLER3_ENERGY_PER_CRAFT_SECOND
            if (energy_share < energy_cost) then goto next_assembler end -- Not enough energy!

             -- Assume only 1 product and that it's an item!
            local recipe_product = recipe.products[next(recipe.products)]           
            if recipe_product.type ~= "item" then goto next_assembler end

            local input_inv = assembler.get_inventory(defines.inventory.assembling_machine_input)
            local input_items = input_inv.get_contents()
            local input_fluids = assembler.get_fluid_contents()

            for _,v in ipairs(recipe.ingredients) do
                if (not input_items[v.name] or (input_items[v.name] < v.amount)) then
                    if (not input_fluids[v.name] or (input_fluids[v.name] < v.amount)) then
                        goto next_assembler -- Not enough ingredients
                    end
                end
            end

            local output_inv = assembler.get_inventory(defines.inventory.assembling_machine_output)        
            if not output_inv.can_insert({name=recipe_product.name, amount=recipe_product.amount}) then
                goto next_assembler -- Can we insert the result?
            end

            -- Add recipe count to output
            output_inv.insert({name=recipe_product.name, count=recipe_product.amount})
            if (assembler.last_user) then
                assembler.last_user.force.item_production_statistics.on_flow(recipe_product.name, recipe_product.amount)
            end

            -- Subtract ingredients from input
            for _,v in ipairs(recipe.ingredients) do
                if (input_items[v.name]) then
                    input_inv.remove({name=v.name, count=v.amount})
                    if (assembler.last_user) then
                        assembler.last_user.force.item_production_statistics.on_flow(v.name, -v.amount)
                    end
                elseif (input_fluids[v.name]) then
                    assembler.remove_fluid{name=v.name, amount=v.amount}
                    if (assembler.last_user) then
                        assembler.last_user.force.fluid_production_statistics.on_flow(v.name, -v.amount)
                    end
                end
            end

            -- Track energy usage
            entry.energy_input.energy = entry.energy_input.energy - energy_cost
            assembler.surface.pollute(assembler.position, recipe.energy*ASSEMBLER3_POLLUTION_PER_CRAFT_SECOND)

            assembler.products_finished = assembler.products_finished + 1

            ::next_assembler::
        end

        ::next_assembler_entry::
    end
end

function MagicCentrifugeOnTick()
    if not global.omagic.centrifuges then return end

    for entry_idx,entry in pairs(global.omagic.centrifuges) do
        
        -- Validate the entry.
        if (entry == nil) or (entry.entities == nil) or (entry.energy_input == nil) or (not entry.energy_input.valid) then
            global.omagic.centrifuges[entry_idx] = nil
            log("MagicCentrifugeOnTick - Magic centrifuge entry removed?")
            goto next_centrifuge_entry
        end

        local energy_share = entry.energy_input.energy/#entry.entities

        for idx,centrifuge in pairs(entry.entities) do

            if (centrifuge == nil) or (not centrifuge.valid) then
                global.omagic.centrifuges[entry_idx] = nil
                log("MagicCentrifugeOnTick - Magic centrifuge removed?")
                goto next_centrifuge_entry
            end
           
            recipe = centrifuge.get_recipe()

            if (not recipe) then
                goto next_centrifuge -- No recipe means do nothing.
            end

            local energy_cost = recipe.energy * CENTRIFUGE_ENERGY_PER_CRAFT_SECOND
            if (energy_share < energy_cost) then goto next_centrifuge end -- Not enough energy!

            local input_inv = centrifuge.get_inventory(defines.inventory.assembling_machine_input)
            local input_items = input_inv.get_contents()

            for _,v in ipairs(recipe.ingredients) do
                if (not input_items[v.name] or (input_items[v.name] < v.amount)) then
                    goto next_centrifuge -- Not enough ingredients
                end
            end

            local output_inv = centrifuge.get_inventory(defines.inventory.assembling_machine_output)     

            local output_item, output_count

            -- 10 uranium ore IN
            -- .993 uranium-238 and .007 uranium-235 OUT
            if (recipe.name == "uranium-processing") then

                local rand_chance = math.random()

                output_count = 1
                if (rand_chance <= .007) then
                    output_item = "uranium-235"
                else
                    output_item = "uranium-238"
                end

                -- Check if we can insert at least 1 of BOTH.
                if not output_inv.can_insert({name="uranium-235", amount=output_count}) then
                    goto next_centrifuge
                end
                if not output_inv.can_insert({name= "uranium-238", amount=output_count}) then
                    goto next_centrifuge
                end

                output_inv.insert({name=output_item, count=output_count})
                if (centrifuge.last_user) then
                    centrifuge.last_user.force.item_production_statistics.on_flow(output_item, output_count)
                end

                for _,v in ipairs(recipe.ingredients) do
                    if (input_items[v.name]) then
                        input_inv.remove({name=v.name, count=v.amount})
                        if (centrifuge.last_user) then
                            centrifuge.last_user.force.item_production_statistics.on_flow(v.name, -v.amount)
                        end
                    end
                end
            else
                goto next_centrifuge -- Unsupported!
            end

            centrifuge.products_finished = centrifuge.products_finished + 1

            -- Track energy usage
            entry.energy_input.energy = entry.energy_input.energy - energy_cost
            centrifuge.surface.pollute(centrifuge.position, recipe.energy*CENTRIFUGE_POLLUTION_PER_CRAFT_SECOND)

            ::next_centrifuge::
        end

        ::next_centrifuge_entry::
    end
end

COIN_MULTIPLIER = 2

COIN_GENERATION_CHANCES = {
    ["small-biter"] = 0.01,
    ["medium-biter"] = 0.02,
    ["big-biter"] = 0.05,
    ["behemoth-biter"] = 1,

    ["small-spitter"] = 0.01,
    ["medium-spitter"] = 0.02,
    ["big-spitter"] = 0.05,
    ["behemoth-spitter"] = 1,

    ["small-worm-turret"] = 5,
    ["medium-worm-turret"] = 10,
    ["big-worm-turret"] = 15,
    ["behemoth-worm-turret"] = 25,

    ["biter-spawner"] = 20,
    ["spitter-spawner"] = 20,
}

function CoinsFromEnemiesOnPostEntityDied(event)
    if (not event.prototype or not event.prototype.name) then return end

    local coin_chance = nil
    if (COIN_GENERATION_CHANCES[event.prototype.name]) then
        coin_chance = COIN_GENERATION_CHANCES[event.prototype.name]
    end

    if (coin_chance) then
        DropCoins(event.position, coin_chance, event.force)
    end
end

-- Drop coins, force is optional, decon is applied if force is not nil.
function DropCoins(pos, count, force)

    local drop_amount = 0

    -- If count is less than 1, it represents a probability to drop a single coin
    if (count < 1) then
        if (math.random() < count) then
            drop_amount = 1
        end

    -- If count is 1 or more, it represents a probability to drop at least that amount and up to 3x
    elseif (count >= 1) then
        drop_amount = math.random(count,count*COIN_MULTIPLIER)
    end

    if drop_amount == 0 then return end
    game.surfaces[GAME_SURFACE_NAME].spill_item_stack(pos, {name="coin", count=math.floor(drop_amount)}, true, force, false) -- Set nil to force to auto decon.
end