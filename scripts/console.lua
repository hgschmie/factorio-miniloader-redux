--------------------------------------------------------------------------------
-- custom commands
--------------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Is = require('stdlib.utils.is')

local const = require('lib.constants')

--------------------------------------------------------------------------------

---@param unit_number integer
---@param ml_entity miniloader.Data
local function check_valid(unit_number, ml_entity)
    if not (ml_entity and Is.Valid(ml_entity.main)) then return false end

    if unit_number ~= ml_entity.main.unit_number then return false end

    if not Is.Valid(ml_entity.loader) then return false end

    for _, inserter in pairs(ml_entity.inserters) do
        if not Is.Valid(inserter) then return false end
    end
    return true
end

---@param data CustomCommandData
local function inspect_miniloaders(data)
    local all = {
        miniloader = {},
        loader = {},
        inserter = {},
    }

    local invalid = {
        miniloader = 0,
        loader = 0,
        inserter = 0,
    }

    local removed = {
        entity = 0,
        miniloader = 0,
        loader = 0,
        inserter = 0,
    }


    ---@param list LuaEntity[]
    ---@param type string
    local function insert(list, type)
        for _, entity in pairs(list) do
            if entity.valid then
                all[type][entity.unit_number] = entity
            else
                invalid[type] = invalid[type] + 1
            end
        end
    end

    for _, surface in pairs(game.surfaces) do
        insert(surface.find_entities_filtered {
            name = const.supported_type_names,
            type = 'inserter',
        }, 'miniloader')

        insert(surface.find_entities_filtered {
            name = const.supported_loader_names,
            type = 'loader-1x1',
        }, 'loader')

        insert(surface.find_entities_filtered {
            name = const.supported_inserter_names,
            type = 'inserter',
        }, 'inserter')
    end

    for unit_number, ml_entity in pairs(This.MiniLoader:entities()) do
        if not check_valid(unit_number, ml_entity) then
            This.MiniLoader:destroy(unit_number)
            if ml_entity.main and ml_entity.main.valid then
                ml_entity.main.destroy()
            end

            removed.entity = removed.entity + 1
        else
            -- miniloader is valid. Remove innards from the the set of found entities
            all.miniloader[ml_entity.main.unit_number] = nil
            all.loader[ml_entity.loader.unit_number] = nil
            for i = 2, #ml_entity.inserters do
                all.inserter[ml_entity.inserters[i].unit_number] = nil
            end
        end
    end

    for _, type in pairs { 'miniloader', 'loader', 'inserter' } do
        for _, entity in pairs(all[type]) do
            entity.destroy()
            removed[type] = removed[type] + 1
        end
    end

    game.print { const:locale('command_inspect_miniloaders_invalid'), invalid.miniloader, invalid.loader, invalid.inserter }
    game.print { const:locale('command_inspect_miniloaders_removed'), removed.miniloader, removed.loader, removed.inserter, removed.entity }
end

local function register_commands()
    commands.add_command('inspect-miniloaders', { const:locale('command_inspect_miniloaders') }, inspect_miniloaders)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_init()
    register_commands()
end

local function on_load()
    register_commands()
end

Event.on_init(on_init)
Event.on_load(on_load)
