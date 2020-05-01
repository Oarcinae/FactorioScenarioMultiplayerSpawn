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
    ["iron-ore"] = {recipe_name = "iron-plate", recipe_energy = 3.2*FURNACE_ENERGY_PER_CRAFT_SECOND},
    ["copper-ore"] = {recipe_name = "copper-plate", recipe_energy = 3.2*FURNACE_ENERGY_PER_CRAFT_SECOND},
    ["iron-plate"] = {recipe_name = "steel-plate", recipe_energy = 16*FURNACE_ENERGY_PER_CRAFT_SECOND}, 
    ["stone"] = {recipe_name = "stone-brick", recipe_energy = 3.2*FURNACE_ENERGY_PER_CRAFT_SECOND},
}

-- The chemplants/refineries/assemblers lookup their own recipes since they can be set by the player.
CHEMPLANT_ENERGY_PER_CRAFT_SECOND = 210000 * POWER_USAGE_SCALING_FACTOR
REFINERY_ENERGY_PER_CRAFT_SECOND = 420000 * POWER_USAGE_SCALING_FACTOR
ASSEMBLER3_ENERGY_PER_CRAFT_SECOND = (375000 / 1.25) * POWER_USAGE_SCALING_FACTOR

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
    -- ["coal-liquefaction"] = true,

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

    global.magic_building_total_count = 0
    global.magic_factory_energy_history = {}
    global.magic_factory_positions = {}
    global.magic_furnaces = {}
    global.magic_chemplants = {}
    global.magic_refineries = {}
    global.magic_assemblers = {}

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
                
                table.insert(global.magic_factory_positions, {x=chunk_x, y=chunk_y})
                game.surfaces[GAME_SURFACE_NAME].request_to_generate_chunks(GetCenterTilePosFromChunkPos({x=chunk_x, y=chunk_y}), 0)
                log("Magic furnace position: " .. chunk_x .. ", " .. chunk_y .. ", " .. angle)
            else
                log("Magic furnace collided with silo location?" .. chunk_x .. ", " .. chunk_y)
            end
        end
    end

    SendBroadcastMsg("Number magic chunks: " .. #global.magic_factory_positions)
end

function IndicateClosestMagicChunk(player)

    if (not player or not player.character) then return end

    local closest_chunk = GetClosestPosFromTable(GetChunkPosFromTilePos(player.character.position), global.magic_factory_positions)
    local target_pos = GetCenterTilePosFromChunkPos(closest_chunk)

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
    local next_choice = math.random(1,3)
    for _,chunk_pos in pairs(global.magic_factory_positions) do
        
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

        -- Spawn Magic Stuff
        if (next_choice == 1) then
            SpawnFurnaceChunk(chunk_pos)
            next_choice = 2
        elseif (next_choice == 2) then
            SpawnOilRefineryChunk(chunk_pos)
            next_choice = 3
        elseif (next_choice == 3) then
            SpawnAssemblyChunk(chunk_pos)
            next_choice = 1
        end

        -- Yay colored tiles
        CreateFixedColorTileArea(game.surfaces[GAME_SURFACE_NAME], 
                                {left_top = {x=c_area.left_top.x+2, y=c_area.left_top.y+2},
                                    right_bottom = {x=c_area.right_bottom.x-2, y=c_area.right_bottom.y-2}},
                                "black")

        -- Put some enemies nearby
        -- SpawnEnemyTurret({x=pos.x-5,y=pos.y-5})
        -- SpawnEnemyTurret({x=pos.x-5,y=pos.y+6})
        -- SpawnEnemyTurret({x=pos.x+6,y=pos.y-5})
        -- SpawnEnemyTurret({x=pos.x+6,y=pos.y+6})
        game.surfaces[GAME_SURFACE_NAME].create_entity{name = ENEMY_WORM_TURRETS[math.random(0,2)], position = {x=pos.x-10,y=pos.y-10}, force = "enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name = ENEMY_WORM_TURRETS[math.random(0,2)], position = {x=pos.x-10,y=pos.y+11}, force = "enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name = ENEMY_WORM_TURRETS[math.random(0,2)], position = {x=pos.x+11,y=pos.y-10}, force = "enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name = ENEMY_WORM_TURRETS[math.random(0,2)], position = {x=pos.x+11,y=pos.y+11}, force = "enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name="biter-spawner", position={x=pos.x-12,y=pos.y}, force="enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name="spitter-spawner", position={x=pos.x+1,y=pos.y-12}, force="enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name="biter-spawner", position={x=pos.x+13,y=pos.y}, force="enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name="spitter-spawner", position={x=pos.x+1,y=pos.y+12}, force="enemy"}

        -- Helper text
        RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME].index,
            {x=pos.x-4,y=pos.y-1},
            1,
            "Consumes energy from sharing system.",
            {0.7,0.4,0.3,0.8})
        RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME].index,
            {x=pos.x-3.5,y=pos.y},
            1,
            "Supply energy at any player spawn.",
            {0.7,0.4,0.3,0.8})
        RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME].index,
            {x=pos.x-4.5,y=pos.y+1},
            1,
            "Modules/beacons DO NOT have any effect!",
            {0.7,0.4,0.3,0.8})

        -- Make it safe from regrowth
        if global.ocfg.enable_regrowth then
            remote.call("oarc_regrowth",
                            "area_offlimits_tilepos",
                            game.surfaces[GAME_SURFACE_NAME].index,
                            pos,
                            1)
        end
    end
end

-- function MagicFurnaceDelayedSpawner()

--     -- Delay the creation of the magical outposts so we place them on already generated lands.
--     if (not global.oarc_magic_smelters_generated and (game.tick >= 10*TICKS_PER_SECOND)) then
--         game.surfaces[GAME_SURFACE_NAME].force_generate_chunk_requests() -- Block and generate all to be sure.
--         global.oarc_magic_smelters_generated = true

--         MagicalFactorySpawnAll()

--         log("Magical furnaces generated!")
--         SendBroadcastMsg("Magical furnaces are now available!")
--     end
-- end

function SpawnEnemyTurret(pos)

    local turret = game.surfaces[GAME_SURFACE_NAME].create_entity{name="gun-turret", position=pos, force="enemy"}
    local turret_inv = turret.get_inventory(defines.inventory.turret_ammo)
    turret_inv.insert({name="uranium-rounds-magazine", count=200})

end


function SpawnFurnaceChunk(chunk_pos)

    center_pos = GetCenterTilePosFromChunkPos(chunk_pos)

    -- 4 Furnaces
    SpawnMagicFurnace({x=center_pos.x-5,y=center_pos.y-5})
    SpawnMagicFurnace({x=center_pos.x+5,y=center_pos.y-5})
    SpawnMagicFurnace({x=center_pos.x-5,y=center_pos.y+5})
    SpawnMagicFurnace({x=center_pos.x+5,y=center_pos.y+5})

end

function SpawnOilRefineryChunk(chunk_pos)

    center_pos = GetCenterTilePosFromChunkPos(chunk_pos)

    -- Refineries
    SpawnMagicRefinery({x=center_pos.x-5,y=center_pos.y-8})
    SpawnMagicRefinery({x=center_pos.x+5,y=center_pos.y-8})

    -- Chem Plants
    SpawnMagicChemicalPlant({x=center_pos.x-10,y=center_pos.y+8})
    SpawnMagicChemicalPlant({x=center_pos.x-6,y=center_pos.y+8})
    SpawnMagicChemicalPlant({x=center_pos.x-2,y=center_pos.y+8})
    SpawnMagicChemicalPlant({x=center_pos.x+2,y=center_pos.y+8})
    SpawnMagicChemicalPlant({x=center_pos.x+6,y=center_pos.y+8})
    SpawnMagicChemicalPlant({x=center_pos.x+10,y=center_pos.y+8})

end

function SpawnAssemblyChunk(chunk_pos)

    center_pos = GetCenterTilePosFromChunkPos(chunk_pos)

    -- 4 Assemblers
    SpawnMagicAssembler({x=center_pos.x-5,y=center_pos.y-5})
    SpawnMagicAssembler({x=center_pos.x+5,y=center_pos.y-5})
    SpawnMagicAssembler({x=center_pos.x-5,y=center_pos.y+5})
    SpawnMagicAssembler({x=center_pos.x+5,y=center_pos.y+5})
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

    global.magic_building_total_count = global.magic_building_total_count + 1

    return magic_building
end

function SpawnMagicFurnace(pos)
    table.insert(global.magic_furnaces, SpawnMagicBuilding("electric-furnace",  pos))
end

function SpawnMagicChemicalPlant(pos)
    table.insert(global.magic_chemplants, SpawnMagicBuilding("chemical-plant",  pos))
end

function SpawnMagicRefinery(pos)
    table.insert(global.magic_refineries, SpawnMagicBuilding("oil-refinery",  pos))
end

function SpawnMagicAssembler(pos)
    table.insert(global.magic_assemblers, SpawnMagicBuilding("assembling-machine-3",  pos))
end

function MagicFactoriesOnTick()
    global.magic_factory_energy_history[game.tick % 60] = 0

    MagicFurnaceOnTick()
    MagicChemplantOnTick()
    MagicRefineryOnTick()
    MagicAssemblerOnTick()
end

function MagicFurnaceOnTick()

    if not global.magic_furnaces then return end
    local energy_used = 0
    local energy_share = global.shared_energy_stored/global.magic_building_total_count

    for idx,furnace in pairs(global.magic_furnaces) do
        
        if (furnace == nil) or (not furnace.valid) then
            global.magic_furnaces[idx] = nil
            log("MagicFurnaceOnTick - Magic furnace removed?")
            goto continue
        end
        
        local input_inv = furnace.get_inventory(defines.inventory.furnace_source)
        local input_items = input_inv.get_contents()

        -- We have something inside?
        local input_item_name = next(input_items)
        if not input_item_name then 
            goto continue
        end

        -- Does the input item have a recipe?
        if not FURNACE_RECIPES[input_item_name] then 
            log("MagicFurnaceOnTick - Missing FURNACE_RECIPES?")
            goto continue
        end
        local recipe = game.forces["neutral"].recipes[FURNACE_RECIPES[input_item_name].recipe_name]
        if not recipe then 
            log("MagicFurnaceOnTick - Missing neutral force recipes?")
            goto continue
        end

        -- Verify 1 ingredient type and 1 product type (for furnaces)
        if (#recipe.products ~= 1) or (#recipe.ingredients ~= 1) then 
            log("MagicFurnaceOnTick - Recipe product/ingredient more than 1?")
            goto continue
        end
        local recipe_ingredient = recipe.ingredients[next(recipe.ingredients)]
        local recipe_product = recipe.products[next(recipe.products)]

        local output_inv = furnace.get_inventory(defines.inventory.furnace_result)
        
        -- Can we insert at least 1 of the recipe result?
        -- if not output_inv.can_insert({name=recipe_product.name}) then goto continue end
        local output_space = output_inv.get_insertable_count(recipe_product.name)
        
        -- Calculate how many times we can make the recipe.
        local ingredient_limit = math.floor(input_items[input_item_name]/recipe_ingredient.amount)
        local output_limit = math.floor(output_space/recipe_product.amount)

        -- Use shared energy pool
        local energy_limit = math.floor(energy_share/FURNACE_RECIPES[input_item_name].recipe_energy)
        local recipe_count = math.min(ingredient_limit, output_limit, energy_limit)

        -- Hit a limit somewhere?
        if (recipe_count <= 0) then goto continue end

        -- Track energy usage
        energy_used = energy_used + (FURNACE_RECIPES[input_item_name].recipe_energy*recipe_count)

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

        ::continue::
    end

    -- Subtract energy
    global.shared_energy_stored = global.shared_energy_stored - energy_used

    if (not global.magic_factory_energy_history) then global.magic_factory_energy_history = {} end
    global.magic_factory_energy_history[game.tick % 60] = global.magic_factory_energy_history[game.tick % 60] + energy_used
end

function MagicChemplantOnTick()

    if not global.magic_chemplants then return end
    local energy_used = 0
    local energy_share = global.shared_energy_stored/global.magic_building_total_count

    for idx,chemplant in pairs(global.magic_chemplants) do
        
        if (chemplant == nil) or (not chemplant.valid) then
            global.magic_chemplants[idx] = nil
            log("Magic chemplant removed?")
            goto continue
        end
        
        recipe = chemplant.get_recipe()

        if (not recipe) then
            goto continue -- No recipe means do nothing.
        end

        local energy_cost = recipe.energy * CHEMPLANT_ENERGY_PER_CRAFT_SECOND
        if (energy_share < energy_cost) then goto continue end -- Not enough energy!

        local input_inv = chemplant.get_inventory(defines.inventory.assembling_machine_input)
        local input_items = input_inv.get_contents()
        local input_fluids = chemplant.get_fluid_contents()

        for _,v in ipairs(recipe.ingredients) do
            if (not input_items[v.name] or (input_items[v.name] < v.amount)) then
                if (not input_fluids[v.name] or (input_fluids[v.name] < v.amount)) then
                    goto continue -- Not enough ingredients
                end
            end
        end

        local recipe_product = recipe.products[next(recipe.products)] -- Assume only 1 product.             

        if recipe_product.type == "fluid" then

            if ((chemplant.get_fluid_count(recipe_product.name) + recipe_product.amount) > 100) then
                goto continue -- Not enough space for ouput
            end

            chemplant.insert_fluid({name=recipe_product.name, amount=recipe_product.amount})
            if (chemplant.last_user) then
                chemplant.last_user.force.fluid_production_statistics.on_flow(recipe_product.name, recipe_product.amount)
            end

        -- Otherwise it must be an item type
        else

            local output_inv = chemplant.get_inventory(defines.inventory.assembling_machine_output)
        
            -- Can we insert at least 1 of the recipe result?
            if not output_inv.can_insert({name=recipe_product.name, amount=recipe_product.amount}) then goto continue end

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
        energy_used = energy_used + energy_cost

        ::continue::
    end

    -- Subtract energy
    global.shared_energy_stored = global.shared_energy_stored - energy_used

    if (not global.magic_factory_energy_history) then global.magic_factory_energy_history = {} end
    global.magic_factory_energy_history[game.tick % 60] = global.magic_factory_energy_history[game.tick % 60] + energy_used
end


function MagicRefineryOnTick()

    if not global.magic_refineries then return end
    local energy_used = 0
    local energy_share = global.shared_energy_stored/global.magic_building_total_count

    for idx,refinery in pairs(global.magic_refineries) do
        
        if (refinery == nil) or (not refinery.valid) then
            global.magic_refineries[idx] = nil
            log("Magic refinery removed?")
            goto continue
        end
        
        recipe = refinery.get_recipe()

        if (not recipe) then
            goto continue -- No recipe means do nothing.
        end

        local energy_cost = recipe.energy * REFINERY_ENERGY_PER_CRAFT_SECOND
        if (energy_share < energy_cost) then goto continue end -- Not enough energy!

        local fluidbox_copy = refinery.fluidbox

        -- If recipe is COAL LIQUEFACTION: heavy(1), steam(2), heavy(3), light(4), petro(5)
        -- if (recipe.name == "coal-liquefaction") then


        -- If recipe is Advanced OIL: water(1), crude(2), heavy(3), light(4), petro(5)
        if (recipe.name == "advanced-oil-processing") then

            if ((not refinery.fluidbox[1]) or (refinery.fluidbox[1].amount < 50)) then goto continue end -- Not enough water
            if ((not refinery.fluidbox[2]) or (refinery.fluidbox[2].amount < 100)) then goto continue end -- Not enough crude               
            if ((refinery.fluidbox[3]) and (refinery.fluidbox[3].amount > 25)) then goto continue end -- Not enough space for heavy
            if ((refinery.fluidbox[4]) and (refinery.fluidbox[4].amount > 45)) then goto continue end -- Not enough space for light
            if ((refinery.fluidbox[5]) and (refinery.fluidbox[5].amount > 55)) then goto continue end -- Not enough space for petro

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

            if ((not refinery.fluidbox[1]) or (refinery.fluidbox[1].amount < 100)) then goto continue end -- Not enough crude
            if ((refinery.fluidbox[2]) and (refinery.fluidbox[2].amount > 45)) then goto continue end -- Not enough space for petro

            refinery.remove_fluid{name="crude-oil", amount=100}
            refinery.insert_fluid({name="petroleum-gas", amount=45})

            if (refinery.last_user) then
                refinery.last_user.force.fluid_production_statistics.on_flow("crude-oil", -100)
                refinery.last_user.force.fluid_production_statistics.on_flow("petroleum-gas", 45)
            end

        else
            goto continue -- Shouldn't hit this...
        end
       
        refinery.products_finished = refinery.products_finished + 1

        -- Track energy usage
        energy_used = energy_used + energy_cost

        ::continue::
    end

    -- Subtract energy
    global.shared_energy_stored = global.shared_energy_stored - energy_used

    if (not global.magic_factory_energy_history) then global.magic_factory_energy_history = {} end
    global.magic_factory_energy_history[game.tick % 60] = global.magic_factory_energy_history[game.tick % 60] + energy_used
end

function MagicAssemblerOnTick()

    if not global.magic_assemblers then return end
    local energy_used = 0
    local energy_share = global.shared_energy_stored/global.magic_building_total_count

    for idx,assembler in pairs(global.magic_assemblers) do
        
        if (assembler == nil) or (not assembler.valid) then
            global.magic_assemblers[idx] = nil
            log("Magic assembler removed?")
            goto continue
        end
        
        recipe = assembler.get_recipe()

        if (not recipe) then
            goto continue -- No recipe means do nothing.
        end

        local energy_cost = recipe.energy * ASSEMBLER3_ENERGY_PER_CRAFT_SECOND
        if (energy_share < energy_cost) then goto continue end -- Not enough energy!

         -- Assume only 1 product and that it's an item!
        local recipe_product = recipe.products[next(recipe.products)]           
        if recipe_product.type ~= "item" then goto continue end

        local input_inv = assembler.get_inventory(defines.inventory.assembling_machine_input)
        local input_items = input_inv.get_contents()
        local input_fluids = assembler.get_fluid_contents()

        for _,v in ipairs(recipe.ingredients) do
            if (not input_items[v.name] or (input_items[v.name] < v.amount)) then
                if (not input_fluids[v.name] or (input_fluids[v.name] < v.amount)) then
                    goto continue -- Not enough ingredients
                end
            end
        end

        local output_inv = assembler.get_inventory(defines.inventory.assembling_machine_output)        
        if not output_inv.can_insert({name=recipe_product.name, amount=recipe_product.amount}) then
            goto continue -- Can we insert the result?
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
        
        assembler.products_finished = assembler.products_finished + 1

        -- Track energy usage
        energy_used = energy_used + energy_cost

        ::continue::
    end

    -- Subtract energy
    global.shared_energy_stored = global.shared_energy_stored - energy_used

    if (not global.magic_factory_energy_history) then global.magic_factory_energy_history = {} end
    global.magic_factory_energy_history[game.tick % 60] = global.magic_factory_energy_history[game.tick % 60] + energy_used
end

COIN_GENERATION_CHANCES = {
    ["small-biter"] = 0.01,
    ["medium-biter"] = 0.05,
    ["big-biter"] = 0.15,
    ["behemoth-biter"] = 0.50,

    ["small-spitter"] = 0.02,
    ["medium-spitter"] = 0.05,
    ["big-spitter"] = 0.20,
    ["behemoth-spitter"] = 0.50,

    ["small-worm-turret"] = 0.10,
    ["medium-worm-turret"] = 0.20,
    ["big-worm-turret"] = 0.50,
    ["behemoth-worm-turret"] = 1.00,

    ["biter-spawner"] = 10,
    ["spitter-spawner"] = 10,
}

function CoinsFromEnemiesOnEntityDied(event)
    if (not event.entity) then return end
    if (event.entity.force.name ~= "enemy") then return end

    for k,v in pairs(COIN_GENERATION_CHANCES) do
        if (k == event.entity.name) then
            DropCoins(event.entity.position, v, event.force)
            return
        end
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

    -- If count is 1 or more, it represents a probability to drop between 1 and count coins.
    elseif (count >= 1) then
        drop_amount = math.random(1,count)
    end

    if drop_amount == 0 then return end
    game.surfaces[GAME_SURFACE_NAME].spill_item_stack(pos, {name="coin", count=math.floor(drop_amount)}, true, nil, false) -- Set nil to force to auto decon.
end