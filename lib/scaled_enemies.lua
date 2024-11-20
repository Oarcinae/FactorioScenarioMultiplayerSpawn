-- This handles scaling enemies in a few different ways to make sure that all players can have a reasonable experience
-- even if they join the game late or are playing at a slower pace.

-- TODO: Plan for new enemies in space DLC.
-- TODO: Plan for new enemies in space DLC.
-- TODO: Plan for new enemies in space DLC.

ENEMY_FORCES_NAMES = { "enemy" }
ENEMY_FORCES_NAMES_INCL_NEUTRAL = { "enemy", "neutral" }


-- gleba-spawner-small
-- gleba-spawner

-- yumako-tree
-- copper-stromatolite
-- jellystem
-- yumako-tree

---Downgrades worms based on distance from origin and near/far spawn distances.
---This helps make sure worms aren't too overwhelming even at these further spawn distances.
---@param event EventData.on_chunk_generated
---@return nil
function DowngradeWormsDistanceBasedOnChunkGenerate(event)
    ---@type OarcConfigGameplaySettings
    local gameplay = storage.ocfg.gameplay

    if (util.distance({ x = 0, y = 0 }, event.area.left_top) < (gameplay.near_spawn_distance * CHUNK_SIZE)) then
        DowngradeWormsInArea(event.surface, event.area, 50, 100, 100) -- 50% small, 50% medium
    elseif (util.distance({ x = 0, y = 0 }, event.area.left_top) < (gameplay.far_spawn_distance * CHUNK_SIZE)) then
        DowngradeWormsInArea(event.surface, event.area, 25, 50, 95)   -- 25% small, 25% medium, 45% big, 5% behemoth
    elseif (util.distance({ x = 0, y = 0 }, event.area.left_top) < (gameplay.far_spawn_distance * CHUNK_SIZE * 1.5)) then
        DowngradeWormsInArea(event.surface, event.area, 0, 40, 85)    -- 40% medium, 45% big, 15% behemoth
    else
        DowngradeWormsInArea(event.surface, event.area, 0, 20, 50)    -- 20% medium, 30% big, 50% behemoth
    end
end

---Downgrades enemies based on distance from origin and near/far spawn distances.
---@param event EventData.on_chunk_generated
---@return nil
function DowngradeAndReduceEnemiesOnChunkGenerate(event)
    local surface = event.surface
    local chunk_area = event.area

    local closest_spawn = GetClosestUniqueSpawn(surface.name, chunk_area.left_top)
    if (closest_spawn == nil) then return end

    local spawn_config --[[@as OarcConfigSpawn]] = storage.ocfg.surfaces_config[surface.name].spawn_config
    local chunkAreaCenter = {
        x = chunk_area.left_top.x + (CHUNK_SIZE / 2),
        y = chunk_area.left_top.y + (CHUNK_SIZE / 2)
    }


    
    -- TODO: Change this lookup to be done once during surface init.
    local nauvis_enemies = surface.map_gen_settings.autoplace_controls["enemy-base"] ~= nil
    local gleba_enemies = surface.map_gen_settings.autoplace_controls["gleba_enemy_base"] ~= nil
    -- local vulcanus_enemies = surface.map_gen_settings.territory_settings ~= nil

    -- Make chunks near a spawn safe by removing enemies
    -- TODO: Refactor this to reduce calls to find_entities_filtered maybe?
    if (util.distance(closest_spawn.position, chunkAreaCenter) < spawn_config.safe_area.safe_radius * CHUNK_SIZE) then
        if nauvis_enemies or gleba_enemies then
            RemoveEnemiesInArea(surface, chunk_area)
        end

        -- Create a warning area with heavily reduced enemies
    elseif (util.distance(closest_spawn.position, chunkAreaCenter) < spawn_config.safe_area.warn_radius * CHUNK_SIZE) then
        if nauvis_enemies or gleba_enemies then
            ReduceEnemiesInArea(surface, chunk_area, spawn_config.safe_area.warn_reduction)
        end

        if nauvis_enemies then
            RemoveWormsInArea(surface, chunk_area, false, true, true, true) -- remove all non-small worms.
        end

        if gleba_enemies then
            DowngradeGlebaSpawnersInArea(surface, chunk_area)
        end

        -- Create a third area with moderately reduced enemies
    elseif (util.distance(closest_spawn.position, chunkAreaCenter) < spawn_config.safe_area.danger_radius * CHUNK_SIZE) then
        if nauvis_enemies or gleba_enemies then
            ReduceEnemiesInArea(surface, chunk_area, spawn_config.safe_area.danger_reduction)
        end

        if nauvis_enemies then
            RemoveWormsInArea(surface, chunk_area, false, false, true, true) -- remove all huge/behemoth worms.
        end
    end
end

---Downgrades gleba spawners in the area
---@param surface LuaSurface
---@param area BoundingBox
---@return nil
function DowngradeGlebaSpawnersInArea(surface, area)
    for _, entity in pairs(surface.find_entities_filtered { area = area, name = "gleba-spawner", force = "enemy" }) do
        local position = entity.position
        entity.destroy()
        local spawner = surface.create_entity { name = "gleba-spawner-small", position = position, force = game.forces.enemy }
    end
end

---Convenient way to remove aliens, just provide an area
---@param surface LuaSurface
---@param area BoundingBox
---@return nil
function RemoveEnemiesInArea(surface, area)
    for _, entity in pairs(surface.find_entities_filtered { area = area, force = "enemy" }) do
        entity.destroy()
    end
end

---Make an area safer, randomly removes enemies based on a reduction factor.
---@param surface LuaSurface
---@param area BoundingBox
---@param reductionFactor integer Reduction factor divides the enemy spawns by that number. 2 = half, 3 = third, etc...
---@return nil
function ReduceEnemiesInArea(surface, area, reductionFactor)
    for _, entity in pairs(surface.find_entities_filtered { area = area, force = "enemy" }) do
        if (math.random(0, reductionFactor) > 0) then
            entity.destroy()
        end
    end
end

---Downgrades worms in an area based on chance. 100% small would mean all worms are changed to small.
---@param surface LuaSurface
---@param area BoundingBox
---@param small_percent integer ---Chance to force to small worm
---@param medium_percent integer ---Chance to force to medium worm
---@param big_percent integer ---Chance to force to big worm
---@return nil
function DowngradeWormsInArea(surface, area, small_percent, medium_percent, big_percent)
    -- Leave out "small-worm-turret" as it's the lowest.
    local worm_types = { "medium-worm-turret", "big-worm-turret", "behemoth-worm-turret" }

    for _, entity in pairs(surface.find_entities_filtered { area = area, name = worm_types }) do
        -- Roll a number between 0-100
        local rand_percent = math.random(0, 100)
        local worm_pos = entity.position
        local worm_name = entity.name
        local force = entity.force

        -- If number is less than small percent, change to small
        if (rand_percent <= small_percent) then
            entity.destroy()
            surface.create_entity { name = "small-worm-turret", position = worm_pos, force = force }

            -- ELSE If number is less than medium percent, change to medium
        elseif (rand_percent <= medium_percent) then
            if (not (worm_name == "medium-worm-turret")) then
                entity.destroy()
                surface.create_entity { name = "medium-worm-turret", position = worm_pos, force = force }
            end

            -- ELSE If number is less than big percent, change to big
        elseif (rand_percent <= big_percent) then
            if (not (worm_name == "big-worm-turret")) then
                entity.destroy()
                surface.create_entity { name = "big-worm-turret", position = worm_pos, force = force }
            end

            -- ELSE ignore it.
        end
    end
end

---A function to help me remove worms in an area. Yeah kind of an unecessary wrapper, but makes my life easier to remember the worm types.
---@param surface LuaSurface
---@param area BoundingBox
---@param small boolean
---@param medium boolean
---@param big boolean
---@param behemoth boolean
---@return nil
function RemoveWormsInArea(surface, area, small, medium, big, behemoth)
    local worm_types = {}

    if (small) then
        table.insert(worm_types, "small-worm-turret")
    end
    if (medium) then
        table.insert(worm_types, "medium-worm-turret")
    end
    if (big) then
        table.insert(worm_types, "big-worm-turret")
    end
    if (behemoth) then
        table.insert(worm_types, "behemoth-worm-turret")
    end

    -- Destroy
    if (#worm_types > 0) then
        for _, entity in pairs(surface.find_entities_filtered { area = area, name = worm_types }) do
            entity.destroy()
        end
    else
        log("RemoveWormsInArea had empty worm_types list!")
    end
end

-- I wrote this to ensure everyone gets safer spawns regardless of evolution level.
-- This is intended to downgrade any biters/spitters spawning near player bases.
-- I'm not sure the performance impact of this but I'm hoping it's not bad.
---@param event EventData.on_entity_spawned|EventData.on_biter_base_built
---@return nil
function ModifyEnemySpawnsNearPlayerStartingAreas(event)
    if (not event.entity or not (event.entity.force.name == "enemy") or not event.entity.position) then
        log("ModifyBiterSpawns - Unexpected use.")
        return
    end

    local enemy_pos = event.entity.position
    local surface = event.entity.surface
    local enemy_name = event.entity.name

    local closest_spawn = GetClosestUniqueSpawn(surface.name, enemy_pos)

    if (closest_spawn == nil) then
        -- log("GetClosestUniqueSpawn ERROR - None found?")
        return
    end

    -- No enemies inside safe radius!
    if (util.distance(enemy_pos, closest_spawn.position) < storage.ocfg.surfaces_config[surface.name].spawn_config.safe_area.safe_radius * CHUNK_SIZE) then
        event.entity.destroy()

        -- Warn distance is all SMALL only.
    elseif (util.distance(enemy_pos, closest_spawn.position) < storage.ocfg.surfaces_config[surface.name].spawn_config.safe_area.warn_radius * CHUNK_SIZE) then
        
        -- Nauvis enemies
        if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter") or (enemy_name == "medium-biter")) then
            event.entity.destroy()
            surface.create_entity { name = "small-biter", position = enemy_pos, force = game.forces.enemy }
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter") or (enemy_name == "medium-spitter")) then
            event.entity.destroy()
            surface.create_entity { name = "small-spitter", position = enemy_pos, force = game.forces.enemy }
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret") or (enemy_name == "medium-worm-turret")) then
            event.entity.destroy()
            surface.create_entity { name = "small-worm-turret", position = enemy_pos, force = game.forces.enemy }

        -- Gleba enemies
        elseif ((enemy_name == "big-wriggler-pentapod") or (enemy_name == "medium-wriggler-pentapod")) then
            event.entity.destroy()
            surface.create_entity { name = "small-wriggler-pentapod", position = enemy_pos, force = game.forces.enemy }
        elseif ((enemy_name == "big-stomper-pentapod")  or (enemy_name == "medium-stomper-pentapod")) then
            event.entity.destroy()
            surface.create_entity { name = "small-stomper-pentapod", position = enemy_pos, force = game.forces.enemy }
        elseif ((enemy_name == "big-strafer-pentapod")  or (enemy_name == "medium-strafer-pentapod")) then
            event.entity.destroy()
            surface.create_entity { name = "small-strafer-pentapod", position = enemy_pos, force = game.forces.enemy }

        -- Gleba spawners downgrade
        elseif (enemy_name == "gleba-spawner") then
            event.entity.destroy()
            surface.create_entity { name = "gleba-spawner-small", position = enemy_pos, force = game.forces.enemy }

        end

        -- Danger distance is MEDIUM max.
    elseif (util.distance(enemy_pos, closest_spawn.position) < storage.ocfg.surfaces_config[surface.name].spawn_config.safe_area.danger_radius * CHUNK_SIZE) then

        -- Nauvis enemies
        if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-biter", position = enemy_pos, force = game.forces.enemy }
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-spitter", position = enemy_pos, force = game.forces.enemy }
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-worm-turret", position = enemy_pos, force = game.forces.enemy }

        -- Gleba enemies
        elseif (enemy_name == "big-wriggler-pentapod") then
            event.entity.destroy()
            surface.create_entity { name = "medium-wriggler-pentapod", position = enemy_pos, force = game.forces.enemy }
        elseif (enemy_name == "big-stomper-pentapod") then
            event.entity.destroy()
            surface.create_entity { name = "medium-stomper-pentapod", position = enemy_pos, force = game.forces.enemy }
        elseif (enemy_name == "big-strafer-pentapod") then
            event.entity.destroy()
            surface.create_entity { name = "medium-strafer-pentapod", position = enemy_pos, force = game.forces.enemy }
        end
    end
end

---Applies bonus damage directly to spawner health to compensate for evolution health scaling
---This is a temporary measure until they release an API to directly change the health scaling of spawners.
---It does not scale properly with the evolution factor because this is linear and that evo is not, but it's better than nothing.
---@param event EventData.on_entity_damaged
---@return nil
function ApplySpawnerDamageScaling(event)
    -- Check if force is a player force
    if (event.force == nil) then
        log("Entity damaged with no force")
        return
    end

    local entity = event.entity
    local surface_name = entity.surface.name

    -- Get the closest player spawn to the entity that was damaged.
    local spawn = GetClosestUniqueSpawn(surface_name, entity.position)
    if (spawn == nil) then return end

    -- Get distance to spawn_position
    local distance = util.distance(spawn.position, entity.position)
    local max_danger_distance = storage.ocfg.surfaces_config[surface_name].spawn_config.safe_area.danger_radius *
    CHUNK_SIZE

    -- If distance is greater than the danger radius, ignore.
    if (distance > max_danger_distance) then return end

    -- Boost the damage based on distance from spawn and current evolution factor.
    local evo_factor = entity.force.get_evolution_factor(entity.surface)
    local distance_factor = 1 - (distance / max_danger_distance)

    -- spawner_evolution_factor_health_modifier = 10 -- This is from https://github.com/wube/factorio-data/blob/master/core/prototypes/utility-constants.lua somehow?
    -- I do 9 because we're assuming 1 (base) + 9 (bonus) = 10.
    local bonus_damange = (distance_factor * evo_factor * 9) * event.final_damage_amount

    -- Apply the additional damage. We do not call entity.damage because that would trigger this event again.
    entity.health = entity.health - bonus_damange

    -- If evo is 1, and distance to spawn is 0, then damage_modifier is 10
    -- If evo is 1, and distance to spawn is 1, then damage_modifier is 1
    -- If evo is 0, then damage_modifier is 1
end

---@param event EventData.on_segment_entity_created
---@return nil
function TrackDemolishers(event)
    local entity = event.entity --[[@as LuaEntity]]
    if (entity.type ~= "segmented-unit") or (not entity.valid) then return end
    if (entity.name == "big-demolisher") or (entity.name == "medium-demolisher") or (entity.name == "small-demolisher") then
        if storage.demolisher_tracker == nil then
            storage.demolisher_tracker = {}
            storage.demolisher_tracker.demolishers = {}
        end

        if storage.demolisher_tracker.demolishers[entity.unit_number] == nil then
            storage.demolisher_tracker.demolishers[entity.unit_number] = entity
        end
    else
        log("Unexpected segmented-unit entity type spawned: " .. entity.name)
    end
end

---This function checks where demolishers are every tick and if it is inside the warning zone it gets removed.
---TODO: This is a TEMPORARY WORK AROUND until there is a better demolisher and territory API.
-- Shouldn't be too bad since we only check a single one per tick.
---@param event EventData.on_tick
---@return nil
function RemoveDemolishersInWarningZone(event)
    if storage.demolisher_tracker == nil then return end

    --TODO: Figure out lua type annotation?!
    local index, next_demolisher = next(storage.demolisher_tracker.demolishers, storage.demolisher_tracker.index)

    if next_demolisher == nil then
        storage.demolisher_tracker.index = nil
        return
    end

    if next_demolisher.valid then
        local closest_spawn = GetClosestUniqueSpawn(next_demolisher.surface.name, next_demolisher.position)
        if (closest_spawn == nil) then return end

        local distance = util.distance(next_demolisher.position, closest_spawn.position)
        local safe_radius_tiles = (storage.ocfg.surfaces_config[next_demolisher.surface.name].spawn_config.safe_area.safe_radius) * CHUNK_SIZE -- TODO: Should probably cache this on first init.

        if (distance < safe_radius_tiles) then
            next_demolisher.destroy()
            storage.demolisher_tracker.demolishers[index] = nil
            storage.demolisher_tracker.index = nil
        else
            storage.demolisher_tracker.index = index
        end
    else
        storage.demolisher_tracker.demolishers[index] = nil
        storage.demolisher_tracker.index = nil
    end
end
