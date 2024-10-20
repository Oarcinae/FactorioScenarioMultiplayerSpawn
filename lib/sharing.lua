-- This handles the shared power logic for the Oarc scenario.
-- Won't work too hard on this since 2.0 might change things...


STARTING_X_OFFSET_SHARING_POLE = -5
Y_OFFSET_SHARING_POLE = 20

---Create and connect a pair of power poles for a new base given surface and position.
---@param surface LuaSurface
---@param position MapPosition
---@return nil
function CreateSharedPowerPolePair(surface, position)

    if storage.shared_power_poles == nil then
        ---@type LuaEntity[]
        storage.shared_power_poles = {}
    end

    --Get an open sharing pole from the holding pen surface if one exists, otherwise create a new one.
    local hidden_pole = FindSharedPowerPole()
    if not hidden_pole then
        local poles_count = table_size(storage.shared_power_poles)
        local new_position = { x = poles_count + STARTING_X_OFFSET_SHARING_POLE, y = Y_OFFSET_SHARING_POLE }
        hidden_pole = CreateSpecialPole(game.surfaces[HOLDING_PEN_SURFACE_NAME], new_position)
        if not hidden_pole then
            log("ERROR - Failed to create shared power poles!? " .. serpent.block(position) .. " on " .. surface.name)
            return
        end
        table.insert(storage.shared_power_poles, hidden_pole)
    end

    --Create the base pole on the new spawn area surface and connect it to the hidden pole.
    local base_pole = CreateSpecialPole(surface, position)
    if not base_pole then
        log("ERROR - Failed to create shared power poles!? " .. serpent.block(position) .. " on " .. surface.name)
        return
    end
    base_pole.connect_neighbour(hidden_pole)

    TemporaryHelperText(
        { "oarc-shared-power-pole-helper-txt" },
        surface,
        {position.x, position.y},
        TICKS_PER_MINUTE*2,
        "right"
    )
end

---Find the first shared power pole that doesn't exceed the max number of connections.
---@return LuaEntity?
function FindSharedPowerPole()
    if storage.shared_power_poles == nil then return nil end

    for _,pole in pairs(storage.shared_power_poles) do
        -- 5 is the hard coded engine limit and we need to leave one open for the connection to the next hidden pole.
        if pole.neighbours["copper"] and table_size(pole.neighbours["copper"]) < 4  then
            return pole
        end
    end

    return nil
end

---Creates a special pole on the surface at the given position on the neutral force.
---@param surface LuaSurface
---@param position MapPosition
---@return LuaEntity?
function CreateSpecialPole(surface, position)
    local pole = surface.create_entity
    {
        name="oarc-linked-power",
        position=position,
        force="neutral"
    }
    pole.destructible = false
    pole.minable = false
    pole.rotatable = false
    return pole
end

---Creates a special linked-chest on the surface at the given position on the neutral force.
---@param surface LuaSurface
---@param position MapPosition
---@return LuaEntity?
function CreateSharedChest(surface, position)
    local chest = surface.create_entity
    {
        name="oarc-linked-chest",
        position=position,
        force="neutral"
    }
    chest.destructible = false
    chest.minable = false
    chest.rotatable = false

    TemporaryHelperText(
        { "oarc-shared-chest-helper-txt" },
        surface,
        {position.x, position.y},
        TICKS_PER_MINUTE*2,
        "right"
    )

    return chest
end