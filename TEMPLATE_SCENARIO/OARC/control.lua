-- To edit this scenario, you must make a copy of it and place it in your own scenarios folder first!
-- Alternatively, you can make a dependent mod based on this as well.

-- I provide this empty scenario to avoid the freeplay scenario extra baggage and as a template for how to modify the
-- settings on init. You can use the freeplay scenario too just fine if you want.

-- This is where you can modify what resources spawn, how much, where, etc.
-- I will try to avoid making breaking changes to this, but no guarantees.

-- To see the full list of all settings available, look at the config.lua file in the mod folder itself.
-- That has all the settings and their definitions and default values. Plus, if you are using VS Code + FMTK (the
-- Factorio Mod Toolkit), you can use the syntax highlighting and autocomplete to see all the settings available.

-- Alternatively, you can use the in-game "export" button to get a string of all settings that you can then format
-- and edit however you want to use here.

----------------------------------------------------------------------------------------------------------------
-- In order to modify the settings of the OARC mod, you need to implement the following section.
-- I need to insert any settings overrides before I run my mod's other init functions so this is why I do it
-- this way! If I let you overwrite config at a later time, it may have no effect or might cause other issues.
-- You should only be modifying the section as described below. Don't modify the rest of this interface.
--
-- You can implement this in a scenario OR a mod (despite the name).
----------------------------------------------------------------------------------------------------------------
local oarc_scenario_interface =
{
    get_scenario_settings = function()

        ---@type OarcConfig
        local modified_settings = remote.call("oarc_mod", "get_mod_settings")

        -- Overwrite whatever settings you want here:
        -- If you provide an invalid value for a mod setting, it will error and not load the scenario.
        -- ANY CONFIG HERE WILL OVERWRITE MOD SETTINGS! This is the whole point.
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
-- End of settings override section.
----------------------------------------------------------------------------------------------------------------


-- Check if the OARC mod is loaded. Other than that, it's an empty scenario! You can modify it however you want.
script.on_init(function(event)
    if not script.active_mods["oarc-mod"] then
        error("OARC mod not found! This scenario is intended to be run with the OARC mod!")
    end

    -- Please note: a scenario can NOT call this during on_init because you can't set load order for a scenario!
    -- You just get nil back. If you are making a mod, you can use this to get the config during on_init.
    -- storage.ocfg_copy = remote.call("oarc_mod", "get_mod_settings")
    -- See the oarc-mod-on-config-changed event for how to keep the config up to date.
end)


----------------------------------------------------------------------------------------------------------------
-- This section shows an example of how to customize the spawn gui options presented to the player, and how to
-- use that to customize the spawn area generation process.
----------------------------------------------------------------------------------------------------------------

local util = require("util") -- Only needed for the distance function in this example.

-- You can require files to use them if you want like this. (Ignore the diagnostic warning.)
---@diagnostic disable-next-line: different-requires
require("__oarc-mod__/lib/oarc_gui_utils") -- I have a helper function in here for creating GUI elements.

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

----------------------------------------------------------------------------------------------------------------
-- This section just supports the above events.
----------------------------------------------------------------------------------------------------------------

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

----------------------------------------------------------------------------------------------------------------
-- This section shows how to add a custom tab to the Oarc Mod GUI (the top left button).
----------------------------------------------------------------------------------------------------------------

local CUSTOM_TAB_NAME = "Test Mod"

script.on_event("oarc-mod-on-mod-top-left-gui-created", function(event --[[@as OarcModOnModTopLeftGuiCreatedEvent]])

    -- Create a custom empty tab:
    remote.call("oarc_mod", "create_custom_gui_tab", game.players[event.player_index], CUSTOM_TAB_NAME)

    -- Get the tab content element
    local tab_content = remote.call("oarc_mod", "get_custom_gui_tab_content_element", game.players[event.player_index], CUSTOM_TAB_NAME)
    
    -- Save a reference to that tab content for later use, if it becomes nil you can ask for it again.
    -- Or you can just always ask for it when you need it, depends on how often you plan to use it.
    if storage.custom_tabs_table == nil then
        storage.custom_tabs_table = {}
    end
    storage.custom_tabs_table[event.player_index] = {content = tab_content, example_data = 0}

    -- Use the element to add content directly to it.
    CreateExampleCustomTabContent(tab_content, tostring(0))
end)

---Creates the test tab content, just adds a couple of text labels and a button as an example.
---@param tab_container LuaGuiElement
---@param example_data string
---@return nil
function CreateExampleCustomTabContent(tab_container, example_data)
    tab_container.clear()
    tab_container.add {
        type = "label",
        caption = "This is a test tab to demonstrate how to add tabs to the Oarc Mod GUI.",
        style = "caption_label"
    }
    tab_container.add {
        type = "label",
        caption = "This tab has been clicked " .. example_data .. " times.",
        style = "caption_label"
    }
    tab_container.add {
        type = "button",
        caption = "Click Me!",
        style = "button",
        name = "test_mod_button",
        tags = { test_mod_button = true } -- Learn to use tags, this is great for identifying where GUI events came from.
    }
end

-- This is the event that is triggered when a player selects a tab (on ANY tabbed pane)
script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
    if (event.element.name ~= "oarc_tabs") then return end -- This is what I have named my tabbed pane in my mod.

    -- Check if your custom tab was selected
    local tab_name = event.element.tabs[event.element.selected_tab_index].tab.name
    if (tab_name ~= "Test Mod") then return end

    log("Selected Test Mod tab")

    -- Proof of concept that shows you can update/change the content of your custom tab when it is selected.
    local entry = storage.custom_tabs_table[event.player_index]
    entry.example_data = entry.example_data + 1
    CreateExampleCustomTabContent(entry.content, tostring(entry.example_data))
end)

-- This is the event that is triggered when a player clicks a button in the GUI (on ANY GUI)
script.on_event(defines.events.on_gui_click, function (event)
    
    -- Check if the button clicked was yours, how you can identify it is up to you, but tags are a good way.
    if event.element.tags and event.element.tags.test_mod_button then
        log("Test Mod button clicked!")
        game.players[event.player_index].print("Test Mod button clicked!")
    end
end)