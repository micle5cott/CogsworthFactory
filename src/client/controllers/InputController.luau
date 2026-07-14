--!strict
-- Translates raw mouse/keyboard input into game actions.
-- Routes to BuildController for placement, UIController for menu toggles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local InputController = Knit.CreateController({ Name = "InputController" })

-- Returns the world position under the cursor snapped to the tile grid.
function InputController:GetCursorTilePosition(): {x: number, z: number}?
    return nil
end

function InputController:KnitInit() end

function InputController:KnitStart()
    -- Bind: R → RotateGhost
    -- Bind: Escape → CancelPlacement
    -- Bind: E → toggle toolbar
    -- Bind: left-click → ConfirmPlacement (when in placement mode)
end

return InputController
