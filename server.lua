-- =====================================================================
--  Distortionz Weapons Market · server.lua
-- =====================================================================

local currentLocationIndex = nil
local lastRotationTime     = 0
local nextRotationAt       = 0   -- unix timestamp (seconds) of next scheduled rotation
local lastPurchaseTime     = {}  -- src -> os.time() of last purchase

local function Debug(msg)
    if Config.Debug then print(('[distortionz_weaponsmarket] %s'):format(msg)) end
end

-- ─── Notify helper ──────────────────────────────────────────────────

local function Notify(src, message, notifyType, duration, title)
    notifyType = notifyType or 'primary'
    duration   = tonumber(duration) or Config.Notify.defaultLength
    title      = title or Config.Notify.title
    if notifyType == 'inform' then notifyType = 'info' end

    if GetResourceState(Config.Notify.resource) == 'started' then
        TriggerClientEvent('distortionz_notify:client:notify', src, {
            title = title, message = message, type = notifyType, duration = duration,
        })
        return
    end
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = title, description = message, type = notifyType, duration = duration,
        })
    end
end

-- ─── Location rotation ──────────────────────────────────────────────

local function PickRandomLocation(excludeIdx)
    local pool = Config.Dealer.locations
    if #pool == 0 then return nil, nil end
    if #pool == 1 then return 1, pool[1] end

    local idx
    repeat
        idx = math.random(1, #pool)
    until idx ~= excludeIdx
    return idx, pool[idx]
end

local function RotateDealer()
    local newIdx, newLoc = PickRandomLocation(currentLocationIndex)
    if not newLoc then return end

    currentLocationIndex = newIdx
    lastRotationTime     = os.time()
    nextRotationAt       = lastRotationTime + (Config.Dealer.rotationMinutes * 60)

    Debug(('Dealer rotated to: %s (next rotation at unix %d)'):format(newLoc.label, nextRotationAt))

    -- Broadcast new location to all players
    TriggerClientEvent('distortionz_weaponsmarket:client:setDealerLocation', -1, newLoc)

    -- Sync the widget countdown for everyone (multiply by 1000 for JS Date.now())
    TriggerClientEvent('distortionz_weaponsmarket:client:syncWidget', -1, {
        nextRotateAt = nextRotationAt * 1000,
    })
end

-- Initial rotation on resource start
CreateThread(function()
    Wait(2000)
    RotateDealer()

    -- Ongoing rotation loop
    while true do
        Wait(Config.Dealer.rotationMinutes * 60 * 1000)
        RotateDealer()
    end
end)

-- ─── Rumor broadcaster ──────────────────────────────────────────────
-- Periodically drops a "word on the street" hint about the current
-- dealer's rough area to all players.

local function PickRumor(areaName)
    local templates = Config.Rumors.templates or {}
    if #templates == 0 then return nil end
    local pick = templates[math.random(1, #templates)]
    return (pick:gsub('{area}', areaName))
end

local function BroadcastRumor()
    if not Config.Rumors or not Config.Rumors.enabled then return end
    if not currentLocationIndex then return end

    local loc = Config.Dealer.locations[currentLocationIndex]
    if not loc or not loc.area then return end

    local message = PickRumor(loc.area)
    if not message then return end

    Debug(('Rumor broadcast: %s'):format(message))

    -- Send to every connected player
    local players = GetPlayers()
    for _, src in ipairs(players) do
        local pid = tonumber(src)
        if pid then
            if Config.Rumors.showInChat then
                TriggerClientEvent('chat:addMessage', pid, {
                    color = { 200, 200, 40 },
                    multiline = true,
                    args = { 'Rumor', message },
                })
            end
            if Config.Rumors.showAsNotify then
                Notify(pid, message, 'info', 7000, 'Whispers')
            end
        end
    end
end

CreateThread(function()
    -- Wait a bit so the first rotation has happened
    Wait(60000)

    while true do
        Wait((Config.Rumors.intervalMinutes or 30) * 60 * 1000)
        BroadcastRumor()
    end
end)

-- A client just joined / requested their first location
RegisterNetEvent('distortionz_weaponsmarket:server:requestLocation', function()
    local src = source
    if not currentLocationIndex then return end
    local loc = Config.Dealer.locations[currentLocationIndex]
    if loc then
        TriggerClientEvent('distortionz_weaponsmarket:client:setDealerLocation', src, loc)
    end

    -- Sync widget countdown for the joining player
    if nextRotationAt > 0 then
        TriggerClientEvent('distortionz_weaponsmarket:client:syncWidget', src, {
            nextRotateAt = nextRotationAt * 1000,
        })
    end
end)

-- ─── Reputation helpers ─────────────────────────────────────────────

local function GetPurchases(src)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return 0 end

    local meta = Player.PlayerData.metadata or {}
    return tonumber(meta.distortionz_weaponsmarket_rep) or 0
end

local function SetPurchases(src, count)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    if not Config.Misc.persistReputation then return end

    Player.Functions.SetMetaData('distortionz_weaponsmarket_rep', count)
end

local function GetTierForPurchases(purchases)
    local tierIdx = 1
    for i, t in ipairs(Config.Reputation.tiers) do
        if purchases >= t.purchasesRequired then
            tierIdx = i
        end
    end
    return tierIdx, Config.Reputation.tiers[tierIdx]
end

local function GetNextTierThreshold(currentTierIdx)
    local nextTier = Config.Reputation.tiers[currentTierIdx + 1]
    return nextTier and nextTier.purchasesRequired or nil
end

-- ─── Shop data callback ─────────────────────────────────────────────

lib.callback.register('distortionz_weaponsmarket:server:getShopData', function(source)
    local src = source
    if not currentLocationIndex then
        return { success = false, reason = 'The dealer is restocking.' }
    end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then
        return { success = false, reason = 'Player not found.' }
    end

    -- Validate distance from dealer
    local dealerLoc = Config.Dealer.locations[currentLocationIndex]
    local pCoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(pCoords - vec3(dealerLoc.coords.x, dealerLoc.coords.y, dealerLoc.coords.z))
    if dist > 4.0 then
        return { success = false, reason = 'Get closer to the dealer.' }
    end

    local purchases = GetPurchases(src)
    local tierIdx, tier = GetTierForPurchases(purchases)

    return {
        success      = true,
        catalog      = Config.Catalog,
        ammo         = Config.Ammo,
        repTier      = tierIdx,
        repTierName  = tier.name,
        repTierLabel = tier.label,
        repTierColor = tier.color,
        purchases    = purchases,
        nextTierAt   = GetNextTierThreshold(tierIdx),
    }
end)

-- ─── Purchase callback ──────────────────────────────────────────────

local function FindCatalogItem(itemName, kind)
    local pool = (kind == 'ammo') and Config.Ammo or Config.Catalog
    for _, entry in ipairs(pool) do
        if entry.item == itemName then return entry end
    end
    return nil
end

local function MaybePoliceAlert(src, tierIdx, productLabel)
    local chance = Config.Police.alertChance[tierIdx] or 0
    if chance <= 0 then return false end
    if math.random(1, 100) > chance then return false end

    local pCoords = GetEntityCoords(GetPlayerPed(src))
    TriggerClientEvent('distortionz_weaponsmarket:client:policeAlert', -1, {
        coords = { x = pCoords.x, y = pCoords.y, z = pCoords.z },
        reason = ('Possible illegal weapons sale (%s)'):format(productLabel or 'unknown'),
    })
    return true
end

lib.callback.register('distortionz_weaponsmarket:server:purchase', function(source, payload)
    local src = source

    if not payload or not payload.item then
        return { success = false, reason = 'Invalid request.' }
    end

    -- Cooldown check
    local now = os.time()
    if lastPurchaseTime[src] and (now - lastPurchaseTime[src]) < Config.Misc.purchaseCooldownSec then
        return { success = false, reason = 'Slow down. The dealer needs a moment.' }
    end

    -- Distance check
    if not currentLocationIndex then
        return { success = false, reason = 'The dealer is gone.' }
    end
    local dealerLoc = Config.Dealer.locations[currentLocationIndex]
    local pCoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(pCoords - vec3(dealerLoc.coords.x, dealerLoc.coords.y, dealerLoc.coords.z))
    if dist > 4.0 then
        return { success = false, reason = 'You\'re too far from the dealer.' }
    end

    local entry = FindCatalogItem(payload.item, payload.kind)
    if not entry then
        return { success = false, reason = 'That item is not for sale.' }
    end

    -- Reputation tier check
    local purchases = GetPurchases(src)
    local tierIdx = GetTierForPurchases(purchases)
    if tierIdx < entry.tier then
        return { success = false, reason = 'The dealer doesn\'t trust you with that yet.' }
    end

    -- Payment check
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then
        return { success = false, reason = 'Player not found.' }
    end

    local payAccount = entry.payAccount or 'cash'
    local price = entry.price

    -- Resolve "dirty" account (qbx_core stores it as 'cash'? depends on server)
    local accountToCharge = payAccount
    if payAccount == 'dirty' then
        -- Common qbx_core / qb-core pattern: dirty money is sometimes in 'cash'
        -- meta or a separate account. Try metadata first.
        local meta = Player.PlayerData.metadata or {}
        if type(meta.dirtymoney) == 'number' and meta.dirtymoney >= price then
            Player.Functions.SetMetaData('dirtymoney', meta.dirtymoney - price)
        else
            return { success = false, reason = 'Not enough dirty money.' }
        end
    else
        local money = Player.Functions.GetMoney(accountToCharge)
        if not money or money < price then
            return { success = false, reason = ('Not enough %s.'):format(accountToCharge) }
        end
        if not Player.Functions.RemoveMoney(accountToCharge, price, 'distortionz_weaponsmarket_purchase') then
            return { success = false, reason = ('Payment failed (%s).'):format(accountToCharge) }
        end
    end

    -- Grant the item via ox_inventory
    local count = (payload.kind == 'ammo') and (entry.count or 50) or 1
    local ok, response = pcall(function()
        return exports.ox_inventory:AddItem(src, entry.item, count)
    end)
    if not ok or response == 'inventory_full' then
        -- Refund if we can't deliver
        if payAccount == 'dirty' then
            local meta = Player.PlayerData.metadata or {}
            Player.Functions.SetMetaData('dirtymoney', (meta.dirtymoney or 0) + price)
        else
            Player.Functions.AddMoney(accountToCharge, price, 'distortionz_weaponsmarket_refund')
        end
        return { success = false, reason = 'Inventory full. Refunded.' }
    end

    -- Increment reputation
    local newPurchases = purchases + 1
    SetPurchases(src, newPurchases)
    lastPurchaseTime[src] = now

    -- Check tier-up
    local newTierIdx, newTier = GetTierForPurchases(newPurchases)
    local tierUp = newTierIdx > tierIdx

    -- Police alert
    local alerted = MaybePoliceAlert(src, entry.tier, entry.label)

    Debug(('Purchase: src=%s item=%s tier=%d price=%d account=%s purchases=%d tierUp=%s alerted=%s')
        :format(src, entry.item, entry.tier, price, payAccount, newPurchases, tostring(tierUp), tostring(alerted)))

    if tierUp and Config.Reputation.notifyOnTierUp then
        Notify(src, ('Dealer trust earned. New rank: %s'):format(newTier.label), 'success', 7000)
    end

    if alerted then
        Notify(src, 'You feel like you were watched...', 'warning', 5000)
    end

    return {
        success     = true,
        item        = entry.item,
        label       = entry.label,
        purchases   = newPurchases,
        repTier     = newTierIdx,
        repTierLabel = newTier.label,
        repTierColor = newTier.color,
        nextTierAt  = GetNextTierThreshold(newTierIdx),
        tierUp      = tierUp,
    }
end)

-- ─── Admin debug ────────────────────────────────────────────────────

lib.addCommand('findarms_admin', {
    help = 'Print current black market dealer location to console (admin)',
    restricted = 'group.admin',
}, function(source)
    if not currentLocationIndex then
        Notify(source, 'No dealer location active.', 'info', 5000)
        return
    end
    local loc = Config.Dealer.locations[currentLocationIndex]
    Notify(source, ('Dealer is at: %s'):format(loc.label), 'info', 8000)
end)

lib.addCommand('rotatearms_admin', {
    help = 'Force the black market dealer to rotate to a new location (admin)',
    restricted = 'group.admin',
}, function(source)
    RotateDealer()
    Notify(source, 'Dealer rotated.', 'success', 5000)
end)

lib.addCommand('rumor_admin', {
    help = 'Force broadcast a black market dealer rumor right now (admin)',
    restricted = 'group.admin',
}, function(source)
    BroadcastRumor()
    Notify(source, 'Rumor broadcast triggered.', 'success', 4000)
end)

-- ─── Cleanup ────────────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    lastPurchaseTime[src] = nil
end)
