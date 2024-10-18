-- If "enemy-easy" and "enemy-medium" forces still exist, merge them into "enemy" force.
if game.forces["enemy-easy"] then
    game.merge_forces("enemy-easy", "enemy")
end
if game.forces["enemy-medium"] then
    game.merge_forces("enemy-medium", "enemy")
end