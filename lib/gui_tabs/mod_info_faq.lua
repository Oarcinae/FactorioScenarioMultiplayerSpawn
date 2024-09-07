-- Contains the GUI for the regrowth controls tab.

---Used by AddOarcGuiTab
---@param tab_container LuaGuiElement
---@param player LuaPlayer
---@return nil
function CreateModInfoTab(tab_container, player)

    AddLabel(tab_container, nil, "Mod Info & FAQ", my_label_header2_style)
    AddSpacerLine(tab_container)

    CreateFAQEntry(tab_container, { "oarc-mod-faq-what-is-this-mod" }, { "oarc-mod-faq-what-is-this-mod-answer" })
    CreateFAQEntry(tab_container, { "oarc-mod-faq-other-surfaces" }, { "oarc-mod-faq-other-surfaces-answer" })
    CreateFAQEntry(tab_container, { "oarc-mod-faq-what-are-teams" }, { "oarc-mod-faq-what-are-teams-answer" })
    CreateFAQEntry(tab_container, { "oarc-mod-faq-shared-spawn" }, { "oarc-mod-faq-shared-spawn-answer" })
    CreateFAQEntry(tab_container, { "oarc-mod-faq-buddy-spawn" }, { "oarc-mod-faq-buddy-spawn-answer" })
    CreateFAQEntry(tab_container, { "oarc-mod-faq-regrowth" }, { "oarc-mod-faq-regrowth-answer" })
    CreateFAQEntry(tab_container, { "oarc-mod-faq-cleanup-abandoned" }, { "oarc-mod-faq-cleanup-abandoned-answer" })
    CreateFAQEntry(tab_container, { "oarc-mod-faq-offline-protection" }, { "oarc-mod-faq-offline-protection-answer" })

end

---Creates a FAQ entry in the tab
---@param tab_container LuaGuiElement
---@param question LocalisedString
---@param answer LocalisedString
---@return nil
function CreateFAQEntry(tab_container, question, answer)
    AddLabel(tab_container, nil, question, "caption_label")
    AddLabel(tab_container, nil, answer, my_longer_label_style)
    AddSpacerLine(tab_container)
end