--!strict

export type NodeDef = {
    itemId: string,
    richness: "rich" | "standard" | "sparse",
    count: number,
}

export type GeographicFeature = {
    name: string,
    description: string,
    counter: string?,
}

export type BiomeDef = {
    id: string,
    name: string,
    description: string,
    unlockResearchId: string?,
    nodes: {NodeDef},
    features: {GeographicFeature},
    visualTheme: string,
}

local Biomes: {[string]: BiomeDef} = {

    verdant_hollow = {
        id="verdant_hollow", name="Verdant Hollow", visualTheme="earthen",
        description="Mossy stone walls, warm lantern light, old oaks, a brook cutting through the center.",
        unlockResearchId=nil,
        nodes={
            { itemId="wood",       richness="rich",     count=8 },
            { itemId="stone",      richness="standard", count=5 },
            { itemId="iron_ore",   richness="sparse",   count=3 },
            { itemId="copper_ore", richness="sparse",   count=3 },
            { itemId="coal",       richness="sparse",   count=2 },
        },
        features={
            { name="River",        description="Bisects the plot — blocks conveyor paths.", counter="Conveyor Bridge (5 Iron Plates)" },
            { name="Dense Forest", description="Blocks building until cleared.", counter="Lumber Mill clear mode" },
        },
    },

    highland_reach = {
        id="highland_reach", name="Highland Reach", visualTheme="highland",
        description="Rugged cliffsides, exposed ore veins, mountain fog, rickety mine scaffolding.",
        unlockResearchId="tier2_biome2",
        nodes={
            { itemId="iron_ore",   richness="rich",     count=8 },
            { itemId="copper_ore", richness="rich",     count=8 },
            { itemId="coal",       richness="standard", count=5 },
            { itemId="granite",    richness="standard", count=6 },
        },
        features={
            { name="Elevation Changes",    description="Slope terrain prevents flat conveyor runs.", counter="Conveyor Ramp (5 Iron Plates + 5 Granite each)" },
            { name="Rocky Outcroppings",   description="Forces non-linear conveyor routing.", counter=nil },
            { name="Mine Shaft Deposits",  description="Miner Mk2+ placed here yields 2× output.", counter=nil },
        },
    },

    volcanic_depths = {
        id="volcanic_depths", name="Volcanic Depths", visualTheme="volcanic",
        description="Glowing lava channels, black rock, heat shimmer, distant low rumbling.",
        unlockResearchId="tier3_biome3",
        nodes={
            { itemId="coal",     richness="rich",     count=8 },
            { itemId="obsidian", richness="standard", count=5 },
            { itemId="sulphur",  richness="sparse",   count=3 },
            { itemId="iron_ore", richness="standard", count=4 },
        },
        features={
            { name="Lava Channels",   description="Permanent unbuildable terrain spanning the biome.", counter="Route around" },
            { name="Heat Vents",      description="Special tiles: +15% output to adjacent machines.", counter=nil },
            { name="Unstable Ground", description="Only lightweight machines (Storage, Splitters) can be placed.", counter=nil },
        },
    },

    crystal_caverns = {
        id="crystal_caverns", name="Crystal Caverns", visualTheme="crystal",
        description="Underground expanse, glowing crystal formations, bioluminescent moss, eerie quiet.",
        unlockResearchId="tier4_biome4",
        nodes={
            { itemId="crystal_shard",   richness="standard", count=6 },
            { itemId="resonance_stone", richness="sparse",   count=3 },
            { itemId="quartz",          richness="standard", count=5 },
            { itemId="copper_ore",      richness="rich",     count=6 },
        },
        features={
            { name="Stalactite Fields",  description="Blocks overhead conveyor paths.", counter="Lower routing" },
            { name="Resonance Zones",    description="+20% Research Station speed if placed within range.", counter=nil },
            { name="Crystal Formations", description="Aesthetically prominent, unbuildable.", counter=nil },
        },
    },

    aether_rift = {
        id="aether_rift", name="Aether Rift", visualTheme="aether",
        description="Reality fractures here. Floating islands drift. Glowing rifts tear the terrain.",
        unlockResearchId="tier5_biome5",
        nodes={
            { itemId="aether_crystal", richness="sparse", count=4 },
            { itemId="void_stone",     richness="sparse", count=3 },
        },
        features={
            { name="Floating Islands",  description="Best Aether nodes are island-only.", counter="Aether Bridge (Automaton Core cost)" },
            { name="Rift Zones",        description="Unbuildable areas that shift slowly over time.", counter="Monitor + reroute" },
            { name="Gravity Anomalies", description="Conveyors run at 50% speed in affected areas.", counter="Aether Dampener (crafted from Void Stone)" },
        },
    },
}

return Biomes
