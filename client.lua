-- =====================================================================
--  Distortionz Weapons Market · client.lua
-- =====================================================================

local dealerPed     = nil
local currentLoc    = nil
local nuiOpen       = false
local proximityBlip = nil   -- red circle blip when within reveal radius

-- ─── Notify wrapper ─────────────────────────────────────────────────

local function Notify(message, notifyType, duration, title)
    if not message then return end
    notifyType = notifyType or 'primary'
    duration   = tonumber(duration) or Config.Notify.defaultLength
    title      = title or Config.Notify.title

    if notifyType == 'inform' then notifyType = 'info' end

    if GetResourceState(Config.Notify.resource) == 'started' then
        exports[Config.Notify.resource]:Notify(message, notifyType, duration, title)
        return
    end

    lib.notify({
        title       = title,
        description = message,
        type        = notifyType,
        duration    = duration,
    })
end

-- ─── Dealer ped management ──────────────────────────────────────────

-- Forward declaration so DespawnDealer can call it before its definition
local HideProximityBlip

local function DespawnDealer()
    if dealerPed and DoesEntityExist(dealerPed) then
        exports.ox_target:removeLocalEntity(dealerPed, 'distortionz_weaponsmarket_dealer')
        DeletePed(dealerPed)
    end
    dealerPed = nil
    if HideProximityBlip then HideProximityBlip() end
end

local function SpawnDealerAt(location)
    DespawnDealer()
    if not location or not location.coords then return end

    currentLoc = location

    local hash = joaat(Config.Dealer.model)
    lib.requestModel(hash, 10000)

    local c = location.coords

    -- Ensure the player has streaming for this area, then resolve the
    -- true ground Z so the ped doesn't float. Try a few fallbacks.
    RequestAdditionalCollisionAtCoord(c.x, c.y, c.z)
    Wait(50)

    local groundZ = c.z
    for _, testZ in ipairs({ c.z, c.z + 2.0, c.z + 5.0, c.z + 10.0, c.z + 50.0 }) do
        local found, gz = GetGroundZFor_3dCoord(c.x, c.y, testZ, false)
        if found then groundZ = gz; break end
    end

    dealerPed = CreatePed(0, hash, c.x, c.y, groundZ, c.w, false, true)
    SetEntityInvincible(dealerPed, true)
    SetBlockingOfNonTemporaryEvents(dealerPed, true)
    PlaceObjectOnGroundProperly(dealerPed)
    FreezeEntityPosition(dealerPed, true)
    SetPedFleeAttributes(dealerPed, 0, false)
    SetPedDiesWhenInjured(dealerPed, false)

    -- v1.0.6 — Distortionz convention: flag as protected so other scripts
    -- (distortionz_robped, etc.) skip this ped for player interactions.
    Entity(dealerPed).state:set('distortionz_protected_ped', true, true)
    Entity(dealerPed).state:set('distortionz_contact_ped',   true, true)
    Entity(dealerPed).state:set('distortionz_dealer_ped',    true, true)

    if Config.Dealer.scenario then
        TaskStartScenarioInPlace(dealerPed, Config.Dealer.scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(hash)

    exports.ox_target:addLocalEntity(dealerPed, {
        {
            name     = 'distortionz_weaponsmarket_dealer',
            label    = Config.Dealer.targetLabel,
            icon     = Config.Dealer.targetIcon,
            distance = 2.0,
            onSelect = function()
                TriggerEvent('distortionz_weaponsmarket:client:openShop')
            end,
        }
    })
end

-- ─── Proximity blip management ──────────────────────────────────────

local function ShowProximityBlip()
    if proximityBlip and DoesBlipExist(proximityBlip) then return end
    if not currentLoc or not currentLoc.coords then return end

    local cfg = Config.ProximityBlip
    local c = currentLoc.coords

    proximityBlip = AddBlipForRadius(c.x, c.y, c.z, cfg.circleRadius)
    SetBlipColour(proximityBlip, cfg.color)
    SetBlipAlpha(proximityBlip, cfg.alpha)
    SetBlipHighDetail(proximityBlip, true)
end

HideProximityBlip = function()
    if proximityBlip and DoesBlipExist(proximityBlip) then
        RemoveBlip(proximityBlip)
    end
    proximityBlip = nil
end

CreateThread(function()
    while true do
        local interval = (Config.ProximityBlip and Config.ProximityBlip.checkIntervalMs) or 1000
        Wait(interval)

        if not Config.ProximityBlip or not Config.ProximityBlip.enabled then
            HideProximityBlip()
        elseif currentLoc and currentLoc.coords then
            local pCoords = GetEntityCoords(PlayerPedId())
            local dist = #(pCoords - vec3(currentLoc.coords.x, currentLoc.coords.y, currentLoc.coords.z))

            if dist <= Config.ProximityBlip.revealRadius then
                ShowProximityBlip()
            else
                HideProximityBlip()
            end
        else
            HideProximityBlip()
        end
    end
end)

-- ─── Server tells us where the dealer is currently ──────────────────

RegisterNetEvent('distortionz_weaponsmarket:client:setDealerLocation', function(location)
    SpawnDealerAt(location)
end)

-- ─── Server pushes widget countdown sync ────────────────────────────

RegisterNetEvent('distortionz_weaponsmarket:client:syncWidget', function(payload)
    if not payload or not payload.nextRotateAt then return end
    SendNUIMessage({
        action       = 'widgetSync',
        nextRotateAt = payload.nextRotateAt,
    })
end)

-- ─── NUI shop control ───────────────────────────────────────────────

local function CloseShop()
    if not nuiOpen then return end
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
end

RegisterNetEvent('distortionz_weaponsmarket:client:openShop', function()
    if nuiOpen then return end

    local data = lib.callback.await('distortionz_weaponsmarket:server:getShopData', false)
    if not data or not data.success then
        Notify(data and data.reason or 'The dealer is busy.', 'error', 5000)
        return
    end

    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = 'show',
        catalog    = data.catalog,
        ammo       = data.ammo,
        repTier    = data.repTier,
        repTierName = data.repTierName,
        repTierColor = data.repTierColor,
        repTierLabel = data.repTierLabel,
        purchases  = data.purchases,
        nextTierAt = data.nextTierAt,
    })
end)

-- ─── NUI callbacks ──────────────────────────────────────────────────

RegisterNUICallback('purchase', function(data, cb)
    local result = lib.callback.await('distortionz_weaponsmarket:server:purchase', false, {
        item = data.item,
        kind = data.kind,
    })
    cb(result or { success = false, reason = 'Unknown error' })
end)

RegisterNUICallback('close', function(_, cb)
    CloseShop()
    cb({ ok = true })
end)

-- ─── Police alert receiver ──────────────────────────────────────────

RegisterNetEvent('distortionz_weaponsmarket:client:policeAlert', function(payload)
    if not payload or not payload.coords then return end

    local PlayerData = exports.qbx_core:GetPlayerData()
    if not PlayerData or not PlayerData.job then return end

    local isCop = false
    for _, j in ipairs(Config.Police.jobNames) do
        if PlayerData.job.name == j and PlayerData.job.onduty then
            isCop = true; break
        end
    end
    if not isCop then return end

    local c = payload.coords
    if type(c) == 'table' then c = vec3(c.x or 0, c.y or 0, c.z or 0) end

    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, 110)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.1)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Suspicious Activity: ' .. (payload.reason or 'Black market'))
    EndTextCommandSetBlipName(blip)

    Notify(payload.reason or 'Suspicious activity reported', 'police', 8000, 'Dispatch')

    SetTimeout((Config.Police.alertDurationSec or 90) * 1000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

-- ─── Lifecycle ──────────────────────────────────────────────────────

CreateThread(function()
    Wait(2000)
    -- Ask the server for the current dealer location on resource start /
    -- player join. Server will reply via setDealerLocation event.
    TriggerServerEvent('distortionz_weaponsmarket:server:requestLocation')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    DespawnDealer()
    SendNUIMessage({ action = 'widgetHide' })
    if nuiOpen then CloseShop() end
end)
