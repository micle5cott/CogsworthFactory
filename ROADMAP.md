# Roadmap

## Milestone 1 — Design & Spec ✅
Full game design document covering all systems, economies, biomes, machines, research, rare nodes, drones, and ascension.

## Milestone 2 — Repository Setup & Project Structure ✅
Rojo/Wally config, all shared data modules, typed service/controller stubs, TestEZ specs for all data modules.

## Milestone 3 — Core Framework ✅
Utility library, configuration modules, player data model, production-ready save framework, networking layer, service layer (PlayerService, DataService, SaveService, PlotService, EconomyService, WorldService, LoggingService), full documentation suite.

## Vertical Slice Alpha ✅
A complete, playable factory loop built across Tasks 1–10. Includes all server services, client controllers, and visual effects needed for the Tree → Lumber Mill → Conveyor → Storage/Seller → Coins loop.

**Services implemented:** VSConfig, extended Network (11 new events), DataModel update, TreeService, MachineService, ConveyorService, StorageService, SellerService, SaveService integration.

**Controllers implemented:** BuildController (ghost preview, snap-to-grid, rotation), InputController (raycast cursor, R/Escape/click), CameraController (orbit, scroll zoom, WASD pan, middle-mouse pan), UIController (4-button shop toolbar, coin display), HUDController (floating +coins on sell, item name on deliver), NotificationController (tree fall tween, belt item slide, lumber mill blade spin).

---

## Milestone 4 — Core Simulation (Full)
Expand simulation beyond the VS alpha to include the complete system set:
- PowerService: grid calculation, blackout events, Pressure Accumulator burst discharge
- ResearchService: pack delivery, tier unlock, biome unlock
- BiomeService: biome unlock state, node placement
- RareNodeService: rare roll on miner placement, trophy case
- DroneService: task queue, construction/logistic drones
- Full MachineService: all 41 machine types, specialization, efficiency tick
- Full ConveyorService: multi-tier belts, throughput metrics
- SaveService: persist/restore full plot state for all new systems
- TestEZ specs for all simulation logic

## Milestone 5 — UI & Client Systems (Full)
- Power bar, efficiency overlays, research progress HUD
- Notification system: rare node banners, tier unlock banners, hints
- Trophy Case display
- Drone visual interpolation on the client
- Co-op UI: invite/kick flow, role badge
- Settings panel: volume sliders, overlay toggles

## Milestone 6 — Economy & Monetization
- Premium coin shop (Roblox Developer Products)
- Blueprint save/load UI
- Ascension flow: activation sequence, reset, permanent unlock shop

## Milestone 7 — Polish & Launch
- Biome terrain models in Roblox Studio
- Machine 3D models and animations (replace procedural Parts)
- Sound design integration (real asset IDs in SoundConfig)
- Achievement system
- Tutorial (Automaton Companion hints)
- Performance profiling
- Closed beta → launch
