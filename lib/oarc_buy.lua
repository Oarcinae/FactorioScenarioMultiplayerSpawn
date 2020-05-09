-- oarc_buy.lua
-- May 2020
-- Adding microtransactions.

require("lib/oarc_store_player_items")
require("lib/oarc_store_map_features")

-- NAME of the top level element (outer frame)
OARC_STORE_GUI = "oarc_store_gui"

OARC_PLAYER_STORE_GUI_TAB_NAME = "Item Store"
OARC_MAP_FEATURE_GUI_TAB_NAME = "Map Features"

local OARC_STORE_TAB_CONTENT_FUNCTIONS = {}
OARC_STORE_TAB_CONTENT_FUNCTIONS[OARC_PLAYER_STORE_GUI_TAB_NAME] = CreatePlayerStoreTab
OARC_STORE_TAB_CONTENT_FUNCTIONS[OARC_MAP_FEATURE_GUI_TAB_NAME] = CreateMapFeatureStoreTab

function InitOarcStoreGuiTabs(player)
    CreateOarcStoreButton(player)
    CreateOarcStoreTabsPane(player)

    -- Store for personal items
    AddOarcStoreTab(player, OARC_PLAYER_STORE_GUI_TAB_NAME)
    SetOarcStoreTabEnabled(player, OARC_PLAYER_STORE_GUI_TAB_NAME, true)

    -- Store for map feature stuff
    AddOarcStoreTab(player, OARC_MAP_FEATURE_GUI_TAB_NAME)
    SetOarcStoreTabEnabled(player, OARC_MAP_FEATURE_GUI_TAB_NAME, true)

    HideOarcStore(player)
end

function CreateOarcStoreButton(player)
    if (mod_gui.get_button_flow(player).oarc_store == nil) then
        local b = mod_gui.get_button_flow(player).add{name="oarc_store",
                                                        type="sprite-button",
                                                        sprite="item/coin",
                                                        style=mod_gui.button_style}
        b.style.padding=2
    end
end

function DoesOarcStoreExist(player)
    return (mod_gui.get_frame_flow(player)[OARC_STORE_GUI] ~= nil)
end

function IsOarcStoreVisible(player)
    local of = mod_gui.get_frame_flow(player)[OARC_STORE_GUI]
    return (of.visible)
end

function ShowOarcStore(player)
    local of = mod_gui.get_frame_flow(player)[OARC_STORE_GUI]
    if (of == nil) then return end
    of.visible = true
    player.opened = of
end

function HideOarcStore(player)
    local of = mod_gui.get_frame_flow(player)[OARC_STORE_GUI]
    if (of == nil) then return end
    of.visible = false
    player.opened = nil
end

function GetOarcStoreTabsPane(player)
    if (mod_gui.get_frame_flow(player)[OARC_STORE_GUI] == nil) then
        return nil
    else
        return mod_gui.get_frame_flow(player)[OARC_STORE_GUI].store_if.store_tabs
    end
end

function ClickOarcStoreButton(event)
    if not (event and event.element and event.element.valid) then return end
    local button = event.element
    local player = game.players[event.player_index]

    -- Don't allow any clicks on the store while player is dead!
    if (not player or player.ticks_to_respawn) then
        if (DoesOarcStoreExist(player)) then
            HideOarcStore(player)   
        end
        return
    end

    if (button.name == "oarc_store") then 
        if (not DoesOarcStoreExist(player)) then
            CreateOarcStoreTabsPane(player)
        else
            if (IsOarcStoreVisible(player)) then
                HideOarcStore(player)
            else
                ShowOarcStore(player)
                FakeTabChangeEventOarcStore(player)
            end
        end
    elseif ((button.parent ~= nil) and (button.parent.parent ~= nil)) then
        if (button.parent.parent.name == OARC_PLAYER_STORE_GUI_TAB_NAME.."_if") then
            OarcPlayerStoreButton(event)
        elseif (button.parent.parent.name == OARC_MAP_FEATURE_GUI_TAB_NAME.."_if") then
            OarcMapFeatureStoreButton(event)
        end
    end
end

function TabChangeOarcStore(event)
    if (event.element.name ~= "store_tabs") then return end

    local player = game.players[event.player_index]
    local otabs = event.element
    local selected_tab_name = otabs.tabs[otabs.selected_tab_index].tab.name

    -- Clear all tab contents
    for i,t in pairs(otabs.tabs) do
        t.content.clear()
    end

    SetOarcStoreTabContent(player, selected_tab_name)
end

function FakeTabChangeEventOarcStore(player)
    local event = {}
    event.element = GetOarcStoreTabsPane(player)
    event.player_index = player.index
    TabChangeOarcStore(event)
end

function CreateOarcStoreTabsPane(player)
    if (mod_gui.get_frame_flow(player)[OARC_STORE_GUI] == nil) then

        -- OUTER FRAME (TOP GUI ELEMENT)
        local frame = mod_gui.get_frame_flow(player).add{
            type = 'frame',
            name = OARC_STORE_GUI,
            direction = "vertical"}
        frame.style.padding = 5

        -- INNER FRAME
        local inside_frame = frame.add{
            type = "frame",
            name = "store_if",
            style = "inside_deep_frame",
            direction = "vertical"
        }

        -- SUB HEADING w/ LABEL
        local subhead = inside_frame.add{
            type="frame",
            name="sub_header",
            style = "changelog_subheader_frame"}
        AddLabel(subhead, "store_info", "OARC Microtransactions and DLC", "subheader_caption_label")

        -- TABBED PANE
        local store_tabs = inside_frame.add{
            name="store_tabs",
            type="tabbed-pane",
            style="tabbed_pane"}
        store_tabs.style.top_padding = 8
    end
end

function AddOarcStoreTab(player, tab_name)
    -- if (not DoesOarcStoreExist(player)) then
    --     CreateOarcStoreTabsPane(player)
    -- end

    -- Get the tabbed pane
    local otabs = GetOarcStoreTabsPane(player)

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

function SetOarcStoreTabContent(player, tab_name)
    if (not DoesOarcStoreExist(player)) then return end

    local otabs = GetOarcStoreTabsPane(player)

    for _,t in ipairs(otabs.tabs) do
        if (t.tab.name == tab_name) then
            t.content.clear()
            OARC_STORE_TAB_CONTENT_FUNCTIONS[tab_name](t.content, player)
            return
        end
    end
end

function SetOarcStoreTabEnabled(player, tab_name, enable)
    if (not DoesOarcStoreExist(player)) then return end

    local otabs = GetOarcStoreTabsPane(player)

    for _,t in ipairs(otabs.tabs) do
        if (t.tab.name == tab_name) then
            t.tab.enabled = enable
            return
        end
    end
end

-- function SwitchOarcStoreTab(player, tab_name)
--     if (not DoesOarcStoreExist(player)) then return end

--     local otabs = GetOarcStoreTabsPane(player)

--     for i,t in pairs(otabs.tabs) do
--         if (t.tab.name == tab_name) then
--             otabs.selected_tab_index = i
--             FakeTabChangeEventOarcStore(player)
--             return
--         end
--     end
-- end

function OarcStoreOnGuiClosedEvent(event)
    if (event.element and (event.element.name == OARC_STORE_GUI)) then
        HideOarcStore(game.players[event.player_index])
    end
end

-- function CreateMapFeatureStoreTab(tab_container, player)
--     tab_container.add{name="furnace_block_btn",
--                         type="sprite-button",
--                         sprite="item/electric-furnace",
--                         tooltip="Cost: 1000 [item=coin]",
--                         style=mod_gui.button_style}
--     tab_container.add{name="refinery_block_btn",
--                         type="sprite-button",
--                         sprite="item/oil-refinery",
--                         tooltip="Cost: 1000 [item=coin]",
--                         style=mod_gui.button_style}
--     tab_container.add{name="assembly_block_btn",
--                         type="sprite-button",
--                         sprite="item/assembling-machine-3",
--                         tooltip="Cost: 1000 [item=coin]",
--                         style=mod_gui.button_style}
-- end
-- OARC_STORE_TAB_CONTENT_FUNCTIONS[OARC_MAP_FEATURE_GUI_TAB_NAME] = CreateMapFeatureStoreTab
