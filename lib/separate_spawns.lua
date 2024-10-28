-- Code that handles everything regarding giving each player a separate spawn

local util = require("util")
local crash_site = require("crash-site")

--[[
  ___  _  _  ___  _____
 |_ _|| \| ||_ _||_   _|
  | | | .` | | |   | |
 |___||_|\_||___|  |_|

--]]

-- Hardcoded force names for special cases.
ABANDONED_FORCE_NAME = "_ABANDONED_"
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

    -- This contains each player's respawn point. Literally where they will respawn on death
    -- There is a way in game to change this under one of the little menu features I added. This allows players to
    -- change their respawn point to something other than their home base.
    -- TODO: Space Age will potentially affect this, as I may need to allow for multiple respawn points on different surfaces.
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
    -- Intended to be re-used for secondary spawns! (TODO SPACE AGE)
    --[[@type OarcSpawnChoicesTable]]
    storage.spawn_choices = {}

    -- Buddy info: The only real use is to check if one of a buddy pair is online to see if we should allow enemy
    -- attacks on the base.  <br>
    -- storage.buddy_pairs[player.name] = requesterName  <br>
    -- storage.buddy_pairs[requesterName] = player.name  <br>
    --[[@type table<string, string>]]
    storage.buddy_pairs = {}

    --- Table contains all the renders that need to be faded out over time in the on_tick event. They are removed when they expire.
    --[[@type table<integer>]]
    storage.oarc_renders_fadeout = {}

    -- Special forces for when players with their own force want a reset.
    game.create_force(ABANDONED_FORCE_NAME)
    -- game.create_force(DESTROYED_FORCE_NAME)

    -- Name a new force to be the default force.
    -- This is what any new player is assigned to when they join, even before they spawn.
    local main_force = CreatePlayerForce(storage.ocfg.gameplay.main_force_name)
    main_force.set_spawn_position({ x = 0, y = 0 }, storage.ocfg.gameplay.default_surface)

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

---Init globals for a new surface and set the default allow spawn value based on settings.
---@param surface_name string
---@return nil
function SeparateSpawnsInitSurface(surface_name)
    -- Shouldn't happen because surface created isn't triggered during on_init.
    if (storage.oarc_surfaces == nil) then
        error("storage.oarc_surfaces not initialized yet?! " .. surface_name)
    end

    if IsSurfaceBlacklisted(surface_name) then return end

    -- Add the surface to the list of surfaces that allow spawns with value from config.
    if storage.ocfg.gameplay.default_allow_spawning_on_other_surfaces then
        storage.oarc_surfaces[surface_name] = { primary = true, secondary = true }

    -- Otherwise only allow the default surface (by default)
    else
        storage.oarc_surfaces[surface_name] = {
            primary = (surface_name == storage.ocfg.gameplay.default_surface),
            secondary = false
        }
    end

    -- Make sure it has a surface configuration entry!
    if (storage.ocfg.surfaces_config[surface_name] == nil) then
        log("Surface does NOT have a config entry, defaulting to nauvis entry for new surface: " .. surface_name)
        storage.ocfg.surfaces_config[surface_name] = table.deepcopy(storage.ocfg.surfaces_config["nauvis"])
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
-- If new player, assign them to the main force so they can communicate with the team without shouting (/s).
---@param player_index integer|string
---@return nil
function SeparateSpawnsInitPlayer(player_index)
    local player = game.players[player_index]

    SafeTeleport(player, game.surfaces[HOLDING_PEN_SURFACE_NAME], { x = 0, y = 0 })

    player.force = storage.ocfg.gameplay.main_force_name -- Put them on the main force.

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

    -- If the mod isn't active on this surface, then ignore it.
    local surface_config = storage.oarc_surfaces[surface_name]
    if (surface_config == nil) or
        (not surface_config.primary and not surface_config.secondary) then
        return
    end

    SendPlayerToSpawn(surface_name, player, false)
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
        SendBroadcastMsg({ "oarc-player-on-platform", player.name, surface.platform.name })
    else
        SendBroadcastMsg({ "oarc-player-changed-surface", player.name, surface.name })
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

    local player_spawn = FindPlayerSpawnOnSurface(player.name, new_surface_name) -- Either they are host or joiner.

    -- If there IS a spawn for them on their new surface, then just send them there.
    if (player_spawn ~= nil) then
        SendPlayerToSpawn(new_surface_name, player, false)
        return
    end

    -- If there is no spawn for them on their new surface, generate one based on previous choices.

    -- Check if secondary spawns are enabled (both globally and on this surface)
    if (not storage.ocfg.gameplay.enable_secondary_spawns) or
        (not storage.oarc_surfaces[new_surface_name].secondary) then
        return
    end

    -- TODO: Need to figure out buddy spawns and other stuff still!

    log("WARNING - THIS IS NOT FULLY IMPLEMENTED YET!!")
    SecondarySpawn(player, game.surfaces[new_surface_name])
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
            script.raise_event("oarc-mod-character-surface-changed", {
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

-- Generate the basic starter resource around a given location.
---@param surface LuaSurface
---@param position TilePosition --The center of the spawn area
---@return nil
function GenerateStartingResources(surface, position)

    local size_mod = storage.ocfg.resource_placement.size_multiplier
    local amount_mod = storage.ocfg.resource_placement.amount_multiplier

    -- Generate all resource tile patches
    -- Generate resources in random order around the spawn point.
    if storage.ocfg.resource_placement.enabled then
        if (storage.ocfg.spawn_general.shape == SPAWN_SHAPE_CHOICE_CIRCLE) or (storage.ocfg.spawn_general.shape == SPAWN_SHAPE_CHOICE_OCTAGON) then
            PlaceResourcesInSemiCircle(surface, position, size_mod, amount_mod)
        elseif (storage.ocfg.spawn_general.shape == SPAWN_SHAPE_CHOICE_SQUARE) then
            PlaceResourcesInSquare(surface, position, size_mod, amount_mod)
        end

    -- Generate resources using specified offsets if auto placement is disabled.
    else
        for r_name, r_data in pairs(storage.ocfg.surfaces_config[surface.name].spawn_config.solid_resources --[[@as table<string, OarcConfigSolidResource>]]) do
            local pos = { x = position.x + r_data.x_offset, y = position.y + r_data.y_offset }
            GenerateResourcePatch(surface, r_name, r_data.size * size_mod, pos, r_data.amount * amount_mod)
        end
    end

    -- Generate special fluid resource patches (oil)
    -- Autoplace using spacing and vertical offset.
    -- Reference position is the bottom of the spawn area.
    if storage.ocfg.resource_placement.enabled then
        local y_offset = storage.ocfg.resource_placement.distance_to_edge
        local fluid_ref_pos = { x = position.x, y = position.y + storage.ocfg.spawn_general.spawn_radius_tiles - y_offset }

        for r_name, r_data in pairs(storage.ocfg.surfaces_config[surface.name].spawn_config.fluid_resources --[[@as table<string, OarcConfigFluidResource>]]) do

            local spacing = r_data.spacing
            local oil_patch_x = fluid_ref_pos.x - (((r_data.num_patches-1) * spacing) / 2)
            local oil_patch_y = fluid_ref_pos.y

            for i = 1, r_data.num_patches do
                surface.create_entity({
                    name = "crude-oil",
                    amount = r_data.amount,
                    position = { oil_patch_x, oil_patch_y }
                })
                oil_patch_x = oil_patch_x + spacing
            end

            fluid_ref_pos.y = fluid_ref_pos.y - spacing
        end

    -- This places using specified offsets if auto placement is disabled.
    else
        local fluid_ref_pos = { x = position.x, y = position.y + storage.ocfg.spawn_general.spawn_radius_tiles }
        for r_name, r_data in pairs(storage.ocfg.surfaces_config[surface.name].spawn_config.fluid_resources --[[@as table<string, OarcConfigFluidResource>]]) do
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

---Places starting resource deposits in a semi-circle around the spawn point.
---@param surface LuaSurface
---@param position TilePosition --The center of the spawn area
---@param size_mod number
---@param amount_mod number
---@return nil
function PlaceResourcesInSemiCircle(surface, position, size_mod, amount_mod)

    -- Create list of resource tiles
    ---@type table<string>
    local r_list = {}
    for r_name, _ in pairs(storage.ocfg.surfaces_config[surface.name].spawn_config.solid_resources --[[@as table<string, OarcConfigSolidResource>]]) do
        if (r_name ~= "") then
            table.insert(r_list, r_name)
        end
    end
    ---@type table<string>
    local shuffled_list = FYShuffle(r_list)

    -- This places resources in a semi-circle
    local angle_offset_radians = math.rad(storage.ocfg.resource_placement.angle_offset)
    local angle_final_radians = math.rad(storage.ocfg.resource_placement.angle_final)
    local num_resources = table_size(storage.ocfg.surfaces_config[surface.name].spawn_config.solid_resources)
    local theta = ((angle_final_radians - angle_offset_radians) / (num_resources-1));
    local count = 0

    local radius = storage.ocfg.spawn_general.spawn_radius_tiles - storage.ocfg.resource_placement.distance_to_edge

    for _, r_name in pairs(shuffled_list) do
        local angle = (theta * count) + angle_offset_radians;

        local tx = (radius * math.cos(angle)) + position.x
        local ty = (radius * math.sin(angle)) + position.y

        local pos = { x = math.floor(tx), y = math.floor(ty) }

        local resourceConfig = storage.ocfg.surfaces_config[surface.name].spawn_config.solid_resources[r_name]
        GenerateResourcePatch(surface, r_name, resourceConfig.size * size_mod, pos, resourceConfig.amount * amount_mod)
        count = count + 1
    end
end

---Places starting resource deposits in a line starting at the top left of the spawn point.
---@param surface LuaSurface
---@param position TilePosition --The center of the spawn area
---@param size_mod number
---@param amount_mod number
---@return nil
function PlaceResourcesInSquare(surface, position, size_mod, amount_mod)

    -- Create list of resource tiles
    ---@type table<string>
    local r_list = {}
    for r_name, _ in pairs(storage.ocfg.surfaces_config[surface.name].spawn_config.solid_resources --[[@as table<string, OarcConfigSolidResource>]]) do
        if (r_name ~= "") then
            table.insert(r_list, r_name)
        end
    end
    ---@type table<string>
    local shuffled_list = FYShuffle(r_list)

    -- Get the top left position of the spawn area
    local resource_position = { x = position.x - storage.ocfg.spawn_general.spawn_radius_tiles,
                                y = position.y - storage.ocfg.spawn_general.spawn_radius_tiles }

    -- Offset the starting position
    resource_position.x = resource_position.x + storage.ocfg.resource_placement.horizontal_offset
    resource_position.y = resource_position.y + storage.ocfg.resource_placement.vertical_offset

    -- Place vertically using linear spacing
    for _, r_name in pairs(shuffled_list) do
        local resourceConfig = storage.ocfg.surfaces_config[surface.name].spawn_config.solid_resources[r_name]
        local size = resourceConfig.size * size_mod
        GenerateResourcePatch(surface, r_name, size, resource_position, resourceConfig.amount * amount_mod)
        resource_position.y = resource_position.y + size + storage.ocfg.resource_placement.linear_spacing
    end
end

---Sends the player to their spawn point
---@param delayed_spawn OarcDelayedSpawn
---@return nil
function SendPlayerToNewSpawnAndCreateIt(delayed_spawn)
    local ocfg --[[@as OarcConfig]] = storage.ocfg
    local spawn_config = ocfg.surfaces_config[delayed_spawn.surface].spawn_config

    -- DOUBLE CHECK and make sure the area is super safe.
    ClearNearbyEnemies(delayed_spawn.position, spawn_config.safe_area.safe_radius * CHUNK_SIZE,
        game.surfaces[delayed_spawn.surface])

    -- Generate water strip only if we don't have a moat.
    if (not delayed_spawn.moat) then
        local water_data = spawn_config.water
        -- Reference position is the top of the spawn area.
        local reference_pos = {
            x = delayed_spawn.position.x,
            y = delayed_spawn.position.y - storage.ocfg.spawn_general.spawn_radius_tiles
        }
        CreateWaterStrip(game.surfaces[delayed_spawn.surface],
            { x = reference_pos.x + water_data.x_offset, y = reference_pos.y + water_data.y_offset },
            water_data.length)
        CreateWaterStrip(game.surfaces[delayed_spawn.surface],
            { x = reference_pos.x + water_data.x_offset, y = reference_pos.y + water_data.y_offset + 1 },
            water_data.length)
    end

    -- Create the spawn resources here
    GenerateStartingResources(game.surfaces[delayed_spawn.surface], delayed_spawn.position)

    -- Reference position is RIGHT (WEST) of the spawn area.
    local sharing_ref_pos = {
        x = delayed_spawn.position.x + storage.ocfg.spawn_general.spawn_radius_tiles,
        y = delayed_spawn.position.y
    }

    -- Create shared power poles
    if (ocfg.gameplay.enable_shared_power and delayed_spawn.primary) then
        local power_pole_position = {
            x = sharing_ref_pos.x + spawn_config.shared_power_pole_position.x_offset,
            y = sharing_ref_pos.y + spawn_config.shared_power_pole_position.y_offset }
        CreateSharedPowerPolePair(game.surfaces[delayed_spawn.surface], power_pole_position)
    end

    -- Create shared chest
    if (ocfg.gameplay.enable_shared_chest and delayed_spawn.primary) then
        local chest_position = {
            x = sharing_ref_pos.x + spawn_config.shared_chest_position.x_offset,
            y = sharing_ref_pos.y + spawn_config.shared_chest_position.y_offset }
        CreateSharedChest(game.surfaces[delayed_spawn.surface], chest_position)
    end

    -- Send the player to that position
    local player = game.players[delayed_spawn.playerName]
    SendPlayerToSpawn(delayed_spawn.surface, player, delayed_spawn.primary)
    GivePlayerStarterItems(player)

    -- Render some welcoming text...
    DisplayWelcomeGroundTextAtSpawn(player, delayed_spawn.surface, delayed_spawn.position)

    -- Chart the area.
    ChartArea(player.force, delayed_spawn.position, math.ceil(storage.ocfg.spawn_general.spawn_radius_tiles / CHUNK_SIZE),
        player.character.surface)

    -- Remove waiting dialog
    if (player.gui.screen.wait_for_spawn_dialog ~= nil) then
        player.gui.screen.wait_for_spawn_dialog.destroy()
    end

    -- Create crash site if configured
    if (ocfg.surfaces_config[delayed_spawn.surface].starting_items.crashed_ship) then
        crash_site.create_crash_site(game.surfaces[delayed_spawn.surface],
            { x = delayed_spawn.position.x + 15, y = delayed_spawn.position.y - 25 },
            ocfg.surfaces_config[delayed_spawn.surface].starting_items.crashed_ship_resources,
            ocfg.surfaces_config[delayed_spawn.surface].starting_items.crashed_ship_wreakage)
    end

    -- Trigger the event that the spawn was created.
    script.raise_event("oarc-mod-on-spawn-created", {spawn_data = storage.unique_spawns[delayed_spawn.surface][delayed_spawn.playerName]})

    -- Trigger the event that player was spawned too.
    script.raise_event("oarc-mod-on-player-spawned", {player_index = player.index})
end

---Displays some welcoming text at the spawn point on the ground. Fades out over time.
---@param player LuaPlayer
---@param surface LuaSurface|string
---@param position MapPosition
---@return nil
function DisplayWelcomeGroundTextAtSpawn(player, surface, position)
    -- Render some welcoming text...
    local tcolor = { 0.9, 0.7, 0.3, 0.8 }
    local ttl = 2000
    local render_object_1 = rendering.draw_text { text = "Welcome",
        surface = surface,
        target = { x = position.x - 21, y = position.y - 15 },
        color = tcolor,
        scale = 20,
        font = "compi",
        time_to_live = ttl,
        -- players={player},
        draw_on_ground = true,
        orientation = 0,
        -- alignment=center,
        scale_with_zoom = false,
        only_in_alt_mode = false }
    local render_object_2 = rendering.draw_text { text = "Home",
        surface = surface,
        target = { x = position.x - 14, y = position.y - 5 },
        color = tcolor,
        scale = 20,
        font = "compi",
        time_to_live = ttl,
        -- players={player},
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
---@param chunkArea BoundingBox
---@return nil
function SetupAndClearSpawnAreas(surface, chunkArea)

    local closest_spawn = GetClosestUniqueSpawn(surface.name, chunkArea.left_top)
    if (closest_spawn == nil) then return end

    --[[@type OarcConfigSpawnGeneral]]
    local general_spawn_config = storage.ocfg.spawn_general

    local chunkAreaCenter = {
        x = chunkArea.left_top.x + (CHUNK_SIZE / 2),
        y = chunkArea.left_top.y + (CHUNK_SIZE / 2)
    }

    -- If there is a buddy spawn, we need to setup both areas TOGETHER so they overlap.
    local spawns = { closest_spawn }
    if (closest_spawn.buddy_name ~= nil) then
        table.insert(spawns, storage.unique_spawns[closest_spawn.surface_name][closest_spawn.buddy_name])
    end

    -- This will typically just contain the one spawn point, but if there is a buddy spawn, it will contain both.
    for _, spawn in pairs(spawns) do
        -- If the chunk is within the main land area, then clear trees/resources and create the land spawn areas
        -- (guaranteed land with a circle of trees)
        local landArea = GetAreaAroundPos(spawn.position, general_spawn_config.spawn_radius_tiles + CHUNK_SIZE)
        if not CheckIfInArea(chunkAreaCenter, landArea) then 
            goto CONTINUE
        end

        -- Remove trees/resources inside the spawn area
        if (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_CIRCLE) or (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_OCTAGON) then
            RemoveInCircle(surface, chunkArea, {"resource", "cliff", "tree"}, spawn.position, general_spawn_config.spawn_radius_tiles + 5)
        elseif (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_SQUARE) then
            RemoveInSquare(surface, chunkArea, {"resource", "cliff", "tree"}, spawn.position, general_spawn_config.spawn_radius_tiles + 5)
        end

        -- Fill in the spawn area with landfill and create a circle of trees around it.
        local fill_tile = "landfill"
        if general_spawn_config.force_grass then
            fill_tile = "grass-1"
        end
        
        if (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_CIRCLE) then
            CreateCropCircle(
                surface,
                spawn.position,
                chunkArea,
                general_spawn_config.spawn_radius_tiles,
                fill_tile,
                spawn.moat,
                storage.ocfg.gameplay.enable_moat_bridging
            )
        elseif (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_OCTAGON) then
            CreateCropOctagon(
                surface,
                spawn.position,
                chunkArea,
                general_spawn_config.spawn_radius_tiles,
                fill_tile,
                spawn.moat,
                storage.ocfg.gameplay.enable_moat_bridging
            )
        elseif (general_spawn_config.shape == SPAWN_SHAPE_CHOICE_SQUARE) then
            CreateCropSquare(
                surface,
                spawn.position,
                chunkArea,
                general_spawn_config.spawn_radius_tiles,
                fill_tile,
                spawn.moat,
                storage.ocfg.gameplay.enable_moat_bridging
            )
        end

        :: CONTINUE ::
    end
end

---This is the main function that creates the spawn area. Provides resources, land and a safe zone.
---@param event EventData.on_chunk_generated
---@return nil
function SeparateSpawnsGenerateChunk(event)
    local surface = event.surface
    local chunkArea = event.area

    -- Don't block based on spawn enabled.
    -- if (not storage.oarc_surfaces[surface.name]) then return end

    -- Downgrade resources near to spawns
    -- TODO: Space Age will change this!
    if storage.ocfg.gameplay.scale_resources_around_spawns then
        DowngradeResourcesDistanceBasedOnChunkGenerate(surface, chunkArea)
    end

    -- This handles chunk generation near player spawns
    -- If it is near a player spawn, it provide a guaranteed area of land and water tiles.
    SetupAndClearSpawnAreas(surface, chunkArea)
end

---Based on the danger distance, you get full resources, and it is exponential from the spawn point to that distance.
---@param surface LuaSurface
---@param chunkArea BoundingBox
---@return nil
function DowngradeResourcesDistanceBasedOnChunkGenerate(surface, chunkArea)
    local closestSpawn = GetClosestUniqueSpawn(surface.name, chunkArea.left_top)

    if (closestSpawn == nil) then return end

    local distance = util.distance(chunkArea.left_top, closestSpawn.position)
    -- Adjust multiplier to bring it in or out
    local modifier = (distance / (storage.ocfg.surfaces_config[surface.name].spawn_config.safe_area.danger_radius * CHUNK_SIZE * 1)) ^ 3
    if modifier < 0.1 then modifier = 0.1 end
    if modifier > 1 then return end

    local ore_per_tile_cap = math.floor(100000 * modifier)

    for _, entity in pairs(surface.find_entities_filtered { area = chunkArea, type = "resource" }) do
        if entity.valid and entity.amount then
            local new_amount = math.ceil(entity.amount * modifier)
            if (new_amount < 1) then
                entity.destroy()
            else
                if (entity.name ~= "crude-oil") then
                    entity.amount = math.min(new_amount, ore_per_tile_cap)
                else
                    entity.amount = new_amount
                end
            end
        end
    end
end

--[[
   ___  _     ___    _    _  _  _   _  ___
  / __|| |   | __|  /_\  | \| || | | || _ \
 | (__ | |__ | _|  / _ \ | .` || |_| ||  _/
  \___||____||___|/_/ \_\|_|\_| \___/ |_|

--]]

-- ---Resets the player and destroys their force if they are not on the main one.
-- ---@param player LuaPlayer
-- ---@return nil
-- function ResetPlayerAndDestroyForce(player)
--     local player_old_force = player.force

--     player.force = storage.ocfg.gameplay.main_force_name

--     if ((#player_old_force.players == 0) and (player_old_force.name ~= storage.ocfg.gameplay.main_force_name)) then
--         SendBroadcastMsg("Team " ..
--             player_old_force.name .. " has been destroyed! All buildings will slowly be destroyed now.") --: localize
--         log("DestroyForce - FORCE DESTROYED: " .. player_old_force.name)
--         game.merge_forces(player_old_force, DESTROYED_FORCE_NAME)
--     end

--     RemoveOrResetPlayer(player, false, false, true, true)
--     SeparateSpawnsInitPlayer(player.index)
-- end

-- ---Resets the player and merges their force into the abandoned_force.
-- ---@param player LuaPlayer
-- ---@return nil
-- function ResetPlayerAndAbandonForce(player)
--     local player_old_force = player.force

--     player.force = storage.ocfg.gameplay.main_force_name

--     if ((#player_old_force.players == 0) and (player_old_force.name ~= storage.ocfg.gameplay.main_force_name)) then
--         SendBroadcastMsg("Team " .. player_old_force.name .. " has been abandoned!") --: localize
--         log("AbandonForce - FORCE ABANDONED: " .. player_old_force.name)
--         game.merge_forces(player_old_force, ABANDONED_FORCE_NAME)
--     end

--     RemoveOrResetPlayer(player, false, false, false, false)
--     SeparateSpawnsInitPlayer(player.index)
-- end

-- ---Reset player and merge their force to neutral
-- ---@param player LuaPlayer
-- ---@return nil
-- function ResetPlayerAndMergeForceToNeutral(player)
--     RemoveOrResetPlayer(player, false, true, true, true)
--     SeparateSpawnsInitPlayer(player.index)
-- end

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
    player.force = storage.ocfg.gameplay.main_force_name

    -- Clear globals
    CleanupPlayerGlobals(player.name) -- This cleans storage.unique_spawns IF we are transferring ownership.

    -- Safely clear the unique spawn IF it is still valid.
    UniqueSpawnCleanupRemove(player.name) -- Specifically storage.unique_spawns

    -- Remove a force if this player created it and they are the only one on it
    if ((#player_old_force.players == 0) and (player_old_force.name ~= storage.ocfg.gameplay.main_force_name)) then
        log("RemoveOrResetPlayer - FORCE REMOVED: " .. player_old_force.name)
        game.merge_forces(player_old_force, "neutral")
    end

    -- Trigger the event that the player was reset.
    script.raise_event("oarc-mod-on-player-reset", {player_index = player.index})

    -- Remove the character completely
    if (remove_player and not player.connected) then
        game.remove_offline_players({ player })

    -- Otherwise, make sure to re-init them!
    else
        if (remove_player) then
            log("ERROR! RemoveOrResetPlayer - Player not removed as they are still connected: " .. player.name)
        end
        SeparateSpawnsInitPlayer(player.index --[[@as string]])
        SendBroadcastMsg({"oarc-player-was-reset-notify", player.name})
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

---Find the primary home spawn of a player, if one exists. It could be they joined a shared spawn.
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

---Cleans up a player's unique spawn point, if safe to do so.
---@param player_name string
---@return nil
function UniqueSpawnCleanupRemove(player_name)

    -- Assumes we only remove the one primary unique spawn per player.
    local primary_spawn = FindPrimaryUniqueSpawn(player_name)
    if (primary_spawn == nil) then return end -- Safety
    log("UniqueSpawnCleanupRemove - " .. player_name)

    local total_spawn_width = storage.ocfg.spawn_general.spawn_radius_tiles +
                                storage.ocfg.spawn_general.moat_width_tiles

    -- Check if it was near someone else's base. (Really just buddy base is possible I think?)
    nearOtherSpawn = false
    for player_index, spawn in pairs(storage.unique_spawns[primary_spawn.surface_name]) do
        if ((player_index ~= player_name) and
            (util.distance(primary_spawn.position, spawn.position) < (total_spawn_width * 3))) then
            log("Won't remove base as it's close to another spawn: " .. player_index)
            nearOtherSpawn = true
        end
    end

    -- TODO: Possibly limit this based on playtime? If player is on for a long time then don't remove it?
    -- Use regrowth mod to cleanup the area.
    local spawn_position = primary_spawn.position
    if (storage.ocfg.regrowth.enable_abandoned_base_cleanup and (not nearOtherSpawn)) then
        log("Removing base: " .. spawn_position.x .. "," .. spawn_position.y .. " on surface: " .. primary_spawn.surface_name)

        -- Clear an area around the spawn that SHOULD not include any other bases.
        local clear_radius = storage.ocfg.gameplay.minimum_distance_to_existing_chunks - 2 -- Bring in a bit for safety.
        RegrowthMarkAreaForRemoval(primary_spawn.surface_name, spawn_position, clear_radius)
        TriggerCleanup()
        -- Trigger event
        script.raise_event("oarc-mod-on-spawn-remove-request", {spawn_data = primary_spawn})
    end

    storage.unique_spawns[primary_spawn.surface_name][player_name] = nil
end

---Cleans up all references to a player in the global tables.
---@param player_name string
---@return nil
function CleanupPlayerGlobals(player_name)
    -- Clear the buddy pair IF one exists
    if (storage.buddy_pairs[player_name] ~= nil) then
        local buddyName = storage.buddy_pairs[player_name]
        storage.buddy_pairs[player_name] = nil
        storage.buddy_pairs[buddyName] = nil
    end

    -- Transfer or remove a shared spawn if player is owner
    local unique_spawn = FindPrimaryUniqueSpawn(player_name)
    if (unique_spawn ~= nil and #unique_spawn.joiners > 0) then
        local new_owner_name = table.remove(unique_spawn.joiners) -- Get 1 to use as new owner.
        TransferOwnershipOfSharedSpawn(unique_spawn, new_owner_name)
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

    -- Remove them from the delayed spawn queue if they are in it
    for index, delayedSpawn in pairs(storage.delayed_spawns --[[@as OarcDelayedSpawnsTable]]) do
        if (player_name == delayedSpawn.playerName) then
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
---@param spawn OarcUniqueSpawn
---@param new_host_name string
---@return nil
function TransferOwnershipOfSharedSpawn(spawn, new_host_name)

    -- Create a new unique for the new owner based on the old one.
    storage.unique_spawns[spawn.surface_name][new_host_name] = {
        position = spawn.position,
        surface_name = spawn.surface_name,
        primary = spawn.primary,
        moat = spawn.moat,
        host_name = new_host_name,
        joiners = spawn.joiners,
        join_queue = {},
        open_access = false,
        buddy_name = spawn.buddy_name
    }

    -- Update the matching buddy spawn if it exists.
    if (spawn.buddy_name ~= nil) then
        storage.unique_spawns[spawn.surface_name][spawn.buddy_name].buddy_name = new_host_name
    end

    -- Delete the old one
    storage.unique_spawns[spawn.surface_name][spawn.host_name] = nil

    game.players[new_host_name].print({ "oarc-new-owner-msg" })
end

--[[
  _  _  ___  _     ___  ___  ___     ___  _____  _   _  ___  ___
 | || || __|| |   | _ \| __|| _ \   / __||_   _|| | | || __|| __|
 | __ || _| | |__ |  _/| _| |   /   \__ \  | |  | |_| || _| | _|
 |_||_||___||____||_|  |___||_|_\   |___/  |_|   \___/ |_|  |_|

--]]

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

    local surface_spawns
    for surface_index, spawns in pairs(storage.unique_spawns) do
        if (surface_index == surface_name) then
            if (table_size(spawns) == 0) then return nil end -- EXIT - No spawns on requested surface
            surface_spawns = spawns
        end
    end
    if (surface_spawns == nil) then return nil end

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

---Find all players that belong to the same PRIMARY shared spawn as this player, including buddies!
---@param player_name string
---@param include_offline boolean
---@return string[]
function GetPlayersFromSameSpawn(player_name, include_offline)
    local shared_players = {}

    for _, spawns in pairs(storage.unique_spawns) do
        for _,spawn in pairs(spawns) do
            if (not spawn.primary) then goto CONTINUE end

            -- Is the player either the host OR a joiner OR a buddy?
            if (spawn.host_name == player_name) or (TableContains(spawn.joiners, player_name) or (spawn.buddy_name == player_name)) then

                if (include_offline or game.players[spawn.host_name].connected) then
                    table.insert(shared_players, spawn.host_name)
                end

                for _,joiner in pairs(spawn.joiners) do
                    if (include_offline or game.players[joiner].connected) then
                        table.insert(shared_players, joiner)
                    end
                end

                if (spawn.buddy_name ~= nil) then
                    if (include_offline or game.players[spawn.buddy_name].connected) then
                        table.insert(shared_players, spawn.buddy_name)
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

---Sets the custom spawn point for a player. They can have one per surface.
---@param player_name string
---@param surface_name string
---@param position MapPosition
---@param reset_cooldown boolean
---@return nil
function SetPlayerRespawn(player_name, surface_name, position, reset_cooldown)
    ---@type OarcPlayerSpawn
    local updatedPlayerSpawn = {}
    updatedPlayerSpawn.surface = surface_name
    updatedPlayerSpawn.position = position

    storage.player_respawns[player_name][surface_name] = updatedPlayerSpawn


    if (storage.player_cooldowns[player_name].setRespawn == nil) or reset_cooldown then
        storage.player_cooldowns[player_name].setRespawn = game.tick
    end
end

---Creates the storage.unique_spawns entries for a new spawn area.
---@param player_name string
---@param surface_name string
---@param spawn_position MapPosition
---@param moat_enabled boolean
---@param primary boolean
---@param buddy_name string?
---@return nil
function InitUniqueSpawnGlobals(player_name, surface_name, spawn_position, moat_enabled, primary, buddy_name)

    ---@type OarcUniqueSpawn
    local new_unique_spawn = {
        surface_name = surface_name,
        position = spawn_position,
        moat = moat_enabled,
        primary = primary,
        host_name = player_name,
        joiners = {},
        join_queue = {},
        open_access = false,
        buddy_name = buddy_name
    }

    if storage.unique_spawns[surface_name] == nil then
        storage.unique_spawns[surface_name] = {}
    end

    storage.unique_spawns[surface_name][player_name] = new_unique_spawn
end

---Queue a player for a delayed spawn. This will generate the spawn area and move the player there when ready.
---@param player_name string
---@param surface string
---@param spawn_position MapPosition
---@param moat_enabled boolean
---@param primary boolean
---@param buddy_name string?
---@return nil
function QueuePlayerForDelayedSpawn(player_name, surface, spawn_position, moat_enabled, primary, buddy_name)
    -- If we get a valid spawn point, setup the area
    if ((spawn_position.x == 0) and (spawn_position.y == 0)) then
        error("Invalid spawn position for player: " .. player_name .. " on surface: " .. surface)
    end

    InitUniqueSpawnGlobals(player_name, surface, spawn_position, moat_enabled, primary, buddy_name)

    -- Add a 1 chunk buffer to be safe
    local total_spawn_width = storage.ocfg.spawn_general.spawn_radius_tiles +
                                storage.ocfg.spawn_general.moat_width_tiles
    local spawn_chunk_radius = math.ceil(total_spawn_width / CHUNK_SIZE) + 1
    local delay_spawn_seconds = 5 * spawn_chunk_radius

    game.players[player_name].print({ "oarc-generating-spawn-please-wait" })
    game.surfaces[surface].request_to_generate_chunks(spawn_position, spawn_chunk_radius)

    local final_chunk = GetChunkPosFromTilePos(spawn_position)
    final_chunk.x = final_chunk.x + spawn_chunk_radius
    final_chunk.y = final_chunk.y + spawn_chunk_radius

    ---@type OarcDelayedSpawn
    local delayed_spawn = {
        playerName = player_name,
        surface = surface,
        position = spawn_position,
        moat = moat_enabled,
        delayedTick = game.tick + delay_spawn_seconds * TICKS_PER_SECOND,
        final_chunk_generated = final_chunk,
        primary = primary
    }

    table.insert(storage.delayed_spawns, delayed_spawn)

    HideOarcGui(game.players[player_name])
    DisplayPleaseWaitForSpawnDialog(game.players[player_name], delay_spawn_seconds, game.surfaces[surface], spawn_position)

    RegrowthMarkAreaSafeGivenTilePos(surface, spawn_position,
        math.ceil(storage.ocfg.spawn_general.spawn_radius_tiles / CHUNK_SIZE), true)

    -- Chart the area to be able to display the minimap while the player waits.
    ChartArea(game.players[player_name].force,
        delayed_spawn.position,
        spawn_chunk_radius,
        surface
    )
end

---Creates and sends a player to a new secondary spawn, temporarily placing them in the holding pen.
---@param player LuaPlayer
---@param surface LuaSurface
---@return nil
function SecondarySpawn(player, surface)

    -- Ensure we still have their previous spawn choices
    local spawn_choices = storage.spawn_choices[player.name]
    if (spawn_choices == nil) then
        log("ERROR - SecondarySpawn - No spawn choices for player: " .. player.name)
        return
    end

    -- Confirm there is no existing spawn point for this player on this surface
    if (storage.unique_spawns[surface.name] ~= nil and storage.unique_spawns[surface.name][player.name] ~= nil) then
        log("ERROR - SecondarySpawn - Player already has a spawn point on this surface: " .. player.name)
        return
    end

    -- Find a new spawn point
    local spawn_position = FindUngeneratedCoordinates(surface, spawn_choices.distance, 3)
    -- If that fails, just throw a warning and don't spawn them. They can try again.
    if ((spawn_position.x == 0) and (spawn_position.y == 0)) then
        player.print({ "oarc-no-ungenerated-land-error" })
        return
    end

    -- Add new spawn point for the new surface
    SetPlayerRespawn(player.name, surface.name, spawn_position, false) -- Do not reset cooldown
    QueuePlayerForDelayedSpawn(player.name, surface.name, spawn_position, spawn_choices.moat, false, nil)

    -- TODO: Temporary for space age, buddies get a single spawn point for secondary spawns.
    if (spawn_choices.buddy) then
        SetPlayerRespawn(spawn_choices.buddy, surface.name, spawn_position, false)

        -- Add buddy to the shared spawn?
        storage.unique_spawns[surface.name][player.name].joiners = { spawn_choices.buddy }

        log("Buddy secondary spawn NOT IMPLEMENTED YET!")
    end

    -- -- If it is a buddy spawn, we need to setup both areas TOGETHER
    -- if spawn_choices.buddy then
    --     -- The x_offset must be big enough to ensure the spawns DO NOT overlap!
    --     local x_offset = (storage.ocfg.spawn_general.spawn_radius_tiles * 2)
    --     if (spawn_choices.moat) then
    --         x_offset = x_offset + 10
    --     end
    --     local buddy_spawn_position = { x = spawn_position.x + x_offset, y = spawn_position.y }
    --     SetPlayerRespawn(spawn_choices.buddy, spawn_choices.surface, buddy_spawn_position, true)
    -- end

    -- Send them to the holding pen
    SafeTeleport(player, game.surfaces[HOLDING_PEN_SURFACE_NAME], {x=0,y=0})

    -- Announce
    SendBroadcastMsg({"", { "oarc-player-new-secondary", player.name, surface.name }, " ", GetGPStext(surface.name, spawn_position)})
end

-- Check a table to see if there are any players waiting to spawn
-- Check if we are past the delayed tick count
-- Spawn the players and remove them from the table.
---@return nil
function DelayedSpawnOnTick()
    if ((game.tick % (30)) == 1) then
        if ((storage.delayed_spawns ~= nil) and (#storage.delayed_spawns > 0)) then

            -- I think this loop removes from the back of the table to the front??
            for i = #storage.delayed_spawns, 1, -1 do
                delayedSpawn = storage.delayed_spawns[i] --[[@as OarcDelayedSpawn]]

                local surface = game.surfaces[delayedSpawn.surface]
                
                if ((delayedSpawn.delayedTick < game.tick) or surface.is_chunk_generated(delayedSpawn.final_chunk_generated) ) then
                    if (game.players[delayedSpawn.playerName] ~= nil) then
                        SendPlayerToNewSpawnAndCreateIt(delayedSpawn)
                    end
                    table.remove(storage.delayed_spawns, i)
                end
            end
        end
    end
end

---Send player to their custom spawn point
---@param surface_name string
---@param player LuaPlayer
---@param first_spawn boolean
---@return nil
function SendPlayerToSpawn(surface_name, player, first_spawn)
    local spawn = storage.player_respawns[player.name][surface_name]

    if (spawn == nil) then
        log("ERROR - SendPlayerToSpawn - No spawn point for player: " .. player.name .. " on surface: " .. surface_name .. " first_spawn: " .. tostring(first_spawn))
        return
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
        if (delayedSpawn.playerName == player_name) then
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

--[[
  ___  ___   ___   ___  ___     ___  ___  ___  ___  ___  ___  ___  ___
 | __|/ _ \ | _ \ / __|| __|   / __|| _ \| __|/ __||_ _|| __||_ _|/ __|
 | _|| (_) ||   /| (__ | _|    \__ \|  _/| _|| (__  | | | _|  | || (__
 |_|  \___/ |_|_\ \___||___|   |___/|_|  |___|\___||___||_|  |___|\___|

--]]


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
        return game.forces[storage.ocfg.gameplay.main_force_name]
    end

    return new_force
end

---Create a new player force and assign the player to it.
---@param player LuaPlayer
---@return LuaForce
function CreatePlayerCustomForce(player)
    local newForce = CreatePlayerForce(player.name)
    player.force = newForce

    if (newForce.name == player.name) then
        SendBroadcastMsg({ "oarc-player-started-own-team", player.name })
    else
        player.print({ "oarc-player-no-new-teams-sorry" })
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

---@enum SpawnTeamChoice
SPAWN_TEAM_CHOICE = {
    join_main_team = 1,
    join_own_team = 2,
    -- join_buddy_team = 3, -- Removed in favor of separate override
}

---Contains the respawn point for a player. Usually this is their home base but it can be changed.
---@alias OarcPlayerSpawn { surface: string, position: MapPosition }
---Table of [OarcSharedSpawn](lua://OarcSharedSpawn) indexed by player name and then by surface name.
---@alias OarcPlayerRespawnsTable table<string, table<string, OarcPlayerSpawn>>

---Class for unique spawn point
---@class OarcUniqueSpawn
---@field surface_name string The surface on which the spawn is located.
---@field position MapPosition The position of the spawn on that surface.
---@field primary boolean Whether this is the primary spawn point for a player, this is the first surface they spawn on. All other spawns are secondary.
---@field moat boolean Whether the spawn has a moat or not.
---@field open_access boolean Whether the spawn is open for other players to join.
---@field host_name string The player name of the host of this spawn.
---@field join_queue string[] List of players waiting to join this spawn.
---@field joiners string[] List of players who have joined this spawn NOT including the host.
---@field buddy_name string? The other buddy player name if this is a buddy spawn.

---Table of [OarcUniqueSpawnClass](lua://OarcUniqueSpawnClass) indexed first by surface name and then by player name.
---@alias OarcUniqueSpawnsTable table<string, table<string, OarcUniqueSpawn>>

---Contains player ability cooldowns. Right now this only tracks changing the respawn ability.
---@alias OarcPlayerCooldown { setRespawn: number }
---Table of [OarcPlayerCooldown](lua://OarcPlayerCooldown) indexed by player name.
---@alias OarcPlayerCooldownsTable table<string, OarcPlayerCooldown>

---Temporary data used when spawning a player. Player needs to wait while the area is prepared.
---Temporary data used when spawning a player. Player needs to wait while the area is prepared.
---@class OarcDelayedSpawn
---@field surface string The surface on which the player will spawn.
---@field playerName string The name of the player.
---@field position MapPosition The position where the player will spawn.
---@field moat boolean Whether the spawn has a moat or not.
---@field delayedTick number The game tick when the spawn will be ready.
---@field final_chunk_generated ChunkPosition The final chunk position that needs to be generated.
---@field primary boolean Whether this is the primary spawn point for a player, this is the first surface they spawn on. All other spawns are secondary.
---Table of [OarcDelayedSpawn](lua://OarcDelayedSpawn) indexed by player name.
---@alias OarcDelayedSpawnsTable table<string, OarcDelayedSpawn>

---This contains the spawn choices for a player in the spawn menu.
---Class representing the spawn choices for a player in the spawn menu.
---@class OarcSpawnChoices
---@field surface string The surface on which the player wants to spawn.
---@field team SpawnTeamChoice The team choice for the player. Main team or own team.
---@field moat boolean Whether the player wants a moat around their spawn.
---@field buddy string? The buddy player name if the player wants to spawn with a buddy.
---@field distance integer The distance from the center of the map where the player wants to spawn.
---@field host string? The host player name if the player wants to join a shared spawn.
---@field buddy_team boolean Whether the player wants to join a buddy's team. This means both players will be on the same team.

---Table of [OarcSpawnChoices](lua://OarcSpawnChoices) indexed by player name.
---@alias OarcSpawnChoicesTable table<string, OarcSpawnChoices>

---Primary means a player can spawn for the first time on this surface, secondary they can land here and also receive a custom spawn area.
---@alias OarcSurfaceSpawnSetting { primary: boolean, secondary: boolean}
