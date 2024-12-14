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
        { variation = 26, main_offset = util.by_pixel(1, 11),   shadow_offset = util.by_pixel(1, 12), show_shadow = true },  -- North
        { variation = 24, main_offset = util.by_pixel(-15, 0),  shadow_offset = { 0, 0 }, },                                 -- East
        { variation = 24, main_offset = util.by_pixel(-17, 0),  shadow_offset = { 0, 0 }, },                                 -- South
        { variation = 31, main_offset = util.by_pixel(15, 0),   shadow_offset = { 0, 0 }, },                                 -- West

        { variation = 31, main_offset = util.by_pixel(17, 0),   shadow_offset = { 0, 0 }, },                                 -- South
        { variation = 31, main_offset = util.by_pixel(15, 0),   shadow_offset = { 0, 0 }, },                                 -- West
        { variation = 30, main_offset = util.by_pixel(0, 11),   shadow_offset = util.by_pixel(0, 12), show_shadow = true, }, -- North
        { variation = 24, main_offset = util.by_pixel(-15, 0),  shadow_offset = { 0, 0 }, },                                 -- East
    }
)

---@param params data.LoaderTemplate
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

---@param params data.LoaderTemplate
local function create_entity(params)
    local entity = {
        -- Prototype Base
        name = params.name,
        localised_name = params.localised_name,
        order = params.order,
        subgroup = params.subgroup,
        hidden = false,

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
        structure_render_layer = 'object',
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

        collision_mask = collision_mask_util.get_default_mask('loader'),
        flags = { 'placeable-neutral', 'placeable-player', 'player-creation' },
        minable = { mining_time = 0.1, result = params.name },
        fast_replaceable_group = 'mini-loaders',
        next_upgrade = params.next_upgrade,
    }

    local nil_keys = { 'icon' }

    local loader = util.copy(data.raw['loader-1x1']['loader-1x1'])

    for key, value in pairs(entity) do
        loader[key] = value
    end

    for _, key in pairs(nil_keys) do
        loader[key] = nil
    end

    -- hack to get the belt color right
    local loader_tier = params.loader_tier or params.prefix

    if loader_tier and loader_tier:len() > 0 then
        local belt_source = data.raw['underground-belt'][loader_tier .. '-underground-belt']
        if belt_source then
            loader.belt_animation_set = belt_source.belt_animation_set
        end
    end

    data:extend { loader }
end

return {
    create_item = create_item,
    create_entity = create_entity,
}
