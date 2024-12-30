---@meta
------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- globals
--------------------------------------------------------------------------------

local table = require('stdlib.utils.table')

local Constants = {}

--------------------------------------------------------------------------------
-- main constants
--------------------------------------------------------------------------------

-- the current version that is the result of the latest migration
Constants.CURRENT_VERSION = 1

Constants.prefix = 'hps__ml-'
Constants.name = 'miniloader'
Constants.root = '__miniloader-redux__'
Constants.gfx_location = Constants.root .. '/graphics/'
Constants.order = 'l[oaders]-m[iniloader]'

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
-- localization
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
return Constants
