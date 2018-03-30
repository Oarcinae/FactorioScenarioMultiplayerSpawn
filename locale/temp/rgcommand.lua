
local function RemoveTileGhosts()
    local surface = game.player.surface
    for c in surface.get_chunks() do
        for key, entity in pairs(surface.find_entities_filtered({area={{c.x * 32, c.y * 32}, {c.x * 32 + 32, c.y * 32 + 32}}, name= "tile-ghost"})) do  
            entity.destroy()
        end
    end
end

local function RemoveBlueprintedModulesGhosts()
    local surface = game.player.surface
    for c in surface.get_chunks() do
        for key, entity in pairs(surface.find_entities_filtered({area={{c.x * 32, c.y * 32}, {c.x * 32 + 32, c.y * 32 + 32}}, name= "item-request-proxy"})) do
            entity.destroy()
        end
    end
end

local function RemoveGhostEntities()
    local surface = game.player.surface
    for c in surface.get_chunks() do
        for key, entity in pairs(surface.find_entities_filtered({area={{c.x * 32, c.y * 32}, {c.x * 32 + 32, c.y * 32 + 32}}, name= "entity-ghost"})) do
          entity.destroy()
        end
    end
end


commands.add_command("rg", "remove ghosts", function(command)
    local player = game.players[command.player_index];
    if player ~= nil and player.admin then
        if (command.parameter ~= nil) then
            if command.parameter == "all" then
                RemoveTileGhosts()
                RemoveBlueprintedModulesGhosts()
                RemoveGhostEntities()
            elseif command.parameter == "tiles" then
                RemoveTileGhosts()
            elseif command.parameter == "modules" then
                RemoveBlueprintedModulesGhosts()
            elseif command.parameter == "entities" then
                RemoveGhostEntities()
            else
                player.print("remove all ghostes | tiles | modules | entities");
            end
        end
    end
end)
