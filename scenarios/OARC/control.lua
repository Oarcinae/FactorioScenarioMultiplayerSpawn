-- control.lua
-- Aug 2024
--   ____          _____   _____ 
--  / __ \   /\   |  __ \ / ____|
-- | |  | | /  \  | |__) | |     
-- | |  | |/ /\ \ |  _  /| |     
-- | |__| / ____ \| | \ \| |____ 
--  \____/_/    \_\_|  \_\\_____|

-- Oarc's Separated Spawn Scenario V2
-- I decided to rewrite my old scenario due to the coming changes in Factorio V2.0 and its new Space Age Expansion.

-- Change Overview:
--      Removed a lot of unnecessary feature bloat.
--      Support the scenario "as a mod" properly from the start. (Keep support for scenario as well.)
--      Move text to locale files where possible.

-- Feature List:
--      Core feature allows for a safe, separate spawn area for each player.
--      Players can choose to spawn with friends (buddy spawn) or join other bases.
--      Offline protection from enemy attacks.
--      Chunk cleanup to keep save file size down.
--      (TENTATIVE) Support for multiple vanilla-style spawn points.

-- TODO NOTES:
--      Add more tooltips?!
--      on_runtime_mod_setting_changed 

-- Start Flow:
--      Display scenario welcome info.
--      Display main spawn options.
--          Display buddy spawn options. (OPTIONAL)
--      Create spawn area.
--      Send player to spawn area.

-- Options Menu:
--      Display scenario info. (Dupe of welcome info?)
--      Admin tools to restart or ban players.
--      Personal settings for player (Allow shared base)

require("lib/oarc_utils")
require("config")
require("lib/config_parser")
require("lib/holding_pen")
require("lib/separate_spawns")
require("lib/separate_spawns_guis")
require("lib/oarc_gui_tabs")



--------------------------------------------------------------------------------
-- On Init - Only runs once the first time the game starts
--------------------------------------------------------------------------------
script.on_init(function(event)
    ValidateAndLoadConfig()
    CreateHoldingPenSurface()
    InitSpawnGlobalsAndForces()
end)

----------------------------------------
-- Player Events
----------------------------------------
script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]

    player.teleport({x=0,y=0}, HOLDING_PEN_SURFACE_NAME)

    SeparateSpawnsPlayerCreated(event.player_index, true)
    InitOarcGuiTabs(player)
end)

script.on_event(defines.events.on_player_respawned, function(event)
    SeparateSpawnsPlayerRespawned(event)

    GivePlayerRespawnItems(game.players[event.player_index])
end)

script.on_event(defines.events.on_player_left_game, function(event)
    local player = game.players[event.player_index]

    -- If players leave early, say goodbye.
    if (player and (player.online_time < (global.ocfg.gameplay.minimum_online_time * TICKS_PER_MINUTE))) then
        log("Player left early: " .. player.name)
        SendBroadcastMsg(player.name .. "'s base was marked for immediate clean up because they left within "..global.ocfg.gameplay.minimum_online_time.." minutes of joining.")
        RemoveOrResetPlayer(player, true, true, true, true)
    end
end)

----------------------------------------
-- On tick events. Stuff that needs to happen at regular intervals.
-- Delayed events, delayed spawns, ...
----------------------------------------
script.on_event(defines.events.on_tick, function(event)
    FadeoutRenderOnTick()
end)

----------------------------------------
-- Chunk Generation
----------------------------------------
script.on_event(defines.events.on_chunk_generated, function(event)
    CreateHoldingPenChunks(event.surface, event.area)
    SeparateSpawnsGenerateChunk(event)
end)

----------------------------------------
-- On Entity Spawned and On Biter Base Built
-- This is where I modify biter spawning based on location and other factors.
----------------------------------------
script.on_event(defines.events.on_entity_spawned, function(event)
    if (global.ocfg.gameplay.oarc_modified_enemy_spawning) then
        ModifyEnemySpawnsNearPlayerStartingAreas(event)
    end
end)
script.on_event(defines.events.on_biter_base_built, function(event)
    if (global.ocfg.gameplay.oarc_modified_enemy_spawning) then
        ModifyEnemySpawnsNearPlayerStartingAreas(event)
    end
end)

----------------------------------------
-- Gui Events
----------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
    ClickOarcGuiButton(event)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    SpawnOptsRadioSelect(event)
    SpawnCtrlGuiOptionsSelect(event)
end)

script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
    TabChangeOarcGui(event)
end)
----------------------------------------
-- On Gui Closed
-- For capturing player escaping custom GUI so we can close it using ESC key.
----------------------------------------
script.on_event(defines.events.on_gui_closed, function(event)
    OarcGuiOnGuiClosedEvent(event)
end)