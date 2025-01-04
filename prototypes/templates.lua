---@meta
------------------------------------------------------------------------
-- Loader templates
------------------------------------------------------------------------

local util = require('util')

local const = require('lib.constants')

---@type table<string, miniloader.LoaderDefinition>
local templates = {
    -- regular miniloader, base game
    [''] = {
        data = function()
            return {
                order = 'd[a]-b',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('ffc340d9'),
                speed = data.raw['transport-belt']['transport-belt'].speed,
                ingredients = {
                    { type = 'item', name = 'underground-belt', amount = 1 },
                    { type = 'item', name = 'steel-plate',      amount = 4 },
                    { type = 'item', name = 'inserter',         amount = 4 },
                },
                prerequisites = { 'logistics', 'steel-processing', 'electronics' },
                upgrade_from = const:name_from_prefix('chute'),
            }
        end,
    },
    -- fast miniloader, base game
    ['fast'] = {
        data = function()
            return {
                order = 'd[a]-c',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('e31717d9'),
                speed = data.raw['transport-belt']['fast-transport-belt'].speed,
                ingredients = {
                    { type = 'item', name = const:name_from_prefix(''), amount = 1 },
                    { type = 'item', name = 'fast-underground-belt',    amount = 1 },
                    { type = 'item', name = 'fast-inserter',            amount = 2 },
                },
                prerequisites = { 'logistics-2', const:name_from_prefix(''), },
                upgrade_from = const:name_from_prefix(''),
            }
        end,
    },
    -- express miniloader, base game
    ['express'] = {
        data = function()
            return {
                order = 'd[a]-d',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('43c0fad9'),
                speed = data.raw['transport-belt']['express-transport-belt'].speed,
                ingredients = {
                    { type = 'item', name = const:name_from_prefix('fast'), amount = 1 },
                    { type = 'item', name = 'express-underground-belt',     amount = 1 },
                    { type = 'item', name = 'fast-inserter',                amount = 4 },
                },
                prerequisites = { 'logistics-3', const:name_from_prefix('fast'), },
                upgrade_from = const:name_from_prefix('fast'),
            }
        end,
    },

    -- turbo miniloader, space age game
    ['turbo'] = {
        condition = function()
            return mods['space-age'] and true or false
        end,
        data = function()
            return {
                order = 'd[a]-e',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('A8D550d9'),
                speed = data.raw['transport-belt']['turbo-transport-belt'].speed,
                ingredients = {
                    { type = 'item', name = const:name_from_prefix('express'), amount = 1 },
                    { type = 'item', name = 'turbo-underground-belt',          amount = 1 },
                    { type = 'item', name = 'bulk-inserter',                   amount = 4 },
                },
                prerequisites = { 'logistics-3', 'metallurgic-science-pack', const:name_from_prefix('express'), },
                upgrade_from = const:name_from_prefix('express'),
            }
        end,
    },

    -- stack miniloader, space age game
    ['stack'] = {
        condition = function()
            return mods['space-age'] and true or false
        end,
        data = function()
            return {
                order = 'd[a]-f',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('ffffffd9'),
                speed = data.raw['transport-belt']['turbo-transport-belt'].speed,
                ingredients = {
                    { type = 'item', name = const:name_from_prefix('turbo'), amount = 1 },
                    { type = 'item', name = 'turbo-underground-belt',        amount = 1 },
                    { type = 'item', name = 'stack-inserter',                amount = 2 },
                },
                prerequisites = { 'logistics-3', 'stack-inserter', const:name_from_prefix('turbo'), },
                bulk = true,
                upgrade_from = const:name_from_prefix('turbo'),
            }
        end,
    },

    -- gravity assisted chute loader
    ['chute'] = {
        condition = function()
            return Framework.settings:startup_setting('chute_loader') and true or false
        end,
        data = function()
            return {
                order = 'd[a]-a',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('999999d9'),
                speed = data.raw['transport-belt']['transport-belt'].speed / 4,
                energy_source = { type = 'void' },
                ingredients = {
                    { type = 'item', name = 'transport-belt',  amount = 1 },
                    { type = 'item', name = 'iron-plate',      amount = 4 },
                    { type = 'item', name = 'burner-inserter', amount = 2 },
                },
                prerequisites = { 'logistics' },
                research_trigger = {
                    type = 'craft-item', item = 'iron-gear-wheel', count = 100,
                },
                loader_tier = '', -- use basic belt animation
                disable_filters = true,
            }
        end,
    },
}

return { templates }
