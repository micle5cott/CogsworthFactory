--!strict
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local InputController = Knit.CreateController({ Name = "InputController" })

local _camera = Workspace.CurrentCamera

-- Returns the world tile position under the mouse cursor, or nil.
function InputController:GetCursorTilePosition(tileSize: number): {x: number, z: number}?
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    local unitRay = _camera:ScreenPointToRay(mouse.X, mouse.Y)
    local ray = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
    local hitInstance, hitPos = Workspace:FindPartOnRayWithIgnoreList(ray, {})
    if not hitPos then return nil end
    return {
        x = math.round(hitPos.X / tileSize),
        z = math.round(hitPos.Z / tileSize),
    }
end

function InputController:KnitInit() end

function InputController:KnitStart()
    local BuildController = Knit.GetController("BuildController")

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.Escape then
            BuildController:cancelPlacement()
        end

        if input.KeyCode == Enum.KeyCode.R then
            BuildController:rotatePlacement()
        end

        if input.KeyCode == Enum.KeyCode.E then
            -- Toggle build mode removal — handled in BuildController via right-click or E+click
        end
    end)

    -- Left-click to confirm placement
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if BuildController:isInPlacementMode() then
                BuildController:confirmPlacement()
            end
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            if BuildController:isInConveyorMode() then
                BuildController:confirmConveyorEnd()
            end
        end
    end)
end

return InputController
