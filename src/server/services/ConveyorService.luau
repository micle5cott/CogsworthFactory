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

    -- Attributes for Task 10 client visuals
    belt:SetAttribute("FromX", fromX)
    belt:SetAttribute("FromZ", fromZ)
    belt:SetAttribute("ToX", toX)
    belt:SetAttribute("ToZ", toZ)

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
    model:SetAttribute("SegmentId", id)

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
        model:SetAttribute("SegmentId", s.segmentId)
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
