# Changelog

All notable changes to CogsworthFactory are documented here.

---

## [VS Alpha] — 2026-07-13 — Vertical Slice Alpha

A complete playable factory loop: Tree → Lumber Mill → Conveyor → Storage/Seller → Coins.

### Added

**Task 1 — Foundation (commit 556ead7)**
- `src/shared/config/VSConfig.luau` — all VS tuning constants (sell prices, machine shop prices, refund fraction, tree health/regen, mill ticks, storage cap, conveyor speed, visual timings)
- `src/shared/Network.luau` — 11 new broadcast events: `TreeFelled`, `TreeRegrown`, `MachinePlaced`, `MachineRemoved`, `ConveyorPlaced`, `ConveyorRemoved`, `ItemTransitStarted`, `ItemDelivered`, `ItemSold`, `StorageUpdated`, `MachineOutput`
- `src/shared/DataModel.luau` — `storageInventories: {[string]: {[string]: number}}` field added to `PlayerData` type and `default()`

### Changed (Task 1)
- `src/shared/config/GameConfig.luau` — `STARTING_COINS` raised from `0` to `200`

**Task 2 — TreeService (commit 883bb7e)**
- `src/server/services/TreeService.luau` — forest spawning (12 trees per plot) at `assignPlot`, per-hit harvest (`health = 3`), 20-second regen, `TreeFelled`/`TreeRegrown` broadcast, procedural trunk + foliage models
- `src/server/services/PlotService.luau` — calls `TreeService:spawnForest` on `assignPlot` and `TreeService:cleanupPlot` on `releasePlot`

**Task 3 — MachineService (commits 0a8b746, 868fa54)**
- `src/server/services/MachineService.luau` — full VS implementation: `PlaceMachine` (tile validation, cost deduction, session persist), `RemoveMachine` (refund, session cleanup), `tick` (lumber mill only: harvest tree → process log → output lumber after 3 ticks), `restorePlot` (rebuild state + models from save), `GetAllMachines` (client join sync), procedural models for lumber_mill / storage_chest / seller_station

**Task 4 — ConveyorService (commits ced2487, e1ce729)**
- `src/server/services/ConveyorService.luau` — full VS implementation: `PlaceConveyor` (adjacency validation, cost deduction, session persist), `RemoveConveyor` (refund, in-transit item cleanup), `tick` (pull from machine output → transit → deliver to machine/storage/seller, chain to next segment), `restoreSegments`, procedural belt Part with grid texture

**Task 5 — StorageService + SellerService (commit 5be826d)**
- `src/server/services/StorageService.luau` — `receiveItem` (50-item cap, per-instance inventory in session, `StorageUpdated` broadcast)
- `src/server/services/SellerService.luau` — `sellItem` (looks up price in VSConfig, calls `EconomyService:awardCoins`, fires `ItemSold` broadcast)

**Task 6 — SaveService Integration (commit 4aa3e78)**
- `src/server/services/SaveService.luau` — after `loadPlayer`, calls `MachineService:restorePlot` and `ConveyorService:restoreSegments` so returning players see their factory rebuilt in Workspace

**Task 7 — BuildController + InputController (commits 6f60990, 1016e7f)**
- `src/client/controllers/BuildController.luau` — ghost preview Part (snaps to tile, changes color on valid/invalid), rotation (R key, 90° steps), `confirmPlacement` (fires `PlaceMachine` RPC), conveyor chain mode (click from-tile then to-tile), ghost cleanup on cancel/Escape
- `src/client/controllers/InputController.luau` — raycast cursor (`FindPartOnRayWithIgnoreList`), `R` → rotate, `Escape` → cancel, left-click → confirm placement / set conveyor from-tile, right-click → confirm conveyor to-tile

**Task 8 — CameraController (commits dc381af, ed019d7)**
- `src/client/controllers/CameraController.luau` — `Enum.CameraType.Scriptable` orbit camera: scroll-wheel zoom (5 studs/tick, 15–150 stud range), WASD + arrow key pan (speed scales with zoom), middle-mouse drag pan (delta translated along world-space right/forward vectors), pitch clamped to −80°…−15°

**Task 9 — UIController + HUDController (commits 2b5775a, 0c1ac29)**
- `src/client/controllers/UIController.luau` — 4-button shop toolbar at bottom of screen (Lumber Mill/$0, Storage Chest/$25, Seller Station/$50, Conveyor/$5), top-left coin label updated via `BalanceUpdated` proxy signal, top-center hint label
- `src/client/controllers/HUDController.luau` — subscribes to `ItemSold` (floating "+N coins" BillboardGui at seller world position) and `ItemDelivered` (floating item name at destination tile); text rises `FLOATING_TEXT_RISE_STUDS` studs over `FLOATING_TEXT_DURATION` seconds then fades and destroys

**Task 10 — NotificationController (commit 4b7c3c4)**
- `src/client/controllers/NotificationController.luau` — tree fall animation (90° X-axis tween + fade on `TreeFelled`, reverse on `TreeRegrown`), item transit visual (colored sliding Part with PointLight tweened from/to tile positions on `ItemTransitStarted`), lumber mill blade spin (360° Z-axis tween on `MachineOutput`, cached per `instanceId`)

---

## [Milestone 3] — 2026-07-13 — Core Framework

### Added
- `src/shared/utils/Logger.luau` — named, levelled logger (INFO/WARN/ERROR/DEBUG); debug mode togglable at runtime
- `src/shared/utils/Timer.luau` — repeating/one-shot timer backed by `task.spawn`
- `src/shared/utils/Janitor.luau` — maid-pattern cleanup for instances, connections, functions, threads
- `src/shared/utils/MathUtil.luau` — clamp, lerp, round, remap, chance, weightedRandom, sum
- `src/shared/utils/Validation.luau` — non-empty string, range, isOneOf, hasKeys, assertServer, positiveAmount
- `src/shared/config/GameConfig.luau` — single source of truth for all numeric tuning values
- `src/shared/config/EconomyConfig.luau` — machine prices, multipliers, unlock costs
- `src/shared/config/SoundConfig.luau` — sound asset IDs and volumes (placeholders)
- `src/shared/config/AnimationConfig.luau` — animation IDs and UI tween timings (placeholders)
- `src/shared/DataModel.luau` — versioned PlayerData schema with `default()`, `migrate()`, `applyDefaults()`
- `src/shared/Network.luau` — centralized RemoteEvent/Function registry with named endpoints
- `src/server/services/DataService.luau` — DataStore wrapper with retry logic and pcall safety
- `src/server/services/PlayerService.luau` — player join/leave lifecycle, session orchestration
- `src/server/services/LoggingService.luau` — applies GameConfig.DEBUG_LOGGING on startup
- `src/server/services/WorldService.luau` — tile grid helpers (snapToTile, tileToWorld, worldToTile)
- `src/server/services/EconomyService.luau` — awardCoins, deductCoins, awardPremiumCoins
- `README.md` — project overview, setup instructions, structure guide
- `docs/TECHNICAL_ARCHITECTURE.md` — layer diagram, module responsibilities, data flow, security model
- `docs/DATA_MODEL.md` — full PlayerData schema, migration guide, DataStore key format
- `docs/NETWORKING.md` — endpoint registry, security principles, how to add new remotes
- `CHANGELOG.md`, `ROADMAP.md`, `TASKS.md`, `MILESTONE_REPORT.md`

### Changed
- `src/server/services/SaveService.luau` — full implementation: session cache, autosave loop, save-on-leave, server shutdown flush, PlayerDataLoaded/Updated events
- `src/server/services/PlotService.luau` — added `assignPlot`, `releasePlot`, `getPlotId`, role rank ordering, GetPlotInfo RemoteFunction

---

## [Milestone 2] — 2026-07-13 — Repository Setup & Project Structure

### Added
- Rojo project files (`default.project.json`, `test.project.json`)
- Wally configuration (`wally.toml`)
- `src/shared/Types.luau` — all exported Luau types
- `src/shared/Constants.luau` — global numeric constants
- `src/shared/data/ItemData.luau` — 50 items across 6 tiers
- `src/shared/data/MachineData.luau` — 41 machines across 6 tiers
- `src/shared/data/ResearchData.luau` — 23 research nodes (5 main + 18 side branches)
- `src/shared/data/BiomeData.luau` — 5 biomes with node lists and geographic features
- `src/shared/data/RareNodeData.luau` — 10 rare nodes (3 legendary, 6 rare, 1 uncommon)
- `src/shared/Remotes.luau` — legacy broadcast RemoteEvents
- `tests/` — TestEZ specs for ItemData, MachineData, ResearchData, BiomeData/RareNodeData
- `tests/run_tests.server.luau` — TestEZ bootstrap runner
- 9 Knit service stubs in `src/server/services/`
- 5 Knit controller stubs in `src/client/controllers/`
- `src/client/init.client.luau`, `src/server/init.server.luau`
- Design spec and Milestone 2 plan in `docs/`

---

## [Milestone 1] — 2026-07-13 — Design & Spec

### Added
- Full game design document: `docs/superpowers/specs/2026-07-13-cogsworth-factory-design.md`
