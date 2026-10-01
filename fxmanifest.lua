-- ============================================================
--  LoRo Scripts · loro_pettycrime_device
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'loro_pettycrime_device'
author 'LoRo Scripts | discord.gg/sfHsAwZvDG'
description 'Petty Crime Hacking Device - QBCore / Qbox / ESX'
version '2.0.0'

shared_scripts {
  '@ox_lib/init.lua',
  'shared/**/*',
}

client_scripts {
  'client/cl_bridge.lua',
  'client/classes/DeviceScreen.lua',
  'client/classes/HackModule.lua',
  'client/modules/parkingmeter.lua',
  'client/modules/vending.lua',
  'client/cl_devicewear.lua',
  'client/cl_drops.lua',
  'client/cl_hackingdevice.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/sv_bridge.lua',
  'server/sv_config.lua',
  'server/sv_drops.lua',
  'server/sv_lootmanager.lua',
  'server/sv_dispatch.lua',
  'server/sv_devicewear.lua',
  'server/sv_parkingmeters.lua',
  'server/sv_vending.lua',
  'server/sv_version.lua',
}

files {
  'web/alpinejs@3.15.11.js',
  'web/parkingmeter/*',
  'web/selector/*',
  'web/vending/*',
  'data/worldParknmeters.json',
  'data/worldVendingMachines.json',
}

-- Framework, inventory, target and dispatch scripts are detected at runtime
-- (see shared/sh_config.lua), so none of them is a hard dependency.
dependencies {
  'ox_lib',
  'oxmysql',
}
