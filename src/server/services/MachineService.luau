--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger     = require(ReplicatedStorage.Shared.utils.Logger)
local VSConfig   = require(ReplicatedStorage.Shared.config.VSConfig)
local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)
local Network    = require(ReplicatedStorage.Shared.Network)

local TILE = GameConfig.TILE_SIZE_STUDS
local log  = Logger.new("MachineService")

-- ── Types ─────────────────────────────────────────────────────────────────────

type MachineRecord = {
    instanceId:   string,
    machineId:    string,
    tileX:        number,
    tileZ:        number,
    rotation:     number,
    inputBuffer:  {string},   -- itemId queue
    outputBuffer: {string},   -- itemId queue
    processTimer: number,     -- ticks since last processing cycle started
    model:        Model?,
}

-- ── State ─────────────────────────────────────────────────────────────────────

local MachineService = Knit.CreateService({
    Name = "MachineService",
    Client = {},
})

-- instanceId → MachineRecord
local _machines: {[string]: MachineRecord} = {}
-- tileKey → instanceId
local _tileOccupied: {[string]: string} = {}
-- simple counter for unique IDs
local _nextId = 0

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function tileKey(x: number, z: number): string
    return x .. "," .. z
end

local function newId(): string
    _nextId += 1
    return "m_" .. _nextId
end

-- Returns the output tile based on machine tile + rotation.
local function outputTile(tileX: number, tileZ: number, rotation: number): {x: number, z: number}
    if rotation == 0   then return {x = tileX,     z = tileZ + 1} end
    if rotation == 90  then return {x = tileX + 1, z = tileZ    } end
    if rotation == 180 then return {x = tileX,     z = tileZ - 1} end
    if rotation == 270 then return {x = tileX - 1, z = tileZ    } end
    return {x = tileX, z = tileZ + 1}
end

-- Build a procedural model for each machine type.
local function buildModel(machineId: string, tileX: number, tileZ: number, rotation: number): Model
    local wx = tileX * TILE
    local wz = tileZ * TILE
    local model = Instance.new("Model")
    model.Name = machineId .. "_" .. tileKey(tileX, tileZ)

    local base = Instance.new("Part")
    base.Name     = "Base"
    base.Anchored = true
    base.Size     = Vector3.new(TILE - 0.2, 2, TILE - 0.2)
    base.CFrame   = CFrame.new(wx, 1, wz) * CFrame.Angles(0, math.rad(rotation), 0)

    if machineId == "lumber_mill" then
        base.BrickColor = BrickColor.new("Medium stone grey")
        base.Material   = Enum.Material.SmoothPlastic

        local blade = Instance.new("Part")
        blade.Name      = "Blade"
        blade.Shape     = Enum.PartType.Cylinder
        blade.Size      = Vector3.new(0.4, TILE - 0.5, TILE - 0.5)
        blade.BrickColor = BrickColor.new("Bright yellow")
        blade.Material  = Enum.Material.Metal
        blade.Anchored  = true
        blade.CFrame    = CFrame.new(wx, 3, wz) * CFrame.Angles(0, 0, math.pi / 2)
        blade.Parent    = model

    elseif machineId == "storage_chest" then
        base.BrickColor = BrickColor.new("Nougat")
        base.Material   = Enum.Material.Wood
        base.Size       = Vector3.new(TILE - 0.2, TILE - 0.2, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, (TILE - 0.2) / 2, wz)

    elseif machineId == "seller_station" then
        base.BrickColor = BrickColor.new("Bright yellow")
        base.Material   = Enum.Material.SmoothPlastic

        local arch = Instance.new("Part")
        arch.Name      = "Arch"
        arch.Size      = Vector3.new(TILE - 0.2, 0.5, 0.5)
        arch.BrickColor = BrickColor.new("Bright yellow")
        arch.Anchored  = true
        arch.CFrame    = CFrame.new(wx, 3.5, wz)
        arch.Parent    = model
    end

    base.Parent    = model
    model.PrimaryPart = base
    model.Parent   = Workspace
    return model
end

-- ── Public API (called by ConveyorService and other services) ─────────────────

function MachineService:getAtTile(key: string): {instanceId: string, machineId: string}?
    local id = _tileOccupied[key]
    if not id then return nil end
    local m = _machines[id]
    if not m then return nil end
    return {instanceId = id, machineId = m.machineId}
end

function MachineService:consumeOutput(instanceId: string): string?
    local m = _machines[instanceId]
    if not m or #m.outputBuffer == 0 then return nil end
    return table.remove(m.outputBuffer, 1)
end

function MachineService:receiveInput(instanceId: string, itemId: string): boolean
    local m = _machines[instanceId]
    if not m then return false end
    if #m.inputBuffer >= 10 then return false end  -- buffer full
    table.insert(m.inputBuffer, itemId)
    return true
end

function MachineService:getOutputTile(instanceId: string): {x: number, z: number}?
    local m = _machines[instanceId]
    if not m then return nil end
    return outputTile(m.tileX, m.tileZ, m.rotation)
end

function MachineService:getWorldCFrame(instanceId: string): CFrame?
    local m = _machines[instanceId]
    if not m then return nil end
    return CFrame.new(m.tileX * TILE, 1, m.tileZ * TILE)
end

-- ── Placement ─────────────────────────────────────────────────────────────────

local VALID_MACHINES = {
    lumber_mill    = true,
    storage_chest  = true,
    seller_station = true,
}

function MachineService.Client:PlaceMachine(
    player: Player,
    machineId: string,
    tileX: number,
    tileZ: number,
    rotation: number
): (boolean, string?)
    if not VALID_MACHINES[machineId] then
        return false, "unknown machine: " .. machineId
    end
    local key = tileKey(tileX, tileZ)
    if _tileOccupied[key] then
        return false, "tile occupied"
    end

    -- Check and deduct cost
    local price = VSConfig.MACHINE_SHOP_PRICES[machineId] or 0
    if price > 0 then
        local EconomyService = Knit.GetService("EconomyService")
        local ok, err = EconomyService:deductCoins(player, price)
        if not ok then return false, err end
    end

    local id    = newId()
    local model = buildModel(machineId, tileX, tileZ, rotation)

    local record: MachineRecord = {
        instanceId   = id,
        machineId    = machineId,
        tileX        = tileX,
        tileZ        = tileZ,
        rotation     = rotation,
        inputBuffer  = {},
        outputBuffer = {},
        processTimer = 0,
        model        = model,
    }
    _machines[id]     = record
    _tileOccupied[key] = id

    -- Persist to session
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(player)
    if data then
        table.insert(data.plot.machines, {
            instanceId     = id,
            machineId      = machineId,
            position       = {x = tileX, z = tileZ},
            rotation       = rotation,
            specialization = nil,
        })
        SaveService:updateSession(player, {plot = data.plot})
    end

    Network.getEvent(Network.Events.MachinePlaced):FireAllClients(id, machineId, tileX, tileZ, rotation)
    log:info("Placed %s at (%d,%d) for %s", machineId, tileX, tileZ, player.Name)
    return true, nil
end

function MachineService.Client:RemoveMachine(player: Player, instanceId: string): boolean
    local m = _machines[instanceId]
    if not m then return false end

    -- Refund
    local price = VSConfig.MACHINE_SHOP_PRICES[m.machineId] or 0
    local refund = math.floor(price * VSConfig.MACHINE_REFUND_FRACTION)
    if refund > 0 then
        local EconomyService = Knit.GetService("EconomyService")
        EconomyService:awardCoins(player, refund)
    end

    -- Destroy model
    if m.model then m.model:Destroy() end

    local key = tileKey(m.tileX, m.tileZ)
    _tileOccupied[key] = nil
    _machines[instanceId] = nil

    -- Persist removal
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(player)
    if data then
        for i, saved in ipairs(data.plot.machines) do
            if saved.instanceId == instanceId then
                table.remove(data.plot.machines, i)
                break
            end
        end
        SaveService:updateSession(player, {plot = data.plot})
    end

    Network.getEvent(Network.Events.MachineRemoved):FireAllClients(instanceId)
    log:info("Removed %s (%s) for %s", m.machineId, instanceId, player.Name)
    return true
end

-- Returns all placed machines so the client can rebuild visuals on join.
function MachineService.Client:GetAllMachines(_player: Player): {{instanceId: string, machineId: string, tileX: number, tileZ: number, rotation: number}}
    local result = {}
    for id, m in pairs(_machines) do
        table.insert(result, {
            instanceId = id,
            machineId  = m.machineId,
            tileX      = m.tileX,
            tileZ      = m.tileZ,
            rotation   = m.rotation,
        })
    end
    return result
end

-- ── Simulation tick ───────────────────────────────────────────────────────────

function MachineService:tick()
    local TreeService = Knit.GetService("TreeService")

    for id, m in pairs(_machines) do
        if m.machineId ~= "lumber_mill" then continue end

        m.processTimer += 1

        -- If input buffer is empty, try to harvest a tree nearby
        if #m.inputBuffer == 0 then
            local center = Vector3.new(m.tileX * TILE, 1, m.tileZ * TILE)
            local item = TreeService:harvestNearestTree(center)
            if item then
                table.insert(m.inputBuffer, item)
            end
        end

        -- Process: consume 1 log → 1 lumber after LUMBER_MILL_PROCESS_TICKS
        if m.processTimer >= VSConfig.LUMBER_MILL_PROCESS_TICKS and #m.inputBuffer > 0 then
            m.processTimer = 0
            local itemId = table.remove(m.inputBuffer, 1)
            if itemId == "log" then
                table.insert(m.outputBuffer, "lumber")
                Network.getEvent(Network.Events.MachineOutput):FireAllClients(id, "lumber")
            end
        end
    end
end

-- ── Restore from save ─────────────────────────────────────────────────────────

-- Called by SaveService integration (Task 6) when a player's session is loaded.
-- Rebuilds in-memory state and Workspace models from persisted data.
function MachineService:restorePlot(savedMachines: {{instanceId: string, machineId: string, position: {x: number, z: number}, rotation: number}})
    for _, saved in ipairs(savedMachines) do
        if not VALID_MACHINES[saved.machineId] then continue end
        local key = tileKey(saved.position.x, saved.position.z)
        if _tileOccupied[key] then continue end  -- conflict guard

        local model = buildModel(saved.machineId, saved.position.x, saved.position.z, saved.rotation)
        local record: MachineRecord = {
            instanceId   = saved.instanceId,
            machineId    = saved.machineId,
            tileX        = saved.position.x,
            tileZ        = saved.position.z,
            rotation     = saved.rotation,
            inputBuffer  = {},
            outputBuffer = {},
            processTimer = 0,
            model        = model,
        }
        _machines[saved.instanceId] = record
        _tileOccupied[key]          = saved.instanceId

        Network.getEvent(Network.Events.MachinePlaced):FireAllClients(
            saved.instanceId, saved.machineId, saved.position.x, saved.position.z, saved.rotation
        )
    end
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function MachineService:KnitInit() end

function MachineService:KnitStart()
    -- Simulation tick loop
    task.spawn(function()
        while true do
            task.wait(1 / VSConfig.MACHINE_TICK_HZ)
            self:tick()
        end
    end)
    log:info("MachineService started (tick Hz = %d)", VSConfig.MACHINE_TICK_HZ)
end

return MachineService
