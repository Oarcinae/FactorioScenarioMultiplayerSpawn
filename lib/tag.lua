-- tag.lua
-- Apr 2017
-- Allows adding play tags

function CreateTagGui(event)
    local player = game.players[event.player_index]
    if player.gui.top.tag == nil then
        player.gui.top.add{name="tag", type="button", caption="Tag"}
    end   
end

-- Tag list
local roles = {
    {display_name = "[Solo]"},
    {display_name = "[Mining]"},
    {display_name = "[Power]"},
    {display_name = "[Oil]"},
    {display_name = "[Smelt]"},
    {display_name = "[Rail]"},
    {display_name = "[Defense]"},
    {display_name = "[Circuits]"},
    {display_name = "[Science!]"},
    {display_name = "[Logistics]"},
    {display_name = "[Misc]"},
    {display_name = "[Aliens]"},
    {display_name = "[Rocket]"},
    {display_name = "[AFK]"}}

local function ExpandTagGui(player)
    local frame = player.gui.left["tag-panel"]
    if (frame) then
        frame.destroy()
    else
        local frame = player.gui.left.add{type="frame", name="tag-panel", caption="What are you doing:", direction = "vertical"}
        for _, role in pairs(roles) do
            frame.add{type="button", caption=role.display_name, name=role.display_name}
        end
        if (player.admin) then
            frame.add{type="button", caption="[Admin]", name="admin"}
            frame.add{type="button", caption="[Moderator]", name="moderator"}
            frame.add{type="button", caption="Clear", name="clear_btn"}
        end
    end
end

function TagGuiClick(event) 
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.element.player_index]
    local name = event.element.name

    if (name == "tag") then
        ExpandTagGui(player)        
    end
    
    if (name == "clear_btn") then 
        player.tag = ""
        return
    end
    
    for _, role in pairs(roles) do
        if (name == role.display_name) then
            player.tag = role.display_name
        elseif (name == "admin") then
            player.tag = "[Admin]"
        elseif (name == "moderator") then
            player.tag = "[Moderator]"
        end
    end
end
