---@meta
------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- globals
--------------------------------------------------------------------------------

local Constants = {}

--------------------------------------------------------------------------------
-- main constants
--------------------------------------------------------------------------------

-- the current version that is the result of the latest migration
Constants.current_version = 1

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

--------------------------------------------------------------------------------
-- settings
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- localization
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
return Constants
