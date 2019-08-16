-- oarc_enemies.lua
-- Oarc Sep 2018
-- My crude attempts at changing enemy experience.


-- This is what an attack request should look like:
-- attack_request_example = {
--      target_player=player_index,      -- REQUIRED (Player index)
--      target_type=TYPE,               -- REQUIRED (OE_ATTACK_TYPE)
--      attempts=3,                     -- REQUIRED (Must be at least 1! Otherwise it won't do anything.)
--      process_stg=TYPE,               -- REQUIRED (Normally starts with OE_PROCESS_STG_FIND_TARGET)
--      building_types=entity_types,    -- REQUIRED if attack request is for a building.
--      surface_idx=surface_index       -- REQUIRED (Tracking of different surfaces)
--      target_entity=lua_entity,       -- Depends on attack type. Calculated during request processing.
--      target_chunk=c_pos,             -- Depends on attack type. Calculated during request processing.
--      size=x,                         -- Calculated during request processing.
--      evo=x,                          -- Calculated during request processing.
--      spawn_chunk=spawn_chunk,        -- Calculated during request processing.
--      path_id=path_request_id,        -- Set during request processing.
--      path=path,                      -- Set by on_script_path_request_finished.
--      group_id=group_id,              -- Set during request processing.
--      group=lua_unit_group            -- The group created to handle the attack
--      group_age=tick_spawned          -- The tick when the group was created
-- }


-- Adapted from:
-- https://stackoverflow.com/questions/3706219/algorithm-for-iterating-over-an-outward-spiral-on-a-discrete-2d-grid-from-the-or
-- Searches in a spiral outwards on a 2D grid map.
-- Returns table of coordinates when the check_function passes.
function SpiralSearch(starting_c_pos, max_radius, max_count, check_function)

    local dx = 1
    local dy = 0
    local segment_length = 1

    local x = starting_c_pos.x
    local y = starting_c_pos.y
    local segment_passed = 0

    local found = {}

    for i=1,(math.pow(max_radius*2+1, 2)) do

        if (true == check_function({x=x, y=y})) then
            table.insert(found, {x=x, y=y})
            if (#found >= max_count) then return found end
        end

        x = x + dx;
        y = y + dy;
        segment_passed  = segment_passed + 1

        if (segment_passed == segment_length) then

            segment_passed = 0

            local buffer = dx
            dx = -dy;
            dy = buffer

            if (dy == 0) then
                segment_length  = segment_length + 1
            end
        end
    end

    if (#found == 0) then
        log("SpiralSearch Failed? " .. x .. "," .. y)
        return nil
    else
        return found
    end
end

function OarcEnemiesSectorScanned(event)
    if (not event.radar.last_user) then return end
    local player = event.radar.last_user

    if not player.connected then return end

    -- 1 in a X chance of triggering an attack on radars?
    if (math.random(1,global.oe_params.radar_scan_attack_chance) == 1) then
        OarcEnemiesBuildingAttack(player.index, "radar")
    end
end

function OarcEnemiesRocketLaunched(event)
    if (not event.rocket_silo) then return end
    local player = event.rocket_silo.last_user
    if (not player) then
        log("Error? No last user on the silo.")
        return
    end

    local silo = event.rocket_silo

    local e,s = GetEnemyGroup{player=player,
                                force_name=player.force.name,
                                surface=silo.surface,
                                target_pos=silo.position}

    local rocket_launch_attack = {target_player = player.index,
                                    target_type = OE_TARGET_TYPE_ENTITY,
                                    attempts=1,
                                    process_stg=OE_PROCESS_STG_FIND_SPAWN,
                                    building_types=nil,
                                    evo=e,
                                    size=s}

    log("SILO ATTACK")
    table.insert(global.oe.attacks, rocket_launch_attack)
end

function OarcEnemiesForceCreated(event)
    if (not event.force) then return end
    global.oe.tech_levels[event.force.index] = 0
end

function CountForceTechCompleted(force)
    if (not force.technologies) then
        log("ERROR - CountForceTechCompleted needs a valid force please.")
        return 0
    end

    local tech_done = 0
    for name,tech in pairs(force.technologies) do
        if tech.researched then
            tech_done = tech_done + 1
        end
    end

    return tech_done
end

function InitOarcEnemies()
    global.oe = {}

    -- We store a map of chunks to help figure out good spawn locations
    global.oe.chunk_map = {}

    -- Keep track of groups so we know when we are done with them (abandoned)
    global.oe.groups = {}
    -- global.oe.units = {}

    -- Keep track of a player's buildings
    global.oe.buildings = {}

    -- Keep track of force tech levels
    global.oe.tech_levels = {}

    -- Each player has a timer for semi-regular attacks.
    global.oe.player_timers = {}

    -- Player speech bubble stuff (track if we have done certain messages)
    global.oe.player_sbubbles = {}

    -- Ongoing attacks
    global.oe.attacks = {}

    -- DEBUG helpers
    global.oe_render_paths = true

    -- These control all evo/size scaling and stuff.
    global.oe_params = {
        attack_size_min = 1,
        attack_size_max = 150,

        player_time_evo_factor = 0.5,
        player_time_size_factor = 30,
        player_time_peak_hours = 20,

        pollution_evo_factor = 0.3,
        pollution_size_factor = 80,
        pollution_peak_amnt = 4000,

        tech_evo_factor = 0.85,
        tech_size_factor = 30,
        tech_peak_count = 180,

        rand_evo_amnt = 0.15, -- Up to + this amount
        rand_size_amnt = 10, -- Up to + this amount

        seconds_between_attacks_min = 5*60,
        seconds_between_attacks_max = 30*60,
        seconds_between_attacks_rand = 4*60,

        radar_scan_attack_chance = 500, -- 1 in X change to trigger an attack due to a radar ping.
    }

    -- Copied from wave defense
    -- game.map_settings.path_finder.use_path_cache = false
    -- game.map_settings.path_finder.max_steps_worked_per_tick = 1000
    -- game.map_settings.path_finder.max_clients_to_accept_any_new_request = 5000
    -- game.map_settings.path_finder.ignore_moving_enemy_collision_distance = 0
    -- game.map_settings.short_request_max_steps = 1000000
    -- game.map_settings.short_request_ratio = 1
    -- game.map_settings.max_failed_behavior_count = 2
    -- game.map_settings.steering.moving.force_unit_fuzzy_goto_behavior = true
    -- game.map_settings.steering.moving.radius = 6
    -- game.map_settings.steering.moving.separation_force = 0.02
    -- game.map_settings.steering.moving.separation_factor = 8
    -- game.map_settings.steering.default.force_unit_fuzzy_goto_behavior = true
    -- game.map_settings.steering.default.radius = 1
    -- game.map_settings.steering.default.separation_force = 0.01
    -- game.map_settings.steering.default.separation_factor  = 1
end

-- Track each force's amount of research completed.
function OarcEnemiesResearchFinishedEvent(event)
    if not (event.research and event.research.force) then return end

    local force = event.research.force
    if (global.oe.tech_levels[force.index] == nil) then
        global.oe.tech_levels[force.index] = CountForceTechCompleted(force)
    else
        global.oe.tech_levels[force.index] = global.oe.tech_levels[force.index] + 1
    end

    -- Trigger an attack on science!
    OarcEnemiesScienceLabAttack(force.index)
end

-- Attack science labs of a given force!
function OarcEnemiesScienceLabAttack(force_index)
    -- For each player (connected only), find a random science lab,
    for _,player in pairs(game.forces[force_index].connected_players) do
        OarcEnemiesBuildingAttack(player.index, "lab")
    end
end

-- Request an attack on a given player's building type.
function OarcEnemiesBuildingAttack(player_index, entity_type)
    -- Make sure player exists and is connected.
    if (not game.players[player_index] or
        not game.players[player_index].connected) then return end

    -- Check we don't have too many ongoing attacks.
    if (#global.oe.attacks >= OE_ATTACKS_MAX) then
        log("Max number of simulataneous attacks reached.")
        return
    end

    local building_attack = {target_player = player_index,
                            target_type = OE_TARGET_TYPE_BUILDING,
                            attempts=3,
                            process_stg=OE_PROCESS_STG_FIND_TARGET,
                            building_types=entity_type}
    log("Building Attack Request: " .. serpent.line(entity_type))
    table.insert(global.oe.attacks, building_attack)
end

-- Attack a player's character
function OarcEnemiesPlayerAttackCharacter(player_index)

    -- Validation checks.
    if (not game.players[player_index] or
        not game.players[player_index].connected or
        not game.players[player_index].character or
        not game.players[player_index].character.valid) then
        log("OarcEnemiesPlayerAttackCharacter - player not connected or is dead?")
        return
    end

    -- Check we don't have too many ongoing attacks.
    if (#global.oe.attacks >= OE_ATTACKS_MAX) then
        log("Max number of simulataneous attacks reached.")
        return
    end

    -- Create the attack request
    local player_attack = {target_player = player_index,
                            target_type = OE_TARGET_TYPE_PLAYER,
                            attempts=3,
                            process_stg=OE_PROCESS_STG_FIND_TARGET}
    log("Player Attack!")
    table.insert(global.oe.attacks, player_attack)
end

-- First time player init stuff
function OarcEnemiesPlayerCreatedEvent(event)
    if (game.players[event.player_index] == nil) then return end

    if (global.oe.player_timers[event.player_index] == nil) then
        global.oe.player_timers[event.player_index] = {character=GetRandomizedPlayerTimer(0, 60*10),
                                             generic=GetRandomizedPlayerTimer(0, 0)}
    end

    if (global.oe.buildings[event.player_index] == nil) then
        global.oe.buildings[event.player_index] = {}
    end

    local force = game.players[event.player_index].force
    if (global.oe.tech_levels[force.index] == nil) then
        global.oe.tech_levels[force.index] = CountForceTechCompleted(force)
    end

    -- Setup tracking of first time chat bubble displays
    if (global.oe.player_sbubbles[event.player_index] == nil) then
        global.oe.player_sbubbles[event.player_index] = {uh_oh=false,
                                                        rocket=false}
    end
end


function OarcEnemiesPlayerRemovedEvent(event)
    if (game.players[event.player_index] == nil) then return end

    global.oe.player_timers[event.player_index] = nil
    global.oe.buildings[event.player_index] = nil
    global.oe.player_sbubbles[event.player_index] = nil
end

function OarcEnemiesChunkGenerated(event)
    if (not event.area or not event.area.left_top) then
        log("ERROR - OarcEnemiesChunkGenerated")
        return
    end

    local c_pos = GetChunkPosFromTilePos(event.area.left_top)

    local enough_land = true

    -- Check if there is any water in the chunk.
    local water_tiles = event.surface.find_tiles_filtered{area = event.area,
                                                            collision_mask = "water-tile",
                                                            limit=5}
    if (#water_tiles >= 5) then
        enough_land = false
    end

    -- Check if it has spawners
    local spawners = event.surface.find_entities_filtered{area=event.area,
                                                            type={"unit-spawner"},
                                                            force="enemy"}

    -- If this is the first chunk in that row:
    if (global.oe.chunk_map[c_pos.x] == nil) then
        global.oe.chunk_map[c_pos.x] = {}
    end

    -- Save chunk info.
    global.oe.chunk_map[c_pos.x][c_pos.y] = {player_building=false,
                                                        near_building=false,
                                                        valid_spawn=enough_land,
                                                        enemy_spawners=spawners}
end

function OarcEnemiesChunkIsNearPlayerBuilding(c_pos)
    if (global.oe.chunk_map[c_pos.x] == nil) then
        global.oe.chunk_map[c_pos.x] = {}
    end
    if (global.oe.chunk_map[c_pos.x][c_pos.y] == nil) then
        global.oe.chunk_map[c_pos.x][c_pos.y] = {player_building=false,
                                                            near_building=true,
                                                            valid_spawn=true,
                                                            enemy_spawners={}}
    else
        global.oe.chunk_map[c_pos.x][c_pos.y].near_building = true
    end
end

function OarcEnemiesChunkHasPlayerBuilding(position)
    local c_pos = GetChunkPosFromTilePos(position)

    for i=-OE_BUILDING_SAFE_AREA_RADIUS,OE_BUILDING_SAFE_AREA_RADIUS do
        for j=-OE_BUILDING_SAFE_AREA_RADIUS,OE_BUILDING_SAFE_AREA_RADIUS do
            OarcEnemiesChunkIsNearPlayerBuilding({x=c_pos.x+i,y=c_pos.y+j})
        end
    end

end

function OarcEnemiesIsChunkValidSpawn(c_pos)

    -- Chunk should exist.
    if (game.surfaces[GAME_SURFACE_NAME].is_chunk_generated(c_pos) == false) then
        return false
    end

    -- Check entry exists.
    if (global.oe.chunk_map[c_pos.x] == nil) then
        return false
    end
    if (global.oe.chunk_map[c_pos.x][c_pos.y] == nil) then
        return false
    end

    -- Get entry
    local chunk = global.oe.chunk_map[c_pos.x][c_pos.y]

    -- Check basic flags
    if (chunk.player_building or chunk.near_building or not chunk.valid_spawn) then
        return false
    end

    -- Check for spawners
    if (not chunk.enemy_spawners or (#chunk.enemy_spawners == 0)) then
        return false
    end

    -- Check visibility
    for _,force in pairs(game.forces) do
        if (force.name ~= "enemy") then
            if (force.is_chunk_visible(game.surfaces[GAME_SURFACE_NAME], c_pos)) then
                return false
            end
        end
    end

    return true
end

-- Check if a given chunk has a spawner in it.
-- Ideally optimized since we use our tracking of spawners in chunk_map
function OarcEnemiesDoesChunkHaveSpawner(c_pos)

    -- Chunk should exist.
    if (game.surfaces[GAME_SURFACE_NAME].is_chunk_generated(c_pos) == false) then
        return false
    end

    -- Check entry exists.
    if (global.oe.chunk_map[c_pos.x] == nil) then
        return false
    end
    if (global.oe.chunk_map[c_pos.x][c_pos.y] == nil) then
        return false
    end

    -- Get entry
    local chunk = global.oe.chunk_map[c_pos.x][c_pos.y]

    -- Check basic flags
    if (not chunk.valid_spawn) then
        return false
    end

    -- Check for spawners
    local has_spawners = false
    if (not chunk.enemy_spawners or (#chunk.enemy_spawners == 0)) then
        return false
    else
        for k,v in pairs(chunk.enemy_spawners) do
            if (not v or not v.valid) then
                table.remove(chunk.enemy_spawners, k)
            else
                has_spawners = true
                break
            end
        end
    end

    return true
end

function OarcEnemiesBiterBaseBuilt(event)
    if (not event.entity or
        not event.entity.valid or
        not (event.entity.force.name == "enemy") or
        not (event.entity.type == "unit-spawner")) then return end

    local c_pos = GetChunkPosFromTilePos(event.entity.position)

    if (global.oe.chunk_map[c_pos.x] == nil) then
        global.oe.chunk_map[c_pos.x] = {}
    end

    if (global.oe.chunk_map[c_pos.x][c_pos.y] == nil) then
        log("ERROR - OarcEnemiesBiterBaseBuilt chunk_map.x.y is nil")
        return
    end

    if (global.oe.chunk_map[c_pos.x][c_pos.y].enemy_spawners == nil) then
        global.oe.chunk_map[c_pos.x][c_pos.y].enemy_spawners = {event.entity}
    else
        table.insert(global.oe.chunk_map[c_pos.x][c_pos.y].enemy_spawners, event.entity)
    end
end

function OarcEnemiesEntityDiedEvent(event)

    -- Validate Enemy spawners only.
    if (not event.entity or
        not (event.entity.force.name == "enemy") or
        not (event.entity.type == "unit-spawner") or
        not (event.cause or event.force)) then return end

    -- Check we don't have too many ongoing attacks.
    if (#global.oe.attacks >= OE_ATTACKS_MAX_RETALIATION) then
        log("Max number of simulataneous attacks reached (retaliation).")
        return
    end

    local death_attack = {attempts=1,
                            spawn_chunk=GetChunkPosFromTilePos(event.entity.position)}

    -- If there is just a force, then just attack the area.
    if (not event.cause) then

        if (event.force.name == "neutral") then return end -- Catch non-player destruction.

        death_attack.process_stg = OE_PROCESS_STG_CREATE_GROUP
        death_attack.spawn_pos = event.entity.position
        death_attack.target_type = OE_TARGET_TYPE_AREA
        death_attack.target_chunk = GetChunkPosFromTilePos(event.entity.position)

        death_attack.evo,death_attack.size = GetEnemyGroup{player=nil,
                                                force_index=event.force.index,
                                                surface=game.surfaces[GAME_SURFACE_NAME],
                                                target_pos=event.entity.position,
                                                min_size=8,min_evo=0.25}

    -- If we have a cause, go attack that cause.
    else

        if (event.cause.force.name == "neutral") then return end -- Catch non-player destruction.

        local player = nil
        if (event.cause.type == "character") then
            player  = event.cause.player
        elseif (event.cause.last_user) then
            player  = event.cause.last_user
        end

        -- No attacks on offline players??
        -- if (not player or not player.connected) then return end

        death_attack.process_stg = OE_PROCESS_STG_SPAWN_PATH_REQ
        death_attack.target_player = player.index
        death_attack.target_type = OE_TARGET_TYPE_ENTITY
        death_attack.target_entity = event.cause
        death_attack.target_chunk = GetChunkPosFromTilePos(player.character.position)

        death_attack.evo,death_attack.size = GetEnemyGroup{player=player,
                                                force_index=event.force.index,
                                                surface=game.surfaces[GAME_SURFACE_NAME],
                                                target_pos=event.entity.position,
                                                min_size=8,min_evo=0.25}
    end

    table.insert(global.oe.attacks, death_attack)
end


function OarcEnemiesTrackBuildings(e)

    -- Don't care about ghosts.
    if (e.name == "entity-ghost") then return end

    if ((e.type ~= "car") and
        (e.type ~= "logistic-robot") and
        (e.type ~= "construction-robot") and
        (e.type ~= "combat-robot")) then
        OarcEnemiesChunkHasPlayerBuilding(e.position)
    end

    if (e.type == "lab") or
        (e.type == "mining-drill") or
        (e.type == "furnace") or
        (e.type == "reactor") or
        (e.type == "solar-panel") or
        (e.type == "assembling-machine") or
        (e.type == "generator") or
        (e.type == "rocket-silo") or
        (e.type == "radar") or
        (e.type == "ammo-turret") or
        (e.type == "electric-turret") or
        (e.type == "fluid-turret") or
        (e.type == "artillery-turret") then

        if (e.last_user == nil) then
            log("ERROR - OarcEnemiesTrackBuildings - entity.last_user is nil! " .. e.name)
            return
        end

        if (global.oe.buildings[e.last_user.index] == nil) then
            global.oe.buildings[e.last_user.index] = {}
        end

        if (global.oe.buildings[e.last_user.index][e.type] == nil) then
            global.oe.buildings[e.last_user.index][e.type] = {}
        end

        table.insert(global.oe.buildings[e.last_user.index][e.type], e)

    end
end

function GetRandomBuildingAny(player_index, entity_type_or_types)
    if (type(entity_type_or_types) == "table") then
        return GetRandomBuildingMultipleTypes(player_index, entity_type_or_types)
    else
        return GetRandomBuildingSingleType(player_index, entity_type_or_types)
    end
end

function GetRandomBuildingMultipleTypes(player_index, entity_types)
    local rand_list = {}
    for _,e_type in pairs(entity_types) do
        local rand_building = GetRandomBuildingSingleType(player_index, e_type)
        if (rand_building) then
            table.insert(rand_list, rand_building)
        end
    end
    if (#rand_list > 0) then
        return rand_list[math.random(#rand_list)]
    else
        return nil
    end
end

function GetRandomBuildingSingleType(player_index, entity_type, count)

    -- We only use this if there are lots of invalid entries, likely from destroyed buildings
    local count_internal = 0
    if (count == nil) then
        count_internal = 20
    else
        count_internal = count
    end

    if (count_internal == 0) then
        log("WARN - GetRandomBuildingSingleType - recursive limit hit")
        return nil
    end

    if (not global.oe.buildings[player_index][entity_type] or
        (#global.oe.buildings[player_index][entity_type] == 0)) then
        -- log("GetRandomBuildingSingleType - none found " .. entity_type)
        return nil
    end

    local rand_key = GetRandomKeyFromTable(global.oe.buildings[player_index][entity_type])
    local random_building = global.oe.buildings[player_index][entity_type][rand_key]

    if (not random_building or not random_building.valid) then
        table.remove(global.oe.buildings[player_index][entity_type], rand_key)
        return GetRandomBuildingSingleType(player_index, entity_type, count_internal-1)
    else
        return random_building
    end
end


function CreateEnemyGroupGivenEvoAndCount(surface, position, evo, count)

    local biter_list = CalculateEvoChanceListBiters(evo)
    local spitter_list = CalculateEvoChanceListSpitters(evo)

    -- Spitters will be between 10-50% of the size
    local rand_spitter_count = math.random(math.ceil(count/10),math.ceil(count/2))

    local enemy_units = {}
    for i=1,count do
        if (i < rand_spitter_count) then
            table.insert(enemy_units, GetEnemyFromChanceList(spitter_list))
        else
            table.insert(enemy_units, GetEnemyFromChanceList(biter_list))
        end
    end

    return CreateEnemyGroup(surface, position, enemy_units)
end


-- Create an enemy group at given position, with array of unit names provided.
function CreateEnemyGroup(surface, position, units)

    -- Create new group at given position
    local new_enemy_group = surface.create_unit_group{position = position}

    -- Attempt to spawn all units nearby
    for k,biter_name in pairs(units) do
        local unit_position = surface.find_non_colliding_position(biter_name, {position.x+math.random(-5,5), position.y+math.random(-5,5)}, 32, 1)
        if (unit_position) then
            new_unit = surface.create_entity{name = biter_name, position = unit_position}
            new_enemy_group.add_member(new_unit)
            -- table.insert(global.oe.units, new_unit)
        end
    end
    table.insert(global.oe.groups, new_enemy_group)

    -- Return the new group
    return new_enemy_group
end


-- function OarcEnemiesGroupCreatedEvent(event)
--     log("Unit group created: " .. event.group.group_number)
--     -- if (global.oe.groups == nil) then
--     --     global.oe.groups = {}
--     -- end
--     -- if (global.oe.groups[event.group.group_number] == nil) then
--     --     global.oe.groups[event.group.group_number] = event.group
--     -- else
--     --     log("A group with this ID was already created???" .. event.group.group_number)
--     -- end
-- end

function OarcEnemiesUnitRemoveFromGroupEvent(event)

    -- Force the unit back into its group if possible, only while that group is navigating/moving
    if ((global.oe.groups[event.group.group_number] ~= nil) and
        event.group and
        event.group.valid and
        ((event.group.state == defines.group_state.moving) or
        (event.group.state == defines.group_state.pathfinding))) then
        -- Re-add a unit back if it's on the move.
        event.group.add_member(event.unit)
        return
    end

    -- Otherwise, ask the unit to build a base.
    EnemyUnitBuildBaseThenWander(event.unit, event.unit.position)
end

function FindAttackKeyFromGroupIdNumber(id)
    for key,attack in pairs(global.oe.attacks) do
        if (attack.group_id and (attack.group_id == id)) then
            return key
        end
    end
    return nil
end

function EnemyGroupAttackAreaThenWander(group, target_pos, radius)

    if (not group or not group.valid or not target_pos or not radius) then
        log("EnemyGroupAttackAreaThenWander - Missing params!")
        return
    end

    local combined_commands = {}

    -- Attack the target.
    table.insert(combined_commands, {type = defines.command.attack_area,
                                        destination = target_pos,
                                        radius = radius,
                                        distraction = defines.distraction.by_enemy})

    -- Then wander and attack anything in the area
    table.insert(combined_commands, {type = defines.command.wander,
                                        distraction = defines.distraction.by_anything})

    -- Execute all commands in sequence regardless of failures.
    local compound_command =
    {
        type = defines.command.compound,
        structure_type = defines.compound_command.return_last,
        commands = combined_commands
    }

    group.set_command(compound_command)
end

function EnemyGroupGoAttackEntityThenWander(group, target, path)

    if (not group or not group.valid or not target or not path) then
        log("EnemyGroupPathAttandThenWander - Missing params!")
        return
    end

    local combined_commands = {}

    -- Add waypoints for long paths.
    -- Based on number of segments in the path.
    local i = 100
    while (path[i] ~= nil) do
        -- log("Adding path " .. i)
        table.insert(combined_commands, {type = defines.command.go_to_location,
                                            destination = path[i].position,
                                            pathfind_flags={low_priority=true},
                                            radius = 5,
                                            distraction = defines.distraction.by_damage})
        i = i + 100
    end

    -- Then attack the target.
    table.insert(combined_commands, {type = defines.command.attack,
                                        target = target,
                                        distraction = defines.distraction.by_damage})
    -- Then attack anything in the area.
    table.insert(combined_commands, {type = defines.command.attack_area,
                                        destination = target.position,
                                        radius = CHUNK_SIZE*2,
                                        distraction = defines.distraction.by_enemy})

    -- Then wander and attack anything in the area
    table.insert(combined_commands, {type = defines.command.wander,
                                        distraction = defines.distraction.by_anything})

    -- Execute all commands in sequence regardless of failures.
    local compound_command =
    {
        type = defines.command.compound,
        structure_type = defines.compound_command.return_last,
        commands = combined_commands
    }

    group.set_command(compound_command)
end

function EnemyGroupBuildBaseThenWander(group, target_pos)

    if (not group or not group.valid or not target_pos) then
        log("EnemyGroupBuildBase - Invalid group or missing target!")
        return
    end

    local combined_commands = {}

    -- Build a base (a few attempts, with randomized locations.)
    table.insert(combined_commands, {type = defines.command.build_base,
                                        destination = target_pos,
                                        ignore_planner = true,
                                        distraction = defines.distraction.by_enemy})
    table.insert(combined_commands, {type = defines.command.build_base,
                                        destination = {x=target_pos.x+math.random(-CHUNK_SIZE,CHUNK_SIZE),
                                                        y=target_pos.y+math.random(-CHUNK_SIZE,CHUNK_SIZE)},
                                        ignore_planner = true,
                                        distraction = defines.distraction.by_enemy})
    table.insert(combined_commands, {type = defines.command.build_base,
                                        destination = {x=target_pos.x+math.random(-CHUNK_SIZE,CHUNK_SIZE),
                                                        y=target_pos.y+math.random(-CHUNK_SIZE,CHUNK_SIZE)},
                                        ignore_planner = true,
                                        distraction = defines.distraction.by_enemy})

    -- Last resort is wander and attack anything in the area
    table.insert(combined_commands, {type = defines.command.wander,
                                        distraction = defines.distraction.by_anything})

    -- Execute all commands in sequence regardless of failures.
    local compound_command =
    {
        type = defines.command.compound,
        structure_type = defines.compound_command.return_last,
        commands = combined_commands
    }

    group.set_command(compound_command)
end


function EnemyUnitBuildBaseThenWander(unit, target_pos)

    if (not unit or not unit.valid or not target_pos) then
        log("EnemyUnitBuildBaseThenWander - Invalid or missing target!")
        return
    end

    -- Temporary fix?
    local temp_group = unit.surface.create_unit_group{position = unit.position}
    temp_group.add_member(unit)

    local combined_commands = {}

    -- Build a base (a few attempts)
    table.insert(combined_commands, {type = defines.command.build_base,
                                        destination = target_pos,
                                        ignore_planner = true,
                                        distraction = defines.distraction.by_enemy})
    table.insert(combined_commands, {type = defines.command.build_base,
                                        destination = {x=target_pos.x+math.random(-64,64),
                                                        y=target_pos.y+math.random(-64,64)},
                                        ignore_planner = true,
                                        distraction = defines.distraction.by_enemy})
    table.insert(combined_commands, {type = defines.command.build_base,
                                        destination = {x=target_pos.x+math.random(-64,64),
                                                        y=target_pos.y+math.random(-64,64)},
                                        ignore_planner = true,
                                        distraction = defines.distraction.by_enemy})

    -- Last resort is wander and attack anything in the area
    table.insert(combined_commands, {type = defines.command.wander,
                                        distraction = defines.distraction.by_anything})

    -- Execute all commands in sequence regardless of failures.
    local compound_command =
    {
        type = defines.command.compound,
        structure_type = defines.compound_command.return_last,
        commands = combined_commands
    }

    -- Temporary fix?
    temp_group.set_command(compound_command)
end