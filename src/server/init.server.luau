--!strict
-- Server bootstrap: loads all Knit services then starts the framework.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

Knit.AddServicesDeep(ServerScriptService.Server.services)

Knit.Start():andThen(function()
    print("[CogsworthFactory] Server started.")
end):catch(function(err)
    warn("[CogsworthFactory] Server startup error:", err)
end)
