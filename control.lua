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
require("lib/rocket_launch")
require("lib/admin_commands")

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

    -- Regardless of whether it's enabled or not, it's good to have this init.
    OarcRegrowthInit()

    -- Frontier Silo Area Generation
    if (global.ocfg.frontier_rocket_silo) then
        SpawnSilosAndGenerateSiloAreas()
    end

    -- Everyone do the shuffle. Helps avoid always starting at the same location.
    global.vanillaSpawns = FYShuffle(global.vanillaSpawns)
    log("Vanilla spawns:")
    log(serpent.block(global.vanillaSpawns))
end)


----------------------------------------
-- Rocket launch event
-- Used for end game win conditions / unlocking late game stuff
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
    RocketGuiClick(event)
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

    if global.satellite_sent then
        CreateRocketGui(game.players[event.player_index])
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
    FindUnusedSpawns(game.players[event.player_index], true)
end)

----------------------------------------
-- On BUILD entity. Don't forget on_robot_built_entity too!
----------------------------------------
script.on_event(defines.events.on_built_entity, function(event)
    if global.ocfg.enable_autofill then
        Autofill(event)
    end

    if global.ocfg.enable_regrowth then
        OarcRegrowthOffLimits(event.created_entity.position, 2)
    end

    if ENABLE_ANTI_GRIEFING then
        SetItemBlueprintTimeToLive(event)
    end

    if global.ocfg.frontier_rocket_silo then
        BuildSiloAttempt(event)
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
        OarcRegrowthOffLimits(event.created_entity.position, 2)
    end

    if global.ocfg.frontier_rocket_silo then
        BuildSiloAttempt(event)
    end
end)

-- I disabled this because it's too much overhead for too little gain!
-- script.on_event(defines.events.on_player_mined_entity, function(event)
--     if global.ocfg.enable_regrowth then
--         OarcRegrowthCheckChunkEmpty(event)
--     end
-- end)
-- script.on_event(defines.events.on_robot_mined_entity, function(event)
--     if global.ocfg.enable_regrowth then
--         OarcRegrowthCheckChunkEmpty(event)
--     end
-- end)


----------------------------------------
-- Shared chat, so you don't have to type /s
-- But you do lose your player colors across forces.
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
    
    -- Never allows players to build rocket-silos in "frontier" mode.
    if global.ocfg.frontier_rocket_silo and not global.ocfg.frontier_allow_build then
        RemoveRecipe(event.research.force, "rocket-silo")
    end

    if LOCK_GOODIES_UNTIL_ROCKET_LAUNCH and 
        (not global.satellite_sent or not global.satellite_sent[event.research.force.name]) then
        RemoveRecipe(event.research.force, "productivity-module-3")
        RemoveRecipe(event.research.force, "speed-module-3")
    end

    if ENABLE_LOADERS then
        EnableLoaders(event)
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


----------------------------------------
-- On Corpse Timed Out
-- Save player's stuff so they don't lose it if they can't get to the corpse fast enough.
----------------------------------------
script.on_event(defines.events.on_character_corpse_expired, function(event)
    DropGravestoneChestFromCorpse(event.corpse)
end)

-- on_biter_base_built -- Worth considering for later.