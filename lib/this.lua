---@meta
----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class MiniLoaderMod
---@field other_mods table<string, string>
---@field MiniLoader miniloader.Controller
---@field Snapping miniloader.Snapping
This = {
    other_mods = {
        ['PickerDollies'] = 'picker-dollies',
        ['even-pickier-dollies'] = 'picker-dollies',
    },
}

Framework.settings:add_defaults(require('lib.settings'))


if script then
    This.MiniLoader = require('scripts.controller')
    This.Snapping = require('scripts.snapping')
    require('scripts.gui')
end
