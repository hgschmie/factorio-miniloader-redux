---@meta
------------------------------------------------------------------------
-- GUI code
------------------------------------------------------------------------

local Is = require('stdlib.utils.is')
local Event = require('stdlib.event.event')

local tools = require('framework.tools')

local const = require('lib.constants')

local TICK_INTERVAL = 10 -- update the inserters every 1/6 of a second

---@return table<integer, miniloader.Data>
local function get_guis()
    return storage.ml_data.open_guis
end

---@param player_index integer
---@param ml_entity miniloader.Data
local function set_player_gui(player_index, ml_entity)
    storage.ml_entity.open_guis[player_index] = ml_entity
end

---@param player_index integer
local function clear_player_gui(player_index)
    storage.ml_entity.open_guis[player_index] = nil
end

---@param player_index integer
---@return miniloader.Data?
local function get_player_gui(player_index)
    return storage.ml_entity.open_guis[player_index]
end

local function sync_open_guis()
    local guis = get_guis()
    if table_size(guis) == 0 then return end

    for _, ml_entity in pairs(guis) do
        if Is.Valid(ml_entity.main) then
            This.MiniLoader:readConfigFromEntity(ml_entity.loader, ml_entity)
            This.MiniLoader:resyncInserters(ml_entity)
        end
    end
end

---@param event EventData.on_gui_opened
local function onGuiOpened(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if not Is.Valid(event.entity) then return end

    local ml_entity = This.MiniLoader:getEntity(event.entity.unit_number)
    if not ml_entity then return end

    set_player_gui(event.player_index, ml_entity)

    -- nerf mode
    if ml_entity.main.prototype.filter_count == 0 then
        game.players[event.player_index].opened = nil
        return
    end

    This.MiniLoader:writeConfigToEntity(ml_entity, ml_entity.loader)
    game.players[event.player_index].opened = ml_entity.loader
end

---@param event EventData.on_gui_closed
local function onGuiClosed(event)
    local ml_entity = get_player_gui(event.player_index)
    if not ml_entity then return end

    if not Is.Valid(event.entity) then return end
    if event.entity.unit_number ~= ml_entity.loader.unit_number then return end

    clear_player_gui(event.player_index)

    This.MiniLoader:readConfigFromEntity(ml_entity.loader, ml_entity)
    This.MiniLoader:reconfigure(ml_entity)
end

local ml_entity_filter = tools.create_event_entity_matcher('name', const.supported_type_names)
local ml_loader_filter = tools.create_event_entity_matcher('name', const.supported_loader_names)

-- Gui updates / sync inserters
Event.register(defines.events.on_gui_opened, onGuiOpened, ml_entity_filter)
Event.register(defines.events.on_gui_closed, onGuiClosed, ml_loader_filter)

Event.on_nth_tick(TICK_INTERVAL, sync_open_guis)
