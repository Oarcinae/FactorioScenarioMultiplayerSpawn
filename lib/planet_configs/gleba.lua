-- This config is used as the default config for the planet gleba.

---@type OarcConfigStartingItems
GLEBA_STARTER_ITEMS = table.deepcopy(NO_STARTER_ITEMS)

---@type OarcConfigSpawn
GLEBA_SPAWN_CONFIG = table.deepcopy(NAUVIS_SPAWN_CONFIG)
GLEBA_SPAWN_CONFIG.fill_tile = "highland-dark-rock-2"
GLEBA_SPAWN_CONFIG.liquid_tile = "gleba-deep-lake"
GLEBA_SPAWN_CONFIG.tree_entity = nil
GLEBA_SPAWN_CONFIG.random_entities = {
    {name = "boompuff", count = 10},
    {name = "sunnycomb", count = 10},
    {name = "stingfrond", count = 10},
    {name = "funneltrunk", count = 10},
    {name = "teflilly", count = 10},
    {name = "slipstack", count = 10},
    {name = "cuttlepop", count = 10},
    {name = "water-cane", count = 10},
}

GLEBA_SPAWN_CONFIG.solid_resources =
{
    ["stone"] = {
        amount = 1000,
        size = 20,

        -- These are only used if not using automatic placing.
        x_offset = -29,
        y_offset = 16
    }
}

GLEBA_SPAWN_CONFIG.growth_resources =
{
    ["yumako"] = {
        tile = "natural-yumako-soil",
        entity = "yumako-tree",
        size = 20
    },
    ["jellystem"] = {
        tile = "natural-jellynut-soil",
        entity = "jellystem",
        size = 20
    },
    ["iron"] = {
        tile = "wetland-dead-skin",
        entity = "iron-stromatolite",
        size = 20
    },
    ["copper"] = {
        tile = "wetland-dead-skin",
        entity = "copper-stromatolite",
        size = 20
    },
}

GLEBA_SPAWN_CONFIG.fluid_resources = { }