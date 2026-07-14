# Tasks

## Active

> Vertical Slice Alpha complete (Tasks 1–10). Awaiting direction for next phase.

---

## Milestone 4 Backlog — Core Simulation (Full)

### PowerService
- [ ] Implement `GetGeneration` — sum all generator outputs on a plot
- [ ] Implement `GetDemand` — sum all powered machine draws
- [ ] Implement `TickPlot` — compare gen vs demand, fire Blackout/Restore events
- [ ] Pressure Accumulator burst discharge logic

### ResearchService
- [ ] Implement `OnPackDelivered` — advance progress, check for completion
- [ ] Implement `SetActiveResearch` — validation against prerequisites
- [ ] On completion: fire `ResearchCompleted`, call BiomeService.UnlockBiome if needed, call MachineService to unlock machines
- [ ] Fire `ResearchTierUnlocked` broadcast on main-tier completion

### BiomeService
- [ ] Implement `UnlockBiome` — update session, fire `BiomeUnlocked`
- [ ] Implement `IsTileAccessible` — check tile against unlocked biome regions

### RareNodeService
- [ ] Implement `RollNode` — MathUtil.chance per Constants, fire broadcast on rare/legendary
- [ ] Implement `SetTrophySlot` — slot bounds check, ownership validation

### DroneService
- [ ] Implement `QueueBlueprintGhost` — add to queue
- [ ] Implement `TickPlot` — assign idle drones to tasks, advance progress
- [ ] Construction drone: builds ghost → calls MachineService.PlaceMachine
- [ ] Logistic drone: moves items between logistic chests

### MachineService (full expansion)
- [ ] Implement `SpecializeMachine` — permanent, irreversible
- [ ] Implement `GetEfficiency` — power availability × input availability
- [ ] Add support for all 41 machine types (beyond lumber_mill, storage_chest, seller_station)

### ConveyorService (full expansion)
- [ ] Multi-tier belt support
- [ ] Implement `GetUtilisation` — items moved / throughput capacity

### Tests
- [ ] MachineService tick unit tests
- [ ] PowerService balance calculations
- [ ] ResearchService pack delivery and prerequisite chains
- [ ] RareNodeService roll probability sanity checks

---

## Completed

- [x] Milestone 1: Design & Spec
- [x] Milestone 2: Repository Setup & Project Structure
- [x] Milestone 3: Core Framework
- [x] VS Alpha Task 1: VSConfig + Network extensions + DataModel prep
- [x] VS Alpha Task 2: TreeService — forest spawning, per-hit harvest, regeneration
- [x] VS Alpha Task 3: MachineService — PlaceMachine, RemoveMachine, lumber mill tick, restorePlot
- [x] VS Alpha Task 4: ConveyorService — PlaceConveyor, RemoveConveyor, item routing, restoreSegments
- [x] VS Alpha Task 5: StorageService (receiveItem, 50-item cap) + SellerService (sellItem, ItemSold)
- [x] VS Alpha Task 6: SaveService integration — restore machines and conveyors from save on join
- [x] VS Alpha Task 7: BuildController (ghost preview, snap-to-grid, rotation) + InputController (raycast, R/Escape/click)
- [x] VS Alpha Task 8: CameraController — orbit, scroll zoom, WASD pan, middle-mouse drag pan
- [x] VS Alpha Task 9: UIController (4-button shop toolbar, coin display) + HUDController (floating +coins, item name)
- [x] VS Alpha Task 10: NotificationController — tree fall tween, item slide on conveyor, lumber mill blade spin
- [x] VS Alpha Task 11: Documentation update
