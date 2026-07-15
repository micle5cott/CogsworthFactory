--!strict
-- Plot ownership, assignment, co-op membership, and permission checks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger  = require(ReplicatedStorage.Shared.utils.Logger)
local Network = require(ReplicatedStorage.Shared.Network)
local Types   = require(ReplicatedStorage.Shared.Types)

type CoopRole = Types.CoopRole

local log = Logger.new("PlotService")

-- Role ordering for permission checks (higher index = more permissions).
local ROLE_ORDER: {CoopRole} = { "visitor", "builder", "co_owner", "owner" }
local ROLE_RANK: {[CoopRole]: number} = {}
for i, r in ipairs(ROLE_ORDER) do ROLE_RANK[r] = i end

local PlotService = Knit.CreateService({
    Name = "PlotService",
    Client = {
        CoopMemberAdded   = Knit.CreateSignal(), -- (playerId: number, role: CoopRole)
        CoopMemberRemoved = Knit.CreateSignal(), -- (playerId: number)
        RoleChanged       = Knit.CreateSignal(), -- (playerId: number, newRole: CoopRole)
    },
})

-- plotId → ownerId
local _plotOwners:  {[string]: number} = {}
-- ownerId → plotId
local _playerPlots: {[number]: string} = {}

-- ── Public API ────────────────────────────────────────────────────────────────

-- Assign a fresh plot to a player on join.
function PlotService:assignPlot(player: Player)
    local plotId = tostring(player.UserId)
    _plotOwners[plotId]          = player.UserId
    _playerPlots[player.UserId]  = plotId
    log:info("Plot '%s' assigned to %s (%d)", plotId, player.Name, player.UserId)
    Network.getEvent(Network.Events.PlotInfoUpdated):FireClient(player, { plotId = plotId })
    -- Tree/deposit spawning handled by SaveService after character lands on terrain
end

-- Release a player's plot on leave.
function PlotService:releasePlot(player: Player)
    local plotId = _playerPlots[player.UserId]
    if plotId then
        _plotOwners[plotId] = nil
        _playerPlots[player.UserId] = nil
        log:info("Plot '%s' released by %s (%d)", plotId, player.Name, player.UserId)
        local TreeService = Knit.GetService("TreeService")
        TreeService:cleanupPlot(plotId)
    end
end

-- Returns the plotId owned by a player, or nil.
function PlotService:getPlotId(player: Player): string?
    return _playerPlots[player.UserId]
end

-- Returns the role an actor has on plotOwnerId's plot. "visitor" if unrelated.
function PlotService:GetRole(actor: Player, plotOwnerId: number): CoopRole
    if actor.UserId == plotOwnerId then return "owner" end
    local SaveService = Knit.GetService("SaveService")
    local ownerPlayer = nil :: Player?
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p.UserId == plotOwnerId then ownerPlayer = p break end
    end
    if not ownerPlayer then return "visitor" end
    local data = SaveService:getSession(ownerPlayer)
    if not data then return "visitor" end
    for _, member in ipairs(data.coop.members) do
        if member.playerId == actor.UserId then
            return member.role :: CoopRole
        end
    end
    return "visitor"
end

-- Returns true if actor has at least minimumRole on plotOwnerId's plot.
function PlotService:HasPermission(actor: Player, plotOwnerId: number, minimumRole: CoopRole): boolean
    local role = self:GetRole(actor, plotOwnerId)
    return (ROLE_RANK[role] or 0) >= (ROLE_RANK[minimumRole] or 0)
end

-- Invite a player. Owner only. Max co-builders enforced. Returns (ok, err?).
function PlotService:InviteMember(owner: Player, targetPlayerId: number, role: CoopRole): (boolean, string?)
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(owner)
    if not data then return false, "session not loaded" end
    if role == "owner" then return false, "cannot assign owner role" end
    local builders = 0
    for _, m in ipairs(data.coop.members) do
        if m.playerId == targetPlayerId then return false, "already a member" end
        builders += 1
    end
    if builders >= 3 then return false, "co-builder limit reached" end
    table.insert(data.coop.members, { playerId = targetPlayerId, role = role })
    SaveService:updateSession(owner, { coop = data.coop })
    self.Client.CoopMemberAdded:Fire(owner, targetPlayerId, role)
    return true, nil
end

-- Remove a co-builder. Owner only.
function PlotService:RemoveMember(owner: Player, targetPlayerId: number): boolean
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(owner)
    if not data then return false end
    for i, m in ipairs(data.coop.members) do
        if m.playerId == targetPlayerId then
            table.remove(data.coop.members, i)
            SaveService:updateSession(owner, { coop = data.coop })
            self.Client.CoopMemberRemoved:Fire(owner, targetPlayerId)
            return true
        end
    end
    return false
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function PlotService:KnitInit() end

function PlotService:KnitStart()
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        self:releasePlot(player)
    end)

    Network.getFunction(Network.Functions.GetPlotInfo).OnServerInvoke = function(player: Player)
        return { plotId = _playerPlots[player.UserId] }
    end

    log:info("PlotService started")
end

return PlotService
