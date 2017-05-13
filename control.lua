-- control.lua
-- Apr 2017

-- Oarc's Separated Spawn Scenario
-- 
-- I wanted to create a scenario that allows you to spawn in separate locations
-- From there, I ended up adding a bunch of other minor/major features
-- 
-- Credit:
--  RSO mod to RSO author - Orzelek - I contacted him via the forum
--  Tags - Taken from WOGs scenario 
--  Rocket Silo - Taken from Frontier as an idea
--
-- Feel free to re-use anything you want. It would be nice to give me credit
-- if you can.
-- 
-- Follow server info on @_Oarc_


-- To keep the scenario more manageable I have done the following:
--      1. Keep all event calls in control.lua (here)
--      2. Put all config options in config.lua
--      3. Put mods into their own files where possible (RSO has multiple)


-- Generic Utility Includes
require("locale/oarc_utils")
require("locale/rso/rso_control")
require("locale/frontier_silo")
require("locale/tag")

-- Main Configuration File
require("config")

-- Scenario Specific Includes
require("separate_spawns")
require("separate_spawns_guis")


--------------------------------------------------------------------------------
-- Rocket Launch Event Code
-- Controls the "win condition"
--------------------------------------------------------------------------------
function RocketLaunchEvent(event)
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
end


--------------------------------------------------------------------------------
-- ALL EVENT HANLDERS ARE HERE IN ONE PLACE!
--------------------------------------------------------------------------------


----------------------------------------
-- On Init - only runs once the first 
--   time the game starts
----------------------------------------
script.on_init(function(event)

    -- CreateLobbySurface() -- Currently unused, but have plans for future.
    
    -- Here I create the game surface. I do this so that I don't have to worry
    -- about the game menu settings and I can now generate a map from the command
    -- line more easily!
    -- 
    -- If you are using RSO, map settings are ignored and you MUST configure
    -- the relevant map settings in config.lua
    -- 
    -- If you disable RSO, the map settings will be set from the ones that you
    -- choose from the game GUI when you start a new scenario.
    if ENABLE_RSO then
        CreateGameSurface(RSO_MODE)
    else
        CreateGameSurface(VANILLA_MODE)
    end

    if ENABLE_SEPARATE_SPAWNS then
        InitSpawnGlobalsAndForces()
    end

    if ENABLE_RANDOM_SILO_POSITION then
        SetRandomSiloPosition()
    else
        SetFixedSiloPosition()
    end

    if FRONTIER_ROCKET_SILO_MODE then
        ChartRocketSiloArea(game.forces[MAIN_FORCE], game.surfaces[GAME_SURFACE_NAME])
    end

    -- Configures the map settings for enemies
    -- This controls evolution growth factors and enemy expansion settings.
    ConfigureAlienStartingParams()

    SetServerWelcomeMessages()
end)


----------------------------------------
-- Freeplay rocket launch info
-- Slightly modified for my purposes
----------------------------------------
script.on_event(defines.events.on_rocket_launched, function(event)
    if FRONTIER_ROCKET_SILO_MODE then
        RocketLaunchEvent(event)
    end
end)


----------------------------------------
-- Chunk Generation
----------------------------------------
script.on_event(defines.events.on_chunk_generated, function(event)
    if ENABLE_UNDECORATOR then
        UndecorateOnChunkGenerate(event)
    end

    if ENABLE_RSO then
        RSO_ChunkGenerated(event)
    end

    if FRONTIER_ROCKET_SILO_MODE then
        GenerateRocketSiloChunk(event)
    end

    -- This MUST come after RSO generation!
    if ENABLE_SEPARATE_SPAWNS then
        SeparateSpawnsGenerateChunk(event)
    end

    CreateHoldingPenGenerateChunk(event);
end)


----------------------------------------
-- Gui Click
----------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
    if ENABLE_TAGS then
        TagGuiClick(event)
    end

    if ENABLE_PLAYER_LIST then
        PlayerListGuiClick(event)
    end

    if ENABLE_SEPARATE_SPAWNS then
        WelcomeTextGuiClick(event)
        SpawnOptsGuiClick(event)
        SpawnCtrlGuiClick(event)
        SharedSpwnOptsGuiClick(event)
    end

end)


----------------------------------------
-- Player Events
----------------------------------------
script.on_event(defines.events.on_player_joined_game, function(event)

    PlayerJoinedMessages(event)

    if ENABLE_TAGS then
        CreateTagGui(event)
    end

    if ENABLE_PLAYER_LIST then
        CreatePlayerListGui(event)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    
    -- Move the player to the game surface immediately.
    -- May change this to Lobby in the future.
    game.players[event.player_index].teleport(game.forces[MAIN_FORCE].get_spawn_position(GAME_SURFACE_NAME), GAME_SURFACE_NAME)

    if ENABLE_LONGREACH then
        GivePlayerLongReach(game.players[event.player_index])
    end

    if not ENABLE_SEPARATE_SPAWNS then
        PlayerSpawnItems(event)
    else
        SeparateSpawnsPlayerCreated(event)
    end
end)

script.on_event(defines.events.on_player_respawned, function(event)
    if ENABLE_SEPARATE_SPAWNS then
        SeparateSpawnsPlayerRespawned(event)        
    end
   
    PlayerRespawnItems(event)

    if ENABLE_LONGREACH then
        GivePlayerLongReach(game.players[event.player_index])
    end
end)

script.on_event(defines.events.on_pre_player_died, function(event)
    if ENABLE_GRAVESTONE_ON_DEATH then
        DropGravestoneChests(game.players[event.player_index])
    end
end)

script.on_event(defines.events.on_player_left_game, function(event)
    if ENABLE_GRAVESTONE_ON_LEAVING then
        if (game.players[event.player_index].online_time <
            ENABLE_GRAVESTONE_ON_LEAVING_TIME_MINS) then
            DropGravestoneChests(game.players[event.player_index])
        end
    end 

    if ENABLE_SEPARATE_SPAWNS then
        FindUnusedSpawns(event)
    end
end)

script.on_event(defines.events.on_built_entity, function(event)
    if ENABLE_AUTOFILL then
        Autofill(event)
    end
end)


local tick_counter = 0
script.on_event(defines.events.on_tick, function(event)

    -- Every few seconds, chart all players to "share vision"
    if ENABLE_SHARED_TEAM_VISION then
        if (tick_counter >= (TICKS_PER_SECOND*5)) then
            ShareVisionBetweenPlayers()
            tick_counter = 0
        else
            tick_counter = tick_counter + 1
        end
    end
end)


----------------------------------------
-- On Research Finished
-- This is where you can permanently remove researched techs
----------------------------------------
script.on_event(defines.events.on_research_finished, function(event)
    if FRONTIER_ROCKET_SILO_MODE then
        RemoveRecipe(event.research.force, "rocket-silo")
    end
end)


----------------------------------------
-- Other?
----------------------------------------
-- script.on_event(defines.events.on_robot_built_entity, function(event)

-- end)