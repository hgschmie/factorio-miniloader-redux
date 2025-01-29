---@meta
------------------------------------------------------------------------
-- global startup settings
------------------------------------------------------------------------

local const = require('lib.constants')

---@type table<FrameworkSettings.name, FrameworkSettingsGroup>
local Settings = {
    runtime = {
        [const.settings_names.loader_snapping] = { key = const.settings.loader_snapping, value = true, },
    },
    startup = {
        [const.settings_names.chute_loader] = { key = const.settings.chute_loader, value = false, },
        [const.settings_names.migrate_loaders] = { key = const.settings.migrate_loaders, value = false, },
    },
}

return Settings
