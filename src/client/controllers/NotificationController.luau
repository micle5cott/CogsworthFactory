--!strict
-- NotificationController — client-side visual effects for:
--   • Tree fall / regrow animations (TweenService)
--   • Item transit part sliding along conveyors (TweenService)
--   • Lumber mill blade spin on MachineOutput (TweenService)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local SoundService      = game:GetService("SoundService")
local Debris            = game:GetService("Debris")

local Packages   = ReplicatedStorage:WaitForChild("Packages")
local Knit       = require(Packages:WaitForChild("Knit"))

local GameConfig  = require(ReplicatedStorage.Shared.config.GameConfig)
local Network     = require(ReplicatedStorage.Shared.Network)
local JuiceConfig = require(ReplicatedStorage.Shared.config.JuiceConfig)

local TILE = GameConfig.TILE_SIZE_STUDS

-- ── Item color map ────────────────────────────────────────────────────────────

local ITEM_COLORS: {[string]: BrickColor} = {
    log    = BrickColor.new("Reddish brown"),
    lumber = BrickColor.new("Bright yellow"),
}

-- ── Sound helper ──────────────────────────────────────────────────────────────

-- Plays a one-shot sound. `parent` = nil → plays from SoundService (non-positional).
local function playSound(assetId: number, parent: Instance?, volume: number?)
    local s = Instance.new("Sound")
    s.SoundId            = "rbxassetid://" .. assetId
    s.Volume             = volume or 0.65
    s.RollOffMaxDistance = 60
    s.Parent             = parent or SoundService
    s:Play()
    Debris:AddItem(s, 8)
end

-- ── Particle helper ───────────────────────────────────────────────────────────

-- Emits `count` particles from `part` then destroys the emitter after 3 seconds.
local function burstParticles(part: BasePart, color: Color3, count: number, speed: number)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color          = ColorSequence.new(color)
    emitter.LightInfluence = 0.1
    emitter.Lifetime       = NumberRange.new(0.3, 0.8)
    emitter.Rate           = 0
    emitter.RotSpeed       = NumberRange.new(-180, 180)
    emitter.Rotation       = NumberRange.new(0, 360)
    emitter.Size           = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.25),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Speed          = NumberRange.new(speed * 0.6, speed)
    emitter.SpreadAngle    = Vector2.new(60, 60)
    emitter.Parent         = part
    emitter:Emit(count)
    Debris:AddItem(emitter, 3)
end

-- ── Mill progress bar helper ──────────────────────────────────────────────────

-- Creates a BillboardGui progress bar above `base` and returns the fill Frame.
local function createMillProgressBar(base: BasePart): Frame
    local bb = Instance.new("BillboardGui")
    bb.Name        = "ProgressBar"
    bb.Size        = UDim2.new(0, JuiceConfig.PROGRESS_BAR_WIDTH, 0, JuiceConfig.PROGRESS_BAR_HEIGHT)
    bb.StudsOffset = Vector3.new(0, JuiceConfig.PROGRESS_STUDS_OFFSET, 0)
    bb.AlwaysOnTop = false
    bb.Parent      = base

    local bg = Instance.new("Frame")
    bg.Size                   = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3       = JuiceConfig.COLOR_PROGRESS_BG
    bg.BackgroundTransparency = 0.2
    bg.BorderSizePixel        = 0
    bg.Parent                 = bb
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 3)
    bgCorner.Parent       = bg

    local fill = Instance.new("Frame")
    fill.Name             = "Fill"
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = JuiceConfig.COLOR_PROGRESS_FG
    fill.BorderSizePixel  = 0
    fill.Parent           = bg
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent       = fill

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 0, 12)
    lbl.Position               = UDim2.new(0, 0, -1.6, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = "⚙ PROCESSING"
    lbl.TextColor3             = Color3.fromRGB(200, 200, 200)
    lbl.TextSize               = 10
    lbl.Font                   = Enum.Font.GothamBold
    lbl.Parent                 = bb

    return fill
end

-- ── State ─────────────────────────────────────────────────────────────────────

-- segmentId → transit visual Part currently sliding
local _transitParts: {[string]: Part} = {}

-- tileKey → health bar billboard/fill references
local _treeHealthBars: {[string]: {billboard: BillboardGui, fill: Frame}} = {}

-- instanceId → mill progress bar fill Frame + last output timestamp
local _millBars:      {[string]: {fill: Frame, lastOutput: number}} = {}
-- segmentId → belt Texture instance (for scroll animation)
local _beltTextures:  {[string]: Texture}                          = {}
-- instanceId → mill base part + its origin CFrame (for vibration)
local _vibrateMills:  {[string]: {base: BasePart, origin: CFrame}} = {}
-- instanceId / "belt_"..segmentId → looping Sound instance
local _loopingSounds: {[string]: Sound}                            = {}

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

local function treeHealthKey(tileX: number, tileZ: number): string
    return tileX .. "," .. tileZ
end

local function setTreeHealthBar(tileX: number, tileZ: number, health: number, maxHealth: number)
    local model = findTreeModel(tileX, tileZ)
    if not model then return end
    local trunk = model:FindFirstChild("Trunk") :: BasePart?
    if not trunk then return end

    local key = treeHealthKey(tileX, tileZ)

    if not _treeHealthBars[key] then
        local bb = Instance.new("BillboardGui")
        bb.Name        = "HealthBar"
        bb.Size        = UDim2.new(0, JuiceConfig.PROGRESS_BAR_WIDTH, 0, JuiceConfig.PROGRESS_BAR_HEIGHT)
        bb.StudsOffset = Vector3.new(0, 5.5, 0)
        bb.AlwaysOnTop = false
        bb.Parent      = trunk

        local bg = Instance.new("Frame")
        bg.Size              = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3  = JuiceConfig.COLOR_PROGRESS_BG
        bg.BorderSizePixel   = 0
        bg.Parent            = bb
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 3)
        bgCorner.Parent       = bg

        local fill = Instance.new("Frame")
        fill.Name             = "Fill"
        fill.Size             = UDim2.new(1, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        fill.BorderSizePixel  = 0
        fill.Parent           = bg
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent       = fill

        _treeHealthBars[key] = {billboard = bb, fill = fill}
    end

    local entry = _treeHealthBars[key]
    local ratio = math.clamp(health / maxHealth, 0, 1)
    entry.fill.Size = UDim2.new(ratio, 0, 1, 0)
end

local function removeTreeHealthBar(tileX: number, tileZ: number)
    local key = treeHealthKey(tileX, tileZ)
    local entry = _treeHealthBars[key]
    if entry then
        entry.billboard:Destroy()
        _treeHealthBars[key] = nil
    end
end

-- Briefly wobbles the tree trunk ±rotDeg degrees on the Z axis.
local function shakeTree(tileX: number, tileZ: number, rotDeg: number)
    local model = findTreeModel(tileX, tileZ)
    if not model then return end
    local trunk = model:FindFirstChild("Trunk") :: BasePart?
    if not trunk then return end

    local wx    = tileX * TILE
    local wz    = tileZ * TILE
    local base  = CFrame.new(wx, 2.5, wz)
    local quick = TweenInfo.new(0.06, Enum.EasingStyle.Linear)

    TweenService:Create(trunk, quick, { CFrame = base * CFrame.Angles(0, 0, math.rad(rotDeg))  }):Play()
    task.delay(0.07, function()
        if trunk and trunk.Parent then
            TweenService:Create(trunk, quick, { CFrame = base * CFrame.Angles(0, 0, math.rad(-rotDeg)) }):Play()
        end
    end)
    task.delay(0.14, function()
        if trunk and trunk.Parent then
            TweenService:Create(trunk, TweenInfo.new(0.09), { CFrame = base }):Play()
        end
    end)
end

local function animateTreeFall(tileX: number, tileZ: number)
    local model = findTreeModel(tileX, tileZ)
    if not model then return end

    local trunk   = model:FindFirstChild("Trunk")   :: BasePart?
    local foliage = model:FindFirstChild("Foliage") :: BasePart?
    if not trunk or not foliage then return end

    local wx = tileX * TILE
    local wz = tileZ * TILE

    -- Phase 1: brief lean (drama before the fall)
    TweenService:Create(trunk, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(wx, 2.5, wz) * CFrame.Angles(math.rad(10), 0, 0)
    }):Play()

    task.delay(0.1, function()
        if not trunk or not trunk.Parent then return end

        -- Phase 2: fall and crash
        local fallInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(trunk, fallInfo, {
            CFrame = CFrame.new(wx, 0.6, wz) * CFrame.Angles(math.pi / 2, 0, 0)
        }):Play()
        TweenService:Create(foliage, fallInfo, {
            CFrame = CFrame.new(wx, 1.5, wz + 3.5)
        }):Play()

        -- Leaf burst from foliage + chip burst from base of trunk
        burstParticles(foliage, JuiceConfig.COLOR_LEAF, JuiceConfig.LEAVES_ON_FALL, 12)
        burstParticles(trunk,   JuiceConfig.COLOR_WOOD_CHIP, 6, 8)

        -- Deep boom sound timed to when the tree hits the ground
        task.delay(0.45, function()
            if trunk and trunk.Parent then
                playSound(JuiceConfig.SFX.TREE_FALL, trunk, 0.85)
            end
        end)
    end)

    -- Fade out after the fall settles + remove health bar
    task.delay(0.65, function()
        if trunk and trunk.Parent then
            local fadeInfo = TweenInfo.new(0.3)
            TweenService:Create(trunk,   fadeInfo, { Transparency = 1 }):Play()
            TweenService:Create(foliage, fadeInfo, { Transparency = 1 }):Play()
        end
        removeTreeHealthBar(tileX, tileZ)
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

    -- Guard table to prevent double-animation if StorageUpdated fires rapidly
    local _lidAnimating: {[string]: boolean} = {}

    -- ── MachinePlaced: spring scale-in, dust, sound, camera shake ────────────
    Network.getEvent(Network.Events.MachinePlaced).OnClientEvent:Connect(function(
        instanceId: string,
        machineId:  string,
        tileX:      number,
        tileZ:      number,
        _rotation:  number
    )
        local modelName = machineId .. "_" .. tileX .. "," .. tileZ
        local model = Workspace:FindFirstChild(modelName)
        if not model or not model:IsA("Model") then return end

        -- Register blade for lumber mill (existing logic)
        if machineId == "lumber_mill" then
            local blade = (model :: Model):FindFirstChild("Blade")
            if blade and blade:IsA("BasePart") then
                machineBlades[instanceId] = blade :: BasePart
            end
        end

        -- Spring scale-in on the Base Part
        local base = (model :: Model):FindFirstChild("Base") :: BasePart?
        if base then
            local origSize = base.Size
            base.Size = origSize * 0.01

            -- Scale to overshoot
            TweenService:Create(base, TweenInfo.new(
                JuiceConfig.PLACE_SCALE_TIME * 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out
            ), { Size = origSize * JuiceConfig.PLACE_OVERSHOOT }):Play()

            -- Settle to natural size
            task.delay(JuiceConfig.PLACE_SCALE_TIME * 0.65, function()
                if base and base.Parent then
                    TweenService:Create(base, TweenInfo.new(
                        JuiceConfig.PLACE_SCALE_TIME * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In
                    ), { Size = origSize }):Play()
                end
            end)

            -- Dust burst at the base
            burstParticles(base, JuiceConfig.COLOR_DUST, JuiceConfig.DUST_ON_PLACE, 8)

            -- Placement sound
            playSound(JuiceConfig.SFX.MACHINE_PLACE, base, 0.75)

            -- Camera shake
            local cam = Knit.GetController("CameraController")
            cam:Shake(JuiceConfig.SHAKE_MACHINE_PLACE, JuiceConfig.SHAKE_DUR_MACHINE_PLACE)

            -- Lumber mill: progress bar + vibration tracking + looping hum
            if machineId == "lumber_mill" then
                local fill = createMillProgressBar(base)
                _millBars[instanceId] = {fill = fill, lastOutput = tick()}

                _vibrateMills[instanceId] = {base = base, origin = base.CFrame}

                local hum = Instance.new("Sound")
                hum.SoundId            = "rbxassetid://" .. JuiceConfig.SFX.MACHINE_HUM
                hum.Volume             = 0.22
                hum.Looped             = true
                hum.RollOffMaxDistance = 40
                hum.Parent             = base
                hum:Play()
                _loopingSounds[instanceId] = hum
            end
        end
    end)

    -- ── MachineRemoved: clean up blade reference and mill state ──────────────
    Network.getEvent(Network.Events.MachineRemoved).OnClientEvent:Connect(function(
        instanceId: string
    )
        machineBlades[instanceId] = nil
        _millBars[instanceId]     = nil
        _vibrateMills[instanceId] = nil

        local snd = _loopingSounds[instanceId]
        if snd then
            snd:Stop()
            pcall(function() snd:Destroy() end)
        end
        _loopingSounds[instanceId] = nil
    end)

    -- ── TreeHit: shake trunk, wood chips, health bar, impact/crack sound ─────────
    Network.getEvent(Network.Events.TreeHit).OnClientEvent:Connect(function(
        tileX: number, tileZ: number, healthRemaining: number, maxHealth: number
    )
        local isFinal = (healthRemaining <= 0)

        shakeTree(tileX, tileZ, if isFinal then 8 else 5)

        local model = findTreeModel(tileX, tileZ)
        local trunk = if model then model:FindFirstChild("Trunk") else nil
        if trunk and trunk:IsA("BasePart") then
            burstParticles(
                trunk :: BasePart,
                JuiceConfig.COLOR_WOOD_CHIP,
                JuiceConfig.CHIPS_PER_HIT,
                10
            )
            local sfxId = if isFinal then JuiceConfig.SFX.TREE_CRACK else JuiceConfig.SFX.TREE_HIT
            playSound(sfxId, trunk :: BasePart, if isFinal then 0.9 else 0.65)
        end

        if isFinal then
            removeTreeHealthBar(tileX, tileZ)
        else
            setTreeHealthBar(tileX, tileZ, healthRemaining, maxHealth)
        end

        local cam = Knit.GetController("CameraController")
        local amp = if isFinal then JuiceConfig.SHAKE_TREE_FALL * 0.5 else JuiceConfig.SHAKE_TREE_HIT
        cam:Shake(amp, JuiceConfig.SHAKE_DUR_TREE_HIT)
    end)

    -- ── TreeFelled: animate tree falling over ─────────────────────────────────
    Network.getEvent(Network.Events.TreeFelled).OnClientEvent:Connect(function(
        tileX: number, tileZ: number
    )
        animateTreeFall(tileX, tileZ)

        -- Heavy camera shake timed to when the tree hits the ground (~0.55s after fell)
        local cam = Knit.GetController("CameraController")
        task.delay(0.55, function()
            cam:Shake(JuiceConfig.SHAKE_TREE_FALL, JuiceConfig.SHAKE_DUR_TREE_FALL)
        end)
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

    -- ── MachineOutput: spin blade, reset progress bar, sparks, camera bump ───
    -- Server fires: (instanceId, itemId) — only lumber_mill produces output in VS
    Network.getEvent(Network.Events.MachineOutput).OnClientEvent:Connect(function(
        instanceId: string,
        _itemId:    string
    )
        -- Reset progress bar timestamp
        local bar = _millBars[instanceId]
        if bar then
            bar.lastOutput = tick()
        end

        -- Enhanced blade spin (360° over 0.3s)
        local blade = machineBlades[instanceId]
        if blade and blade.Parent then
            local targetCF = blade.CFrame * CFrame.Angles(0, 0, math.pi * 2)
            TweenService:Create(blade, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {
                CFrame = targetCF
            }):Play()

            -- Spark burst from the blade
            burstParticles(blade, JuiceConfig.COLOR_SPARK, JuiceConfig.SPARKS_ON_OUTPUT, 14)
        end

        -- Light camera bump
        local cam = Knit.GetController("CameraController")
        cam:Shake(JuiceConfig.SHAKE_MACHINE_OUTPUT, JuiceConfig.SHAKE_DUR_OUTPUT)
    end)

    -- ── ConveyorPlaced: start belt texture scroll + belt hum ──────────────────
    Network.getEvent(Network.Events.ConveyorPlaced).OnClientEvent:Connect(function(
        segmentId: string,
        _fX: number, _fZ: number, _tX: number, _tZ: number
    )
        task.delay(0.12, function()  -- brief delay for replication to settle
            local belt = findConveyorPart(segmentId)
            if not belt then return end

            local tex = belt:FindFirstChildWhichIsA("Texture")
            if tex then
                _beltTextures[segmentId] = tex :: Texture
            end

            local snd = Instance.new("Sound")
            snd.SoundId            = "rbxassetid://" .. JuiceConfig.SFX.BELT_LOOP
            snd.Volume             = 0.16
            snd.Looped             = true
            snd.RollOffMaxDistance = 30
            snd.Parent             = belt
            snd:Play()
            _loopingSounds["belt_" .. segmentId] = snd
        end)
    end)

    -- ── ConveyorRemoved: stop belt animation + sound ──────────────────────────
    Network.getEvent(Network.Events.ConveyorRemoved).OnClientEvent:Connect(function(
        segmentId: string
    )
        _beltTextures[segmentId] = nil

        local sndKey = "belt_" .. segmentId
        local snd = _loopingSounds[sndKey]
        if snd then
            snd:Stop()
            pcall(function() snd:Destroy() end)
        end
        _loopingSounds[sndKey] = nil
    end)

    -- ── StorageUpdated: lid open/close + particle burst + chest sound ─────────
    Network.getEvent(Network.Events.StorageUpdated).OnClientEvent:Connect(function(
        instanceId: string, _inventory: {[string]: number}
    )
        if _lidAnimating[instanceId] then return end

        -- Find the Lid BasePart by searching for a Model with InstanceId attribute
        local lid: BasePart? = nil
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:GetAttribute("InstanceId") == instanceId then
                local found = (obj :: Model):FindFirstChild("Lid")
                if found and found:IsA("BasePart") then
                    lid = found :: BasePart
                    break
                end
            end
        end
        if not lid then return end

        _lidAnimating[instanceId] = true
        local closedCF = lid.CFrame
        local openCF   = closedCF * CFrame.new(0, 1.5, 0)

        -- Open lid
        TweenService:Create(lid, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = openCF
        }):Play()
        burstParticles(lid, JuiceConfig.COLOR_DUST, 6, 5)
        playSound(JuiceConfig.SFX.STORAGE_FILL, lid, 0.6)

        -- Close lid after a short hold
        task.delay(0.4, function()
            if lid and lid.Parent then
                TweenService:Create(lid, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    CFrame = closedCF
                }):Play()
            end
            task.delay(0.25, function()
                _lidAnimating[instanceId] = nil
            end)
        end)
    end)

    -- ── Per-frame: progress bars, belt scroll, mill vibration ─────────────────
    RunService.RenderStepped:Connect(function(dt: number)
        local now = tick()

        -- Lumber mill progress bars
        for id, entry in pairs(_millBars) do
            if not entry.fill or not entry.fill.Parent then
                _millBars[id] = nil
                continue
            end
            local elapsed  = now - entry.lastOutput
            local fraction = math.clamp(elapsed / JuiceConfig.PROGRESS_CYCLE_SECS, 0, 1)
            entry.fill.Size = UDim2.new(fraction, 0, 1, 0)
        end

        -- Belt texture scroll
        for segId, tex in pairs(_beltTextures) do
            if not tex or not tex.Parent then
                _beltTextures[segId] = nil
                continue
            end
            tex.OffsetStudsV = tex.OffsetStudsV + JuiceConfig.BELT_SCROLL_SPEED * dt
        end

        -- Mill vibration (subtle Y sine wobble)
        for id, entry in pairs(_vibrateMills) do
            if not entry.base or not entry.base.Parent then
                _vibrateMills[id] = nil
                continue
            end
            local wobble = math.sin(now * 15) * 0.018
            entry.base.CFrame = entry.origin * CFrame.new(0, wobble, 0)
        end
    end)
end

return NotificationController
