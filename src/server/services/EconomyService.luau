--!strict
-- Currency transactions and shop purchases. All economy state is server-authoritative.
-- Full shop implementation deferred to Milestone 4.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local Logger     = require(ReplicatedStorage.Shared.utils.Logger)
local Validation = require(ReplicatedStorage.Shared.utils.Validation)

local log = Logger.new("EconomyService")

local EconomyService = Knit.CreateService({
    Name = "EconomyService",
    Client = {
        BalanceUpdated = Knit.CreateSignal(), -- (coins: number, premiumCoins: number)
    },
})

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function getSession(player: Player)
    return (Knit.GetService("SaveService") :: any):getSession(player)
end

local function pushBalance(player: Player, data: any)
    EconomyService.Client.BalanceUpdated:Fire(
        player,
        data.currency.coins,
        data.currency.premiumCoins
    )
end

-- ── Public API ────────────────────────────────────────────────────────────────

function EconomyService:getCoins(player: Player): number
    local data = getSession(player)
    return if data then data.currency.coins else 0
end

function EconomyService:getPremiumCoins(player: Player): number
    local data = getSession(player)
    return if data then data.currency.premiumCoins else 0
end

-- Award coins server-side (quest rewards, machine output sales, etc.).
function EconomyService:awardCoins(player: Player, amount: number): (boolean, string?)
    local ok, err = Validation.positiveAmount(amount)
    if not ok then return false, err end
    local data = getSession(player)
    if not data then return false, "session not loaded" end
    data.currency.coins += amount
    local SaveService = Knit.GetService("SaveService")
    SaveService:updateSession(player, { currency = data.currency })
    pushBalance(player, data)
    log:debug("Awarded %d coins to %s", amount, player.Name)
    return true, nil
end

-- Deduct coins; fails if balance is insufficient.
function EconomyService:deductCoins(player: Player, amount: number): (boolean, string?)
    local ok, err = Validation.positiveAmount(amount)
    if not ok then return false, err end
    local data = getSession(player)
    if not data then return false, "session not loaded" end
    if data.currency.coins < amount then
        return false, string.format("insufficient coins (%d < %d)", data.currency.coins, amount)
    end
    data.currency.coins -= amount
    local SaveService = Knit.GetService("SaveService")
    SaveService:updateSession(player, { currency = data.currency })
    pushBalance(player, data)
    log:debug("Deducted %d coins from %s", amount, player.Name)
    return true, nil
end

-- Force-set coins to an exact amount (dev/admin use only).
function EconomyService:setCoins(player: Player, amount: number)
    local data = getSession(player)
    if not data then return end
    data.currency.coins = math.max(0, amount)
    local SaveService = Knit.GetService("SaveService")
    SaveService:updateSession(player, { currency = data.currency })
    pushBalance(player, data)
end

-- Award premium coins (granted by MarketplaceService or admin tools).
function EconomyService:awardPremiumCoins(player: Player, amount: number): (boolean, string?)
    local ok, err = Validation.positiveAmount(amount)
    if not ok then return false, err end
    local data = getSession(player)
    if not data then return false, "session not loaded" end
    data.currency.premiumCoins += amount
    local SaveService = Knit.GetService("SaveService")
    SaveService:updateSession(player, { currency = data.currency })
    pushBalance(player, data)
    return true, nil
end

function EconomyService:KnitInit() end

function EconomyService:KnitStart()
    log:info("EconomyService started")
end

return EconomyService
