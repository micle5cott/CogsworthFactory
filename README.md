# CogsworthFactory

**Clockpunk cozy factory automation game on Roblox.**

Build and automate a Victorian clockwork factory across five biomes. Smelt ore, craft components, research new technologies, and ultimately trigger Ascension to restart with permanent bonuses.

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

# 2. Install Wally packages (Knit, Signal, TableUtil, TestEZ)
wally install

# 3. Start Rojo sync
rojo serve default.project.json

# 4. Open Roblox Studio and click "Connect" in the Rojo plugin
```

### Running Tests
```bash
rojo build test.project.json --output test-place.rbxl
# Open test-place.rbxl in Studio, run tests/run_tests.server.luau
```

---

## Project Structure

```
src/
  shared/
    config/       Central configuration (GameConfig, EconomyConfig, SoundConfig, AnimationConfig)
    data/         Static game data (ItemData, MachineData, ResearchData, BiomeData, RareNodeData)
    utils/        Utilities (Logger, Timer, Janitor, MathUtil, Validation)
    DataModel.luau  Player data schema and migration
    Network.luau    Networking layer (RemoteEvents / RemoteFunctions)
    Types.luau      Exported Luau types
    Constants.luau  Legacy numeric constants (superseded by GameConfig)
    Remotes.luau    Legacy broadcast remotes (superseded by Network.luau)
  server/
    services/     Knit services (DataService, SaveService, PlayerService, PlotService, ...)
    init.server.luau  Server bootstrap
  client/
    controllers/  Knit controllers (BuildController, UIController, ...)
    init.client.luau  Client bootstrap
  gui/
    MainGui/      Root ScreenGui (populated at runtime by UIController)
docs/
  specs/          Design documents
  plans/          Milestone implementation plans
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
| Signal | 1.6.0 | Typed events |
| TableUtil | 1.2.0 | Table helpers |
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
| 4 | Core Simulation | Pending |
| 5 | UI & Client Systems | Pending |
| 6 | Economy & Monetization | Pending |
| 7 | Polish & Launch | Pending |
