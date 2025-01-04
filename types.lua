---@meta
----------------------------------------------------------------------------------------------------
-- class definitions
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- prototypes/templates.lua
----------------------------------------------------------------------------------------------------

---@class miniloader.LoaderDefinition
---@field condition (fun():boolean)?
---@field data fun():miniloader.LoaderTemplate

---@class miniloader.LoaderTemplate
---@field prefix string? Prefix for the loader. Set by code from the template key
---@field name string? Internal name for the loader. Set by code from the template key
---@field localised_name string? Localised name for the loader. defaults to entity-name.<name>
---@field upgrade_from string? Tier name from which this loader is an upgrade.
---@field order string
---@field subgroup string
---@field speed integer
---@field tint Color
---@field stack_size number
---@field ingredients data.IngredientPrototype[] Ingredients to make the loader
---@field prerequisites data.TechnologyID[]? Technology prerequisites to make the miniloader
---@field research_trigger data.TechnologyTrigger? A technology trigger that will enable the technology.
---@field unit data.TechnologyUnit? The unit of research required. If both unit and research_trigger are undefined, the values from the first ingredient are copied.
---@field energy_source? data.ElectricEnergySource|data.VoidEnergySource
---@field loader_tier string? Optional, if missing use the prefix. Loader Tier for belt speed
---@field bulk? boolean If true, support bulk moves
---@field nerf_mode? boolean Turn off all the nice features and make the loader really dumb.


----------------------------------------------------------------------------------------------------
-- scripts/controller.lua
----------------------------------------------------------------------------------------------------

---@class miniloader.Storage
---@field VERSION integer
---@field count integer
---@field by_main table<number, miniloader.Data>

---@class miniloader.Config
---@field enabled boolean
---@field status defines.entity_status?
---@field loader_type miniloader.LoaderDirection -- direction of the loader. The loader_type and the direction combined define the direction of the loader entity
---@field direction defines.direction?           -- direction of the miniloader. This is always the inserter direction and is never changed by the mod (only by player interaction)
---@field inserter_config table<string, any?>    -- inserter config, gets synced in reconfigure

---@class miniloader.Data
---@field main LuaEntity
---@field loader LuaEntity
---@field inserters LuaEntity[]
---@field config miniloader.Config
