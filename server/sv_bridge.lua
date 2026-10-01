-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/server/sv_bridge.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

Bridge = {}

local function started(resource)
    return resource and GetResourceState(resource) == 'started'
end

local FRAMEWORKS = {
    { id = 'qbx', resource = 'qbx_core' },
    { id = 'qb', resource = 'qb-core' },
    { id = 'esx', resource = 'es_extended' },
}

local framework = nil
local QBCore, ESX = nil, nil

---@return string? 'qbx' | 'qb' | 'esx'
function Bridge.Framework()
    if framework then return framework end

    local wanted = tostring(Config.Framework or 'auto'):lower()

    for _, entry in ipairs(FRAMEWORKS) do
        if (wanted == 'auto' or wanted == entry.id) and started(entry.resource) then
            framework = entry.id
            break
        end
    end

    if framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif framework == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
    end

    return framework
end

---@param source integer
function Bridge.GetPlayer(source)
    local fw = Bridge.Framework()

    if fw == 'qbx' then
        return exports.qbx_core:GetPlayer(source)
    elseif fw == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif fw == 'esx' then
        return ESX.GetPlayerFromId(source)
    end
end

---@param source integer
---@return string?
function Bridge.GetIdentifier(source)
    local ok, player = pcall(Bridge.GetPlayer, source)

    if not ok or not player then return nil end

    if Bridge.Framework() == 'esx' then
        return player.identifier
    end

    return player.PlayerData and player.PlayerData.citizenid
end

---@param source integer
---@param amount integer
---@param reason string?
function Bridge.AddCash(source, amount, reason)
    if amount <= 0 then return false end

    local player = Bridge.GetPlayer(source)

    if not player then return false end

    local ok = pcall(function()
        if Bridge.Framework() == 'esx' then
            player.addAccountMoney('money', amount, reason)
        else
            player.Functions.AddMoney('cash', amount, reason)
        end
    end)

    return ok
end

local function fromQb(item)
    if not item then return nil end

    return {
        name = item.name,
        slot = item.slot,
        count = item.amount or item.count or 1,
        metadata = item.info or item.metadata or {},
    }
end

local qbFamily = {
    addItem = function(source, name, count, metadata)
        local player = Bridge.GetPlayer(source)
        if not player then return false end

        local added = player.Functions.AddItem(name, count, false, metadata)

        if added and QBCore and QBCore.Shared.Items[name] then
            TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[name], 'add', count)
        end

        return added
    end,

    removeItem = function(source, name, count, slot)
        local player = Bridge.GetPlayer(source)
        return player and player.Functions.RemoveItem(name, count, slot) or false
    end,

    getSlot = function(source, slot)
        local player = Bridge.GetPlayer(source)
        return player and fromQb(player.PlayerData.items[slot])
    end,

    findItem = function(source, name)
        local player = Bridge.GetPlayer(source)
        return player and fromQb(player.Functions.GetItemByName(name))
    end,

    setMetadata = function(source, slot, metadata)
        local player = Bridge.GetPlayer(source)
        if not player then return false end

        local items = player.PlayerData.items
        if not items[slot] then return false end

        items[slot].info = metadata
        player.Functions.SetPlayerData('items', items)

        return true
    end,
}

local INVENTORIES = {
    ox_inventory = {
        addItem = function(source, name, count, metadata)
            return exports.ox_inventory:AddItem(source, name, count, metadata)
        end,
        removeItem = function(source, name, count, slot)
            return exports.ox_inventory:RemoveItem(source, name, count, nil, slot)
        end,
        getSlot = function(source, slot)
            return exports.ox_inventory:GetSlot(source, slot)
        end,
        findItem = function(source, name)
            return exports.ox_inventory:GetSlotWithItem(source, name)
        end,
        setMetadata = function(source, slot, metadata)
            exports.ox_inventory:SetMetadata(source, slot, metadata)
            return true
        end,
        currentWeapon = function(source)
            return exports.ox_inventory:GetCurrentWeapon(source)
        end,
    },

    ['qs-inventory'] = {
        addItem = function(source, name, count, metadata)
            return exports['qs-inventory']:AddItem(source, name, count, nil, metadata)
        end,
        removeItem = function(source, name, count, slot)
            return exports['qs-inventory']:RemoveItem(source, name, count, slot)
        end,
        getSlot = function(source, slot)
            local inventory = exports['qs-inventory']:GetInventory(source) or {}
            return fromQb(inventory[slot])
        end,
        findItem = function(source, name)
            for _, item in pairs(exports['qs-inventory']:GetInventory(source) or {}) do
                if item.name == name then return fromQb(item) end
            end
        end,
        setMetadata = function(source, slot, metadata)
            exports['qs-inventory']:SetItemMetadata(source, slot, metadata)
            return true
        end,
    },

    ['codem-inventory'] = {
        addItem = function(source, name, count, metadata)
            return exports['codem-inventory']:AddItem(source, name, count, nil, metadata)
        end,
        removeItem = function(source, name, count, slot)
            return exports['codem-inventory']:RemoveItem(source, name, count, slot)
        end,
        getSlot = function(source, slot)
            return fromQb(exports['codem-inventory']:GetItemBySlot(source, slot))
        end,
        findItem = function(source, name)
            return fromQb(exports['codem-inventory']:GetItemByName(source, name))
        end,
        setMetadata = function(source, slot, metadata)
            exports['codem-inventory']:SetItemMetadata(source, slot, metadata)
            return true
        end,
    },

    ['tgiann-inventory'] = {
        addItem = function(source, name, count, metadata)
            return exports['tgiann-inventory']:AddItem(source, name, count, nil, metadata)
        end,
        removeItem = function(source, name, count, slot)
            return exports['tgiann-inventory']:RemoveItem(source, name, count, slot)
        end,
        getSlot = function(source, slot)
            return fromQb(exports['tgiann-inventory']:GetItemBySlot(source, slot))
        end,
        findItem = function(source, name)
            return fromQb(exports['tgiann-inventory']:GetItemByName(source, name))
        end,
        setMetadata = function(source, slot, metadata)
            local item = exports['tgiann-inventory']:GetItemBySlot(source, slot)
            if not item then return false end
            exports['tgiann-inventory']:UpdateItemMetadata(source, item.name, slot, metadata)
            return true
        end,
    },

    ['qb-inventory'] = qbFamily,
    ['ps-inventory'] = qbFamily,
    ['lj-inventory'] = qbFamily,

    framework = {
        addItem = function(source, name, count, metadata)
            if Bridge.Framework() ~= 'esx' then
                return qbFamily.addItem(source, name, count, metadata)
            end

            local player = Bridge.GetPlayer(source)
            if not player then return false end

            if player.canCarryItem and not player.canCarryItem(name, count) then
                return false
            end

            player.addInventoryItem(name, count)
            return true
        end,
        removeItem = function(source, name, count, slot)
            if Bridge.Framework() ~= 'esx' then
                return qbFamily.removeItem(source, name, count, slot)
            end

            local player = Bridge.GetPlayer(source)
            if not player then return false end

            if player.hasWeapon and player.hasWeapon(name) then
                player.removeWeapon(name)
                return true
            end

            player.removeInventoryItem(name, count)
            return true
        end,
        getSlot = function(source, slot)
            if Bridge.Framework() ~= 'esx' then
                return qbFamily.getSlot(source, slot)
            end
        end,
        findItem = function(source, name)
            if Bridge.Framework() ~= 'esx' then
                return qbFamily.findItem(source, name)
            end

            local player = Bridge.GetPlayer(source)
            local item = player and player.getInventoryItem(name)

            if item and (item.count or 0) > 0 then
                return { name = item.name, count = item.count, metadata = {} }
            end

            if player and player.hasWeapon and player.hasWeapon(name) then
                return { name = name, count = 1, metadata = {} }
            end
        end,
        setMetadata = function(source, slot, metadata)
            if Bridge.Framework() ~= 'esx' then
                return qbFamily.setMetadata(source, slot, metadata)
            end

            return false
        end,
    },
}

local INVENTORY_ORDER = {
    'ox_inventory', 'qs-inventory', 'codem-inventory', 'tgiann-inventory',
    'ps-inventory', 'lj-inventory', 'qb-inventory',
}

local inventoryName = nil

---@return string name
---@return table adapter
function Bridge.Inventory()
    if inventoryName then return inventoryName, INVENTORIES[inventoryName] end

    local wanted = tostring(Config.Inventory or 'auto')

    if wanted ~= 'auto' and INVENTORIES[wanted] then
        inventoryName = wanted
    else
        for _, name in ipairs(INVENTORY_ORDER) do
            if started(name) then
                inventoryName = name
                break
            end
        end
    end

    if not inventoryName then
        return 'framework', INVENTORIES.framework
    end

    return inventoryName, INVENTORIES[inventoryName]
end

local function call(method, ...)
    local name, adapter = Bridge.Inventory()
    local fn = adapter and adapter[method]

    if not fn then return nil end

    local ok, result = pcall(fn, ...)

    if not ok then
        lib.print.warn(('[pettydevice] %s.%s failed: %s'):format(name, method, result))
        return nil
    end

    return result
end

---@return boolean
function Bridge.AddItem(source, name, count, metadata)
    return call('addItem', source, name, count, metadata) and true or false
end

---@return boolean
function Bridge.RemoveItem(source, name, count, slot)
    return call('removeItem', source, name, count, slot) and true or false
end

---@return boolean stored false when the inventory has nowhere to keep it
function Bridge.SetMetadata(source, slot, metadata)
    if not slot then return false end

    return call('setMetadata', source, slot, metadata) == true
end

---@param source integer
---@param names string[] weapon item names this resource cares about
---@return table? slot { name, slot, count, metadata }
function Bridge.GetCurrentWeapon(source, names)
    local _, adapter = Bridge.Inventory()

    if adapter and adapter.currentWeapon then
        local ok, weapon = pcall(adapter.currentWeapon, source)
        return ok and weapon or nil
    end

    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return nil end

    local held = GetSelectedPedWeapon(ped)

    for _, name in ipairs(names) do
        if joaat(name) == held then
            return call('findItem', source, name)
                or call('findItem', source, name:lower())
        end
    end
end
