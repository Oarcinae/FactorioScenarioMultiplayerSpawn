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

--------------------------------------------------------------------------------
-- GUI Tab Handler
--------------------------------------------------------------------------------

-- NAME of the top level element (outer frame)
local OARC_GUI = "oarc_gui"

function CreateOarcGuiButton(player)
    if (mod_gui.get_button_flow(player).oarc_button == nil) then
        local b = mod_gui.get_button_flow(player).add{name="oarc_button",
                                                        type="sprite-button",
                                                        sprite="utility/expand_dots",
                                                        style=mod_gui.button_style}
        b.style.padding=2
        b.style.width=20
    end

    if (global.oarc_gui_tabs == nil) then
        global.oarc_gui_tabs = {}
    end
end

function DoesOarcGuiExist(player)
    return (mod_gui.get_frame_flow(player)[OARC_GUI] ~= nil)
end

function ToggleOarcGuiVisible(player)
    local of = mod_gui.get_frame_flow(player)[OARC_GUI]
    if (of ~= nil) then
        of.visible = not of.visible
    end
end

function GetOarcGuiTabsPane(player)
    if (mod_gui.get_frame_flow(player)[OARC_GUI] == nil) then
        return nil
    else
        return mod_gui.get_frame_flow(player)[OARC_GUI].oarc_if.oarc_tabs
    end
end

function ClickOarcGuiButton(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.element.player_index]
    local name = event.element.name

    if (name ~= "oarc_button") then return end
    if (not DoesOarcGuiExist(player)) then
        CreateOarcGuiTabsPane(player)
    else
        ToggleOarcGuiVisible(player)
        FakeTabChangeEventOarcGui(player)
    end
end

function TabChangeOarcGui(event)
    if (event.element.name ~= "oarc_tabs") then return end

    local player = game.players[event.player_index]
    local otabs = GetOarcGuiTabsPane(player)
    local selected_tab_name = otabs.tabs[otabs.selected_tab_index].tab.name
    local container = global.oarc_gui_tabs[player.name][selected_tab_name].container
    local gui_function = global.oarc_gui_tabs[player.name][selected_tab_name].gui_tab_function

    for i,t in pairs(otabs.tabs) do
        if (i ~= otabs.selected_tab_index) then
            local tname = otabs.tabs[i].tab.name
            global.oarc_gui_tabs[player.name][tname].container.clear()
        end
    end

    container.clear()
    gui_function(container, player)
end

function FakeTabChangeEventOarcGui(player)
    local event = {}
    event.element = {}
    event.element.name = "oarc_tabs"
    event.player_index = player.index
    TabChangeOarcGui(event)
end

function CreateOarcGuiTabsPane(player)

    if (mod_gui.get_frame_flow(player)[OARC_GUI] == nil) then

        -- OUTER FRAME (TOP GUI ELEMENT)
        local frame = mod_gui.get_frame_flow(player).add{
            type = 'frame',
            name = OARC_GUI,
            direction = "vertical"}
        frame.style.padding = 5

        -- INNER FRAME
        local inside_frame = frame.add{
            type = "frame",
            name = "oarc_if",
            style = "inside_deep_frame",
            direction = "vertical"
        }

        -- SUB HEADING w/ LABEL
        local subhead = inside_frame.add{
            type="frame",
            name="sub_header",
            style = "changelog_subheader_frame"}
        AddLabel(subhead, "scen_info", "Scenario Info and Controls", "subheader_caption_label")

        -- TABBED PANE
        local oarc_tabs = inside_frame.add{
            name="oarc_tabs",
            type="tabbed-pane",
            style="tabbed_pane"}
        oarc_tabs.style.top_padding = 8
    end

    if (global.oarc_gui_tabs == nil) then
        global.oarc_gui_tabs = {}
    end
    if (global.oarc_gui_tabs[player.name] == nil) then
        global.oarc_gui_tabs[player.name] = {}
    end
end

-- Function creates a new tab.
-- gui_tab_function is a function that takes (gui_element, player)
-- It adds whatever it wants to the provided scroll-pane.
function AddOarcGuiTab(player, tab_name, gui_tab_function)
    if (not DoesOarcGuiExist(player)) then
        CreateOarcGuiTabsPane(player)
        ToggleOarcGuiVisible(player)
    end

    -- Destroy if it exists?
    RemoveOarcGuiTab(player, tab_name)

    -- Get the tabbed pane
    local otabs = GetOarcGuiTabsPane(player)

    local new_tab = otabs.add{
        type="tab",
        name=tab_name,
        caption=tab_name}

    -- Create inside frame to hold content
    local tab_inside_frame = otabs.add{
        type="frame",
        style = "inside_deep_frame",
        direction="vertical"}
    tab_inside_frame.style.left_margin = 10
    tab_inside_frame.style.right_margin = 10
    tab_inside_frame.style.top_margin = 4
    tab_inside_frame.style.bottom_margin = 4
    tab_inside_frame.style.padding = 5
    tab_inside_frame.style.horizontally_stretchable = true
    -- tab_inside_frame.style.vertically_stretchable = true
    -- tab_inside_frame.style.horizontally_squashable = true
    -- tab_inside_frame.style.vertically_squashable = true

    -- Add the whole thing to the tab now.
    otabs.add_tab(new_tab, tab_inside_frame)

    -- If no other tabs are selected, select the first one.
    if (otabs.selected_tab_index == nil) then
        otabs.selected_tab_index = 1
    end

    -- Add this tab and it's content creation function to a global table
    -- So that we can recall that function to refresh the table content.
    if (global.oarc_gui_tabs[player.name] ~= nil) then
        global.oarc_gui_tabs[player.name][tab_name] = {
            container=tab_inside_frame,
            tab=new_tab,
            gui_tab_function=gui_tab_function}
    end

    -- FakeTabChangeEventOarcGui(player)
end

function RemoveOarcGuiTab(player, tab_name)
    if (not DoesOarcGuiExist(player)) then return end

    -- Get the tabbed pane
    local otabs = GetOarcGuiTabsPane(player)

    -- Destroy content and remove tab
    if (otabs[tab_name] ~= nil) then
        global.oarc_gui_tabs[player.name][tab_name].container.destroy()
        otabs.remove_tab(global.oarc_gui_tabs[player.name][tab_name].tab)
        global.oarc_gui_tabs[player.name][tab_name].tab.destroy()
        global.oarc_gui_tabs[player.name][tab_name] = nil

        -- Hopefully we have a starting tab we can reset to.
        otabs.selected_tab_index = 1
        FakeTabChangeEventOarcGui(player)
    end
end