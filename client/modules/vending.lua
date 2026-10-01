-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/client/modules/vending.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

VendingModule = HackModule:new({
    id = 'vending',
    config = {},
})

---@return { text: string, type: string }[]
function VendingModule:getHackLines()
    return {
        { text = '[*] Establishing connection...',           type = 'info' },
        { text = '[*] Scanning network interfaces...',       type = 'info' },
        { text = '[+] Open port detected: 8080',             type = 'success' },
        { text = '[*] Initiating handshake protocol...',     type = 'info' },
        { text = '[!] Firewall detected — analysing...',     type = 'warning' },
        { text = '[*] Deploying bypass module...',           type = 'info' },
        { text = '[+] Firewall bypassed successfully',       type = 'success' },
        { text = '[*] Injecting payload into vending MCU...', type = 'info' },
        { text = '[*] Intercepting transaction bus...',      type = 'info' },
        { text = '[+] Payment validation disabled',          type = 'success' },
        { text = '[*] Dumping inventory manifest...',        type = 'info' },
        { text = '[*] Spoofing dispense signal...',          type = 'info' },
    }
end

---@param targets table[] entries carrying a `coords`
---@return table lootedByIndex
function VendingModule:checkLooted(targets)
    if #targets == 0 then return {} end

    local coords = {}

    for index, target in ipairs(targets) do
        coords[index] = target.coords
    end

    return lib.callback.await('loro_pettydevice:vending:isLooted', false, coords) or {}
end

---@param entity integer
---@return table { allowed: boolean, reason?: string }
function VendingModule:beginHack(entity)
    local response = lib.callback.await('loro_pettydevice:vending:begin', false,
        self:targetCoords(entity))

    return response or { allowed = false, reason = 'no_response' }
end

---@param entity integer
---@return table { success: boolean, reason?: string }
function VendingModule:resolveHack(entity)
    local response = lib.callback.await('loro_pettydevice:vending:hack', false,
        self:targetCoords(entity))

    return response or { success = false, reason = 'no_response' }
end

function VendingModule:onHackSuccess() end
function VendingModule:onHackFailed() end

PettyCrimeModules = PettyCrimeModules or {}
PettyCrimeModules.vending = VendingModule
