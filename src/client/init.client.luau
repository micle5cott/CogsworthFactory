--!strict
-- Client bootstrap: loads all Knit controllers then starts the framework.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")

Knit.AddControllersDeep(playerScripts.Client.controllers)

Knit.Start():andThen(function()
    print("[CogsworthFactory] Client started for", localPlayer.Name)
end):catch(function(err)
    warn("[CogsworthFactory] Client startup error:", err)
end)
