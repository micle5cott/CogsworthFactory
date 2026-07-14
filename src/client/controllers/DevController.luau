--!strict
-- DevController — Studio-only testing panel.
-- Invisible in production (RunService:IsStudio() guard).

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local DevController = Knit.CreateController({ Name = "DevController" })

-- ── UI constants ──────────────────────────────────────────────────────────────

local C_BG     = Color3.fromRGB(16, 16, 20)
local C_BTN    = Color3.fromRGB(42, 42, 54)
local C_RESET  = Color3.fromRGB(175, 50, 40)
local C_FAST   = Color3.fromRGB(50, 175, 85)
local C_TITLE  = Color3.fromRGB(130, 205, 255)
local C_TEXT   = Color3.fromRGB(225, 225, 225)

local BTN_H    = 30
local BTN_GAP  = 6
local PADDING  = 8

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function corner(parent: Instance, px: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px)
    c.Parent       = parent
end

local function makeBtn(parent: Frame, label: string, index: number, col: Color3?): TextButton
    local yPos = PADDING + 26 + (BTN_H + BTN_GAP) * (index - 1)
    local b = Instance.new("TextButton")
    b.Size              = UDim2.new(1, -(PADDING * 2), 0, BTN_H)
    b.Position          = UDim2.new(0, PADDING, 0, yPos)
    b.BackgroundColor3  = col or C_BTN
    b.BorderSizePixel   = 0
    b.Text              = label
    b.TextColor3        = C_TEXT
    b.Font              = Enum.Font.GothamMedium
    b.TextSize          = 13
    b.AutoButtonColor   = true
    b.Parent            = parent
    corner(b, 5)
    return b
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function DevController:KnitInit() end

function DevController:KnitStart()
    if not RunService:IsStudio() then return end

    local dev = Knit.GetService("DevService")

    -- Panel sizing
    local numBtns   = 5
    local panelH    = PADDING + 26 + (BTN_H + BTN_GAP) * numBtns + PADDING - BTN_GAP
    local panelW    = 155

    local gui = Instance.new("ScreenGui")
    gui.Name           = "DevPanel"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = Players.LocalPlayer:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size                   = UDim2.new(0, panelW, 0, panelH)
    panel.Position               = UDim2.new(0, 10, 0.5, -panelH / 2)
    panel.BackgroundColor3       = C_BG
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel        = 0
    panel.Parent                 = gui
    corner(panel, 7)

    local stroke = Instance.new("UIStroke")
    stroke.Color       = Color3.fromRGB(60, 60, 80)
    stroke.Thickness   = 1
    stroke.Transparency = 0.5
    stroke.Parent      = panel

    local title = Instance.new("TextLabel")
    title.Size              = UDim2.new(1, 0, 0, 26)
    title.Position          = UDim2.new(0, 0, 0, PADDING - 2)
    title.BackgroundTransparency = 1
    title.Text              = "DEV  TOOLS"
    title.TextColor3        = C_TITLE
    title.Font              = Enum.Font.GothamBold
    title.TextSize          = 11
    title.Parent            = panel

    -- ── Buttons ───────────────────────────────────────────────────────────────

    local resetBtn = makeBtn(panel, "Reset Plot",   1, C_RESET)
    local coinsBtn = makeBtn(panel, "+500 Coins",   2)
    local fillBtn  = makeBtn(panel, "Fill Mills",   3)
    local speedBtn = makeBtn(panel, "Speed: 1x",    4)
    local stateBtn = makeBtn(panel, "Print State",  5)

    -- Reset Plot: wipes all machines, conveyors, resets coins to 200
    resetBtn.MouseButton1Click:Connect(function()
        dev:ResetPlot()
    end)

    -- +500 Coins
    coinsBtn.MouseButton1Click:Connect(function()
        dev:AddCoins(500)
    end)

    -- Fill Mills: puts 5 logs in each lumber mill input buffer
    fillBtn.MouseButton1Click:Connect(function()
        dev:FillMills(5)
    end)

    -- Speed toggle: 1x normal ↔ 5x fast (machines and conveyors)
    local isFast = false
    speedBtn.MouseButton1Click:Connect(function()
        isFast = not isFast
        local mult = if isFast then 5 else 1
        dev:SetTickMultiplier(mult)
        speedBtn.Text             = "Speed: " .. mult .. "x"
        speedBtn.BackgroundColor3 = if isFast then C_FAST else C_BTN
    end)

    -- Print State: dumps machine/conveyor/coin state to server output
    stateBtn.MouseButton1Click:Connect(function()
        dev:PrintState()
    end)
end

return DevController
