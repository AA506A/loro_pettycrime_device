-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/server/sv_config.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

-- Server only - players cannot read these values.

Config.Server = {
    respawnSeconds = 45 * 60,    -- machine cooldown after being emptied
    playerCooldownSeconds = 90,  -- per player, per machine type
    rangeTolerance = 3.0,        -- extra distance allowed on server checks
    minDurationFactor = 0.8,     -- hack must last at least 80% of hackDuration
    gridSize = 0.5,              -- machines are tracked per grid cell
    lootedQueryIntervalMs = 400, -- anti-spam for radar queries

    -- chance = 0.0 - 1.0 (0.30 = 30%)
    Loot = {
        vending = {
            cash = { chance = 0.85, min = 15, max = 90 },

            items = {
                { name = 'ecola',     chance = 0.30, min = 1, max = 2 },
                { name = 'sprunk',    chance = 0.30, min = 1, max = 2 },
                { name = 'water',     chance = 0.25, min = 1, max = 2 },
                { name = 'sandwich',  chance = 0.20, min = 1, max = 1 },
                { name = 'burger',    chance = 0.12, min = 1, max = 1 },
                { name = 'pqs_candy', chance = 0.18, min = 1, max = 2 },
            },

            maxItemLines = 3, -- max different items per machine
        },

        parkingmeter = {
            cash = { chance = 0.95, min = 25, max = 140 },

            items = {
                { name = 'scrapmetal',    chance = 0.08, min = 1, max = 2 },
                { name = 'circuit_board', chance = 0.04, min = 1, max = 1 },
            },

            maxItemLines = 1,

            -- Rare items, rolled separately. chancePercent = 1 means 1%
            rare = {
                {
                    name = 'sticky_note',
                    chancePercent = 1,
                    min = 1,
                    max = 1,
                    metadataFrom = nil, -- optional 'resource.exportName' that returns item metadata
                },
            },
        },
    },

    -- Runs after every successful hack. Use it for XP / reputation / logs.
    -- OnHackComplete = function(source, module)
    --     exports['my_reputation']:AddXp(source, 'crime', 5)
    -- end,
    OnHackComplete = nil,
}
