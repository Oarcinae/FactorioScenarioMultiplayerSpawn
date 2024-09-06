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
require("lib/regrowth_map")
require("lib/holding_pen")
require("lib/separate_spawns")
require("lib/separate_spawns_guis")
require("lib/oarc_gui_tabs")

require("lib/oarc_tests")



--------------------------------------------------------------------------------
-- On Init - Only runs once the first time the game starts
--------------------------------------------------------------------------------
script.on_init(function(event)
    -- Test create some other surfaces
    -- TODO: Remove this later.
    game.create_surface("vulcanus")
    game.create_surface("fulgora")
    game.create_surface("gleba")
    game.create_surface("aquilo")

    ValidateAndLoadConfig()
    RegrowthInit()

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

--------------------------------------------------------------------------------
-- On Configuration Changed - Only runs when the mod configuration changes
--------------------------------------------------------------------------------
-- oarc_new_spawn_created = script.generate_event_name()

-- script.on_configuration_changed(function(data)
--     -- Regenerate event ID:
-- end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if (not StringStarsWith(event.setting, "oarc-mod")) then return end
    RuntimeModSettingChanged(event)
end)

----------------------------------------
-- Player Events
----------------------------------------
script.on_event(defines.events.on_player_created, function(event)
    SeparateSpawnsInitPlayer(event.player_index)
end)

script.on_event(defines.events.on_player_respawned, function(event)
    SeparateSpawnsPlayerRespawned(event)
end)

script.on_event(defines.events.on_player_left_game, function(event)
    SeparateSpawnsPlayerLeft(event)
end)

----------------------------------------
-- Shared chat, so you don't have to type /s
-- But you do lose your player colors across forces.
----------------------------------------
script.on_event(defines.events.on_console_chat, function(event)
    if (global.ocfg.gameplay.enable_shared_team_chat) then
        if (event.player_index ~= nil) then
            ShareChatBetweenForces(game.players[event.player_index], event.message)
        end
    end
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
    -- TODO: Decide if this should always be enabled (to track chunks).
    if global.ocfg.regrowth.enable_regrowth then
        RegrowthChunkGenerate(event)
    end
    
    CreateHoldingPenChunks(event.surface, event.area)
    SeparateSpawnsGenerateChunk(event)
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
    RegrowthSurfaceCreated(event)
end)

script.on_event(defines.events.on_pre_surface_deleted, function(event)
    log("Surface deleted: " .. game.surfaces[event.surface_index].name)
    SeparateSpawnsSurfaceDeleted(event)
    RegrowthSurfaceDeleted(event)
end)

----------------------------------------
-- Various on "built" events
----------------------------------------
script.on_event(defines.events.on_built_entity, function(event)
    if global.ocfg.regrowth.enable_regrowth then
        -- if (event.created_entity.surface.name ~= GAME_SURFACE_NAME) then return end
        RegrowthMarkAreaSafeGivenTilePos(event.created_entity.surface.name, event.created_entity.position, 2, false)
    end

    -- if global.ocfg.enable_anti_grief then
    --     SetItemBlueprintTimeToLive(event)
    -- end
end)

script.on_event(defines.events.on_robot_built_entity, function (event)
    if global.ocfg.regrowth.enable_regrowth then
        -- if (event.created_entity.surface.name ~= GAME_SURFACE_NAME) then return end
        RegrowthMarkAreaSafeGivenTilePos(event.created_entity.surface.name, event.created_entity.position, 2, false)
    end
end)

script.on_event(defines.events.on_player_built_tile, function (event)
    if global.ocfg.regrowth.enable_regrowth then
        -- if (game.surfaces[event.surface_index].name ~= GAME_SURFACE_NAME) then return end

        for k,v in pairs(event.tiles) do
            RegrowthMarkAreaSafeGivenTilePos(game.surfaces[event.surface_index].name, v.position, 2, false)
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
        RegrowthMarkAreaSafeGivenTilePos(event.entity.surface.name, event.entity.position, 2, false)
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
    if not event.element.valid then return end -- Should we ever react to invalid GUI elements?

    SeparateSpawnsGuiClick(event)

    ClickOarcGuiButton(event)
    ServerInfoGuiClick(event)
    SpawnCtrlGuiClick(event)
    SettingsControlsTabGuiClick(event)
end)

--- Called when LuaGuiElement checked state is changed (related to checkboxes and radio buttons).
script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    if not event.element.valid then return end -- Should we ever react to invalid GUI elements?

    SeparateSpawnsGuiCheckedStateChanged(event)

    SpawnCtrlGuiOptionsSelect(event)
end)

script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
    if not event.element.valid then return end -- Should we ever react to invalid GUI elements?

    OarcGuiSelectedTabChanged(event)
end)

-- For capturing player escaping custom GUI so we can close it using ESC key.
script.on_event(defines.events.on_gui_closed, function(event)
    OarcGuiClosed(event)
end)


--- For sliders and other value changing elements.
script.on_event(defines.events.on_gui_value_changed, function(event)
    if not event.element.valid then return end -- Should we ever react to invalid GUI elements?

    SeparateSpawnsGuiValueChanged(event)
end)

--- For dropdowns and listboxes.
script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    if not event.element.valid then return end -- Should we ever react to invalid GUI elements?

    SeparateSpawnsGuiSelectionStateChanged(event)
end)

--on_gui_checked_state_changed	 Called when LuaGuiElement checked state is changed (related to checkboxes and radio buttons).
--on_gui_click	 Called when LuaGuiElement is clicked.
--on_gui_closed	 Called when the player closes the GUI they have open. [...]
--on_gui_confirmed	 Called when a LuaGuiElement is confirmed, for example by pressing Enter in a textfield.
--on_gui_elem_changed	 Called when LuaGuiElement element value is changed (related to choose element buttons).
--on_gui_hover	 Called when LuaGuiElement is hovered by the mouse.
--on_gui_leave	 Called when the player's cursor leaves a LuaGuiElement that was previously hovered.
--on_gui_location_changed	 Called when LuaGuiElement element location is changed (related to frames in player.gui.screen).
--on_gui_opened	 Called when the player opens a GUI.
--on_gui_selected_tab_changed	 Called when LuaGuiElement selected tab is changed (related to tabbed-panes).
--on_gui_selection_state_changed	 Called when LuaGuiElement selection state is changed (related to drop-downs and listboxes).
--on_gui_switch_state_changed	 Called when LuaGuiElement switch state is changed (related to switches).
--on_gui_text_changed	 Called when LuaGuiElement text is changed by the player.
--on_gui_value_changed	 Called when LuaGuiElement slider value is changed (related to the slider element).

----------------------------------------
-- Remote Interface
----------------------------------------
local oarc_mod_interface =
{
  get_mod_settings = function()
    return OCFG
  end
}

remote.add_interface("oarc_mod", oarc_mod_interface)