--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local VSConfig = require(ReplicatedStorage.Shared.config.VSConfig)
local Network  = require(ReplicatedStorage.Shared.Network)

local UIController = Knit.CreateController({ Name = "UIController" })

local localPlayer    = Players.LocalPlayer
local _gui: ScreenGui?
local _inventoryOpen = false
local _storageOpen   = false
local _deliverOpen   = false

local _inventoryFrame: Frame?
local _slotFrames: {[number]: Frame} = {}
local _currentSlots: {[number]: {itemId: string, count: number}?} = {}

local _storageFrame:       Frame?
local _storageInstanceId:  string?

local _deliverFrame: Frame?

-- Machine item id → machineId for build controller
local MACHINE_ITEMS: {[string]: string} = {
    lumber_mill_item    = "lumber_mill",
    smelter_item        = "smelter",
    storage_chest_item  = "storage_chest",
    crafting_bench_item = "crafting_bench",
    conveyor_belt_item  = "_conveyor",
}

-- ── UI helpers ────────────────────────────────────────────────────────────────

local function makeCorner(parent: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent       = parent
end

local function makeFrame(parent: GuiObject, size: UDim2, pos: UDim2, color: Color3, alpha: number): Frame
    local f = Instance.new("Frame")
    f.Size = size; f.Position = pos
    f.BackgroundColor3 = color; f.BackgroundTransparency = alpha
    f.BorderSizePixel  = 0; f.Parent = parent
    makeCorner(f, 8)
    return f
end

local function makeLabel(parent: GuiObject, text: string, size: UDim2, pos: UDim2, textSize: number, color: Color3?): TextLabel
    local l = Instance.new("TextLabel")
    l.Size = size; l.Position = pos; l.Text = text; l.TextSize = textSize
    l.BackgroundTransparency = 1
    l.TextColor3  = color or Color3.fromRGB(220, 220, 220)
    l.Font        = Enum.Font.GothamBold
    l.TextWrapped = true
    l.Parent      = parent
    return l
end

local function makeButton(parent: GuiObject, text: string, size: UDim2, pos: UDim2): TextButton
    local b = Instance.new("TextButton")
    b.Size = size; b.Position = pos; b.Text = text; b.TextSize = 13
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    b.BorderSizePixel  = 0
    b.TextColor3       = Color3.fromRGB(220, 220, 220)
    b.Font             = Enum.Font.Gotham
    b.AutoButtonColor  = true
    b.Parent           = parent
    makeCorner(b, 6)
    return b
end

-- ── Inventory screen ──────────────────────────────────────────────────────────

local function buildInventoryScreen(gui: ScreenGui)
    local bg = makeFrame(gui,
        UDim2.new(0, 600, 0, 500),
        UDim2.new(0.5, -300, 0.5, -250),
        Color3.fromRGB(18, 18, 28), 0.08
    )
    bg.Name    = "InventoryBG"
    bg.Visible = false
    _inventoryFrame = bg

    makeLabel(bg, "INVENTORY  [TAB to close]",
        UDim2.new(1, -8, 0, 26), UDim2.new(0, 8, 0, 8), 14,
        Color3.fromRGB(160, 160, 200))

    -- 5×5 slot grid
    local SLOT_SZ  = 74
    local SLOT_PAD = 5
    for i = 1, VSConfig.INVENTORY_SLOTS do
        local col = (i - 1) % 5
        local row = math.floor((i - 1) / 5)
        local sx  = 12 + col * (SLOT_SZ + SLOT_PAD)
        local sy  = 42 + row * (SLOT_SZ + SLOT_PAD)

        local slotBg = makeFrame(bg,
            UDim2.new(0, SLOT_SZ, 0, SLOT_SZ),
            UDim2.new(0, sx, 0, sy),
            Color3.fromRGB(32, 32, 48), 0)

        slotBg.Name = "Slot_" .. i

        local itemLbl = makeLabel(slotBg, "",
            UDim2.new(1, -2, 0.55, 0), UDim2.new(0, 1, 0.42, 0), 10)
        itemLbl.Name           = "ItemLabel"
        itemLbl.TextXAlignment = Enum.TextXAlignment.Center

        local countLbl = makeLabel(slotBg, "",
            UDim2.new(1, -4, 0, 15), UDim2.new(0, 2, 1, -18), 12,
            Color3.fromRGB(200, 200, 100))
        countLbl.Name           = "CountLabel"
        countLbl.TextXAlignment = Enum.TextXAlignment.Right

        -- Click: if machine item → enter placement mode
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,1,0)
        btn.BackgroundTransparency = 1
        btn.Text   = ""; btn.Parent = slotBg
        local idx  = i
        btn.MouseButton1Click:Connect(function()
            local slot = _currentSlots[idx]
            if not slot then return end
            local machineId = MACHINE_ITEMS[slot.itemId]
            if machineId then
                local BuildController = Knit.GetController("BuildController")
                if machineId == "_conveyor" then
                    BuildController:beginConveyorPlacement()
                else
                    BuildController:beginPlacement(machineId)
                end
                UIController:closeInventory()
            end
        end)

        _slotFrames[i] = slotBg
    end

    -- Personal crafting panel on the right
    local craftPanel = makeFrame(bg,
        UDim2.new(0, 168, 0, 450),
        UDim2.new(0, 420, 0, 38),
        Color3.fromRGB(28, 28, 44), 0)
    makeLabel(craftPanel, "CRAFT (personal)",
        UDim2.new(1,0,0,22), UDim2.new(0,0,0,4), 12,
        Color3.fromRGB(140, 140, 180))

    local y = 30
    for recipeId, recipe in pairs(VSConfig.PERSONAL_RECIPES) do
        local outText = ""
        for itemId, count in pairs(recipe.outputs) do
            outText = "→ " .. count .. "× " .. itemId
        end
        local inText = ""
        for itemId, count in pairs(recipe.inputs) do
            inText = inText .. count .. "× " .. itemId .. "  "
        end
        local btn = makeButton(craftPanel, outText .. "\n" .. inText,
            UDim2.new(1, -8, 0, 52), UDim2.new(0, 4, 0, y))
        btn.TextSize = 11
        local rid = recipeId
        btn.MouseButton1Click:Connect(function()
            local inventoryService = Knit.GetService("InventoryService")
            local ok, err = inventoryService:PersonalCraft(rid)
            if not ok and err then
                -- briefly flash label red
            end
        end)
        y += 58
    end

    -- Close button
    local closeBtn = makeButton(bg, "✕", UDim2.new(0, 28, 0, 28), UDim2.new(1, -34, 0, 4))
    closeBtn.MouseButton1Click:Connect(function() UIController:closeInventory() end)
end

function UIController:refreshSlots(slots: {[number]: {itemId: string, count: number}?})
    _currentSlots = slots
    for i = 1, VSConfig.INVENTORY_SLOTS do
        local frame = _slotFrames[i]
        if not frame then continue end
        local slot      = slots[i]
        local itemLbl   = frame:FindFirstChild("ItemLabel")  :: TextLabel?
        local countLbl  = frame:FindFirstChild("CountLabel") :: TextLabel?
        if slot then
            if itemLbl  then itemLbl.Text  = slot.itemId end
            if countLbl then countLbl.Text = "×" .. slot.count end
            frame.BackgroundColor3 = Color3.fromRGB(44, 44, 66)
        else
            if itemLbl  then itemLbl.Text  = "" end
            if countLbl then countLbl.Text = "" end
            frame.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
        end
    end
end

function UIController:openInventory()
    if not _inventoryFrame then return end
    _inventoryFrame.Visible = true
    _inventoryOpen = true
    local inventoryService = Knit.GetService("InventoryService")
    local slots = inventoryService:GetSlots()
    self:refreshSlots(slots)
end

function UIController:closeInventory()
    if _inventoryFrame then _inventoryFrame.Visible = false end
    _inventoryOpen = false
end

function UIController:toggleInventory()
    if _inventoryOpen then self:closeInventory() else self:openInventory() end
end

-- ── Storage UI ────────────────────────────────────────────────────────────────

local function buildStorageUI(gui: ScreenGui)
    local bg = makeFrame(gui,
        UDim2.new(0, 300, 0, 340),
        UDim2.new(0.5, -150, 0.5, -170),
        Color3.fromRGB(28, 18, 10), 0.08)
    bg.Name    = "StorageBG"
    bg.Visible = false
    _storageFrame = bg

    makeLabel(bg, "STORAGE CHEST",
        UDim2.new(1,0,0,26), UDim2.new(0,0,0,6), 14,
        Color3.fromRGB(210, 160, 90))

    local contentLbl = makeLabel(bg, "(empty)",
        UDim2.new(1,-16,0,230), UDim2.new(0,8,0,36), 13)
    contentLbl.Name           = "ContentLabel"
    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
    contentLbl.TextYAlignment = Enum.TextYAlignment.Top

    local takeBtn = makeButton(bg, "Take All",
        UDim2.new(1,-16,0,38), UDim2.new(0,8,1,-52))
    takeBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
    takeBtn.MouseButton1Click:Connect(function()
        if _storageInstanceId then
            local storageService = Knit.GetService("StorageService")
            storageService:TakeAll(_storageInstanceId)
            UIController:closeStorage()
        end
    end)

    local closeBtn = makeButton(bg, "✕", UDim2.new(0,28,0,28), UDim2.new(1,-34,0,4))
    closeBtn.MouseButton1Click:Connect(function() UIController:closeStorage() end)
end

function UIController:openStorage(instanceId: string, inventory: {[string]: number})
    _storageInstanceId = instanceId
    if not _storageFrame then return end
    local lbl = _storageFrame:FindFirstChild("ContentLabel") :: TextLabel?
    if lbl then
        local lines = {}
        local empty = true
        for itemId, count in pairs(inventory) do
            if count > 0 then
                table.insert(lines, count .. "× " .. itemId)
                empty = false
            end
        end
        lbl.Text = if empty then "(empty)" else table.concat(lines, "\n")
    end
    _storageFrame.Visible = true
    _storageOpen = true
end

function UIController:closeStorage()
    if _storageFrame then _storageFrame.Visible = false end
    _storageOpen       = false
    _storageInstanceId = nil
end

-- ── Nova Machina delivery UI ──────────────────────────────────────────────────

local function buildDeliverUI(gui: ScreenGui)
    local bg = makeFrame(gui,
        UDim2.new(0, 340, 0, 380),
        UDim2.new(0.5, -170, 0.5, -190),
        Color3.fromRGB(8, 18, 40), 0.08)
    bg.Name    = "DeliverBG"
    bg.Visible = false
    _deliverFrame = bg

    makeLabel(bg, "NOVA MACHINA — ITERATION I",
        UDim2.new(1,0,0,26), UDim2.new(0,0,0,6), 13,
        Color3.fromRGB(100, 180, 255))

    local progressLbl = makeLabel(bg, "Loading...",
        UDim2.new(1,-16,0,140), UDim2.new(0,8,0,36), 13)
    progressLbl.Name           = "ProgressLabel"
    progressLbl.TextXAlignment = Enum.TextXAlignment.Left
    progressLbl.TextYAlignment = Enum.TextYAlignment.Top

    local y = 186
    for itemId, _ in pairs(VSConfig.ITERATION_I_GOALS) do
        local btn = makeButton(bg, "Deliver all " .. itemId .. " from inventory",
            UDim2.new(1,-16,0,40), UDim2.new(0,8,0,y))
        btn.BackgroundColor3 = Color3.fromRGB(30, 70, 120)
        local iid = itemId
        btn.MouseButton1Click:Connect(function()
            local total = 0
            for _, slot in pairs(_currentSlots) do
                if slot and slot.itemId == iid then total += slot.count end
            end
            if total > 0 then
                local novaMachinaService = Knit.GetService("NovaMachinaService")
                novaMachinaService:Deliver(iid, total)
            end
        end)
        y += 48
    end

    local closeBtn = makeButton(bg, "✕", UDim2.new(0,28,0,28), UDim2.new(1,-34,0,4))
    closeBtn.MouseButton1Click:Connect(function() UIController:closeDeliver() end)
end

function UIController:openDeliver(deliveries: {[string]: number}, goals: {[string]: number})
    if not _deliverFrame then return end
    local lbl = _deliverFrame:FindFirstChild("ProgressLabel") :: TextLabel?
    if lbl then
        local lines = {}
        for itemId, required in pairs(goals) do
            local have = deliveries[itemId] or 0
            local done = if have >= required then " ✓" else ""
            table.insert(lines, itemId .. ": " .. have .. " / " .. required .. done)
        end
        lbl.Text = table.concat(lines, "\n")
    end
    _deliverFrame.Visible = true
    _deliverOpen = true
end

function UIController:closeDeliver()
    if _deliverFrame then _deliverFrame.Visible = false end
    _deliverOpen = false
end

-- ── Query ─────────────────────────────────────────────────────────────────────

function UIController:isAnyUIOpen(): boolean
    return _inventoryOpen or _storageOpen or _deliverOpen
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function UIController:KnitInit() end

function UIController:KnitStart()
    local gui = Instance.new("ScreenGui")
    gui.Name           = "NovaMachinaHUD"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.Parent         = localPlayer:WaitForChild("PlayerGui")
    _gui = gui

    buildInventoryScreen(gui)
    buildStorageUI(gui)
    buildDeliverUI(gui)

    -- Server push: inventory changed
    Network.getEvent(Network.Events.InventoryUpdated).OnClientEvent:Connect(function(slots)
        _currentSlots = slots
        if _inventoryOpen then self:refreshSlots(slots) end
    end)

    -- Server push: storage opened
    Network.getEvent(Network.Events.StorageOpened).OnClientEvent:Connect(function(instanceId, inventory)
        self:openStorage(instanceId, inventory)
    end)

    -- Server push: nova machina progress
    Network.getEvent(Network.Events.NovaMachinaUpdated).OnClientEvent:Connect(function(deliveries, goals)
        if _deliverOpen then self:openDeliver(deliveries, goals) end
    end)

    -- Iteration complete announcement
    Network.getEvent(Network.Events.IterationComplete).OnClientEvent:Connect(function(iteration: number, playerName: string)
        local ann = Instance.new("TextLabel")
        ann.Size            = UDim2.new(0, 520, 0, 70)
        ann.AnchorPoint     = Vector2.new(0.5, 0)
        ann.Position        = UDim2.new(0.5, 0, 0, 90)
        ann.BackgroundColor3 = Color3.fromRGB(8, 24, 60)
        ann.BackgroundTransparency = 0.1
        ann.BorderSizePixel = 0
        ann.Text            = "★  ITERATION " .. iteration .. " COMPLETE  ★\n" .. playerName .. " awakened the Nova Machina!"
        ann.TextColor3      = Color3.fromRGB(100, 200, 255)
        ann.TextSize        = 19
        ann.Font            = Enum.Font.GothamBold
        ann.TextWrapped     = true
        ann.Parent          = gui
        makeCorner(ann, 10)
        game:GetService("Debris"):AddItem(ann, 8)
    end)

    -- Hint label: show E-key prompts and build mode status
    local hintLabel = makeLabel(gui, "",
        UDim2.new(0, 400, 0, 28), UDim2.new(0.5, -200, 0, 56), 14,
        Color3.fromRGB(240, 230, 100))
    hintLabel.Name        = "HintLabel"
    hintLabel.AnchorPoint = Vector2.new(0.5, 0)

    -- Expose hint label for other controllers to update
    self._hintLabel = hintLabel
end

function UIController:setHint(text: string)
    if self._hintLabel then
        (self._hintLabel :: TextLabel).Text = text
    end
end

return UIController
