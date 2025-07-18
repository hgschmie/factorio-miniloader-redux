-- reconfigure all miniloaders

for entity_id, entity in pairs(This.MiniLoader:entities()) do
    if not (entity.main.valid and entity.loader.valid) then
        This.MiniLoader:destroy(entity_id)
    else
        for i = 2, #entity.inserters do
            if entity.inserters[i].valid then
                entity.inserters[i].destroy()
            end
            entity.inserters[i] = nil
        end
        entity.inserters = This.MiniLoader:createInserters(entity.main, entity.loader, entity.config)
        This.MiniLoader:reconfigure(entity)
    end
end
