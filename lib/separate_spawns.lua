-- Code that handles everything regarding giving each player a separate spawn

local util = require("util")
local crash_site = require("crash-site")
require("lib/spawn_area_generation")

--[[
  ___  _  _  ___  _____
 |_ _|| \| ||_ _||_   _|
  | | | .` | | |   | |
 |___||_|\_||___|  |_|

--]]

-- Hardcoded force names for special cases.
ABANDONED_FORCE_NAME = "_ABANDONED_"
-- Players are put on the vanilla player force until they have a spawn of their own.
LOBBY_FORCE_NAME = "player"
-- DESTROYED_FORCE_NAME = "_DESTROYED_"

---Initializes the globals used to track the special spawn and player status information.
---@return nil
function InitSpawnGlobalsAndForces()

    -- Contains a table of entries for each surface. This tracks which surfaces allow spawning?
    --[[@type table<string, OarcSurfaceSpawnSetting>]]
    storage.oarc_surfaces = {}
    for _, surface in pairs(game.surfaces) do
        SeparateSpawnsInitSurface(surface.name)
    end
    SeparateSpawnsInitPlanets()

    -- This contains each player's respawn point for each surface. Literally where they will respawn on death
    -- There is a way in game to change this under one of the little menu features I added. This allows players to
    -- change their respawn point to something other than their home base.
    --[[@type OarcPlayerRespawnsTable]]
    storage.player_respawns = {}

    -- This is the most important table. It is a list of all the unique spawn points.
    -- This is what chunk generation checks against, and is used for shared spawn tracking, and more.
    ---@type OarcUniqueSpawnsTable
    storage.unique_spawns = {}

    -- Each player has an option to change their respawn which has a cooldown when used.
    -- Other similar abilities/functions that require cooldowns could be added here.
    --[[@type OarcPlayerCooldownsTable]]
    storage.player_cooldowns = {}

    -- Players who have made a spawn choice get put into this list while waiting.
    -- An on_tick event checks when it expires and then places down the base resources, and teleports the player.
    -- Go look at DelayedSpawnOnTick() for more info.
    --[[@type OarcDelayedSpawnsTable]]
    storage.delayed_spawns = {}

    -- This stores the spawn choices that a player makes from the GUI interactions.
    -- Intended to be re-used for secondary spawns!
    --[[@type OarcSpawnChoicesTable]]
    storage.spawn_choices = {}

    --- Table contains all the renders that need to be faded out over time in the on_tick event. They are removed when they expire.
    --[[@type table<integer>]]
    storage.oarc_renders_fadeout = {}

    -- This is a queue of players that need to be teleported to their spawn point.
    --[[@type table<string, OarcNilCharacterTeleportQueueEntry>]]
    storage.nil_character_teleport_queue = {}

    -- Keep track of the landing pads for each surface, for each force so we don't have to keep using find_entities_filtered.
    --[[@type table<string, table<string, table<LuaEntity>>>]]
    storage.landing_pads = {}

    -- Special forces for when players with their own force want a reset.
    game.create_force(ABANDONED_FORCE_NAME)
    -- game.create_force(DESTROYED_FORCE_NAME)

    CreateHoldingPenPermissionsGroup()
end

function CreateHoldingPenPermissionsGroup()

    -- Create a permission group for the holding pen players.
    if (game.permissions.get_group("holding_pen") == nil) then
        game.permissions.create_group("holding_pen")
    end

    local holding_pen_group = game.permissions.get_group("holding_pen")

    -- Disable all permissions for the holding pen group.
    for _,action in pairs(defines.input_action) do
        holding_pen_group.set_allows_action(action, false)
    end

    -- Just allow the ones we want:
    holding_pen_group.set_allows_action(defines.input_action.gui_checked_state_changed, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_click, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_confirmed, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_elem_changed, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_hover, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_leave, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_location_changed, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_selected_tab_changed, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_switch_state_changed, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_text_changed, true)
    holding_pen_group.set_allows_action(defines.input_action.gui_value_changed, true)
    holding_pen_group.set_allows_action(defines.input_action.start_walking, true)
    holding_pen_group.set_allows_action(defines.input_action.write_to_console, true)

end

---Detects when new surfaces are created and inits them. Does not trigger during on_init?
---@param event EventData.on_surface_created
---@return nil
function SeparateSpawnsSurfaceCreated(event)
    local surface_name = game.surfaces[event.surface_index].name
    log("SeparateSpawnsSurfaceCreated - " .. surface_name)
    SeparateSpawnsInitSurface(surface_name)
end

---Init globals for a new surface and set the default allow spawn values.
---@param surface_name string
---@return nil
function SeparateSpawnsInitSurface(surface_name)
    -- Shouldn't happen because surface created isn't triggered during on_init.
    if (storage.oarc_surfaces == nil) then
        error("storage.oarc_surfaces not initialized yet?! " .. surface_name)
    end

    if IsSurfaceBlacklisted(surface_name) then return end

    if storage.oarc_surfaces[surface_name] == nil then
        -- Default surface is set to primary only. Every other planet allows secondary spawns, because each planet
        -- has its own starting point grid. Other surfaces (from other mods) have no grid, so they get neither.
        if (surface_name == storage.ocfg.gameplay.default_surface) then
            storage.oarc_surfaces[surface_name] = {
                primary = true,
                secondary = false
            }
        else
            storage.oarc_surfaces[surface_name] = {
                primary = false,
                secondary = (game.planets[surface_name] ~= nil)
            }
        end
    end

    -- Make sure it has a surface configuration entry!
    if (storage.ocfg.surfaces_config[surface_name] == nil) then
        log("Surface does NOT have a config entry, defaulting to nauvis entry for new surface: " .. surface_name)
        storage.ocfg.surfaces_config[surface_name] = table.deepcopy(storage.ocfg.surfaces_config["nauvis"])
        script.raise_event("oarc-classic-on-config-changed", {})
    end
end

---Init surface globals using game.planets
---@return nil
function SeparateSpawnsInitPlanets()
    for _, planet in pairs(game.planets) do
        SeparateSpawnsInitSurface(planet.name)
    end
end

---Detects when surfaces are deleted and removes them from the list of surfaces that allow spawns.
---@param event EventData.on_pre_surface_deleted
---@return nil
function SeparateSpawnsSurfaceDeleted(event)
    local surface_name = game.surfaces[event.surface_index].name

    -- Remove the surface from the list of surfaces that allow spawns
    if storage.oarc_surfaces[surface_name] ~= nil then
        log("WARNING!! - Surface deleted event not validated/implemented yet! " .. surface_name)
        storage.oarc_surfaces[surface_name] = nil
        -- TODO: Validate if we need to do other cleanup too, like unique spawns, etc. I can't
        -- think of a reason why we would need to do that yet.
    end
end

--[[
  ___  _       _ __   __ ___  ___     ___  ___  ___  ___  ___  ___  ___  ___
 | _ \| |     /_\\ \ / /| __|| _ \   / __|| _ \| __|/ __||_ _|| __||_ _|/ __|
 |  _/| |__  / _ \\ V / | _| |   /   \__ \|  _/| _|| (__  | | | _|  | || (__
 |_|  |____|/_/ \_\|_|  |___||_|_\   |___/|_|  |___|\___||___||_|  |___|\___|

--]]

-- When a player is newly created or just reset, present the spawn options to them.
-- New players wait on the lobby force until they have a spawn of their own.
---@param player_index integer|string
---@return nil
function SeparateSpawnsInitPlayer(player_index)
    local player = game.players[player_index]

    SafeTeleport(player, game.surfaces[HOLDING_PEN_SURFACE_NAME], { x = 0, y = 0 })

    player.force = LOBBY_FORCE_NAME

    if (not player.admin) then
        player.permission_group = game.permissions.get_group("holding_pen")
    end

    if (storage.player_respawns[player.name] == nil) then
        storage.player_respawns[player.name] = {}
    end
    if (storage.player_cooldowns[player.name] == nil) then
        storage.player_cooldowns[player.name] = { setRespawn = game.tick }
    end

    -- Reset GUI and show the spawn options.
    DisplayWelcomeTextGui(player)
    InitOarcGuiTabs(player)
    HideOarcGui(player)
    SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_TAB_NAME, false) -- Make sure spawn control tab is disabled
    SwitchOarcGuiTab(player, OARC_SERVER_INFO_TAB_NAME)
end

-- Check if the player has a different spawn point than the default one
-- Make sure to give the default starting items
---@param event EventData.on_player_respawned
---@return nil
function SeparateSpawnsPlayerRespawned(event)
    local player = game.players[event.player_index]
    local surface_name = player.character.surface.name

    -- It's possible if player is dead, and then resets, we don't want to do anything else.
    if (surface_name == HOLDING_PEN_SURFACE_NAME) then return end

    -- If the player was reset while dead, they have no home spawn, so send them to the holding pen instead.
    if (FindPlayerHomeSpawn(player.name) == nil) then
        SafeTeleport(player, game.surfaces[HOLDING_PEN_SURFACE_NAME], { x = 0, y = 0 })
        return
    end

    -- If they picked a new spawn while dead, OnTickNilCharacterTeleportQueue will send them there.
    if (storage.nil_character_teleport_queue[player.name] ~= nil) then return end

    -- If the mod isn't active on this surface, then ignore it.
    local surface_config = storage.oarc_surfaces[surface_name]
    if (surface_config == nil) or
        (not surface_config.primary and not surface_config.secondary) then
        return
    end

    TeleportPlayerToRespawnPoint(surface_name, player, false)
    GivePlayerRespawnItems(player)
end

---If the player leaves early, remove their base.
---@param event EventData.on_player_left_game
---@return nil
function SeparateSpawnsPlayerLeft(event)
    local player = game.players[event.player_index]

    -- If players leave early, say goodbye.
    if (player and (player.online_time < (storage.ocfg.gameplay.minimum_online_time * TICKS_PER_MINUTE))) then
        SendBroadcastMsg({ "oarc-player-left-early", player.name, storage.ocfg.gameplay.minimum_online_time })
        RemoveOrResetPlayer(player, true)
    end
end

---If the player moves surfaces, check if we need to present them with new a new spawn.
---@param player LuaPlayer
---@param previous_surface_name string?
---@param new_surface_name string
---@return nil
function SeparateSpawnsPlayerChangedSurface(player, previous_surface_name, new_surface_name)

    if (previous_surface_name == nil) then return end
    log("SeparateSpawnsPlayerChangedSurface from " .. previous_surface_name .. " to " .. new_surface_name)

    -- TODO make sure this isn't too spammy?
    local surface = game.surfaces[new_surface_name]
    local platform = surface.platform
    if (platform ~= nil) then
        SendBroadcastMsg({ "oarc-player-on-platform", player.name, surface.platform.index }, { color = player.color})
    else
        if (game.planets[new_surface_name] ~= nil) then
            SendBroadcastMsg({ "oarc-player-changed-surface", player.name, "[planet=" .. new_surface_name .. "]" }, { color = player.color, sound_path = "utility/new_objective"})
        else
            SendBroadcastMsg({ "oarc-player-changed-surface", player.name, surface.localised_name or { "space-location-name." .. surface.name } or surface.name}, { color = player.color})
        end
    end

    -- Check if player has been init'd yet. If not, then ignore it.
    if (storage.player_respawns[player.name] == nil) then return end

    -- If the mod isn't active on this surface, then ignore it.
    local surface_config = storage.oarc_surfaces[new_surface_name]
    if (surface_config == nil) or
        (not surface_config.primary and not surface_config.secondary) then
        return
    end

    -- If previous surface was a platform
    -- local arriving_from_space = StringStartsWith(previous_surface_name, "platform-")

    -- If we are NOT arriving from space, then ignore the rest of this??
    -- if (not arriving_from_space) then return end

    -- Check if there is already a landing pad for their force on the surface
    local landing_pad = surface.find_entities_filtered{name = "cargo-landing-pad", force = player.force, limit = 1}
    if (#landing_pad > 0) then
        -- If there's a landing pad for the force, I don't think we should interfere with the native behavior until
        -- there is an API that lets us do it properly. Otherwise I'm having to track landing pads per spawn...
        log("Player has a landing pad on this surface, let them land there?")
        return
    end

    local player_spawn = FindPlayerSpawnOnSurface(player.name, new_surface_name) -- Either they are host or joiner.

    -- If there IS a spawn for them on their new surface
    if (player_spawn ~= nil) then

        -- Then just send them to their respawn point which they should have.
        if (player_spawn.generated) then
            -- Unless they are riding a cargo pod already redirected to this spawn (OnCargoPodFinishedAscending), then
            -- let it land with them inside.
            local pod = player.cargo_pod
            if (pod ~= nil) and pod.valid then
                local destination = pod.cargo_pod_destination
                if (destination.position ~= nil) and
                    (destination.position.x == player_spawn.position.x) and
                    (destination.position.y == player_spawn.position.y) then
                    return
                end
            end

            TeleportPlayerToRespawnPoint(new_surface_name, player, false)
            return

        -- Unless they have to wait for it to be generated.
        else
            local delayed_spawn = FindDelayedSpawn(player.name, new_surface_name)
            if (delayed_spawn == nil) then
                error("FindPlayerSpawnOnSurface is ungenerated but FindDelayedSpawn returned nil? " .. player.name)
            end
            QueuePlayerForSpawn(player.name, delayed_spawn)
            return
        end
    end

    -- Check if secondary spawns are disabled
    if (not storage.oarc_surfaces[new_surface_name].secondary) then
        return
    end

    -- If there is no spawn for them on their new surface, generate one based on previous choices.
    SecondarySpawn(player, new_surface_name, true)
end

---Updates the player's surface and raises an event if it changes.
---@param player LuaPlayer
---@param new_surface_name string
---@return nil
function SeparateSpawnsUpdatePlayerSurface(player, new_surface_name)
    if (storage.player_surfaces == nil) then
        storage.player_surfaces = {}
    end

    local previous_surface_name = storage.player_surfaces[player.name]

    if (previous_surface_name ~= new_surface_name) then
        storage.player_surfaces[player.name] = new_surface_name

        -- Raise event if previous surface isn't nil (avoids first spawn event)
        if (previous_surface_name ~= nil) then
            script.raise_event("oarc-classic-character-surface-changed", {
                player_index=player.index,
                old_surface_name=previous_surface_name,
                new_surface_name=new_surface_name
            })
        end
    end
end

--[[
  ___  ___   _ __      __ _  _     ___  ___  _____  _   _  ___
 / __|| _ \ /_\\ \    / /| \| |   / __|| __||_   _|| | | || _ \
 \__ \|  _// _ \\ \/\/ / | .` |   \__ \| _|   | |  | |_| ||  _/
 |___/|_| /_/ \_\\_/\_/  |_|\_|   |___/|___|  |_|   \___/ |_|

--]]

---Generate liquid strip
---@param delayed_spawn OarcDelayedSpawn
---@param spawn_config OarcConfigSpawn
---@param surface LuaSurface
---@return nil
function GenerateStartingLiquidStrip(delayed_spawn, spawn_config, surface)

    local water_data = spawn_config.water
    -- Reference position is the top of the spawn area.
    local reference_pos = {
        x = delayed_spawn.position.x,
        y = delayed_spawn.position.y - (storage.ocfg.spawn_general.spawn_radius_tiles * spawn_config.radius_modifier)
    }
    CreateTileStrip(surface,
        { x = reference_pos.x + water_data.x_offset, y = reference_pos.y + water_data.y_offset },
        water_data.length,
        spawn_config.liquid_tile)
    CreateTileStrip(surface,
        { x = reference_pos.x + water_data.x_offset, y = reference_pos.y + water_data.y_offset + 1 },
        water_data.length,
        spawn_config.liquid_tile)

end


-- Generate the basic starter resource around a given location.
---@param surface LuaSurface
---@param position TilePosition --The center of the spawn area
---@return nil
function GenerateStartingResources(surface, position)

    --TODO: This should come from map gen settings instead:
    local size_mod = storage.ocfg.resource_placement.size_multiplier
    local amount_mod = storage.ocfg.resource_placement.amount_multiplier

    local spawn_general = storage.ocfg.spawn_general

    -- Generate all resource tile patches
    -- Generate resources in random order around the spawn point.
    if storage.ocfg.resource_placement.enabled then
        if (spawn_general.shape == SPAWN_SHAPE_CHOICE_CIRCLE) or (spawn_general.shape == SPAWN_SHAPE_CHOICE_OCTAGON) then
            PlaceResourcesInSemiCircle(surface, position, size_mod, amount_mod)
        elseif (spawn_general.shape == SPAWN_SHAPE_CHOICE_SQUARE) then
            PlaceResourcesInSquare(surface, position, size_mod, amount_mod)
        end

    -- Generate resources using specified offsets if auto placement is disabled.
    else
        for r_name, r_data in pairs(storage.ocfg.surfaces_config[surface.name].spawn_config.solid_resources) do
            local pos = { x = position.x + r_data.x_offset, y = position.y + r_data.y_offset }
            GenerateResourcePatch(surface, r_name, r_data.size * size_mod, pos, r_data.amount * amount_mod)
        end

        --TODO: Add support for specific location placement. OR remove it entirely.
        -- for g_name, g_data in pairs(storage.ocfg.surfaces_config[surface.name].spawn_config.gleba_resources) do
        --     local pos = { x = position.x + g_data.x_offset, y = position.y + g_data.y_offset }
        --     GenerateGlebaStyleResourcePatch(surface, g_data, g_data.size * size_mod, pos)
        -- end
    end

    local spawn_config = storage.ocfg.surfaces_config[surface.name].spawn_config
    local radius = spawn_general.spawn_radius_tiles * spawn_config.radius_modifier

    -- Generate special fluid resource patches (oil)
    -- Autoplace using spacing and vertical offset.
    -- Reference position is the bottom of the spawn area.
    if storage.ocfg.resource_placement.enabled then
        local y_offset = storage.ocfg.resource_placement.distance_to_edge
        local fluid_ref_pos = { x = position.x, y = position.y + radius - y_offset }

        local fluid_resources = storage.ocfg.surfaces_config[surface.name].spawn_config.fluid_resources
        if fluid_resources ~= nil then
            for r_name, r_data in pairs(fluid_resources) do

                local spacing = r_data.spacing
                local oil_patch_x = fluid_ref_pos.x - (((r_data.num_patches-1) * spacing) / 2)
                local oil_patch_y = fluid_ref_pos.y

                for i = 1, r_data.num_patches do
                    surface.create_entity({
                        name = r_name,
                        amount = r_data.amount,
                        position = { oil_patch_x, oil_patch_y }
                    })
                    oil_patch_x = oil_patch_x + spacing
                end

                fluid_ref_pos.y = fluid_ref_pos.y - spacing
            end
        end

    -- This places using specified offsets if auto placement is disabled.
    else
        local fluid_ref_pos = { x = position.x, y = position.y + radius }
        local fluid_resources = storage.ocfg.surfaces_config[surface.name].spawn_config.fluid_resources
        if fluid_resources ~= nil then
            for r_name, r_data in pairs(fluid_resources) do
                local oil_patch_x = fluid_ref_pos.x + r_data.x_offset_start
                local oil_patch_y = fluid_ref_pos.y + r_data.y_offset_start
                for i = 1, r_data.num_patches do
                    surface.create_entity({
                        name = r_name,
                        amount = r_data.amount,
                        position = { oil_patch_x, oil_patch_y }
                    })
                    oil_patch_x = oil_patch_x + r_data.x_offset_next
                    oil_patch_y = oil_patch_y + r_data.y_offset_next
                end
            end
        end
    end
end

---Get a list of resources from solid_resources and gleba_resources, will be randomly shuffled if 
---resource_placement.random_order is true.
---@param surface_name string
---@return table<string>
function GetResourceList(surface_name)

    local spawn_config = storage.ocfg.surfaces_config[surface_name].spawn_config

    -- Create list of solid resource tiles
    local r_list = {}
    local solid_resources = spawn_config.solid_resources
    if solid_resources ~= nil then
        for r_name, _ in pairs(solid_resources) do
            if (r_name ~= "") then
                table.insert(r_list, r_name)
            end
        end
    end

    -- Gleba style resources like plants that need to be placed on certain tiles
    local gleba_resources = spawn_config.gleba_resources
    if gleba_resources ~= nil then
        for g_name, _ in pairs(gleba_resources) do
            if (g_name ~= "") then
                table.insert(r_list, g_name)
            end
        end
    end

    ---@type table<string>
    local shuffled_list = r_list
    if storage.ocfg.resource_placement.random_order then
        shuffled_list = FYShuffle(r_list)
    end

    return shuffled_list
end

---Places starting resource deposits in a semi-circle around the spawn point.
---@param surface LuaSurface
---@param position TilePosition --The center of the spawn area
---@param size_mod number
---@param amount_mod number
---@return nil
function PlaceResourcesInSemiCircle(surface, position, size_mod, amount_mod)

    ---@type table<string>
    local shuffled_list = GetResourceList(surface.name)
    local num_resources = table_size(shuffled_list)

    -- This places resources in a semi-circle
    local surface_config = storage.ocfg.surfaces_config[surface.name]
    local angle_offset_radians = math.rad(storage.ocfg.resource_placement.angle_offset)
    local angle_final_radians = math.rad(storage.ocfg.resource_placement.angle_final)
    local radius = storage.ocfg.spawn_general.spawn_radius_tiles * surface_config.spawn_config.radius_modifier - storage.ocfg.resource_placement.distance_to_edge

    -- Special case for only one resource, place it in the middle of the semi-circle.
    if (num_resources == 1) then
        local r_name = shuffled_list[1]
        local angle = ((angle_final_radians - angle_offset_radians) / 2) + angle_offset_radians;

        local tx = (radius * math.cos(angle)) + position.x
        local ty = (radius * math.sin(angle)) + position.y

        local pos = { x = math.floor(tx), y = math.floor(ty) }

        local resourceConfig = surface_config.spawn_config.solid_resources[r_name]
        if (resourceConfig ~= nil) then
            GenerateResourcePatch(surface, r_name, resourceConfig.size * size_mod, pos, resourceConfig.amount * amount_mod)
        else
            local gResourceConfig = surface_config.spawn_config.gleba_resources[r_name]
            GenerateGlebaStyleResourcePatch(surface, gResourceConfig, gResourceConfig.size * size_mod, pos)
        end

    else
        local theta = ((angle_final_radians - angle_offset_radians) / (num_resources-1));
        local count = 0

        for _, r_name in pairs(shuffled_list) do
            local angle = (theta * count) + angle_offset_radians;

            local tx = (radius * math.cos(angle)) + position.x
            local ty = (radius * math.sin(angle)) + position.y

            local pos = { x = math.floor(tx), y = math.floor(ty) }

            local resourceConfig = surface_config.spawn_config.solid_resources[r_name]
            if (resourceConfig ~= nil) then
                GenerateResourcePatch(surface, r_name, resourceConfig.size * size_mod, pos, resourceConfig.amount * amount_mod)
            else
                local gResourceConfig = surface_config.spawn_config.gleba_resources[r_name]
                GenerateGlebaStyleResourcePatch(surface, gResourceConfig, gResourceConfig.size * size_mod, pos)
            end
            count = count + 1
        end
    end
end

---Places starting resource deposits in a line starting at the top left of the spawn point.
---@param surface LuaSurface
---@param position TilePosition --The center of the spawn area
---@param size_mod number
---@param amount_mod number
---@return nil
function PlaceResourcesInSquare(surface, position, size_mod, amount_mod)

    ---@type table<string>
    local shuffled_list = GetResourceList(surface.name)

    local spawn_general = storage.ocfg.spawn_general
    local spawn_config = storage.ocfg.surfaces_config[surface.name].spawn_config
    local radius = spawn_general.spawn_radius_tiles * spawn_config.radius_modifier

    -- Get the top left position of the spawn area
    local resource_position = { x = position.x - radius,
                                y = position.y - radius }

    -- Offset the starting position
    resource_position.x = resource_position.x + storage.ocfg.resource_placement.horizontal_offset
    resource_position.y = resource_position.y + storage.ocfg.resource_placement.vertical_offset

    -- Place vertically using linear spacing
    for _, r_name in pairs(shuffled_list) do

        if spawn_config.solid_resources[r_name] then
            local solid_resource = spawn_config.solid_resources[r_name]
            local size = solid_resource.size * size_mod
            GenerateResourcePatch(surface, r_name, size, resource_position, solid_resource.amount * amount_mod)
            resource_position.y = resource_position.y + size + storage.ocfg.resource_placement.linear_spacing
        elseif spawn_config.gleba_resources[r_name] then
            local gleba_resource = spawn_config.gleba_resources[r_name]
            local size = gleba_resource.size * size_mod
            GenerateGlebaStyleResourcePatch(surface, gleba_resource, size, resource_position)
            resource_position.y = resource_position.y + size + storage.ocfg.resource_placement.linear_spacing
        else
            error("Resource not found in solid_resources or gleba_resources: " .. r_name)
        end
    end
end

---Players can pick a prefab spawn, the OG Oarc style spawn circle (crop shape, moat, scripted resources) built on top
---of the starting point, if this is enabled. Otherwise every spawn uses the vanilla starting area as is.
---@return boolean
function IsOarcStyleSpawnAllowed()
    return storage.ocfg.gameplay.allow_oarc_style_spawn
end

---Places the final spawn elements after chunk generation is complete.
---@param delayed_spawn OarcDelayedSpawn
---@return nil
function GenerateFinalSpawnPieces(delayed_spawn)
    local ocfg --[[@as OarcConfig]] = storage.ocfg
    local spawn_config = ocfg.surfaces_config[delayed_spawn.surface_name].spawn_config

    local surface = game.surfaces[delayed_spawn.surface_name]

    if delayed_spawn.prefab then
        -- Generate water strip only if we don't have a moat.
        if (not delayed_spawn.moat or spawn_config.liquid_tile == "lava") then
            GenerateStartingLiquidStrip(delayed_spawn, spawn_config, surface)
        end

        -- Create the spawn resources here
        GenerateStartingResources(surface, delayed_spawn.position)

        -- Place randomized entities
        if (delayed_spawn.surface_name == "fulgora") then
            PlaceFulgoranLightningAttractors(surface, delayed_spawn.position, 10, game.players[delayed_spawn.host_name].force)
        end

        PlaceRandomEntities(surface, delayed_spawn.position)
    end

    -- Only primary spawns get a crashed ship.
    if delayed_spawn.primary then
        -- Create crash site if configured
        if (ocfg.surfaces_config[delayed_spawn.surface_name].starting_items.crashed_ship) then
            crash_site.create_crash_site(surface,
                { x = delayed_spawn.position.x + 15, y = delayed_spawn.position.y - 25 },
                ocfg.surfaces_config[delayed_spawn.surface_name].starting_items.crashed_ship_resources,
                ocfg.surfaces_config[delayed_spawn.surface_name].starting_items.crashed_ship_wreakage)

            -- Need to search for the crash site entities and make them match the player force!
            local radius = ocfg.spawn_general.spawn_radius_tiles * spawn_config.radius_modifier
            local wreckage = surface.find_entities_filtered{position = delayed_spawn.position, radius = radius, force = "player"}
            for _, wreck in pairs(wreckage) do
                wreck.force = game.players[delayed_spawn.host_name].force
            end
        end
    end

    game.players[delayed_spawn.host_name].force.set_spawn_position(delayed_spawn.position, surface)

    -- Render some welcoming text...
    DisplayWelcomeGroundTextAtSpawn(delayed_spawn.surface_name, delayed_spawn.position)

    -- Trigger the event that the spawn was created.
    script.raise_event("oarc-classic-on-spawn-created", {spawn_data = storage.unique_spawns[delayed_spawn.surface_name][delayed_spawn.host_name]})
end

---Sends the player to a NEW spawn point (primary OR secondary)
---@param player_name string
---@param surface_name string
---@param first_spawn boolean
---@param is_host boolean
---@return nil
function SendPlayerToNewSpawn(player_name, surface_name, first_spawn, is_host)

    local player = game.players[player_name]

    -- Check if player character is nil
    if (player.character == nil) then
        log("Player character is nil, can't send to spawn point just yet: " .. player_name)
        QueueNilCharacterForNewSpawnTeleport(player_name, surface_name, first_spawn, is_host)
        return
    end

    -- Send the player to that position
    TeleportPlayerToRespawnPoint(surface_name, player, first_spawn)

    -- Remove waiting dialog
    if (player.gui.screen.wait_for_spawn_dialog ~= nil) then
        player.gui.screen.wait_for_spawn_dialog.destroy()
    end

    -- Only first time spawns get starter items.
    if first_spawn then
        GivePlayerStarterItems(player)
    end

    -- Trigger the event that player was spawned too.
    script.raise_event("oarc-classic-on-player-spawned", {player_index = player.index, first_spawn = first_spawn, is_host = is_host})
end

---Displays some welcoming text at the spawn point on the ground. Fades out over time.
---@param surface LuaSurface|string
---@param position MapPosition
---@return nil
function DisplayWelcomeGroundTextAtSpawn(surface, position)
    -- Render some welcoming text...
    local tcolor = { 0.9, 0.7, 0.3, 0.8 }
    local ttl = 2000
    local render_object_1 = rendering.draw_text { text = {"oarc-spawn-ground-text-welcome"},
        surface = surface,
        target = { x = position.x - 21, y = position.y - 15 },
        color = tcolor,
        scale = 20,
        font = "compi",
        time_to_live = ttl,
        draw_on_ground = true,
        orientation = 0,
        -- alignment=center,
        scale_with_zoom = false,
        only_in_alt_mode = false }
    local render_object_2 = rendering.draw_text { text = {"oarc-spawn-ground-text-home"},
        surface = surface,
        target = { x = position.x - 14, y = position.y - 5 },
        color = tcolor,
        scale = 20,
        font = "compi",
        time_to_live = ttl,
        draw_on_ground = true,
        orientation = 0,
        -- alignment=center,
        scale_with_zoom = false,
        only_in_alt_mode = false }
    local rid1 = render_object_1.id
    local rid2 = render_object_2.id

    table.insert(storage.oarc_renders_fadeout, rid1)
    table.insert(storage.oarc_renders_fadeout, rid2)
end

--[[
   ___  _  _  _   _  _  _  _  __     ___  ___  _  _  ___  ___    _  _____  ___  ___   _  _
  / __|| || || | | || \| || |/ /    / __|| __|| \| || __|| _ \  /_\|_   _||_ _|/ _ \ | \| |
 | (__ | __ || |_| || .` || ' <    | (_ || _| | .` || _| |   / / _ \ | |   | || (_) || .` |
  \___||_||_| \___/ |_|\_||_|\_\    \___||___||_|\_||___||_|_\/_/ \_\|_|  |___|\___/ |_|\_|

--]]

---Clear the spawn areas. This should be run inside the chunk generate event and be given a list of all
---unique spawn points. This clears enemies in the immediate area, creates a slightly safe area around it,
---Resources are generated at a delayed time when the player is moved to the spawn point! It only works off of
---the closest spawn point!!
---@param surface LuaSurface
---@param chunk_area BoundingBox
---@return nil
function SetupAndClearSpawnAreas(surface, chunk_area)

    local closest_spawn = GetClosestUniqueSpawn(surface.name, chunk_area.left_top)
    if (closest_spawn == nil) then return end

    -- Natural spawns leave the vanilla starting area alone.
    if (not closest_spawn.prefab) then return end

    --[[@type OarcConfigSpawnGeneral]]
    local general_spawn_config = storage.ocfg.spawn_general
    local surface_spawn_config = storage.ocfg.surfaces_config[surface.name].spawn_config
    local radius = general_spawn_config.spawn_radius_tiles * surface_spawn_config.radius_modifier

    local chunk_area_center = {
        x = chunk_area.left_top.x + (CHUNK_SIZE / 2),
        y = chunk_area.left_top.y + (CHUNK_SIZE / 2)
    }

    -- If the chunk is within the main land area, then clear trees/resources and create the land spawn areas
    -- (guaranteed land with a circle of trees)
    local land_area = GetAreaAroundPos(closest_spawn.position, radius + CHUNK_SIZE)
    if not CheckIfInArea(chunk_area_center, land_area) then return end

    -- Remove decoratives
    if (general_spawn_config.remove_decoratives) then
        surface.destroy_decoratives {area = chunk_area}
    end

    -- Remove trees/resources inside the spawn area
    if (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_CIRCLE) or (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_OCTAGON) then
        RemoveInCircle(surface, chunk_area, {"resource", "cliff", "tree", "plant", "lightning-attractor", "simple-entity"}, closest_spawn.position, radius + 5)
    elseif (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_SQUARE) then
        RemoveInSquare(surface, chunk_area, {"resource", "cliff", "tree", "plant", "lightning-attractor", "simple-entity"}, closest_spawn.position, radius + 5)
    end

    if (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_CIRCLE) then
        CreateCropCircle(surface, closest_spawn, chunk_area)
    elseif (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_OCTAGON) then
        CreateCropOctagon(surface, closest_spawn, chunk_area)
    elseif (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_SQUARE) then
        CreateCropSquare(surface, closest_spawn, chunk_area)
    end

    script.raise_event("oarc-classic-on-chunk-generated-near-spawn", {surface = surface, chunk_area = chunk_area, spawn_data = closest_spawn})
end

---This is the main function that creates the spawn area. Provides resources, land and a safe zone.
---@param event EventData.on_chunk_generated
---@return nil
function SeparateSpawnsGenerateChunk(event)
    local surface = event.surface
    local chunkArea = event.area

    -- This handles chunk generation near player spawns
    -- If it is near a player spawn, it provide a guaranteed area of land and water tiles.
    SetupAndClearSpawnAreas(surface, chunkArea)

    AssignLightningAttractorsToClosestSpawn(surface, chunkArea)
end

---Map gen places lightning attractors (Fulgora ruins) on the player force, so nobody can deconstruct them. This gives
---them to the force of the closest spawn instead. They stay on the player force while no spawn exists on the surface.
---@param surface LuaSurface
---@param chunk_area BoundingBox
---@return nil
function AssignLightningAttractorsToClosestSpawn(surface, chunk_area)
    local attractors = surface.find_entities_filtered { area = chunk_area, type = "lightning-attractor", force = "player" }
    if (#attractors == 0) then return end

    local chunk_area_center = {
        x = chunk_area.left_top.x + (CHUNK_SIZE / 2),
        y = chunk_area.left_top.y + (CHUNK_SIZE / 2)
    }
    local closest_spawn = GetClosestUniqueSpawn(surface.name, chunk_area_center)
    if (closest_spawn == nil) then return end

    local host = game.players[closest_spawn.host_name]
    if (host == nil) then return end

    for _, attractor in pairs(attractors) do
        attractor.force = host.force
    end
end

--[[
   ___  _     ___    _    _  _  _   _  ___
  / __|| |   | __|  /_\  | \| || | | || _ \
 | (__ | |__ | _|  / _ \ | .` || |_| ||  _/
  \___||____||___|/_/ \_\|_|\_| \___/ |_|

--]]

---Call this if a player leaves the game early (or a player wants an early game reset)
---@param player LuaPlayer
---@param remove_player boolean Deletes player from the game assuming they are offline.
function RemoveOrResetPlayer(player, remove_player)
    if (not player) then
        log("ERROR - CleanupPlayer on NIL Player!")
        return
    end

    -- If playtime is less than minimum online time, try to remove starter items
    if (player.online_time < (storage.ocfg.gameplay.minimum_online_time * TICKS_PER_MINUTE)) then
        RemovePlayerStarterItems(player)
    end

    -- If this player is staying in the game, lets make sure we don't delete them along with the map chunks being
    -- cleared.
    SafeTeleport(player, game.surfaces[HOLDING_PEN_SURFACE_NAME], {x=0,y=0})
    local player_old_force = player.force
    player.force = LOBBY_FORCE_NAME
    local player_name = player.name

    -- Clear globals and transfers spawn ownership if needed.
    CleanupPlayerGlobals(player_name) -- This cleans storage.unique_spawns IF we are transferring ownership.

    -- Safely clear all spawns if they are the host.
    local spawns = FindAllUniqueSpawnsWherePlayerIsTheHost(player_name)
    for _,spawn in pairs(spawns) do
        UniqueSpawnCleanupRemove(player_name, spawn)
    end

    -- Remove a force if this player created it and they are the only one on it
    if ((#player_old_force.players == 0) and (player_old_force.name ~= LOBBY_FORCE_NAME)) then
        log("RemoveOrResetPlayer - FORCE REMOVED: " .. player_old_force.name)
        game.merge_forces(player_old_force, "neutral")
    end

    -- Trigger the event that the player was reset.
    script.raise_event("oarc-classic-on-player-reset", {player_index = player.index})

    -- Remove the character completely
    if (remove_player and not player.connected) then
        game.remove_offline_players({ player }) -- SOMEHOW RELATED TO THE DESYNCS? (This plus cheat command for other planets.)

    -- Otherwise, make sure to re-init them!
    else
        if (remove_player) then
            log("ERROR! RemoveOrResetPlayer - Player not removed as they are still connected: " .. player_name)
        end
        SeparateSpawnsInitPlayer(player.index --[[@as string]])
        SendBroadcastMsg({"oarc-player-was-reset-notify", player_name})
    end

    -- Refresh the shared spawn spawn gui for all players
    for _,p in pairs(game.connected_players) do
        RefreshSharedSpawnFrameIfExist(p)
    end
end

---Searches all unique spawns for the primary one for a player. This will return null if they joined someeone else's spawn.
---@param player_name string
---@return OarcUniqueSpawn?
function FindPrimaryUniqueSpawn(player_name)
    for _,spawns in pairs(storage.unique_spawns) do
        if (spawns[player_name] ~= nil and spawns[player_name].primary) then
            return spawns[player_name]
        end
    end
    return nil
end

---Returns all spawns (primary and secondary) where this player is the host
---@param player_name string
---@return OarcUniqueSpawn[]
function FindAllUniqueSpawnsWherePlayerIsTheHost(player_name)
    local found_spawns = {}
    for _,spawns in pairs(storage.unique_spawns) do
        for _, spawn in pairs(spawns) do
            if (spawn.host_name == player_name) then
                table.insert(found_spawns, spawn)
            end
        end
    end
    return found_spawns
end

---Find the primary home spawn of a player, if one exists. This will return a shared spawn if they joined one.
---@param player_name string
---@return OarcUniqueSpawn?
function FindPlayerHomeSpawn(player_name)
    for _,spawns in pairs(storage.unique_spawns) do
        for _,spawn in pairs(spawns) do
            if (spawn.primary) and ((spawn.host_name == player_name) or TableContains(spawn.joiners, player_name)) then
                return spawn
            end
        end
    end
end

---Get the spawn choices from whoever is the host of the spawn the player joined, even if they are the host.
---@param player_name string
---@return OarcSpawnChoices?
function GetPrimarySpawnChoices(player_name)
    local primary_spawn = FindPlayerHomeSpawn(player_name)
    if (primary_spawn == nil) then return nil end
    return storage.spawn_choices[primary_spawn.host_name]
end

---Find the spawn of a player, if one exists, on a specific surface.
---@param player_name string
---@param surface_name string
---@return OarcUniqueSpawn?
function FindPlayerSpawnOnSurface(player_name, surface_name)
    if (storage.unique_spawns[surface_name] == nil) then return nil end
    for _,spawn in pairs(storage.unique_spawns[surface_name]) do
        if ((spawn.host_name == player_name) or TableContains(spawn.joiners, player_name)) then
            return spawn
        end
    end
end

---Searches all unique spawns for a list of secondary ones for a player.
---@param player_name string
---@return table<string, OarcUniqueSpawn> -- Indexed by surface name!
function FindSecondaryUniqueSpawns(player_name)
    local secondary_spawns = {}
    for surface_index, spawns in pairs(storage.unique_spawns) do
        if (spawns[player_name] ~= nil and not spawns[player_name].primary) then
            secondary_spawns[surface_index] = spawns[player_name]
        end
    end
    return secondary_spawns
end

---Searches through the delayed spawns to see if there is one for this player.
---@param player_name string
---@param surface_name string
---@return OarcDelayedSpawn?
function FindDelayedSpawn(player_name, surface_name)
    for _,delayed_spawn in pairs(storage.delayed_spawns) do
        if (delayed_spawn.surface_name == surface_name) then
            if (delayed_spawn.host_name == player_name) or (TableContains(delayed_spawn.joiners, player_name)) then
                return delayed_spawn
            end
        end
    end
end

---Cleans up a player's unique spawn point, if safe to do so.
---@param player_name string
---@param unique_spawn OarcUniqueSpawn?
---@return nil
function UniqueSpawnCleanupRemove(player_name, unique_spawn)

    if (unique_spawn == nil) then return end -- Safety
    log("UniqueSpawnCleanupRemove - " .. player_name .. " on surface: " .. unique_spawn.surface_name)

    -- Use regrowth mod to cleanup the area. Grid spacing keeps every other spawn well outside the cleared area.
    local spawn_position = unique_spawn.position
    if (storage.ocfg.regrowth.enable_abandoned_base_cleanup) then
        log("Removing base: " .. spawn_position.x .. "," .. spawn_position.y .. " on surface: " .. unique_spawn.surface_name)

        RegrowthMarkAreaForRemoval(unique_spawn.surface_name, spawn_position, GetSpawnCleanupChunkRadius(unique_spawn))
        TriggerCleanup()
        -- Trigger event
        script.raise_event("oarc-classic-on-spawn-remove-request", {spawn_data = unique_spawn})
    end

    -- Remove the spawn point from the global table.
    storage.unique_spawns[unique_spawn.surface_name][player_name] = nil

    ReleaseStartingPoint(unique_spawn.surface_name, spawn_position)
end

---Cleans up all references to a player in the global tables.
---@param player_name string
---@return nil
function CleanupPlayerGlobals(player_name)

    -- Transfer or remove a shared spawn if player is owner
    local unique_spawn = FindPrimaryUniqueSpawn(player_name)
    if (unique_spawn ~= nil and #unique_spawn.joiners > 0) then
        local new_owner_name = table.remove(unique_spawn.joiners) -- Get 1 to use as new owner.
        TransferOwnershipOfAllSpawns(unique_spawn, new_owner_name)
        SendBroadcastMsg( {"oarc-host-left-new-host", player_name, new_owner_name})
    end

    -- Check all other shared spawns too in case they joined one.
    for surface_index, spawns in pairs(storage.unique_spawns) do
        for player_index, spawn in pairs(spawns) do
            for index, joiner in pairs(spawn.joiners) do
                if (player_name == joiner) then
                    storage.unique_spawns[surface_index][player_index].joiners[index] = nil
                end
            end
        end
    end

    -- Clear their personal spawn point info
    if (storage.player_respawns[player_name] ~= nil) then
        storage.player_respawns[player_name] = nil
    end

    -- Remove them from the delayed spawn queue if they are still the host
    for index, delayedSpawn in pairs(storage.delayed_spawns --[[@as OarcDelayedSpawnsTable]]) do
        if (player_name == delayedSpawn.host_name) then
            storage.delayed_spawns[index] = nil
            log("Removing player from delayed spawn queue: " .. player_name)
            break
        end
    end

    -- Remove them from any join queues they may be in:
    RemovePlayerFromJoinQueue(player_name)

    if (storage.player_cooldowns[player_name] ~= nil) then
        storage.player_cooldowns[player_name] = nil
    end
end

---Transfers ownership of a shared spawn to another player.
---@param primary_spawn OarcUniqueSpawn
---@param new_host_name string
---@return nil
function TransferOwnershipOfAllSpawns(primary_spawn, new_host_name)

    TransferStartingPointClaims(primary_spawn.host_name, new_host_name)

    -- Transfer every primary AND secondary spawn.
    for surface_name, unique_spawns in pairs(storage.unique_spawns) do
        for host_name, unique_spawn in pairs(unique_spawns) do
            if (host_name == primary_spawn.host_name) then

                -- Create a new unique for the new owner based on the old one.
                storage.unique_spawns[surface_name][new_host_name] = table.deepcopy(unique_spawn)
                -- local new_spawn = table.deepcopy(unique_spawn)
                storage.unique_spawns[surface_name][new_host_name].host_name = new_host_name
                storage.unique_spawns[surface_name][new_host_name].joiners = table.deepcopy(primary_spawn.joiners) -- Copy the old joiner list, with the new host already removed.

                -- Remove the old spawn
                storage.unique_spawns[surface_name][host_name] = nil
            end
        end
    end

    -- Transfer any delayed_spawns
    for index, delayed_spawn in pairs(storage.delayed_spawns) do
        if (delayed_spawn.host_name == primary_spawn.host_name) then
            storage.delayed_spawns[index].host_name = new_host_name
        end
    end

    CompatSend(game.players[new_host_name], { "oarc-new-owner-msg" })
end

--[[
  _  _  ___  _     ___  ___  ___     ___  _____  _   _  ___  ___
 | || || __|| |   | _ \| __|| _ \   / __||_   _|| | | || __|| __|
 | __ || _| | |__ |  _/| _| |   /   \__ \  | |  | |_| || _| | _|
 |_||_||___||____||_|  |___||_|_\   |___/  |_|   \___/ |_|  |_|

--]]

---Queue a player whose character is nil when being sent to a new spawn.
---A separate on_tick function will read this queue and send the player to the spawn point when they have a character again.
---@param player_name string
---@param surface_name string
---@param first_spawn boolean
---@param is_host boolean
---@return nil
function QueueNilCharacterForNewSpawnTeleport(player_name, surface_name, first_spawn, is_host)
    if (storage.nil_character_teleport_queue[player_name] == nil) then
        storage.nil_character_teleport_queue[player_name] = { surface_name = surface_name, first_spawn = first_spawn, is_host = is_host }
    end
end

---On tick function to process the nil character teleport queue.
---@return nil
function OnTickNilCharacterTeleportQueue()
    for player_name, data in pairs(storage.nil_character_teleport_queue) do
        local player = game.players[player_name]

        -- If player is nil, remove them from the queue.
        if (player == nil) then
            storage.nil_character_teleport_queue[player_name] = nil

        -- Else if they have a character, send them to the spawn point.
        -- And hope to high heaven this doesn't recurse infinitely.
        elseif (player.character ~= nil) then
            storage.nil_character_teleport_queue[player_name] = nil
            SendPlayerToNewSpawn(player_name, data.surface_name, data.first_spawn, data.is_host)
        end
    end
end

---Finds and removes a player from a shared spawn join queue, and refreshes the host's GUI.
---@param player_name string
---@return boolean
function RemovePlayerFromJoinQueue(player_name)

    for surface_index, spawns in pairs(storage.unique_spawns) do
        for player_index, spawn in pairs(spawns) do
            for index, requestor in pairs(spawn.join_queue) do
                if (requestor == player_name) then
                    storage.unique_spawns[surface_index][player_index].join_queue[index] = nil

                    local host_player = game.players[player_index]
                    if (host_player ~= nil) and (host_player.connected) then
                        OarcGuiRefreshContent(host_player)
                    end

                    return true
                end
            end
        end
    end

    return false
end

---Same as GetClosestPosFromTable but specific to storage.unique_spawns
---@param surface_name string
---@param pos MapPosition
---@return OarcUniqueSpawn?
function GetClosestUniqueSpawn(surface_name, pos)

    local surface_spawns = storage.unique_spawns[surface_name]
    if (surface_spawns == nil) then return nil end -- EXIT - No spawns on requested surface
    if (table_size(surface_spawns) == 0) then return nil end -- EXIT - No spawns on requested surface

    local closest_dist = nil
    local closest_spawn = nil

    for _,spawn in pairs(surface_spawns) do
        local new_dist = util.distance(pos, spawn.position)
        if (closest_dist == nil) then
            closest_dist = new_dist
            closest_spawn = spawn
        elseif (closest_dist > new_dist) then
            closest_dist = new_dist
            closest_spawn = spawn
        end
    end

    return closest_spawn
end

---Get the spawns from a particular force on a specific surface.
---@param force LuaForce
---@param surface_name string
---@return OarcUniqueSpawn[]
function FindUniqueSpawnByForceForSurface(force, surface_name)
    local force_spawns = {}
    
    if (storage.unique_spawns[surface_name] == nil) then return force_spawns end

    for _,spawn in pairs(storage.unique_spawns[surface_name]) do
        if (game.players[spawn.host_name].force == force) then
            table.insert(force_spawns, spawn)
        end
    end
    return force_spawns
end

---Find the primary spawn for a force (on any surface). Returns the first one found.
---@param force LuaForce
---@return OarcUniqueSpawn?
function FindPrimarySpawnForForce(force)
    for _,spawns in pairs(storage.unique_spawns) do
        for _,spawn in pairs(spawns) do
            if (spawn.primary) and (game.players[spawn.host_name].force == force) then
                return spawn
            end
        end
    end
    return nil
end

---Checks if a force already has at least one landing pad on a surface.
---@param force LuaForce
---@param surface LuaSurface
---@return boolean
function DoesForceHaveLandingPadOnSurface(force, surface)

    -- Init the landing pad storage if it doesn't exist.
    if storage.landing_pads == nil then
        storage.landing_pads = { [surface.name] = { [force.name] = {} } }
    elseif storage.landing_pads[surface.name] == nil then
        storage.landing_pads[surface.name] = { [force.name] = {} }
    elseif storage.landing_pads[surface.name][force.name] == nil then
        storage.landing_pads[surface.name][force.name] = surface.find_entities_filtered{ name = "cargo-landing-pad", force = force }
    end

    -- Check if any of the landing pads are still valid.
    for index, landing_pad in pairs(storage.landing_pads[surface.name][force.name]) do
        if (landing_pad.valid) then
            return true
        else
            storage.landing_pads[surface.name][force.name][index] = nil
        end
    end

    -- If we got here, we need to re-find the landing pads.
    local landing_pads = surface.find_entities_filtered{ name = "cargo-landing-pad", force = force }
    storage.landing_pads[surface.name][force.name] = landing_pads
    return (#landing_pads > 0)
end

---Find all players that belong to the same PRIMARY shared spawn as this player, including buddies!
---@param player_name string
---@param include_offline boolean
---@return string[]
function GetPlayersFromSameSpawn(player_name, include_offline)
    local shared_players = {}

    for _, spawns in pairs(storage.unique_spawns) do
        for _,spawn in pairs(spawns) do
            if (not spawn.primary) then goto CONTINUE end

            -- Is the player either the host OR a joiner?
            if (spawn.host_name == player_name) or TableContains(spawn.joiners, player_name) then

                if (include_offline or game.players[spawn.host_name].connected) then
                    table.insert(shared_players, spawn.host_name)
                end

                for _,joiner in pairs(spawn.joiners) do
                    if (include_offline or game.players[joiner].connected) then
                        table.insert(shared_players, joiner)
                    end
                end

                return shared_players -- We only need to find one match.
            end

            :: CONTINUE ::
        end
    end

    return shared_players
end



---Returns the number of players currently online at the shared spawn including the host.
---@param surface_name string
---@param owner_name string
---@return number
function GetOnlinePlayersAtSharedSpawn(surface_name, owner_name)
    local spawn = storage.unique_spawns[surface_name][owner_name]

    if spawn == nil then return 0 end

    -- Does not count base owner
    local count = 0

    -- For each player in the shared spawn, check if online and add to count.
    for _,joiner in pairs(spawn.joiners) do
        if game.players[joiner].connected then
            count = count + 1
        end
    end

    -- Add the host player to the count
    if game.players[owner_name].connected then
        count = count + 1
    end

    return count
end

-- -- Get the number of currently available shared spawns.
-- -- This means the base owner has enabled access AND the number of online players
-- -- is below the threshold.
-- ---@return number
-- function GetNumberOfAvailableSharedSpawns()
--     return #GetAvailableSharedSpawns()
-- end

---This is used to provide both a list of spawns and a list of hosts for easy display in the GUI.
---@alias AvailableSpawnsTable { hosts: string[], spawns : OarcUniqueSpawn[] }

---Get a list of available shared spawns.
---@return AvailableSpawnsTable
function GetAvailableSharedSpawns()
    local available_spawns = { hosts = {}, spawns = {} }

    for surface_index, spawns in pairs(storage.unique_spawns) do
        for owner_name, spawn in pairs(spawns) do
            if IsSharedSpawnOpen(surface_index, owner_name) and not IsSharedSpawnFull(surface_index, owner_name) then
                table.insert(available_spawns.hosts, owner_name)
                table.insert(available_spawns.spawns, spawn)
            end
        end
    end

    return available_spawns
end

---Check if a specific shared spawn is valid, open and host is online (might still be full!)
---@param surface_name string
---@param owner_name string
---@return boolean
function IsSharedSpawnOpen(surface_name, owner_name)
    if (storage.unique_spawns[surface_name] == nil) or (storage.unique_spawns[surface_name][owner_name] == nil) then
        return false
    end

    local spawn = storage.unique_spawns[surface_name][owner_name]

    if (not spawn.open_access) then
        return false
    end

    -- Currently don't support directly joining secondary spawns!
    if (not spawn.primary) then
        return false
    end

    if (game.players[owner_name] == nil) or not (game.players[owner_name].connected) then
        return false
    end

    return true
end

---Check if a specific shared spawn is full.
---@param surface_name string
---@param owner_name string
---@return boolean --True if the shared spawn is full or invalid.
function IsSharedSpawnFull(surface_name, owner_name)
    if (storage.unique_spawns[surface_name][owner_name] == nil) then return true end

    -- Technically I only limit the players based on if they are online, so you can exceed the limit if players join
    -- while others are offline. This is a feature, not a bug?
    return (GetOnlinePlayersAtSharedSpawn(surface_name, owner_name) >= storage.ocfg.gameplay.number_of_players_per_shared_spawn)
end

---Creates a new spawn, this triggers the chunk generation and will provide an event when done.
---@param host_name string
---@param surface_name string -- Might be different from spawn_choices if it is a secondary spawn.
---@param spawn_position MapPosition
---@param spawn_choices OarcSpawnChoices
---@param primary boolean
---@return OarcDelayedSpawn
function GenerateNewSpawn(host_name, surface_name, spawn_position, spawn_choices, primary)

    local unique_spawn = nil
    if primary then
        unique_spawn = InitPrimarySpawnGlobals(host_name, spawn_position, spawn_choices)
    else
        local primary_spawn = FindPrimaryUniqueSpawn(host_name)
        if (primary_spawn == nil) then
            error("ERROR - GenerateNewSpawn - No primary spawn found for: " .. host_name)
        end
        unique_spawn = InitSecondarySpawnGlobals(primary_spawn, surface_name, spawn_position)
    end

    return QueueNewSpawnGeneration(unique_spawn)
end

---Queues a player who is waiting on their spawn to be generated.
---@param player_name string
---@param delayed_spawn OarcDelayedSpawn
---@return nil
function QueuePlayerForSpawn(player_name, delayed_spawn)

    -- Send them to the holding pen if they are not already there.
    local player = game.players[player_name]
    if (player.character == nil) or (player.character.surface.name ~= HOLDING_PEN_SURFACE_NAME) then
        SafeTeleport(player, game.surfaces[HOLDING_PEN_SURFACE_NAME], {x=0,y=0})
    end

    SetPlayerRespawn(player_name, delayed_spawn.surface_name, delayed_spawn.position, true, true)

    CompatSend(game.players[player_name], { "oarc-generating-spawn-please-wait" }, { volume_modifier = 0})

    local ticks_remaining = delayed_spawn.delayed_tick - game.tick
    local seconds_remaining = math.ceil(ticks_remaining / TICKS_PER_SECOND)

    HideOarcGui(game.players[player_name])
    DisplayPleaseWaitForSpawnDialog(game.players[player_name], seconds_remaining, game.surfaces[delayed_spawn.surface_name], delayed_spawn.position)

    table.insert(delayed_spawn.waiting_players, player_name)
    log("QueuePlayerForSpawn - Player:" .. player_name .. " - Host:" .. delayed_spawn.host_name)
end

---Sets the custom spawn point for a player. They can have one per surface.
---@param player_name string
---@param surface_name string
---@param position MapPosition
---@param reset_cooldown boolean
---@param use_offset boolean
---@return nil
function SetPlayerRespawn(player_name, surface_name, position, reset_cooldown, use_offset)
    ---@type OarcPlayerSpawn
    local updatedPlayerSpawn = {}
    updatedPlayerSpawn.surface = surface_name
    updatedPlayerSpawn.position = position

    -- Allow modders to set a custom offset for the player spawn point.
    local offset = storage.ocfg.surfaces_config[surface_name].spawn_config.player_spawn_offset
    if use_offset and (offset ~= nil) then
        updatedPlayerSpawn.position = { x = position.x + offset.x, y = position.y + offset.y }
    end

    storage.player_respawns[player_name][surface_name] = updatedPlayerSpawn


    if (storage.player_cooldowns[player_name].setRespawn == nil) or reset_cooldown then
        storage.player_cooldowns[player_name].setRespawn = game.tick
    end
end

---Creates the storage.unique_spawns entries for a new PRIMARY spawn area.
---@param host_name string
---@param spawn_position MapPosition
---@param spawn_choices OarcSpawnChoices
---@return OarcUniqueSpawn
function InitPrimarySpawnGlobals(host_name, spawn_position, spawn_choices)

    ---@type OarcUniqueSpawn
    local new_unique_spawn = {
        surface_name = spawn_choices.surface_name,
        position = spawn_position,
        -- Re-check the setting, in case it was disabled while the spawn menu was open. Only prefab spawns have a moat.
        prefab = spawn_choices.prefab and IsOarcStyleSpawnAllowed(),
        moat = spawn_choices.moat and spawn_choices.prefab and IsOarcStyleSpawnAllowed(),
        primary = true,
        host_name = host_name,
        joiners = {},
        join_queue = {},
        open_access = false,
        generated = false
    }

    if storage.unique_spawns[spawn_choices.surface_name] == nil then
        storage.unique_spawns[spawn_choices.surface_name] = {}
    end

    storage.unique_spawns[spawn_choices.surface_name][host_name] = new_unique_spawn

    return new_unique_spawn
end

---Creates the storage.unique_spawns entries for a new SECONDARY spawn area.
---@param unique_spawn OarcUniqueSpawn
---@param surface_name string
---@param spawn_position MapPosition
---@return OarcUniqueSpawn
function InitSecondarySpawnGlobals(unique_spawn, surface_name, spawn_position)

    local new_unique_spawn = table.deepcopy(unique_spawn)
    new_unique_spawn.surface_name = surface_name
    new_unique_spawn.position = spawn_position
    new_unique_spawn.primary = false
    new_unique_spawn.generated = false

    -- Same style as the primary spawn, unless Oarc style spawns were disabled since then.
    new_unique_spawn.prefab = unique_spawn.prefab and IsOarcStyleSpawnAllowed()
    new_unique_spawn.moat = unique_spawn.moat and new_unique_spawn.prefab

    if storage.unique_spawns[surface_name] == nil then
        storage.unique_spawns[surface_name] = {}
    end

    storage.unique_spawns[surface_name][unique_spawn.host_name] = new_unique_spawn

    return new_unique_spawn
end

---Gets the radius in chunks that a spawn area covers, including the moat and a 1 chunk buffer.
---@param surface_name string
---@return integer
function GetSpawnChunkRadius(surface_name)
    local spawn_config = storage.ocfg.surfaces_config[surface_name].spawn_config
    local radius = storage.ocfg.spawn_general.spawn_radius_tiles * spawn_config.radius_modifier

    local total_spawn_width = radius + storage.ocfg.spawn_general.moat_width_tiles
    return math.ceil(total_spawn_width / CHUNK_SIZE) + 1 -- Add a 1 chunk buffer to be safe
end

---Gets the radius in chunks that is deleted when a spawn is cleaned up. It always covers the starting point's explored
---area, and also the whole prefab spawn when it is bigger than that.
---@param unique_spawn OarcUniqueSpawn
---@return integer
function GetSpawnCleanupChunkRadius(unique_spawn)
    if unique_spawn.prefab then
        return math.max(STARTING_POINT_CLEANUP_CHUNK_RADIUS, GetSpawnChunkRadius(unique_spawn.surface_name))
    end
    return STARTING_POINT_CLEANUP_CHUNK_RADIUS
end

---Resets the enemy evolution on a surface to 0, including the pollution, time and spawner kill parts of it.
---This affects everyone on that surface.
---@param surface_name string
---@return nil
function ResetEnemyEvolution(surface_name)
    local enemy = game.forces["enemy"]
    enemy.set_evolution_factor(0, surface_name)
    enemy.set_evolution_factor_by_pollution(0, surface_name)
    enemy.set_evolution_factor_by_time(0, surface_name)
    enemy.set_evolution_factor_by_killing_spawners(0, surface_name)

    log("ResetEnemyEvolution - Reset enemy evolution on surface: " .. surface_name)
    SendBroadcastMsg({ "oarc-evolution-reset-new-spawn", surface_name })
end

---Starts the generation of a new unique spawn. This will generate an event when done.
---@param unique_spawn OarcUniqueSpawn
---@return OarcDelayedSpawn
function QueueNewSpawnGeneration(unique_spawn)

    -- Every new spawn passes through here right after its point is claimed, before any chunks are generated.
    if (storage.ocfg.gameplay.reset_evolution_on_new_spawn) then
        ResetEnemyEvolution(unique_spawn.surface_name)
    end

    local spawn_chunk_radius = GetSpawnChunkRadius(unique_spawn.surface_name)

    -- This is just a rough estimate of worst case chunk generation time.
    -- If we hit this timeout, usually it means something has gone wrong.
    local delay_spawn_seconds = 5 * spawn_chunk_radius

    -- Trigger the chunk generation
    game.surfaces[unique_spawn.surface_name].request_to_generate_chunks(unique_spawn.position, spawn_chunk_radius)

    local final_chunk = GetChunkPosFromTilePos(unique_spawn.position)
    final_chunk.x = final_chunk.x + spawn_chunk_radius
    final_chunk.y = final_chunk.y + spawn_chunk_radius

    ---@type OarcDelayedSpawn
    local delayed_spawn =  {

        -- I do this explicitly so that I get the LUA warnings if I miss a field!
        -- I know I could use table.deepcopy, but this is INTENTIONAL! 
        surface_name = unique_spawn.surface_name,
        position = unique_spawn.position,
        prefab = unique_spawn.prefab,
        moat = unique_spawn.moat,
        primary = unique_spawn.primary,
        host_name = unique_spawn.host_name,
        joiners = unique_spawn.joiners,
        join_queue = unique_spawn.join_queue,
        open_access = unique_spawn.open_access,

        -- This is the extra data I need for the delayed spawn
        delayed_tick = game.tick + delay_spawn_seconds * TICKS_PER_SECOND,
        final_chunk_generated = final_chunk,
        waiting_players = {}
    }

    table.insert(storage.delayed_spawns, delayed_spawn)

    RegrowthMarkAreaSafeGivenTilePos(unique_spawn.surface_name, unique_spawn.position, spawn_chunk_radius, true)

    -- Chart the area to be able to display the minimap while the player waits.
    ChartArea(game.players[unique_spawn.host_name].force,
        delayed_spawn.position,
        spawn_chunk_radius,
        unique_spawn.surface_name)

    return delayed_spawn
end

---Creates and sends a player to a new secondary spawn, temporarily placing them in the holding pen.
---@param player LuaPlayer
---@param surface_name string
---@param send_player boolean Queues the player to be sent to the new spawn when it is created.
---@return nil
function SecondarySpawn(player, surface_name, send_player)

    local player_name = player.name

    -- Get their home spawn first:
    local primary_spawn = FindPlayerHomeSpawn(player_name)
    local host_name = primary_spawn.host_name

    -- Ensure we still have the previous spawn choices (theirs or the host's)
    local spawn_choices = GetPrimarySpawnChoices(host_name)
    if (spawn_choices == nil) then
        log("ERROR - SecondarySpawn - No spawn choices for player: " .. host_name)
        return
    end

    -- Confirm there is no existing spawn point for this host on this surface
    if (storage.unique_spawns[surface_name] ~= nil and storage.unique_spawns[surface_name][host_name] ~= nil) then
        log("ERROR - SecondarySpawn - Host already has a spawn point on this surface: " .. host_name .. " on surface: " .. surface_name)
        return
    end

    -- Claim the next free starting point on the new surface
    local spawn_position = ClaimNextStartingPoint(surface_name, host_name)
    if (spawn_position == nil) then
        SendErrorMsg(player, { "oarc-no-free-starting-points", surface_name })
        return
    end

    -- Add new spawn point for the new surface
    local delayed_spawn = GenerateNewSpawn(host_name, surface_name, spawn_position, spawn_choices, false)
    
    if send_player then 
        QueuePlayerForSpawn(player_name, delayed_spawn)
    else
        SetPlayerRespawn(player_name, delayed_spawn.surface_name, delayed_spawn.position, true, true)
    end

    -- Make sure host and joiners all have their new respawn position set for this surface.
    if (#storage.unique_spawns[surface_name][host_name].joiners > 0) then
        SetPlayerRespawn(host_name, surface_name, spawn_position, false, true)

        for _,joiner_name in pairs(storage.unique_spawns[surface_name][host_name].joiners) do
            SetPlayerRespawn(joiner_name, surface_name, spawn_position, false, true)
        end
    end

    -- Announce
    SendBroadcastMsg({"", { "oarc-player-new-secondary", player_name, surface_name }, " ", GetGPStext(surface_name, spawn_position)})

    -- Tell the player about the reroll command:
    CompatSend(player, { "oarc-reroll-spawn-command" })
end

-- Check a table to see if there are any players waiting to spawn
-- Check if we are past the delayed tick count
-- Spawn the players and remove them from the table.
---@return nil
function DelayedSpawnOnTick()
    if ((game.tick % (30)) ~= 1) then return end

    if ((storage.delayed_spawns ~= nil) and (#storage.delayed_spawns > 0)) then

        -- I think this loop removes from the back of the table to the front??
        for i = #storage.delayed_spawns, 1, -1 do
            delayed_spawn = storage.delayed_spawns[i] --[[@as OarcDelayedSpawn]]

            local surface = game.surfaces[delayed_spawn.surface_name]

            if ((delayed_spawn.delayed_tick < game.tick) or surface.is_chunk_generated(delayed_spawn.final_chunk_generated) ) then
                log("DelayedSpawnOnTick - Generating spawn for: " .. delayed_spawn.host_name)

                GenerateFinalSpawnPieces(delayed_spawn)
                storage.unique_spawns[delayed_spawn.surface_name][delayed_spawn.host_name].generated = true

                -- For each player waiting to spawn, send them to their new spawn point.
                for _,player_name in pairs(delayed_spawn.waiting_players) do
                    local player = game.players[player_name]
                    if (player ~= nil) then
                        SendPlayerToNewSpawn(player_name, delayed_spawn.surface_name, delayed_spawn.primary, delayed_spawn.host_name == player_name)
                    end
                end

                -- Check if there are any dropped pods waiting to be collected for this force
                TeleportCargoPodsToLocation(surface, game.players[delayed_spawn.host_name].force, delayed_spawn.position)

                table.remove(storage.delayed_spawns, i)
            end
        end
    end
end

---Send player to their custom spawn point
---@param surface_name string
---@param player LuaPlayer
---@param first_spawn boolean
---@return nil
function TeleportPlayerToRespawnPoint(surface_name, player, first_spawn)
    local spawn = storage.player_respawns[player.name][surface_name]

    if (spawn == nil) then
        log("ERROR - SendPlayerToSpawn - No spawn point for player: " .. player.name .. " on surface: " .. surface_name .. " first_spawn: " .. tostring(first_spawn))
        return
    end

    if player.driving then
        --Ignore the lua warning, the factorio docs use "bool" instead of "boolean" so its broken. TODO: Remove this when they update the docs.
        ---@diagnostic disable-next-line: param-type-mismatch
        player.set_driving(false, true) -- We need to force player out of the cargo-pod before we teleport.
    end
    SafeTeleport(player, game.surfaces[surface_name], spawn.position)

    if first_spawn then
        player.permission_group = game.permissions.get_group("Default")
    end
end

---Check if a player has a delayed spawn
---@param player_name string
---@return boolean
function PlayerHasDelayedSpawn(player_name)
    for _,delayedSpawn in pairs(storage.delayed_spawns) do
        if (delayedSpawn.host_name == player_name) then
            return true
        end
    end
    return false
end

---Get the list of surfaces that are allowed for primary spawning.
---@return string[]
function GetAllowedSurfaces()
    ---@type string[]
    local surfaceList = {}
    for surfaceName, allowed in pairs(storage.oarc_surfaces) do
        if allowed.primary then
            table.insert(surfaceList, surfaceName)
        end
    end
    return surfaceList
end

---Get the destination surface of a cargo pod as a valid LuaSurface.
---CargoDestination.surface is a SurfaceIdentification (index, name or LuaSurface), and the surface may have been
---deleted (e.g. by another mod) while the pod is in flight, so this can return nil.
---@param destination CargoDestination
---@return LuaSurface?
local function GetCargoPodDestinationSurface(destination)
    local surface_id = destination.surface
    if (surface_id == nil) then return nil end

    ---@type LuaSurface?
    local surface
    if (type(surface_id) == "number") or (type(surface_id) == "string") then
        surface = game.get_surface(surface_id)
    else
        surface = surface_id --[[@as LuaSurface]]
    end

    if (surface == nil) or (not surface.valid) then return nil end
    return surface
end

---Only pods that are headed for a planet surface (not a specific station) need redirecting to a spawn.
---Pods going to a station (landing pad or platform hub), orbit, or a platform are destroyed/handled by the game.
---@param pod LuaEntity
---@return boolean
local function ShouldTrackCargoPod(pod)
    local destination = pod.cargo_pod_destination
    if (destination.type ~= defines.cargo_destination.surface) then
        log("Not tracking cargo pod: " .. tostring(pod.unit_number) .. " - Destination type: " .. tostring(destination.type))
        return false
    end

    -- If the destination surface was deleted (e.g. by another mod like Carna), the game sends the pod back to the
    -- space platform that launched it, so there is nothing for us to do.
    local surface = GetCargoPodDestinationSurface(destination)
    if (surface == nil) then
        log("Not tracking cargo pod: " .. tostring(pod.unit_number) .. " - Destination surface is missing or invalid.")
        return false
    end

    log("Tracking cargo pod: " .. tostring(pod.unit_number) .. " - Destination surface: " .. surface.name .. " - Position: " .. serpent.line(destination.position))
    return true
end

---Pods headed for a surface are only sent to a spawn if spawns are enabled on that surface and the force has no
---landing pad there. If it has a pad, the pods land on it as normal.
---@param force LuaForce
---@param surface LuaSurface
---@return boolean
local function ShouldRedirectCargoPodsOnSurface(force, surface)
    local oarc_surface = storage.oarc_surfaces[surface.name]
    if (not oarc_surface or not (oarc_surface.primary or oarc_surface.secondary)) then return false end
    return not DoesForceHaveLandingPadOnSurface(force, surface)
end

---Find the spawn a cargo pod belongs to on a surface. A pod with a player riding in it belongs to that player's spawn,
---any other pod belongs to its force's spawn.
---@param pod LuaEntity
---@param player LuaPlayer? The player riding in the pod, if any.
---@param surface LuaSurface
---@return OarcUniqueSpawn?
local function FindCargoPodSpawn(pod, player, surface)
    if (player ~= nil) then
        return FindPlayerSpawnOnSurface(player.name, surface.name)
    end

    local force = pod.force --[[@as LuaForce]] -- Always a LuaForce when read.
    return FindUniqueSpawnByForceForSurface(force, surface.name)[1]
end

---If a cargo pod headed for a planet surface belongs to a generated spawn there, point the pod at that spawn by
---writing its destination position, so it lands there instead of at the map center.
---@param pod LuaEntity
---@param player LuaPlayer? The player riding in the pod, if any.
---@return boolean redirected
local function TryRedirectCargoPod(pod, player)
    local destination = pod.cargo_pod_destination
    if (destination.type ~= defines.cargo_destination.surface) then return false end

    local surface = GetCargoPodDestinationSurface(destination)
    if (surface == nil) or not ShouldRedirectCargoPodsOnSurface(pod.force --[[@as LuaForce]], surface) then return false end

    local spawn = FindCargoPodSpawn(pod, player, surface)
    if (spawn == nil) or (not spawn.generated) then return false end

    destination.position = spawn.position
    pod.cargo_pod_destination = destination
    log("Redirected cargo pod " .. tostring(pod.unit_number) .. " to spawn on " .. surface.name .. " at " .. serpent.line(spawn.position))
    return true
end

---When a cargo pod leaves a platform hub for a planet, start generating the secondary spawn it belongs to if there
---isn't one yet. This gives the spawn the whole flight to generate, so the pod can usually be redirected to it in
---OnCargoPodFinishedAscending. If it isn't ready in time, CargoPodHandlerOnTick handles the pod, or the player riding
---in it waits in the holding pen (SeparateSpawnsPlayerChangedSurface).
---@param event EventData.on_cargo_pod_started_ascending
---@return nil
function OnCargoPodStartedAscending(event)
    local pod = event.cargo_pod
    local destination = pod.cargo_pod_destination
    if (destination.type ~= defines.cargo_destination.surface) then return end

    local surface = GetCargoPodDestinationSurface(destination)
    if (surface == nil) or not ShouldRedirectCargoPodsOnSurface(pod.force --[[@as LuaForce]], surface) then return end
    if (not storage.oarc_surfaces[surface.name].secondary) then return end

    -- The secondary spawn is created for the player riding in the pod, or otherwise for the force's host.
    ---@type LuaPlayer?
    local player = nil
    ---@type LuaPlayer
    local spawn_player
    if (event.player_index ~= nil) then
        player = game.players[event.player_index]
        if (storage.player_respawns[player.name] == nil) then return end -- Player hasn't spawned yet.
        spawn_player = player
    else
        local force = pod.force --[[@as LuaForce]]
        local primary_spawn = FindPrimarySpawnForForce(force)
        if (primary_spawn == nil) then return end
        spawn_player = game.players[primary_spawn.host_name]
    end

    -- Only one spawn is created, even if several pods are on their way.
    if (FindCargoPodSpawn(pod, player, surface) ~= nil) then return end

    log("A cargo pod leaving for " .. surface.name .. " triggered a secondary spawn for: " .. spawn_player.name)
    SecondarySpawn(spawn_player, surface.name, false)
end

---Redirect the cargo pods coming down onto a planet to the spawn they belong to. Pods without a player riding in them
---that can't be redirected yet are tracked for CargoPodHandlerOnTick.
---@param event EventData.on_cargo_pod_finished_ascending
---@return nil
function OnCargoPodFinishedAscending(event)
    if (storage.cargo_pods == nil) then
        --[[@type table<integer, LuaEntity>]]
        storage.cargo_pods = {}
    end

    local pod = event.cargo_pod

    -- If a pod with a player riding in it can't be redirected, SeparateSpawnsPlayerChangedSurface handles the player.
    if (event.player_index ~= nil) then
        TryRedirectCargoPod(pod, game.players[event.player_index])
        return
    end

    -- Only handle pods that are launched from a space platform.
    if (event.launched_by_rocket) then return end
    if TryRedirectCargoPod(pod, nil) then return end

    -- TODO: Check if we can trace the cargo pod to the player who launched it somehow.
    local unit_number = pod.unit_number
    if (unit_number ~= nil) and ShouldTrackCargoPod(pod) then
        storage.cargo_pods[unit_number] = pod
    end
end

---On tick, handle any tracked cargo pods that couldn't be redirected when they finished ascending (e.g. their spawn
---was still generating), teleporting them to a spawn point where possible.
---@return nil
function CargoPodHandlerOnTick()
    if (storage.cargo_pods == nil) then return end

    -- TODO: The early returns below mean only one pod is handled per tick. This is a known limitation, any remaining
    -- pods are handled on the following ticks.
    for index, pod in pairs(storage.cargo_pods) do

        -- Pods can be destroyed before we see them descend (e.g. landing on a platform or removed by another mod).
        -- The stored entity reference is then invalid and any API call on it would crash the game.
        if (not pod.valid) then
            storage.cargo_pods[index] = nil

        -- Sanity check, we only store pods headed for a surface.
        elseif (pod.cargo_pod_destination.type ~= defines.cargo_destination.surface) then
            storage.cargo_pods[index] = nil
            log("ERROR! Cargo pod destination is not a surface?")

        -- The destination surface can be deleted while the pod is still valid (e.g. by another mod like Carna).
        -- The game sends the pod back to the space platform that launched it, so we just stop tracking it.
        elseif (GetCargoPodDestinationSurface(pod.cargo_pod_destination) == nil) then
            storage.cargo_pods[index] = nil
            log("Cargo pod destination surface is missing or invalid, no longer tracking pod: " .. tostring(index))

        -- Wait until the pod has left the platform surface it launched from (it is descending) before handling it.
        elseif (pod.surface.platform == nil) then
            -- Use the destination surface, not pod.surface, which may still report the surface it launched from.
            local surface = GetCargoPodDestinationSurface(pod.cargo_pod_destination) --[[@as LuaSurface]]
            local force = pod.force --[[@as LuaForce]] -- Always a LuaForce when read.

            -- Remove any pods that are landing on a surface we don't care about:
            -- Check if both primary and secondary spawns are disabled
            local oarc_surface = storage.oarc_surfaces[surface.name]
            if (not oarc_surface or not (oarc_surface.primary or oarc_surface.secondary)) then
                storage.cargo_pods[index] = nil
                return
            end

            -- Check if the force has a landing pad on this surface
            local has_landing_pad = DoesForceHaveLandingPadOnSurface(force, surface)
            if has_landing_pad then
                storage.cargo_pods[index] = nil
                return
            end

            -- Only surfaces with secondary spawns enabled get pods redirected to a spawn.
            if (not oarc_surface.secondary) then
                storage.cargo_pods[index] = nil
                return
            end

            -- Check if the force has a unique spawn on this surface
            local unique_spawn = FindUniqueSpawnByForceForSurface(force, surface.name)
            local has_unique_spawn = (#unique_spawn > 0)

            -- Pod has a spawn it belongs to, send it there.
            if has_unique_spawn then
                log("Pod has a unique spawn, need to send it there.")

                -- Forcefully finish descending and remove the pod from our list.
                pod.force_finish_descending()
                storage.cargo_pods[index] = nil

                -- Search for dropped pods and teleport them to the unique spawn.
                -- If the spawn is still generating, they will be teleported when it is done.
                if unique_spawn[1].generated then
                    TeleportCargoPodsToLocation(surface, force, unique_spawn[1].position)
                end
                return

            -- Pod will trigger the creation of a new secondary spawn otherwise
            else
                -- Find a primary spawn of the force to get the host:
                local spawn = FindPrimarySpawnForForce(force)
                if (spawn == nil) then
                    -- This should never happen in theory...
                    log("ERROR! No primary spawn found for force: " .. force.name)
                    storage.cargo_pods[index] = nil
                    return
                end

                log("A landing cargo pod triggered a secondary spawn for force: " .. force.name)
                SecondarySpawn(game.players[spawn.host_name], surface.name, false)

                -- Any cargo pods will be teleported to the unique spawn when it is finished generating.
                pod.force_finish_descending()
                storage.cargo_pods[index] = nil
                return
            end
        end
    end
end

local CARGO_SEARCH_RADIUS = CHUNK_SIZE * 3
local CARGO_SEARCH_AREA = { { -CARGO_SEARCH_RADIUS, -CARGO_SEARCH_RADIUS }, { CARGO_SEARCH_RADIUS, CARGO_SEARCH_RADIUS } }

---Search for cargo pods at the center of this surface and teleport them to the requested location.
---@param surface LuaSurface
---@param force LuaForce|string|integer
---@param position MapPosition
---@return nil
function TeleportCargoPodsToLocation(surface, force, position)
    local cargo_pods = surface.find_entities_filtered { area = CARGO_SEARCH_AREA, name = "cargo-pod-container", force = force }
    for _, cargo_pod in pairs(cargo_pods) do
        SafeEntityTeleport(cargo_pod, position)
    end
end

--[[
  ___  ___   ___   ___  ___     ___  ___  ___  ___  ___  ___  ___  ___
 | __|/ _ \ | _ \ / __|| __|   / __|| _ \| __|/ __||_ _|| __||_ _|/ __|
 | _|| (_) ||   /| (__ | _|    \__ \|  _/| _|| (__  | | | _|  | || (__
 |_|  \___/ |_|_\ \___||___|   |___/|_|  |___|\___||___||_|  |___|\___|

--]]


---Unlock a space location (e.g. a planet) for a force, so it shows as discovered.
---unlock_space_location throws on a name that isn't a space location (such as a custom or modded non-planet
---surface), so this checks the prototype exists first.
---@param force LuaForce
---@param location_name string
---@return nil
function UnlockSpaceLocationForForce(force, location_name)
    if (prototypes.space_location[location_name] == nil) then
        log("ERROR - UnlockSpaceLocationForForce - Not a space location: " .. location_name .. " for force: " .. force.name)
        return
    end

    force.unlock_space_location(location_name)
end

---Create a new player force (sets ceasefire and friendly status for all teams)
---@param force_name string
---@return LuaForce
function CreatePlayerForce(force_name)
    local new_force = nil

    -- Check if force already exists
    if (game.forces[force_name] ~= nil) then
        log("Force already exists!")
        return CreatePlayerForce(force_name .. "_") -- Append a character to make the force name unique.

        -- Create a new force
    elseif (#game.forces < MAX_FORCES) then
        new_force = game.create_force(force_name)
        new_force.share_chart = storage.ocfg.gameplay.enable_shared_team_vision
        new_force.friendly_fire = storage.ocfg.gameplay.enable_friendly_fire
        -- SetCeaseFireBetweenAllPlayerForces()
        -- SetFriendlyBetweenAllPlayerForces()
        ConfigurePlayerForceRelationships(storage.ocfg.gameplay.enable_cease_fire,
            storage.ocfg.gameplay.enable_friendly_teams)
        -- ConfigureEnemyForceRelationshipsForNewPlayerForce(new_force)
    else
        log("TOO MANY FORCES!!! - CreatePlayerForce()")
        return game.forces[LOBBY_FORCE_NAME]
    end

    return new_force
end

---Create a new player force and assign the player to it.
---@param player LuaPlayer
---@return LuaForce
function CreatePlayerCustomForce(player)
    local newForce = CreatePlayerForce(player.name)
    player.force = newForce

    local spawn_choices = storage.spawn_choices[player.name]
    if (spawn_choices ~= nil) then
        UnlockSpaceLocationForForce(newForce, spawn_choices.surface_name)
    else
        log("ERROR - CreatePlayerCustomForce - No spawn choices for player: " .. player.name)
    end

    if (newForce.name == player.name) then
        SendBroadcastMsg({ "oarc-player-started-own-team", player.name })
    else
        SendErrorMsg(player, { "oarc-player-no-new-teams-sorry" })
    end

    return newForce
end


--[[

  _   _   _  _     _______   _____ ___     _   _  _ _  _  ___ _____ _ _____ ___ ___  _  _ ___
 | | | | | |/_\   |_   _\ \ / / _ \ __|   /_\ | \| | \| |/ _ \_   _/_\_   _|_ _/ _ \| \| / __|
 | |_| |_| / _ \    | |  \ V /|  _/ _|   / _ \| .` | .` | (_) || |/ _ \| |  | | (_) | .` \__ \
 |____\___/_/ \_\   |_|   |_| |_| |___| /_/ \_\_|\_|_|\_|\___/ |_/_/ \_\_| |___\___/|_|\_|___/

 These are LUA type annotations for development and editor support.
 You can ignore this unless you're making changes to the mod, in which case it might be helpful.
]]

---Contains the respawn point for a player. Usually this is their home base but it can be changed.
---@alias OarcPlayerSpawn { surface: string, position: MapPosition }
---Table of [OarcSharedSpawn](lua://OarcSharedSpawn) indexed by player name and then by surface name.
---@alias OarcPlayerRespawnsTable table<string, table<string, OarcPlayerSpawn>>

---Class for unique spawn point
---@class OarcUniqueSpawn
---@field surface_name string The surface on which the spawn is located.
---@field position MapPosition The position of the spawn on that surface.
---@field primary boolean Whether this is the primary spawn point for a player, this is the first surface they spawn on. All other spawns are secondary.
---@field prefab boolean Whether this is an OG Oarc style spawn circle (prefab) or the vanilla starting area. Secondary spawns copy it from the primary spawn.
---@field moat boolean Whether the spawn has a moat or not.
---@field open_access boolean Whether the spawn is open for other players to join.
---@field host_name string The player name of the host of this spawn.
---@field join_queue string[] List of players waiting to join this spawn.
---@field joiners string[] List of players who have joined this spawn NOT including the host.
---@field generated boolean Whether the spawn has finished being generated or not.

---Table of [OarcUniqueSpawnClass](lua://OarcUniqueSpawnClass) indexed first by surface name and then by player name.
---@alias OarcUniqueSpawnsTable table<string, table<string, OarcUniqueSpawn>>

---Contains player ability cooldowns. Right now this only tracks changing the respawn ability.
---@alias OarcPlayerCooldown { setRespawn: number }
---Table of [OarcPlayerCooldown](lua://OarcPlayerCooldown) indexed by player name.
---@alias OarcPlayerCooldownsTable table<string, OarcPlayerCooldown>

---Temporary data used when spawning a player. Player needs to wait while the area is prepared.
---Temporary data used when spawning a player. Player needs to wait while the area is prepared.
---@class OarcDelayedSpawn: OarcUniqueSpawn
---@field delayed_tick number The game tick when the spawn will be ready.
---@field final_chunk_generated ChunkPosition The final chunk position that needs to be generated.
---@field waiting_players string[] List of players waiting to join this spawn once it is done generating.
---Array of [OarcDelayedSpawn](lua://OarcDelayedSpawn).
---@alias OarcDelayedSpawnsTable OarcDelayedSpawn[]

---This contains the spawn choices for a player in the spawn menu.
---Class representing the spawn choices for a player in the spawn menu.
---@class OarcSpawnChoices
---@field surface_name string The surface on which the player wants to spawn.
---@field prefab boolean Whether the player wants the OG Oarc style spawn circle instead of the vanilla starting area.
---@field moat boolean Whether the player wants a moat around their spawn. Only used for prefab spawns.
---@field host_name string? The host player name if the player wants to join a shared spawn.

---Table of [OarcSpawnChoices](lua://OarcSpawnChoices) indexed by player name.
---@alias OarcSpawnChoicesTable table<string, OarcSpawnChoices>

---Primary means a player can spawn for the first time on this surface, secondary they can land here and also receive a custom spawn area.
---@alias OarcSurfaceSpawnSetting { primary: boolean, secondary: boolean}

---Entry for a nil_character_teleport_queue
---@alias OarcNilCharacterTeleportQueueEntry { surface_name: string, first_spawn: boolean, is_host: boolean } 
