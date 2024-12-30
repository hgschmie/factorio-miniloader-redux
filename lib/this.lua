---@meta
----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class InvSensorModThis
---@field other_mods table<string, string>
---@field MiniLoader miniloader.Controller
---@field Snapping miniloader.Snapping
local This = {
    other_mods = {
        ['PickerDollies'] = 'picker-dollies',
        ['even-pickier-dollies'] = 'picker-dollies',
    },

    MiniLoader = require('scripts.controller'),
    Snapping = require('scripts.snapping'),
}

Framework.settings:add_defaults(require('scripts.settings'))

----------------------------------------------------------------------------------------------------

return function(stage)
    if This['this_' .. stage] then
        This['this_' .. stage](This)
    end

    return This
end
