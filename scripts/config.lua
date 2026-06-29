------------------------------------------------------------------------
-- all the config things
------------------------------------------------------------------------
assert(script)

local Position = require('stdlib.area.position')

local const = require('lib.constants')

---@class miniloader.EntityConfig
local Config = {}

---@type miniloader.Config
local function get_default_config()
    return util.copy {
        enabled = true,
        loader_type = const.loader_direction.input, -- freshly minted loader image is 'input'
        highspeed = false,
        nerf_mode = false,
        turbo_mode = false,
        lane_filter = false,
        circuit_set_filters = false,
        circuit_enable_disable = false,
        circuit_condition = { constant = 0, comparator = '<', },
        connect_to_logistic_network = false,
        logistic_condition = { constant = 0, comparator = '<', },
        filters = {},
        filter_mode = 'none',
        read_transfers = false,
        spoil_priority = This.MiniLoader.spoiling and 'none' or nil,
        stack_size = 1, -- 1 is always supported
    }
end

--- loader and inserter control behavior keys
--- keys are for entity attributes, values are for blueprint entities
---@type table<string, string>
local CONTROL_BEHAVIOR_KEYS = {
    circuit_set_filters = 'circuit_set_filters',
    circuit_enable_disable = 'circuit_enabled',
    circuit_condition = 'circuit_condition',
    connect_to_logistic_network = 'connect_to_logistic_network',
    logistic_condition = 'logistic_condition',
}

-- all keys except the control behavior keys and 'filters'
local CONFIG_KEYS = {
    'enabled', 'turbo_mode', 'lane_filter',
    'filter_mode', 'read_transfers', 'spoil_priority', 'stack_size',
}

--- see https://forums.factorio.com/viewtopic.php?t=133512
local FIX_SPOIL_PRIO = {
    ['fresh-first'] = 'fresh_first',
    ['spoiled-first'] = 'spoiled_first',
    fresh_first = 'fresh_first',
    spoiled_first = 'spoiled_first',
    none = 'none',
}

---@param main LuaEntity
---@param parent_config miniloader.Config?
---@return miniloader.Config config
function Config:createConfiguration(main, parent_config)
    local config = get_default_config()

    self:configureFromInserter(main, config)

    -- always copy the direction keys and nerf_mode if present
    config.direction = parent_config and parent_config.direction
    config.loader_type = parent_config and parent_config.loader_type
    config.nerf_mode = config.nerf_mode or (parent_config and parent_config.nerf_mode)

    -- nerf mode just uses the defaults
    if config.nerf_mode then return config end

    if parent_config then
        for key, parent_value in pairs(parent_config) do
            if config[key] ~= nil then config[key] = util.copy(parent_value) end
        end
    end

    return config
end

---@return miniloader.State
function Config:createState()
    return {
        status = defines.entity_status.disabled,
        filters = {}
    }
end

---@param src_config miniloader.Config
---@param dst_config miniloader.Config
function Config:copyConfig(src_config, dst_config)
    local ml_config = util.copy(src_config)
    local default_config = get_default_config()

    for _, key in pairs(CONFIG_KEYS) do
        if dst_config.nerf_mode then
            dst_config[key] = default_config[key]
        else
            dst_config[key] = ml_config[key]
        end
    end

    -- copy shared control keys over
    for control_key in pairs(CONTROL_BEHAVIOR_KEYS) do
        if dst_config.nerf_mode then
            dst_config[control_key] = default_config[control_key]
        else
            dst_config[control_key] = ml_config[control_key]
        end
    end

    -- copy filter over
    dst_config.filters = {}
    if not dst_config.nerf_mode then
        for key, value in pairs(ml_config.filters) do
            local new_key = tonumber(key)
            if new_key then dst_config.filters[new_key] = value end
        end
    end
end

---@param ml_config miniloader.Config
---@param inserter LuaEntity
function Config:updateConfigFromInserter(ml_config, inserter)
    assert(inserter and inserter.valid)

    local control = assert(inserter.get_or_create_control_behavior()) --[[@as LuaInserterControlBehavior ]]
    assert(control.valid)

    -- copy shared control keys over
    local default_config = get_default_config()
    for control_key in pairs(CONTROL_BEHAVIOR_KEYS) do
        if ml_config.nerf_mode then
            ml_config[control_key] = default_config[control_key]
        else
            ml_config[control_key] = control[control_key]
        end
    end

    -- remove fulfilled flag, otherwise comparing configs won't work
    ml_config.circuit_condition.fulfilled = nil
    ml_config.logistic_condition.fulfilled = nil

    ml_config.read_transfers = control.circuit_read_hand_contents
    local stack_size = inserter.inserter_stack_size_override

    if stack_size > 0 then -- do not reset to default
        ml_config.stack_size = stack_size
    end

    if This.MiniLoader.spoiling then
        ml_config.spoil_priority = ml_config.nerf_mode and 'none' or inserter.inserter_spoil_priority
    else
        ml_config.spoil_priority = nil
    end

    self:updateFiltersFromInserter(ml_config, inserter)
end

---@param ml_config miniloader.Config
---@param inserter LuaEntity
---@param update boolean?
function Config:updateFiltersFromInserter(ml_config, inserter, update)
    if ml_config.nerf_mode or (inserter.filter_slot_count == 0) then
        ml_config.filter_mode = 'none'
        ml_config.filters = {}
        return
    end

    ml_config.filter_mode = inserter.use_filters and inserter.inserter_filter_mode or 'none'

    local filters = {}
    for i = 1, inserter.filter_slot_count, 1 do
        filters[i] = inserter.get_filter(i)
    end

    -- in update mode, only change the filters when there is actually a filter to set
    if not (update and table_size(filters) == 0) then
        ml_config.filters = filters
    end
end

---@param ml_config miniloader.Config
---@param loader LuaEntity
function Config:updateConfigFromLoader(ml_config, loader)
    assert(loader and loader.valid)

    local control = assert(loader.get_or_create_control_behavior()) --[[@as LuaLoaderControlBehavior ]]
    assert(control.valid)

    -- copy shared control keys over
    local default_config = get_default_config()
    for control_key in pairs(CONTROL_BEHAVIOR_KEYS) do
        if ml_config.nerf_mode then
            ml_config[control_key] = default_config[control_key]
        else
            ml_config[control_key] = control[control_key]
        end
    end

    -- remove fulfilled flag, otherwise comparing configs won't work
    ml_config.circuit_condition.fulfilled = nil
    ml_config.logistic_condition.fulfilled = nil

    ml_config.read_transfers = control.circuit_read_transfers
    local stack_size = loader.loader_belt_stack_size_override

    if stack_size > 0 then -- do not reset to default
        ml_config.stack_size = stack_size
    end

    self:updateFiltersFromLoader(ml_config, loader)
end

---@param ml_config miniloader.Config
---@param loader LuaEntity
function Config:updateFiltersFromLoader(ml_config, loader)
    if ml_config.nerf_mode or (loader.filter_slot_count == 0) then
        ml_config.filter_mode = 'none'
        ml_config.filters = {}
        return
    end

    ml_config.filter_mode = loader.loader_filter_mode

    local filters = {}
    for i = 1, loader.filter_slot_count, 1 do
        filters[i] = loader.get_filter(i)
    end
    ml_config.filters = filters
end

---@param ml_config miniloader.Config
---@param inserter LuaEntity
local function write_config_to_inserter(ml_config, inserter)
    if not (inserter and inserter.valid) then return end

    local control = assert(inserter.get_or_create_control_behavior()) --[[@as LuaInserterControlBehavior ]]
    if not control.valid then return end

    -- copy control attributes
    local default_config = get_default_config()
    for control_key in pairs(CONTROL_BEHAVIOR_KEYS) do
        if ml_config.nerf_mode then
            control[control_key] = default_config[control_key]
        else
            control[control_key] = ml_config[control_key]
        end
    end

    control.circuit_read_hand_contents = ml_config.read_transfers
    control.circuit_hand_read_mode = defines.control_behavior.inserter.hand_read_mode.pulse

    inserter.inserter_stack_size_override = inserter.prototype.bulk
        -- input loader has no GUI for stack size. Set to max so that any amount coming in is moved.
        and (ml_config.loader_type == 'input'
            and inserter.prototype.inserter_max_belt_stack_size
            or ml_config.stack_size)
        or 0 -- set to the default stack size, this is needed for some inserter speeds

    if This.MiniLoader.spoiling then
        inserter.inserter_spoil_priority = (ml_config.nerf_mode and 'none') or (ml_config.spoil_priority or 'none')
    else
        inserter.inserter_spoil_priority = 'none'
    end
end

---@param ml_config miniloader.Config
---@param loader LuaEntity
local function write_config_to_loader(ml_config, loader)
    if not (loader and loader.valid) then return end

    local control = assert(loader.get_or_create_control_behavior()) --[[@as LuaLoaderControlBehavior ]]
    if not control.valid then return end

    -- copy control attributes
    local default_config = get_default_config()
    for control_key in pairs(CONTROL_BEHAVIOR_KEYS) do
        if ml_config.nerf_mode then
            control[control_key] = default_config[control_key]
        else
            control[control_key] = ml_config[control_key]
        end
    end

    control.circuit_read_transfers = ml_config.read_transfers

    if loader.prototype.loader_adjustable_belt_stack_size then
        loader.loader_belt_stack_size_override = ml_config.stack_size
    end
end

-- Removes everything that is either on the loader on in the inserter hands. Try to push it into
-- source or destination container if available, otherwise spill on the ground.
---@param ml_entity miniloader.Data
function Config:flushEntities(ml_entity)
    -- worst case scenario: Sushi Belt (8 different stacks) on the loader, one stack per inserter
    local inventory = game.create_inventory(8 + table_size(ml_entity.inserters))

    ---@type defines.transport_line
    for idx = 1, ml_entity.loader.get_max_transport_line_index(), 1 do
        local transport_line = ml_entity.loader.get_transport_line(idx)
        for tl = 1, #transport_line, 1 do
            if transport_line[tl] then inventory.insert(transport_line[tl]) end
        end
        transport_line.clear()
    end

    for _, inserter in pairs(ml_entity.inserters) do
        if inserter.held_stack.count > 0 then
            inventory.insert(inserter.held_stack)
            inserter.held_stack.clear()
        end
    end

    inventory.sort_and_merge()

    if inventory.is_empty() then
        inventory.destroy()
        return
    end

    local container = ml_entity.loader.loader_container

    if not container then
        local back_area = Position(ml_entity.main.position):translate(ml_entity.config.direction, -1):expand_to_area(0.5)
        local entities = ml_entity.main.surface.find_entities_filtered {
            area = back_area,
            force = ml_entity.main.force,
        }

        for _, entity in pairs(entities) do
            if entity.get_inventory(defines.inventory.chest) then
                container = entity
                break
            end
        end
    end

    -- push as much as possible into the container (if any)
    if container and container.valid then
        local container_inventory = assert(container.get_inventory(defines.inventory.chest))
        for idx = 1, #inventory, 1 do
            local stack = inventory[idx]
            if stack.count > 0 then
                local inserted = container_inventory.insert(stack)
                if inserted >= stack.count then
                    stack.clear()
                else
                    stack.count = stack.count - inserted
                end
            end
        end
    end

    -- spill whatever is left: no container, or the container could not hold it all
    if not inventory.is_empty() then
        ml_entity.main.surface.spill_inventory {
            position = ml_entity.main.position,
            inventory = inventory,
            force = ml_entity.main.force,
            allow_belts = true,
        }
    end

    inventory.destroy()
end

---@param ml_entity miniloader.Data
local function update_filters(ml_entity)
    if ml_entity.config.filter_mode == ml_entity.state.filter_mode and table.compare(ml_entity.config.filters, ml_entity.state.filters) then return end

    local needs_flush = (ml_entity.state.filter_mode == 'none' and ml_entity.config.filter_mode ~= 'none')
        or (ml_entity.config.filter_mode == 'whitelist' and table_size(ml_entity.config.filters) == 0)
    if needs_flush then Config:flushEntities(ml_entity) end

    local has_filters = (not ml_entity.config.nerf_mode) and (ml_entity.loader.filter_slot_count > 0)

    -- loader

    for i = 1, ml_entity.loader.filter_slot_count, 1 do
        ml_entity.loader.set_filter(i, ml_entity.config.filters[i])
    end

    ml_entity.loader.loader_filter_mode = has_filters and ml_entity.config.filter_mode or 'none'

    -- inserters

    local use_filters = has_filters and (ml_entity.config.filter_mode ~= 'none') or false
    local inserter_filter_mode = use_filters and ml_entity.config.filter_mode or 'whitelist'

    for _, inserter in pairs(ml_entity.inserters) do
        inserter.use_filters = use_filters
        inserter.inserter_filter_mode = inserter_filter_mode

        for i = 1, inserter.filter_slot_count, 1 do
            inserter.set_filter(i, ml_entity.config.filters[i])
        end
    end

    ml_entity.state.filter_mode = ml_entity.config.filter_mode
    ml_entity.state.filters = util.copy(ml_entity.config.filters)
end

---@param ml_entity miniloader.Data
function Config:resyncEntities(ml_entity)
    --- resync inserters
    for _, inserter in pairs(ml_entity.inserters) do
        write_config_to_inserter(ml_entity.config, inserter)
    end

    write_config_to_loader(ml_entity.config, ml_entity.loader)

    update_filters(ml_entity)
end

--- Blueprints are deserialized from json and the set of keys may be deserialized
--- as strings. Turn them back into numbers.
---
---@param ml_config miniloader.Config?
function Config:sanitizeConfiguration(ml_config)
    if not (ml_config and ml_config.filters) then return end -- don't migrate old pre-1.0 entities here.

    local filters = {}
    for key, value in pairs(ml_config.filters) do
        local new_key = tonumber(key)
        if new_key then
            filters[new_key] = value
        end
    end

    ml_config.filters = filters
end

---@param entity LuaEntity
---@param ml_config miniloader.Config
function Config:configureFromInserter(entity, ml_config)
    ---@type miniloader.ModData
    local inserter_data = assert(prototypes.mod_data[const.name].data[entity.name])
    -- 240 is max speed for one lane
    ml_config.highspeed = inserter_data.speed_config.items_per_second > 240
    ml_config.nerf_mode = inserter_data.nerf_mode
end

---@param tag_value table<string, any>?
---@return miniloader.Config
function Config:readConfigFromTag(tag_value)
    assert(tag_value)
    local ml_config = util.copy(tag_value)

    if ml_config.inserter_config then
        -- pre-1.0 configuration
        for control_key in pairs(CONTROL_BEHAVIOR_KEYS) do
            ml_config[control_key] = ml_config.inserter_config[control_key]
            ml_config.inserter_config[control_key] = nil
        end

        if ml_config.inserter_config.filters then
            ml_config.filters = util.copy(ml_config.inserter_config.filters)
            ml_config.inserter_config.filters = nil
        end

        ml_config.read_transfers = ml_config.inserter_config.read_transfers or false
        ml_config.inserter_config.read_transfers = nil
        ml_config.filter_mode = ml_config.inserter_config.loader_filter_mode or 'none'
        ml_config.inserter_config.loader_filter_mode = nil

        if table_size(ml_config.inserter_config) > 0 then
            Framework.logger:logf('Dropping unknown pre-1.0 inserter_config keys: %s', serpent.line(ml_config.inserter_config))
        end
        ml_config.inserter_config = nil
    end

    -- sanitize all the config keys that are not common control behavior
    local default_config = get_default_config()

    for _, config_key in pairs(CONFIG_KEYS) do
        if ml_config[config_key] == nil then
            ml_config[config_key] = default_config[config_key]
        end
    end

    -- new config keys for 1.0 - sanitize all the control behavior keys
    for control_key in pairs(CONTROL_BEHAVIOR_KEYS) do
        if ml_config.nerf_mode or (ml_config[control_key] == nil) then
            ml_config[control_key] = default_config[control_key]
        end
    end

    -- remove fulfilled flag, otherwise comparing configs won't work
    ml_config.circuit_condition.fulfilled = nil
    ml_config.logistic_condition.fulfilled = nil

    -- finally fix the filters
    if ml_config.nerf_mode then ml_config.filters = {} end

    self:sanitizeConfiguration(ml_config)

    return ml_config
end

---@param ml_config miniloader.Config
---@param inserter BlueprintEntity.inserter
function Config:readConfigFromBlueprintInserter(ml_config, inserter)
    ---@type InserterBlueprintControlBehavior
    local control_behavior = inserter.control_behavior or {}

    -- copy blueprint control behavior attributes
    local default_config = get_default_config()
    for control_key, bp_key in pairs(CONTROL_BEHAVIOR_KEYS) do
        if ml_config.nerf_mode then
            ml_config[control_key] = default_config[control_key]
        else
            ml_config[control_key] = (control_behavior[bp_key] ~= nil) and control_behavior[bp_key] or default_config[control_key]
        end
    end

    -- remove fulfilled flag, otherwise comparing configs won't work
    ml_config.circuit_condition.fulfilled = nil
    ml_config.logistic_condition.fulfilled = nil

    if This.MiniLoader.spoiling then
        ml_config.spoil_priority = ml_config.nerf_mode and 'none' or FIX_SPOIL_PRIO[inserter.spoil_priority]
    else
        ml_config.spoil_priority = nil
    end

    if ml_config.nerf_mode then
        ml_config.filter_mode = 'none'
        ml_config.filters = {}
        return
    end

    ml_config.filter_mode = (inserter.use_filters and (inserter.filter_mode or 'whitelist')) or 'none'

    local filters = {}
    if inserter.filters then
        for _, filter in pairs(inserter.filters) do
            filters[filter.index] = {
                name = filter.name,
                quality = filter.quality,
                comparator = filter.comparator,
            }
        end
        ml_config.filters = filters
    end
end

return Config
