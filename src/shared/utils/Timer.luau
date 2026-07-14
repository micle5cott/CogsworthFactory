--!strict
-- Repeating or one-shot timer backed by task.spawn.
-- Call :start() to begin, :stop() to cancel cleanly.

local Timer = {}
Timer.__index = Timer

type TimerFields = {
    _interval: number,
    _callback: () -> (),
    _repeating: boolean,
    _running: boolean,
    _thread: thread?,
}

export type Timer = typeof(setmetatable({} :: TimerFields, Timer))

function Timer.new(interval: number, callback: () -> (), repeating: boolean?): Timer
    return setmetatable({
        _interval  = interval,
        _callback  = callback,
        _repeating = if repeating ~= nil then repeating else true,
        _running   = false,
        _thread    = nil,
    } :: TimerFields, Timer)
end

function Timer:start()
    if self._running then return end
    self._running = true
    self._thread = task.spawn(function()
        repeat
            task.wait(self._interval)
            if self._running then
                self._callback()
            end
        until not self._repeating or not self._running
        self._running = false
    end)
end

function Timer:stop()
    self._running = false
    if self._thread then
        task.cancel(self._thread)
        self._thread = nil
    end
end

function Timer:isRunning(): boolean
    return self._running
end

function Timer:destroy()
    self:stop()
end

return Timer
