-- Oarc's Separated Spawn Scenario
-- I wanted to create a scenario that allows you to spawn in separate locations
-- Additionally, it allows you to either join the main force or go it alone.
-- All teams(forces) are always neutral to each other (ceasefire mode).
-- 
-- Each spawn location has some basic starter resources enforced, except for
-- the main default 0,0 starting location
-- 
-- Around each spawn area, a safe area is created and then a reduced alien areaas
-- as well. See config options for settings
-- 
-- When someone dies, they are given the option to join the default team
-- if they were not already.

-- config options

-- Near spawn option is on the edge of generated chunks
-- On a large map, this may be quite far from spawn.
local MIN_CHUNK_SPAWN_DIST = 2

-- Far spawn options is this number of chunks past generated area
local FAR_CHUNK_SPAWN_DIST = 10

local FAR_MIN_DIST = 1000^2
local FAR_MAX_DIST = 6000^2

-- Start resource amountsmm
local START_IRON_AMOUNT = 1500
local START_COPPER_AMOUNT = 1000
local START_STONE_AMOUNT = 1500
local START_COAL_AMOUNT = 1500
local START_OIL_AMOUNT = 20000

-- Safe area has no aliens
-- +/- this in x and y direction
local SAFE_AREA_TILE_DIST = 250

-- Warning area has reduced aliens
-- +/- this in x and y direction
local WARNING_AREA_TILE_DIST = 500

-- 1 : X (spawners alive : spawners destroyed) in this area
local WARN_AREA_REDUCTION_RATIO = 15

-- Create a circle of land area for the spawn
local ENFORCE_LAND_AREA_TILE_DIST = 40
local ENFORCE_LAND_AREA_TILE_DIST_SQUARED = ENFORCE_LAND_AREA_TILE_DIST^2

-- Main force is what default players join
local MAIN_FORCE = "main_force"

-- Disable enemy expansion
local ENEMY_EXPANSION = false

-- Divide the alien factors by this number to reduce it (or multiply if < 1)
local ENEMY_POLLUTION_FACTOR_DIVISOR = 10
local ENEMY_DESTROY_FACTOR_DIVISOR = 1

-- Useful constants
local CHUNK_SIZE = 32
local MAX_FORCES = 64


-- Print debug only to me while testing.
-- Should remove this if you are hosting it yourself.
local function DebugPrint(msg)
    if ((game.players["Oarc"] ~= nil) and (global.oarcDebugEnabled)) then
        game.players["Oarc"].print("DEBUG: " .. msg)
    end
end


-- Simple function to get total number of items in table
function TableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- Give player these default items.
local function GivePlayerItems(player)
    player.insert{name="pistol", count=1}
    player.insert{name="firearm-magazine", count=10}
end

-- Additional starter only items
local function GivePlayerStarterItems(player)
    GivePlayerItems(player)
    player.insert{name="iron-plate", count=8}
    player.insert{name="burner-mining-drill", count = 1}
    player.insert{name="stone-furnace", count = 1}
end

-- Check if given position is in area bounding box
local function CheckIfInArea(point, area)
    if ((point.x > area.left_top.x) and (point.x < area.right_bottom.x)) then
        if ((point.y > area.left_top.y) and (point.y < area.right_bottom.y)) then
            return true
        end
    end
    return false
end

-- Ceasefire
-- All forces are always neutral
local function SetCeaseFireBetweenAllForces()
    for name,team in pairs(game.forces) do
        if name ~= "neutral" and name ~= "enemy" then
            for x,y in pairs(game.forces) do
                if x ~= "neutral" and x ~= "enemy" then
                    team.set_cease_fire(x,true)
                end
            end
        end
    end
end

-- Broadcast messages
local function SendBroadcastMsg(msg)
    for name,player in pairs(game.players) do
        player.print(msg)
    end
end


local function CreateNewSpawnCoordinates(spawn_distance, recursion_max)
    local position = {x=0,y=0}
    local chunkPos = {x=0,y=0}
    local randVec = {x=0,y=0}

    -- Create a random direction vector to look in
    while ((randVec.x == 0) and (randVec.y == 0))
    do 
        randVec.x = math.random(-3,3)
        randVec.y = math.random(-3,3)
    end
    DebugPrint("direction: x=" .. randVec.x .. ", y=" .. randVec.y)

    while(true)
    do
        
        -- Set some absolute limits.
        if ((math.abs(chunkPos.x) > 1000) or (math.abs(chunkPos.y) > 1000)) then
            break
        
        -- If chunk is already generated, keep looking
        elseif (game.surfaces["nauvis"].is_chunk_generated(chunkPos)) then
            chunkPos.x = chunkPos.x + randVec.x*spawn_distance
            chunkPos.y = chunkPos.y + randVec.y*spawn_distance
        
        -- Found a possible ungenerated area
        else
            
            chunkPos.x = chunkPos.x + (randVec.x*spawn_distance)
            chunkPos.y = chunkPos.y + (randVec.y*spawn_distance)

            -- If it's still ungenerated even further out, use that position.
            if (not game.surfaces["nauvis"].is_chunk_generated(chunkPos)) then
                position.x = (chunkPos.x*CHUNK_SIZE) + (CHUNK_SIZE/2)
                position.y = (chunkPos.y*CHUNK_SIZE) + (CHUNK_SIZE/2)
                break
            end
        end
    end

    -- Very dangerous and stupid recursive call.
    if (spawn_distance == FAR_CHUNK_SPAWN_DIST) then
        local distSqrd = position.x^2 + position.y^2
        if ((distSqrd < FAR_MIN_DIST) or (distSqrd > FAR_MAX_DIST)) then
            if (recursion_max == 0) then
                return {x=0,y=0}
            else
                DebugPrint("spawn: x=" .. position.x .. ", y=" .. position.y)
                return CreateNewSpawnCoordinates(spawn_distance, recursion_max-1)
            end
        end
    end

    DebugPrint("spawn: x=" .. position.x .. ", y=" .. position.y)
    return position
end

local my_label_style = {
    minimal_width = 450,
    maximal_width = 450,
    font_color = {r=1,g=1,b=1}
}

local my_note_style = {
    minimal_width = 450,
    maximal_height = 10,
    font = "default-small-semibold",
    font_color = {r=1,g=0.5,b=0.5}
}

local my_warning_style = {
    minimal_width = 450,
    maximal_width = 450,
    font_color = {r=1,g=0.1,b=0.1}
}

function ApplyStyle (guiIn, styleIn)
    for k,v in pairs(styleIn) do
        guiIn.style[k]=v
    end 
end

function DisplaySpawnOptions(player)
    player.gui.center.add{name = "spawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Spawn Options"}
    local spawnGui = player.gui.center.spawn_opts

    spawnGui.style.maximal_width = 450
    spawnGui.style.maximal_height = 650

    spawnGui.add{name = "warning_lbl1", type = "label",
                    caption="CHOOSE CAREFULLY - YOU ONLY GET ONE CUSTOM SPAWN POINT!"}
    spawnGui.add{name = "warning_spacer", type = "label",
                    caption=" "}
    ApplyStyle(spawnGui.warning_lbl1, my_warning_style)
    ApplyStyle(spawnGui.warning_spacer, my_label_style)

    spawnGui.add{name = "normal_spawn",
                    type = "button",
                    caption="Default Spawn"}
    spawnGui.add{name = "normal_spawn_lbl1", type = "label",
                    caption="This is the default spawn behavior of a vanilla game."}
    spawnGui.add{name = "normal_spawn_lbl2", type = "label",
                    caption="You join the default team in the center of the map."}
    spawnGui.add{name = "normal_spawn_spacer", type = "label",
                    caption=" "}
    ApplyStyle(spawnGui.normal_spawn_lbl1, my_label_style)
    ApplyStyle(spawnGui.normal_spawn_lbl2, my_label_style)
    ApplyStyle(spawnGui.normal_spawn_spacer, my_label_style)

    spawnGui.add{name = "isolated_spawn",
                    type = "button",
                    caption="Isolated Spawn"}
    spawnGui.add{name = "isolated_spawn_far",
                    type = "button",
                    caption="Isolated Spawn (Far Away)"}
    spawnGui.add{name = "isolated_spawn_lbl1", type = "label",
                    caption="You are spawned in a new area, with starting resources."}
    spawnGui.add{name = "isolated_spawn_lbl2", type = "label",
                    caption="You will still be part of the default team."}
    spawnGui.add{name = "isolated_spawn_spacer", type = "label",
                    caption=" "}
    ApplyStyle(spawnGui.isolated_spawn_lbl1, my_label_style)
    ApplyStyle(spawnGui.isolated_spawn_lbl2, my_label_style)
    ApplyStyle(spawnGui.isolated_spawn_spacer, my_label_style)

    spawnGui.add{name = "new_force",
                    type = "button",
                    caption="Separate Team"}
    spawnGui.add{name = "new_force_far",
                    type = "button",
                    caption="Separate Team (Far Away)"}
    spawnGui.add{name = "new_force_lbl1", type = "label",
                    caption="You are spawned in a new area, with starting resources."}
    spawnGui.add{name = "new_force_lbl2", type = "label",
                    caption="You will be on your own team. (No shared vision or research with others.)"}
    spawnGui.add{name = "new_force_lbl3", type = "label",
                    caption="Do not choose this option if you are new to the game!"}
    spawnGui.add{name = "new_force_spacer", type = "label",
                    caption=" "}
    ApplyStyle(spawnGui.new_force_lbl1, my_label_style)
    ApplyStyle(spawnGui.new_force_lbl2, my_warning_style)
    ApplyStyle(spawnGui.new_force_lbl3, my_warning_style)
    ApplyStyle(spawnGui.new_force_spacer, my_label_style)

    spawnGui.add{name = "note_lbl1", type = "label",
                    caption="All members of a team share map vision and research."}                            
    spawnGui.add{name = "note_lbl2", type = "label",
                    caption="To talk to someone on a different team, you need to use /s to shout."}
    spawnGui.add{name = "note_lbl3", type = "label",
                    caption="All teams are neutral. This is still a cooperative PvE game... NOT PVP!"}
    spawnGui.add{name = "note_lbl4", type = "label",
                    caption="Far away spawn is between 1000-6000 distance units away from the center of the map."}
    spawnGui.add{name = "note_lbl5", type = "label",
                    caption="Isolated spawns are dangerous! You will have to fight to reach other players."}
    spawnGui.add{name = "note_lbl6", type = "label",
                    caption="You can change your team and spawn point when you die"}
    ApplyStyle(spawnGui.note_lbl1, my_note_style)
    ApplyStyle(spawnGui.note_lbl2, my_note_style)
    ApplyStyle(spawnGui.note_lbl3, my_note_style)
    ApplyStyle(spawnGui.note_lbl4, my_note_style)
    ApplyStyle(spawnGui.note_lbl5, my_note_style)
end

function DisplayRespawnContinueOption(player)

    player.gui.center.add{name = "respawn_continue_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Respawn Options"}
    local respawnGui = player.gui.center.respawn_continue_opts

    respawnGui.style.maximal_width = 450
    respawnGui.style.maximal_height = 550

    respawnGui.add{name = "respawn_continue",
                    type = "button",
                    caption="Continue"}
    respawnGui.add{name = "respawn_continue_lbl1", type = "label",
                    caption="Continue at your current spawn location."}
    respawnGui.add{name = "respawn_continue_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_continue_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_continue_spacer, my_label_style)

    respawnGui.add{name = "respawn_change",
                    type = "button",
                    caption="Change Spawn"}
    respawnGui.add{name = "respawn_change_lbl1", type = "label",
                    caption="Allow you to change your spawn and team."}
    respawnGui.add{name = "respawn_change_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_change_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_change_spacer, my_label_style)
end


function DisplayRespawnOptions(player)

    player.gui.center.add{name = "respawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption="Respawn Options"}
    local respawnGui = player.gui.center.respawn_opts

    respawnGui.style.maximal_width = 450
    respawnGui.style.maximal_height = 750

    -- Basically a cancel button to avoid choosing a different spawn.
    respawnGui.add{name = "respawn_continue",
                    type = "button",
                    caption="Cancel"}
    respawnGui.add{name = "respawn_continue_lbl1", type = "label",
                    caption="Continue with current spawn."}
    respawnGui.add{name = "respawn_continue_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_continue_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_continue_spacer, my_label_style)

    respawnGui.add{name = "respawn_mainforce",
                    type = "button",
                    caption="Use Default Spawn"}
    respawnGui.add{name = "respawn_mainforce_lbl1", type = "label",
                    caption="This will join the default team."}
    respawnGui.add{name = "respawn_mainforce_lbl2", type = "label",
                    caption="If you are on another team all your research will be lost!"}
    respawnGui.add{name = "respawn_mainforce_lbl3", type = "label",
                    caption="You will spawn at the default spawn point in the center."}
    respawnGui.add{name = "respawn_mainforce_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_mainforce_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_mainforce_lbl2, my_warning_style)
    ApplyStyle(respawnGui.respawn_mainforce_lbl3, my_label_style)
    ApplyStyle(respawnGui.respawn_mainforce_spacer, my_label_style)


    respawnGui.add{name = "respawn_custom_spawn",
                    type = "button",
                    caption="Custom Spawn"}
    respawnGui.add{name = "respawn_custom_lbl1", type = "label",
                    caption="This will join the default team."}
    respawnGui.add{name = "respawn_custom_lbl2", type = "label",
                    caption="If you are on another team all your research will be lost!"}
    respawnGui.add{name = "respawn_custom_lbl3", type = "label",
                    caption="You will spawn at your previous custom spawn point."}
    respawnGui.add{name = "respawn_custom_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_custom_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_custom_lbl2, my_warning_style)
    ApplyStyle(respawnGui.respawn_custom_lbl3, my_label_style)
    ApplyStyle(respawnGui.respawn_custom_spacer, my_label_style)


    respawnGui.add{name = "respawn_custom_team",
                    type = "button",
                    caption="Custom Team Spawn"}
    respawnGui.add{name = "respawn_custom_team_lbl1", type = "label",
                    caption="This will join your own custom team."}
    respawnGui.add{name = "respawn_custom_team_lbl2", type = "label",
                    caption="You will have your own map vision and research tree. Use /s to talk to others."}
    respawnGui.add{name = "respawn_custom_team_lbl3", type = "label",
                    caption="You will spawn at your previous custom spawn point."}
    respawnGui.add{name = "respawn_custom_team_spacer", type = "label",
                    caption=" "}
    ApplyStyle(respawnGui.respawn_custom_team_lbl1, my_label_style)
    ApplyStyle(respawnGui.respawn_custom_team_lbl2, my_warning_style)
    ApplyStyle(respawnGui.respawn_custom_team_lbl3, my_label_style)
    ApplyStyle(respawnGui.respawn_custom_team_spacer, my_label_style)

    if (global.enableRespawnSurprise == true) then
        respawnGui.add{name = "respawn_surpise",
                        type = "button",
                        caption="Surprise me!"}
    end
    
    respawnGui.add{name = "respawn_note1", type = "label",
                    caption="You cannot generate new custom spawn points."}
    ApplyStyle(respawnGui.respawn_note1, my_note_style)
end

function GenerateStartingResources(player)
    local surface = player.surface

    -- Generate stone
    local stonePos = {x=player.position.x-25,
                  y=player.position.y-31}

    -- Generate coal
    local coalPos = {x=player.position.x-25,
                  y=player.position.y-16}

    -- Generate copper ore
    local copperOrePos = {x=player.position.x-25,
                  y=player.position.y+0}
                  
    -- Generate iron ore
    local ironOrePos = {x=player.position.x-25,
                  y=player.position.y+15}

    -- Tree generation is taken care of in chunk generation

    -- Generate oil patches
    surface.create_entity({name="crude-oil", amount=START_OIL_AMOUNT,
                    position={player.position.x-30, player.position.y-2}})
    surface.create_entity({name="crude-oil", amount=START_OIL_AMOUNT,
                    position={player.position.x-30, player.position.y+2}})

    for y=0, 15 do
        for x=0, 15 do
            if ((x-7)^2 + (y - 7)^2 < 7^2) then
                surface.create_entity({name="iron-ore", amount=START_IRON_AMOUNT,
                    position={ironOrePos.x+x, ironOrePos.y+y}})
                surface.create_entity({name="copper-ore", amount=START_COPPER_AMOUNT,
                    position={copperOrePos.x+x, copperOrePos.y+y}})
                surface.create_entity({name="stone", amount=START_STONE_AMOUNT,
                    position={stonePos.x+x, stonePos.y+y}})
                surface.create_entity({name="coal", amount=START_COAL_AMOUNT,
                    position={coalPos.x+x, coalPos.y+y}})
            end
        end
    end
end

local function RemoveDecorationsArea(surface, area )
    for _, entity in pairs(surface.find_entities_filtered{area = area, type="decorative"}) do
        entity.destroy()
    end
end

local function ClearNearbyEnemies(player)
    local safeArea = {left_top=
                    {x=player.position.x-SAFE_AREA_TILE_DIST,
                     y=player.position.y-SAFE_AREA_TILE_DIST},
                  right_bottom=
                    {x=player.position.x+SAFE_AREA_TILE_DIST,
                     y=player.position.y+SAFE_AREA_TILE_DIST}}

    for _, entity in pairs(player.surface.find_entities_filtered{area = safeArea, force = "enemy"}) do
        entity.destroy()
    end
end


local function DoesPlayerHaveCustomSpawn(player)
    for name,spawnPos in pairs(global.playerSpawns) do
        if (player.name == name) then
            return true
        end
    end
    return false
end

local function DoesPlayerHaveActiveCustomSpawn(player)
    if (DoesPlayerHaveCustomSpawn(player)) then
        return global.activePlayerSpawns[player.name]
    else
        return false
    end
end

local function ActivatePlayerCustomSpawn(player, value)
    for name,_ in pairs(global.playerSpawns) do
        if (player.name == name) then
            global.activePlayerSpawns[player.name] = value
            break
        end
    end
end

local function CreatePlayerCustomForce(player)
    local newForce = nil
    
    -- Check if force already exists
    if (game.forces[player.name] ~= nil) then
        return game.forces[player.name]

    -- Create a new force using the player's name
    elseif (TableLength(game.forces) < MAX_FORCES) then
        newForce = game.create_force(player.name)
        player.force = newForce
        SetCeaseFireBetweenAllForces()        
    else
        player.force = MAIN_FORCE
        player.print("Sorry, no new teams can be created. You were assigned to the default team instead.")
    end

    return newForce
end

local function SendPlayerToNewSpawnAndCreateIt(player, spawn)
    -- Send the player to that position
    player.teleport(spawn)
    GivePlayerStarterItems(player)

    -- If we get a valid spawn point, setup the area
    if (spawn ~= {x=0,y=0}) then
        GenerateStartingResources(player)
        ClearNearbyEnemies(player)
    end
end

local function SendPlayerToActiveSpawn(player)
    if (DoesPlayerHaveActiveCustomSpawn(player)) then
        player.teleport(global.playerSpawns[player.name])
    else
        player.teleport(game.forces[MAIN_FORCE].get_spawn_position("nauvis"))
    end
end

local function SendPlayerToRandomSpawn(player)
    local numSpawns = TableLength(global.playerSpawns)
    local rndSpawn = math.random(0,numSpawns)
    local counter = 0

    if (rndSpawn == 0) then
        player.teleport(game.forces[MAIN_FORCE].get_spawn_position("nauvis"))
    else
        counter = counter + 1
        for name,spawnPos in pairs(global.playerSpawns) do
            if (counter == rndSpawn) then
                player.teleport(spawnPos)
                break
            end
            counter = counter + 1
        end 
    end
end


-- When a new player is created, present the spawn options
-- Assign them to the main force so they can communicate with the team
-- without shouting.
script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    player.force = MAIN_FORCE
    DisplaySpawnOptions(player)
    player.print("Welcome to Oarc's server! Now with oil spots, better respawn menus and gravestone chests!")
end)


-- Create the appropriate force & spawn when player selects their choice
script.on_event(defines.events.on_gui_click, function (event)
    
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name

    -- Only clear gui if a valid button was clicked!!
    if ((buttonClicked == "normal_spawn") or
        (buttonClicked == "isolated_spawn") or
        (buttonClicked == "isolated_spawn_far") or
        (buttonClicked == "new_force") or
        (buttonClicked == "new_force_far") or
        (buttonClicked == "respawn_continue") or
        (buttonClicked == "respawn_change") or
        (buttonClicked == "respawn_custom_team") or
        (buttonClicked == "respawn_custom_spawn") or
        (buttonClicked == "respawn_surpise") or
        (buttonClicked == "respawn_mainforce")) then



        if (player.gui.center.spawn_opts ~= nil) then
            player.gui.center.spawn_opts.destroy()
        end
        if (player.gui.center.respawn_opts ~= nil) then
            player.gui.center.respawn_opts.destroy()
        end
        if (player.gui.center.respawn_continue_opts ~= nil) then
            player.gui.center.respawn_continue_opts.destroy()
        end
    end

    -- In this option, the vanilla spawn is used and the player is
    -- part of the main force.
    if (buttonClicked == "normal_spawn") then
        player.force = MAIN_FORCE
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " joined the main force!")

    -- In this option, the player gets a separate spawn point
    -- but is still part of the main force.
    elseif ((buttonClicked == "isolated_spawn") or (buttonClicked == "isolated_spawn_far")) then
        player.force = MAIN_FORCE
        
        -- Create a new spawn point
        local newSpawn = {}
        if (buttonClicked == "isolated_spawn_far") then
            newSpawn = CreateNewSpawnCoordinates(FAR_CHUNK_SPAWN_DIST, 20)
        else
            newSpawn = CreateNewSpawnCoordinates(MIN_CHUNK_SPAWN_DIST, 20)
        end
        global.playerSpawns[player.name] = newSpawn
        global.activePlayerSpawns[player.name] = true
        
        SendPlayerToNewSpawnAndCreateIt(player, newSpawn)
        if (buttonClicked == "isolated_spawn") then
            SendBroadcastMsg(player.name .. " joined the main force from a distance!")
        elseif (buttonClicked == "isolated_spawn_far") then
            SendBroadcastMsg(player.name .. " joined the main force from a great distance!")
        end

    -- In this option, the player is given a new force and a 
    -- separate spawn point
    elseif ((buttonClicked == "new_force") or (buttonClicked == "new_force_far")) then

        -- Create a new force using the player's name
        local newForce = CreatePlayerCustomForce(player)
        
        -- Create a new spawn point
        local newSpawn = {}
        if (buttonClicked == "new_force_far") then
            newSpawn = CreateNewSpawnCoordinates(FAR_CHUNK_SPAWN_DIST, 20)
        else
            newSpawn = CreateNewSpawnCoordinates(MIN_CHUNK_SPAWN_DIST, 20)
        end
        global.playerSpawns[player.name] = newSpawn
        global.activePlayerSpawns[player.name] = true
        
        -- Set the new spawn point
        if (newForce ~= nil) then
            newForce.set_spawn_position(newSpawn, "nauvis")
        end
        
        SendPlayerToNewSpawnAndCreateIt(player, newSpawn)
        SendBroadcastMsg(player.name .. " is going it alone!")

    -- Continue to respawn on your own team at that location
    elseif (buttonClicked == "respawn_continue") then
        GivePlayerItems(player)


    -- If changing your spawn behavior
    elseif (buttonClicked == "respawn_change") then
        if (DoesPlayerHaveCustomSpawn(player)) then
            DisplayRespawnOptions(player)
        else
            DisplaySpawnOptions(player)
        end

    -- Respawn with the main force in the default location
    elseif (buttonClicked == "respawn_mainforce") then
        
        -- Remove custom force if it exists
        if (player.force.name ~= MAIN_FORCE) then
            game.merge_forces(player.name, MAIN_FORCE)
        end

        -- Deactivate the stored spawn point
        ActivatePlayerCustomSpawn(player, false)
        player.teleport(player.force.get_spawn_position("nauvis"))
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " is returning to base!")

    -- Respawn in your already generated custom spawn area on the main team
    elseif (buttonClicked == "respawn_custom_spawn") then

        -- Remove custom force if it exists
        if (player.force.name ~= MAIN_FORCE) then
            game.merge_forces(player.name, MAIN_FORCE)
        end

        -- Activate the stored spawn point
        ActivatePlayerCustomSpawn(player, true)
        SendPlayerToActiveSpawn(player)
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " is returning to their outpost!")        

    -- Respawn in your already generated custom spawn area but on your own
    -- force. This force is created new if it doesn't exist.
    elseif (buttonClicked == "respawn_custom_team") then
        
        -- Create a new force using the player's name
        local newForce = CreatePlayerCustomForce(player)

        -- Set the new spawn point
        if (newForce ~= nil) then
            newForce.set_spawn_position(global.playerSpawns[player.name], "nauvis")
        end

        -- Activate the stored spawn point
        ActivatePlayerCustomSpawn(player, true)
        SendPlayerToActiveSpawn(player)
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " is returning to their outpost alone!")   

    -- lol wut
    elseif (buttonClicked == "respawn_surpise") then
        
        -- Remove custom force if it exists
        if (player.force.name ~= MAIN_FORCE) then
            game.merge_forces(player.name, MAIN_FORCE)
        end

        -- Activate the stored spawn point
        SendPlayerToRandomSpawn(player)
        GivePlayerStarterItems(player)
        SendBroadcastMsg(player.name .. " is surprised!")   

    end
end)

-- local testFlag = false

-- Check if the player has a different spawn point than the default one
-- Make sure to give the default starting items
script.on_event(defines.events.on_player_respawned, function(event)
    local player = game.players[event.player_index]

    -- local testSpawn
    -- if testFlag then
    --     testSpawn = CreateNewSpawnCoordinates(FAR_CHUNK_SPAWN_DIST, 20)
    -- else
    --     testSpawn = CreateNewSpawnCoordinates(MIN_CHUNK_SPAWN_DIST, 20)
    -- end
    -- testFlag = not testFlag
    -- player.teleport(testSpawn)
    -- DebugPrint("Test Spawn: " .. testSpawn.x .. "," .. testSpawn.y)


    -- If a player has an active spawn, use it.
    if (DoesPlayerHaveActiveCustomSpawn(player)) then
        player.teleport(global.playerSpawns[player.name])
    end

    -- Display the respawn continue option
    DisplayRespawnContinueOption(player)
end)


-- New spawn area tile generation and enemy clearing must go here
script.on_event(defines.events.on_chunk_generated, function(event)
    local surface = event.surface
    if surface.name ~= "nauvis" then return end
    local chunkArea = event.area
    
    -- This handles chunk generation near player spawns
    -- If it is near a player spawn, it does a few things like make the area
    -- safe and provide a guaranteed area of land and water tiles.
    for name,spawnPos in pairs(global.playerSpawns) do

        local landArea = {left_top=
                            {x=spawnPos.x-ENFORCE_LAND_AREA_TILE_DIST,
                             y=spawnPos.y-ENFORCE_LAND_AREA_TILE_DIST},
                          right_bottom=
                            {x=spawnPos.x+ENFORCE_LAND_AREA_TILE_DIST,
                             y=spawnPos.y+ENFORCE_LAND_AREA_TILE_DIST}}

        local safeArea = {left_top=
                            {x=spawnPos.x-SAFE_AREA_TILE_DIST,
                             y=spawnPos.y-SAFE_AREA_TILE_DIST},
                          right_bottom=
                            {x=spawnPos.x+SAFE_AREA_TILE_DIST,
                             y=spawnPos.y+SAFE_AREA_TILE_DIST}}

        local warningArea = {left_top=
                                {x=spawnPos.x-WARNING_AREA_TILE_DIST,
                                 y=spawnPos.y-WARNING_AREA_TILE_DIST},
                            right_bottom=
                                {x=spawnPos.x+WARNING_AREA_TILE_DIST,
                                 y=spawnPos.y+WARNING_AREA_TILE_DIST}}

        local chunkAreaCenter = {x=chunkArea.left_top.x+(CHUNK_SIZE/2),
                                 y=chunkArea.left_top.y+(CHUNK_SIZE/2)}

                                 

        -- Make chunks near a spawn safe by removing enemies
        if CheckIfInArea(chunkAreaCenter,safeArea) then
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, force = "enemy"}) do
                entity.destroy()
            end
        
        -- Create a warning area with reduced enemies
        elseif CheckIfInArea(chunkAreaCenter,warningArea) then
            local counter = 0
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, force = "enemy"}) do
                if ((counter % WARN_AREA_REDUCTION_RATIO) ~= 0) then
                    entity.destroy()
                end
                counter = counter + 1
            end

            -- Remove all big and huge worms
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, name = "medium-worm-turret"}) do
                    entity.destroy()
            end
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, name = "big-worm-turret"}) do
                    entity.destroy()
            end

        end

        -- Fill in any water to make sure we have guaranteed land mass at the spawn point.
        if CheckIfInArea(chunkAreaCenter,landArea) then

            -- remove trees in the immediate areas?
            for key, entity in pairs(surface.find_entities_filtered({area=chunkArea, type= "tree"})) do
                if ((spawnPos.x - entity.position.x)^2 + (spawnPos.y - entity.position.y)^2 < ENFORCE_LAND_AREA_TILE_DIST^2) then
                    entity.destroy()
                end
            end

            local dirtTiles = {}
            for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
                for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do

                    -- This ( X^2 + Y^2 ) is used to calculate if something
                    -- is inside a circle area.
                    local distVar = math.floor((spawnPos.x - i)^2 + (spawnPos.y - j)^2)

                    -- Fill in all unexpected water in a circle
                    if (distVar < ENFORCE_LAND_AREA_TILE_DIST_SQUARED) then
                        if (surface.get_tile(i,j).collides_with("water-tile")) then
                            table.insert(dirtTiles, {name = "grass", position ={i,j}})
                        end
                    end

                    -- Create a circle of trees around the spawn point.
                    if ((distVar < ENFORCE_LAND_AREA_TILE_DIST_SQUARED-200) and 
                        (distVar > ENFORCE_LAND_AREA_TILE_DIST_SQUARED-260)) then
                        surface.create_entity({name="tree-01", amount=1, position={i, j}})
                    end
                end
            end

            
            surface.set_tiles(dirtTiles)
        end

        -- Provide a guaranteed spot of water to use for power generation
        if CheckIfInArea(spawnPos,chunkArea) then
            local waterTiles = {{name = "water", position ={spawnPos.x+0,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+1,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+2,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+3,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+4,spawnPos.y-30}},
                                {name = "water", position ={spawnPos.x+5,spawnPos.y-30}}}
            -- DebugPrint("Setting water tiles in this chunk! " .. chunkArea.left_top.x .. "," .. chunkArea.left_top.y)
            surface.set_tiles(waterTiles)
        end
    end

    -- Remove decor to save on file size
    RemoveDecorationsArea(surface, chunkArea)
end)

script.on_init(function(event)
    
    -- Containes an array of all player spawns
    -- A secondary array tracks whether the character will respawn there.
    if (global.playerSpawns == nil) then
        global.playerSpawns = {}
        global.activePlayerSpawns = {}
    end

    -- Adjust alien params
    game.map_settings.enemy_evolution.time_factor=0
    game.map_settings.enemy_evolution.destroy_factor = game.map_settings.enemy_evolution.destroy_factor / ENEMY_DESTROY_FACTOR_DIVISOR
    game.map_settings.enemy_evolution.pollution_factor = game.map_settings.enemy_evolution.pollution_factor / ENEMY_POLLUTION_FACTOR_DIVISOR
    game.map_settings.enemy_expansion.enabled = ENEMY_EXPANSION

    game.create_force(MAIN_FORCE)
    game.forces[MAIN_FORCE].set_spawn_position(game.forces["player"].get_spawn_position("nauvis"), "nauvis")
end)


-- Freeplay rocket launch info
script.on_event(defines.events.on_rocket_launched, function(event)
    local force = event.rocket.force
    if event.rocket.get_item_count("satellite") == 0 then
        for index, player in pairs(force.players) do
            player.print("You launched the rocket, but you didn't put a satellite inside.")
        end
        return
    end

    if not global.satellite_sent then
        global.satellite_sent = {}
    end

    if global.satellite_sent[force.name] then
        global.satellite_sent[force.name] = global.satellite_sent[force.name] + 1   
    else
        game.set_game_state{game_finished=true, player_won=true, can_continue=true}
        global.satellite_sent[force.name] = 1
    end
    
    for index, player in pairs(force.players) do
        if player.gui.left.rocket_score then
            player.gui.left.rocket_score.rocket_count.caption = tostring(global.satellite_sent[force.name])
        else
            local frame = player.gui.left.add{name = "rocket_score", type = "frame", direction = "horizontal", caption="Score"}
            frame.add{name="rocket_count_label", type = "label", caption={"", "Satellites launched", ":"}}
            frame.add{name="rocket_count", type = "label", caption=tostring(global.satellite_sent[force.name])}
        end
    end
end)

--Gravestone Scripts
---- THIS IS NOT MY CODE ---- I DO NOT KNOW WHO TO CREDIT THIS TO
--I got it from "Gravestone and announcements" scenario that I joined.
script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if entity.type == "player" then
        local pos = entity.surface.find_non_colliding_position("steel-chest", entity.position, 8, 1)
        if not pos then return end
    
        local grave = entity.surface.create_entity{name="steel-chest", position=pos, force="neutral"}
        if protective_mode then
            grave.destructible = false
        end
        local grave_inv = grave.get_inventory(defines.inventory.chest)
        local count = 0
        for i, id in ipairs{
        defines.inventory.player_guns,
        defines.inventory.player_tools,
        defines.inventory.player_ammo,
        defines.inventory.player_quickbar,
        defines.inventory.player_main,
        defines.inventory.player_armor,
        defines.inventory.player_trash} do
            local inv = entity.get_inventory(id)
            for j = 1, #inv do
                if inv[j].valid_for_read then
                    count = count + 1
                    if count > #grave_inv then
                        print("Not enough room in chest. You've lost some stuff...")
                        return 
                    end
                    grave_inv[count].set_stack(inv[j])
                end
            end
        end
    end
end)
