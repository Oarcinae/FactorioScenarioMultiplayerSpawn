-- oarc_gui_utils.lua
-- Mar 2019

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

-- Apply a style option to a GUI
function ApplyStyle (guiIn, styleIn)
    for k,v in pairs(styleIn) do
        guiIn.style[k]=v
    end
end

-- Shorter way to add a label with a style
function AddLabel(guiIn, name, message, style)
    local g = guiIn.add{name = name, type = "label",
                    caption=message}
    if (type(style) == "table") then
        ApplyStyle(g, style)
    else
        g.style = style
    end
end

-- Shorter way to add a spacer
function AddSpacer(guiIn)
    ApplyStyle(guiIn.add{type = "label", caption=" "}, my_spacer_style)
end

function AddSpacerLine(guiIn)
    ApplyStyle(guiIn.add{type = "line", direction="horizontal"}, my_spacer_style)
end