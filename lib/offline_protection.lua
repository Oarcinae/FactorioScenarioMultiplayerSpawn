-- This attempt will try to intercept normal vanilla enemy groups and modify them based on player activity.

-- Basic logic:
--  on_unit_group_finished_gathering we check what command is given.
--  find destination position
--  check for closest "player" using find_nearest_enemy function
--  if a player is found, check if player is part of a shared spawn
--  Remove the enemy group if no player in the shared spawn is online.

-- Generic Utility Includes
require("lib/oarc_utils")

---This function is called when a unit group finishes gathering.
---@param event EventData.on_unit_group_finished_gathering
---@return nil
function OarcModifyEnemyGroup(event)

    local group = event.group

    -- Check validity
    if ((group == nil) or (group.command == nil) or not TableContains(ENEMY_FORCES_NAMES, group.force.name)) then
        log("OarcModifyEnemyGroup ignoring INVALID group/command")
        return
    end

    -- Make sure the attack is of a TYPE that we care about.
    if ((group.command.type == defines.command.attack_area) or 
        (group.command.type == defines.command.build_base)) then
        -- log("OarcModifyEnemyGroup MODIFYING command TYPE=" .. group.command.type)
    else
        -- log("OarcModifyEnemyGroup ignoring command TYPE=" .. group.command.type)
        return
    end

    -- (group.command.type == defines.command.attack) or  
    -- defines.command.attack --> target --> target.position
    -- if (group.command.type == defines.command.attack) then
    --     log("OarcModifyEnemyGroup defines.command.attack NOT IMPLEMENTED YET!")
    --     return
    -- end

    -- defines.command.attack_area --> destination --> closest enemy (within 3 chunk radius?)
    -- defines.command.build_base --> destination --> closest enemy (expansion chunk distance?)

    local destination = group.command.destination

    local search_radius = CHUNK_SIZE*3
    if (group.command.type == defines.command.build_base) then
        search_radius = CHUNK_SIZE * (game.map_settings.enemy_expansion.max_expansion_distance)
    end

    -- Look for any player force targets near the destination point.
    local target_entities = group.surface.find_entities_filtered{
                                            position=destination,
                                            radius=search_radius,
                                            force=ENEMY_FORCES_NAMES_INCL_NEUTRAL,
                                            limit=50,
                                            invert=true}

    -- Search through them all to find anything with a non-nil last_user.
    local target_entity = nil
    for _,target in ipairs(target_entities) do
        if (target.last_user ~= nil) then
            target_entity = target
            break
        end
    end

    -- No targets found with a last_user
    if (target_entity == nil) then

        -- This is unexpected, not sure under which conditions this would happen.
        if (group.command.type == defines.command.attack_area) then
            -- SendBroadcastMsg("OarcModifyEnemyGroup find_nearest_enemy attack_area FAILED!?!? " .. GetGPStext(group.surface.name, group.position) .. " Target: " .. GetGPStext(group.surface.name, group.command.destination))
            log("ERROR - OarcModifyEnemyGroup find_nearest_enemy attack_area FAILED!?!?")
            -- for _,member in pairs(group.members) do
            --     member.destroy()
            -- end
        
        -- This is fine, as the enemy group is just expanding / building bases
        else
            -- log("OarcModifyEnemyGroup find_nearest_enemy did not find anything!")
        end
        return
    end

    -- Most common target will be a built entity with a "last_user"
    local target_player = target_entity.last_user

    -- -- Target could also be a player character (more rare)
    -- if (target_player == nil) and (target_entity.type == "character") then
    --     target_player = target_entity.player
    -- end

    -- I don't think this should happen ever...
    if ((target_player == nil) or (not target_player.valid)) then
        -- SendBroadcastMsg("ERROR?? target_player nil/invalid " .. GetGPStext(group.surface.name, group.position) .. " Target: " .. GetGPStext(group.surface.name, target_entity.position))
        log("ERROR - OarcModifyEnemyGroup target_player nil/invalid?")
        -- for _,member in pairs(group.members) do
        --     member.destroy()
        -- end
        return
    end

    -- Is the target player online? Then the attack can go through.
    if (target_player.connected) then
        -- SendBroadcastMsg("Enemy group released (player): " .. GetGPStext(group.surface.name, group.position) .. " Target: " .. GetGPStext(group.surface.name, target_entity.position) .. " " .. target_player.name)
        -- log("OarcModifyEnemyGroup RELEASING enemy group since player is ONLINE " .. target_player.name)
        return
    end

    -- Find the shared spawn that the player is part of.
    -- This could be the own player's spawn (quite likely)
    local online_players = GetPlayersFromSameSpawn(target_player.name, false)

    -- Is someone in the group online?
    if (#online_players > 0) then
        -- SendBroadcastMsg("Enemy group released (shared): " .. GetGPStext(group.surface.name, group.position) .. " Target: " .. GetGPStext(group.surface.name, target_entity.position) .. " " .. target_player.name)
        -- log("OarcModifyEnemyGroup RELEASING enemy group since someone in the group is ONLINE " .. target_player.name)
        return
    end

    -- Otherwise, we delete the group.
    for _,member in pairs(group.members) do
        member.destroy()
    end
    -- SendBroadcastMsg("Enemy group deleted: " .. GetGPStext(group.surface.name, group.position) .. " Target: " .. GetGPStext(group.surface.name, target_entity.position) .. " " .. target_player.name)
    log("OarcModifyEnemyGroup REMOVED enemy group since nobody was online? " .. target_player.name)
    
end