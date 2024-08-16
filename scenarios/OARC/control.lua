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
    modified_settings.gameplay.main_force_name = "test"

    modified_settings.surfaces_config["nauvis"].starting_items.player_start_items = {
        ["coal"] = 1,
    }

    return modified_settings
  end
}

remote.add_interface("oarc_scenario", oarc_scenario_interface)