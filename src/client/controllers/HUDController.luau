--!strict
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local TweenService       = game:GetService("TweenService")
local GameConfig         = require(ReplicatedStorage.Shared.config.GameConfig)
local VSConfig           = require(ReplicatedStorage.Shared.config.VSConfig)
local Network            = require(ReplicatedStorage.Shared.Network)
local Packages           = ReplicatedStorage:WaitForChild("Packages")
local Knit               = require(Packages:WaitForChild("Knit"))

local TILE = GameConfig.TILE_SIZE_STUDS
local HUDController = Knit.CreateController({ Name = "HUDController" })

-- Shows a floating "+N coins" BillboardGui above a world position, then fades out.
local function spawnFloatingText(worldPos: Vector3, text: string)
    local part = Instance.new("Part")
    part.Size         = Vector3.new(0.1, 0.1, 0.1)
    part.Anchored     = true
    part.Transparency = 1
    part.CanCollide   = false
    part.CFrame       = CFrame.new(worldPos)
    part.Parent       = Workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Size         = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset  = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop  = false
    billboard.Parent       = part

    local label = Instance.new("TextLabel")
    label.Size              = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text              = text
    label.TextColor3        = Color3.fromRGB(255, 215, 0)
    label.TextSize          = 22
    label.Font              = Enum.Font.GothamBold
    label.TextStrokeColor3  = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.5
    label.Parent            = billboard

    local duration = VSConfig.FLOATING_TEXT_DURATION
    local riseStuds = VSConfig.FLOATING_TEXT_RISE_STUDS

    -- Tween: rise and fade
    local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(worldPos + Vector3.new(0, riseStuds, 0))
    })
    tween:Play()

    local fadeTween = TweenService:Create(label, TweenInfo.new(duration * 0.5, Enum.EasingStyle.Linear), {
        TextTransparency = 1,
    })
    task.delay(duration * 0.5, function() fadeTween:Play() end)

    task.delay(duration + 0.1, function()
        part:Destroy()
    end)
end

function HUDController:KnitInit() end

function HUDController:KnitStart()
    -- Show floating coin text when an item is sold
    Network.getEvent(Network.Events.ItemSold).OnClientEvent:Connect(function(
        tileX: number, tileZ: number, _itemId: string, coinsEarned: number
    )
        local worldPos = Vector3.new(tileX * TILE, 2, tileZ * TILE)
        spawnFloatingText(worldPos, "+" .. coinsEarned .. " coins")
    end)

    -- Show floating "+item" text when item delivered to storage
    Network.getEvent(Network.Events.ItemDelivered).OnClientEvent:Connect(function(
        tileX: number, tileZ: number, itemId: string
    )
        -- Brief flash showing what was delivered
        local worldPos = Vector3.new(tileX * TILE, 2, tileZ * TILE)
        spawnFloatingText(worldPos, "+" .. itemId)
    end)
end

return HUDController
