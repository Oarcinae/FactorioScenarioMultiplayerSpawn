-- oarc_gui_tabs.lua

local mod_gui = require("mod-gui")

--------------------------------------------------------------------------------
-- GUI Tab Handler
--------------------------------------------------------------------------------

-- NAME of the top level element (outer frame)
OARC_GUI = "oarc_gui"

-- LIST of all implemented tabs and their content Functions
OARC_GAME_OPTS_GUI_TAB_NAME = "Server Info"
OARC_SPAWN_CTRL_GUI_NAME = "Spawn Controls"


local OARC_GUI_TAB_CONTENT_FUNCTIONS = {}
OARC_GUI_TAB_CONTENT_FUNCTIONS["Server Info"] = CreateGameOptionsTab
OARC_GUI_TAB_CONTENT_FUNCTIONS["Spawn Controls"] = CreateSpawnCtrlGuiTab


---@param player LuaPlayer
---@return nil
function InitOarcGuiTabs(player)

    -- Make safe to call multiple times
    if (DoesOarcGuiExist(player)) then
        return
    end

    CreateOarcGuiButton(player)

    -- Add general info tab
    AddOarcGuiTab(player, OARC_GAME_OPTS_GUI_TAB_NAME)
    SetOarcGuiTabEnabled(player, OARC_GAME_OPTS_GUI_TAB_NAME, true)

    -- Spawn control tab, disabled by default
    AddOarcGuiTab(player, OARC_SPAWN_CTRL_GUI_NAME)

    HideOarcGui(player)
end

---@param player LuaPlayer
---@return nil
function CreateOarcGuiButton(player)
    if (mod_gui.get_button_flow(player).oarc_button == nil) then
        local b = mod_gui.get_button_flow(player).add{name="oarc_button",
                                                        caption="CLICK ME FOR MORE INFO",
                                                        type="sprite-button",
                                                        -- sprite="utility/expand_dots",
                                                        style=mod_gui.button_style}
        b.style.padding=2
        -- b.style.width=20
    end
end

---@param player LuaPlayer
---@return boolean
function DoesOarcGuiExist(player)
    return (mod_gui.get_frame_flow(player)[OARC_GUI] ~= nil)
end

---@param player LuaPlayer
---@return boolean
function IsOarcGuiVisible(player)
    ---@type LuaGuiElement
    local of = mod_gui.get_frame_flow(player)[OARC_GUI]
    return (of.visible)
end

---@param player LuaPlayer
---@return nil
function ShowOarcGui(player)
    ---@type LuaGuiElement
    local of = mod_gui.get_frame_flow(player)[OARC_GUI]
    if (of == nil) then return end
    of.visible = true
    player.opened = of
end

---@param player LuaPlayer
---@return nil
function HideOarcGui(player)
    ---@type LuaGuiElement
    local of = mod_gui.get_frame_flow(player)[OARC_GUI]
    if (of == nil) then return end
    of.visible = false
    player.opened = nil
end

---@param player LuaPlayer
---@return LuaGuiElement?
function GetOarcGuiTabsPane(player)
    ---@type LuaGuiElement
    local of = mod_gui.get_frame_flow(player)[OARC_GUI]
    if (of == nil) then
        return nil
    else
        return of.oarc_if.oarc_tabs
    end
end

---@param event EventData.on_gui_click
---@return nil
function ClickOarcGuiButton(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local name = event.element.name

    if (name ~= "oarc_button") then return end

    if (event.element.caption ~= "") then
        event.element.caption = ""
        event.element.style.width = 20
        event.element.sprite="utility/expand_dots"
    end

    if (not DoesOarcGuiExist(player)) then
        CreateOarcGuiTabsPane(player)
    else
        if (IsOarcGuiVisible(player)) then
            HideOarcGui(player)
        else
            ShowOarcGui(player)
            FakeTabChangeEventOarcGui(player)
        end
    end
end

---@param event EventData.on_gui_selected_tab_changed
---@return nil
function TabChangeOarcGui(event)
    if (event.element.name ~= "oarc_tabs") then return end

    local player = game.players[event.player_index]
    local otabs = event.element
    local selected_tab_name = otabs.tabs[otabs.selected_tab_index].tab.name

    -- Clear all tab contents
    for i,t in pairs(otabs.tabs) do
        t.content.clear()
    end

    SetOarGuiTabContent(player, selected_tab_name)
end

---@param player LuaPlayer
---@return nil
function FakeTabChangeEventOarcGui(player)
    local event = {}
    event.element = GetOarcGuiTabsPane(player)
    event.player_index = player.index
    TabChangeOarcGui(event)
end

---@param player LuaPlayer
---@return nil
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
end

-- Function creates a new tab.
-- It adds whatever it wants to the provided scroll-pane.
---@param player LuaPlayer
---@param tab_name string
function AddOarcGuiTab(player, tab_name)
    if (not DoesOarcGuiExist(player)) then
        CreateOarcGuiTabsPane(player)
    end

    -- Get the tabbed pane
    local otabs = GetOarcGuiTabsPane(player)

    if (otabs == nil) then return end

    -- Create new tab
    local new_tab = otabs.add{
        type="tab",
        name=tab_name,
        caption=tab_name}

    -- Create inside frame for content
    local tab_inside_frame = otabs.add{
        type="frame",
        name=tab_name.."_if",
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

    -- Disable all new tabs by default
    new_tab.enabled = false

    -- If no other tabs are selected, select the first one.
    if (otabs.selected_tab_index == nil) then
        otabs.selected_tab_index = 1
    end
end

---@param player LuaPlayer
---@param tab_name string
function SetOarGuiTabContent(player, tab_name)
    if (not DoesOarcGuiExist(player)) then return end

    local otabs = GetOarcGuiTabsPane(player)

    for _,t in ipairs(otabs.tabs) do
        if (t.tab.name == tab_name) then
            t.content.clear()
            OARC_GUI_TAB_CONTENT_FUNCTIONS[tab_name](t.content, player)
            return
        end
    end
end

---@param player LuaPlayer
---@param tab_name string
---@param enable boolean
function SetOarcGuiTabEnabled(player, tab_name, enable)
    if (not DoesOarcGuiExist(player)) then return end

    local otabs = GetOarcGuiTabsPane(player)

    for _,t in ipairs(otabs.tabs) do
        if (t.tab.name == tab_name) then
            t.tab.enabled = enable
            return
        end
    end
end

---@param player LuaPlayer
---@param tab_name string
function SwitchOarcGuiTab(player, tab_name)
    if (not DoesOarcGuiExist(player)) then return end

    local otabs = GetOarcGuiTabsPane(player)

    for i,t in pairs(otabs.tabs) do
        if (t.tab.name == tab_name) then
            otabs.selected_tab_index = i
            FakeTabChangeEventOarcGui(player)
            return
        end
    end
end

--@param event EventData.on_gui_closed
function OarcGuiOnGuiClosedEvent(event)
    if (event.element and (event.element.name == "oarc_gui")) then
        HideOarcGui(game.players[event.player_index])
    end
end