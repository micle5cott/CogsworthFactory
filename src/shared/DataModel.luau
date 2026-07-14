--!strict
-- Canonical player data schema. Every field that ever touches a DataStore
-- must be declared here. All services read/write via this model.

local DataModel = {}
DataModel.SCHEMA_VERSION = 2

-- ── Sub-types ─────────────────────────────────────────────────────────────────

export type InventorySlot = {
    itemId: string,
    count:  number,
}

export type MachineInstanceData = {
    instanceId:     string,
    machineId:      string,
    position:       {x: number, z: number},
    rotation:       number,
    specialization: string?,
}

export type ConveyorSegmentData = {
    segmentId:    string,
    tier:         number,
    fromPosition: {x: number, z: number},
    toPosition:   {x: number, z: number},
}

export type PlotData = {
    biomeId:      string,
    machines:     {MachineInstanceData},
    conveyors:    {ConveyorSegmentData},
    powerBalance: number,
}

export type NovaMachinaData = {
    iterationsComplete: number,
    deliveries:         {[string]: number},  -- itemId → amount delivered so far
}

export type StatisticsData = {
    playtimeSeconds:        number,
    totalItemsProduced:     number,
    totalResearchCompleted: number,
    totalAscensions:        number,
}

export type SettingsData = {
    hintsEnabled:      boolean,
    musicVolume:       number,
    sfxVolume:         number,
    efficiencyOverlay: boolean,
}

-- ── Root type ─────────────────────────────────────────────────────────────────

export type PlayerData = {
    _version:           number,
    inventory:          {[number]: InventorySlot?},  -- slots 1–25; nil = empty
    plot:               PlotData,
    oreDeposits:        {[string]: number},          -- depositId → remaining yields (-1 = infinite)
    novaMachina:        NovaMachinaData,
    statistics:         StatisticsData,
    settings:           SettingsData,
    achievements:       {[string]: boolean},
    storageInventories: {[string]: {[string]: number}},
}

-- ── Default ───────────────────────────────────────────────────────────────────

function DataModel.default(): PlayerData
    return {
        _version  = DataModel.SCHEMA_VERSION,
        inventory = {},   -- all slots empty; InventoryService seeds chisel on first join
        plot = {
            biomeId      = "verdant_hollow",
            machines     = {},
            conveyors    = {},
            powerBalance = 0,
        },
        oreDeposits = {},
        novaMachina = {
            iterationsComplete = 0,
            deliveries         = {},
        },
        statistics = {
            playtimeSeconds        = 0,
            totalItemsProduced     = 0,
            totalResearchCompleted = 0,
            totalAscensions        = 0,
        },
        settings = {
            hintsEnabled      = true,
            musicVolume       = 0.8,
            sfxVolume         = 1.0,
            efficiencyOverlay = false,
        },
        achievements       = {},
        storageInventories = {},
    }
end

-- ── Migration ─────────────────────────────────────────────────────────────────

local migrations: {[number]: (data: {[string]: any}) -> {[string]: any}} = {
    [2] = function(data)
        -- v1 had currency/unlocks/research/ascension/blueprints/coop — strip them
        data.currency   = nil
        data.unlocks    = nil
        data.research   = nil
        data.ascension  = nil
        data.blueprints = nil
        data.coop       = nil
        -- v1 inventory was {[string]:number}; v2 is {[number]:InventorySlot?}
        if data.inventory and type(data.inventory) == "table" then
            local old = data.inventory :: {[string]: number}
            local newInv: {[number]: {itemId: string, count: number}?} = {}
            local slot = 1
            for itemId, count in pairs(old) do
                if slot > 25 then break end
                if type(itemId) == "string" and type(count) == "number" and count > 0 then
                    newInv[slot] = { itemId = itemId, count = count }
                    slot += 1
                end
            end
            data.inventory = newInv
        end
        if data.oreDeposits == nil then data.oreDeposits = {} end
        if data.novaMachina == nil then
            data.novaMachina = { iterationsComplete = 0, deliveries = {} }
        end
        return data
    end,
}

function DataModel.migrate(raw: {[string]: any}): ({[string]: any}, boolean)
    local from = raw._version or 0
    if from == DataModel.SCHEMA_VERSION then return raw, false end
    local data = raw
    for v = from + 1, DataModel.SCHEMA_VERSION do
        local fn = migrations[v]
        if fn then data = fn(data) end
        data._version = v
    end
    return data, true
end

function DataModel.applyDefaults(data: {[string]: any}): {[string]: any}
    local defaults = DataModel.default() :: {[string]: any}
    for key, defaultVal in pairs(defaults) do
        if data[key] == nil then
            data[key] = defaultVal
        end
    end
    return data
end

return DataModel
