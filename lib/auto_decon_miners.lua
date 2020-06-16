-- auto_decon_miners.lua
-- May 2020
-- My shitty softmod version which is buggy

function OarcAutoDeconOnInit(event)
	if (not global.depleted_miners_check) then
		global.depleted_miners_check = {}
	end
end

function OarcAutoDeconOnTick()
    if (global.depleted_miners_check and (#global.depleted_miners_check > 0)) then
        for i,miner in pairs(global.depleted_miners_check) do
            if ((not miner) or (not miner.valid)) then
                table.remove(global.depleted_miners_check, i)

            else
                if (#miner.surface.find_entities_filtered{area = {{miner.position.x-3, miner.position.y-3},
                                                                            {miner.position.x+3, miner.position.y+3}},
                                                                            type = "resource", limit = 1} == 0) then
                    miner.order_deconstruction(miner.force)
                end
                table.remove(global.depleted_miners_check, i)
            end
        end
    end
end

function OarcAutoDeconOnResourceDepleted(event)
	if (not global.depleted_miners_check) then
		global.depleted_miners_check = {}
	end
    if (event.entity and event.entity.position and event.entity.surface) then

        local nearby_miners = event.entity.surface.find_entities_filtered{area = {{event.entity.position.x-1, event.entity.position.y-1},
                                                                                        {event.entity.position.x+1, event.entity.position.y+1}},
                                                                            name = {"burner-mining-drill", "electric-mining-drill"}}

        for i,v in pairs(nearby_miners) do
            table.insert(global.depleted_miners_check, v)
        end
    end
end
