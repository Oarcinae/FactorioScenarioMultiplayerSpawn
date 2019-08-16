-- oarc_enemies_tick_logic.lua
-- Aug 2019
--
-- Holds all the code related to the the on_tick "state machine"
-- Where we process on going attacks step by step.

function OarcEnemiesOnTick()

    -- Cleanup attacks that have died or somehow become invalid.
    if ((game.tick % (TICKS_PER_SECOND)) == 20) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackCleanupInvalidGroups(key, attack) then break end
        end
    end

    -- Process player timers
    if ((game.tick % (TICKS_PER_SECOND)) == 21) then
        ProcessPlayerTimersEverySecond()
    end

    -- OE_PROCESS_STG_FIND_TARGET
    -- Find target given request type
    if ((game.tick % (TICKS_PER_SECOND)) == 22) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackFindTarget(key, attack) then break end
        end
    end

    -- OE_PROCESS_STG_FIND_SPAWN
    -- Find spawn location
    if ((game.tick % (TICKS_PER_SECOND)) == 23) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackFindSpawn(key, attack) then break end
        end
    end

    -- OE_PROCESS_STG_SPAWN_PATH_REQ
    -- Find path
    if ((game.tick % (TICKS_PER_SECOND)) == 24) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackCheckPathFromSpawn(key, attack) then break end
        end
    end

    -- OE_PROCESS_STG_SPAWN_PATH_CALC -- WAIT FOR EVENT
    -- Event Function: ProcessAttackCheckPathComplete(event)

    -- OE_PROCESS_STG_CREATE_GROUP
    -- Spawn group
    if ((game.tick % (TICKS_PER_SECOND)) == 25) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackCreateGroup(key, attack) then break end
        end
    end

    -- OE_PROCESS_STG_CMD_GROUP
    -- Send group on attack
    if ((game.tick % (TICKS_PER_SECOND)) == 26) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackCommandGroup(key, attack) then break end
        end
    end

    -- OE_PROCESS_STG_GROUP_ACTIVE -- ACTIVE STATE, WAIT FOR EVENT
    -- Event Function: OarcEnemiesGroupCmdFailed(event)

    -- OE_PROCESS_STG_CMD_FAILED
    -- Handle failed groups?
    if ((game.tick % (TICKS_PER_SECOND)) == 27) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackCommandFailed(key, attack) then break end
        end
    end

    -- OE_PROCESS_STG_FALLBACK_ATTACK
    -- Attempt fallback attack on general area of target
    if ((game.tick % (TICKS_PER_SECOND)) == 28) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackFallbackAttack(key, attack) then break end
        end
    end

    -- OE_PROCESS_STG_FALLBACK_FINAL
    -- Final fallback just abandons attack and sets the group to autonomous
    if ((game.tick % (TICKS_PER_SECOND)) == 29) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackFallbackAuto(key, attack) then break end
        end
    end

    -- OE_PROCESS_STG_RETRY_PATH_REQ
    -- Handle pathing retries
    if ((game.tick % (TICKS_PER_SECOND)) == 30) then
        for key,attack in pairs(global.oe.attacks) do
            if ProcessAttackRetryPath(key, attack) then break end
        end
    end

    -- OE_PROCESS_STG_RETRY_PATH_CALC -- WAIT FOR EVENT
    -- Event Function: ProcessAttackCheckPathComplete(event)

end


function ProcessAttackCleanupInvalidGroups(key, attack)
    if (attack.process_stg ~= OE_PROCESS_STG_GROUP_ACTIVE) and
    	(attack.process_stg ~= OE_PROCESS_STG_BUILD_BASE) then return false end

    if (not attack.group or not attack.group.valid) then
        log("ProcessAttackCleanupInvalidGroups - Group killed?")
        table.remove(global.oe.attacks, key)
        return true

    elseif (attack.group.state == defines.group_state.wander_in_group) then
        log("ProcessAttackCleanupInvalidGroups - Group done (wandering)?")
        EnemyGroupBuildBaseThenWander(attack.group, attack.group.position)
        global.oe.attacks[key].process_stg = OE_PROCESS_STG_BUILD_BASE
        return true
    end

    return false
end

function ProcessPlayerTimersEverySecond()
    for p_index,timer_table in pairs(global.oe.player_timers) do
        if (game.players[p_index] and game.players[p_index].connected) then

            for timer_name,timer_val in pairs(timer_table) do
                if (timer_val > 0) then
                    global.oe.player_timers[p_index][timer_name] = timer_val-1
                else
                    if (timer_name == "character") then
                        OarcEnemiesPlayerAttackCharacter(p_index)
                        global.oe.player_timers[p_index][timer_name] =
                            GetRandomizedPlayerTimer(game.players[p_index].online_time/TICKS_PER_SECOND, 0)

                    elseif (timer_name == "generic") then
                        OarcEnemiesBuildingAttack(p_index, OE_GENERIC_TARGETS)
                        global.oe.player_timers[p_index][timer_name] =
                            GetRandomizedPlayerTimer(game.players[p_index].online_time/TICKS_PER_SECOND, 0)
                    end
                end
            end
        end
    end
end

function ProcessAttackFindTarget(key, attack)

    if (attack.process_stg ~= OE_PROCESS_STG_FIND_TARGET) then return false end

    -- log("tick_log ProcessAttackFindTarget " .. game.tick)

    if (attack.attempts == 0) then
        log("attack.attempts = 0 - ATTACK FAILURE")
        table.remove(global.oe.attacks, key)
        return false
    end

    if (attack.target_player and attack.target_type) then

        local player = game.players[attack.target_player]

        -- Attack a building of the player, given a certain building type
        if (attack.target_type == OE_TARGET_TYPE_BUILDING) then

            local random_building = GetRandomBuildingAny(attack.target_player,
                                                            attack.building_types)

            if (random_building ~= nil) then
                global.oe.attacks[key].target_entity = random_building

                local e,s = GetEnemyGroup{player=player,
                                            force_index=player.force.index,
                                            surface=game.surfaces[GAME_SURFACE_NAME],
                                            target_pos=random_building.position}

                global.oe.attacks[key].size = s
                global.oe.attacks[key].evo = e
                global.oe.attacks[key].process_stg = OE_PROCESS_STG_FIND_SPAWN
                return true
            else
                log("No building found to attack.")
                table.remove(global.oe.attacks, key)
            end

        -- Attack a player directly
        elseif (attack.target_type == OE_TARGET_TYPE_PLAYER) then

            global.oe.attacks[key].target_entity = player.character

            local e,s = GetEnemyGroup{player=player,
                                            force_index=player.force.index,
                                            surface=game.surfaces[GAME_SURFACE_NAME],
                                            target_pos=player.character.position}

            global.oe.attacks[key].size = s
            global.oe.attacks[key].evo = e
            global.oe.attacks[key].process_stg = OE_PROCESS_STG_FIND_SPAWN
            return true
        end

    else
        log("ERROR - Missing info in attack - target_player or target_type!" .. key)
    end

    return false
end


function ProcessAttackFindSpawn(key, attack)

    if (attack.process_stg ~= OE_PROCESS_STG_FIND_SPAWN) then return false end

    -- log("tick_log ProcessAttackFindSpawn " .. game.tick)

    if (attack.attempts == 0) then
        log("attack.attempts = 0 - ProcessAttackFindSpawn FAILURE")
        table.remove(global.oe.attacks, key)
        return false
    end

    if (attack.target_entity or attack.target_chunk) then

        -- Invalid entity check?
        if (attack.target_entity and not attack.target_entity.valid) then
            global.oe.attacks[key].target_entity = nil
            global.oe.attacks[key].attempts = attack.attempts - 1
            global.oe.attacks[key].process_stg = OE_PROCESS_STG_FIND_TARGET
            return false
        end

        -- Use entity or target chunk info to start search
        local c_pos
        if (attack.target_entity) then
            c_pos = GetChunkPosFromTilePos(attack.target_entity.position)
            global.oe.attacks[key].target_chunk = c_pos -- ALWAYS SET FOR BACKUP
        elseif (attack.target_chunk) then
            c_pos = attack.target_chunk
        end
        local spawns = SpiralSearch(c_pos, OE_ATTACK_SEARCH_RADIUS_CHUNKS, 5, OarcEnemiesDoesChunkHaveSpawner)

        if (spawns ~= nil) then
            global.oe.attacks[key].spawn_chunk = spawns[GetRandomKeyFromTable(spawns)]
            global.oe.attacks[key].process_stg = OE_PROCESS_STG_SPAWN_PATH_REQ
        else
            log("Could not find a spawn near target...")
            global.oe.attacks[key].target_entity = nil
            global.oe.attacks[key].attempts = attack.attempts - 1
            global.oe.attacks[key].process_stg = OE_PROCESS_STG_FIND_TARGET
        end

        return true
    else
        log("Missing attack info: target_entity or target_chunk!" .. key)
    end

    return false
end


function ProcessAttackCheckPathFromSpawn(key, attack)

    if (attack.process_stg ~= OE_PROCESS_STG_SPAWN_PATH_REQ) then return false end

    -- log("tick_log ProcessAttackCheckPathFromSpawn " .. game.tick)

    if (attack.attempts == 0) then
        log("attack.attempts = 0 - ProcessAttackCheckPathFromSpawn FAILURE")
        table.remove(global.oe.attacks, key)
        return false
    end

    if (attack.spawn_chunk) then

        -- Check group doesn't already exist
        if (attack.group and attack.group_id and attack.group.valid) then
            log("ERROR - group should not be valid - ProcessAttackCheckPathFromSpawn!")
            table.remove(global.oe.attacks, key)
            return false
        end

        -- Find a large area that is free to spawn biters in
        local spawn_pos = game.surfaces[GAME_SURFACE_NAME].find_non_colliding_position("rocket-silo",
                                            GetCenterTilePosFromChunkPos(attack.spawn_chunk),
                                            32,
                                            1)
        global.oe.attacks[key].spawn_pos = spawn_pos

        if (not spawn_pos) then
        	log("No space to spawn? ProcessAttackCheckPathFromSpawn")
        	global.oe.attacks[key].attempts = attack.attempts - 1
        	return false
        end

        local target_pos = nil
        if (attack.target_entity and attack.target_entity.valid) then
            target_pos = attack.target_entity.position
        elseif (attack.target_chunk) then
            target_pos = GetCenterTilePosFromChunkPos(attack.target_chunk)
        end

        if (not target_pos) then
            log("Lost target during ProcessAttackCheckPathFromSpawn")
            global.oe.attacks[key].target_entity = nil
            global.oe.attacks[key].target_chunk = nil
            global.oe.attacks[key].attempts = attack.attempts - 1
            global.oe.attacks[key].process_stg = OE_PROCESS_STG_FIND_TARGET
            return false
        end

        global.oe.attacks[key].path_id = game.surfaces[GAME_SURFACE_NAME].request_path{bounding_box={{0,0},{0,0}},
                                                        collision_mask={"player-layer"},
                                                        start=spawn_pos,
                                                        goal=target_pos,
                                                        force=game.forces["enemy"],
                                                        radius=8,
                                                        pathfind_flags={low_priority=true},
                                                        can_open_gates=false,
                                                        path_resolution_modifier=-1}
        global.oe.attacks[key].process_stg = OE_PROCESS_STG_SPAWN_PATH_CALC
        return true
    else
        log("ERROR - Missing attack info: spawn_chunk or path_id!" .. key)
    end

    return false
end


function ProcessAttackCheckPathComplete(event)
    if (not event.id) then return end
    local path_success = (event.path ~= nil)

    -- Debug help info
    if (path_success) then
        if (global.oe_render_paths) then
            RenderPath(event.path, TICKS_PER_MINUTE, game.connected_players)
        end
    else
        log("WARN - on_script_path_request_finished: FAILED")
        if (event.try_again_later) then
            log("ERROR - on_script_path_request_finished: TRY AGAIN LATER?")
        end
    end

    for key,attack in pairs(global.oe.attacks) do
        if (attack.path_id == event.id) then

            local group_exists_already = (attack.group and attack.group_id and attack.group.valid)

            -- First time path check before a group is spawned
            if (attack.process_stg == OE_PROCESS_STG_SPAWN_PATH_CALC) then
                if (group_exists_already) then
                    log("ERROR - OE_PROCESS_STG_SPAWN_PATH_CALC has a valid group?!")
                    -- table.remove(global.oe.attacks, key)
                    return
                end

                if (path_success) then
                    global.oe.attacks[key].path = event.path
                    global.oe.attacks[key].process_stg = OE_PROCESS_STG_CREATE_GROUP
                else
                    global.oe.attacks[key].path_id = nil
                    global.oe.attacks[key].attempts = attack.attempts - 1
                    global.oe.attacks[key].process_stg = OE_PROCESS_STG_FIND_TARGET
                end

            -- Retry path check on a command failure
            elseif  (attack.process_stg == OE_PROCESS_STG_RETRY_PATH_CALC) then

                if (not group_exists_already) then
                    log("ERROR - OE_PROCESS_STG_RETRY_PATH_CALC has NO valid group?!")
                    -- table.remove(global.oe.attacks, key)
                    return
                end

                if (path_success) then
                    global.oe.attacks[key].path = event.path
                    global.oe.attacks[key].process_stg = OE_PROCESS_STG_CMD_GROUP
                else
                    log("Group can no longer path to target. Performing fallback attack instead" .. attack.group_id)
                    global.oe.attacks[key].path_id = nil
                    global.oe.attacks[key].attempts = attack.attempts - 1
                    global.oe.attacks[key].process_stg = OE_PROCESS_STG_FALLBACK_ATTACK
                end

            else
                log("Path calculated but process stage is wrong!??!")
            end

            return
        end
    end
end


function ProcessAttackCreateGroup(key, attack)
    if (attack.process_stg ~= OE_PROCESS_STG_CREATE_GROUP) then return false end

    -- log("tick_log ProcessAttackCreateGroup " .. game.tick)

    if (attack.attempts == 0) then
        log("attack.attempts = 0 - ProcessAttackCreateGroup FAILURE")
        table.remove(global.oe.attacks, key)
        return false
    end

    if (attack.group_id == nil) then
        local group = CreateEnemyGroupGivenEvoAndCount(game.surfaces[GAME_SURFACE_NAME],
                                                        attack.spawn_pos,
                                                        attack.evo,
                                                        attack.size)
        global.oe.attacks[key].group_id = group.group_number
        global.oe.attacks[key].group = group
        global.oe.attacks[key].process_stg = OE_PROCESS_STG_CMD_GROUP

        -- On the first time the player has a direct attack, warn them?
        if (attack.target_type == OE_TARGET_TYPE_PLAYER) and
           (not global.oe.player_sbubbles[attack.target_player].uh_oh) then
            DisplaySpeechBubble(game.players[attack.target_player],
                                "Uh oh... Something is coming for me!", 10)
            global.oe.player_sbubbles[attack.target_player].uh_oh = true
        end

        return true
    else
        log("ERROR - ProcessAttackCreateGroup already has a group?" .. key)
    end

    return false
end


function ProcessAttackCommandGroup(key, attack)
    if (attack.process_stg ~= OE_PROCESS_STG_CMD_GROUP) then return false end

    -- log("tick_log ProcessAttackCommandGroup " .. game.tick)

    if (attack.attempts == 0) then
        log("attack.attempts = 0 - ProcessAttackCommandGroup FAILURE")
        table.remove(global.oe.attacks, key)
        return false
    end

    -- Sanity check we have a group and a path
    if (attack.group_id and attack.group and attack.group.valid) then

        -- If we have a target entity, attack that.
        if (attack.target_entity and attack.target_entity.valid and attack.path_id) then
            EnemyGroupGoAttackEntityThenWander(attack.group, attack.target_entity, attack.path)
            global.oe.attacks[key].process_stg = OE_PROCESS_STG_GROUP_ACTIVE
            return true

        -- If we have a target chunk, attack that area.
        elseif (attack.target_chunk) then
            EnemyGroupAttackAreaThenWander(attack.group,
                                            GetCenterTilePosFromChunkPos(attack.target_chunk),
                                            CHUNK_SIZE*2)
            global.oe.attacks[key].process_stg = OE_PROCESS_STG_GROUP_ACTIVE
            return true

        -- Otherwise, shit's fucked
        else
            log("ProcessAttackCommandGroup invalid target?" .. key)
            global.oe.attacks[key].path_id = nil
            global.oe.attacks[key].attempts = attack.attempts - 1
            global.oe.attacks[key].process_stg = OE_PROCESS_STG_FIND_TARGET
            return false
        end
    else
        log("ProcessAttackCommandGroup invalid group?" .. key)
    end

    return false
end


function OarcEnemiesGroupCmdFailed(event)
    local attack_key = FindAttackKeyFromGroupIdNumber(event.unit_number)

    -- This group cmd failure is not associated with an attack. Must be a unit or something.
    if (not attack_key) then return end

    local attack = global.oe.attacks[attack_key]

    -- Is group no longer valid?
    if (not attack.group or not attack.group.valid) then
        log("OarcEnemiesGroupCmdFailed group not valid anymore")
        table.remove(global.oe.attacks, attack_key)
        return
    end

    -- Check if it's a fallback attack.
    if (attack.target_type == OE_TARGET_TYPE_AREA) then
        global.oe.attacks[attack_key].process_stg = OE_PROCESS_STG_FALLBACK_FINAL

    -- Else handle failure based on attack type.
    else
        global.oe.attacks[attack_key].process_stg = OE_PROCESS_STG_CMD_FAILED
    end
end


function ProcessAttackCommandFailed(key, attack)
    if (attack.process_stg ~= OE_PROCESS_STG_CMD_FAILED) then return false end

    -- log("tick_log ProcessAttackCommandFailed " .. game.tick)

    if (attack.attempts == 0) then
        log("attack.attempts = 0 - ProcessAttackCommandFailed FAILURE")
        table.remove(global.oe.attacks, key)
        return false
    end

    -- If we fail to attack the player, it likely means the player moved.
    -- So we try to retry pathing so we can "chase" the player.
    if (attack.target_type == OE_TARGET_TYPE_PLAYER) then
        global.oe.attacks[key].process_stg = OE_PROCESS_STG_RETRY_PATH_REQ
        return true

    -- Fallback for all other attack types is to attack the general area instead.
    -- Might add other special cases here later.
    else
        log("ProcessAttackCommandFailed - performing fallback now?")
        global.oe.attacks[key].attempts = attack.attempts - 1
        global.oe.attacks[key].process_stg = OE_PROCESS_STG_FALLBACK_ATTACK
        return true
    end

    return false
end


function ProcessAttackFallbackAttack(key, attack)
    if (attack.process_stg ~= OE_PROCESS_STG_FALLBACK_ATTACK) then return false end

    -- log("tick_log ProcessAttackFallbackAttack " .. game.tick)

    if (attack.group_id and attack.group and attack.group.valid and attack.target_chunk) then

        EnemyGroupAttackAreaThenWander(attack.group,
                                      GetCenterTilePosFromChunkPos(attack.target_chunk),
                                      CHUNK_SIZE*2)
        global.oe.attacks[key].target_type = OE_TARGET_TYPE_AREA
        global.oe.attacks[key].process_stg = OE_PROCESS_STG_GROUP_ACTIVE
        return true
    else
        log("ProcessAttackFallbackAttack invalid group or target?" .. key)
    end

    return false
end


function ProcessAttackFallbackAuto(key, attack)
    if (attack.process_stg ~= OE_PROCESS_STG_FALLBACK_FINAL) then return false end

    -- log("tick_log ProcessAttackFallbackAuto " .. game.tick)

    if (attack.group and attack.group.valid) then
        log("ProcessAttackFallbackAuto - Group now autonomous...")
        attack.group.set_autonomous()
    else
        log("ProcessAttackFallbackAuto - Group no longer valid!")
    end

    table.remove(global.oe.attacks, key)
    return true
end


function ProcessAttackRetryPath(key, attack)

    if (attack.process_stg ~= OE_PROCESS_STG_RETRY_PATH_REQ) then return false end

    -- log("tick_log ProcessAttackRetryPath " .. game.tick)

    -- Validation checks
    if ((attack.target_type ~= OE_TARGET_TYPE_PLAYER) or
        (attack.attempts == 0) or
        (not attack.target_entity) or
        (not attack.target_entity.valid)) then
        log("ProcessAttackRetryPath FAILURE")
        if (attack.group and attack.group.valid) then
            attack.group.set_autonomous()
        end
        table.remove(global.oe.attacks, key)
        return false
    end

    -- Check group still exists
    if (attack.group and attack.group_id and attack.group.valid) then

        -- Path request
        global.oe.attacks[key].path_id =
            game.surfaces[GAME_SURFACE_NAME].request_path{bounding_box={{0,0},{0,0}},
                                            collision_mask={"player-layer"},
                                            start=attack.group.members[1].position,
                                            goal=attack.target_entity.position,
                                            force=game.forces["enemy"],
                                            radius=8,
                                            pathfind_flags={low_priority=true},
                                            can_open_gates=false,
                                            path_resolution_modifier=-1}
        global.oe.attacks[key].process_stg = OE_PROCESS_STG_RETRY_PATH_CALC
        return true

    else
        log("ERROR - group should BE valid - ProcessAttackRetryPath!")
        table.remove(global.oe.attacks, key)
        return false
    end

    return false
end