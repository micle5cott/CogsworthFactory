--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local Debris            = game:GetService("Debris")

local Packages   = ReplicatedStorage:WaitForChild("Packages")
local Knit       = require(Packages:WaitForChild("Knit"))

local GameConfig  = require(ReplicatedStorage.Shared.config.GameConfig)
local VSConfig    = require(ReplicatedStorage.Shared.config.VSConfig)
local JuiceConfig = require(ReplicatedStorage.Shared.config.JuiceConfig)
local Network     = require(ReplicatedStorage.Shared.Network)

local TILE = GameConfig.TILE_SIZE_STUDS

local HUDController = Knit.CreateController({ Name = "HUDController" })

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function playSound(assetId: number, volume: number?)
    if assetId == 0 then return end
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. assetId
    s.Volume  = volume or 0.65
    s.Parent  = SoundService
    s:Play()
    Debris:AddItem(s, 8)
end

-- Animated popup with Back-easing scale-in, hold, then fade.
local function spawnJuicyPopup(worldPos: Vector3, text: string, color: Color3)
    local anchor = Instance.new("Part")
    anchor.Size         = Vector3.new(0.1, 0.1, 0.1)
    anchor.Anchored     = true
    anchor.Transparency = 1
    anchor.CanCollide   = false
    anchor.CFrame       = CFrame.new(worldPos)
    anchor.Parent       = Workspace

    local bb = Instance.new("BillboardGui")
    bb.Size        = UDim2.new(0, 200, 0, 54)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = false
    bb.Parent      = anchor

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text
    lbl.TextColor3             = color
    lbl.TextSize               = 0     -- start invisible; scale-in via tween
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 0.35
    lbl.Parent                 = bb

    -- Scale in with Back easing (overshoot = "bounce" feel)
    TweenService:Create(lbl, TweenInfo.new(
        JuiceConfig.POPUP_SCALE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out
    ), { TextSize = 22 }):Play()

    -- Rise continuously
    local totalSecs = JuiceConfig.POPUP_SCALE_TIME + JuiceConfig.POPUP_HOLD_TIME + JuiceConfig.POPUP_FADE_TIME
    TweenService:Create(anchor, TweenInfo.new(totalSecs, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(worldPos + Vector3.new(0, VSConfig.FLOATING_TEXT_RISE_STUDS, 0))
    }):Play()

    -- Fade out after hold
    local fadeDelay = JuiceConfig.POPUP_SCALE_TIME + JuiceConfig.POPUP_HOLD_TIME
    task.delay(fadeDelay, function()
        if lbl and lbl.Parent then
            TweenService:Create(lbl, TweenInfo.new(JuiceConfig.POPUP_FADE_TIME), {
                TextTransparency = 1
            }):Play()
        end
    end)

    Debris:AddItem(anchor, totalSecs + 0.15)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function HUDController:KnitInit() end

function HUDController:KnitStart()
    -- TreeFelled → "LOG HARVESTED" popup at tree position
    Network.getEvent(Network.Events.TreeFelled).OnClientEvent:Connect(function(
        tileX: number, tileZ: number
    )
        local pos = Vector3.new(tileX * TILE, 2, tileZ * TILE)
        spawnJuicyPopup(pos, "LOG HARVESTED", Color3.fromRGB(180, 120, 60))
        playSound(JuiceConfig.SFX.ITEM_COLLECT, 0.4)
    end)

    -- MachineOutput → "LUMBER ✓" popup above the machine
    Network.getEvent(Network.Events.MachineOutput).OnClientEvent:Connect(function(
        instanceId: string, _itemId: string
    )
        -- Find the machine's Base Part by InstanceId on its parent Model
        local base: BasePart? = nil
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:GetAttribute("InstanceId") == instanceId then
                local found = (obj :: Model):FindFirstChild("Base")
                if found and found:IsA("BasePart") then
                    base = found :: BasePart
                    break
                end
            end
        end
        if base then
            local pos = base.Position + Vector3.new(0, 2, 0)
            spawnJuicyPopup(pos, "LUMBER  ✓", Color3.fromRGB(255, 220, 60))
        end
    end)

    -- ItemDelivered → "→ DELIVERED" popup at destination tile
    Network.getEvent(Network.Events.ItemDelivered).OnClientEvent:Connect(function(
        tileX: number, tileZ: number, _itemId: string
    )
        local pos = Vector3.new(tileX * TILE, 2, tileZ * TILE)
        spawnJuicyPopup(pos, "→  DELIVERED", Color3.fromRGB(100, 200, 255))
    end)
end

return HUDController
