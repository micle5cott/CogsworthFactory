--!strict
-- Handles visual-only drone interpolation on the client.
-- Receives drone task events from DroneService and animates drone models.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local DroneController = Knit.CreateController({ Name = "DroneController" })

-- Spawn a drone model and begin animating it toward targetPosition.
-- droneId is used to update/remove the drone later.
function DroneController:SpawnDroneVisual(droneId: string, targetPosition: Vector3)
end

-- Despawn a drone model (called when task completes).
function DroneController:DespawnDroneVisual(droneId: string)
end

function DroneController:KnitInit() end
function DroneController:KnitStart() end

return DroneController
