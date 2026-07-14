--!strict
-- Low-level DataStore wrapper. Provides retry logic and pcall safety.
-- No other service should touch DataStoreService directly.

local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger    = require(ReplicatedStorage.Shared.utils.Logger)
local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)

local log = Logger.new("DataService")

local DataService = Knit.CreateService({
    Name   = "DataService",
    Client = {},
})

local _store: DataStore

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function withRetry<T>(label: string, fn: () -> T): (T?, string?)
    local lastErr: string?
    for attempt = 1, GameConfig.DATASTORE_MAX_RETRIES do
        local ok, result = pcall(fn)
        if ok then
            return result :: T, nil
        end
        lastErr = tostring(result)
        log:warn("DataStore %s attempt %d/%d failed: %s",
            label, attempt, GameConfig.DATASTORE_MAX_RETRIES, lastErr)
        if attempt < GameConfig.DATASTORE_MAX_RETRIES then
            task.wait(GameConfig.DATASTORE_RETRY_DELAY_SECONDS * attempt)
        end
    end
    log:error("DataStore %s exhausted retries: %s", label, lastErr or "unknown")
    return nil, lastErr
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Load raw data for key. Returns (data|nil, err|nil).
function DataService:load(key: string): ({[string]: any}?, string?)
    return withRetry("load:" .. key, function()
        return _store:GetAsync(key)
    end)
end

-- Overwrite data for key. Returns (success, err|nil).
function DataService:save(key: string, data: {[string]: any}): (boolean, string?)
    local _, err = withRetry("save:" .. key, function()
        _store:SetAsync(key, data)
    end)
    return err == nil, err
end

-- Atomic update — transformFn receives current stored value (may be nil).
function DataService:update(
    key: string,
    transformFn: (current: {[string]: any}?) -> {[string]: any}
): (boolean, string?)
    local _, err = withRetry("update:" .. key, function()
        _store:UpdateAsync(key, function(current)
            return transformFn(current)
        end)
    end)
    return err == nil, err
end

-- Remove data for key (GDPR wipe, not ascension reset).
function DataService:remove(key: string): (boolean, string?)
    local _, err = withRetry("remove:" .. key, function()
        _store:RemoveAsync(key)
    end)
    return err == nil, err
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function DataService:KnitInit()
    _store = DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)
    log:info("DataStore opened: %s", GameConfig.DATASTORE_NAME)
end

function DataService:KnitStart() end

return DataService
