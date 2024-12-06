-- This config is used as the default config for the planet gleba.

---@type OarcConfigStartingItems
GLEBA_STARTER_ITEMS = table.deepcopy(NO_STARTER_ITEMS)

---@type OarcConfigSpawn
GLEBA_SPAWN_CONFIG = table.deepcopy(NAUVIS_SPAWN_CONFIG)
GLEBA_SPAWN_CONFIG.fill_tile = "lowland-olive-blubber"
GLEBA_SPAWN_CONFIG.liquid_tile = "gleba-deep-lake"
GLEBA_SPAWN_CONFIG.tree_entity = "funneltrunk"
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

-- Make the warning and danger areas a bit bigger for this planet.
GLEBA_SPAWN_CONFIG.safe_area.warn_radius = 16
GLEBA_SPAWN_CONFIG.safe_area.danger_radius = 32

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

GLEBA_SPAWN_CONFIG.fluid_resources = { }

--TODO: Add support for specific location placement. OR remove it entirely.
GLEBA_SPAWN_CONFIG.gleba_resources =
{
    ["yumako"] = {
        tile = "natural-yumako-soil",
        entities = {"yumako-tree"},
        size = 25,
        density = 0.05
    },
    ["jellystem"] = {
        tile = "natural-jellynut-soil",
        entities = {"jellystem"},
        size = 25,
        density = 0.05
    },
    ["iron"] = {
        tile = "wetland-green-slime",
        entities = {"iron-stromatolite", "copper-stromatolite"},
        size = 25,
        density = 0.10
    },
}