-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/client/cl_drops.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

local bags = {}

local bagOptions = {}

---@param netId integer
---@param entity integer
local function settleOnGround(netId, entity)
    NetworkRequestControlOfEntity(entity)

    local timeout = GetGameTimer() + 1000

    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end

    if not NetworkHasControlOfEntity(entity) then return end

    FreezeEntityPosition(entity, false)
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)

    local at = GetEntityCoords(entity)

    TriggerServerEvent('loro_pettydevice:drops:settled', netId, at.x, at.y, at.z)
end

---@param netId integer
---@param options table
local function addBag(netId, options)
    if bags[netId] then return end

    CreateThread(function()
        local timeout = GetGameTimer() + 10000
        local entity = 0

        while entity == 0 and GetGameTimer() < timeout do
            if NetworkDoesEntityExistWithNetworkId(netId) then
                entity = NetworkGetEntityFromNetworkId(netId)
            end

            if entity == 0 then Wait(100) end
        end

        if entity == 0 or not DoesEntityExist(entity) then return end

        if bags[netId] == nil and not NetworkDoesEntityExistWithNetworkId(netId) then
            return
        end

        bags[netId] = entity

        if options.settle then
            settleOnGround(netId, entity)
        end

        bagOptions[netId] = {
            name = ('pettydevice_bag_%s'):format(netId),
            icon = options.icon or 'fa-solid fa-sack-dollar',
            label = options.label or 'Take the coins',
            distance = options.distance or 1.6,

            onSelect = function()
                TriggerServerEvent('loro_pettydevice:drops:collect', netId)
            end,
        }

        Bridge.AddEntityTarget(entity, bagOptions[netId])
    end)
end

---@param netId integer
local function removeBag(netId)
    local entity, option = bags[netId], bagOptions[netId]

    bags[netId] = nil
    bagOptions[netId] = nil

    if not entity or not option then return end

    pcall(Bridge.RemoveEntityTarget, entity, option)
end

RegisterNetEvent('loro_pettydevice:drops:add', function(netId, options)
    addBag(tonumber(netId), options or {})
end)

RegisterNetEvent('loro_pettydevice:drops:remove', function(netId)
    removeBag(tonumber(netId))
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for netId in pairs(bags) do
        removeBag(netId)
    end
end)
