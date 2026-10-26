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

    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-what-is-this-mod" }, { "oarc-classic-faq-what-is-this-mod-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-starting-points" }, { "oarc-classic-faq-starting-points-answer" })
    if IsOarcStyleSpawnAllowed() then
        CreateFAQEntry(scroll_pane, { "oarc-classic-faq-oarc-style-spawn" }, { "oarc-classic-faq-oarc-style-spawn-answer" })
    end
    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-other-surfaces" }, { "oarc-classic-faq-other-surfaces-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-secondary-spawns" }, { "oarc-classic-faq-secondary-spawns-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-reroll" }, { "oarc-classic-faq-reroll-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-what-are-teams" }, { "oarc-classic-faq-what-are-teams-answer" })
    if (storage.ocfg.gameplay.reset_evolution_on_new_spawn) then
        CreateFAQEntry(scroll_pane, { "oarc-classic-faq-evolution-reset" }, { "oarc-classic-faq-evolution-reset-answer" })
    end
    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-shared-spawn" }, { "oarc-classic-faq-shared-spawn-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-regrowth" }, { "oarc-classic-faq-regrowth-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-cleanup-abandoned" }, { "oarc-classic-faq-cleanup-abandoned-answer" })
    CreateFAQEntry(scroll_pane, { "oarc-classic-faq-offline-protection" }, { "oarc-classic-faq-offline-protection-answer" })

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