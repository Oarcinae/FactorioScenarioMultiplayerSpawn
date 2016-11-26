function create_tag_gui(event)
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
  {display_name = "[Labs]"},
  {display_name = "[Logistics]"},
  {display_name = "[Misc]"},
  {display_name = "[Aliens]"},
  {display_name = "[Rocket]"},
  {display_name = "[AFK]"},
  {display_name = "Clear"}}

function expand_tag_gui(player)
    local frame = player.gui.left["tag-panel"]
    if (frame) then
        frame.destroy()
    else
        local frame = player.gui.left.add{type="frame", name="tag-panel", caption="What are you doing:"}
    		for _, role in pairs(roles) do
    			frame.add{type="button", caption=role.display_name, name=role.display_name}
 			end
    end
end

local function on_gui_click(event) 
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.element.player_index]
    local name = event.element.name

		if (name == "tag") then
			expand_tag_gui(player)		
		end
		
		if (name == "Clear") then 
			player.tag = ""
			return
		end
		for _, role in pairs(roles) do
			if (name == role.display_name) then
				player.tag = role.display_name			end
		end
end


Event.register(defines.events.on_gui_click, on_gui_click)
Event.register(defines.events.on_player_joined_game, create_tag_gui)