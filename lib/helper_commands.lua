-- helper_commands.lua
-- Jan 2018
-- None of this is my code.

require("lib/oarc_utils")

commands.add_command("run", "change player speed bonus", function(command)
    local player = game.players[command.player_index];
    if player ~= nil then
        if (command.parameter ~= nil) then
            if command.parameter == "fast" then
                player.character_running_speed_modifier = 1
            elseif command.parameter == "slow" then
                player.character_running_speed_modifier = 0
            else
                player.print("run fast | slow");
            end
        end
    end
end)

commands.add_command("handcraft", "change player speed bonus", function(command)
    local player = game.players[command.player_index];
    if player ~= nil then
        if (command.parameter ~= nil) then
            if command.parameter == "fast" then
                player.character_crafting_speed_modifier = 5
            elseif command.parameter == "slow" then
                player.character_crafting_speed_modifier = 0
            else
                player.print("handcraft fast | slow");
            end
        end
    end
end)

commands.add_command("mine", "change player speed bonus", function(command)
    local player = game.players[command.player_index];
    if player ~= nil then
        if (command.parameter ~= nil) then
            if command.parameter == "fast" then
                player.character_mining_speed_modifier = 2
            elseif command.parameter == "slow" then
                player.character_mining_speed_modifier = 0
            else
                player.print("mine fast | slow");
            end
        end
    end
end)

commands.add_command("kit", "give a start kit", function(command)
    local player = game.players[command.player_index];
    if player ~= nil and player.admin then
        local target = player
        if (command.parameter ~= nil) then
            target = game.players[command.parameter]
        end
        if target ~= nil then
            GivePlayerStarterItems(target);
            player.print("gave a kit to " .. target.name);
            target.print("you have been given a start kit");
        else
            player.print("no player " .. command.parameter);
        end
    end
end)