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
