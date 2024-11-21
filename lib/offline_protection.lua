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
    if ((group.command == nil) or (group.force.name ~= "enemy")) then
        log("WARN - OarcModifyEnemyGroup ignoring INVALID group/command " .. serpent.block(group))
        return
    end

    -- Make sure the attack is of a TYPE that we care about.
    if ((group.command.type ~= defines.command.attack_area) and
        (group.command.type ~= defines.command.build_base)) then
        -- log("OarcModifyEnemyGroup ignoring command TYPE=" .. group.command.type)
        return
    end

    -- For these 2 commands, we look around to find the nearest player.
    -- defines.command.attack_area --> destination --> closest player (within 3 chunk radius?)
    -- defines.command.build_base --> destination --> closest player (expansion chunk distance?)

    local destination = group.command.destination

    local search_radius = CHUNK_SIZE * 3 -- Just a reasonable default search size I think?
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
        -- There are 2 Known cases where this can happen:
        -- Either (group.command.type == defines.command.attack_area) in which case it is likely a player attacking bases with nukes.
        -- OR
        -- The enemy group is just expanding / building bases.

        -- If we really have an edge case, then so be it, let it go through.

        -- In both cases, we don't want to stop the enemy group.
        return
    end

    -- Most common target will be a built entity with a "last_user"
    local target_player = target_entity.last_user

    -- I don't think this should happen ever...
    if ((target_player == nil) or (not target_player.valid)) then
        log("ERROR - OarcModifyEnemyGroup target_player nil/invalid?" .. serpent.block(group))
        -- for _,member in pairs(group.members) do
        --     member.destroy()
        -- end
        return
    end

    -- Is the target player online? Then the attack can go through.
    if (target_player.connected) then
        -- log("OarcModifyEnemyGroup RELEASING enemy group since player is ONLINE " .. target_player.name)
        return
    end

    -- Find the shared spawn that the player is part of.
    -- This could be the own player's spawn (quite likely)
    local online_players = GetPlayersFromSameSpawn(target_player.name, false)

    -- Is someone in the group online?
    if (#online_players > 0) then
        -- log("OarcModifyEnemyGroup RELEASING enemy group since someone in the group is ONLINE " .. target_player.name)
        return
    end

    -- Otherwise, we delete the group.
    for _,member in pairs(group.members) do
        member.destroy()
    end
    -- log("OarcModifyEnemyGroup REMOVED enemy group since nobody was online? " .. target_player.name)
end