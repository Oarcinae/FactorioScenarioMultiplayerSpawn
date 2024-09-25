
-- I created a few custom entities for making it clear that the shared power poles and chests are special.

local oarc_linked_chest=table.deepcopy(data.raw["container"]["wooden-chest"])
oarc_linked_chest.type="linked-container"
oarc_linked_chest.name="oarc-linked-chest"
oarc_linked_chest.inventory_type="with_filters_and_bar"
oarc_linked_chest.inventory_size=settings.startup["oarc-mod-linked-chest-size"].value --[[@as integer]]
oarc_linked_chest.picture.layers[1].filename = "__oarc-mod__/graphics/oarc-linked-chest.png"
oarc_linked_chest.picture.layers[1].hr_version.filename = "__oarc-mod__/graphics/hr-oarc-linked-chest.png"


local oarc_linked_power=table.deepcopy(data.raw["electric-pole"]["small-electric-pole"])
oarc_linked_power.name="oarc-linked-power"
oarc_linked_power.pictures.layers[1].filename = "__oarc-mod__/graphics/oarc-electric-pole.png"
oarc_linked_power.pictures.layers[1].hr_version.filename = "__oarc-mod__/graphics/hr-oarc-electric-pole.png"

data:extend({
    {
        type = "sprite",
        name = "oarc-mod-sprite-40",
        filename = "__oarc-mod__/icon_40x40.png",
        width = 40,
        height = 40
    },
    oarc_linked_chest, oarc_linked_power
})
