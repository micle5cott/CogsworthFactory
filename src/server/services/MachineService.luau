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

local function getTerrainY(wx: number, wz: number): number
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { Workspace.Terrain }
    local result = Workspace:Raycast(Vector3.new(wx, 500, wz), Vector3.new(0, -1000, 0), params)
    return if result then result.Position.Y else 0
end

type MachineRecord = {
    instanceId:   string,
    machineId:    string,
    tileX:        number,
    tileZ:        number,
    rotation:     number,
    inputBuffer:  {string},
    outputBuffer: {string},
    processTimer: number,
    model:        Model?,
}

local MachineService = Knit.CreateService({ Name = "MachineService", Client = {} })

local _machines:     {[string]: MachineRecord} = {}
local _tileOccupied: {[string]: string}        = {}
local _nextId    = 0
local _tickMult: number = 1.0

local VALID_MACHINES: {[string]: boolean} = {
    lumber_mill   = true,
    smelter       = true,
    storage_chest = true,
}

-- Maps machineId → the inventory item id used to carry/place it
local MACHINE_ITEM: {[string]: string} = {
    lumber_mill   = "lumber_mill_item",
    smelter       = "smelter_item",
    storage_chest = "storage_chest_item",
}

local function tileKey(x: number, z: number): string
    return x .. "," .. z
end

local function newId(): string
    _nextId += 1
    return "m_" .. _nextId
end

local function outputTile(tileX: number, tileZ: number, rotation: number): {x: number, z: number}
    if rotation == 0   then return {x = tileX,     z = tileZ + 1} end
    if rotation == 90  then return {x = tileX + 1, z = tileZ    } end
    if rotation == 180 then return {x = tileX,     z = tileZ - 1} end
    if rotation == 270 then return {x = tileX - 1, z = tileZ    } end
    return {x = tileX, z = tileZ + 1}
end

local function buildModel(machineId: string, tileX: number, tileZ: number, rotation: number): Model
    local wx, wz   = tileX * TILE, tileZ * TILE
    local groundY  = getTerrainY(wx, wz)
    local model    = Instance.new("Model")
    model.Name     = machineId .. "_" .. tileKey(tileX, tileZ)

    local base = Instance.new("Part")
    base.Name     = "Base"
    base.Anchored = true
    base.Size     = Vector3.new(TILE - 0.2, 2, TILE - 0.2)
    base.CFrame   = CFrame.new(wx, groundY + 1, wz) * CFrame.Angles(0, math.rad(rotation), 0)

    if machineId == "lumber_mill" then
        base.BrickColor = BrickColor.new("Medium stone grey")
        base.Material   = Enum.Material.SmoothPlastic
        local blade = Instance.new("Part")
        blade.Name       = "Blade"
        blade.Shape      = Enum.PartType.Cylinder
        blade.Size       = Vector3.new(0.4, TILE - 0.5, TILE - 0.5)
        blade.BrickColor = BrickColor.new("Bright yellow")
        blade.Material   = Enum.Material.Metal
        blade.Anchored   = true
        blade.CFrame     = CFrame.new(wx, groundY + 3, wz) * CFrame.Angles(0, 0, math.pi / 2)
        blade.Parent     = model

    elseif machineId == "smelter" then
        base.BrickColor = BrickColor.new("Bright red")
        base.Material   = Enum.Material.SmoothPlastic
        base.Size       = Vector3.new(TILE - 0.2, 3, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, groundY + 1.5, wz) * CFrame.Angles(0, math.rad(rotation), 0)
        local chimney = Instance.new("Part")
        chimney.Name       = "Chimney"
        chimney.Anchored   = true
        chimney.CanCollide = false
        chimney.Size       = Vector3.new(1, 2, 1)
        chimney.BrickColor = BrickColor.new("Dark stone grey")
        chimney.Material   = Enum.Material.SmoothPlastic
        chimney.CFrame     = CFrame.new(wx, groundY + 4.5, wz)
        chimney.Parent     = model

    elseif machineId == "storage_chest" then
        base.BrickColor = BrickColor.new("Nougat")
        base.Material   = Enum.Material.Wood
        base.Size       = Vector3.new(TILE - 0.2, TILE - 0.2, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, groundY + (TILE - 0.2) / 2, wz)
        local lid = Instance.new("Part")
        lid.Name       = "Lid"
        lid.Size       = Vector3.new(TILE - 0.2, 0.25, TILE - 0.2)
        lid.BrickColor = BrickColor.new("Dark orange")
        lid.Material   = Enum.Material.Wood
        lid.Anchored   = true
        lid.CanCollide = false
        lid.CFrame     = CFrame.new(wx, groundY + (TILE - 0.2) + 0.125, wz)
        lid.Parent     = model
    end

    base.Parent       = model
    model.PrimaryPart = base
    model.Parent      = Workspace
    return model
end

-- ── Public API ────────────────────────────────────────────────────────────────

function MachineService:getAtTile(key: string): {instanceId: string, machineId: string}?
    local id = _tileOccupied[key]
    if not id then return nil end
    local m = _machines[id]
    if not m then return nil end
    return { instanceId = id, machineId = m.machineId }
end

function MachineService:consumeOutput(instanceId: string): string?
    local m = _machines[instanceId]
    if not m or #m.outputBuffer == 0 then return nil end
    return table.remove(m.outputBuffer, 1)
end

function MachineService:receiveInput(instanceId: string, itemId: string): boolean
    local m = _machines[instanceId]
    if not m then return false end
    if #m.inputBuffer >= 10 then return false end
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
    return CFrame.new(m.tileX * TILE, 1, m.tileZ * TILE) * CFrame.Angles(0, math.rad(m.rotation), 0)
end

-- ── Placement ─────────────────────────────────────────────────────────────────

function MachineService.Client:PlaceMachine(
    player: Player,
    machineId: string,
    tileX: number, tileZ: number,
    rotation: number
): (boolean, string?)
    if not VALID_MACHINES[machineId] then
        return false, "unknown machine: " .. machineId
    end
    local key = tileKey(tileX, tileZ)
    if _tileOccupied[key] then return false, "tile occupied" end

    local CraftingBenchService = Knit.GetService("CraftingBenchService")
    if CraftingBenchService:isTileOccupied(key) then return false, "tile occupied by bench" end

    -- Deduct machine item from inventory
    local itemId = MACHINE_ITEM[machineId]
    if itemId then
        local InventoryService = Knit.GetService("InventoryService")
        local ok, err = InventoryService:removeItems(player, { [itemId] = 1 })
        if not ok then return false, err end
    end

    local id    = newId()
    local model = buildModel(machineId, tileX, tileZ, rotation)
    model:SetAttribute("InstanceId", id)
    model.PrimaryPart:SetAttribute("InstanceId", id)

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
    _machines[id]      = record
    _tileOccupied[key] = id

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

    -- Return machine item to inventory
    local itemId = MACHINE_ITEM[m.machineId]
    if itemId then
        local InventoryService = Knit.GetService("InventoryService")
        InventoryService:addItem(player, itemId, 1)
    end

    if m.model then m.model:Destroy() end

    local key = tileKey(m.tileX, m.tileZ)
    _tileOccupied[key] = nil
    _machines[instanceId] = nil

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

function MachineService.Client:GetAllMachines(_player: Player): {{instanceId: string, machineId: string, tileX: number, tileZ: number, rotation: number}}
    local result = {}
    for id, m in pairs(_machines) do
        table.insert(result, { instanceId = id, machineId = m.machineId, tileX = m.tileX, tileZ = m.tileZ, rotation = m.rotation })
    end
    return result
end

-- ── Simulation tick ───────────────────────────────────────────────────────────

function MachineService:tick()
    for id, m in pairs(_machines) do
        m.processTimer += 1

        if m.machineId == "lumber_mill" then
            if m.processTimer >= VSConfig.LUMBER_MILL_PROCESS_TICKS and #m.inputBuffer > 0 then
                m.processTimer = 0
                local itemId = table.remove(m.inputBuffer, 1)
                if itemId == "log" then
                    table.insert(m.outputBuffer, "lumber")
                    Network.getEvent(Network.Events.MachineOutput):FireAllClients(id, "lumber")
                end
            end

        elseif m.machineId == "smelter" then
            if m.processTimer >= VSConfig.SMELTER_PROCESS_TICKS then
                -- Needs one ore AND one lumber (fuel) — both must be in the buffer
                local oreIdx: number?    = nil
                local lumberIdx: number? = nil
                for i, item in ipairs(m.inputBuffer) do
                    if not oreIdx and (item == "iron_ore" or item == "copper_ore") then
                        oreIdx = i
                    elseif not lumberIdx and item == "lumber" then
                        lumberIdx = i
                    end
                end
                if oreIdx and lumberIdx then
                    m.processTimer = 0
                    local ore = m.inputBuffer[oreIdx]
                    -- Remove higher index first so lower index stays valid
                    local hi = math.max(oreIdx, lumberIdx)
                    local lo = math.min(oreIdx, lumberIdx)
                    table.remove(m.inputBuffer, hi)
                    table.remove(m.inputBuffer, lo)
                    local ingot = if ore == "iron_ore" then "iron_ingot" else "copper_ingot"
                    table.insert(m.outputBuffer, ingot)
                    Network.getEvent(Network.Events.MachineOutput):FireAllClients(id, ingot)
                end
            end
        end
    end
end

-- ── Restore from save ─────────────────────────────────────────────────────────

function MachineService:restorePlot(savedMachines: {{instanceId: string, machineId: string, position: {x: number, z: number}, rotation: number}})
    for _, saved in ipairs(savedMachines) do
        if not VALID_MACHINES[saved.machineId] then continue end
        local key = tileKey(saved.position.x, saved.position.z)
        if _tileOccupied[key] then continue end

        local model = buildModel(saved.machineId, saved.position.x, saved.position.z, saved.rotation)
        model:SetAttribute("InstanceId", saved.instanceId)
        model.PrimaryPart:SetAttribute("InstanceId", saved.instanceId)

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

    for _, saved in ipairs(savedMachines) do
        local n = tonumber(string.match(saved.instanceId, "^m_(%d+)$"))
        if n and n > _nextId then _nextId = n end
    end
end

-- ── Dev helpers ───────────────────────────────────────────────────────────────

function MachineService:setTickMultiplier(mult: number)
    _tickMult = math.clamp(mult, 0.25, 20)
end

function MachineService:resetAll()
    for id, m in pairs(_machines) do
        if m.model then m.model:Destroy() end
        Network.getEvent(Network.Events.MachineRemoved):FireAllClients(id)
    end
    _machines     = {}
    _tileOccupied = {}
    _nextId       = 0
end

function MachineService:fillAllMills(count: number)
    for _, m in pairs(_machines) do
        if m.machineId ~= "lumber_mill" then continue end
        for _ = 1, count do
            if #m.inputBuffer >= 10 then break end
            table.insert(m.inputBuffer, "log")
        end
    end
end

function MachineService:debugPrintState()
    warn("── MachineService state ──────────────────")
    for id, m in pairs(_machines) do
        warn(string.format("  [%s] %s @ (%d,%d)  in=%d out=%d",
            id, m.machineId, m.tileX, m.tileZ, #m.inputBuffer, #m.outputBuffer))
    end
    if next(_machines) == nil then warn("  (no machines)") end
end

function MachineService:KnitInit() end

function MachineService:KnitStart()
    task.spawn(function()
        while true do
            task.wait((1 / VSConfig.MACHINE_TICK_HZ) / _tickMult)
            self:tick()
        end
    end)
    log:info("MachineService started (tick Hz = %d)", VSConfig.MACHINE_TICK_HZ)
end

return MachineService
