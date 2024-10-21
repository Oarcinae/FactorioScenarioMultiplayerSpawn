-- Lets players share electricity via a special power pole and cross surface connections.
-- Also lets players share items via a linked-chest.

X_OFFSET_SHARING_POLE = 10
Y_OFFSET_SHARING_POLE = 0


function InitSharingPowerPoles()
    if storage.shared_power_poles == nil then
        ---@type LuaEntity[]
        storage.shared_power_poles = {}
    end

    if storage.shared_power_link == nil then
        local link_position = { x = X_OFFSET_SHARING_POLE, y = Y_OFFSET_SHARING_POLE }
        local link_pole = CreateSpecialPole(game.surfaces[HOLDING_PEN_SURFACE_NAME], link_position)
        storage.shared_power_link = link_pole
    end
end

---Create and connect a pair of power poles for a new base given surface and position.
---@param surface LuaSurface
---@param position MapPosition
---@return nil
function CreateSharedPowerPolePair(surface, position)

    if storage.shared_power_poles == nil then
        ---@type LuaEntity[]
        storage.shared_power_poles = {}
    end

    if storage.shared_power_link == nil then
        local link_position = { x = X_OFFSET_SHARING_POLE, y = Y_OFFSET_SHARING_POLE }
        local link_pole = CreateSpecialPole(game.surfaces[HOLDING_PEN_SURFACE_NAME], link_position)
        storage.shared_power_link = link_pole
    end

    --Create the base pole on the new spawn area surface and connect it to the hidden pole.
    local base_pole = CreateSpecialPole(surface, position)
    if not base_pole then
        log("ERROR - Failed to create shared power poles!? " .. serpent.block(position) .. " on " .. surface.name)
        return
    end
    local base_connector = base_pole.get_wire_connector(defines.wire_connector_id.pole_copper, true)
    local hidden_connector = storage.shared_power_link.get_wire_connector(defines.wire_connector_id.pole_copper, true)
    base_connector.connect_to(hidden_connector, false, defines.wire_origin.script)

    TemporaryHelperText(
        { "oarc-shared-power-pole-helper-txt" },
        surface,
        {position.x, position.y},
        TICKS_PER_MINUTE*2,
        "right"
    )
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