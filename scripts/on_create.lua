local drill_manager = require("scripts.drills.drill_manager")

-- Handle when a drill is built bu player
script.on_event(defines.events.on_built_entity,
    function(event)
        local entity = event.created_entity
        if entity and entity.valid and entity.type == "mining-drill" then
            drill_manager.add_drill(entity)
        end
    end
)
-- Handle when a drill is built by robot
script.on_event(defines.events.on_robot_built_entity,
    function(event)
        local entity = event.created_entity
        if entity and entity.valid and entity.type == "mining-drill" then
            drill_manager.add_drill(entity)
        end
    end
)
