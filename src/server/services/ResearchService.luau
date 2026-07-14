--!strict
-- Manages research pack delivery, tier progression, and side-branch unlocks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local ResearchService = Knit.CreateService({
    Name = "ResearchService",
    Client = {
        ResearchProgressUpdated = Knit.CreateSignal(), -- (researchId: string, progress: number, required: number)
        ResearchCompleted       = Knit.CreateSignal(), -- (researchId: string, unlocks: {string})
    },
})

-- Returns the currently active research node for a plot (the one consuming packs).
function ResearchService:GetActiveResearch(plotOwnerId: number): string?
    return nil
end

-- Set which research node should actively consume packs.
-- Player must own the plot. Returns (success, errorMessage?).
function ResearchService:SetActiveResearch(player: Player, researchId: string): (boolean, string?)
    return false, "not implemented"
end

-- Returns true if a research node is completed for a plot.
function ResearchService:IsCompleted(plotOwnerId: number, researchId: string): boolean
    return false
end

-- Called when the Research Station receives a valid pack item.
-- Advances progress toward the active research node.
function ResearchService:OnPackDelivered(plotOwnerId: number, itemId: string)
end

function ResearchService:KnitInit() end
function ResearchService:KnitStart() end

return ResearchService
