-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/client/cl_devicewear.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

CreateThread(function()
    local wear = Config.DeviceWear

    if not wear or wear.enabled == false then return end

    Bridge.DisplayMetadata(
        wear.metadataKey or 'hackUses',
        wear.tooltipLabel or 'Hacks Left')
end)
