-- A nice way to organize the GUI tabs.

local mod_gui = require("mod-gui")
require("lib/gui_tabs/server_info")
require("lib/gui_tabs/spawn_controls")
require("lib/gui_tabs/settings_controls")
require("lib/gui_tabs/mod_info_faq")
require("lib/gui_tabs/player_list")
require("lib/gui_tabs/surface_config")
require("lib/gui_tabs/item_shop")

--------------------------------------------------------------------------------
-- GUI Tab Handler
--------------------------------------------------------------------------------

-- NAME of the top level element (outer frame)
OARC_GUI = "oarc_gui"

-- All tabs and their content Functions
OARC_SERVER_INFO_TAB_NAME = "server_info"
OARC_SPAWN_CTRL_TAB_NAME = "spawn_controls"
OARC_CONFIG_CTRL_TAB_NAME = "settings"
OARC_MOD_INFO_CTRL_TAB_NAME = "mod_info"
OARC_MOD_PLAYER_LIST_TAB_NAME = "player_list"
OARC_SURFACE_CONFIG_TAB_NAME = "surface_config"
OARC_ITEM_SHOP_TAB_NAME = "item_shop"

local OARC_GUI_TAB_CONTENT = {
    [OARC_SERVER_INFO_TAB_NAME] = {
        create_tab_function = CreateServerInfoTab,
        localized_name = {"oarc-server-info-tab-title"}
    },
    [OARC_SPAWN_CTRL_TAB_NAME] = {
        create_tab_function = CreateSpawnControlsTab,
        localized_name = {"oarc-spawn-ctrls-tab-title"}
    },
    [OARC_MOD_INFO_CTRL_TAB_NAME] = {
        create_tab_function = CreateModInfoTab,
        localized_name = {"oarc-mod-info-tab-title"}
    },
    [OARC_CONFIG_CTRL_TAB_NAME] = {
        create_tab_function = CreateSettingsControlsTab,
        localized_name = {"oarc-settings-tab-title"}
    },
    [OARC_MOD_PLAYER_LIST_TAB_NAME] = {
        create_tab_function = CreatePlayerListTab,
        localized_name = {"oarc-player-list-tab-title"}
    },
    [OARC_SURFACE_CONFIG_TAB_NAME] = {
        create_tab_function = CreateSurfaceConfigTab,
        localized_name = {"oarc-surface-config-tab-title"}
    },
    [OARC_ITEM_SHOP_TAB_NAME] = {
        create_tab_function = CreateItemShopTab,
        localized_name = {"oarc-item-shop-tab-title"}
    }
}

---@param player LuaPlayer
---@return nil
function InitOarcGuiTabs(player)

    -- Make safe to call multiple times
    if (DoesOarcGuiExist(player)) then
        return
    end

    CreateOarcGuiButton(player)

    -- Add general info tab
    AddOarcGuiTab(player, OARC_SERVER_INFO_TAB_NAME)
    SetOarcGuiTabEnabled(player, OARC_SERVER_INFO_TAB_NAME, true)

    -- Mod Info tab
    AddOarcGuiTab(player, OARC_MOD_INFO_CTRL_TAB_NAME)
    SetOarcGuiTabEnabled(player, OARC_MOD_INFO_CTRL_TAB_NAME, true)

    -- Spawn control tab, enable if player is already spawned
    AddOarcGuiTab(player, OARC_SPAWN_CTRL_TAB_NAME)
    local player_respawns = storage.player_respawns[player.name]
    local spawn_enabled = (player_respawns ~= nil) and (next(player_respawns) ~= nil) -- TODO: Maybe make a specific state flag or something more explicit?
    SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_TAB_NAME, spawn_enabled)

    -- Player list tab
    AddOarcGuiTab(player, OARC_MOD_PLAYER_LIST_TAB_NAME)
    SetOarcGuiTabEnabled(player, OARC_MOD_PLAYER_LIST_TAB_NAME, true)

    -- Item shop tab
    if (storage.ocfg.gameplay.enable_coin_shop) then
        AddOarcGuiTab(player, OARC_ITEM_SHOP_TAB_NAME)
        SetOarcGuiTabEnabled(player, OARC_ITEM_SHOP_TAB_NAME, true)
    end

    -- Settings control tab
    AddOarcGuiTab(player, OARC_CONFIG_CTRL_TAB_NAME)
    SetOarcGuiTabEnabled(player, OARC_CONFIG_CTRL_TAB_NAME, true)

    -- Surface config tab
    if (player.admin) then
        AddOarcGuiTab(player, OARC_SURFACE_CONFIG_TAB_NAME)
        SetOarcGuiTabEnabled(player, OARC_SURFACE_CONFIG_TAB_NAME, true)
    end

    -- Let other mods know the top left GUI was created, this is a good time to add buttons to it.
    script.raise_event("oarc-mod-on-mod-top-left-gui-created", {player_index = player.index})

    HideOarcGui(player)
end

---@param player LuaPlayer
---@return nil
function CreateOarcGuiButton(player)
    if (mod_gui.get_button_flow(player).oarc_mod_gui_button == nil) then
        local b = mod_gui.get_button_flow(player).add{
            name="oarc_mod_gui_button",
            type="sprite-button",
            sprite = "oarc-mod-sprite-40",
            style="slot_button",
            tooltip={ "oarc-gui-tooltip" }
        }
        b.style.padding=0
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
    if not event.element.valid then return end
    local player = game.players[event.player_index]
    local name = event.element.name

    if (name ~= "oarc_mod_gui_button") then return end

    if (not DoesOarcGuiExist(player)) then
        CreateOarcGuiTabsPane(player)
    else
        if (IsOarcGuiVisible(player)) then
            HideOarcGui(player)
        else
            ShowOarcGui(player)
            OarcGuiCreateContentOfTab(player)
        end
    end
end



---Set tab content to currently selected tab, clears all other tab content and refreshes the selected tab content!
---Safe to call just to refresh the current tab.
---@param player LuaPlayer
---@return nil
function OarcGuiCreateContentOfTab(player)
    local otabs = GetOarcGuiTabsPane(player)
    if (otabs == nil) then return end

    local tab_name = otabs.tabs[otabs.selected_tab_index].tab.name

    -- log("OarcGuiCreateContentOfTab: " .. tab_name)

    for _,t in ipairs(otabs.tabs) do
        if (OARC_GUI_TAB_CONTENT[t.tab.name] ~= nil) then -- Only clear my own tabs.
            t.content.clear()
            if (t.tab.name == tab_name) then
                OARC_GUI_TAB_CONTENT[tab_name].create_tab_function(t.content, player)
            end
        end
    end
end

---Gets the content element of the named tab.
---@param player LuaPlayer
---@param tab_name string
---@return LuaGuiElement?
function OarcGuiGetTabContentElement(player, tab_name)
    local otabs = GetOarcGuiTabsPane(player)
    if (otabs == nil) then return nil end

    for _,t in ipairs(otabs.tabs) do
        if (t.tab.name == tab_name) then
            return t.content
        end
    end
    return nil
end

---Just an alias for OarcGuiCreateContentOfTab
---@param player LuaPlayer
---@return nil
function OarcGuiRefreshContent(player)
    -- log("Hit OarcGuiRefreshContent" .. player.name)
    OarcGuiCreateContentOfTab(player)
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
            style = "subheader_frame"
        }
        subhead.style.horizontally_stretchable = true

        -- changelog_subheader_frame =
        -- {
        --   type = "frame_style",
        --   parent = "subheader_frame",
        --   left_padding = 12,
        --   right_padding = 12,
        --   top_padding = 4,
        --   horizontally_stretchable = "on"
        -- }

        AddLabel(subhead, nil, {"oarc-gui-tab-header-label"}, "subheader_caption_label")

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
---@param localized_name LocalisedString
function AddOarcGuiTabWrapper(player, tab_name, localized_name)
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
        caption=localized_name}

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

-- Uses AddOarcGuiTabWrapper to add my own tabs using OARC_GUI_TAB_CONTENT for the localized name.
---@param player LuaPlayer
---@param tab_name string
function AddOarcGuiTab(player, tab_name)
    AddOarcGuiTabWrapper(player, tab_name, OARC_GUI_TAB_CONTENT[tab_name].localized_name)
end

-- https://forums.factorio.com/viewtopic.php?f=7&t=115901
-- ---Removes a tab from the GUI.
-- ---@param player LuaPlayer
-- ---@param tab_name string
-- function RemoveOarcGuiTab(player, tab_name)
--     if (not DoesOarcGuiExist(player)) then return end

--     local otabs = GetOarcGuiTabsPane(player)

--     local selected_tab_name = otabs.tabs[otabs.selected_tab_index].tab.name

--     for _,t in ipairs(otabs.tabs) do
--         if (t.tab.name == tab_name) then

--             local tab = t.tab
--             local content = t.content
--             otabs.remove_tab(t.tab)
--             tab.destroy()
--             content.destroy()

--             --TODO: I haven't figured out how to do this nicely, but removing tabs fucks up the tab view.
--             -- So for now, we just recreate the GUI.

--             OarcGuiCreateContentOfTab(player)

--             return
--         end
--     end
-- end

---Check if tab exists in the GUI.
---@param player LuaPlayer
---@param tab_name string
---@return boolean
function DoesOarcGuiTabExist(player, tab_name)
    if (not DoesOarcGuiExist(player)) then return false end

    local otabs = GetOarcGuiTabsPane(player)

    for _,t in ipairs(otabs.tabs) do
        if (t.tab.name == tab_name) then
            return true
        end
    end

    return false
end

---This sets the enable state of a tab.
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

---Switches the tab to the one specified.
---@param player LuaPlayer
---@param tab_name string
function SwitchOarcGuiTab(player, tab_name)
    if (not DoesOarcGuiExist(player)) then return end

    local otabs = GetOarcGuiTabsPane(player)

    for i,t in pairs(otabs.tabs) do
        if (t.tab.name == tab_name) then
            otabs.selected_tab_index = i
            OarcGuiCreateContentOfTab(player)
            return
        end
    end
end

---Completely destroys and recreates the OARC GUI for a player.
---@param player LuaPlayer
---@return nil
function RecreateOarcGui(player)
    if (mod_gui.get_button_flow(player).oarc_button ~= nil) then
        mod_gui.get_button_flow(player).oarc_button.destroy()
    end

    if (mod_gui.get_frame_flow(player)[OARC_GUI] ~= nil) then
        mod_gui.get_frame_flow(player)[OARC_GUI].destroy()
    end

    InitOarcGuiTabs(player)
end

---Add or remove a tab for all players.
---@param tab_name string
---@param add boolean If true, add the tab. If false, remove the tab.
---@param enable boolean If true, enables the tab. If false, disable the tab. Only used if adding the tab.
---@return nil
function AddRemoveOarcGuiTabForAllPlayers(tab_name, add, enable)
    for _,player in pairs(game.players) do
        if (add and not DoesOarcGuiTabExist(player, tab_name)) then
            AddOarcGuiTab(player, tab_name)
            SetOarcGuiTabEnabled(player, tab_name, true)
        elseif (not add and DoesOarcGuiTabExist(player, tab_name)) then
            -- RemoveOarcGuiTab(player, tab_name) -- TODO: SEE https://forums.factorio.com/viewtopic.php?f=7&t=115901
            RecreateOarcGui(player) -- Assumes a ocfg setting change, so just recreate the whole thing.
        end
    end
end


-- Lets other mods add their own tabs to the OARC GUI.
---@param player LuaPlayer
---@param tab_name string
function AddCustomOarcGuiTab(player, tab_name)
    AddOarcGuiTabWrapper(player, tab_name, tab_name)
    SetOarcGuiTabEnabled(player, tab_name, true)
end


--[[
  _____   _____ _  _ _____   _  _   _   _  _ ___  _    ___ ___  ___ 
 | __\ \ / / __| \| |_   _| | || | /_\ | \| |   \| |  | __| _ \/ __|
 | _| \ V /| _|| .` | | |   | __ |/ _ \| .` | |) | |__| _||   /\__ \
 |___| \_/ |___|_|\_| |_|   |_||_/_/ \_\_|\_|___/|____|___|_|_\|___/

]]

---Handles the closing of the OARC GUI.
---@param event EventData.on_gui_closed
---@return nil
function OarcGuiClosed(event)
    if (event.element and (event.element.name == "oarc_gui")) then
        HideOarcGui(game.players[event.player_index])
    end
end

---@param event EventData.on_gui_selected_tab_changed
---@return nil
function OarcGuiTabsSelectedTabChanged(event)
    if (event.element.name ~= "oarc_tabs") then return end
    OarcGuiCreateContentOfTab(game.players[event.player_index])
end

---All gui tabs click event handler
---@param event EventData.on_gui_click
---@return nil
function OarcGuiTabsClick(event)
    if not event.element.valid then return end
    ClickOarcGuiButton(event)
    ServerInfoTabGuiClick(event)
    SpawnCtrlTabGuiClick(event)
    SettingsControlsTabGuiClick(event)
    SettingsSurfaceControlsTabGuiClick(event)
    PlayerListTabGuiClick(event)
    SurfaceConfigTabGuiClick(event)
    OarcItemShopGuiClick(event)
end

---All gui tabs on_gui_checked_state_changed event handler
---@param event EventData.on_gui_checked_state_changed
---@return nil
function OarcGuiTabsCheckedStateChanged(event)
    if not event.element.valid then return end
    SpawnCtrlGuiOptionsCheckedStateChanged(event)
end


---Handles the `on_gui_value_changed` event.
---@param event EventData.on_gui_value_changed
---@return nil
function OarcGuiTabsValueChanged(event)
    if not event.element.valid then return end
    SettingsControlsTabGuiValueChanged(event)
end

---Handles the `on_gui_selection_state_changed` event.
---@param event EventData.on_gui_selection_state_changed
---@return nil
function OarcGuiTabsSelectionStateChanged(event)
    if not event.element.valid then return end
    SettingsControlsTabGuiSelectionStateChanged(event)
    SurfaceConfigTabGuiSelect(event)
end

---Handles the `on_gui_text_changed` event.
---@param event EventData.on_gui_text_changed
---@return nil
function OarcGuiTabsTextChanged(event)
    if not event.element.valid then return end
    SettingsControlsTabGuiTextChanged(event)
    SurfaceConfigTabGuiTextChanged(event)
end

---Handles the `on_gui_confirmed` event.
---@param event EventData.on_gui_confirmed
---@return nil
function OarcGuiTabsConfirmed(event)
    if not event.element.valid then return end
    SettingsControlsTabGuiTextconfirmed(event)
    SurfaceConfigTabGuiConfirmed(event)
end

---Handles the `on_gui_elem_changed` event.
---@param event EventData.on_gui_elem_changed
---@return nil
function OarcGuiTabsElemChanged(event)
    if not event.element.valid then return end
    SurfaceConfigTabGuiElemChanged(event)
end
