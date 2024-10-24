-- This file is used to validate the config.lua file and handle any mod settings conflicts.
-- DON'T JUDGE ME! I wanted to try and make a nice in game setting GUI since the native mod settings GUI is so limited.

---Provides a way to look up the config settings key from the mod settings key.
---@alias OarcSettingsLookup { mod_key: string, ocfg_keys: table<integer, string>, type: string, text: LocalisedString?, caption: LocalisedString?, tooltip: LocalisedString?  }

---@type table<string, OarcSettingsLookup>
OCFG_KEYS =
{
    ["server_info_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-server-info"}},
    ["server_info.welcome_msg_title"] = {mod_key = "oarc-mod-welcome-msg-title" , ocfg_keys = {"server_info", "welcome_msg_title"}, type = "string"},
    ["server_info.welcome_msg"] = {mod_key = "oarc-mod-welcome-msg" , ocfg_keys = {"server_info", "welcome_msg"}, type = "string"},
    ["server_info.discord_invite"] = {mod_key = "oarc-mod-discord-invite" , ocfg_keys = {"server_info", "discord_invite"}, type = "string"},

    ["gameplay_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-gameplay"}},
    ["gameplay_spawn_choices_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-spawn-choices"}},
    ["gameplay.enable_main_team"] = {mod_key = "oarc-mod-enable-main-team" , ocfg_keys = {"gameplay", "enable_main_team"}, type = "boolean"},
    ["gameplay.enable_separate_teams"] = {mod_key = "oarc-mod-enable-separate-teams" , ocfg_keys = {"gameplay", "enable_separate_teams"}, type = "boolean"},
    -- STARTUP ["gameplay.enable_spawning_on_other_surfaces"] = {mod_key = "oarc-mod-default-allow-spawning-on-other-surfaces" , ocfg_keys = {"gameplay", "enable_spawning_on_other_surfaces"}, type = "boolean"},
    ["gameplay.allow_moats_around_spawns"] = {mod_key = "oarc-mod-allow-moats-around-spawns" , ocfg_keys = {"gameplay", "allow_moats_around_spawns"}, type = "boolean"},
    ["gameplay.enable_moat_bridging"] = {mod_key = "oarc-mod-enable-moat-bridging" , ocfg_keys = {"gameplay", "enable_moat_bridging"}, type = "boolean"},
    ["gameplay.minimum_distance_to_existing_chunks"] = {mod_key = "oarc-mod-minimum-distance-to-existing-chunks" , ocfg_keys = {"gameplay", "minimum_distance_to_existing_chunks"}, type = "integer"},
    ["gameplay.near_spawn_distance"] = {mod_key = "oarc-mod-near-spawn-distance" , ocfg_keys = {"gameplay", "near_spawn_distance"}, type = "integer"},
    ["gameplay.far_spawn_distance"] = {mod_key = "oarc-mod-far-spawn-distance" , ocfg_keys = {"gameplay", "far_spawn_distance"}, type = "integer"},
    ["gameplay.enable_buddy_spawn"] = {mod_key = "oarc-mod-enable-buddy-spawn" , ocfg_keys = {"gameplay", "enable_buddy_spawn"}, type = "boolean"},
    ["gameplay.enable_shared_spawns"] = {mod_key = "oarc-mod-enable-shared-spawns" , ocfg_keys = {"gameplay", "enable_shared_spawns"}, type = "boolean"},
    ["gameplay.number_of_players_per_shared_spawn"] = {mod_key = "oarc-mod-number-of-players-per-shared-spawn" , ocfg_keys = {"gameplay", "number_of_players_per_shared_spawn"}, type = "integer"},
    ["gameplay.default_surface"] = {mod_key = "oarc-mod-default-surface" , ocfg_keys = {"gameplay", "default_surface"}, type = "string"},
    ["gameplay.enable_secondary_spawns"] = {mod_key = "oarc-mod-enable-secondary-spawns" , ocfg_keys = {"gameplay", "enable_secondary_spawns"}, type = "boolean"},
    -- STARTUP ["gameplay.main_force_name"] = {mod_key = "oarc-mod-main-force-name" , ocfg_keys = {"gameplay", "main_force_name"}, type = "string"},

    ["gameplay_difficulty_scaling_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-difficulty-scaling"}},
    ["gameplay.enable_offline_protection"] = {mod_key = "oarc-mod-enable-offline-protection" , ocfg_keys = {"gameplay", "enable_offline_protection"}, type = "boolean"},
    ["gameplay.scale_resources_around_spawns"] = {mod_key = "oarc-mod-scale-resources-around-spawns" , ocfg_keys = {"gameplay", "scale_resources_around_spawns"}, type = "boolean"},
    ["gameplay.modified_enemy_spawning"] = {mod_key = "oarc-mod-modified-enemy-spawning" , ocfg_keys = {"gameplay", "modified_enemy_spawning"}, type = "boolean"},
    -- ["gameplay.modified_enemy_easy_evo"] = {mod_key = "oarc-mod-modified-enemy-easy-evo" , ocfg_keys = {"gameplay", "modified_enemy_easy_evo"}, type = "double"},
    -- ["gameplay.modified_enemy_medium_evo"] = {mod_key = "oarc-mod-modified-enemy-medium-evo" , ocfg_keys = {"gameplay", "modified_enemy_medium_evo"}, type = "double"},

    ["gameplay_misc_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-gameplay-misc"}},
    ["gameplay.enable_friendly_fire"] = {mod_key = "oarc-mod-enable-friendly-fire" , ocfg_keys = {"gameplay", "enable_friendly_fire"}, type = "boolean"},
    ["gameplay.minimum_online_time"] = {mod_key = "oarc-mod-minimum-online-time" , ocfg_keys = {"gameplay", "minimum_online_time"}, type = "integer"},
    ["gameplay.respawn_cooldown_min"] = {mod_key = "oarc-mod-respawn-cooldown-min" , ocfg_keys = {"gameplay", "respawn_cooldown_min"}, type = "integer"},

    ["gameplay_sharing_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-sharing"}},
    ["gameplay.enable_shared_team_vision"] = {mod_key = "oarc-mod-enable-shared-team-vision" , ocfg_keys = {"gameplay", "enable_shared_team_vision"}, type = "boolean"},
    ["gameplay.enable_shared_team_chat"] = {mod_key = "oarc-mod-enable-shared-team-chat" , ocfg_keys = {"gameplay", "enable_shared_team_chat"}, type = "boolean"},
    ["gameplay.enable_shared_power"] = {mod_key = "oarc-mod-enable-shared-power" , ocfg_keys = {"gameplay", "enable_shared_power"}, type = "boolean"},
    ["gameplay.enable_shared_chest"] = {mod_key = "oarc-mod-enable-shared-chest" , ocfg_keys = {"gameplay", "enable_shared_chest"}, type = "boolean"},
    ["gameplay.enable_coin_shop"] = {mod_key = "oarc-mod-enable-coin-shop" , ocfg_keys = {"gameplay", "enable_coin_shop"}, type = "boolean"},

    ["regrowth_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-regrowth"}},
    ["regrowth_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-regrowth-warning"}},
    ["regrowth.enable_regrowth"] = {mod_key = "oarc-mod-enable-regrowth" , ocfg_keys = {"regrowth", "enable_regrowth"}, type = "boolean"},
    ["regrowth.enable_world_eater"] = {mod_key = "oarc-mod-enable-world-eater" , ocfg_keys = {"regrowth", "enable_world_eater"}, type = "boolean"},
    ["regrowth.enable_abandoned_base_cleanup"] = {mod_key = "oarc-mod-enable-abandoned-base-cleanup" , ocfg_keys = {"regrowth", "enable_abandoned_base_cleanup"}, type = "boolean"},
    ["regrowth.cleanup_interval"] = {mod_key = "oarc-mod-regrowth-cleanup-interval-min" , ocfg_keys = {"regrowth", "cleanup_interval"}, type = "integer"},

    ["general_spawn_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-general-spawn"}},
    ["spawn_general.spawn_radius_tiles"] = {mod_key = "oarc-mod-spawn-general-radius-tiles" , ocfg_keys = {"spawn_general", "spawn_radius_tiles"}, type = "integer"},
    ["spawn_general.moat_width_tiles"] = {mod_key = "oarc-mod-spawn-general-moat-width-tiles" , ocfg_keys = {"spawn_general", "moat_width_tiles"}, type = "integer"},
    ["spawn_general.tree_width_tiles"] = {mod_key = "oarc-mod-spawn-general-tree-width-tiles" , ocfg_keys = {"spawn_general", "tree_width_tiles"}, type = "integer"},
    ["spawn_general.resources_shape"] = {mod_key = "oarc-mod-spawn-general-enable-resources-circle-shape" , ocfg_keys = {"spawn_general", "resources_shape"}, type = "string-list"},
    ["spawn_general.force_grass"] = {mod_key = "oarc-mod-spawn-general-enable-force-grass" , ocfg_keys = {"spawn_general", "force_grass"}, type = "boolean"},
    ["spawn_general.shape"] = {mod_key = "oarc-mod-spawn-general-shape" , ocfg_keys = {"spawn_general", "shape"}, type = "string-list"},

    ["resource_placement_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = {"oarc-settings-section-header-resource-placement"}},
    ["resource_placement.enabled"] = {mod_key = "oarc-mod-resource-placement-enabled" , ocfg_keys = {"resource_placement", "enabled"}, type = "boolean"},
    ["resource_placement.size_multiplier"] = {mod_key = "oarc-mod-resource-placement-size-multiplier" , ocfg_keys = {"resource_placement", "size_multiplier"}, type = "double"},
    ["resource_placement.amount_multiplier"] = {mod_key = "oarc-mod-resource-placement-amount-multiplier" , ocfg_keys = {"resource_placement", "amount_multiplier"}, type = "double"},

    ["resource_placement_circle_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-resource-placement-circular"}},
    ["resource_placement.distance_to_edge"] = {mod_key = "oarc-mod-resource-placement-distance-to-edge" , ocfg_keys = {"resource_placement", "distance_to_edge"}, type = "integer"},
    ["resource_placement.angle_offset"] = {mod_key = "oarc-mod-resource-placement-degrees-offset" , ocfg_keys = {"resource_placement", "angle_offset"}, type = "integer"},
    ["resource_placement.angle_final"] = {mod_key = "oarc-mod-resource-placement-degrees-final" , ocfg_keys = {"resource_placement", "angle_final"}, type = "integer"},

    ["resource_placement_square_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = {"oarc-settings-section-subheader-resource-placement-square"}},
    ["resource_placement.vertical_offset"] = {mod_key = "oarc-mod-resource-placement-vertical-offset" , ocfg_keys = {"resource_placement", "vertical_offset"}, type = "integer"},
    ["resource_placement.horizontal_offset"] = {mod_key = "oarc-mod-resource-placement-horizontal-offset" , ocfg_keys = {"resource_placement", "horizontal_offset"}, type = "integer"},
    ["resource_placement.linear_spacing"] = {mod_key = "oarc-mod-resource-placement-linear-spacing" , ocfg_keys = {"resource_placement", "linear_spacing"}, type = "integer"},

    -- These are settings that aren't included in the games mod settings but are still nice to have easy access to.
    ["non_mod_settings_HEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "header", text = "Additional Settings (Not available in the mod settings menu.)"},
    ["coin_generation_SUBHEADER"] = {mod_key = "" , ocfg_keys = {""}, type = "subheader", text = "Coin Generation"},
    ["coin_generation.enabled"] = {mod_key = "" , ocfg_keys = {"coin_generation", "enabled"}, type = "boolean", caption = "Coin Generation", tooltip = "Enemies drop coins when killed."},
    ["coin_generation.auto_decon_coins"] = {mod_key = "" , ocfg_keys = {"coin_generation", "auto_decon_coins"}, type = "boolean", caption = "Auto Decon Coins", tooltip = "Automatically marks coins dropped by enemies for deconstruction so robots will pick them up."},
    ["gameplayer.enable_player_self_reset"] = {mod_key = "" , ocfg_keys = {"gameplay", "enable_player_self_reset"}, type = "boolean", caption = "Player Self Reset", tooltip = "Allow players to reset themselves in the spawn controls."}
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
        SendBroadcastMsg("ERROR - Missing server_info section in config! Loading defaults instead!")
        storage.ocfg.server_info = table.deepcopy(OCFG.server_info)
    end
    if (storage.ocfg["gameplay"] == nil) then
        log("ERROR - Missing gameplay section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing gameplay section in config! Loading defaults instead!")
        storage.ocfg.gameplay = table.deepcopy(OCFG.gameplay)
    end
    if (storage.ocfg["regrowth"] == nil) then
        log("ERROR - Missing regrowth section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing regrowth section in config! Loading defaults instead!")
        storage.ocfg.regrowth = table.deepcopy(OCFG.regrowth)
    end
    if (storage.ocfg["spawn_general"] == nil) then
        log("ERROR - Missing spawn_general section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing spawn_general section in config! Loading defaults instead!")
        storage.ocfg.spawn_general = table.deepcopy(OCFG.spawn_general)
    end
    if (storage.ocfg["resource_placement"] == nil) then
        log("ERROR - Missing resource_placement section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing resource_placement section in config! Loading defaults instead!")
        storage.ocfg.resource_placement = table.deepcopy(OCFG.resource_placement)
    end
    if (storage.ocfg["surfaces_config"] == nil) then
        log("ERROR - Missing surfaces_config section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing surfaces_config section in config! Loading defaults instead!")
        storage.ocfg.surfaces_config = table.deepcopy(OCFG.surfaces_config)
    end
    if (storage.ocfg["surfaces_blacklist"] == nil) then
        log("ERROR - Missing surfaces_blacklist section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing surfaces_blacklist section in config! Loading defaults instead!")
        storage.ocfg.surfaces_blacklist = table.deepcopy(OCFG.surfaces_blacklist)
    end
    if (storage.ocfg["surfaces_blacklist_match"] == nil) then
        log("ERROR - Missing surfaces_blacklist_match section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing surfaces_blacklist_match section in config! Loading defaults instead!")
        storage.ocfg.surfaces_blacklist_match = table.deepcopy(OCFG.surfaces_blacklist_match)
    end
    if (storage.ocfg["shop_items"] == nil) then
        log("ERROR - Missing shop_items section in config! Loading defaults instead!")
        SendBroadcastMsg("ERROR - Missing shop_items section in config! Loading defaults instead!")
        storage.ocfg.shop_items = table.deepcopy(OCFG.shop_items)
    end


    -- Validate enable_main_team and enable_separate_teams.
    -- Force enable_main_team if both are disabled.
    if (not storage.ocfg.gameplay.enable_main_team and not storage.ocfg.gameplay.enable_separate_teams) then
        log("Both main force and separate teams are disabled! Enabling main force. Please check your mod settings or config!")
        storage.ocfg.gameplay.enable_main_team = true
        settings.global["oarc-mod-enable-main-team"] = { value = true }
        SendBroadcastMsg("Invalid setting! Both main force and separate teams are disabled! Enabling main force.")
    end

    -- Validate minimum is less than maximums
    if (storage.ocfg.gameplay.near_spawn_distance >= storage.ocfg.gameplay.far_spawn_distance) then
        log("Near spawn min distance is greater than or equal to near spawn max distance! Please check your mod settings or config!")
        storage.ocfg.gameplay.far_spawn_distance = storage.ocfg.gameplay.near_spawn_distance + 1
        settings.global["oarc-mod-far-spawn-distance"] = { value = storage.ocfg.gameplay.far_spawn_distance }
        SendBroadcastMsg("Invalid setting! Near spawn min distance is greater than or equal to near spawn max distance!")
    end

    -- Validate that regrowth is enabled if world eater is enabled.
    if (storage.ocfg.regrowth.enable_world_eater and not storage.ocfg.regrowth.enable_regrowth) then
        log("World eater is enabled but regrowth is not! Disabling world eater. Please check your mod settings or config!")
        storage.ocfg.regrowth.enable_world_eater = false
        settings.global["oarc-mod-enable-world-eater"] = { value = false }
        SendBroadcastMsg("Invalid setting! World eater is enabled but regrowth is not! Disabling world eater.")
    end

    -- Validate that default surface exists.
    if (game.surfaces[storage.ocfg.gameplay.default_surface] == nil) then
        log("Default surface does not exist! Please check your mod settings or config!")
        storage.ocfg.gameplay.default_surface = "nauvis"
        settings.global["oarc-mod-default-surface"] = { value = "nauvis" }
        SendBroadcastMsg("Invalid setting! Default surface does not exist! Setting to nauvis.")
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

    -- Special case for startup settings
    storage.ocfg.gameplay.default_allow_spawning_on_other_surfaces = settings.startup["oarc-mod-default-allow-spawning-on-other-surfaces"].value  --[[@as boolean]]
    storage.ocfg.gameplay.main_force_name = settings.startup["oarc-mod-main-force-name"].value --[[@as string]]
end

---Get the scenario settings from the scenario if it exists.
---@return nil
function GetScenarioOverrideSettings()

    if remote.interfaces["oarc_scenario"] then

        log("Getting scenario override settings...")
        local scenario_settings = remote.call("oarc_scenario", "get_scenario_settings")

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
        error("Unknown oarc-mod setting changed: " .. event.setting)
    else
        ValidateSettings()
        ApplyRuntimeChanges(OCFG_MOD_KEYS[event.setting])
    end

    --Exception for coin shop, update the GUI if the setting is changed
    if (event.setting == "oarc-mod-enable-coin-shop") then
        local new_value = storage.ocfg.gameplay.enable_coin_shop
        AddRemoveOarcGuiTabForAllPlayers(OARC_ITEM_SHOP_TAB_NAME, settings.global[event.setting].value --[[@as boolean]], true)
    end
end

---A probably quit stupid function to let me lookup and set the storage.ocfg entries using a key table.
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

    ---Handle changing enable_shared_team_vision
    if (oarc_setting_index == "gameplay.enable_shared_team_vision") then
        for _,force in pairs(game.forces) do
            if (not TableContains(ENEMY_FORCES_NAMES_INCL_NEUTRAL, force.name)) then
                force.share_chart = storage.ocfg.gameplay.enable_shared_team_vision
            end
        end

    ---Handle changing enable_friendly_fire
    elseif (oarc_setting_index == "gameplay.enable_friendly_fire") then
        for _,force in pairs(game.forces) do
            if (not TableContains(ENEMY_FORCES_NAMES_INCL_NEUTRAL, force.name)) then
                force.friendly_fire = storage.ocfg.gameplay.enable_friendly_fire
            end
        end

    end
end