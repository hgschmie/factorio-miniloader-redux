-- add read_transfers config attribute

for _,entity in pairs(This.MiniLoader:entities()) do
    if entity.config.inserter_config then
        entity.config.inserter_config.read_transfers = entity.config.inserter_config.read_transfers or false
    end
end
