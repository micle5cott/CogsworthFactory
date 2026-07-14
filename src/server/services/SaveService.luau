--!strict
-- Player data persistence orchestrator.
-- Owns the in-memory session cache and the full load/save/autosave lifecycle.
-- All DataStore I/O is delegated to DataService.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger     = require(ReplicatedStorage.Shared.utils.Logger)
local DataModel  = require(ReplicatedStorage.Shared.DataModel)
local GameConfig = require(ReplicatedStorage.Shared.config.GameConfig)
local Network    = require(ReplicatedStorage.Shared.Network)

local log = Logger.new("SaveService")

local SaveService = Knit.CreateService({
    Name   = "SaveService",
    Client = {},
})

-- userId (as string) → PlayerData
local _sessions: {[string]: DataModel.PlayerData} = {}

local function key(player: Player): string
    return "player_" .. tostring(player.UserId)
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Load data on join. Migrates old saves, applies defaults for new fields.
-- Fires PlayerDataLoaded to the owning client when done.
function SaveService:loadPlayer(player: Player): DataModel.PlayerData
    local DataService = Knit.GetService("DataService")
    local raw, err = DataService:load(key(player))

    if err then
        log:warn("Load error for %s — defaulting: %s", player.Name, err)
        raw = nil
    end

    local data: {[string]: any}
    local migrated = false

    if raw == nil then
        log:info("New player: %s (%d)", player.Name, player.UserId)
        data = DataModel.default() :: {[string]: any}
    else
        data, migrated = DataModel.migrate(raw)
        data = DataModel.applyDefaults(data)
        if migrated then
            log:info("Migrated save for %s to schema v%d", player.Name, DataModel.SCHEMA_VERSION)
        end
    end

    _sessions[key(player)] = data :: DataModel.PlayerData
    Network.getEvent(Network.Events.PlayerDataLoaded):FireClient(player, data)
    return data :: DataModel.PlayerData
end

-- Persist the in-memory session to DataStore. Returns true on success.
function SaveService:savePlayer(player: Player): boolean
    local session = _sessions[key(player)]
    if not session then
        log:warn("savePlayer: no session for %s", player.Name)
        return false
    end
    local DataService = Knit.GetService("DataService")
    local ok, err = DataService:save(key(player), session :: {[string]: any})
    if ok then
        log:debug("Saved %s (%d)", player.Name, player.UserId)
    else
        log:error("Save failed for %s: %s", player.Name, err or "unknown")
    end
    return ok
end

-- Returns the in-memory session (no DataStore hit).
function SaveService:getSession(player: Player): DataModel.PlayerData?
    return _sessions[key(player)]
end

-- Merge a patch into the session and notify the client.
-- patch should be a table of top-level PlayerData keys → new values.
function SaveService:updateSession(player: Player, patch: {[string]: any})
    local session = _sessions[key(player)]
    if not session then
        log:error("updateSession: no session for %s", player.Name)
        return
    end
    for k, v in pairs(patch) do
        (session :: {[string]: any})[k] = v
    end
    Network.getEvent(Network.Events.PlayerDataUpdated):FireClient(player, patch)
end

-- Remove session from memory after saving (called on PlayerRemoving).
function SaveService:evictSession(player: Player)
    _sessions[key(player)] = nil
end

-- Permanently delete all stored data (GDPR / post-ascension wipe).
function SaveService:wipePlayer(player: Player): boolean
    local DataService = Knit.GetService("DataService")
    local ok, err = DataService:remove(key(player))
    if not ok then
        log:error("Wipe failed for %s: %s", player.Name, err or "unknown")
    end
    return ok
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function SaveService:KnitInit() end

function SaveService:KnitStart()
    -- Autosave loop
    task.spawn(function()
        while true do
            task.wait(GameConfig.AUTOSAVE_INTERVAL_SECONDS)
            local saved, failed = 0, 0
            for _, player in ipairs(Players:GetPlayers()) do
                if self:savePlayer(player) then saved += 1 else failed += 1 end
            end
            if saved + failed > 0 then
                log:info("Autosave: %d saved, %d failed", saved, failed)
            end
        end
    end)

    -- Save on player disconnect
    Players.PlayerRemoving:Connect(function(player)
        self:savePlayer(player)
        self:evictSession(player)
    end)

    -- Save all on server shutdown
    game:BindToClose(function()
        log:info("Server closing — flushing all sessions")
        for _, player in ipairs(Players:GetPlayers()) do
            self:savePlayer(player)
        end
    end)

    log:info("SaveService started (autosave every %ds)", GameConfig.AUTOSAVE_INTERVAL_SECONDS)
end

return SaveService
