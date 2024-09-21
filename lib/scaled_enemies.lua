-- This handles scaling enemies in a few different ways to make sure that all players can have a reasonable experience
-- even if they join the game late or are playing at a slower pace.

-- TODO: Plan for new enemies in space DLC.
-- TODO: Plan for new enemies in space DLC.
-- TODO: Plan for new enemies in space DLC.


ENEMY_FORCE_EASY = "enemy-easy"
ENEMY_FORCE_MEDIUM = "enemy-medium"
ENEMY_FORCES_NAMES = {"enemy", ENEMY_FORCE_EASY, ENEMY_FORCE_MEDIUM}

ENEMY_BUILT_TYPES = { "biter-spawner", "spitter-spawner", "small-worm-turret", "medium-worm-turret", "big-worm-turret", "behemoth-worm-turret" }

---Create a few extra enemy forces with fixed evolution factors for scaling down near player bases.
---@return nil
function CreateEnemyForces()

    --  Create the enemy forces if they don't exist
    for _,force_name in pairs(ENEMY_FORCES_NAMES) do
        if (game.forces[force_name] == nil) then
            game.create_force(force_name)
        end

        local enemy_force = game.forces[force_name]
        enemy_force.ai_controllable = true
    end

    ConfigureEnemyForceRelationships()
end

---Configures the friend and cease fire relationships between all forces and enemy forces.
---@return nil
function ConfigureEnemyForceRelationships()
    for _,force in pairs(game.forces) do

        -- If this is an enemy force
        if (TableContains(ENEMY_FORCES_NAMES, force.name)) then

            -- Make sure it IS friends with all other enemy forces.
            for _,enemy_force_name in pairs(ENEMY_FORCES_NAMES) do
                if (force.name ~= enemy_force_name) then -- Exclude self
                    local enemy_force = game.forces[enemy_force_name]

                    force.set_friend(enemy_force, true)
                    force.set_cease_fire(enemy_force, true)

                    enemy_force.set_friend(force, true)
                    enemy_force.set_cease_fire(force, true)
                end
            end

        -- If this is a non-enemy force
        else
            -- Make sure this force is NOT friends with any enemy forces.
            for _,enemy_force_name in pairs(ENEMY_FORCES_NAMES) do
                local enemy_force = game.forces[enemy_force_name]

                force.set_friend(enemy_force, false)
                force.set_cease_fire(enemy_force, false)

                enemy_force.set_friend(force, false)
                enemy_force.set_cease_fire(force, false)
            end
        end

    end
end

---Configures the friend and cease fire relationships between all enemy forces and a new player force.
---@param new_player_force LuaForce
---@return nil
function ConfigureEnemyForceRelationshipsForNewPlayerForce(new_player_force)
    for _,enemy_force_name in pairs(ENEMY_FORCES_NAMES) do
        local enemy_force = game.forces[enemy_force_name]

        new_player_force.set_friend(enemy_force, false)
        new_player_force.set_cease_fire(enemy_force, false)

        enemy_force.set_friend(new_player_force, false)
        enemy_force.set_cease_fire(new_player_force, false)
    end
end


--- Keep the enemy evolution factor in check.
---@return nil
function RestrictEnemyEvolutionOnTick()
    local base_evo_factor = game.forces["enemy"].evolution_factor

    -- Restrict the evolution factor of the enemy forces
    game.forces[ENEMY_FORCE_EASY].evolution_factor = math.min(base_evo_factor, global.ocfg.gameplay.modified_enemy_easy_evo)
    game.forces[ENEMY_FORCE_MEDIUM].evolution_factor = math.min(base_evo_factor, global.ocfg.gameplay.modified_enemy_medium_evo)
end

---Downgrades worms based on distance from origin and near/far spawn distances.
---This helps make sure worms aren't too overwhelming even at these further spawn distances.
---@param event EventData.on_chunk_generated
---@return nil
function DowngradeWormsDistanceBasedOnChunkGenerate(event)

    ---@type OarcConfigGameplaySettings
    local gameplay = global.ocfg.gameplay

    if (util.distance({ x = 0, y = 0 }, event.area.left_top) < (gameplay.near_spawn_distance * CHUNK_SIZE)) then
        DowngradeWormsInArea(event.surface, event.area, 100, 100, 100)
    elseif (util.distance({ x = 0, y = 0 }, event.area.left_top) < (gameplay.far_spawn_distance * CHUNK_SIZE)) then
        DowngradeWormsInArea(event.surface, event.area, 50, 90, 100)
    elseif (util.distance({ x = 0, y = 0 }, event.area.left_top) < (gameplay.far_spawn_distance * CHUNK_SIZE * 2)) then
        DowngradeWormsInArea(event.surface, event.area, 20, 80, 97)
    else
        DowngradeWormsInArea(event.surface, event.area, 0, 20, 90)
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

    local spawn_config --[[@as OarcConfigSpawn]] = global.ocfg.surfaces_config[surface.name].spawn_config
    local chunkAreaCenter = {
        x = chunk_area.left_top.x + (CHUNK_SIZE / 2),
        y = chunk_area.left_top.y + (CHUNK_SIZE / 2)
    }

    -- Make chunks near a spawn safe by removing enemies
    if (util.distance(closest_spawn.position, chunkAreaCenter) < spawn_config.safe_area.safe_radius) then
        RemoveEnemiesInArea(surface, chunk_area)

        -- Create a warning area with heavily reduced enemies
    elseif (util.distance(closest_spawn.position, chunkAreaCenter) < spawn_config.safe_area.warn_radius) then

        -- TODO: Refactor this to reduce calls to find_entities_filtered!
        ReduceEnemiesInArea(surface, chunk_area, spawn_config.safe_area.warn_reduction)
        RemoveWormsInArea(surface, chunk_area, false, true, true, true) -- remove all non-small worms.
        ConvertEnemiesToOtherForceInArea(surface, chunk_area, ENEMY_FORCE_EASY)

        -- Create a third area with moderately reduced enemies
    elseif (util.distance(closest_spawn.position, chunkAreaCenter) < spawn_config.safe_area.danger_radius) then

        -- TODO: Refactor this to reduce calls to find_entities_filtered!
        ReduceEnemiesInArea(surface, chunk_area, spawn_config.safe_area.danger_reduction)
        RemoveWormsInArea(surface, chunk_area, false, false, true, true) -- remove all huge/behemoth worms.
        ConvertEnemiesToOtherForceInArea(surface, chunk_area, ENEMY_FORCE_MEDIUM)
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
---@param small_percent integer ---Chance to change to small worm
---@param medium_percent integer
---@param big_percent integer
---@return nil
function DowngradeWormsInArea(surface, area, small_percent, medium_percent, big_percent)
    -- Leave out "small-worm-turret" as it's the lowest.
    local worm_types = { "medium-worm-turret", "big-worm-turret", "behemoth-worm-turret" }

    for _, entity in pairs(surface.find_entities_filtered { area = area, name = worm_types }) do
        -- Roll a number between 0-100
        local rand_percent = math.random(0, 100)
        local worm_pos = entity.position
        local worm_name = entity.name

        -- If number is less than small percent, change to small
        if (rand_percent <= small_percent) then
            if (not (worm_name == "small-worm-turret")) then
                entity.destroy()
                surface.create_entity { name = "small-worm-turret", position = worm_pos, force = game.forces.enemy }
            end

        -- ELSE If number is less than medium percent, change to small
        elseif (rand_percent <= medium_percent) then
            if (not (worm_name == "medium-worm-turret")) then
                entity.destroy()
                surface.create_entity { name = "medium-worm-turret", position = worm_pos, force = game.forces.enemy }
            end

        -- ELSE If number is less than big percent, change to small
        elseif (rand_percent <= big_percent) then
            if (not (worm_name == "big-worm-turret")) then
                entity.destroy()
                surface.create_entity { name = "big-worm-turret", position = worm_pos, force = game.forces.enemy }
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

---Converts all enemies in the base enemy force in an area to easy force.
---@param surface LuaSurface
---@param area BoundingBox
---@param force_name string
---@return nil
function ConvertEnemiesToOtherForceInArea(surface, area, force_name)
    for _, entity in pairs(surface.find_entities_filtered { area = area, force = "enemy" }) do
        entity.force = game.forces[force_name]
    end
end

---Converts new enemy bases to different enemy forces if they are near to player bases.
---@param event EventData.on_biter_base_built
---@return nil
function ChangeEnemySpawnersToOtherForceOnBuilt(event)
    if (not event.entity or not event.entity.position or not TableContains(ENEMY_FORCES_NAMES, event.entity.force.name)) then
        log("ChangeEnemySpawnersToOtherForceOnBuilt Unexpected entity or force?")
        return
    end

    local enemy_pos = event.entity.position
    local surface = event.entity.surface
    local enemy_name = event.entity.name

    if (not TableContains(ENEMY_BUILT_TYPES, enemy_name)) then
        log("ChangeEnemySpawnersToOtherForceOnBuilt Unexpected entity name? " .. enemy_name)
        return
    end

    local closest_spawn = GetClosestUniqueSpawn(surface.name, enemy_pos)
    if (closest_spawn == nil) then return end

    -- No enemies inside safe radius!
    if (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.safe_radius) then
        event.entity.destroy()

    -- Warn distance should be EASY
    elseif (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.warn_radius) then
        event.entity.force = game.forces[ENEMY_FORCE_EASY]

    -- Danger distance should be MEDIUM
    elseif (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.danger_radius) then
        event.entity.force = game.forces[ENEMY_FORCE_MEDIUM]
    
    -- Otherwise make sure they are on the base enemy force (stops easy enemies from spreading out too far).
    else
        event.entity.force = game.forces["enemy"]
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
    if (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.safe_radius) then
        event.entity.destroy()

        -- Warn distance is all SMALL only.
    elseif (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.warn_radius) then
        if ((enemy_name == "biter-spawner") or (enemy_name == "spitter-spawner")) then
            event.entity.force = game.forces["enemy-easy"]
        
        elseif ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter") or (enemy_name == "medium-biter")) then
            event.entity.destroy()
            surface.create_entity { name = "small-biter", position = enemy_pos, force = game.forces["enemy-easy"] }
            -- log("Downgraded biter close to spawn.")
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter") or (enemy_name == "medium-spitter")) then
            event.entity.destroy()
            surface.create_entity { name = "small-spitter", position = enemy_pos, force = game.forces["enemy-easy"] }
            -- log("Downgraded spitter close to spawn.")
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret") or (enemy_name == "medium-worm-turret")) then
            event.entity.destroy()
            surface.create_entity { name = "small-worm-turret", position = enemy_pos, force = game.forces["enemy-easy"] }
            -- log("Downgraded worm close to spawn.")
        end

        -- Danger distance is MEDIUM max.
    elseif (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.danger_radius) then
        if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-biter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded biter further from spawn.")
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-spitter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded spitter further from spawn
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-worm-turret", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded worm further from spawn.")
        end
    end
end