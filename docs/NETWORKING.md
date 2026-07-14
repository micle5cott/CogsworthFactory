# Networking

## Architecture

All remotes are managed through `src/shared/Network.luau`. The server creates instances in a `Network` folder under ReplicatedStorage; the client waits for them.

Knit services handle per-client signals via their `Client` table (e.g. `MachineService.Client.MachinePlaced`). `Network.luau` covers **server-to-all-clients broadcasts** and **client→server request/response**.

---

## Adding a New Remote

### RemoteEvent (fire and forget)
```lua
-- 1. Register the name in Network.Events
Network.Events.MyNewEvent = "MyNewEvent"

-- 2. Server fires
Network.getEvent(Network.Events.MyNewEvent):FireAllClients(data)
-- or FireClient(player, data)

-- 3. Client listens
Network.getEvent(Network.Events.MyNewEvent).OnClientEvent:Connect(function(data) ... end)
```

### RemoteFunction (request/response)
```lua
-- 1. Register the name in Network.Functions
Network.Functions.MyQuery = "MyQuery"

-- 2. Server handles
Network.getFunction(Network.Functions.MyQuery).OnServerInvoke = function(player, args)
    return result
end

-- 3. Client calls
local result = Network.getFunction(Network.Functions.MyQuery):InvokeServer(args)
```

---

## Current Endpoints

### RemoteEvents

| Name | Direction | Args | Description |
|------|-----------|------|-------------|
| `PlayerDataLoaded` | Server → Client | `(data: PlayerData)` | Fires once on join when data is ready |
| `PlayerDataUpdated` | Server → Client | `(patch: {})` | Fires on any session write |
| `PlotInfoUpdated` | Server → Client | `(info: {plotId})` | Fires when plot assignment changes |
| `RareNodeDiscovered` | Server → All | `(playerName, nodeId, announcement)` | Server-wide rare node alert |
| `ServerAnnouncement` | Server → All | `(message)` | Generic broadcast |
| `ResearchTierUnlocked` | Server → All | `(ownerName, tier)` | Tier unlock broadcast |
| `AscensionTriggered` | Server → All | `(ownerName, ascensionCount)` | Ascension broadcast |

### RemoteFunctions

| Name | Direction | Returns | Description |
|------|-----------|---------|-------------|
| `GetPlayerData` | Client → Server | `PlayerData?` | Pull own data on demand |
| `GetPlotInfo` | Client → Server | `{plotId: string?}` | Query own plot assignment |

---

## Security Principles

1. **Never trust args from the client** — validate all inputs server-side before acting
2. **Never return another player's full data** — `GetPlayerData` only returns the caller's session
3. **Rate-limit heavy requests** — add throttling in Milestone 4/5 as needed
4. **Server fires, client receives** — progression state changes always originate on the server

---

## Legacy: Remotes.luau

`src/shared/Remotes.luau` (created in Milestone 2) puts remotes directly in ReplicatedStorage. It is superseded by `Network.luau` which organises them under a `Network` subfolder. New systems should use `Network.luau`. The legacy module is kept for backward compatibility during the transition.
