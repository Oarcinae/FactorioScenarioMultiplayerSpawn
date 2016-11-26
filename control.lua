-- Oarc's Separated Spawn Scenario
-- I wanted to create a scenario that allows you to spawn in separate locations
-- Additionally, it allows you to either join the main force or go it alone.
-- All teams(forces) are always neutral to each other (ceasefire mode).
-- 
-- Each spawn location has some basic starter resources enforced, except for
-- the main default 0,0 starting location
-- 
-- Around each spawn area, a safe area is created and then a reduced alien areaas
-- as well. See config options for settings
-- 
-- When someone dies, they are given the option to join the default team
-- if they were not already.


-- To do:
-- Clean up text around spawn choices.
-- Make rocket silo more obvious, try to spawn a train station
-- Add longreach


require("event")
require("config")
require("rso_control") -- MUST LOAD THIS before other modifications to chunk generation
require("oarc_utils")
require("separate_spawns")
require("tag")

-- On init stuff
script.on_init(function(event)
    if ENABLE_SEPARATE_SPAWNS then
        -- For separate spawns stuff required on init
        InitSpawnGlobalsAndForces()

        -- Adjust alien params
        game.map_settings.enemy_evolution.time_factor=0
        game.map_settings.enemy_evolution.destroy_factor = game.map_settings.enemy_evolution.destroy_factor / ENEMY_DESTROY_FACTOR_DIVISOR
        game.map_settings.enemy_evolution.pollution_factor = game.map_settings.enemy_evolution.pollution_factor / ENEMY_POLLUTION_FACTOR_DIVISOR
        game.map_settings.enemy_expansion.enabled = ENEMY_EXPANSION
    end

    if FRONTIER_ROCKET_SILO_MODE then
        game.forces[MAIN_FORCE].chart(game.surfaces["nauvis"], {{SILO_POSITION.x-CHUNK_SIZE, SILO_POSITION.y-CHUNK_SIZE}, {SILO_POSITION.x+CHUNK_SIZE, SILO_POSITION.y+CHUNK_SIZE}})
    end
end)

-- Freeplay rocket launch info
-- Slightly modified for my purposes
script.on_event(defines.events.on_rocket_launched, function(event)
    local force = event.rocket.force
    if event.rocket.get_item_count("satellite") == 0 then
        for index, player in pairs(force.players) do
            player.print("You launched the rocket, but you didn't put a satellite inside.")
        end
        return
    end

    if not global.satellite_sent then
        global.satellite_sent = {}
    end

    if global.satellite_sent[force.name] then
        global.satellite_sent[force.name] = global.satellite_sent[force.name] + 1   
    else
        game.set_game_state{game_finished=true, player_won=true, can_continue=true}
        global.satellite_sent[force.name] = 1
    end
    
    for index, player in pairs(force.players) do
        if player.gui.left.rocket_score then
            player.gui.left.rocket_score.rocket_count.caption = tostring(global.satellite_sent[force.name])
        else
            local frame = player.gui.left.add{name = "rocket_score", type = "frame", direction = "horizontal", caption="Score"}
            frame.add{name="rocket_count_label", type = "label", caption={"", "Satellites launched", ":"}}
            frame.add{name="rocket_count", type = "label", caption=tostring(global.satellite_sent[force.name])}
        end
    end
end)
