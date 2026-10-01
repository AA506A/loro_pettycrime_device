-- LoRo Scripts · loro_pettycrime_device · https://discord.gg/sfHsAwZvDG
-- ESX default inventory (no ox_inventory). Run in your database.
-- ox_inventory is recommended on ESX: use install/ox_inventory.lua instead.
-- The hacking device is a weapon: /giveweapon [id] WEAPON_HACKINGDEVICE 0
-- If ESX refuses it, add WEAPON_HACKINGDEVICE to es_extended/config.weapons.lua
-- (ESX default inventory has no item images.)

INSERT IGNORE INTO `items` (`name`, `label`, `weight`) VALUES
    ('ecola', 'eCola', 1),
    ('sprunk', 'Sprunk', 1),
    ('water', 'Water', 1),
    ('sandwich', 'Sandwich', 1),
    ('burger', 'Burger', 1),
    ('pqs_candy', 'Candy', 1),
    ('scrapmetal', 'Scrap Metal', 1),
    ('circuit_board', 'Circuit Board', 1),
    ('sticky_note', 'Sticky Note', 1);
