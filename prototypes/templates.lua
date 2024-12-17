---@meta
------------------------------------------------------------------------
-- Loader templates
------------------------------------------------------------------------

---@type table<string, miniloader.LoaderTemplate>
local templates = {
    -- regular miniloader, base game
    [''] = {
        order = 'd[a]-a',
        subgroup = 'belt',
        stack_size = 50,
        tint = util.color('ffc340d9'),
        speed = data.raw['transport-belt']['transport-belt'].speed,
    },
    -- fast miniloader, base game
    ['fast'] = {
        order = 'd[a]-b',
        subgroup = 'belt',
        stack_size = 50,
        tint = util.color('e31717d9'),
        speed = data.raw['transport-belt']['fast-transport-belt'].speed,
    },
    -- express miniloader, base game
    ['express'] = {
        order = 'd[a]-c',
        subgroup = 'belt',
        stack_size = 50,
        tint = util.color('43c0fad9'),
        speed = data.raw['transport-belt']['express-transport-belt'].speed,
    }
}


-- upgrades between the different loader types
---@type table<string, string>
local upgrades = {
    [''] = 'fast',
    ['fast'] = 'express',
}

return { templates, upgrades }
