# Roadmap

## Milestone 1 — Design & Spec ✅
Full game design document covering all systems, economies, biomes, machines, research, rare nodes, drones, and ascension.

## Milestone 2 — Repository Setup & Project Structure ✅
Rojo/Wally config, all shared data modules, typed service/controller stubs, TestEZ specs for all data modules.

## Milestone 3 — Core Framework ✅
Utility library, configuration modules, player data model, production-ready save framework, networking layer, service layer (PlayerService, DataService, SaveService, PlotService, EconomyService, WorldService, LoggingService), full documentation suite.

---

## Milestone 4 — Core Simulation
Implement all Knit service bodies:
- MachineService: placement, removal, efficiency tick, specialization
- ConveyorService: segment placement, batched item transport
- PowerService: grid calculation, blackout events
- ResearchService: pack delivery, tier unlock, biome unlock
- BiomeService: biome unlock state, node placement
- RareNodeService: rare roll on miner placement, trophy case
- DroneService: task queue, construction/logistic drones
- SaveService integration: persist/restore full plot state
- TestEZ specs for all simulation logic

## Milestone 5 — UI & Client Systems
- Build mode: ghost preview, click-to-place, rotation, conveyor chaining
- HUD: toolbar, power bar, efficiency overlays, research progress
- Notification system: rare node banners, tier unlock banners, hints
- Trophy Case display
- Drone visual interpolation on the client
- Co-op UI: invite/kick flow, role badge
- Settings panel: volume sliders, overlay toggles

## Milestone 6 — Economy & Monetization
- Machine shop with coin prices
- Premium coin shop (Roblox Developer Products)
- Blueprint save/load UI
- Ascension flow: activation sequence, reset, permanent unlock shop

## Milestone 7 — Polish & Launch
- Biome terrain models in Roblox Studio
- Machine 3D models and animations
- Sound design integration
- Achievement system
- Tutorial (Automaton Companion hints)
- Performance profiling
- Closed beta → launch
