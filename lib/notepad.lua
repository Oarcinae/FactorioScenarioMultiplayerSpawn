-- notepad.lua
-- Oarc's simple notepad cause I keep forgetting what I want to do next.


function CreateNotepadGuiTab(tab_container, player)

    if global.oarc_notepad == nil then
        global.oarc_notepad = {}
    end

    if global.oarc_notepad[player.name] == nil then
        global.oarc_notepad[player.name] = "Write something here...!"
    end

    AddLabel(tab_container, "notepad_info", "Use this to take notes:", my_longer_label_style)

    local txt_box = tab_container.add{type="text-box", name="oarc_notepad_textbox", text=global.oarc_notepad[player.name]}
    ApplyStyle(txt_box, my_notepad_fixed_width_style)

    txt_box.focus()
end


function NotepadOnGuiTextChange(event)

    if (event.element.name ~= "oarc_notepad_textbox") then return end

    local player = game.players[event.player_index]

    if global.oarc_notepad == nil then
        global.oarc_notepad = {}
    end

    global.oarc_notepad[player.name] = event.element.text
end
