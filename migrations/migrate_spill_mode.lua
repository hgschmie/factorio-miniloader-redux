--
-- Add 1.1 spill_mode flag
--

This, Framework = require('lib.init')()

local const = require('lib.constants')

local spill_mode = Framework.settings:startup_setting(const.settings_names.spill_items)

for _, ml_entity in pairs(This.MiniLoader:entities()) do
    if ml_entity.config.spill_mode == nil then
        ml_entity.config.spill_mode = spill_mode
    end
end
