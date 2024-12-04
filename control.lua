-- Sep 2024
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

-- Major Features:
--      Core feature allows for a safe, separate spawn area for each player.
--      Players can choose to spawn with friends (buddy spawn) or join other bases.
--      Offline protection from enemy attacks.
--      Chunk cleanup to keep save file size down.
--      Sharing of electricity and items between players.

require("lib/oarc_utils")
require("lib/config")
require("lib/config_parser")
require("lib/regrowth_map")
require("lib/holding_pen")
require("lib/separate_spawns")
require("lib/separate_spawns_guis")
require("lib/oarc_gui_tabs")
require("lib/offline_protection")
require("lib/scaled_enemies")
require("lib/sharing")

-- TODO: Possibly remove this later?
require("lib/oarc_tests")

require("lib/oarc_commands")


--------------------------------------------------------------------------------
-- On Init - Only runs once the first time the game starts
--------------------------------------------------------------------------------
script.on_init(function(event)

    -- If init has already been run, we immediately hard error.
    -- This is NOT supported. Checking for this force is just an easy dumb way to do it.
    if (game.forces[ABANDONED_FORCE_NAME] ~= nil) then
        error("It appears as though this mod is trying to re-run on_init. If you removed the mod and re-added it again, this is NOT supported. You have to rollback to a previous save where the mod was enabled.")
        return
    end

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

    -- If there are any players that already exist, init them now.
    for _,player in pairs(game.players) do
        SeparateSpawnsInitPlayer(player.index)
    end

    game.technology_notifications_enabled = false
end)


--------------------------------------------------------------------------------
-- On Load - Only for setting up some table stuff that shouldn't change during gameplay!
--------------------------------------------------------------------------------
script.on_load(function()
    SetupOCFGModKeys()
end)

--------------------------------------------------------------------------------
-- On Configuration Changed - Only runs when the mod configuration changes
--------------------------------------------------------------------------------
script.on_configuration_changed(function(data)
    for _,player in pairs(game.players) do
        RecreateOarcGui(player) -- Reset the players GUI
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if (not StringStartsWith(event.setting, "oarc-mod")) then return end
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

-- This does NOT do what I expected, it triggers anytime the VIEW changes, not the character moving.
-- script.on_event(defines.events.on_player_changed_surface, function(event)
--     SeparateSpawnsPlayerChangedSurface(event)
-- end)

script.on_event(defines.events.on_rocket_launched, function(event)
    log("Rocket launched!")
    log(serpent.block(event))
end)

script.on_event(defines.events.on_player_driving_changed_state, function (event)
    local entity = event.entity

    --If a player gets in or out of a vehicle, mark the area as safe so we don't delete the vehicle by accident.
    --Only world eater will clean up these chunks over time if it is enabled.
    if storage.ocfg.regrowth.enable_regrowth and (entity ~= nil) then
        RegrowthMarkAreaSafeGivenTilePos(entity.surface.name, entity.position, 1, false)
    end

    log("Player driving changed state")
    log(serpent.block(event))

    -- Track the surfaces whenever driving state changes for a cargo-pod ONLY.
    -- This triggers events for surface changes when using the standard space travel method.
    if (entity ~= nil) and (entity.name == "cargo-pod") then
        local player = game.players[event.player_index]

        -- Check if driving flag is set
        if (player.driving) then
            log("Player is driving a cargo-pod")
        end

        SeparateSpawnsUpdatePlayerSurface(player, entity.surface.name)
    end
end)

script.on_event(defines.events.on_research_finished, function(event)
    local research = event.research

    -- Duplicates the research finished message for all forces if shared team chat is enabled.
    -- The force that did the research always gets a sound notification even if the technology_notifications_enabled is false.
    for _,force in pairs(game.forces) do
        if (force == research.force) or (storage.ocfg.gameplay.enable_shared_team_chat) then
            if (prototypes.technology[research.name].max_level ~= 4294967295) then
                CompatSend(force,
                    {"oarc-research-finished", research.force.name, research.name},
                    { color = research.force.color, sound = defines.print_sound.never })
            else
                CompatSend(force,
                    {"oarc-research-finished-infinite", research.force.name, research.name, research.localised_name, research.level},
                    { color = research.force.color, sound = defines.print_sound.never })
            end
        end
    end
end)

-- script.on_event(defines.events.on_cargo_pod_finished_ascending, function (event)
--     log("Cargo pod finished ascending")
--     log(serpent.block(event))
-- end)

----------------------------------------
-- CUSTOM OARC Events (shown here for demo and logging purposes)
----------------------------------------

---@class OarcCustomEventBase
---@field mod_name string
---@field name integer --For custom events, this is the event ID
---@field tick integer

---@class OarcModOnSpawnChoicesGuiDisplayedEvent: OarcCustomEventBase
---@field player_index integer
---@field gui_element LuaGuiElement
script.on_event("oarc-mod-on-spawn-choices-gui-displayed", function(event)
    log("EVENT - oarc-mod-on-spawn-choices-gui-displayed:" .. serpent.block(event --[[@as OarcModOnSpawnChoicesGuiDisplayedEvent]]))
    -- The 4 main sub sections are called: spawn_settings_frame, solo_spawn_frame, shared_spawn_frame, and buddy_spawn_frame
end)


---@class OarcModOnSpawnCreatedEvent: OarcCustomEventBase
---@field spawn_data OarcUniqueSpawn
script.on_event("oarc-mod-on-spawn-created", function(event)
    log("EVENT - oarc-mod-on-spawn-created:" .. serpent.block(event --[[@as OarcModOnSpawnCreatedEvent]]))
end)

---@class OarcModOnSpawnRemoveRequestEvent: OarcCustomEventBase
---@field spawn_data OarcUniqueSpawn
script.on_event("oarc-mod-on-spawn-remove-request", function(event)
    log("EVENT - oarc-mod-on-spawn-remove-request:" .. serpent.block(event --[[@as OarcModOnSpawnRemoveRequestEvent]]))
end)

---@class OarcModOnPlayerResetEvent: OarcCustomEventBase
---@field player_index integer
script.on_event("oarc-mod-on-player-reset", function(event)
    log("EVENT - oarc-mod-on-player-reset:" .. serpent.block(event --[[@as OarcModOnPlayerResetEvent]]))
end)

---@class OarcModOnPlayerSpawnedEvent: OarcCustomEventBase
---@field player_index integer
---@field first_spawn boolean
---@field is_host boolean
script.on_event("oarc-mod-on-player-spawned", function(event)
    log("EVENT - oarc-mod-on-player-spawned:" .. serpent.block(event --[[@as OarcModOnPlayerSpawnedEvent]]))
end)

---@class OarcModCharacterSurfaceChangedEvent: OarcCustomEventBase
---@field player_index integer
---@field old_surface_name string
---@field new_surface_name string
script.on_event("oarc-mod-character-surface-changed", function(event)
    log("EVENT - oarc-mod-character-surface-changed:" .. serpent.block(event --[[@as OarcModCharacterSurfaceChangedEvent]]))

    --This is just here so I don't get lua warnings about unused variables.
    ---@type OarcModCharacterSurfaceChangedEvent
    local custom_event = event --[[@as OarcModCharacterSurfaceChangedEvent]]

    local player = game.players[custom_event.player_index]
    SeparateSpawnsPlayerChangedSurface(player, custom_event.old_surface_name, custom_event.new_surface_name)
end)

---@class OarcModOnChunkGeneratedNearSpawnEvent: OarcCustomEventBase
---@field surface LuaSurface
---@field chunk_area BoundingBox
---@field spawn_data OarcUniqueSpawn
-- script.on_event("oarc-mod-on-chunk-generated-near-spawn", function(event)
--  I wouldn't recommend any logging inside this event as it is called for every chunk generated near a spawn.
--     log("EVENT - oarc-mod-on-chunk-generated-near-spawn:" .. serpent.block(event --[[@as OarcModOnChunkGeneratedNearSpawnEvent]]))
-- end)

---@class OarcModOnConfigChangedEvent: OarcCustomEventBase
-- script.on_event("oarc-mod-on-config-changed", function(event)
-- This can get called quite a lot during init or importing of settings.
--     log("EVENT - oarc-mod-on-config-changed:" .. serpent.block(event --[[@as OarcModOnConfigChangedEvent]]))
-- end)

-- I raise this event whenever teleporting the player!
script.on_event(defines.events.script_raised_teleported, function(event)
    local entity = event.entity
    if entity.type == "character" and entity.player then
        SeparateSpawnsUpdatePlayerSurface(entity.player, entity.surface.name)
    end
end)

----------------------------------------
-- Shared chat, so you don't have to type /s
-- But you do lose your player colors across forces.
----------------------------------------
script.on_event(defines.events.on_console_chat, function(event)
    if (storage.ocfg.gameplay.enable_shared_team_chat) then
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
    OnTickNilCharacterTeleportQueue()

    if storage.ocfg.regrowth.enable_regrowth then
        RegrowthOnTick()
    end
    RegrowthForceRemovalOnTick() -- Allows for abandoned base cleanup without regrowth enabled.

    if storage.ocfg.gameplay.modified_enemy_spawning then
        RemoveDemolishersInWarningZone(event)
    end
end)

----------------------------------------
-- Chunk Generation
----------------------------------------
script.on_event(defines.events.on_chunk_generated, function(event)
    if storage.ocfg.regrowth.enable_regrowth then
        RegrowthChunkGenerate(event)
    end

    CreateHoldingPenChunks(event)

    if storage.ocfg.gameplay.modified_enemy_spawning then
        DowngradeWormsDistanceBasedOnChunkGenerate(event)
        DowngradeAndReduceEnemiesOnChunkGenerate(event)
    end

    SeparateSpawnsGenerateChunk(event)
end)

----------------------------------------
-- Radar Scanning
----------------------------------------
script.on_event(defines.events.on_sector_scanned, function (event)
    if storage.ocfg.regrowth.enable_regrowth then
        RegrowthSectorScan(event)
    end
end)

----------------------------------------
-- Surface Generation
----------------------------------------
-- This is not called when the default surface "nauvis" is created as it will always exist!
script.on_event(defines.events.on_surface_created, function(event)
    local surface = game.surfaces[event.surface_index]

    log("Surface created: " .. surface.name)
    if IsSurfaceBlacklisted(surface.name) then return end

    SeparateSpawnsSurfaceCreated(event)
    RegrowthSurfaceCreated(event)
end)

script.on_event(defines.events.on_pre_surface_deleted, function(event)
    local surface = game.surfaces[event.surface_index]

    log("Surface deleted: " .. surface.name)
    if IsSurfaceBlacklisted(surface.name) then return end

    SeparateSpawnsSurfaceDeleted(event)
    RegrowthSurfaceDeleted(event)
end)

----------------------------------------
-- Various on "built" events
----------------------------------------
script.on_event(defines.events.on_built_entity, function(event)
    if storage.ocfg.regrowth.enable_regrowth then
        RegrowthMarkAreaSafeGivenTilePos(event.entity.surface.name, event.entity.position, 2, false)
    end

    -- For tracking spidertrons...
    RegrowthOnBuiltEntity(event)
end)

script.on_event(defines.events.on_robot_built_entity, function (event)
    if storage.ocfg.regrowth.enable_regrowth then
        RegrowthMarkAreaSafeGivenTilePos(event.entity.surface.name, event.entity.position, 2, false)
    end
end)

script.on_event(defines.events.on_player_built_tile, function (event)
    if storage.ocfg.regrowth.enable_regrowth then
        for _,v in pairs(event.tiles) do
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
    if storage.ocfg.regrowth.enable_regrowth then
        RegrowthMarkAreaSafeGivenTilePos(event.entity.surface.name, event.entity.position, 2, false)
    end
end)

----------------------------------------
-- On Entity Spawned and On Biter Base Built
-- This is where I modify biter spawning based on location and other factors.
----------------------------------------
script.on_event(defines.events.on_entity_spawned, function(event)
    if (storage.ocfg.gameplay.modified_enemy_spawning) then
        ModifyEnemySpawnsNearPlayerStartingAreas(event)
    end
end)

script.on_event(defines.events.on_biter_base_built, function(event)
    if (storage.ocfg.gameplay.modified_enemy_spawning) then
        ModifyEnemySpawnsNearPlayerStartingAreas(event)
    end
end)

script.on_event(defines.events.on_segment_entity_created, function(event)
    if storage.ocfg.gameplay.modified_enemy_spawning then
        TrackDemolishers(event)
    end
end)

----------------------------------------
-- On unit group finished gathering
-- This is where I remove biter waves on offline players
----------------------------------------
script.on_event(defines.events.on_unit_group_finished_gathering, function(event)
    if (storage.ocfg.gameplay.enable_offline_protection) then
        OarcModifyEnemyGroup(event)
    end
end)

----------------------------------------
-- On enemies killed
-- For coin generation and stuff
----------------------------------------
script.on_event(defines.events.on_post_entity_died, function(event)
    if storage.ocfg.coin_generation.enabled then
        CoinsFromEnemiesOnPostEntityDied(event)
    end
end,
{{filter="type", type = "unit"}, {filter="type", type = "unit-spawner"}, {filter="type", type = "turret"}})

script.on_event(defines.events.on_entity_damaged, function(event)
    if storage.ocfg.gameplay.scale_spawner_damage then
        ApplySpawnerDamageScaling(event)
    end
end,
{{filter="type", type = "unit-spawner"}})

----------------------------------------
-- Gui Events
----------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
    if not event.element.valid then return end

    SeparateSpawnsGuiClick(event)
    OarcGuiTabsClick(event)
end)

--- Called when LuaGuiElement checked state is changed (related to checkboxes and radio buttons).
script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    if not event.element.valid then return end

    SeparateSpawnsGuiCheckedStateChanged(event)
    OarcGuiTabsCheckedStateChanged(event)
end)

script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
    if not event.element.valid then return end

    OarcGuiTabsSelectedTabChanged(event)
end)

-- For capturing player escaping custom GUI so we can close it using ESC key.
script.on_event(defines.events.on_gui_closed, function(event)
    OarcGuiClosed(event)
end)


--- For sliders and other value changing elements.
script.on_event(defines.events.on_gui_value_changed, function(event)
    if not event.element.valid then return end

    SeparateSpawnsGuiValueChanged(event)
    OarcGuiTabsValueChanged(event)
end)

--- For dropdowns and listboxes.
script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    if not event.element.valid then return end

    SeparateSpawnsGuiSelectionStateChanged(event)
    OarcGuiTabsSelectionStateChanged(event)
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    if not event.element.valid then return end

    OarcGuiTabsTextChanged(event)
end)

script.on_event(defines.events.on_gui_confirmed, function(event)
    if not event.element.valid then return end

    OarcGuiTabsConfirmed(event)
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
    if not event.element.valid then return end

    OarcGuiTabsElemChanged(event)
end)

----------------------------------------
-- Remote Interface
----------------------------------------
local oarc_mod_interface =
{
  get_mod_settings = function()
    return storage.ocfg
  end,

  get_unique_spawns = function()
    return storage.unique_spawns
  end,

  get_player_home_spawn = function(player_name)
    return FindPlayerHomeSpawn(player_name)
  end,

  get_player_primary_spawn = function(player_name)
    return FindPrimaryUniqueSpawn(player_name)
  end,
}

remote.add_interface("oarc_mod", oarc_mod_interface)
