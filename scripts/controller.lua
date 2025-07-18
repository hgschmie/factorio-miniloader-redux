---@meta
------------------------------------------------------------------------
-- controller
------------------------------------------------------------------------
assert(script)

local util = require('util')

local Is = require('stdlib.utils.is')
local Direction = require('stdlib.area.direction')
local Position = require('stdlib.area.position')

require('stdlib.utils.string')

local const = require('lib.constants')

---@class miniloader.Controller
---@field outside_positions table<defines.direction, MapPosition[]>
---@field inside_positions table<defines.direction, MapPosition[]>
local Controller = {}

-- position calculation
--
--   8  6  4  2   +-- entity --+
--                |            |
--   7  5  3  1   +------------+
--
--   x  0.4  0.2  0.0 -0.2  y -0.25
--                          y  0.25
--
-- dropoff is 0/0.25 and 0/-0.25


Controller.outside_positions = {
    [defines.direction.north] = {},
    [defines.direction.east] = {},
    [defines.direction.south] = {},
    [defines.direction.west] = {},
}

Controller.inside_positions = util.copy(Controller.outside_positions)

local outside_count = 8 -- number of "outside" positions
local step = 0.2        -- increment per step
local shift = 0.25      -- shift for the position (either left/right or up/down, depending on orientation)

local count = 0         -- goes 0 .. 3 to choose the four sets of data
for direction in pairs(Controller.outside_positions) do
    local v = bit32.band(count, 1) == 1
    local h = (bit32.band(count, 2) == 2) and 1 or -1
    local pos = -0.4 -- first start position

    for index = 1, outside_count, 2 do
        local offset = pos * h
        local x = v and shift or offset
        local y = v and offset or shift

        Controller.outside_positions[direction][index] = Position { x = x, y = y }
        Controller.outside_positions[direction][index + 1] = Position { x = v and -x or x, y = v and y or -y }
        pos = pos + step
    end

    Controller.inside_positions[direction][1] = Controller.outside_positions[direction][1]
    Controller.inside_positions[direction][2] = Controller.outside_positions[direction][2]

    count = count + 1
end

------------------------------------------------------------------------

---@type miniloader.Config
local default_config = {
    enabled = true,
    loader_type = const.loader_direction.input, -- freshly minted loader image is 'input'
    inserter_config = {
        filters = {},
    },
}

--- Creates a default configuration with some fields overridden by
--- an optional parent.
---
---@param parent_config miniloader.Config?
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
        by_main = {},
        open_guis = {},
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
    return storage.ml_data.by_main
end

--- Returns data for a given miniloader
---@param entity_id integer main unit number (== entity id)
---@return miniloader.Data? entity
function Controller:getEntity(entity_id)
    return storage.ml_data.by_main[entity_id]
end

--- Sets or clears a miniloader entity.
---@param entity_id integer The unit_number of the primary
---@param ml_entity miniloader.Data?
function Controller:setEntity(entity_id, ml_entity)
    assert((ml_entity ~= nil and storage.ml_data.by_main[entity_id] == nil)
        or (ml_entity == nil and storage.ml_data.by_main[entity_id] ~= nil))

    if (ml_entity) then
        assert(Is.Valid(ml_entity.main) and ml_entity.main.unit_number == entity_id)
    end

    storage.ml_data.by_main[entity_id] = ml_entity
    storage.ml_data.count = storage.ml_data.count + ((ml_entity and 1) or -1)

    if storage.ml_data.count < 0 then
        storage.ml_data.count = table_size(storage.ml_data.by_main)
        Framework.logger:logf('Miniloader count got negative (bug), size is now: %d', storage.ml_data.count)
    end
end

------------------------------------------------------------------------
-- sub entity management
------------------------------------------------------------------------

---@param config miniloader.Config
---@return defines.direction
local function compute_loader_direction(config)
    -- output loader points in the same direction as the miniloader, input loader points in opposite direction
    return config.loader_type == const.loader_direction.output and config.direction or Direction.opposite(config.direction)
end

---@param main LuaEntity
---@param config miniloader.Config
local function create_loader(main, config)
    -- create the loader with the same orientation as the inserter. Then look in front of the
    -- loader and snap the direction for it.
    local loader = main.surface.create_entity {
        name = const.loader_name(main.name),
        position = main.position,
        direction = compute_loader_direction(config),
        force = main.force,
        type = tostring(config.loader_type),
    }
    assert(loader)

    loader.destructible = false
    loader.operable = true

    local main_wire_connectors = main.get_wire_connectors(true)
    local loader_wire_connectors = loader.get_wire_connectors(true)

    for wire_connector_id, wire_connector in pairs(loader_wire_connectors) do
        wire_connector.connect_to(main_wire_connectors[wire_connector_id], false, defines.wire_origin.script)
    end

    return loader
end

---@param main LuaEntity
---@param loader LuaEntity
---@param config miniloader.Config
function Controller:createInserters(main, loader, config)
    --- belt speed (carries 4 items per lane, two lanes) / inserter rotation speed
    local inserter_count = math.floor(loader.prototype.belt_speed / ((main.prototype.inserter_stack_size_bonus + 1) * main.prototype.get_inserter_rotation_speed(main.quality)) * 2 * 4)
    inserter_count = (inserter_count < 2) and 2 or inserter_count
    assert(inserter_count <= 8)

    local inserters = { main }

    local main_wire_connectors = main.get_wire_connectors(true)

    assert(#inserters <= inserter_count)

    while #inserters < inserter_count do
        local inserter = main.surface.create_entity {
            name = const.inserter_name(main.name),
            position = main.position,
            direction = config.direction,
            force = main.force,
        }
        assert(inserter)

        inserter.destructible = false
        inserter.operable = false

        local inserter_wire_connectors = inserter.get_wire_connectors(true)

        for wire_connector_id, wire_connector in pairs(inserter_wire_connectors) do
            wire_connector.connect_to(main_wire_connectors[wire_connector_id], false, defines.wire_origin.script)
        end

        table.insert(inserters, inserter)
    end

    return inserters
end

------------------------------------------------------------------------
-- rotate/move
------------------------------------------------------------------------

---@param ml_entity miniloader.Data
---@param reverse boolean
function Controller:rotate(ml_entity, reverse)
    if ml_entity.config.loader_type == (reverse and const.loader_direction.input or const.loader_direction.output) then
        ml_entity.config.direction = Direction.opposite(ml_entity.config.direction)
    end
    ml_entity.config.loader_type = This.Snapping:reverse_loader_type(ml_entity.config.loader_type)
    self:reconfigure(ml_entity)
end

---@param main LuaEntity
function Controller:move(main)
    if not const.supported_types[main.name] then return end

    local ml_entity = self:getEntity(main.unit_number)
    if not ml_entity then return end

    self:reconfigure(ml_entity)
end

------------------------------------------------------------------------
-- blueprinting
------------------------------------------------------------------------

--- in very rare cases, some entries in the filter array end up having string
--- keys. try to convert them to number keys, if there would be a conflict, drop
--- the key that comes second
---@param ml_entity miniloader.Data
function Controller:sanitizeConfiguration(ml_entity)
    local filters = {}
    for key, value in pairs(ml_entity.config.inserter_config.filters) do
        if type(key) == 'number' then
            filters[key] = value
        elseif type(key) == 'string' then
            local new_key = tonumber(key)
            if new_key then
                filters[new_key] = filters[new_key] or value
            end
        end
    end
    if table_size(ml_entity.config.inserter_config.filters) ~= table_size(filters) then
        ml_entity.config.inserter_config.filters = filters
    end
end

--- Serializes the configuration suitable for blueprinting and tombstone management.
---
---@param entity LuaEntity
---@return table<string, any>?
function Controller:serializeConfiguration(entity)
    local ml_entity = self:getEntity(entity.unit_number)
    if not ml_entity then return end

    self:sanitizeConfiguration(ml_entity)

    return {
        [const.config_tag_name] = ml_entity.config,
    }
end

------------------------------------------------------------------------
-- create/destroy
------------------------------------------------------------------------

---@param main LuaEntity
---@param config miniloader.Config?
---@return miniloader.Data
function Controller:setup(main, config)
    local entity_id = main.unit_number --[[@as integer]]

    assert(self:getEntity(entity_id) == nil)

    -- if tags were passed in and they contain a config, use that.
    config = create_config(config)
    config.status = main.status
    config.direction = main.direction -- miniloader entity always points in inserter direction

    local loader = create_loader(main, config)
    local inserters = self:createInserters(main, loader, config)

    ---@type miniloader.Data
    local ml_entity = {
        main = main,
        loader = loader,
        inserters = inserters,
        config = util.copy(config),
    }

    self:setEntity(entity_id, ml_entity)

    return ml_entity
end

--- Creates a new entity from the main entity, registers with the mod
--- and configures it.
---@param main LuaEntity
---@param config miniloader.Config?
---@return miniloader.Data?
function Controller:create(main, config)
    if not Is.Valid(main) then return nil end

    local ml_entity = self:setup(main, config)

    This.Snapping:snapToNeighbor(ml_entity)

    self:readConfigFromEntity(main, ml_entity)
    self:reconfigure(ml_entity)

    return ml_entity
end

--- Destroys a Miniloader and all its sub-entities
---@param entity_id integer? main unit number (== entity id)
---@return boolean True if entity was destroyed
function Controller:destroy(entity_id)
    if not (entity_id and Is.Number(entity_id)) then return false end
    assert(entity_id)

    local ml_entity = self:getEntity(entity_id)
    if not ml_entity then return false end

    self:setEntity(entity_id, nil)

    ml_entity.main = nil
    ml_entity.inserters[1] = nil -- do not add to the loop below, game needs to manage the main inserter

    if Is.Valid(ml_entity.loader) then ml_entity.loader.destroy() end
    ml_entity.loader = nil

    if ml_entity.inserters then
        for i = 2, #ml_entity.inserters do
            if Is.Valid(ml_entity.inserters[i]) then ml_entity.inserters[i].destroy() end
            ml_entity.inserters[i] = nil
        end
    end

    return true
end

------------------------------------------------------------------------
-- sync control behavior
------------------------------------------------------------------------

-- GUI updates the loader, loader config is synced to the inserters
-- entity creation / resurrection uses the primary inserter. config is synced from the inserter to the loader
-- all meet at ml_entity.config

local control_attributes = {
    'circuit_set_filters',
    'circuit_enable_disable',
    'circuit_condition',
    'connect_to_logistic_network',
    'logistic_condition',
}

local EMPTY_LOADER_CONFIG = {
    circuit_set_filters = false,
    circuit_enable_disable = false,
    circuit_condition = { constant = 0, comparator = '<', fulfilled = false },
    connect_to_logistic_network = false,
    logistic_condition = { constant = 0, comparator = '<', fulfilled = false },
    loader_filter_mode = 'none',
    filters = {},
    read_transfers = false,
}

---@param entity LuaEntity Loader or Inserter
---@param ml_entity miniloader.Data
function Controller:readConfigFromEntity(entity, ml_entity)
    local control = entity.get_or_create_control_behavior() --[[@as LuaGenericOnOffControlBehavior ]]
    assert(control)

    if not control.valid then return end

    local inserter_config = ml_entity.config.inserter_config

    -- copy control attributes
    for _, attribute in pairs(control_attributes) do
        inserter_config[attribute] = control[attribute]
    end

    if entity.type == 'inserter' then
        if entity.filter_slot_count > 0 then
            inserter_config.loader_filter_mode = entity.use_filters and entity.inserter_filter_mode or 'none'

            local inserter_control = control --[[@as LuaInserterControlBehavior]]
            inserter_config.read_transfers = inserter_control.circuit_read_hand_contents

            for i = 1, entity.filter_slot_count, 1 do
                inserter_config.filters[i] = entity.get_filter(i)
            end
        else
            inserter_config.loader_filter_mode = 'none'
        end
    else
        inserter_config.loader_filter_mode = entity.loader_filter_mode
        local loader_control = control --[[@as LuaLoaderControlBehavior ]]
        inserter_config.read_transfers = loader_control.circuit_read_transfers

        for i = 1, entity.filter_slot_count, 1 do
            inserter_config.filters[i] = entity.get_filter(i)
        end
    end
end

---@param inserter_config table<string, any?>
---@param entity LuaEntity Loader or Inserter
function Controller:writeConfigToEntity(inserter_config, entity)
    if not (entity and entity.valid) then return end

    local control = entity.get_or_create_control_behavior() --[[@as LuaGenericOnOffControlBehavior ]]
    assert(control)

    if not control.valid then return end

    -- copy control attributes
    for _, attribute in pairs(control_attributes) do
        control[attribute] = inserter_config[attribute]
    end

    if entity.type == 'inserter' then
        if entity.filter_slot_count > 0 then
            for i = 1, entity.filter_slot_count, 1 do
                entity.set_filter(i, inserter_config.filters[i])
            end

            if inserter_config.loader_filter_mode and inserter_config.loader_filter_mode ~= 'none' then
                entity.use_filters = true
                entity.inserter_filter_mode = inserter_config.loader_filter_mode
            else
                entity.use_filters = false
            end
        end

        entity.inserter_stack_size_override = entity.prototype.bulk and 4 or 1

        local inserter_control = control --[[@as LuaInserterControlBehavior]]
        inserter_control.circuit_set_stack_size = false

        if inserter_config.read_transfers then
            inserter_control.circuit_read_hand_contents = true
            inserter_control.circuit_hand_read_mode = defines.control_behavior.inserter.hand_read_mode.pulse
        end
    else
        if entity.filter_slot_count > 0 then
            for i = 1, entity.filter_slot_count, 1 do
                entity.set_filter(i, inserter_config.filters[i])
            end

            entity.loader_filter_mode = inserter_config.loader_filter_mode or 'none'
        end

        local loader_control = control --[[@as LuaLoaderControlBehavior ]]
        loader_control.circuit_read_transfers = inserter_config.read_transfers or false
    end
end

---@param ml_entity miniloader.Data
---@param skip_main boolean?
function Controller:resyncInserters(ml_entity, skip_main)
    for _, inserter in pairs(ml_entity.inserters) do
        if not (skip_main and inserter.unit_number == ml_entity.main.unit_number) then
            self:writeConfigToEntity(ml_entity.config.inserter_config, inserter)
        end
    end
end

------------------------------------------------------------------------
-- manage internal state
------------------------------------------------------------------------

-- compute 1-based modulo.
---@param x number
---@param y number
---@return number
local function one_mod(x, y)
    return ((x - 1) % y) + 1
end

---@param ml_entity miniloader.Data
---@param position MapPosition
---@param color Color
---@param index number
local function draw_position(ml_entity, position, color, index)
    if ml_entity.inserters[index] and not ml_entity.inserters[index].active then
        color = { r = 0.3, g = 0.3, b = 0.3 }
    end

    local area = Position(position):expand_to_area(0.1)
    rendering.draw_rectangle {
        color = color,
        surface = ml_entity.main.surface,
        left_top = area.left_top,
        right_bottom = area.right_bottom,
        time_to_live = const.debug_lifetime,
    }
    rendering.draw_text {
        text = tostring(index),
        surface = ml_entity.main.surface,
        target = position,
        color = color,
        scale = 0.5,
        alignment = 'center',
        vertical_alignment = 'middle',
        time_to_live = const.debug_lifetime,
    }
end

---@param ml_entity miniloader.Data
function Controller:reconfigure(ml_entity, cfg)
    if cfg then
        local new_config = util.copy(cfg)
        -- do not overwrite direction and loader type. But they need to be
        -- in the config to allow blueprinting / copy&paste of entities
        new_config.direction = ml_entity.config.direction
        new_config.loader_type = ml_entity.config.loader_type
        ml_entity.config = new_config
    end

    local config = ml_entity.config
    local direction = config.direction
    assert(direction)

    assert(ml_entity.loader.valid)

    -- reorient loader
    ml_entity.loader.loader_type = tostring(config.loader_type)
    ml_entity.loader.direction = compute_loader_direction(config)
    if Position(ml_entity.main.position) ~= Position(ml_entity.loader.position) then
        -- miniloader was moved
        ml_entity.loader.destroy()
        ml_entity.loader = create_loader(ml_entity.main, ml_entity.config)
    end

    -- connect loader to belt if needed
    ml_entity.loader.update_connections()

    -- connect inserters and loader
    local back_position = Position(ml_entity.main.position):translate(direction, -1)
    local front_position = Position(ml_entity.main.position)
    local inside_target = ml_entity.loader

    if Framework.settings:runtime_setting('debug_mode') then
        for x = table_size(ml_entity.inserters) + 1, table_size(self.outside_positions[direction]), 1 do
            local outside_position = back_position + self.outside_positions[direction][one_mod(x, 8)]

            if config.loader_type == const.loader_direction.input then
                draw_position(ml_entity, outside_position, { r = 0.4, g = 0.1, b = 0.1 }, x)
            else
                draw_position(ml_entity, outside_position, { r = 0.1, g = 0.4, b = 0.1 }, x)
            end
        end
    end

    for index, inserter in pairs(ml_entity.inserters) do
        -- reorient inserter
        inserter.direction = direction
        inserter.teleport(ml_entity.main.position)

        if (index % 2) == 1 then
            -- odd number - pick up from right lane
            inserter.pickup_from_left_lane = false
            inserter.pickup_from_right_lane = true
        else
            -- even number - pick up from left lane
            inserter.pickup_from_left_lane = true
            inserter.pickup_from_right_lane = false
        end

        -- either pickup or drop position
        local outside_position = back_position + self.outside_positions[direction][one_mod(index, 8)]
        local inside_position = front_position + self.inside_positions[direction][one_mod(index, 2)]

        local pickup_position = inside_position
        local drop_position = outside_position

        -- loader gets items, inserter drop them off
        if config.loader_type == const.loader_direction.input then
            inserter.pickup_target = inside_target
            inserter.drop_target = nil
        else
            -- inserter gets items, loader sends them down the belt
            pickup_position = outside_position
            drop_position = inside_position

            inserter.pickup_target = nil
            inserter.drop_target = inside_target
        end

        inserter.pickup_position = pickup_position
        inserter.drop_position = drop_position

        if Framework.settings:runtime_setting('debug_mode') then
            draw_position(ml_entity, drop_position, { r = 1, g = 0, b = 0 }, index)
            draw_position(ml_entity, pickup_position, { r = 0, g = 1, b = 0 }, index)
        end
    end

    self:resyncInserters(ml_entity)

    -- clear out loader configuration
    self:writeConfigToEntity(EMPTY_LOADER_CONFIG, ml_entity.loader)
end

------------------------------------------------------------------------

return Controller
