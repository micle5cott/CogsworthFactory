--!strict
-- Manages the Drone Network: task queuing, drone assignment, logistic/construction execution.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type DroneTask = Types.DroneTask

local DroneService = Knit.CreateService({
    Name = "DroneService",
    Client = {
        DroneTaskStarted   = Knit.CreateSignal(), -- (droneId: string, task: DroneTask)
        DroneTaskCompleted = Knit.CreateSignal(), -- (droneId: string)
        ActiveDroneCount   = Knit.CreateSignal(), -- (count: number)
    },
})

-- Returns number of active drones on a plot.
function DroneService:GetActiveDroneCount(plotOwnerId: number): number
    return 0
end

-- Place a Blueprint ghost. Construction Drones will auto-build it.
-- ghostId identifies this ghost; machineId + position define what to build.
function DroneService:QueueBlueprintGhost(
    plotOwnerId: number,
    ghostId: string,
    machineId: string,
    position: {x: number, z: number},
    rotation: number
)
end

-- Cancel a pending ghost (before drones start building it).
function DroneService:CancelGhost(plotOwnerId: number, ghostId: string): boolean
    return false
end

-- Tick drone tasks forward. Called at POWER_UPDATE_HZ by the server loop.
function DroneService:TickPlot(plotOwnerId: number, deltaTime: number)
end

function DroneService:KnitInit() end
function DroneService:KnitStart() end

return DroneService
