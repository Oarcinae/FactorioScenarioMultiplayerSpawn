-- THIS is used as the default starting items on all surfaces if no other settings are provided!
---@type OarcConfigStartingItems
FULGORA_STARTER_ITEMS = table.deepcopy(NO_STARTER_ITEMS)

---@type OarcConfigSpawn
FULGORA_SPAWN_CONFIG = table.deepcopy(NAUVIS_SPAWN_CONFIG)
FULGORA_SPAWN_CONFIG.fill_tile = "fulgoran-paving"
FULGORA_SPAWN_CONFIG.liquid_tile = "oil-ocean-deep"
FULGORA_SPAWN_CONFIG.tree_entity = nil
FULGORA_SPAWN_CONFIG.random_entities = {
    {name = "fulgoran-ruin-vault", count = 2},
    {name = "fulgoran-ruin-stonehenge", count = 5},
    {name = "fulgoran-ruin-colossal", count = 5},
    {name = "fulgoran-ruin-medium", count = 20},
    {name = "fulgoran-ruin-small", count = 30},
    {name = "fulgurite", count = 20},
    {name = "fulgurite-small", count = 30},
}
-- I think Fulgora should be smaller in general.
FULGORA_SPAWN_CONFIG.radius_modifier = 0.7

FULGORA_SPAWN_CONFIG.solid_resources =
{
    ["scrap"] = {
        amount = 10000,
        size = 25,

        -- These are only used if not using automatic placing.
        x_offset = -29,
        y_offset = 16
    }
}

FULGORA_SPAWN_CONFIG.fluid_resources = { }