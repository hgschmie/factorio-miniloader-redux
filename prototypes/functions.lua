---@meta
------------------------------------------------------------------------
-- Item generation code
------------------------------------------------------------------------

local const = require('lib.constants')
local collision_mask_util = require('collision-mask-util')

require 'circuit-connector-generated-definitions'
require 'circuit-connector-sprites'

local connector_definitions = circuit_connector_definitions.create_vector(
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
    local loader_name = entity_name .. '-loader'

    -- This is the entity that is used to represent the miniloader.
    -- - it can be rotated
    -- - it has four different pictures
    -- - it has no wire connections

    local entity = {
        -- Prototype Base
        name = entity_name,
        type = 'simple-entity-with-owner',
        localised_name = params.localised_name,
        order = params.order,
        subgroup = params.subgroup,
        hidden = false,

        -- SimpleEntityWithOwnerPrototype
        render_layer = 'object',
        picture = {
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

        -- EntityWitHealthPrototype
        max_health = 170,

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

        collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } },
        collision_mask = collision_mask_util.get_default_mask('loader'),
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        flags = { 'placeable-player', 'player-creation' },
        minable = { mining_time = 0.1, result = entity_name },
        fast_replaceable_group = 'mini-loaders',
        next_upgrade = params.next_upgrade,
    }

    local loader = {
        -- Prototype Base
        name = loader_name,
        type = 'loader-1x1',
        localised_name = params.localised_name,
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
            type = 'electric',
            usage_priority = 'secondary-input',
        },
        energy_per_item = '1.5kJ',
        circuit_wire_max_distance = default_circuit_wire_max_distance,
        circuit_connector = connector_definitions,

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

        collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } },
        collision_mask = collision_mask_util.get_default_mask('loader'),
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        flags = { 'placeable-player', 'player-creation' },
        minable = { mining_time = 0.1, result = params.name },
        fast_replaceable_group = 'mini-loaders',
        next_upgrade = params.next_upgrade,
    }

    -- hack to get the belt color right
    local loader_tier = params.loader_tier or params.prefix

    if loader_tier and loader_tier:len() > 0 then
        local belt_source = data.raw['underground-belt'][loader_tier .. '-underground-belt']
        if belt_source then
            loader.belt_animation_set = util.copy(belt_source.belt_animation_set)
        end
    end

    data:extend { entity, loader }
end

return {
    create_item = create_item,
    create_entity = create_entity,
}
