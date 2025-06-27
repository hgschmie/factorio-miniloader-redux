---@meta
------------------------------------------------------------------------
-- Loader templates
------------------------------------------------------------------------

local util = require('util')
local const = require('lib.constants')

local template = {}

local supported_mods = {
    ['space-age'] = 'space_age',
}

local game_mode = {}
for mod_name, name in pairs(supported_mods) do
    if mods[mod_name] then
        game_mode[name] = true
    end
end

---@param data table<string, any>
local function select_data(data)
    for _, mode in pairs(game_mode) do
        if data[mode] then return data[mode] end
    end
    return data.base
end


---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    -- regular miniloader, base game
    [''] = {
        condition = function() return true end,
        data = function()
            return {
                order = 'd[a]-b',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('ffc340d9'),
                speed = data.raw['transport-belt']['transport-belt'].speed,
                upgrade_from = const:name_from_prefix('chute'),
            }
        end,
        ingredients = function()
            return select_data({
                base = {
                    { type = 'item', name = 'underground-belt', amount = 1 },
                    { type = 'item', name = 'steel-plate',      amount = 4 },
                    { type = 'item', name = 'inserter',         amount = 4 },
                },
            })
        end,
        prerequisites = function()
            return select_data({
                base = { 'logistics', 'steel-processing', 'electronics' },
                space_age = {},
            })
        end,
    },
    -- fast miniloader, base game
    ['fast'] = {
        condition = function() return true end,
        data = function()
            return {
                order = 'd[a]-c',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('e31717d9'),
                speed = data.raw['transport-belt']['fast-transport-belt'].speed,
                upgrade_from = const:name_from_prefix(''),
            }
        end,
        ingredients = function()
            return select_data({
                base = {
                    { type = 'item', name = const:name_from_prefix(''), amount = 1 },
                    { type = 'item', name = 'fast-underground-belt',    amount = 1 },
                    { type = 'item', name = 'fast-inserter',            amount = 2 },
                },
            })
        end,
        prerequisites = function()
            return select_data({
                base = { 'logistics-2', const:name_from_prefix(''), },
                space_age = {},
            })
        end,
    },
    -- express miniloader, base game
    ['express'] = {
        condition = function() return true end,
        data = function()
            return {
                order = 'd[a]-d',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('43c0fad9'),
                speed = data.raw['transport-belt']['express-transport-belt'].speed,
                upgrade_from = const:name_from_prefix('fast'),
            }
        end,
        ingredients = function()
            return select_data({
                base = {
                    { type = 'item', name = const:name_from_prefix('fast'), amount = 1 },
                    { type = 'item', name = 'express-underground-belt',     amount = 1 },
                    { type = 'item', name = 'fast-inserter',                amount = 4 },
                },
            })
        end,
        prerequisites = function()
            return select_data({
                base = { 'logistics-3', const:name_from_prefix('fast'), },
                space_age = {},
            })
        end,
    },

    -- turbo miniloader, space age game
    ['turbo'] = {
        condition = function()
            return game_mode.space_age and true or false
        end,
        data = function()
            return {
                order = 'd[a]-e',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('A8D550d9'),
                speed = data.raw['transport-belt']['turbo-transport-belt'].speed,
                upgrade_from = const:name_from_prefix('express'),
            }
        end,
        ingredients = function()
            return select_data({
                base = {
                    { type = 'item', name = const:name_from_prefix('express'), amount = 1 },
                    { type = 'item', name = 'turbo-underground-belt',          amount = 1 },
                    { type = 'item', name = 'bulk-inserter',                   amount = 4 },
                },
            })
        end,
        prerequisites = function()
            return select_data({
                base = { 'turbo-transport-belt', 'metallurgic-science-pack', const:name_from_prefix('express'), },
            })
        end,
    },

    -- stack miniloader, space age game
    ['stack'] = {
        condition = function()
            return game_mode.space_age and true or false
        end,
        data = function()
            return {
                order = 'd[a]-f',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('ffffffd9'),
                speed = data.raw['transport-belt']['turbo-transport-belt'].speed,
                bulk = true,
                upgrade_from = const:name_from_prefix('turbo'),
                loader_tier = 'turbo', -- use turbo animations, explosion etc.
            }
        end,
        ingredients = function()
            return select_data({
                base = {
                    { type = 'item', name = const:name_from_prefix('turbo'), amount = 1 },
                    { type = 'item', name = 'turbo-underground-belt',        amount = 1 },
                    { type = 'item', name = 'stack-inserter',                amount = 2 },
                },
            })
        end,
        prerequisites = function()
            return select_data({
                base = { 'logistics-3', 'stack-inserter', const:name_from_prefix('turbo'), },
            })
        end,
    },

    -- gravity assisted chute loader
    ['chute'] = {
        condition = function()
            return Framework.settings:startup_setting(const.settings_names.chute_loader) and true or false
        end,
        data = function()
            return {
                order = 'd[a]-a',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('999999d9'),
                speed = data.raw['transport-belt']['transport-belt'].speed / 4,
                energy_source = { type = 'void' },
                research_trigger = {
                    type = 'craft-item', item = 'iron-gear-wheel', count = 100,
                },
                loader_tier = '', -- use basic belt animation
                nerf_mode = true,
            }
        end,
        ingredients = function()
            return select_data({
                base = {
                    { type = 'item', name = 'transport-belt',  amount = 1 },
                    { type = 'item', name = 'iron-plate',      amount = 4 },
                    { type = 'item', name = 'burner-inserter', amount = 2 },
                },
            })
        end,
        prerequisites = function()
            return select_data({
                base = { 'logistics' },
                space_age = {},
            })
        end,
    },
}

template.game_mode = game_mode

return template
