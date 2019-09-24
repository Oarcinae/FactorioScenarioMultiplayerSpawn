-- admin_commands.lua
-- May 2019
-- 
-- Yay, admin commands!

require("lib/oarc_utils")

-- Give yourself or another player, power armor
commands.add_command("powerstart", "give a start kit", function(command)
    
    local player = game.players[command.player_index]
    local target = player
    
    if player ~= nil and player.admin then
        if (command.parameter ~= nil) then
        	if game.players[command.parameter] ~= nil then
        		target = game.players[command.parameter]
        	else
        		target.print("Invalid player target. Double check the player name?")
        		return
        	end
        end

        GiveQuickStartPowerArmor(target)
        player.print("Gave a powerstart kit to " .. target.name)
        target.print("You have been given a power armor starting kit!")
    end
end)
