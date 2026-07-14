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

local function newId(): string
    _nextId += 1
    return "dep_" .. _nextId
end

local function buildDepositModel(depositType: string, tileX: number, tileZ: number): Model
    local wx, wz = tileX * TILE, tileZ * TILE
    local model  = Instance.new("Model")
    model.Name   = "Deposit_" .. depositType .. "_" .. tileX .. "_" .. tileZ

    local rock = Instance.new("Part")
    rock.Name      = "Rock"
    rock.Anchored  = true
    rock.Size      = Vector3.new(3, 2.5, 3)
    rock.BrickColor = DEPOSIT_COLORS[depositType] or BrickColor.new("Medium stone grey")
    rock.Material  = Enum.Material.SmoothPlastic
    rock.CFrame    = CFrame.new(wx, 1.25, wz)
    rock.Parent    = model

    local indicator = Instance.new("Part")
    indicator.Name       = "Indicator"
    indicator.Anchored   = true
    indicator.CanCollide = false
    indicator.Size       = Vector3.new(1, 0.5, 1)
    indicator.BrickColor = DEPOSIT_COLORS[depositType] or BrickColor.new("Bright blue")
    indicator.Material   = Enum.Material.Neon
    indicator.CFrame     = CFrame.new(wx, 2.75, wz)
    indicator.Parent     = model

    model.PrimaryPart = rock
    model.Parent      = Workspace
    return model
end

-- ── Public API ────────────────────────────────────────────────────────────────

function DepositService:spawnDeposits(plotId: string, originWorld: Vector3)
    local originTileX = math.round(originWorld.X / TILE)
    local originTileZ = math.round(originWorld.Z / TILE)
    local used: {[string]: boolean} = {}

    -- Seed from plotId length so different players get slightly varied layouts
    math.randomseed(os.clock() * 10000 + #plotId)

    for depositType, cfg in pairs(VSConfig.DEPOSIT_CONFIG) do
        local radius  = cfg.radius :: number
        local count   = cfg.count  :: number
        local spawned = 0
        for _ = 1, count * 15 do
            if spawned >= count then break end
            local dx  = math.random(-radius, radius)
            local dz  = math.random(-radius, radius)
            local tx  = originTileX + dx
            local tz  = originTileZ + dz
            local key = tx .. "," .. tz
            if used[key] then continue end
            used[key] = true

            local id        = newId()
            local infinite  = cfg.infinite :: boolean
            local remaining = if infinite then -1 else (cfg.totalYield :: number)
            local model     = buildDepositModel(depositType, tx, tz)
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
            spawned += 1
        end
    end
    log:info("Spawned deposits for plot %s", plotId)
end

function DepositService:getDeposit(depositId: string): DepositRecord?
    return _deposits[depositId]
end

function DepositService:applySavedState(savedOreDeposits: {[string]: number})
    for id, remaining in pairs(savedOreDeposits) do
        local dep = _deposits[id]
        if dep then
            if remaining <= 0 and not dep.infinite then
                if dep.model then dep.model:Destroy() end
                dep.model     = nil
                dep.remaining = 0
            else
                dep.remaining = remaining
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

    -- Proximity check
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return nil, nil end
    local wx   = dep.tileX * TILE
    local wz   = dep.tileZ * TILE
    local dist = (hrp.Position - Vector3.new(wx, hrp.Position.Y, wz)).Magnitude
    if dist > 12 then return nil, nil end

    -- Chisel check
    local InventoryService = Knit.GetService("InventoryService")
    if not InventoryService:hasItems(player, { chisel = 1 }) then return nil, nil end

    -- Yield
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
