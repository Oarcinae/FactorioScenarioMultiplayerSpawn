---For each planet's surface, mark the center of the map permanently safe from regrowth.
-- If we can detect and redirect cargo-pods, then this can be removed.

-- TODO: Hopefully a temporary measure to make sure map center never gets deleted.
-- If we can detect and redirect cargo-pods, then this can be removed.

-- Loop through each surface
for _,surface in pairs(game.surfaces) do
    if (storage.rg[surface.name] ~= nil) then
        for i = -2, 2 do
            for j = -2, 2 do
                MarkChunkSafe(surface.name, { x = i, y = j }, true)
            end
        end
        log("Applying migration for V2.1.13: Marked center of "..surface.name.." safe from regrowth.")
    end
end
