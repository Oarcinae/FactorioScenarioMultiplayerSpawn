-- Contains the GUI for the regrowth controls tab.

---Used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateRegrowthControlsTab(tab_container, player)
    AddLabel(tab_container, nil, "test regrowth message my_label_style", my_label_style)
    AddLabel(tab_container, nil, "test regrowth message my_label_header_style", my_label_header_style)
    AddLabel(tab_container, nil, "test regrowth message my_label_header_grey_style", my_label_header_grey_style)
    AddLabel(tab_container, nil, "test regrowth message my_note_style", my_note_style)
    AddLabel(tab_container, nil, "test regrowth message my_warning_style", my_warning_style)
    AddLabel(tab_container, nil, "test regrowth message my_longer_label_style", my_longer_label_style)
end