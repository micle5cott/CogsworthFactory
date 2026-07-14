--!strict
-- Server-side logging coordinator.
-- Configures the shared Logger on startup and exposes runtime debug toggle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger     = require(ReplicatedStorage.Shared.utils.Logger)
local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)

local log = Logger.new("LoggingService")

local LoggingService = Knit.CreateService({
    Name   = "LoggingService",
    Client = {},
})

-- Enable or disable debug output globally at runtime.
function LoggingService:setDebug(enabled: boolean)
    Logger.setDebugEnabled(enabled)
    log:info("Debug logging %s", enabled and "ENABLED" or "DISABLED")
end

function LoggingService:isDebugEnabled(): boolean
    return Logger.isDebugEnabled()
end

function LoggingService:KnitInit()
    -- Apply config before any other service's KnitStart runs.
    Logger.setDebugEnabled(GameConfig.DEBUG_LOGGING)
end

function LoggingService:KnitStart()
    log:info("LoggingService started (debug=%s)", tostring(GameConfig.DEBUG_LOGGING))
end

return LoggingService
