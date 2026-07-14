--!strict

local Constants = require(script.Parent.Parent.Constants)

export type RareNodeDef = {
    id: string,
    name: string,
    biomeId: string,
    sourceNodeItemId: string,
    rarity: "uncommon" | "rare" | "legendary",
    spawnChance: number,
    outputItemId: string,
    serverAnnouncement: string,
    gameplayNote: string,
}

local RareNodes: {[string]: RareNodeDef} = {

    starfire_iron = {
        id="starfire_iron", name="Starfire Iron",
        biomeId="verdant_hollow", sourceNodeItemId="iron_ore",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="starfire_ingot",
        serverAnnouncement="{player} has struck Starfire Iron in the Verdant Hollow!",
        gameplayNote="Used in the Masterwork Smelter recipe. Displayable in Trophy Case.",
    },

    mooncopper = {
        id="mooncopper", name="Mooncopper",
        biomeId="verdant_hollow", sourceNodeItemId="copper_ore",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="mooncopper_ingot",
        serverAnnouncement="{player} has struck Mooncopper in the Verdant Hollow!",
        gameplayNote="Used in the Masterwork Wire Refinery recipe. Displayable in Trophy Case.",
    },

    gilded_vein = {
        id="gilded_vein", name="Gilded Vein",
        biomeId="highland_reach", sourceNodeItemId="iron_ore",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="gilded_alloy",
        serverAnnouncement="{player} has struck a Gilded Vein in the Highland Reach!",
        gameplayNote="Used in the Masterwork Gear Press recipe. Displayable in Trophy Case.",
    },

    embercoal = {
        id="embercoal", name="Embercoal",
        biomeId="highland_reach", sourceNodeItemId="coal",
        rarity="uncommon", spawnChance=Constants.RARE_NODE_CHANCE.uncommon,
        outputItemId="embercoal",
        serverAnnouncement="{player} found Embercoal in the Highland Reach.",
        gameplayNote="Feed to any Forge for +50% output for 60 seconds.",
    },

    obsidian_heart = {
        id="obsidian_heart", name="Obsidian Heart",
        biomeId="volcanic_depths", sourceNodeItemId="obsidian",
        rarity="legendary", spawnChance=Constants.RARE_NODE_CHANCE.legendary,
        outputItemId="heart_of_obsidian",
        serverAnnouncement="{player} has uncovered the Heart of Obsidian in the Volcanic Depths!",
        gameplayNote="Trophy display only. Pure prestige — no recipe.",
    },

    sulphur_crown = {
        id="sulphur_crown", name="Sulphur Crown",
        biomeId="volcanic_depths", sourceNodeItemId="sulphur",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="pure_sulphur",
        serverAnnouncement="{player} has found a Sulphur Crown in the Volcanic Depths!",
        gameplayNote="Used in the Masterwork Conductor Coil recipe.",
    },

    prismatic_crystal = {
        id="prismatic_crystal", name="Prismatic Crystal",
        biomeId="crystal_caverns", sourceNodeItemId="crystal_shard",
        rarity="legendary", spawnChance=Constants.RARE_NODE_CHANCE.legendary,
        outputItemId="prismatic_shard",
        serverAnnouncement="{player} has found a Prismatic Crystal in the Crystal Caverns!",
        gameplayNote="Unlocks cosmetic Crystal Resonator skin. Displayable in Trophy Case.",
    },

    resonance_geode = {
        id="resonance_geode", name="Resonance Geode",
        biomeId="crystal_caverns", sourceNodeItemId="resonance_stone",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="resonance_gem",
        serverAnnouncement="{player} has unearthed a Resonance Geode in the Crystal Caverns!",
        gameplayNote="Counts as 5 Resonance Cores in any Tier 5 recipe.",
    },

    void_shard = {
        id="void_shard", name="Void Shard",
        biomeId="aether_rift", sourceNodeItemId="void_stone",
        rarity="legendary", spawnChance=Constants.RARE_NODE_CHANCE.legendary,
        outputItemId="void_fragment",
        serverAnnouncement="{player} has torn a Void Shard from the Aether Rift!",
        gameplayNote="Required for the secret Void Ascendant Blueprint. Trophy display.",
    },

    aether_bloom = {
        id="aether_bloom", name="Aether Bloom",
        biomeId="aether_rift", sourceNodeItemId="aether_crystal",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="pure_aether_bloom",
        serverAnnouncement="{player} has found an Aether Bloom in the Aether Rift!",
        gameplayNote="Counts as 10 Pure Aether in the Ascension activation cost.",
    },
}

return RareNodes
