# CogsworthFactory

Clockpunk cozy factory automation game on Roblox.

## Design Source of Truth
`docs/superpowers/specs/2026-07-13-cogsworth-factory-design.md` — read this before changing any gameplay numbers or system behavior.

## Stack
- Luau strict mode throughout (`--!strict` on every file)
- Rojo 7.x for Studio sync: `rojo serve` then connect in Studio
- Wally for packages: `wally install` after cloning
- Knit framework: services on server, controllers on client
- TestEZ for specs in `tests/` folder

## Key Rules
- Item IDs, machine IDs, and research IDs are **permanent** — save data keys on them
- Server is authoritative for all progression state (items, research, ascension)
- Never trust the client for counts or validity checks
- All machine stats live in `src/shared/data/MachineData.luau` — single source of truth
- Power draw is in PU (Power Units); generators produce PU; consumers draw PU

## Directory Layout
- `src/server/services/` — Knit services (server-only logic)
- `src/client/controllers/` — Knit controllers (client-only logic)
- `src/shared/data/` — static game data (machines, items, research, biomes, rare nodes)
- `src/shared/Types.luau` — all exported Luau types
- `src/shared/Constants.luau` — global numeric constants
- `src/shared/Remotes.luau` — non-Knit RemoteEvents (broadcast announcements)
- `tests/` — TestEZ spec files mirroring src/ structure

## Running Tests
1. `wally install` (first time)
2. `rojo build test.project.json --output test-place.rbxl`
3. Open `test-place.rbxl` in Roblox Studio
4. Run `tests/run_tests.server.luau` via Studio Command Bar or as a Script

## Service → System Mapping
| Service | Responsibility |
|---|---|
| MachineService | Placement, removal, efficiency %, specialization |
| ConveyorService | Item transport, throughput batching |
| PowerService | Grid calculation, blackout events |
| ResearchService | Pack delivery, tier unlock |
| BiomeService | Biome unlock, node management |
| DroneService | Drone network, logistic/construction tasks |
| RareNodeService | Rare spawn rolls, server announcements, trophy data |
| SaveService | Serialize/deserialize full plot state to DataStore |
| PlotService | Plot ownership, co-op permissions |
