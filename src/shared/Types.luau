--!strict

export type ItemId = string
export type MachineId = string
export type InstanceId = string -- unique per placed machine
export type PlayerId = number
export type BiomeId = string
export type ResearchId = string

export type TilePosition = {
    x: number,
    z: number,
}

export type ItemStack = {
    itemId: ItemId,
    count: number,
}

export type MachineInstance = {
    instanceId: InstanceId,
    machineId: MachineId,
    position: TilePosition,
    rotation: number,            -- 0 | 90 | 180 | 270
    specialization: string?,     -- nil until specialized (permanent after)
    efficiency: number,          -- 0–100
    inputBuffer: {ItemStack},
    outputBuffer: {ItemStack},
    recipe: {inputItemId: ItemId, outputItemId: ItemId}?, -- for assemblers with variable recipes
}

export type ConveyorSegment = {
    segmentId: string,
    tier: number,                -- 1–5
    fromPosition: TilePosition,
    toPosition: TilePosition,
}

export type DroneTask =
    | { kind: "logistic"; fromChestId: string; toChestId: string; itemId: ItemId; count: number }
    | { kind: "construct"; blueprintGhostId: string; machineId: MachineId; position: TilePosition; rotation: number }
    | { kind: "deconstruct"; instanceId: InstanceId; returnChestId: string }

export type CoopRole = "visitor" | "builder" | "co_owner" | "owner"

export type CoopMember = {
    playerId: PlayerId,
    role: CoopRole,
}

export type PlotState = {
    ownerId: PlayerId,
    machines: {MachineInstance},
    conveyors: {ConveyorSegment},
    researchProgress: {[ResearchId]: number},
    completedResearch: {ResearchId},
    unlockedTiers: {number},
    unlockedBiomes: {BiomeId},
    ascensionCount: number,
    ascensionUnlocks: {string},
    trophyCaseItems: {ItemId?},  -- exactly 9 slots; nil = empty
    coopMembers: {CoopMember},
    powerBalance: number,        -- positive = surplus, negative = deficit
}

export type RareNodeRoll = {
    nodeId: string,
    rarity: "uncommon" | "rare" | "legendary",
    outputItemId: ItemId,
    announcement: string,
}

export type InventorySlot = {
    itemId: string,
    count:  number,
}

export type CraftRecipe = {
    inputs:  {[string]: number},
    outputs: {[string]: number},
}

export type NovaMachinaData = {
    iterationsComplete: number,
    deliveries: {[string]: number},
}

return {}
