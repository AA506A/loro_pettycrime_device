-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/server/sv_dispatch.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

Dispatch = Dispatch or {}

local SYSTEMS = {
    ['ps-dispatch'] = function(source, alert, jobs, coords)
        TriggerEvent('ps-dispatch:server:notify', {
            message = alert.title,
            codeName = alert.type,
            code = alert.code or '10-90',
            icon = 'fas fa-mask',
            priority = alert.priority == 'high' and 1 or 2,
            coords = coords,
            information = alert.message,
            jobs = jobs,
            alert = {
                radius = alert.blip and alert.blip.radius or 0,
                sprite = alert.blip and alert.blip.sprite or 1,
                color = alert.blip and alert.blip.colour or 1,
                scale = 1.0,
                length = alert.blip and alert.blip.time or 2,
                flash = false,
            },
        })
    end,

    ['cd_dispatch'] = function(source, alert, jobs, coords)
        TriggerClientEvent('cd_dispatch:AddNotification', -1, {
            job_table = jobs,
            coords = coords,
            title = alert.title,
            message = alert.message,
            flash = 0,
            unique_id = tostring(math.random(0000000, 9999999)),
            sound = 1,
            blip = {
                sprite = alert.blip and alert.blip.sprite or 1,
                scale = 1.0,
                colour = alert.blip and alert.blip.colour or 1,
                flashes = false,
                text = alert.title,
                time = alert.blip and alert.blip.time or 5,
                radius = alert.blip and alert.blip.radius or 0,
            },
        })
    end,

    ['qs-dispatch'] = function(source, alert, jobs, coords)
        TriggerEvent('qs-dispatch:server:CreateDispatchCall', {
            job = jobs,
            callLocation = coords,
            callCode = { code = alert.code or '10-90', snippet = alert.title },
            message = alert.message,
            flashes = false,
            blip = {
                sprite = alert.blip and alert.blip.sprite or 1,
                scale = 1.0,
                colour = alert.blip and alert.blip.colour or 1,
                flashes = false,
                text = alert.title,
                time = (alert.blip and alert.blip.time or 5) * 60000,
            },
        })
    end,

    ['rcore_dispatch'] = function(source, alert, jobs, coords)
        TriggerEvent('rcore_dispatch:server:sendAlert', {
            code = alert.code or '10-90',
            default_priority = alert.priority == 'high' and 'high' or 'medium',
            coords = coords,
            job = jobs,
            text = alert.message,
            type = 'alerts',
            blip_time = alert.blip and alert.blip.time or 5,
            blip = {
                sprite = alert.blip and alert.blip.sprite or 1,
                colour = alert.blip and alert.blip.colour or 1,
                scale = 1.0,
                text = alert.title,
                flashes = false,
                radius = alert.blip and alert.blip.radius or 0,
            },
        })
    end,

    ['core_dispatch'] = function(source, alert, jobs, coords)
        for _, job in ipairs(jobs) do
            exports['core_dispatch']:addCall(alert.code or '10-90', alert.message,
                { { icon = 'fa-mask', info = alert.title } },
                { coords.x, coords.y, coords.z }, job, 5000,
                alert.blip and alert.blip.sprite or 1,
                alert.blip and alert.blip.colour or 1)
        end
    end,

    custom = function(source, alert, jobs, coords)
        local custom = Config.Dispatch.custom

        if type(custom) == 'function' then
            custom(source, alert, jobs, coords)
        end
    end,
}

local AUTO_ORDER = { 'ps-dispatch', 'cd_dispatch', 'qs-dispatch', 'rcore_dispatch', 'core_dispatch' }

---@return function?
local function resolveSystem()
    local wanted = tostring(Config.Dispatch.system or 'auto')

    if wanted == 'none' then return nil end

    if wanted == 'custom' then return SYSTEMS.custom end

    if wanted ~= 'auto' then
        return GetResourceState(wanted) == 'started' and SYSTEMS[wanted] or nil
    end

    for _, name in ipairs(AUTO_ORDER) do
        if GetResourceState(name) == 'started' then
            return SYSTEMS[name]
        end
    end
end

---@param source integer
---@param module string
function Dispatch.Report(source, module)
    local settings = Config.Dispatch

    if not settings or not settings.enabled then return end

    local send = resolveSystem()

    if not send then return end

    local alert = settings.modules and settings.modules[module]

    if not alert then return end

    if math.random(100) > (alert.chance or 100) then return end

    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)

    SetTimeout(alert.delay or 5000, function()
        local ok, err = pcall(send, source, alert, settings.jobs or { 'police' },
            vector3(coords.x, coords.y, coords.z))

        if not ok then
            lib.print.warn(('[pettydevice] dispatch failed: %s'):format(err))
        end
    end)
end
