---@meta
----------------------------------------------------------------------------------------------------
-- class definitions
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- prototypes/templates.lua
----------------------------------------------------------------------------------------------------

---@class miniloader.SpeedConfig
---@field rotation_speed number
---@field items_per_second number
---@field inserter_pairs integer
---@field stack_size_bonus integer

---@class miniloader.LoaderDefinition
---@field condition (fun():boolean)?
---@field data fun(dash_prefix:string):miniloader.LoaderTemplate

---@alias miniloader.PrototypeProcessor fun(prototype: data.EntityWithOwnerPrototype)

---@class miniloader.LoaderTemplate
---@field prefix string Prefix for the loader. Set by code from the template key
---@field name string Internal name for the loader. Set by code from the template key
---@field order string
---@field subgroup string
---@field speed integer
---@field tint Color
---@field stack_size number
---@field speed_config miniloader.SpeedConfig
---@field localised_name string? Localised name for the loader. defaults to entity-name.<name>
---@field upgrade_from string? Tier name from which this loader is an upgrade.
---@field ingredients fun():data.IngredientPrototype[] Ingredients to make the loader
---@field prerequisites fun():data.TechnologyID[]? Technology prerequisites to make the miniloader
---@field research_trigger data.TechnologyTrigger? A technology trigger that will enable the technology.
---@field unit data.TechnologyUnit? The unit of research required. If both unit and research_trigger are undefined, the values from the first ingredient are copied.
---@field energy_source (fun():data.BaseEnergySource, number, number)?
---@field explosion_gfx string? Optional, if missing use the prefix. Selects explosion graphics.
---@field corpse_gfx string? Optional, if missing use the prefix. Selects remnants graphics.
---@field belt_gfx string? Optional, if missing use the loader tier. Selects belt animation set.
---@field entity_gfx string? Graphics variant for miniloader graphics
---@field stack boolean? If true, supports stacking
---@field nerf_mode boolean? Turn off all the nice features and make the loader really dumb.
---@field belt_color_selector fun(loader: data.LoaderPrototype, name: string)?
---@field prototype_processor miniloader.PrototypeProcessor?
---@field global_prototype_processors miniloader.PrototypeProcessor[]

---@class miniloader.ModData
---@field speed_config miniloader.SpeedConfig
---@field nerf_mode boolean

----------------------------------------------------------------------------------------------------
-- scripts/controller.lua
----------------------------------------------------------------------------------------------------

---@class miniloader.Storage
---@field count integer
---@field by_main table<number, miniloader.Data>
---@field open_guis table<integer, miniloader.Data>

--- for 1.0, config works differently. It contains all of the config settings detached from
--- the inserter and loader. For each entity, the control behavior (and additional entity settings)
--- are generated from the config and if read from an entity, they are updated here.
---@class miniloader.Config
---@field enabled boolean                                Is this miniloader active? (FIXME - has no function right now)
---@field loader_type miniloader.LoaderDirection         Direction of the loader. The loader_type and the direction combined define the direction of the loader entity
---@field direction defines.direction?                   Direction of the miniloader. This is always the inserter direction and is never changed by the mod (only by player interaction)
---@field highspeed boolean?                             Speed > 240 items/sec ?
---@field nerf_mode boolean?                             Loader is really dumb (no filters, connections etc.)
---@field turbo_mode boolean                             1.0 Run in "turbo" mode (only belt <-> container, but very fast)
---@field lane_filter boolean                            1.0 Only two filters, one for each lane
---@field circuit_set_filters boolean                    1.0 Inserter/Loader circuit_set_filters
---@field circuit_enable_disable boolean                 1.0 Inserter/Loader circuit_enable_disable
---@field circuit_condition CircuitConditionDefinition?  1.0 Inserter/Loader circuit_condition
---@field connect_to_logistic_network boolean            1.0 Inserter/Loader connect_to_logistic_network
---@field logistic_condition CircuitConditionDefinition? 1.0 Inserter/Loader circuit_condition
---@field filters ItemFilter[]                           1.0 Inserter/Loader maps to set_filter/get_filter
---@field filter_mode PrototypeFilterMode                1.0 Inserter - filter_mode/use_filters Loader - loader_filter_mode
---@field read_transfers boolean                         1.0 Loader - maps to circuit_read_transfers
---@field spoil_priority SpoilPriority                   1.0 Inserter - maps to inserter_spoil_priority (not available in turbo mode)
---@field stack_size integer                             1.0 Stack size if stacking is supported

---@class miniloader.State
---@field status defines.entity_status?                  The miniloader status. (FIXME - gets initialized from main and then nothing is done with it)
---@field filters ItemFilter[]                           1.0 Inserter/Loader maps to set_filter/get_filter
---@field filter_mode PrototypeFilterMode?               1.0 Inserter - filter_mode/use_filters Loader - loader_filter_mode
---@field turbo_mode boolean?                            1.0 Run in "turbo" mode (only belt <-> container, but very fast)
---@field lane_filter boolean?                           1.0 Only two filters, one for each lane

---@class miniloader.Data
---@field main LuaEntity              Main inserter. This is what is visible on screen and what is copied, blueprinted etc.
---@field loader LuaEntity            The loader that connects to belts and does most of the work. The GUI opened comes from this loader.
---@field inserters LuaEntity[]       All inserters in this miniloader.
---@field config miniloader.Config    Config settings. This is what gets blueprinted / configured etc.
---@field state miniloader.State      Runtime state. Updated as the Miniloader works.

---@class miniloader.PreBuild
---@field direction defines.direction  Direction as reported by the prebuild event
---@field flip_horizontal boolean      Flip horizontal as reported by the prebuild event
---@field flip_vertical boolean        Flip vertical as reported by the prebuild event
