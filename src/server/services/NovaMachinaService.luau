--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger   = require(ReplicatedStorage.Shared.utils.Logger)
local VSConfig = require(ReplicatedStorage.Shared.config.VSConfig)
local Network  = require(ReplicatedStorage.Shared.Network)

local log = Logger.new("NovaMachinaService")

local NovaMachinaService = Knit.CreateService({ Name = "NovaMachinaService", Client = {} })

local _deliveries:          {[string]: number} = {}
local _iterationsComplete = 0
local _machinaModel:   Model?
local _machinaPosition: Vector3?

local GOALS           = VSConfig.ITERATION_I_GOALS
local INTERACT_RADIUS = 16  -- studs

local function buildMachinaModel(position: Vector3): Model
    local model = Instance.new("Model")
    model.Name  = "NovaMachina"

    local base = Instance.new("Part")
    base.Name      = "Base"
    base.Anchored  = true
    base.Size      = Vector3.new(10, 1, 10)
    base.BrickColor = BrickColor.new("Dark stone grey")
    base.Material  = Enum.Material.SmoothPlastic
    base.CFrame    = CFrame.new(position.X, position.Y, position.Z)
    base.Parent    = model

    local pillar = Instance.new("Part")
    pillar.Name      = "Pillar"
    pillar.Anchored  = true
    pillar.Size      = Vector3.new(3, 8, 3)
    pillar.BrickColor = BrickColor.new("Medium stone grey")
    pillar.Material  = Enum.Material.SmoothPlastic
    pillar.CFrame    = CFrame.new(position.X, position.Y + 4.5, position.Z)
    pillar.Parent    = model

    local core = Instance.new("Part")
    core.Name      = "Core"
    core.Anchored  = true
    core.Shape     = Enum.PartType.Ball
    core.Size      = Vector3.new(2, 2, 2)
    core.BrickColor = BrickColor.new("Cyan")
    core.Material  = Enum.Material.Neon
    core.CFrame    = CFrame.new(position.X, position.Y + 9, position.Z)
    core.Parent    = model

    local ring = Instance.new("Part")
    ring.Name       = "Ring"
    ring.Anchored   = true
    ring.Shape      = Enum.PartType.Cylinder
    ring.Size       = Vector3.new(0.5, 7, 7)
    ring.BrickColor = BrickColor.new("Bright yellow")
    ring.Material   = Enum.Material.Metal
    ring.CanCollide = false
    ring.CFrame     = CFrame.new(position.X, position.Y + 5, position.Z) * CFrame.Angles(0, 0, math.pi / 2)
    ring.Parent     = model

    -- Tag all parts for E-key interaction
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc:SetAttribute("NovaMachina", true)
        end
    end

    model.PrimaryPart = base
    model.Parent      = Workspace
    return model
end

-- ── Public API ────────────────────────────────────────────────────────────────

function NovaMachinaService:spawnMachina(position: Vector3)
    if _machinaModel then _machinaModel:Destroy() end
    _machinaModel    = buildMachinaModel(position)
    _machinaPosition = position
    log:info("Nova Machina spawned at %s", tostring(position))
end

function NovaMachinaService:loadProgress(saved: {iterationsComplete: number, deliveries: {[string]: number}})
    _iterationsComplete = saved.iterationsComplete or 0
    _deliveries         = saved.deliveries or {}
end

function NovaMachinaService:getProgressForSave(): {iterationsComplete: number, deliveries: {[string]: number}}
    return { iterationsComplete = _iterationsComplete, deliveries = _deliveries }
end

-- ── Client endpoints ──────────────────────────────────────────────────────────

function NovaMachinaService.Client:GetProgress(_player: Player): {deliveries: {[string]: number}, goals: {[string]: number}}
    return { deliveries = _deliveries, goals = GOALS }
end

function NovaMachinaService.Client:Deliver(player: Player, itemId: string, amount: number): (boolean, string?)
    if amount <= 0 then return false, "invalid amount" end

    local goal = GOALS[itemId]
    if not goal then return false, itemId .. " is not needed for Iteration I" end

    local already    = _deliveries[itemId] or 0
    local stillNeeded = goal - already
    if stillNeeded <= 0 then return false, itemId .. " already fulfilled" end

    -- Proximity check
    if _machinaPosition then
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if hrp and (hrp.Position - _machinaPosition).Magnitude > INTERACT_RADIUS then
            return false, "too far from Nova Machina"
        end
    end

    local toDeliver = math.min(amount, stillNeeded)

    local InventoryService = Knit.GetService("InventoryService")
    local ok, err = InventoryService:removeItems(player, { [itemId] = toDeliver })
    if not ok then return false, err end

    _deliveries[itemId] = already + toDeliver
    Network.getEvent(Network.Events.NovaMachinaUpdated):FireAllClients(_deliveries, GOALS)

    -- Check if all goals met
    local complete = true
    for reqItem, reqAmount in pairs(GOALS) do
        if (_deliveries[reqItem] or 0) < reqAmount then
            complete = false
            break
        end
    end

    if complete then
        _iterationsComplete += 1
        _deliveries = {}
        Network.getEvent(Network.Events.IterationComplete):FireAllClients(_iterationsComplete, player.Name)
        log:info("ITERATION %d COMPLETE — %s", _iterationsComplete, player.Name)
    end

    log:info("%s delivered %d × %s", player.Name, toDeliver, itemId)
    return true, nil
end

function NovaMachinaService:KnitInit() end

function NovaMachinaService:KnitStart()
    log:info("NovaMachinaService started")
end

return NovaMachinaService
