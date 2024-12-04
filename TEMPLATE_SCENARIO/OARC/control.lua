-- To edit this scenario, you must make a copy of it and place it in your own scenarios folder first!

-- I provide this empty scenario to avoid the freeplay scenario extra baggage and as a template for how to modify the
-- settings on init. You can use the freeplay scenario too just fine if you want.

-- This is where you can modify what resources spawn, how much, where, etc.
-- I will try to avoid making breaking changes to this, but no guarantees.

-- To see the full list of all settings available, look at the config.lua file in the mod folder itself.
-- That has all the settings and their definitions and default values. Plus, if you are using VS Code + FMTK (the
-- Factorio Mod Toolkit), you can use the syntax highlighting and autocomplete to see all the settings available.

-- Alternatively, you can use the in-game "export" button to get a string of all settings that you can then format
-- and edit however you want to use here.

-- ANY CONFIG HERE WILL OVERWRITE MOD SETTINGS! This is the whole point.

-- Check if the OARC mod is loaded. Other than that, it's an empty scenario!
script.on_init(function(event)
    if not script.active_mods["oarc-mod"] then
        error("OARC mod not found! This scenario is intended to be run with the OARC mod!")
    end

    storage.ocfg_copy = remote.call("oarc_mod", "get_mod_settings")
    log("server info test: ")
end)


local oarc_scenario_interface =
{
    get_scenario_settings = function()

        ---@type OarcConfig
        local modified_settings = remote.call("oarc_mod", "get_mod_settings")

        -- Overwrite whatever settings you want here:
        -- If you provide an invalid value for a mod setting, it will error and not load the scenario.
        ----------------------------------------------------------------------------------------------------------------
        modified_settings.server_info.welcome_msg_title = "THIS IS A TEMPLATE SCENARIO"
        modified_settings.server_info.welcome_msg = "This is a template scenario. You can modify the settings in the control.lua file. If you are seeing this message, you did not modify the scenario correctly."

        -- modified_settings.spawn_general.shape = "circle"

        -- Some examples of overriding surface config (which is not accessible from the mod settings!)
        -- modified_settings.surfaces_config["nauvis"].starting_items.player_start_items = {
        --     ["coal"] = 1, -- You're on the naughty list!
        -- }
        ----------------------------------------------------------------------------------------------------------------
        return modified_settings
    end
}

remote.add_interface("oarc_scenario", oarc_scenario_interface)




----------------------------------------------------------------------------------------------------------------
-- Everything below here is an example of how to use the custom events provided by the OARC mod.
----------------------------------------------------------------------------------------------------------------

local util = require("util")

-- You can require files to use them if you want like this. (Ignore the diagnostic warning.)
---@diagnostic disable-next-line: different-requires
require("__oarc-mod__/lib/oarc_gui_utils")

-- This will keep a local copy of the mod's config so you can use it in your custom events.
script.on_event("oarc-mod-on-config-changed", function(event)
    storage.ocfg_copy = remote.call("oarc_mod", "get_mod_settings")
end)

-- This is how you can customize the spawn options menu by inserting whatever you want into it!
script.on_event("oarc-mod-on-spawn-choices-gui-displayed", function(event)

    --This is just here so I don't get lua warnings
    ---@type OarcModOnSpawnChoicesGuiDisplayedEvent
    local custom_event = event
    local player = game.players[custom_event.player_index]

    -- The 4 main sub sections are called: spawn_settings_frame, solo_spawn_frame, shared_spawn_frame, and buddy_spawn_frame

    local gui = custom_event.gui_element
    if (gui.spawn_settings_frame ~= nil) then
        CreateTilesSelectDropdown(gui.spawn_settings_frame)
    end

    if storage.custom_spawn_choices == nil then
        storage.custom_spawn_choices = {}
    end
    if storage.custom_spawn_choices[player.name] == nil then
        storage.custom_spawn_choices[player.name] = { tile_select_name = "refined-concrete" }
    end
end)

-- This is how you can customize the spawn area chunk generation process.
script.on_event("oarc-mod-on-chunk-generated-near-spawn", function(event)

    --This is just here so I don't get lua warnings
    ---@type OarcModOnChunkGeneratedNearSpawnEvent
    local custom_event = event

    -- Remove decoratives (grass/roots/enemy-decal)
    custom_event.surface.destroy_decoratives {area = custom_event.chunk_area}

    -- Get the spawn config from our local copy.
    local general_spawn_config = storage.ocfg_copy.spawn_general
    local surface_spawn_config = storage.ocfg_copy.surfaces_config[custom_event.surface.name].spawn_config
    local radius = general_spawn_config.spawn_radius_tiles * surface_spawn_config.radius_modifier

    -- Use spawn data to look up custom spawn choices if you want to
    local host_name = custom_event.spawn_data.host_name
    local custom_spawn_choices = storage.custom_spawn_choices[host_name]
    if custom_spawn_choices == nil then
        error("Custom spawn choices entry not found for host: " .. host_name)
    end

    -- As an example, we are placing a specific tile over the entire spawn area.
    local chunk_area = custom_event.chunk_area
    local tiles = {}

    -- I leave it as an exercise to the reader to implement the other shapes:
    if (general_spawn_config.shape == "circle") then
        for x = chunk_area.left_top.x, chunk_area.right_bottom.x, 1 do
            for y = chunk_area.left_top.y, chunk_area.right_bottom.y, 1 do
                if (util.distance(custom_event.spawn_data.position, {x=x,y=y}) < radius) then
                    table.insert(tiles, {name=custom_spawn_choices.tile_select_name, position={x,y}})
                end
            end
        end
    end

    custom_event.surface.set_tiles(tiles)
end)

---A helper function to create a dropdown for selecting tiles
---@param parent_flow LuaGuiElement
---@return nil
function CreateTilesSelectDropdown(parent_flow)
    local flow = parent_flow.add {
        name = "tile_horizontal_flow",
        type = "flow",
        direction = "horizontal"
    }

    local tiles =
    {
        "concrete"                 ,
        "refined-concrete"         ,
        "red-refined-concrete"     ,
        "green-refined-concrete"   ,
        "blue-refined-concrete"    ,
        "orange-refined-concrete"  ,
        "yellow-refined-concrete"  ,
        "pink-refined-concrete"    ,
        "purple-refined-concrete"  ,
        "black-refined-concrete"   ,
        "brown-refined-concrete"   ,
        "cyan-refined-concrete"    ,
        "acid-refined-concrete"    ,
    }
    local tilesLocalised = {}
    for _, name in ipairs(tiles) do
        table.insert(tilesLocalised,  {"", "[tile="..name.. "]", " ", prototypes.tile[name].localised_name} )
    end

    AddLabel(flow, nil, { "oarc-tile-select-cap"}, my_label_style)
    flow.add {
        type = "drop-down",
        name = "tile_select_dropdown",
        tags = { action = "custom_spawn_options", setting = "tile_select" },
        selected_index = 1,
        items = tilesLocalised
    }
end

---Handle dropdown selection changes
---@param event EventData.on_gui_selection_state_changed
---@return nil
function CustomSpawnOptsSelectionChanged(event)
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local tags = event.element.tags

    if (tags.action ~= "custom_spawn_options") then
        return
    end

    if (tags.setting == "tile_select") then
        local tiles =
        {
            "concrete"                 ,
            "refined-concrete"         ,
            "red-refined-concrete"     ,
            "green-refined-concrete"   ,
            "blue-refined-concrete"    ,
            "orange-refined-concrete"  ,
            "yellow-refined-concrete"  ,
            "pink-refined-concrete"    ,
            "purple-refined-concrete"  ,
            "black-refined-concrete"   ,
            "brown-refined-concrete"   ,
            "cyan-refined-concrete"    ,
            "acid-refined-concrete"    ,
        }
        local index = event.element.selected_index

        storage.custom_spawn_choices[player.name].tile_select_name =  tiles[index]
    end
end

--- For dropdowns and listboxes.
script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    if not event.element.valid then return end

    CustomSpawnOptsSelectionChanged(event)
end)