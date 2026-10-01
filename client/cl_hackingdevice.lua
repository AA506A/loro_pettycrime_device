-- ============================================================
--  LoRo Scripts · loro_pettycrime_device/client/cl_hackingdevice.lua
--  © 2026 LoRo Scripts. All rights reserved.
--  Redistribution, resale, re-upload or modification without written
--  permission from LoRo Scripts is strictly prohibited.
--  يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
--  Discord: https://discord.gg/sfHsAwZvDG
-- ============================================================

---@type table<integer, table[]>
local modulesByWeapon = {}

local activeModule = nil

local selectorScreen = nil
local selectorOpen = false
local selectorModules = nil
local selectedIndex = 1

---@type table<string, table>
local selectorKeybinds = {}

local function loadModules()
    lib.print.debug('loadModules() starting...')

    for id, moduleConfig in pairs(Config.Modules) do
        lib.print.debug(('Attempting to load module: %s'):format(id))

        local module = PettyCrimeModules[id]

        if not module then
            lib.print.debug(('Failed to load module: %s'):format(id))
        else
            module.config = moduleConfig
            module:loadProps()

            local propCount = 0

            for _ in pairs(module.propHashes) do
                propCount = propCount + 1
            end

            lib.print.debug(('Module loaded: %s | props: %d'):format(id, propCount))

            local weaponHash = module:getWeaponHash()

            lib.print.debug(('Module %s -> weapon hash: %d'):format(id, weaponHash))

            modulesByWeapon[weaponHash] = modulesByWeapon[weaponHash] or {}

            local list = modulesByWeapon[weaponHash]
            list[#list + 1] = module
        end
    end

    lib.print.debug('loadModules() complete. Registered weapon hashes:')

    for hash, list in pairs(modulesByWeapon) do
        for _, module in ipairs(list) do
            lib.print.debug(('  hash %d -> %s'):format(hash, module.id))
        end
    end
end

---@param weaponHash integer
---@return table[]
local function modulesForWeapon(weaponHash)
    local list = modulesByWeapon[weaponHash]

    if not list then return {} end

    local usable = {}

    for _, module in ipairs(list) do
        if next(module.propHashes) then
            usable[#usable + 1] = module
        end
    end

    return usable
end

local function clearSelectorKeybinds()
    for _, keybind in pairs(selectorKeybinds) do
        keybind:disable(true)
    end

    selectorKeybinds = {}
end

local function closeSelector()
    selectorOpen = false

    clearSelectorKeybinds()

    if selectorScreen then
        selectorScreen:deactivate()
        selectorScreen = nil
    end

    selectorModules = nil
    selectedIndex = 1
end

---@param delta integer
local function moveSelection(delta)
    if not selectorOpen or not selectorScreen then return end

    local count = #selectorModules

    selectedIndex = selectedIndex + delta

    if selectedIndex < 1 then
        selectedIndex = count
    elseif selectedIndex > count then
        selectedIndex = 1
    end

    selectorScreen:sendMessage({ action = 'select', selected = selectedIndex })
end

---@param available table[]
local function openSelector(available)
    local device = available[1].config.device or {}

    local entries = {}

    for index, module in ipairs(available) do
        entries[index] = {
            id = module.id,
            label = module.config.label or module.id,
        }
    end

    selectorScreen = DeviceScreen.new({
        url = ('nui://%s/web/selector/index.html'):format(cache.resource),
        weapon = device.weapon or 'WEAPON_HACKINGDEVICE',
        renderTarget = device.renderTarget or 'w_am_hackdevice_m32',
        duiSize = device.duiSize,
    })

    selectorScreen:activate()

    selectorModules = available
    selectedIndex = 1
    selectorOpen = true

    for step = 1, 10 do
        SetTimeout(200 * step, function()
            if not selectorOpen or not selectorScreen then return end

            selectorScreen:sendMessage({
                action = 'show',
                modules = entries,
                selected = selectedIndex,
            })
        end)
    end

    selectorKeybinds.up = lib.addKeybind({
        name = 'pettydevice_selector_up',
        description = 'Hacking Device - Selector Up',
        defaultKey = 'UP',

        onPressed = function()
            moveSelection(-1)
        end,
    })

    selectorKeybinds.down = lib.addKeybind({
        name = 'pettydevice_selector_down',
        description = 'Hacking Device - Selector Down',
        defaultKey = 'DOWN',

        onPressed = function()
            moveSelection(1)
        end,
    })

    selectorKeybinds.confirm = lib.addKeybind({
        name = 'pettydevice_selector_confirm',
        description = 'Hacking Device - Confirm Selection',
        defaultKey = 'RETURN',

        onPressed = function()
            if not selectorOpen then return end

            selectorScreen:sendMessage({
                action = 'confirm',
                selected = selectedIndex,
            })

            local chosen = selectorModules[selectedIndex]

            SetTimeout(400, function()
                closeSelector()

                activeModule = chosen
                activeModule:activate()
            end)
        end,
    })
end

---@param weaponHash integer
local function activateDevice(weaponHash)
    if activeModule then
        lib.print.debug(('activateDevice: already active (%s), skipping')
            :format(activeModule.id))

        return
    end

    if selectorOpen then return end

    local available = modulesForWeapon(weaponHash)

    if #available == 0 then
        lib.print.debug(('activateDevice: no modules for hash %d'):format(weaponHash))
        return
    end

    if #available == 1 then
        lib.print.debug(('activateDevice: single module %s, activating')
            :format(available[1].id))

        activeModule = available[1]
        activeModule:activate()

        return
    end

    lib.print.debug(('activateDevice: %d modules for hash %d, showing selector')
        :format(#available, weaponHash))

    openSelector(available)
end

local function deactivateDevice()
    if selectorOpen then
        closeSelector()
    end

    if not activeModule then return end

    lib.print.debug(('deactivateDevice: deactivating %s'):format(activeModule.id))

    activeModule:deactivate()
    activeModule = nil
end

CreateThread(function()
    loadModules()

    local weaponHash = cache.weapon

    if weaponHash and modulesByWeapon[weaponHash] then
        lib.print.debug(
            ('Script started while holding weapon hash %d, activating device...')
                :format(weaponHash))

        TriggerServerEvent('loro_pettydevice:server:ensureDeviceUses')
        activateDevice(weaponHash)
    end
end)

lib.onCache('weapon', function(weaponHash)
    if weaponHash and modulesByWeapon[weaponHash] then
        lib.print.debug(('Equipped weapon with hash %d, checking for modules...')
            :format(weaponHash))

        TriggerServerEvent('loro_pettydevice:server:ensureDeviceUses')
        activateDevice(weaponHash)

        return
    end

    lib.print.debug(
        'No weapon equipped or no modules for this weapon, deactivating device if active...')

    deactivateDevice()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        deactivateDevice()
    end
end)
