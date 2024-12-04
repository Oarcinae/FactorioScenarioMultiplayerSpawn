--Fix a missing migration in spawn choices table.
for player_name,entry in pairs(storage.spawn_choices) do
    if entry["surface"] ~= nil then
        entry.surface_name = entry["surface"]
    end
    if entry["host"] ~= nil then
        entry.host_name = entry["host"]
    end
    log("Migrated spawn choice entry: "..entry.surface_name.." for "..player_name)
end