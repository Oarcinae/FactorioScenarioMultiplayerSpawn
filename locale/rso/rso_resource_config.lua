
local function fillVanillaConfig()
    
    config["iron-ore"] = {
        type="resource-ore",
        
        -- general spawn params
        allotment=90, -- how common resource is
        spawns_per_region={min=1, max=1}, --number of chunks
        richness=20000,        -- resource_ore has only one richness value - resource-liquid has min/max
        
        size={min=15, max=25}, -- rough radius of area, too high value can produce square shaped areas
        min_amount=350,
        
        -- resource provided at starting location
        -- probability: 1 = 100% chance to be in starting area
        --              0 = resource is not in starting area
        starting={richness=8000, size=25, probability=1},
        
        multi_resource_chance=0.20, -- absolute value
        multi_resource={
            ["iron-ore"] = 2, -- ["resource_name"] = allotment
            ['copper-ore'] = 4,
            ["coal"] = 4,
            ["stone"] = 4,
        }
    }
    
    config["copper-ore"] = {
        type="resource-ore",
        
        allotment=80,
        spawns_per_region={min=1, max=1},
        richness=20000,
        size={min=15, max=25},
        min_amount=350,

        starting={richness=6000, size=25, probability=1},
        
        multi_resource_chance=0.20,
        multi_resource={
            ["iron-ore"] = 4,
            ['copper-ore'] = 2,
            ["coal"] = 4,
            ["stone"] = 4,
        }
    }
    
    config["coal"] = {
        type="resource-ore",
        
        allotment=80,
        
        spawns_per_region={min=1, max=1},
        size={min=15, max=25},
        richness=16000,
        min_amount=350,

        starting={richness=6000, size=20, probability=1},
        
        multi_resource_chance=0.30,
        multi_resource={
            ["crude-oil"] = 1,
            ["iron-ore"] = 3,
            ['copper-ore'] = 3,
        }
    }
    
    config["stone"] = {
        type="resource-ore",
        
        allotment=60,
        spawns_per_region={min=1, max=1},
        richness=12000,
        size={min=15, max=20},
        min_amount=250,

        starting={richness=5000, size=16, probability=1},
        
        multi_resource_chance=0.30,
        multi_resource={
            ["coal"] = 4,
            ["iron-ore"] = 3,
            ['copper-ore'] = 3,
        }
    }
    
    config["uranium-ore"] = {
        type="resource-ore",
        
        allotment=50,
        spawns_per_region={min=1, max=1},
        richness=10000,
        size={min=15, max=20},
        min_amount=500,

        starting={richness=2000, size=10, probability=1},
    }

    config["crude-oil"] = {
        type="resource-liquid",
        minimum_amount=10000,
        allotment=70,
        spawns_per_region={min=1, max=1},
        richness={min=400000, max=1000000}, -- richness per resource spawn
        size={min=3, max=7},
        
        starting={richness=400000, size=2, probability=1},
        
        multi_resource_chance=0.20,
        multi_resource={
            ["coal"] = 4,
        }
    }
end

local function fillEnemies()
    
    config["enemy-base"] = {
        type="entity",
        force="enemy",
        clear_range = {6, 6},
        
        spawns_per_region={min=2,max=4},
        size={min=2,max=4},
        size_per_region_factor=0.3,
        richness=3,
        
        absolute_probability=absolute_enemy_chance, -- chance to spawn in region
        probability_distance_factor=1.1, -- relative increase per region
        max_probability_distance_factor=3, -- absolute value
        
        along_resource_probability=0.20, -- chance to spawn in resource chunk anyway, absolute value. Can happen once per resource.
        
        sub_spawn_probability=0.1,     -- chance for this entity to spawn anything from sub_spawns table, absolute value
        sub_spawn_size={min=1, max=2}, -- in same chunk
        sub_spawn_distance_factor=1.01,
        sub_spawn_max_distance_factor=1.5,
        sub_spawns={
            ["small-worm-turret"]={
                min_distance=0,
                allotment=200,
                allotment_distance_factor=0.99,
                clear_range = {2, 2},
            },
            ["medium-worm-turret"]={
                min_distance=10,
                allotment=100,
                allotment_distance_factor=1.01,
                clear_range = {2, 2},
            },
            ["big-worm-turret"]={
                min_distance=20,
                allotment=100,
                allotment_distance_factor=1.015,
                clear_range = {2, 2},
            }
        }
    }
    
end

function loadResourceConfig()
    
    config={}
    
    fillVanillaConfig()
    fillEnemies()
    
    return config
end