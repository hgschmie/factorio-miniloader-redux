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
    This.MiniLoader:init()
end

local function onLoadMiniloaders()
end

--------------------------------------------------------------------------------
-- entity create / delete
--------------------------------------------------------------------------------

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_revive | EventData.script_raised_built
local function onEntityCreated(event)
    local entity = event and event.entity

    local player_index = event.player_index
    local tags = event.tags

    local entity_ghost = Framework.ghost_manager:findMatchingGhost(entity)
    if entity_ghost then
        player_index = player_index or entity_ghost.player_index
        tags = tags or entity_ghost.tags
    end

    -- register entity for destruction
    script.register_on_object_destroyed(entity)

    This.MiniLoader:create(entity, player_index, tags)
end

---@param event EventData.on_player_mined_entity | EventData.on_robot_mined_entity | EventData.on_entity_died | EventData.script_raised_destroy
local function onEntityDeleted(event)
    local entity = event and event.entity

    local unit_number = entity.unit_number

    This.MiniLoader:destroy(unit_number)
    -- Gui.closeByEntity(unit_number)
end

--------------------------------------------------------------------------------
-- Entity destruction
--------------------------------------------------------------------------------

---@param event EventData.on_object_destroyed
local function onObjectDestroyed(event)
    -- is it a ghost?
    if storage.ghosts and storage.ghosts[event.useful_id] then
        storage.ghosts[event.useful_id] = nil
        return
    end

    -- or a main entity?
    local ml_entity = This.MiniLoader:getEntity(event.useful_id)
    if not ml_entity then return end

    -- main entity destroyed
    This.MiniLoader:destroy(event.useful_id)
    -- Gui.closeByEntity(event.useful_id)
end


--------------------------------------------------------------------------------
-- Configuration changes (runtime and startup)
--------------------------------------------------------------------------------

---@param changed ConfigurationChangedData?
local function onConfigurationChanged(changed)
    This.MiniLoader:init()
    This.MiniLoader:update_supported_loaders()
    storage.ml_data.miniloaders = storage.ml_data.miniloaders or {}
    storage.ml_data.count = storage.ml_data.count or 0
end

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local ml_entity_filter = tools.create_event_entity_matcher('type', const.supported_type_names)

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

-- entity create / delete
tools.event_register(tools.CREATION_EVENTS, onEntityCreated, ml_entity_filter)
tools.event_register(tools.DELETION_EVENTS, onEntityDeleted, ml_entity_filter)
