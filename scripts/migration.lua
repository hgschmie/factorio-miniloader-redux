---@meta
--------------------------------------------------------------------------------
-- loader migration
--------------------------------------------------------------------------------

local util = require('util')

local Position = require('stdlib.area.position')
local Is = require('stdlib.utils.is')

local const = require('lib.constants')

---@class miniloader.Migrations
---@field ml_entities LuaEntityPrototype[]
---@field migrations table<string, LuaEntityPrototype>
---@field blueprint_migrations table<string, LuaEntityPrototype>
---@field stats table<string, integer>
local Migrations = {
    ml_entities = {},
    migrations = {},
    blueprint_migrations = {},
    stats = {},
}

for prefix, migration in pairs(const:migrations()) do
    local name = prefix .. 'miniloader-inserter'
    local blueprint_name = prefix .. 'miniloader'
    local entity = prototypes.entity[name]
    assert(entity)
    table.insert(Migrations.ml_entities, entity)
    Migrations.migrations[name] = migration
    Migrations.blueprint_migrations[blueprint_name] = migration
end

---@param src LuaEntity
---@param dst LuaEntity
local function copy_wire_connections(src, dst)
    for wire_connector_id, wire_connector in pairs(src.get_wire_connectors(true)) do
        local dst_connector = dst.get_wire_connector(wire_connector_id, true)
        for _, connection in pairs(wire_connector.connections) do
            if connection.origin == defines.wire_origin.player then
                dst_connector.connect_to(connection.target, false, connection.origin)
            end
        end
    end
end

---@param surface LuaSurface
---@param loader LuaEntity
local function migrate_loader(surface, loader)
    if not Is.Valid(loader) then return end
    local entities_to_delete = surface.find_entities(Position(loader.position):expand_to_area(0.5))

    for _, entity_to_delete in pairs(entities_to_delete) do
        -- remove anything that can not migrated. This kills the loader and the container
        if not Migrations.migrations[entity_to_delete.name] then
            entity_to_delete.destroy()
        end
    end

    -- create new main entity in the same spot
    local main = surface.create_entity {
        name = Migrations.migrations[loader.name],
        position = loader.position,
        direction = loader.direction,
        quality = loader.quality,
        force = loader.force,
        create_build_effect_smoke = false,
        move_stuck_players = true,
    }

    assert(main)

    -- add the loader and additional inserters. The loader will be fine as the old
    -- loader has already been deleted
    local ml_entity = This.MiniLoader:setup(main)

    -- pull the config out of the loader that is migrating
    This.MiniLoader:syncInserterConfig(ml_entity, loader)

    copy_wire_connections(loader, main)

    -- reconfigure the loaer. This syncs the configuration across all the
    -- inserters and reorients loader and inserters
    This.MiniLoader:reconfigure(ml_entity)

    Migrations.stats[loader.name] = (Migrations.stats[loader.name] or 0) + 1

    -- kill everything else that was found in this spot. This removes
    -- all of the old inserters
    for _, entity_to_delete in pairs(entities_to_delete) do
        if Is.Valid(entity_to_delete) then
            entity_to_delete.destroy()
        end
    end
end

function Migrations:migrate_miniloaders()
    for _, surface in pairs(game.surfaces) do
        Migrations.stats = {}

        local loaders = surface.find_entities_filtered {
            name = Migrations.ml_entities,
        }

        for _, loader in pairs(loaders) do
            migrate_loader(surface, loader)
        end

        local stats = ''
        local total = 0
        for name, count in pairs(Migrations.stats) do
            stats = stats .. ('%s: %s'):format(name, count)
            total = total + count
            if next(Migrations.stats, name) then
                stats = stats .. ', '
            end
        end
        if total > 0 then
            game.print { const:locale('migration'), total, surface.name, stats }
        end
    end
end

---@param blueprint LuaRecord
local function migrate_blueprint(blueprint)
    if blueprint.type == 'blueprint-book' then
        for _, nested_blueprint in pairs(blueprint.contents) do
            migrate_blueprint(nested_blueprint)
        end
        return
    end

    if blueprint.type ~= 'blueprint' then return end

    for _, default_icon in pairs(blueprint.default_icons) do
        if (default_icon.signal.type == nil or default_icon.signal.type == 'item') and Migrations.blueprint_migrations[default_icon.signal.name] then
            default_icon.signal.name = Migrations.blueprint_migrations[default_icon.signal.name]
        end
    end

    local dirty = false

    local blueprint_entities = blueprint.get_blueprint_entities()
    if not blueprint_entities then return end

    for i = 1, blueprint.get_blueprint_entity_count() do
        local blueprint_entity = blueprint_entities[i]

        if Migrations.migrations[blueprint_entity.name] then
            local new_entity = util.copy(blueprint_entity)
            new_entity.name = Migrations.migrations[blueprint_entity.name]
            blueprint_entities[i] = new_entity
            dirty = true
        end
    end

    if dirty then
        blueprint.set_blueprint_entities(blueprint_entities)
    end
end

function Migrations:migrate_game_blueprints()
    for _, blueprint in pairs(game.blueprints) do
        migrate_blueprint(blueprint)
    end
end

return Migrations
