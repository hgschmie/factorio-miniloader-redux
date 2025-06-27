---@meta
------------------------------------------------------------------------
-- Loader templates
------------------------------------------------------------------------

local util = require('util')
local const = require('lib.constants')

local template = {}

local supported_mods = {
    ['space-age'] = 'space_age',
    ['matts-logistics'] = 'matt',
}

local game_mode = {}
for mod_name, name in pairs(supported_mods) do
    if mods[mod_name] then
        game_mode[name] = true
    end
end

local space_age = game_mode.space_age and true or false
-- highest available loader tier in the base / space age game
local max_loader = space_age and 'turbo' or 'express'

---@param data table<string, any>
local function select_data(data)
    for name in pairs(game_mode) do
        -- mod + space age?
        if space_age then
            local sa_name = name .. '_space_age'
            if data[sa_name] then return data[sa_name] end
        end
        -- just mod?
        if data[name] then return data[name] end
    end
    -- when an inserter tier is under a condition switch, then
    -- the data must exist under that condition (e.g. for mod 'xxx', the
    -- data must have an 'xxx' key). Otherwise, it will fall back to base which
    -- may not exist
    assert(data.base, 'base data does not exist.')
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
                ingredients = function()
                    return select_data {
                        base = {
                            { type = 'item', name = 'underground-belt', amount = 1 },
                            { type = 'item', name = 'steel-plate',      amount = 4 },
                            { type = 'item', name = 'inserter',         amount = 4 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        base = { 'logistics', 'steel-processing', 'electronics' },
                    }
                end,
            }
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
                ingredients = function()
                    return select_data {
                        base = {
                            { type = 'item', name = const:name_from_prefix(''), amount = 1 },
                            { type = 'item', name = 'fast-underground-belt',    amount = 1 },
                            { type = 'item', name = 'fast-inserter',            amount = 2 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        base = { 'logistics-2', const:name_from_prefix(''), },
                    }
                end,
            }
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
                ingredients = function()
                    return select_data {
                        base = {
                            { type = 'item', name = const:name_from_prefix('fast'), amount = 1 },
                            { type = 'item', name = 'express-underground-belt',     amount = 1 },
                            { type = 'item', name = 'fast-inserter',                amount = 4 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        base = { 'logistics-3', const:name_from_prefix('fast'), },
                    }
                end,
            }
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
                ingredients = function()
                    return select_data {
                        base = {
                            { type = 'item', name = const:name_from_prefix('express'), amount = 1 },
                            { type = 'item', name = 'turbo-underground-belt',          amount = 1 },
                            { type = 'item', name = 'bulk-inserter',                   amount = 4 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        space_age = { 'turbo-transport-belt', 'metallurgic-science-pack', const:name_from_prefix('express'), },
                    }
                end,
            }
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
                belt_tier = 'turbo',
                ingredients = function()
                    return select_data {
                        base = {
                            { type = 'item', name = const:name_from_prefix('turbo'), amount = 1 },
                            { type = 'item', name = 'turbo-underground-belt',        amount = 1 },
                            { type = 'item', name = 'stack-inserter',                amount = 2 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        space_age = { 'logistics-3', 'stack-inserter', const:name_from_prefix('turbo'), },
                    }
                end,
            }
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
                belt_tier = '',
                nerf_mode = true,
                ingredients = function()
                    return select_data {
                        base = {
                            { type = 'item', name = 'transport-belt',  amount = 1 },
                            { type = 'item', name = 'iron-plate',      amount = 4 },
                            { type = 'item', name = 'burner-inserter', amount = 2 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        base = { 'logistics' },
                    }
                end,
            }
        end,
    },

    -- =================================================
    -- == Matt's logistics
    -- =================================================

    ['ultra-fast'] = {
        condition = function()
            return game_mode.matt and true or false
        end,
        data = function()
            local previous = space_age and 'turbo' or 'express'

            return {
                order = 'd[b]-a',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('2ac217'),
                speed = data.raw['transport-belt']['ultra-fast-transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
                loader_tier = max_loader, -- animations, explosion etc.
                variant = 'matt',
                ingredients = function()
                    return select_data {
                        matt = {
                            { type = 'item', name = const:name_from_prefix(previous), amount = 2 },
                            { type = 'item', name = previous .. '-underground-belt',  amount = 2 },
                            { type = 'item', name = 'bulk-inserter',                  amount = 4 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        matt = { 'logistics-4', const:name_from_prefix(previous), },
                    }
                end,
            }
        end,
    },
    ['extreme-fast'] = {
        condition = function()
            return game_mode.matt and true or false
        end,
        data = function()
            local previous = 'ultra-fast'

            return {
                order = 'd[b]-a',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('c34722'),
                speed = data.raw['transport-belt']['extreme-fast-transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
                loader_tier = max_loader, -- animations, explosion etc.
                variant = 'matt',
                ingredients = function()
                    return select_data {
                        matt = {
                            { type = 'item', name = const:name_from_prefix(previous), amount = 2 },
                            { type = 'item', name = previous .. '-underground-belt',  amount = 2 },
                            { type = 'item', name = 'bulk-inserter',                  amount = 8 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        matt = { 'logistics-5', const:name_from_prefix(previous), },
                    }
                end,
            }
        end,
    },
    ['ultra-express'] = {
        condition = function()
            return game_mode.matt and true or false
        end,
        data = function()
            local previous = 'extreme-fast'

            return {
                order = 'd[b]-a',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('5a17c2'),
                speed = data.raw['transport-belt']['ultra-express-transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
                loader_tier = max_loader, -- animations, explosion etc.
                variant = 'matt',
                ingredients = function()
                    return select_data {
                        matt = {
                            { type = 'item', name = const:name_from_prefix(previous), amount = 4 },
                            { type = 'item', name = previous .. '-underground-belt',  amount = 2 },
                            { type = 'item', name = 'bulk-inserter',                  amount = 8 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        matt = { 'logistics-6', const:name_from_prefix(previous), },
                    }
                end,
            }
        end,
    },
    ['extreme-express'] = {
        condition = function()
            return game_mode.matt and true or false
        end,
        data = function()
            local previous = 'ultra-express'

            return {
                order = 'd[b]-a',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('1146d4'),
                speed = data.raw['transport-belt']['extreme-express-transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
                loader_tier = max_loader, -- animations, explosion etc.
                variant = 'matt',
                ingredients = function()
                    return select_data {
                        matt = {
                            { type = 'item', name = const:name_from_prefix(previous), amount = 4 },
                            { type = 'item', name = previous .. '-underground-belt',  amount = 4 },
                            { type = 'item', name = 'bulk-inserter',                  amount = 8 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        matt = { 'logistics-7', const:name_from_prefix(previous), },
                    }
                end,
            }
        end,
    },
    ['ultimate'] = {
        condition = function()
            return game_mode.matt and true or false
        end,
        data = function()
            local previous = 'extreme-express'

            return {
                order = 'd[b]-a',
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('a6a6a6'),
                speed = data.raw['transport-belt']['ultimate-transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
                loader_tier = max_loader, -- animations, explosion etc.
                variant = 'matt',
                ingredients = function()
                    return select_data {
                        matt = {
                            { type = 'item', name = const:name_from_prefix(previous), amount = 1 },
                            { type = 'item', name = previous .. '-underground-belt',  amount = 1 },
                            { type = 'item', name = 'bulk-inserter',                  amount = 2 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        matt = { 'logistics-8', const:name_from_prefix(previous), },
                    }
                end,
            }
        end,
    },
}

template.game_mode = game_mode

return template
