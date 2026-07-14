--!strict
-- Owns the main HUD: machine toolbar, research progress bar, efficiency overlays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local UIController = Knit.CreateController({ Name = "UIController" })

-- Show/hide the machine selection toolbar.
function UIController:SetToolbarVisible(visible: boolean)
end

-- Update the research progress bar (0–1).
function UIController:SetResearchProgress(fraction: number, researchName: string)
end

-- Show efficiency overlay on all visible machines.
function UIController:SetEfficiencyOverlayEnabled(enabled: boolean)
end

-- Open the Trophy Case display for a plot.
function UIController:OpenTrophyCase(plotOwnerId: number)
end

function UIController:KnitInit() end
function UIController:KnitStart() end

return UIController
