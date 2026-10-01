# loro_pettycrime_device

**LoRo Scripts** · Discord: https://discord.gg/sfHsAwZvDG

جهاز تهكير لعدادات المواقف ومكائن البيع. يدعم Qbox و QBCore و ESX.
Hacking device for parking meters and vending machines. Qbox / QBCore / ESX.

---

## المتطلبات · Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- Framework: `qbx_core` / `qb-core` / `es_extended`

## يدعم تلقائياً · Auto-detected

| | |
|---|---|
| Framework | qbx_core, qb-core, es_extended |
| Inventory | ox_inventory, qs-inventory, codem-inventory, tgiann-inventory, ps-inventory, lj-inventory, qb-inventory, ESX default |
| Target | ox_target, qb-target, أو "اضغط E" بدون سكربت target · built-in "press E" |
| Dispatch | ps-dispatch, cd_dispatch, qs-dispatch, rcore_dispatch, core_dispatch, custom |

تقدر تحدد أي واحد من `shared/sh_config.lua` أو تخليه `'auto'`.
You can force any of them in `shared/sh_config.lua` or leave it on `'auto'`.

---

## التركيب · Install

1. حط المجلد `loro_pettycrime_device` في resources.
   Put `loro_pettycrime_device` in your resources folder.
2. أضف الايتمات للانفنتوري (تحت).
   Add the items to your inventory (below).
3. في `server.cfg` بعد ox_lib و oxmysql والفريم ورك والانفنتوري:
   In `server.cfg`, after ox_lib, oxmysql, your framework and inventory:
   ```
   ensure loro_pettycrime_device
   ```
4. جداول الداتابيس تنسوى تلقائياً. · Database tables are created automatically.

---

## إضافة الايتمات · Adding the items

صور الايتمات كلها في `install/images/`.
All item images are in `install/images/`.

| Item | Image |
|---|---|
| `WEAPON_HACKINGDEVICE` (weapon) | `WEAPON_HACKINGDEVICE.png` |
| `ecola` | `ecola.png` |
| `sprunk` | `sprunk.png` |
| `water` | `water.png` |
| `sandwich` | `sandwich.png` |
| `burger` | `burger.png` |
| `pqs_candy` | `pqs_candy.png` |
| `scrapmetal` | `scrapmetal.png` |
| `circuit_board` | `circuit_board.png` |
| `sticky_note` | `sticky_note.png` |

> إذا عندك الايتم من قبل لا تضيفه مرة ثانية. وإذا اسمه مختلف عندك (مثلاً `water_bottle`) غيّر الاسم في `server/sv_config.lua` بدل ما تضيف ايتم جديد.
>
> Skip items you already have. If yours has a different name (e.g. `water_bottle`), change the name in `server/sv_config.lua` instead.

### ox_inventory (Qbox / QBCore / ESX)

1. انسخ الصور من `install/images/` إلى `ox_inventory/web/images/`
   Copy `install/images/*.png` to `ox_inventory/web/images/`
2. افتح `install/ox_inventory.lua`:
   - السلاح `WEAPON_HACKINGDEVICE` يروح في `ox_inventory/data/weapons.lua` داخل `Weapons = { }`
     The weapon goes in `ox_inventory/data/weapons.lua` inside `Weapons = { }`
   - باقي الايتمات في `ox_inventory/data/items.lua`
     The rest go in `ox_inventory/data/items.lua`
3. ريستارت للانفنتوري. · Restart the inventory.

### qb-inventory / ps-inventory / lj-inventory / qs-inventory (QBCore)

1. انسخ الصور إلى مجلد صور الانفنتوري:
   Copy the images to your inventory's image folder:
   - `qb-inventory/html/images/`
   - `ps-inventory/html/images/`
   - `lj-inventory/html/images/`
   - `qs-inventory/html/images/`
2. افتح `install/qb-core.lua`:
   - الايتمات في `qb-core/shared/items.lua` · Items go in `qb-core/shared/items.lua`
   - سطر السلاح الأخير في `qb-core/shared/weapons.lua` · The last (weapon) line goes in `qb-core/shared/weapons.lua`
3. ريستارت للسيرفر. · Restart the server.

### codem-inventory / tgiann-inventory

نفس صيغة QBCore في `install/qb-core.lua`. حط الايتمات في ملف الايتمات حق الانفنتوري، والصور في مجلد الصور حقه.
Same format as `install/qb-core.lua`. Put the items in that inventory's items file and the images in its image folder.

### ESX (بدون ox_inventory · without ox_inventory)

1. شغّل `install/esx.sql` في الداتابيس. · Run `install/esx.sql` on your database.
2. الجهاز سلاح: `/giveweapon [id] WEAPON_HACKINGDEVICE 0`
   The device is a weapon: `/giveweapon [id] WEAPON_HACKINGDEVICE 0`
3. ننصح بـ ox_inventory مع ESX عشان الصور وعداد الاستخدامات في التولتيب.
   ox_inventory is recommended on ESX (images + uses-left tooltip).

---

## الإعدادات · Config

- `shared/sh_config.lua` - الفريم ورك، الانفنتوري، الديسباتش، مدة التهكير، عدد استخدامات الجهاز.
  Framework, inventory, dispatch, hack timings, device charges.
- `server/sv_config.lua` - الغنائم، الكول داون، و `OnHackComplete` لربط XP أو سمعة خاصة فيك.
  Loot tables, cooldowns, and `OnHackComplete` to hook your own XP / reputation.

## الحقوق · License

© 2026 LoRo Scripts. يُمنع إعادة النشر أو البيع أو التعديل بدون إذن. شوف [LICENSE.md](LICENSE.md).
Redistribution, resale or modification without permission is prohibited. See [LICENSE.md](LICENSE.md).
