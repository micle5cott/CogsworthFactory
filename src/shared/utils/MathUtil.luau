--!strict
-- Generic math helpers used across services and simulation code.

local MathUtil = {}

function MathUtil.clamp(value: number, min: number, max: number): number
    return math.max(min, math.min(max, value))
end

function MathUtil.lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

function MathUtil.round(n: number): number
    return math.floor(n + 0.5)
end

-- Round to N decimal places.
function MathUtil.roundTo(n: number, decimals: number): number
    local factor = 10 ^ decimals
    return math.floor(n * factor + 0.5) / factor
end

-- Returns true with probability p (0–1).
function MathUtil.chance(p: number): boolean
    return math.random() < p
end

-- Re-map a value from [fromMin, fromMax] to [toMin, toMax].
function MathUtil.remap(
    value: number,
    fromMin: number, fromMax: number,
    toMin: number,   toMax: number
): number
    return toMin + (value - fromMin) / (fromMax - fromMin) * (toMax - toMin)
end

-- Sum all values in a number array.
function MathUtil.sum(t: {number}): number
    local total = 0
    for _, v in ipairs(t) do total += v end
    return total
end

-- Weighted random pick. weights table must match items table length.
function MathUtil.weightedRandom<T>(items: {T}, weights: {number}): T
    local total = MathUtil.sum(weights)
    local r = math.random() * total
    local cumulative = 0
    for i, w in ipairs(weights) do
        cumulative += w
        if r <= cumulative then
            return items[i]
        end
    end
    return items[#items]
end

return MathUtil
