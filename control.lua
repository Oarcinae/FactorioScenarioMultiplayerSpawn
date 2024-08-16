-- control.lua
-- Aug 2024
--   ____          _____   _____ 
--  / __ \   /\   |  __ \ / ____|
-- | |  | | /  \  | |__) | |     
-- | |  | |/ /\ \ |  _  /| |     
-- | |__| / ____ \| | \ \| |____ 
--  \____/_/    \_\_|  \_\\_____|

-- Oarc's Separated Spawn MOD V2
-- I decided to rewrite my old scenario due to the coming changes in Factorio V2.0 and its new Space Age Expansion.

-- Change Overview:
--      Support the scenario "as a mod" ONLY. Scenario merely provides a way to overwrite settings on_init.
--      Removed a lot of unnecessary feature bloat.
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
require("lib/config")
require("lib/config_parser")
require("lib/game_opts")
require("lib/regrowth_map")
require("lib/holding_pen")
require("lib/separate_spawns")
require("lib/separate_spawns_guis")
require("lib/oarc_gui_tabs")



--------------------------------------------------------------------------------
-- On Init - Only runs once the first time the game starts
--------------------------------------------------------------------------------
script.on_init(function(event)
    ValidateAndLoadConfig()
    RegrowthInit()

    -- Test create some other surfaces
    -- TODO: Remove this later.
    game.create_surface("vulcanus")
    game.create_surface("fulgora")
    game.create_surface("gleba")
    game.create_surface("aquilo")

    InitSpawnGlobalsAndForces()
    CreateHoldingPenSurface() -- Must be after init spawn globals?

    -- Useful for debugging and if players choose not to use the provided empty scenario.
    if remote.interfaces["freeplay"] then
        log("Freeplay interface detected. Disabling various freeplay features now!")
        remote.call("freeplay", "set_skip_intro", true)
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_created_items", {})
        remote.call("freeplay", "set_respawn_items", {})
    end
end)

----------------------------------------
-- Player Events
----------------------------------------
script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    player.teleport({x=0,y=0}, HOLDING_PEN_SURFACE_NAME)

    SeparateSpawnsInitPlayer(event.player_index, true)
end)

script.on_event(defines.events.on_player_respawned, function(event)
    SeparateSpawnsPlayerRespawned(event)
end)

script.on_event(defines.events.on_player_left_game, function(event)
    SeparateSpawnsPlayerLeft(event)
end)

----------------------------------------
-- On tick events. Stuff that needs to happen at regular intervals.
-- Delayed events, delayed spawns, ...
----------------------------------------
script.on_event(defines.events.on_tick, function(event)
    DelayedSpawnOnTick()
    FadeoutRenderOnTick()

    if global.ocfg.regrowth.enable_regrowth then
        RegrowthOnTick()
        RegrowthForceRemovalOnTick()
    end
end)

----------------------------------------
-- Chunk Generation
----------------------------------------
script.on_event(defines.events.on_chunk_generated, function(event)
    CreateHoldingPenChunks(event.surface, event.area)
    SeparateSpawnsGenerateChunk(event)

    -- TODO: Decide if this should always be enabled (to track chunks).
    if global.ocfg.regrowth.enable_regrowth then
        RegrowthChunkGenerate(event)
    end
end)

script.on_event(defines.events.on_sector_scanned, function (event)   
    if global.ocfg.regrowth.enable_regrowth then
        RegrowthSectorScan(event)
    end
end)

----------------------------------------
-- Surface Generation
----------------------------------------
-- This is not called when the default surface "nauvis" is created as it will always exist!
script.on_event(defines.events.on_surface_created, function(event)
    log("Surface created: " .. game.surfaces[event.surface_index].name)
    SeparateSpawnsSurfaceCreated(event)
    -- RegrowthSurfaceCreated(event)
end)

script.on_event(defines.events.on_surface_deleted, function(event)
    log("Surface deleted: " .. game.surfaces[event.surface_index].name)
    SeparateSpawnsSurfaceDeleted(event)
    -- RegrowthSurfaceDeleted(event)
end)

----------------------------------------
-- Various on "built" events
----------------------------------------
script.on_event(defines.events.on_built_entity, function(event)
    if global.ocfg.regrowth.enable_regrowth then
        -- if (event.created_entity.surface.name ~= GAME_SURFACE_NAME) then return end
        RegrowthMarkAreaSafeGivenTilePos(event.created_entity.position, 2, false)
    end

    -- if global.ocfg.enable_anti_grief then
    --     SetItemBlueprintTimeToLive(event)
    -- end
end)

script.on_event(defines.events.on_robot_built_entity, function (event)
    if global.ocfg.regrowth.enable_regrowth then
        -- if (event.created_entity.surface.name ~= GAME_SURFACE_NAME) then return end
        RegrowthMarkAreaSafeGivenTilePos(event.created_entity.position, 2, false)
    end
end)

script.on_event(defines.events.on_player_built_tile, function (event)
    if global.ocfg.regrowth.enable_regrowth then
        -- if (game.surfaces[event.surface_index].name ~= GAME_SURFACE_NAME) then return end

        for k,v in pairs(event.tiles) do
            RegrowthMarkAreaSafeGivenTilePos(v.position, 2, false)
        end
    end
end)

----------------------------------------
-- On script_raised_built. This should help catch mods that
-- place items that don't count as player_built and robot_built.
-- Specifically FARL.
----------------------------------------
script.on_event(defines.events.script_raised_built, function(event)
    if global.ocfg.regrowth.enable_regrowth then
        -- if (event.entity.surface.name ~= GAME_SURFACE_NAME) then return end
        RegrowthMarkAreaSafeGivenTilePos(event.entity.position, 2, false)
    end
end)

----------------------------------------
-- On Entity Spawned and On Biter Base Built
-- This is where I modify biter spawning based on location and other factors.
----------------------------------------
script.on_event(defines.events.on_entity_spawned, function(event)
    if (global.ocfg.gameplay.modified_enemy_spawning) then
        ModifyEnemySpawnsNearPlayerStartingAreas(event)
    end
end)

script.on_event(defines.events.on_biter_base_built, function(event)
    if (global.ocfg.gameplay.modified_enemy_spawning) then
        ModifyEnemySpawnsNearPlayerStartingAreas(event)
    end
end)

----------------------------------------
-- Gui Events
----------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
    WelcomeTextGuiClick(event)
    SpawnOptsGuiClick(event)
    SpawnCtrlGuiClick(event)
    SharedSpwnOptsGuiClick(event)
    BuddySpawnOptsGuiClick(event)
    BuddySpawnWaitMenuClick(event)
    BuddySpawnRequestMenuClick(event)
    SharedSpawnJoinWaitMenuClick(event)
    ClickOarcGuiButton(event)
    GameOptionsGuiClick(event)
end)

--- Called when LuaGuiElement checked state is changed (related to checkboxes and radio buttons).
script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    SpawnOptsRadioSelect(event)
    SpawnCtrlGuiOptionsSelect(event)
end)

script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
    TabChangeOarcGui(event)
end)

-- For capturing player escaping custom GUI so we can close it using ESC key.
script.on_event(defines.events.on_gui_closed, function(event)
    OarcGuiOnGuiClosedEvent(event)
end)

local oarc_mod_interface =
{
  get_mod_settings = function()
    return OCFG
  end
}

remote.add_interface("oarc_mod", oarc_mod_interface)