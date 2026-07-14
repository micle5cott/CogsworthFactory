# Tasks

## Active

> Milestone 3 complete. Awaiting Milestone 4 approval.

---

## Milestone 4 Backlog — Core Simulation

### MachineService
- [ ] Implement `PlaceMachine` — tile validation, build cost deduction, instance creation
- [ ] Implement `RemoveMachine` — refund materials, cleanup
- [ ] Implement `SpecializeMachine` — permanent, irreversible
- [ ] Implement `Tick` — consume inputBuffer, advance outputBuffer at efficiency %
- [ ] Implement `GetEfficiency` — power availability × input availability
- [ ] Write MachineService TestEZ specs

### ConveyorService
- [ ] Implement `PlaceSegment` — tile adjacency validation, cost deduction
- [ ] Implement `RemoveSegment` — refund, disconnect routing
- [ ] Implement `TickPlot` — move items from machine output → conveyor → machine input
- [ ] Implement `GetUtilisation` — items moved / throughput capacity

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

### SaveService integration
- [ ] Persist and restore full MachineInstance + ConveyorSegment arrays
- [ ] Restore machines on plot load (spawn models in world)

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
