-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/server/sv_parkingmeters.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

local MODULE = 'parkingmeter'

lib.callback.register('loro_pettydevice:parkingmeter:isLooted', function(source, list)
    return Loot.Looted(source, MODULE, list)
end)

lib.callback.register('loro_pettydevice:parkingmeter:begin', function(source, coords)
    return Loot.Begin(source, MODULE, coords)
end)

lib.callback.register('loro_pettydevice:parkingmeter:hack', function(source, coords)
    return Loot.Resolve(source, MODULE, coords)
end)
