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

-- E-key: opens storage UI for the owning player (fires StorageOpened to that client)
function StorageService.Client:OpenStorage(player: Player, instanceId: string): boolean
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(player)
    if not data then return false end

    -- Proximity check via MachineService world CFrame
    local MachineService = Knit.GetService("MachineService")
    local cf = MachineService:getWorldCFrame(instanceId)
    if not cf then return false end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return false end
    if (hrp.Position - cf.Position).Magnitude > 12 then return false end

    local inv = data.storageInventories[instanceId] or {}
    Network.getEvent(Network.Events.StorageOpened):FireClient(player, instanceId, inv)
    return true
end

-- Empties a chest into the player's personal inventory
function StorageService:takeAll(instanceId: string, player: Player)
    local SaveService = Knit.GetService("SaveService")
    local data = SaveService:getSession(player)
    if not data then return end

    local inv = data.storageInventories[instanceId]
    if not inv then return end

    local InventoryService = Knit.GetService("InventoryService")
    for itemId, count in pairs(inv) do
        if count > 0 then
            InventoryService:addItem(player, itemId, count)
        end
    end

    data.storageInventories[instanceId] = {}
    SaveService:updateSession(player, {storageInventories = data.storageInventories})
    Network.getEvent(Network.Events.StorageUpdated):FireAllClients(instanceId, {})
    log:info("%s took all from storage %s", player.Name, instanceId)
end

function StorageService.Client:TakeAll(player: Player, instanceId: string)
    StorageService:takeAll(instanceId, player)
end

function StorageService:KnitInit() end
function StorageService:KnitStart()
    log:info("StorageService started")
end

return StorageService
