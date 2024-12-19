-- This is a fix for a bug where a buddy was deleted but still exist in the spawn info.
for _,spawns in pairs(storage.unique_spawns) do
    for _,spawn in pairs(spawns) do
        -- If the name is not nil, but the player doesn't exist, nil it out.
        if (spawn.buddy_name ~= nil) and (game.players[spawn.buddy_name] == nil) then
            spawn.buddy_name = nil
        end
    end
end