# Milestone Reports

---

## Milestone 3 — Core Framework

**Completed:** 2026-07-13
**Commit:** (see git log)

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

### Recommendations for Milestone 4

1. Implement `MachineService.Tick` and `ConveyorService.TickPlot` first — they're the critical path for the simulation loop.
2. Wire `PowerService.TickPlot` into the server loop early; blackout mechanics affect every other system.
3. Add a server loop script (`src/server/loop.server.luau`) that runs `RunService.Heartbeat` and dispatches ticks to all simulation services at the correct Hz values defined in `GameConfig`.
4. Write TestEZ specs alongside each service implementation — the existing spec pattern (`describe` → `it`) is established and works.

---

## Milestone 2 — Repository Setup & Project Structure

**Completed:** 2026-07-13

Built the complete project scaffold: Rojo/Wally config, all shared data modules (50 items, 41 machines, 23 research nodes, 5 biomes, 10 rare nodes), TestEZ specs, Knit service and controller stubs, server/client bootstrap, design spec and milestone plan committed to `docs/`.

Tagged: `milestone-2`

---

## Milestone 1 — Design & Spec

**Completed:** 2026-07-13

Full game design document authored covering all systems: 6 tiers of machines, 5 biomes, research tree, power grid, drone network, rare nodes, co-op, ascension, blueprint system, monetization, and engineering constraints.
