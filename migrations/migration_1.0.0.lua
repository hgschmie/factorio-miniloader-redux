--
-- Migrate to new 1.0 config format
--

This.Console.resyncMiniloaders()

-- fix up tombstone manager

if storage.framework and storage.framework.tombstone_manager then
    storage.framework.tombstone_manager.tombstones = {}
    storage.framework.tombstone_manager.tombstone_count = 0
    storage.framework.tombstone_manager.last_tick_index = nil
end
