-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/server/sv_lootmanager.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

Loot = Loot or {}

Loot.ready = false

local SCHEMA = {
    [[CREATE TABLE IF NOT EXISTS `loro_pettydevice_targets` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `module` VARCHAR(32) NOT NULL,
        `grid_x` INT NOT NULL,
        `grid_y` INT NOT NULL,
        `grid_z` INT NOT NULL,
        `looted_at` INT UNSIGNED NOT NULL,
        `looted_by` VARCHAR(64) NULL,
        `times_looted` INT UNSIGNED NOT NULL DEFAULT 1,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uniq_cell` (`module`, `grid_x`, `grid_y`, `grid_z`),
        KEY `idx_module_time` (`module`, `looted_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],

    [[CREATE TABLE IF NOT EXISTS `loro_pettydevice_hacks` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `citizenid` VARCHAR(64) NOT NULL,
        `module` VARCHAR(32) NOT NULL,
        `grid_x` INT NOT NULL,
        `grid_y` INT NOT NULL,
        `grid_z` INT NOT NULL,
        `succeeded` TINYINT(1) NOT NULL DEFAULT 0,
        `cash` INT UNSIGNED NOT NULL DEFAULT 0,
        `created_at` INT UNSIGNED NOT NULL,
        PRIMARY KEY (`id`),
        KEY `idx_citizen_time` (`citizenid`, `created_at`),
        KEY `idx_module_time` (`module`, `created_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],

    [[CREATE TABLE IF NOT EXISTS `loro_pettydevice_hack_items` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `hack_id` INT UNSIGNED NOT NULL,
        `item` VARCHAR(64) NOT NULL,
        `count` INT UNSIGNED NOT NULL DEFAULT 1,
        PRIMARY KEY (`id`),
        KEY `idx_hack` (`hack_id`),
        KEY `idx_item` (`item`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
}

---@param value any
---@return number?, number?, number?
local function coordsOf(value)
    if type(value) == 'vector3' then
        return value.x, value.y, value.z
    end

    if type(value) ~= 'table' then return end

    local x = tonumber(value.x or value[1])
    local y = tonumber(value.y or value[2])
    local z = tonumber(value.z or value[3])

    if x and y and z then return x, y, z end
end

---@param value any
---@return integer?, integer?, integer?
function Loot.Cell(value)
    local x, y, z = coordsOf(value)

    if not x then return end

    local size = Config.Server.gridSize

    return math.floor(x / size + 0.5),
           math.floor(y / size + 0.5),
           math.floor(z / size + 0.5)
end

---@param gx integer
---@param gy integer
---@param gz integer
---@return string
local function cellKey(gx, gy, gz)
    return ('%d:%d:%d'):format(gx, gy, gz)
end

---@type table<string, table<string, integer>> module -> cell key -> looted at
local lootedAt = {}

---@param module string
---@param gx integer
---@param gy integer
---@param gz integer
---@return boolean
function Loot.IsCellLooted(module, gx, gy, gz)
    local byCell = lootedAt[module]

    if not byCell then return false end

    local at = byCell[cellKey(gx, gy, gz)]

    if not at then return false end

    return (os.time() - at) < Config.Server.respawnSeconds
end

---@param module string
---@param gx integer
---@param gy integer
---@param gz integer
---@param citizenid string?
local function markLooted(module, gx, gy, gz, citizenid)
    local now = os.time()

    lootedAt[module] = lootedAt[module] or {}
    lootedAt[module][cellKey(gx, gy, gz)] = now

    MySQL.prepare([[
        INSERT INTO `loro_pettydevice_targets`
            (`module`, `grid_x`, `grid_y`, `grid_z`, `looted_at`, `looted_by`)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `looted_at` = VALUES(`looted_at`),
            `looted_by` = VALUES(`looted_by`),
            `times_looted` = `times_looted` + 1
    ]], { module, gx, gy, gz, now, citizenid })
end

---@type table<string, { source: integer, startedAt: integer, module: string }>
local locks = {}

---@type table<integer, table<string, integer>> source -> module -> ready at
local cooldowns = {}

---@type table<integer, integer> source -> last isLooted sweep, in ms
local lastSweep = {}

---@param module string
---@param gx integer
---@param gy integer
---@param gz integer
---@return string
local function lockKey(module, gx, gy, gz)
    return ('%s|%d:%d:%d'):format(module, gx, gy, gz)
end

---@param source integer
---@param module string? only this module, or all of them
local function releaseLocks(source, module)
    for key, lock in pairs(locks) do
        if lock.source == source and (not module or lock.module == module) then
            locks[key] = nil
        end
    end
end

---@param source integer
---@return boolean
local function hasOpenLock(source)
    for _, lock in pairs(locks) do
        if lock.source == source then return true end
    end

    return false
end

---@param source integer
---@return string? citizenid
local function citizenIdOf(source)
    return Bridge.GetIdentifier(source)
end

---@param source integer
---@param x number
---@param y number
---@param z number
---@return number
local function distanceFrom(source, x, y, z)
    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return math.huge end

    return #(GetEntityCoords(ped) - vector3(x, y, z))
end

---@param source integer
---@param module string
---@param list any[] coordinates, in scan order
---@return table<integer, boolean>
function Loot.Looted(source, module, list)
    local answer = {}

    if not Loot.ready or type(list) ~= 'table' then return answer end

    local now = GetGameTimer()
    local last = lastSweep[source]

    if last and (now - last) < Config.Server.lootedQueryIntervalMs then
        return answer
    end

    lastSweep[source] = now

    for index = 1, #list do
        local gx, gy, gz = Loot.Cell(list[index])

        answer[index] = gx ~= nil and Loot.IsCellLooted(module, gx, gy, gz) or false
    end

    return answer
end

---@param source integer
---@param module string
---@param coords any
---@return table { allowed: boolean, reason?: string }
function Loot.Begin(source, module, coords)
    if not Loot.ready then
        return { allowed = false, reason = 'not_ready' }
    end

    if not Config.Modules[module] then
        return { allowed = false, reason = 'unknown_module' }
    end

    local citizenid = citizenIdOf(source)

    if not citizenid then
        return { allowed = false, reason = 'no_character' }
    end

    local gx, gy, gz = Loot.Cell(coords)

    if not gx then
        return { allowed = false, reason = 'bad_target' }
    end

    local x, y, z = coordsOf(coords)

    local range = (Config.Modules[module].hackFailRange or 5.0)
        + Config.Server.rangeTolerance

    if distanceFrom(source, x, y, z) > range then
        return { allowed = false, reason = 'too_far' }
    end

    if hasOpenLock(source) then
        return { allowed = false, reason = 'already_hacking' }
    end

    local readyAt = cooldowns[source] and cooldowns[source][module]

    if readyAt and os.time() < readyAt then
        return { allowed = false, reason = 'cooldown' }
    end

    if Loot.IsCellLooted(module, gx, gy, gz) then
        return { allowed = false, reason = 'already_looted' }
    end

    local key = lockKey(module, gx, gy, gz)
    local held = locks[key]

    local expiry = ((Config.Modules[module].hackDuration or 15000) / 1000) + 30

    if held and (os.time() - held.startedAt) < expiry and held.source ~= source then
        return { allowed = false, reason = 'already_hacking' }
    end

    if not DeviceWear.HasUse(source) then
        return { allowed = false, reason = 'device_dead' }
    end

    locks[key] = { source = source, startedAt = os.time(), module = module }

    Dispatch.Report(source, module)

    return { allowed = true }
end

---@param source integer
---@param module string
---@param coords any
---@return table { success: boolean, reason?: string, usesLeft?: integer, deviceBroke?: boolean }
function Loot.Resolve(source, module, coords)
    if not Loot.ready then
        return { success = false, reason = 'not_ready' }
    end

    local moduleConfig = Config.Modules[module]

    if not moduleConfig then
        return { success = false, reason = 'unknown_module' }
    end

    local gx, gy, gz = Loot.Cell(coords)

    if not gx then
        return { success = false, reason = 'bad_target' }
    end

    local key = lockKey(module, gx, gy, gz)
    local lock = locks[key]

    if not lock or lock.source ~= source then
        return { success = false, reason = 'not_started' }
    end

    local elapsed = (os.time() - lock.startedAt) * 1000
    local required = (moduleConfig.hackDuration or 15000)
        * Config.Server.minDurationFactor

    if elapsed < required then
        locks[key] = nil

        lib.print.warn(
            ('[pettydevice] %s resolved a %s hack after %d ms of a required %d ms')
                :format(GetPlayerName(source) or source, module, elapsed, required))

        return { success = false, reason = 'too_fast' }
    end

    local x, y, z = coordsOf(coords)

    local range = (moduleConfig.hackFailRange or 5.0) + Config.Server.rangeTolerance

    if distanceFrom(source, x, y, z) > range then
        locks[key] = nil

        return { success = false, reason = 'too_far' }
    end

    locks[key] = nil

    if Loot.IsCellLooted(module, gx, gy, gz) then
        return { success = false, reason = 'already_looted' }
    end

    local citizenid = citizenIdOf(source)

    if not citizenid then
        return { success = false, reason = 'no_character' }
    end

    markLooted(module, gx, gy, gz, citizenid)

    if type(Config.Server.OnHackComplete) == 'function' then
        local ok, err = pcall(Config.Server.OnHackComplete, source, module)

        if not ok then
            lib.print.warn(('[pettydevice] OnHackComplete failed: %s'):format(err))
        end
    end

    cooldowns[source] = cooldowns[source] or {}
    cooldowns[source][module] = os.time() + Config.Server.playerCooldownSeconds

    local wear = DeviceWear.Spend(source)
    local cash, items = Loot.Roll(module)

    if cash > 0 or #items > 0 then
        local dropConfig = Config.Modules[module] and Config.Modules[module].drop

        if dropConfig and dropConfig.enabled
            and Drops.Spawn(source, module, coords, cash, items) then
            Loot.Record(citizenid, module, gx, gy, gz, true, cash, items)

            return {
                success = true,
                dropped = true,
                usesLeft = wear.usesLeft,
                deviceBroke = wear.broke,
            }
        end
    end

    if cash > 0 then
        Bridge.AddCash(source, cash, ('pettydevice-%s'):format(module))
    end

    local granted = {}

    for _, entry in ipairs(items) do
        if Bridge.AddItem(source, entry.name, entry.count, entry.metadata) then
            granted[#granted + 1] = entry
        else
            lib.print.warn(('[pettydevice] could not grant %dx %s')
                :format(entry.count, entry.name))
        end
    end

    Loot.Record(citizenid, module, gx, gy, gz, cash > 0 or #granted > 0, cash, granted)

    if cash == 0 and #granted == 0 then
        return {
            success = false,
            reason = 'no_loot',
            usesLeft = wear.usesLeft,
            deviceBroke = wear.broke,
        }
    end

    return {
        success = true,
        usesLeft = wear.usesLeft,
        deviceBroke = wear.broke,
    }
end

---@param source integer
---@param module string?
function Loot.Cancel(source, module)
    releaseLocks(source, module)
end

---@param spec string?
---@return table? metadata
local function resolveMetadata(spec)
    if type(spec) ~= 'string' then return nil end

    local resource, exportName = spec:match('^([^.]+)%.(.+)$')

    if not resource or not exportName then return nil end
    if GetResourceState(resource) ~= 'started' then return nil end

    local ok, metadata = pcall(function()
        return exports[resource][exportName](nil)
    end)

    if not ok or type(metadata) ~= 'table' then return nil end

    return metadata
end

---@param module string
---@return integer cash
---@return { name: string, count: integer, metadata: table? }[] items
function Loot.Roll(module)
    local loot = Config.Server.Loot[module]

    if not loot then return 0, {} end

    local cash = 0

    if loot.cash and math.random() < loot.cash.chance then
        cash = math.random(loot.cash.min, loot.cash.max)
    end

    local items = {}
    local limit = loot.maxItemLines or 99

    for _, entry in ipairs(loot.items or {}) do
        if #items >= limit then break end

        if math.random() < entry.chance then
            items[#items + 1] = {
                name = entry.name,
                count = math.random(entry.min or 1, entry.max or 1),
            }
        end
    end

    for _, entry in ipairs(loot.rare or {}) do
        local percent = tonumber(entry.chancePercent) or 0

        if percent > 0 and math.random() < percent / 100 then
            items[#items + 1] = {
                name = entry.name,
                count = math.random(entry.min or 1, entry.max or 1),
                metadata = resolveMetadata(entry.metadataFrom),
            }
        end
    end

    return cash, items
end

---@param citizenid string
---@param module string
---@param gx integer
---@param gy integer
---@param gz integer
---@param succeeded boolean
---@param cash integer
---@param items { name: string, count: integer }[]
function Loot.Record(citizenid, module, gx, gy, gz, succeeded, cash, items)
    local hackId = MySQL.insert.await([[
        INSERT INTO `loro_pettydevice_hacks`
            (`citizenid`, `module`, `grid_x`, `grid_y`, `grid_z`,
             `succeeded`, `cash`, `created_at`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], { citizenid, module, gx, gy, gz, succeeded and 1 or 0, cash, os.time() })

    if not hackId or #items == 0 then return end

    local rows = {}

    for index = 1, #items do
        rows[index] = { hackId, items[index].name, items[index].count }
    end

    MySQL.prepare([[
        INSERT INTO `loro_pettydevice_hack_items` (`hack_id`, `item`, `count`)
        VALUES (?, ?, ?)
    ]], rows)
end

AddEventHandler('playerDropped', function()
    local source = source

    releaseLocks(source)

    cooldowns[source] = nil
    lastSweep[source] = nil
end)

RegisterNetEvent('loro_pettydevice:server:cancelHack', function(module)
    Loot.Cancel(source, type(module) == 'string' and module or nil)
end)

CreateThread(function()
    for index = 1, #SCHEMA do
        MySQL.query.await(SCHEMA[index])
    end

    local cutoff = os.time() - Config.Server.respawnSeconds

    for _, row in ipairs(MySQL.query.await([[
        SELECT `module`, `grid_x`, `grid_y`, `grid_z`, `looted_at`
        FROM `loro_pettydevice_targets`
        WHERE `looted_at` > ?
    ]], { cutoff }) or {}) do
        lootedAt[row.module] = lootedAt[row.module] or {}
        lootedAt[row.module][cellKey(row.grid_x, row.grid_y, row.grid_z)] = row.looted_at
    end

    Loot.ready = true

end)

CreateThread(function()
    while true do
        Wait(600000)

        local cutoff = os.time() - Config.Server.respawnSeconds

        for module, byCell in pairs(lootedAt) do
            for key, at in pairs(byCell) do
                if at < cutoff then
                    byCell[key] = nil
                end
            end

            if not next(byCell) then
                lootedAt[module] = nil
            end
        end
    end
end)
