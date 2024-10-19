-- If "enemy-easy" and "enemy-medium" forces still exist, merge them into "enemy" force.
if game.forces["enemy-easy"] then
    game.merge_forces("enemy-easy", "enemy")
end
if game.forces["enemy-medium"] then
    game.merge_forces("enemy-medium", "enemy")
end

--If angle offset and angle final are the same as the default radian values, migrate them?
if (settings.global["oarc-mod-resource-placement-angle-offset"].value == 2) and
        (settings.global["oarc-mod-resource-placement-angle-final"].value == 4) then
    settings.global["oarc-mod-resource-placement-angle-offset"] = { value = 120 }
    settings.global["oarc-mod-resource-placement-angle-final"] = { value = 240 }
    global.ocfg.resource_placement.angle_offset = 120
    global.ocfg.resource_placement.angle_final = 240
    log("Migrated resource placement angle offset and final from default radian values to degrees")
end