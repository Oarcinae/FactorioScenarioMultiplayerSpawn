-- Add new coin shop settings and config.

if global.ocfg.gameplay.enable_coin_shop == nil then
    global.ocfg.gameplay.enable_coin_shop = false -- Default to off
end

if global.ocfg.shop_items == nil then
    global.ocfg.shop_items = table.deepcopy(OARC_SHOP_ITEMS)
end

if global.ocfg.coin_generation == nil then
    global.ocfg.coin_generation = table.deepcopy(OCFG.coin_generation)
end