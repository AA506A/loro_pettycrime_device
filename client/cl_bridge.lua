-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/client/cl_bridge.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

Bridge = {}

function Bridge.Notify(message, kind)
    lib.notify({
        description = message,
        type = kind or 'inform',
    })
end

---@param key string
---@param label string
function Bridge.DisplayMetadata(key, label)
    CreateThread(function()
        local timeout = GetGameTimer() + 30000

        while GetResourceState('ox_inventory') ~= 'started' and GetGameTimer() < timeout do
            Wait(500)
        end

        if GetResourceState('ox_inventory') ~= 'started' then return end

        pcall(function()
            exports.ox_inventory:displayMetadata(key, label)
        end)
    end)
end

local function targetSystem()
    local wanted = tostring(Config.Target or 'auto')

    if wanted ~= 'auto' then return wanted end

    if GetResourceState('ox_target') == 'started' then return 'ox_target' end
    if GetResourceState('qb-target') == 'started' then return 'qb-target' end

    return 'textui'
end

---@type table<string, { entity: integer, option: table }>
local textTargets = {}
local textLoopRunning = false

local function textLoop()
    if textLoopRunning then return end

    textLoopRunning = true

    CreateThread(function()
        local shown = nil

        while next(textTargets) do
            local origin = GetEntityCoords(cache.ped)
            local closest, closestDistance = nil, math.huge

            for name, entry in pairs(textTargets) do
                if DoesEntityExist(entry.entity) then
                    local distance = #(origin - GetEntityCoords(entry.entity))

                    if distance <= (entry.option.distance or 1.6) and distance < closestDistance then
                        closest, closestDistance = name, distance
                    end
                end
            end

            if closest ~= shown then
                if shown then lib.hideTextUI() end
                if closest then
                    lib.showTextUI(('[E] %s'):format(textTargets[closest].option.label))
                end
                shown = closest
            end

            if closest and IsControlJustReleased(0, 38) then
                textTargets[closest].option.onSelect()
            end

            Wait(closest and 0 or 250)
        end

        if shown then lib.hideTextUI() end

        textLoopRunning = false
    end)
end

---@param entity integer
---@param option { name: string, label: string, icon?: string, distance?: number, onSelect: function }
function Bridge.AddEntityTarget(entity, option)
    local system = targetSystem()

    if system == 'ox_target' then
        exports.ox_target:addLocalEntity(entity, { option })
    elseif system == 'qb-target' then
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                {
                    icon = option.icon,
                    label = option.label,
                    action = option.onSelect,
                },
            },
            distance = option.distance,
        })
    else
        textTargets[option.name] = { entity = entity, option = option }
        textLoop()
    end
end

---@param entity integer
---@param option { name: string, label: string }
function Bridge.RemoveEntityTarget(entity, option)
    local system = targetSystem()

    if system == 'ox_target' then
        exports.ox_target:removeLocalEntity(entity, option.name)
    elseif system == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(entity, option.label)
    else
        textTargets[option.name] = nil
    end
end
