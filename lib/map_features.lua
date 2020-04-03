-- map_features.lua
-- April 2020
-- Oarc's clone of whistlestop factories maybe?

-- Generic Utility Includes
require("lib/oarc_utils")


POWER_USAGE_SCALING_FACTOR = 2

FURNACE_RECIPES = {
    ["iron-ore"] = {recipe_name = "iron-plate", recipe_energy = 288000*POWER_USAGE_SCALING_FACTOR},
    ["copper-ore"] = {recipe_name = "copper-plate", recipe_energy = 288000*POWER_USAGE_SCALING_FACTOR},
    ["iron-plate"] = {recipe_name = "steel-plate", recipe_energy = 1440000*POWER_USAGE_SCALING_FACTOR}, 
    ["stone"] = {recipe_name = "stone-brick", recipe_energy = 288000*POWER_USAGE_SCALING_FACTOR},
}

ENEMY_WORM_TURRETS =
{
    [0] = "small-worm-turret",
    [1] = "medium-worm-turret",
    [2] = "big-worm-turret"
}

function MagicFurnaceInit()

    -- Neutral force requires recipes so that furnaces can smelt steel for example.
    game.forces["neutral"].enable_all_recipes()

    -- Buff the enemy force a bit?
    game.forces["enemy"].technologies["physical-projectile-damage-1"].researched = true
    game.forces["enemy"].technologies["weapon-shooting-speed-1"].researched = true

    MagicFurnaceChunkGenerator()
end

function MagicFurnaceChunkGenerator()
    global.magic_smelter_positions = {}
    for r=40,350,55 do
        local random_angle_offset = math.random(0, math.pi * 2)
        local num_smelters = math.ceil((r/10))

        for i=1,num_smelters do
            local theta = ((math.pi * 2) / num_smelters);
            local angle = (theta * i) + random_angle_offset;

            local tx = (r*CHUNK_SIZE * math.cos(angle)) + math.random(-CHUNK_SIZE*2, CHUNK_SIZE*2)
            local ty = (r*CHUNK_SIZE * math.sin(angle)) + math.random(-CHUNK_SIZE*2, CHUNK_SIZE*2)

            table.insert(global.magic_smelter_positions, {x=math.floor(tx), y=math.floor(ty)})
            game.surfaces[GAME_SURFACE_NAME].request_to_generate_chunks({x=math.floor(tx), y=math.floor(ty)}, 1)
            log("Magic furnace position: " .. tx .. ", " .. ty .. ", " .. angle)
        end
    end
end

function MagicalFurnaceSpawnAll()
    for _,pos in pairs(global.magic_smelter_positions) do
        
        -- Remove any entities in the area.
        for _, entity in pairs(game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{position = pos, radius = 20}) do
            entity.destroy()
        end

        -- Place landfill underneath
        local dirtTiles = {}
        for i=pos.x-8,pos.x+8,1 do
            for j=pos.y-8,pos.y+8,1 do
                table.insert(dirtTiles, {name = "landfill", position ={i,j}})
            end
        end
        game.surfaces[GAME_SURFACE_NAME].set_tiles(dirtTiles)

        -- Spawn furnace.
        SpawnMagicFurnace(pos)

        -- Put some enemies nearby
        -- SpawnEnemyTurret({x=pos.x-5,y=pos.y-5})
        -- SpawnEnemyTurret({x=pos.x-5,y=pos.y+6})
        -- SpawnEnemyTurret({x=pos.x+6,y=pos.y-5})
        -- SpawnEnemyTurret({x=pos.x+6,y=pos.y+6})
        game.surfaces[GAME_SURFACE_NAME].create_entity{name = ENEMY_WORM_TURRETS[math.random(0,2)], position = {x=pos.x-5,y=pos.y-5}, force = "enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name = ENEMY_WORM_TURRETS[math.random(0,2)], position = {x=pos.x-5,y=pos.y+6}, force = "enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name = ENEMY_WORM_TURRETS[math.random(0,2)], position = {x=pos.x+6,y=pos.y-5}, force = "enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name = ENEMY_WORM_TURRETS[math.random(0,2)], position = {x=pos.x+6,y=pos.y+6}, force = "enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name="biter-spawner", position={x=pos.x-5,y=pos.y}, force="enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name="spitter-spawner", position={x=pos.x+1,y=pos.y-5}, force="enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name="biter-spawner", position={x=pos.x+6,y=pos.y}, force="enemy"}
        game.surfaces[GAME_SURFACE_NAME].create_entity{name="spitter-spawner", position={x=pos.x+1,y=pos.y+5}, force="enemy"}

        -- Helper text
        RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME].index,
            {x=pos.x-4,y=pos.y+2},
            1,
            "Consumes energy from sharing system.",
            {0.7,0.4,0.3,0.8})
        RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME].index,
            {x=pos.x-3.5,y=pos.y+2.5},
            1,
            "Supply energy at any player spawn.",
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

function MagicFurnaceDelayedSpawner()

    -- Delay the creation of the magical outposts so we place them on already generated lands.
    if (not global.oarc_magic_smelters_generated and (game.tick >= 10*TICKS_PER_SECOND)) then
        game.surfaces[GAME_SURFACE_NAME].force_generate_chunk_requests() -- Block and generate all to be sure.
        global.oarc_magic_smelters_generated = true

        MagicalFurnaceSpawnAll()

        log("Magical furnaces generated!")
        SendBroadcastMsg("Magical furnaces are now available!")
    end
end

function SpawnEnemyTurret(pos)

    local turret = game.surfaces[GAME_SURFACE_NAME].create_entity{name="gun-turret", position=pos, force="enemy"}
    local turret_inv = turret.get_inventory(defines.inventory.turret_ammo)
    turret_inv.insert({name="uranium-rounds-magazine", count=200})

end


function SpawnMagicFurnace(pos)

    local magic_furnace = game.surfaces[GAME_SURFACE_NAME].create_entity{name="electric-furnace", position=pos, force="neutral"}
    magic_furnace.destructible = false
    magic_furnace.minable = false
    magic_furnace.operable = true
    magic_furnace.active = false

    if global.magic_furnaces == nil then
        global.magic_furnaces = {}
    end

    table.insert(global.magic_furnaces, magic_furnace)
end

function MagicFurnaceOnTick()

    MagicFurnaceDelayedSpawner()

    if not global.magic_furnaces then return end
    local number_furnaces = table_size(global.magic_furnaces)
    local energy_used = 0

    for idx,furnace in pairs(global.magic_furnaces) do
        
        if (furnace == nil) or (not furnace.valid) then
            global.magic_furnaces[idx] = nil
            log("Magic furnace removed?")
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
            log("Missing FURNACE_RECIPES?")
            SendBroadcastMsg("Missing FURNACE_RECIPES?")
            goto continue
        end
        local recipe = game.forces["neutral"].recipes[FURNACE_RECIPES[input_item_name].recipe_name]
        if not recipe then 
            log("Missing neutral force recipes?")
            SendBroadcastMsg("Missing neutral force recipes?")
            goto continue
        end

        -- Verify 1 ingredient tyep and 1 product type (for furnace)
        if (#recipe.products ~= 1) or (#recipe.ingredients ~= 1) then 
            log("Recipe product/ingredient more than 1?")
            SendBroadcastMsg("Recipe product/ingredient more than 1?")
            goto continue
        end
        local recipe_ingredient = recipe.ingredients[next(recipe.ingredients)]
        local recipe_product = recipe.products[next(recipe.products)]

        local output_inv = furnace.get_inventory(defines.inventory.furnace_result)
        
        -- Can we insert at least 1 of the recipe result?
        if not output_inv.can_insert({name=recipe_product.name}) then goto continue end
        local output_space = output_inv.get_insertable_count(recipe_product.name)
        
        -- Calculate how many times we can make the recipe.
        local max_count_ingredients = math.floor(input_items[input_item_name]/recipe_ingredient.amount)
        local max_output = math.floor(output_space/recipe_product.amount)

        -- Use shared energy pool?
        if not global.shared_energy_stored then goto continue end
        local energy_per_recipe = FURNACE_RECIPES[input_item_name].recipe_energy
        local energy_share = global.shared_energy_stored/number_furnaces
        local max_recipes_for_energy = math.floor(energy_share/energy_per_recipe)
        local min_max_count = math.min(max_count_ingredients, max_output, max_recipes_for_energy)

        -- Hit a limit somewhere?
        if (min_max_count <= 0) then goto continue end

        -- Track energy usage
        energy_used = energy_used + (energy_per_recipe*min_max_count)

        -- Subtract recipe count from input
        input_inv.remove({name=recipe_ingredient.name, count=min_max_count*recipe_ingredient.amount})

        -- Add recipe count to output
        output_inv.insert({name=recipe_product.name, count=min_max_count*recipe_product.amount})

        ::continue::
    end

    -- Subtract energy
    global.shared_energy_stored = global.shared_energy_stored - energy_used

    if (not global.magic_smelter_energy_history) then global.magic_smelter_energy_history = {} end
    global.magic_smelter_energy_history[game.tick % 60] = energy_used
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
    game.surfaces[GAME_SURFACE_NAME].spill_item_stack(pos, {name="coin", count=math.floor(drop_amount)}, true, force, false)
end