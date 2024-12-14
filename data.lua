------------------------------------------------------------------------
-- data phase 1
------------------------------------------------------------------------

require('lib.init')('data')

local const = require('lib.constants')

-- all loaders are templated
local templates, upgrades = table.unpack(require('prototypes.templates'))
local functions = require('prototypes.functions')

for prefix, loader_definition in pairs(templates) do
    -- if a condition is present, it must return true
    if loader_definition.condition and loader_definition.condition() or true then
        local params = util.copy(loader_definition)
        params.prefix = prefix
        params.name = const:name_from_prefix(params.prefix)
        params.localised_name = params.localised_name and params.localised_name or { 'entity-name.' .. params.name }

        params.next_upgrade = params.next_upgrade or const:name_from_prefix(upgrades[params.prefix])

        -- create per-loader items
        functions.create_item(params)
        functions.create_entity(params)
    end
end

------------------------------------------------------------------------

------------------------------------------------------------------------
require('framework.other-mods').data()
