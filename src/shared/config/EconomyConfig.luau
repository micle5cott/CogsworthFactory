--!strict
-- Economy tuning: shop prices, multipliers, unlock costs.
-- All values are placeholders — final balance pass in Milestone 4.

local EconomyConfig = {}

-- Machine shop prices (coins). 0 = free starter machine.
EconomyConfig.MACHINE_PRICES = {
    -- Tier 1 (free starters)
    lumber_mill      = 0,
    stone_crusher    = 0,
    clay_furnace     = 0,
    gear_stamp       = 50,
    wire_braider     = 50,
    clockwork_bench  = 100,
    miner_mk1        = 75,
    storage_chest    = 25,
    research_station = 150,
    -- Tier 2+ prices set in Milestone 4
}

-- Multiplier applied to machine base price for specializations.
EconomyConfig.SPECIALIZATION_COST_MULTIPLIER = 3.0

-- Premium coin cost to unlock extra blueprint save slots.
EconomyConfig.BLUEPRINT_SLOT_PRICE_PREMIUM = 50

-- Coin cost to unlock Trophy Case display before first ascension.
EconomyConfig.TROPHY_UNLOCK_COINS = 500

-- Max coins a player can hold (prevents overflow exploits).
EconomyConfig.MAX_COINS = 1_000_000_000

return EconomyConfig
