--!strict
return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local BiomeData    = require(ReplicatedStorage.Shared.data.BiomeData)
    local RareNodeData = require(ReplicatedStorage.Shared.data.RareNodeData)
    local ItemData     = require(ReplicatedStorage.Shared.data.ItemData)
    local ResearchData = require(ReplicatedStorage.Shared.data.ResearchData)
    local Constants    = require(ReplicatedStorage.Shared.Constants)

    describe("BiomeData", function()
        it("contains exactly 5 biomes", function()
            local count = 0
            for _ in pairs(BiomeData) do count += 1 end
            expect(count).to.equal(5)
        end)

        it("every biome node itemId exists in ItemData", function()
            for biomeId, biome in pairs(BiomeData) do
                for _, node in ipairs(biome.nodes) do
                    expect(ItemData[node.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("unlock research ids exist in ResearchData when non-nil", function()
            for _, biome in pairs(BiomeData) do
                if biome.unlockResearchId then
                    expect(ResearchData[biome.unlockResearchId] ~= nil).to.equal(true)
                end
            end
        end)

        it("exactly one biome has no unlock (starting biome)", function()
            local startCount = 0
            for _, biome in pairs(BiomeData) do
                if biome.unlockResearchId == nil then
                    startCount += 1
                end
            end
            expect(startCount).to.equal(1)
        end)
    end)

    describe("RareNodeData", function()
        it("contains exactly 10 rare nodes", function()
            local count = 0
            for _ in pairs(RareNodeData) do count += 1 end
            expect(count).to.equal(10)
        end)

        it("every rare node biomeId exists in BiomeData", function()
            for _, node in pairs(RareNodeData) do
                expect(BiomeData[node.biomeId] ~= nil).to.equal(true)
            end
        end)

        it("every outputItemId exists in ItemData", function()
            for _, node in pairs(RareNodeData) do
                expect(ItemData[node.outputItemId] ~= nil).to.equal(true)
            end
        end)

        it("spawn chances match Constants.RARE_NODE_CHANCE", function()
            for _, node in pairs(RareNodeData) do
                local expected = Constants.RARE_NODE_CHANCE[node.rarity]
                expect(node.spawnChance).to.equal(expected)
            end
        end)

        it("has exactly 3 legendary nodes", function()
            local count = 0
            for _, node in pairs(RareNodeData) do
                if node.rarity == "legendary" then count += 1 end
            end
            expect(count).to.equal(3)
        end)
    end)
end
