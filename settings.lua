require('lib.init')

local const = require('lib.constants')

data:extend({
    {
        -- Debug mode (framework dependency)
        type = "bool-setting",
        name = Framework.PREFIX .. 'debug-mode',
        order = "z",
        setting_type = "runtime-global",
        default_value = false,
    },
    {
        type = 'bool-setting',
        name = const.settings.loader_snapping,
        order = 'aa',
        setting_type = 'runtime-global',
        default_value = true,
    },
    {
        type = 'bool-setting',
        name = const.settings.chute_loader,
        order = 'aa',
        setting_type = 'startup',
        default_value = false,
    },
    {
        type = 'bool-setting',
        name = const.settings.no_power,
        order = 'ab',
        setting_type = 'startup',
        default_value = false,
    },
    {
        type = 'bool-setting',
        name = const.settings.migrate_loaders,
        order = 'ac',
        setting_type = 'startup',
        default_value = false,
    },
})

--------------------------------------------------------------------------------

Framework.post_settings_stage()
