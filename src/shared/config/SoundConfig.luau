--!strict
-- Sound asset IDs and volume levels.
-- Replace placeholder IDs (0) with real Roblox asset IDs in Milestone 4/5.

local SoundConfig = {}

SoundConfig.SOUNDS: {[string]: {id: number, volume: number}} = {
    machine_place         = { id = 0, volume = 0.8 },
    machine_remove        = { id = 0, volume = 0.6 },
    machine_running_loop  = { id = 0, volume = 0.4 },
    research_complete     = { id = 0, volume = 1.0 },
    tier_unlock           = { id = 0, volume = 1.0 },
    rare_node_uncommon    = { id = 0, volume = 0.9 },
    rare_node_rare        = { id = 0, volume = 1.0 },
    rare_node_legendary   = { id = 0, volume = 1.0 },
    ascension_trigger     = { id = 0, volume = 1.0 },
    ascension_complete    = { id = 0, volume = 1.0 },
    conveyor_jam          = { id = 0, volume = 0.5 },
    power_blackout        = { id = 0, volume = 0.8 },
    power_restore         = { id = 0, volume = 0.6 },
    coin_earn             = { id = 0, volume = 0.6 },
    blueprint_save        = { id = 0, volume = 0.7 },
    ambient_factory       = { id = 0, volume = 0.3 },
}

-- Biome ambient music tracks (Roblox asset IDs — placeholders).
SoundConfig.BIOME_MUSIC: {[string]: number} = {
    verdant_hollow  = 0,
    highland_reach  = 0,
    volcanic_depths = 0,
    crystal_caverns = 0,
    aether_rift     = 0,
}

return SoundConfig
