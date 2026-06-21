-- add nerf mode field to all entities

local const = require('lib.constants')

for entity_id, entity in pairs(This.MiniLoader:entities()) do
    if entity.config.inserter_config then
        if not (entity.main.valid and entity.loader.valid) then
            This.MiniLoader:destroy(entity_id)
        else
            local nerf_mode = prototypes.mod_data[const.name].data[entity.main.name].nerf_mode or false
            entity.config.nerf_mode = entity.config.nerf_mode or nerf_mode
            This.MiniLoader:reconfigure(entity)
        end
    end
end
