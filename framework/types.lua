---@meta
----------------------------------------------------------------------------------------------------
--- framework types
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--- ghost_manager.lua
----------------------------------------------------------------------------------------------------

---@class FrameworkAttachedEntity
---@field entity LuaEntity
---@field name string?
---@field position MapPosition?
---@field orientation float?
---@field tags Tags?
---@field player_index integer
---@field tick integer

---@class FrameworkGhostManagerState
---@field ghost_entities FrameworkAttachedEntity[]

----------------------------------------------------------------------------------------------------
--- gui_manager.lua
----------------------------------------------------------------------------------------------------

---@class FrameworkGuiManagerState
---@field count integer running count of all known UIs
---@field guis table<number, FrameworkGui> All registered and known guis for this manager.

----------------------------------------------------------------------------------------------------
--- gui.lua
----------------------------------------------------------------------------------------------------

--- A handler function to invoke when receiving GUI events for this element.
---@alias FrameworkGuiElemHandler fun(e: FrameworkGuiEventData)

--- Aggregate type of all possible GUI events.
---@alias FrameworkGuiEventData EventData.on_gui_checked_state_changed|EventData.on_gui_click|EventData.on_gui_closed|EventData.on_gui_confirmed|EventData.on_gui_elem_changed|EventData.on_gui_location_changed|EventData.on_gui_opened|EventData.on_gui_selected_tab_changed|EventData.on_gui_selection_state_changed|EventData.on_gui_switch_state_changed|EventData.on_gui_text_changed|EventData.on_gui_value_changed

---@class FrameworkGuiElementExtras
---@field style_mods table<string, any>? Post-creation modifications to the element's style.
---@field elem_mods table<string, any>? Post-creation modifications to the element itself.
---@field elem_tags table<string, any>? Post-creation modifications to the element tags.
---@field drag_target string? Set the element's drag target to the element whose name matches this string. The drag target must be present in the UI component tree before assigning it.
---@field handler (FrameworkGuiElemHandler|table<defines.events, FrameworkGuiElemHandler>)? Handler(s) to assign to this element. If assigned to a function, that function will be called for any GUI event on this element.
---@field children FrameworkGuiElemDef[]? Children to add to this element.

--- A GUI element definition. This extends `LuaGuiElement.add_param` with several new attributes.
---@class FrameworkGuiElemDef: LuaGuiElement.add_param.base
---@field style_mods table<string, any>? Post-creation modifications to make to the element's style.
---@field elem_mods table<string, any>? Post-creation modifications to make to the element itself.
---@field drag_target string? Set the element's drag target to the element whose name matches this string. The drag target must be present in the UI component tree before assigning it.
---@field handler (FrameworkGuiElemHandler|table<defines.events, FrameworkGuiElemHandler>)? Handler(s) to assign to this element. If assigned to a function, that function will be called for any GUI event on this element.
---@field children FrameworkGuiElemDef[]? Children to add to this element.
---@field tab FrameworkGuiElemDef? To add a tab, specify `tab` and `content` and leave all other fields unset.
---@field content FrameworkGuiElemDef? To add a tab, specify `tab` and `content` and leave all other fields unset.

----------------------------------------------------------------------------------------------------
--- init.lua
----------------------------------------------------------------------------------------------------

---@class FrameworkConfig
---@field name string The human readable name for the module
---@field prefix string A prefix for all game registered elements
---@field root string The module root name
---@field log_tag string? A custom logger tag
---@field remote_name string? The name for the remote interface. If defined, the mod will have a remote interface.

----------------------------------------------------------------------------------------------------
--- settings.lua
----------------------------------------------------------------------------------------------------

---@alias FrameworkSettingsStorage table<string, (FrameworkSettingValue|table<string, FrameworkSettingValue?>)?>?

---@class FrameworkSettingsProvider
---@field values FrameworkSettingsStorage
---@field load_value fun(name: string, player_index: integer?): ModSetting?
---@field store_value fun(name: string, value: FrameworkSettingValue, player_index: integer?)?
---@field get_values fun(self: FrameworkSettingsProvider, player_index: integer?): FrameworkSettingsStorage
---@field set_values fun(self: FrameworkSettingsProvider, values: table<string, FrameworkSettingValue?>, player_index: integer?)
---@field clear fun(self: FrameworkSettingsProvider, player_index: integer?)

---@alias FrameworkSettingValue (int)|(double)|(boolean)|(string)|(Color)

---@class FrameworkSetting
---@field key string
---@field value FrameworkSettingValue

---@alias FrameworkSettingsGroup table<string, FrameworkSetting>