-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/client/modules/parkingmeter.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

ParkingMeterModule = HackModule:new({
    id = 'parkingmeter',
    config = {},
})

---@return { text: string, type: string }[]
function ParkingMeterModule:getHackLines()
    return {
        { text = '[*] Establishing connection...',                 type = 'info' },
        { text = '[*] Scanning network interfaces...',             type = 'info' },
        { text = '[+] Open port detected: 8080',                   type = 'success' },
        { text = '[*] Initiating handshake protocol...',           type = 'info' },
        { text = '[!] Firewall detected — analysing...',           type = 'warning' },
        { text = '[*] Deploying bypass module...',                 type = 'info' },
        { text = '[+] Firewall bypassed successfully',             type = 'success' },
        { text = '[*] Injecting payload into parking meter MCU...', type = 'info' },
        { text = '[*] Intercepting transaction bus...',            type = 'info' },
        { text = '[+] Payment validation disabled',                type = 'success' },
        { text = '[*] Dumping inventory manifest...',              type = 'info' },
        { text = '[*] Spoofing dispense signal...',                type = 'info' },
    }
end

---@param targets table[] entries carrying a `coords`
---@return table lootedByIndex
function ParkingMeterModule:checkLooted(targets)
    if #targets == 0 then return {} end

    local coords = {}

    for index, target in ipairs(targets) do
        coords[index] = target.coords
    end

    return lib.callback.await('loro_pettydevice:parkingmeter:isLooted', false, coords)
        or {}
end

---@param entity integer
---@return table { allowed: boolean, reason?: string }
function ParkingMeterModule:beginHack(entity)
    local response = lib.callback.await('loro_pettydevice:parkingmeter:begin', false,
        self:targetCoords(entity))

    return response or { allowed = false, reason = 'no_response' }
end

---@param entity integer
---@return table { success: boolean, reason?: string }
function ParkingMeterModule:resolveHack(entity)
    local response = lib.callback.await('loro_pettydevice:parkingmeter:hack', false,
        self:targetCoords(entity))

    return response or { success = false, reason = 'no_response' }
end

function ParkingMeterModule:onHackSuccess() end
function ParkingMeterModule:onHackFailed() end

PettyCrimeModules = PettyCrimeModules or {}
PettyCrimeModules.parkingmeter = ParkingMeterModule
