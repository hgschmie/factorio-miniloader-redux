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
---@field miniloaders table<number, miniloader.Data>

---@class miniloader.Config
---@field enabled boolean
---@field status defines.entity_status?

---@class miniloader.Data
---@field main LuaEntity
---@field config miniloader.Config
---@field ref table<string, LuaEntity>
