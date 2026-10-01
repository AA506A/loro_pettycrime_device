-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/shared/sh_config.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

Config = {}

Config.Debug = false -- debug prints + green outline on scanned props

-- 'auto' | 'qbx' | 'qb' | 'esx'
Config.Framework = 'auto'

-- 'auto' | 'ox_inventory' | 'qs-inventory' | 'codem-inventory' | 'tgiann-inventory'
-- | 'ps-inventory' | 'lj-inventory' | 'qb-inventory' | 'framework' (ESX default inventory)
Config.Inventory = 'auto'

-- Coin bag interaction: 'auto' | 'ox_target' | 'qb-target' | 'textui' (press E)
Config.Target = 'auto'

-- Police alerts
Config.Dispatch = {
    enabled = true,
    jobs = { 'police' },

    -- 'auto' | 'ps-dispatch' | 'cd_dispatch' | 'qs-dispatch' | 'rcore_dispatch'
    -- | 'core_dispatch' | 'custom' | 'none'
    system = 'auto',

    -- Only used when system = 'custom' (server side)
    -- custom = function(source, alert, jobs, coords) end,
    custom = nil,

    modules = {
        parkingmeter = {
            chance = 100, -- % chance to alert
            delay = 5000, -- ms after the hack starts
            type = 'parkingmeter_tamper',
            title = 'Parking Meter Tampering',
            message = 'A witness reports someone working on a parking meter.',
            priority = 'medium',

            blip = {
                sprite = 419,
                colour = 5,
                time = 5,
                radius = 80.0,
            },
        },

        vending = {
            chance = 100,
            delay = 8000,
            type = 'vending_tamper',
            title = 'Vending Machine Tampering',
            message = 'A witness reports someone tampering with a vending machine.',
            priority = 'medium',

            blip = {
                sprite = 402,
                colour = 5,
                time = 5,
                radius = 100.0,
            },
        },
    },
}

-- Each hack uses one charge of the device. At 0 the device breaks.
Config.DeviceWear = {
    enabled = true,
    metadataKey = 'hackUses',
    tooltipLabel = 'Hacks Left',

    uses = {
        WEAPON_HACKINGDEVICE = 20, -- charges on a new device
    },
}

Config.Modules = {
    vending = {
        label = 'VND HCKS v4.9', -- name on the device screen

        device = {
            weapon = 'WEAPON_HACKINGDEVICE',
            renderTarget = 'w_am_hackdevice_m32',
        },

        maxScanRange = 30.0, -- scan radius
        hackRange = 3.0,     -- distance to start the hack
        hackFailRange = 5.0, -- walking further than this cancels the hack
        hackDuration = 60000, -- ms

        props = {
            'prop_vend_coffe_01',
            'prop_vend_fags_01',
            'prop_vend_fridge01',
            'prop_vend_snak_01',
            'prop_vend_soda_01',
            'prop_vend_soda_02',
            'prop_vend_water_01',
            'prop_watercooler',
            'prop_watercooler_dark',
            'v_68_broeknvend',
        },
    },

    parkingmeter = {
        label = 'PM Cracker v7.23',

        device = {
            weapon = 'WEAPON_HACKINGDEVICE',
            renderTarget = 'w_am_hackdevice_m32',
        },

        maxScanRange = 30.0,
        hackRange = 3.0,
        hackFailRange = 5.0,
        hackDuration = 45000,

        signalInterval = 3000, -- ms between radar updates
        sendNearbyToUI = true, -- show nearby meters on the radar
        maxNearbyBlips = 3,

        props = {
            'prop_parknmeter_01',
            'prop_parknmeter_02',
        },

        -- Loot drops on the ground as a bag the player has to pick up
        drop = {
            enabled = true,
            model = 'h4_prop_h4_med_bag_01b',
            forward = 0.5, -- metres in front of the player
            offset = vec3(0.0, 0.0, 0.0),

            label = 'Take the coins',
            icon = 'fa-solid fa-sack-dollar',
            distance = 1.6,

            timeoutSeconds = 300, -- bag is deleted after this
            ownerOnly = true,     -- only the player who hacked can take it
        },
    },
}
