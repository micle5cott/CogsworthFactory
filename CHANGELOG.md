# Changelog

All notable changes to CogsworthFactory are documented here.

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
