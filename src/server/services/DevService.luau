--!strict
-- DevService — server-side testing helpers.
-- Only the DevController (Studio-only) calls these methods.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger = require(ReplicatedStorage.Shared.utils.Logger)
local log    = Logger.new("DevService")

local DevService = Knit.CreateService({ Name = "DevService", Client = {} })

-- Removes all machines and conveyors and clears persisted plot data.
function DevService.Client:ResetPlot(player: Player)
    local MachineService  = Knit.GetService("MachineService")
    local ConveyorService = Knit.GetService("ConveyorService")
    local SaveService     = Knit.GetService("SaveService")

    ConveyorService:resetAll()
    MachineService:resetAll()

    local data = (SaveService :: any):getSession(player)
    if data then
        data.plot.machines  = {}
        data.plot.conveyors = {}
        SaveService:updateSession(player, { plot = data.plot })
    end
    log:info("ResetPlot for %s", player.Name)
end

-- Gives the player starter items directly into their inventory.
function DevService.Client:GiveStarterItems(player: Player)
    local InventoryService = Knit.GetService("InventoryService")
    InventoryService:addItem(player, "log",      30)
    InventoryService:addItem(player, "stone",    20)
    InventoryService:addItem(player, "iron_ore", 15)
    log:info("Gave starter items to %s", player.Name)
end

-- Stuffs 5 logs into every placed lumber mill's input buffer.
function DevService.Client:FillMills(_player: Player, count: number)
    Knit.GetService("MachineService"):fillAllMills(math.clamp(count, 1, 10))
    log:info("filled mills ×%d", count)
end

-- Changes simulation speed for both machine and conveyor ticks.
function DevService.Client:SetTickMultiplier(_player: Player, mult: number)
    mult = math.clamp(mult, 1, 10)
    Knit.GetService("MachineService"):setTickMultiplier(mult)
    Knit.GetService("ConveyorService"):setTickMultiplier(mult)
    log:info("tick multiplier → %dx", mult)
end

-- Dumps machine and conveyor state to the server output panel.
function DevService.Client:PrintState(player: Player)
    warn(string.format("══ Dev State Dump (%s) ══════════════════", player.Name))
    local InventoryService = Knit.GetService("InventoryService")
    local slots = InventoryService:getSlots(player)
    local lines = {}
    for i = 1, 25 do
        local s = slots[i]
        if s then table.insert(lines, string.format("  [%d] %s × %d", i, s.itemId, s.count)) end
    end
    warn("  Inventory:\n" .. (if #lines > 0 then table.concat(lines, "\n") else "  (empty)"))
    Knit.GetService("MachineService"):debugPrintState()
    Knit.GetService("ConveyorService"):debugPrintState()
    warn("═══════════════════════════════════════════")
end

function DevService:KnitInit() end
function DevService:KnitStart()
    log:info("DevService started")
end

return DevService
