---@meta
------------------------------------------------------------------------
-- controller
------------------------------------------------------------------------

local Is = require('stdlib.utils.is')

require('stdlib.utils.string')

local const = require('lib.constants')

---@class miniloader.Controller
local Controller = {}

------------------------------------------------------------------------

--- Called when the mod is initialized
function Controller:init()
    ---@type miniloader.Storage
    storage.ml_data = storage.ml_data or {
        VERSION = const.CURRENT_VERSION,
        supported_loaders = {},
        count = 0,
        miniloaders = {},
    }
end

------------------------------------------------------------------------
-- attribute getters/setters
------------------------------------------------------------------------

--- Returns the registered total count
---@return integer count The total count of miniloaders
function Controller:entityCount()
    return storage.ml_data.count
end

--- Returns data for all miniloaders.
---@return table<integer, miniloader.Data> entities
function Controller:entities()
    return storage.ml_data.miniloaders
end

--- Returns data for a given miniloader
---@param entity_id integer main unit number (== entity id)
---@return miniloader.Data? entity
function Controller:getEntity(entity_id)
    return storage.ml_data.miniloaders[entity_id]
end

--- Sets or clears a miniloader entity.
---@param entity_id integer The unit_number of the primary
---@param ml_entity miniloader.Data?
function Controller:setEntity(entity_id, ml_entity)
    assert((ml_entity ~= nil and storage.ml_data.miniloaders[entity_id] == nil)
        or (ml_entity == nil and storage.ml_data.miniloaders[entity_id] ~= nil))

    if (ml_entity) then
        assert(Is.Valid(ml_entity.main) and ml_entity.main.unit_number == entity_id)
    end

    storage.ml_data.miniloaders[entity_id] = ml_entity
    storage.ml_data.count = storage.ml_data.count + ((ml_entity and 1) or -1)

    if storage.ml_data.count < 0 then
        storage.ml_data.count = table_size(storage.ml_data.miniloaders)
        Framework.logger:logf('Miniloader count got negative (bug), size is now: %d', storage.ml_data.count)
    end
end


------------------------------------------------------------------------
--
------------------------------------------------------------------------

function Controller:update_supported_loaders()
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
function Controller:is_supported(entity)
    if not Is.Valid(entity) then return false end
    assert(entity)

    return storage.ml_data.supported_loaders[entity.prototype.name] and const.supported_types[entity.prototype.type] and true or false
end

------------------------------------------------------------------------
-- create/destroy
------------------------------------------------------------------------

--- Creates a new entity from the main entity, registers with the mod
--- and configures it.
---@param main LuaEntity
---@param player_index integer?
---@param tags Tags?
function Controller:create(main, player_index, tags)
    if not Is.Valid(main) then return end

    local entity_id = main.unit_number --[[@as integer]]
end

--- Destroys a Miniloader and all its sub-entities
---@param entity_id integer? main unit number (== entity id)
function Controller:destroy(entity_id)
    if not (entity_id and Is.Number(entity_id)) then return end
    assert(entity_id)

    local ml_entity = self:getEntity(entity_id)
    if not ml_entity then return end
end

------------------------------------------------------------------------


return Controller
