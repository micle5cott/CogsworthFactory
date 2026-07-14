--!strict
-- Canonical player data schema. Every field that ever touches a DataStore
-- must be declared here. All services read/write via this model.
--
-- To add fields: add to the relevant type + DataModel.default() + applyDefaults().
-- To rename/remove fields: bump SCHEMA_VERSION and add a migration entry.

local DataModel = {}

-- Increment whenever a breaking schema change is made.
DataModel.SCHEMA_VERSION = 1

-- ── Sub-types ─────────────────────────────────────────────────────────────────

export type CurrencyData = {
    coins: number,
    premiumCoins: number,
}

export type InventoryData = {
    [string]: number,  -- itemId → count
}

export type MachineInstanceData = {
    instanceId: string,
    machineId: string,
    position: {x: number, z: number},
    rotation: number,    -- 0 | 90 | 180 | 270
    specialization: string?,
}

export type ConveyorSegmentData = {
    segmentId: string,
    tier: number,
    fromPosition: {x: number, z: number},
    toPosition: {x: number, z: number},
}

export type PlotData = {
    biomeId: string,
    machines: {MachineInstanceData},
    conveyors: {ConveyorSegmentData},
    powerBalance: number,
}

export type ResearchSaveData = {
    completed: {string},
    active: string?,
    progress: {[string]: number},
}

export type UnlocksData = {
    tiers: {number},
    biomes: {string},
    machines: {string},
    specializations: {string},
}

export type RarityStrikeStats = {
    uncommon: number,
    rare: number,
    legendary: number,
}

export type StatisticsData = {
    playtimeSeconds: number,
    totalItemsProduced: number,
    totalResearchCompleted: number,
    totalAscensions: number,
    rarityNodeStrikes: RarityStrikeStats,
}

export type SettingsData = {
    hintsEnabled: boolean,
    musicVolume: number,       -- 0–1
    sfxVolume: number,         -- 0–1
    efficiencyOverlay: boolean,
}

export type AchievementData = {
    [string]: boolean,         -- achievementId → unlocked
}

export type BlueprintData = {
    blueprintId: string,
    name: string,
    machines: {MachineInstanceData},
    conveyors: {ConveyorSegmentData},
}

export type AscensionData = {
    count: number,
    unlocks: {string},
    trophyCase: {string?},     -- exactly TROPHY_CASE_SLOTS slots; nil = empty
}

export type CoopMemberEntry = {
    playerId: number,
    role: string,
}

export type CoopData = {
    members: {CoopMemberEntry},
}

-- ── Root type ─────────────────────────────────────────────────────────────────

export type PlayerData = {
    _version: number,
    currency: CurrencyData,
    inventory: InventoryData,
    plot: PlotData,
    research: ResearchSaveData,
    unlocks: UnlocksData,
    statistics: StatisticsData,
    settings: SettingsData,
    achievements: AchievementData,
    blueprints: {[string]: BlueprintData},
    ascension: AscensionData,
    coop: CoopData,
    storageInventories: {[string]: {[string]: number}},  -- instanceId → itemId → count
}

-- ── Default ───────────────────────────────────────────────────────────────────

function DataModel.default(): PlayerData
    return {
        _version = DataModel.SCHEMA_VERSION,
        currency = { coins = 0, premiumCoins = 0 },
        inventory = {},
        plot = {
            biomeId  = "verdant_hollow",
            machines = {},
            conveyors = {},
            powerBalance = 0,
        },
        research = {
            completed = {},
            active    = nil,
            progress  = {},
        },
        unlocks = {
            tiers   = { 1 },
            biomes  = { "verdant_hollow" },
            machines = {
                "lumber_mill", "stone_crusher", "clay_furnace",
                "gear_stamp",  "wire_braider",  "clockwork_bench",
                "miner_mk1",   "storage_chest", "research_station",
            },
            specializations = {},
        },
        statistics = {
            playtimeSeconds       = 0,
            totalItemsProduced    = 0,
            totalResearchCompleted = 0,
            totalAscensions       = 0,
            rarityNodeStrikes     = { uncommon = 0, rare = 0, legendary = 0 },
        },
        settings = {
            hintsEnabled      = true,
            musicVolume       = 0.8,
            sfxVolume         = 1.0,
            efficiencyOverlay = false,
        },
        achievements = {},
        blueprints   = {},
        ascension = {
            count     = 0,
            unlocks   = {},
            trophyCase = { nil, nil, nil, nil, nil, nil, nil, nil, nil },
        },
        coop = { members = {} },
        storageInventories = {},
    }
end

-- ── Migration ─────────────────────────────────────────────────────────────────

-- Each entry upgrades data from (key-1) → key.
-- Functions receive a raw table and return a raw table.
local migrations: {[number]: (data: {[string]: any}) -> {[string]: any}} = {
    -- v0 → v1: first public schema; no stored v0 data exists, so no-op.
    -- [1] = function(data) return data end,
}

-- Migrate raw data to the current SCHEMA_VERSION.
-- Returns (migratedData, didMigrate).
function DataModel.migrate(raw: {[string]: any}): ({[string]: any}, boolean)
    local from = raw._version or 0
    if from == DataModel.SCHEMA_VERSION then
        return raw, false
    end
    local data = raw
    for v = from + 1, DataModel.SCHEMA_VERSION do
        local fn = migrations[v]
        if fn then
            data = fn(data)
        end
        data._version = v
    end
    return data, true
end

-- Backfill any fields missing from an older (but already migrated) save.
-- Safe to call on every load — only writes nil slots.
function DataModel.applyDefaults(data: {[string]: any}): {[string]: any}
    local defaults = DataModel.default() :: {[string]: any}
    for key, defaultVal in pairs(defaults) do
        if data[key] == nil then
            data[key] = defaultVal
        elseif typeof(defaultVal) == "table" and typeof(data[key]) == "table" then
            local sub = data[key] :: {[string]: any}
            for subKey, subDefault in pairs(defaultVal :: {[string]: any}) do
                if sub[subKey] == nil then
                    sub[subKey] = subDefault
                end
            end
        end
    end
    return data
end

return DataModel
