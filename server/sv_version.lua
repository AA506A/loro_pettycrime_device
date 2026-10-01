-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/server/sv_version.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

-- Startup banner.

CreateThread(function()
    local resource = GetCurrentResourceName()
    local version = GetResourceMetadata(resource, 'version', 0) or '?'

    print(('^1[LoRo Scripts]^7 %s ^2v%s^7 started.'):format(resource, version))
    print('^1[LoRo Scripts]^7 (c) LoRo Scripts - redistribution or modification without permission is prohibited.')
    print('^1[LoRo Scripts]^7 Support: ^5https://discord.gg/sfHsAwZvDG^7')
end)
