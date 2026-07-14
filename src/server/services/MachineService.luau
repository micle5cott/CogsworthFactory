--!strict
-- Manages machine placement, removal, efficiency tracking, and specialization.
-- Server-authoritative: all client build requests validated here before applying.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type MachineInstance = Types.MachineInstance
type TilePosition = Types.TilePosition

local MachineService = Knit.CreateService({
    Name = "MachineService",
    Client = {
        -- Fired when a machine's efficiency % changes (throttled to MACHINE_EFFICIENCY_UPDATE_HZ)
        EfficiencyChanged = Knit.CreateSignal(), -- (instanceId: string, efficiency: number)
        -- Fired when any machine is placed on the plot
        MachinePlaced = Knit.CreateSignal(),     -- (machine: MachineInstance)
        -- Fired when any machine is removed
        MachineRemoved = Knit.CreateSignal(),    -- (instanceId: string)
    },
})

-- Place a machine. Returns (success, errorMessage?).
-- Validates: plot ownership, tile empty, materials available, tier unlocked.
-- On success: deducts build cost, creates MachineInstance, fires MachinePlaced.
function MachineService:PlaceMachine(
    player: Player,
    machineId: string,
    position: TilePosition,
    rotation: number
): (boolean, string?)
    return false, "not implemented"
end

-- Remove a machine by instanceId. Returns 100% of build materials to player storage.
function MachineService:RemoveMachine(player: Player, instanceId: string): boolean
    return false
end

-- Apply a specialization to a machine. Permanent and irreversible.
-- Returns (success, errorMessage?).
function MachineService:SpecializeMachine(
    player: Player,
    instanceId: string,
    specializationId: string
): (boolean, string?)
    return false, "not implemented"
end

-- Returns current efficiency 0–100 for a machine instance.
function MachineService:GetEfficiency(instanceId: string): number
    return 0
end

-- Called by ConveyorService every simulation tick.
-- Attempts to consume items from inputBuffer and advance outputBuffer.
function MachineService:Tick(instanceId: string, deltaTime: number)
end

function MachineService:KnitInit() end
function MachineService:KnitStart() end

return MachineService
