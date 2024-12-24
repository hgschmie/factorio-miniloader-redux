---@meta
----------------------------------------------------------------------------------------------------
-- class definitions
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- prototypes/templates.lua
----------------------------------------------------------------------------------------------------

---@class miniloader.LoaderTemplate
---@field prefix string?
---@field name string?
---@field localised_name string?
---@field order string
---@field subgroup string
---@field speed integer
---@field next_upgrade string?
---@field tint Color?
---@field loader_tier string?
---@field stack_size number?
---@field condition (fun():boolean)?


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

---@class miniloader.Data
---@field main LuaEntity
---@field loader LuaEntity
---@field inserters LuaEntity[]
---@field config miniloader.Config
