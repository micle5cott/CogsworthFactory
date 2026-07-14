--!strict
-- Non-Knit RemoteEvents for server-to-all-clients broadcasts.
-- Knit services expose their own per-client signals via their Client tables.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = RunService:IsServer()

local function getOrCreate(name: string): RemoteEvent
    if IS_SERVER then
        local existing = ReplicatedStorage:FindFirstChild(name)
        if existing and existing:IsA("RemoteEvent") then
            return existing :: RemoteEvent
        end
        local event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = ReplicatedStorage
        return event
    else
        local found = ReplicatedStorage:WaitForChild(name, 10)
        assert(found and found:IsA("RemoteEvent"), "Remote not found: " .. name)
        return found :: RemoteEvent
    end
end

--[[
    Fired server→all-clients when a rare node is discovered.
    Args: (playerName: string, rareNodeId: string, announcement: string)
]]
local RareNodeDiscovered: RemoteEvent = getOrCreate("RareNodeDiscovered")

--[[
    Fired server→all-clients for generic server announcements.
    Args: (message: string)
]]
local ServerAnnouncement: RemoteEvent = getOrCreate("ServerAnnouncement")

--[[
    Fired server→all-clients when the plot owner unlocks a new tier.
    Args: (ownerName: string, tier: number)
]]
local ResearchTierUnlocked: RemoteEvent = getOrCreate("ResearchTierUnlocked")

--[[
    Fired server→all-clients when Ascension is triggered.
    Args: (ownerName: string, ascensionCount: number)
]]
local AscensionTriggered: RemoteEvent = getOrCreate("AscensionTriggered")

return {
    RareNodeDiscovered   = RareNodeDiscovered,
    ServerAnnouncement   = ServerAnnouncement,
    ResearchTierUnlocked = ResearchTierUnlocked,
    AscensionTriggered   = AscensionTriggered,
}
