-- Generic GUI stuff goes here.

--------------------------------------------------------------------------------
-- GUI Styles
--------------------------------------------------------------------------------

my_fixed_width_style = {
    minimal_width = 450,
    maximal_width = 450
}
my_label_style = {
    -- minimal_width = 450,
    -- maximal_width = 50,
    single_line = false,
    font_color = {r=1,g=1,b=1},
    top_padding = 0,
    bottom_padding = 0
}
my_label_header_style = {
    single_line = false,
    font = "heading-1",
    font_color = {r=1,g=1,b=1},
    top_padding = 0,
    bottom_padding = 0
}
my_label_header_grey_style = {
    single_line = false,
    font = "heading-1",
    font_color = {r=0.6,g=0.6,b=0.6},
    top_padding = 0,
    bottom_padding = 0
}
my_note_style = {
    -- minimal_width = 450,
    single_line = false,
    font = "default-small-semibold",
    font_color = {r=1,g=0.5,b=0.5},
    top_padding = 0,
    bottom_padding = 0
}
my_warning_style = {
    -- minimal_width = 450,
    -- maximal_width = 450,
    single_line = false,
    font_color = {r=1,g=0.1,b=0.1},
    top_padding = 0,
    bottom_padding = 0
}
my_spacer_style = {
    minimal_height = 10,
    top_padding = 0,
    bottom_padding = 0
}
my_small_button_style = {
    font = "default-small-semibold"
}
my_player_list_fixed_width_style = {
    minimal_width = 200,
    maximal_width = 400,
    maximal_height = 200
}
my_shared_item_list_fixed_width_style = {
    minimal_width = 200,
    maximal_width = 600,
    maximal_height = 600
}
my_player_list_admin_style = {
    font = "default-semibold",
    font_color = {r=1,g=0.5,b=0.5},
    minimal_width = 200,
    top_padding = 0,
    bottom_padding = 0,
    single_line = false,
}
my_player_list_style = {
    font = "default-semibold",
    minimal_width = 200,
    top_padding = 0,
    bottom_padding = 0,
    single_line = false,
}
my_player_list_offline_style = {
    -- font = "default-semibold",
    font_color = {r=0.5,g=0.5,b=0.5},
    minimal_width = 200,
    top_padding = 0,
    bottom_padding = 0,
    single_line = false,
}
my_player_list_style_spacer = {
    minimal_height = 20,
}
my_color_red = {r=1,g=0.1,b=0.1}

my_longer_label_style = {
    maximal_width = 600,
    single_line = false,
    font_color = {r=1,g=1,b=1},
    top_padding = 0,
    bottom_padding = 0
}
my_longer_warning_style = {
    maximal_width = 600,
    single_line = false,
    font_color = {r=1,g=0.1,b=0.1},
    top_padding = 0,
    bottom_padding = 0
}
my_notepad_fixed_width_style = {
    minimal_width = 600,
    maximal_width = 600,
    minimal_height = 300,
    maximal_height = 300,
    font = "default-small-semibold",
    font_color = {r=0.2,g=0.3,b=0.4},
    top_margin = 5,
    bottom_margin = 5
}

--------------------------------------------------------------------------------
-- GUI Functions
--------------------------------------------------------------------------------

---Apply a style option to a GUI
---@param gui_element LuaGuiElement
---@param style_in table
---@return nil
function ApplyStyle (gui_element, style_in)
    for k,v in pairs(style_in) do
        gui_element.style[k]=v
    end
end

---Shorter way to add a label with a style
---@param gui_element LuaGuiElement
---@param name string?
---@param message LocalisedString
---@param style table|string
---@return nil
function AddLabel(gui_element, name, message, style)
    local g = gui_element.add{name = name, type = "label", caption=message}
    if (type(style) == "table") then
        ApplyStyle(g, style)
    else
        g.style = style
    end
end

---Shorter way to add a spacer
---@param gui_element LuaGuiElement
---@return nil
function AddSpacer(gui_element)
    ApplyStyle(gui_element.add{type = "label", caption=" "}, my_spacer_style)
end

---Shorter way to add a spacer line
---@param gui_element LuaGuiElement
---@return nil
function AddSpacerLine(gui_element)
    ApplyStyle(gui_element.add{type = "line", direction="horizontal"}, my_spacer_style)
end