--!strict
-- Configurable logger. Create a named instance per module.
-- Debug output is suppressed globally until LoggingService enables it.

local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local _prefix = IS_SERVER and "[S]" or "[C]"
local _debugEnabled = false

local Logger = {}
Logger.__index = Logger

type LoggerFields = {
    _context: string,
}

export type Logger = typeof(setmetatable({} :: LoggerFields, Logger))

function Logger.new(context: string): Logger
    return setmetatable({ _context = context } :: LoggerFields, Logger)
end

function Logger:info(fmt: string, ...: any)
    print(string.format("%s[INFO][%s] %s", _prefix, self._context, string.format(fmt, ...)))
end

function Logger:warn(fmt: string, ...: any)
    warn(string.format("%s[WARN][%s] %s", _prefix, self._context, string.format(fmt, ...)))
end

function Logger:error(fmt: string, ...: any)
    -- Non-throwing; use assert/error at call site when a hard stop is needed.
    warn(string.format("%s[ERROR][%s] %s", _prefix, self._context, string.format(fmt, ...)))
end

function Logger:debug(fmt: string, ...: any)
    if _debugEnabled then
        print(string.format("%s[DEBUG][%s] %s", _prefix, self._context, string.format(fmt, ...)))
    end
end

function Logger.setDebugEnabled(enabled: boolean)
    _debugEnabled = enabled
end

function Logger.isDebugEnabled(): boolean
    return _debugEnabled
end

return Logger
