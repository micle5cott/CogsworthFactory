--!strict
-- Displays server announcements (rare node discoveries, tier unlocks, ascension events)
-- and contextual Automaton Companion hints.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local NotificationController = Knit.CreateController({ Name = "NotificationController" })

-- Show a server-wide announcement banner (rare node, ascension, tier unlock).
-- priority: "low" | "high" | "legendary" — controls animation and duration.
function NotificationController:ShowAnnouncement(message: string, priority: string)
end

-- Show a contextual Automaton Companion hint bubble.
-- Auto-dismissed after 8 seconds or on player action.
function NotificationController:ShowHint(message: string)
end

-- Suppress all hints (player toggled off in Settings).
function NotificationController:SetHintsEnabled(enabled: boolean)
end

function NotificationController:KnitInit() end

function NotificationController:KnitStart()
    -- Subscribe to Remotes.RareNodeDiscovered → ShowAnnouncement
    -- Subscribe to Remotes.ResearchTierUnlocked → ShowAnnouncement
    -- Subscribe to Remotes.AscensionTriggered → ShowAnnouncement (legendary priority)
end

return NotificationController
