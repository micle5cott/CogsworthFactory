--!strict
-- Handles machine/conveyor placement UI: ghost preview, click-to-place, rotation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local BuildController = Knit.CreateController({ Name = "BuildController" })

-- Enter placement mode for a machine type. Shows ghost preview on cursor.
function BuildController:BeginPlacement(machineId: string)
end

-- Confirm placement at the current ghost position.
function BuildController:ConfirmPlacement()
end

-- Cancel current placement without placing anything.
function BuildController:CancelPlacement()
end

-- Rotate the placement ghost 90° clockwise.
function BuildController:RotateGhost()
end

-- Enter conveyor placement mode for a given tier.
function BuildController:BeginConveyorPlacement(tier: number)
end

function BuildController:KnitInit() end
function BuildController:KnitStart() end

return BuildController
