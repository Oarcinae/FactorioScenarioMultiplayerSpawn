-- control.lua
-- Mar 2019

-- Oarc's Separated Spawn Scenario
-- 
-- I wanted to create a scenario that allows you to spawn in separate locations
-- From there, I ended up adding a bunch of other minor/major features
-- 
-- Credit:
--  Tags - Taken from WOGs scenario 
--  Rocket Silo - Taken from Frontier as an idea
--
-- Feel free to re-use anything you want. It would be nice to give me credit
-- if you can.



-- To keep the scenario more manageable (for myself) I have done the following:
--      1. Keep all event calls in control.lua (here)
--      2. Put all config options in config.lua and provided an example-config.lua file too.
--      3. Put other stuff into their own files where possible.
--      4. Put all other files into lib folder
--      5. Provided an examples folder for example/recommended map gen settings


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

-- Save all config settings to global table.
require("lib/oarc_global_cfg.lua")

-- Scenario Specific Includes
require("lib/separate_spawns")
require("lib/separate_spawns_guis")

-- Create a new surface so we can modify map settings at the start.
GAME_SURFACE_NAME="oarc"

--------------------------------------------------------------------------------
-- ALL EVENT HANLDERS ARE HERE IN ONE PLACE!
--------------------------------------------------------------------------------

----------------------------------------
-- On Init - only runs once the first 
--   time the game starts
----------------------------------------
script.on_init(function(event)

    -- FIRST
    InitOarcConfig()

    -- Create new game surface
    CreateGameSurface()

    -- MUST be before other stuff, but after surface creation.
    InitSpawnGlobalsAndForces()

    if SILO_FIXED_POSITION then
        SetFixedSiloPosition(SILO_POSITION)
    else
        SetRandomSiloPosition(SILO_NUM_SPAWNS)
    end

    if FRONTIER_ROCKET_SILO_MODE then
        GenerateRocketSiloAreas(game.surfaces[GAME_SURFACE_NAME])
    end

    -- Regardless of whether it's enabled or not, it's good to have this init.
    OarcRegrowthInit()
end)


----------------------------------------
-- Freeplay rocket launch info
-- Slightly modified for my purposes
----------------------------------------
script.on_event(defines.events.on_rocket_launched, function(event)
    if global.ocfg.frontier_rocket_silo then
        RocketLaunchEvent(event)
    end
end)


local first_chunk_generated_flag = false
----------------------------------------
-- Chunk Generation
----------------------------------------
script.on_event(defines.events.on_chunk_generated, function(event)

    if global.ocfg.enable_regrowth then
        OarcRegrowthChunkGenerate(event.area.left_top)
    end

    if global.ocfg.enable_undecorator then
        UndecorateOnChunkGenerate(event)
    end

    if global.ocfg.frontier_rocket_silo then
        GenerateRocketSiloChunk(event)
    end

    SeparateSpawnsGenerateChunk(event)

    CreateHoldingPen(event.surface, event.area, 16, 32)
end)


----------------------------------------
-- Gui Click
----------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
    if global.ocfg.enable_tags then
        TagGuiClick(event)
    end

    if global.ocfg.enable_player_list then
        PlayerListGuiClick(event)
    end

    WelcomeTextGuiClick(event)
    SpawnOptsGuiClick(event)
    SpawnCtrlGuiClick(event)
    SharedSpwnOptsGuiClick(event)
    BuddySpawnOptsGuiClick(event)
    BuddySpawnWaitMenuClick(event)
    BuddySpawnRequestMenuClick(event)
    SharedSpawnJoinWaitMenuClick(event)

    GameOptionsGuiClick(event)

end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    SpawnOptsRadioSelect(event)
    SpawnCtrlGuiOptionsSelect(event)
end)


----------------------------------------
-- Player Events
----------------------------------------
script.on_event(defines.events.on_player_joined_game, function(event)

    CreateGameOptionsGui(event)

    PlayerJoinedMessages(event)

    if global.ocfg.enable_player_list then
        CreatePlayerListGui(event)
    end

    if global.ocfg.enable_tags then
        CreateTagGui(event)
    end

end)

script.on_event(defines.events.on_player_created, function(event)
    
    -- Move the player to the game surface immediately.
    -- May change this to Lobby in the future.
    game.players[event.player_index].teleport({x=0,y=0}, GAME_SURFACE_NAME)

    if global.ocfg.enable_long_reach then
        GivePlayerLongReach(game.players[event.player_index])
    end

    SeparateSpawnsPlayerCreated(event.player_index)
end)

script.on_event(defines.events.on_player_respawned, function(event)
    SeparateSpawnsPlayerRespawned(event)
   
    PlayerRespawnItems(event)

    if global.ocfg.enable_long_reach then
        GivePlayerLongReach(game.players[event.player_index])
    end
end)

script.on_event(defines.events.on_player_left_game, function(event)
    FindUnusedSpawns(event)
end)

script.on_event(defines.events.on_built_entity, function(event)
    if global.ocfg.enable_autofill then
        Autofill(event)
    end

    if global.ocfg.enable_regrowth then
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
    if global.ocfg.enable_regrowth then
        OarcRegrowthOnTick()
    end

    if global.ocfg.enable_abandoned_base_removal then
        OarcRegrowthForceRemovalOnTick()
    end

    DelayedSpawnOnTick()

    if global.ocfg.frontier_rocket_silo then
        DelayedSiloCreationOnTick(game.surfaces[GAME_SURFACE_NAME])
    end

end)


script.on_event(defines.events.on_sector_scanned, function (event)
    if global.ocfg.enable_regrowth then
        OarcRegrowthSectorScan(event)
    end
end)

----------------------------------------
-- Refreshes regrowth timers around an active timer
-- Refresh areas where stuff is built, and mark any chunks with player
-- built stuff as permanent.
----------------------------------------
script.on_event(defines.events.on_robot_built_entity, function (event)
    if global.ocfg.enable_regrowth then
        OarcRegrowthOffLimitsChunk(event.created_entity.position)
    end
end)
script.on_event(defines.events.on_player_mined_entity, function(event)
    if global.ocfg.enable_regrowth then
        OarcRegrowthCheckChunkEmpty(event)
    end
end)
script.on_event(defines.events.on_robot_mined_entity, function(event)
    if global.ocfg.enable_regrowth then
        OarcRegrowthCheckChunkEmpty(event)
    end
end)





----------------------------------------
-- Shared chat, so you don't have to type /s
----------------------------------------
script.on_event(defines.events.on_console_chat, function(event)
    if (global.ocfg.enable_shared_chat) then
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
    if global.ocfg.frontier_rocket_silo then
        RemoveRecipe(event.research.force, "rocket-silo")
    end
end)

----------------------------------------
-- On Entity Spawned
-- This is where I modify biter spawning based on location and other factors.
----------------------------------------
script.on_event(defines.events.on_entity_spawned, function(event)
    if (global.ocfg.modified_enemy_spawning) then
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
        for _,f in pairs(game.forces) do
            EnableTech(f, "atomic-bomb")
            EnableTech(f, "power-armor-2")
            EnableTech(f, "artillery")
        end
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