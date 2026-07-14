--!strict
local VSConfig = {}

-- Inventory
VSConfig.INVENTORY_SLOTS      = 25
VSConfig.STACK_SIZE           = 50
VSConfig.ITEM_PICKUP_RADIUS   = 10   -- studs
VSConfig.CONVEYOR_SNAP_RADIUS = 8    -- studs; auto-route drop to nearest conveyor input
VSConfig.DROP_DESPAWN_SECONDS = 300  -- 5 min

-- Tools
VSConfig.CHISEL_HIT_COOLDOWN = 0.4  -- seconds between hits

-- Trees (hand-chop)
VSConfig.FOREST_TREES_PER_PLOT    = 12
VSConfig.TREE_HEALTH              = 3   -- hits to fell
VSConfig.TREE_REGEN_SECONDS       = 30
VSConfig.FOREST_ZONE_RADIUS_TILES = 8

-- Deposits
VSConfig.DEPOSIT_CONFIG = {
    stone      = { infinite = true,  hitsPerYield = 1, yieldItem = "stone",      count = 8, radius = 10 },
    iron_ore   = { infinite = false, totalYield = 50,  yieldItem = "iron_ore",   count = 4, radius = 12 },
    copper_ore = { infinite = false, totalYield = 40,  yieldItem = "copper_ore", count = 3, radius = 12 },
    gold_ore   = { infinite = false, totalYield = 20,  yieldItem = "gold_ore",   count = 1, radius = 15 },
}

-- Machines
VSConfig.MACHINE_TICK_HZ           = 1
VSConfig.LUMBER_MILL_PROCESS_TICKS = 3   -- ticks: 1 log → 1 lumber
VSConfig.SMELTER_PROCESS_TICKS     = 5   -- ticks: 1 iron_ore → 1 iron_ingot
VSConfig.STORAGE_CHEST_CAPACITY    = 200
VSConfig.CONVEYOR_SPEED_TICKS      = 2
VSConfig.CONVEYOR_HEIGHT_STUDS     = 0.5
VSConfig.LUMBER_MILL_HARVEST_RADIUS = 14

-- Crafting bench
VSConfig.CRAFTING_BENCH_MAX_PER_PLOT = 3

-- Machine costs (items deducted from inventory on placement)
VSConfig.MACHINE_COSTS = {
    lumber_mill    = { log = 10, stone = 5, iron_ore = 3 },
    smelter        = { stone = 8, iron_ore = 5 },
    storage_chest  = { log = 8, iron_ore = 2 },
    conveyor_belt  = { log = 1 },   -- per segment
    crafting_bench = { log = 5, stone = 5 },
}

-- Machine refund on removal (fraction of cost returned as item)
VSConfig.MACHINE_REFUND_FRACTION = 0.5

-- Personal crafting recipes (no bench needed — available in inventory UI)
VSConfig.PERSONAL_RECIPES = {
    crafting_bench_item = { inputs = { log = 5, stone = 5 }, outputs = { crafting_bench_item = 1 } },
}

-- Bench crafting recipes
VSConfig.BENCH_RECIPES = {
    lumber_mill_item   = { inputs = { log = 10, stone = 5, iron_ore = 3 }, outputs = { lumber_mill_item = 1 } },
    smelter_item       = { inputs = { stone = 8, iron_ore = 5 },           outputs = { smelter_item = 1 } },
    storage_chest_item = { inputs = { log = 8, iron_ore = 2 },             outputs = { storage_chest_item = 1 } },
    conveyor_belt_item = { inputs = { log = 3 },                           outputs = { conveyor_belt_item = 5 } },
}

-- Nova Machina — Iteration I delivery goals
VSConfig.ITERATION_I_GOALS = {
    lumber    = 100,
    iron_ingot = 50,
}

-- Visual
VSConfig.FLOATING_TEXT_RISE_STUDS = 5
VSConfig.FLOATING_TEXT_DURATION   = 1.5

return VSConfig
