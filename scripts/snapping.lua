---@meta
------------------------------------------------------------------------
-- snapping logic
------------------------------------------------------------------------

local Event = require('stdlib.event.event')
local Is = require('stdlib.utils.is')
local Area = require('stdlib.area.area')
local Position = require('stdlib.area.position')
local Direction = require('stdlib.area.direction')

local const = require('lib.constants')

local tools = require('framework.tools')

---@param entity LuaEntity
---@return 'input'|'output'|nil
local function get_loader_type(entity)
    if entity.type == 'loader' or entity.type == 'loader-1x1' then return entity.loader_type end
    if entity.type == 'underground-belt' then return entity.belt_to_ground_type end
    if entity.type == 'linked-belt' then return entity.linked_belt_type end
    return nil
end

---@param entity LuaEntity
---@return boolean
local function is_vertical_aligned(entity)
    return entity.direction == defines.direction.north or entity.direction == defines.direction.south
end

---@param entity LuaEntity
---@return boolean
local function is_horizontal_aligned(entity)
    return entity.direction == defines.direction.west or entity.direction == defines.direction.east
end

---@param entity1 LuaEntity
---@param entity2 LuaEntity
---@return boolean
local function are_aligned(entity1, entity2)
    return is_vertical_aligned(entity1) ~= is_horizontal_aligned(entity2)
end

---@param loader LuaEntity
---@param loader_type 'input'|'output'
local function to_loader_type(loader, loader_type)
    if loader.loader_type ~= loader_type then
        loader.loader_type = loader_type
    end
end

---@param loader_type 'input'|'output'
---@return 'input'|'output'
local function reverse_loader_type(loader_type)
    return loader_type == 'input' and 'output' or 'input'
end

-- set loader direction according to the entity in front. Unlike other snapping code,
-- this only considers the entity in front of the loader
--
-- loader snaps to
--  - a belt off direction - switch loader to output
--  - a belt in direction - align loader with belt
--  - an entity in direction - check the direction of the entity, align with direction
--
---@param loader LuaEntity
---@param entity LuaEntity
---
local function snap_loader_to_target(loader, entity)
    if not (Is.Valid(entity) and Is.Valid(loader)) then return end
    if not const.snapping_types[entity.type] then return end

    if not are_aligned(loader, entity) then
        if entity.type ~= 'transport-belt' then return end

        -- if the loader points at a transport belt, make it output to the belt
        return to_loader_type(loader, 'output')
    else
        -- is the thing that we point at some sort of directional object
        local entity_loader_type = get_loader_type(entity)
        if entity_loader_type then return to_loader_type(loader, reverse_loader_type(entity_loader_type)) end

        -- something without loader_type, e.g. a belt
        -- if the direction is the same, do nothing, otherwise flip the loader type
        if loader.direction ~= entity.direction then
            loader.loader_type = reverse_loader_type(loader.loader_type)
        end
    end
end

-- returns loaders next to a given entity
---@param entity LuaEntity
---@return (LuaEntity[]) loaders
local function find_loader_by_entity(entity)
    local area = Area(entity.prototype.selection_box):offset(entity.position):expand(1)

    if Framework.settings:runtime_setting('debug_mode') then
        rendering.draw_rectangle {
            color = { r = 1, g = 0.5, b = 0.5 },
            surface = entity.surface,
            left_top = area.left_top,
            right_bottom = area.right_bottom,
            time_to_live = 10,
        }
    end

    return entity.surface.find_entities_filtered {
        type = const.supported_type_names,
        name = storage.supported_loader_names,
        area = area,
        force = entity.force
    }
end

---@param loader LuaEntity The loader to check
---@param direction defines.direction? Direction override
---@return LuaEntity? An entity that may influence the loader direction
local function find_neighbor_entity(loader, direction)
    direction = direction or loader.direction

    -- if the loader is "input", the directions are actually reversed
    local offset = loader.loader_type == 'input' and -1 or 1

    -- find area to look at
    local area = Area { { -0.5, -0.5 }, { 0.5, 0.5 } }:offset(Position(loader.position)):translate(direction, offset)

    if Framework.settings:runtime_setting('debug_mode') then
        rendering.draw_rectangle {
            color = { r = 0.5, g = 0.5, b = 1 },
            surface = loader.surface,
            left_top = area.left_top,
            right_bottom = area.right_bottom,
            time_to_live = 10,
        }
    end

    local entities = loader.surface.find_entities_filtered {
        type = const.snapping_type_names,
        area = area,
        force = loader.force,
    }

    return #entities > 0 and entities[1] or nil
end

---@param loader LuaEntity
---@param entity LuaEntity?
local function snap_to_neighbor(loader, entity)
    local neighbor = find_neighbor_entity(loader)
    if neighbor and (not entity or (entity.unit_number == neighbor.unit_number)) then
        return snap_loader_to_target(loader, neighbor)
    end

    -- now look at back unit, if no front unit found
    neighbor = find_neighbor_entity(loader, Direction.opposite(loader.direction))
    if neighbor and (not entity or (entity.unit_number == neighbor.unit_number)) then
        return snap_loader_to_target(loader, neighbor)
    end
end

local function update_neighbor_loaders(entity)
    if not Is.Valid(entity) then return end
    assert(entity)

    local loaders = find_loader_by_entity(entity)
    for _, loader in pairs(loaders) do
        snap_to_neighbor(loader)
    end
end

-- called when entity was rotated or non loader was built
---@param entity LuaEntity
local function update_loaders(entity)
    if not const.snapping_types[entity.type] then return end
    update_neighbor_loaders(entity)

    if entity.type == 'underground-belt' then
        update_neighbor_loaders(entity.neighbours)
    elseif entity.type == 'linked-belt' then
        update_neighbor_loaders(entity.linked_belt_neighbour)
    end
end

--------------------------------------------------------------------------------
-- entity rotation
--------------------------------------------------------------------------------

local function onRotatedEntity(event)
    if not Framework.settings:runtime_setting('loader_snapping') then return end
    local entity = event.entity

    if not Is.Valid(entity) then return end

    assert(entity)
    -- don't snap when the miniloader is rotated, otherwise it will never rotate again
    if This.MiniLoader:is_supported(entity) then return end

    update_loaders(entity)
end

--------------------------------------------------------------------------------
-- entity creation
--------------------------------------------------------------------------------

local function onEntityCreated(event)
    if not Framework.settings:runtime_setting('loader_snapping') then return end
    local entity = event.entity

    if not Is.Valid(entity) then return end
    assert(entity)

    -- is it a supported loader?
    if This.MiniLoader:is_supported(entity) then
        snap_to_neighbor(entity)
    else
        update_loaders(entity)
    end
end

local ml_entity_filter = tools.create_event_entity_matcher('name', This.MiniLoader.supported_loader_names)

-- Event.on_event(tools.CREATION_EVENTS, onEntityCreated, ml_entity_filter)

-- Event.on_event(defines.events.on_player_rotated_entity, onRotatedEntity, ml_entity_filter)
