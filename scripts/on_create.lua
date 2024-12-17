-- on_create.lua
local drill_manager = require("scripts.drills.drill_manager")

script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.entity
    if entity and entity.valid and entity.type == "mining-drill" then
        drill_manager.add_drill(entity, true)
        -- Force a second refresh after adding the drill:
        drill_manager.refresh_ui()
    end
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
    local entity = event.entity
    if entity and entity.valid and entity.type == "mining-drill" then
        drill_manager.add_drill(entity, true)
        -- Force a second refresh after adding the drill:
        drill_manager.refresh_ui()
    end
end)
