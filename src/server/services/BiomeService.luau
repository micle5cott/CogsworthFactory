--!strict
-- Manages biome unlock state and resource node placement per biome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local BiomeService = Knit.CreateService({
    Name = "BiomeService",
    Client = {
        BiomeUnlocked = Knit.CreateSignal(), -- (biomeId: string)
    },
})

-- Returns list of unlocked biome ids for a plot.
function BiomeService:GetUnlockedBiomes(plotOwnerId: number): {string}
    return {}
end

-- Called by ResearchService when a biome unlock is completed.
function BiomeService:UnlockBiome(plotOwnerId: number, biomeId: string)
end

-- Returns true if a given tile position is within an unlocked biome.
function BiomeService:IsTileAccessible(plotOwnerId: number, position: {x: number, z: number}): boolean
    return false
end

function BiomeService:KnitInit() end
function BiomeService:KnitStart() end

return BiomeService
