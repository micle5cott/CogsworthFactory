--!strict
-- Centralized networking registry. All RemoteEvents and RemoteFunctions
-- are declared here so any service can obtain them without knowing who owns them.
--
-- Usage (server): Network.getEvent(Network.Events.Foo):FireAllClients(...)
-- Usage (client): Network.getEvent(Network.Events.Foo).OnClientEvent:Connect(...)
--
-- The server creates instances; the client waits for them.
-- Knit services handle per-client signals via their Client table — this module
-- covers server-to-all-clients broadcasts and cross-service request/response.

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = RunService:IsServer()
local WAIT_TIMEOUT = 10

local Network = {}

-- ── Internal state ────────────────────────────────────────────────────────────

local _events:    {[string]: RemoteEvent}    = {}
local _functions: {[string]: RemoteFunction} = {}
local _folder:    Folder?

local function folder(): Folder
    if _folder then return _folder :: Folder end
    if IS_SERVER then
        local f = ReplicatedStorage:FindFirstChild("Network") :: Folder?
        if not f then
            f = Instance.new("Folder")
            f.Name = "Network"
            f.Parent = ReplicatedStorage
        end
        _folder = f
    else
        _folder = ReplicatedStorage:WaitForChild("Network", WAIT_TIMEOUT) :: Folder
        assert(_folder, "Network folder not found in ReplicatedStorage after " .. WAIT_TIMEOUT .. "s")
    end
    return _folder :: Folder
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Returns (creating if needed on server, waiting on client) a named RemoteEvent.
function Network.getEvent(name: string): RemoteEvent
    if _events[name] then return _events[name] end
    local f = folder()
    if IS_SERVER then
        local existing = f:FindFirstChild(name)
        if existing and existing:IsA("RemoteEvent") then
            _events[name] = existing :: RemoteEvent
            return _events[name]
        end
        local e = Instance.new("RemoteEvent")
        e.Name   = name
        e.Parent = f
        _events[name] = e
        return e
    else
        local found = f:WaitForChild(name, WAIT_TIMEOUT)
        assert(found and found:IsA("RemoteEvent"), "RemoteEvent not found: " .. name)
        _events[name] = found :: RemoteEvent
        return _events[name]
    end
end

-- Returns a named RemoteFunction.
function Network.getFunction(name: string): RemoteFunction
    if _functions[name] then return _functions[name] end
    local f = folder()
    if IS_SERVER then
        local existing = f:FindFirstChild(name)
        if existing and existing:IsA("RemoteFunction") then
            _functions[name] = existing :: RemoteFunction
            return _functions[name]
        end
        local fn = Instance.new("RemoteFunction")
        fn.Name   = name
        fn.Parent = f
        _functions[name] = fn
        return fn
    else
        local found = f:WaitForChild(name, WAIT_TIMEOUT)
        assert(found and found:IsA("RemoteFunction"), "RemoteFunction not found: " .. name)
        _functions[name] = found :: RemoteFunction
        return _functions[name]
    end
end

-- ── Named endpoint registry ───────────────────────────────────────────────────
-- All remote names in one place. Adding a new endpoint = add it here.

Network.Events = {
    -- Server → all clients
    RareNodeDiscovered   = "RareNodeDiscovered",
    ServerAnnouncement   = "ServerAnnouncement",
    ResearchTierUnlocked = "ResearchTierUnlocked",
    AscensionTriggered   = "AscensionTriggered",
    PlayerDataLoaded     = "PlayerDataLoaded",    -- fires to owning client on join
    PlayerDataUpdated    = "PlayerDataUpdated",   -- fires to owning client on any write
    PlotInfoUpdated      = "PlotInfoUpdated",     -- fires when plot state changes
}

Network.Functions = {
    -- Client → server request/response
    GetPlayerData        = "GetPlayerData",
    GetPlotInfo          = "GetPlotInfo",
}

return Network
