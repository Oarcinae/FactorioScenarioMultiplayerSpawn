-- This config is used as the default config for the planet aquilo.

---@type OarcConfigStartingItems
AQUILO_STARTER_ITEMS = table.deepcopy(NO_STARTER_ITEMS)

---@type OarcConfigSpawn
AQUILO_SPAWN_CONFIG = table.deepcopy(NAUVIS_SPAWN_CONFIG)
AQUILO_SPAWN_CONFIG.fill_tile = "snow-crests"
AQUILO_SPAWN_CONFIG.liquid_tile = "ammoniacal-ocean-2"
AQUILO_SPAWN_CONFIG.tree_entity = nil
AQUILO_SPAWN_CONFIG.random_entities = {
    {name = "crude-oil", count = 3, amount = 2000000},
    {name = "lithium-brine", count = 3, amount = 500000},
    {name = "fluorine-vent", count = 3, amount = 500000},
    {name = "lithium-iceberg-big", count = 25},
    {name = "lithium-iceberg-huge", count = 25},
}

-- Ignore warn/danger areas, essentially disable them because the danger radius is used for resource scaling.
AQUILO_SPAWN_CONFIG.safe_area.warn_radius = AQUILO_SPAWN_CONFIG.safe_area.safe_radius
AQUILO_SPAWN_CONFIG.safe_area.danger_radius = AQUILO_SPAWN_CONFIG.safe_area.safe_radius


-- Aquilo should have a smaller spawn area
AQUILO_SPAWN_CONFIG.radius_modifier = 0.5

AQUILO_SPAWN_CONFIG.solid_resources = {}

AQUILO_SPAWN_CONFIG.fluid_resources = {
    -- ["crude-oil"] =
    -- {
    --     num_patches = 2,
    --     amount = 2000000,
    --     spacing = 6, -- Spacing between each patch, only used for automatic placing.

    --     -- These are only used if not using automatic placing.
    --     -- Starting position offset (relative to bottom/south of spawn area)
    --     x_offset_start = -3,
    --     y_offset_start = -10,
    --     -- Additional position offsets for each new oil patch (relative to previous oil patch)
    --     x_offset_next = 6,
    --     y_offset_next = 0
    -- },
    -- ["lithium-brine"] =
    -- {
    --     num_patches = 2,
    --     amount = 900000,
    --     spacing = 6, -- Spacing between each patch, only used for automatic placing.

    --     -- These are only used if not using automatic placing.
    --     -- Starting position offset (relative to bottom/south of spawn area)
    --     x_offset_start = -3,
    --     y_offset_start = -10,
    --     -- Additional position offsets for each new oil patch (relative to previous oil patch)
    --     x_offset_next = 6,
    --     y_offset_next = 0
    -- },
    -- ["fluorine-vent"] =
    -- {
    --     num_patches = 2,
    --     amount = 100000,
    --     spacing = 6, -- Spacing between each patch, only used for automatic placing.

    --     -- These are only used if not using automatic placing.
    --     -- Starting position offset (relative to bottom/south of spawn area)
    --     x_offset_start = -3,
    --     y_offset_start = -10,
    --     -- Additional position offsets for each new oil patch (relative to previous oil patch)
    --     x_offset_next = 6,
    --     y_offset_next = 0
    -- }
}