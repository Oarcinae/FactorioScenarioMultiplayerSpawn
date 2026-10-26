-- Add a command to let people call droppods to themselves
commands.add_command("oarc-wheres-my-cargo-pod", {"oarc-command-dude-wheres-my-cargo-pod"}, function(command)
    if command.player_index == nil then return end -- Ignore if it's not a player
    DudeWheresMyCargoPod(game.players[command.player_index])
end)

-- Allow spawn rerolls
commands.add_command("oarc-reroll-spawn", {"oarc-command-reroll-spawn"}, function(command)
    if command.player_index == nil then return end -- Ignore if it's not a player
    RerollSpawn(game.players[command.player_index])
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

-- TEMPORARY: Prototype testing of MapGenSettings.starting_points
commands.add_command("oarc-test-starting-points", "Apply the 4x4 test starting points grid to nauvis and clear it.", function(command)
    if command.player_index ~= nil and not game.get_player(command.player_index).admin then
        SendErrorMsg(game.players[command.player_index], {"oarc-command-not-admin-warning", command.name})
        return
    end

    local surface = game.surfaces["nauvis"]
    ApplyTestStartingPoints(surface, true, "command")
    game.print("Applied " .. #surface.map_gen_settings.starting_points .. " starting points to nauvis and cleared it.")
end)

commands.add_command("oarc-tp-start", "Teleport to test starting point <1-16> [surface], surface defaults to nauvis.", function(command)
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
    TeleportToTestStartingPoint(player, tonumber(index) or 0, surface_name)
end)
