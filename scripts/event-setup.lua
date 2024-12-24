---@meta
--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------

local Direction = require('stdlib.area.direction')
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
-- Entity snapping
--------------------------------------------------------------------------------

local function onSnappableEntityCreated(event)
    if not Framework.settings:runtime_setting('loader_snapping') then return end

    local entity = event and event.entity
    if not Is.Valid(entity) then return end

    -- if this is an actual miniloader, don't snap it
    if This.MiniLoader.supported_types[entity.name] then return end

    This.Snapping:updateLoaders(entity)
end

local function onSnappableEntityRotated(event)
    if not Framework.settings:runtime_setting('loader_snapping') then return end

    local entity = event and event.entity
    if not Is.Valid(entity) then return end
    assert(entity)

    -- if this is an actual miniloader, don't snap it
    if This.MiniLoader.supported_types[entity.name] then return end

    This.Snapping:updateLoaders(entity)
end

--------------------------------------------------------------------------------
-- Entity destruction
--------------------------------------------------------------------------------

---@param event EventData.on_object_destroyed
local function onObjectDestroyed(event)

    -- clear out references if applicable
    if This.MiniLoader:getEntity(event.useful_id) then
        This.MiniLoader:setEntity(event.useful_id, nil)
    end

end

--------------------------------------------------------------------------------
-- Entity rotation
--------------------------------------------------------------------------------

---@param event EventData.on_player_rotated_entity
local function onEntityRotated(event)
    -- main entity rotated?
    if not Is.Valid(event.entity) then return end
    local ml_entity = This.MiniLoader:getEntity(event.entity.unit_number)
    if not ml_entity then return end

    This.MiniLoader:rotate(ml_entity, event.previous_direction)
end

--------------------------------------------------------------------------------
-- Blueprinting
--------------------------------------------------------------------------------

---@param entity LuaEntity
---@param idx integer
---@param blueprint LuaItemStack
---@param context table<string, any>
local function onBlueprintCallback(entity, idx, blueprint, context)
    if not Is.Valid(entity) then return end

    This.MiniLoader:blueprint_callback(entity, idx, blueprint, context)
end

--------------------------------------------------------------------------------
-- Configuration changes (runtime and startup)
--------------------------------------------------------------------------------

---@param changed ConfigurationChangedData?
local function onConfigurationChanged(changed)
    This.MiniLoader:init()
    storage.ml_data.by_loader = nil

    for id, ml_entity in pairs(This.MiniLoader:entities()) do
        ml_entity.config.direction = ml_entity.config.orientation or ml_entity.config.direction
        ml_entity.config.orientation = nil
        ml_entity.config.loader_type = ml_entity.config.loader_direction or ml_entity.config.loader_type
        ml_entity.config.loader_direction = nil
        ml_entity.config.direction = Direction.opposite(ml_entity.config.direction)

        This.MiniLoader:reconfigure(ml_entity)
    end

    -- if storage.ml_data.miniloaders then
    --     storage.ml_data.by_main = storage.ml_data.miniloaders
    --     storage.ml_data.miniloaders = nil
    -- end

    -- storage.ml_data.by_main = storage.ml_data.by_main or {}
    -- storage.ml_data.count = storage.ml_data.count or 0

    -- storage.ml_data.supported_loaders = nil

    -- local rescued_loaders = {}
    -- local ids = util.copy(This.MiniLoader:entities())
    -- for id, ml_entity in pairs(ids) do
    --     local main = ml_entity.main
    --     if Is.Valid(main) then
    --         rescued_loaders[main.unit_number] = { main = main, config = ml_entity.config }
    --     end
    --     This.MiniLoader:destroy(id)
    -- end

    -- assert(table_size(storage.ml_data.by_main) == 0)

    -- for _, surface in pairs(game.surfaces) do
    --     local entities = surface.find_entities_filtered {
    --         name = This.MiniLoader.supported_type_names,
    --     }

    --     for _, entity in pairs(entities) do
    --         if Is.Valid(entity) and not rescued_loaders[entity.unit_number] then
    --             entity.destroy()
    --         end
    --     end

    --     local loaders = surface.find_entities_filtered {
    --         name = This.MiniLoader.supported_loader_names,
    --     }

    --     for _, loader in pairs(loaders) do
    --         loader.destroy()
    --     end

    --     local inserters = surface.find_entities_filtered {
    --         name = This.MiniLoader.supported_inserter_names,
    --     }

    --     for _, inserter in pairs(inserters) do
    --         inserter.destroy()
    --     end

    --     for id, data in pairs(rescued_loaders) do
    --         This.MiniLoader:create(data.main, 1, { ml_config = data.config })
    --     end
    -- end
end

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local ml_entity_filter = tools.create_event_entity_matcher('name', This.MiniLoader.supported_type_names)
local snap_entity_filter = tools.create_event_entity_matcher('type', const.snapping_type_names)

-- mod init code
Event.on_init(onInitMiniloaders)
Event.on_load(onLoadMiniloaders)

-- Configuration changes (runtime and startup)
Event.on_configuration_changed(onConfigurationChanged)
Event.register(defines.events.on_runtime_mod_setting_changed, onConfigurationChanged)

-- entity destroy (can't filter on that)
Event.register(defines.events.on_object_destroyed, onObjectDestroyed)

-- manage ghost building (robot building) Register all ghosts we are interested in
Framework.ghost_manager:register_for_ghost_names(This.MiniLoader.supported_type_names)

-- manage blueprinting and copy/paste
Framework.blueprint:register_callback(This.MiniLoader.supported_type_names, onBlueprintCallback)

-- entity create / delete
tools.event_register(tools.CREATION_EVENTS, onEntityCreated, ml_entity_filter)
tools.event_register(tools.DELETION_EVENTS, onEntityDeleted, ml_entity_filter)

-- other entities
tools.event_register(tools.CREATION_EVENTS, onSnappableEntityCreated, snap_entity_filter)
Event.register(defines.events.on_player_rotated_entity, onSnappableEntityRotated, snap_entity_filter)

-- entity rotation
Event.register(defines.events.on_player_rotated_entity, onEntityRotated, ml_entity_filter)
