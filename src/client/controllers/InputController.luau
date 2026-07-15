--!strict
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)
local VSConfig   = require(ReplicatedStorage.Shared.config.VSConfig)

local TILE = GameConfig.TILE_SIZE_STUDS

local InputController = Knit.CreateController({ Name = "InputController" })

local _camera    = Workspace.CurrentCamera
local _eMining   = false   -- true while E is held

-- Returns tile position under cursor (used by BuildController)
function InputController:GetCursorTilePosition(tileSize: number, ignoreList: {Instance}?): {x: number, z: number}?
    local mouse   = Players.LocalPlayer:GetMouse()
    local unitRay = _camera:ScreenPointToRay(mouse.X, mouse.Y)
    local ray     = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
    local _, hitPos = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList or {})
    if not hitPos then return nil end
    return {
        x = math.round(hitPos.X / tileSize),
        z = math.round(hitPos.Z / tileSize),
    }
end

-- Returns Part + hit position under cursor, ignoring the local character
function InputController:GetCursorPart(ignoreList: {Instance}?): (BasePart?, Vector3?)
    local mouse   = Players.LocalPlayer:GetMouse()
    local unitRay = _camera:ScreenPointToRay(mouse.X, mouse.Y)
    local ray     = Ray.new(unitRay.Origin, unitRay.Direction * 500)
    local ignore  = ignoreList or {}
    local char    = Players.LocalPlayer.Character
    if char then table.insert(ignore, char) end
    local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, ignore)
    return hit, pos
end

local function isChiselEquipped(): boolean
    local char = Players.LocalPlayer.Character
    return char ~= nil and char:FindFirstChild("Chisel") ~= nil
end

-- E-key context handler: checks what Part is under the cursor and dispatches
function InputController:handleEKey()
    local UIController = Knit.GetController("UIController")
    local part, _      = self:GetCursorPart()
    if not part then return end

    -- World drop?
    local dropId = part:GetAttribute("DropId")
    if dropId then
        local worldDropService = Knit.GetService("WorldDropService")
        worldDropService:PickupDrop(dropId)
        -- brief pickup confirmation in the hint
        local rawName = part.Name  -- e.g. "Drop_log" or "Drop_iron_ore"
        local itemName = rawName:match("^Drop_(.+)$") or rawName
        UIController:setHint("+ " .. itemName)
        task.delay(0.6, function() UIController:setHint("") end)
        return
    end

    -- Deposit (rock)?
    local depositId = part:GetAttribute("DepositId")
    if depositId then
        if not isChiselEquipped() then
            UIController:setHint("Equip Chisel [press 1] to mine")
            return
        end
        local depositService = Knit.GetService("DepositService")
        depositService:HitDeposit(depositId)
        return
    end

    -- Tree?
    local treeTileX = part:GetAttribute("TreeTileX")
    local treeTileZ = part:GetAttribute("TreeTileZ")
    if treeTileX and treeTileZ then
        if not isChiselEquipped() then
            UIController:setHint("Equip Chisel [press 1] to chop")
            return
        end
        local treeService = Knit.GetService("TreeService")
        treeService:HitTree(treeTileX, treeTileZ)
        return
    end

    -- Crafting bench? (has CraftingBenchId; must come before generic InstanceId check)
    local benchId = part:GetAttribute("CraftingBenchId")
    if benchId then
        UIController:openBenchCraft(benchId)
        return
    end

    -- Storage chest or machine?
    local instanceId = part:GetAttribute("InstanceId")
    if instanceId then
        local storageService = Knit.GetService("StorageService")
        storageService:OpenStorage(instanceId)
        return
    end

    -- Nova Machina?
    local isNova = part:GetAttribute("NovaMachina")
    if isNova then
        local novaMachinaService = Knit.GetService("NovaMachinaService")
        local progress = novaMachinaService:GetProgress()
        UIController:openDeliver(progress.deliveries, progress.goals)
        return
    end
end

function InputController:KnitInit() end

function InputController:KnitStart()
    local BuildController = Knit.GetController("BuildController")
    local UIController    = Knit.GetController("UIController")

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        -- TAB: check BEFORE gameProcessed — Roblox leaderboard also binds to Tab
        -- and marks it gameProcessed, which would block our inventory toggle.
        if input.KeyCode == Enum.KeyCode.Tab then
            UIController:toggleInventory()
            return
        end

        if gameProcessed then return end

        -- Block other keys when a UI panel is open
        if UIController:isAnyUIOpen() then return end

        if input.KeyCode == Enum.KeyCode.Escape then
            BuildController:cancelPlacement()
            UIController:setHint("")
        end

        if input.KeyCode == Enum.KeyCode.R then
            BuildController:rotatePlacement()
        end

        if input.KeyCode == Enum.KeyCode.E then
            if BuildController:isInPlacementMode() or BuildController:isInConveyorMode() then return end
            if _eMining then return end
            _eMining = true
            task.spawn(function()
                while _eMining do
                    if not UIController:isAnyUIOpen() then
                        self:handleEKey()
                    end
                    task.wait(VSConfig.CHISEL_HIT_COOLDOWN)
                end
            end)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.E then
            _eMining = false
        end
    end)

    -- Left-click: confirm placement
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or UIController:isAnyUIOpen() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if BuildController:isInPlacementMode() then
                BuildController:confirmPlacement()
            elseif BuildController:isInConveyorMode() then
                BuildController:confirmConveyorStep()
            end
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            if BuildController:isInConveyorMode() then
                BuildController:cancelPlacement()
                UIController:setHint("")
            end
        end
    end)

    -- Per-frame: update the cursor hint based on what the cursor is hovering
    RunService.RenderStepped:Connect(function()
        if UIController:isAnyUIOpen() then
            UIController:setHint("")
            return
        end
        if BuildController:isInPlacementMode() then
            UIController:setHint("[LMB] Place  ·  [R] Rotate  ·  [ESC] Cancel")
            return
        end
        if BuildController:isInConveyorMode() then
            UIController:setHint("[LMB] Set tile  ·  [LMB] Connect  ·  [RMB] Cancel")
            return
        end

        local part = self:GetCursorPart()
        if not part then UIController:setHint(""); return end

        if part:GetAttribute("DropId") then
            UIController:setHint("[E] Pick up")
        elseif part:GetAttribute("DepositId") then
            if isChiselEquipped() then
                UIController:setHint("[E] Mine (hold)")
            else
                UIController:setHint("Equip Chisel [1] to mine")
            end
        elseif part:GetAttribute("TreeTileX") then
            if isChiselEquipped() then
                UIController:setHint("[E] Chop (hold)")
            else
                UIController:setHint("Equip Chisel [1] to chop")
            end
        elseif part:GetAttribute("CraftingBenchId") then
            UIController:setHint("[E] Open Crafting Bench")
        elseif part:GetAttribute("NovaMachina") then
            UIController:setHint("[E] Open Nova Machina")
        elseif part:GetAttribute("InstanceId") then
            UIController:setHint("[E] Interact")
        else
            UIController:setHint("")
        end
    end)
end

return InputController
