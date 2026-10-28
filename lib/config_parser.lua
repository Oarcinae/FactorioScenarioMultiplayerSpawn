-- This file is used to validate the config.lua file and handle any mod settings conflicts.
-- DON'T JUDGE ME! I wanted to try and make a nice in game setting GUI since the native mod settings GUI is so limited.

---Provides a way to look up the config settings key from the mod settings key.
---prefab_only entries only apply to Oarc style spawns, so the settings tab hides them when those are not allowed.
---@alias OarcSettingsLookup { mod_key: string, ocfg_keys: table<integer, string>, type: string, text: LocalisedString?, caption: LocalisedString?, tooltip: LocalisedString?, prefab_only: boolean? }

---@type table<string, OarcSettingsLookup>
OCFG_KEYS =
{
    ["server_info_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-server-info"}},
    ["server_info.welcome_msg_title"] = {mod_key = "oarc-classic-welcome-msg-title" , ocfg_keys = {"server_info", "welcome_msg_title"}, type = "string"},
    ["server_info.welcome_msg"] = {mod_key = "oarc-classic-welcome-msg" , ocfg_keys = {"server_info", "welcome_msg"}, type = "string"},
    ["server_info.discord_invite"] = {mod_key = "oarc-classic-discord-invite" , ocfg_keys = {"server_info", "discord_invite"}, type = "string"},

    ["gameplay_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-gameplay"}},
    ["gameplay_spawn_choices_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-spawn-choices"}},
    ["gameplay.allow_oarc_style_spawn"] = {mod_key = "oarc-classic-allow-oarc-style-spawn" , ocfg_keys = {"gameplay", "allow_oarc_style_spawn"}, type = "boolean"},
    ["gameplay.allow_moats_around_spawns"] = {mod_key = "oarc-classic-allow-moats-around-spawns" , ocfg_keys = {"gameplay", "allow_moats_around_spawns"}, type = "boolean", prefab_only = true},
    ["gameplay.enable_moat_bridging"] = {mod_key = "oarc-classic-enable-moat-bridging" , ocfg_keys = {"gameplay", "enable_moat_bridging"}, type = "boolean", prefab_only = true},
    ["gameplay.enable_shared_spawns"] = {mod_key = "oarc-classic-enable-shared-spawns" , ocfg_keys = {"gameplay", "enable_shared_spawns"}, type = "boolean"},
    ["gameplay.number_of_players_per_shared_spawn"] = {mod_key = "oarc-classic-number-of-players-per-shared-spawn" , ocfg_keys = {"gameplay", "number_of_players_per_shared_spawn"}, type = "integer"},
    ["gameplay.default_surface"] = {mod_key = "oarc-classic-default-surface" , ocfg_keys = {"gameplay", "default_surface"}, type = "string"},

    ["gameplay.enable_offline_protection"] = {mod_key = "oarc-classic-enable-offline-protection" , ocfg_keys = {"gameplay", "enable_offline_protection"}, type = "boolean"},
    ["gameplay.reset_evolution_on_new_spawn"] = {mod_key = "oarc-classic-reset-evolution-on-new-spawn" , ocfg_keys = {"gameplay", "reset_evolution_on_new_spawn"}, type = "boolean"},

    ["gameplay_misc_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-gameplay-misc"}},
    ["gameplay.enable_friendly_fire"] = {mod_key = "oarc-classic-enable-friendly-fire" , ocfg_keys = {"gameplay", "enable_friendly_fire"}, type = "boolean"},
    ["gameplay.minimum_online_time"] = {mod_key = "oarc-classic-minimum-online-time" , ocfg_keys = {"gameplay", "minimum_online_time"}, type = "integer"},
    ["gameplay.respawn_cooldown_min"] = {mod_key = "oarc-classic-respawn-cooldown-min" , ocfg_keys = {"gameplay", "respawn_cooldown_min"}, type = "integer"},

    ["gameplay_sharing_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-sharing"}},
    ["gameplay.enable_shared_team_vision"] = {mod_key = "oarc-classic-enable-shared-team-vision" , ocfg_keys = {"gameplay", "enable_shared_team_vision"}, type = "boolean"},
    ["gameplay.enable_shared_team_chat"] = {mod_key = "oarc-classic-enable-shared-team-chat" , ocfg_keys = {"gameplay", "enable_shared_team_chat"}, type = "boolean"},
    ["gameplay.enable_friendly_teams"] = {mod_key = "oarc-classic-enable-friendly-teams" , ocfg_keys = {"gameplay", "enable_friendly_teams"}, type = "boolean"},
    ["gameplay.enable_cease_fire"] = {mod_key = "oarc-classic-enable-cease-fire" , ocfg_keys = {"gameplay", "enable_cease_fire"}, type = "boolean"},

    ["regrowth_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-regrowth"}},
    ["regrowth_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-regrowth-warning"}},
    ["regrowth.enable_regrowth"] = {mod_key = "oarc-classic-enable-regrowth" , ocfg_keys = {"regrowth", "enable_regrowth"}, type = "boolean"},
    ["regrowth.enable_world_eater"] = {mod_key = "oarc-classic-enable-world-eater" , ocfg_keys = {"regrowth", "enable_world_eater"}, type = "boolean"},
    ["regrowth.enable_abandoned_base_cleanup"] = {mod_key = "oarc-classic-enable-abandoned-base-cleanup" , ocfg_keys = {"regrowth", "enable_abandoned_base_cleanup"}, type = "boolean"},
    ["regrowth.cleanup_interval"] = {mod_key = "oarc-classic-regrowth-cleanup-interval-min" , ocfg_keys = {"regrowth", "cleanup_interval"}, type = "integer"},

    ["general_spawn_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-general-spawn"}, prefab_only = true},
    ["spawn_general.spawn_radius_tiles"] = {mod_key = "oarc-classic-spawn-general-radius-tiles" , ocfg_keys = {"spawn_general", "spawn_radius_tiles"}, type = "integer", prefab_only = true},
    ["spawn_general.moat_width_tiles"] = {mod_key = "oarc-classic-spawn-general-moat-width-tiles" , ocfg_keys = {"spawn_general", "moat_width_tiles"}, type = "integer", prefab_only = true},
    ["spawn_general.tree_width_tiles"] = {mod_key = "oarc-classic-spawn-general-tree-width-tiles" , ocfg_keys = {"spawn_general", "tree_width_tiles"}, type = "integer", prefab_only = true},
    ["spawn_general.resources_shape"] = {mod_key = "oarc-classic-spawn-general-enable-resources-circle-shape" , ocfg_keys = {"spawn_general", "resources_shape"}, type = "string-list", prefab_only = true},
    ["spawn_general.force_tiles"] = {mod_key = "oarc-classic-spawn-general-enable-force-tiles" , ocfg_keys = {"spawn_general", "force_tiles"}, type = "boolean", prefab_only = true},
    ["spawn_general.shape"] = {mod_key = "oarc-classic-spawn-general-shape" , ocfg_keys = {"spawn_general", "shape"}, type = "string-list", prefab_only = true},

    ["resource_placement_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-resource-placement"}, prefab_only = true},
    ["resource_placement.enabled"] = {mod_key = "oarc-classic-resource-placement-enabled" , ocfg_keys = {"resource_placement", "enabled"}, type = "boolean", prefab_only = true},
    ["resource_placement.size_multiplier"] = {mod_key = "oarc-classic-resource-placement-size-multiplier" , ocfg_keys = {"resource_placement", "size_multiplier"}, type = "double", prefab_only = true},
    ["resource_placement.amount_multiplier"] = {mod_key = "oarc-classic-resource-placement-amount-multiplier" , ocfg_keys = {"resource_placement", "amount_multiplier"}, type = "double", prefab_only = true},

    ["resource_placement_circle_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-resource-placement-circular"}, prefab_only = true},
    ["resource_placement.distance_to_edge"] = {mod_key = "oarc-classic-resource-placement-distance-to-edge" , ocfg_keys = {"resource_placement", "distance_to_edge"}, type = "integer", prefab_only = true},
    ["resource_placement.angle_offset"] = {mod_key = "oarc-classic-resource-placement-degrees-offset" , ocfg_keys = {"resource_placement", "angle_offset"}, type = "integer", prefab_only = true},
    ["resource_placement.angle_final"] = {mod_key = "oarc-classic-resource-placement-degrees-final" , ocfg_keys = {"resource_placement", "angle_final"}, type = "integer", prefab_only = true},

    ["resource_placement_square_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-resource-placement-square"}, prefab_only = true},
    ["resource_placement.vertical_offset"] = {mod_key = "oarc-classic-resource-placement-vertical-offset" , ocfg_keys = {"resource_placement", "vertical_offset"}, type = "integer", prefab_only = true},
    ["resource_placement.horizontal_offset"] = {mod_key = "oarc-classic-resource-placement-horizontal-offset" , ocfg_keys = {"resource_placement", "horizontal_offset"}, type = "integer", prefab_only = true},
    ["resource_placement.linear_spacing"] = {mod_key = "oarc-classic-resource-placement-linear-spacing" , ocfg_keys = {"resource_placement", "linear_spacing"}, type = "integer", prefab_only = true},

    -- These are settings that aren't included in the games mod settings but are still nice to have easy access to.
    ["non_mod_settings_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-non-mod-settings-header"}},
    ["gameplay.enable_player_self_reset"] = {mod_key = "" , ocfg_keys = {"gameplay", "enable_player_self_reset"}, type = "boolean", caption = {"oarc-player-self-reset-caption"}, tooltip = {"oarc-player-self-reset-tooltip"}},
    ["spawn_general.remove_decoratives"] = {mod_key = "" , ocfg_keys = {"spawn_general", "remove_decoratives"}, type = "boolean", caption = {"oarc-remove-decoratives-caption"}, tooltip = {"oarc-remove-decoratives-tooltip"}, prefab_only = true},
    ["resource_placement.random_order"] = {mod_key = "" , ocfg_keys = {"resource_placement", "random_order"}, type = "boolean", caption = {"oarc-resource-placement-random-order-caption"}, tooltip = {"oarc-resource-placement-random-order-tooltip"}, prefab_only = true},

}

---Easy reverse lookup for mod settings keys.
---@type table<string, string>
local OCFG_MOD_KEYS = {}

---Create the reverse lookup table.
---@return nil
function SetupOCFGModKeys()
    for key,entry in pairs(OCFG_KEYS) do
        if (entry.type ~= "header") and (entry.type ~= "subheader") then
            OCFG_MOD_KEYS[entry.mod_key] = key
        end
    end
end

function ValidateAndLoadConfig()

    SetupOCFGModKeys()

    -- Check that each of the OCFG_MOD_KEYS has a corresponding OCFG_KEYS entry.
    for mod_key,ocfg_key in pairs(OCFG_MOD_KEYS) do
        if (OCFG_KEYS[ocfg_key] == nil) then
            error("OCFG_MOD_KEYS entry does not have a corresponding OCFG_KEYS entry: " .. mod_key .. " -> " .. ocfg_key)
        end
    end
    -- And check the opposite.
    for ocfg_key,entry in pairs(OCFG_KEYS) do
        if (entry.type ~= "header") and (entry.type ~= "subheader") and (OCFG_MOD_KEYS[entry.mod_key] == nil) then
            error("OCFG_KEYS entry does not have a corresponding OCFG_MOD_KEYS entry: " .. ocfg_key .. " -> " .. entry.mod_key)
        end
    end

    -- Load the template config into the global table.
    ---@class OarcConfig
    storage.ocfg = table.deepcopy(OCFG)

    -- Check that each entry in OCFG matches the default value of the mod setting. This is just for my own sanity.
    -- Helps make sure mod default settings and my internal config are in sync.
    for _,entry in pairs(OCFG_KEYS) do
        if (entry.mod_key ~= "") then
            local mod_key = entry.mod_key
            local oarc_key = entry.ocfg_keys
            local mod_value = prototypes.mod_setting[mod_key].default_value
            local oarc_value = GetGlobalOarcConfigUsingKeyTable(oarc_key)
            if (mod_value ~= oarc_value) then
                error("OCFG value does not match mod setting: " .. mod_key .. " = " .. tostring(mod_value) .. " -> " .. serpent.block(oarc_key) .. " = " .. tostring(oarc_value))
            end
        end
    end

    CacheModSettings() -- Get all mod settings and overwrite the defaults in OARC_CFG.

    GetScenarioOverrideSettings() -- Get any scenario settings and overwrite both the mod settings and OARC_CFG.

    SyncModSettingsToOCFG() -- Make sure mod settings are in sync with storage.ocfg table.

    ValidateSettings() -- These are validation checks that can't be done within the mod settings natively.
end

---DO some basic validation checks on the config settings.
---@return nil
function ValidateSettings()

    -- Verify the major sections exist. Not exhaustive but should catch missing sections.
    if (storage.ocfg["server_info"] == nil) then
        log("ERROR - Missing server_info section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing server_info section in config! Loading defaults instead!", { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
        storage.ocfg.server_info = table.deepcopy(OCFG.server_info)
    end
    if (storage.ocfg["gameplay"] == nil) then
        log("ERROR - Missing gameplay section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing gameplay section in config! Loading defaults instead!", { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
        storage.ocfg.gameplay = table.deepcopy(OCFG.gameplay)
    end
    if (storage.ocfg["regrowth"] == nil) then
        log("ERROR - Missing regrowth section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing regrowth section in config! Loading defaults instead!", { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
        storage.ocfg.regrowth = table.deepcopy(OCFG.regrowth)
    end
    if (storage.ocfg["spawn_general"] == nil) then
        log("ERROR - Missing spawn_general section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing spawn_general section in config! Loading defaults instead!", { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
        storage.ocfg.spawn_general = table.deepcopy(OCFG.spawn_general)
    end
    if (storage.ocfg["resource_placement"] == nil) then
        log("ERROR - Missing resource_placement section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing resource_placement section in config! Loading defaults instead!", { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
        storage.ocfg.resource_placement = table.deepcopy(OCFG.resource_placement)
    end
    if (storage.ocfg["surfaces_config"] == nil) then
        log("ERROR - Missing surfaces_config section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing surfaces_config section in config! Loading defaults instead!", { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
        storage.ocfg.surfaces_config = table.deepcopy(OCFG.surfaces_config)
    end
    if (storage.ocfg["surfaces_blacklist"] == nil) then
        log("ERROR - Missing surfaces_blacklist section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing surfaces_blacklist section in config! Loading defaults instead!", { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
        storage.ocfg.surfaces_blacklist = table.deepcopy(OCFG.surfaces_blacklist)
    end
    if (storage.ocfg["surfaces_blacklist_match"] == nil) then
        log("ERROR - Missing surfaces_blacklist_match section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing surfaces_blacklist_match section in config! Loading defaults instead!", { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
        storage.ocfg.surfaces_blacklist_match = table.deepcopy(OCFG.surfaces_blacklist_match)
    end


    -- Validate that regrowth is enabled if world eater is enabled.
    if (storage.ocfg.regrowth.enable_world_eater and not storage.ocfg.regrowth.enable_regrowth) then
        log("World eater is enabled but regrowth is not! Disabling world eater. Please check your mod settings or config!")
        storage.ocfg.regrowth.enable_world_eater = false
        settings.global["oarc-classic-enable-world-eater"] = { value = false }
    SendBroadcastMsg({"oarc-world-eater-invalid-msg"}, { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
    end

    -- Validate that default surface exists.
    if (game.surfaces[storage.ocfg.gameplay.default_surface] == nil) then
        log("Default surface does not exist! Please check your mod settings or config!")
        storage.ocfg.gameplay.default_surface = "nauvis"
        settings.global["oarc-classic-default-surface"] = { value = "nauvis" }
    SendBroadcastMsg({"oarc-default-surface-invalid-msg"}, { color = { r = 1, g = 0.2, b = 0.2 }, sound_path = "utility/cannot_build" })
    end

    -- Validate that a "nauvis" surface config exists (nauvis is the default config fallback)
    -- This should only break with a bad scenario custom config.
    if (storage.ocfg.surfaces_config["nauvis"] == nil) then
        error("nauvis surface config does not exist! Please check your mod settings or config!")
    end

    -- Very for each surface config that the item counts are valid.
    for surface_name,surface_config in pairs(storage.ocfg.surfaces_config) do
        if (table_size(surface_config.starting_items.crashed_ship_resources) > MAX_CRASHED_SHIP_RESOURCES_ITEMS) then
            error("Too many items in crashed_ship_resources for surface: " .. surface_name)
        end

        if (table_size(surface_config.starting_items.crashed_ship_wreakage) > MAX_CRASHED_SHIP_WRECKAGE_ITEMS) then
            error("Too many items in crashed_ship_wreakage for surface: " .. surface_name)
        end
    end
end

-- Read in the mod settings and copy them to the OARC_CFG table, overwriting the defaults in config.lua.
function CacheModSettings()

    log("Copying mod settings to OCFG table...")

    -- Copy the global settings from the mod settings.
    -- Find the matching OARC setting and update it.
    for _,entry in pairs(OCFG_KEYS) do
        if (entry.mod_key ~= "") then
            SetGlobalOarcConfigUsingKeyTable(entry.ocfg_keys, settings.global[entry.mod_key].value)
        end
    end

    -- Startup settings only read when the game starts, so they are left out of OCFG_KEYS.
    storage.ocfg.gameplay.starting_points_count = settings.startup["oarc-classic-starting-points-count"].value --[[@as integer]]
    storage.ocfg.gameplay.starting_points_spacing_chunks = settings.startup["oarc-classic-starting-points-spacing-chunks"].value --[[@as integer]]

    -- Remember the values the game started with, so a later change can be detected.
    storage.starting_points_startup_settings = {
        count = storage.ocfg.gameplay.starting_points_count,
        spacing_chunks = storage.ocfg.gameplay.starting_points_spacing_chunks
    }
end

---Get the scenario settings from the scenario if it exists.
---@return nil
function GetScenarioOverrideSettings()

    if remote.interfaces["oarc_classic_scenario"] then

        log("Getting scenario override settings...")
        local scenario_settings = remote.call("oarc_classic_scenario", "get_scenario_settings")

        -- Overwrite the non mod settings with the scenario settings.
        storage.ocfg = scenario_settings
    else
        log("No scenario settings found.")
    end
end

---Syncs all mod settings to the OARC config table.
---@return nil
function SyncModSettingsToOCFG()

    -- Override the mod settings with the the storage.ocfg settings.
    for _,entry in pairs(OCFG_KEYS) do
        if (entry.mod_key ~= "") then
            local mod_key = entry.mod_key
            local oarc_key = entry.ocfg_keys
            local scenario_value = GetGlobalOarcConfigUsingKeyTable(oarc_key)
            if (scenario_value ~= nil) then
                local ok,result = pcall(function() settings.global[mod_key] = { value = scenario_value } end)
                if not ok then
                    error("Error setting mod setting: " .. mod_key .. " = " .. tostring(scenario_value) .. "\n" .. "If you see this, you probably picked an invalid value for a setting override in the custom scenario.")
                end
            end
        end
    end

end

---The starting point grid is built when the game starts, so changing its startup settings on an existing save has
---no effect. Called from on_configuration_changed to tell admins.
---@param data ConfigurationChangedData
---@return nil
function WarnIfStartingPointSettingsChanged(data)
    if (not data.mod_startup_settings_changed) then return end
    local started_with = storage.starting_points_startup_settings
    if (started_with == nil) then return end

    if (settings.startup["oarc-classic-starting-points-count"].value ~= started_with.count) or
            (settings.startup["oarc-classic-starting-points-spacing-chunks"].value ~= started_with.spacing_chunks) then
        log("WARNING - Starting point startup settings changed on an existing save, they have no effect.")
        SendBroadcastMsg({"oarc-starting-points-setting-game-start-only"}, { color = { r = 1, g = 0.2, b = 0.2 } })
    end
end

---Handles the event when a mod setting is changed in the mod settings menu.
---@param event EventData.on_runtime_mod_setting_changed
---@return nil
function RuntimeModSettingChanged(event)

    if (event.setting_type ~= "runtime-global") then
        return
    end

    log("on_runtime_mod_setting_changed: " .. event.setting .. " = " .. tostring(settings.global[event.setting].value))

    -- Find the matching OARC setting and update it.
    local found_setting = false

    if (OCFG_MOD_KEYS[event.setting] ~= nil) then
        local oarc_setting_index = OCFG_MOD_KEYS[event.setting]
        local oarc_setting_table = OCFG_KEYS[oarc_setting_index]
        SetGlobalOarcConfigUsingKeyTable(oarc_setting_table.ocfg_keys, settings.global[event.setting].value)
        found_setting = true
    end

    if (not found_setting) then
        error("Unknown oarc-classic setting changed: " .. event.setting)
    else
        ValidateSettings()
        ApplyRuntimeChanges(OCFG_MOD_KEYS[event.setting])
    end

    --Exception for regrowth, refresh the content tab so the checkboxes get updated
    --Same for allowing Oarc style spawns, which shows or hides the prefab only settings
    if (event.setting == "oarc-classic-enable-regrowth") or (event.setting == "oarc-classic-allow-oarc-style-spawn") then
        for _,player in pairs(game.players) do
            OarcGuiRefreshContent(player)
        end
    end
end

---A probably quite stupid function to let me lookup and set the storage.ocfg entries using a key table.
---@param key_table table<integer, string>
---@param value any
function SetGlobalOarcConfigUsingKeyTable(key_table, value)
    local number_of_keys = #key_table

    if (number_of_keys == 1) then
        storage.ocfg[key_table[1]] = value
    elseif (number_of_keys == 2) then
        storage.ocfg[key_table[1]][key_table[2]] = value
    elseif (number_of_keys == 3) then
        storage.ocfg[key_table[1]][key_table[2]][key_table[3]] = value
    else
        error("Invalid key_table length: " .. number_of_keys .. "\n" .. serpent.block(key_table))
    end

    -- Hopefully I'm not missing any other entry points where storage.ocfg might be changed.
    script.raise_event("oarc-classic-on-config-changed", {})
end

---An equally stupid function to let me lookup the storage.ocfg entries using a key table.
---@param key_table table<integer, string>
---@return any
function GetGlobalOarcConfigUsingKeyTable(key_table)
    local number_of_keys = #key_table

    if (number_of_keys == 1) then
        if (storage.ocfg[key_table[1]] == nil) then
            error("Invalid key_table 1: " .. serpent.block(key_table))
        end
        return storage.ocfg[key_table[1]]
    elseif (number_of_keys == 2) then
        if (storage.ocfg[key_table[1]] == nil) or (storage.ocfg[key_table[1]][key_table[2]] == nil) then
            error("Invalid key_table 2: " .. serpent.block(key_table))
        end
        return storage.ocfg[key_table[1]][key_table[2]]
    elseif (number_of_keys == 3) then
        if (storage.ocfg[key_table[1]] == nil) or
            (storage.ocfg[key_table[1]][key_table[2]] == nil) or
            (storage.ocfg[key_table[1]][key_table[2]][key_table[3]] == nil) then
            error("Invalid key_table 3: " .. serpent.block(key_table))
        end
        return storage.ocfg[key_table[1]][key_table[2]][key_table[3]]
    else
        error("Invalid key_table length: " .. number_of_keys .. "\n" .. serpent.block(key_table))
    end
end

---Handles any runtime changes that need more than just the setting change.
---@param oarc_setting_index string
---@return nil
function ApplyRuntimeChanges(oarc_setting_index)

    -- Handle changing enable_shared_team_vision
    if (oarc_setting_index == "gameplay.enable_shared_team_vision") then
        for _,force in pairs(game.forces) do
            if (not TableContains(ENEMY_FORCES_NAMES_INCL_NEUTRAL, force.name)) then
                force.share_chart = storage.ocfg.gameplay.enable_shared_team_vision
            end
        end

    -- Handle changing enable_friendly_fire
    elseif (oarc_setting_index == "gameplay.enable_friendly_fire") then
        for _,force in pairs(game.forces) do
            if (not TableContains(ENEMY_FORCES_NAMES_INCL_NEUTRAL, force.name)) then
                force.friendly_fire = storage.ocfg.gameplay.enable_friendly_fire
            end
        end

    -- Handle changing enable_friendly_teams or enable_cease_fire
    elseif (oarc_setting_index == "gameplay.enable_friendly_teams") or
              (oarc_setting_index == "gameplay.enable_cease_fire") then
        ConfigurePlayerForceRelationships(storage.ocfg.gameplay.enable_cease_fire,
            storage.ocfg.gameplay.enable_friendly_teams)
    end
end
