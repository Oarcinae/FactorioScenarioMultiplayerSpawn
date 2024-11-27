
-- I created a few custom entities for making it clear that the shared power poles and chests are special.

local oarc_linked_chest=table.deepcopy(data.raw["container"]["wooden-chest"])
oarc_linked_chest.type="linked-container"
oarc_linked_chest.name="oarc-linked-chest"
oarc_linked_chest.inventory_type="with_filters_and_bar"
oarc_linked_chest.inventory_size=settings.startup["oarc-mod-linked-chest-size"].value --[[@as integer]]
oarc_linked_chest.picture.layers[1].filename = "__oarc-mod__/graphics/hr-oarc-linked-chest.png"


local oarc_linked_power=table.deepcopy(data.raw["electric-pole"]["small-electric-pole"])
oarc_linked_power.name="oarc-linked-power"
oarc_linked_power.pictures.layers[1].filename = "__oarc-mod__/graphics/hr-oarc-electric-pole.png"

data:extend({
    {
        type = "sprite",
        name = "oarc-mod-sprite-40",
        filename = "__oarc-mod__/icon_40x40.png",
        width = 40,
        height = 40
    },
    oarc_linked_chest, oarc_linked_power,  
})

-- See control.lua for the event type defs to see what each event provides you.
data:extend({
    -- A player was presented with the spawn options
    {
        type = "custom-event",
        name = "oarc-mod-on-spawn-choices-gui-displayed",
    },

    -- A spawn area was created (and is finished generating)
    {
        type = "custom-event",
        name = "oarc-mod-on-spawn-created",
    },

    -- A spawn area was REQUESTED to be removed. (Not that it has been removed already.)
    {
        type = "custom-event",
        name = "oarc-mod-on-spawn-remove-request",
    },

    -- A player was reset (also called when a player is removed)
    -- If you want just player removed, use native on_player_removed and/or on_pre_player_removed
    {
        type = "custom-event",
        name = "oarc-mod-on-player-reset",
    },

    -- A player was spawned (sent to a new spawn OR joined a shared spawn)
    {
        type = "custom-event",
        name = "oarc-mod-on-player-spawned",
    },

    -- A player moved from surface to space platform
    {
        type = "custom-event",
        name = "oarc-mod-character-surface-changed",
    },
})


-- Make coins not hidden
data.raw["item"]["coin"].hidden = false