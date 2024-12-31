---@meta
------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- globals
--------------------------------------------------------------------------------

require('stdlib.utils.string')

local table = require('stdlib.utils.table')

--------------------------------------------------------------------------------
-- main constants
--------------------------------------------------------------------------------

---@class miniloader.Constants
---@field supported_types table<string, true>
---@field supported_type_names string[]
---@field supported_loaders table<string, true>
---@field supported_loader_names string[]
---@field supported_inserters table<string, true>
---@field supported_inserter_names string[]
---@field CURRENT_VERSION number
---@field prefix string
---@field name string
---@field root string
--_@field order string
local Constants = {
    -- the current version that is the result of the latest migration
    CURRENT_VERSION = 1,

    prefix = 'hps__ml-',
    name = 'miniloader',
    root = '__miniloader-redux__',
    order = 'l[oaders]-m[iniloader]',

    supported_types = {},
    supported_type_names = {},
    supported_loaders = {},
    supported_loader_names = {},
    supported_inserters = {},
    supported_inserter_names = {},
}

Constants.gfx_location = Constants.root .. '/graphics/'

--------------------------------------------------------------------------------
-- Framework intializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function Constants.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = Constants.prefix,
        -- name is a human readable name
        name = Constants.name,
        -- The filesystem root.
        root = Constants.root,
    }
end

--------------------------------------------------------------------------------
-- Path and name helpers
--------------------------------------------------------------------------------

---@param value string
---@return string result
function Constants:with_prefix(value)
    return self.prefix .. value
end

---@param path string
---@return string result
function Constants:png(path)
    return self.gfx_location .. path .. '.png'
end

---@param id string
---@return string result
function Constants:locale(id)
    return Constants:with_prefix('gui.') .. id
end

---@param prefix string?
---@return string result
function Constants:name_from_prefix(prefix)
    local name = (prefix and prefix:len() > 0 and (prefix .. '-' .. self.name)) or self.name
    return self:with_prefix(name)
end

--------------------------------------------------------------------------------
-- entity names and maps
--------------------------------------------------------------------------------

-- Base name
Constants.miniloader_name = Constants:with_prefix(Constants.name)

---@param name string
---@return string
function Constants.loader_name(name)
    return name .. '-l'
end

---@param name string
---@return string
function Constants.inserter_name(name)
    return name .. '-i'
end

Constants.miniloader_type_names = {
    'inserter',
}

Constants.miniloader_types = table.array_to_dictionary(Constants.miniloader_type_names, true)

Constants.snapping_type_names = {
    'lane-splitter', 'linked-belt', 'loader', 'loader-1x1', 'splitter', 'underground-belt', 'transport-belt'
}

-- supported types for snapping
---@type table<string, true>
Constants.snapping_types = table.array_to_dictionary(Constants.snapping_type_names, true)

---@enum miniloader.LoaderDirection
---@type table<miniloader.LoaderDirection, string>
Constants.loader_direction = {
    input = 'input',
    output = 'output',
}

--------------------------------------------------------------------------------
-- settings
--------------------------------------------------------------------------------

Constants.settings = {
    loader_snapping = Constants:with_prefix('loader_snapping'),
    chute_loader = Constants:with_prefix('chute_loader'),
    migrate_loaders = Constants:with_prefix('migrate_loaders'),
    migrate_player_blueprints = Constants:with_prefix('migrate_player_blueprints')
}

Constants.debug_lifetime = 10 -- how long debug info is shown

--------------------------------------------------------------------------------
-- migrations
--------------------------------------------------------------------------------
function Constants:migrations()
    -- entities that can be migrated from the old 1.1 miniloader.
    local migrations = {
        [''] = self:with_prefix('miniloader'),
        ['fast-'] = self:with_prefix('fast-miniloader'),
        ['express-'] = self:with_prefix('express-miniloader'),
        ['filter-'] = self:with_prefix('miniloader'),
        ['fast-filter-'] = self:with_prefix('fast-miniloader'),
        ['express-filter-'] = self:with_prefix('express-miniloader'),
    }

    if Framework.settings:startup_setting('chute_loader') then
        migrations['chute-'] = self:with_prefix('chute-miniloader')
        migrations['chute-filter-'] = self:with_prefix('chute-miniloader')
    end

    return migrations
end

--------------------------------------------------------------------------------
-- supported entities
--------------------------------------------------------------------------------

if script then
    for prototype_name, prototype in pairs(prototypes.entity) do
        if prototype_name:starts_with(Constants.prefix) and Constants.miniloader_types[prototype.type] and prototype_name:ends_with(Constants.name) then
            Constants.supported_types[prototype_name] = true
            table.insert(Constants.supported_type_names, prototype_name)

            local loader_name = Constants.loader_name(prototype_name)
            Constants.supported_loaders[loader_name] = true
            table.insert(Constants.supported_loader_names, loader_name)

            local inserter_name = Constants.inserter_name(prototype_name)
            Constants.supported_inserters[inserter_name] = true
            table.insert(Constants.supported_inserter_names, inserter_name)
        end
    end
end

--------------------------------------------------------------------------------
return Constants
