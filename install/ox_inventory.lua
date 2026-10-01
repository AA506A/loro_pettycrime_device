-- LoRo Scripts · loro_pettycrime_device · https://discord.gg/sfHsAwZvDG
-- ox_inventory (Qbox / QBCore / ESX)
-- Images: copy install/images/*.png to ox_inventory/web/images/

----------------------------------------------------------------
-- ox_inventory/data/weapons.lua  ->  inside Weapons = { ... }
----------------------------------------------------------------
['WEAPON_HACKINGDEVICE'] = {
    label = 'Hacking Device',
    weight = 500,
},

----------------------------------------------------------------
-- ox_inventory/data/items.lua  ->  inside return { ... }
-- Skip any item your server already has.
----------------------------------------------------------------
['ecola'] = {
    label = 'eCola',
    weight = 330,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ecola_can`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500 },
},
['sprunk'] = {
    label = 'Sprunk',
    weight = 330,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500 },
},
['water'] = {
    label = 'Water',
    weight = 500,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2500 },
},
['sandwich'] = {
    label = 'Sandwich',
    weight = 250,
    client = { status = { hunger = 200000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
},
['burger'] = {
    label = 'Burger',
    weight = 300,
    client = { status = { hunger = 200000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
},
['pqs_candy'] = {
    label = 'Candy',
    weight = 100,
    client = { status = { hunger = 100000 }, anim = 'eating', usetime = 2000 },
},
['scrapmetal'] = {
    label = 'Scrap Metal',
    weight = 80,
},
['circuit_board'] = {
    label = 'Circuit Board',
    weight = 200,
    description = 'Broken but salvageable electronics.',
},
['sticky_note'] = {
    label = 'Sticky Note',
    weight = 10,
    stack = false,
    description = 'A folded sticky note. Something is scribbled inside.',
},
