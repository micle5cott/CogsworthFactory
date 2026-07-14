--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger   = require(ReplicatedStorage.Shared.utils.Logger)
local VSConfig = require(ReplicatedStorage.Shared.config.VSConfig)
local Network  = require(ReplicatedStorage.Shared.Network)

local log = Logger.new("WorldDropService")

local WorldDropService = Knit.CreateService({ Name = "WorldDropService", Client = {} })

type DropRecord = {
    dropId:     string,
    itemId:     string,
    count:      number,
    part:       Part,
    expireTask: thread?,
}

local _drops: {[string]: DropRecord} = {}
local _nextId = 0

local ITEM_COLORS: {[string]: BrickColor} = {
    log              = BrickColor.new("Reddish brown"),
    stone            = BrickColor.new("Medium stone grey"),
    iron_ore         = BrickColor.new("Bright red"),
    copper_ore       = BrickColor.new("Bright orange"),
    gold_ore         = BrickColor.new("Bright yellow"),
    lumber           = BrickColor.new("Nougat"),
    iron_ingot       = BrickColor.new("Sand red"),
}

local function newId(): string
    _nextId += 1
    return "drop_" .. _nextId
end

local function buildDropPart(itemId: string, pos: Vector3): Part
    local p = Instance.new("Part")
    p.Name       = "Drop_" .. itemId
    p.Size       = Vector3.new(0.6, 0.6, 0.6)
    p.BrickColor = ITEM_COLORS[itemId] or BrickColor.new("Medium blue")
    p.Material   = Enum.Material.SmoothPlastic
    p.Anchored   = false
    p.CanCollide = true
    p.CFrame     = CFrame.new(pos + Vector3.new(0, 1, 0))
    p.Parent     = Workspace
    return p
end

-- ── Public API ────────────────────────────────────────────────────────────────

function WorldDropService:dropItem(itemId: string, count: number, position: Vector3)
    local id   = newId()
    local part = buildDropPart(itemId, position)
    part:SetAttribute("DropId", id)

    local record: DropRecord = {
        dropId = id,
        itemId = itemId,
        count  = count,
        part   = part,
    }

    record.expireTask = task.delay(VSConfig.DROP_DESPAWN_SECONDS, function()
        if _drops[id] then
            _drops[id].part:Destroy()
            _drops[id] = nil
            Network.getEvent(Network.Events.ItemPickedUp):FireAllClients(id)
        end
    end)

    _drops[id] = record

    Network.getEvent(Network.Events.ItemDropped):FireAllClients(
        id, itemId, count, position.X, position.Y, position.Z
    )
end

-- ── Client endpoints ──────────────────────────────────────────────────────────

function WorldDropService.Client:PickupDrop(player: Player, dropId: string): (boolean, string?)
    local drop = _drops[dropId]
    if not drop then return false, "drop not found" end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return false, "no character" end

    local dist = (hrp.Position - drop.part.Position).Magnitude
    if dist > VSConfig.ITEM_PICKUP_RADIUS then
        return false, "too far"
    end

    local InventoryService = Knit.GetService("InventoryService")
    InventoryService:addItem(player, drop.itemId, drop.count)

    if drop.expireTask then task.cancel(drop.expireTask) end
    drop.part:Destroy()
    _drops[dropId] = nil

    Network.getEvent(Network.Events.ItemPickedUp):FireAllClients(dropId)
    log:info("%s picked up %d × %s", player.Name, drop.count, drop.itemId)
    return true, nil
end

function WorldDropService:KnitInit() end

function WorldDropService:KnitStart()
    log:info("WorldDropService started")
end

return WorldDropService
