--!strict
local Players           = game:GetService("Players")
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

-- Chisel is a physical Roblox Tool in the hotbar, not a slot item.
-- Give it to Backpack on join; CharacterAdded re-gives it after respawn.
function InventoryService:seedChisel(player: Player)
    local char     = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    local hasIt    = (char and char:FindFirstChild("Chisel") ~= nil)
                  or (backpack and backpack:FindFirstChild("Chisel") ~= nil)
    if hasIt then return end

    local tool = Instance.new("Tool")
    tool.Name           = "Chisel"
    tool.ToolTip        = "Mining Chisel — equip and hold E to mine"
    tool.RequiresHandle = true
    tool.CanBeDropped   = false

    local handle = Instance.new("Part")
    handle.Name     = "Handle"
    handle.Size     = Vector3.new(0.2, 1.4, 0.2)
    handle.BrickColor = BrickColor.new("Bright yellow")
    handle.Material = Enum.Material.Metal
    handle.Parent   = tool

    if backpack then
        tool.Parent = backpack
    end
    log:info("Seeded chisel Tool for %s", player.Name)
end

function InventoryService:loadFromSave(player: Player, saved: {[number]: {itemId: string, count: number}?})
    -- Strip any legacy chisel slot entries — chisel is now a Tool, not a slot item
    local filtered: {[number]: {itemId: string, count: number}?} = {}
    for k, v in pairs(saved or {}) do
        if v and v.itemId ~= "chisel" then
            filtered[k] = v
        end
    end
    _sessions[player.UserId] = filtered
    -- Push to client immediately; client may already be connected after DataStore latency
    fireUpdate(player)
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

    local function wireCharacter(player: Player)
        -- Re-seed chisel each time character spawns (e.g. after death)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)  -- let Backpack settle before parenting Tool
            self:seedChisel(player)
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        wireCharacter(player)
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        wireCharacter(p)
    end
end

return InventoryService
