--!strict
-- Central configuration hub. All tunable values live here.
-- No gameplay numbers should be hardcoded in service logic.

local GameConfig = {}

-- ── Debug ─────────────────────────────────────────────────────────────────────
GameConfig.DEBUG_LOGGING = false

-- ── DataStore ─────────────────────────────────────────────────────────────────
GameConfig.DATASTORE_NAME             = "PlayerData_v1"
GameConfig.DATASTORE_MAX_RETRIES      = 3
GameConfig.DATASTORE_RETRY_DELAY_SECONDS = 2

-- ── Save ──────────────────────────────────────────────────────────────────────
GameConfig.AUTOSAVE_INTERVAL_SECONDS  = 60

-- ── Simulation ticks ──────────────────────────────────────────────────────────
GameConfig.MACHINE_TICK_HZ            = 2
GameConfig.POWER_TICK_HZ              = 1
GameConfig.CONVEYOR_TICK_HZ           = 2

-- ── Economy ───────────────────────────────────────────────────────────────────
GameConfig.STARTING_COINS             = 200
GameConfig.STARTING_PREMIUM_COINS     = 0

-- ── Plot ──────────────────────────────────────────────────────────────────────
GameConfig.MAX_CO_BUILDERS            = 3
GameConfig.PLOT_SIZE_TILES            = 100  -- 100 × 100 tile grid
GameConfig.TILE_SIZE_STUDS            = 4

-- ── Machines ──────────────────────────────────────────────────────────────────
GameConfig.MACHINE_BUFFER_SIZE        = 10
GameConfig.MACHINE_EFFICIENCY_UPDATE_HZ = 2

-- ── Research ──────────────────────────────────────────────────────────────────
GameConfig.RESEARCH_PACK_INTERVAL_SECONDS = 30

-- ── Power ─────────────────────────────────────────────────────────────────────
GameConfig.POWER_UPDATE_HZ            = 1
GameConfig.PRESSURE_ACCUMULATOR_CAPACITY_PU = 500

-- ── Drones ────────────────────────────────────────────────────────────────────
GameConfig.DRONE_DOCK_RADIUS_STUDS    = 50
GameConfig.DRONE_DOCK_BASE_CAPACITY   = 5
GameConfig.DRONE_DOCK_MAX_CAPACITY    = 10
GameConfig.DRONE_DOCK_IDLE_POWER_PU   = 120
GameConfig.DRONE_DOCK_ACTIVE_POWER_PU = 30
GameConfig.DRONE_CARRY_CAPACITY       = 20
GameConfig.DRONE_CONSTRUCT_SECONDS    = 8

-- ── Rare nodes ────────────────────────────────────────────────────────────────
GameConfig.RARE_NODE_CHANCE = {
    uncommon  = 0.03,
    rare      = 0.01,
    legendary = 0.001,
}

-- ── Trophy Case ───────────────────────────────────────────────────────────────
GameConfig.TROPHY_CASE_SLOTS          = 9

-- ── Ascension ─────────────────────────────────────────────────────────────────
GameConfig.ASCENDANT_POWER_REQUIRED_PU   = 10000
GameConfig.ASCENDANT_ACTIVATION_SECONDS  = 60

-- ── Embercoal ─────────────────────────────────────────────────────────────────
GameConfig.EMBERCOAL_BOOST_MULTIPLIER = 1.5
GameConfig.EMBERCOAL_BOOST_SECONDS    = 60

-- ── Save ──────────────────────────────────────────────────────────────────────
GameConfig.SAVE_INTERVAL_SECONDS      = 60

return GameConfig
