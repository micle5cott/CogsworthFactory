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
local log  = Logger.new("DepositService")

local DepositService = Knit.CreateService({ Name = "DepositService", Client = {} })

type DepositRecord = {
    depositId:   string,
    depositType: string,
    yieldItem:   string,
    infinite:    boolean,
    remaining:   number,   -- -1 if infinite
    tileX:       number,
    tileZ:       number,
    model:       Model?,
}

local _deposits: {[string]: DepositRecord} = {}
local _nextId = 0

local DEPOSIT_COLORS: {[string]: BrickColor} = {
    stone      = BrickColor.new("Medium stone grey"),
    iron_ore   = BrickColor.new("Bright red"),
    copper_ore = BrickColor.new("Bright orange"),
    gold_ore   = BrickColor.new("Bright yellow"),
}

-- Per-type cluster distances (in tiles) and cluster radius
local SPAWN_ZONE: {[string]: {minDist: number, maxDist: number, clusterR: number}} = {
    stone      = { minDist = 5,  maxDist = 18, clusterR = 3 },
    iron_ore   = { minDist = 12, maxDist = 25, clusterR = 2 },
    copper_ore = { minDist = 20, maxDist = 38, clusterR = 2 },
    gold_ore   = { minDist = 35, maxDist = 52, clusterR = 2 },
}

local function newId(): string
    _nextId += 1
    return "dep_" .. _nextId
end

-- Cast a ray downward to find the terrain surface Y at a given XZ world position.
local function getTerrainY(wx: number, wz: number): number
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { Workspace.Terrain }
    local result = Workspace:Raycast(Vector3.new(wx, 500, wz), Vector3.new(0, -1000, 0), params)
    return if result then result.Position.Y else 0
end

local function buildDepositModel(depositType: string, tileX: number, tileZ: number): Model
    local wx, wz  = tileX * TILE, tileZ * TILE
    local groundY = getTerrainY(wx, wz)
    local model   = Instance.new("Model")
    model.Name    = "Deposit_" .. depositType .. "_" .. tileX .. "_" .. tileZ

    local rock = Instance.new("Part")
    rock.Name       = "Rock"
    rock.Anchored   = true
    rock.Size       = Vector3.new(3, 2.5, 3)
    rock.BrickColor = DEPOSIT_COLORS[depositType] or BrickColor.new("Medium stone grey")
    rock.Material   = Enum.Material.SmoothPlastic
    rock.CFrame     = CFrame.new(wx, groundY + 1.25, wz)
    rock.Parent     = model

    local indicator = Instance.new("Part")
    indicator.Name       = "Indicator"
    indicator.Anchored   = true
    indicator.CanCollide = false
    indicator.Size       = Vector3.new(1, 0.5, 1)
    indicator.BrickColor = DEPOSIT_COLORS[depositType] or BrickColor.new("Bright blue")
    indicator.Material   = Enum.Material.Neon
    indicator.CFrame     = CFrame.new(wx, groundY + 2.75, wz)
    indicator.Parent     = model

    model.PrimaryPart = rock
    model.Parent      = Workspace
    return model
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Satisfactory/Factorio-style cluster spawning:
-- Each ore type gets distinct distance zones from the spawn origin.
-- Deposits of the same type are placed in tight clusters so they look like
-- visible ore patches on the terrain rather than random scatter.
function DepositService:spawnDeposits(plotId: string, originWorld: Vector3)
    local originTileX = math.round(originWorld.X / TILE)
    local originTileZ = math.round(originWorld.Z / TILE)
    local used: {[string]: boolean} = {}

    math.randomseed(os.clock() * 10000 + #plotId)

    -- Each type gets a random base angle so clusters fan out in all directions
    local baseAngles: {[string]: number} = {
        stone      = math.random() * math.pi * 2,
        iron_ore   = math.random() * math.pi * 2,
        copper_ore = math.random() * math.pi * 2,
        gold_ore   = math.random() * math.pi * 2,
    }

    local TYPE_ORDER = { "stone", "iron_ore", "copper_ore", "gold_ore" }

    for _, depositType in ipairs(TYPE_ORDER) do
        local cfg = VSConfig.DEPOSIT_CONFIG[depositType]
        if not cfg then continue end

        local zone       = SPAWN_ZONE[depositType]
        local count      = cfg.count :: number
        local infinite   = cfg.infinite :: boolean
        local totalYield = (cfg.totalYield or 0) :: number
        -- Each deposit gets the full per-deposit yield from config
        local remaining: number = if infinite then -1 else totalYield

        -- Divide deposits across 1-2 clusters per type
        local numClusters   = if count <= 1 then 1 else math.ceil(count / 2)
        local perCluster    = math.ceil(count / numClusters)
        local baseAngle     = baseAngles[depositType]

        for c = 1, numClusters do
            -- Space clusters evenly around baseAngle with slight randomness
            local angle = baseAngle
                + (c - 1) * (math.pi * 2 / numClusters)
                + (math.random() - 0.5) * 1.0
            local dist  = math.random(zone.minDist, zone.maxDist)
            local cCX   = originTileX + math.round(math.cos(angle) * dist)
            local cCZ   = originTileZ + math.round(math.sin(angle) * dist)

            local placed = 0
            for _ = 1, perCluster * 10 do
                if placed >= perCluster then break end
                local dx    = math.random(-zone.clusterR, zone.clusterR)
                local dz    = math.random(-zone.clusterR, zone.clusterR)
                local tx    = cCX + dx
                local tz    = cCZ + dz
                local tileKey = tx .. "," .. tz
                if used[tileKey] then continue end
                used[tileKey] = true

                local id    = newId()
                local model = buildDepositModel(depositType, tx, tz)
                model:SetAttribute("DepositId", id)
                model.PrimaryPart:SetAttribute("DepositId", id)

                _deposits[id] = {
                    depositId   = id,
                    depositType = depositType,
                    yieldItem   = cfg.yieldItem :: string,
                    infinite    = infinite,
                    remaining   = remaining,
                    tileX       = tx,
                    tileZ       = tz,
                    model       = model,
                }
                placed += 1
            end
        end
    end
    log:info("Spawned deposits for plot %s at origin %s", plotId, tostring(originWorld))
end

function DepositService:getDeposit(depositId: string): DepositRecord?
    return _deposits[depositId]
end

function DepositService:applySavedState(savedOreDeposits: {[string]: number})
    for id, rem in pairs(savedOreDeposits) do
        local dep = _deposits[id]
        if dep then
            if rem <= 0 and not dep.infinite then
                if dep.model then dep.model:Destroy() end
                dep.model     = nil
                dep.remaining = 0
            else
                dep.remaining = rem
            end
        end
    end
end

function DepositService:getSaveState(): {[string]: number}
    local out: {[string]: number} = {}
    for id, dep in pairs(_deposits) do
        if not dep.infinite then
            out[id] = dep.remaining
        end
    end
    return out
end

-- ── Client endpoints ──────────────────────────────────────────────────────────

function DepositService.Client:HitDeposit(player: Player, depositId: string): (string?, number?)
    local dep = _deposits[depositId]
    if not dep then return nil, nil end
    if dep.remaining == 0 then return nil, nil end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return nil, nil end
    local wx   = dep.tileX * TILE
    local wz   = dep.tileZ * TILE
    local dist = (hrp.Position - Vector3.new(wx, hrp.Position.Y, wz)).Magnitude
    if dist > 12 then return nil, nil end

    local InventoryService = Knit.GetService("InventoryService")
    if not InventoryService:hasItems(player, { chisel = 1 }) then return nil, nil end

    local yielded = dep.yieldItem
    if not dep.infinite then
        dep.remaining = math.max(0, dep.remaining - 1)
    end

    local WorldDropService = Knit.GetService("WorldDropService")
    local dropPos = hrp.Position + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
    WorldDropService:dropItem(yielded, 1, dropPos)

    if dep.remaining == 0 and not dep.infinite then
        if dep.model then dep.model:Destroy() end
        dep.model = nil
        Network.getEvent(Network.Events.DepositDepleted):FireAllClients(depositId)
        log:info("Deposit %s (%s) depleted", depositId, dep.depositType)
    else
        local displayRemaining = if dep.infinite then -1 else dep.remaining
        Network.getEvent(Network.Events.DepositHit):FireAllClients(depositId, displayRemaining)
    end

    return yielded, dep.remaining
end

function DepositService:KnitInit() end

function DepositService:KnitStart()
    log:info("DepositService started")
end

return DepositService
