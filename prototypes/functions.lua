---@meta
------------------------------------------------------------------------
-- Item generation code
------------------------------------------------------------------------

local meld = require('meld')
local util = require('util')
local collision_mask_util = require('collision-mask-util')

require 'circuit-connector-generated-definitions'
require 'circuit-connector-sprites'
require 'sound-util'

local const = require('lib.constants')


-- similar to the original miniloader module, this uses an inserter as the "main" entity.
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

---@param prefix string?
---@param name string
local function add_tier_prefix(prefix, name)
    if prefix and prefix:len() > 0 then
        return prefix .. '-' .. name
    else
        return name
    end
end

---@param params miniloader.LoaderTemplate
local function create_item(params)
    local stack_size = params.stack_size or 50

    local item = {
        -- PrototypeBase
        type = 'item',
        name = params.name,
        localised_name = params.localised_name,
        order = params.order,
        subgroup = params.subgroup,

        -- ItemPrototype
        stack_size = stack_size,
        weight = 1000 / stack_size * kg,
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
    local loader_tier = params.loader_tier or params.prefix

    local items_per_second = math.floor(params.speed * 480 * 100 + 0.5) / 100

    local description = { '',
        { 'entity-description.' .. entity_name },
        '\n',
        '[font=default-semibold][color=255,230,192]',
        { 'description.belt-speed' },
        ':[/color][/font] ',
        tostring(items_per_second),
        ' ',
        { 'description.belt-items' },
        { 'per-second-suffix' }
    }

    local drain = '0.0000001W'
    local consumption = tostring(params.speed * 1200 * (params.bulk and 1.5 or 1)) .. 'kW'

    local electric_energy = params.energy_source or {
        type = 'electric',
        buffer_capacity = '0kJ',
        usage_priority = 'secondary-input',
        render_no_power_icon = true,
        render_no_network_icon = true,
    }

    local void_energy = { type = 'void', }

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
        extension_speed = params.speed * 8,
        rotation_speed = params.speed * 4,
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
        energy_source = electric_energy,
        energy_per_movement = consumption,
        energy_per_rotation = consumption,
        allow_custom_vectors = true,
        draw_held_item = false,
        use_easter_egg = false,
        filter_count = params.nerf_mode and 0 or 5,

        -- handle stacking
        bulk = params.bulk or false,
        wait_for_full_hand = params.bulk or false,
        grab_less_to_match_belt_stack = params.bulk or false,
        stack_size_bonus = params.bulk and 4,
        max_belt_stack_size = params.bulk and 4,

        circuit_wire_max_distance = not params.nerf_mode and default_circuit_wire_max_distance or 0,
        draw_inserter_arrow = false,
        chases_belt_items = false,
        circuit_connector = not params.nerf_mode and inserter_connector_definitions or nil,

        -- EntityWitHealthPrototype
        max_health = 170,
        damaged_trigger_effect = {
            type = 'create-entity',
            entity_name = 'spark-explosion',
            offset_deviation = { { -0.5, -0.5 }, { 0.5, 0.5 } },
            offsets = { { 0, 1 } },
            damage_type_filters = 'fire'
        },
        dying_explosion = add_tier_prefix(loader_tier, 'underground-belt-explosion'),
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
        corpse = add_tier_prefix(loader_tier, 'underground-belt-remnants'),

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
        collision_mask = collision_mask_util.get_default_mask('inserter'),
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        flags = { 'placeable-neutral', 'placeable-player', 'player-creation' },
        minable = { mining_time = 0.1, result = entity_name },
        selection_priority = 50,
        impact_category = 'metal',
        open_sound = { filename = '__base__/sound/open-close/inserter-open.ogg', volume = 0.6 },
        close_sound = { filename = '__base__/sound/open-close/inserter-close.ogg', volume = 0.5 },
        working_sound = {
            match_progress_to_activity = true,
            sound = sound_variations('__base__/sound/inserter-basic', 5, 0.5, { volume_multiplier('main-menu', 2), volume_multiplier('tips-and-tricks', 1.8) }),
            audible_distance_modifier = 0.3
        },
        fast_replaceable_group = 'mini-loader',
    }

    local hidden_inserter = meld(util.copy(inserter), {
        name = inserter_name,
        icons = meld.delete(),
        icon = '__core__/graphics/empty.png',
        hidden = true,
        hidden_in_factoriopedia = true,
        platform_picture = meld.overwrite(util.empty_sprite()),
        collision_mask = meld.overwrite(collision_mask_util.new_mask()),
        selection_box = { { 0, 0 }, { 0, 0 } },
        flags = meld.overwrite {
            'placeable-neutral',
            'placeable-player',
            'not-on-map',
            'not-deconstructable',
            'not-blueprintable',
            'hide-alt-info',
            'not-flammable',
            'not-upgradable',
            'not-in-kill-statistics',
            'not-in-made-in',
        },
        minable = meld.delete(),
        selection_priority = 0,
        allow_copy_paste = false,
        selectable_in_game = false,
        fast_replaceable_group = meld.delete(),
    })

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
        filter_count = params.nerf_mode and 0 or 5,
        structure_render_layer = 'object',
        container_distance = 0,
        allow_rail_interaction = false,
        allow_container_interaction = false,
        per_lane_filters = false,
        energy_source = void_energy,
        energy_per_item = drain,

        circuit_wire_max_distance = default_circuit_wire_max_distance,
        circuit_connector = loader_connector_definitions,

        -- EntityWitHealthPrototype
        max_health = 10,

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
        collision_mask = { layers = { transport_belt = true, } },
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        flags = {
            'placeable-neutral',
            'placeable-player',
            'not-on-map',
            'not-deconstructable',
            'not-blueprintable',
            'hide-alt-info',
            'not-flammable',
            'not-upgradable',
            'not-in-kill-statistics',
            'not-in-made-in',
        },
        minable = nil,
        selection_priority = 0,
        allow_copy_paste = false,
        selectable_in_game = false,
    }

    -- hack to get the belt color right
    if loader_tier and loader_tier:len() > 0 then
        local belt_source = data.raw['underground-belt'][add_tier_prefix(loader_tier, 'underground-belt')]
        if belt_source then
            loader.belt_animation_set = util.copy(belt_source.belt_animation_set)
        end
    end

    data:extend { inserter, hidden_inserter, loader }
end

local technology_icons = {
    {
        icon = const:png('technology/technology-base'),
        icon_size = 128,
    },
    {
        icon = const:png('technology/technology-mask'),
        icon_size = 128,
    },
}

local function create_recipe(params)
    local recipe = {
        type = 'recipe',
        name = params.name,
        localised_name = params.localised_name,
        ingredients = params.ingredients,
        enabled = false,
        results = {
            {
                type = 'item',
                name = params.name,
                amount = 1,
            },
        },
    }

    local technology = {
        type = 'technology',
        name = params.name,
        order = params.order,
        icons = util.copy(technology_icons),
        prerequisites = params.prerequisites,
        research_trigger = params.research_trigger,
        visible_when_disabled = false,
        effects = {
            {
                type = 'unlock-recipe',
                recipe = params.name,
            }
        }
    }

    -- apply tint to copied icon
    technology.icons[2].tint = params.tint

    if not (technology.unit or technology.research_trigger) then
        assert(technology.prerequisites[1])
        local main_prereq = data.raw['technology'][technology.prerequisites[1]]

        if main_prereq.unit then
            technology.unit = util.copy(main_prereq.unit)
        else
            technology.research_trigger = util.copy(main_prereq.research_trigger)
        end
    end

    data:extend { recipe, technology }
end

return {
    create_item = create_item,
    create_entity = create_entity,
    create_recipe = create_recipe,
}
