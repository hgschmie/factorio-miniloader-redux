---@meta
------------------------------------------------------------------------
-- global startup settings
------------------------------------------------------------------------

local const = require('lib.constants')

---@type table<FrameworkSettings.name, FrameworkSettingsGroup>
local Settings = {
    runtime = {
        loader_snapping = { key = const.settings.loader_snapping, value = false },
    },
    startup = {
        chute_loader = { key = const.settings.chute_loader, value = false },
    },
}

return Settings
