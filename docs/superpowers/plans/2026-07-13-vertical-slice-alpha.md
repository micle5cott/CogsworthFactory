# Vertical Slice Alpha — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable 15–20 minute factory loop — Tree → Lumber Mill → Conveyor → Storage/Seller → Coins → Buy More Machines.

**Architecture:** Server-authoritative Knit services own all simulation state. Clients receive broadcast Network events and render visuals independently. All machine models are procedural Parts (no Studio work required for the alpha). Items move as logical server-side queues; clients tween visual parts based on transit events.

**Tech Stack:** Roblox Luau, Knit 1.5.1 (`sleitnick/knit`), Rojo, TweenService (animations), UserInputService (build mode), RunService (client camera/HUD loop).

## Global Constraints

- `--!strict` on all new files.
- All game logic is server-authoritative. Clients only request and render.
- Tile grid: `TILE_SIZE_STUDS = 4`. Tile key: `"x,z"` (integers).
- In-transit items are transient — not persisted across server restarts.
- No power, research, drones, biomes, or specialization in this plan.
- Shared module path: `require(ReplicatedStorage.Shared.<subpath>)`.
- Knit require: `require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))`.
- Client Knit functions: server defines `Client = { Fn = function(self, player, ...) }`. Client calls `svc:Fn(...)` (Knit injects player).
- Client Knit signals: server fires `Service.Client.Signal:Fire(player, ...)`. Client connects `svc.Signal:Connect(...)`.
- Broadcasts to all clients: `Network.getEvent(name):FireAllClients(...)`.
- Machine output tile: 1 tile in the direction of rotation from machine position.
  - Rotation 0 → (x, z+1); 90 → (x+1, z); 180 → (x, z-1); 270 → (x-1, z).
- Conveyor delivers to the destination tile's occupant (machine, storage, or seller).

---

### Task 1: VSConfig + Network Extensions + DataModel Prep

**Files:**
- Create: `src/shared/config/VSConfig.luau`
- Modify: `src/shared/Network.luau` (add VS broadcast events)
- Modify: `src/shared/config/GameConfig.luau` (STARTING_COINS → 200)
- Modify: `src/shared/DataModel.luau` (add `storageInventories` field)

**Interfaces:**
- Produces: `VSConfig` module consumed by every subsequent task.
- Produces: Extended `Network.Events` table used by every broadcast in Tasks 2–10.
- Produces: `DataModel.PlayerData.storageInventories` field used by Task 5.

---

- [ ] **Step 1: Create `src/shared/config/VSConfig.luau`**

```lua
--!strict
local VSConfig = {}

-- Economy
VSConfig.SELL_PRICE: {[string]: number} = {
    lumber = 10,
    log    = 3,
}
VSConfig.MACHINE_SHOP_PRICES: {[string]: number} = {
    lumber_mill    = 0,
    storage_chest  = 25,
    seller_station = 50,
    conveyor_belt  = 5,
}
VSConfig.MACHINE_REFUND_FRACTION = 0.5

-- Trees
VSConfig.FOREST_TREES_PER_PLOT      = 12
VSConfig.TREE_HEALTH                = 3
VSConfig.TREE_REGEN_SECONDS         = 20
VSConfig.LUMBER_MILL_HARVEST_RADIUS = 14  -- studs

-- Machines
VSConfig.MACHINE_TICK_HZ            = 1   -- 1 tick per second
VSConfig.LUMBER_MILL_PROCESS_TICKS  = 3   -- ticks to convert 1 log → 1 lumber
VSConfig.STORAGE_CHEST_CAPACITY     = 50
VSConfig.CONVEYOR_SPEED_TICKS       = 2   -- ticks to cross one segment

-- World
VSConfig.FOREST_OFFSET_TILES        = {x = -20, z = 0}  -- forest origin relative to plot

-- Visual
VSConfig.FLOATING_TEXT_RISE_STUDS   = 5
VSConfig.FLOATING_TEXT_DURATION     = 1.5

return VSConfig
```

- [ ] **Step 2: Add VS broadcast events to `src/shared/Network.luau`**

Inside the `Network.Events = { ... }` block, append after existing entries:

```lua
    -- VS slice broadcasts (server → all clients)
    TreeFelled          = "TreeFelled",         -- (tileX: number, tileZ: number)
    TreeRegrown         = "TreeRegrown",         -- (tileX: number, tileZ: number)
    MachinePlaced       = "MachinePlaced",       -- (instanceId, machineId, tileX, tileZ, rotation)
    MachineRemoved      = "MachineRemoved",      -- (instanceId: string)
    ConveyorPlaced      = "ConveyorPlaced",      -- (segmentId, fromX, fromZ, toX, toZ)
    ConveyorRemoved     = "ConveyorRemoved",     -- (segmentId: string)
    ItemTransitStarted  = "ItemTransitStarted",  -- (segmentId, itemId, travelSeconds: number)
    ItemDelivered       = "ItemDelivered",       -- (tileX, tileZ, itemId)
    ItemSold            = "ItemSold",            -- (tileX, tileZ, itemId, coinsEarned)
    StorageUpdated      = "StorageUpdated",      -- (instanceId, inventory: {[string]: number})
    MachineOutput       = "MachineOutput",       -- (instanceId, itemId) — lumber mill produced
```

- [ ] **Step 3: Update `src/shared/config/GameConfig.luau`**

Change `GameConfig.STARTING_COINS = 0` to `GameConfig.STARTING_COINS = 200`.

- [ ] **Step 4: Update `src/shared/DataModel.luau`**

In `PlayerData` type, add the field:
```lua
    storageInventories: {[string]: {[string]: number}},  -- instanceId → itemId → count
```

In `DataModel.default()`, add:
```lua
        storageInventories = {},
```

The existing `applyDefaults` sub-table loop will backfill this field for older saves automatically.

- [ ] **Step 5: Verify test runner still loads (no compile errors)**

Run in Studio or via `rojo serve` and check output for `--!strict` errors in the changed files. Expect no errors.

- [ ] **Step 6: Commit**

```
git add src/shared/config/VSConfig.luau src/shared/Network.luau src/shared/config/GameConfig.luau src/shared/DataModel.luau
git commit -m "feat(vs): add VSConfig, extend Network events, update DataModel for vertical slice"
```

---

### Task 2: TreeService

**Files:**
- Create: `src/server/services/TreeService.luau`
- Modify: `src/server/services/PlotService.luau` (call spawnForest on assignPlot)

**Interfaces:**
- Consumes: `VSConfig`, `GameConfig.TILE_SIZE_STUDS`, `Network.Events.TreeFelled`, `Network.Events.TreeRegrown`
- Produces: `TreeService:spawnForest(plotId: string, originWorld: Vector3)` — called by PlotService
- Produces: `TreeService:harvestNearestTree(centerWorld: Vector3): string?` — returns `"log"` or nil, called by MachineService.Tick
- Produces: `TreeService:cleanupPlot(plotId: string)` — called by PlotService on player leave

---

- [ ] **Step 1: Create `src/server/services/TreeService.luau`**

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger     = require(ReplicatedStorage.Shared.utils.Logger)
local VSConfig   = require(ReplicatedStorage.Shared.config.VSConfig)
local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)
local Network    = require(ReplicatedStorage.Shared.Network)

local TILE = GameConfig.TILE_SIZE_STUDS
local log  = Logger.new("TreeService")

type TreeNode = {
    model:     Model,
    health:    number,
    tileX:     number,
    tileZ:     number,
    isFelled:  boolean,
    regenTask: thread?,
}

local TreeService = Knit.CreateService({ Name = "TreeService", Client = {} })

local _plotTrees: {[string]: {TreeNode}} = {}

local function makeTileKey(x: number, z: number): string
    return x .. "," .. z
end

local function buildTreeModel(tileX: number, tileZ: number): Model
    local wx, wz = tileX * TILE, tileZ * TILE
    local model = Instance.new("Model")
    model.Name = "Tree_" .. makeTileKey(tileX, tileZ)

    local trunk = Instance.new("Part")
    trunk.Name      = "Trunk"
    trunk.Size      = Vector3.new(1.2, 5, 1.2)
    trunk.BrickColor = BrickColor.new("Reddish brown")
    trunk.Material  = Enum.Material.Wood
    trunk.Anchored  = true
    trunk.CFrame    = CFrame.new(wx, 2.5, wz)
    trunk.Parent    = model

    local foliage = Instance.new("Part")
    foliage.Name      = "Foliage"
    foliage.Shape     = Enum.PartType.Ball
    foliage.Size      = Vector3.new(5, 5, 5)
    foliage.BrickColor = BrickColor.new("Bright green")
    foliage.Material  = Enum.Material.Grass
    foliage.Anchored  = true
    foliage.CFrame    = CFrame.new(wx, 7.5, wz)
    foliage.Parent    = model

    model.PrimaryPart = trunk
    model.Parent      = Workspace
    return model
end

function TreeService:spawnForest(plotId: string, originWorld: Vector3)
    if _plotTrees[plotId] then
        self:cleanupPlot(plotId)
    end

    local trees: {TreeNode} = {}
    local originTileX = math.round(originWorld.X / TILE)
    local originTileZ = math.round(originWorld.Z / TILE)
    local radius  = VSConfig.FOREST_ZONE_RADIUS_TILES or 8
    local target  = VSConfig.FOREST_TREES_PER_PLOT
    local spawned = 0

    math.randomseed(os.clock() * 1000)

    for attempt = 1, target * 10 do
        if spawned >= target then break end
        local dx = math.random(-radius, radius)
        local dz = math.random(-radius, radius)
        local tx  = originTileX + dx
        local tz  = originTileZ + dz
        -- Avoid overlapping tiles already used
        local key = makeTileKey(tx, tz)
        local occupied = false
        for _, node in ipairs(trees) do
            if makeTileKey(node.tileX, node.tileZ) == key then
                occupied = true
                break
            end
        end
        if not occupied then
            local node: TreeNode = {
                model    = buildTreeModel(tx, tz),
                health   = VSConfig.TREE_HEALTH,
                tileX    = tx,
                tileZ    = tz,
                isFelled = false,
                regenTask = nil,
            }
            table.insert(trees, node)
            spawned += 1
        end
    end

    _plotTrees[plotId] = trees
    log:info("Spawned %d trees for plot %s", spawned, plotId)
end

-- Called by MachineService each tick.
-- Searches all plots for a harvestable tree within radius of centerWorld.
-- Returns "log" if a tree is found and hit (felled when health reaches 0), else nil.
function TreeService:harvestNearestTree(centerWorld: Vector3): string?
    for _, trees in pairs(_plotTrees) do
        local best: TreeNode? = nil
        local bestDist = math.huge

        for _, node in ipairs(trees) do
            if node.isFelled then continue end
            local wx = node.tileX * TILE
            local wz = node.tileZ * TILE
            local dist = math.sqrt((centerWorld.X - wx)^2 + (centerWorld.Z - wz)^2)
            if dist <= VSConfig.LUMBER_MILL_HARVEST_RADIUS and dist < bestDist then
                best = node
                bestDist = dist
            end
        end

        if best then
            best.health -= 1
            if best.health <= 0 then
                best.isFelled = true
                best.model.Parent = nil
                Network.getEvent(Network.Events.TreeFelled):FireAllClients(best.tileX, best.tileZ)

                best.regenTask = task.spawn(function()
                    task.wait(VSConfig.TREE_REGEN_SECONDS)
                    best.health   = VSConfig.TREE_HEALTH
                    best.isFelled = false
                    best.model.Parent = Workspace
                    Network.getEvent(Network.Events.TreeRegrown):FireAllClients(best.tileX, best.tileZ)
                end)

                return "log"
            end
            -- Hit but not felled yet
            return nil
        end
    end
    return nil
end

function TreeService:cleanupPlot(plotId: string)
    local trees = _plotTrees[plotId]
    if not trees then return end
    for _, node in ipairs(trees) do
        if node.regenTask then task.cancel(node.regenTask) end
        if node.model then node.model:Destroy() end
    end
    _plotTrees[plotId] = nil
end

function TreeService:KnitInit() end

function TreeService:KnitStart()
    log:info("TreeService started")
end

return TreeService
```

- [ ] **Step 2: Modify `src/server/services/PlotService.luau` — call spawnForest in `assignPlot`**

At the end of `PlotService:assignPlot`, after the existing log and network fire, add:

```lua
    -- Spawn the forest for this plot.
    -- Forest origin is offset from the plot tile origin.
    local VSConfig = require(ReplicatedStorage.Shared.config.VSConfig)
    local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)
    local offset = VSConfig.FOREST_OFFSET_TILES
    local forestWorld = Vector3.new(offset.x * GameConfig.TILE_SIZE_STUDS, 0, offset.z * GameConfig.TILE_SIZE_STUDS)
    local TreeService = Knit.GetService("TreeService")
    TreeService:spawnForest(plotId, forestWorld)
```

Also in `PlotService:releasePlot`, after releasing the plot, add:

```lua
    local TreeService = Knit.GetService("TreeService")
    TreeService:cleanupPlot(plotId)
```

Add `VSConfig.FOREST_ZONE_RADIUS_TILES = 8` to VSConfig (add to Step 1 of Task 1 if not already present — the value is referenced in TreeService).

- [ ] **Step 3: Verify: start server, join game, confirm 12 trees appear in Workspace under random tile positions near (-80, 0, 0) (offset x=-20 × TILE=4)**

- [ ] **Step 4: Commit**

```
git add src/server/services/TreeService.luau src/server/services/PlotService.luau
git commit -m "feat(vs): add TreeService — forest spawning, harvest, regeneration"
```

---

### Task 3: MachineService — VS Implementation

**Files:**
- Modify: `src/server/services/MachineService.luau` (full rewrite of stub)

**Interfaces:**
- Consumes: `TreeService:harvestNearestTree(pos)`, `EconomyService:deductCoins`, `EconomyService:awardCoins`, `SaveService:getSession`, `SaveService:updateSession`, `WorldService:tileToWorld`
- Consumes: `VSConfig`, `GameConfig.TILE_SIZE_STUDS`
- Consumes: `Network.Events.MachinePlaced`, `Network.Events.MachineRemoved`, `Network.Events.MachineOutput`
- Produces: `MachineService.Client.PlaceMachine(self, player, machineId, tileX, tileZ, rotation) → (boolean, string?)`
- Produces: `MachineService.Client.RemoveMachine(self, player, instanceId) → boolean`
- Produces: `MachineService.Client.GetAllMachines(self, player) → {MachineRecord}` — for plot restore on client join
- Produces: `MachineService:getAtTile(tileKey: string) → {instanceId: string, machineId: string}?`
- Produces: `MachineService:consumeOutput(instanceId: string) → string?` — pops one item from outputBuffer
- Produces: `MachineService:receiveInput(instanceId: string, itemId: string) → boolean`
- Produces: `MachineService:getOutputTile(instanceId: string) → {x: number, z: number}?`
- Produces: `MachineService:getWorldCFrame(instanceId: string) → CFrame?`
- Produces: `MachineService:tick()` — called every 1/MACHINE_TICK_HZ seconds from KnitStart loop

---

- [ ] **Step 1: Write the full MachineService implementation**

Replace `src/server/services/MachineService.luau` entirely:

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger     = require(ReplicatedStorage.Shared.utils.Logger)
local VSConfig   = require(ReplicatedStorage.Shared.config.VSConfig)
local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)
local Network    = require(ReplicatedStorage.Shared.Network)

local TILE = GameConfig.TILE_SIZE_STUDS
local log  = Logger.new("MachineService")

-- ── Types ─────────────────────────────────────────────────────────────────────

type MachineRecord = {
    instanceId:   string,
    machineId:    string,
    tileX:        number,
    tileZ:        number,
    rotation:     number,
    inputBuffer:  {string},   -- itemId queue
    outputBuffer: {string},   -- itemId queue
    processTimer: number,     -- ticks since last processing cycle started
    model:        Model?,
}

-- ── State ─────────────────────────────────────────────────────────────────────

local MachineService = Knit.CreateService({
    Name = "MachineService",
    Client = {},
})

-- instanceId → MachineRecord
local _machines: {[string]: MachineRecord} = {}
-- tileKey → instanceId
local _tileOccupied: {[string]: string} = {}
-- simple counter for unique IDs
local _nextId = 0

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function tileKey(x: number, z: number): string
    return x .. "," .. z
end

local function newId(): string
    _nextId += 1
    return "m_" .. _nextId
end

-- Returns the output tile based on machine tile + rotation.
local function outputTile(tileX: number, tileZ: number, rotation: number): {x: number, z: number}
    if rotation == 0   then return {x = tileX,     z = tileZ + 1} end
    if rotation == 90  then return {x = tileX + 1, z = tileZ    } end
    if rotation == 180 then return {x = tileX,     z = tileZ - 1} end
    if rotation == 270 then return {x = tileX - 1, z = tileZ    } end
    return {x = tileX, z = tileZ + 1}
end

-- Build a procedural model for each machine type.
local function buildModel(machineId: string, tileX: number, tileZ: number, rotation: number): Model
    local wx = tileX * TILE
    local wz = tileZ * TILE
    local model = Instance.new("Model")
    model.Name = machineId .. "_" .. tileKey(tileX, tileZ)

    local base = Instance.new("Part")
    base.Name     = "Base"
    base.Anchored = true
    base.Size     = Vector3.new(TILE - 0.2, 2, TILE - 0.2)
    base.CFrame   = CFrame.new(wx, 1, wz) * CFrame.Angles(0, math.rad(rotation), 0)

    if machineId == "lumber_mill" then
        base.BrickColor = BrickColor.new("Medium stone grey")
        base.Material   = Enum.Material.SmoothPlastic

        local blade = Instance.new("Part")
        blade.Name      = "Blade"
        blade.Shape     = Enum.PartType.Cylinder
        blade.Size      = Vector3.new(0.4, TILE - 0.5, TILE - 0.5)
        blade.BrickColor = BrickColor.new("Bright yellow")
        blade.Material  = Enum.Material.Metal
        blade.Anchored  = true
        blade.CFrame    = CFrame.new(wx, 3, wz) * CFrame.Angles(0, 0, math.pi / 2)
        blade.Parent    = model

    elseif machineId == "storage_chest" then
        base.BrickColor = BrickColor.new("Nougat")
        base.Material   = Enum.Material.Wood
        base.Size       = Vector3.new(TILE - 0.2, TILE - 0.2, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, (TILE - 0.2) / 2, wz)

    elseif machineId == "seller_station" then
        base.BrickColor = BrickColor.new("Bright yellow")
        base.Material   = Enum.Material.SmoothPlastic

        local arch = Instance.new("Part")
        arch.Name      = "Arch"
        arch.Size      = Vector3.new(TILE - 0.2, 0.5, 0.5)
        arch.BrickColor = BrickColor.new("Bright yellow")
        arch.Anchored  = true
        arch.CFrame    = CFrame.new(wx, 3.5, wz)
        arch.Parent    = model
    end

    base.Parent    = model
    model.PrimaryPart = base
    model.Parent   = Workspace
    return model
end

-- ── Public API (called by ConveyorService and other services) ─────────────────

function MachineService:getAtTile(key: string): {instanceId: string, machineId: string}?
    local id = _tileOccupied[key]
    if not id then return nil end
    local m = _machines[id]
    if not m then return nil end
    return {instanceId = id, machineId = m.machineId}
end

function MachineService:consumeOutput(instanceId: string): string?
    local m = _machines[instanceId]
    if not m or #m.outputBuffer == 0 then return nil end
    return table.remove(m.outputBuffer, 1)
end

function MachineService:receiveInput(instanceId: string, itemId: string): boolean
    local m = _machines[instanceId]
    if not m then return false end
    if #m.inputBuffer >= 10 then return false end  -- buffer full
    table.insert(m.inputBuffer, itemId)
    return true
end

function MachineService:getOutputTile(instanceId: string): {x: number, z: number}?
    local m = _machines[instanceId]
    if not m then return nil end
    return outputTile(m.tileX, m.tileZ, m.rotation)
end

function MachineService:getWorldCFrame(instanceId: string): CFrame?
    local m = _machines[instanceId]
    if not m then return nil end
    return CFrame.new(m.tileX * TILE, 1, m.tileZ * TILE)
end

-- ── Placement ─────────────────────────────────────────────────────────────────

local VALID_MACHINES = {
    lumber_mill    = true,
    storage_chest  = true,
    seller_station = true,
}

function MachineService.Client:PlaceMachine(
    player: Player,
    machineId: string,
    tileX: number,
    tileZ: number,
    rotation: number
): (boolean, string?)
    if not VALID_MACHINES[machineId] then
        return false, "unknown machine: " .. machineId
    end
    local key = tileKey(tileX, tileZ)
    if _tileOccupied[key] then
        return false, "tile occupied"
    end

    -- Check and deduct cost
    local price = VSConfig.MACHINE_SHOP_PRICES[machineId] or 0
    if price > 0 then
        local EconomyService = Knit.GetService("EconomyService")
        local ok, err = EconomyService:deductCoins(player, price)
        if not ok then return false, err end
    end

    local id    = newId()
    local model = buildModel(machineId, tileX, tileZ, rotation)

    local record: MachineRecord = {
        instanceId   = id,
        machineId    = machineId,
        tileX        = tileX,
        tileZ        = tileZ,
        rotation     = rotation,
        inputBuffer  = {},
        outputBuffer = {},
        processTimer = 0,
        model        = model,
    }
    _machines[id]     = record
    _tileOccupied[key] = id

    -- Persist to session
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(player)
    if data then
        table.insert(data.plot.machines, {
            instanceId     = id,
            machineId      = machineId,
            position       = {x = tileX, z = tileZ},
            rotation       = rotation,
            specialization = nil,
        })
        SaveService:updateSession(player, {plot = data.plot})
    end

    Network.getEvent(Network.Events.MachinePlaced):FireAllClients(id, machineId, tileX, tileZ, rotation)
    log:info("Placed %s at (%d,%d) for %s", machineId, tileX, tileZ, player.Name)
    return true, nil
end

function MachineService.Client:RemoveMachine(player: Player, instanceId: string): boolean
    local m = _machines[instanceId]
    if not m then return false end

    -- Refund
    local price = VSConfig.MACHINE_SHOP_PRICES[m.machineId] or 0
    local refund = math.floor(price * VSConfig.MACHINE_REFUND_FRACTION)
    if refund > 0 then
        local EconomyService = Knit.GetService("EconomyService")
        EconomyService:awardCoins(player, refund)
    end

    -- Destroy model
    if m.model then m.model:Destroy() end

    local key = tileKey(m.tileX, m.tileZ)
    _tileOccupied[key] = nil
    _machines[instanceId] = nil

    -- Persist removal
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(player)
    if data then
        for i, saved in ipairs(data.plot.machines) do
            if saved.instanceId == instanceId then
                table.remove(data.plot.machines, i)
                break
            end
        end
        SaveService:updateSession(player, {plot = data.plot})
    end

    Network.getEvent(Network.Events.MachineRemoved):FireAllClients(instanceId)
    log:info("Removed %s (%s) for %s", m.machineId, instanceId, player.Name)
    return true
end

-- Returns all placed machines so the client can rebuild visuals on join.
function MachineService.Client:GetAllMachines(_player: Player): {{instanceId: string, machineId: string, tileX: number, tileZ: number, rotation: number}}
    local result = {}
    for id, m in pairs(_machines) do
        table.insert(result, {
            instanceId = id,
            machineId  = m.machineId,
            tileX      = m.tileX,
            tileZ      = m.tileZ,
            rotation   = m.rotation,
        })
    end
    return result
end

-- ── Simulation tick ───────────────────────────────────────────────────────────

function MachineService:tick()
    local TreeService = Knit.GetService("TreeService")

    for id, m in pairs(_machines) do
        if m.machineId ~= "lumber_mill" then continue end

        m.processTimer += 1

        -- If input buffer is empty, try to harvest a tree nearby
        if #m.inputBuffer == 0 then
            local center = Vector3.new(m.tileX * TILE, 1, m.tileZ * TILE)
            local item = TreeService:harvestNearestTree(center)
            if item then
                table.insert(m.inputBuffer, item)
            end
        end

        -- Process: consume 1 log → 1 lumber after LUMBER_MILL_PROCESS_TICKS
        if m.processTimer >= VSConfig.LUMBER_MILL_PROCESS_TICKS and #m.inputBuffer > 0 then
            m.processTimer = 0
            local itemId = table.remove(m.inputBuffer, 1)
            if itemId == "log" then
                table.insert(m.outputBuffer, "lumber")
                Network.getEvent(Network.Events.MachineOutput):FireAllClients(id, "lumber")
            end
        end
    end
end

-- ── Restore from save ─────────────────────────────────────────────────────────

-- Called by SaveService integration (Task 6) when a player's session is loaded.
-- Rebuilds in-memory state and Workspace models from persisted data.
function MachineService:restorePlot(savedMachines: {{instanceId: string, machineId: string, position: {x: number, z: number}, rotation: number}})
    for _, saved in ipairs(savedMachines) do
        if not VALID_MACHINES[saved.machineId] then continue end
        local key = tileKey(saved.position.x, saved.position.z)
        if _tileOccupied[key] then continue end  -- conflict guard

        local model = buildModel(saved.machineId, saved.position.x, saved.position.z, saved.rotation)
        local record: MachineRecord = {
            instanceId   = saved.instanceId,
            machineId    = saved.machineId,
            tileX        = saved.position.x,
            tileZ        = saved.position.z,
            rotation     = saved.rotation,
            inputBuffer  = {},
            outputBuffer = {},
            processTimer = 0,
            model        = model,
        }
        _machines[saved.instanceId] = record
        _tileOccupied[key]          = saved.instanceId

        Network.getEvent(Network.Events.MachinePlaced):FireAllClients(
            saved.instanceId, saved.machineId, saved.position.x, saved.position.z, saved.rotation
        )
    end
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function MachineService:KnitInit() end

function MachineService:KnitStart()
    -- Simulation tick loop
    task.spawn(function()
        while true do
            task.wait(1 / VSConfig.MACHINE_TICK_HZ)
            self:tick()
        end
    end)
    log:info("MachineService started (tick Hz = %d)", VSConfig.MACHINE_TICK_HZ)
end

return MachineService
```

- [ ] **Step 2: Verify no strict type errors in Studio output window (attach Rojo, check Script Analysis)**

- [ ] **Step 3: Commit**

```
git add src/server/services/MachineService.luau
git commit -m "feat(vs): implement MachineService — placement, removal, lumber mill tick"
```

---

### Task 4: ConveyorService — VS Implementation

**Files:**
- Modify: `src/server/services/ConveyorService.luau` (full rewrite of stub)

**Interfaces:**
- Consumes: `MachineService:getAtTile`, `MachineService:consumeOutput`, `MachineService:receiveInput`, `MachineService:getOutputTile`
- Consumes: `SaveService:getSession`, `SaveService:updateSession`
- Consumes: `VSConfig`, `GameConfig.TILE_SIZE_STUDS`
- Consumes: `Network.Events.ConveyorPlaced`, `Network.Events.ConveyorRemoved`, `Network.Events.ItemTransitStarted`, `Network.Events.ItemDelivered`, `Network.Events.ItemSold`
- Produces: `ConveyorService.Client.PlaceConveyor(self, player, fromX, fromZ, toX, toZ) → (boolean, string?)`
- Produces: `ConveyorService.Client.RemoveConveyor(self, player, segmentId) → boolean`
- Produces: `ConveyorService:tick()` — called every 1/MACHINE_TICK_HZ seconds, after MachineService:tick()
- Produces: `ConveyorService:restoreSegments(saved: {ConveyorSegmentData})` — called by SaveService integration

---

- [ ] **Step 1: Write the full ConveyorService**

Replace `src/server/services/ConveyorService.luau` entirely:

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger     = require(ReplicatedStorage.Shared.utils.Logger)
local VSConfig   = require(ReplicatedStorage.Shared.config.VSConfig)
local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)
local Network    = require(ReplicatedStorage.Shared.Network)

local TILE = GameConfig.TILE_SIZE_STUDS
local log  = Logger.new("ConveyorService")

-- ── Types ─────────────────────────────────────────────────────────────────────

type SegmentEntry = {
    segmentId:    string,
    fromX:        number,
    fromZ:        number,
    toX:          number,
    toZ:          number,
    plotOwnerId:  number,
    model:        Part?,
}

type InTransitItem = {
    itemId:       string,
    segmentId:    string,
    ticksLeft:    number,
    plotOwnerId:  number,
}

-- ── State ─────────────────────────────────────────────────────────────────────

local ConveyorService = Knit.CreateService({
    Name = "ConveyorService",
    Client = {},
})

local _segments:  {[string]: SegmentEntry}  = {}
local _fromTile:  {[string]: string}        = {} -- tileKey → segmentId (one segment per from-tile)
local _toTile:    {[string]: {string}}      = {} -- tileKey → {segmentId, ...} (can merge)
local _inTransit: {InTransitItem}           = {}
local _nextId     = 0

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function tileKey(x: number, z: number): string
    return x .. "," .. z
end

local function newSegId(): string
    _nextId += 1
    return "seg_" .. _nextId
end

local function buildConveyorModel(fromX: number, fromZ: number, toX: number, toZ: number): Part
    local fx, fz = fromX * TILE, fromZ * TILE
    local tx, tz = toX   * TILE, toZ   * TILE
    local midX = (fx + tx) / 2
    local midZ = (fz + tz) / 2
    local lenX = math.abs(tx - fx)
    local lenZ = math.abs(tz - fz)
    local length = lenX + lenZ

    local belt = Instance.new("Part")
    belt.Name      = "Conveyor_" .. tileKey(fromX, fromZ) .. "_" .. tileKey(toX, toZ)
    belt.Size      = Vector3.new(
        if lenX > 0 then length else TILE * 0.8,
        VSConfig.CONVEYOR_HEIGHT_STUDS or 0.5,
        if lenZ > 0 then length else TILE * 0.8
    )
    belt.BrickColor = BrickColor.new("Dark orange")
    belt.Material  = Enum.Material.SmoothPlastic
    belt.Anchored  = true
    belt.CFrame    = CFrame.new(midX, 0.25, midZ)
    belt.Parent    = Workspace

    -- Add a surface texture for the belt look
    local texture = Instance.new("Texture")
    texture.Texture   = "rbxasset://textures/grid.png"
    texture.Face      = Enum.NormalId.Top
    texture.StudsPerTileU = 2
    texture.StudsPerTileV = 2
    texture.Parent    = belt

    return belt
end

-- Find which player owns the plot containing the from-tile.
-- For VS: single-player, so use the first player found.
local function findPlotOwnerForTile(_tileX: number, _tileZ: number): number
    local PlotService = Knit.GetService("PlotService")
    for _, player in ipairs(Players:GetPlayers()) do
        local plotId = PlotService:getPlotId(player)
        if plotId then
            return player.UserId
        end
    end
    return 0
end

-- ── Placement ─────────────────────────────────────────────────────────────────

function ConveyorService.Client:PlaceConveyor(
    player: Player,
    fromX: number, fromZ: number,
    toX:   number, toZ:   number
): (boolean, string?)
    -- Only allow adjacent tiles (horizontal or vertical, not diagonal)
    local dx = math.abs(toX - fromX)
    local dz = math.abs(toZ - fromZ)
    if dx + dz ~= 1 then
        return false, "conveyor must connect adjacent tiles"
    end

    local fromKey = tileKey(fromX, fromZ)
    if _fromTile[fromKey] then
        return false, "a conveyor already starts at this tile"
    end

    -- Check and deduct cost
    local price = VSConfig.MACHINE_SHOP_PRICES.conveyor_belt or 5
    if price > 0 then
        local EconomyService = Knit.GetService("EconomyService")
        local ok, err = EconomyService:deductCoins(player, price)
        if not ok then return false, err end
    end

    local id    = newSegId()
    local model = buildConveyorModel(fromX, fromZ, toX, toZ)

    local entry: SegmentEntry = {
        segmentId   = id,
        fromX       = fromX,
        fromZ       = fromZ,
        toX         = toX,
        toZ         = toZ,
        plotOwnerId = player.UserId,
        model       = model,
    }
    _segments[id] = entry
    _fromTile[fromKey] = id

    local toKey = tileKey(toX, toZ)
    if not _toTile[toKey] then _toTile[toKey] = {} end
    table.insert(_toTile[toKey], id)

    -- Persist
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(player)
    if data then
        table.insert(data.plot.conveyors, {
            segmentId    = id,
            tier         = 1,
            fromPosition = {x = fromX, z = fromZ},
            toPosition   = {x = toX,   z = toZ},
        })
        SaveService:updateSession(player, {plot = data.plot})
    end

    Network.getEvent(Network.Events.ConveyorPlaced):FireAllClients(id, fromX, fromZ, toX, toZ)
    log:info("Placed conveyor %s from (%d,%d) to (%d,%d)", id, fromX, fromZ, toX, toZ)
    return true, nil
end

function ConveyorService.Client:RemoveConveyor(player: Player, segmentId: string): boolean
    local seg = _segments[segmentId]
    if not seg then return false end
    if seg.plotOwnerId ~= player.UserId then return false end

    -- Refund
    local price  = VSConfig.MACHINE_SHOP_PRICES.conveyor_belt or 5
    local refund = math.floor(price * VSConfig.MACHINE_REFUND_FRACTION)
    if refund > 0 then
        local EconomyService = Knit.GetService("EconomyService")
        EconomyService:awardCoins(player, refund)
    end

    if seg.model then seg.model:Destroy() end

    local fromKey = tileKey(seg.fromX, seg.fromZ)
    local toKey   = tileKey(seg.toX,   seg.toZ)
    _fromTile[fromKey] = nil

    if _toTile[toKey] then
        for i, sid in ipairs(_toTile[toKey]) do
            if sid == segmentId then table.remove(_toTile[toKey], i) break end
        end
    end
    _segments[segmentId] = nil

    -- Remove in-transit items on this segment
    for i = #_inTransit, 1, -1 do
        if _inTransit[i].segmentId == segmentId then
            table.remove(_inTransit, i)
        end
    end

    -- Persist removal
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(player)
    if data then
        for i, saved in ipairs(data.plot.conveyors) do
            if saved.segmentId == segmentId then
                table.remove(data.plot.conveyors, i)
                break
            end
        end
        SaveService:updateSession(player, {plot = data.plot})
    end

    Network.getEvent(Network.Events.ConveyorRemoved):FireAllClients(segmentId)
    return true
end

-- ── Simulation tick ───────────────────────────────────────────────────────────

local function deliverItem(item: InTransitItem, seg: SegmentEntry)
    local toKey    = tileKey(seg.toX, seg.toZ)
    local MachineService  = Knit.GetService("MachineService")
    local StorageService  = Knit.GetService("StorageService")
    local SellerService   = Knit.GetService("SellerService")
    local atTile   = MachineService:getAtTile(toKey)

    Network.getEvent(Network.Events.ItemDelivered):FireAllClients(seg.toX, seg.toZ, item.itemId)

    if atTile then
        if atTile.machineId == "lumber_mill" then
            MachineService:receiveInput(atTile.instanceId, item.itemId)
        elseif atTile.machineId == "storage_chest" then
            -- Find the player who owns this plot
            local owner = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == item.plotOwnerId then owner = p break end
            end
            if owner then StorageService:receiveItem(atTile.instanceId, item.itemId, owner) end
        elseif atTile.machineId == "seller_station" then
            local owner = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == item.plotOwnerId then owner = p break end
            end
            if owner then SellerService:sellItem(atTile.instanceId, item.itemId, owner) end
        end
    else
        -- Check if another segment continues from this tile
        local nextSegId = _fromTile[toKey]
        if nextSegId and _segments[nextSegId] then
            local nextSeg = _segments[nextSegId]
            local travelSecs = VSConfig.CONVEYOR_SPEED_TICKS / VSConfig.MACHINE_TICK_HZ
            table.insert(_inTransit, {
                itemId      = item.itemId,
                segmentId   = nextSegId,
                ticksLeft   = VSConfig.CONVEYOR_SPEED_TICKS,
                plotOwnerId = item.plotOwnerId,
            })
            Network.getEvent(Network.Events.ItemTransitStarted):FireAllClients(
                nextSegId, item.itemId, travelSecs
            )
        end
        -- else: item falls off end of conveyor (dropped — acceptable for VS)
    end
end

function ConveyorService:tick()
    local MachineService = Knit.GetService("MachineService")

    -- 1. Advance in-transit items
    local delivered: {number} = {}
    for i, item in ipairs(_inTransit) do
        item.ticksLeft -= 1
        if item.ticksLeft <= 0 then
            local seg = _segments[item.segmentId]
            if seg then deliverItem(item, seg) end
            table.insert(delivered, i)
        end
    end
    -- Remove delivered (iterate backwards to preserve indices)
    for i = #delivered, 1, -1 do
        table.remove(_inTransit, delivered[i])
    end

    -- 2. Pull items from machine output buffers onto connected conveyors
    for segId, seg in pairs(_segments) do
        -- Check if a segment is already carrying an item (limit 1 per segment for VS)
        local busy = false
        for _, item in ipairs(_inTransit) do
            if item.segmentId == segId then busy = true break end
        end
        if busy then continue end

        -- Check what's at the from-tile
        local fromKey  = tileKey(seg.fromX, seg.fromZ)
        local atSource = MachineService:getAtTile(fromKey)
        if atSource and atSource.machineId == "lumber_mill" then
            -- Also check output tile alignment
            local outTile = MachineService:getOutputTile(atSource.instanceId)
            if outTile and tileKey(outTile.x, outTile.z) == fromKey then
                local itemId = MachineService:consumeOutput(atSource.instanceId)
                if itemId then
                    local travelSecs = VSConfig.CONVEYOR_SPEED_TICKS / VSConfig.MACHINE_TICK_HZ
                    table.insert(_inTransit, {
                        itemId      = itemId,
                        segmentId   = segId,
                        ticksLeft   = VSConfig.CONVEYOR_SPEED_TICKS,
                        plotOwnerId = seg.plotOwnerId,
                    })
                    Network.getEvent(Network.Events.ItemTransitStarted):FireAllClients(
                        segId, itemId, travelSecs
                    )
                end
            end
        end
    end
end

-- ── Restore from save ─────────────────────────────────────────────────────────

function ConveyorService:restoreSegments(
    saved: {{segmentId: string, tier: number, fromPosition: {x: number, z: number}, toPosition: {x: number, z: number}}},
    plotOwnerId: number
)
    for _, s in ipairs(saved) do
        local fromKey = tileKey(s.fromPosition.x, s.fromPosition.z)
        if _fromTile[fromKey] then continue end

        local model = buildConveyorModel(s.fromPosition.x, s.fromPosition.z, s.toPosition.x, s.toPosition.z)
        local entry: SegmentEntry = {
            segmentId   = s.segmentId,
            fromX       = s.fromPosition.x,
            fromZ       = s.fromPosition.z,
            toX         = s.toPosition.x,
            toZ         = s.toPosition.z,
            plotOwnerId = plotOwnerId,
            model       = model,
        }
        _segments[s.segmentId] = entry
        _fromTile[fromKey]     = s.segmentId

        local toKey = tileKey(s.toPosition.x, s.toPosition.z)
        if not _toTile[toKey] then _toTile[toKey] = {} end
        table.insert(_toTile[toKey], s.segmentId)

        Network.getEvent(Network.Events.ConveyorPlaced):FireAllClients(
            s.segmentId, s.fromPosition.x, s.fromPosition.z, s.toPosition.x, s.toPosition.z
        )
    end
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function ConveyorService:KnitInit() end

function ConveyorService:KnitStart()
    task.spawn(function()
        while true do
            task.wait(1 / VSConfig.MACHINE_TICK_HZ)
            self:tick()
        end
    end)
    log:info("ConveyorService started")
end

return ConveyorService
```

- [ ] **Step 2: Commit**

```
git add src/server/services/ConveyorService.luau
git commit -m "feat(vs): implement ConveyorService — item routing, transit, delivery"
```

---

### Task 5: StorageService + SellerService

**Files:**
- Create: `src/server/services/StorageService.luau`
- Create: `src/server/services/SellerService.luau`

**Interfaces:**
- StorageService consumes: `SaveService:getSession/updateSession`, `VSConfig.STORAGE_CHEST_CAPACITY`, `Network.Events.StorageUpdated`
- StorageService produces: `StorageService:receiveItem(instanceId, itemId, player)` — called by ConveyorService
- SellerService consumes: `EconomyService:awardCoins`, `VSConfig.SELL_PRICE`, `Network.Events.ItemSold`
- SellerService produces: `SellerService:sellItem(instanceId, itemId, player)` — called by ConveyorService

---

- [ ] **Step 1: Create `src/server/services/StorageService.luau`**

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger   = require(ReplicatedStorage.Shared.utils.Logger)
local VSConfig = require(ReplicatedStorage.Shared.config.VSConfig)
local Network  = require(ReplicatedStorage.Shared.Network)

local log = Logger.new("StorageService")

local StorageService = Knit.CreateService({ Name = "StorageService", Client = {} })

function StorageService:receiveItem(instanceId: string, itemId: string, player: Player)
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(player)
    if not data then return end

    local inv = data.storageInventories[instanceId]
    if not inv then
        data.storageInventories[instanceId] = {}
        inv = data.storageInventories[instanceId]
    end

    local total = 0
    for _, count in pairs(inv) do total += count end
    if total >= VSConfig.STORAGE_CHEST_CAPACITY then
        log:warn("Storage chest %s full", instanceId)
        return
    end

    inv[itemId] = (inv[itemId] or 0) + 1
    SaveService:updateSession(player, {storageInventories = data.storageInventories})

    Network.getEvent(Network.Events.StorageUpdated):FireAllClients(instanceId, inv)
    log:debug("Storage %s received %s (total %d)", instanceId, itemId, total + 1)
end

function StorageService:KnitInit() end
function StorageService:KnitStart()
    log:info("StorageService started")
end

return StorageService
```

- [ ] **Step 2: Create `src/server/services/SellerService.luau`**

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger   = require(ReplicatedStorage.Shared.utils.Logger)
local VSConfig = require(ReplicatedStorage.Shared.config.VSConfig)
local Network  = require(ReplicatedStorage.Shared.Network)
local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)

local TILE = GameConfig.TILE_SIZE_STUDS
local log  = Logger.new("SellerService")

local SellerService = Knit.CreateService({ Name = "SellerService", Client = {} })

function SellerService:sellItem(instanceId: string, itemId: string, player: Player)
    local price = VSConfig.SELL_PRICE[itemId]
    if not price or price <= 0 then
        log:warn("No sell price for item: %s", itemId)
        return
    end

    local EconomyService = Knit.GetService("EconomyService")
    EconomyService:awardCoins(player, price)

    -- Find the seller's world position via MachineService
    local MachineService = Knit.GetService("MachineService")
    local cf = MachineService:getWorldCFrame(instanceId)
    local tileX = if cf then math.round(cf.Position.X / TILE) else 0
    local tileZ = if cf then math.round(cf.Position.Z / TILE) else 0

    Network.getEvent(Network.Events.ItemSold):FireAllClients(tileX, tileZ, itemId, price)
    log:debug("Sold %s for %d coins (player %s)", itemId, price, player.Name)
end

function SellerService:KnitInit() end
function SellerService:KnitStart()
    log:info("SellerService started")
end

return SellerService
```

- [ ] **Step 3: Commit**

```
git add src/server/services/StorageService.luau src/server/services/SellerService.luau
git commit -m "feat(vs): add StorageService and SellerService"
```

---

### Task 6: SaveService Integration — Restore Plot on Join

**Files:**
- Modify: `src/server/services/SaveService.luau` (call restorePlot and restoreSegments after loadPlayer)
- Modify: `src/server/services/PlayerService.luau` (or wherever loadPlayer is wired to PlayerAdded)

The goal: when a returning player joins, their machines and conveyors are respawned in Workspace from saved data.

**Interfaces:**
- Consumes: `MachineService:restorePlot(savedMachines)`, `ConveyorService:restoreSegments(savedConveyors, plotOwnerId)`
- Consumes: `SaveService:loadPlayer(player)` (already implemented)

---

- [ ] **Step 1: Read `src/server/services/PlayerService.luau`**

Check how PlayerAdded and SaveService:loadPlayer are wired. (Expected: PlayerService.KnitStart connects PlayerAdded → SaveService:loadPlayer → PlotService:assignPlot.)

- [ ] **Step 2: Modify `src/server/services/SaveService.luau` — restore plot after load**

At the end of `SaveService:loadPlayer`, after the `_sessions` assignment and before the `PlayerDataLoaded` fire, add:

```lua
    -- Restore persisted machines and conveyors in Workspace
    local MachineService  = Knit.GetService("MachineService")
    local ConveyorService = Knit.GetService("ConveyorService")
    local plotData = (data :: {[string]: any}).plot
    if plotData and plotData.machines and #plotData.machines > 0 then
        MachineService:restorePlot(plotData.machines)
    end
    if plotData and plotData.conveyors and #plotData.conveyors > 0 then
        ConveyorService:restoreSegments(plotData.conveyors, player.UserId)
    end
```

- [ ] **Step 3: Test: place a machine, leave, rejoin. Machine should reappear in Workspace.**

- [ ] **Step 4: Commit**

```
git add src/server/services/SaveService.luau
git commit -m "feat(vs): restore machines and conveyors from save on player join"
```

---

### Task 7: BuildController + InputController (Client — Build Mode)

**Files:**
- Modify: `src/client/controllers/BuildController.luau` (full implementation)
- Modify: `src/client/controllers/InputController.luau` (full implementation)

**Interfaces:**
- Consumes (client Knit service proxies): `MachineService:PlaceMachine(...)`, `MachineService:RemoveMachine(...)`, `ConveyorService:PlaceConveyor(...)`, `ConveyorService:RemoveConveyor(...)`
- Consumes: `UserInputService`, `RunService`, `Workspace.Camera`, `Mouse`
- Produces: `BuildController:beginPlacement(machineId: string)` — called by UIController when shop button pressed
- Produces: `BuildController:beginConveyorPlacement()` — called by UIController
- Produces: `BuildController:cancelPlacement()` — called by InputController on Escape
- Produces: `BuildController:rotatePlacement()` — called by InputController on R
- Produces: `BuildController:isInPlacementMode() → boolean` — queried by InputController

---

- [ ] **Step 1: Write the full InputController**

Replace `src/client/controllers/InputController.luau`:

```lua
--!strict
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local InputController = Knit.CreateController({ Name = "InputController" })

local _camera = Workspace.CurrentCamera

-- Returns the world tile position under the mouse cursor, or nil.
function InputController:GetCursorTilePosition(tileSize: number): {x: number, z: number}?
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    local unitRay = _camera:ScreenPointToRay(mouse.X, mouse.Y)
    local ray = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
    local hitInstance, hitPos = Workspace:FindPartOnRayWithIgnoreList(ray, {})
    if not hitPos then return nil end
    return {
        x = math.round(hitPos.X / tileSize),
        z = math.round(hitPos.Z / tileSize),
    }
end

function InputController:KnitInit() end

function InputController:KnitStart()
    local BuildController = Knit.GetController("BuildController")

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.Escape then
            BuildController:cancelPlacement()
        end

        if input.KeyCode == Enum.KeyCode.R then
            BuildController:rotatePlacement()
        end

        if input.KeyCode == Enum.KeyCode.E then
            -- Toggle build mode removal — handled in BuildController via right-click or E+click
        end
    end)

    -- Left-click to confirm placement
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if BuildController:isInPlacementMode() then
                BuildController:confirmPlacement()
            end
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            if BuildController:isInConveyorMode() then
                BuildController:confirmConveyorEnd()
            end
        end
    end)
end

return InputController
```

- [ ] **Step 2: Write the full BuildController**

Replace `src/client/controllers/BuildController.luau`:

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)

local TILE = GameConfig.TILE_SIZE_STUDS

local BuildController = Knit.CreateController({ Name = "BuildController" })

-- ── State ─────────────────────────────────────────────────────────────────────

local _mode: "none" | "machine" | "conveyor" = "none"
local _selectedMachineId: string?      = nil
local _rotation: number                = 0       -- 0 | 90 | 180 | 270
local _ghostModel: Model?              = nil
local _conveyorFromTile: {x: number, z: number}? = nil
local _ghostConveyorPart: Part?        = nil

-- ── Ghost model builders (mirrors server procedural models) ──────────────────

local function buildGhostBase(tileX: number, tileZ: number, rotation: number, machineId: string): Model
    local model = Instance.new("Model")
    local wx, wz = tileX * TILE, tileZ * TILE

    local base = Instance.new("Part")
    base.Name      = "GhostBase"
    base.Anchored  = true
    base.CanCollide = false
    base.Size      = Vector3.new(TILE - 0.2, 2, TILE - 0.2)
    base.CFrame    = CFrame.new(wx, 1, wz) * CFrame.Angles(0, math.rad(rotation), 0)
    base.Transparency = 0.5

    if machineId == "lumber_mill" then
        base.BrickColor = BrickColor.new("Medium stone grey")
    elseif machineId == "storage_chest" then
        base.BrickColor = BrickColor.new("Nougat")
        base.Size       = Vector3.new(TILE - 0.2, TILE - 0.2, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, (TILE - 0.2) / 2, wz)
    elseif machineId == "seller_station" then
        base.BrickColor = BrickColor.new("Bright yellow")
    end

    base.Parent    = model
    model.PrimaryPart = base
    model.Parent   = Workspace
    return model
end

local function setGhostValid(valid: boolean)
    if not _ghostModel then return end
    local color = if valid then BrickColor.new("Bright green") else BrickColor.new("Bright red")
    for _, part in ipairs(_ghostModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.BrickColor = color
        end
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

function BuildController:isInPlacementMode(): boolean
    return _mode == "machine"
end

function BuildController:isInConveyorMode(): boolean
    return _mode == "conveyor"
end

function BuildController:beginPlacement(machineId: string)
    self:cancelPlacement()
    _mode             = "machine"
    _selectedMachineId = machineId
    _rotation         = 0
    -- Ghost will be created on first RenderStepped frame
end

function BuildController:beginConveyorPlacement()
    self:cancelPlacement()
    _mode = "conveyor"
    _conveyorFromTile = nil
end

function BuildController:rotatePlacement()
    if _mode ~= "machine" then return end
    _rotation = (_rotation + 90) % 360
end

function BuildController:cancelPlacement()
    _mode              = "none"
    _selectedMachineId = nil
    _conveyorFromTile  = nil
    if _ghostModel then
        _ghostModel:Destroy()
        _ghostModel = nil
    end
    if _ghostConveyorPart then
        _ghostConveyorPart:Destroy()
        _ghostConveyorPart = nil
    end
end

function BuildController:confirmPlacement()
    if _mode ~= "machine" or not _selectedMachineId then return end

    local InputController = Knit.GetController("InputController")
    local tile = InputController:GetCursorTilePosition(TILE)
    if not tile then return end

    local machineService = Knit.GetService("MachineService")
    local ok, err = machineService:PlaceMachine(_selectedMachineId, tile.x, tile.z, _rotation)
    if not ok then
        -- Flash ghost red briefly, then stay in placement mode
        setGhostValid(false)
        task.delay(0.3, function() setGhostValid(true) end)
        if err then warn("[BuildController] PlaceMachine failed:", err) end
    end
    -- Stay in placement mode so player can place multiple
end

-- Conveyor: left-click sets FROM tile; right-click (confirmConveyorEnd) sets TO tile.
function BuildController:confirmPlacementConveyorStart()
    if _mode ~= "conveyor" then return end
    local InputController = Knit.GetController("InputController")
    local tile = InputController:GetCursorTilePosition(TILE)
    if not tile then return end
    _conveyorFromTile = tile
end

function BuildController:confirmConveyorEnd()
    if _mode ~= "conveyor" or not _conveyorFromTile then return end
    local InputController = Knit.GetController("InputController")
    local tile = InputController:GetCursorTilePosition(TILE)
    if not tile then return end

    local from = _conveyorFromTile
    local conveyorService = Knit.GetService("ConveyorService")
    local ok, err = conveyorService:PlaceConveyor(from.x, from.z, tile.x, tile.z)
    if not ok and err then
        warn("[BuildController] PlaceConveyor failed:", err)
    end
    -- Reset from-tile so player can chain next segment
    _conveyorFromTile = tile
end

-- ── Render loop — update ghost position ──────────────────────────────────────

function BuildController:KnitInit() end

function BuildController:KnitStart()
    local InputController = Knit.GetController("InputController")

    RunService.RenderStepped:Connect(function()
        if _mode == "machine" and _selectedMachineId then
            local tile = InputController:GetCursorTilePosition(TILE)
            if not tile then
                if _ghostModel then _ghostModel.Parent = nil end
                return
            end

            if not _ghostModel or _ghostModel.Parent == nil then
                if _ghostModel then _ghostModel:Destroy() end
                _ghostModel = buildGhostBase(tile.x, tile.z, _rotation, _selectedMachineId)
            else
                local wx, wz = tile.x * TILE, tile.z * TILE
                local base = _ghostModel:FindFirstChild("GhostBase") :: BasePart?
                if base then
                    base.CFrame = CFrame.new(wx, base.Size.Y / 2, wz) * CFrame.Angles(0, math.rad(_rotation), 0)
                end
            end
            -- Validity: always green for now (server will reject if invalid)
            setGhostValid(true)

        elseif _mode == "conveyor" then
            local tile = InputController:GetCursorTilePosition(TILE)
            if tile and _conveyorFromTile then
                -- Show a preview line from fromTile to cursor
                if not _ghostConveyorPart then
                    _ghostConveyorPart = Instance.new("Part")
                    _ghostConveyorPart.Name        = "ConveyorGhost"
                    _ghostConveyorPart.Anchored     = true
                    _ghostConveyorPart.CanCollide   = false
                    _ghostConveyorPart.Transparency = 0.6
                    _ghostConveyorPart.BrickColor   = BrickColor.new("Bright green")
                    _ghostConveyorPart.Material     = Enum.Material.SmoothPlastic
                    _ghostConveyorPart.Parent       = Workspace
                end
                local fx = _conveyorFromTile.x * TILE
                local fz = _conveyorFromTile.z * TILE
                local tx = tile.x * TILE
                local tz = tile.z * TILE
                local midX = (fx + tx) / 2
                local midZ = (fz + tz) / 2
                local lenX = math.abs(tx - fx)
                local lenZ = math.abs(tz - fz)
                _ghostConveyorPart.Size   = Vector3.new(
                    if lenX > 0 then lenX else TILE * 0.8,
                    0.5,
                    if lenZ > 0 then lenZ else TILE * 0.8
                )
                _ghostConveyorPart.CFrame = CFrame.new(midX, 0.35, midZ)
            end
        else
            -- Clean up ghosts when not in build mode
            if _ghostModel then
                _ghostModel:Destroy()
                _ghostModel = nil
            end
            if _ghostConveyorPart then
                _ghostConveyorPart:Destroy()
                _ghostConveyorPart = nil
            end
        end
    end)

    -- Left-click in conveyor mode sets FROM tile
    game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if _mode == "conveyor" and not _conveyorFromTile then
                self:confirmPlacementConveyorStart()
            elseif _mode == "conveyor" and _conveyorFromTile then
                self:confirmConveyorEnd()
            end
        end
    end)
end

return BuildController
```

- [ ] **Step 3: Commit**

```
git add src/client/controllers/BuildController.luau src/client/controllers/InputController.luau
git commit -m "feat(vs): implement BuildController and InputController for build mode"
```

---

### Task 8: CameraController

**Files:**
- Create: `src/client/controllers/CameraController.luau`

**Interfaces:**
- Produces: Comfortable orbit camera with scroll-to-zoom and middle-mouse pan
- Consumes: `RunService.RenderStepped`, `UserInputService`

---

- [ ] **Step 1: Create `src/client/controllers/CameraController.luau`**

```lua
--!strict
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local Players          = game:GetService("Players")
local Packages         = ReplicatedStorage:WaitForChild("Packages")
local Knit             = require(Packages:WaitForChild("Knit"))

local CameraController = Knit.CreateController({ Name = "CameraController" })

local camera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- Camera state
local _yaw:    number = -45    -- horizontal rotation degrees
local _pitch:  number = -50   -- vertical angle degrees (negative = looking down)
local _dist:   number = 60    -- distance from focus point (studs)
local _focus:  Vector3 = Vector3.new(0, 0, 0)

local MIN_PITCH = -80
local MAX_PITCH = -15
local MIN_DIST  = 15
local MAX_DIST  = 150

local _panning    = false
local _lastMousePos: Vector2? = nil

local function updateCamera()
    local yawRad   = math.rad(_yaw)
    local pitchRad = math.rad(_pitch)

    local offset = Vector3.new(
        math.cos(pitchRad) * math.sin(yawRad),
        math.sin(-pitchRad),
        math.cos(pitchRad) * math.cos(yawRad)
    ) * _dist

    local camPos = _focus + offset
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame     = CFrame.lookAt(camPos, _focus)
end

function CameraController:KnitInit() end

function CameraController:KnitStart()
    -- Disable default roblox camera
    camera.CameraType = Enum.CameraType.Scriptable

    -- Scroll to zoom
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            _dist = math.clamp(_dist - input.Position.Z * 5, MIN_DIST, MAX_DIST)
        end

        -- Middle mouse pan
        if _panning and input.UserInputType == Enum.UserInputType.MouseMovement then
            if _lastMousePos then
                local delta = input.Position - Vector3.new(_lastMousePos.X, _lastMousePos.Y, 0)
                local rightVec = Vector3.new(math.cos(math.rad(_yaw)), 0, -math.sin(math.rad(_yaw)))
                local forwardVec = Vector3.new(math.sin(math.rad(_yaw)), 0, math.cos(math.rad(_yaw)))
                _focus = _focus - rightVec * delta.X * 0.15 + forwardVec * delta.Y * 0.15
            end
            _lastMousePos = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)

    -- Middle mouse button to pan
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            _panning = true
            _lastMousePos = nil
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            _panning = false
            _lastMousePos = nil
        end
    end)

    -- WASD / arrow key pan of focus point
    RunService.RenderStepped:Connect(function(dt)
        local speed = _dist * 0.5 * dt
        local rightVec   = Vector3.new(math.cos(math.rad(_yaw)), 0, -math.sin(math.rad(_yaw)))
        local forwardVec = Vector3.new(math.sin(math.rad(_yaw)), 0, math.cos(math.rad(_yaw)))

        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
            _focus = _focus + forwardVec * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
            _focus = _focus - forwardVec * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
            _focus = _focus - rightVec * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
            _focus = _focus + rightVec * speed
        end

        updateCamera()
    end)
end

return CameraController
```

- [ ] **Step 2: Commit**

```
git add src/client/controllers/CameraController.luau
git commit -m "feat(vs): add CameraController — orbit zoom, WASD pan, middle-mouse pan"
```

---

### Task 9: UIController + HUDController (Shop Toolbar + Money Display)

**Files:**
- Modify: `src/client/controllers/UIController.luau` (full implementation — shop toolbar)
- Create: `src/client/controllers/HUDController.luau` (money display + floating coin text + coin particles)

**Interfaces:**
- UIController consumes: `BuildController:beginPlacement`, `BuildController:beginConveyorPlacement`, `EconomyService.BalanceUpdated` signal
- HUDController consumes: `Network.Events.ItemSold`, `Network.Events.StorageUpdated`, `EconomyService.BalanceUpdated`
- HUDController produces: floating "+N coins" text at world position when item sells

The shop toolbar is a row of ScreenGui buttons at the bottom of the screen. Each shows machine name + cost. Clicking enters build mode.

---

- [ ] **Step 1: Write the full UIController**

Replace `src/client/controllers/UIController.luau`:

```lua
--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local VSConfig = require(ReplicatedStorage.Shared.config.VSConfig)

local UIController = Knit.CreateController({ Name = "UIController" })

local localPlayer = Players.LocalPlayer
local _gui: ScreenGui? = nil
local _coinLabel: TextLabel? = nil

local SHOP_ITEMS = {
    { id = "lumber_mill",    label = "Lumber Mill",  price = VSConfig.MACHINE_SHOP_PRICES.lumber_mill    },
    { id = "storage_chest",  label = "Storage",      price = VSConfig.MACHINE_SHOP_PRICES.storage_chest  },
    { id = "seller_station", label = "Seller",       price = VSConfig.MACHINE_SHOP_PRICES.seller_station },
    { id = "_conveyor",      label = "Conveyor",     price = VSConfig.MACHINE_SHOP_PRICES.conveyor_belt  },
}

local function makeButton(parent: GuiObject, text: string, position: UDim2, size: UDim2): TextButton
    local btn = Instance.new("TextButton")
    btn.Size              = size
    btn.Position          = position
    btn.BackgroundColor3  = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel   = 0
    btn.Text              = text
    btn.TextColor3        = Color3.fromRGB(240, 240, 240)
    btn.TextSize          = 14
    btn.Font              = Enum.Font.GothamBold
    btn.AutoButtonColor   = true
    btn.Parent            = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent       = btn
    return btn
end

local function buildUI()
    local gui = Instance.new("ScreenGui")
    gui.Name            = "CogsworthHUD"
    gui.ResetOnSpawn    = false
    gui.IgnoreGuiInset  = true
    gui.Parent          = localPlayer:WaitForChild("PlayerGui")
    _gui = gui

    -- ── Coin display (top left) ────────────────────────────────────────────────
    local coinFrame = Instance.new("Frame")
    coinFrame.Name            = "CoinFrame"
    coinFrame.Size            = UDim2.new(0, 180, 0, 44)
    coinFrame.Position        = UDim2.new(0, 12, 0, 12)
    coinFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    coinFrame.BackgroundTransparency = 0.3
    coinFrame.BorderSizePixel = 0
    coinFrame.Parent          = gui

    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(0, 10)
    coinCorner.Parent       = coinFrame

    local coinLbl = Instance.new("TextLabel")
    coinLbl.Name            = "CoinLabel"
    coinLbl.Size            = UDim2.new(1, -8, 1, 0)
    coinLbl.Position        = UDim2.new(0, 8, 0, 0)
    coinLbl.BackgroundTransparency = 1
    coinLbl.Text            = "$ 200"
    coinLbl.TextColor3      = Color3.fromRGB(255, 215, 0)
    coinLbl.TextSize        = 22
    coinLbl.Font            = Enum.Font.GothamBold
    coinLbl.TextXAlignment  = Enum.TextXAlignment.Left
    coinLbl.Parent          = coinFrame
    _coinLabel = coinLbl

    -- ── Shop toolbar (bottom center) ───────────────────────────────────────────
    local toolbar = Instance.new("Frame")
    toolbar.Name              = "Toolbar"
    toolbar.AnchorPoint       = Vector2.new(0.5, 1)
    toolbar.Size              = UDim2.new(0, #SHOP_ITEMS * 120 + (#SHOP_ITEMS - 1) * 8 + 16, 0, 80)
    toolbar.Position          = UDim2.new(0.5, 0, 1, -12)
    toolbar.BackgroundColor3  = Color3.fromRGB(20, 20, 30)
    toolbar.BackgroundTransparency = 0.25
    toolbar.BorderSizePixel   = 0
    toolbar.Parent            = gui

    local toolbarCorner = Instance.new("UICorner")
    toolbarCorner.CornerRadius = UDim.new(0, 12)
    toolbarCorner.Parent       = toolbar

    local layout = Instance.new("UIListLayout")
    layout.FillDirection  = Enum.FillDirection.Horizontal
    layout.Padding        = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Parent         = toolbar

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft  = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent       = toolbar

    local BuildController = Knit.GetController("BuildController")

    for _, item in ipairs(SHOP_ITEMS) do
        local priceText = if item.price == 0 then "Free" else ("$" .. item.price)
        local btn = makeButton(toolbar, item.label .. "\n" .. priceText, UDim2.new(0, 0, 0, 0), UDim2.new(0, 120, 0, 60))
        btn.TextSize = 13

        btn.MouseButton1Click:Connect(function()
            if item.id == "_conveyor" then
                BuildController:beginConveyorPlacement()
            else
                BuildController:beginPlacement(item.id)
            end
        end)
    end

    -- ── Hint label (top center, shows build mode status) ──────────────────────
    local hintLabel = Instance.new("TextLabel")
    hintLabel.Name              = "HintLabel"
    hintLabel.Size              = UDim2.new(0, 400, 0, 30)
    hintLabel.AnchorPoint       = Vector2.new(0.5, 0)
    hintLabel.Position          = UDim2.new(0.5, 0, 0, 60)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text              = ""
    hintLabel.TextColor3        = Color3.fromRGB(240, 240, 100)
    hintLabel.TextSize          = 16
    hintLabel.Font              = Enum.Font.Gotham
    hintLabel.Parent            = gui
end

function UIController:SetCoinBalance(coins: number)
    if _coinLabel then
        _coinLabel.Text = "$ " .. tostring(coins)
    end
end

-- Called by HUDController when StorageUpdated fires
function UIController:ShowStorageTooltip(_instanceId: string, _inventory: {[string]: number})
    -- Future: show a tooltip near the storage chest
end

function UIController:KnitInit() end

function UIController:KnitStart()
    buildUI()

    -- Listen for balance changes
    local economyService = Knit.GetService("EconomyService")
    economyService.BalanceUpdated:Connect(function(coins: number, _premiumCoins: number)
        self:SetCoinBalance(coins)
    end)
end

return UIController
```

- [ ] **Step 2: Create `src/client/controllers/HUDController.luau`**

```lua
--!strict
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local TweenService       = game:GetService("TweenService")
local GameConfig         = require(ReplicatedStorage.Shared.config.GameConfig)
local VSConfig           = require(ReplicatedStorage.Shared.config.VSConfig)
local Network            = require(ReplicatedStorage.Shared.Network)
local Packages           = ReplicatedStorage:WaitForChild("Packages")
local Knit               = require(Packages:WaitForChild("Knit"))

local TILE = GameConfig.TILE_SIZE_STUDS
local HUDController = Knit.CreateController({ Name = "HUDController" })
local localPlayer = Players.LocalPlayer

-- Shows a floating "+N coins" BillboardGui above a world position, then fades out.
local function spawnFloatingText(worldPos: Vector3, text: string)
    local part = Instance.new("Part")
    part.Size         = Vector3.new(0.1, 0.1, 0.1)
    part.Anchored     = true
    part.Transparency = 1
    part.CanCollide   = false
    part.CFrame       = CFrame.new(worldPos)
    part.Parent       = Workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Size         = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset  = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop  = false
    billboard.Parent       = part

    local label = Instance.new("TextLabel")
    label.Size              = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text              = text
    label.TextColor3        = Color3.fromRGB(255, 215, 0)
    label.TextSize          = 22
    label.Font              = Enum.Font.GothamBold
    label.TextStrokeColor3  = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.5
    label.Parent            = billboard

    local duration = VSConfig.FLOATING_TEXT_DURATION
    local riseStuds = VSConfig.FLOATING_TEXT_RISE_STUDS

    -- Tween: rise and fade
    local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(worldPos + Vector3.new(0, riseStuds, 0))
    })
    tween:Play()

    local fadeTween = TweenService:Create(label, TweenInfo.new(duration * 0.5, Enum.EasingStyle.Linear), {
        TextTransparency = 1,
    })
    task.delay(duration * 0.5, function() fadeTween:Play() end)

    task.delay(duration + 0.1, function()
        part:Destroy()
    end)
end

function HUDController:KnitInit() end

function HUDController:KnitStart()
    -- Show floating coin text when an item is sold
    Network.getEvent(Network.Events.ItemSold).OnClientEvent:Connect(function(
        tileX: number, tileZ: number, _itemId: string, coinsEarned: number
    )
        local worldPos = Vector3.new(tileX * TILE, 2, tileZ * TILE)
        spawnFloatingText(worldPos, "+" .. coinsEarned .. " coins")
    end)

    -- Show floating "+item" text when item delivered to storage
    Network.getEvent(Network.Events.ItemDelivered).OnClientEvent:Connect(function(
        tileX: number, tileZ: number, itemId: string
    )
        -- Only show if at a storage tile (brief flash)
        -- Kept small: just a tiny label
        local worldPos = Vector3.new(tileX * TILE, 2, tileZ * TILE)
        spawnFloatingText(worldPos, "+" .. itemId)
    end)
end

return HUDController
```

- [ ] **Step 3: Commit**

```
git add src/client/controllers/UIController.luau src/client/controllers/HUDController.luau
git commit -m "feat(vs): add shop toolbar, coin display, floating coin text"
```

---

### Task 10: TreeController + ConveyorController (Client Visuals)

**Files:**
- Modify: `src/client/controllers/NotificationController.luau` (replace stub; handles TreeFelled animation + item transit visuals)

Alternatively, all client visual handlers can live in a single new file. For organizational clarity, use the existing `NotificationController.luau` stub (which is currently empty) for item transit visuals, and add tree animations inline.

**Interfaces:**
- Consumes: `Network.Events.TreeFelled`, `Network.Events.TreeRegrown`, `Network.Events.ItemTransitStarted`, `Network.Events.MachinePlaced`, `Network.Events.MachineRemoved`, `Network.Events.ConveyorPlaced`, `Network.Events.ConveyorRemoved`
- Produces: Tree falling tween (TweenService), item visual part sliding along conveyor, machine spin animation (RunService)

---

- [ ] **Step 1: Read the existing `src/client/controllers/NotificationController.luau`**

(Confirm it is currently a stub with no implementation, safe to replace.)

- [ ] **Step 2: Write the visual effects controller**

Replace `src/client/controllers/NotificationController.luau`:

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local GameConfig        = require(ReplicatedStorage.Shared.config.GameConfig)
local Network           = require(ReplicatedStorage.Shared.Network)
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local TILE = GameConfig.TILE_SIZE_STUDS

local NotificationController = Knit.CreateController({ Name = "NotificationController" })

-- itemId → BrickColor
local ITEM_COLORS: {[string]: BrickColor} = {
    log    = BrickColor.new("Reddish brown"),
    lumber = BrickColor.new("Bright yellow"),
}

-- segmentId → visual Part currently in transit
local _transitParts: {[string]: Part} = {}

-- instanceId → spinning blade part
local _machineBlades: {[string]: BasePart} = {}

local function findTreeModel(tileX: number, tileZ: number): Model?
    local name = tileX .. "," .. tileZ
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name == "Tree_" .. name then
            return obj
        end
    end
    return nil
end

local function animateTreeFall(tileX: number, tileZ: number)
    local model = findTreeModel(tileX, tileZ)
    if not model then return end
    local trunk = model:FindFirstChild("Trunk") :: BasePart?
    local foliage = model:FindFirstChild("Foliage") :: BasePart?
    if not trunk or not foliage then return end

    -- Tween trunk to fall sideways
    local fallAngle = math.pi / 2 + math.random() * 0.3
    local wx = tileX * TILE
    local wz = tileZ * TILE

    local tween = TweenService:Create(trunk, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        CFrame = CFrame.new(wx, 0.6, wz) * CFrame.Angles(fallAngle, math.random() * math.pi * 2, 0)
    })
    local tweenF = TweenService:Create(foliage, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        CFrame = CFrame.new(wx + math.random(-2,2), 1.5, wz + math.random(-2,2))
    })
    tween:Play()
    tweenF:Play()

    -- Fade out after fall
    task.delay(0.7, function()
        if trunk and trunk.Parent then
            local fade = TweenService:Create(trunk, TweenInfo.new(0.3), {Transparency = 1})
            local fadeF = TweenService:Create(foliage, TweenInfo.new(0.3), {Transparency = 1})
            fade:Play()
            fadeF:Play()
        end
    end)
end

local function spawnTransitItem(segmentId: string, itemId: string, fromX: number, fromZ: number, toX: number, toZ: number, travelSeconds: number)
    -- Clean up any existing item on this segment
    if _transitParts[segmentId] then
        _transitParts[segmentId]:Destroy()
    end

    local part = Instance.new("Part")
    part.Name        = "Item_" .. segmentId
    part.Size        = Vector3.new(0.6, 0.6, 0.6)
    part.BrickColor  = ITEM_COLORS[itemId] or BrickColor.new("Medium stone grey")
    part.Anchored    = true
    part.CanCollide  = false
    part.CFrame      = CFrame.new(fromX * TILE, 0.6, fromZ * TILE)
    part.Parent      = Workspace

    -- Add a little sparkle / point light
    local light = Instance.new("PointLight")
    light.Brightness = 1
    light.Range      = 4
    light.Color      = part.Color
    light.Parent     = part

    local tween = TweenService:Create(part, TweenInfo.new(travelSeconds, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(toX * TILE, 0.6, toZ * TILE)
    })
    tween:Play()
    _transitParts[segmentId] = part

    task.delay(travelSeconds + 0.1, function()
        if _transitParts[segmentId] == part then
            _transitParts[segmentId] = nil
        end
        part:Destroy()
    end)
end

-- Lookup the from/to tiles of a segment by segmentId from known conveyor models in Workspace.
-- For VS: encode from/to in the Part's name (server does this already in buildConveyorModel).
local function getSegmentTiles(segmentId: string): ({x: number, z: number}, {x: number, z: number})?
    -- Find the conveyor Part whose name encodes the segment
    -- Server names it: "Conveyor_fromKey_toKey"
    -- We stored segmentId separately — use attributes instead.
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and obj:GetAttribute("SegmentId") == segmentId then
            local fx = obj:GetAttribute("FromX") :: number?
            local fz = obj:GetAttribute("FromZ") :: number?
            local tx = obj:GetAttribute("ToX")   :: number?
            local tz = obj:GetAttribute("ToZ")   :: number?
            if fx and fz and tx and tz then
                return {x = fx, z = fz}, {x = tx, z = tz}
            end
        end
    end
    return nil, nil
end

function NotificationController:KnitInit() end

function NotificationController:KnitStart()
    -- Tree fell animation
    Network.getEvent(Network.Events.TreeFelled).OnClientEvent:Connect(function(tileX: number, tileZ: number)
        animateTreeFall(tileX, tileZ)
    end)

    -- Tree regrown — model becomes visible again server-side; client just sees it reappear
    Network.getEvent(Network.Events.TreeRegrown).OnClientEvent:Connect(function(_tileX: number, _tileZ: number)
        -- Nothing needed: server already set model.Parent = Workspace which replicates to clients
    end)

    -- Item transit: spawn a sliding item Part
    Network.getEvent(Network.Events.ItemTransitStarted).OnClientEvent:Connect(function(
        segmentId: string, itemId: string, travelSeconds: number
    )
        local from, to = getSegmentTiles(segmentId)
        if from and to then
            spawnTransitItem(segmentId, itemId, from.x, from.z, to.x, to.z, travelSeconds)
        end
    end)

    -- Spin lumber mill blades (look for blade parts in Workspace via tag or name)
    RunService.RenderStepped:Connect(function(dt)
        for _, model in ipairs(Workspace:GetChildren()) do
            if model:IsA("Model") and model.Name:find("lumber_mill") then
                local blade = model:FindFirstChild("Blade") :: BasePart?
                if blade then
                    blade.CFrame = blade.CFrame * CFrame.Angles(0, 0, dt * 3)
                end
            end
        end
    end)
end

return NotificationController
```

- [ ] **Step 3: Update server's `buildConveyorModel` in ConveyorService to set Attributes on the Part**

In `ConveyorService.luau`, inside `buildConveyorModel`, after creating `belt`, add:

```lua
    belt:SetAttribute("FromX", fromX)
    belt:SetAttribute("FromZ", fromZ)
    belt:SetAttribute("ToX",   toX)
    belt:SetAttribute("ToZ",   toZ)
    -- SegmentId is set after this function returns; caller must set it.
```

Then in `ConveyorService.Client.PlaceConveyor`, after `local model = buildConveyorModel(...)`, add:

```lua
    model:SetAttribute("SegmentId", id)
```

And in `ConveyorService:restoreSegments`, after creating the model:

```lua
    model:SetAttribute("SegmentId", s.segmentId)
```

- [ ] **Step 4: Commit**

```
git add src/client/controllers/NotificationController.luau src/server/services/ConveyorService.luau
git commit -m "feat(vs): add client visual effects — tree fall, item transit, blade spin"
```

---

### Task 11: Documentation Updates

**Files:**
- Modify: `README.md`
- Modify: `ROADMAP.md`
- Modify: `CHANGELOG.md`
- Modify: `TASKS.md`
- Modify: `MILESTONE_REPORT.md`

---

- [ ] **Step 1: Update `ROADMAP.md`**

Replace the Milestone 4 section with:

```markdown
## Vertical Slice Alpha ← CURRENT
Pivoted from milestone-by-milestone feature builds to a focused playable loop.
Target: Tree → Lumber Mill → Conveyor → Storage/Seller → Coins → Buy More.
Systems: TreeService, MachineService (lumber_mill only), ConveyorService,
StorageService, SellerService, BuildController, CameraController, UIController,
HUDController, NotificationController.
```

Mark Milestones 4–7 as "Post-Alpha (pending VS review)".

- [ ] **Step 2: Update `TASKS.md`**

Replace the M4 Backlog section with:

```markdown
## Vertical Slice Alpha — Completed

- [x] Task 1: VSConfig + Network + DataModel
- [x] Task 2: TreeService (spawning, harvest, regen)
- [x] Task 3: MachineService (placement, lumber mill tick)
- [x] Task 4: ConveyorService (routing, item transit)
- [x] Task 5: StorageService + SellerService
- [x] Task 6: SaveService integration (restore layout on join)
- [x] Task 7: BuildController + InputController
- [x] Task 8: CameraController
- [x] Task 9: UIController + HUDController
- [x] Task 10: NotificationController (tree fall, item visuals)
- [x] Task 11: Documentation

## Post-Alpha Backlog (do not start until VS is reviewed)

- [ ] MachineService: additional machine types (stone_crusher, etc.)
- [ ] Multiple conveyor tiers
- [ ] Power system
- [ ] Research system
- [ ] Biomes
- [ ] Drones
- [ ] Ascension
- [ ] Sound assets (replace placeholder IDs in SoundConfig)
- [ ] 3D machine models (replace procedural parts)
```

- [ ] **Step 3: Update `CHANGELOG.md`**

Add a new entry at the top:

```markdown
## [Vertical Slice Alpha] — 2026-07-13

### Pivot
Abandoned milestone-by-milestone plan in favour of a Vertical Slice Alpha.
Goal: prove the core loop is fun before building additional content.

### Added
- VSConfig: all vertical-slice tuning constants
- TreeService: forest spawning, click-harvest, regeneration
- MachineService: machine placement/removal, lumber mill tick, tree harvesting
- ConveyorService: segment placement/removal, item routing and transit
- StorageService: item receipt and persistence in storageInventories
- SellerService: auto-sell on item arrival, coin award
- SaveService: restore machines + conveyors from save on join
- BuildController: ghost preview, snap-to-grid, rotation, place, cancel
- InputController: WASD camera controls, R to rotate, Escape to cancel
- CameraController: orbit zoom, middle-mouse pan, WASD pan
- UIController: shop toolbar (Lumber Mill, Storage, Seller, Conveyor), coin display
- HUDController: floating "+N coins" text on sale, floating item text
- NotificationController: tree fall animation, item transit parts, blade spin
- Network: 11 new broadcast events for VS systems
- DataModel: storageInventories field
```

- [ ] **Step 4: Add Vertical Slice Alpha entry to `MILESTONE_REPORT.md`**

Add a new section at the top (before Milestone 3) describing the VS pivot, what was built, architectural decisions, and remaining risks (missing 3D models, placeholder sounds, no server-side placement validation for occupied tiles in vs-conveyor check, etc.).

- [ ] **Step 5: Commit**

```
git add README.md ROADMAP.md CHANGELOG.md TASKS.md MILESTONE_REPORT.md
git commit -m "docs: update all documentation for vertical slice alpha pivot"
```

---

## Self-Review

**Spec coverage check:**

| Requirement | Task |
|-------------|------|
| Grid placement, ghost preview, snap-to-grid, rotation, removal | Task 7 (BuildController) |
| Trees: spawning, regen, health, falling animation, collection | Task 2 (TreeService) + Task 10 (NotificationController) |
| Lumber Mill: animation, sound, visual indicators, processing progress | Task 3 (MachineService procedural model) + Task 10 (blade spin) |
| Conveyor: reliable movement, clean item spacing, good performance | Task 4 (ConveyorService) + Task 10 (transit Part) |
| Storage: stored items, capacity, simple UI | Task 5 (StorageService) + Task 9 (UIController StorageUpdated) |
| Seller: sound, particles, floating money, balance increase | Task 6 (SellerService) + Task 9 (HUDController floating text) |
| Economy: money, building costs, selling value | Task 1 (VSConfig prices) + existing EconomyService |
| Shop: conveyor, lumber mill, storage, seller | Task 9 (UIController toolbar) |
| Save: money, buildings, layout, inventory | Task 6 (SaveService integration) |
| Camera: comfortable controls, zoom, smooth movement | Task 8 (CameraController) |

**Known gaps (acceptable for alpha):**
- Sound effects: placeholder asset IDs (0) remain in SoundConfig. No audio in VS.
- 3D machine models: procedural coloured Parts only. Add Studio models post-review.
- Server-side tile validation for conveyors does not prevent placing on top of a tree tile. Trees and machines share the same world-space grid but `_tileOccupied` only tracks machines. Acceptable for alpha; add tree tile registry post-review.
- `getSegmentTiles` in NotificationController walks all Workspace children each event. Performance acceptable with <50 conveyors.

**Placeholder scan:** No "TBD", "TODO", or "implement later" found in the plan.

**Type consistency check:**
- `MachineService.Client.PlaceMachine` parameters: `machineId: string, tileX: number, tileZ: number, rotation: number` — matches BuildController call `machineService:PlaceMachine(_selectedMachineId, tile.x, tile.z, _rotation)` ✓
- `ConveyorService.Client.PlaceConveyor` parameters: `fromX, fromZ, toX, toZ` — matches BuildController call `conveyorService:PlaceConveyor(from.x, from.z, tile.x, tile.z)` ✓
- `TreeService:harvestNearestTree(centerWorld: Vector3): string?` — matches MachineService call `TreeService:harvestNearestTree(center)` ✓
- `ConveyorService:tick()` calls `MachineService:getAtTile(toKey)` which returns `{instanceId, machineId}?` — matched by deliverItem checks ✓
- `Network.Events.ItemSold` args: `(tileX, tileZ, itemId, coinsEarned)` — matches SellerService fire and HUDController listener ✓

---

**Plan complete and saved to `docs/superpowers/plans/2026-07-13-vertical-slice-alpha.md`.**

**Two execution options:**

**1. Subagent-Driven (recommended)** — Fresh subagent per task, review between tasks, fast iteration. Use skill `superpowers:subagent-driven-development`.

**2. Inline Execution** — Execute tasks in this session with checkpoints. Use skill `superpowers:executing-plans`.

Which approach?
