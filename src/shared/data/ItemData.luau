--!strict

export type ItemDef = {
    id: string,
    name: string,
    tier: number,
    isRaw: boolean?,
    isRare: boolean?,
    rarityTier: ("uncommon" | "rare" | "legendary")?,
}

local Items: {[string]: ItemDef} = {
    -- ── Raw Resources ────────────────────────────────────────────
    wood             = { id="wood",             name="Wood",             tier=1, isRaw=true },
    stone            = { id="stone",            name="Stone",            tier=1, isRaw=true },
    iron_ore         = { id="iron_ore",         name="Iron Ore",         tier=1, isRaw=true },
    copper_ore       = { id="copper_ore",       name="Copper Ore",       tier=1, isRaw=true },
    coal             = { id="coal",             name="Coal",             tier=1, isRaw=true },
    raw_ore          = { id="raw_ore",          name="Raw Ore",          tier=1, isRaw=true }, -- miner placeholder; resolved to actual ore type at runtime
    granite          = { id="granite",          name="Granite",          tier=2, isRaw=true },
    obsidian         = { id="obsidian",         name="Obsidian",         tier=3, isRaw=true },
    sulphur          = { id="sulphur",          name="Sulphur",          tier=3, isRaw=true },
    crystal_shard    = { id="crystal_shard",    name="Crystal Shard",    tier=4, isRaw=true },
    resonance_stone  = { id="resonance_stone",  name="Resonance Stone",  tier=4, isRaw=true },
    quartz           = { id="quartz",           name="Quartz",           tier=4, isRaw=true },
    aether_crystal   = { id="aether_crystal",   name="Aether Crystal",   tier=5, isRaw=true },
    void_stone       = { id="void_stone",       name="Void Stone",       tier=5, isRaw=true },

    -- ── Tier 1 Processed ─────────────────────────────────────────
    lumber            = { id="lumber",            name="Lumber",            tier=1 },
    crushed_stone     = { id="crushed_stone",     name="Crushed Stone",     tier=1 },
    iron_ingot        = { id="iron_ingot",        name="Iron Ingot",        tier=1 },
    copper_ingot      = { id="copper_ingot",      name="Copper Ingot",      tier=1 },
    iron_gear         = { id="iron_gear",         name="Iron Gear",         tier=1 },
    copper_wire       = { id="copper_wire",       name="Copper Wire",       tier=1 },
    clockwork_module  = { id="clockwork_module",  name="Clockwork Module",  tier=1 },

    -- ── Tier 2 Processed ─────────────────────────────────────────
    steam              = { id="steam",              name="Steam",              tier=2 },
    iron_plate         = { id="iron_plate",         name="Iron Plate",         tier=2 },
    reinforced_panel   = { id="reinforced_panel",   name="Reinforced Panel",   tier=2 },
    quality_ingot      = { id="quality_ingot",      name="Quality Ingot",      tier=2 }, -- from Precision Forge

    -- ── Tier 3 Processed ─────────────────────────────────────────
    steel_ingot       = { id="steel_ingot",       name="Steel Ingot",       tier=3 },
    steel_plate       = { id="steel_plate",       name="Steel Plate",       tier=3 },
    reinforced_frame  = { id="reinforced_frame",  name="Reinforced Frame",  tier=3 },
    glass_lens        = { id="glass_lens",        name="Glass Lens",        tier=3 },
    steam_capsule     = { id="steam_capsule",     name="Steam Capsule",     tier=3 },
    quality_assembly  = { id="quality_assembly",  name="Quality Assembly",  tier=3 }, -- from Quality Assembler

    -- ── Tier 4 Processed ─────────────────────────────────────────
    precision_gear    = { id="precision_gear",    name="Precision Gear",    tier=4 },
    master_gear       = { id="master_gear",       name="Master Gear",       tier=4 }, -- from Artisan Lathe
    conductor_coil    = { id="conductor_coil",    name="Conductor Coil",    tier=4 },
    optical_assembly  = { id="optical_assembly",  name="Optical Assembly",  tier=4 },
    advanced_frame    = { id="advanced_frame",    name="Advanced Frame",    tier=4 },
    obsidian_shard    = { id="obsidian_shard",    name="Obsidian Shard",    tier=4 },

    -- ── Tier 5 Processed ─────────────────────────────────────────
    automaton_core          = { id="automaton_core",          name="Automaton Core",          tier=5 },
    steam_chassis           = { id="steam_chassis",           name="Steam Chassis",           tier=5 },
    resonance_core          = { id="resonance_core",          name="Resonance Core",          tier=5 },
    conductor_array         = { id="conductor_array",         name="Conductor Array",         tier=5 },
    clockwork_automaton     = { id="clockwork_automaton",     name="Clockwork Automaton",     tier=5 },
    automaton_foreman_unit  = { id="automaton_foreman_unit",  name="Automaton Foreman",       tier=5 },
    automaton_courier_unit  = { id="automaton_courier_unit",  name="Automaton Courier",       tier=5 },

    -- ── Tier 6 Processed ─────────────────────────────────────────
    pure_aether = { id="pure_aether", name="Pure Aether", tier=6 },

    -- ── Rare Items (Design §18) ───────────────────────────────────
    starfire_ingot    = { id="starfire_ingot",    name="Starfire Ingot",    tier=1, isRare=true, rarityTier="rare" },
    mooncopper_ingot  = { id="mooncopper_ingot",  name="Mooncopper Ingot",  tier=1, isRare=true, rarityTier="rare" },
    gilded_alloy      = { id="gilded_alloy",      name="Gilded Alloy",      tier=2, isRare=true, rarityTier="rare" },
    embercoal         = { id="embercoal",         name="Embercoal",         tier=2, isRare=true, rarityTier="uncommon" },
    heart_of_obsidian = { id="heart_of_obsidian", name="Heart of Obsidian", tier=3, isRare=true, rarityTier="legendary" },
    pure_sulphur      = { id="pure_sulphur",      name="Pure Sulphur",      tier=3, isRare=true, rarityTier="rare" },
    prismatic_shard   = { id="prismatic_shard",   name="Prismatic Shard",   tier=4, isRare=true, rarityTier="legendary" },
    resonance_gem     = { id="resonance_gem",     name="Resonance Gem",     tier=4, isRare=true, rarityTier="rare" },
    void_fragment     = { id="void_fragment",     name="Void Fragment",     tier=5, isRare=true, rarityTier="legendary" },
    pure_aether_bloom = { id="pure_aether_bloom", name="Pure Aether Bloom", tier=5, isRare=true, rarityTier="rare" },
}

return Items
