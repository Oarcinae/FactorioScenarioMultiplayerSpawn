-- To edit this scenario, you must make a copy of it and place it in your own scenarios folder first!
-- Alternatively, you can make a dependent mod based on this as well.

-- This scenario only exists so server hosts can override the Oarc Classic config before the game starts.
-- To see every setting available, look at lib/config.lua in the mod folder.

----------------------------------------------------------------------------------------------------------------
-- The mod calls this interface during its on_init, before it builds anything, so overrides here take effect.
-- If you provide an invalid value for a mod setting, it will error and not load the scenario.
----------------------------------------------------------------------------------------------------------------
local oarc_classic_scenario_interface =
{
    get_scenario_settings = function()

        ---@type OarcConfig
        local modified_settings = remote.call("oarc_classic", "get_mod_settings")

        modified_settings.server_info.welcome_msg_title = "THIS IS A TEMPLATE SCENARIO"
        modified_settings.server_info.welcome_msg = "This is a template scenario. You can modify the settings in the control.lua file. If you are seeing this message, you did not modify the scenario correctly."

        -- Let players pick the OG Oarc style spawn circle (crop circle, moat, scripted resources) in the spawn menu:
        -- modified_settings.gameplay.allow_oarc_style_spawn = true

        -- Surface config is not available in the mod settings, for example starting items:
        -- modified_settings.surfaces_config["nauvis"].starting_items.player_start_items = {
        --     ["coal"] = 1, -- You're on the naughty list!
        -- }

        -- Or a different starting point grid for one planet:
        -- modified_settings.surfaces_config["vulcanus"].starting_points = { count = 8, spacing_chunks = 120 }

        return modified_settings
    end
}

remote.add_interface("oarc_classic_scenario", oarc_classic_scenario_interface)

script.on_init(function(event)
    if not script.active_mods["oarc-classic"] then
        error("Oarc Classic mod not found! This scenario is intended to be run with the Oarc Classic mod!")
    end
end)
