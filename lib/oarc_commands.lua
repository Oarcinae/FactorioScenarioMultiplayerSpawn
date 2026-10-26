-- Add a command to let people call droppods to themselves
commands.add_command("oarc-wheres-my-cargo-pod", {"oarc-command-dude-wheres-my-cargo-pod"}, function(command)
    if command.player_index == nil then return end -- Ignore if it's not a player
    DudeWheresMyCargoPod(game.players[command.player_index])
end)

-- Allow spawn rerolls, admins can name another player
commands.add_command("oarc-reroll-spawn", {"oarc-command-reroll-spawn"}, function(command)
    if command.player_index == nil then return end -- Ignore if it's not a player
    local caller = game.players[command.player_index]

    local target = caller
    local player_name = string.match(command.parameter or "", "^%s*(%S+)")
    if (player_name ~= nil) then
        target = game.get_player(player_name)
        if (target == nil) then
            SendErrorMsg(caller, {"oarc-player-not-found", player_name})
            return
        end
    end

    RerollSpawn(caller, target)
end)

-- Trigger immediate regrowth cleanups
commands.add_command("oarc-trigger-cleanup", {"oarc-command-trigger-cleanup"}, function(command)

    -- Check if calling player is nil (server) OR if the player is an admin
    if command.player_index ~= nil and not game.get_player(command.player_index).admin then
        SendErrorMsg(game.players[command.player_index], {"oarc-command-not-admin-warning", command.name})
        return
    end

    TriggerCleanup()
end)

-- Cleanup a player base
commands.add_command("oarc-cleanup-player", {"oarc-command-cleanup-player"}, function(command)

    -- Check if calling player is nil (server) OR if the player is an admin
    if command.player_index ~= nil and not game.get_player(command.player_index).admin then
        SendErrorMsg(game.players[command.player_index], {"oarc-command-not-admin-warning", command.name})
        return
    end

    if command.parameter == nil then
        if command.player_index ~= nil then
            SendErrorMsg(game.players[command.player_index], {"oarc-command-cleanup-player-usage"})
        end
        return
    end

    local target_player = game.get_player(command.parameter)
    if target_player == nil then
        if command.player_index ~= nil then
            SendErrorMsg(game.players[command.player_index], {"oarc-command-cleanup-player-usage"})
        end
        return
    end

    if target_player.connected then
        if command.player_index ~= nil then
            SendErrorMsg(game.players[command.player_index], {"oarc-command-cleanup-player-online"})
        end
        return
    end

    RemoveOrResetPlayer(target_player, true)
end)

-- Admin test helper to look at the starting points
commands.add_command("oarc-tp-start", "Teleport to starting point <index> [surface], surface defaults to nauvis.", function(command)
    if command.player_index == nil then return end
    local player = game.players[command.player_index]
    if not player.admin then
        SendErrorMsg(player, {"oarc-command-not-admin-warning", command.name})
        return
    end

    local index, surface_name = string.match(command.parameter or "", "^%s*(%d+)%s*(%S*)")
    if (surface_name == nil) or (surface_name == "") then
        surface_name = "nauvis"
    end
    TeleportToStartingPoint(player, tonumber(index) or 0, surface_name)
end)

-- Admin test helper to send a player to another planet without flying there
commands.add_command("oarc-test-planet", "Send a player to a planet, creating a secondary spawn on its next free starting point if needed. <planet> [player], player defaults to you.", function(command)
    if command.player_index == nil then return end
    local admin = game.players[command.player_index]
    if not admin.admin then
        SendErrorMsg(admin, {"oarc-command-not-admin-warning", command.name})
        return
    end

    local planet_name, player_name = string.match(command.parameter or "", "^%s*(%S+)%s*(%S*)")
    if (planet_name == nil) then
        admin.print("Usage: /oarc-test-planet <planet> [player]")
        return
    end

    local target = admin
    if (player_name ~= "") then
        target = game.get_player(player_name)
        if (target == nil) then
            admin.print("No player named " .. player_name)
            return
        end
    end

    TestSendPlayerToPlanet(admin, target, planet_name)
end)
