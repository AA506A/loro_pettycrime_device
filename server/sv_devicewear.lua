-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/server/sv_devicewear.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

DeviceWear = DeviceWear or {}

---@return integer? uses a fresh device of this weapon carries
local function freshUses(weaponName)
    local wear = Config.DeviceWear
    local uses = wear and wear.uses

    if not uses or not weaponName then return nil end

    return uses[weaponName] or uses[weaponName:upper()]
end

---@return string
local function metaKey()
    return (Config.DeviceWear and Config.DeviceWear.metadataKey) or 'hackUses'
end

---@return string[]
local function deviceNames()
    local names = {}

    for name in pairs(Config.DeviceWear.uses or {}) do
        names[#names + 1] = name
    end

    return names
end

---@return string? key the KVP slot for this character's device
local function kvpKey(source, slot)
    local identifier = Bridge.GetIdentifier(source)

    if not identifier then return nil end

    return ('wear:%s:%s'):format(identifier, slot.name:upper())
end

---@param source integer
---@return table? slot
local function heldDevice(source)
    if not Config.DeviceWear or Config.DeviceWear.enabled == false then return end

    local weapon = Bridge.GetCurrentWeapon(source, deviceNames())

    if not weapon then return end
    if not freshUses(weapon.name) then return end

    return weapon
end

---@return integer?
local function readUses(source, slot)
    local uses = tonumber(slot.metadata and slot.metadata[metaKey()])

    if uses then return uses end

    local key = kvpKey(source, slot)

    if key then
        return tonumber(GetResourceKvpString(key))
    end
end

---@param source integer
---@param slot table
---@param uses integer
local function writeUses(source, slot, uses)
    local metadata = {}

    for key, value in pairs(slot.metadata or {}) do
        metadata[key] = value
    end

    metadata[metaKey()] = uses

    if Bridge.SetMetadata(source, slot.slot, metadata) then return end

    local key = kvpKey(source, slot)

    if key then
        SetResourceKvp(key, tostring(uses))
    end
end

---@param source integer
function DeviceWear.Ensure(source)
    local slot = heldDevice(source)

    if not slot then return end

    if readUses(source, slot) then return end

    writeUses(source, slot, freshUses(slot.name))
end

---@param source integer
---@return boolean
function DeviceWear.HasUse(source)
    if not Config.DeviceWear or Config.DeviceWear.enabled == false then return true end

    local slot = heldDevice(source)

    if not slot then return true end

    local uses = readUses(source, slot)

    return uses == nil or uses > 0
end

---@param source integer
---@return { usesLeft?: integer, broke?: boolean }
function DeviceWear.Spend(source)
    if not Config.DeviceWear or Config.DeviceWear.enabled == false then return {} end

    local slot = heldDevice(source)

    if not slot then return {} end

    local uses = readUses(source, slot) or freshUses(slot.name)

    uses = math.max(0, uses - 1)

    if uses > 0 then
        writeUses(source, slot, uses)

        return { usesLeft = uses }
    end

    Bridge.RemoveItem(source, slot.name, 1, slot.slot)

    local key = kvpKey(source, slot)

    if key then DeleteResourceKvp(key) end

    return { usesLeft = 0, broke = true }
end

RegisterNetEvent('loro_pettydevice:server:ensureDeviceUses', function()
    DeviceWear.Ensure(source)
end)
