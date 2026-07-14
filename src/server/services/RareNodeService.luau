--!strict
-- Rolls rare node chance when a Miner is placed. Fires server-wide announcements.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type RareNodeRoll = Types.RareNodeRoll

local RareNodeService = Knit.CreateService({
    Name = "RareNodeService",
    Client = {
        -- Fired when the local player finds a rare node
        RareNodeFound = Knit.CreateSignal(), -- (roll: RareNodeRoll)
    },
})

-- Called by MachineService when a Miner is placed on a resource node.
-- Returns RareNodeRoll if a rare was triggered, nil otherwise.
-- Fires server-wide RemoteEvent on rare/legendary discoveries.
function RareNodeService:RollNode(
    player: Player,
    baseItemId: string,
    biomeId: string
): RareNodeRoll?
    return nil
end

-- Returns items currently stored in the trophy case for a plot.
function RareNodeService:GetTrophyCase(plotOwnerId: number): {string?}
    return {}
end

-- Place a rare item into a trophy case slot (0–8). Returns (success, errorMessage?).
function RareNodeService:SetTrophySlot(
    player: Player,
    slot: number,
    itemId: string?
): (boolean, string?)
    return false, "not implemented"
end

function RareNodeService:KnitInit() end
function RareNodeService:KnitStart() end

return RareNodeService
