data:extend({
    {
        type = "string-setting",
        name = "oarc-classic-welcome-msg-title",
        setting_type = "runtime-global",
        default_value = "Insert Server Title Here!",
        order = "a1"
    },
    {
        type = "string-setting",
        name = "oarc-classic-welcome-msg",
        setting_type = "runtime-global",
        default_value = "Insert Server Welcome Message Here!",
        order = "a2"
    },
    {
        type = "string-setting",
        name = "oarc-classic-discord-invite",
        setting_type = "runtime-global",
        default_value = "Insert Discord Invite Here!",
        order = "a4"
    },

    {
        type = "bool-setting",
        name = "oarc-classic-allow-oarc-style-spawn",
        setting_type = "runtime-global",
        default_value = false,
        order = "b3"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-allow-moats-around-spawns",
        setting_type = "runtime-global",
        default_value = true,
        order = "b4"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-enable-moat-bridging",
        setting_type = "runtime-global",
        default_value = false,
        order = "b5"
    },

    {
        type = "int-setting",
        name = "oarc-classic-starting-points-count",
        setting_type = "runtime-global",
        default_value = 16,
        minimum_value = 1,
        maximum_value = 128,
        order = "c2"
    },
    {
        type = "int-setting",
        name = "oarc-classic-starting-points-spacing-chunks",
        setting_type = "runtime-global",
        default_value = 100,
        minimum_value = 20,
        maximum_value = 1000,
        order = "c3"
    },

    {
        type = "bool-setting",
        name = "oarc-classic-enable-offline-protection",
        setting_type = "runtime-global",
        default_value = true,
        order = "d2"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-reset-evolution-on-new-spawn",
        setting_type = "runtime-global",
        default_value = false,
        order = "d21"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-enable-shared-team-vision",
        setting_type = "runtime-global",
        default_value = true,
        order = "d3"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-enable-shared-team-chat",
        setting_type = "runtime-global",
        default_value = true,
        order = "d31"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-enable-friendly-teams",
        setting_type = "runtime-global",
        default_value = true,
        order = "d32"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-enable-cease-fire",
        setting_type = "runtime-global",
        default_value = true,
        order = "d33"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-enable-shared-spawns",
        setting_type = "runtime-global",
        default_value = true,
        order = "d5"
    },
    {
        type = "int-setting",
        name = "oarc-classic-number-of-players-per-shared-spawn",
        setting_type = "runtime-global",
        default_value = 3,
        minimum_value = 2,
        maximum_value = 10,
        order = "d6"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-enable-friendly-fire",
        setting_type = "runtime-global",
        default_value = false,
        order = "d7"
    },

    {
        type = "string-setting",
        name = "oarc-classic-default-surface",
        setting_type = "runtime-global",
        default_value = "nauvis",
        order = "e2"
    },

    {
        type = "int-setting",
        name = "oarc-classic-minimum-online-time",
        setting_type = "runtime-global",
        default_value = 15,
        minimum_value = 0,
        maximum_value = 60,
        order = "f3"
    },
    {
        type = "int-setting",
        name = "oarc-classic-respawn-cooldown-min",
        setting_type = "runtime-global",
        default_value = 5,
        minimum_value = 0,
        maximum_value = 60,
        order = "f4"
    },

    {
        type = "bool-setting",
        name = "oarc-classic-enable-regrowth",
        setting_type = "runtime-global",
        default_value = false,
        order = "g1"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-enable-world-eater",
        setting_type = "runtime-global",
        default_value = false,
        order = "g2"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-enable-abandoned-base-cleanup",
        setting_type = "runtime-global",
        default_value = true,
        order = "g3"
    },
    {
        type = "int-setting",
        name = "oarc-classic-regrowth-cleanup-interval-min",
        setting_type = "runtime-global",
        default_value = 60,
        minimum_value = 15,
        maximum_value = 180,
        order = "g4"
    },

    {
        type = "int-setting",
        name = "oarc-classic-spawn-general-radius-tiles",
        setting_type = "runtime-global",
        default_value = 64,
        minimum_value = 32,
        maximum_value = 320,
        order = "h1"
    },
    {
        type = "int-setting",
        name = "oarc-classic-spawn-general-moat-width-tiles",
        setting_type = "runtime-global",
        default_value = 8,
        minimum_value = 1,
        maximum_value = 32,
        order = "h2"
    },
    {
        type = "int-setting",
        name = "oarc-classic-spawn-general-tree-width-tiles",
        setting_type = "runtime-global",
        default_value = 5,
        minimum_value = 1,
        maximum_value = 32,
        order = "h3"
    },
    {
        type = "string-setting",
        name = "oarc-classic-spawn-general-enable-resources-circle-shape",
        setting_type = "runtime-global",
        default_value = "circle",
        allowed_values = {"circle", "square"},
        order = "h4"
    },
    {
        type = "bool-setting",
        name = "oarc-classic-spawn-general-enable-force-tiles",
        setting_type = "runtime-global",
        default_value = true,
        order = "h5"
    },    {
        type = "string-setting",
        name = "oarc-classic-spawn-general-shape",
        setting_type = "runtime-global",
        default_value = "circle",
        allowed_values = {"circle", "octagon", "square"},
        order = "h6"
    },

    {
        type = "bool-setting",
        name = "oarc-classic-resource-placement-enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "i1"
    },
    {
        type = "int-setting",
        name = "oarc-classic-resource-placement-distance-to-edge",
        setting_type = "runtime-global",
        default_value = 20,
        minimum_value = 0,
        maximum_value = 96,
        order = "i2"
    },
    {
        type = "int-setting",
        name = "oarc-classic-resource-placement-degrees-offset",
        setting_type = "runtime-global",
        default_value = 120,
        minimum_value = 0,
        maximum_value = 359,
        order = "i3"
    },
    {
        type = "int-setting",
        name = "oarc-classic-resource-placement-degrees-final",
        setting_type = "runtime-global",
        default_value = 240,
        minimum_value = 0,
        maximum_value = 359,
        order = "i4"
    },
    {
        type = "int-setting",
        name = "oarc-classic-resource-placement-vertical-offset",
        setting_type = "runtime-global",
        default_value = 20,
        minimum_value = 0,
        maximum_value = 96,
        order = "i5"
    },
    {
        type = "int-setting",
        name = "oarc-classic-resource-placement-horizontal-offset",
        setting_type = "runtime-global",
        default_value = 20,
        minimum_value = 0,
        maximum_value = 96,
        order = "i6"
    },
    {
        type = "int-setting",
        name = "oarc-classic-resource-placement-linear-spacing",
        setting_type = "runtime-global",
        default_value = 6,
        minimum_value = 0,
        maximum_value = 32,
        order = "i7"
    },
    {
        type = "double-setting",
        name = "oarc-classic-resource-placement-size-multiplier",
        setting_type = "runtime-global",
        default_value = 1.0,
        minimum_value = 0,
        maximum_value = 10,
        order = "i8"
    },
    {
        type = "double-setting",
        name = "oarc-classic-resource-placement-amount-multiplier",
        setting_type = "runtime-global",
        default_value = 1.0,
        minimum_value = 0,
        maximum_value = 10,
        order = "i9"
    },
})