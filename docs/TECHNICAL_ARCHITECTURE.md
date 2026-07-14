# Technical Architecture

## Overview

CogsworthFactory uses a **server-authoritative, service-oriented architecture** built on the Knit framework. All game state lives on the server; the client is a thin presentation layer that displays state and submits requests.

---

## Layer Diagram

```
┌─────────────────────────────────────────────────┐
│                  CLIENT SIDE                    │
│  Controllers (Knit)  ←→  UI / Input / Visuals   │
└────────────────────┬────────────────────────────┘
                     │ RemoteEvents / RemoteFunctions
                     │ (via Network.luau)
┌────────────────────▼────────────────────────────┐
│                  SERVER SIDE                    │
│  Services (Knit)  ←→  Game Logic / Validation  │
│  DataService      ←→  Roblox DataStoreService   │
└─────────────────────────────────────────────────┘
```

---

## Module Responsibilities

### Shared

| Module | Role |
|--------|------|
| `config/GameConfig` | All tunable numeric values |
| `config/EconomyConfig` | Shop prices, multipliers |
| `config/SoundConfig` | Sound asset IDs and volumes |
| `config/AnimationConfig` | Animation IDs and UI timings |
| `data/ItemData` | Static item definitions |
| `data/MachineData` | Static machine definitions |
| `data/ResearchData` | Research tree |
| `data/BiomeData` | Biome definitions |
| `data/RareNodeData` | Rare node drop table |
| `utils/Logger` | Named, levelled logging |
| `utils/Timer` | Repeating / one-shot timers |
| `utils/Janitor` | Connection/instance cleanup |
| `utils/MathUtil` | Pure math helpers |
| `utils/Validation` | Input guards for service boundaries |
| `DataModel` | PlayerData schema, defaults, migrations |
| `Network` | RemoteEvent/Function registry |
| `Types` | Luau type exports |

### Server Services

| Service | Role |
|---------|------|
| `LoggingService` | Configure Logger; runtime debug toggle |
| `DataService` | DataStore I/O with retries |
| `SaveService` | Session cache, autosave, load/save lifecycle |
| `PlayerService` | Join/leave orchestration |
| `PlotService` | Plot assignment, ownership, co-op roles |
| `EconomyService` | Coin transactions (server-authoritative) |
| `WorldService` | Tile grid, biome region queries |
| `MachineService` | Placement, removal, efficiency (M4) |
| `ConveyorService` | Conveyor segments, transport tick (M4) |
| `PowerService` | Grid balance, blackout events (M4) |
| `ResearchService` | Pack delivery, tier unlock (M4) |
| `BiomeService` | Biome unlock state, node placement (M4) |
| `DroneService` | Task queue, drone assignment (M4) |
| `RareNodeService` | Rare roll, trophy case (M4) |

### Client Controllers

| Controller | Role |
|-----------|------|
| `BuildController` | Ghost preview, placement, rotation (M5) |
| `UIController` | HUD, toolbar, overlays (M5) |
| `InputController` | Mouse/keyboard → game actions (M5) |
| `DroneController` | Drone visual interpolation (M5) |
| `NotificationController` | Announcement banners, hints (M5) |

---

## Data Flow: Player Join

```
PlayerAdded
  → PlayerService.onPlayerAdded
    → SaveService.loadPlayer
      → DataService.load (DataStore)
      → DataModel.migrate + applyDefaults
      → cache in _sessions
      → Network.PlayerDataLoaded → client
    → PlotService.assignPlot
      → Network.PlotInfoUpdated → client
    → PlayerService.Client.SessionReady → client
```

## Data Flow: Autosave

```
task.wait(AUTOSAVE_INTERVAL_SECONDS)
  → SaveService autosave loop
    → for each Player:
        SaveService.savePlayer
          → DataService.save (DataStore, with retries)
```

---

## Knit Startup Sequence

Knit calls `KnitInit` on all services before calling `KnitStart` on any. This means:

1. `LoggingService.KnitInit` — sets debug flag from GameConfig
2. `DataService.KnitInit` — opens DataStore handle
3. All other `KnitInit` calls complete
4. `SaveService.KnitStart` — starts autosave loop, connects PlayerRemoving
5. `PlayerService.KnitStart` — connects PlayerAdded, handles late-join players
6. All other `KnitStart` calls complete

Because `Knit.AddServicesDeep` auto-discovers all files in `src/server/services/`, adding a new service file is sufficient — no bootstrap changes needed.

---

## Security Model

- **Client is untrusted**: all player inputs are validated server-side before mutating state
- **Server-authoritative**: coin balances, item counts, research progress, plot state all live in `_sessions` on the server
- **No client-side state for progression**: the client receives read-only data via RemoteEvents; it never writes directly to a DataStore
- **RemoteFunction responses**: server returns only what the client needs; no raw PlayerData dumps except `GetPlayerData` (authenticated by Roblox's player identity)
