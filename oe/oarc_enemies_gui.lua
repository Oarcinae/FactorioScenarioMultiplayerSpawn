-- oarc_enemis_gui.lua
-- July 2019
-- GUI for my enemy mod

require("mod-gui")

function OarcEnemiesCreateGui(event)
    local player = game.players[event.player_index]
    if mod_gui.get_button_flow(player).oarc_enemies == nil then
        mod_gui.get_button_flow(player).add{name="oarc_enemies", type="button", caption="OE", style=mod_gui.button_style}
    end
end

local function ExpandOarcEnemiesGui(player)
    local frame = mod_gui.get_frame_flow(player)["oe-panel"]
    if (frame) then
        frame.destroy()
    else
        local frame = mod_gui.get_frame_flow(player).add{type="frame", name="oe-panel", caption="Oarc's Enemies:", direction = "vertical"}

        AddLabel(frame, "oe_note", "These buttons and info are for testing/debugging my enemy mod.", my_warning_style)

        frame.add{type="button", caption="Player Attack", name="oe_attack_player"}
        frame.add{type="button", caption="General Attack", name="oe_attack_any"}
        frame.add{type="button", caption="Science Labs Attack", name="oe_attack_labs"}
        frame.add{type="button", caption="Furnace Attack", name="oe_attack_furnace"}
        frame.add{type="button", caption="Mining Attack", name="oe_attack_mining"}
        frame.add{type="button", caption="Turret Attack", name="oe_attack_turret"}

        local oe_info="General Info:" .. "\n" ..
                        "Attacks: " .. #global.oe.attacks .. "\n" ..
                        "Tech levels: " .. global.oe.tech_levels[player.force.index] .. "\n" ..
                        "Next Player Attack: " .. global.oe.player_timers[player.index]["character"] .. "\n" ..
                        "Next Building Attack: " .. global.oe.player_timers[player.index]["generic"] ..
                        " "
        AddLabel(frame, "oe_info", oe_info, my_longer_label_style)
    end
end

function OarcEnemiesGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local name = event.element.name

    if (name == "oarc_enemies") then
        ExpandOarcEnemiesGui(player)
    end

    if (name == "oe_attack_player") then
        OarcEnemiesPlayerAttackCharacter(player.index)
    end

    if (name == "oe_attack_any") then
        OarcEnemiesBuildingAttack(player.index, OE_GENERIC_TARGETS)
    end

    if (name == "oe_attack_labs") then
        OarcEnemiesScienceLabAttack(player.force.index)
    end

    if (name == "oe_attack_furnace") then
        OarcEnemiesBuildingAttack(player.index, "furnace")
    end

    if (name == "oe_attack_mining") then
        OarcEnemiesBuildingAttack(player.index, "mining-drill")
    end

    if (name == "oe_attack_turret") then
        OarcEnemiesBuildingAttack(player.index, {"ammo-turret",
                                                "electric-turret",
                                                "fluid-turret",
                                                "artillery-turret"})
    end




end
