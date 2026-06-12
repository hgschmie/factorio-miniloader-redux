-- add turbo mode and lane filter field to all entities

for entity_id, entity in pairs(This.MiniLoader:entities()) do
    This.MiniLoader:sanitizeConfiguration(entity.config)

        if not (entity.main.valid and entity.loader.valid) then
        This.MiniLoader:destroy(entity_id)
    else
        entity.config.turbo_mode = false
        entity.config.lane_filter = false
        This.MiniLoader:reconfigure(entity)
    end
end

-- fix up tombstone manager

storage.framework.tombstone_manager.tombstones = {}
storage.framework.tombstone_manager.tombstone_count = 0
storage.framework.tombstone_manager.last_tick_index = nil
