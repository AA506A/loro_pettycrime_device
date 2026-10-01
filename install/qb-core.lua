-- LoRo Scripts · loro_pettycrime_device · https://discord.gg/sfHsAwZvDG
-- QBCore inventories: qb-inventory / ps-inventory / lj-inventory / qs-inventory
-- (codem-inventory and tgiann-inventory use the same item format)
-- Images: copy install/images/*.png to your inventory's images folder
--   qb-inventory/html/images/   ps-inventory/html/images/   lj-inventory/html/images/
--   qs-inventory/html/images/

----------------------------------------------------------------
-- qb-core/shared/items.lua  ->  inside QBShared.Items = { ... }
-- Skip any item your server already has.
----------------------------------------------------------------
weapon_hackingdevice = { name = 'weapon_hackingdevice', label = 'Hacking Device', weight = 500, type = 'weapon', ammotype = nil, image = 'WEAPON_HACKINGDEVICE.png', unique = true, useable = false, description = 'A device for cracking parking meters and vending machines.' },
ecola                = { name = 'ecola', label = 'eCola', weight = 330, type = 'item', image = 'ecola.png', unique = false, useable = true, shouldClose = true, description = 'A can of eCola.' },
sprunk               = { name = 'sprunk', label = 'Sprunk', weight = 330, type = 'item', image = 'sprunk.png', unique = false, useable = true, shouldClose = true, description = 'A can of Sprunk.' },
water                = { name = 'water', label = 'Water', weight = 500, type = 'item', image = 'water.png', unique = false, useable = true, shouldClose = true, description = 'A bottle of water.' },
sandwich             = { name = 'sandwich', label = 'Sandwich', weight = 250, type = 'item', image = 'sandwich.png', unique = false, useable = true, shouldClose = true, description = 'A sandwich.' },
burger               = { name = 'burger', label = 'Burger', weight = 300, type = 'item', image = 'burger.png', unique = false, useable = true, shouldClose = true, description = 'A burger.' },
pqs_candy            = { name = 'pqs_candy', label = 'Candy', weight = 100, type = 'item', image = 'pqs_candy.png', unique = false, useable = true, shouldClose = true, description = 'A bag of candy.' },
scrapmetal           = { name = 'scrapmetal', label = 'Scrap Metal', weight = 80, type = 'item', image = 'scrapmetal.png', unique = false, useable = false, shouldClose = false, description = 'Scrap metal.' },
circuit_board        = { name = 'circuit_board', label = 'Circuit Board', weight = 200, type = 'item', image = 'circuit_board.png', unique = false, useable = false, shouldClose = false, description = 'Broken but salvageable electronics.' },
sticky_note          = { name = 'sticky_note', label = 'Sticky Note', weight = 10, type = 'item', image = 'sticky_note.png', unique = true, useable = false, shouldClose = true, description = 'A folded sticky note. Something is scribbled inside.' },

----------------------------------------------------------------
-- qb-core/shared/weapons.lua  ->  inside QBShared.Weapons = { ... }
----------------------------------------------------------------
[`weapon_hackingdevice`] = { name = 'weapon_hackingdevice', label = 'Hacking Device', weapontype = 'Miscellaneous', ammotype = nil, damagereason = 'Hacked' },
