------------------------------------------------------------------------
-- data phase 2
------------------------------------------------------------------------

require('lib.init')

------------------------------------------------------------------------

local util = require('util')

local const = require('lib.constants')

-- all loaders are templated
local templates = require('prototypes.templates')
local functions = require('prototypes.functions')

local upgrades = {}

for prefix, loader_definition in pairs(templates.loaders) do
    assert(loader_definition.condition)
    if (loader_definition.condition()) then
        local dash_prefix = functions.compute_dash_prefix(prefix)
        ---@type miniloader.LoaderTemplate
        local params = util.copy(loader_definition.data(dash_prefix))
        params.prefix = prefix
        params.name = const:with_prefix(dash_prefix .. const.name)
        params.localised_name = params.localised_name and params.localised_name or { 'entity-name.' .. params.name }
        if params.upgrade_from then
            upgrades[params.upgrade_from] = params.name
        end

        -- create per-loader items
        functions.create_item(params)
        functions.create_entity(params)
        functions.create_recipe(params)
    end
end

for upgrade, target in pairs(upgrades) do
    local previous_tier = data.raw['inserter'][upgrade]
    if previous_tier then
        assert(previous_tier.next_upgrade == nil)
        previous_tier.next_upgrade = target
    end
end

------------------------------------------------------------------------

Framework.post_data_updates_stage()
