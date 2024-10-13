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
    if not game.active_mods["oarc-mod"] then
        error("OARC mod not found! This scenario is intended to be run with the OARC mod!")
    end
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