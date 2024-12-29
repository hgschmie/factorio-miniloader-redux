---@meta
------------------------------------------------------------------------
-- controller
------------------------------------------------------------------------

local Is = require('stdlib.utils.is')
local Area = require('stdlib.area.area')
local Direction = require('stdlib.area.direction')
local Position = require('stdlib.area.position')

require('stdlib.utils.string')

local const = require('lib.constants')

---@class miniloader.Controller
---@field supported_types table<string, true>
---@field supported_type_names string[]
---@field supported_loaders table<string, true>
---@field supported_loader_names string[]
---@field supported_inserters table<string, true>
---@field supported_inserter_names string[]
---@field outside_positions table<defines.direction, MapPosition[]>
---@field inside_positions table<defines.direction, MapPosition[]>
local Controller = {
    supported_types = {},
    supported_type_names = {},
    supported_loaders = {},
    supported_loader_names = {},
    supported_inserters = {},
    supported_inserter_names = {},
}

if script then
    for prototype_name, prototype in pairs(prototypes.entity) do
        if prototype_name:starts_with(const.prefix) and const.miniloader_types[prototype.type] and prototype_name:ends_with(const.name) then
            Controller.supported_types[prototype_name] = true
            table.insert(Controller.supported_type_names, prototype_name)

            local loader_name = const.loader_name(prototype_name)
            Controller.supported_loaders[loader_name] = true
            table.insert(Controller.supported_loader_names, loader_name)

            local inserter_name = const.inserter_name(prototype_name)
            Controller.supported_inserters[inserter_name] = true
            table.insert(Controller.supported_inserter_names, inserter_name)
        end
    end
end

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

    local x = v and shift or 0
    local y = v and 0 or shift
    Controller.inside_positions[direction][1] = Position { x = x, y = y }
    Controller.inside_positions[direction][2] = Position { x = v and -x or x, y = v and y or -y }

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

    loader.active = false
    loader.destructible = false
    loader.operable = false

    script.register_on_object_destroyed(loader)

    return loader
end

---@param main LuaEntity
---@param loader LuaEntity
---@param config miniloader.Config
local function create_inserters(main, loader, config)
    -- 0.125 = 60 items/s / 60 ticks/s / 8 items/tile
    -- create twice the number of inserters needed (two lanes), but one inserter is
    -- the main unit
    local inserter_count = math.ceil(loader.prototype.belt_speed / 0.125) * 2

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
        
        inserter.active = false
        inserter.destructible = false
        inserter.operable = false
        script.register_on_object_destroyed(inserter)

        local inserter_wire_connectors = inserter.get_wire_connectors(true)

        for wire_connector_id, wire_connector in pairs(inserter_wire_connectors) do
            wire_connector.connect_to(main_wire_connectors[wire_connector_id], false, defines.wire_origin.script)
        end

        table.insert(inserters, inserter)
    end

    return inserters
end

------------------------------------------------------------------------
-- rotate
------------------------------------------------------------------------

---@param ml_entity miniloader.Data
---@param previous_direction defines.direction
function Controller:rotate(ml_entity, previous_direction)
    if ml_entity.config.loader_type == const.loader_direction.output then
        ml_entity.config.direction = Direction.opposite(ml_entity.config.direction)
    end
    ml_entity.config.loader_type = This.Snapping:reverse_loader_type(ml_entity.config.loader_type)
    self:reconfigure(ml_entity)
end

------------------------------------------------------------------------
-- blueprinting
------------------------------------------------------------------------

---@param entity LuaEntity
---@param idx integer
---@param blueprint LuaItemStack
---@param context table<string, any>
function Controller:blueprint_callback(entity, idx, blueprint, context)
    local ml_entity = self:getEntity(entity.unit_number)
    if not ml_entity then return end

    blueprint.set_blueprint_entity_tag(idx, 'ml_config', ml_entity.config)
end

------------------------------------------------------------------------
-- create/destroy
------------------------------------------------------------------------

--- Creates a new entity from the main entity, registers with the mod
--- and configures it.
---@param main LuaEntity
---@param tags Tags?
---@return miniloader.Data?
function Controller:create(main, tags)
    if not Is.Valid(main) then return nil end

    local entity_id = main.unit_number --[[@as integer]]

    assert(self:getEntity(entity_id) == nil)

    -- if tags were passed in and they contain a config, use that.
    local config = create_config(tags and tags['ml_config'] --[[@as miniloader.Config]])
    config.status = main.status
    config.direction = main.direction -- miniloader entity always points in inserter direction

    main.active = false

    local loader = create_loader(main, config)
    local inserters = create_inserters(main, loader, config)

    ---@type miniloader.Data
    local ml_entity = {
        main = main,
        loader = loader,
        inserters = inserters,
        config = util.copy(config),
    }

    self:setEntity(entity_id, ml_entity)

    This.Snapping:snapToNeighbor(ml_entity)
    self:syncInserterConfig(ml_entity)
    self:reconfigure(ml_entity)

    return ml_entity
end

--- Destroys a Miniloader and all its sub-entities
---@param entity_id integer? main unit number (== entity id)
function Controller:destroy(entity_id)
    if not (entity_id and Is.Number(entity_id)) then return end
    assert(entity_id)

    local ml_entity = self:getEntity(entity_id)
    if not ml_entity then return end

    self:setEntity(entity_id, nil)

    if ml_entity.loader then
        ml_entity.loader.destroy()
        ml_entity.loader = nil
    end

    if ml_entity.inserters then
        for i = 2, #ml_entity.inserters do
            if ml_entity.inserters[i].valid then
                ml_entity.inserters[i].destroy()
            end
            ml_entity.inserters[i] = nil
        end
    end
end

------------------------------------------------------------------------
-- sync inserter control behavior
------------------------------------------------------------------------

local control_attributes = {
    'circuit_set_filters',
    'circuit_read_hand_contents',
    'circuit_hand_read_mode',
    'circuit_set_stack_size',
    'circuit_stack_control_signal',
    'circuit_enable_disable',
    'circuit_condition',
    'connect_to_logistic_network',
    'logistic_condition',
}

local entity_attributes = {
    'inserter_stack_size_override',
    'use_filters',
    'inserter_filter_mode',

}


---@param ml_entity miniloader.Data
function Controller:syncInserterConfig(ml_entity)
    local control = ml_entity.main.get_or_create_control_behavior() --[[@as LuaInserterControlBehavior ]]
    assert(control)

    if not control.valid then return end

    local inserter_config = {
        filters = {},
    }

    for _, attribute in pairs(control_attributes) do
        inserter_config[attribute] = control[attribute]
    end

    for _, attribute in pairs(entity_attributes) do
        inserter_config[attribute] = ml_entity.main[attribute]
    end

    for i = 1, ml_entity.main.filter_slot_count, 1 do
        inserter_config.filters[i] = ml_entity.main.get_filter(i)
    end

    ml_entity.config.inserter_config = inserter_config
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

    local area = position:expand_to_area(0.1)
    rendering.draw_rectangle {
        color = color,
        surface = ml_entity.loader.surface,
        left_top = area.left_top,
        right_bottom = area.right_bottom,
        time_to_live = const.debug_lifetime,
    }
    rendering.draw_text {
        text = tostring(index),
        surface = ml_entity.loader.surface,
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

    -- reorient loader
    ml_entity.loader.loader_type = tostring(config.loader_type)
    ml_entity.loader.direction = compute_loader_direction(config)

    -- connect inserters and loader

    local back_position = Position(ml_entity.main.position):translate(direction, -1)
    local front_position = Position(ml_entity.loader.position):translate(direction, 0.2)
    local inside_target = ml_entity.loader

    if Framework.settings:runtime_setting('debug_mode') then
        for x = 1, table_size(self.outside_positions[direction]), 1 do
            local outside_position = back_position + self.outside_positions[direction][one_mod(x, 8)]
            local inside_position = front_position + self.inside_positions[direction][one_mod(x, 2)]

            local pickup_position = outside_position
            local drop_position = inside_position

            if config.loader_type == const.loader_direction.input then
                pickup_position = inside_position
                drop_position = outside_position
            end

            draw_position(ml_entity, drop_position, { r = 0.4, g = 0.1, b = 0.1 }, x)
            draw_position(ml_entity, pickup_position, { r = 0.1, g = 0.4, b = 0.1 }, x)
        end
    end

    ml_entity.loader.active = true

    for index, inserter in pairs(ml_entity.inserters) do
        -- reorient inserter
        inserter.direction = direction

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
            pickup_position = outside_position
            drop_position = inside_position

            inserter.pickup_target = nil
            inserter.drop_target = inside_target
        end

        inserter.pickup_position = pickup_position
        inserter.drop_position = drop_position

        for _, attribute in pairs(entity_attributes) do
            inserter[attribute] = ml_entity.config.inserter_config[attribute]
        end

        for i = 1, inserter.filter_slot_count, 1 do
            inserter.set_filter(i, ml_entity.config.inserter_config.filters[i])
        end

        local control = inserter.get_or_create_control_behavior() --[[@as LuaInserterControlBehavior ]]
        assert(control)

        if control.valid then
            for _, attribute in pairs(control_attributes) do
                control[attribute] = ml_entity.config.inserter_config[attribute]
            end
        end

        inserter.active = true

        if Framework.settings:runtime_setting('debug_mode') then
            draw_position(ml_entity, drop_position, { r = 1, g = 0, b = 0 }, index)
            draw_position(ml_entity, pickup_position, { r = 0, g = 1, b = 0 }, index)
        end
    end
end

------------------------------------------------------------------------

return Controller
