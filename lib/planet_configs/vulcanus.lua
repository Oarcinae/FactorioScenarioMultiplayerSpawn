-- This config is used as the default config for the planet vulcanus.

---@type OarcConfigStartingItems
VULCANUS_STARTER_ITEMS = table.deepcopy(NO_STARTER_ITEMS)

---@type OarcConfigSpawn
VULCANUS_SPAWN_CONFIG = table.deepcopy(NAUVIS_SPAWN_CONFIG)
VULCANUS_SPAWN_CONFIG.fill_tile = "volcanic-ash-flats"
VULCANUS_SPAWN_CONFIG.liquid_tile = "lava"
VULCANUS_SPAWN_CONFIG.tree_entity = "ashland-lichen-tree"
VULCANUS_SPAWN_CONFIG.random_entities = {
    {name = "vulcanus-chimney", count = 10},
    {name = "vulcanus-chimney-truncated", count = 10},
    {name = "huge-volcanic-rock", count = 10},
    {name = "big-volcanic-rock", count = 10},
    {name = "ashland-lichen-tree-flaming", count = 5},
    {name = "ashland-lichen-tree", count = 5},
}

-- These don't matter in the current implementation.
-- VULCANUS_SPAWN_CONFIG.safe_area.warn_reduction = 0
-- VULCANUS_SPAWN_CONFIG.safe_area.danger_reduction = 0

-- Feels like more space might be helpful on Vulcanus?
VULCANUS_SPAWN_CONFIG.radius_modifier = 1

VULCANUS_SPAWN_CONFIG.solid_resources =
{
    ["coal"] = {
        amount = 2000,
        size = 25,

        -- These are only used if not using automatic placing.
        x_offset = -29,
        y_offset = 16
    },
    ["calcite"] = {
        amount = 1000,
        size = 25,

        -- These are only used if not using automatic placing.
        x_offset = -28,
        y_offset = -3
    },
    ["tungsten-ore"] = {
        amount = 250,
        size = 25,

        -- These are only used if not using automatic placing.
        x_offset = -28,
        y_offset = -3
    }
}

VULCANUS_SPAWN_CONFIG.fluid_resources = {
    ["sulfuric-acid-geyser"] =
    {
        num_patches = 4,
        amount = 9000000,
        spacing = 6, -- Spacing between each patch, only used for automatic placing.

        -- These are only used if not using automatic placing.
        -- Starting position offset (relative to bottom/south of spawn area)
        x_offset_start = -3,
        y_offset_start = -10,
        -- Additional position offsets for each new oil patch (relative to previous oil patch)
        x_offset_next = 6,
        y_offset_next = 0
    }
}