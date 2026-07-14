--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger   = require(ReplicatedStorage.Shared.utils.Logger)
local VSConfig = require(ReplicatedStorage.Shared.config.VSConfig)
local Network  = require(ReplicatedStorage.Shared.Network)

local log = Logger.new("InventoryService")

local InventoryService = Knit.CreateService({ Name = "InventoryService", Client = {} })

-- player.UserId → {[number]: {itemId:string, count:number}?}
local _sessions: {[number]: {[number]: {itemId: string, count: number}?}} = {}

local SLOTS = VSConfig.INVENTORY_SLOTS
local STACK = VSConfig.STACK_SIZE

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function getSlots(player: Player): {[number]: {itemId: string, count: number}?}
    if not _sessions[player.UserId] then
        _sessions[player.UserId] = {}
    end
    return _sessions[player.UserId]
end

local function fireUpdate(player: Player)
    Network.getEvent(Network.Events.InventoryUpdated):FireClient(player, getSlots(player))
end

-- ── Public API ────────────────────────────────────────────────────────────────

function InventoryService:getSlots(player: Player): {[number]: {itemId: string, count: number}?}
    return getSlots(player)
end

function InventoryService:addItem(player: Player, itemId: string, count: number): (boolean, string?)
    local slots     = getSlots(player)
    local remaining = count

    -- Fill existing stacks of the same item first
    for i = 1, SLOTS do
        if remaining <= 0 then break end
        local slot = slots[i]
        if slot and slot.itemId == itemId and slot.count < STACK then
            local space = STACK - slot.count
            local add   = math.min(space, remaining)
            slot.count += add
            remaining  -= add
        end
    end

    -- Open new slots for any remainder
    for i = 1, SLOTS do
        if remaining <= 0 then break end
        if slots[i] == nil then
            local add = math.min(STACK, remaining)
            slots[i]  = { itemId = itemId, count = add }
            remaining -= add
        end
    end

    if remaining > 0 then
        log:warn("Inventory full for %s — lost %d × %s", player.Name, remaining, itemId)
    end

    fireUpdate(player)
    return true, nil
end

function InventoryService:hasItems(player: Player, costs: {[string]: number}): boolean
    local slots  = getSlots(player)
    local totals: {[string]: number} = {}
    for i = 1, SLOTS do
        local slot = slots[i]
        if slot then
            totals[slot.itemId] = (totals[slot.itemId] or 0) + slot.count
        end
    end
    for itemId, needed in pairs(costs) do
        if (totals[itemId] or 0) < needed then return false end
    end
    return true
end

function InventoryService:removeItems(player: Player, costs: {[string]: number}): (boolean, string?)
    if not self:hasItems(player, costs) then
        return false, "insufficient items"
    end
    local slots = getSlots(player)
    for itemId, needed in pairs(costs) do
        local left = needed
        for i = 1, SLOTS do
            if left <= 0 then break end
            local slot = slots[i]
            if slot and slot.itemId == itemId then
                local take = math.min(slot.count, left)
                slot.count -= take
                left       -= take
                if slot.count <= 0 then slots[i] = nil end
            end
        end
    end
    fireUpdate(player)
    return true, nil
end

function InventoryService:seedChisel(player: Player)
    local slots       = getSlots(player)
    local hasAnything = false
    for i = 1, SLOTS do
        if slots[i] then hasAnything = true; break end
    end
    if not hasAnything then
        self:addItem(player, "chisel", 1)
        log:info("Seeded chisel for new player %s", player.Name)
    end
end

function InventoryService:loadFromSave(player: Player, saved: {[number]: {itemId: string, count: number}?})
    _sessions[player.UserId] = saved or {}
end

function InventoryService:getSlotsForSave(player: Player): {[number]: {itemId: string, count: number}?}
    return getSlots(player)
end

-- ── Client endpoints ──────────────────────────────────────────────────────────

function InventoryService.Client:GetSlots(player: Player): {[number]: {itemId: string, count: number}?}
    return InventoryService:getSlots(player)
end

function InventoryService.Client:PersonalCraft(player: Player, recipeId: string): (boolean, string?)
    local recipe = VSConfig.PERSONAL_RECIPES[recipeId]
    if not recipe then return false, "unknown recipe: " .. recipeId end

    local ok, err = InventoryService:removeItems(player, recipe.inputs)
    if not ok then return false, err end

    for itemId, count in pairs(recipe.outputs) do
        InventoryService:addItem(player, itemId, count)
    end
    log:info("%s crafted %s (personal)", player.Name, recipeId)
    return true, nil
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function InventoryService:KnitInit() end

function InventoryService:KnitStart()
    log:info("InventoryService started (slots=%d, stack=%d)", SLOTS, STACK)
end

return InventoryService
