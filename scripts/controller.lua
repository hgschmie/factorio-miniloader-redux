---@meta
------------------------------------------------------------------------
-- controller
------------------------------------------------------------------------

local Is = require('stdlib.utils.is')

require('stdlib.utils.string')

local const = require('lib.constants')

---@class miniloader.Controller
---@field supported_loaders table<string, true>
---@field supported_loader_names string[]
local Controller = {
    supported_loaders = {},
    supported_loader_names = {},
}

if script then
    for prototype_name, prototype in pairs(prototypes.entity) do
        -- currently only supports 1x1 loaders
        if prototype_name:starts_with(const.prefix) and const.supported_types[prototype.type] then
            Controller.supported_loaders[prototype_name] = true
            table.insert(Controller.supported_loader_names, prototype_name)
        end
    end
end

------------------------------------------------------------------------

---@type miniloader.Config
local default_config = {
    enabled = true,
}

--- Creates a default configuration with some fields overridden by
--- an optional parent.
---
---@param parent_config miniloader.Config
---@return miniloader.Config
local function create_config(parent_config)
    parent_config = parent_config or default_config

    local config = {}
    -- iterate over all field names given in the default_config
    for field_name, _ in pairs(default_config) do
        if parent_config[field_name] ~= nil then
            config[field_name] = parent_config[field_name]
        else
            config[field_name] = default_config[field_name]
        end
    end

    return config
end


------------------------------------------------------------------------

--- Called when the mod is initialized
function Controller:init()
    ---@type miniloader.Storage
    storage.ml_data = storage.ml_data or {
        VERSION = const.CURRENT_VERSION,
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

    assert(self:getEntity(entity_id) == nil)

    -- if true, draw all combinators and wires. For debugging
    local debug = player_index and Framework.settings:runtime_setting('debug_mode') --[[@as boolean]]

    -- if tags were passed in and they contain a fc config, use that.
    local config = create_config(tags and tags['fc_config'] --[[@as FilterCombinatorConfig]])
    config.status = main.status

    ---@type miniloader.Data
    local ml_entity = {
        main = main,
        ref = { main = main, },
    }
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
