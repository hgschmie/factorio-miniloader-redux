------------------------------------------------------------------------
-- GUI code
------------------------------------------------------------------------
assert(script)

local util = require('util')

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')
local table = require('stdlib.utils.table')

local Matchers = require('framework.matchers')

local const = require('lib.constants')

---@class miniloader.Gui
local Gui = {
    AUX_GUI_NAME = 'miniloader'
}

local function get_gui_event_definition()
    ---@type framework.gui_manager.event_definition
    return {
        events = {
            onToggleSpoilage = Gui.onToggleSpoilage,
            onSpoilPriority = Gui.onSpoilPriority,
            onToggleTurboMode = Gui.onToggleTurboMode,
            onToggleLaneFilter = Gui.onToggleLaneFilter,
            onSpillMode = Gui.onSpillMode,
        },
        callback = Gui.guiUpdater,
    }
end


---@param gui framework.gui
---@return framework.gui.element_definition ui
local function spoilage_gui(gui)
    local gui_events = gui.gui_events

    return {
        type = 'flow',
        direction = 'horizontal',
        children = {
            {
                type = 'checkbox',
                caption = { '', { 'gui-inserter.spoiled-priority' }, ' [img=info]' },
                tooltip = { 'gui-inserter.spoiled-priority-tooltip' },
                name = 'spoilage_priority',
                handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onToggleSpoilage },
                state = false,
            },
            {
                type = 'empty-widget',
                style_mods = {
                    horizontally_stretchable = true,
                    horizontally_squashable = true,
                },
            },
            {
                type = 'radiobutton',
                caption = { 'gui-inserter.spoiled-first' },
                name = 'spoiled_first',
                elem_tags = { mode = 'spoiled_first', },
                handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onSpoilPriority },
                state = false,
                enabled = false,
            },
            {
                type = 'radiobutton',
                caption = { 'gui-inserter.fresh-first' },
                name = 'fresh_first',
                elem_tags = { mode = 'fresh_first', },
                handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onSpoilPriority },
                state = false,
                enabled = false,
            },
        },
    }
end

---@param gui framework.gui
---@param ml_entity miniloader.Data
---@return framework.gui.element_definition ui
local function turbo_gui(gui, ml_entity)
    local gui_events = gui.gui_events

    return {
        type = 'flow',
        direction = 'horizontal',
        children = {
            {
                type = 'checkbox',
                caption = { '', { const:locale('turbo_mode') }, ' [img=info]' },
                tooltip = { const:locale('turbo_mode_tooltip') },
                name = 'turbo_mode',
                handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onToggleTurboMode },
                state = ml_entity.config.turbo_mode or false,
                enabled = true,
            },
            {
                type = 'empty-widget',
                style_mods = {
                    horizontally_stretchable = true,
                    horizontally_squashable = true,
                },
            },
            {
                type = 'checkbox',
                caption = { '', { const:locale('lane_filter') }, ' [img=info]' },
                tooltip = { const:locale('lane_filter_tooltip') },
                name = 'lane_filter',
                handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onToggleLaneFilter },
                state = ml_entity.config.lane_filter or false,
                enabled = true,
            },
        },
    }
end

---@param gui framework.gui
---@param ml_entity miniloader.Data
---@return framework.gui.element_definition ui
local function spill_gui(gui, ml_entity)
    local gui_events = gui.gui_events

    return {
        type = 'flow',
        direction = 'vertical',
        style_mods = {
            top_padding = 8,
        },
        children = {
            {
                type = 'radiobutton',
                caption = { '', { const:locale('spill_stuck_items') }, ' [img=info]' },
                tooltip = { const:locale('spill_stuck_items_tooltip') },
                name = 'spill_stuck_items',
                elem_tags = { mode = 'spill_stuck_items', },
                handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onSpillMode },
                state = ml_entity.config.spill_mode,
                enabled = true,
            },
            {
                type = 'radiobutton',
                caption = { '', { const:locale('discard_stuck_items') }, ' [img=info]' },
                tooltip = { const:locale('discard_stuck_items_tooltip') },
                name = 'discard_stuck_items',
                elem_tags = { mode = 'discard_stuck_items', },
                handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onSpillMode },
                state = not ml_entity.config.spill_mode,
                enabled = true,
            },
            {
                type = 'empty-widget',
                style_mods = {
                    horizontally_stretchable = true,
                    horizontally_squashable = true,
                },
            },
        },
    }
end

---@param gui framework.gui
---@return framework.gui.element_definition? ui
function Gui.getUi(gui)
    local ml_entity = assert(This.MiniLoader:getEntity(gui.entity_id))

    if ml_entity.config.nerf_mode then return nil end

    local children = {}

    if not ml_entity.config.nerf_mode then
        children[#children + 1] = turbo_gui(gui, ml_entity)
        children[#children + 1] = spill_gui(gui, ml_entity)
    end

    if This.MiniLoader.spoiling then
        children[#children + 1] = spoilage_gui(gui)
    end

    return {
        type = 'frame',
        name = 'aux_gui_root',
        direction = 'vertical',
        style_mods = {
            width = 448,
        },
        anchor = {
            gui = defines.relative_gui_type.loader_gui,
            position = defines.relative_gui_position.bottom,
        },
        children = {
            {
                type = 'frame',
                style = 'entity_frame',
                direction = 'vertical',
                children = children,
            },
        },
    }
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onToggleSpoilage(event, gui)
    local ml_entity = This.MiniLoader:getEntity(gui.entity_id)
    if not ml_entity then return end

    ---@type miniloader.GuiContext
    local gui_context = gui.context

    local element = event.element
    if element.state then
        ml_entity.config.spoil_priority = gui_context.spoil_priority
    else
        gui_context.spoil_priority = ml_entity.config.spoil_priority
        ml_entity.config.spoil_priority = 'none'
    end
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onSpoilPriority(event, gui)
    local ml_entity = This.MiniLoader:getEntity(gui.entity_id)
    if not ml_entity then return end

    local element = event.element
    ml_entity.config.spoil_priority = assert(element.tags.mode)
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onToggleTurboMode(event, gui)
    local ml_entity = This.MiniLoader:getEntity(gui.entity_id)
    if not ml_entity then return end

    local element = event.element
    ml_entity.config.turbo_mode = element.state or false
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onToggleLaneFilter(event, gui)
    local ml_entity = This.MiniLoader:getEntity(gui.entity_id)
    if not ml_entity then return end

    local element = event.element
    ml_entity.config.lane_filter = element.state or false
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onSpillMode(event, gui)
    local ml_entity = This.MiniLoader:getEntity(gui.entity_id)
    if not ml_entity then return end

    local element = event.element
    ml_entity.config.spill_mode = assert(element.tags.mode) == 'spill_stuck_items'
end

--------------------------------------------------------------------------------
-- Gui Updater
--------------------------------------------------------------------------------

---@param gui framework.gui
---@param ml_entity miniloader.Data
local function update_spoilage(gui, ml_entity)
    local spoilage_priority = assert(gui:findElement('spoilage_priority'))
    local spoiled_first = assert(gui:findElement('spoiled_first'))
    local fresh_first = assert(gui:findElement('fresh_first'))

    if This.MiniLoader.spoiling and not ml_entity.config.turbo_mode then
        spoilage_priority.enabled = true

        local inserter_spoil_priority = ml_entity.config.spoil_priority or 'none'

        spoilage_priority.state = (inserter_spoil_priority ~= 'none')
        spoiled_first.enabled = spoilage_priority.state
        fresh_first.enabled = spoilage_priority.state
        spoiled_first.state = (inserter_spoil_priority == 'spoiled_first')
        fresh_first.state = (inserter_spoil_priority == 'fresh_first')
    else
        spoilage_priority.enabled = false
        spoilage_priority.state = false
        spoiled_first.enabled = false
        spoiled_first.state = false
        fresh_first.enabled = false
        fresh_first.state = false
    end
end

---@param gui framework.gui
---@param ml_entity miniloader.Data
local function update_gui(gui, ml_entity)
    local turbo_mode = assert(gui:findElement('turbo_mode'))
    local lane_filter = assert(gui:findElement('lane_filter'))

    turbo_mode.state = ml_entity.config.turbo_mode

    lane_filter.state = ml_entity.config.lane_filter
    lane_filter.enabled = turbo_mode.state

    local spill_stuck_items = assert(gui:findElement('spill_stuck_items'))
    local discard_stuck_items = assert(gui:findElement('discard_stuck_items'))

    spill_stuck_items.state = ml_entity.config.spill_mode
    discard_stuck_items.state = not ml_entity.config.spill_mode
end


---@param gui framework.gui
---@return boolean
function Gui.guiUpdater(gui)
    local ml_entity = This.MiniLoader:getEntity(gui.entity_id)
    if not ml_entity then return false end

    This.Config:updateConfigFromLoader(ml_entity.config, ml_entity.loader)

    ---@type miniloader.GuiContext
    local context = gui.context

    local refresh_config = not (context.last_config and table.compare(context.last_config, ml_entity.config))

    if refresh_config then
        -- if reconfiguration closed the gui, exit right away.
        if This.MiniLoader:reconfigure(ml_entity) then return true end

        if This.MiniLoader.spoiling then update_spoilage(gui, ml_entity) end

        update_gui(gui, ml_entity)
        context.last_config = util.copy(ml_entity.config)
    end

    return true
end

--------------------------------------------------------------------------------
-- Event management
--------------------------------------------------------------------------------

---@param event EventData.on_gui_opened
local function on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if not (event.entity and event.entity.valid) then return end

    return Gui.openGui(event.entity, event.player_index)
end

function Gui.openGui(entity, player_index)
    local ml_entity = This.MiniLoader:getEntity(entity.unit_number)
    if not ml_entity then return end

    local player = Player.get(player_index)
    if not player then return end


    -- nerf mode
    if ml_entity.config.nerf_mode then
        player.opened = nil
        return
    end

    ---@class miniloader.GuiContext
    ---@field last_config table<string, any>?
    ---@field spoil_priority SpoilPriority
    local gui_state = {
        last_config = nil, -- first gui tick updates the UI
        spoil_priority = 'spoiled_first',
    }

    Framework.gui_manager:createGui {
        type = Gui.AUX_GUI_NAME,
        player_index = player_index,
        parent = player.gui.relative,
        ui_tree_provider = Gui.getUi,
        context = gui_state,
        entity_id = ml_entity.main.unit_number,
    }

    if game.players[player_index].opened == ml_entity.loader then return end

    game.players[player_index].opened = ml_entity.loader
end

---@param event EventData.on_gui_closed
local function on_gui_closed(event)
    if not (event.entity and event.entity.valid) then return end

    local gui = Framework.gui_manager:findGui(event.player_index, Gui.AUX_GUI_NAME)

    local ml_entity = gui and This.MiniLoader:getEntity(gui.entity_id)

    Framework.gui_manager:destroyGui(event.player_index, Gui.AUX_GUI_NAME)

    if not ml_entity then return end

    This.Config:updateConfigFromLoader(ml_entity.config, ml_entity.loader)
    This.Config:resyncEntities(ml_entity)

    ml_entity.state.status = ml_entity.loader.status
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

    Framework.gui_manager:registerGuiType(Gui.AUX_GUI_NAME, get_gui_event_definition())
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
