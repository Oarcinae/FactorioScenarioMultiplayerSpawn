-- rocket_launch.lua
-- May 2019

-- This is meant to extract out any rocket launch related logic to support my oarc scenario designs.

require("lib/oarc_utils")
require("config")

--------------------------------------------------------------------------------
-- Rocket Launch Event Code
-- Controls the "win condition"
--------------------------------------------------------------------------------
function RocketLaunchEvent(event)
    local force = event.rocket.force
    
    -- Notify players on force if rocket was launched without sat.
    if event.rocket.get_item_count("satellite") == 0 then
        for index, player in pairs(force.players) do
            player.print("You launched the rocket, but you didn't put a satellite inside.")
        end
        return
    end

    -- First ever sat launch
    if not global.satellite_sent then
        global.satellite_sent = {}
        SendBroadcastMsg("Team " .. event.rocket.force.name .. " was the first to launch a rocket!")
        ServerWriteFile("rocket_events", "Team " .. event.rocket.force.name .. " was the first to launch a rocket!" .. "\n")

		for name,player in pairs(game.connected_players) do
	        CreateRocketGui(player)
	    end
    end

    -- Track additional satellites launched by this force
    if global.satellite_sent[force.name] then
        global.satellite_sent[force.name] = global.satellite_sent[force.name] + 1   
        ServerWriteFile("rocket_events", "Team " .. event.rocket.force.name .. " launched another rocket. Total " .. global.satellite_sent[force.name] .. "\n")

    -- First sat launch for this force.
    else
        -- game.set_game_state{game_finished=true, player_won=true, can_continue=true}
        global.satellite_sent[force.name] = 1
        ServerWriteFile("rocket_events", "Team " .. event.rocket.force.name .. " launched their first rocket!" .. "\n")

        -- Unlock research
        if LOCK_GOODIES_UNTIL_ROCKET_LAUNCH then
            EnableTech(force, "atomic-bomb")
            EnableTech(force, "power-armor-mk2")
            EnableTech(force, "artillery")

            if (force.technologies["speed-module-3"].researched) then
		    	AddRecipe(force, "speed-module-3")
		    end
		    if (force.technologies["productivity-module-3"].researched) then
		    	AddRecipe(force, "productivity-module-3")
		    end
        end
    end
end


function CreateRocketGui(player)
    if mod_gui.get_button_flow(player)["rocket-score"] == nil then
        mod_gui.get_button_flow(player).add{name="rocket-score", type="button", caption="Rockets", style=mod_gui.button_style}
    end   
end


local function ExpandRocketGui(player)
    local frame = player.gui.left["rocket-panel"]
    if (frame) then
        frame.destroy()
    else
        local frame = player.gui.left.add{type="frame", name="rocket-panel", caption="Satellites Launched:", direction = "vertical"}

        for force_name,sat_count in pairs(global.satellite_sent) do
        	frame.add{name="rc_"..force_name, type = "label",
    					caption="Team " .. force_name .. ": " .. tostring(sat_count)}
        end
    end
end

function RocketGuiClick(event) 
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.element.player_index]
    local name = event.element.name

    if (name == "rocket-score") then
        ExpandRocketGui(player)        
    end
end
