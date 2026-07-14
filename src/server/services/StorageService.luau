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
