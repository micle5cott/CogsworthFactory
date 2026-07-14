--!strict
-- Maid/cleanup utility. Tracks Instances, RBXScriptConnections, functions,
-- and threads, then destroys/disconnects/cancels all of them on :cleanup().

local Janitor = {}
Janitor.__index = Janitor

type Task = Instance | RBXScriptConnection | (() -> ()) | thread

type JanitorFields = {
    _tasks: {Task},
}

export type Janitor = typeof(setmetatable({} :: JanitorFields, Janitor))

function Janitor.new(): Janitor
    return setmetatable({ _tasks = {} } :: JanitorFields, Janitor)
end

-- Add any trackable task. Returns the task so callers can store and use it.
function Janitor:add<T>(t: T & Task): T
    table.insert(self._tasks, t :: Task)
    return t
end

-- Convenience overload for connections (same as :add but named explicitly).
function Janitor:addConnection(c: RBXScriptConnection): RBXScriptConnection
    return self:add(c)
end

-- Destroy all tracked tasks and clear the list.
function Janitor:cleanup()
    for _, t in ipairs(self._tasks) do
        local kind = typeof(t)
        if kind == "Instance" then
            (t :: Instance):Destroy()
        elseif kind == "RBXScriptConnection" then
            (t :: RBXScriptConnection):Disconnect()
        elseif kind == "function" then
            (t :: () -> ())()
        elseif kind == "thread" then
            task.cancel(t :: thread)
        end
    end
    table.clear(self._tasks)
end

-- Alias for :cleanup() — satisfies Roblox destroy conventions.
function Janitor:destroy()
    self:cleanup()
end

return Janitor
