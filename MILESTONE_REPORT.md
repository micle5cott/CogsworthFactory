# Milestone Reports

---

## Vertical Slice Alpha

**Completed:** 2026-07-13
**Commits:** `556ead7` (Task 1) through `4b7c3c4` (Task 10)
**Base:** `a4c7b44` (Milestone 3)

### What Was Built

The VS Alpha delivers a complete, playable factory automation loop built across 10 implementation tasks. All server logic is authoritative. Clients receive broadcast events and render visuals independently. All machine models are procedural Parts — no Studio work required.

#### Gameplay Loop

Tree → hit tree 3 times → log drops → lumber mill converts log → conveyor belt moves lumber → storage chest holds it → seller station sells it → coins → buy more machines → repeat.

#### Server Services

| Service | Key Functions | Notes |
|---------|--------------|-------|
| `VSConfig` | All tuning constants | Economy, trees, machines, visual timings |
| `TreeService` | `spawnForest`, `harvestNearestTree`, `cleanupPlot` | 12 trees per plot, health = 3, 20s regen |
| `MachineService` | `PlaceMachine`, `RemoveMachine`, `tick`, `restorePlot` | lumber_mill only ticks; storage_chest and seller_station are passive |
| `ConveyorService` | `PlaceConveyor`, `RemoveConveyor`, `tick`, `restoreSegments` | Adjacent-tile only; 1 item per segment in transit at a time |
| `StorageService` | `receiveItem` | 50-item cap, per-instance inventory in save data |
| `SellerService` | `sellItem` | Prices from VSConfig; fires `ItemSold` broadcast |
| `SaveService` | restore on join | `restorePlot` + `restoreSegments` called after `loadPlayer` |

**Network — 11 new VS broadcast events:**
`TreeFelled`, `TreeRegrown`, `MachinePlaced`, `MachineRemoved`, `ConveyorPlaced`, `ConveyorRemoved`, `ItemTransitStarted`, `ItemDelivered`, `ItemSold`, `StorageUpdated`, `MachineOutput`

**DataModel changes:**
- `storageInventories: {[string]: {[string]: number}}` added to `PlayerData`
- `GameConfig.STARTING_COINS` raised to `200`

#### Client Controllers

| Controller | Key Behavior |
|-----------|-------------|
| `BuildController` | Ghost preview Part, snap-to-grid, R to rotate (90° steps), left-click to place, conveyor chain mode (click from → click to), Escape to cancel |
| `InputController` | Raycast cursor via `FindPartOnRayWithIgnoreList`, wires R/Escape/click to BuildController |
| `CameraController` | Scriptable orbit camera; scroll zoom (15–150 studs); WASD + arrow key pan; middle-mouse drag pan; pitch clamped −80°…−15° |
| `UIController` | 4-button shop toolbar (Lumber Mill/$0, Storage Chest/$25, Seller Station/$50, Conveyor/$5), coin label, hint label |
| `HUDController` | Floating "+N coins" text on `ItemSold`; floating item name on `ItemDelivered`; BillboardGui on Part, rises and fades |
| `NotificationController` | Tree fall tween (90° X-axis + fade) on `TreeFelled`/`TreeRegrown`; sliding colored Part with PointLight on `ItemTransitStarted`; 360° blade spin tween on `MachineOutput` |

### Architectural Decisions

1. **VSConfig as the single tuning knob.** All numeric values for the VS loop (prices, timings, capacities) live in `src/shared/config/VSConfig.luau`. Nothing is hardcoded in service bodies.

2. **Procedural models only.** All machines and conveyors are built from Instance.new calls at runtime. No Roblox Studio asset work required to run the alpha.

3. **In-transit items are transient.** Items in flight on conveyors are not saved. Only placed machines and conveyors are persisted; transit restarts fresh on rejoin.

4. **1 item per segment per tick.** ConveyorService enforces a maximum of one in-transit item per segment at a time, keeping routing logic simple and deterministic for the VS.

5. **Server fires MachinePlaced on restore.** When `restorePlot` rebuilds machines from save data, it fires `MachinePlaced` to all clients so the client-side visual layer (NotificationController blade caching, etc.) receives the same signal as a fresh placement.

### Known VS-Acceptable Limitations

- **MachinePlaced race on high latency:** The server fires `MachinePlaced` immediately, but the Workspace model may not have replicated to the client yet when `NotificationController` tries to cache the blade Part. A `task.wait()` or `WaitForChild` can fix this before public launch.
- **ConveyorPlaced/ConveyorRemoved not wired in NotificationController:** The brief does not require visual effects for conveyor placement; the belt Part itself is replicated by the server. This is correct for VS scope.
- **restorePlot has no player argument:** `MachineService:restorePlot` takes only the saved machine array. For VS single-player this is fine; multi-player support would require passing a `plotOwnerId` to scope restoration correctly.
- **Items fall off unconnected conveyor ends:** If a conveyor ends at an empty tile with no machine or continuation, the item is silently dropped. Acceptable for VS; a warning or bounce-back is post-alpha work.

### Recommendations for Milestone 4

1. Implement `PowerService.TickPlot` first — blackout mechanics will affect every other service.
2. Expand `MachineService` to support all 41 machine types using a dispatch table keyed on `machineId`.
3. Add a server-side loop script (`src/server/loop.server.luau`) that manages a single `RunService.Heartbeat` and dispatches ticks to all simulation services at configured Hz values, rather than each service spawning its own loop.
4. Add session locking to `SaveService` before production launch to prevent double-load on server crash.
5. Replace procedural Part models with Studio-authored models before Milestone 7 polish.

---

## Milestone 3 — Core Framework

**Completed:** 2026-07-13
**Commit:** (see git log — `a4c7b44`)

### What Was Built

#### Utility Library (`src/shared/utils/`)
Five production-ready utilities consumed by all services:
- **Logger** — named per-module, four log levels (INFO/WARN/ERROR/DEBUG), debug globally toggleable at runtime by `LoggingService`
- **Timer** — repeating or one-shot, backed by `task.spawn` with clean cancel via `task.cancel`
- **Janitor** — maid-pattern cleanup tracking Instances, RBXScriptConnections, functions, and threads
- **MathUtil** — clamp, lerp, round, remap, chance, weightedRandom, sum
- **Validation** — input guards for service boundaries: non-empty strings, range checks, set membership, required keys, server assertion, positive amount

#### Configuration Layer (`src/shared/config/`)
All hardcoded values removed from service logic and centralised:
- **GameConfig** — DataStore name, retry settings, tick rates, plot dimensions, power/drone/ascension constants, rare node chances
- **EconomyConfig** — machine shop prices, specialization cost multiplier, blueprint slot cost, trophy unlock cost
- **SoundConfig** — all sound asset IDs (placeholders) and volume levels
- **AnimationConfig** — all animation asset IDs (placeholders) and UI tween durations

#### Player Data Model (`src/shared/DataModel.luau`)
Full versioned schema for every field that touches a DataStore:
- 13 top-level keys: `_version`, `currency`, `inventory`, `plot`, `research`, `unlocks`, `statistics`, `settings`, `achievements`, `blueprints`, `ascension`, `coop`
- `DataModel.default()` — factory for new players
- `DataModel.migrate(raw)` — version-by-version upgrade path
- `DataModel.applyDefaults(data)` — backfills nil fields without a version bump

#### Networking Layer (`src/shared/Network.luau`)
Replaces ad-hoc `Remotes.luau` with a structured registry:
- Server creates; client waits (10-second timeout)
- Named endpoint tables (`Network.Events`, `Network.Functions`) make all remotes discoverable in one file
- 7 events, 2 functions registered for Milestone 3; adding more requires one line

#### Service Layer

| Service | What's real | What's stubbed |
|---------|-------------|----------------|
| `DataService` | DataStore load/save/update/remove with 3-attempt retry and exponential backoff | — |
| `SaveService` | Session cache, load-on-join, autosave loop (60s), save-on-leave, server shutdown flush, migration, PlayerDataLoaded/Updated events | — |
| `PlayerService` | PlayerAdded/Removing wiring, data load orchestration, GetPlayerData RemoteFunction | — |
| `LoggingService` | Logger configuration on KnitInit, runtime setDebug | — |
| `PlotService` | assignPlot/releasePlot, GetRole with ROLE_RANK ordering, HasPermission, InviteMember (3-member cap), RemoveMember, GetPlotInfo RemoteFunction | Physical plot spawning (M4) |
| `EconomyService` | awardCoins, deductCoins (with balance check), awardPremiumCoins, BalanceUpdated signal | Shop purchases (M4) |
| `WorldService` | snapToTile, tileToWorld, worldToTile | getBiomeAtPosition (M4) |

#### Documentation
- `README.md` — setup, structure, tech stack, key rules, milestones
- `docs/TECHNICAL_ARCHITECTURE.md` — layer diagram, module table, data flow sequences, Knit startup order, security model
- `docs/DATA_MODEL.md` — full schema tree, new-player defaults, migration guide, DataStore key format
- `docs/NETWORKING.md` — all endpoints, how to add new ones, security principles, legacy note
- `CHANGELOG.md` — full history from M1
- `ROADMAP.md` — all 7 milestones with scope
- `TASKS.md` — M4 backlog broken down by service

### Architectural Decisions

1. **DataService is the only DataStore caller.** All other services call `DataService:load/save/update/remove`. This means retry logic, error handling, and budget tracking live in one place.

2. **Session cache in SaveService.** `_sessions` is the single in-memory truth for player data during a session. Services that need player data call `SaveService:getSession()` — no duplicated tables, no synchronization issues.

3. **Network.luau over Remotes.luau.** Named endpoint tables prevent magic-string errors and make the full remote surface discoverable in one file.

4. **Migrations are additive-first.** `applyDefaults` handles most additions without a version bump; `migrate` is reserved for breaking changes. This keeps the migration table lean.

5. **KnitInit vs KnitStart ordering.** `LoggingService.KnitInit` sets the debug flag before any service's `KnitStart` logs anything. `DataService.KnitInit` opens the DataStore handle before `SaveService.KnitStart` begins its autosave loop.

### Remaining Risks

- **DataStore budget exhaustion** — with many concurrent players, autosave calls may exceed the DataStore request budget. Milestone 4 should add budget monitoring via `DataStoreService:GetRequestBudgetForRequestType`.
- **No session locking** — if the server shuts down abnormally mid-save, a player could theoretically rejoin another server before the save completes. Standard ProfileService-style session locking should be added before production launch.
- **Sound/Animation placeholders** — all asset IDs in SoundConfig and AnimationConfig are `0` (no-op). Real assets must be uploaded before Milestone 5.

---

## Milestone 2 — Repository Setup & Project Structure

**Completed:** 2026-07-13

Built the complete project scaffold: Rojo/Wally config, all shared data modules (50 items, 41 machines, 23 research nodes, 5 biomes, 10 rare nodes), TestEZ specs, Knit service and controller stubs, server/client bootstrap, design spec and milestone plan committed to `docs/`.

Tagged: `milestone-2`

---

## Milestone 1 — Design & Spec

**Completed:** 2026-07-13

Full game design document authored covering all systems: 6 tiers of machines, 5 biomes, research tree, power grid, drone network, rare nodes, co-op, ascension, blueprint system, monetization, and engineering constraints.
