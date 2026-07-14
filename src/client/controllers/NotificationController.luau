--!strict
-- NotificationController — client-side visual effects for:
--   • Tree fall / regrow animations (TweenService)
--   • Item transit part sliding along conveyors (TweenService)
--   • Lumber mill blade spin on MachineOutput (TweenService)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")

local Packages   = ReplicatedStorage:WaitForChild("Packages")
local Knit       = require(Packages:WaitForChild("Knit"))

local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)
local Network    = require(ReplicatedStorage.Shared.Network)

local TILE = GameConfig.TILE_SIZE_STUDS

-- ── Item color map ────────────────────────────────────────────────────────────

local ITEM_COLORS: {[string]: BrickColor} = {
    log    = BrickColor.new("Reddish brown"),
    lumber = BrickColor.new("Bright yellow"),
}

-- ── State ─────────────────────────────────────────────────────────────────────

-- segmentId → transit visual Part currently sliding
local _transitParts: {[string]: Part} = {}

-- ── Controller ────────────────────────────────────────────────────────────────

local NotificationController = Knit.CreateController({ Name = "NotificationController" })

-- Show a server-wide announcement banner (rare node, ascension, tier unlock).
-- priority: "low" | "high" | "legendary" — controls animation and duration.
function NotificationController:ShowAnnouncement(_message: string, _priority: string)
    -- Reserved for future UI integration
end

-- Show a contextual Automaton Companion hint bubble.
-- Auto-dismissed after 8 seconds or on player action.
function NotificationController:ShowHint(_message: string)
    -- Reserved for future UI integration
end

-- Suppress all hints (player toggled off in Settings).
function NotificationController:SetHintsEnabled(_enabled: boolean)
    -- Reserved for future UI integration
end

-- ── Tree helpers ──────────────────────────────────────────────────────────────

local function findTreeModel(tileX: number, tileZ: number): Model?
    local name = "Tree_" .. tileX .. "," .. tileZ
    -- Try direct children first (most common case)
    local child = Workspace:FindFirstChild(name)
    if child and child:IsA("Model") then
        return child :: Model
    end
    -- Fall back to full descendants search
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == name then
            return obj :: Model
        end
    end
    return nil
end

local function animateTreeFall(tileX: number, tileZ: number)
    local model = findTreeModel(tileX, tileZ)
    if not model then return end

    local trunk   = model:FindFirstChild("Trunk")   :: BasePart?
    local foliage = model:FindFirstChild("Foliage") :: BasePart?
    if not trunk or not foliage then return end

    local wx = tileX * TILE
    local wz = tileZ * TILE

    -- Tween trunk ~90 degrees sideways (fall over)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local trunkFall = TweenService:Create(trunk, tweenInfo, {
        CFrame = CFrame.new(wx, 0.6, wz) * CFrame.Angles(math.pi / 2, 0, 0)
    })
    local foliageFall = TweenService:Create(foliage, tweenInfo, {
        CFrame = CFrame.new(wx, 1.5, wz + 3.5)
    })

    trunkFall:Play()
    foliageFall:Play()

    -- Fade out after fall completes (server will set model.Parent = nil shortly after,
    -- but we pre-fade for a smoother client-side experience)
    task.delay(0.55, function()
        if trunk and trunk.Parent then
            local fadeInfo = TweenInfo.new(0.25)
            TweenService:Create(trunk,   fadeInfo, { Transparency = 1 }):Play()
            TweenService:Create(foliage, fadeInfo, { Transparency = 1 }):Play()
        end
    end)
end

local function animateTreeRegrow(tileX: number, tileZ: number)
    -- The server sets model.Parent = Workspace which replicates, so the tree
    -- reappears at its original CFrame. We restore transparency in case the
    -- client faded it out during the fall animation.
    task.delay(0.05, function()
        -- Small delay to let the replication propagate before we search
        local model = findTreeModel(tileX, tileZ)
        if not model then return end

        local trunk   = model:FindFirstChild("Trunk")   :: BasePart?
        local foliage = model:FindFirstChild("Foliage") :: BasePart?
        if not trunk or not foliage then return end

        local wx = tileX * TILE
        local wz = tileZ * TILE

        -- Fade the parts back in and ensure they are upright
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        TweenService:Create(trunk, tweenInfo, {
            CFrame       = CFrame.new(wx, 2.5, wz),
            Transparency = 0,
        }):Play()
        TweenService:Create(foliage, tweenInfo, {
            CFrame       = CFrame.new(wx, 7.5, wz),
            Transparency = 0,
        }):Play()
    end)
end

-- ── Item transit helpers ──────────────────────────────────────────────────────

local function findConveyorPart(segmentId: string): BasePart?
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj:GetAttribute("SegmentId") == segmentId then
            return obj :: BasePart
        end
    end
    return nil
end

local function spawnTransitItem(
    segmentId:     string,
    itemId:        string,
    fromX:         number,
    fromZ:         number,
    toX:           number,
    toZ:           number,
    travelSeconds: number
)
    -- Clean up any existing visual for this segment
    local existing = _transitParts[segmentId]
    if existing then
        existing:Destroy()
        _transitParts[segmentId] = nil
    end

    local part = Instance.new("Part")
    part.Name       = "TransitItem_" .. segmentId
    part.Size       = Vector3.new(0.6, 0.6, 0.6)
    part.BrickColor = ITEM_COLORS[itemId] or BrickColor.new("Medium stone grey")
    part.Anchored   = true
    part.CanCollide = false
    part.CastShadow = false
    part.CFrame     = CFrame.new(fromX * TILE, 0.8, fromZ * TILE)
    part.Parent     = Workspace

    -- Small point light for visibility
    local light = Instance.new("PointLight")
    light.Brightness = 0.8
    light.Range      = 4
    light.Color      = part.Color
    light.Parent     = part

    local tween = TweenService:Create(
        part,
        TweenInfo.new(travelSeconds, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(toX * TILE, 0.8, toZ * TILE) }
    )
    tween:Play()
    _transitParts[segmentId] = part

    task.delay(travelSeconds + 0.1, function()
        -- Only destroy if this is still the active part for the segment
        if _transitParts[segmentId] == part then
            _transitParts[segmentId] = nil
        end
        part:Destroy()
    end)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function NotificationController:KnitInit() end

function NotificationController:KnitStart()
    -- Map of instanceId → Blade BasePart for lumber mills we know about
    local machineBlades: {[string]: BasePart} = {}

    -- ── MachinePlaced: register lumber mill blades ────────────────────────────
    Network.getEvent(Network.Events.MachinePlaced).OnClientEvent:Connect(function(
        instanceId: string,
        machineId:  string,
        tileX:      number,
        tileZ:      number,
        _rotation:  number
    )
        if machineId ~= "lumber_mill" then return end
        -- The server names the model: machineId .. "_" .. tileX .. "," .. tileZ
        local modelName = machineId .. "_" .. tileX .. "," .. tileZ
        -- The model is placed directly in Workspace by the server
        local model = Workspace:FindFirstChild(modelName)
        if model and model:IsA("Model") then
            local blade = (model :: Model):FindFirstChild("Blade")
            if blade and blade:IsA("BasePart") then
                machineBlades[instanceId] = blade :: BasePart
            end
        end
    end)

    -- ── MachineRemoved: clean up blade reference ──────────────────────────────
    Network.getEvent(Network.Events.MachineRemoved).OnClientEvent:Connect(function(
        instanceId: string
    )
        machineBlades[instanceId] = nil
    end)

    -- ── TreeFelled: animate tree falling over ─────────────────────────────────
    Network.getEvent(Network.Events.TreeFelled).OnClientEvent:Connect(function(
        tileX: number,
        tileZ: number
    )
        animateTreeFall(tileX, tileZ)
    end)

    -- ── TreeRegrown: fade tree back in / restore upright ──────────────────────
    Network.getEvent(Network.Events.TreeRegrown).OnClientEvent:Connect(function(
        tileX: number,
        tileZ: number
    )
        animateTreeRegrow(tileX, tileZ)
    end)

    -- ── ItemTransitStarted: spawn a sliding item Part ─────────────────────────
    -- Server fires: (segmentId, itemId, travelSeconds)
    -- We look up tile coords from the conveyor Part's attributes in Workspace.
    Network.getEvent(Network.Events.ItemTransitStarted).OnClientEvent:Connect(function(
        segmentId:     string,
        itemId:        string,
        travelSeconds: number
    )
        local belt = findConveyorPart(segmentId)
        if not belt then return end

        local fromX = belt:GetAttribute("FromX") :: number?
        local fromZ = belt:GetAttribute("FromZ") :: number?
        local toX   = belt:GetAttribute("ToX")   :: number?
        local toZ   = belt:GetAttribute("ToZ")   :: number?
        if not (fromX and fromZ and toX and toZ) then return end

        spawnTransitItem(segmentId, itemId, fromX, fromZ, toX, toZ, travelSeconds)
    end)

    -- ── MachineOutput: spin lumber mill blade 360° over 0.3 s ────────────────
    -- Server fires: (instanceId, itemId) — only lumber_mill produces output in VS
    Network.getEvent(Network.Events.MachineOutput).OnClientEvent:Connect(function(
        instanceId: string,
        _itemId:    string
    )
        local blade = machineBlades[instanceId]
        if not blade or not blade.Parent then return end

        -- Tween 360 degrees around the Z axis (blade lies on its side — CFrame.Angles(0,0,pi/2))
        -- We add a full rotation on top of the current CFrame
        local currentCF = blade.CFrame
        local targetCF  = currentCF * CFrame.Angles(0, 0, math.pi * 2)

        TweenService:Create(
            blade,
            TweenInfo.new(0.3, Enum.EasingStyle.Linear),
            { CFrame = targetCF }
        ):Play()
    end)
end

return NotificationController
