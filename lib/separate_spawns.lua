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
DESTROYED_FORCE_NAME = "_DESTROYED_"

---Initializes the globals used to track the special spawn and player status information.
---@return nil
function InitSpawnGlobalsAndForces()

    -- Contains a table of entries for each surface. This tracks which surfaces allow spawning?
    --[[@type table<string, boolean>]]
    global.oarc_surfaces = {}
    for _, surface in pairs(game.surfaces) do
        SeparateSpawnsInitSurface(surface.name)
    end

    -- This contains each player's respawn point. Literally where they will respawn on death
    -- There is a way in game to change this under one of the little menu features I added. This allows players to
    -- change their respawn point to something other than their home base.
    -- TODO: Space Age will potentially affect this, as I may need to allow for multiple respawn points on different surfaces.
    --[[@type OarcPlayerRespawnsTable]]
    global.player_respawns = {}

    -- This is the most important table. It is a list of all the unique spawn points.
    -- This is what chunk generation checks against, and is used for shared spawn tracking, and more.
    ---@type OarcUniqueSpawnsTable
    global.unique_spawns = {}

    -- Each player has an option to change their respawn which has a cooldown when used.
    -- Other similar abilities/functions that require cooldowns could be added here.
    --[[@type OarcPlayerCooldownsTable]]
    global.player_cooldowns = {}

    -- Players who have made a spawn choice get put into this list while waiting.
    -- An on_tick event checks when it expires and then places down the base resources, and teleports the player.
    -- Go look at DelayedSpawnOnTick() for more info.
    --[[@type OarcDelayedSpawnsTable]]
    global.delayed_spawns = {}

    -- This stores the spawn choices that a player makes from the GUI interactions.
    -- Intended to be re-used for secondary spawns! (TODO SPACE AGE)
    --[[@type OarcSpawnChoicesTable]]
    global.spawn_choices = {}

    -- Buddy info: The only real use is to check if one of a buddy pair is online to see if we should allow enemy
    -- attacks on the base.  <br>
    -- global.buddy_pairs[player.name] = requesterName  <br>
    -- global.buddy_pairs[requesterName] = player.name  <br>
    --[[@type table<string, string>]]
    global.buddy_pairs = {}

    --- Table contains all the renders that need to be faded out over time in the on_tick event. They are removed when they expire.
    --[[@type table<integer>]]
    global.oarc_renders_fadeout = {}

    -- Special forces for when players with their own force want a reset.
    game.create_force(ABANDONED_FORCE_NAME)
    game.create_force(DESTROYED_FORCE_NAME)

    -- Name a new force to be the default force.
    -- This is what any new player is assigned to when they join, even before they spawn.
    local main_force = CreatePlayerForce(global.ocfg.gameplay.main_force_name)
    main_force.set_spawn_position({ x = 0, y = 0 }, global.ocfg.gameplay.default_surface)

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
    -- holding_pen_group.set_allows_action(defines.input_action.write_to_console, true)

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
    if (global.oarc_surfaces == nil) then
        error("global.oarc_surfaces not initialized yet?! " .. surface_name)
    end

    if IsSurfaceBlacklisted(surface_name) then return end

    -- Add the surface to the list of surfaces that allow spawns with value from config.
    if global.ocfg.gameplay.default_allow_spawning_on_other_surfaces then
        global.oarc_surfaces[surface_name] = true

    -- Otherwise only allow the default surface (by default)
    else
        global.oarc_surfaces[surface_name] = (surface_name == global.ocfg.gameplay.default_surface)
    end

    -- Make sure it has a surface configuration entry
    if (global.oarc_surfaces[surface_name] and global.ocfg.surfaces_config[surface_name] == nil) then
        log("Surface does NOT have a config entry, defaulting to nauvis entry for new surface: " .. surface_name)
        global.ocfg.surfaces_config[surface_name] = global.ocfg.surfaces_config["nauvis"]
    end
end

---Detects when surfaces are deleted and removes them from the list of surfaces that allow spawns.
---@param event EventData.on_pre_surface_deleted
---@return nil
function SeparateSpawnsSurfaceDeleted(event)
    local surface_name = game.surfaces[event.surface_index].name
    log("WARNING!! - Surface deleted event not validated/implemented yet! " .. surface_name)

    -- Remove the surface from the list of surfaces that allow spawns
    global.oarc_surfaces[surface_name] = nil
    -- TODO: Validate if we need to do other cleanup too, like unique spawns, etc. I can't
    -- think of a reason why we would need to do that yet.
end

--[[
  ___  _       _ __   __ ___  ___     ___  ___  ___  ___  ___  ___  ___  ___
 | _ \| |     /_\\ \ / /| __|| _ \   / __|| _ \| __|/ __||_ _|| __||_ _|/ __|
 |  _/| |__  / _ \\ V / | _| |   /   \__ \|  _/| _|| (__  | | | _|  | || (__
 |_|  |____|/_/ \_\|_|  |___||_|_\   |___/|_|  |___|\___||___||_|  |___|\___|

--]]

-- When a player is newly created or just reset, present the spawn options to them.
-- If new player, assign them to the main force so they can communicate with the team without shouting (/s).
-- TODO: Possibly change this to a holding_pen force?
---@param player_index integer|string
---@return nil
function SeparateSpawnsInitPlayer(player_index)
    local player = game.players[player_index]

    SafeTeleport(player, game.surfaces[HOLDING_PEN_SURFACE_NAME], { x = 0, y = 0 })

    player.force = global.ocfg.gameplay.main_force_name -- Put them on the main force.

    if (not player.admin) then
        player.permission_group = game.permissions.get_group("holding_pen")
    end

    if (global.player_respawns[player.name] == nil) then
        global.player_respawns[player.name] = {}
    end
    if (global.player_cooldowns[player.name] == nil) then
        global.player_cooldowns[player.name] = { setRespawn = game.tick }
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
    local surface_name = player.surface.name

    -- It's possible if player is dead, and then resets, we don't want to do anything else.
    if (player.surface.name == HOLDING_PEN_SURFACE_NAME) then return end

    SendPlayerToSpawn(surface_name, player)
    GivePlayerRespawnItems(player)
end

---If the player leaves early, remove their base.
---@param event EventData.on_player_left_game
---@return nil
function SeparateSpawnsPlayerLeft(event)
    local player = game.players[event.player_index]

    -- If players leave early, say goodbye.
    if (player and (player.online_time < (global.ocfg.gameplay.minimum_online_time * TICKS_PER_MINUTE))) then
        SendBroadcastMsg({ "oarc-player-left-early", player.name, global.ocfg.gameplay.minimum_online_time })
        RemoveOrResetPlayer(player, true)
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
---@param position TilePosition
---@return nil
function GenerateStartingResources(surface, position)
    local rand_settings = global.ocfg.surfaces_config[surface.name].spawn_config.resource_rand_pos_settings

    -- Generate all resource tile patches
    if (not rand_settings.enabled) then
        for r_name, r_data in pairs(global.ocfg.surfaces_config[surface.name].spawn_config.solid_resources --[[@as table<string, OarcConfigSolidResource>]]) do
            local pos = { x = position.x + r_data.x_offset, y = position.y + r_data.y_offset }
            GenerateResourcePatch(surface, r_name, r_data.size, pos, r_data.amount)
        end

        -- Generate resources in random order around the spawn point. Tweak in config.lua
    else
        -- Create list of resource tiles
        ---@type table<string>
        local r_list = {}
        for r_name, _ in pairs(global.ocfg.surfaces_config[surface.name].spawn_config.solid_resources --[[@as table<string, OarcConfigSolidResource>]]) do
            if (r_name ~= "") then
                table.insert(r_list, r_name)
            end
        end
        ---@type table<string>
        local shuffled_list = FYShuffle(r_list)

        -- This places resources in a semi-circle
        local angle_offset = rand_settings.angle_offset
        local num_resources = TableLength(global.ocfg.surfaces_config[surface.name].spawn_config.solid_resources)
        local theta = ((rand_settings.angle_final - rand_settings.angle_offset) / num_resources);
        local count = 0

        for _, r_name in pairs(shuffled_list) do
            local angle = (theta * count) + angle_offset;

            local tx = (rand_settings.radius * math.cos(angle)) + position.x
            local ty = (rand_settings.radius * math.sin(angle)) + position.y

            local pos = { x = math.floor(tx), y = math.floor(ty) }

            local resourceConfig = global.ocfg.surfaces_config[surface.name].spawn_config.solid_resources[r_name]
            GenerateResourcePatch(surface, r_name, resourceConfig.size, pos, resourceConfig.amount)
            count = count + 1
        end
    end

    -- Generate special fluid resource patches (oil)
    for r_name, r_data in pairs(global.ocfg.surfaces_config[surface.name].spawn_config.fluid_resources --[[@as table<string, OarcConfigFluidResource>]]) do
        local oil_patch_x = position.x + r_data.x_offset_start
        local oil_patch_y = position.y + r_data.y_offset_start
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

---Sends the player to their spawn point
---@param delayed_spawn OarcDelayedSpawn
---@return nil
function SendPlayerToNewSpawnAndCreateIt(delayed_spawn)
    local ocfg --[[@as OarcConfig]] = global.ocfg

    -- DOUBLE CHECK and make sure the area is super safe.
    ClearNearbyEnemies(delayed_spawn.position, ocfg.surfaces_config[delayed_spawn.surface].spawn_config.safe_area.safe_radius,
        game.surfaces[delayed_spawn.surface])

    -- Generate water strip only if we don't have a moat.
    if (not delayed_spawn.moat) then
        local water_data = ocfg.surfaces_config[delayed_spawn.surface].spawn_config.water
        CreateWaterStrip(game.surfaces[delayed_spawn.surface],
            { x = delayed_spawn.position.x + water_data.x_offset, y = delayed_spawn.position.y + water_data.y_offset },
            water_data.length)
        CreateWaterStrip(game.surfaces[delayed_spawn.surface],
            { x = delayed_spawn.position.x + water_data.x_offset, y = delayed_spawn.position.y + water_data.y_offset + 1 },
            water_data.length)
    end

    -- Create the spawn resources here
    GenerateStartingResources(game.surfaces[delayed_spawn.surface], delayed_spawn.position)

    -- Send the player to that position
    local player = game.players[delayed_spawn.playerName]
    SendPlayerToSpawn(delayed_spawn.surface, player)
    GivePlayerStarterItems(player)

    -- Render some welcoming text...
    DisplayWelcomeGroundTextAtSpawn(player, delayed_spawn.surface, delayed_spawn.position)

    -- Chart the area.
    ChartArea(player.force, delayed_spawn.position, math.ceil(ocfg.surfaces_config[delayed_spawn.surface].spawn_config.general.spawn_radius_tiles / CHUNK_SIZE),
        player.surface)

    if (player.gui.screen.wait_for_spawn_dialog ~= nil) then
        player.gui.screen.wait_for_spawn_dialog.destroy()
    end

    if (ocfg.surfaces_config[delayed_spawn.surface].starting_items.crashed_ship) then
        crash_site.create_crash_site(game.surfaces[delayed_spawn.surface],
            { x = delayed_spawn.position.x + 15, y = delayed_spawn.position.y - 25 },
            ocfg.surfaces_config[delayed_spawn.surface].starting_items.crashed_ship_resources,
            ocfg.surfaces_config[delayed_spawn.surface].starting_items.crashed_ship_wreakage)
    end
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
    local rid1 = rendering.draw_text { text = "Welcome",
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
    local rid2 = rendering.draw_text { text = "Home",
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

    table.insert(global.oarc_renders_fadeout, rid1)
    table.insert(global.oarc_renders_fadeout, rid2)
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

    local spawn_config --[[@as OarcConfigSpawn]] = global.ocfg.surfaces_config[surface.name].spawn_config
    local chunkAreaCenter = {
        x = chunkArea.left_top.x + (CHUNK_SIZE / 2),
        y = chunkArea.left_top.y + (CHUNK_SIZE / 2)
    }

    -- Make chunks near a spawn safe by removing enemies
    -- TODO: Space Age will change this!
    if (util.distance(closest_spawn.position, chunkAreaCenter) < spawn_config.safe_area.safe_radius) then
        RemoveEnemiesInArea(surface, chunkArea)

        -- Create a warning area with heavily reduced enemies
    elseif (util.distance(closest_spawn.position, chunkAreaCenter) < spawn_config.safe_area.warn_radius) then
        ReduceEnemiesInArea(surface, chunkArea, spawn_config.safe_area.warn_reduction)
        -- DowngradeWormsInArea(surface, chunkArea, 100, 100, 100)
        RemoveWormsInArea(surface, chunkArea, false, true, true, true) -- remove all non-small worms.

        -- Create a third area with moderately reduced enemies
    elseif (util.distance(closest_spawn.position, chunkAreaCenter) < spawn_config.safe_area.danger_radius) then
        ReduceEnemiesInArea(surface, chunkArea, spawn_config.safe_area.danger_reduction)
        -- DowngradeWormsInArea(surface, chunkArea, 50, 100, 100)
        RemoveWormsInArea(surface, chunkArea, false, false, true, true) -- remove all huge/behemoth worms.
    end

    -- If there is a buddy spawn, we need to setup both areas TOGETHER so they overlap.
    local spawns = { closest_spawn }
    if (closest_spawn.buddy_name ~= nil) then
        table.insert(spawns, global.unique_spawns[closest_spawn.surface_name][closest_spawn.buddy_name])
    end

    -- This will typically just contain the one spawn point, but if there is a buddy spawn, it will contain both.
    for _, spawn in pairs(spawns) do
        -- If the chunk is within the main land area, then clear trees/resources and create the land spawn areas
        -- (guaranteed land with a circle of trees)
        local landArea = GetAreaAroundPos(spawn.position, spawn_config.general.spawn_radius_tiles + CHUNK_SIZE)
        if not CheckIfInArea(chunkAreaCenter, landArea) then 
            goto CONTINUE
        end

        -- Remove trees/resources inside the spawn area
        RemoveInCircle(surface, chunkArea, "tree", spawn.position, spawn_config.general.spawn_radius_tiles)
        RemoveInCircle(surface, chunkArea, "resource", spawn.position, spawn_config.general.spawn_radius_tiles + 5)
        RemoveInCircle(surface, chunkArea, "cliff", spawn.position, spawn_config.general.spawn_radius_tiles + 5)

        -- Fill in the spawn area with landfill and create a circle of trees around it.
        local fill_tile = "landfill"
        if (spawn_config.general.tree_circle) then
            CreateCropCircle(surface, spawn.position, chunkArea, spawn_config.general.spawn_radius_tiles, fill_tile)
        end
        if (spawn_config.general.tree_octagon) then
            CreateCropOctagon(surface, spawn.position, chunkArea, spawn_config.general.spawn_radius_tiles, fill_tile)
        end

        if (spawn.moat) then
            CreateMoat(surface,
                spawn.position,
                chunkArea,
                spawn_config.general.spawn_radius_tiles,
                "water",
                global.ocfg.gameplay.enable_moat_bridging)
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
    -- if (not global.oarc_surfaces[surface.name]) then return end

    -- Helps scale worm sizes to not be unreasonable when far from the origin.
    -- TODO: Space Age will change this!
    if global.ocfg.gameplay.modified_enemy_spawning then
        DowngradeWormsDistanceBasedOnChunkGenerate(event)
    end

    -- Downgrade resources near to spawns
    -- TODO: Space Age will change this!
    if global.ocfg.gameplay.scale_resources_around_spawns then
        DowngradeResourcesDistanceBasedOnChunkGenerate(surface, chunkArea)
    end

    -- This handles chunk generation near player spawns
    -- If it is near a player spawn, it does a few things like make the area
    -- safe and provide a guaranteed area of land and water tiles.
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
    local modifier = (distance / (global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.danger_radius * 1)) ^ 3
    if modifier < 0.1 then modifier = 0.1 end
    if modifier > 1 then return end

    local ore_per_tile_cap = math.floor(100000 * modifier)

    for _, entity in pairs(surface.find_entities_filtered { area = chunkArea, type = "resource" }) do
        if entity.valid and entity and entity.position and entity.amount then
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

-- I wrote this to ensure everyone gets safer spawns regardless of evolution level.
-- This is intended to downgrade any biters/spitters spawning near player bases.
-- I'm not sure the performance impact of this but I'm hoping it's not bad.
---@param event EventData.on_entity_spawned|EventData.on_biter_base_built
---@return nil
function ModifyEnemySpawnsNearPlayerStartingAreas(event)
    if (not event.entity or not (event.entity.force.name == "enemy") or not event.entity.position) then
        log("ModifyBiterSpawns - Unexpected use.")
        return
    end

    local enemy_pos = event.entity.position
    local surface = event.entity.surface
    local enemy_name = event.entity.name

    local closest_spawn = GetClosestUniqueSpawn(surface.name, enemy_pos)

    if (closest_spawn == nil) then
        -- log("GetClosestUniqueSpawn ERROR - None found?")
        return
    end

    -- No enemies inside safe radius!
    if (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.safe_radius) then
        event.entity.destroy()

        -- Warn distance is all SMALL only.
    elseif (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.warn_radius) then
        if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter") or (enemy_name == "medium-biter")) then
            event.entity.destroy()
            surface.create_entity { name = "small-biter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded biter close to spawn.")
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter") or (enemy_name == "medium-spitter")) then
            event.entity.destroy()
            surface.create_entity { name = "small-spitter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded spitter close to spawn.")
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret") or (enemy_name == "medium-worm-turret")) then
            event.entity.destroy()
            surface.create_entity { name = "small-worm-turret", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded worm close to spawn.")
        end

        -- Danger distance is MEDIUM max.
    elseif (util.distance(enemy_pos, closest_spawn.position) < global.ocfg.surfaces_config[surface.name].spawn_config.safe_area.danger_radius) then
        if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-biter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded biter further from spawn.")
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-spitter", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded spitter further from spawn
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret")) then
            event.entity.destroy()
            surface.create_entity { name = "medium-worm-turret", position = enemy_pos, force = game.forces.enemy }
            -- log("Downgraded worm further from spawn.")
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

--     player.force = global.ocfg.gameplay.main_force_name

--     if ((#player_old_force.players == 0) and (player_old_force.name ~= global.ocfg.gameplay.main_force_name)) then
--         SendBroadcastMsg("Team " ..
--             player_old_force.name .. " has been destroyed! All buildings will slowly be destroyed now.") --TODO: localize
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

--     player.force = global.ocfg.gameplay.main_force_name

--     if ((#player_old_force.players == 0) and (player_old_force.name ~= global.ocfg.gameplay.main_force_name)) then
--         SendBroadcastMsg("Team " .. player_old_force.name .. " has been abandoned!") --TODO: localize
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
    if (player.online_time < (global.ocfg.gameplay.minimum_online_time * TICKS_PER_MINUTE)) then
        RemovePlayerStarterItems(player)
    end

    -- If this player is staying in the game, lets make sure we don't delete them along with the map chunks being
    -- cleared.
    player.teleport({x=0,y=0}, HOLDING_PEN_SURFACE_NAME)
    local player_old_force = player.force
    player.force = global.ocfg.gameplay.main_force_name

    -- Clear globals
    CleanupPlayerGlobals(player.name) -- This cleans global.unique_spawns IF we are transferring ownership.

    -- Safely clear the unique spawn IF it is still valid.
    UniqueSpawnCleanupRemove(player.name) -- Specifically global.unique_spawns

    -- Remove a force if this player created it and they are the only one on it
    if ((#player_old_force.players == 0) and (player_old_force.name ~= global.ocfg.gameplay.main_force_name)) then
        log("RemoveOrResetPlayer - FORCE REMOVED: " .. player_old_force.name)
        game.merge_forces(player_old_force, "neutral")
    end

    -- Remove the character completely
    if (remove_player) then
        game.remove_offline_players({ player })
    end
end

---Searches all unique spawns for the primary one for a player.
---@param player_name string
---@return OarcUniqueSpawn?
function FindPrimaryUniqueSpawn(player_name)
    for _,spawns in pairs(global.unique_spawns) do
        if (spawns[player_name] ~= nil and spawns[player_name].primary) then
            return spawns[player_name]
        end
    end
end

---Cleans up a player's unique spawn point, if safe to do so.
---@param player_name string
---@return nil
function UniqueSpawnCleanupRemove(player_name)

    -- Assumes we only remove the one primary unique spawn per player.
    local primary_spawn = FindPrimaryUniqueSpawn(player_name)
    if (primary_spawn == nil) then return end -- Safety
    log("UniqueSpawnCleanupRemove - " .. player_name)

    local spawn_radius_tiles = global.ocfg.surfaces_config[primary_spawn.surface_name].spawn_config.general.spawn_radius_tiles

    -- Check if it was near someone else's base. (Really just buddy base is possible I think?)
    nearOtherSpawn = false
    for player_index, spawn in pairs(global.unique_spawns[primary_spawn.surface_name]) do
        if ((player_index ~= player_name) and
            (util.distance(primary_spawn.position, spawn.position) < (spawn_radius_tiles * 3))) then
            log("Won't remove base as it's close to another spawn: " .. player_index)
            nearOtherSpawn = true
        end
    end

    -- Use regrowth mod to cleanup the area.
    local spawn_position = primary_spawn.position
    if (global.ocfg.regrowth.enable_abandoned_base_cleanup and (not nearOtherSpawn)) then
        log("Removing base: " .. spawn_position.x .. "," .. spawn_position.y .. " on surface: " .. primary_spawn.surface_name)
        RegrowthMarkAreaForRemoval(primary_spawn.surface_name, spawn_position, math.ceil(spawn_radius_tiles / CHUNK_SIZE))
        TriggerCleanup()
    end

    global.unique_spawns[primary_spawn.surface_name][player_name] = nil
end

---Cleans up all references to a player in the global tables.
---@param player_name string
---@return nil
function CleanupPlayerGlobals(player_name)
    -- Clear the buddy pair IF one exists
    if (global.buddy_pairs[player_name] ~= nil) then
        local buddyName = global.buddy_pairs[player_name]
        global.buddy_pairs[player_name] = nil
        global.buddy_pairs[buddyName] = nil
    end

    -- Transfer or remove a shared spawn if player is owner
    local unique_spawn = FindPrimaryUniqueSpawn(player_name)
    if (unique_spawn ~= nil and #unique_spawn.joiners > 0) then
        local new_owner_name = table.remove(unique_spawn.joiners) -- Get 1 to use as new owner.
        TransferOwnershipOfSharedSpawn(unique_spawn, new_owner_name)
        SendBroadcastMsg( {"oarc-host-left-new-host", player_name, new_owner_name})
    end

    -- Check all other shared spawns too in case they joined one.
    for surface_index, spawns in pairs(global.unique_spawns) do
        for player_index, spawn in pairs(spawns) do
            for index, joiner in pairs(spawn.joiners) do
                if (player_name == joiner) then
                    global.unique_spawns[surface_index][player_index].joiners[index] = nil
                    goto LOOP_BREAK -- Nest loop break. Assumes only one entry per player is possible.
                end
            end
        end
    end
    ::LOOP_BREAK::

    -- Clear their personal spawn point info
    if (global.player_respawns[player_name] ~= nil) then
        global.player_respawns[player_name] = nil
    end

    -- Remove them from the delayed spawn queue if they are in it
    for index, delayedSpawn in pairs(global.delayed_spawns --[[@as OarcDelayedSpawnsTable]]) do
        if (player_name == delayedSpawn.playerName) then
            global.delayed_spawns[index] = nil
            log("Removing player from delayed spawn queue: " .. player_name)
            break
        end
    end

    -- Remove them from any join queues they may be in:
    RemovePlayerFromJoinQueue(player_name)

    if (global.player_cooldowns[player_name] ~= nil) then
        global.player_cooldowns[player_name] = nil
    end
end

---Transfers ownership of a shared spawn to another player.
---@param spawn OarcUniqueSpawn
---@param new_host_name string
---@return nil
function TransferOwnershipOfSharedSpawn(spawn, new_host_name)

    -- Create a new unique for the new owner based on the old one.
    global.unique_spawns[spawn.surface_name][new_host_name] = {
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
        global.unique_spawns[spawn.surface_name][spawn.buddy_name].buddy_name = new_host_name
    end

    -- Delete the old one
    global.unique_spawns[spawn.surface_name][spawn.host_name] = nil

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

    for surface_index, spawns in pairs(global.unique_spawns) do
        for player_index, spawn in pairs(spawns) do
            for index, requestor in pairs(spawn.join_queue) do
                if (requestor == player_name) then
                    global.unique_spawns[surface_index][player_index].join_queue[index] = nil

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

---Same as GetClosestPosFromTable but specific to global.unique_spawns
---@param surface_name string
---@param pos MapPosition
---@return OarcUniqueSpawn?
function GetClosestUniqueSpawn(surface_name, pos)

    local surface_spawns
    for surface_index, spawns in pairs(global.unique_spawns) do
        if (surface_index == surface_name) then
            if (TableLength(spawns) == 0) then return nil end -- EXIT - No spawns on requested surface
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

    for _, spawns in pairs(global.unique_spawns) do
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

                break -- We only need to find one match.
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
    local spawn = global.unique_spawns[surface_name][owner_name]

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

    for surface_index, spawns in pairs(global.unique_spawns) do
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
    if (global.unique_spawns[surface_name] == nil) or (global.unique_spawns[surface_name][owner_name] == nil) then
        return false
    end

    local spawn = global.unique_spawns[surface_name][owner_name]

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
    if (global.unique_spawns[surface_name][owner_name] == nil) then return true end

    -- Technically I only limit the players based on if they are online, so you can exceed the limit if players join
    -- while others are offline. This is a feature, not a bug?
    return (GetOnlinePlayersAtSharedSpawn(surface_name, owner_name) >= global.ocfg.gameplay.number_of_players_per_shared_spawn)
end

-- ---Checks if player has a custom spawn point set.
-- ---@param player LuaPlayer
-- ---@return boolean
-- function DoesPlayerHaveCustomSpawn(player)
--     for name,_ in pairs(global.player_respawns --[[@as OarcPlayerRespawnsTable]]) do
--         if (player.name == name) then
--             return true
--         end
--     end
--     return false
-- end

-- ---Gets the custom spawn point for a player if they have one.
-- ---@param player LuaPlayer
-- ---@return OarcPlayerSpawn?
-- function GetPlayerCustomSpawn(player)
--     for name, player_spawn in pairs(global.player_respawns --[[@as OarcPlayerRespawnsTable]]) do
--         if (player.name == name) then
--             return player_spawn
--         end
--     end
--     return nil
-- end

---Sets the custom spawn point for a player.
---@param player_name string
---@param surface_name string
---@param position MapPosition
---@return nil
function ChangePlayerRespawn(player_name, surface_name, position)
    ---@type OarcPlayerSpawn
    local updatedPlayerSpawn = {}
    updatedPlayerSpawn.surface = surface_name
    updatedPlayerSpawn.position = position

    global.player_respawns[player_name][surface_name] = updatedPlayerSpawn
    global.player_cooldowns[player_name] = { setRespawn = game.tick }
end

---Creates the global.unique_spawns entries for a new spawn area.
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

    if global.unique_spawns[surface_name] == nil then
        global.unique_spawns[surface_name] = {}
    end

    global.unique_spawns[surface_name][player_name] = new_unique_spawn
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
    local spawn_chunk_radius = math.ceil(global.ocfg.surfaces_config[surface].spawn_config.general.spawn_radius_tiles / CHUNK_SIZE) + 1
    local delay_spawn_seconds = 5 * spawn_chunk_radius

    game.players[player_name].print({ "oarc-generating-spawn-please-wait" })
    game.surfaces[surface].request_to_generate_chunks(spawn_position, spawn_chunk_radius)

    local final_chunk = GetChunkPosFromTilePos(spawn_position)
    final_chunk.x = final_chunk.x + spawn_chunk_radius
    final_chunk.y = final_chunk.y + spawn_chunk_radius

    ---@type OarcDelayedSpawn
    local delayedSpawn = {}
    delayedSpawn.playerName = player_name
    delayedSpawn.surface = surface
    delayedSpawn.position = spawn_position
    delayedSpawn.moat = moat_enabled
    delayedSpawn.delayedTick = game.tick + delay_spawn_seconds * TICKS_PER_SECOND
    delayedSpawn.final_chunk_generated = final_chunk

    table.insert(global.delayed_spawns, delayedSpawn)

    HideOarcGui(game.players[player_name])
    DisplayPleaseWaitForSpawnDialog(game.players[player_name], delay_spawn_seconds, game.surfaces[surface], spawn_position)

    RegrowthMarkAreaSafeGivenTilePos(surface, spawn_position,
        math.ceil(global.ocfg.surfaces_config[surface].spawn_config.general.spawn_radius_tiles / CHUNK_SIZE), true)

    -- Chart the area to be able to display the minimap while the player waits.
    ChartArea(game.players[player_name].force,
        delayedSpawn.position,
        spawn_chunk_radius,
        surface
    )
end

-- Check a table to see if there are any players waiting to spawn
-- Check if we are past the delayed tick count
-- Spawn the players and remove them from the table.
---@return nil
function DelayedSpawnOnTick()
    if ((game.tick % (30)) == 1) then
        if ((global.delayed_spawns ~= nil) and (#global.delayed_spawns > 0)) then

            -- I think this loop removes from the back of the table to the front??
            for i = #global.delayed_spawns, 1, -1 do
                delayedSpawn = global.delayed_spawns[i] --[[@as OarcDelayedSpawn]]

                local surface = game.surfaces[delayedSpawn.surface]
                
                if ((delayedSpawn.delayedTick < game.tick) or surface.is_chunk_generated(delayedSpawn.final_chunk_generated) ) then
                    if (game.players[delayedSpawn.playerName] ~= nil) then
                        SendPlayerToNewSpawnAndCreateIt(delayedSpawn)
                    end
                    table.remove(global.delayed_spawns, i)
                end
            end
        end
    end
end

---Send player to their custom spawn point
---@param surface_name string
---@param player LuaPlayer
---@return nil
function SendPlayerToSpawn(surface_name, player)
    local spawn = global.player_respawns[player.name][surface_name]
    SafeTeleport(player, game.surfaces[surface_name], spawn.position)
    player.permission_group = game.permissions.get_group("default")
end

-- ---Send player to a random spawn point.
-- ---@param player LuaPlayer
-- ---@return nil
-- function SendPlayerToRandomSpawn(player)
--     local numSpawns = #global.oc--ore.unique--Spawns
--     local rndSpawn = math.random(0, numSpawns)
--     local counter = 0

--     if (rndSpawn == 0) then
--         local gameplayConfig = global.ocfg.gameplay --[[@as OarcConfigGameplaySettings]]
--         player.teleport(
--         game.forces[gameplayConfig.main_force_name].get_spawn_position(gameplayConfig.default_surface),
--             gameplayConfig.default_surface)
--     else
--         counter = counter + 1
--         for name, spawn in pairs(global.oc--ore.unique--Spawns --[[@as OarcUnique--SpawnsTable]]) do
--             if (counter == rndSpawn) then
--                 player.teleport(spawn.position)
--                 break
--             end
--             counter = counter + 1
--         end
--     end
-- end

---Check if a player has a delayed spawn
---@param player_name string
---@return boolean
function PlayerHasDelayedSpawn(player_name)
    for _,delayedSpawn in pairs(global.delayed_spawns --[[@as OarcDelayedSpawnsTable]]) do
        if (delayedSpawn.playerName == player_name) then
            return true
        end
    end
    return false
end

---Get the list of surfaces that are allowed for spawning.
---@return string[]
function GetAllowedSurfaces()
    ---@type string[]
    local surfaceList = {}
    for surfaceName,allowed in pairs(global.oarc_surfaces --[[@as table<string, boolean>]]) do
        if allowed then
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
    local newForce = nil

    -- Check if force already exists
    if (game.forces[force_name] ~= nil) then
        log("Force already exists!")
        return CreatePlayerForce(force_name .. "_") -- Append a character to make the force name unique.

        -- Create a new force
    elseif (#game.forces < MAX_FORCES) then
        newForce = game.create_force(force_name)
        newForce.share_chart = global.ocfg.gameplay.enable_shared_team_vision
        newForce.friendly_fire = global.ocfg.gameplay.enable_friendly_fire
        SetCeaseFireBetweenAllForces()
        SetFriendlyBetweenAllForces()
    else
        log("TOO MANY FORCES!!! - CreatePlayerForce()")
        return game.forces[global.ocfg.gameplay.main_force_name]
    end

    return newForce
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
---@alias OarcDelayedSpawn { surface: string, playerName: string, position: MapPosition, moat: boolean, delayedTick: number, final_chunk_generated: ChunkPosition }
---Table of [OarcDelayedSpawn](lua://OarcDelayedSpawn) indexed by player name.
---@alias OarcDelayedSpawnsTable table<string, OarcDelayedSpawn>

---This contains the spawn choices for a player in the spawn menu.
---@alias OarcSpawnChoices { surface: string, team: SpawnTeamChoice, moat: boolean, buddy: string?, distance: integer, host: string?, buddy_team: boolean }
---Table of [OarcSpawnChoices](lua://OarcSpawnChoices) indexed by player name.
---@alias OarcSpawnChoicesTable table<string, OarcSpawnChoices>

