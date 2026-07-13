--!strict

export type PackRequirement = {
    itemId: string,
    count: number,
}

export type ResearchNode = {
    id: string,
    name: string,
    description: string,
    packRequirements: {PackRequirement},
    unlocks: {string},         -- machine ids, biome ids, or misc unlock strings
    prerequisite: string?,     -- researchId that must be completed first (nil = available from start)
    isSideBranch: boolean,
}

local Research: {[string]: ResearchNode} = {

    -- ── Main Tier Unlocks ────────────────────────────────────────

    tier2_main = {
        id="tier2_main", name="Iron & Copper Mastery", isSideBranch=false,
        description="Unlock Tier 2 machines: Smelters, Gear Presses, Steam Power.",
        packRequirements={
            { itemId="iron_gear",   count=10 },
            { itemId="copper_wire", count=10 },
        },
        unlocks={"smelter","gear_press","copper_refinery","wire_refinery",
                 "roller_press","panel_bender","steam_boiler","steam_engine","storage_mk2"},
        prerequisite=nil,
    },

    tier3_main = {
        id="tier3_main", name="Steel & Steam", isSideBranch=false,
        description="Unlock Tier 3 machines: Forge, Assemblers, Pressurized Steam engines.",
        packRequirements={
            { itemId="clockwork_module", count=20 },
            { itemId="steam_capsule",    count=10 },
            { itemId="glass_lens",       count=5 },
        },
        unlocks={"forge","glass_kiln","assembler_mk1","roller_press_mk2",
                 "forge_press","pressure_engine","pressure_accumulator"},
        prerequisite="tier2_main",
    },

    tier4_main = {
        id="tier4_main", name="Precision Engineering", isSideBranch=false,
        description="Unlock Tier 4 machines: Precision Lathes, Coil Winders, Clockwork Dynamos.",
        packRequirements={
            { itemId="optical_assembly", count=15 },
            { itemId="conductor_coil",   count=20 },
            { itemId="reinforced_frame", count=10 },
        },
        unlocks={"precision_lathe","coil_winder","optical_refinery","advanced_assembler",
                 "obsidian_cutter","clockwork_dynamo","smart_splitter"},
        prerequisite="tier3_main",
    },

    tier5_main = {
        id="tier5_main", name="Clockwork Mastery", isSideBranch=false,
        description="Unlock Tier 5 machines: Automaton Workshop, Crystal Refinery, Crystal Resonator.",
        packRequirements={
            { itemId="automaton_core", count=10 },
            { itemId="resonance_core", count=5 },
            { itemId="precision_gear", count=20 },
        },
        unlocks={"automaton_workshop","crystal_refinery","resonance_forge",
                 "crystal_resonator","automaton_loader"},
        prerequisite="tier4_main",
    },

    tier6_main = {
        id="tier6_main", name="Ascension", isSideBranch=false,
        description="Unlock Tier 6: Aether Refinery, Resonance Amplifier, and the Clockwork Ascendant.",
        packRequirements={
            { itemId="clockwork_automaton", count=20 },
            { itemId="aether_crystal",      count=10 },
            { itemId="resonance_core",      count=5 },
        },
        unlocks={"aether_refinery","resonance_amplifier","clockwork_ascendant"},
        prerequisite="tier5_main",
    },

    -- ── Tier 2 Side Branches ─────────────────────────────────────

    tier2_biome2 = {
        id="tier2_biome2", name="Highland Expedition", isSideBranch=true,
        description="Unlock Biome 2: Highland Reach. Rich iron and copper deposits.",
        packRequirements={
            { itemId="iron_plate",  count=10 },
            { itemId="copper_wire", count=5 },
        },
        unlocks={"biome_highland_reach"},
        prerequisite="tier2_main",
    },

    tier2_smelter_spec = {
        id="tier2_smelter_spec", name="Smelter Specialization", isSideBranch=true,
        description="Unlock Blast Furnace and Precision Forge specializations.",
        packRequirements={{ itemId="iron_gear", count=15 }},
        unlocks={"spec_blast_furnace","spec_precision_forge"},
        prerequisite="tier2_main",
    },

    tier2_roller_press = {
        id="tier2_roller_press", name="Rolling Mill", isSideBranch=true,
        description="Unlock the Roller Press for Iron Plate production.",
        packRequirements={{ itemId="iron_ingot", count=15 }},
        unlocks={"roller_press"},
        prerequisite="tier2_main",
    },

    -- ── Tier 3 Side Branches ─────────────────────────────────────

    tier3_biome3 = {
        id="tier3_biome3", name="Volcanic Expedition", isSideBranch=true,
        description="Unlock Biome 3: Volcanic Depths. Coal, Obsidian, and Sulphur deposits.",
        packRequirements={
            { itemId="steel_plate", count=15 },
            { itemId="glass_lens",  count=10 },
        },
        unlocks={"biome_volcanic_depths"},
        prerequisite="tier3_main",
    },

    tier3_assembler_spec = {
        id="tier3_assembler_spec", name="Assembler Specialization", isSideBranch=true,
        description="Unlock High-Volume and Quality specializations for Assembler Mk1.",
        packRequirements={{ itemId="clockwork_module", count=20 }},
        unlocks={"spec_high_volume","spec_quality"},
        prerequisite="tier3_main",
    },

    tier3_miner_mk2 = {
        id="tier3_miner_mk2", name="Industrial Mining", isSideBranch=true,
        description="Unlock Miner Mk2 for 2× ore output.",
        packRequirements={
            { itemId="steel_plate",      count=10 },
            { itemId="clockwork_module", count=5 },
        },
        unlocks={"miner_mk2"},
        prerequisite="tier3_main",
    },

    tier3_conveyor_mk3 = {
        id="tier3_conveyor_mk3", name="High-Speed Conveyors", isSideBranch=true,
        description="Unlock Conveyor Mk3 (120 items/min).",
        packRequirements={{ itemId="steel_plate", count=10 }},
        unlocks={"conveyor_mk3"},
        prerequisite="tier3_main",
    },

    tier3_pressure_accumulator = {
        id="tier3_pressure_accumulator", name="Power Storage", isSideBranch=true,
        description="Unlock the Pressure Accumulator for burst power buffering.",
        packRequirements={
            { itemId="iron_gear",   count=20 },
            { itemId="copper_wire", count=10 },
        },
        unlocks={"pressure_accumulator"},
        prerequisite="tier3_main",
    },

    -- ── Tier 4 Side Branches ─────────────────────────────────────

    tier4_biome4 = {
        id="tier4_biome4", name="Crystal Expedition", isSideBranch=true,
        description="Unlock Biome 4: Crystal Caverns. Crystal Shards and Resonance Stone.",
        packRequirements={
            { itemId="optical_assembly", count=20 },
            { itemId="conductor_coil",   count=15 },
        },
        unlocks={"biome_crystal_caverns"},
        prerequisite="tier4_main",
    },

    tier4_lathe_spec = {
        id="tier4_lathe_spec", name="Lathe Specialization", isSideBranch=true,
        description="Unlock Mass Lathe and Artisan Lathe specializations.",
        packRequirements={{ itemId="precision_gear", count=25 }},
        unlocks={"spec_mass_lathe","spec_artisan_lathe"},
        prerequisite="tier4_main",
    },

    tier4_logistics_mk2 = {
        id="tier4_logistics_mk2", name="Advanced Logistics", isSideBranch=true,
        description="Unlock overflow valves, item filters, and priority routing.",
        packRequirements={{ itemId="conductor_coil", count=20 }},
        unlocks={"overflow_valve","item_filter","priority_router"},
        prerequisite="tier4_main",
    },

    tier4_conveyor_mk4 = {
        id="tier4_conveyor_mk4", name="Precision Conveyors", isSideBranch=true,
        description="Unlock Conveyor Mk4 (240 items/min).",
        packRequirements={
            { itemId="steel_plate",    count=15 },
            { itemId="conductor_coil", count=10 },
        },
        unlocks={"conveyor_mk4"},
        prerequisite="tier4_main",
    },

    tier4_drone_network = {
        id="tier4_drone_network", name="Drone Network", isSideBranch=true,
        description="Unlock Drone Docks, Logistic Drones, Construction Drones, and Logistic Chests.",
        packRequirements={
            { itemId="optical_assembly", count=20 },
            { itemId="conductor_coil",   count=10 },
            { itemId="precision_gear",   count=10 },
        },
        unlocks={"drone_dock","logistic_chest_provider","logistic_chest_requester","logistic_chest_buffer"},
        prerequisite="tier4_main",
    },

    -- ── Tier 5 Side Branches ─────────────────────────────────────

    tier5_biome5 = {
        id="tier5_biome5", name="Aether Expedition", isSideBranch=true,
        description="Unlock Biome 5: Aether Rift. Aether Crystals and Void Stone.",
        packRequirements={
            { itemId="resonance_core", count=20 },
            { itemId="automaton_core", count=10 },
        },
        unlocks={"biome_aether_rift"},
        prerequisite="tier5_main",
    },

    tier5_workshop_spec = {
        id="tier5_workshop_spec", name="Automaton Specialization", isSideBranch=true,
        description="Unlock Automaton Foreman and Automaton Courier specializations.",
        packRequirements={{ itemId="automaton_core", count=20 }},
        unlocks={"spec_automaton_foreman","spec_automaton_courier"},
        prerequisite="tier5_main",
    },

    tier5_miner_mk3 = {
        id="tier5_miner_mk3", name="Deep Mining", isSideBranch=true,
        description="Unlock Miner Mk3 for maximum ore yield.",
        packRequirements={{ itemId="automaton_core", count=15 }},
        unlocks={"miner_mk3"},
        prerequisite="tier5_main",
    },

    tier5_conveyor_mk5 = {
        id="tier5_conveyor_mk5", name="Crystal Conveyors", isSideBranch=true,
        description="Unlock Conveyor Mk5 (480 items/min).",
        packRequirements={
            { itemId="automaton_core", count=20 },
            { itemId="resonance_core", count=10 },
        },
        unlocks={"conveyor_mk5"},
        prerequisite="tier5_main",
    },

    tier5_scout_drones = {
        id="tier5_scout_drones", name="Scout Drones", isSideBranch=true,
        description="Unlock Scout Drones to reveal rare node locations before mining.",
        packRequirements={
            { itemId="automaton_core", count=10 },
            { itemId="resonance_core", count=5 },
        },
        unlocks={"scout_drone"},
        prerequisite="tier4_drone_network",
    },
}

return Research
