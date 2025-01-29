---@meta
--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------
assert(script)

local Position = require('stdlib.area.position')
local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')
local Is = require('stdlib.utils.is')
local table = require('stdlib.utils.table')

local tools = require('framework.tools')

local const = require('lib.constants')

local migration = require('scripts.migration')


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

    This.MiniLoader:create(entity, tags)
end

---@param event EventData.on_player_mined_entity | EventData.on_robot_mined_entity | EventData.on_entity_died | EventData.script_raised_destroy
local function onEntityDeleted(event)
    local entity = event and event.entity

    local unit_number = entity.unit_number

    This.MiniLoader:destroy(unit_number)
end

--------------------------------------------------------------------------------
-- Entity snapping
--------------------------------------------------------------------------------

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_revive | EventData.script_raised_built
local function onSnappableEntityCreated(event)
    if not Framework.settings:runtime_setting(const.settings_names.loader_snapping) then return end

    local entity = event and event.entity
    if not Is.Valid(entity) then return end

    -- if this is an actual miniloader, don't snap it
    if const.supported_types[entity.name] then return end

    This.Snapping:updateLoaders(entity)
end

local function onSnappableEntityRotated(event)
    if not Framework.settings:runtime_setting(const.settings_names.loader_snapping) then return end

    local entity = event and event.entity
    if not Is.Valid(entity) then return end
    assert(entity)

    -- if this is an actual miniloader, don't snap it
    if const.supported_types[entity.name] then return end

    This.Snapping:updateLoaders(entity)
end

--------------------------------------------------------------------------------
-- Entity destruction
--------------------------------------------------------------------------------

---@param event EventData.on_object_destroyed
local function onObjectDestroyed(event)
    -- clear out references if applicable
    if not This.MiniLoader:getEntity(event.useful_id) then return end

    This.MiniLoader:destroy(event.useful_id)
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

    This.MiniLoader:rotate(ml_entity)
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
-- Entity settings pasting
--------------------------------------------------------------------------------

---@param event EventData.on_entity_settings_pasted
local function onEntitySettingsPasted(event)
    local player = Player.get(event.player_index)

    if not (Is.Valid(player) and player.force == event.source.force and player.force == event.destination.force) then return end

    local src_entity = This.MiniLoader:getEntity(event.source.unit_number)
    local dst_entity = This.MiniLoader:getEntity(event.destination.unit_number)

    if not (src_entity and dst_entity) then return end

    This.MiniLoader:reconfigure(dst_entity, src_entity.config)
end

--------------------------------------------------------------------------------
-- Entity cloning
--------------------------------------------------------------------------------

---@param event EventData.on_entity_cloned
local function onEntityCloned(event)
    if not (Is.Valid(event.source) and Is.Valid(event.destination)) then return end

    local src_data = This.MiniLoader:getEntity(event.source.unit_number)
    if not src_data then return end

    local cloned_entities = event.destination.surface.find_entities(Position(event.destination.position):expand_to_area(0.5))
    for _, cloned_entity in pairs(cloned_entities) do
        if const.supported_inserters[cloned_entity.name] then
            cloned_entity.destroy()
        elseif const.supported_loaders[cloned_entity.name] then
            cloned_entity.destroy()
        end
    end

    local tags = { ml_config = src_data.config } -- clone the config from the src to the destination

    This.MiniLoader:create(event.destination, tags)
end

---@param event EventData.on_entity_cloned
local function onInternalEntityCloned(event)
    if not (Is.Valid(event.source) and Is.Valid(event.destination)) then return end

    -- delete the destination entity, it is not needed as the internal structure of the
    -- miniloader is recreated when the main entity is cloned
    event.destination.destroy()
end

--------------------------------------------------------------------------------
-- Configuration changes (runtime and startup)
--------------------------------------------------------------------------------

local function onConfigurationChanged()
    This.MiniLoader:init()

    -- enable recipes if researched
    for _, force in pairs(game.forces) do
        for _, name in pairs(const.supported_type_names) do
            if force.recipes[name] and force.technologies[name] then
                force.recipes[name].enabled = force.technologies[name].researched
            end
        end
    end

    if Framework.settings:startup_setting('migrate_loaders') then
        migration:migrate_miniloaders()
        migration:migrate_game_blueprints()
    end
end

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local function register_events()
    local ml_entity_filter = tools.create_event_entity_matcher('name', const.supported_type_names)
    local ml_internal_entity_filter = tools.create_event_entity_matcher('name', table.array_combine(const.supported_inserter_names, const.supported_loader_names))
    local snap_entity_filter = tools.create_event_entity_matcher('type', const.snapping_type_names)
    local forward_snap_entity_filter = tools.create_event_entity_matcher('type', const.forward_snapping_type_names)

    -- Configuration changes (runtime and startup)
    Event.on_configuration_changed(onConfigurationChanged)

    -- entity destroy (can't filter on that)
    Event.register(defines.events.on_object_destroyed, onObjectDestroyed)

    -- manage blueprinting and copy/paste
    Framework.blueprint:register_callback(const.supported_type_names, onBlueprintCallback)

    -- entity create / delete
    tools.event_register(tools.CREATION_EVENTS, onEntityCreated, ml_entity_filter)
    tools.event_register(tools.DELETION_EVENTS, onEntityDeleted, ml_entity_filter)

    -- other entities
    tools.event_register(tools.CREATION_EVENTS, onSnappableEntityCreated, snap_entity_filter)
    Event.register(defines.events.on_player_rotated_entity, onSnappableEntityRotated, forward_snap_entity_filter)

    -- entity rotation
    Event.register(defines.events.on_player_rotated_entity, onEntityRotated, ml_entity_filter)

    -- Entity cloning
    Event.register(defines.events.on_entity_cloned, onEntityCloned, ml_entity_filter)
    Event.register(defines.events.on_entity_cloned, onInternalEntityCloned, ml_internal_entity_filter)

    -- Entity settings pasting
    Event.register(defines.events.on_entity_settings_pasted, onEntitySettingsPasted, ml_entity_filter)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function onInitMiniloaders()
    This.MiniLoader:init()
    register_events()
end

local function onLoadMiniloaders()
    register_events()
end

-- setup player management
Player.register_events(true)

-- mod init code
Event.on_init(onInitMiniloaders)
Event.on_load(onLoadMiniloaders)
