-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/client/classes/DeviceScreen.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

local DEFAULT_DUI_SIZE = 512

DeviceScreen = {}
DeviceScreen.__index = DeviceScreen

---@param options { url: string, weapon: string, renderTarget: string, duiSize?: integer }
---@return table
function DeviceScreen.new(options)
    return setmetatable({
        active = false,
        dui = nil,
        scaleform = nil,

        url = options.url,
        weaponHash = joaat(options.weapon),
        renderTargetName = options.renderTarget,
        duiSize = options.duiSize or DEFAULT_DUI_SIZE,
    }, DeviceScreen)
end

---@param message table
function DeviceScreen:sendMessage(message)
    if self.dui then
        self.dui:sendMessage(message)
    end
end

function DeviceScreen:activate()
    if self.active then return end

    self.active = true

    self.dui = lib.dui:new({
        url = self.url,
        width = self.duiSize,
        height = self.duiSize,
    })

    self.scaleform = lib.scaleform:new({
        name = 'CELLPHONE_IFRUIT',

        renderTarget = {
            name = self.renderTargetName,
            model = GetWeapontypeModel(self.weaponHash),
        },
    })

    self:renderLoop()
end

function DeviceScreen:deactivate()
    if not self.active then return end

    self.active = false

    SetTextRenderId(GetDefaultScriptRendertargetRenderId())

    if self.scaleform then
        self.scaleform:dispose()
        self.scaleform = nil
    end

    if self.dui then
        self.dui:remove()
        self.dui = nil
    end
end

function DeviceScreen:renderLoop()
    CreateThread(function()
        while self.active do
            local scaleform, dui = self.scaleform, self.dui

            if scaleform and dui and scaleform.target then
                SetTextRenderId(scaleform.target)

                SetScriptGfxDrawOrder(4)
                SetScriptGfxDrawBehindPausemenu(true)

                DrawSprite(dui.dictName, dui.txtName,
                    0.5, 0.5, 1.0, 1.0, 0.0,
                    255, 255, 255, 255)

                SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            end

            Wait(0)
        end

        SetTextRenderId(GetDefaultScriptRendertargetRenderId())
    end)
end
