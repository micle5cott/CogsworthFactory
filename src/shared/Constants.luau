--!strict

local Constants = {}

-- Conveyor throughput by tier (items per minute)
Constants.CONVEYOR_THROUGHPUT: {[number]: number} = {
    [1] = 30,
    [2] = 60,
    [3] = 120,
    [4] = 240,
    [5] = 480,
}

-- Machine defaults
Constants.MACHINE_BUFFER_SIZE = 10
Constants.RESEARCH_PACK_INTERVAL_SECONDS = 30   -- 1 pack consumed per 30 sec
Constants.MACHINE_EFFICIENCY_UPDATE_HZ = 2      -- efficiency recalc per second

-- Power
Constants.POWER_UPDATE_HZ = 1                   -- power grid recalc per second
Constants.PRESSURE_ACCUMULATOR_CAPACITY_PU = 500

-- Drone network
Constants.DRONE_DOCK_RADIUS_STUDS = 50
Constants.DRONE_DOCK_BASE_CAPACITY = 5
Constants.DRONE_DOCK_MAX_CAPACITY = 10          -- after Drone Expansion research
Constants.DRONE_DOCK_IDLE_POWER_PU = 120
Constants.DRONE_DOCK_ACTIVE_POWER_PER_DRONE_PU = 30
Constants.DRONE_CARRY_CAPACITY = 20             -- items per logistic trip
Constants.DRONE_CONSTRUCT_SECONDS_PER_MACHINE = 8

-- Trophy Case
Constants.TROPHY_CASE_SLOTS = 9

-- Rare node chances
Constants.RARE_NODE_CHANCE: {[string]: number} = {
    uncommon  = 0.03,
    rare      = 0.01,
    legendary = 0.001,
}

-- Embercoal boost
Constants.EMBERCOAL_BOOST_MULTIPLIER = 1.5
Constants.EMBERCOAL_BOOST_SECONDS = 60

-- Plot
Constants.MAX_CO_BUILDERS = 3
Constants.SAVE_INTERVAL_SECONDS = 60

-- Ascension
Constants.ASCENDANT_POWER_REQUIRED_PU = 10000
Constants.ASCENDANT_ACTIVATION_SECONDS = 60
Constants.ASCENDANT_ACTIVATION_COST: {itemId: string, count: number} = {
    { itemId = "clockwork_automaton", count = 500 },
    { itemId = "pure_aether",         count = 200 },
    { itemId = "resonance_core",      count = 100 },
}

return Constants
