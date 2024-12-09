-- THIS is used as the default starting items on all surfaces if no other settings are provided!
---@type OarcConfigStartingItems
NAUVIS_STARTER_ITEMS =
{
    player_start_items = {
        ["iron-plate"] = 8,
        ["wood"] = 1,
        ["pistol"] = 1,
        ["firearm-magazine"] = 10,
        ["burner-mining-drill"] = 1,
        ["stone-furnace"] = 1
    },
    player_respawn_items = {
        ["pistol"] = 1,
        ["firearm-magazine"] = 10
    },

    crashed_ship = true,
    crashed_ship_resources = {
        ["firearm-magazine"] = 8 -- Max of 5 inventory slots!
    },
    crashed_ship_wreakage = {
        ["iron-plate"] = 8 -- I don't recommend more than 1 item type here!
    },
}

-- THIS is used when disabling starter items on a surface?
---@type OarcConfigStartingItems
NO_STARTER_ITEMS =
{
    player_start_items = { },
    player_respawn_items = {
        ["pistol"] = 1,
        ["firearm-magazine"] = 10
    },

    crashed_ship = false,
    crashed_ship_resources = {
        -- ["firearm-magazine"] = 8 -- Max of 5 inventory slots!
    },
    crashed_ship_wreakage = {
        -- ["iron-plate"] = 8 -- I don't recommend more than 1 item type here!
    },
}

-- THIS is used as the default spawn config  on all surfaces if no other settings are provided!
---@type OarcConfigSpawn
NAUVIS_SPAWN_CONFIG =
{
    -- Used to fill in area that collides with water layer, IF force grass is enabled.
    fill_tile = "grass-1",

    -- Used to fill in the moat and the liquid strip at the top of the circle if no moat.
    liquid_tile = "water",

    -- Used to circle the base. Set to nil to disable.
    tree_entity = "tree-02",

    -- Random entities to place around the base.
    random_entities = {
        {name = "big-rock", count = 5},
        {name = "huge-rock", count = 5},
        {name = "dead-grey-trunk", count = 5},
        {name = "big-sand-rock", count = 5},
    },

    -- Used to modify the size of the base.
    radius_modifier = 1,

    -- Safe Spawn Area Options
    -- The default settings here are balanced for my recommended map gen settings (close to train world).
    safe_area =
    {
        -- Safe area has no aliens
        -- This is the radius in chunks of safe area.
        safe_radius = 6,

        -- Warning area has significantly reduced aliens
        -- This is the radius in chunks of warning area.
        warn_radius = 12,

        -- 1 : X (spawners alive : spawners destroyed) in this area
        warn_reduction = 20,

        -- Danger area has slightly reduced aliens
        -- This is the radius in chunks of danger area.
        danger_radius = 24,

        -- 1 : X (spawners alive : spawners destroyed) in this area
        danger_reduction = 5,
    },

    -- Location of water strip within the spawn area (2 horizontal rows)
    -- The offset is from the TOP (NORTH) of the spawn area.
    water = {
        x_offset = -4,
        y_offset = 10,
        length = 8,
    },

    -- Location of shared power pole within the spawn area (if enabled)
    -- The offset is from the RIGHT (WEST) of the spawn area.
    shared_power_pole_position = {
        x_offset=-10,
        y_offset=0
    },

    -- Location of shared chest within the spawn area (if enabled)
    -- The offset is from the RIGHT (WEST) of the spawn area.
    shared_chest_position = {
        x_offset=-10,
        y_offset=1
    },

    -- Solid resource tiles
    -- If you are running with mods that add or change resources, you'll want to customize this.
    -- Offsets only are applicable if auto placement is disabled. Offsets are from CENTER of spawn area.
    solid_resources = {
        ["iron-ore"] = {
            amount = 1500,
            size = 21,

            -- These are only used if not using automatic placing.
            x_offset = -29,
            y_offset = 16
        },
        ["copper-ore"] = {
            amount = 1200,
            size = 21,

            -- These are only used if not using automatic placing.
            x_offset = -28,
            y_offset = -3
        },
        ["stone"] = {
            amount = 1200,
            size = 21,

            -- These are only used if not using automatic placing.
            x_offset = -27,
            y_offset = -34
        },
        ["coal"] = {
            amount = 1200,
            size = 21,

            -- These are only used if not using automatic placing.
            x_offset = -27,
            y_offset = -20
        }
    },

    -- Fluid resource patches like oil
    -- If you are running with mods that add or change resources, you'll want to customize this.
    -- The offset is from the BOTTOM (SOUTH) of the spawn area.
    fluid_resources =
    {
        ["crude-oil"] =
        {
            num_patches = 2,
            amount = 900000,
            spacing = 6, -- Spacing between each patch, only used for automatic placing.

            -- These are only used if not using automatic placing.
            -- Starting position offset (relative to bottom/south of spawn area)
            x_offset_start = -3,
            y_offset_start = -10,
            -- Additional position offsets for each new oil patch (relative to previous oil patch)
            x_offset_next = 6,
            y_offset_next = 0
        }
    },

    gleba_resources = {},

    player_spawn_offset = nil,
}

---@type OarcConfigSurface
NAUVIS_SURFACE_CONFIG =
{
    starting_items = NAUVIS_STARTER_ITEMS,
    spawn_config = NAUVIS_SPAWN_CONFIG
}