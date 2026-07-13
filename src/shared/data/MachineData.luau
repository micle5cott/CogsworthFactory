--!strict

export type InputDef = {
    itemId: string,
    rate: number,   -- items consumed per second at 100% efficiency
}

export type OutputDef = {
    itemId: string,
    rate: number,   -- items produced per second at 100% efficiency
}

export type BuildCostEntry = {
    itemId: string,
    count: number,
}

export type SpecializationDef = {
    id: string,
    name: string,
    description: string,
    outputMultiplier: number,       -- multiplies base output rate
    powerMultiplier: number,        -- multiplies base powerDraw
    alternateOutputItemId: string?, -- if non-nil, replaces the base output itemId
}

export type MachineDef = {
    id: string,
    name: string,
    tier: number,
    powerDraw: number,          -- PU consumed per second (0 = no power needed)
    inputs: {InputDef},
    outputs: {OutputDef},
    buildCost: {BuildCostEntry},
    bufferSize: number,
    smeltsOre: boolean?,        -- accepts any ore; outputs corresponding ingot (clay_furnace, smelter)
    isMiner: boolean?,
    isStorage: boolean?,
    storageCapacity: number?,
    isGenerator: boolean?,
    generatorOutput: number?,   -- PU produced per second
    isResearchStation: boolean?,
    isDroneDock: boolean?,
    isLogistics: boolean?,      -- splitters, loaders, smart-routing machines
    specializations: {SpecializationDef}?,
}

local Machines: {[string]: MachineDef} = {

    -- ════════════════════════════════════════════════════════════
    -- TIER 1 — No Power Required
    -- ════════════════════════════════════════════════════════════

    lumber_mill = {
        id="lumber_mill", name="Lumber Mill", tier=1, powerDraw=0,
        inputs={}, outputs={{ itemId="lumber", rate=2 }},
        buildCost={{ itemId="wood", count=5 }},
        bufferSize=10, isMiner=true,
    },

    stone_crusher = {
        id="stone_crusher", name="Stone Crusher", tier=1, powerDraw=0,
        inputs={}, outputs={{ itemId="crushed_stone", rate=2 }},
        buildCost={{ itemId="lumber", count=10 }},
        bufferSize=10, isMiner=true,
    },

    clay_furnace = {
        id="clay_furnace", name="Clay Furnace", tier=1, powerDraw=0,
        -- smeltsOre=true: whichever ore arrives is smelted; rate/output resolved at runtime
        inputs={
            { itemId="iron_ore",   rate=1 },
            { itemId="copper_ore", rate=1 },
        },
        outputs={
            { itemId="iron_ingot",   rate=0.5 },
            { itemId="copper_ingot", rate=0.5 },
        },
        buildCost={
            { itemId="lumber",        count=10 },
            { itemId="crushed_stone", count=5 },
        },
        bufferSize=10, smeltsOre=true,
    },

    gear_stamp = {
        id="gear_stamp", name="Gear Stamp", tier=1, powerDraw=0,
        inputs={{ itemId="iron_ingot", rate=2 }},
        outputs={{ itemId="iron_gear", rate=0.5 }},
        buildCost={
            { itemId="iron_ingot", count=10 },
            { itemId="lumber",     count=5 },
        },
        bufferSize=10,
    },

    wire_braider = {
        id="wire_braider", name="Wire Braider", tier=1, powerDraw=0,
        inputs={{ itemId="copper_ingot", rate=1 }},
        outputs={{ itemId="copper_wire", rate=1 }},
        buildCost={
            { itemId="copper_ingot", count=5 },
            { itemId="lumber",       count=5 },
        },
        bufferSize=10,
    },

    clockwork_bench = {
        id="clockwork_bench", name="Clockwork Bench", tier=1, powerDraw=0,
        inputs={
            { itemId="iron_gear",   rate=1 },
            { itemId="copper_wire", rate=1 },
        },
        outputs={{ itemId="clockwork_module", rate=0.5 }},
        buildCost={
            { itemId="iron_gear",   count=15 },
            { itemId="copper_wire", count=10 },
        },
        bufferSize=10,
    },

    miner_mk1 = {
        id="miner_mk1", name="Miner Mk1", tier=1, powerDraw=0,
        inputs={}, outputs={{ itemId="raw_ore", rate=1 }},
        buildCost={
            { itemId="lumber",        count=15 },
            { itemId="crushed_stone", count=5 },
        },
        bufferSize=10, isMiner=true,
    },

    storage_chest = {
        id="storage_chest", name="Storage Chest", tier=1, powerDraw=0,
        inputs={}, outputs={},
        buildCost={{ itemId="lumber", count=10 }},
        bufferSize=200, isStorage=true, storageCapacity=200,
    },

    research_station = {
        id="research_station", name="Research Station", tier=1, powerDraw=0,
        inputs={}, outputs={},
        buildCost={
            { itemId="lumber",        count=20 },
            { itemId="crushed_stone", count=10 },
        },
        bufferSize=10, isResearchStation=true,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 2 — Steam Power Required
    -- ════════════════════════════════════════════════════════════

    smelter = {
        id="smelter", name="Smelter", tier=2, powerDraw=25,
        inputs={
            { itemId="iron_ore",   rate=2 },
            { itemId="copper_ore", rate=2 },
        },
        outputs={
            { itemId="iron_ingot",   rate=1 },
            { itemId="copper_ingot", rate=1 },
        },
        buildCost={
            { itemId="iron_ingot", count=20 },
            { itemId="lumber",     count=10 },
        },
        bufferSize=10, smeltsOre=true,
        specializations={
            {
                id="blast_furnace", name="Blast Furnace",
                description="2× ingot output. Consumes 3× coal. Best for bulk iron/copper lines.",
                outputMultiplier=2, powerMultiplier=1,
            },
            {
                id="precision_forge", name="Precision Forge",
                description="Standard speed. Outputs Quality Ingots required for Tier 5–6 recipes.",
                outputMultiplier=1, powerMultiplier=1,
                alternateOutputItemId="quality_ingot",
            },
        },
    },

    gear_press = {
        id="gear_press", name="Gear Press", tier=2, powerDraw=30,
        inputs={{ itemId="iron_ingot", rate=2 }},
        outputs={{ itemId="iron_gear", rate=1 }},
        buildCost={
            { itemId="iron_ingot",    count=15 },
            { itemId="crushed_stone", count=5 },
        },
        bufferSize=10,
    },

    copper_refinery = {
        id="copper_refinery", name="Copper Refinery", tier=2, powerDraw=20,
        inputs={{ itemId="copper_ore",   rate=2 }},
        outputs={{ itemId="copper_ingot", rate=1 }},
        buildCost={
            { itemId="copper_ingot", count=15 },
            { itemId="iron_ingot",   count=10 },
        },
        bufferSize=10,
    },

    wire_refinery = {
        id="wire_refinery", name="Wire Refinery", tier=2, powerDraw=20,
        inputs={{ itemId="copper_ingot", rate=2 }},
        outputs={{ itemId="copper_wire", rate=1 }},
        buildCost={
            { itemId="copper_ingot", count=10 },
            { itemId="iron_gear",    count=10 },
        },
        bufferSize=10,
    },

    roller_press = {
        id="roller_press", name="Roller Press", tier=2, powerDraw=25,
        inputs={{ itemId="iron_ingot", rate=2 }},
        outputs={{ itemId="iron_plate", rate=1 }},
        buildCost={
            { itemId="iron_ingot", count=15 },
            { itemId="iron_gear",  count=10 },
        },
        bufferSize=10,
    },

    panel_bender = {
        id="panel_bender", name="Panel Bender", tier=2, powerDraw=30,
        inputs={{ itemId="iron_plate",      rate=2 }},
        outputs={{ itemId="reinforced_panel", rate=1 }},
        buildCost={
            { itemId="iron_plate", count=20 },
            { itemId="iron_gear",  count=10 },
        },
        bufferSize=10,
    },

    steam_boiler = {
        id="steam_boiler", name="Steam Boiler", tier=2, powerDraw=0,
        inputs={{ itemId="coal",  rate=1 }},
        outputs={{ itemId="steam", rate=5 }},
        buildCost={
            { itemId="iron_ingot",    count=20 },
            { itemId="crushed_stone", count=10 },
        },
        bufferSize=10,
    },

    steam_engine = {
        id="steam_engine", name="Steam Engine", tier=2, powerDraw=0,
        inputs={{ itemId="steam", rate=5 }},
        outputs={},
        buildCost={
            { itemId="iron_gear",  count=15 },
            { itemId="iron_ingot", count=10 },
        },
        bufferSize=10, isGenerator=true, generatorOutput=50,
    },

    storage_mk2 = {
        id="storage_mk2", name="Storage Mk2", tier=2, powerDraw=10,
        inputs={}, outputs={},
        buildCost={
            { itemId="iron_plate", count=20 },
            { itemId="iron_gear",  count=10 },
        },
        bufferSize=500, isStorage=true, storageCapacity=500,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 3 — Pressurized Steam
    -- ════════════════════════════════════════════════════════════

    forge = {
        id="forge", name="Forge", tier=3, powerDraw=50,
        inputs={
            { itemId="iron_ingot", rate=3 },
            { itemId="coal",       rate=1 },
        },
        outputs={{ itemId="steel_ingot", rate=1 }},
        buildCost={
            { itemId="iron_gear",       count=30 },
            { itemId="clockwork_module", count=15 },
        },
        bufferSize=10,
    },

    glass_kiln = {
        id="glass_kiln", name="Glass Kiln", tier=3, powerDraw=40,
        inputs={{ itemId="crushed_stone", rate=2 }},
        outputs={{ itemId="glass_lens",   rate=1 }},
        buildCost={
            { itemId="iron_plate",       count=20 },
            { itemId="clockwork_module", count=10 },
        },
        bufferSize=10,
    },

    assembler_mk1 = {
        id="assembler_mk1", name="Assembler Mk1", tier=3, powerDraw=60,
        inputs={}, outputs={},  -- recipe set per placed instance
        buildCost={
            { itemId="clockwork_module", count=25 },
            { itemId="iron_gear",        count=15 },
        },
        bufferSize=10,
        specializations={
            {
                id="high_volume", name="High-Volume Assembler",
                description="3× output speed at 2× power draw. Best for bulk mid-tier components.",
                outputMultiplier=3, powerMultiplier=2,
            },
            {
                id="quality", name="Quality Assembler",
                description="Standard speed. Outputs refined assembly variants for Tier 5–6.",
                outputMultiplier=1, powerMultiplier=1,
                alternateOutputItemId="quality_assembly",
            },
        },
    },

    roller_press_mk2 = {
        id="roller_press_mk2", name="Roller Press Mk2", tier=3, powerDraw=55,
        inputs={{ itemId="steel_ingot", rate=2 }},
        outputs={{ itemId="steel_plate", rate=1 }},
        buildCost={
            { itemId="steel_ingot", count=20 },
            { itemId="iron_plate",  count=15 },
        },
        bufferSize=10,
    },

    forge_press = {
        id="forge_press", name="Forge Press", tier=3, powerDraw=65,
        inputs={{ itemId="steel_ingot",    rate=2 }},
        outputs={{ itemId="reinforced_frame", rate=1 }},
        buildCost={
            { itemId="steel_plate",      count=25 },
            { itemId="clockwork_module", count=15 },
        },
        bufferSize=10,
    },

    pressure_engine = {
        id="pressure_engine", name="Pressure Engine", tier=3, powerDraw=0,
        inputs={
            { itemId="steam",         rate=5 },
            { itemId="steam_capsule", rate=1 },
        },
        outputs={},
        buildCost={
            { itemId="steel_plate", count=20 },
            { itemId="iron_gear",   count=15 },
        },
        bufferSize=10, isGenerator=true, generatorOutput=150,
    },

    pressure_accumulator = {
        id="pressure_accumulator", name="Pressure Accumulator", tier=3, powerDraw=0,
        inputs={}, outputs={},
        buildCost={
            { itemId="steel_ingot",  count=20 },
            { itemId="copper_wire",  count=10 },
        },
        bufferSize=0,
        -- Stores 500 PU for burst discharge; handled by PowerService
        isStorage=true, storageCapacity=500,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 4 — Clockwork Power
    -- ════════════════════════════════════════════════════════════

    precision_lathe = {
        id="precision_lathe", name="Precision Lathe", tier=4, powerDraw=80,
        inputs={{ itemId="steel_ingot",   rate=2 }},
        outputs={{ itemId="precision_gear", rate=1 }},
        buildCost={
            { itemId="steel_plate",    count=30 },
            { itemId="conductor_coil", count=20 },
        },
        bufferSize=10,
        specializations={
            {
                id="mass_lathe", name="Mass Lathe",
                description="3 Precision Gears/sec. Raw throughput for bulk late-game production.",
                outputMultiplier=3, powerMultiplier=1.5,
            },
            {
                id="artisan_lathe", name="Artisan Lathe",
                description="0.5/sec. Outputs Master Gears required for Clockwork Automaton.",
                outputMultiplier=0.5, powerMultiplier=1,
                alternateOutputItemId="master_gear",
            },
        },
    },

    coil_winder = {
        id="coil_winder", name="Coil Winder", tier=4, powerDraw=60,
        inputs={{ itemId="copper_wire",   rate=2 }},
        outputs={{ itemId="conductor_coil", rate=1 }},
        buildCost={
            { itemId="copper_wire", count=20 },
            { itemId="iron_plate",  count=15 },
        },
        bufferSize=10,
    },

    optical_refinery = {
        id="optical_refinery", name="Optical Refinery", tier=4, powerDraw=70,
        inputs={
            { itemId="glass_lens",  rate=2 },
            { itemId="copper_wire", rate=1 },
        },
        outputs={{ itemId="optical_assembly", rate=1 }},
        buildCost={
            { itemId="optical_assembly", count=25 },
            { itemId="steel_plate",      count=15 },
        },
        bufferSize=10,
    },

    advanced_assembler = {
        id="advanced_assembler", name="Advanced Assembler", tier=4, powerDraw=100,
        inputs={}, outputs={},  -- recipe set per placed instance; 1.5/sec base
        buildCost={
            { itemId="optical_assembly", count=30 },
            { itemId="reinforced_frame", count=20 },
        },
        bufferSize=10,
    },

    obsidian_cutter = {
        id="obsidian_cutter", name="Obsidian Cutter", tier=4, powerDraw=90,
        inputs={{ itemId="obsidian",      rate=1 }},
        outputs={{ itemId="obsidian_shard", rate=1 }},
        buildCost={
            { itemId="steel_plate",    count=25 },
            { itemId="precision_gear", count=15 },
        },
        bufferSize=10,
    },

    clockwork_dynamo = {
        id="clockwork_dynamo", name="Clockwork Dynamo", tier=4, powerDraw=0,
        inputs={{ itemId="conductor_coil", rate=1 }},
        outputs={},
        buildCost={
            { itemId="conductor_coil", count=25 },
            { itemId="precision_gear", count=20 },
        },
        bufferSize=10, isGenerator=true, generatorOutput=400,
    },

    smart_splitter = {
        id="smart_splitter", name="Smart Splitter", tier=4, powerDraw=15,
        inputs={}, outputs={},  -- 3 filtered output lanes; config per instance
        buildCost={
            { itemId="conductor_coil",   count=10 },
            { itemId="optical_assembly", count=5 },
        },
        bufferSize=10, isLogistics=true,
    },

    drone_dock = {
        id="drone_dock", name="Drone Dock", tier=4, powerDraw=120,
        inputs={}, outputs={},
        buildCost={
            { itemId="precision_gear",   count=25 },
            { itemId="conductor_coil",   count=20 },
            { itemId="optical_assembly", count=10 },
        },
        bufferSize=0, isDroneDock=true,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 5 — Crystal Power
    -- ════════════════════════════════════════════════════════════

    automaton_workshop = {
        id="automaton_workshop", name="Automaton Workshop", tier=5, powerDraw=200,
        inputs={
            { itemId="automaton_core", rate=2 },
            { itemId="steam_chassis",  rate=1 },
        },
        outputs={{ itemId="clockwork_automaton", rate=0.5 }},
        buildCost={
            { itemId="automaton_core", count=40 },
            { itemId="resonance_core", count=20 },
        },
        bufferSize=10,
        specializations={
            {
                id="automaton_foreman", name="Automaton Foreman",
                description="Outputs deploy-able Foreman units. Place near machines for +25% efficiency aura.",
                outputMultiplier=1, powerMultiplier=1,
                alternateOutputItemId="automaton_foreman_unit",
            },
            {
                id="automaton_courier", name="Automaton Courier",
                description="Outputs deploy-able Courier units. Replaces conveyors in a small radius.",
                outputMultiplier=1, powerMultiplier=1,
                alternateOutputItemId="automaton_courier_unit",
            },
        },
    },

    crystal_refinery = {
        id="crystal_refinery", name="Crystal Refinery", tier=5, powerDraw=150,
        inputs={{ itemId="crystal_shard",  rate=2 }},
        outputs={{ itemId="resonance_core", rate=1 }},
        buildCost={
            { itemId="resonance_core", count=30 },
            { itemId="automaton_core", count=20 },
            { itemId="quartz",         count=10 },
        },
        bufferSize=10,
    },

    resonance_forge = {
        id="resonance_forge", name="Resonance Forge", tier=5, powerDraw=180,
        inputs={
            { itemId="steel_ingot",   rate=2 },
            { itemId="resonance_core", rate=1 },
        },
        outputs={{ itemId="conductor_array", rate=1 }},
        buildCost={
            { itemId="resonance_core", count=25 },
            { itemId="automaton_core", count=15 },
        },
        bufferSize=10,
    },

    crystal_resonator = {
        id="crystal_resonator", name="Crystal Resonator", tier=5, powerDraw=0,
        inputs={}, outputs={},
        buildCost={
            { itemId="crystal_shard",  count=50 },
            { itemId="resonance_core", count=30 },
            { itemId="automaton_core", count=20 },
        },
        bufferSize=0, isGenerator=true, generatorOutput=2000,
    },

    automaton_loader = {
        id="automaton_loader", name="Automaton Loader", tier=5, powerDraw=80,
        inputs={}, outputs={},  -- 120 items/min smart-routed
        buildCost={
            { itemId="automaton_core", count=20 },
            { itemId="conductor_coil", count=10 },
        },
        bufferSize=10, isLogistics=true,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 6 — Aether Power
    -- ════════════════════════════════════════════════════════════

    aether_refinery = {
        id="aether_refinery", name="Aether Refinery", tier=6, powerDraw=500,
        inputs={{ itemId="aether_crystal", rate=3 }},
        outputs={{ itemId="pure_aether",   rate=1 }},
        buildCost={
            { itemId="aether_crystal", count=30 },
            { itemId="resonance_core", count=20 },
        },
        bufferSize=10,
    },

    resonance_amplifier = {
        id="resonance_amplifier", name="Resonance Amplifier", tier=6, powerDraw=300,
        inputs={}, outputs={},  -- aura: +50% output to all adjacent machines
        buildCost={
            { itemId="pure_aether",    count=20 },
            { itemId="conductor_array", count=15 },
        },
        bufferSize=0,
    },

    clockwork_ascendant = {
        id="clockwork_ascendant", name="Clockwork Ascendant", tier=6, powerDraw=10000,
        -- powerDraw is sustained for 60 sec during activation; requires 5× Crystal Resonators minimum
        inputs={
            { itemId="clockwork_automaton", rate=0 }, -- 500 consumed on activation trigger
            { itemId="pure_aether",         rate=0 }, -- 200 consumed on activation trigger
            { itemId="resonance_core",      rate=0 }, -- 100 consumed on activation trigger
        },
        outputs={},
        buildCost={
            { itemId="pure_aether",    count=50 },
            { itemId="conductor_array", count=30 },
            { itemId="void_stone",     count=20 },
        },
        bufferSize=0,
    },
}

return Machines
