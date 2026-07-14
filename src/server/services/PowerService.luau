--!strict
-- Calculates power balance for each plot. Triggers blackout events when demand > supply.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local PowerService = Knit.CreateService({
    Name = "PowerService",
    Client = {
        PowerBalanceUpdated = Knit.CreateSignal(), -- (balance: number) — positive = surplus
        BlackoutStarted     = Knit.CreateSignal(), -- () — fired when plot enters blackout
        BlackoutEnded       = Knit.CreateSignal(), -- () — fired when power restored
    },
})

-- Returns total generation (PU) for a plot.
function PowerService:GetGeneration(plotOwnerId: number): number
    return 0
end

-- Returns total demand (PU) for all powered machines on a plot.
function PowerService:GetDemand(plotOwnerId: number): number
    return 0
end

-- Returns true if the plot is currently in a blackout.
function PowerService:IsBlackout(plotOwnerId: number): boolean
    return false
end

-- Recalculate power balance and fire events if state changed.
-- Called at POWER_UPDATE_HZ by the server loop.
function PowerService:TickPlot(plotOwnerId: number)
end

function PowerService:KnitInit() end
function PowerService:KnitStart() end

return PowerService
