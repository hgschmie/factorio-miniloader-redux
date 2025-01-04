---@meta
------------------------------------------------------------------------
-- GUI code
------------------------------------------------------------------------

local Is = require('stdlib.utils.is')
local Event = require('stdlib.event.event')

local tools = require('framework.tools')

local const = require('lib.constants')


---@class miniloader.Gui
---@field open_guis table<integer, miniloader.Data>
local Gui = {
    open_guis = {}
}

local function sync_open_guis()
    for _, ml_entity in pairs(Gui.open_guis) do
        if Is.Valid(ml_entity.main) then
            This.MiniLoader:syncInserterConfig(ml_entity)
            This.MiniLoader:resyncInserters(ml_entity, true)
        end
    end
end

---@param event EventData.on_gui_opened
local function onGuiOpened(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if not Is.Valid(event.entity) then return end

    local ml_entity = This.MiniLoader:getEntity(event.entity.unit_number)
    if not ml_entity then return end

    if ml_entity.main.prototype.filter_count == 0 then
        game.players[event.player_index].opened = nil
        return
    end

    if table_size(Gui.open_guis) == 0 then
        Event.register(-10, sync_open_guis)
    end

    Gui.open_guis[event.player_index] = ml_entity
end

---@param event EventData.on_gui_closed
local function onGuiClosed(event)
    Gui.open_guis[event.player_index] = nil

    if table_size(Gui.open_guis) == 0 then
        Event.remove(-10, sync_open_guis)
    end

    if not Is.Valid(event.entity) then return end
    local ml_entity = This.MiniLoader:getEntity(event.entity.unit_number)
    if not ml_entity then return end

    This.MiniLoader:syncInserterConfig(ml_entity)
    This.MiniLoader:reconfigure(ml_entity)
end

local ml_entity_filter = tools.create_event_entity_matcher('name', const.supported_type_names)

-- Gui updates / sync inserters
Event.register(defines.events.on_gui_opened, onGuiOpened, ml_entity_filter)
Event.register(defines.events.on_gui_closed, onGuiClosed, ml_entity_filter)

return Gui
