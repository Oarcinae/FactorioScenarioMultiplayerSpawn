-- oarc_enemies.lua
-- Feb 2020

-- This is my second attempt at modifying the normal enemy experience. The
-- first attempt ended up in a wave attack system which wasn't well received.
-- This attempt will try to intercept normal vanilla enemy groups and modify
-- them based on player activity.

-- Basic logic:
-- 	on_unit_group_finished_gathering we check what command is given.
-- 	find destination position
--  check for closest "player" using find_nearest_enemy function
--  if a player is found, check if player is part of a shared spawn
--  Remove the enemy group if no player in the shared spawn is online.

-- TODO:
--  Add options for modifying the default waves or spawning additional special waves.
--  Add option to disable attacks completely for a given spawn.

-- Generic Utility Includes
require("lib/oarc_utils")

function OarcModifyEnemyGroup(group)

	-- Check validity
	if ((group == nil) or (group.command == nil) or (group.force.name ~= "enemy")) then
		log("OarcModifyEnemyGroup ignoring INVALID group/command")
		return
	end

	-- Make sure the attack is of a TYPE that we care about.
	if ((group.command.type == defines.command.attack) or 
		(group.command.type == defines.command.attack_area) or 
		(group.command.type == defines.command.build_base)) then
		log("OarcModifyEnemyGroup MODIFYING command TYPE=" .. group.command.type)
	else
		log("OarcModifyEnemyGroup ignoring command TYPE=" .. group.command.type)
		return
	end

	-- defines.command.attack --> target --> target.position
	if (group.command.type == defines.command.attack) then
		log("OarcModifyEnemyGroup defines.command.attack NOT IMPLEMENTED YET!")
		return
	
	-- defines.command.attack_area --> destination --> closest enemy (within 3 chunk radius?)
	-- defines.command.build_base --> destination --> closest enemy (expansion chunk distance?)
	else
		local destination = group.command.destination

		local distance = CHUNK_SIZE*3
		if (group.command.type == defines.command.build_base) then
			distance = CHUNK_SIZE*7 --game.map_settings.enemy_expansion.max_expansion_distance
		end

		local target_entity = group.surface.find_nearest_enemy{position=destination,
																max_distance=distance,
																force="enemy"}
        -- No enemies nearby?
        if (target_entity == nil) then
        	if (group.command.type == defines.command.attack_area) then
        		SendBroadcastMsg("OarcModifyEnemyGroup find_nearest_enemy attack_area FAILED!?!?")
        		log("OarcModifyEnemyGroup UNEXPECTED find_nearest_enemy did not find anything!")
        	else
        		log("OarcModifyEnemyGroup find_nearest_enemy did not find anything!")
        	end
        	return
        end

        -- Probably don't need this I hope?
        if (target_entity.force == "neutral") then
        	log("OarcModifyEnemyGroup UNEXPECTED find_nearest_enemy found neutral target?")
        	return
        end

        local target_player = target_entity.last_user

        -- I don't think this should happen often...
        if (target_player == nil) then
        	SendBroadcastMsg("ERROR?? target_player == nil " .. GetGPStext(group.members[1].position) .. " Target: " .. GetGPStext(target_entity.position))
        	return
        end
        if (not target_player.valid) then
        	SendBroadcastMsg("ERROR?? not target_player.valid " .. GetGPStext(group.members[1].position) .. " Target: " .. GetGPStext(target_entity.position))
        	return
        end

        -- Is the target player online? Then the attack can go through.
        if (target_player.connected) then
        	SendBroadcastMsg("Enemy group released: " .. GetGPStext(group.members[1].position) .. " Target: " .. GetGPStext(target_entity.position) .. " " .. target_player.name)
        	log("OarcModifyEnemyGroup RELEASING enemy group since player is ONLINE")
        	return
        end

        -- Find the shared spawn that the player is part of.
        -- This could be the own player's spawn (quite likely)
        local sharedSpawnOwner = FindPlayerSharedSpawn(target_player.name)

        -- Is someone in the shared spawn online?
        if (sharedSpawnOwner ~= nil) then
	        if (GetOnlinePlayersAtSharedSpawn(sharedSpawnOwner) > 0) then
	        	SendBroadcastMsg("Enemy group released: " .. GetGPStext(group.members[1].position) .. " Target: " .. GetGPStext(target_entity.position) .. " " .. target_player.name)
	        	log("OarcModifyEnemyGroup RELEASING enemy group since someone in the group is ONLINE")
	        	return
	        end
        end

        -- Otherwise, we delete the group.
        SendBroadcastMsg("Enemy group deleted: " .. GetGPStext(group.members[1].position) .. " Target: " .. GetGPStext(target_entity.position) .. " " .. target_player.name)
        for _,member in pairs(group.members) do
        	member.destroy()
        end
        log("OarcModifyEnemyGroup REMOVED enemy group since nobody was online?")
	end
end