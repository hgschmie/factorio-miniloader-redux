for _, ml_entity in pairs(This.MiniLoader:entities()) do
    This.Config:sanitizeConfiguration(ml_entity.config)
end
