------------------------------------------------------------------------
-- data phase 3
------------------------------------------------------------------------

require('lib.init')

local util = require('util')

local const = require('lib.constants')

require 'circuit-connector-generated-definitions'
require 'circuit-connector-sprites'

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

local function create_technology(technology_name)
    local technology = {
        type = 'technology',
        name = technology_name,
        icons = { util.empty_icon() },
        visible_when_disabled = false,
        research_trigger = {
            type = 'craft-item',
            item = 'iron-plate',
            count = 50
        }
    }

    data:extend { technology }
end

if Framework.settings:startup_setting(const.settings_names.migrate_loaders) then
    for prefix in pairs(const:migrations()) do
        local ml_name = prefix .. 'miniloader-inserter'
        if not data.raw['inserter'][ml_name] then
            create_miniloader_entity(ml_name)
        end
        -- patch up all entities to support filters.
        data.raw['inserter'][ml_name].filter_count = 5

        if not (prefix:match('chute') or prefix:match('filter')) then
            local technology_name = prefix .. 'miniloader'
            if not data.raw['technology'][technology_name] then
                create_technology(technology_name)
            end
        end
    end
end

Framework.post_data_final_fixes_stage()
