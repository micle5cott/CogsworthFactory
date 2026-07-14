--!strict
-- Input validation helpers for service boundaries (player requests, config checks).
-- All functions are pure and have no side effects.

local RunService = game:GetService("RunService")

local Validation = {}

-- Assert value is non-nil and return it; raises on failure.
function Validation.require<T>(value: T?, label: string): T
    if value == nil then
        error(string.format("[Validation] Required value missing: %s", label), 2)
    end
    return value :: T
end

-- Returns true if value is a non-empty string.
function Validation.nonEmptyString(value: unknown): boolean
    return typeof(value) == "string" and #(value :: string) > 0
end

-- Returns true if number is within [min, max] inclusive.
function Validation.inRange(value: number, min: number, max: number): boolean
    return value >= min and value <= max
end

-- Returns true if value exists in the options list.
function Validation.isOneOf<T>(value: T, options: {T}): boolean
    for _, v in ipairs(options) do
        if v == value then return true end
    end
    return false
end

-- Returns (true, nil) if all keys exist in t; (false, missingKey) otherwise.
function Validation.hasKeys(t: {[string]: unknown}, keys: {string}): (boolean, string?)
    for _, key in ipairs(keys) do
        if t[key] == nil then
            return false, key
        end
    end
    return true, nil
end

-- Hard assert that the caller is the server. Used at service entry points.
function Validation.assertServer()
    assert(RunService:IsServer(), "[Validation] Server-only function called from client")
end

-- Returns (true, nil) if amount > 0; (false, reason) otherwise.
function Validation.positiveAmount(amount: number): (boolean, string?)
    if amount <= 0 then
        return false, string.format("amount must be positive, got %g", amount)
    end
    return true, nil
end

return Validation
