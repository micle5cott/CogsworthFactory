--!strict
-- Player session lifecycle. Entry point for all join/leave logic.
-- Coordinates SaveService (data load) and PlotService (plot assignment).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger    = require(ReplicatedStorage.Shared.utils.Logger)
local DataModel = require(ReplicatedStorage.Shared.DataModel)
local Network   = require(ReplicatedStorage.Shared.Network)

local log = Logger.new("PlayerService")

local PlayerService = Knit.CreateService({
    Name = "PlayerService",
    Client = {
        SessionReady = Knit.CreateSignal(), -- () fired to owning client when data is loaded
    },
})

-- ── Public API ────────────────────────────────────────────────────────────────

-- Returns the in-memory PlayerData for a player, or nil if not yet loaded.
function PlayerService:getData(player: Player): DataModel.PlayerData?
    local SaveService = Knit.GetService("SaveService")
    return SaveService:getSession(player)
end

-- Returns PlayerData or errors if the session is not loaded.
-- Use inside services that require an active session.
function PlayerService:requireData(player: Player): DataModel.PlayerData
    local data = self:getData(player)
    assert(data ~= nil,
        string.format("PlayerService: session not loaded for %s (%d)", player.Name, player.UserId))
    return data :: DataModel.PlayerData
end

-- ── Internal ──────────────────────────────────────────────────────────────────

local function onPlayerAdded(player: Player)
    log:info("Player joined: %s (%d)", player.Name, player.UserId)
    task.spawn(function()
        local SaveService = Knit.GetService("SaveService")
        SaveService:loadPlayer(player)

        local PlotService = Knit.GetService("PlotService")
        PlotService:assignPlot(player)

        log:info("Session ready: %s (%d)", player.Name, player.UserId)
        PlayerService.Client.SessionReady:Fire(player)
    end)
end

local function onPlayerRemoving(player: Player)
    log:info("Player leaving: %s (%d)", player.Name, player.UserId)
    -- SaveService handles the actual save via its own PlayerRemoving connection.
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function PlayerService:KnitInit() end

function PlayerService:KnitStart()
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    -- Handle players who joined before KnitStart (rare in practice, safe to have).
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(onPlayerAdded, player)
    end

    -- Expose GetPlayerData RemoteFunction for the client.
    local getDataFn = Network.getFunction(Network.Functions.GetPlayerData)
    getDataFn.OnServerInvoke = function(player: Player)
        return self:getData(player)
    end

    log:info("PlayerService started")
end

return PlayerService
