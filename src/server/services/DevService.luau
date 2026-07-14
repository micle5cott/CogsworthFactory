--!strict
-- DevService — server-side testing helpers.
-- Only the DevController (Studio-only) calls these methods.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger = require(ReplicatedStorage.Shared.utils.Logger)
local log    = Logger.new("DevService")

local STARTING_COINS = 200

local DevService = Knit.CreateService({ Name = "DevService", Client = {} })

-- Removes all machines and conveyors, resets coins to the starting amount,
-- and clears persisted plot data so the session reloads cleanly.
function DevService.Client:ResetPlot(player: Player)
    local MachineService  = Knit.GetService("MachineService")
    local ConveyorService = Knit.GetService("ConveyorService")
    local EconomyService  = Knit.GetService("EconomyService")
    local SaveService     = Knit.GetService("SaveService")

    -- Conveyors first so no belt tries to push into a removed machine
    ConveyorService:resetAll()
    MachineService:resetAll()

    local data = (SaveService :: any):getSession(player)
    if data then
        data.plot.machines  = {}
        data.plot.conveyors = {}
        SaveService:updateSession(player, { plot = data.plot })
    end

    EconomyService:setCoins(player, STARTING_COINS)
    log:info("ResetPlot for %s", player.Name)
end

-- Awards coins directly without requiring a sell cycle.
function DevService.Client:AddCoins(player: Player, amount: number)
    Knit.GetService("EconomyService"):awardCoins(player, math.max(1, amount))
    log:info("+%d coins for %s", amount, player.Name)
end

-- Stuffs 5 logs into every placed lumber mill's input buffer.
function DevService.Client:FillMills(player: Player, count: number)
    Knit.GetService("MachineService"):fillAllMills(math.clamp(count, 1, 10))
    log:info("filled mills ×%d for %s", count, player.Name)
end

-- Changes simulation speed for both machine and conveyor ticks.
-- mult=1 is normal; mult=5 is fast test mode.
function DevService.Client:SetTickMultiplier(_player: Player, mult: number)
    mult = math.clamp(mult, 1, 10)
    Knit.GetService("MachineService"):setTickMultiplier(mult)
    Knit.GetService("ConveyorService"):setTickMultiplier(mult)
    log:info("tick multiplier → %dx", mult)
end

-- Dumps machine, conveyor, and in-transit state to the server output panel.
function DevService.Client:PrintState(player: Player)
    warn(string.format("══ Dev State Dump (%s) ══════════════════", player.Name))
    warn(string.format("  Coins: %d", Knit.GetService("EconomyService"):getCoins(player)))
    Knit.GetService("MachineService"):debugPrintState()
    Knit.GetService("ConveyorService"):debugPrintState()
    warn("═══════════════════════════════════════════")
end

function DevService:KnitInit() end
function DevService:KnitStart()
    log:info("DevService started")
end

return DevService
