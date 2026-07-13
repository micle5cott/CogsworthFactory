--!strict
return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ItemData = require(ReplicatedStorage.Shared.data.ItemData)

    describe("ItemData", function()
        it("exports a non-empty table", function()
            expect(next(ItemData)).to.be.ok()
        end)

        it("every entry has id matching its key", function()
            for key, item in pairs(ItemData) do
                expect(item.id).to.equal(key)
            end
        end)

        it("every entry has a name string", function()
            for _, item in pairs(ItemData) do
                expect(typeof(item.name)).to.equal("string")
                expect(#item.name > 0).to.equal(true)
            end
        end)

        it("every entry has a valid tier 1–6", function()
            for _, item in pairs(ItemData) do
                expect(item.tier >= 1 and item.tier <= 6).to.equal(true)
            end
        end)

        it("rare items have a rarityTier", function()
            for _, item in pairs(ItemData) do
                if item.isRare then
                    expect(item.rarityTier).to.be.ok()
                    local valid = item.rarityTier == "uncommon"
                        or item.rarityTier == "rare"
                        or item.rarityTier == "legendary"
                    expect(valid).to.equal(true)
                end
            end
        end)

        it("contains expected core items", function()
            expect(ItemData["iron_ore"]).to.be.ok()
            expect(ItemData["copper_wire"]).to.be.ok()
            expect(ItemData["clockwork_automaton"]).to.be.ok()
            expect(ItemData["pure_aether"]).to.be.ok()
            expect(ItemData["void_fragment"]).to.be.ok()
        end)
    end)
end
