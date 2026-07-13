--!strict
return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ResearchData = require(ReplicatedStorage.Shared.data.ResearchData)
    local ItemData     = require(ReplicatedStorage.Shared.data.ItemData)

    describe("ResearchData", function()
        it("exports a non-empty table", function()
            expect(next(ResearchData)).to.be.ok()
        end)

        it("every entry has id matching its key", function()
            for key, node in pairs(ResearchData) do
                expect(node.id).to.equal(key)
            end
        end)

        it("every pack requirement itemId exists in ItemData", function()
            for id, node in pairs(ResearchData) do
                for _, req in ipairs(node.packRequirements) do
                    expect(ItemData[req.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("all prerequisites reference existing research nodes", function()
            for id, node in pairs(ResearchData) do
                if node.prerequisite then
                    expect(ResearchData[node.prerequisite] ~= nil).to.equal(true)
                end
            end
        end)

        it("the six main tier unlocks exist and are not side branches", function()
            local mainNodes = {"tier2_main","tier3_main","tier4_main","tier5_main","tier6_main"}
            for _, nodeId in ipairs(mainNodes) do
                local node = ResearchData[nodeId]
                expect(node).to.be.ok()
                expect(node.isSideBranch).to.equal(false)
            end
        end)

        it("tier2_main has no prerequisite", function()
            expect(ResearchData["tier2_main"].prerequisite).never.to.be.ok()
        end)
    end)
end
