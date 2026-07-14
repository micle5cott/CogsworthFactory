--!strict
-- Manages plot ownership, co-op membership, and permission checks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type CoopRole = Types.CoopRole

local PlotService = Knit.CreateService({
    Name = "PlotService",
    Client = {
        CoopMemberAdded   = Knit.CreateSignal(), -- (playerId: number, role: CoopRole)
        CoopMemberRemoved = Knit.CreateSignal(), -- (playerId: number)
        RoleChanged       = Knit.CreateSignal(), -- (playerId: number, newRole: CoopRole)
    },
})

-- Returns the role a player has on a given plot. "visitor" if not a member.
function PlotService:GetRole(actor: Player, plotOwnerId: number): CoopRole
    return "visitor"
end

-- Returns true if actor has at least the given role on the plot.
function PlotService:HasPermission(actor: Player, plotOwnerId: number, minimumRole: CoopRole): boolean
    return false
end

-- Invite a player to co-build. Owner only. Max 3 co-builders. Returns (success, errorMessage?).
function PlotService:InviteMember(owner: Player, targetPlayerId: number, role: CoopRole): (boolean, string?)
    return false, "not implemented"
end

-- Remove a co-builder. Owner only.
function PlotService:RemoveMember(owner: Player, targetPlayerId: number): boolean
    return false
end

function PlotService:KnitInit() end
function PlotService:KnitStart() end

return PlotService
