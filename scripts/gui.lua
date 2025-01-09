---@meta
------------------------------------------------------------------------
-- GUI code
------------------------------------------------------------------------

local Is = require('stdlib.utils.is')
local Event = require('stdlib.event.event')

local tools = require('framework.tools')

local const = require('lib.constants')

local TICK_INTERVAL = -10

---@class miniloader.Gui
---@field open_guis table<integer, miniloader.Data>
local Gui = {
    open_guis = {}
}

local function sync_open_guis()
    for _, ml_entity in pairs(Gui.open_guis) do
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

    Event.register_if(table_size(Gui.open_guis) == 0, TICK_INTERVAL, sync_open_guis)
    Gui.open_guis[event.player_index] = ml_entity

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
    local ml_entity =  Gui.open_guis[event.player_index]
    if not ml_entity then return end

    if not Is.Valid(event.entity) then return end
    if event.entity.unit_number ~= ml_entity.loader.unit_number then return end

    Gui.open_guis[event.player_index] = nil
    Event.remove_if(table_size(Gui.open_guis) == 0, TICK_INTERVAL, sync_open_guis)

    This.MiniLoader:readConfigFromEntity(ml_entity.loader, ml_entity)
    This.MiniLoader:reconfigure(ml_entity)
end

local ml_entity_filter = tools.create_event_entity_matcher('name', const.supported_type_names)
local ml_loader_filter = tools.create_event_entity_matcher('name', const.supported_loader_names)

-- Gui updates / sync inserters
Event.register(defines.events.on_gui_opened, onGuiOpened, ml_entity_filter)
Event.register(defines.events.on_gui_closed, onGuiClosed, ml_loader_filter)

return Gui
