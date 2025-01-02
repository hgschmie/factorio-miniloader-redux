------------------------------------------------------------------------
-- data phase 3
------------------------------------------------------------------------

local const = require('lib.constants')
local collision_mask_util = require('collision-mask-util')

require 'circuit-connector-generated-definitions'
require 'circuit-connector-sprites'

require('lib.init')('data')

local function create_miniloader_entity(name)
    local source_inserter = data.raw['inserter'][const:name_from_prefix('')]
    assert(source_inserter)

    local loader_inserter = {
        type = 'inserter',
        name = name,
        icon = const:png('item/icon-base'),
        icon_size = 64,
        collision_box = { { -0.2, -0.2 }, { 0.2, 0.2 } },
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        selection_priority = 50,
        allow_custom_vectors = true,
        energy_per_movement = '.0000001J',
        energy_per_rotation = '.0000001J',
        energy_source = {
            type = 'void',
        },
        extension_speed = 1,
        rotation_speed = 0.5,
        pickup_position = { 0, 0 },
        insert_position = { 0, 0 },
        draw_held_item = false,
        draw_inserter_arrow = false,
        circuit_wire_max_distance = default_circuit_wire_max_distance,
        circuit_connector = source_inserter.circuit_connector,
    }

    data:extend { loader_inserter }
end

if Framework.settings:startup_setting('migrate_loaders') then
    for prefix in pairs(const:migrations()) do
        local ml_name = prefix .. 'miniloader-inserter'
        if not data.raw['inserter'][ml_name] then
            create_miniloader_entity(ml_name)
        end
        -- patch up all entities to support filters.
        data.raw['inserter'][ml_name].filter_count = 5
    end
end

require('framework.other-mods').data_final_fixes()
