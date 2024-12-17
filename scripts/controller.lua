---@meta
------------------------------------------------------------------------
-- controller
------------------------------------------------------------------------

local Is = require('stdlib.utils.is')

local string = require('stdlib.utils.string')

local const = require('lib.constants')

---@class miniloader.Controller
local controller = {}

---@class miniloader.Storage
---@field VERSION integer
---@field supported_loaders table<string, true>

------------------------------------------------------------------------

--- Called when the mod is initialized
function controller:init()
    ---@type miniloader.Storage
    storage.ml_data = storage.ml_data or {
        VERSION = const.CURRENT_VERSION,
        supported_loaders = {}
    }
end

function controller:update_supported_loaders()
    local supported_loaders = {}
    for prototype_name, prototype in pairs(prototypes.entity) do
        -- currently only supports 1x1 loaders
        if prototype_name:starts_with(const.prefix) and const.supported_types[prototype.type] then
            supported_loaders[prototype_name] = true
        end
    end

    storage.ml_data.supported_loaders = supported_loaders
end

---@param entity LuaEntity?
---@return boolean
function controller:is_supported(entity)
    if not Is.Valid(entity) then return false end
    assert(entity)

    return storage.ml_data.supported_loaders[entity.prototype.name] and const.supported_types[entity.prototype.type] and true or false
end

------------------------------------------------------------------------


return controller
