require('lib.init')('settings')

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
})

--------------------------------------------------------------------------------

require('framework.other-mods').settings()
