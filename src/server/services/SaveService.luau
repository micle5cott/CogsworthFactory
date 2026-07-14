--!strict
-- Serializes and deserializes full PlotState to/from Roblox DataStores.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Types = require(ReplicatedStorage.Shared.Types)
type PlotState = Types.PlotState

local SaveService = Knit.CreateService({
    Name = "SaveService",
    Client = {},
})

-- Load PlotState for a player. Returns nil if no save exists (new player).
function SaveService:LoadPlot(player: Player): PlotState?
    return nil
end

-- Persist PlotState. Called every SAVE_INTERVAL_SECONDS and on player leave.
function SaveService:SavePlot(player: Player, state: PlotState): boolean
    return false
end

-- Wipe save data for a player (used on Ascension reset after state is confirmed saved).
function SaveService:WipePlot(player: Player): boolean
    return false
end

function SaveService:KnitInit() end

function SaveService:KnitStart()
    -- Set up auto-save loop at Constants.SAVE_INTERVAL_SECONDS
    -- Set up player leaving hook to save on disconnect
end

return SaveService
