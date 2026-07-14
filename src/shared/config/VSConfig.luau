--!strict
local VSConfig = {}

-- Economy
VSConfig.SELL_PRICE: {[string]: number} = {
    lumber = 10,
    log    = 3,
}
VSConfig.MACHINE_SHOP_PRICES: {[string]: number} = {
    lumber_mill    = 0,
    storage_chest  = 25,
    seller_station = 50,
    conveyor_belt  = 5,
}
VSConfig.MACHINE_REFUND_FRACTION = 0.5

-- Trees
VSConfig.FOREST_TREES_PER_PLOT      = 12
VSConfig.TREE_HEALTH                = 3
VSConfig.TREE_REGEN_SECONDS         = 20
VSConfig.LUMBER_MILL_HARVEST_RADIUS = 14  -- studs

-- Machines
VSConfig.MACHINE_TICK_HZ            = 1   -- 1 tick per second
VSConfig.LUMBER_MILL_PROCESS_TICKS  = 3   -- ticks to convert 1 log → 1 lumber
VSConfig.STORAGE_CHEST_CAPACITY     = 50
VSConfig.CONVEYOR_SPEED_TICKS       = 2   -- ticks to cross one segment

-- World
VSConfig.FOREST_OFFSET_TILES        = {x = -20, z = 0}  -- forest origin relative to plot

-- Visual
VSConfig.FLOATING_TEXT_RISE_STUDS   = 5
VSConfig.FLOATING_TEXT_DURATION     = 1.5

return VSConfig
