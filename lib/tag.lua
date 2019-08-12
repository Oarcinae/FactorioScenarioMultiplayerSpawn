-- tag.lua
-- Apr 2017
-- Allows adding play tags

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

function CreateTagGuiTab(tab_container, player)
    for i,role in ipairs(roles) do
        tab_container.add{type="button", caption=role.display_name, name=role.display_name}
    end
    if (player.admin) then
        tab_container.add{type="button", caption="[Admin]", name="admin"}
        tab_container.add{type="button", caption="[Moderator]", name="moderator"}
    end
    tab_container.add{type="button", caption="Clear", name="clear_btn"}
end

function TagGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.element.player_index]
    local name = event.element.name

    if (name == "clear_btn") then
        player.tag = ""
        return
    end

    for i,role in ipairs(roles) do
        if (name == role.display_name) then
            player.tag = role.display_name
        elseif (name == "admin") then
            player.tag = "[Admin]"
        elseif (name == "moderator") then
            player.tag = "[Moderator]"
        end
    end
end
