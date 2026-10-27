local mod_gui = require("mod-gui")

---Test out all the fonts available in the game.
---@param player LuaPlayer
---@return nil
function TestFonts(player)
    local font_list = {
        "compi",
        "compilatron-message-font",
        "count-font",
        "default",
        "default-bold",
        "default-dialog-button",
        "default-dropdown",
        "default-game",
        "default-large",
        "default-large-bold",
        "default-large-semibold",
        "default-listbox",
        "default-semibold",
        "default-small",
        "default-small-bold",
        "default-small-semibold",
        "default-tiny-bold",
        "heading-1",
        "heading-2",
        "heading-3",
        "locale-pick",
        "scenario-message-dialog",
        "technology-slot-level-font",
        "var",
    }

    local test_frame = player.gui.screen.add{type="frame", name="font_test_frame", direction="vertical"}
    for _,font in pairs(font_list) do
        local test_text = test_frame.add{type="label", caption=font}
        test_text.style.font = font
    end

    test_frame.auto_center = true
end

function ClearTestFonts(player)
    if player.gui.screen.font_test_frame then
        player.gui.screen.font_test_frame.destroy()
    end
end

---Test out all the button styles available in the game.
---@param player LuaPlayer
---@return nil
function TestButtons(player)
    local button_styles = {
        "back_button",
        "big_slot_button",
        -- "blueprint_drop_slot_button",
        "blueprint_record_selection_button",
        "blueprint_record_slot_button",
        "browse_games_gui_toggle_favorite_off_button",
        "browse_games_gui_toggle_favorite_on_button",
        "cancel_close_button",
        -- "character_gui_entity_button",
        "choose_chat_icon_button",
        "choose_chat_icon_in_textbox_button",
        "close_button",
        "compact_slot_sized_button",
        "confirm_button",
        "confirm_double_arrow_button",
        "confirm_in_load_game_button",
        "control_settings_button",
        "control_settings_section_button",
        "current_research_info_button",
        "dark_button",
        "dark_rounded_button",
        "dialog_button",
        "drop_target_button",
        "dropdown_button",
        "entity_variation_button",
        "forward_button",
        "frame_action_button",
        "frame_button",
        "green_button",
        "highlighted_tool_button",
        "inventory_limit_slot_button",
        "left_slider_button",
        "locomotive_minimap_button",
        "logistic_slot_button",
        "map_generator_close_preview_button",
        "map_generator_confirm_button",
        "map_generator_preview_button",
        "map_view_add_button",
        "map_view_options_button",
        "menu_button",
        "mini_button",
        "mod_gui_button",
        "not_working_weapon_button",
        "open_armor_button",
        "other_settings_gui_button",
        "quick_bar_page_button",
        "quick_bar_slot_button",
        "recipe_slot_button",
        "red_back_button",
        "red_button",
        "red_confirm_button",
        "red_logistic_slot_button",
        "red_slot_button",
        "research_queue_cancel_button",
        "right_slider_button",
        "rounded_button",
        "shortcut_bar_button",
        "shortcut_bar_expand_button",
        "side_menu_button",
        "slider_button",
        "slot_button",
        "slot_sized_button",
        "station_train_status_button",
        "statistics_slot_button",
        "tile_variation_button",
        "tip_notice_button",
        "tip_notice_close_button",
        "tool_bar_open_button",
        "tool_button",
        "tracking_off_button",
        "tracking_on_button",
        "train_schedule_action_button",
        "train_schedule_add_station_button",
        "train_schedule_add_wait_condition_button",
        "train_schedule_comparison_type_button",
        "train_schedule_condition_time_selection_button",
        "train_schedule_delete_button",
        "train_schedule_fulfilled_delete_button",
        "train_schedule_fulfilled_item_select_button",
        "train_schedule_item_select_button",
        "train_schedule_temporary_station_delete_button",
        "train_status_button",
        -- "train_stop_entity_button",
        -- "wide_entity_button",
        "working_weapon_button",
        "yellow_logistic_slot_button",
    }

    local test_frame = player.gui.screen.add{type="scroll-pane", name="button_test_frame", direction="vertical"}
    -- test_frame.auto_center = true
    test_frame.vertical_scroll_policy = "auto"
    test_frame.style.maximal_height = 800

    for _,button_style in pairs(button_styles) do
        local test_button = test_frame.add
        {
            type="button",
            caption=button_style,
            style=button_style
        }
    end


end

function ClearTestButtons(player)
    if player.gui.screen.button_test_frame then
        player.gui.screen.button_test_frame.destroy()
    end
end


function SetNauvisChunksGenerated()
    local nauvis = game.surfaces["nauvis"]

    for x = -100, 100, 1 do
        for y = -100, 100, 1 do
            nauvis.set_chunk_generated_status({x=x, y=y}, defines.chunk_generated_status.entities)
        end
    end
end


function FlagEnemyForce(player, enemy_force_name)

    local enemy_force = game.forces[enemy_force_name]

    player.force.set_friend(enemy_force, true)
    player.force.set_cease_fire(enemy_force, true)

end

function UnflagEnemyForce(player, enemy_force_name)

    local enemy_force = game.forces[enemy_force_name]

    player.force.set_friend(enemy_force, false)
    player.force.set_cease_fire(enemy_force, false)

end

function CreateTestSurfaces()

    game.create_surface("vulcanus")
    game.create_surface("fulgora")
    game.create_surface("gleba")
    game.create_surface("aquilo")

end


---Searchs a 3x3 chunk around the map origin for "cargo-pod-container" entities and if they are on the same force
---as the player it will teleport the cargo pod to the player. This is meant to be a temporary work around since I don't
---know how to detect the cargo pod that is associated with the player or when it is sent/landed.
---@param player LuaPlayer
---@return nil
function DudeWheresMyCargoPod(player)

    if not player.character then
        SendErrorMsg(player, { "oarc-character-invalid" })
        return
    end

    local surface = player.character.surface
    local radius = CHUNK_SIZE*3
    local search_area = {{-radius,-radius},{radius,radius}}

    local pods = surface.find_entities_filtered{area=search_area, name="cargo-pod-container", force=player.force}

    if #pods == 0 then
        SendErrorMsg(player, { "oarc-no-cargo-pods" })
        return
    end

    for _,cargo_pod in pairs(pods) do

        local new_position = surface.find_non_colliding_position("cargo-pod-container", player.character.position, CHUNK_SIZE, 1)

        if new_position == nil then
            SendErrorMsg(player, { "oarc-teleport-cargo-pod-fail" })
            return
        end

        cargo_pod.teleport(new_position)
        CompatSend(player, { "oarc-teleport-cargo-pod-success" })
    end
end

-- Radius around a spawn that is checked before a reroll.
REROLL_CHECK_RADIUS_TILES = 3 * CHUNK_SIZE
-- How long a reroll warning waits for the command to be run again.
REROLL_CONFIRM_TICKS = 60 * TICKS_PER_SECOND

-- Entities on the force that come with every new spawn, so they don't count as the player's stuff.
local REROLL_IGNORED_TYPES = { "character", "cargo-pod", "entity-ghost", "tile-ghost" }
local REROLL_IGNORED_NAMES = { "fulgoran-ruin-attractor" }
local REROLL_IGNORED_NAME_PREFIX = "crash-site-"

---Finds a player character from another force near a spawn. Offline players' characters count too.
---@param surface LuaSurface
---@param position MapPosition
---@param force LuaForce
---@return string? player_name Name of the character's player, or nil if there is none.
function FindOtherForceCharacterNearSpawn(surface, position, force)
    local characters = surface.find_entities_filtered { type = "character", position = position, radius = REROLL_CHECK_RADIUS_TILES }
    for _, character in pairs(characters) do
        if (character.force ~= force) then
            local owner = character.player or character.associated_player
            if (owner ~= nil) then
                return owner.name
            end
        end
    end
    return nil
end

---Counts the buildings and landed cargo pods with items that a force has near a spawn. Empty cargo pods and the
---entities every new spawn gets (crash site, Fulgora ruin attractors) are left out.
---@param surface LuaSurface
---@param position MapPosition
---@param force LuaForce
---@return integer buildings
---@return integer pods
function CountForceStuffNearSpawn(surface, position, force)
    local buildings = 0
    local pods = 0
    local entities = surface.find_entities_filtered { position = position, radius = REROLL_CHECK_RADIUS_TILES, force = force }
    for _, entity in pairs(entities) do
        if (entity.name == "cargo-pod-container") then
            local inventory = entity.get_inventory(defines.inventory.chest)
            if (inventory ~= nil) and (not inventory.is_empty()) then
                pods = pods + 1
            end
        elseif (not TableContains(REROLL_IGNORED_TYPES, entity.type)) and
            (not TableContains(REROLL_IGNORED_NAMES, entity.name)) and
            (not StringStartsWith(entity.name, REROLL_IGNORED_NAME_PREFIX)) then
            buildings = buildings + 1
        end
    end
    return buildings, pods
end

---Checks if the caller was warned about this reroll recently, which means they want to go ahead with it.
---@param caller LuaPlayer
---@param player LuaPlayer
---@param surface_name string
---@return boolean
local function IsRerollConfirmed(caller, player, surface_name)
    local confirmation = storage.reroll_confirmations[caller.name]
    return (confirmation ~= nil) and
        (confirmation.target_name == player.name) and
        (confirmation.surface_name == surface_name) and
        (game.tick - confirmation.tick <= REROLL_CONFIRM_TICKS)
end

---Moves a player's spawn on the surface they are standing on to the next free starting point. Admins can reroll
---anyone as often as they want. Other players can only reroll themselves, once per surface. A reroll is only used up
---if a free starting point was found.
---@param caller LuaPlayer The player running the command, for error messages and the admin check.
---@param player LuaPlayer The player whose spawn is rerolled.
---@return nil
function RerollSpawn(caller, player)

    if (caller ~= player) and not caller.admin then
        SendErrorMsg(caller, {"oarc-command-not-admin-warning", "oarc-reroll-spawn " .. player.name})
        return
    end

    -- Make sure character is valid
    if not player.character then
        SendErrorMsg(caller, { "oarc-reroll-no-character", player.name })
        return
    end

    local surface = player.character.surface
    local surface_name = surface.name

    -- Confirm this player is the host of a spawn on this surface
    if (storage.unique_spawns[surface_name] == nil or storage.unique_spawns[surface_name][player.name] == nil) then
        SendErrorMsg(caller, { "oarc-reroll-no-spawn", player.name, surface_name })
        return
    end

    -- Ensure we still have their previous spawn choices
    local spawn_choices = storage.spawn_choices[player.name]
    if (spawn_choices == nil) then
        log("ERROR - RerollSpawn - No spawn choices for player: " .. player.name)
        return
    end

    if (not caller.admin) and storage.player_rerolls[player.name] and storage.player_rerolls[player.name][surface_name] then
        SendErrorMsg(caller, { "oarc-reroll-used-up", surface_name })
        return
    end

    -- Save a copy of the previous spawn point
    local old_spawn_point = table.deepcopy(storage.unique_spawns[surface_name][player.name])
    local force = player.force --[[@as LuaForce]]

    -- Another team's player at the spawn would lose whatever they are doing there.
    local other_player_name = FindOtherForceCharacterNearSpawn(surface, old_spawn_point.position, force)
    if (other_player_name ~= nil) then
        SendErrorMsg(caller, { "oarc-reroll-blocked-player", other_player_name, surface_name })
        return
    end

    -- Pods on their way would land at the old spawn and be lost.
    if IsCargoPodHeadingToSurface(force, surface) then
        SendErrorMsg(caller, { "oarc-reroll-blocked-cargo-pod", surface_name })
        return
    end

    -- Warn about anything that would be lost. Running the command again soon after goes ahead anyway.
    local buildings, pods = CountForceStuffNearSpawn(surface, old_spawn_point.position, force)
    if ((buildings + pods) > 0) and not IsRerollConfirmed(caller, player, surface_name) then
        storage.reroll_confirmations[caller.name] = { target_name = player.name, surface_name = surface_name, tick = game.tick }
        SendErrorMsg(caller, { "oarc-reroll-confirm-warning", buildings, pods, player.name, surface_name })
        return
    end
    storage.reroll_confirmations[caller.name] = nil

    -- Claim the next free starting point
    local spawn_position = ClaimNextStartingPoint(surface_name, player.name)
    if (spawn_position == nil) then
        SendErrorMsg(caller, { "oarc-no-free-starting-points", surface_name })
        return
    end

    -- Admin rerolls don't use up the player's own reroll
    if not caller.admin then
        storage.player_rerolls[player.name] = storage.player_rerolls[player.name] or {}
        storage.player_rerolls[player.name][surface_name] = true
    end

    -- Remove the old spawn point
    if (storage.ocfg.regrowth.enable_abandoned_base_cleanup) then
        log("Removing base: " .. old_spawn_point.position.x .. "," .. old_spawn_point.position.y .. " on surface: " .. surface_name)

        RegrowthMarkAreaForRemoval(surface_name, old_spawn_point.position, GetSpawnCleanupChunkRadius(old_spawn_point))
        TriggerCleanup()
        script.raise_event("oarc-classic-on-spawn-remove-request", {spawn_data = old_spawn_point})
    end
    ReleaseStartingPoint(surface_name, old_spawn_point.position)

    -- Queue spawn generation and the player.
    local delayed_spawn = GenerateNewSpawn(player.name, surface_name, spawn_position, spawn_choices, old_spawn_point.primary)
    QueuePlayerForSpawn(player.name, delayed_spawn)

    -- Send them to the holding pen
    SafeTeleport(player, game.surfaces[HOLDING_PEN_SURFACE_NAME], {x=0,y=0})

    -- Queue joiners too (if they are on this surface?)
    for _,joiner in pairs(old_spawn_point.joiners) do
        local joiner_player = game.players[joiner]
        if (joiner_player ~= nil) and (joiner_player.character ~= nil) and joiner_player.character.surface.name == surface_name then
            QueuePlayerForSpawn(joiner, delayed_spawn)
            SafeTeleport(game.players[joiner], game.surfaces[HOLDING_PEN_SURFACE_NAME], {x=0,y=0})
        end
    end

    -- Announce
    SendBroadcastMsg({"", { "oarc-spawn-rerolled", player.name, surface_name }, " ", GetGPStext(surface_name, spawn_position)})
end


---Sends a player to a planet the same way landing there from space would. If their spawn has no base on that planet
---yet, this creates a secondary spawn on the planet's next free starting point, even if secondary spawns are disabled
---on that surface. Otherwise they are sent to their respawn point there.
---@param admin LuaPlayer The player running the command, for error messages.
---@param player LuaPlayer
---@param planet_name string
---@return nil
function TestSendPlayerToPlanet(admin, player, planet_name)
    if (game.planets[planet_name] == nil) then
        admin.print("No planet named " .. planet_name)
        return
    end
    if (player.character == nil) then
        admin.print(player.name .. " has no character right now.")
        return
    end
    if (FindPlayerHomeSpawn(player.name) == nil) then
        admin.print(player.name .. " has no home spawn yet. They need to spawn on their primary surface first.")
        return
    end

    local player_spawn = FindPlayerSpawnOnSurface(player.name, planet_name)
    if (player_spawn == nil) then
        log("TestSendPlayerToPlanet - Creating a secondary spawn for " .. player.name .. " on " .. planet_name)
        SecondarySpawn(player, planet_name, true)
    elseif (not player_spawn.generated) then
        local delayed_spawn = FindDelayedSpawn(player.name, planet_name)
        if (delayed_spawn ~= nil) then
            QueuePlayerForSpawn(player.name, delayed_spawn)
        end
    else
        TeleportPlayerToRespawnPoint(planet_name, player, false)
    end
end

---Teleport a player to one of the starting points and chart the area around it.
---@param player LuaPlayer
---@param index integer
---@param surface_name string
---@return nil
function TeleportToStartingPoint(player, index, surface_name)
    local surface = game.surfaces[surface_name]
    local points = storage.starting_points[surface_name]
    if (surface == nil) or (points == nil) then
        player.print("No starting points on a surface named " .. surface_name)
        return
    end

    local point = points[index] and points[index].position
    if point == nil then
        player.print("Usage: /oarc-tp-start <1-" .. #points .. "> [surface]")
        return
    end
    local radius = 256
    player.force.chart(surface, {{point.x - radius, point.y - radius}, {point.x + radius, point.y + radius}})
    surface.request_to_generate_chunks(point, 2)
    surface.force_generate_chunk_requests()

    local safe_pos = surface.find_non_colliding_position("character", point, 64, 1) or point
    player.teleport(safe_pos, surface)
    player.print("Teleported to starting point " .. index .. " " .. GetGPStext(surface.name, point))
end
