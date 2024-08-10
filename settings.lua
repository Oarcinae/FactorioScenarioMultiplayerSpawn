data:extend({
    -- Startup
    {
        type = "bool-setting",
        name = "oarc-mod-enable-main-force",
        setting_type = "startup",
        default_value = true,
        order = "a"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-separate-teams",
        setting_type = "startup",
        default_value = true,
        order = "b"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-spawning-on-other-surfaces",
        setting_type = "startup",
        default_value = true,
        order = "c"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-buddy-spawn",
        setting_type = "startup",
        default_value = true,
        order = "d"
    },
    {
        type = "string-setting",
        name = "oarc-mod-scenario-config-note-startup",
        setting_type = "startup",
        default_value = "Additional settings can be found in the scenario config file. See config.lua for more info.",
        allowed_values = {"Additional settings can be found in the scenario config file. See config.lua for more info."},
        order = "zzz"
    },

    -- Vanilla spawn point are not implemented yet.
    -- {
    --     type = "bool-setting",
    --     name = "oarc-mod-enable-vanilla-spawn-points",
    --     setting_type = "startup",
    --     default_value = true
    -- },
    -- {
    --     type = "int-setting",
    --     name = "oarc-mod-number-of-vanilla-spawn-points",
    --     setting_type = "startup",
    --     default_value = 5,
    --     minimum_value = 1,
    --     maximum_value = 10
    -- },
    -- {
    --     type = "int-setting",
    --     name = "oarc-mod-vanilla-spawn-point-spacing",
    --     setting_type = "startup",
    --     default_value = 10,
    --     minimum_value = 5,
    --     maximum_value = 20
    -- },


    -- Runtime global
    {
        type = "bool-setting",
        name = "oarc-mod-enable-regrowth",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-world-eater",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-offline-protection",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-shared-team-vision",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-shared-team-chat",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-shared-spawns",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "int-setting",
        name = "oarc-mod-number-of-players-per-shared-spawn",
        setting_type = "runtime-global",
        default_value = 4,
        minimum_value = 2,
        maximum_value = 8
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-abandoned-base-cleanup",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-friendly-fire",
        setting_type = "runtime-global",
        default_value = false
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-allow-moats-around-spawns",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-force-bridges-next-to-moats",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "int-setting",
        name = "oarc-mod-minimum-distance-to-existing-chunks",
        setting_type = "runtime-global",
        default_value = 10,
        minimum_value = 5,
        maximum_value = 20
    },
    {
        type = "int-setting",
        name = "oarc-mod-near-spawn-min-distance",
        setting_type = "runtime-global",
        default_value = 100,
        minimum_value = 50,
        maximum_value = 200
    },
    {
        type = "int-setting",
        name = "oarc-mod-near-spawn-max-distance",
        setting_type = "runtime-global",
        default_value = 200,
        minimum_value = 100,
        maximum_value = 300
    },
    {
        type = "int-setting",
        name = "oarc-mod-far-spawn-min-distance",
        setting_type = "runtime-global",
        default_value = 500,
        minimum_value = 300,
        maximum_value = 700
    },
    {
        type = "int-setting",
        name = "oarc-mod-far-spawn-max-distance",
        setting_type = "runtime-global",
        default_value = 700,
        minimum_value = 500,
        maximum_value = 900
    }
})