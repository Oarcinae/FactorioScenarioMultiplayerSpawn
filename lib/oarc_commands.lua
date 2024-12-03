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

    RemoveOrResetPlayer(target_player, true)
end)