------------------------------------------------------------------------
-- GUI code
------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')

local Matchers = require('framework.matchers')

local const = require('lib.constants')

---@class miniloader.Gui
local Gui = {
    TICK_INTERVAL = 10 -- update the inserters every 1/6 of a second
}

---@return table<integer, miniloader.Data>
local function get_guis()
    return storage.ml_data.open_guis
end

---@param player_index integer
---@param ml_entity miniloader.Data
local function add_player_gui(player_index, ml_entity)
    storage.ml_data.open_guis[player_index] = ml_entity
end

---@param player_index integer
---@return miniloader.Data? ml_entity
local function remove_player_gui(player_index)
    local ml_entity = storage.ml_data.open_guis[player_index]
    storage.ml_data.open_guis[player_index] = nil
    return ml_entity
end

---@param ml_entity  miniloader.Data
---@return boolean is_open
function Gui:hasOpenGui(ml_entity)
    if  not (ml_entity.main and ml_entity.main.valid) then return false end

    local guis = get_guis()
    if table_size(guis) == 0 then return false end

    for _, open_ml_entity in pairs(guis) do
        if  open_ml_entity.main and open_ml_entity.main.valid then
            if open_ml_entity.main.unit_number == ml_entity.main.unit_number then return true end
        end
    end

    return false
end

local function sync_open_guis()
    local guis = get_guis()
    if table_size(guis) == 0 then return end

    local seen_entity = {}

    for _, ml_entity in pairs(guis) do
        if  ml_entity.main and ml_entity.main.valid then
            if not seen_entity[ml_entity.main.unit_number] then
                This.MiniLoader:readConfigFromEntity(ml_entity.loader, ml_entity)
                This.MiniLoader:resyncInserters(ml_entity)
                seen_entity[ml_entity.main.unit_number] = true
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Event management
--------------------------------------------------------------------------------

---@param event EventData.on_gui_opened
local function on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if not (event.entity and event.entity.valid) then return end

    local ml_entity = This.MiniLoader:getEntity(event.entity.unit_number)
    if not ml_entity then return end

    -- nerf mode
    if ml_entity.main.prototype.filter_count == 0 then
        game.players[event.player_index].opened = nil
        return
    end

    add_player_gui(event.player_index, ml_entity)

    This.MiniLoader:writeConfigToEntity(ml_entity.config.inserter_config, ml_entity.loader)
    game.players[event.player_index].opened = ml_entity.loader
end

---@param event EventData.on_gui_closed
local function on_gui_closed(event)
    if not (event.entity and event.entity.valid) then return end

    local ml_entity = remove_player_gui(event.player_index)
    if not ml_entity then return end

    if event.entity.unit_number ~= ml_entity.loader.unit_number then return end

    This.MiniLoader:readConfigFromEntity(ml_entity.loader, ml_entity)
    This.MiniLoader:reconfigure(ml_entity)
end

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local function register_events()
    local ml_entity_filter = Matchers:matchEventEntityName(const.supported_type_names)
    local ml_loader_filter = Matchers:matchEventEntityName(const.supported_loader_names)

    -- Gui updates / sync inserters
    Event.register(defines.events.on_gui_opened, on_gui_opened, ml_entity_filter)
    Event.register(defines.events.on_gui_closed, on_gui_closed, ml_loader_filter)
    Event.on_nth_tick(Gui.TICK_INTERVAL, sync_open_guis)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_load()
    register_events()
end

local function on_init()
    register_events()
end

Event.on_init(on_init)
Event.on_load(on_load)

return Gui
