-- I provide this empty scenario to avoid the freeplay scenario extra baggage.
-- You can use the freeplay scenario too just fine if you want.
-- The main benefit of the scenario is that it lets you modify the any of the config during on_init of the mod.

-- This is where you can modify what resources spawn, how much, where, etc.
-- Once you have a config you like, it's a good idea to save it for later use so you don't lose it if you update the
-- scenario. I will try to avoid making breaking changes to this, but no guarantees.

-- To see what settings are available, look at the config_mod.lua file in the mod folder.

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

        modified_settings.spawn_general.shape = "circle"
        
        -- Some examples of overriding surface config (which is not accessible from the mod settings!)
        modified_settings.surfaces_config["nauvis"].starting_items.player_start_items = {
            ["coal"] = 1, -- You're on the naughty list!
        }
        ----------------------------------------------------------------------------------------------------------------
        return modified_settings
    end
}

remote.add_interface("oarc_scenario", oarc_scenario_interface)