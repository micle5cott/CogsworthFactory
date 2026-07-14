# CogsworthFactory

**Clockpunk cozy factory automation game on Roblox.**

Build and automate a Victorian clockwork factory. Chop trees, process logs into lumber, route items on conveyor belts, store or sell products, and earn coins to expand your factory.

> **Current state:** Vertical Slice Alpha — a complete 15–20 minute gameplay loop is playable end-to-end. The full milestone roadmap (biomes, research, power, drones, ascension) is planned for post-alpha.

---

## Quick Start

### Prerequisites
- [Rojo 7.x](https://rojo.space)
- [Wally](https://wally.run)
- Roblox Studio

### Setup
```bash
# 1. Clone the repository
git clone https://github.com/micle5cott/CogsworthFactory.git
cd CogsworthFactory

# 2. Install Wally packages (creates Packages/ and DevPackages/)
wally install

# 3. Start Rojo sync
rojo serve default.project.json

# 4. Open Roblox Studio and click "Connect" in the Rojo plugin
```

> **Note:** `wally install` must run before `rojo serve`. The `Packages/` directory it creates is gitignored and must be generated locally.

### Running Tests
```bash
rojo build test.project.json --output test-place.rbxl
# Open test-place.rbxl in Studio, run tests/run_tests.server.luau
```

---

## Gameplay Loop (VS Alpha)

1. **Harvest** — A lumber mill automatically harvests nearby trees (health = 3 hits, radius = 14 studs).
2. **Process** — Logs are converted to lumber after 3 machine ticks (1 tick/sec).
3. **Transport** — Conveyor belts route lumber tile by tile (2 ticks per segment) to a destination.
4. **Store or Sell** — Storage chests hold up to 50 items. Seller stations convert items to coins.
5. **Expand** — Use coins to buy more machines and conveyors and repeat.

---

## Project Structure

```
src/
  shared/
    config/       Central configuration (VSConfig, GameConfig, EconomyConfig, SoundConfig, AnimationConfig)
    data/         Static game data (ItemData, MachineData, ResearchData, BiomeData, RareNodeData)
    utils/        Utilities (Logger, Timer, Janitor, MathUtil, Validation)
    DataModel.luau  Player data schema and migration
    Network.luau    Networking layer (RemoteEvents / RemoteFunctions)
    Types.luau      Exported Luau types
    Constants.luau  Legacy numeric constants (superseded by GameConfig)
    Remotes.luau    Legacy broadcast remotes (superseded by Network.luau)
  server/
    services/     Knit services (DataService, SaveService, PlayerService, PlotService,
                  TreeService, MachineService, ConveyorService, StorageService, SellerService, ...)
    init.server.luau  Server bootstrap
  client/
    controllers/  Knit controllers (BuildController, InputController, CameraController,
                  UIController, HUDController, NotificationController, ...)
    init.client.luau  Client bootstrap
  gui/
    MainGui/      Root ScreenGui (populated at runtime by UIController)
docs/
  specs/          Design documents
  plans/          Implementation plans
  TECHNICAL_ARCHITECTURE.md
  DATA_MODEL.md
  NETWORKING.md
tests/            TestEZ spec files mirroring src/shared/data/
```

---

## Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Luau | strict | All source files |
| Rojo | 7.x | Studio sync |
| Wally | latest | Package manager |
| Knit | 1.5.1 | Service/Controller framework |
| TestEZ | 0.4.1 | Test runner (dev) |

---

## Key Rules

- All Luau files use `--!strict`
- Item IDs, machine IDs, and research IDs are **permanent** — save data keys on them
- Server is authoritative for all progression state
- Never trust the client for counts, placement validity, or research delivery
- No hardcoded values outside config modules in `src/shared/config/`
- All DataStore access goes through `DataService` — never call DataStoreService directly

---

## Milestones

| # | Name | Status |
|---|------|--------|
| 1 | Design & Spec | Complete |
| 2 | Repository Setup & Project Structure | Complete |
| 3 | Core Framework | Complete |
| VS Alpha | Vertical Slice Alpha | **Complete** |
| 4 | Core Simulation (full) | Pending |
| 5 | UI & Client Systems (full) | Pending |
| 6 | Economy & Monetization | Pending |
| 7 | Polish & Launch | Pending |
