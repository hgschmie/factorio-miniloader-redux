---@meta
--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------

local Event = require('stdlib.event.event')
local Is = require('stdlib.utils.is')
local Player = require('stdlib.event.player')
local tools = require('framework.tools')
local const = require('lib.constants')

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function onInitMiniloaders()
end

local function onLoadMiniloaders()
end

--------------------------------------------------------------------------------
-- entity create / delete
--------------------------------------------------------------------------------

---@param event EventData.on_object_destroyed
local function onObjectDestroyed(event)
end


--------------------------------------------------------------------------------
-- Configuration changes (runtime and startup)
--------------------------------------------------------------------------------

---@param changed ConfigurationChangedData?
local function onConfigurationChanged(changed)
end

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local ml_entity_filter = tools.create_event_entity_matcher('name', const.miniloader_name)

-- mod init code
Event.on_init(onInitMiniloaders)
Event.on_load(onLoadMiniloaders)

-- Configuration changes (runtime and startup)
Event.on_configuration_changed(onConfigurationChanged)
Event.register(defines.events.on_runtime_mod_setting_changed, onConfigurationChanged)

-- entity destroy
Event.register(defines.events.on_object_destroyed, onObjectDestroyed, ml_entity_filter)

-- manage ghost building (robot building) Register all ghosts we are interested in
Framework.ghost_manager:register_for_ghost_names(const.miniloader_name)
