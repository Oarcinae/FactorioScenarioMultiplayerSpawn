-- control.lua
-- Mar 2019

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



-- To keep the scenario more manageable (for myself) I have done the following:
--      1. Keep all event calls in control.lua (here)
--      2. Put all config options in config.lua
--      3. Put other stuff into their own files where possible.


-- Generic Utility Includes
require("lib/oarc_utils")

-- Other soft-mod type features.
require("lib/frontier_silo")
require("lib/tag")
require("lib/game_opts")
require("lib/regrowth_map")
require("lib/player_list")

-- For Philip. I currently do not use this and need to add proper support for
-- commands like this in the future.
-- require("lib/rgcommand")
-- require("lib/helper_commands")

-- Main Configuration File
require("config")

-- Scenario Specific Includes
require("lib/separate_spawns")
require("lib/separate_spawns_guis")

-- In this case, we are using the default surface.
GAME_SURFACE_NAME="nauvis"

--------------------------------------------------------------------------------
-- ALL EVENT HANLDERS ARE HERE IN ONE PLACE!
--------------------------------------------------------------------------------

----------------------------------------
-- On Init - only runs once the first 
--   time the game starts
----------------------------------------
script.on_init(function(event)

    -- Configures the map settings for enemies
    -- This controls evolution growth factors and enemy expansion settings.
    -- The only reason this is here is because --map-settings doesn't seem to work
    -- with --start-server-load-scenario
    ConfigureAlienStartingParams()

    if ENABLE_SEPARATE_SPAWNS then
        InitSpawnGlobalsAndForces()
    end

    if SILO_FIXED_POSITION then
        SetFixedSiloPosition(SILO_POSITION)
    else
        SetRandomSiloPosition(SILO_NUM_SPAWNS)
    end

    if FRONTIER_ROCKET_SILO_MODE then
        GenerateRocketSiloAreas(game.surfaces[GAME_SURFACE_NAME])
    end

    SetServerWelcomeMessages()

    if ENABLE_REGROWTH or ENABLE_ABANDONED_BASE_REMOVAL then
        OarcRegrowthInit()
    end
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
    if ENABLE_REGROWTH then
        OarcRegrowthChunkGenerate(event.area.left_top)
    end

    if ENABLE_UNDECORATOR then
        UndecorateOnChunkGenerate(event)
    end

    if FRONTIER_ROCKET_SILO_MODE then
        GenerateRocketSiloChunk(event)
    end

    if ENABLE_SEPARATE_SPAWNS and not USE_VANILLA_STARTING_SPAWN then
        SeparateSpawnsGenerateChunk(event)
    end

    if not ENABLE_DEFAULT_SPAWN then
        CreateHoldingPen(event.surface, event.area, 16, false)
    end
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
        BuddySpawnOptsGuiClick(event)
        BuddySpawnWaitMenuClick(event)
        BuddySpawnRequestMenuClick(event)
        SharedSpawnJoinWaitMenuClick(event)
    end

    GameOptionsGuiClick(event)

end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    if ENABLE_SEPARATE_SPAWNS then
        SpawnOptsRadioSelect(event)
        SpawnCtrlGuiOptionsSelect(event)
    end
end)


----------------------------------------
-- Player Events
----------------------------------------
script.on_event(defines.events.on_player_joined_game, function(event)

    CreateGameOptionsGui(event)

    PlayerJoinedMessages(event)

    if ENABLE_PLAYER_LIST then
        CreatePlayerListGui(event)
    end

    if ENABLE_TAGS then
        CreateTagGui(event)
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
        SeparateSpawnsPlayerCreated(event.player_index)
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

script.on_event(defines.events.on_player_left_game, function(event)
    if ENABLE_SEPARATE_SPAWNS then
        FindUnusedSpawns(event)
    end
end)

script.on_event(defines.events.on_built_entity, function(event)
    if ENABLE_AUTOFILL then
        Autofill(event)
    end

    if ENABLE_REGROWTH then
        OarcRegrowthOffLimitsChunk(event.created_entity.position)
    end

    if ENABLE_ANTI_GRIEFING then
        SetItemBlueprintTimeToLive(event)
    end
end)


----------------------------------------
-- Shared vision, charts a small area around other players
----------------------------------------
script.on_event(defines.events.on_tick, function(event)
    if ENABLE_REGROWTH then
        OarcRegrowthOnTick()
    end

    if ENABLE_ABANDONED_BASE_REMOVAL then
        OarcRegrowthForceRemovalOnTick()
    end

    if ENABLE_SEPARATE_SPAWNS then
        DelayedSpawnOnTick()
    end

    if FRONTIER_ROCKET_SILO_MODE then
        DelayedSiloCreationOnTick(game.surfaces[GAME_SURFACE_NAME])
    end

end)


script.on_event(defines.events.on_sector_scanned, function (event)
    if ENABLE_REGROWTH then
        OarcRegrowthSectorScan(event)
    end
end)

----------------------------------------
-- Refreshes regrowth timers around an active timer
-- Refresh areas where stuff is built, and mark any chunks with player
-- built stuff as permanent.
----------------------------------------
if ENABLE_REGROWTH then

    script.on_event(defines.events.on_robot_built_entity, function (event)
        OarcRegrowthOffLimitsChunk(event.created_entity.position)
    end)

    script.on_event(defines.events.on_player_mined_entity, function(event)
        OarcRegrowthCheckChunkEmpty(event)
    end)
    
    script.on_event(defines.events.on_robot_mined_entity, function(event)
        OarcRegrowthCheckChunkEmpty(event)
    end)

end



----------------------------------------
-- Shared chat, so you don't have to type /s
----------------------------------------
script.on_event(defines.events.on_console_chat, function(event)
    if (ENABLE_SHARED_TEAM_CHAT) then
        if (event.player_index ~= nil) then
            ShareChatBetweenForces(game.players[event.player_index], event.message)
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
-- On Entity Spawned
-- This is where I modify biter spawning based on location and other factors.
----------------------------------------
script.on_event(defines.events.on_entity_spawned, function(event)
    if (OARC_MODIFIED_ENEMY_SPAWNING) then
        ModifyEnemySpawnsNearPlayerStartingAreas(event)
    end
end)
-- on_biter_base_built -- Worth considering for later.

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