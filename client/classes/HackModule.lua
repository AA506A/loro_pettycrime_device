-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/client/classes/HackModule.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

HackModule = {}
HackModule.__index = HackModule

---@type table<string, table>
PettyCrimeModules = {}

local SIGNAL_LEVELS = 8

---@param options { id: string, config?: table }
---@return table
function HackModule:new(options)
    return setmetatable({
        id = options.id,
        screen = nil,

        active = false,
        booting = false,
        hacking = false,
        hackTarget = nil,

        propHashes = {},

        config = options.config or {},
    }, self)
end

function HackModule:loadProps()
    self.propHashes = {}

    for _, prop in ipairs(self.config.props or {}) do
        local hash = joaat(prop)
        self.propHashes[hash] = true

        lib.print.debug(('[%s] Registered prop: %s (hash: %d)')
            :format(self.id, prop, hash))
    end
end

---@param entity integer
---@return boolean
function HackModule:isTargetProp(entity)
    return self.propHashes[GetEntityModel(entity)] == true
end

---@param target table
---@return vector3?
function HackModule:targetCoords(target)
    if target.hackCoords then
        return target.hackCoords
    end

    if target.object and DoesEntityExist(target.object) then
        return GetEntityCoords(target.object)
    end

    return target.coords
end

function HackModule:buildScreen()
    if self.screen then return end

    local device = self.config.device or {}

    local url = ('nui://%s/web/%s/index.html'):format(cache.resource, self.id)

    local weapon = device.weapon or 'WEAPON_HACKINGDEVICE'
    local renderTarget = device.renderTarget or 'w_am_hackdevice_m32'

    lib.print.debug(('[%s] buildScreen: weapon=%s renderTarget=%s url=%s')
        :format(self.id, weapon, renderTarget, url))

    self.screen = DeviceScreen.new({
        url = url,
        weapon = weapon,
        renderTarget = renderTarget,
        duiSize = device.duiSize,
    })
end

---@return integer weaponHash
function HackModule:getWeaponHash()
    self:buildScreen()

    return self.screen.weaponHash
end

---@param message table
function HackModule:send(message)
    if self.screen then
        self.screen:sendMessage(message)
    end
end

function HackModule:activate()
    if self.active then
        lib.print.debug(('[%s] activate: already active, skipping'):format(self.id))
        return
    end

    if not next(self.propHashes) then
        lib.print.debug(('[%s] activate: no props loaded, aborting'):format(self.id))
        return
    end

    lib.print.debug(('[%s] activate: starting module'):format(self.id))

    self:buildScreen()

    self.active = true
    self.booting = true

    self.screen:activate()

    for step = 1, 10 do
        SetTimeout(200 * step, function()
            if not self.active or not self.screen then return end

            self:send({ action = 'show', mode = 'boot' })
        end)
    end

    SetTimeout(self.config.bootDuration or 7000, function()
        self.booting = false
    end)

    self:signalLoop()

    if Config.Debug then
        self:debugLoop()
    end
end

function HackModule:deactivate()
    if not self.active then return end

    self.active = false
    self.booting = false
    self.hacking = false

    self:clearDebugOutline()

    self.hackTarget = nil

    if self.screen then
        self.screen:deactivate()
        self.screen = nil
    end
end

local DEFAULT_OUTLINE_SHADER = 0
local THICK_OUTLINE_SHADER = 1

---@param entity integer
function HackModule:setDebugOutline(entity)
    if not entity or not DoesEntityExist(entity) then return end

    SetEntityDrawOutline(entity, true)
    SetEntityDrawOutlineColor(0, 255, 65, 200)
    SetEntityDrawOutlineShader(THICK_OUTLINE_SHADER)
end

local function restoreOutlineShader()
    SetEntityDrawOutlineShader(DEFAULT_OUTLINE_SHADER)
end

function HackModule:clearDebugOutline()
    local target = self.hackTarget

    if target and target.object and DoesEntityExist(target.object) then
        SetEntityDrawOutline(target.object, false)
    end

    if not self._debugEntities then
        return restoreOutlineShader()
    end

    for entity in pairs(self._debugEntities) do
        if DoesEntityExist(entity) then
            SetEntityDrawOutline(entity, false)
        end
    end

    self._debugEntities = {}

    restoreOutlineShader()
end

function HackModule:debugLoop()
    self._debugEntities = {}

    CreateThread(function()
        while self.active do
            local wanted = {}

            for _, entity in ipairs(self._debugTargets or {}) do
                wanted[entity] = true
            end

            for entity in pairs(self._debugEntities) do
                if not wanted[entity] and DoesEntityExist(entity) then
                    SetEntityDrawOutline(entity, false)
                end
            end

            for entity in pairs(wanted) do
                if not self._debugEntities[entity] and DoesEntityExist(entity) then
                    self:setDebugOutline(entity)
                end
            end

            self._debugEntities = wanted

            if not next(wanted) then
                restoreOutlineShader()
            end

            Wait(200)
        end

        for entity in pairs(self._debugEntities) do
            if DoesEntityExist(entity) then
                SetEntityDrawOutline(entity, false)
            end
        end

        self._debugEntities = {}

        restoreOutlineShader()
    end)
end

---@param distance number
---@param maxRange number
---@param floorLevel integer lowest bar a visible target may show
---@return integer
local function signalLevel(distance, maxRange, floorLevel)
    local level = math.ceil((1.0 - distance / maxRange) * SIGNAL_LEVELS)

    return math.max(floorLevel, math.min(SIGNAL_LEVELS, level))
end

---@param from vector3
---@param to vector3
---@param facing number the player's heading, already inverted
---@return number degrees 0-360
local function bearingTo(from, to, facing)
    local angle = math.deg(math.atan(to.x - from.x, to.y - from.y)) % 360

    return (angle - facing) % 360
end

---@return number
local function facingAngle()
    return (360.0 - GetEntityHeading(PlayerPedId())) % 360
end

---@param origin vector3
---@param maxRange number
---@return table? nearest
---@return number nearestDistance
---@return table[] scanned everything in range, unsorted
function HackModule:scan(origin, maxRange)
    local objects = lib.getNearbyObjects(origin, maxRange)

    local nearest
    local nearestDistance = math.huge

    for _, entry in ipairs(objects) do
        if self:isTargetProp(entry.object) then
            local distance = #(origin - entry.coords)

            if distance < nearestDistance then
                nearestDistance = distance
                nearest = { object = entry.object, coords = entry.coords }
            end
        end
    end

    return nearest, nearestDistance, objects
end

---@param origin vector3
---@param objects table[] everything the scan returned
---@param maxRange number
---@return table[] blips
---@return integer[] entities the props behind them, for debug outlines
function HackModule:buildNearbyBlips(origin, objects, maxRange)
    local facing = facingAngle()
    local found = {}

    for _, entry in ipairs(objects) do
        if self:isTargetProp(entry.object) then
            local distance = #(origin - entry.coords)

            if distance < maxRange then
                found[#found + 1] = {
                    bearing = bearingTo(origin, entry.coords, facing),
                    level = signalLevel(distance, maxRange, 1),
                    distance = math.floor(distance * 10) / 10,
                    object = entry.object,
                    coords = entry.coords,
                }
            end
        end
    end

    table.sort(found, function(a, b)
        return a.distance < b.distance
    end)

    local limit = math.min(#found, self.config.maxNearbyBlips or 10)
    local nearest = {}

    for index = 1, limit do
        nearest[index] = found[index]
    end

    local looted = self:checkLooted(nearest)

    local blips, entities = {}, {}

    for index = 1, #nearest do
        blips[index] = {
            bearing = nearest[index].bearing,
            level = nearest[index].level,
            distance = nearest[index].distance,
            looted = (looted and looted[index]) or false,
        }

        entities[index] = nearest[index].object
    end

    return blips, entities
end

function HackModule:signalLoop()
    CreateThread(function()
        while self.active do
            if not self.hacking then
                local origin = GetEntityCoords(PlayerPedId())
                local maxRange = self.config.maxScanRange or 100.0

                local nearest, distance, objects = self:scan(origin, maxRange)

                local level = 0
                local bearing = 0.0

                if nearest and distance < maxRange then
                    level = signalLevel(distance, maxRange, 0)
                    bearing = bearingTo(origin, nearest.coords, facingAngle())
                end

                local blips

                if self.config.sendNearbyToUI and nearest then
                    local entities

                    blips, entities = self:buildNearbyBlips(origin, objects, maxRange)

                    if Config.Debug then
                        self._debugTargets = entities
                    end
                end

                if not self.active or not self.screen then break end

                self:send({
                    action = 'updateSignal',
                    level = level,
                    distance = nearest and (math.floor(distance * 10) / 10) or 0,
                    bearing = bearing,
                    interval = self.config.signalInterval or 500,
                    nearbyBlips = blips,
                })

                if nearest and distance <= (self.config.hackRange or 3.0)
                    and not self.booting then
                    self:startHack(nearest)
                end

                if Config.Debug and not self.hacking then
                    self.hackTarget = nearest

                    if not self.config.sendNearbyToUI then
                        self._debugTargets = nearest and { nearest.object } or {}
                    end
                end
            end

            Wait(self.config.signalInterval or 500)
        end
    end)
end

---@param targets table[]
---@return table?
function HackModule:checkLooted(targets)
    return nil
end

---@return { text: string, type: string }[]
function HackModule:getHackLines()
    return {
        { text = '[*] Establishing connection...',       type = 'info' },
        { text = '[*] Scanning network interfaces...',   type = 'info' },
        { text = '[+] Open port detected: 8080',         type = 'success' },
        { text = '[*] Initiating handshake protocol...', type = 'info' },
        { text = '[!] Firewall detected — analysing...', type = 'warning' },
        { text = '[*] Deploying bypass module...',       type = 'info' },
        { text = '[+] Firewall bypassed successfully',   type = 'success' },
        { text = '[*] Injecting payload into target...', type = 'info' },
        { text = '[*] Intercepting data packets...',     type = 'info' },
        { text = '[+] Secure data stream established',   type = 'success' },
        { text = '[*] Downloading intercepted data...',  type = 'info' },
        { text = '[*] Decrypting contents...',           type = 'info' },
    }
end

---@return table { allowed: boolean, reason?: string }
function HackModule:beginHack()
    return { allowed = true }
end

---@return table { success: boolean, reason?: string }
function HackModule:resolveHack()
    return { success = true }
end

function HackModule:onHackSuccess() end
function HackModule:onHackFailed() end

---@param result table?
function HackModule:reportDeviceWear(result)
    if not result then return end

    if result.deviceBroke then
        Bridge.Notify('The device burned out and is now useless.', 'error')

        return
    end

    if result.usesLeft then
        Bridge.Notify(('Device hacks left: %d'):format(result.usesLeft), 'inform')
    end
end

---@param delay integer
function HackModule:releaseAfter(delay)
    CreateThread(function()
        Wait(delay)

        if not self.active then return end

        self:clearDebugOutline()

        self.hackTarget = nil
        self.hacking = false
    end)
end

---@param target table
function HackModule:startHack(target)
    if self.hacking then return end

    self.hacking = true
    self.hackTarget = target
    self._hackAborted = false

    target.hackCoords = self:targetCoords(target)

    local permission = self:beginHack(target)

    if not permission or not permission.allowed then
        self:send({
            action = 'hackResult',
            success = false,
            reason = (permission and permission.reason) or 'no_response',
        })

        self:releaseAfter(5000)

        return
    end

    local duration = self.config.hackDuration or 15000

    self:send({
        action = 'startHack',
        lines = self:getHackLines(target),
        duration = duration,
    })

    self:hackDistanceWatch(target)

    CreateThread(function()
        Wait(duration)

        if not self.active or self._hackAborted then return end

        Wait(self.config.rewardDelay or 1500)

        if not self.active or self._hackAborted then return end

        local result = self:resolveHack(target)
        local success = (result and result.success) or false

        self:send({
            action = 'hackResult',
            success = success,
            reason = result and result.reason or nil,
        })

        if success then
            self:onHackSuccess(target, result)
        else
            self:onHackFailed(target, result)
        end

        self:reportDeviceWear(result)

        self:releaseAfter(5000)
    end)
end

---@param target table
function HackModule:hackDistanceWatch(target)
    CreateThread(function()
        local failRange = self.config.hackFailRange or 5.0

        while self.active and self.hacking and not self._hackAborted do
            local origin = GetEntityCoords(PlayerPedId())

            local targetCoords = (target.object and DoesEntityExist(target.object))
                and GetEntityCoords(target.object)
                or target.coords

            local distance = #(origin - targetCoords)

            if distance > failRange then
                self._hackAborted = true

                TriggerServerEvent('loro_pettydevice:server:cancelHack', self.id)

                self:send({
                    action = 'hackResult',
                    success = false,
                    reason = 'moved_too_far',
                })

                self:onHackFailed(target)
                self:releaseAfter(5000)

                return
            end

            Wait(300)
        end
    end)
end
