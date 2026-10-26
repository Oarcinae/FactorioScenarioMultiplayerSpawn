data:extend({
    {
        type = "sprite",
        name = "oarc-classic-sprite-40",
        filename = "__oarc-classic__/icon_40x40.png",
        width = 40,
        height = 40
    },
})

-- See control.lua for the event type defs to see what each event provides you.
data:extend({
    -- A player was presented with the spawn options
    {
        type = "custom-event",
        name = "oarc-classic-on-spawn-choices-gui-displayed",
    },

    -- A spawn area was created (and is finished generating)
    {
        type = "custom-event",
        name = "oarc-classic-on-spawn-created",
    },

    -- A spawn area was REQUESTED to be removed. (Not that it has been removed already.)
    {
        type = "custom-event",
        name = "oarc-classic-on-spawn-remove-request",
    },

    -- A player was reset (also called when a player is removed)
    -- If you want just player removed, use native on_player_removed and/or on_pre_player_removed
    {
        type = "custom-event",
        name = "oarc-classic-on-player-reset",
    },

    -- A player was spawned (sent to a new spawn OR joined a shared spawn)
    {
        type = "custom-event",
        name = "oarc-classic-on-player-spawned",
    },

    -- A player moved from surface to space platform
    {
        type = "custom-event",
        name = "oarc-classic-character-surface-changed",
    },

    -- A chunk was generated near a unique spawn
    {
        type = "custom-event",
        name = "oarc-classic-on-chunk-generated-near-spawn",
    },

    -- An entry in storage.ocfg was changed
    {
        type = "custom-event",
        name = "oarc-classic-on-config-changed",
    },

    -- A player's custom GUI panel (top right special button) was created
    {
        type = "custom-event",
        name = "oarc-classic-on-mod-top-left-gui-created",
    },
})
