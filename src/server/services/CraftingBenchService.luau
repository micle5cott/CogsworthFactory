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
local log  = Logger.new("CraftingBenchService")

local CraftingBenchService = Knit.CreateService({ Name = "CraftingBenchService", Client = {} })

type BenchRecord = {
    instanceId: string,
    tileX:      number,
    tileZ:      number,
    rotation:   number,
    ownerId:    number,
    model:      Model?,
}

local _benches:      {[string]: BenchRecord} = {}  -- instanceId → record
local _tileOccupied: {[string]: string}      = {}  -- tileKey → instanceId
local _playerCount:  {[number]: number}      = {}  -- userId → bench count
local _nextId = 0

local function tileKey(x: number, z: number): string
    return x .. "," .. z
end

local function newId(): string
    _nextId += 1
    return "bench_" .. _nextId
end

local function buildBenchModel(tileX: number, tileZ: number, rotation: number): Model
    local wx, wz = tileX * TILE, tileZ * TILE
    local model  = Instance.new("Model")
    model.Name   = "CraftingBench_" .. tileKey(tileX, tileZ)

    local base = Instance.new("Part")
    base.Name      = "Base"
    base.Anchored  = true
    base.Size      = Vector3.new(TILE - 0.2, 1.5, TILE - 0.2)
    base.BrickColor = BrickColor.new("Dark orange")
    base.Material  = Enum.Material.Wood
    base.CFrame    = CFrame.new(wx, 0.75, wz) * CFrame.Angles(0, math.rad(rotation), 0)
    base.Parent    = model

    local top = Instance.new("Part")
    top.Name       = "Top"
    top.Anchored   = true
    top.CanCollide = false
    top.Size       = Vector3.new(TILE - 0.2, 0.2, TILE - 0.2)
    top.BrickColor = BrickColor.new("Nougat")
    top.Material   = Enum.Material.Wood
    top.CFrame     = CFrame.new(wx, 1.6, wz)
    top.Parent     = model

    model.PrimaryPart = base
    model.Parent      = Workspace
    return model
end

-- ── Public API ────────────────────────────────────────────────────────────────

function CraftingBenchService:isTileOccupied(key: string): boolean
    return _tileOccupied[key] ~= nil
end

function CraftingBenchService:getAtTile(key: string): {instanceId: string}?
    local id = _tileOccupied[key]
    if not id then return nil end
    return { instanceId = id }
end

-- ── Client endpoints ──────────────────────────────────────────────────────────

function CraftingBenchService.Client:PlaceBench(
    player: Player,
    tileX: number, tileZ: number, rotation: number
): (boolean, string?)
    local userId = player.UserId
    local count  = _playerCount[userId] or 0
    if count >= VSConfig.CRAFTING_BENCH_MAX_PER_PLOT then
        return false, "max benches placed (" .. VSConfig.CRAFTING_BENCH_MAX_PER_PLOT .. ")"
    end

    local key = tileKey(tileX, tileZ)
    if _tileOccupied[key] then return false, "tile occupied by bench" end

    local MachineService = Knit.GetService("MachineService")
    if MachineService:getAtTile(key) then return false, "tile occupied by machine" end

    -- Deduct bench item from inventory
    local InventoryService = Knit.GetService("InventoryService")
    local ok, err = InventoryService:removeItems(player, { crafting_bench_item = 1 })
    if not ok then return false, err end

    local id    = newId()
    local model = buildBenchModel(tileX, tileZ, rotation)
    model:SetAttribute("InstanceId", id)
    model.PrimaryPart:SetAttribute("InstanceId", id)

    _benches[id]       = { instanceId = id, tileX = tileX, tileZ = tileZ, rotation = rotation, ownerId = userId, model = model }
    _tileOccupied[key] = id
    _playerCount[userId] = count + 1

    Network.getEvent(Network.Events.MachinePlaced):FireAllClients(id, "crafting_bench", tileX, tileZ, rotation)
    log:info("%s placed crafting bench %s at (%d,%d)", player.Name, id, tileX, tileZ)
    return true, nil
end

function CraftingBenchService.Client:RemoveBench(player: Player, instanceId: string): boolean
    local bench = _benches[instanceId]
    if not bench then return false end
    if bench.ownerId ~= player.UserId then return false end

    if bench.model then bench.model:Destroy() end
    local key = tileKey(bench.tileX, bench.tileZ)
    _tileOccupied[key] = nil
    _benches[instanceId] = nil
    _playerCount[player.UserId] = math.max(0, (_playerCount[player.UserId] or 1) - 1)

    local InventoryService = Knit.GetService("InventoryService")
    InventoryService:addItem(player, "crafting_bench_item", 1)

    Network.getEvent(Network.Events.MachineRemoved):FireAllClients(instanceId)
    return true
end

function CraftingBenchService.Client:Craft(player: Player, instanceId: string, recipeId: string): (boolean, string?)
    local bench = _benches[instanceId]
    if not bench then return false, "bench not found" end

    local recipe = VSConfig.BENCH_RECIPES[recipeId]
    if not recipe then return false, "unknown recipe: " .. recipeId end

    -- Proximity check
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return false, "no character" end
    local bx = bench.tileX * TILE
    local bz = bench.tileZ * TILE
    if (hrp.Position - Vector3.new(bx, hrp.Position.Y, bz)).Magnitude > 12 then
        return false, "too far from bench"
    end

    local InventoryService = Knit.GetService("InventoryService")
    local ok, err = InventoryService:removeItems(player, recipe.inputs)
    if not ok then return false, err end

    for itemId, count in pairs(recipe.outputs) do
        InventoryService:addItem(player, itemId, count)
    end
    log:info("%s crafted %s at bench %s", player.Name, recipeId, instanceId)
    return true, nil
end

function CraftingBenchService.Client:GetRecipes(_player: Player): {[string]: {inputs: {[string]: number}, outputs: {[string]: number}}}
    return VSConfig.BENCH_RECIPES
end

function CraftingBenchService:KnitInit() end

function CraftingBenchService:KnitStart()
    log:info("CraftingBenchService started (max %d per plot)", VSConfig.CRAFTING_BENCH_MAX_PER_PLOT)
end

return CraftingBenchService
