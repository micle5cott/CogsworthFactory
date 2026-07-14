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
local log  = Logger.new("TreeService")

type TreeNode = {
    model:     Model,
    health:    number,
    tileX:     number,
    tileZ:     number,
    isFelled:  boolean,
    regenTask: thread?,
}

local TreeService = Knit.CreateService({ Name = "TreeService", Client = {} })

local _plotTrees: {[string]: {TreeNode}} = {}

local function makeTileKey(x: number, z: number): string
    return x .. "," .. z
end

local function buildTreeModel(tileX: number, tileZ: number): Model
    local wx, wz = tileX * TILE, tileZ * TILE
    local model = Instance.new("Model")
    model.Name = "Tree_" .. makeTileKey(tileX, tileZ)

    local trunk = Instance.new("Part")
    trunk.Name      = "Trunk"
    trunk.Size      = Vector3.new(1.2, 5, 1.2)
    trunk.BrickColor = BrickColor.new("Reddish brown")
    trunk.Material  = Enum.Material.Wood
    trunk.Anchored  = true
    trunk.CFrame    = CFrame.new(wx, 2.5, wz)
    trunk.Parent    = model

    local foliage = Instance.new("Part")
    foliage.Name      = "Foliage"
    foliage.Shape     = Enum.PartType.Ball
    foliage.Size      = Vector3.new(5, 5, 5)
    foliage.BrickColor = BrickColor.new("Bright green")
    foliage.Material  = Enum.Material.Grass
    foliage.Anchored  = true
    foliage.CFrame    = CFrame.new(wx, 7.5, wz)
    foliage.Parent    = model

    model.PrimaryPart = trunk
    model.Parent      = Workspace
    return model
end

function TreeService:spawnForest(plotId: string, originWorld: Vector3)
    if _plotTrees[plotId] then
        self:cleanupPlot(plotId)
    end

    local trees: {TreeNode} = {}
    local originTileX = math.round(originWorld.X / TILE)
    local originTileZ = math.round(originWorld.Z / TILE)
    local radius  = VSConfig.FOREST_ZONE_RADIUS_TILES or 8
    local target  = VSConfig.FOREST_TREES_PER_PLOT
    local spawned = 0

    math.randomseed(os.clock() * 1000)

    for attempt = 1, target * 10 do
        if spawned >= target then break end
        local dx = math.random(-radius, radius)
        local dz = math.random(-radius, radius)
        local tx  = originTileX + dx
        local tz  = originTileZ + dz
        -- Avoid overlapping tiles already used
        local key = makeTileKey(tx, tz)
        local occupied = false
        for _, node in ipairs(trees) do
            if makeTileKey(node.tileX, node.tileZ) == key then
                occupied = true
                break
            end
        end
        if not occupied then
            local node: TreeNode = {
                model    = buildTreeModel(tx, tz),
                health   = VSConfig.TREE_HEALTH,
                tileX    = tx,
                tileZ    = tz,
                isFelled = false,
                regenTask = nil,
            }
            table.insert(trees, node)
            spawned += 1
        end
    end

    _plotTrees[plotId] = trees
    log:info("Spawned %d trees for plot %s", spawned, plotId)
end

-- Called by MachineService each tick.
-- Searches all plots for a harvestable tree within radius of centerWorld.
-- Returns "log" if a tree is found and hit (felled when health reaches 0), else nil.
function TreeService:harvestNearestTree(centerWorld: Vector3): string?
    for _, trees in pairs(_plotTrees) do
        local best: TreeNode? = nil
        local bestDist = math.huge

        for _, node in ipairs(trees) do
            if node.isFelled then continue end
            local wx = node.tileX * TILE
            local wz = node.tileZ * TILE
            local dist = math.sqrt((centerWorld.X - wx)^2 + (centerWorld.Z - wz)^2)
            if dist <= VSConfig.LUMBER_MILL_HARVEST_RADIUS and dist < bestDist then
                best = node
                bestDist = dist
            end
        end

        if best then
            best.health -= 1
            local healthAfter = best.health
            local maxHealth   = VSConfig.TREE_HEALTH

            if healthAfter <= 0 then
                best.isFelled = true
                best.model.Parent = nil

                -- Fire hit first (CRACK sound + chip burst on client), then fell
                Network.getEvent(Network.Events.TreeHit):FireAllClients(
                    best.tileX, best.tileZ, 0, maxHealth
                )
                Network.getEvent(Network.Events.TreeFelled):FireAllClients(best.tileX, best.tileZ)

                best.regenTask = task.spawn(function()
                    task.wait(VSConfig.TREE_REGEN_SECONDS)
                    best.health   = VSConfig.TREE_HEALTH
                    best.isFelled = false
                    best.model.Parent = Workspace
                    Network.getEvent(Network.Events.TreeRegrown):FireAllClients(best.tileX, best.tileZ)
                end)

                return "log"
            end

            -- Non-felling hit
            Network.getEvent(Network.Events.TreeHit):FireAllClients(
                best.tileX, best.tileZ, healthAfter, maxHealth
            )
            return nil
        end
    end
    return nil
end

function TreeService:cleanupPlot(plotId: string)
    local trees = _plotTrees[plotId]
    if not trees then return end
    for _, node in ipairs(trees) do
        if node.regenTask then task.cancel(node.regenTask) end
        if node.model then node.model:Destroy() end
    end
    _plotTrees[plotId] = nil
end

function TreeService:KnitInit() end

function TreeService:KnitStart()
    log:info("TreeService started")
end

return TreeService
