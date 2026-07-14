--!strict
-- Manages conveyor placement and batched item transport between machine buffers.
-- Items move in batches per MACHINE_EFFICIENCY_UPDATE_HZ, not per-frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type TilePosition = Types.TilePosition

local ConveyorService = Knit.CreateService({
    Name = "ConveyorService",
    Client = {
        ConveyorPlaced  = Knit.CreateSignal(), -- (segmentId: string, tier: number, from: TilePosition, to: TilePosition)
        ConveyorRemoved = Knit.CreateSignal(), -- (segmentId: string)
        JamDetected     = Knit.CreateSignal(), -- (segmentId: string) — fired when throughput is blocked
    },
})

-- Place one conveyor segment. Returns (success, errorMessage?).
function ConveyorService:PlaceSegment(
    player: Player,
    tier: number,
    fromPosition: TilePosition,
    toPosition: TilePosition
): (boolean, string?)
    return false, "not implemented"
end

-- Remove a segment by segmentId. Refunds build materials.
function ConveyorService:RemoveSegment(player: Player, segmentId: string): boolean
    return false
end

-- Returns throughput utilisation 0–1 for a segment (1 = at capacity).
function ConveyorService:GetUtilisation(segmentId: string): number
    return 0
end

-- Run one transport tick for all conveyors on a plot.
-- Moves items from source machine outputBuffer toward destination inputBuffer.
-- Called by the main server loop at MACHINE_EFFICIENCY_UPDATE_HZ.
function ConveyorService:TickPlot(plotOwnerId: number, deltaTime: number)
end

function ConveyorService:KnitInit() end
function ConveyorService:KnitStart() end

return ConveyorService
