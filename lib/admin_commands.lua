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


commands.add_command("load-quickbar", "Pre-load quickbar shortcuts", function(command)

    local p = game.players[command.player_index]

    -- 1st Row
    p.set_quick_bar_slot(1, "transport-belt");
    p.set_quick_bar_slot(2, "small-electric-pole");
    p.set_quick_bar_slot(3, "inserter");
    p.set_quick_bar_slot(4, "underground-belt");
    p.set_quick_bar_slot(5, "splitter");

    p.set_quick_bar_slot(6, "coal");
    p.set_quick_bar_slot(7, "repair-pack");
    p.set_quick_bar_slot(8, "gun-turret");
    p.set_quick_bar_slot(9, "stone-wall");
    p.set_quick_bar_slot(10, "radar");

    -- 2nd Row
    p.set_quick_bar_slot(11, "stone-furnace");
    p.set_quick_bar_slot(12, "wooden-chest");
    p.set_quick_bar_slot(13, "steel-chest");
    p.set_quick_bar_slot(14, "assembling-machine-1");
    p.set_quick_bar_slot(15, "assembling-machine-2");

    p.set_quick_bar_slot(16, nil);
    p.set_quick_bar_slot(17, nil);
    p.set_quick_bar_slot(18, nil);
    p.set_quick_bar_slot(19, nil);
    p.set_quick_bar_slot(20, nil);

    -- 3rd Row
    p.set_quick_bar_slot(21, "electric-mining-drill");
    p.set_quick_bar_slot(22, "fast-inserter");
    p.set_quick_bar_slot(23, "long-handed-inserter");
    p.set_quick_bar_slot(24, "medium-electric-pole");
    p.set_quick_bar_slot(25, "big-electric-pole");

    p.set_quick_bar_slot(26, "stack-inserter");
    p.set_quick_bar_slot(27, nil);
    p.set_quick_bar_slot(28, nil);
    p.set_quick_bar_slot(29, nil);
    p.set_quick_bar_slot(30, nil);

    -- 4th Row
    p.set_quick_bar_slot(31, "fast-transport-belt");
    p.set_quick_bar_slot(32, "medium-electric-pole");
    p.set_quick_bar_slot(33, "fast-inserter");
    p.set_quick_bar_slot(34, "fast-underground-belt");
    p.set_quick_bar_slot(35, "fast-splitter");

    p.set_quick_bar_slot(36, "stone-wall");
    p.set_quick_bar_slot(37, "repair-pack");
    p.set_quick_bar_slot(38, "gun-turret");
    p.set_quick_bar_slot(39, "laser-turret");
    p.set_quick_bar_slot(40, "radar");

    -- 5th Row
    p.set_quick_bar_slot(41, "train-stop");
    p.set_quick_bar_slot(42, "rail-signal");
    p.set_quick_bar_slot(43, "rail-chain-signal");
    p.set_quick_bar_slot(44, "rail");
    p.set_quick_bar_slot(45, "big-electric-pole");

    p.set_quick_bar_slot(46, "locomotive");
    p.set_quick_bar_slot(47, "cargo-wagon");
    p.set_quick_bar_slot(48, "fluid-wagon");
    p.set_quick_bar_slot(49, "pump");
    p.set_quick_bar_slot(50, "storage-tank");

    -- 6th Row
    p.set_quick_bar_slot(51, "oil-refinery");
    p.set_quick_bar_slot(52, "chemical-plant");
    p.set_quick_bar_slot(53, "storage-tank");
    p.set_quick_bar_slot(54, "pump");
    p.set_quick_bar_slot(55, nil);

    p.set_quick_bar_slot(56, "pipe");
    p.set_quick_bar_slot(57, "pipe-to-ground");
    p.set_quick_bar_slot(58, "assembling-machine-2");
    p.set_quick_bar_slot(59, "pump");
    p.set_quick_bar_slot(60, nil);

    -- 7th Row
    p.set_quick_bar_slot(61, "roboport");
    p.set_quick_bar_slot(62, "logistic-chest-storage");
    p.set_quick_bar_slot(63, "logistic-chest-passive-provider");
    p.set_quick_bar_slot(64, "logistic-chest-requester");
    p.set_quick_bar_slot(65, "logistic-chest-buffer");

    p.set_quick_bar_slot(66, "logistic-chest-active-provider");
    p.set_quick_bar_slot(67, "logistic-robot");
    p.set_quick_bar_slot(68, "construction-robot");
    p.set_quick_bar_slot(69, nil);
    p.set_quick_bar_slot(70, nil);

end)