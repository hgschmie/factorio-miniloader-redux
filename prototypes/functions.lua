---@meta
------------------------------------------------------------------------
-- Item generation code
------------------------------------------------------------------------

local const = require('lib.constants')
local collision_mask_util = require('collision-mask-util')

require 'circuit-connector-generated-definitions'
require 'circuit-connector-sprites'

--
-- similar to the existing miniloader module, this uses an inserter as the "main" entity.
-- unlike the miniloader, it manages all other entities fully. It also uses different inserter entities for
-- primary and hidden inserters which allows for correct power stats and blueprints.

local loader_connector_definitions = circuit_connector_definitions.create_vector(
    universal_connector_template,
    {
        { variation = 26, main_offset = util.by_pixel(1, 11),  shadow_offset = util.by_pixel(1, 12), show_shadow = true },  -- North
        { variation = 24, main_offset = util.by_pixel(-15, 0), shadow_offset = { 0, 0 }, },                                 -- East
        { variation = 24, main_offset = util.by_pixel(-17, 0), shadow_offset = { 0, 0 }, },                                 -- South
        { variation = 31, main_offset = util.by_pixel(15, 0),  shadow_offset = { 0, 0 }, },                                 -- West

        { variation = 31, main_offset = util.by_pixel(17, 0),  shadow_offset = { 0, 0 }, },                                 -- South
        { variation = 31, main_offset = util.by_pixel(15, 0),  shadow_offset = { 0, 0 }, },                                 -- West
        { variation = 30, main_offset = util.by_pixel(0, 11),  shadow_offset = util.by_pixel(0, 12), show_shadow = true, }, -- North
        { variation = 24, main_offset = util.by_pixel(-15, 0), shadow_offset = { 0, 0 }, },                                 -- East
    }
)

local inserter_connector_definitions = circuit_connector_definitions.create_vector(
    universal_connector_template,
    {
        { variation = 31, main_offset = util.by_pixel(17, 0),  shadow_offset = { 0, 0 }, }, -- North
        { variation = 30, main_offset = util.by_pixel(0, 11),  shadow_offset = { 0, 0 }, }, -- West
        { variation = 24, main_offset = util.by_pixel(-17, 0), shadow_offset = { 0, 0 }, }, -- South
        { variation = 26, main_offset = util.by_pixel(1, 11),  shadow_offset = { 0, 0 }, }, -- East
    }
)

---@param params miniloader.LoaderTemplate
local function create_item(params)
    local item = {
        -- PrototypeBase
        type = 'item',
        name = params.name,
        localised_name = params.localised_name,
        order = params.order,
        subgroup = params.subgroup,

        -- ItemPrototype
        stack_size = params.stack_size or 50,
        icons = {
            {
                icon = const:png('item/icon-base'),
                icon_size = 64,
            },
            {
                icon = const:png('item/icon-mask'),
                icon_size = 64,
                tint = params.tint,
            },
        },

        place_result = params.name,
    }

    data:extend { item }
end

---@param params miniloader.LoaderTemplate
local function create_entity(params)
    local entity_name = params.name
    local loader_name = const.loader_name(entity_name)
    local inserter_name = const.inserter_name(entity_name)

    local items_per_second = math.floor(params.speed * 480 * 100 + 0.5) / 100
    local description = { '',
        '[font=default-semibold][color=255,230,192]',
        { 'description.belt-speed' },
        ':[/color][/font] ',
        tostring(items_per_second),
        ' ',
        { 'description.belt-items' },
        { 'per-second-suffix' }
    }
    -- This is the entity that is used to represent the miniloader.
    -- - it can be rotated
    -- - it has four different pictures
    -- - it has no wire connections

    local inserter = {
        -- Prototype Base
        type = 'inserter',
        name = entity_name,
        order = params.order,
        localised_name = params.localised_name,
        localised_description = description,
        subgroup = params.subgroup,
        hidden = false,
        hidden_in_factoriopedia = false,

        -- InserterPrototype
        extension_speed = 1,
        rotation_speed = 0.5,
        insert_position = { 0, 0 },
        pickup_position = { 0, 0 },
        platform_picture = {
            sheets = {
                -- Base
                {
                    filename = const:png('entity/miniloader-structure-base'),
                    height = 192,
                    priority = 'extra-high',
                    scale = 0.5,
                    width = 192,
                    y = 0,
                },
                -- Mask
                {
                    filename = const:png('entity/miniloader-structure-mask'),
                    height = 192,
                    priority = 'extra-high',
                    scale = 0.5,
                    width = 192,
                    y = 0,
                    tint = params.tint,
                },
                -- Shadow
                {
                    filename = const:png('entity/miniloader-structure-shadow'),
                    draw_as_shadow = true,
                    height = 192,
                    priority = 'extra-high',
                    scale = 0.5,
                    width = 192,
                    y = 0,
                }
            }
        },
        hand_base_picture = util.empty_sprite(),
        hand_open_picture = util.empty_sprite(),
        hand_closed_picture = util.empty_sprite(),
        hand_base_shadow = util.empty_sprite(),
        hand_open_shadow = util.empty_sprite(),
        hand_closed_shadow = util.empty_sprite(),
        energy_source = {
            type = 'electric',
            usage_priority = 'secondary-input',
        },
        energy_per_movement = '2kJ',
        energy_per_rotation = '2kJ',
        -- energy_source = { type = 'void', },
        -- energy_per_movement = '.0000001J',
        -- energy_per_rotation = '.0000001J',
        bulk = false,
        allow_custom_vectors = true,
        draw_held_item = false,
        use_easter_egg = false,
        grab_less_to_match_belt_stack = false,
        wait_for_full_hand = false, -- todo for bulk?
        filter_count = 5,

        circuit_wire_max_distance = default_circuit_wire_max_distance,
        draw_inserter_arrow = false,
        chases_belt_items = false,
        stack_size_bonus = 0,
        circuit_connector = inserter_connector_definitions,

        -- EntityWitHealthPrototype
        max_health = 170,
        resistances = {
            {
                type = 'fire',
                percent = 60
            },
            {
                type = 'impact',
                percent = 30
            }
        },

        -- EntityPrototype
        icons = {
            {
                icon = const:png('item/icon-base'),
                icon_size = 64,
            },
            {
                icon = const:png('item/icon-mask'),
                icon_size = 64,
                tint = params.tint,
            },
        },

        collision_box = { { -0.2, -0.2 }, { 0.2, 0.2 } },
        collision_mask = collision_mask_util.get_default_mask('inserter'),
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        flags = { 'placeable-player', 'player-creation' },
        minable = { mining_time = 0.1, result = entity_name },
        selection_priority = 50,
        fast_replaceable_group = 'mini-loader',
        next_upgrade = params.next_upgrade,
    }

    local hidden_inserter = util.copy(inserter)
    hidden_inserter.name = inserter_name
    hidden_inserter.localised_name = nil
    hidden_inserter.localised_description = nil
    hidden_inserter.hidden = true
    hidden_inserter.hidden_in_factoriopedia = true
    hidden_inserter.platform_picture = util.empty_sprite()
    hidden_inserter.energy_source = { type = 'void' }
    hidden_inserter.icons = { util.empty_icon() }
    -- hidden_inserter.collision_box = { { 0,0}, { 0,0 }}
    hidden_inserter.collision_mask = collision_mask_util.new_mask()
    hidden_inserter.selection_box =  { { 0,0}, { 0,0 }}
    hidden_inserter.minable = nil
    hidden_inserter.selection_priority = 0
    hidden_inserter.fast_replaceable_group = nil
    hidden_inserter.next_upgrade = nil

    local loader = {
        -- Prototype Base
        name = loader_name,
        type = 'loader-1x1',
        order = params.order,
        subgroup = params.subgroup,
        hidden = true,
        hidden_in_factoriopedia = true,

        -- LoaderPrototype
        structure = {
            direction_in = {
                sheets = {
                    -- Base
                    {
                        filename = const:png('entity/miniloader-structure-base'),
                        height = 192,
                        priority = 'extra-high',
                        scale = 0.5,
                        width = 192,
                        y = 0,
                    },
                    -- Mask
                    {
                        filename = const:png('entity/miniloader-structure-mask'),
                        height = 192,
                        priority = 'extra-high',
                        scale = 0.5,
                        width = 192,
                        y = 0,
                        tint = params.tint,
                    },
                    -- Shadow
                    {
                        filename = const:png('entity/miniloader-structure-shadow'),
                        draw_as_shadow = true,
                        height = 192,
                        priority = 'extra-high',
                        scale = 0.5,
                        width = 192,
                        y = 0,
                    }
                }
            },
            direction_out = {
                sheets = {
                    -- Base
                    {
                        filename = const:png('entity/miniloader-structure-base'),
                        height = 192,
                        priority = 'extra-high',
                        scale = 0.5,
                        width = 192,
                        y = 192,
                    },
                    -- Mask
                    {
                        filename = const:png('entity/miniloader-structure-mask'),
                        height = 192,
                        priority = 'extra-high',
                        scale = 0.5,
                        width = 192,
                        y = 192,
                        tint = params.tint,
                    },
                    -- Shadow
                    {
                        filename = const:png('entity/miniloader-structure-shadow'),
                        height = 192,
                        priority = 'extra-high',
                        scale = 0.5,
                        width = 192,
                        y = 192,
                        draw_as_shadow = true,
                    }
                }
            },
            back_patch = {
                sheet = {
                    filename = const:png('entity/miniloader-structure-back-patch'),
                    priority = 'extra-high',
                    width = 192,
                    height = 192,
                    scale = 0.5,
                }
            },
            front_patch = {
                sheet = {
                    filename = const:png('entity/miniloader-structure-front-patch'),
                    priority = 'extra-high',
                    width = 192,
                    height = 192,
                    scale = 0.5,
                }
            }
        },
        filter_count = 5,
        structure_render_layer = 'lower-object',
        container_distance = 1,
        allow_rail_interaction = true,
        allow_container_interaction = true,
        per_lane_filters = false,
        energy_source = {
            type = 'void',
        },

        energy_per_item = '.0000001J',
        circuit_wire_max_distance = default_circuit_wire_max_distance,
        circuit_connector = loader_connector_definitions,

        -- TransportBeltConnectablePrototype
        belt_animation_set = util.copy(data.raw['underground-belt']['underground-belt'].belt_animation_set),
        animation_speed_coefficient = 32,
        speed = params.speed,

        -- EntityPrototype
        icons = {
            {
                icon = const:png('item/icon-base'),
                icon_size = 64,
            },
            {
                icon = const:png('item/icon-mask'),
                icon_size = 64,
                tint = params.tint,
            },
        },

        collision_box = { { -0.3, -0.3, }, { 0.3, 0.3 } },
        collision_mask = { layers = { transport_belt = true, } },
        selection_box = { { 0, 0 }, { 0, 0 } },
        selection_priority = 0,
        flags = { 'placeable-player', 'player-creation' },
    }

    -- hack to get the belt color right
    local loader_tier = params.loader_tier or params.prefix

    if loader_tier and loader_tier:len() > 0 then
        local belt_source = data.raw['underground-belt'][loader_tier .. '-underground-belt']
        if belt_source then
            loader.belt_animation_set = util.copy(belt_source.belt_animation_set)
        end
    end

    data:extend { inserter, hidden_inserter, loader }
end

return {
    create_item = create_item,
    create_entity = create_entity,
}
