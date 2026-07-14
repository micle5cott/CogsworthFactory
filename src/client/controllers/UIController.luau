--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local VSConfig = require(ReplicatedStorage.Shared.config.VSConfig)

local UIController = Knit.CreateController({ Name = "UIController" })

local localPlayer = Players.LocalPlayer
local _gui: ScreenGui? = nil
local _coinLabel: TextLabel? = nil

local SHOP_ITEMS = {
    { id = "lumber_mill",    label = "Lumber Mill",  price = VSConfig.MACHINE_SHOP_PRICES.lumber_mill    },
    { id = "storage_chest",  label = "Storage",      price = VSConfig.MACHINE_SHOP_PRICES.storage_chest  },
    { id = "seller_station", label = "Seller",       price = VSConfig.MACHINE_SHOP_PRICES.seller_station },
    { id = "_conveyor",      label = "Conveyor",     price = VSConfig.MACHINE_SHOP_PRICES.conveyor_belt  },
}

local function makeButton(parent: GuiObject, text: string, position: UDim2, size: UDim2): TextButton
    local btn = Instance.new("TextButton")
    btn.Size              = size
    btn.Position          = position
    btn.BackgroundColor3  = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel   = 0
    btn.Text              = text
    btn.TextColor3        = Color3.fromRGB(240, 240, 240)
    btn.TextSize          = 14
    btn.Font              = Enum.Font.GothamBold
    btn.AutoButtonColor   = true
    btn.Parent            = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent       = btn
    return btn
end

local function buildUI()
    local gui = Instance.new("ScreenGui")
    gui.Name            = "CogsworthHUD"
    gui.ResetOnSpawn    = false
    gui.IgnoreGuiInset  = true
    gui.Parent          = localPlayer:WaitForChild("PlayerGui")
    _gui = gui

    -- ── Coin display (top left) ────────────────────────────────────────────────
    local coinFrame = Instance.new("Frame")
    coinFrame.Name            = "CoinFrame"
    coinFrame.Size            = UDim2.new(0, 180, 0, 44)
    coinFrame.Position        = UDim2.new(0, 12, 0, 12)
    coinFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    coinFrame.BackgroundTransparency = 0.3
    coinFrame.BorderSizePixel = 0
    coinFrame.Parent          = gui

    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(0, 10)
    coinCorner.Parent       = coinFrame

    local coinLbl = Instance.new("TextLabel")
    coinLbl.Name            = "CoinLabel"
    coinLbl.Size            = UDim2.new(1, -8, 1, 0)
    coinLbl.Position        = UDim2.new(0, 8, 0, 0)
    coinLbl.BackgroundTransparency = 1
    coinLbl.Text            = "$ 200"
    coinLbl.TextColor3      = Color3.fromRGB(255, 215, 0)
    coinLbl.TextSize        = 22
    coinLbl.Font            = Enum.Font.GothamBold
    coinLbl.TextXAlignment  = Enum.TextXAlignment.Left
    coinLbl.Parent          = coinFrame
    _coinLabel = coinLbl

    -- ── Shop toolbar (bottom center) ───────────────────────────────────────────
    local toolbar = Instance.new("Frame")
    toolbar.Name              = "Toolbar"
    toolbar.AnchorPoint       = Vector2.new(0.5, 1)
    toolbar.Size              = UDim2.new(0, #SHOP_ITEMS * 120 + (#SHOP_ITEMS - 1) * 8 + 16, 0, 80)
    toolbar.Position          = UDim2.new(0.5, 0, 1, -12)
    toolbar.BackgroundColor3  = Color3.fromRGB(20, 20, 30)
    toolbar.BackgroundTransparency = 0.25
    toolbar.BorderSizePixel   = 0
    toolbar.Parent            = gui

    local toolbarCorner = Instance.new("UICorner")
    toolbarCorner.CornerRadius = UDim.new(0, 12)
    toolbarCorner.Parent       = toolbar

    local layout = Instance.new("UIListLayout")
    layout.FillDirection  = Enum.FillDirection.Horizontal
    layout.Padding        = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Parent         = toolbar

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft  = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent       = toolbar

    local BuildController = Knit.GetController("BuildController")

    for _, item in ipairs(SHOP_ITEMS) do
        local priceText = if item.price == 0 then "Free" else ("$" .. item.price)
        local btn = makeButton(toolbar, item.label .. "\n" .. priceText, UDim2.new(0, 0, 0, 0), UDim2.new(0, 120, 0, 60))
        btn.TextSize = 13

        btn.MouseButton1Click:Connect(function()
            if item.id == "_conveyor" then
                BuildController:beginConveyorPlacement()
            else
                BuildController:beginPlacement(item.id)
            end
        end)
    end

    -- ── Hint label (top center, shows build mode status) ──────────────────────
    local hintLabel = Instance.new("TextLabel")
    hintLabel.Name              = "HintLabel"
    hintLabel.Size              = UDim2.new(0, 400, 0, 30)
    hintLabel.AnchorPoint       = Vector2.new(0.5, 0)
    hintLabel.Position          = UDim2.new(0.5, 0, 0, 60)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text              = ""
    hintLabel.TextColor3        = Color3.fromRGB(240, 240, 100)
    hintLabel.TextSize          = 16
    hintLabel.Font              = Enum.Font.Gotham
    hintLabel.Parent            = gui
end

function UIController:SetCoinBalance(coins: number)
    if _coinLabel then
        _coinLabel.Text = "$ " .. tostring(coins)
    end
end

-- Called by HUDController when StorageUpdated fires
function UIController:ShowStorageTooltip(_instanceId: string, _inventory: {[string]: number})
    -- Future: show a tooltip near the storage chest
end

function UIController:KnitInit() end

function UIController:KnitStart()
    buildUI()

    -- Listen for balance changes
    local economyService = Knit.GetService("EconomyService")
    economyService.BalanceUpdated:Connect(function(coins: number, _premiumCoins: number)
        self:SetCoinBalance(coins)
    end)
end

return UIController
