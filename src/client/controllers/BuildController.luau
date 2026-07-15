--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)

local TILE = GameConfig.TILE_SIZE_STUDS

local BuildController = Knit.CreateController({ Name = "BuildController" })

-- Cast downward through terrain only to find surface Y at a world XZ position.
local function getTerrainY(wx: number, wz: number): number
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { Workspace.Terrain }
    local result = Workspace:Raycast(Vector3.new(wx, 500, wz), Vector3.new(0, -1000, 0), params)
    return if result then result.Position.Y else 0
end

-- ── State ─────────────────────────────────────────────────────────────────────

local _mode: "none" | "machine" | "conveyor" = "none"
local _selectedMachineId: string?      = nil
local _rotation: number                = 0       -- 0 | 90 | 180 | 270
local _ghostPart: BasePart?            = nil
local _conveyorFromTile: {x: number, z: number}? = nil
local _ghostConveyorPart: Part?        = nil
local _lastSnappedTile: {x: number, z: number}? = nil
local _ghostBaseSize: Vector3?         = nil  -- locked in when ghost is created; never read mid-tween

-- ── Ghost model builders (mirrors server procedural models) ──────────────────

local function buildGhostBase(tileX: number, tileZ: number, groundY: number, rotation: number, machineId: string): BasePart
    local wx, wz = tileX * TILE, tileZ * TILE

    local base = Instance.new("Part")
    base.Name         = "GhostBase"
    base.Anchored     = true
    base.CanCollide   = false
    base.Transparency = 0.5

    if machineId == "storage_chest" then
        base.BrickColor = BrickColor.new("Nougat")
        base.Size       = Vector3.new(TILE - 0.2, TILE - 0.2, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, groundY + (TILE - 0.2) / 2, wz) * CFrame.Angles(0, math.rad(rotation), 0)
    elseif machineId == "smelter" then
        base.BrickColor = BrickColor.new("Bright red")
        base.Size       = Vector3.new(TILE - 0.2, 3, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, groundY + 1.5, wz) * CFrame.Angles(0, math.rad(rotation), 0)
    elseif machineId == "crafting_bench" then
        base.BrickColor = BrickColor.new("Dark orange")
        base.Size       = Vector3.new(TILE - 0.2, 1.5, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, groundY + 0.75, wz) * CFrame.Angles(0, math.rad(rotation), 0)
    elseif machineId == "seller_station" then
        base.BrickColor = BrickColor.new("Bright yellow")
        base.Size       = Vector3.new(TILE - 0.2, 2, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, groundY + 1, wz) * CFrame.Angles(0, math.rad(rotation), 0)
    else  -- lumber_mill and fallback
        base.BrickColor = BrickColor.new("Medium stone grey")
        base.Size       = Vector3.new(TILE - 0.2, 2, TILE - 0.2)
        base.CFrame     = CFrame.new(wx, groundY + 1, wz) * CFrame.Angles(0, math.rad(rotation), 0)
    end

    base.Parent = Workspace
    return base
end

local function setGhostValid(valid: boolean)
    if not _ghostPart then return end
    local color = if valid then BrickColor.new("Bright green") else BrickColor.new("Bright red")
    _ghostPart.BrickColor = color
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
    _lastSnappedTile   = nil
    _ghostBaseSize     = nil
    if _ghostPart then
        _ghostPart:Destroy()
        _ghostPart = nil
    end
    if _ghostConveyorPart then
        _ghostConveyorPart:Destroy()
        _ghostConveyorPart = nil
    end
end

function BuildController:confirmPlacement()
    if _mode ~= "machine" or not _selectedMachineId then return end

    local InputController = Knit.GetController("InputController")
    local ignoreList: {Instance} = {}
    if _ghostPart then table.insert(ignoreList, _ghostPart) end
    if _ghostConveyorPart then table.insert(ignoreList, _ghostConveyorPart) end
    local tile = InputController:GetCursorTilePosition(TILE, ignoreList)
    if not tile then return end

    local ok: boolean
    local err: string?
    if _selectedMachineId == "crafting_bench" then
        local craftingBenchService = Knit.GetService("CraftingBenchService")
        ok, err = craftingBenchService:PlaceBench(tile.x, tile.z, _rotation)
    else
        local machineService = Knit.GetService("MachineService")
        ok, err = machineService:PlaceMachine(_selectedMachineId, tile.x, tile.z, _rotation)
    end
    if not ok then
        -- Flash ghost red briefly, then stay in placement mode
        setGhostValid(false)
        task.delay(0.3, function() setGhostValid(true) end)
        if err then warn("[BuildController] PlaceMachine failed:", err) end
    end
    -- Stay in placement mode so player can place multiple
end

-- Single entry point called by InputController left-click in conveyor mode
function BuildController:confirmConveyorStep()
    if not _conveyorFromTile then
        self:confirmPlacementConveyorStart()
    else
        self:confirmConveyorEnd()
    end
end

-- Conveyor: left-click sets FROM tile; right-click cancels.
function BuildController:confirmPlacementConveyorStart()
    if _mode ~= "conveyor" then return end
    local InputController = Knit.GetController("InputController")
    local ignoreList: {Instance} = {}
    if _ghostPart then table.insert(ignoreList, _ghostPart) end
    if _ghostConveyorPart then table.insert(ignoreList, _ghostConveyorPart) end
    local tile = InputController:GetCursorTilePosition(TILE, ignoreList)
    if not tile then return end
    _conveyorFromTile = tile
end

function BuildController:confirmConveyorEnd()
    if _mode ~= "conveyor" or not _conveyorFromTile then return end
    local InputController = Knit.GetController("InputController")
    local ignoreList: {Instance} = {}
    if _ghostPart then table.insert(ignoreList, _ghostPart) end
    if _ghostConveyorPart then table.insert(ignoreList, _ghostConveyorPart) end
    local tile = InputController:GetCursorTilePosition(TILE, ignoreList)
    if not tile then return end

    local from = _conveyorFromTile
    local dx = math.abs(tile.x - from.x)
    local dz = math.abs(tile.z - from.z)
    if dx + dz ~= 1 then
        warn("[BuildController] Conveyor: tiles are not adjacent")
        return
    end

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
            local ignoreList: {Instance} = {}
            if _ghostPart then table.insert(ignoreList, _ghostPart) end
            if _ghostConveyorPart then table.insert(ignoreList, _ghostConveyorPart) end
            local tile = InputController:GetCursorTilePosition(TILE, ignoreList)
            if not tile then
                if _ghostPart then _ghostPart:Destroy(); _ghostPart = nil end
                return
            end

            local wx, wz   = tile.x * TILE, tile.z * TILE
            local groundY  = getTerrainY(wx, wz)

            if not _ghostPart or _ghostPart.Parent == nil then
                if _ghostPart then _ghostPart:Destroy() end
                _ghostPart     = buildGhostBase(tile.x, tile.z, groundY, _rotation, _selectedMachineId)
                _ghostBaseSize = _ghostPart.Size
                _lastSnappedTile = nil  -- force snap pulse on first appearance
            else
                _ghostPart.CFrame = CFrame.new(wx, groundY + _ghostPart.Size.Y / 2, wz) * CFrame.Angles(0, math.rad(_rotation), 0)
            end

            -- Snap pulse: brief scale pop when cursor crosses onto a new tile
            if not _lastSnappedTile
                or _lastSnappedTile.x ~= tile.x
                or _lastSnappedTile.z ~= tile.z
            then
                _lastSnappedTile = tile
                if _ghostPart and _ghostBaseSize then
                    local base = _ghostBaseSize
                    _ghostPart.Size = base * 1.12
                    TweenService:Create(
                        _ghostPart,
                        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Size = base }
                    ):Play()
                end
            end

            -- Validity: always green for now (server will reject if invalid)
            setGhostValid(true)

        elseif _mode == "conveyor" then
            local ignoreList: {Instance} = {}
            if _ghostPart then table.insert(ignoreList, _ghostPart) end
            if _ghostConveyorPart then table.insert(ignoreList, _ghostConveyorPart) end
            local tile = InputController:GetCursorTilePosition(TILE, ignoreList)
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
            if _ghostPart then
                _ghostPart:Destroy()
                _ghostPart = nil
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
