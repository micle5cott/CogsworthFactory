--!strict
return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local MachineData = require(ReplicatedStorage.Shared.data.MachineData)
    local ItemData    = require(ReplicatedStorage.Shared.data.ItemData)

    describe("MachineData", function()
        it("exports a non-empty table", function()
            expect(next(MachineData)).to.be.ok()
        end)

        it("every entry has id matching its key", function()
            for key, m in pairs(MachineData) do
                expect(m.id).to.equal(key)
            end
        end)

        it("every entry has required scalar fields", function()
            for id, m in pairs(MachineData) do
                expect(typeof(m.name)).to.equal("string")
                expect(m.tier >= 1 and m.tier <= 6).to.equal(true)
                expect(m.powerDraw >= 0).to.equal(true)
                expect(m.bufferSize >= 0).to.equal(true)
            end
        end)

        it("all build cost itemIds exist in ItemData", function()
            for id, m in pairs(MachineData) do
                for _, entry in ipairs(m.buildCost) do
                    expect(ItemData[entry.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("all input itemIds exist in ItemData", function()
            for id, m in pairs(MachineData) do
                for _, inp in ipairs(m.inputs) do
                    expect(ItemData[inp.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("all output itemIds exist in ItemData", function()
            for id, m in pairs(MachineData) do
                for _, out in ipairs(m.outputs) do
                    expect(ItemData[out.itemId] ~= nil).to.equal(true)
                end
            end
        end)

        it("generators have generatorOutput > 0", function()
            for id, m in pairs(MachineData) do
                if m.isGenerator then
                    expect((m.generatorOutput or 0) > 0).to.equal(true)
                end
            end
        end)

        it("storage machines have storageCapacity", function()
            for id, m in pairs(MachineData) do
                if m.isStorage then
                    expect((m.storageCapacity or 0) > 0).to.equal(true)
                end
            end
        end)

        it("contains exactly 41 machines across tiers 1–6", function()
            local count = 0
            for _ in pairs(MachineData) do count += 1 end
            expect(count).to.equal(41)
        end)
    end)
end
