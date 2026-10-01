-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/server/sv_drops.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

Drops = {}

---@type table<integer, table>
local pending = {}

---@param source integer
---@param message string
---@param kind string?
local function notify(source, message, kind)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Petty Crime',
        description = message,
        type = kind or 'info',
    })
end

---@param netId integer
local function despawn(netId)
    pending[netId] = nil

    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    TriggerClientEvent('loro_pettydevice:drops:remove', -1, netId)
end

---@param source integer
---@param module string
---@param coords vector3|table
---@param cash integer
---@param items table[]
---@return boolean dropped
function Drops.Spawn(source, module, coords, cash, items)
    local function trace(message)
        if Config.Debug then
            print('[pettydevice drop] ' .. message)
        end
    end

    local config = Config.Modules[module] and Config.Modules[module].drop

    if not config or not config.enabled then
        trace(('no drop config for %s'):format(module))
        return false
    end

    local at

    local ped = GetPlayerPed(source)

    if ped and ped ~= 0 then
        local pedAt = GetEntityCoords(ped)

        local forward = tonumber(config.forward) or 0.8
        local heading = math.rad(GetEntityHeading(ped))

        at = vec3(
            pedAt.x - math.sin(heading) * forward,
            pedAt.y + math.cos(heading) * forward,
            pedAt.z)
    elseif coords then
        at = vec3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    end

    if not at then
        trace('no position: player has no ped and no machine coords were sent')
        return false
    end

    at = at + (config.offset or vec3(0.0, 0.0, 0.0))

    local model = joaat(config.model)
    local entity = CreateObjectNoOffset(model, at.x, at.y, at.z, true, true, false)

    if not entity or entity == 0 then
        trace(('CreateObjectNoOffset refused %s (%s) -- is the model streamed?')
            :format(config.model, model))
        return false
    end

    local timeout = GetGameTimer() + 2000

    while not DoesEntityExist(entity) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not DoesEntityExist(entity) then
        trace(('entity %s never came into existence'):format(entity))
        return false
    end

    local netId = NetworkGetNetworkIdFromEntity(entity)

    if not netId or netId == 0 then
        trace(('entity %s has no network id'):format(entity))
        DeleteEntity(entity)
        return false
    end

    trace(('bag %s (net %s) at %.2f, %.2f, %.2f holding $%d and %d items')
        :format(entity, netId, at.x, at.y, at.z, cash, #items))

    FreezeEntityPosition(entity, true)

    pending[netId] = {
        module = module,
        cash = cash,
        items = items,
        owner = source,

        citizenid = Drops.CitizenId(source),

        coords = at,
        expiresAt = os.time() + (config.timeoutSeconds or 300),
    }

    local advert = {
        label = config.label,
        icon = config.icon,
        distance = config.distance,
    }

    TriggerClientEvent('loro_pettydevice:drops:add', -1, netId, advert)

    if source and source ~= 0 then
        advert.settle = true
        TriggerClientEvent('loro_pettydevice:drops:add', source, netId, advert)
    end

    SetTimeout((config.timeoutSeconds or 300) * 1000, function()
        despawn(netId)
    end)

    return true
end

---@param source integer
---@return string?
function Drops.CitizenId(source)
    return Bridge.GetIdentifier(source)
end

RegisterNetEvent('loro_pettydevice:drops:settled', function(netId, x, y, z)
    local source = source

    netId = tonumber(netId)

    if not netId then return end

    local drop = pending[netId]

    if not drop or drop.owner ~= source then return end

    x, y, z = tonumber(x), tonumber(y), tonumber(z)

    if not x or not y or not z then return end

    local settled = vec3(x, y, z)

    if #(settled - drop.coords) > 2.0 then
        if Config.Debug then
            print(('[pettydevice drop] bag %s reported %.2f, %.2f, %.2f -- too far from where it was placed, ignored')
                :format(netId, x, y, z))
        end

        return
    end

    drop.coords = settled
end)

RegisterNetEvent('loro_pettydevice:drops:collect', function(netId)
    local source = source

    netId = tonumber(netId)

    if not netId then return end

    local drop = pending[netId]

    if not drop then return end

    local config = Config.Modules[drop.module] and Config.Modules[drop.module].drop or {}

    if config.ownerOnly ~= false then
        local citizenid = Drops.CitizenId(source)

        local sameCharacter = citizenid and drop.citizenid and citizenid == drop.citizenid
        local sameSession = drop.owner == source

        if not sameCharacter and not sameSession then
            return notify(source, 'That is not yours.', 'error')
        end
    end

    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return end

    if #(GetEntityCoords(ped) - drop.coords) > (config.distance or 1.6) + 2.0 then
        return notify(source, 'You are too far from it.', 'error')
    end

    pending[netId] = nil

    if drop.cash > 0 then
        Bridge.AddCash(source, drop.cash, ('pettydevice-%s'):format(drop.module))
    end

    for _, entry in ipairs(drop.items or {}) do
        Bridge.AddItem(source, entry.name, entry.count, entry.metadata)
    end

    despawn(netId)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for netId in pairs(pending) do
        local entity = NetworkGetEntityFromNetworkId(netId)

        if entity and entity ~= 0 and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    pending = {}
end)
