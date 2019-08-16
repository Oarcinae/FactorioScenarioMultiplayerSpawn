-- oarc_enemy_evo.lua
-- Aug 2019
-- Stuff related to calculating group size and evo values.

-- Evo lerp stuff taken from here:
-- https://hastebin.com/udakacavap.js and Factorio Wiki
local biter_weight_table = {
    {"small-biter",    {{0.0, 0.3}, {0.6, 0.0}}},
    {"medium-biter",   {{0.2, 0.0}, {0.6, 0.3}, {0.7, 0.1}}},
    {"big-biter",      {{0.5, 0.0}, {1.0, 0.4}}},
    {"behemoth-biter", {{0.9, 0.0}, {1.0, 0.3}}}
}

local spitter_weight_table = {
    {"small-biter",      {{0.0, 0.3}, {0.35, 0.0}}},
    {"small-spitter",    {{0.25, 0.0}, {0.5, 0.3}, {0.7, 0.0}}},
    {"medium-spitter",   {{0.4, 0.0}, {0.7, 0.3}, {0.9, 0.1}}},
    {"big-spitter",      {{0.5, 0.0}, {1.0, 0.4}}},
    {"behemoth-spitter", {{0.9, 0.0}, {1.0, 0.3}}}
}

-- calculates the interpolated value
local function lerp(low, high, pos)
    local s = high[1] - low[1]
    local l = (pos - low[1]) / s
    return ((low[2] * (1-l)) + (high[2] * l))
end

-- gets the weight list
local function getValues(map, evo)
    local result = {}
    local sum = 0

    for k,v in pairs(map) do
        local list = v[2];
        local low = list[1];
        local high = list[#list];

        for k2,v2 in pairs(list) do
            if ((v2[1] <= evo) and (v2[1] >  low[1])) then
                low = v2
            end
            if ((v2[1] >= evo) and (v2[1] < high[1])) then
                high = v2
            end
        end

        local val = nil;
        if (evo <= low[1]) then
            val = low[2]

        elseif (evo >= high[1]) then
            val = high[2]

        else
            val = lerp(low, high, evo)
        end
        sum = sum + val;
        table.insert(result, {v[1], val})
    end

    local total = 0
    for _,v in pairs(result) do
        v[2] = v[2] / sum
        total = total + v[2]
        v[2] = math.ceil(total*100)
        v[2] = math.min(v[2], 100)
        v[2] = math.max(0, v[2])
    end

    return result
end

-- Calculate the weight lists for a given evo and return the table.
function CalculateEvoChanceListBiters(evo)
    return getValues(biter_weight_table, evo)
end
function CalculateEvoChanceListSpitters(evo)
    return getValues(spitter_weight_table, evo)
end

-- Roll the dice on an enemy given the chance list created.
function GetEnemyFromChanceList(chance_list)

    if ((chance_list == nil) or (#chance_list == 0)) then
        log("ERROR - need a valid chance list!")
        return "small-biter"
    end

    local rand = math.random(0, 100)
    for _,v in pairs(chance_list) do
        if (rand < v[2]) then
            return v[1]
        end
    end

    return "small-biter"
end


-- Gives evo and size contribution from play time (of a given player).
function GetPlayerTimeEvoSize(play_time_ticks)
    local evo = 0
    local size = 0
    local p = global.oe_params

    local hrs = play_time_ticks/TICKS_PER_HOUR
    local hrs_factor = math.min(hrs/p.player_time_peak_hours, 1)

    local evo = math.min(hrs_factor*p.player_time_evo_factor,
                            p.player_time_evo_factor)
    local size = math.min(hrs_factor*p.player_time_size_factor,
                            p.player_time_size_factor)

    return evo,size
end

-- Gives evo and size contribution from pollution (in target chunk)
function GetPollutionEvoSize(pollution_amount)
    local evo = 0
    local size = 0
    local p = global.oe_params

    local pol_factor = math.min(pollution_amount/p.pollution_peak_amnt, 1)

    local evo = math.min(pol_factor*p.pollution_evo_factor,
                            p.pollution_evo_factor)
    local size = math.min(pol_factor*p.pollution_size_factor,
                            p.pollution_size_factor)

    return evo,size
end

-- Gives evo and size contribution from pollution (in target chunk)
function GetTechLevelEvoSize(tech_level)
    local evo = 0
    local size = 0
    local p = global.oe_params

    local tech_factor = math.min(tech_level/p.tech_peak_count, 1)

    local evo = math.min(tech_factor*p.tech_evo_factor,
                            p.tech_evo_factor)
    local size = math.min(tech_factor*p.tech_size_factor,
                            p.tech_size_factor)

    return evo,size
end

-- Get the evo and size given optional params
-- args = {player, force_index, surface, target_pos, min_evo, max_eevo, min_size, max_size}
function GetEnemyGroup(args)

    -- Default values
    local evo = 0
    local size = 1

    -- Temp holders
    local e,s = 0
    local p = global.oe_params

    -- Given a player, use that for time played AND for player force.
    if (args.player and args.player.connected) then
        local ticks_online = args.player.online_time
        local tech_levels = global.oe.tech_levels[args.player.force.index]

        e,s = GetPlayerTimeEvoSize(ticks_online)
        evo = evo + e
        size = size + s

        e,s = GetTechLevelEvoSize(tech_levels)
        evo = evo + e
        size = size + s

    -- Support only force given, no player (should be RARE)
    elseif (args.force_index) then
        local tech_levels = global.oe.tech_levels[args.force_index]

        e,s = GetTechLevelEvoSize(tech_levels)
        evo = evo + e
        size = size + s
    end

    log("First size=" .. string.format("%.3f", size) .. " evo=".. string.format("%.3f", evo))

    -- Size/Evo from pollution
    if (args.surface and args.target_pos) then
        local pollution = args.surface.get_pollution(args.target_pos)

        e,s = GetPollutionEvoSize(pollution)
        evo = evo + e
        size = size + s
    end

    log("Second size=" .. string.format("%.3f", size) .. " evo=".. string.format("%.3f", evo))

    -- Optional Clamps (before randomization)
    if (args.min_evo) then
        if (evo < args.min_evo) then evo = args.min_evo end
    end
    if (args.max_evo) then
        if (evo < args.max_evo) then evo = args.max_evo end
    end
    if (args.min_size) then
        if (size < args.min_size) then size = args.min_size end
    end
    if (args.max_size) then
        if (size < args.max_size) then size = args.max_size end
    end

    -- Randomize a bit (upwards only)
    evo = evo + math.random()*math.random()*p.rand_evo_amnt
    size = size + math.random()*math.random()*p.rand_size_amnt

    -- Safety Clamps
    if (evo > 1) then evo = 1 end
    if (evo < 0) then evo = 0 end
    if (size > p.attack_size_max) then size = p.attack_size_max end
    if (size < p.attack_size_min) then size = p.attack_size_min end

    -- Size should be an int.
    size = math.ceil(size)

    log("Final: size=" .. string.format("%.3f", size) .. " evo=".. string.format("%.3f", evo))

    return evo,size
end

-- Returns a new timer in seconds scaled to given play time.
function GetRandomizedPlayerTimer(play_time_seconds, additional_offset)
    local p = global.oe_params

    -- More time played = Faster attacks
    local time_factor = play_time_seconds / (p.player_time_peak_hours*3600)
    local adjusted_minimum = (p.seconds_between_attacks_max)
                            -(p.seconds_between_attacks_max*time_factor)
                            +p.seconds_between_attacks_min
    -- Add some +/- random seconds as well.
    local final_seconds = adjusted_minimum + additional_offset +
                (math.random()*math.random(-p.seconds_between_attacks_rand,
                                            p.seconds_between_attacks_rand))

    -- Validate absolute minimum of X seconds
    if (final_seconds <= 15) then return 15 end

    return math.floor(final_seconds)
end