# Milestone 2: Repository Setup & Project Structure

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a fully structured Roblox Luau repository with Rojo/Wally config, all shared data modules, typed service/controller stubs, and data-validation test specs — so Milestone 3 (core simulation logic) can begin with zero scaffolding work.

**Architecture:** Server-authoritative Roblox game using the Knit framework for service/controller organization. All game data (machines, items, research, biomes, rare nodes) lives in typed shared data modules under `src/shared/data/`. Server logic goes in `src/server/services/`, client logic in `src/client/controllers/`. Rojo maps these directories to the correct Roblox services.

**Tech Stack:** Luau (strict mode), Rojo 7.x, Wally, Knit 1.5, TestEZ 0.4 (dev), luau-lsp (optional, for local type checking)

## Global Constraints

- All Luau files start with `--!strict`
- Item IDs are snake_case strings — never change them once defined (save data depends on them)
- Machine IDs are snake_case strings — same constraint
- Research IDs are snake_case strings — same constraint
- Never trust the client for item counts, placement validity, or research delivery (see design doc §17)
- Max 10-item input/output buffer per machine (configurable via Constants)
- The design document is the authoritative source of truth: `docs/superpowers/specs/2026-07-13-cogsworth-factory-design.md`

---

### Task 1: Git + Rojo + Wally + CLAUDE.md

**Files:**
- Create: `.gitignore`
- Create: `.gitattributes`
- Create: `default.project.json`
- Create: `test.project.json`
- Create: `wally.toml`
- Create: `CLAUDE.md`

**Interfaces:**
- Produces: a buildable Rojo project (`rojo build default.project.json` exits 0)

- [ ] **Step 1: Init git repo**

```bash
cd "C:/Users/mille/documents/CogsworthFactory"
git init
```

Expected: `Initialized empty Git repository in .../CogsworthFactory/.git/`

- [ ] **Step 2: Create .gitignore**

```
# Roblox build outputs
*.rbxl
*.rbxlx
*.rbxm
*.rbxmx

# Wally packages (like node_modules)
packages/
dev-packages/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/settings.json
.idea/

# Rojo generated
sourcemap.json
```

- [ ] **Step 3: Create .gitattributes**

```
* text=auto eol=lf
*.luau text eol=lf
*.lua  text eol=lf
*.json text eol=lf
*.toml text eol=lf
*.md   text eol=lf
```

- [ ] **Step 4: Create default.project.json**

```json
{
  "name": "CogsworthFactory",
  "tree": {
    "$className": "DataModel",

    "ServerScriptService": {
      "$className": "ServerScriptService",
      "Server": {
        "$path": "src/server"
      }
    },

    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Shared": {
        "$path": "src/shared"
      },
      "Packages": {
        "$path": "packages"
      }
    },

    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "Client": {
          "$path": "src/client"
        }
      }
    },

    "StarterGui": {
      "$className": "StarterGui",
      "MainGui": {
        "$path": "src/gui/MainGui"
      }
    }
  }
}
```

- [ ] **Step 5: Create test.project.json**

```json
{
  "name": "CogsworthFactory-Tests",
  "tree": {
    "$className": "DataModel",

    "ServerScriptService": {
      "$className": "ServerScriptService",
      "Server": { "$path": "src/server" },
      "Tests": { "$path": "tests" }
    },

    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Shared": { "$path": "src/shared" },
      "Packages": { "$path": "packages" },
      "DevPackages": { "$path": "dev-packages" }
    },

    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "Client": { "$path": "src/client" }
      }
    },

    "StarterGui": {
      "$className": "StarterGui",
      "MainGui": { "$path": "src/gui/MainGui" }
    }
  }
}
```

- [ ] **Step 6: Create wally.toml**

```toml
[package]
name = "cogsworth/factory"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
Knit      = "sleitnick/knit@1.5.1"
Signal    = "sleitnick/signal@1.6.0"
TableUtil = "sleitnick/tableutil@1.2.0"

[dev-dependencies]
TestEZ = "roblox/testez@0.4.1"
```

- [ ] **Step 7: Create CLAUDE.md**

```markdown
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
```

- [ ] **Step 8: Create all source directories**

```bash
mkdir -p "C:/Users/mille/documents/CogsworthFactory/src/server/services"
mkdir -p "C:/Users/mille/documents/CogsworthFactory/src/client/controllers"
mkdir -p "C:/Users/mille/documents/CogsworthFactory/src/shared/data"
mkdir -p "C:/Users/mille/documents/CogsworthFactory/src/gui/MainGui"
mkdir -p "C:/Users/mille/documents/CogsworthFactory/tests/shared/data"
```

- [ ] **Step 9: Install Wally packages**

```bash
cd "C:/Users/mille/documents/CogsworthFactory"
wally install
```

Expected: `packages/` and `dev-packages/` directories created with Knit, Signal, TableUtil, TestEZ.

- [ ] **Step 10: Verify Rojo build**

```bash
rojo build default.project.json --output build-check.rbxl
```

Expected: exits 0, produces `build-check.rbxl`. Delete it after.

- [ ] **Step 11: Initial commit**

```bash
git add .gitignore .gitattributes default.project.json test.project.json wally.toml wally.lock CLAUDE.md
git commit -m "chore: repo setup — rojo, wally, gitignore, CLAUDE.md"
```

---

### Task 2: Types & Constants

**Files:**
- Create: `src/shared/Types.luau`
- Create: `src/shared/Constants.luau`

**Interfaces:**
- Produces: `Types.MachineInstance`, `Types.PlotState`, `Types.TilePosition`, `Types.ItemStack` — used by every service and data module in later tasks

- [ ] **Step 1: Create src/shared/Types.luau**

```lua
--!strict

export type ItemId = string
export type MachineId = string
export type InstanceId = string -- unique per placed machine
export type PlayerId = number
export type BiomeId = string
export type ResearchId = string

export type TilePosition = {
    x: number,
    z: number,
}

export type ItemStack = {
    itemId: ItemId,
    count: number,
}

export type MachineInstance = {
    instanceId: InstanceId,
    machineId: MachineId,
    position: TilePosition,
    rotation: number,            -- 0 | 90 | 180 | 270
    specialization: string?,     -- nil until specialized (permanent after)
    efficiency: number,          -- 0–100
    inputBuffer: {ItemStack},
    outputBuffer: {ItemStack},
    recipe: {inputItemId: ItemId, outputItemId: ItemId}?, -- for assemblers with variable recipes
}

export type ConveyorSegment = {
    segmentId: string,
    tier: number,                -- 1–5
    fromPosition: TilePosition,
    toPosition: TilePosition,
}

export type DroneTask =
    | { kind: "logistic"; fromChestId: string; toChestId: string; itemId: ItemId; count: number }
    | { kind: "construct"; blueprintGhostId: string; machineId: MachineId; position: TilePosition; rotation: number }
    | { kind: "deconstruct"; instanceId: InstanceId; returnChestId: string }

export type CoopRole = "visitor" | "builder" | "co_owner" | "owner"

export type CoopMember = {
    playerId: PlayerId,
    role: CoopRole,
}

export type PlotState = {
    ownerId: PlayerId,
    machines: {MachineInstance},
    conveyors: {ConveyorSegment},
    researchProgress: {[ResearchId]: number},
    completedResearch: {ResearchId},
    unlockedTiers: {number},
    unlockedBiomes: {BiomeId},
    ascensionCount: number,
    ascensionUnlocks: {string},
    trophyCaseItems: {ItemId?},  -- exactly 9 slots; nil = empty
    coopMembers: {CoopMember},
    powerBalance: number,        -- positive = surplus, negative = deficit
}

export type RareNodeRoll = {
    nodeId: string,
    rarity: "uncommon" | "rare" | "legendary",
    outputItemId: ItemId,
    announcement: string,
}
```

- [ ] **Step 2: Create src/shared/Constants.luau**

```lua
--!strict

local Constants = {}

-- Conveyor throughput by tier (items per minute)
Constants.CONVEYOR_THROUGHPUT: {[number]: number} = {
    [1] = 30,
    [2] = 60,
    [3] = 120,
    [4] = 240,
    [5] = 480,
}

-- Machine defaults
Constants.MACHINE_BUFFER_SIZE = 10
Constants.RESEARCH_PACK_INTERVAL_SECONDS = 30   -- 1 pack consumed per 30 sec
Constants.MACHINE_EFFICIENCY_UPDATE_HZ = 2      -- efficiency recalc per second

-- Power
Constants.POWER_UPDATE_HZ = 1                   -- power grid recalc per second
Constants.PRESSURE_ACCUMULATOR_CAPACITY_PU = 500

-- Drone network
Constants.DRONE_DOCK_RADIUS_STUDS = 50
Constants.DRONE_DOCK_BASE_CAPACITY = 5
Constants.DRONE_DOCK_MAX_CAPACITY = 10          -- after Drone Expansion research
Constants.DRONE_DOCK_IDLE_POWER_PU = 120
Constants.DRONE_DOCK_ACTIVE_POWER_PER_DRONE_PU = 30
Constants.DRONE_CARRY_CAPACITY = 20             -- items per logistic trip
Constants.DRONE_CONSTRUCT_SECONDS_PER_MACHINE = 8

-- Trophy Case
Constants.TROPHY_CASE_SLOTS = 9

-- Rare node chances
Constants.RARE_NODE_CHANCE: {[string]: number} = {
    uncommon  = 0.03,
    rare      = 0.01,
    legendary = 0.001,
}

-- Embercoal boost
Constants.EMBERCOAL_BOOST_MULTIPLIER = 1.5
Constants.EMBERCOAL_BOOST_SECONDS = 60

-- Plot
Constants.MAX_CO_BUILDERS = 3
Constants.SAVE_INTERVAL_SECONDS = 60

-- Ascension
Constants.ASCENDANT_POWER_REQUIRED_PU = 10000
Constants.ASCENDANT_ACTIVATION_SECONDS = 60
Constants.ASCENDANT_ACTIVATION_COST: {itemId: string, count: number} = {
    { itemId = "clockwork_automaton", count = 500 },
    { itemId = "pure_aether",         count = 200 },
    { itemId = "resonance_core",      count = 100 },
}

return Constants
```

- [ ] **Step 3: Commit**

```bash
git add src/shared/Types.luau src/shared/Constants.luau
git commit -m "feat: shared Types and Constants modules"
```

---

### Task 3: Item Data Module

**Files:**
- Create: `src/shared/data/ItemData.luau`
- Create: `tests/shared/data/ItemData.spec.luau`

**Interfaces:**
- Consumes: nothing
- Produces: `ItemData[itemId]` → `ItemDef` — referenced by MachineData build costs, ResearchData pack requirements, RareNodeData output items

- [ ] **Step 1: Write the failing test first**

Create `tests/shared/data/ItemData.spec.luau`:

```lua
--!strict
return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ItemData = require(ReplicatedStorage.Shared.data.ItemData)

    describe("ItemData", function()
        it("exports a non-empty table", function()
            expect(next(ItemData)).to.be.ok()
        end)

        it("every entry has id matching its key", function()
            for key, item in pairs(ItemData) do
                expect(item.id).to.equal(key)
            end
        end)

        it("every entry has a name string", function()
            for _, item in pairs(ItemData) do
                expect(typeof(item.name)).to.equal("string")
                expect(#item.name > 0).to.equal(true)
            end
        end)

        it("every entry has a valid tier 1–6", function()
            for _, item in pairs(ItemData) do
                expect(item.tier >= 1 and item.tier <= 6).to.equal(true)
            end
        end)

        it("rare items have a rarityTier", function()
            for _, item in pairs(ItemData) do
                if item.isRare then
                    expect(item.rarityTier).to.be.ok()
                    local valid = item.rarityTier == "uncommon"
                        or item.rarityTier == "rare"
                        or item.rarityTier == "legendary"
                    expect(valid).to.equal(true)
                end
            end
        end)

        it("contains expected core items", function()
            expect(ItemData["iron_ore"]).to.be.ok()
            expect(ItemData["copper_wire"]).to.be.ok()
            expect(ItemData["clockwork_automaton"]).to.be.ok()
            expect(ItemData["pure_aether"]).to.be.ok()
            expect(ItemData["void_fragment"]).to.be.ok()
        end)
    end)
end
```

- [ ] **Step 2: Run test — confirm FAIL**

In Roblox Studio (test.project.json build), run `tests/run_tests.server.luau`.  
Expected: `ItemData.spec` errors with `require() failed` or module not found.

- [ ] **Step 3: Create src/shared/data/ItemData.luau**

```lua
--!strict

export type ItemDef = {
    id: string,
    name: string,
    tier: number,
    isRaw: boolean?,
    isRare: boolean?,
    rarityTier: ("uncommon" | "rare" | "legendary")?,
}

local Items: {[string]: ItemDef} = {
    -- ── Raw Resources ────────────────────────────────────────────
    wood             = { id="wood",             name="Wood",             tier=1, isRaw=true },
    stone            = { id="stone",            name="Stone",            tier=1, isRaw=true },
    iron_ore         = { id="iron_ore",         name="Iron Ore",         tier=1, isRaw=true },
    copper_ore       = { id="copper_ore",       name="Copper Ore",       tier=1, isRaw=true },
    coal             = { id="coal",             name="Coal",             tier=1, isRaw=true },
    raw_ore          = { id="raw_ore",          name="Raw Ore",          tier=1, isRaw=true }, -- miner placeholder; resolved to actual ore type at runtime
    granite          = { id="granite",          name="Granite",          tier=2, isRaw=true },
    obsidian         = { id="obsidian",         name="Obsidian",         tier=3, isRaw=true },
    sulphur          = { id="sulphur",          name="Sulphur",          tier=3, isRaw=true },
    crystal_shard    = { id="crystal_shard",    name="Crystal Shard",    tier=4, isRaw=true },
    resonance_stone  = { id="resonance_stone",  name="Resonance Stone",  tier=4, isRaw=true },
    quartz           = { id="quartz",           name="Quartz",           tier=4, isRaw=true },
    aether_crystal   = { id="aether_crystal",   name="Aether Crystal",   tier=5, isRaw=true },
    void_stone       = { id="void_stone",       name="Void Stone",       tier=5, isRaw=true },

    -- ── Tier 1 Processed ─────────────────────────────────────────
    lumber            = { id="lumber",            name="Lumber",            tier=1 },
    crushed_stone     = { id="crushed_stone",     name="Crushed Stone",     tier=1 },
    iron_ingot        = { id="iron_ingot",        name="Iron Ingot",        tier=1 },
    copper_ingot      = { id="copper_ingot",      name="Copper Ingot",      tier=1 },
    iron_gear         = { id="iron_gear",         name="Iron Gear",         tier=1 },
    copper_wire       = { id="copper_wire",       name="Copper Wire",       tier=1 },
    clockwork_module  = { id="clockwork_module",  name="Clockwork Module",  tier=1 },

    -- ── Tier 2 Processed ─────────────────────────────────────────
    steam              = { id="steam",              name="Steam",              tier=2 },
    iron_plate         = { id="iron_plate",         name="Iron Plate",         tier=2 },
    reinforced_panel   = { id="reinforced_panel",   name="Reinforced Panel",   tier=2 },
    quality_ingot      = { id="quality_ingot",      name="Quality Ingot",      tier=2 }, -- from Precision Forge

    -- ── Tier 3 Processed ─────────────────────────────────────────
    steel_ingot       = { id="steel_ingot",       name="Steel Ingot",       tier=3 },
    steel_plate       = { id="steel_plate",       name="Steel Plate",       tier=3 },
    reinforced_frame  = { id="reinforced_frame",  name="Reinforced Frame",  tier=3 },
    glass_lens        = { id="glass_lens",        name="Glass Lens",        tier=3 },
    steam_capsule     = { id="steam_capsule",     name="Steam Capsule",     tier=3 },
    quality_assembly  = { id="quality_assembly",  name="Quality Assembly",  tier=3 }, -- from Quality Assembler

    -- ── Tier 4 Processed ─────────────────────────────────────────
    precision_gear    = { id="precision_gear",    name="Precision Gear",    tier=4 },
    master_gear       = { id="master_gear",       name="Master Gear",       tier=4 }, -- from Artisan Lathe
    conductor_coil    = { id="conductor_coil",    name="Conductor Coil",    tier=4 },
    optical_assembly  = { id="optical_assembly",  name="Optical Assembly",  tier=4 },
    advanced_frame    = { id="advanced_frame",    name="Advanced Frame",    tier=4 },
    obsidian_shard    = { id="obsidian_shard",    name="Obsidian Shard",    tier=4 },

    -- ── Tier 5 Processed ─────────────────────────────────────────
    automaton_core          = { id="automaton_core",          name="Automaton Core",          tier=5 },
    steam_chassis           = { id="steam_chassis",           name="Steam Chassis",           tier=5 },
    resonance_core          = { id="resonance_core",          name="Resonance Core",          tier=5 },
    conductor_array         = { id="conductor_array",         name="Conductor Array",         tier=5 },
    clockwork_automaton     = { id="clockwork_automaton",     name="Clockwork Automaton",     tier=5 },
    automaton_foreman_unit  = { id="automaton_foreman_unit",  name="Automaton Foreman",       tier=5 },
    automaton_courier_unit  = { id="automaton_courier_unit",  name="Automaton Courier",       tier=5 },

    -- ── Tier 6 Processed ─────────────────────────────────────────
    pure_aether = { id="pure_aether", name="Pure Aether", tier=6 },

    -- ── Rare Items (Design §18) ───────────────────────────────────
    starfire_ingot    = { id="starfire_ingot",    name="Starfire Ingot",    tier=1, isRare=true, rarityTier="rare" },
    mooncopper_ingot  = { id="mooncopper_ingot",  name="Mooncopper Ingot",  tier=1, isRare=true, rarityTier="rare" },
    gilded_alloy      = { id="gilded_alloy",      name="Gilded Alloy",      tier=2, isRare=true, rarityTier="rare" },
    embercoal         = { id="embercoal",         name="Embercoal",         tier=2, isRare=true, rarityTier="uncommon" },
    heart_of_obsidian = { id="heart_of_obsidian", name="Heart of Obsidian", tier=3, isRare=true, rarityTier="legendary" },
    pure_sulphur      = { id="pure_sulphur",      name="Pure Sulphur",      tier=3, isRare=true, rarityTier="rare" },
    prismatic_shard   = { id="prismatic_shard",   name="Prismatic Shard",   tier=4, isRare=true, rarityTier="legendary" },
    resonance_gem     = { id="resonance_gem",     name="Resonance Gem",     tier=4, isRare=true, rarityTier="rare" },
    void_fragment     = { id="void_fragment",     name="Void Fragment",     tier=5, isRare=true, rarityTier="legendary" },
    pure_aether_bloom = { id="pure_aether_bloom", name="Pure Aether Bloom", tier=5, isRare=true, rarityTier="rare" },
}

return Items
```

- [ ] **Step 4: Run test — confirm PASS**

Run tests again. Expected: `ItemData` describe block: 6 PASS, 0 FAIL.

- [ ] **Step 5: Commit**

```bash
git add src/shared/data/ItemData.luau tests/shared/data/ItemData.spec.luau
git commit -m "feat: ItemData module with all 50 items + spec"
```

---

### Task 4: Machine Data Module

**Files:**
- Create: `src/shared/data/MachineData.luau`
- Create: `tests/shared/data/MachineData.spec.luau`

**Interfaces:**
- Consumes: `ItemData` — build costs and input/output itemIds must exist in ItemData
- Produces: `MachineData[machineId]` → `MachineDef` — used by MachineService, ConveyorService, PowerService

- [ ] **Step 1: Write the failing test**

Create `tests/shared/data/MachineData.spec.luau`:

```lua
--!strict
return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local MachineData = require(ReplicatedStorage.Shared.data.MachineData)
    local ItemData    = require(ReplicatedStorage.Shared.data.ItemData)

    describe("MachineData", function()
        it("exports a non-empty table", function()
            expect(next(MachineData)).to.be.ok()
        end)

        it("every entry has id matching its key", function()
            for key, m in pairs(MachineData) do
                expect(m.id).to.equal(key)
            end
        end)

        it("every entry has required scalar fields", function()
            for id, m in pairs(MachineData) do
                expect(typeof(m.name)).to.equal("string")
                expect(m.tier >= 1 and m.tier <= 6).to.equal(true)
                expect(m.powerDraw >= 0).to.equal(true)
                expect(m.bufferSize >= 0).to.equal(true)
            end
        end)

        it("all build cost itemIds exist in ItemData", function()
            for id, m in pairs(MachineData) do
                for _, entry in ipairs(m.buildCost) do
                    expect(ItemData[entry.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("all input itemIds exist in ItemData", function()
            for id, m in pairs(MachineData) do
                for _, inp in ipairs(m.inputs) do
                    expect(ItemData[inp.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("all output itemIds exist in ItemData", function()
            for id, m in pairs(MachineData) do
                for _, out in ipairs(m.outputs) do
                    expect(ItemData[out.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("generators have generatorOutput > 0", function()
            for id, m in pairs(MachineData) do
                if m.isGenerator then
                    expect((m.generatorOutput or 0) > 0).to.equal(true)
                end
            end
        end)

        it("storage machines have storageCapacity", function()
            for id, m in pairs(MachineData) do
                if m.isStorage then
                    expect((m.storageCapacity or 0) > 0).to.equal(true)
                end
            end
        end)

        it("contains exactly 40 machines across tiers 1–6", function()
            local count = 0
            for _ in pairs(MachineData) do count += 1 end
            expect(count).to.equal(40)
        end)
    end)
end
```

- [ ] **Step 2: Run test — confirm FAIL**

Expected: `MachineData.spec` fails with module not found.

- [ ] **Step 3: Create src/shared/data/MachineData.luau**

```lua
--!strict

export type InputDef = {
    itemId: string,
    rate: number,   -- items consumed per second at 100% efficiency
}

export type OutputDef = {
    itemId: string,
    rate: number,   -- items produced per second at 100% efficiency
}

export type BuildCostEntry = {
    itemId: string,
    count: number,
}

export type SpecializationDef = {
    id: string,
    name: string,
    description: string,
    outputMultiplier: number,       -- multiplies base output rate
    powerMultiplier: number,        -- multiplies base powerDraw
    alternateOutputItemId: string?, -- if non-nil, replaces the base output itemId
}

export type MachineDef = {
    id: string,
    name: string,
    tier: number,
    powerDraw: number,          -- PU consumed per second (0 = no power needed)
    inputs: {InputDef},
    outputs: {OutputDef},
    buildCost: {BuildCostEntry},
    bufferSize: number,
    smeltsOre: boolean?,        -- accepts any ore; outputs corresponding ingot (clay_furnace, smelter)
    isMiner: boolean?,
    isStorage: boolean?,
    storageCapacity: number?,
    isGenerator: boolean?,
    generatorOutput: number?,   -- PU produced per second
    isResearchStation: boolean?,
    isDroneDock: boolean?,
    isLogistics: boolean?,      -- splitters, loaders, smart-routing machines
    specializations: {SpecializationDef}?,
}

local Machines: {[string]: MachineDef} = {

    -- ════════════════════════════════════════════════════════════
    -- TIER 1 — No Power Required
    -- ════════════════════════════════════════════════════════════

    lumber_mill = {
        id="lumber_mill", name="Lumber Mill", tier=1, powerDraw=0,
        inputs={}, outputs={{ itemId="lumber", rate=2 }},
        buildCost={{ itemId="wood", count=5 }},
        bufferSize=10, isMiner=true,
    },

    stone_crusher = {
        id="stone_crusher", name="Stone Crusher", tier=1, powerDraw=0,
        inputs={}, outputs={{ itemId="crushed_stone", rate=2 }},
        buildCost={{ itemId="lumber", count=10 }},
        bufferSize=10, isMiner=true,
    },

    clay_furnace = {
        id="clay_furnace", name="Clay Furnace", tier=1, powerDraw=0,
        -- smeltsOre=true: whichever ore arrives is smelted; rate/output resolved at runtime
        inputs={
            { itemId="iron_ore",   rate=1 },
            { itemId="copper_ore", rate=1 },
        },
        outputs={
            { itemId="iron_ingot",   rate=0.5 },
            { itemId="copper_ingot", rate=0.5 },
        },
        buildCost={
            { itemId="lumber",        count=10 },
            { itemId="crushed_stone", count=5 },
        },
        bufferSize=10, smeltsOre=true,
    },

    gear_stamp = {
        id="gear_stamp", name="Gear Stamp", tier=1, powerDraw=0,
        inputs={{ itemId="iron_ingot", rate=2 }},
        outputs={{ itemId="iron_gear", rate=0.5 }},
        buildCost={
            { itemId="iron_ingot", count=10 },
            { itemId="lumber",     count=5 },
        },
        bufferSize=10,
    },

    wire_braider = {
        id="wire_braider", name="Wire Braider", tier=1, powerDraw=0,
        inputs={{ itemId="copper_ingot", rate=1 }},
        outputs={{ itemId="copper_wire", rate=1 }},
        buildCost={
            { itemId="copper_ingot", count=5 },
            { itemId="lumber",       count=5 },
        },
        bufferSize=10,
    },

    clockwork_bench = {
        id="clockwork_bench", name="Clockwork Bench", tier=1, powerDraw=0,
        inputs={
            { itemId="iron_gear",   rate=1 },
            { itemId="copper_wire", rate=1 },
        },
        outputs={{ itemId="clockwork_module", rate=0.5 }},
        buildCost={
            { itemId="iron_gear",   count=15 },
            { itemId="copper_wire", count=10 },
        },
        bufferSize=10,
    },

    miner_mk1 = {
        id="miner_mk1", name="Miner Mk1", tier=1, powerDraw=0,
        inputs={}, outputs={{ itemId="raw_ore", rate=1 }},
        buildCost={
            { itemId="lumber",        count=15 },
            { itemId="crushed_stone", count=5 },
        },
        bufferSize=10, isMiner=true,
    },

    storage_chest = {
        id="storage_chest", name="Storage Chest", tier=1, powerDraw=0,
        inputs={}, outputs={},
        buildCost={{ itemId="lumber", count=10 }},
        bufferSize=200, isStorage=true, storageCapacity=200,
    },

    research_station = {
        id="research_station", name="Research Station", tier=1, powerDraw=0,
        inputs={}, outputs={},
        buildCost={
            { itemId="lumber",        count=20 },
            { itemId="crushed_stone", count=10 },
        },
        bufferSize=10, isResearchStation=true,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 2 — Steam Power Required
    -- ════════════════════════════════════════════════════════════

    smelter = {
        id="smelter", name="Smelter", tier=2, powerDraw=25,
        inputs={
            { itemId="iron_ore",   rate=2 },
            { itemId="copper_ore", rate=2 },
        },
        outputs={
            { itemId="iron_ingot",   rate=1 },
            { itemId="copper_ingot", rate=1 },
        },
        buildCost={
            { itemId="iron_ingot", count=20 },
            { itemId="lumber",     count=10 },
        },
        bufferSize=10, smeltsOre=true,
        specializations={
            {
                id="blast_furnace", name="Blast Furnace",
                description="2× ingot output. Consumes 3× coal. Best for bulk iron/copper lines.",
                outputMultiplier=2, powerMultiplier=1,
            },
            {
                id="precision_forge", name="Precision Forge",
                description="Standard speed. Outputs Quality Ingots required for Tier 5–6 recipes.",
                outputMultiplier=1, powerMultiplier=1,
                alternateOutputItemId="quality_ingot",
            },
        },
    },

    gear_press = {
        id="gear_press", name="Gear Press", tier=2, powerDraw=30,
        inputs={{ itemId="iron_ingot", rate=2 }},
        outputs={{ itemId="iron_gear", rate=1 }},
        buildCost={
            { itemId="iron_ingot",    count=15 },
            { itemId="crushed_stone", count=5 },
        },
        bufferSize=10,
    },

    copper_refinery = {
        id="copper_refinery", name="Copper Refinery", tier=2, powerDraw=20,
        inputs={{ itemId="copper_ore",   rate=2 }},
        outputs={{ itemId="copper_ingot", rate=1 }},
        buildCost={
            { itemId="copper_ingot", count=15 },
            { itemId="iron_ingot",   count=10 },
        },
        bufferSize=10,
    },

    wire_refinery = {
        id="wire_refinery", name="Wire Refinery", tier=2, powerDraw=20,
        inputs={{ itemId="copper_ingot", rate=2 }},
        outputs={{ itemId="copper_wire", rate=1 }},
        buildCost={
            { itemId="copper_ingot", count=10 },
            { itemId="iron_gear",    count=10 },
        },
        bufferSize=10,
    },

    roller_press = {
        id="roller_press", name="Roller Press", tier=2, powerDraw=25,
        inputs={{ itemId="iron_ingot", rate=2 }},
        outputs={{ itemId="iron_plate", rate=1 }},
        buildCost={
            { itemId="iron_ingot", count=15 },
            { itemId="iron_gear",  count=10 },
        },
        bufferSize=10,
    },

    panel_bender = {
        id="panel_bender", name="Panel Bender", tier=2, powerDraw=30,
        inputs={{ itemId="iron_plate",      rate=2 }},
        outputs={{ itemId="reinforced_panel", rate=1 }},
        buildCost={
            { itemId="iron_plate", count=20 },
            { itemId="iron_gear",  count=10 },
        },
        bufferSize=10,
    },

    steam_boiler = {
        id="steam_boiler", name="Steam Boiler", tier=2, powerDraw=0,
        inputs={{ itemId="coal",  rate=1 }},
        outputs={{ itemId="steam", rate=5 }},
        buildCost={
            { itemId="iron_ingot",    count=20 },
            { itemId="crushed_stone", count=10 },
        },
        bufferSize=10,
    },

    steam_engine = {
        id="steam_engine", name="Steam Engine", tier=2, powerDraw=0,
        inputs={{ itemId="steam", rate=5 }},
        outputs={},
        buildCost={
            { itemId="iron_gear",  count=15 },
            { itemId="iron_ingot", count=10 },
        },
        bufferSize=10, isGenerator=true, generatorOutput=50,
    },

    storage_mk2 = {
        id="storage_mk2", name="Storage Mk2", tier=2, powerDraw=10,
        inputs={}, outputs={},
        buildCost={
            { itemId="iron_plate", count=20 },
            { itemId="iron_gear",  count=10 },
        },
        bufferSize=500, isStorage=true, storageCapacity=500,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 3 — Pressurized Steam
    -- ════════════════════════════════════════════════════════════

    forge = {
        id="forge", name="Forge", tier=3, powerDraw=50,
        inputs={
            { itemId="iron_ingot", rate=3 },
            { itemId="coal",       rate=1 },
        },
        outputs={{ itemId="steel_ingot", rate=1 }},
        buildCost={
            { itemId="iron_gear",       count=30 },
            { itemId="clockwork_module", count=15 },
        },
        bufferSize=10,
    },

    glass_kiln = {
        id="glass_kiln", name="Glass Kiln", tier=3, powerDraw=40,
        inputs={{ itemId="crushed_stone", rate=2 }},
        outputs={{ itemId="glass_lens",   rate=1 }},
        buildCost={
            { itemId="iron_plate",       count=20 },
            { itemId="clockwork_module", count=10 },
        },
        bufferSize=10,
    },

    assembler_mk1 = {
        id="assembler_mk1", name="Assembler Mk1", tier=3, powerDraw=60,
        inputs={}, outputs={},  -- recipe set per placed instance
        buildCost={
            { itemId="clockwork_module", count=25 },
            { itemId="iron_gear",        count=15 },
        },
        bufferSize=10,
        specializations={
            {
                id="high_volume", name="High-Volume Assembler",
                description="3× output speed at 2× power draw. Best for bulk mid-tier components.",
                outputMultiplier=3, powerMultiplier=2,
            },
            {
                id="quality", name="Quality Assembler",
                description="Standard speed. Outputs refined assembly variants for Tier 5–6.",
                outputMultiplier=1, powerMultiplier=1,
                alternateOutputItemId="quality_assembly",
            },
        },
    },

    roller_press_mk2 = {
        id="roller_press_mk2", name="Roller Press Mk2", tier=3, powerDraw=55,
        inputs={{ itemId="steel_ingot", rate=2 }},
        outputs={{ itemId="steel_plate", rate=1 }},
        buildCost={
            { itemId="steel_ingot", count=20 },
            { itemId="iron_plate",  count=15 },
        },
        bufferSize=10,
    },

    forge_press = {
        id="forge_press", name="Forge Press", tier=3, powerDraw=65,
        inputs={{ itemId="steel_ingot",    rate=2 }},
        outputs={{ itemId="reinforced_frame", rate=1 }},
        buildCost={
            { itemId="steel_plate",      count=25 },
            { itemId="clockwork_module", count=15 },
        },
        bufferSize=10,
    },

    pressure_engine = {
        id="pressure_engine", name="Pressure Engine", tier=3, powerDraw=0,
        inputs={
            { itemId="steam",         rate=5 },
            { itemId="steam_capsule", rate=1 },
        },
        outputs={},
        buildCost={
            { itemId="steel_plate", count=20 },
            { itemId="iron_gear",   count=15 },
        },
        bufferSize=10, isGenerator=true, generatorOutput=150,
    },

    pressure_accumulator = {
        id="pressure_accumulator", name="Pressure Accumulator", tier=3, powerDraw=0,
        inputs={}, outputs={},
        buildCost={
            { itemId="steel_ingot",  count=20 },
            { itemId="copper_wire",  count=10 },
        },
        bufferSize=0,
        -- Stores 500 PU for burst discharge; handled by PowerService
        isStorage=true, storageCapacity=500,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 4 — Clockwork Power
    -- ════════════════════════════════════════════════════════════

    precision_lathe = {
        id="precision_lathe", name="Precision Lathe", tier=4, powerDraw=80,
        inputs={{ itemId="steel_ingot",   rate=2 }},
        outputs={{ itemId="precision_gear", rate=1 }},
        buildCost={
            { itemId="steel_plate",    count=30 },
            { itemId="conductor_coil", count=20 },
        },
        bufferSize=10,
        specializations={
            {
                id="mass_lathe", name="Mass Lathe",
                description="3 Precision Gears/sec. Raw throughput for bulk late-game production.",
                outputMultiplier=3, powerMultiplier=1.5,
            },
            {
                id="artisan_lathe", name="Artisan Lathe",
                description="0.5/sec. Outputs Master Gears required for Clockwork Automaton.",
                outputMultiplier=0.5, powerMultiplier=1,
                alternateOutputItemId="master_gear",
            },
        },
    },

    coil_winder = {
        id="coil_winder", name="Coil Winder", tier=4, powerDraw=60,
        inputs={{ itemId="copper_wire",   rate=2 }},
        outputs={{ itemId="conductor_coil", rate=1 }},
        buildCost={
            { itemId="copper_wire", count=20 },
            { itemId="iron_plate",  count=15 },
        },
        bufferSize=10,
    },

    optical_refinery = {
        id="optical_refinery", name="Optical Refinery", tier=4, powerDraw=70,
        inputs={
            { itemId="glass_lens",  rate=2 },
            { itemId="copper_wire", rate=1 },
        },
        outputs={{ itemId="optical_assembly", rate=1 }},
        buildCost={
            { itemId="optical_assembly", count=25 },
            { itemId="steel_plate",      count=15 },
        },
        bufferSize=10,
    },

    advanced_assembler = {
        id="advanced_assembler", name="Advanced Assembler", tier=4, powerDraw=100,
        inputs={}, outputs={},  -- recipe set per placed instance; 1.5/sec base
        buildCost={
            { itemId="optical_assembly", count=30 },
            { itemId="reinforced_frame", count=20 },
        },
        bufferSize=10,
    },

    obsidian_cutter = {
        id="obsidian_cutter", name="Obsidian Cutter", tier=4, powerDraw=90,
        inputs={{ itemId="obsidian",      rate=1 }},
        outputs={{ itemId="obsidian_shard", rate=1 }},
        buildCost={
            { itemId="steel_plate",    count=25 },
            { itemId="precision_gear", count=15 },
        },
        bufferSize=10,
    },

    clockwork_dynamo = {
        id="clockwork_dynamo", name="Clockwork Dynamo", tier=4, powerDraw=0,
        inputs={{ itemId="conductor_coil", rate=1 }},
        outputs={},
        buildCost={
            { itemId="conductor_coil", count=25 },
            { itemId="precision_gear", count=20 },
        },
        bufferSize=10, isGenerator=true, generatorOutput=400,
    },

    smart_splitter = {
        id="smart_splitter", name="Smart Splitter", tier=4, powerDraw=15,
        inputs={}, outputs={},  -- 3 filtered output lanes; config per instance
        buildCost={
            { itemId="conductor_coil",   count=10 },
            { itemId="optical_assembly", count=5 },
        },
        bufferSize=10, isLogistics=true,
    },

    drone_dock = {
        id="drone_dock", name="Drone Dock", tier=4, powerDraw=120,
        inputs={}, outputs={},
        buildCost={
            { itemId="precision_gear",   count=25 },
            { itemId="conductor_coil",   count=20 },
            { itemId="optical_assembly", count=10 },
        },
        bufferSize=0, isDroneDock=true,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 5 — Crystal Power
    -- ════════════════════════════════════════════════════════════

    automaton_workshop = {
        id="automaton_workshop", name="Automaton Workshop", tier=5, powerDraw=200,
        inputs={
            { itemId="automaton_core", rate=2 },
            { itemId="steam_chassis",  rate=1 },
        },
        outputs={{ itemId="clockwork_automaton", rate=0.5 }},
        buildCost={
            { itemId="automaton_core", count=40 },
            { itemId="resonance_core", count=20 },
        },
        bufferSize=10,
        specializations={
            {
                id="automaton_foreman", name="Automaton Foreman",
                description="Outputs deploy-able Foreman units. Place near machines for +25% efficiency aura.",
                outputMultiplier=1, powerMultiplier=1,
                alternateOutputItemId="automaton_foreman_unit",
            },
            {
                id="automaton_courier", name="Automaton Courier",
                description="Outputs deploy-able Courier units. Replaces conveyors in a small radius.",
                outputMultiplier=1, powerMultiplier=1,
                alternateOutputItemId="automaton_courier_unit",
            },
        },
    },

    crystal_refinery = {
        id="crystal_refinery", name="Crystal Refinery", tier=5, powerDraw=150,
        inputs={{ itemId="crystal_shard",  rate=2 }},
        outputs={{ itemId="resonance_core", rate=1 }},
        buildCost={
            { itemId="resonance_core", count=30 },
            { itemId="automaton_core", count=20 },
            { itemId="quartz",         count=10 },
        },
        bufferSize=10,
    },

    resonance_forge = {
        id="resonance_forge", name="Resonance Forge", tier=5, powerDraw=180,
        inputs={
            { itemId="steel_ingot",   rate=2 },
            { itemId="resonance_core", rate=1 },
        },
        outputs={{ itemId="conductor_array", rate=1 }},
        buildCost={
            { itemId="resonance_core", count=25 },
            { itemId="automaton_core", count=15 },
        },
        bufferSize=10,
    },

    crystal_resonator = {
        id="crystal_resonator", name="Crystal Resonator", tier=5, powerDraw=0,
        inputs={}, outputs={},
        buildCost={
            { itemId="crystal_shard",  count=50 },
            { itemId="resonance_core", count=30 },
            { itemId="automaton_core", count=20 },
        },
        bufferSize=0, isGenerator=true, generatorOutput=2000,
    },

    automaton_loader = {
        id="automaton_loader", name="Automaton Loader", tier=5, powerDraw=80,
        inputs={}, outputs={},  -- 120 items/min smart-routed
        buildCost={
            { itemId="automaton_core", count=20 },
            { itemId="conductor_coil", count=10 },
        },
        bufferSize=10, isLogistics=true,
    },

    -- ════════════════════════════════════════════════════════════
    -- TIER 6 — Aether Power
    -- ════════════════════════════════════════════════════════════

    aether_refinery = {
        id="aether_refinery", name="Aether Refinery", tier=6, powerDraw=500,
        inputs={{ itemId="aether_crystal", rate=3 }},
        outputs={{ itemId="pure_aether",   rate=1 }},
        buildCost={
            { itemId="aether_crystal", count=30 },
            { itemId="resonance_core", count=20 },
        },
        bufferSize=10,
    },

    resonance_amplifier = {
        id="resonance_amplifier", name="Resonance Amplifier", tier=6, powerDraw=300,
        inputs={}, outputs={},  -- aura: +50% output to all adjacent machines
        buildCost={
            { itemId="pure_aether",    count=20 },
            { itemId="conductor_array", count=15 },
        },
        bufferSize=0,
    },

    clockwork_ascendant = {
        id="clockwork_ascendant", name="Clockwork Ascendant", tier=6, powerDraw=10000,
        -- powerDraw is sustained for 60 sec during activation; requires 5× Crystal Resonators minimum
        inputs={
            { itemId="clockwork_automaton", rate=0 }, -- 500 consumed on activation trigger
            { itemId="pure_aether",         rate=0 }, -- 200 consumed on activation trigger
            { itemId="resonance_core",      rate=0 }, -- 100 consumed on activation trigger
        },
        outputs={},
        buildCost={
            { itemId="pure_aether",    count=50 },
            { itemId="conductor_array", count=30 },
            { itemId="void_stone",     count=20 },
        },
        bufferSize=0,
    },
}

return Machines
```

- [ ] **Step 4: Run test — confirm PASS**

Expected: `MachineData` describe block: 8 PASS, 0 FAIL.

- [ ] **Step 5: Commit**

```bash
git add src/shared/data/MachineData.luau tests/shared/data/MachineData.spec.luau
git commit -m "feat: MachineData module — all 40 machines + spec"
```

---

### Task 5: Research Data Module

**Files:**
- Create: `src/shared/data/ResearchData.luau`
- Create: `tests/shared/data/ResearchData.spec.luau`

**Interfaces:**
- Consumes: `ItemData` — pack requirement itemIds must exist
- Produces: `ResearchData[researchId]` → `ResearchNode` — used by ResearchService

- [ ] **Step 1: Write the failing test**

Create `tests/shared/data/ResearchData.spec.luau`:

```lua
--!strict
return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ResearchData = require(ReplicatedStorage.Shared.data.ResearchData)
    local ItemData     = require(ReplicatedStorage.Shared.data.ItemData)

    describe("ResearchData", function()
        it("exports a non-empty table", function()
            expect(next(ResearchData)).to.be.ok()
        end)

        it("every entry has id matching its key", function()
            for key, node in pairs(ResearchData) do
                expect(node.id).to.equal(key)
            end
        end)

        it("every pack requirement itemId exists in ItemData", function()
            for id, node in pairs(ResearchData) do
                for _, req in ipairs(node.packRequirements) do
                    expect(ItemData[req.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("all prerequisites reference existing research nodes", function()
            for id, node in pairs(ResearchData) do
                if node.prerequisite then
                    expect(ResearchData[node.prerequisite] ~= nil).to.equal(true)
                end
            end
        end)

        it("the six main tier unlocks exist and are not side branches", function()
            local mainNodes = {"tier2_main","tier3_main","tier4_main","tier5_main","tier6_main"}
            for _, nodeId in ipairs(mainNodes) do
                local node = ResearchData[nodeId]
                expect(node).to.be.ok()
                expect(node.isSideBranch).to.equal(false)
            end
        end)

        it("tier2_main has no prerequisite", function()
            expect(ResearchData["tier2_main"].prerequisite).never.to.be.ok()
        end)
    end)
end
```

- [ ] **Step 2: Run test — confirm FAIL**

Expected: fails with module not found.

- [ ] **Step 3: Create src/shared/data/ResearchData.luau**

```lua
--!strict

export type PackRequirement = {
    itemId: string,
    count: number,
}

export type ResearchNode = {
    id: string,
    name: string,
    description: string,
    packRequirements: {PackRequirement},
    unlocks: {string},         -- machine ids, biome ids, or misc unlock strings
    prerequisite: string?,     -- researchId that must be completed first (nil = available from start)
    isSideBranch: boolean,
}

local Research: {[string]: ResearchNode} = {

    -- ── Main Tier Unlocks ────────────────────────────────────────

    tier2_main = {
        id="tier2_main", name="Iron & Copper Mastery", isSideBranch=false,
        description="Unlock Tier 2 machines: Smelters, Gear Presses, Steam Power.",
        packRequirements={
            { itemId="iron_gear",   count=10 },
            { itemId="copper_wire", count=10 },
        },
        unlocks={"smelter","gear_press","copper_refinery","wire_refinery",
                 "roller_press","panel_bender","steam_boiler","steam_engine","storage_mk2"},
        prerequisite=nil,
    },

    tier3_main = {
        id="tier3_main", name="Steel & Steam", isSideBranch=false,
        description="Unlock Tier 3 machines: Forge, Assemblers, Pressurized Steam engines.",
        packRequirements={
            { itemId="clockwork_module", count=20 },
            { itemId="steam_capsule",    count=10 },
            { itemId="glass_lens",       count=5 },
        },
        unlocks={"forge","glass_kiln","assembler_mk1","roller_press_mk2",
                 "forge_press","pressure_engine","pressure_accumulator"},
        prerequisite="tier2_main",
    },

    tier4_main = {
        id="tier4_main", name="Precision Engineering", isSideBranch=false,
        description="Unlock Tier 4 machines: Precision Lathes, Coil Winders, Clockwork Dynamos.",
        packRequirements={
            { itemId="optical_assembly", count=15 },
            { itemId="conductor_coil",   count=20 },
            { itemId="reinforced_frame", count=10 },
        },
        unlocks={"precision_lathe","coil_winder","optical_refinery","advanced_assembler",
                 "obsidian_cutter","clockwork_dynamo","smart_splitter"},
        prerequisite="tier3_main",
    },

    tier5_main = {
        id="tier5_main", name="Clockwork Mastery", isSideBranch=false,
        description="Unlock Tier 5 machines: Automaton Workshop, Crystal Refinery, Crystal Resonator.",
        packRequirements={
            { itemId="automaton_core", count=10 },
            { itemId="resonance_core", count=5 },
            { itemId="precision_gear", count=20 },
        },
        unlocks={"automaton_workshop","crystal_refinery","resonance_forge",
                 "crystal_resonator","automaton_loader"},
        prerequisite="tier4_main",
    },

    tier6_main = {
        id="tier6_main", name="Ascension", isSideBranch=false,
        description="Unlock Tier 6: Aether Refinery, Resonance Amplifier, and the Clockwork Ascendant.",
        packRequirements={
            { itemId="clockwork_automaton", count=20 },
            { itemId="aether_crystal",      count=10 },
            { itemId="resonance_core",      count=5 },
        },
        unlocks={"aether_refinery","resonance_amplifier","clockwork_ascendant"},
        prerequisite="tier5_main",
    },

    -- ── Tier 2 Side Branches ─────────────────────────────────────

    tier2_biome2 = {
        id="tier2_biome2", name="Highland Expedition", isSideBranch=true,
        description="Unlock Biome 2: Highland Reach. Rich iron and copper deposits.",
        packRequirements={
            { itemId="iron_plate",  count=10 },
            { itemId="copper_wire", count=5 },
        },
        unlocks={"biome_highland_reach"},
        prerequisite="tier2_main",
    },

    tier2_smelter_spec = {
        id="tier2_smelter_spec", name="Smelter Specialization", isSideBranch=true,
        description="Unlock Blast Furnace and Precision Forge specializations.",
        packRequirements={{ itemId="iron_gear", count=15 }},
        unlocks={"spec_blast_furnace","spec_precision_forge"},
        prerequisite="tier2_main",
    },

    tier2_roller_press = {
        id="tier2_roller_press", name="Rolling Mill", isSideBranch=true,
        description="Unlock the Roller Press for Iron Plate production.",
        packRequirements={{ itemId="iron_ingot", count=15 }},
        unlocks={"roller_press"},
        prerequisite="tier2_main",
    },

    -- ── Tier 3 Side Branches ─────────────────────────────────────

    tier3_biome3 = {
        id="tier3_biome3", name="Volcanic Expedition", isSideBranch=true,
        description="Unlock Biome 3: Volcanic Depths. Coal, Obsidian, and Sulphur deposits.",
        packRequirements={
            { itemId="steel_plate", count=15 },
            { itemId="glass_lens",  count=10 },
        },
        unlocks={"biome_volcanic_depths"},
        prerequisite="tier3_main",
    },

    tier3_assembler_spec = {
        id="tier3_assembler_spec", name="Assembler Specialization", isSideBranch=true,
        description="Unlock High-Volume and Quality specializations for Assembler Mk1.",
        packRequirements={{ itemId="clockwork_module", count=20 }},
        unlocks={"spec_high_volume","spec_quality"},
        prerequisite="tier3_main",
    },

    tier3_miner_mk2 = {
        id="tier3_miner_mk2", name="Industrial Mining", isSideBranch=true,
        description="Unlock Miner Mk2 for 2× ore output.",
        packRequirements={
            { itemId="steel_plate",      count=10 },
            { itemId="clockwork_module", count=5 },
        },
        unlocks={"miner_mk2"},
        prerequisite="tier3_main",
    },

    tier3_conveyor_mk3 = {
        id="tier3_conveyor_mk3", name="High-Speed Conveyors", isSideBranch=true,
        description="Unlock Conveyor Mk3 (120 items/min).",
        packRequirements={{ itemId="steel_plate", count=10 }},
        unlocks={"conveyor_mk3"},
        prerequisite="tier3_main",
    },

    tier3_pressure_accumulator = {
        id="tier3_pressure_accumulator", name="Power Storage", isSideBranch=true,
        description="Unlock the Pressure Accumulator for burst power buffering.",
        packRequirements={
            { itemId="iron_gear",   count=20 },
            { itemId="copper_wire", count=10 },
        },
        unlocks={"pressure_accumulator"},
        prerequisite="tier3_main",
    },

    -- ── Tier 4 Side Branches ─────────────────────────────────────

    tier4_biome4 = {
        id="tier4_biome4", name="Crystal Expedition", isSideBranch=true,
        description="Unlock Biome 4: Crystal Caverns. Crystal Shards and Resonance Stone.",
        packRequirements={
            { itemId="optical_assembly", count=20 },
            { itemId="conductor_coil",   count=15 },
        },
        unlocks={"biome_crystal_caverns"},
        prerequisite="tier4_main",
    },

    tier4_lathe_spec = {
        id="tier4_lathe_spec", name="Lathe Specialization", isSideBranch=true,
        description="Unlock Mass Lathe and Artisan Lathe specializations.",
        packRequirements={{ itemId="precision_gear", count=25 }},
        unlocks={"spec_mass_lathe","spec_artisan_lathe"},
        prerequisite="tier4_main",
    },

    tier4_logistics_mk2 = {
        id="tier4_logistics_mk2", name="Advanced Logistics", isSideBranch=true,
        description="Unlock overflow valves, item filters, and priority routing.",
        packRequirements={{ itemId="conductor_coil", count=20 }},
        unlocks={"overflow_valve","item_filter","priority_router"},
        prerequisite="tier4_main",
    },

    tier4_conveyor_mk4 = {
        id="tier4_conveyor_mk4", name="Precision Conveyors", isSideBranch=true,
        description="Unlock Conveyor Mk4 (240 items/min).",
        packRequirements={
            { itemId="steel_plate",    count=15 },
            { itemId="conductor_coil", count=10 },
        },
        unlocks={"conveyor_mk4"},
        prerequisite="tier4_main",
    },

    tier4_drone_network = {
        id="tier4_drone_network", name="Drone Network", isSideBranch=true,
        description="Unlock Drone Docks, Logistic Drones, Construction Drones, and Logistic Chests.",
        packRequirements={
            { itemId="optical_assembly", count=20 },
            { itemId="conductor_coil",   count=10 },
            { itemId="precision_gear",   count=10 },
        },
        unlocks={"drone_dock","logistic_chest_provider","logistic_chest_requester","logistic_chest_buffer"},
        prerequisite="tier4_main",
    },

    -- ── Tier 5 Side Branches ─────────────────────────────────────

    tier5_biome5 = {
        id="tier5_biome5", name="Aether Expedition", isSideBranch=true,
        description="Unlock Biome 5: Aether Rift. Aether Crystals and Void Stone.",
        packRequirements={
            { itemId="resonance_core", count=20 },
            { itemId="automaton_core", count=10 },
        },
        unlocks={"biome_aether_rift"},
        prerequisite="tier5_main",
    },

    tier5_workshop_spec = {
        id="tier5_workshop_spec", name="Automaton Specialization", isSideBranch=true,
        description="Unlock Automaton Foreman and Automaton Courier specializations.",
        packRequirements={{ itemId="automaton_core", count=20 }},
        unlocks={"spec_automaton_foreman","spec_automaton_courier"},
        prerequisite="tier5_main",
    },

    tier5_miner_mk3 = {
        id="tier5_miner_mk3", name="Deep Mining", isSideBranch=true,
        description="Unlock Miner Mk3 for maximum ore yield.",
        packRequirements={{ itemId="automaton_core", count=15 }},
        unlocks={"miner_mk3"},
        prerequisite="tier5_main",
    },

    tier5_conveyor_mk5 = {
        id="tier5_conveyor_mk5", name="Crystal Conveyors", isSideBranch=true,
        description="Unlock Conveyor Mk5 (480 items/min).",
        packRequirements={
            { itemId="automaton_core", count=20 },
            { itemId="resonance_core", count=10 },
        },
        unlocks={"conveyor_mk5"},
        prerequisite="tier5_main",
    },

    tier5_scout_drones = {
        id="tier5_scout_drones", name="Scout Drones", isSideBranch=true,
        description="Unlock Scout Drones to reveal rare node locations before mining.",
        packRequirements={
            { itemId="automaton_core", count=10 },
            { itemId="resonance_core", count=5 },
        },
        unlocks={"scout_drone"},
        prerequisite="tier4_drone_network",
    },
}

return Research
```

- [ ] **Step 4: Run test — confirm PASS**

Expected: `ResearchData` describe block: 6 PASS.

- [ ] **Step 5: Commit**

```bash
git add src/shared/data/ResearchData.luau tests/shared/data/ResearchData.spec.luau
git commit -m "feat: ResearchData module — full research tree + spec"
```

---

### Task 6: Biome & Rare Node Data

**Files:**
- Create: `src/shared/data/BiomeData.luau`
- Create: `src/shared/data/RareNodeData.luau`
- Create: `tests/shared/data/BiomeData.spec.luau`

**Interfaces:**
- Consumes: `ItemData`, `ResearchData`, `Constants`
- Produces: `BiomeData[biomeId]`, `RareNodeData[rareNodeId]` — used by BiomeService, RareNodeService

- [ ] **Step 1: Write the failing test**

Create `tests/shared/data/BiomeData.spec.luau`:

```lua
--!strict
return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local BiomeData    = require(ReplicatedStorage.Shared.data.BiomeData)
    local RareNodeData = require(ReplicatedStorage.Shared.data.RareNodeData)
    local ItemData     = require(ReplicatedStorage.Shared.data.ItemData)
    local ResearchData = require(ReplicatedStorage.Shared.data.ResearchData)
    local Constants    = require(ReplicatedStorage.Shared.Constants)

    describe("BiomeData", function()
        it("contains exactly 5 biomes", function()
            local count = 0
            for _ in pairs(BiomeData) do count += 1 end
            expect(count).to.equal(5)
        end)

        it("every biome node itemId exists in ItemData", function()
            for biomeId, biome in pairs(BiomeData) do
                for _, node in ipairs(biome.nodes) do
                    expect(ItemData[node.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("unlock research ids exist in ResearchData when non-nil", function()
            for _, biome in pairs(BiomeData) do
                if biome.unlockResearchId then
                    expect(ResearchData[biome.unlockResearchId] ~= nil).to.equal(true)
                end
            end
        end)

        it("exactly one biome has no unlock (starting biome)", function()
            local startCount = 0
            for _, biome in pairs(BiomeData) do
                if biome.unlockResearchId == nil then
                    startCount += 1
                end
            end
            expect(startCount).to.equal(1)
        end)
    end)

    describe("RareNodeData", function()
        it("contains exactly 10 rare nodes", function()
            local count = 0
            for _ in pairs(RareNodeData) do count += 1 end
            expect(count).to.equal(10)
        end)

        it("every rare node biomeId exists in BiomeData", function()
            for _, node in pairs(RareNodeData) do
                expect(BiomeData[node.biomeId] ~= nil).to.equal(true)
            end
        end)

        it("every outputItemId exists in ItemData", function()
            for _, node in pairs(RareNodeData) do
                expect(ItemData[node.outputItemId] ~= nil).to.equal(true)
            end
        end)

        it("spawn chances match Constants.RARE_NODE_CHANCE", function()
            for _, node in pairs(RareNodeData) do
                local expected = Constants.RARE_NODE_CHANCE[node.rarity]
                expect(node.spawnChance).to.equal(expected)
            end
        end)

        it("has exactly 3 legendary nodes", function()
            local count = 0
            for _, node in pairs(RareNodeData) do
                if node.rarity == "legendary" then count += 1 end
            end
            expect(count).to.equal(3)
        end)
    end)
end
```

- [ ] **Step 2: Run test — confirm FAIL**

Expected: fails with module not found.

- [ ] **Step 3: Create src/shared/data/BiomeData.luau**

```lua
--!strict

export type NodeDef = {
    itemId: string,
    richness: "rich" | "standard" | "sparse",
    count: number,
}

export type GeographicFeature = {
    name: string,
    description: string,
    counter: string?,
}

export type BiomeDef = {
    id: string,
    name: string,
    description: string,
    unlockResearchId: string?,
    nodes: {NodeDef},
    features: {GeographicFeature},
    visualTheme: string,
}

local Biomes: {[string]: BiomeDef} = {

    verdant_hollow = {
        id="verdant_hollow", name="Verdant Hollow", visualTheme="earthen",
        description="Mossy stone walls, warm lantern light, old oaks, a brook cutting through the center.",
        unlockResearchId=nil,
        nodes={
            { itemId="wood",       richness="rich",     count=8 },
            { itemId="stone",      richness="standard", count=5 },
            { itemId="iron_ore",   richness="sparse",   count=3 },
            { itemId="copper_ore", richness="sparse",   count=3 },
            { itemId="coal",       richness="sparse",   count=2 },
        },
        features={
            { name="River",        description="Bisects the plot — blocks conveyor paths.", counter="Conveyor Bridge (5 Iron Plates)" },
            { name="Dense Forest", description="Blocks building until cleared.", counter="Lumber Mill clear mode" },
        },
    },

    highland_reach = {
        id="highland_reach", name="Highland Reach", visualTheme="highland",
        description="Rugged cliffsides, exposed ore veins, mountain fog, rickety mine scaffolding.",
        unlockResearchId="tier2_biome2",
        nodes={
            { itemId="iron_ore",   richness="rich",     count=8 },
            { itemId="copper_ore", richness="rich",     count=8 },
            { itemId="coal",       richness="standard", count=5 },
            { itemId="granite",    richness="standard", count=6 },
        },
        features={
            { name="Elevation Changes",    description="Slope terrain prevents flat conveyor runs.", counter="Conveyor Ramp (5 Iron Plates + 5 Granite each)" },
            { name="Rocky Outcroppings",   description="Forces non-linear conveyor routing.", counter=nil },
            { name="Mine Shaft Deposits",  description="Miner Mk2+ placed here yields 2× output.", counter=nil },
        },
    },

    volcanic_depths = {
        id="volcanic_depths", name="Volcanic Depths", visualTheme="volcanic",
        description="Glowing lava channels, black rock, heat shimmer, distant low rumbling.",
        unlockResearchId="tier3_biome3",
        nodes={
            { itemId="coal",     richness="rich",     count=8 },
            { itemId="obsidian", richness="standard", count=5 },
            { itemId="sulphur",  richness="sparse",   count=3 },
            { itemId="iron_ore", richness="standard", count=4 },
        },
        features={
            { name="Lava Channels",   description="Permanent unbuildable terrain spanning the biome.", counter="Route around" },
            { name="Heat Vents",      description="Special tiles: +15% output to adjacent machines.", counter=nil },
            { name="Unstable Ground", description="Only lightweight machines (Storage, Splitters) can be placed.", counter=nil },
        },
    },

    crystal_caverns = {
        id="crystal_caverns", name="Crystal Caverns", visualTheme="crystal",
        description="Underground expanse, glowing crystal formations, bioluminescent moss, eerie quiet.",
        unlockResearchId="tier4_biome4",
        nodes={
            { itemId="crystal_shard",   richness="standard", count=6 },
            { itemId="resonance_stone", richness="sparse",   count=3 },
            { itemId="quartz",          richness="standard", count=5 },
            { itemId="copper_ore",      richness="rich",     count=6 },
        },
        features={
            { name="Stalactite Fields",  description="Blocks overhead conveyor paths.", counter="Lower routing" },
            { name="Resonance Zones",    description="+20% Research Station speed if placed within range.", counter=nil },
            { name="Crystal Formations", description="Aesthetically prominent, unbuildable.", counter=nil },
        },
    },

    aether_rift = {
        id="aether_rift", name="Aether Rift", visualTheme="aether",
        description="Reality fractures here. Floating islands drift. Glowing rifts tear the terrain.",
        unlockResearchId="tier5_biome5",
        nodes={
            { itemId="aether_crystal", richness="sparse", count=4 },
            { itemId="void_stone",     richness="sparse", count=3 },
        },
        features={
            { name="Floating Islands",  description="Best Aether nodes are island-only.", counter="Aether Bridge (Automaton Core cost)" },
            { name="Rift Zones",        description="Unbuildable areas that shift slowly over time.", counter="Monitor + reroute" },
            { name="Gravity Anomalies", description="Conveyors run at 50% speed in affected areas.", counter="Aether Dampener (crafted from Void Stone)" },
        },
    },
}

return Biomes
```

- [ ] **Step 4: Create src/shared/data/RareNodeData.luau**

```lua
--!strict

local Constants = require(script.Parent.Parent.Constants)

export type RareNodeDef = {
    id: string,
    name: string,
    biomeId: string,
    sourceNodeItemId: string,
    rarity: "uncommon" | "rare" | "legendary",
    spawnChance: number,
    outputItemId: string,
    serverAnnouncement: string, -- use {player} as placeholder
    gameplayNote: string,
}

local RareNodes: {[string]: RareNodeDef} = {

    starfire_iron = {
        id="starfire_iron", name="Starfire Iron",
        biomeId="verdant_hollow", sourceNodeItemId="iron_ore",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="starfire_ingot",
        serverAnnouncement="{player} has struck Starfire Iron in the Verdant Hollow!",
        gameplayNote="Used in the Masterwork Smelter recipe. Displayable in Trophy Case.",
    },

    mooncopper = {
        id="mooncopper", name="Mooncopper",
        biomeId="verdant_hollow", sourceNodeItemId="copper_ore",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="mooncopper_ingot",
        serverAnnouncement="{player} has struck Mooncopper in the Verdant Hollow!",
        gameplayNote="Used in the Masterwork Wire Refinery recipe. Displayable in Trophy Case.",
    },

    gilded_vein = {
        id="gilded_vein", name="Gilded Vein",
        biomeId="highland_reach", sourceNodeItemId="iron_ore",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="gilded_alloy",
        serverAnnouncement="{player} has struck a Gilded Vein in the Highland Reach!",
        gameplayNote="Used in the Masterwork Gear Press recipe. Displayable in Trophy Case.",
    },

    embercoal = {
        id="embercoal", name="Embercoal",
        biomeId="highland_reach", sourceNodeItemId="coal",
        rarity="uncommon", spawnChance=Constants.RARE_NODE_CHANCE.uncommon,
        outputItemId="embercoal",
        serverAnnouncement="{player} found Embercoal in the Highland Reach.",
        gameplayNote="Feed to any Forge for +50% output for 60 seconds.",
    },

    obsidian_heart = {
        id="obsidian_heart", name="Obsidian Heart",
        biomeId="volcanic_depths", sourceNodeItemId="obsidian",
        rarity="legendary", spawnChance=Constants.RARE_NODE_CHANCE.legendary,
        outputItemId="heart_of_obsidian",
        serverAnnouncement="{player} has uncovered the Heart of Obsidian in the Volcanic Depths!",
        gameplayNote="Trophy display only. Pure prestige — no recipe.",
    },

    sulphur_crown = {
        id="sulphur_crown", name="Sulphur Crown",
        biomeId="volcanic_depths", sourceNodeItemId="sulphur",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="pure_sulphur",
        serverAnnouncement="{player} has found a Sulphur Crown in the Volcanic Depths!",
        gameplayNote="Used in the Masterwork Conductor Coil recipe.",
    },

    prismatic_crystal = {
        id="prismatic_crystal", name="Prismatic Crystal",
        biomeId="crystal_caverns", sourceNodeItemId="crystal_shard",
        rarity="legendary", spawnChance=Constants.RARE_NODE_CHANCE.legendary,
        outputItemId="prismatic_shard",
        serverAnnouncement="{player} has found a Prismatic Crystal in the Crystal Caverns!",
        gameplayNote="Unlocks cosmetic Crystal Resonator skin. Displayable in Trophy Case.",
    },

    resonance_geode = {
        id="resonance_geode", name="Resonance Geode",
        biomeId="crystal_caverns", sourceNodeItemId="resonance_stone",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="resonance_gem",
        serverAnnouncement="{player} has unearthed a Resonance Geode in the Crystal Caverns!",
        gameplayNote="Counts as 5 Resonance Cores in any Tier 5 recipe.",
    },

    void_shard = {
        id="void_shard", name="Void Shard",
        biomeId="aether_rift", sourceNodeItemId="void_stone",
        rarity="legendary", spawnChance=Constants.RARE_NODE_CHANCE.legendary,
        outputItemId="void_fragment",
        serverAnnouncement="{player} has torn a Void Shard from the Aether Rift!",
        gameplayNote="Required for the secret Void Ascendant Blueprint. Trophy display.",
    },

    aether_bloom = {
        id="aether_bloom", name="Aether Bloom",
        biomeId="aether_rift", sourceNodeItemId="aether_crystal",
        rarity="rare", spawnChance=Constants.RARE_NODE_CHANCE.rare,
        outputItemId="pure_aether_bloom",
        serverAnnouncement="{player} has found an Aether Bloom in the Aether Rift!",
        gameplayNote="Counts as 10 Pure Aether in the Ascension activation cost.",
    },
}

return RareNodes
```

- [ ] **Step 5: Run test — confirm PASS**

Expected: `BiomeData` (4 PASS) + `RareNodeData` (5 PASS) = 9 total PASS.

- [ ] **Step 6: Commit**

```bash
git add src/shared/data/BiomeData.luau src/shared/data/RareNodeData.luau tests/shared/data/BiomeData.spec.luau
git commit -m "feat: BiomeData and RareNodeData modules + spec"
```

---

### Task 7: Remotes + Test Runner

**Files:**
- Create: `src/shared/Remotes.luau`
- Create: `tests/run_tests.server.luau`

**Interfaces:**
- Consumes: nothing
- Produces: `Remotes.RareNodeDiscovered`, `Remotes.ServerAnnouncement`, `Remotes.ResearchTierUnlocked`, `Remotes.AscensionTriggered` — used by RareNodeService, ResearchService

- [ ] **Step 1: Create src/shared/Remotes.luau**

```lua
--!strict
-- Non-Knit RemoteEvents for server-to-all-clients broadcasts.
-- Knit services expose their own per-client signals via their Client tables.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = RunService:IsServer()

local function getOrCreate(name: string): RemoteEvent
    if IS_SERVER then
        local existing = ReplicatedStorage:FindFirstChild(name)
        if existing and existing:IsA("RemoteEvent") then
            return existing :: RemoteEvent
        end
        local event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = ReplicatedStorage
        return event
    else
        local found = ReplicatedStorage:WaitForChild(name, 10)
        assert(found and found:IsA("RemoteEvent"), "Remote not found: " .. name)
        return found :: RemoteEvent
    end
end

--[[
    Fired server→all-clients when a rare node is discovered.
    Args: (playerName: string, rareNodeId: string, announcement: string)
]]
local RareNodeDiscovered: RemoteEvent = getOrCreate("RareNodeDiscovered")

--[[
    Fired server→all-clients for generic server announcements.
    Args: (message: string)
]]
local ServerAnnouncement: RemoteEvent = getOrCreate("ServerAnnouncement")

--[[
    Fired server→all-clients when the plot owner unlocks a new tier.
    Args: (ownerName: string, tier: number)
]]
local ResearchTierUnlocked: RemoteEvent = getOrCreate("ResearchTierUnlocked")

--[[
    Fired server→all-clients when Ascension is triggered.
    Args: (ownerName: string, ascensionCount: number)
]]
local AscensionTriggered: RemoteEvent = getOrCreate("AscensionTriggered")

return {
    RareNodeDiscovered   = RareNodeDiscovered,
    ServerAnnouncement   = ServerAnnouncement,
    ResearchTierUnlocked = ResearchTierUnlocked,
    AscensionTriggered   = AscensionTriggered,
}
```

- [ ] **Step 2: Create tests/run_tests.server.luau**

```lua
--!strict
-- Test entry point. Run this script in a test.project.json Studio session
-- to execute all TestEZ specs under ReplicatedStorage.Shared.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DevPackages = ReplicatedStorage:WaitForChild("DevPackages")
local TestEZ = require(DevPackages:WaitForChild("TestEZ"))

local results = TestEZ.TestBootstrap:run({
    ReplicatedStorage.Shared,   -- runs any *.spec.luau under Shared
    ServerScriptService.Tests,  -- runs any *.spec.luau under Tests
})

if results.failureCount > 0 then
    error(string.format("[TestEZ] %d test(s) FAILED", results.failureCount))
else
    print(string.format("[TestEZ] All %d test(s) PASSED", results.successCount))
end
```

- [ ] **Step 3: Commit**

```bash
git add src/shared/Remotes.luau tests/run_tests.server.luau
git commit -m "feat: Remotes module + TestEZ runner"
```

---

### Task 8: Server Entry Point + Service Stubs

**Files:**
- Create: `src/server/init.server.luau`
- Create: `src/server/services/MachineService.luau`
- Create: `src/server/services/ConveyorService.luau`
- Create: `src/server/services/PowerService.luau`
- Create: `src/server/services/ResearchService.luau`
- Create: `src/server/services/BiomeService.luau`
- Create: `src/server/services/DroneService.luau`
- Create: `src/server/services/RareNodeService.luau`
- Create: `src/server/services/SaveService.luau`
- Create: `src/server/services/PlotService.luau`

**Interfaces:**
- Consumes: `Types`, `Constants`, `MachineData`, `ItemData`, `ResearchData`, `BiomeData`, `RareNodeData`, `Remotes`, Knit
- Produces: 9 Knit services with documented method signatures — implemented in Milestone 3

- [ ] **Step 1: Create src/server/init.server.luau**

```lua
--!strict
-- Server bootstrap: loads all Knit services then starts the framework.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

Knit.AddServicesDeep(ServerScriptService.Server.services)

Knit.Start():andThen(function()
    print("[CogsworthFactory] Server started.")
end):catch(function(err)
    warn("[CogsworthFactory] Server startup error:", err)
end)
```

- [ ] **Step 2: Create src/server/services/MachineService.luau**

```lua
--!strict
-- Manages machine placement, removal, efficiency tracking, and specialization.
-- Server-authoritative: all client build requests validated here before applying.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type MachineInstance = Types.MachineInstance
type TilePosition = Types.TilePosition

local MachineService = Knit.CreateService({
    Name = "MachineService",
    Client = {
        -- Fired when a machine's efficiency % changes (throttled to MACHINE_EFFICIENCY_UPDATE_HZ)
        EfficiencyChanged = Knit.CreateSignal(), -- (instanceId: string, efficiency: number)
        -- Fired when any machine is placed on the plot
        MachinePlaced = Knit.CreateSignal(),     -- (machine: MachineInstance)
        -- Fired when any machine is removed
        MachineRemoved = Knit.CreateSignal(),    -- (instanceId: string)
    },
})

-- Place a machine. Returns (success, errorMessage?).
-- Validates: plot ownership, tile empty, materials available, tier unlocked.
-- On success: deducts build cost, creates MachineInstance, fires MachinePlaced.
function MachineService:PlaceMachine(
    player: Player,
    machineId: string,
    position: TilePosition,
    rotation: number
): (boolean, string?)
    return false, "not implemented"
end

-- Remove a machine by instanceId. Returns 100% of build materials to player storage.
function MachineService:RemoveMachine(player: Player, instanceId: string): boolean
    return false
end

-- Apply a specialization to a machine. Permanent and irreversible.
-- Returns (success, errorMessage?).
function MachineService:SpecializeMachine(
    player: Player,
    instanceId: string,
    specializationId: string
): (boolean, string?)
    return false, "not implemented"
end

-- Returns current efficiency 0–100 for a machine instance.
function MachineService:GetEfficiency(instanceId: string): number
    return 0
end

-- Called by ConveyorService every simulation tick.
-- Attempts to consume items from inputBuffer and advance outputBuffer.
function MachineService:Tick(instanceId: string, deltaTime: number)
end

function MachineService:KnitInit() end
function MachineService:KnitStart() end

return MachineService
```

- [ ] **Step 3: Create src/server/services/ConveyorService.luau**

```lua
--!strict
-- Manages conveyor placement and batched item transport between machine buffers.
-- Items move in batches per MACHINE_EFFICIENCY_UPDATE_HZ, not per-frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type TilePosition = Types.TilePosition

local ConveyorService = Knit.CreateService({
    Name = "ConveyorService",
    Client = {
        ConveyorPlaced  = Knit.CreateSignal(), -- (segmentId: string, tier: number, from: TilePosition, to: TilePosition)
        ConveyorRemoved = Knit.CreateSignal(), -- (segmentId: string)
        JamDetected     = Knit.CreateSignal(), -- (segmentId: string) — fired when throughput is blocked
    },
})

-- Place one conveyor segment. Returns (success, errorMessage?).
function ConveyorService:PlaceSegment(
    player: Player,
    tier: number,
    fromPosition: TilePosition,
    toPosition: TilePosition
): (boolean, string?)
    return false, "not implemented"
end

-- Remove a segment by segmentId. Refunds build materials.
function ConveyorService:RemoveSegment(player: Player, segmentId: string): boolean
    return false
end

-- Returns throughput utilisation 0–1 for a segment (1 = at capacity).
function ConveyorService:GetUtilisation(segmentId: string): number
    return 0
end

-- Run one transport tick for all conveyors on a plot.
-- Moves items from source machine outputBuffer toward destination inputBuffer.
-- Called by the main server loop at MACHINE_EFFICIENCY_UPDATE_HZ.
function ConveyorService:TickPlot(plotOwnerId: number, deltaTime: number)
end

function ConveyorService:KnitInit() end
function ConveyorService:KnitStart() end

return ConveyorService
```

- [ ] **Step 4: Create src/server/services/PowerService.luau**

```lua
--!strict
-- Calculates power balance for each plot. Triggers blackout events when demand > supply.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local PowerService = Knit.CreateService({
    Name = "PowerService",
    Client = {
        PowerBalanceUpdated = Knit.CreateSignal(), -- (balance: number) — positive = surplus
        BlackoutStarted     = Knit.CreateSignal(), -- () — fired when plot enters blackout
        BlackoutEnded       = Knit.CreateSignal(), -- () — fired when power restored
    },
})

-- Returns total generation (PU) for a plot.
function PowerService:GetGeneration(plotOwnerId: number): number
    return 0
end

-- Returns total demand (PU) for all powered machines on a plot.
function PowerService:GetDemand(plotOwnerId: number): number
    return 0
end

-- Returns true if the plot is currently in a blackout.
function PowerService:IsBlackout(plotOwnerId: number): boolean
    return false
end

-- Recalculate power balance and fire events if state changed.
-- Called at POWER_UPDATE_HZ by the server loop.
function PowerService:TickPlot(plotOwnerId: number)
end

function PowerService:KnitInit() end
function PowerService:KnitStart() end

return PowerService
```

- [ ] **Step 5: Create src/server/services/ResearchService.luau**

```lua
--!strict
-- Manages research pack delivery, tier progression, and side-branch unlocks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local ResearchService = Knit.CreateService({
    Name = "ResearchService",
    Client = {
        ResearchProgressUpdated = Knit.CreateSignal(), -- (researchId: string, progress: number, required: number)
        ResearchCompleted       = Knit.CreateSignal(), -- (researchId: string, unlocks: {string})
    },
})

-- Returns the currently active research node for a plot (the one consuming packs).
function ResearchService:GetActiveResearch(plotOwnerId: number): string?
    return nil
end

-- Set which research node should actively consume packs.
-- Player must own the plot. Returns (success, errorMessage?).
function ResearchService:SetActiveResearch(player: Player, researchId: string): (boolean, string?)
    return false, "not implemented"
end

-- Returns true if a research node is completed for a plot.
function ResearchService:IsCompleted(plotOwnerId: number, researchId: string): boolean
    return false
end

-- Called when the Research Station receives a valid pack item.
-- Advances progress toward the active research node.
function ResearchService:OnPackDelivered(plotOwnerId: number, itemId: string)
end

function ResearchService:KnitInit() end
function ResearchService:KnitStart() end

return ResearchService
```

- [ ] **Step 6: Create src/server/services/BiomeService.luau**

```lua
--!strict
-- Manages biome unlock state and resource node placement per biome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local BiomeService = Knit.CreateService({
    Name = "BiomeService",
    Client = {
        BiomeUnlocked = Knit.CreateSignal(), -- (biomeId: string)
    },
})

-- Returns list of unlocked biome ids for a plot.
function BiomeService:GetUnlockedBiomes(plotOwnerId: number): {string}
    return {}
end

-- Called by ResearchService when a biome unlock is completed.
function BiomeService:UnlockBiome(plotOwnerId: number, biomeId: string)
end

-- Returns true if a given tile position is within an unlocked biome.
function BiomeService:IsTileAccessible(plotOwnerId: number, position: {x: number, z: number}): boolean
    return false
end

function BiomeService:KnitInit() end
function BiomeService:KnitStart() end

return BiomeService
```

- [ ] **Step 7: Create src/server/services/DroneService.luau**

```lua
--!strict
-- Manages the Drone Network: task queuing, drone assignment, logistic/construction execution.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type DroneTask = Types.DroneTask

local DroneService = Knit.CreateService({
    Name = "DroneService",
    Client = {
        DroneTaskStarted    = Knit.CreateSignal(), -- (droneId: string, task: DroneTask)
        DroneTaskCompleted  = Knit.CreateSignal(), -- (droneId: string)
        ActiveDroneCount    = Knit.CreateSignal(), -- (count: number)
    },
})

-- Returns number of active drones on a plot.
function DroneService:GetActiveDroneCount(plotOwnerId: number): number
    return 0
end

-- Place a Blueprint ghost. Construction Drones will auto-build it.
-- ghostId identifies this ghost; machineId + position define what to build.
function DroneService:QueueBlueprintGhost(
    plotOwnerId: number,
    ghostId: string,
    machineId: string,
    position: {x: number, z: number},
    rotation: number
)
end

-- Cancel a pending ghost (before drones start building it).
function DroneService:CancelGhost(plotOwnerId: number, ghostId: string): boolean
    return false
end

-- Tick drone tasks forward. Called at POWER_UPDATE_HZ by the server loop.
function DroneService:TickPlot(plotOwnerId: number, deltaTime: number)
end

function DroneService:KnitInit() end
function DroneService:KnitStart() end

return DroneService
```

- [ ] **Step 8: Create src/server/services/RareNodeService.luau**

```lua
--!strict
-- Rolls rare node chance when a Miner is placed. Fires server-wide announcements.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type RareNodeRoll = Types.RareNodeRoll

local RareNodeService = Knit.CreateService({
    Name = "RareNodeService",
    Client = {
        -- Fired when the local player finds a rare node
        RareNodeFound = Knit.CreateSignal(), -- (roll: RareNodeRoll)
    },
})

-- Called by MachineService when a Miner is placed on a resource node.
-- Returns RareNodeRoll if a rare was triggered, nil otherwise.
-- Fires server-wide RemoteEvent on rare/legendary discoveries.
function RareNodeService:RollNode(
    player: Player,
    baseItemId: string,
    biomeId: string
): RareNodeRoll?
    return nil
end

-- Returns items currently stored in the trophy case for a plot.
function RareNodeService:GetTrophyCase(plotOwnerId: number): {string?}
    return {}
end

-- Place a rare item into a trophy case slot (0–8). Returns (success, errorMessage?).
function RareNodeService:SetTrophySlot(
    player: Player,
    slot: number,
    itemId: string?
): (boolean, string?)
    return false, "not implemented"
end

function RareNodeService:KnitInit() end
function RareNodeService:KnitStart() end

return RareNodeService
```

- [ ] **Step 9: Create src/server/services/SaveService.luau**

```lua
--!strict
-- Serializes and deserializes full PlotState to/from Roblox DataStores.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type PlotState = Types.PlotState

local SaveService = Knit.CreateService({
    Name = "SaveService",
    Client = {},
})

-- Load PlotState for a player. Returns nil if no save exists (new player).
function SaveService:LoadPlot(player: Player): PlotState?
    return nil
end

-- Persist PlotState. Called every SAVE_INTERVAL_SECONDS and on player leave.
function SaveService:SavePlot(player: Player, state: PlotState): boolean
    return false
end

-- Wipe save data for a player (used on Ascension reset after state is confirmed saved).
function SaveService:WipePlot(player: Player): boolean
    return false
end

function SaveService:KnitInit() end

function SaveService:KnitStart()
    -- Set up auto-save loop at Constants.SAVE_INTERVAL_SECONDS
    -- Set up player leaving hook to save on disconnect
end

return SaveService
```

- [ ] **Step 10: Create src/server/services/PlotService.luau**

```lua
--!strict
-- Manages plot ownership, co-op membership, and permission checks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type CoopRole = Types.CoopRole

local PlotService = Knit.CreateService({
    Name = "PlotService",
    Client = {
        CoopMemberAdded   = Knit.CreateSignal(), -- (playerId: number, role: CoopRole)
        CoopMemberRemoved = Knit.CreateSignal(), -- (playerId: number)
        RoleChanged       = Knit.CreateSignal(), -- (playerId: number, newRole: CoopRole)
    },
})

-- Returns the role a player has on a given plot. "visitor" if not a member.
function PlotService:GetRole(actor: Player, plotOwnerId: number): CoopRole
    return "visitor"
end

-- Returns true if actor has at least the given role on the plot.
function PlotService:HasPermission(actor: Player, plotOwnerId: number, minimumRole: CoopRole): boolean
    return false
end

-- Invite a player to co-build. Owner only. Max 3 co-builders. Returns (success, errorMessage?).
function PlotService:InviteMember(owner: Player, targetPlayerId: number, role: CoopRole): (boolean, string?)
    return false, "not implemented"
end

-- Remove a co-builder. Owner only.
function PlotService:RemoveMember(owner: Player, targetPlayerId: number): boolean
    return false
end

function PlotService:KnitInit() end
function PlotService:KnitStart() end

return PlotService
```

- [ ] **Step 11: Verify Rojo build includes all services**

```bash
rojo build default.project.json --output build-check.rbxl
```

Expected: exits 0. Delete the file after.

- [ ] **Step 12: Commit**

```bash
git add src/server/
git commit -m "feat: server entry point + 9 Knit service stubs"
```

---

### Task 9: Client Entry Point + Controller + GUI Stubs

**Files:**
- Create: `src/client/init.client.luau`
- Create: `src/client/controllers/BuildController.luau`
- Create: `src/client/controllers/UIController.luau`
- Create: `src/client/controllers/InputController.luau`
- Create: `src/client/controllers/DroneController.luau`
- Create: `src/client/controllers/NotificationController.luau`
- Create: `src/gui/MainGui/init.luau`

**Interfaces:**
- Consumes: Knit (client-side), Remotes, Types
- Produces: 5 Knit controllers — implemented in Milestone 4 (UI)

- [ ] **Step 1: Create src/client/init.client.luau**

```lua
--!strict
-- Client bootstrap: loads all Knit controllers then starts the framework.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")

Knit.AddControllersDeep(playerScripts.Client.controllers)

Knit.Start():andThen(function()
    print("[CogsworthFactory] Client started for", localPlayer.Name)
end):catch(function(err)
    warn("[CogsworthFactory] Client startup error:", err)
end)
```

- [ ] **Step 2: Create src/client/controllers/BuildController.luau**

```lua
--!strict
-- Handles machine/conveyor placement UI: ghost preview, click-to-place, rotation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local BuildController = Knit.CreateController({ Name = "BuildController" })

-- Enter placement mode for a machine type. Shows ghost preview on cursor.
function BuildController:BeginPlacement(machineId: string)
end

-- Confirm placement at the current ghost position.
function BuildController:ConfirmPlacement()
end

-- Cancel current placement without placing anything.
function BuildController:CancelPlacement()
end

-- Rotate the placement ghost 90° clockwise.
function BuildController:RotateGhost()
end

-- Enter conveyor placement mode for a given tier.
function BuildController:BeginConveyorPlacement(tier: number)
end

function BuildController:KnitInit() end
function BuildController:KnitStart() end

return BuildController
```

- [ ] **Step 3: Create src/client/controllers/UIController.luau**

```lua
--!strict
-- Owns the main HUD: machine toolbar, research progress bar, efficiency overlays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local UIController = Knit.CreateController({ Name = "UIController" })

-- Show/hide the machine selection toolbar.
function UIController:SetToolbarVisible(visible: boolean)
end

-- Update the research progress bar (0–1).
function UIController:SetResearchProgress(fraction: number, researchName: string)
end

-- Show efficiency overlay on all visible machines.
function UIController:SetEfficiencyOverlayEnabled(enabled: boolean)
end

-- Open the Trophy Case display for a plot.
function UIController:OpenTrophyCase(plotOwnerId: number)
end

function UIController:KnitInit() end
function UIController:KnitStart() end

return UIController
```

- [ ] **Step 4: Create src/client/controllers/InputController.luau**

```lua
--!strict
-- Translates raw mouse/keyboard input into game actions.
-- Routes to BuildController for placement, UIController for menu toggles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local InputController = Knit.CreateController({ Name = "InputController" })

-- Returns the world position under the cursor snapped to the tile grid.
function InputController:GetCursorTilePosition(): {x: number, z: number}?
    return nil
end

function InputController:KnitInit() end

function InputController:KnitStart()
    -- Bind: R → RotateGhost
    -- Bind: Escape → CancelPlacement
    -- Bind: E → toggle toolbar
    -- Bind: left-click → ConfirmPlacement (when in placement mode)
end

return InputController
```

- [ ] **Step 5: Create src/client/controllers/DroneController.luau**

```lua
--!strict
-- Handles visual-only drone interpolation on the client.
-- Receives drone task events from DroneService and animates drone models.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local DroneController = Knit.CreateController({ Name = "DroneController" })

-- Spawn a drone model and begin animating it toward targetPosition.
-- droneId is used to update/remove the drone later.
function DroneController:SpawnDroneVisual(droneId: string, targetPosition: Vector3)
end

-- Despawn a drone model (called when task completes).
function DroneController:DespawnDroneVisual(droneId: string)
end

function DroneController:KnitInit() end
function DroneController:KnitStart() end

return DroneController
```

- [ ] **Step 6: Create src/client/controllers/NotificationController.luau**

```lua
--!strict
-- Displays server announcements (rare node discoveries, tier unlocks, ascension events)
-- and contextual Automaton Companion hints.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local NotificationController = Knit.CreateController({ Name = "NotificationController" })

-- Show a server-wide announcement banner (rare node, ascension, tier unlock).
-- priority: "low" | "high" | "legendary" — controls animation and duration.
function NotificationController:ShowAnnouncement(message: string, priority: string)
end

-- Show a contextual Automaton Companion hint bubble.
-- Auto-dismissed after 8 seconds or on player action.
function NotificationController:ShowHint(message: string)
end

-- Suppress all hints (player toggled off in Settings).
function NotificationController:SetHintsEnabled(enabled: boolean)
end

function NotificationController:KnitInit() end

function NotificationController:KnitStart()
    -- Subscribe to Remotes.RareNodeDiscovered → ShowAnnouncement
    -- Subscribe to Remotes.ResearchTierUnlocked → ShowAnnouncement
    -- Subscribe to Remotes.AscensionTriggered → ShowAnnouncement (legendary priority)
end

return NotificationController
```

- [ ] **Step 7: Create src/gui/MainGui/init.luau**

```lua
--!strict
-- Root ScreenGui for CogsworthFactory HUD.
-- All UI elements are created programmatically by UIController in KnitStart.
-- This file marks the folder as a ScreenGui instance in Rojo.

local ScreenGui = script.Parent

-- UIController populates children at runtime.
-- This module is intentionally minimal — UI structure lives in UIController.

return {}
```

- [ ] **Step 8: Final Rojo build + full test run**

```bash
rojo build test.project.json --output test-place.rbxl
```

Open `test-place.rbxl` in Studio, run `tests/run_tests.server.luau`.  
Expected: all specs PASS (ItemData: 6, MachineData: 8, ResearchData: 6, BiomeData+RareNodeData: 9).

Delete `test-place.rbxl` and `build-check.rbxl`.

- [ ] **Step 9: Final commit**

```bash
git add src/client/ src/gui/
git commit -m "feat: client entry point + 5 Knit controller stubs + MainGui"
```

- [ ] **Step 10: Tag Milestone 2**

```bash
git tag -a milestone-2 -m "Milestone 2 complete: repository setup and project structure"
```

---

## Self-Review

**Spec coverage:**
- §1–§9 (game design): No implementation required — data only. MachineData, ItemData, ResearchData, BiomeData, RareNodeData cover all 40 machines, 50 items, 21 research nodes, 5 biomes. ✅
- §10 (Blueprint System): DroneService.QueueBlueprintGhost stubs the construction drone auto-build path. Full Blueprint save/load is Milestone 3. ✅ stub
- §11 (Multiplayer Co-op): PlotService with CoopRole types and permission check stubs. ✅ stub
- §12 (Tutorial): NotificationController.ShowHint covers Automaton Companion. ✅ stub
- §13 (Achievements): No stub needed — achievements read game state; covered in Milestone 5.
- §14 (Monetization): No code required in Milestone 2.
- §17 (Engineering Notes): Server-authoritative constraint enforced in all service stubs (client requests validated server-side). Save interval constant defined. ✅
- §18 (Rare Discoveries): RareNodeData.luau with all 10 nodes, RareNodeService stub, Trophy Case slot method. ✅
- §19 (Drone Network): DroneService stub with ghost queuing and tick. DroneController for visuals. ✅

**Placeholder scan:** No TBD, TODO, or "implement later" text in implementation steps — all code blocks are complete. Stubs explicitly return sentinel values or empty tables, not TODO strings.

**Type consistency:**
- `TilePosition` defined in Types.luau and used consistently across all services ✅
- `PlotState` used in SaveService ✅
- `DroneTask` union type used in DroneService ✅
- `CoopRole` used in PlotService ✅
- `MachineInstance` used in MachineService ✅
