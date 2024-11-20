-- Contains the GUI for the regrowth controls tab.

---Used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateModInfoTab(tab_container, player)

    local scroll_pane = tab_container.add {
        type = "scroll-pane",
        vertical_scroll_policy = "auto",
    }
    scroll_pane.style.maximal_height = GENERIC_GUI_MAX_HEIGHT
    scroll_pane.style.padding = 5

    AddLabel(scroll_pane, nil, "Mod Info & FAQ", my_label_header2_style)
    AddSpacerLine(scroll_pane)

    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-what-is-this-mod" }, { "oarc-mod-faq-what-is-this-mod-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-other-surfaces" }, { "oarc-mod-faq-other-surfaces-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-secondary-spawns" }, { "oarc-mod-faq-secondary-spawns-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-enemy-scaling" }, { "oarc-mod-faq-enemy-scaling-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-what-are-teams" }, { "oarc-mod-faq-what-are-teams-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-shared-spawn" }, { "oarc-mod-faq-shared-spawn-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-buddy-spawn" }, { "oarc-mod-faq-buddy-spawn-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-regrowth" }, { "oarc-mod-faq-regrowth-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-cleanup-abandoned" }, { "oarc-mod-faq-cleanup-abandoned-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-offline-protection" }, { "oarc-mod-faq-offline-protection-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-shared-power" }, { "oarc-mod-faq-shared-power-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-mod-faq-shared-chest" }, { "oarc-mod-faq-shared-chest-answer" })

end

---Creates a FAQ entry in the tab
---@param container LuaGuiElement
---@param question LocalisedString
---@param answer LocalisedString
---@return nil
function CreateFAQEntry(container, question, answer)
    AddLabel(container, nil, question, "caption_label")
    AddLabel(container, nil, answer, my_longer_label_style)
    AddSpacerLine(container)
end