-- Contains the GUI for the controlling various settings of the mod.

-- Used by AddOarcGuiTab
function CreateSettingsControlsTab(tab_container, player)
    AddLabel(tab_container, nil, "test settings controls my_label_style", my_label_style)
    AddLabel(tab_container, nil, "test settings controls my_label_header_style", my_label_header_style)
    AddLabel(tab_container, nil, "test settings controls my_label_header_grey_style", my_label_header_grey_style)
    AddLabel(tab_container, nil, "test settings controls my_note_style", my_note_style)
    AddLabel(tab_container, nil, "test settings controls my_warning_style", my_warning_style)
    AddLabel(tab_container, nil, "test settings controls my_longer_label_style", my_longer_label_style)
end