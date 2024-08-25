data:extend({
    {
        type = "string-setting",
        name = "oarc-mod-welcome-msg-title",
        setting_type = "runtime-global",
        default_value = "Insert Server Title Here!",
        order = "a1"
    },
    {
        type = "string-setting",
        name = "oarc-mod-welcome-msg",
        setting_type = "runtime-global",
        default_value = "Insert Server Welcome Message Here!",
        order = "a2"
    },
    {
        type = "string-setting",
        name = "oarc-mod-server-msg",
        setting_type = "runtime-global",
        default_value = "Insert Server Info Message Here!",
        order = "a3"
    },


    {
        type = "bool-setting",
        name = "oarc-mod-enable-main-team",
        setting_type = "runtime-global",
        default_value = true,
        order = "b1"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-separate-teams",
        setting_type = "runtime-global",
        default_value = true,
        order = "b2"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-spawning-on-other-surfaces",
        setting_type = "runtime-global",
        default_value = true,
        order = "b3"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-allow-moats-around-spawns",
        setting_type = "runtime-global",
        default_value = true,
        order = "b4"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-moat-bridging",
        setting_type = "runtime-global",
        default_value = true,
        order = "b5"
    },

    {
        type = "int-setting",
        name = "oarc-mod-minimum-distance-to-existing-chunks",
        setting_type = "runtime-global",
        default_value = 10,
        minimum_value = 5,
        maximum_value = 25,
        order = "c1"
    },
    {
        type = "int-setting",
        name = "oarc-mod-near-spawn-distance",
        setting_type = "runtime-global",
        default_value = 100,
        minimum_value = 50,
        maximum_value = 250,
        order = "c2"
    },
    {
        type = "int-setting",
        name = "oarc-mod-far-spawn-distance",
        setting_type = "runtime-global",
        default_value = 500,
        minimum_value = 250,
        maximum_value = 5000,
        order = "c3"
    },

    {
        type = "bool-setting",
        name = "oarc-mod-enable-buddy-spawn",
        setting_type = "runtime-global",
        default_value = true,
        order = "d1"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-offline-protection",
        setting_type = "runtime-global",
        default_value = true,
        order = "d2"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-shared-team-vision",
        setting_type = "runtime-global",
        default_value = true,
        order = "d3"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-shared-team-chat",
        setting_type = "runtime-global",
        default_value = true,
        order = "d4"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-shared-spawns",
        setting_type = "runtime-global",
        default_value = true,
        order = "d5"
    },
    {
        type = "int-setting",
        name = "oarc-mod-number-of-players-per-shared-spawn",
        setting_type = "runtime-global",
        default_value = 4,
        minimum_value = 2,
        maximum_value = 10,
        order = "d6"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-friendly-fire",
        setting_type = "runtime-global",
        default_value = false,
        order = "d7"
    },

    {
        type = "string-setting",
        name = "oarc-mod-main-force-name",
        setting_type = "runtime-global",
        default_value = "Main Force",
        order = "e1"
    },
    {
        type = "string-setting",
        name = "oarc-mod-default-surface",
        setting_type = "runtime-global",
        default_value = "nauvis",
        order = "e2"
    },

    {
        type = "bool-setting",
        name = "oarc-mod-scale-resources-around-spawns",
        setting_type = "runtime-global",
        default_value = true,
        order = "f1"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-modified-enemy-spawning",
        setting_type = "runtime-global",
        default_value = true,
        order = "f2"
    },

    {
        type = "int-setting",
        name = "oarc-mod-minimum-online-time",
        setting_type = "runtime-global",
        default_value = 15,
        minimum_value = 0,
        maximum_value = 60,
        order = "f3"
    },
    {
        type = "int-setting",
        name = "oarc-mod-respawn-cooldown-min",
        setting_type = "runtime-global",
        default_value = 15,
        minimum_value = 0,
        maximum_value = 60,
        order = "f4"
    },

    {
        type = "bool-setting",
        name = "oarc-mod-enable-regrowth",
        setting_type = "runtime-global",
        default_value = true,
        order = "g1"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-world-eater",
        setting_type = "runtime-global",
        default_value = false,
        order = "g2"
    },
    {
        type = "bool-setting",
        name = "oarc-mod-enable-abandoned-base-cleanup",
        setting_type = "runtime-global",
        default_value = true,
        order = "g3"
    },


    -- Vanilla spawn point are not implemented yet.
    -- {
    --     type = "bool-setting",
    --     name = "oarc-mod-enable-vanilla-spawn-points",
    --     setting_type = "runtime-global",
    --     default_value = true
    -- },
    -- {
    --     type = "int-setting",
    --     name = "oarc-mod-number-of-vanilla-spawn-points",
    --     setting_type = "runtime-global",
    --     default_value = 5,
    --     minimum_value = 1,
    --     maximum_value = 10
    -- },
    -- {
    --     type = "int-setting",
    --     name = "oarc-mod-vanilla-spawn-point-spacing",
    --     setting_type = "runtime-global",
    --     default_value = 10,
    --     minimum_value = 5,
    --     maximum_value = 20
    -- },
})