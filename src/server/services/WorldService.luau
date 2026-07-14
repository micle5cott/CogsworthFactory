--!strict
-- World and environment management: biome regions, tile grid, ambient systems.
-- Gameplay implementation (actual terrain, node spawning) deferred to Milestone 4.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger     = require(ReplicatedStorage.Shared.utils.Logger)
local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)

local log = Logger.new("WorldService")

local TILE_SIZE = GameConfig.TILE_SIZE_STUDS

local WorldService = Knit.CreateService({
    Name = "WorldService",
    Client = {
        BiomeActivated = Knit.CreateSignal(), -- (biomeId: string)
    },
})

-- Returns the biome id containing a given world position.
-- Stub: returns starting biome until biome region maps are built in Milestone 4.
function WorldService:getBiomeAtPosition(_position: Vector3): string
    return "verdant_hollow"
end

-- Returns world position snapped to the nearest tile centre.
function WorldService:snapToTile(position: Vector3): Vector3
    return Vector3.new(
        math.round(position.X / TILE_SIZE) * TILE_SIZE,
        position.Y,
        math.round(position.Z / TILE_SIZE) * TILE_SIZE
    )
end

-- Converts a tile {x, z} to a world Vector3 at ground level.
function WorldService:tileToWorld(tile: {x: number, z: number}): Vector3
    return Vector3.new(tile.x * TILE_SIZE, 0, tile.z * TILE_SIZE)
end

-- Converts a world position to tile coordinates.
function WorldService:worldToTile(position: Vector3): {x: number, z: number}
    return {
        x = math.round(position.X / TILE_SIZE),
        z = math.round(position.Z / TILE_SIZE),
    }
end

function WorldService:KnitInit() end

function WorldService:KnitStart()
    log:info("WorldService started (tileSize=%d studs)", TILE_SIZE)
end

return WorldService
