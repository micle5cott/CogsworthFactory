--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local Debris            = game:GetService("Debris")

local Packages   = ReplicatedStorage:WaitForChild("Packages")
local Knit       = require(Packages:WaitForChild("Knit"))

local JuiceConfig = require(ReplicatedStorage.Shared.config.JuiceConfig)
local Network     = require(ReplicatedStorage.Shared.Network)

local OnboardingController = Knit.CreateController({ Name = "OnboardingController" })

local localPlayer = Players.LocalPlayer

local _stepDone:   {boolean}   = {false, false, false, false, false}
local _stepLabels: {TextLabel} = {}
local _gui: ScreenGui? = nil

-- ── Panel construction ────────────────────────────────────────────────────────

local function buildPanel(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name           = "OnboardingHUD"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.Parent         = localPlayer:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Name                   = "Panel"
    panel.AnchorPoint            = Vector2.new(1, 0)
    panel.Position               = UDim2.new(1, -16, 0, 16)
    panel.Size                   = UDim2.new(0, 268, 0, 176)
    panel.BackgroundColor3       = Color3.fromRGB(12, 12, 18)
    panel.BackgroundTransparency = 0.22
    panel.BorderSizePixel        = 0
    panel.Parent                 = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent       = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color        = Color3.fromRGB(255, 200, 60)
    stroke.Thickness    = 1.5
    stroke.Transparency = 0.6
    stroke.Parent       = panel

    local title = Instance.new("TextLabel")
    title.Size               = UDim2.new(1, -16, 0, 28)
    title.Position           = UDim2.new(0, 8, 0, 5)
    title.BackgroundTransparency = 1
    title.Text               = "OBJECTIVES"
    title.TextColor3         = Color3.fromRGB(255, 200, 60)
    title.TextSize           = 14
    title.Font               = Enum.Font.GothamBold
    title.TextXAlignment     = Enum.TextXAlignment.Left
    title.Parent             = panel

    local divider = Instance.new("Frame")
    divider.Size             = UDim2.new(1, -16, 0, 1)
    divider.Position         = UDim2.new(0, 8, 0, 33)
    divider.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    divider.BorderSizePixel  = 0
    divider.Parent           = panel

    for i, labelText in ipairs(JuiceConfig.STEP_LABELS) do
        local lbl = Instance.new("TextLabel")
        lbl.Size                   = UDim2.new(1, -16, 0, 22)
        lbl.Position               = UDim2.new(0, 8, 0, 35 + (i - 1) * 26)
        lbl.BackgroundTransparency = 1
        lbl.Text                   = "○  " .. labelText
        lbl.TextColor3             = Color3.fromRGB(155, 155, 165)
        lbl.TextSize               = 13
        lbl.Font                   = Enum.Font.Gotham
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = panel
        table.insert(_stepLabels, lbl)
    end

    return gui
end

-- ── Step completion ───────────────────────────────────────────────────────────

local function screenFlash()
    if not _gui then return end
    local flash = Instance.new("Frame")
    flash.Size                   = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    flash.BackgroundTransparency = 0.65
    flash.BorderSizePixel        = 0
    flash.ZIndex                 = 20
    flash.Parent                 = _gui

    TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    }):Play()
    Debris:AddItem(flash, 0.55)
end

local function playCompletionSound()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. JuiceConfig.SFX.STEP_COMPLETE
    s.Volume  = 0.7
    s.Parent  = SoundService
    s:Play()
    Debris:AddItem(s, 5)
end

local function completeStep(stepIndex: number)
    if _stepDone[stepIndex] then return end
    _stepDone[stepIndex] = true

    local lbl = _stepLabels[stepIndex]
    if not lbl then return end

    lbl.Text       = "✓  " .. JuiceConfig.STEP_LABELS[stepIndex]
    lbl.TextColor3 = Color3.fromRGB(80, 220, 80)

    -- Scale-bounce the label
    lbl.TextSize = 17
    TweenService:Create(lbl, TweenInfo.new(
        0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out
    ), { TextSize = 13 }):Play()

    screenFlash()
    playCompletionSound()

    -- Final step: show "FACTORY RUNNING!" banner
    if stepIndex == #JuiceConfig.STEP_LABELS then
        task.delay(0.4, function()
            if not _gui then return end

            local banner = Instance.new("Frame")
            banner.Name                   = "CompletionBanner"
            banner.Size                   = UDim2.new(0, 340, 0, 54)
            banner.AnchorPoint            = Vector2.new(0.5, 0)
            banner.Position               = UDim2.new(0.5, 0, 0, 72)
            banner.BackgroundColor3       = Color3.fromRGB(30, 180, 80)
            banner.BackgroundTransparency = 0.1
            banner.BorderSizePixel        = 0
            banner.ZIndex                 = 15
            banner.Parent                 = _gui

            local bannerCorner = Instance.new("UICorner")
            bannerCorner.CornerRadius = UDim.new(0, 10)
            bannerCorner.Parent       = banner

            local bannerText = Instance.new("TextLabel")
            bannerText.Size                   = UDim2.new(1, -16, 1, 0)
            bannerText.Position               = UDim2.new(0, 8, 0, 0)
            bannerText.BackgroundTransparency = 1
            bannerText.Text                   = "FACTORY RUNNING!  Just one more machine…"
            bannerText.TextColor3             = Color3.fromRGB(255, 255, 255)
            bannerText.TextSize               = 15
            bannerText.Font                   = Enum.Font.GothamBold
            bannerText.TextWrapped            = true
            bannerText.ZIndex                 = 16
            bannerText.Parent                 = banner

            -- Fade out after 3.5 seconds
            task.delay(3.5, function()
                if banner and banner.Parent then
                    TweenService:Create(banner, TweenInfo.new(0.5), {
                        BackgroundTransparency = 1,
                    }):Play()
                    TweenService:Create(bannerText, TweenInfo.new(0.5), {
                        TextTransparency = 1,
                    }):Play()
                    Debris:AddItem(banner, 0.6)
                end
            end)
        end)
    end
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function OnboardingController:KnitInit() end

function OnboardingController:KnitStart()
    _gui = buildPanel()

    -- Step 1: Place a Lumber Mill
    -- Step 4: Build a Storage Chest (after step 3)
    Network.getEvent(Network.Events.MachinePlaced).OnClientEvent:Connect(function(
        _instanceId: string, machineId: string,
        _tileX: number, _tileZ: number, _rot: number
    )
        if machineId == "lumber_mill" and not _stepDone[1] then
            completeStep(1)
        end
        if machineId == "storage_chest" and _stepDone[3] and not _stepDone[4] then
            completeStep(4)
            task.delay(0.35, function() completeStep(5) end)
        end
    end)

    -- Step 2: First Lumber Produced (after step 1)
    Network.getEvent(Network.Events.MachineOutput).OnClientEvent:Connect(function(
        _instanceId: string, _itemId: string
    )
        if _stepDone[1] and not _stepDone[2] then
            completeStep(2)
        end
    end)

    -- Step 3: Connect a Conveyor (after step 2)
    Network.getEvent(Network.Events.ConveyorPlaced).OnClientEvent:Connect(function(
        _segmentId: string,
        _fX: number, _fZ: number, _tX: number, _tZ: number
    )
        if _stepDone[2] and not _stepDone[3] then
            completeStep(3)
        end
    end)
end

return OnboardingController
